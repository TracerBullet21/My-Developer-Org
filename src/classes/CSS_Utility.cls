/**
 * Utility class for Customer Self Service Community functionality. Methods in this utility class 
 * can return exceptions, so please double check error handling when calling these methods.
 * 
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_UtilityTest
 */
public without sharing class CSS_Utility {

  /** Parnter user licenses for the Customer Self Service Community  */
  public static final List<String> PARTNER_LICENSES = new List<String> {'Partner Community'};

  /** 
   * Set to true if DML operations are allowed (i.e., DML is allowed in page controllers, but not
   * allowed in constructors or getters and setters). 
   */
  public static Boolean allowDML = true;


  /**
   * This method logs an error message to both the Apex debug logs and the integration log, which
   * is used globally for errors and messages.  Warning: this method is not bulkified. Only use 
   * this method when processing has stopped due to an issue or error. Do not call this method 
   * within a loop!
   *
   * @param msg error message
   * @param error the exception thrown
   */
  public static void logError(String msg, Exception error) {
    System.debug(LoggingLevel.ERROR, msg + '::' + error.getMessage());
    System.debug(LoggingLevel.ERROR, error.getStackTraceString());
    
    if (allowDML) { // only insert into the database if DML is allowed
      try {

        // Allows all fields to be truncated (i.e., its an error log)
        Database.DMLOptions options = new Database.DMLOptions();
        options.allowFieldTruncation = true;

        // Log the error to the Salesforce database
        Error_Log__c log = new Error_Log__c();
        log.Error_Text__c = msg + ' System Message: ' + error.getMessage() + 
          ' Stack Trace: ' + error.getStackTraceString();
        log.Logging_Step__c = error.getLineNumber() == null ? '' : 
          String.valueOf(error.getLineNumber());
        Database.insert(log, options);
      }
      catch (Exception ex) {
        System.debug(LoggingLevel.ERROR, 'CSS_Utility - Failed to Update Error Log: ' + ex.getMessage());
        System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
      }
    }
  }

 /**
   * This method logs an error message to both the Apex debug logs and the integration log, which
   * is used globally for errors and messages.  Warning: this method is not bulkified. Only use 
   * this method when processing has stopped due to an issue or error. Do not call this method 
   * within a loop!
   *
   * @param msg error message
   */
  public static void logError(String msg) {
    System.debug(LoggingLevel.ERROR, msg);
    
    if (allowDML) { // only insert into the database if DML is allowed
      try {

        // Allows all fields to be truncated (i.e., its an error log)
        Database.DMLOptions options = new Database.DMLOptions();
        options.allowFieldTruncation = true;

        // Log the error to the Salesforce database
        Error_Log__c log = new Error_Log__c();
        log.Error_Text__c = msg;
        Database.insert(log, options);
      }
      catch (Exception ex) {
        System.debug(LoggingLevel.ERROR, 'CSS_Utility - Failed to Update Error Log: ' + ex.getMessage());
        System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
      }
    }
  }

  /** 
   * Generate a relative detail page url given an object's controller
   *
   * @param relative url to an object's detail page
   */
  public static String getDetailPage(ApexPages.StandardController controller) {
    return Site.getPathPrefix() + '/css_' + controller.getRecord().getSObjectType().
      getDescribe().getName().removeEndIgnoreCase('__c').toLowerCase() + '_detail?id=' + 
      controller.getRecord().Id;
  }

}