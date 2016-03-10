/**
 * The Customer Self Service Community List Page controller test class provides verification of
 * functionality provided by CSS_ListController class.
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_SetController
 */
@isTest
private class CSS_ListControllerTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createTestData();
  }

  /** 
   * Test the loading of the search page
   */
  @isTest static void testInitialization() {

    // Use the default object type as a test type (i.e., opportunity)
    PageReference pageRef = Page.css_community_list;
    Test.setCurrentPage(pageRef);
    CSS_ListController controller = new CSS_ListController();
    System.assertEquals('Opportunity', controller.objectType);
    System.assertEquals('CreatedDate', controller.defaultDate);
    
    // Generate the standard controller and edit attachment controller
    Test.startTest();
    controller.search();
    List<sObject> records = controller.getRecords();
    System.assert(!records.isEmpty(), 'Expecting a non-empty list of records');
    Test.stopTest();

    // Use opportunity as a test type
    pageRef.getParameters().put('type', 'Opportunity');
    Test.setCurrentPage(pageRef);
    controller = new CSS_ListController();
    System.assertEquals('Opportunity', controller.objectType);
    System.assertEquals('CreatedDate', controller.defaultDate);

    // Use Case as a test type
    pageRef.getParameters().put('type', 'Case');
    Test.setCurrentPage(pageRef);
    controller = new CSS_ListController();
    System.assertEquals('Case', controller.objectType);
    System.assertEquals('CreatedDate', controller.defaultDate);

    // Use Order__c as a test type
    pageRef.getParameters().put('type', 'Order__c');
    Test.setCurrentPage(pageRef);
    controller = new CSS_ListController();
    System.assertEquals('Order__c', controller.objectType);
    System.assertEquals('PO_Date__c', controller.defaultDate);

    // Use SAP_Invoice__c as a test type
    pageRef.getParameters().put('type', 'SAP_Invoice__c');
    Test.setCurrentPage(pageRef);
    controller = new CSS_ListController();
    System.assertEquals('SAP_Invoice__c', controller.objectType);
    System.assertEquals('Invoice_Date__c', controller.defaultDate);
 
    // Use an invalid objet type as a test type
    pageRef.getParameters().put('type', 'Bad_Type__c');
    Test.setCurrentPage(pageRef);
    try {
      controller = new CSS_ListController();
      System.assert(false, 'Code execution should not reach this point due to an expected thrown exception.');
    }
    catch (Exception ex) {
      System.assert(String.isNotBlank(ex.getMessage()), 'Expecting an error message due to thrown exception.');
    }
 }

  /** 
   * Test the loading of the search page
   */
  @isTest static void testSOSLSearch() {

    // Use opportunity as a test type (setup method should create opportunities)
    PageReference pageRef = Page.css_opportunity_detail;
    pageRef.getParameters().put('type', 'Opportunity');
    Test.setCurrentPage(pageRef);
    CSS_ListController controller = new CSS_ListController();
    System.assertEquals('Opportunity', controller.objectType);
    System.assertEquals('CreatedDate', controller.defaultDate);
    
    // Generate the standard controller and edit attachment controller
    Test.startTest();

    // Test with a valid key word search
    controller.keys = 'css-data-opportunity-0';
    controller.search();
    List<sObject> records = controller.getRecords();
    System.assert(records <> null, 'Expecting a list of records');

    Test.stopTest();
  }

  /** 
   * Test the loading of the search page
   */
  @isTest static void testClear() {

    // Use the default object type as a test type (i.e., opportunity)
    PageReference pageRef = Page.css_community_list;
    Test.setCurrentPage(pageRef);
    pageRef.getParameters().put('type', 'Opportunity');
    CSS_ListController controller = new CSS_ListController();
    System.assertEquals('Opportunity', controller.objectType);
    System.assertEquals('CreatedDate', controller.defaultDate);
    
    // Generate the standard controller and edit attachment controller
    Test.startTest();
    controller.keys = 'VERYBADKEYVERYBADKEY'; // key should be cleared!
    controller.clear();
    List<sObject> records = controller.getRecords();
    System.assert(!records.isEmpty(), 'Expecting a non-empty list of records');
    Test.stopTest();
 }

}