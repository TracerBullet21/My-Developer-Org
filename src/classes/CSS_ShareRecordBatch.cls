/** 
 * This record sharing class grants access to records based on associated accounts (e.g., order 
 * ship to, order sold to, SAP invoice bill to, SAP invoice sold to, and case account). This
 * class should be used for batch updating of users to grant them access to orders, invoices and
 * complaints. 
 *
 * Granting access to these records is only applicable to external community partner users
 * in the Customer Self Service Portal (i.e., user must have a specific license type).
 *
 * Do NOT schedule this class using the Apex Scheduler (i.e., "All Scheduled Jobs" under setup). 
 * Instead use CSS_ShareRecordScheduler. This class implements Schedulable for adhoc scheduling 
 * only, not scheduling via Apex Scheduler. 
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_ShareRecordService, CSS_ShareRecordScheduler, CSS_Utility
 */
global without sharing class CSS_ShareRecordBatch implements Database.Batchable<sObject>, 
  Database.Stateful, Schedulable {

  /** Applicable job types for this batch process (i.e., used to query in-process batches) */
  public static final Set<String> JOB_TYPES = new Set<String> 
    {'BatchApex', 'ScheduledApex'};

  /** In-process job types for this batch process */
  public static final Set<String> JOB_INPROCESS_STATUS = new Set<String>
    {'Preparing','Processing'}; // not included: Aborted, Completed, Failed

  /** Queued job types for this batch process */
  public static final Set<String> JOB_QUEUED_STATUS = new Set<String>
    {'Holding','Queued'}; // not included: Aborted, Completed, Failed

  /** Complaint record type identifier, which should never change (needed for query) */
  public static final String RECORD_TYPE_ID_COMPLAINT = '012i00000011WNIAA2';

  /** Cascade of shares to update (e.g., start with orders, go to invoices, go to cases, ...) */
  private static final Map<Schema.sObjectType,Schema.sObjectType> 
    cascade = new Map<Schema.sObjectType,Schema.sObjectType> {
      Order__c.sObjectType=>SAP_Invoice__c.sObjectType,
      SAP_Invoice__c.sObjectType=> Case.sObjectType, 
      Case.sObjectType=>null
    };

  /** Object type that is currently being processed */
  private final Schema.sObjectType objectType;

  /** List of in scope users (i.e., dirty community users) */
  private final List<User> users;

  /** List of in scope accounts (i.e., dirty community accounts) */
  private final List<Id> accountIds;


  /**
   * No argument, default constructor for this Customer Self Service Community record sharing
   * batch class. This constructor should not be called by outside methods. Instead, please use
   * the reconcile static methods to schedule batches. Doing this ensures multiple batches are not 
   * created and scheduled within the same time period.
   */
  @TestVisible
  private CSS_ShareRecordBatch() { }

 /**
   * Constructor for this Customer Self Service Community record sharing batch class. This 
   * constructor should not be called by outside methods. Instead, please use the reconcile 
   * static methods to schedule batches. Doing this ensures multiple batches are not created 
   * and scheduled within the same time period.
   *
   * @param token the first object in the cascade to start processing record shares for 
   */
  @TestVisible
  private CSS_ShareRecordBatch(Schema.sObjectType token) {
    this.objectType = token; // object type will persist accross batches
    
    // Identify applicable users (i.e., dirty community users)
    this.users = [SELECT Contact.AccountId, Profile.UserLicense.Name FROM User 
      WHERE isActive = true AND Profile.UserLicense.Name = :CSS_Utility.PARTNER_LICENSES
      AND Community_Dirty_Flag__c = true];
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordService - Sharing ' + token + ' Records: ' + 
      'dirty community users: ' + this.users);
    
    // Identify applicable accounts (i.e., dirty accounts and dirty children accounts)
    this.accountIds = new List<Id>();
    for (User usr : this.users) { // users should only have one account
      this.accountIds.add(usr.Contact.AccountId);
    } // add dirty children accounts next...
    this.accountIds.addAll(CSS_ShareRecordUtility.getChildrenAccounts(this.accountIds)); 
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordService - Sharing ' + token + ' Records: ' + 
      'dirty community accounts: ' + this.accountIds);
  }

  /**
   * Execute the Customer Self Service batch executable class instance. This method is required
   * for schedulable classes. Use this method to schedule a community share reconciliation on an
   * adhoc basis only! For Scheduled Apex, please use CSS_ShareRecordScheduler.
   *
   * @param SchedulableContext information about the schedulable environment
   */
  public void execute(SchedulableContext sc) {
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordBatch - Scheduled Adhoc Request.');
    CSS_ShareRecordBatch.reconcile(); // with caution is not necessary for adhoc requests
  }

  /**
   * This start method is called at the beginning of the batch Apex job and is used to 
   * instantiate the Database.QueryLocator object with the query defined within. If the batch job
   * is timing out, it is most likely due to the query defined in this method, so make sure the 
   * query is selective). 
   *
   * @param context batchable context variable, which can be used to get the batch identifier
   * @return a newly instantiated QueryLocator object based on the query defined within the method.
   */
  public Database.QueryLocator start(Database.BatchableContext context){
    String query = getQueryString(this.objectType); 
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordBatch - Share Record Batch: ' + query);
    Database.QueryLocator locator = Database.getQueryLocator(query);
    return locator;
  }

  /**
   * The execute method grants access to order, case, and SAP invoices records by leverating
   * the CSS_ShareRecordService class. Sharing is only applicable to external community partner 
   * users in the Customer Self Service Portal (i.e., user must have a specific license type).
  * 
   * @param context batchable context variable, which can be used to get the batch identifier
   * @param records list of records to process (i.e., remove/add associated shares)
   */
  public void execute(Database.BatchableContext context, List<sObject> records){
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordBatch - Execute Batch: ' + records);
   
    try { // Share records with community users
      if (records instanceof List<Order__c>) {
        CSS_ShareRecordService.shareOrders(records); 
      }
      if (records instanceof List<SAP_Invoice__c>) {
        CSS_ShareRecordService.shareSAPInvoices(records); 
      }
      if (records instanceof List<Case>) {
        CSS_ShareRecordService.shareCases(records); 
      }
    }
    catch (Exception ex) { // log exception to database using util class
      CSS_Utility.logError('CSS_ShareRecordBatch - Share Orders Failed. ', ex);
    } 
  }

  /**
   * The finish method is called after all batches have been processed. This method will call other
   * batches until the batch cascade is complete (i.e., orders then invoices then cases then nothing).
   *
   * @param context batchable context variable, which can be used to get the batch identifier
   */
  public void finish(Database.BatchableContext context) {
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordBatch - finished Batch: ' + this.objectType);
    if (cascade.get(this.objectType) != null) { // continue if cascade isn't finished
      CSS_ShareRecordBatch batch = new CSS_ShareRecordBatch(cascade.get(this.objectType)); 
      database.executebatch(batch);
    }
    else { // cascade has finished
      try { // update each user as clean
        List<user> updates = users.clone();
        for (User usr : updates) {
          usr.Community_Dirty_Flag__c = false;
        }
        update updates;
      }
      catch (Exception ex) { // log exception to database using util class
        CSS_Utility.logError('CSS_ShareRecordBatch - Update Community Users to Clean Failed. ', ex);
      } 
    }
  }

  /**
   * Use the getQueryString method to return an object specific query string, which can be fed
   * into a batchable database queryLocator. The accountIds instance variable should be set
   * before calling this method
   *
   * @param token the sObjectType token for the requested query
   * @return a query string based on the given object token
   * @throws a CSS_Exception if the query token provided is not supported
   */
  @TestVisible 
  private static String getQueryString(Schema.sObjectType token) {
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordBatch - Getting Query String: ' + token);
    
    if (token == Order__c.sObjectType) { // ship to and sold to accounts
      return 'SELECT Name, Ship_To_Name__c, Sold_to_Account__c FROM Order__c ' +
        'WHERE Ship_To_Name__c = :accountIds OR Sold_to_Account__c = :accountIds';
    }
    else if (token == SAP_Invoice__c.sObjectType) { // bill to, sold to, and payer accounts
      return 'SELECT Name, Bill_To_Account__c, Sold_To_Party__c, Payer_Account__c, Ship_to_Party__c FROM SAP_Invoice__c ' +
        'WHERE Bill_To_Account__c = :accountIds OR Sold_To_Party__c = :accountIds ' + 
        'OR Payer_Account__c = :accountIds OR Ship_to_Party__c = :accountIds';
    }
    else if (token == Case.sObjectType) { // case accounts with record type of compliant
      return 'SELECT RecordTypeId, AccountId FROM Case WHERE AccountId = :accountIds ' +
        'AND RecordTypeId = :RECORD_TYPE_ID_COMPLAINT';
    }
    else { // invalid object type passed
      throw new CSS_Exception('SObject token provided is not supported. Please pass a supported token.');
    }
  }

  /**
   * Execute the Customer Self Service batch executable class instance. Use this method to 
   * execute a community share reconciliation for dirty community users.
   *
   * @param SchedulableContext information about the schedulable environment
   */
  public static void reconcile() {
    CSS_ShareRecordBatch batch = new CSS_ShareRecordBatch(Order__c.sObjectType); 
    database.executebatch(batch);
  }

  /**
   * Use the getQuery method to return a query string to feed the batchable database queryLocator.
   *
   * @param token the sObjectType token for the requested query
   * @return a query string based on the given object token
   * @throws a CSS_Exception if the query token provided is not supported
   */
  public static String reconcileWithCaution() {
    
    // Find all the currently queued or executing batch jobs
    List<AsyncApexJob> jobs = [SELECT Status, CreatedDate, CompletedDate FROM AsyncApexJob 
      WHERE JobType = :JOB_TYPES AND ApexClass.Name = 'CSS_ShareRecordBatch' 
      AND (Status = :JOB_INPROCESS_STATUS OR Status = :JOB_QUEUED_STATUS) 
      AND CreatedDate = LAST_N_DAYS:1];
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordBatch - Reconcile Sharing Jobs: ' + jobs);
    
    // Loop through and determine if any jobs are already queued (i.e., scheduled)
    for (AsyncApexJob job : jobs) {
      if (JOB_QUEUED_STATUS.contains(job.status)) {
        System.debug(LoggingLevel.INFO, System.Label.CSS_Sharing_Scheduled);
        return System.Label.CSS_Sharing_Scheduled;
      }
    }

    // Loop through and determine if any jobs are already in-process
    for (AsyncApexJob job : jobs) {
      if (JOB_INPROCESS_STATUS.contains(job.status)) {

        // Create a timestamp that is minutes in the future
        Datetime timestamp = Datetime.now().addMinutes(30); // 30 minute delay
        String timeForScheduler = timestamp.format('s m H d M \'?\' yyyy');
        
        // Schedule an instance of this class to execute in the future
        Id scheduleId = System.Schedule('Scheduled Community Share Reconciliation ' + timestamp,
          timeForScheduler, new CSS_ShareRecordBatch());
        System.debug(LoggingLevel.INFO, System.Label.CSS_Sharing_In_Process);
        return System.Label.CSS_Sharing_In_Process;
      }
    }
    
    // No queued or in-process batches, so start the batch immediately
    reconcile();
    System.debug(LoggingLevel.INFO, System.Label.CSS_Sharing_Submitted);
    return System.Label.CSS_Sharing_Submitted;
  }

  /**
   * The updateVisibilty web service method is used by JavaScript buttons to schedule a Customer 
   * Self Service Community sharing reconciliation for the given user.
   *
   * @param contactId the contact identifier of the community user.
   * @return a string that indicates success or failure.
   */
  webservice static String updateVisibility (String contactId) {
    try {

      // First, update the user to a dirty user (i.e., isDirty = true)
      user usr = [SELECT Id FROM User WHERE ContactId = :contactId LIMIT 1];
      usr.Community_Dirty_Flag__c = true;
      update usr;

      // Second, reconcile sharing rules, return any status messages
      return reconcileWithCaution();
    }
    catch (Exception ex) {
      CSS_Utility.logError('CSS_ShareRecordBatch - Update Visibilty Failed. ', ex);
      return 'Error: Update Visibilty Failed. System Message: ' + ex.getMessage();
    }  
  }
}