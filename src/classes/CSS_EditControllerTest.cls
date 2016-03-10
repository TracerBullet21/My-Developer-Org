/**
 * Customer Self Service Community test controller for the edit page controller. This test class
 * will verify the creating or updating of records.
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_BaseController
 */
@isTest
private class CSS_EditControllerTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class. 
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createTestData();
  }

  /** 
   * Test the creation of a new record, using default query parameters 
   */
  @isTest static void testSaveWithNewRecord() {
    Opportunity opp = [SELECT Name FROM Opportunity WHERE Oppty_External_ID__c = 'css-data-opportunity-0'];

    // Configure query parameters, which should be passed in
    PageReference pageRef = Page.css_opportunity_detail;
    pageRef.getParameters().put('contractor_po_number__c','css-default-invoice-0');
    pageRef.getParameters().put('recordTypeId', '012i00000011WNVAA2'); // lowe's detail (won't change)
    pageRef.getParameters().put('opportunity__c', opp.id); // lowe's detail (won't change)
    Test.setCurrentPage(pageRef);

    // Create a new invoice and verify the passed in query parameters are set
    Test.startTest();
    ApexPages.StandardController stdController = new ApexPages.StandardController(new Invoice__c());
    CSS_EditController controller = new CSS_EditController(stdController);
    controller.save();

    // The passed in parameters should be set in the saved invoice
    Invoice__c invoice = [SELECT recordTypeId FROM Invoice__c WHERE Contractor_PO_Number__c = 'css-default-invoice-0' LIMIT 1];
    System.assertEquals('012i00000011WNVAA2', String.valueOf(invoice.recordTypeId));
    Test.stopTest();
  }


  /** 
   * Tesst the querying of records using bad setting (i.e., you should get a blank list)
   */
  @isTest static void testSetDefaultsWithError() {
    PageReference pageRef = Page.css_opportunity_detail;
    pageRef.getParameters().put('COC_Form_Submitted__c', 'fase'); // booleans are not supported
    Test.setCurrentPage(pageRef);

    // Create a new invoice and verify the passed in query parameters were not set due to an error
    Test.startTest();
    try {
      ApexPages.StandardController stdController = new ApexPages.StandardController(new Invoice__c());
      CSS_EditController controller = new CSS_EditController(stdController); 
      System.assert(false, 'Code execution should not reach this point due to an expected thrown exception.');
    }
    catch (Exception ex) { // booleans are not supported
      System.assert(String.isNotBlank(ex.getMessage()), 'Expecting an error message due to thrown exception.');
    }    
    Test.stopTest();
  }

  /** 
   * Tesst the querying of records using bad setting (i.e., you should get a blank list)
   */
  @isTest static void testSaveWithError() {
    PageReference pageRef = Page.css_opportunity_detail;
    Test.setCurrentPage(pageRef);

    // Create a new invoice and verify the passed in query parameters were not set due to an error
    Test.startTest();
   
    ApexPages.StandardController stdController = new ApexPages.StandardController(new Invoice__c());
    stdController.getRecord().put('RecordTypeId','012i00000011WNWAA2'); // Lowe's Job requires COC Form
    stdController.getRecord().put('COC_Form_Submitted__c', false); // COC Form Submitted is Required
    CSS_EditController controller = new CSS_EditController(stdController);
    controller.save();
   
    System.assert(!controller.getPageMessages().isEmpty(), 'Expecting an error message due to thrown exception.');
    Test.stopTest();
  }

  /** 
   * Tesst the querying of records using bad setting (i.e., you should get a blank list)
   */
  @isTest static void testCancel() {
    PageReference pageRef = Page.css_invoice_detail;
    pageRef.getParameters().put('retUrl', '/css_invoice_detail');
    Test.setCurrentPage(pageRef);

    // Create a new invoice and verify the cancel goes back to the appropriate page
    Test.startTest();
    ApexPages.StandardController stdController = new ApexPages.StandardController(new Invoice__c());
    CSS_EditController controller = new CSS_EditController(stdController);
    System.assertEquals('/css_invoice_detail', controller.cancel().getUrl()); 
    Test.stopTest();
  }

 
}