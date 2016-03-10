/**
 * Test class for the Customer Self Service Community, which tests functionality provided by the
 * Utility class 
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_UtilityTest
 */
@isTest
private class CSS_UtilityTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
  }

  /** 
   * Test logging errors, using both the straight error message version and the method that
   * takes an exception.
   */
  @isTest static void testLogError() {
    CSS_Utility.logError('Test Error');
    CSS_Utility.logError('Test Error', new CSS_Exception('Test Exception'));
  }

  /** 
   * Test the generation of a detail page given a specific object
   */
  @isTest static void testGetDetailPage() {
    
    // Leverage an opportunity from the test set of opportunities
    Opportunity opp = new Opportunity(); // [SELECT Name FROM Opportunity WHERE Oppty_External_ID__c = 'css-data-opportunity-0'];
    ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
    System.assertEquals('/css_opportunity_detail?id=null', CSS_Utility.getDetailPage(stdController));
  }
}