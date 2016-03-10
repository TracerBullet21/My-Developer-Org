/**
 * The Customer Self Service Base Controller test class verifies that functionality provided by
 * the CSS_BaseController class, which is a parent controller class for CSS Community Visualforce 
 * children controllers.
 *
 * Overall, this parent class provides return URL functionality, database modification
 * language (DML) error handing functionaly, ...
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_BaseController, CSS_ListController
 */
@isTest
private class CSS_BaseControllerTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createTestData();
  }
    
  /** 
   * Test retrieval of community alerts using the CSS_AnnouncementService class
   */
  @isTest static void testRedirectWithCustomController() {
    
    // Verify return URL has been set with given URL
    PageReference pageRef = Page.css_opportunity_detail;
    pageRef.getParameters().put('retURL', 'http://www.test.com');
    Test.setCurrentPage(pageRef);
    CSS_BaseController controller = new CSS_BaseController();
    System.AssertEquals('http://www.test.com', controller.getRedirect().getURL()); 

    // Verify return URL has been set with home page (default URL)
    Test.setCurrentPage(Page.css_case_detail);
    controller = new CSS_BaseController();
    System.AssertEquals(Page.css_home.getURL(), controller.getRedirect().getURL()); 
  }

  /** 
   * Test retrieval of community alerts using the CSS_AnnouncementService class
   */
  @isTest static void testRedirectWithControllerExtension() {
    
    // Leverage an opportunity from the test set of opportunities
    Opportunity opp = [SELECT Name FROM Opportunity WHERE Oppty_External_ID__c = 'css-data-opportunity-0'];
    ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
    
    // Verify return URL has been set with given URL
    PageReference pageRef = Page.css_opportunity_detail;
    pageRef.getParameters().put('retURL', 'http://www.test.com');
    pageRef.getParameters().put('id',opp.id);
    Test.setCurrentPage(pageRef);
    CSS_BaseController controller = new CSS_BaseController(stdController);
    System.AssertEquals('http://www.test.com', controller.getRedirect().getURL()); 

    // Verify return URL has been set with detail page (default URL for standard controllers)
    Test.setCurrentPage(Page.css_case_detail);
    controller = new CSS_BaseController(stdController);
    System.AssertEquals('/css_opportunity_detail?id=' + opp.id, controller.getRedirect().getURL()); 
  }  

  /** 
   * Test retrieval of community alerts using the CSS_AnnouncementService class
   */
  @isTest static void testPageErrors() {
    
    // Verify return URL has been set with given URL
    Test.setCurrentPage(Page.css_opportunity_detail);
    CSS_BaseController controller = new CSS_BaseController();
    System.Assert(controller.getPageMessages().isEmpty(), 'Expected an empty list of messages'); 
    
    try { // generate a DML Exception for testing page errors.
      Opportunity badOpp = new Opportunity(Name = 'Bad Opportunity');
      update badOpp;
    }
    catch (DmlException dmle) {
      controller.addDMLErrorsToPage(dmle);
    }
    System.AssertEquals('ERROR', controller.getPageMessages()[0].severity); 
   }

}