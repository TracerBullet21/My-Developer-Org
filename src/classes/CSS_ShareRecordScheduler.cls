/** 
 * This record sharing class grants access to records based on associated accounts (e.g., order 
 * ship to, order sold to, SAP invoice bill to, SAP invoice sold to, and case account). This
 * class should be used for scheduling the batch updating of users to grant them access to orders, 
 * invoices and complaints.  Schedule this class instead of CSS_ShareRecordBatch for Apex 
 * Scheduling. Do not use Apex Scheduling with CSS_ShareRecordBatch, which should only be used
 * for adhoc scheduling.
 *
 * Granting access to these records is only applicable to external community partner users
 * in the Customer Self Service Portal (i.e., user must have a specific license type).
 *
 * @author Craig Poirier
 * @see CSS_ShareRecordService, CSS_ShareRecordBatch, CSS_Utility
 */
public without sharing class CSS_ShareRecordScheduler implements Schedulable {


  /**
   * No argument, default constructor for this Customer Self Service Community record sharing
   * schedulable class. 
   */
  public CSS_ShareRecordScheduler() { }

  /**
   * Execute the Customer Self Service batch executable class instance. This method is required
   * for schedulable classes.  Use this method to schedule a community share reconciliation
   *
   * @param SchedulableContext information about the schedulable environment
   */
  public void execute(SchedulableContext sc) {
    setUsersDirty(); // label applicable community users dirty
    CSS_ShareRecordBatch.reconcile(); // with caution is not necessary
  }

  /**
   * Returns the last modified date to use when search for modified users. This value will default
   * to the last 24 hours if a value is not specified in custom settings
   *
   * return last modified date to use when search for modified users
   */
  @TestVisible 
  private static void setUsersDirty(){
    try {

      // Using a map gets rid of duplicate users
      Map<Id,User> users = new Map<Id,User>();
      users.putAll(findUsersByPermission());
      users.putAll(findUsersByLastModified());
      System.debug(LoggingLevel.INFO, 'CSS_ShareRecordScheduler - Setting Users Dirty: ' + users);
      
      // Loop through users and set dirty flag
      for (User usr : users.values()) {
        usr.Community_Dirty_Flag__c = true;
      }
      update users.values();
    }
    catch (Exception ex) {
      CSS_Utility.logError('CSS_ShareRecordScheduler - Unable to Mark Community Users Dirty. ', ex);
    }
  }


  /** 
   * Find recently modified users by looking at recently modified permission set assignments.
   *
   * @param list of community user ids for users that have been recently added to permissions sets
   */
  @TestVisible 
  private static List<User> findUsersByPermission() {
    
    // First, find the proper date filter to use
    datetime filterDate = getFilterDate();
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordScheduler - Finding Users By Permission: ' +
      'using the following date filter: ' + filterDate);
    
    // Second, find list of users with new permissions
    return [SELECT Name FROM USER WHERE Id IN (SELECT AssigneeId
      FROM PermissionSetAssignment
      WHERE Assignee.isActive = true 
        AND Assignee.Profile.UserLicense.Name = :CSS_Utility.PARTNER_LICENSES
        AND SystemModstamp > :filterDate)];
  }

  /** 
   * Find recently modified users by looking at recently modified timestamps on user records.
   *
   * @param list of community user ids for users that have been recently modified
   */
  @TestVisible 
  private static List<User> findUsersByLastModified() {
    
    // First, find the proper date filter to use
    datetime filterDate = getFilterDate();
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordScheduler - Finding Users By Last Modified: ' +
      'using the following date filter: ' + filterDate);
    
    // Second, find list of recently modified users
    return [SELECT Name FROM User
      WHERE isActive = true 
        AND Profile.UserLicense.Name = :CSS_Utility.PARTNER_LICENSES
        AND LastModifiedDate > :filterDate];
  }


  /**
   * Returns the last modified date to use when search for modified users. This value will default
   * to the last 24 hours if a value is not specified in custom settings
   *
   * return last modified date to use when search for modified users
   */
  @TestVisible 
  private static datetime getFilterDate(){
    try {
      Parameter__c parameter = Parameter__c.getValues('CSS_RecordShareDayRange');
      if ((parameter <> null) && (!String.isEmpty(parameter.Parameter_Value__c))) {
        Integer days = -1 * Integer.valueOf(parameter.Parameter_Value__c);
        return System.now().addDays(days);
      }
    }
    catch (Exception ex) {
      CSS_Utility.logError('CSS_ShareRecordScheduler - Invalid Day Range Specified. ' +
        'Please update the following custom setting: Parameter__c.CSS_RecordShareDayRange.', ex);
    }
    return System.now().addDays(-1); // default to the last 24 hours
  }

}