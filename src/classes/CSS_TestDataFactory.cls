/**
 * The Customer Self Service test data factory creates community users and associated records for 
 * testing community functionality.
 *
 * @author Craig Poirier
 */
@isTest
public class CSS_TestDataFactory {

  /** Build a local cache so that we don't request this multiple times */
  private static Map<Schema.SObjectType,Map<String,Id>> rtypesCache
    = new Map<Schema.SObjectType,Map<String,Id>>();

  /** 
   * Name po profile to test with; name must match exactly. This profile will be used as the 
   * profile for the official community partner test user, which is retrieved by using the 
   * getCommunityUser method.
   */
  public static final String TEST_PROFILE = 'BI Customer w Installed Sales';

    /** JMConnexus Site Guest User; name has to match exactly */
  public static final String GUEST_USER_NAME = 'JMConnexus Site Guest User';

  /** List of default objects that should have their triggers bypassed */
  public static String triggerBypasses = 'Account;Contact;Opportunity;User';

  /** List of permission sets to assign to test users; names must match exactly. */
  public static List<String> permissions = new List<String> 
    {'CSS_Financial_Data', 'CSS_ComplaintCases'};


  /**
   * Sets up enviroment specific settings (i.e., custom settings) using the current user.
   *
   * @param bypassValidations set to true to bypass validations
   * @param bypassTriggers set to true to bypass triggers
   */
  public static void setEnviroment(Boolean bypassValidations, Boolean bypassTriggers) {
    setEnviroment(bypassValidations, bypassTriggers, UserInfo.getUserId());
  }

  /**
   * Sets up enviroment specific settings (i.e., custom settings).
   *
   * @param bypassValidations set to true to bypass validations
   * @param bypassTriggers set to true to bypass triggers
   * @param userId the user's identifier running the tests
   */
  public static void setEnviroment(Boolean bypassValidations, Boolean bypassTriggers, String userId) {
    
    // Configure all the necessary custom settings for community test classes
    List<sObject> settings = new List<sObject>();
    settings.add(new Disable_Background_Processes__c(SetupOwnerId = userId,
      Disable_Validation_Rules__c = bypassValidations, 
      Disable_Triggers__c = bypassTriggers, 
      Trigger_Objects__c = triggerBypasses));
    insert settings;
  }

  /**
   * The createTestData method creates a default set of accounts, opportunities, orders, cases
   * invoices, notes, SAP invoices, etc... this method does not create partner community users or 
   * partner accounts.
   */
  public static void createTestData() {
    List<SObject> records = new List<SObject>();

    // Generate a test set of partner accounts
    records.add(new Account(
      Name = 'css-data-account-0', 
      Type = 'Contr - Insulation',
      Account_External_ID__c = 'css-data-account-0',
      RecordTypeId = '012i00000011WNEAA2' // Customer (should never change)
    ));
        
    // Generate a test set of opportunities
    records.add(new Opportunity(
      Name = 'css-data-opportunity-0',
      StageName = 'Pending',
      CloseDate = Date.today().addDays(10),
      Oppty_External_ID__c = 'css-data-opportunity-0',
      Account = new Account(Account_External_ID__c = 'css-data-account-0'),
      RecordTypeId = '012i00000011WNiAAM' // Lowe's Job (should never change)
    ));

    // Generate a test set of invoices
    records.add(new Invoice__c(
      Contractor_PO_Number__c = 'css-data-invoice-0',
      COC_Form_Submitted__c = true,
      Opportunity__r = new Opportunity(Oppty_External_ID__c = 'css-data-opportunity-0')
    ));

    // Generate a test set of attachments
    records.add(new Attachment_JM_Obj__c(
      Title__c = 'css-data-attachment-0',
      Type__c = 'Scope of Work',
      Private__c = false,
      Security__c = 'external',
      AttachmentNotes_External_ID__c = 'css-data-attachment-0',
      Opportunity_R__r = new Opportunity(Oppty_External_ID__c = 'css-data-opportunity-0')
    ));

    // Load all the account and contact records before adding users
    System.debug(LoggingLevel.INFO, 'CSS_TestDataFactory - Inserting Records: ' + records);
    insert records;

    List<Attachment> attachments = new List<Attachment>();
    attachments.add(new Attachment(
      Name = 'css-data-attachment-child-0',
      Body = Blob.valueof('body'),
      ContentType = 'application/pdf',
      ParentId = records[3].id // attachment record
    ));
    insert attachments;
  }

  /**
   * Creates a partner account, a partner contact, and associated user record. This set of test
   * data is seperated from other sets because it performs mixed DML operations between account,
   * contact, and user, which is not allowed outside of test methods.
   *
   * If you still receive a mixed DML error in a Test Method, call this method inside 
   * Test.startTest and Test.stopTest to bypass the mixed DML error in the Test Method. For more
   * details see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/
   * apex_dml_non_mix_sobjects_test_methods.htm
   */
  public static void createCommunityUsers() {
    
    // Generate a test set of partner accounts
    List<SObject> parents = new List<SObject>();
    parents.add(new Account(
      Name = 'css-test-parent-0', 
      Type = 'Contr - Insulation',
      Account_External_ID__c = 'css-test-parent-0',
      RecordTypeId = '012i00000011WNEAA2'  // Customer (should never change)
    ));
    insert parents; // has to be insert first since parent of some sObject type

    // Create test accounts
    List<SObject> records = new List<SObject>();
    records.add(new Account(
      Name = 'css-test-account-0', 
      Type = 'Contr - Insulation',
      Ship_To_Financials__c = true,
      Parent = new Account(Account_External_ID__c = 'css-test-parent-0'),
      Account_External_ID__c = 'css-test-account-0',
      RecordTypeId = '012i00000011WNEAA2'  // Customer (should never change)
    ));

    // Create test partner contacts (one for each license)
    records.add(new Contact(
      FirstName = 'Test',
      LastName = 'Contractor0',
      Email = 'css-test-user-0@example.com.css',
      Account = new Account(Account_External_ID__c = 'css-test-account-0'),
      Contact_External_ID__c = 'css-test-contact-0'));

    // Create test orders
    records.add(new Order__c(
      Name = '123456789', 
      Order_Number__c = '123456789', 
      Ship_To_Name__r = new Account(Account_External_ID__c = 'css-test-account-0'),
      Sold_to_Account__r = new Account(Account_External_ID__c = 'css-test-account-0')
    ));

    // Create test SAP invoices
    records.add(new SAP_Invoice__c(
      Name = '123456789', 
      Invoice_Number__c = '123456789', 
      Bill_To_Account__r = new Account(Account_External_ID__c = 'css-test-account-0'),
      Payer_Account__r = new Account(Account_External_ID__c = 'css-test-account-0'),
      Ship_to_Party__r = new Account(Account_External_ID__c = 'css-test-account-0'),
      Sold_To_Party__r = new Account(Account_External_ID__c = 'css-test-account-0')
    ));

    // Create test Compliants
    records.add(new Case(
      Case_External_ID__c = '123456789',
      RecordTypeId = CSS_ShareRecordService.RECORD_TYPE_ID_COMPLAINT,
      Account = new Account(Account_External_ID__c = 'css-test-account-0')
    ));

    // Load all the account and contact records before adding users
    System.debug(LoggingLevel.INFO, 'CSS_TestDataFactory - Inserting Records: ' + records);
    insert records;

    // Run the next insert as a super user to avoid mixed DML errors
    System.runAs(getSuperUser()) { 

      // Create community user (one for each profile)
      String  profileId = [SELECT id FROM Profile WHERE Name = :TEST_PROFILE LIMIT 1].id; 
      User usr = createTestUser(profileId, 'CSS-Community-Test', 'User');
      usr.contact = new Contact(Contact_External_ID__c = 'css-test-contact-0');
      System.debug(LoggingLevel.INFO, 'CSS_TestDataFactory - Inserting User: ' + usr);
      insert usr;
  
      // Create new permissions for the community test user
      List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
      for (PermissionSet pSet : [SELECT Name FROM PermissionSet WHERE Name IN :permissions]) { 
        PermissionSetAssignment assignee = new PermissionSetAssignment(
        AssigneeId = usr.id,
        PermissionSetId = pSet.id);
        assignments.add(assignee);  
      }  
      System.debug(LoggingLevel.INFO, 'CSS_TestDataFactory - Inserting Assignments: ' + assignments);
      insert assignments; 
    }
  }

  /**
   * Use the get community user method to get the offical community partner test user, which has
   * an associated account, contact, order, invoice, case, and permission records. This user can
   * be used to run specific tests and is saved in the database. Remember to call 
   * createCommunityUser before calling this method!
   *
   * @return the offical community partner test user
   */
  public static User getCommunityUser() {
    return [SELECT Name, UserName, ProfileId, Profile.UserLicense.Name, 
      ContactId, Community_Dirty_Flag__c FROM User 
      WHERE FirstName = 'CSS-Community-Test' AND LastName = 'User' LIMIT 1];
  }

  /**
   * Use the get guest user method to get a community guest user. Every community has a guest 
   * profile with an associated guest user. This user is saved in the database and every call
   * to this method returns the same guest user.
   *
   * @return a Customer Self Service Community guest user
   */
  public static User getGuestUser() {
    return [SELECT Name, UserName, ProfileId FROM User WHERE Name = :GUEST_USER_NAME LIMIT 1];
  }

  /**
   * Use the get admin user method to get an system administrator user. This user can be used
   * to run specific tests. This user is not saved in the database and every call to this method
   * creates a new unique admin user.
   *
   * @return a system administrator user
   */
  public static User getAdminUser() { 
    Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id; 
    return createTestUser(profileId, 'Admin', 'User');
  }

  /**
   * Use the get super user method to get an system administrator user. This user can be used
   * to create new users. This user is not saved in the database and every call to this method
   * creates a new unique admin user.
   *
   * @return a system administrator user
   */
  public static User getSuperUser() { 
    Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id; 
    return createTestUser(profileId, 'Super', 'User');
  }

  /**
   * Use the get bogus user method to get a bad community user, who is not assigned a valid 
   * community profile. This user is not saved in the database and every call to this method
   * creates a new unique admin user.
   *
   * @return a bad community user
   */
  public static User getBogusUser() {
    Id profileId = [SELECT id FROM Profile WHERE Name = 'Chatter External User' LIMIT 1].Id;
    return createTestUser(profileId, 'Bogus', 'User');
  }

  /**
   * Usernames are shared across instances, but not across environments (production/sandbox). 
   * Uniqueness is enforced during deployments when tests are run, so an insert call will fail if 
   * the username is already registered in another org in the same environment (production or
   * sandbox). The resolution for this is to use a guaranteed unique username for tests, which this 
   * method does. 
   *
   * @param profId the unique profile identifier
   * @param fName the first name of the user
   * @param lName the last name of the user
   * @return a new user record, which has not been saved to the database
   */
  public static User createTestUser(Id profId, String fName, String lName) {
    String orgId = UserInfo.getOrganizationId();
    String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
    Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
    String uniqueName = orgId + dateString + randomInt;
    User tuser = new User(  
      isActive = true,
      firstname = fName,
      lastName = lName,
      email = uniqueName + '@test' + orgId + '.org',
      Username = uniqueName + '@test' + orgId + '.org',
      EmailEncodingKey = 'ISO-8859-1',
      Alias = uniqueName.substring(18, 23),
      TimeZoneSidKey = 'America/Denver',
      LocaleSidKey = 'en_US',
      LanguageLocaleKey = 'en_US',
      ProfileId = profId);
    return tuser;
  }

  /**
   * Returns a map of active, user-available RecordType IDs for a given SObjectType,
   * keyed by each RecordType's unique, unchanging DeveloperName.
   *
   * @param token the sObject token for the records types desired
   * @return a map of record name to identifier.
   */
  public static Map<String, Id> getRecordTypeIds(Schema.SObjectType token) {
    
    // Do we already have a result? 
    Map<String, Id> mapRecordTypes = rtypesCache.get(token);
    
    // If not, build a map of RecordTypeIds keyed by DeveloperName
    if (mapRecordTypes == null) {
      mapRecordTypes = new Map<String, Id>();
      rtypesCache.put(token,mapRecordTypes);
    } 
    else { // If we do, return our cached result immediately!
      return mapRecordTypes;
    }

    // Get the Describe Result
    Schema.DescribeSObjectResult obj = token.getDescribe();

    // Obtain ALL Active Record Types for the given SObjectType token (we will filter out the 
    // Record Types that are unavailable to the Running User using Schema information)
    String soql = 
      'SELECT Id, Name, DeveloperName ' + 
      'FROM RecordType ' + 
      'WHERE SObjectType = \'' + String.escapeSingleQuotes(obj.getName()) + '\' ' + 
      'AND IsActive = TRUE';
    
    List<SObject> results;
    try {
      results = Database.query(soql);
    } 
    catch (Exception ex) {
      results = new List<SObject>();
    }

    // Obtain the RecordTypeInfos for this SObjectType token
    Map<Id,Schema.RecordTypeInfo> recordTypeInfos = obj.getRecordTypeInfosByID();

    // Loop through all of the Record Types we found, and weed out those that are unavailable 
    // to the Running User
    for (SObject rt : results) {  
      if (recordTypeInfos.get(rt.Id).isAvailable()) {
        // RecordType is available, so add it to our map of RecordTypeIds by DeveloperName
        mapRecordTypes.put(String.valueOf(rt.get('DeveloperName')),rt.Id);
      }
    }
    return mapRecordTypes;
  }

}