/**
 * Test the Account Summary Service for the Customer Self Service Community.
 *
 * @author Craig Poirier
 * @version 1.0   
 * @see CSS_AccountSummaryService, CSS_CommunityService
 */
@isTest
private class CSS_AccountSummaryServiceTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class. This test class requires trigger bypasses and a community partner user.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createCommunityUsers();
  }

  /** 
   * Test retrieval of account summary information using the CSS_AccountSummaryService service 
   * class.
   */
  @isTest static void testRetrieval() {
    Test.startTest();
  
    // Configure test data on the user's accont
    Account account = [SELECT id FROM Account WHERE name = 'css-test-account-0'];
    account.Revenue_YTD_Net__c = 512.12;
    update account;

    // Verify the community partner user can see his or her account summary
    System.runAs(CSS_TestDataFactory.getCommunityUser()) {
      CSS_AccountSummaryService.AccountSummary summary = CSS_AccountSummaryService.getAccountSummary();
      System.assertEquals('512',summary.ytdNetRevenue);
    } 
    Test.stopTest();
  }

  /** 
   * Test retrieval of account summary information using a invalid user. The method should throw
   * a Customer Self Service Community Exception because the invalid user used is not a community
   * user.
   */
  @isTest static void testRetrievalWithInvalidUser() {
    Test.startTest();

    // Use an admin user as the internal user to get an error 
    System.runAs(CSS_TestDataFactory.getAdminUser()) {
      try { // an exception should be thrown since this is not a community user
        CSS_AccountSummaryService.AccountSummary summary = CSS_AccountSummaryService.getAccountSummary();
        System.assert(false, 'This statement should never be reached due to an expected thrown exception.');
      }
      catch (CSS_Exception csse) {
        System.assertEquals(csse.getMessage(), CSS_AccountSummaryService.MESSAGE_INVALID_USER);
      }
    } 
    Test.stopTest();
  }

}