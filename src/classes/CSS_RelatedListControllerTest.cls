/**
 * The Customer Self Service Community Related List Page test controller class verifies basic set
 * controller functionality for related lists
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_RelatedListController 
 */
@isTest
private class CSS_RelatedListControllerTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createTestData();
  }

  /** 
   * Test the generation of a basic field set
   */
  @isTest static void testGetFieldSet() {
    CSS_RelatedListController controller = new CSS_RelatedListController();
    controller.objectType = 'Invoice__c';
    controller.fieldSetName = 'Community_Invoice_List_View';

    // Verify the request field set was created
    CSS_FieldSetUtility.FieldSet fldSet = controller.getFieldSet();
    System.assert(!fldSet.fields.isEmpty(), 'Expecting a non-empty field set for the Invoice__c object.');
  }

  /** 
   * Test the generation of child records that can be used in a related list
   */
  @isTest static void testGetRecords() {
    CSS_RelatedListController controller = new CSS_RelatedListController();
    Opportunity opp = [SELECT Name FROM Opportunity WHERE Oppty_External_ID__c = 'css-data-opportunity-0' LIMIT 1];

    // Components assign controller variables by using assignTo
    controller.parentId = opp.Id;
    controller.parentField = 'Opportunity__c';
    controller.objectType = 'Invoice__c';
    controller.fieldSetName = 'Community_Invoice_List_View';

    // Query for children invoices of the set parent opportunity
    Test.startTest();
    List<SObject> records = controller.getRecords();
    System.assert(!records.isEmpty(), 'Expecting a non-empty set of invoice records.');
    Test.stopTest();
  }

  /** 
   * Tesst the querying of records using bad setting (i.e., you should get a blank list)
   */
  @isTest static void testGetRecordsWithError() {
    CSS_RelatedListController controller = new CSS_RelatedListController();
  
    // Components assign controller variables by using assignTo
    controller.parentField = 'Invalid__c';
    controller.objectType = 'Invoice__c';
    controller.fieldSetName = 'Community_Invoice_List_View';

    // Query for children invoices of the set parent opportunity
    Test.startTest();
    List<SObject> records = controller.getRecords();
    System.assert(records.isEmpty(), 'Expecting an empty set of invoice records.');
    Test.stopTest();
  }

  /** 
   * Test the deleting of a child record with an attachment.
   */
  @isTest static void testDeleteRecord() {
    CSS_RelatedListController controller = new CSS_RelatedListController();
    Opportunity opp = [SELECT Name FROM Opportunity WHERE Oppty_External_ID__c = 'css-data-opportunity-0' LIMIT 1];

    // Components assign controller variables by using assignTo
    controller.parentId = opp.Id;
    controller.parentField = 'Opportunity_R__c';
    controller.objectType = 'Attachment_JM_Obj__c';
    controller.fieldSetName = 'Community_Attachment_Note_List_View';

    // Query for children invoices of the set parent opportunity
    Test.startTest();
    List<SObject> records = controller.getRecords();
    System.assert(!records.isEmpty(), 'Expecting a non-empty set of atttachment records.');
  
    // Test deleteing an invoice with attachment
    controller.recordId = records[0].Id;
    controller.deleteRecord();
    Test.stopTest();
  }

  /** 
   * Test the generation of a basisc edit page URL, which does not contain the id query parameter.
   */
  @isTest static void testGetEditPageURL() {
    CSS_RelatedListController controller = new CSS_RelatedListController();
    controller.objectType = 'Invoice__c';
    System.assertEquals('/css_invoice_edit', controller.getEditPageURL());
  }
}