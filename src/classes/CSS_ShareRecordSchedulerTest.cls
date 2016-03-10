/**
 * Test class for the Customer Self Service Community Record Scheduler class. 
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_ShareRecordScheduler
 */
@isTest
private class CSS_ShareRecordSchedulerTest {

  /**
   * CRON expression: midnight on March 15. Because this is a test, job executes immediately 
   * after Test.stopTest(). 
   */
  public static String CRON_EXPRESSION = '0 0 0 15 3 ? 2022';


  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createCommunityUsers();
  }

  /** 
   * Test Share Record Scheduler as a schedulable class, which finds and marks dirty users and
   * kicks off the share record batch.
   */
   static testmethod void testExecute() {
    Test.startTest();

    // Schedule the test job and get the information from the CronTrigger API object
    String jobId = System.schedule('CSS_ShareRecordSchedulerTest', CRON_EXPRESSION, 
      new CSS_ShareRecordScheduler());
    CronTrigger cTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
      FROM CronTrigger WHERE id = :jobId];
   
    // Verify the expressions are the same
    System.assertEquals(CRON_EXPRESSION, cTrigger.CronExpression);

    // Verify the job has not run
    System.assertEquals(0, cTrigger.TimesTriggered);

    // Verify the next time the job will run
    System.assertEquals('2022-03-15 00:00:00', String.valueOf(cTrigger.NextFireTime));
    
    // Verify the scheduled job hasn't run yet.
    User usr = CSS_TestDataFactory.getCommunityUser();
    System.assertEquals(false, usr.Community_Dirty_Flag__c);
    Test.stopTest();

    // Verify the scheduled job executed
    usr = CSS_TestDataFactory.getCommunityUser();
    System.assertEquals(true, usr.Community_Dirty_Flag__c);
  }

  /** 
   * Test the finding of dirty users by looking at last modified.
   */
  @isTest static void testFindUsersByLastModified() {
    Test.startTest();

    // The test setup method setup just created a new user
    List<User> users = CSS_ShareRecordScheduler.findUsersByLastModified();
    System.assert(!users.isEmpty(), 'Expected non-empty user list');
    Test.stopTest();
  }
 
  /** 
   * Test the finding of dirty users by looking who has been added to a permission recently.
   */
  @isTest static void testFindUsersByPermission() {
    Test.startTest();

    // The test setup method setup just created a new permission for these new users
    List<User> users = CSS_ShareRecordScheduler.findUsersByPermission();
    System.assert(!users.isEmpty(), 'Expected non-empty user list');
    Test.stopTest();
  }

  /** 
   * Test the retrieval of getting the filter date (i.e., how far back do you go to find dirty
   * users).
   */
  @isTest static void testGetFilterDate() {
    Test.startTest();

    // Test the default retrieval date, which should be a day
    datetime dt = CSS_ShareRecordScheduler.getFilterDate();
    System.assert((dt <= System.now().addHours(-16)) && (dt >= System.now().addHours(-32)), 
      'Expected a date around a day old; date received: ' + dt + '.');

    // Test the configurable retrieval date, which should be any day you want
    Parameter__c parameter = new Parameter__c (Name = 'CSS_RecordShareDayRange',
      Parameter_Key__c = 'CSS_RecordShareDayRange', Parameter_Value__c = '3');
    insert parameter;
    dt = CSS_ShareRecordScheduler.getFilterDate();
    System.assert((dt <= System.now().addDays(-2)) && (dt >= System.now().addDays(-4)), 
      'Expected a date around three days old; date received: ' + dt + '.');
    delete parameter;

    // Test with a bad configurable retrieval date, which should default to a day
    parameter = new Parameter__c (Name = 'CSS_RecordShareDayRange',
      Parameter_Key__c = 'CSS_RecordShareDayRange', Parameter_Value__c = 'BAD');
    insert parameter;
    dt = CSS_ShareRecordScheduler.getFilterDate();
    System.assert((dt <= System.now().addHours(-16)) && (dt >= System.now().addHours(-32)), 
      'Expected a date around a day old; date received: ' + dt + '.');

    Test.stopTest();
  }

}