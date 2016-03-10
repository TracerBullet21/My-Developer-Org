/**
 * The Customer Self Service Community Detail Section Test Controller verifies functionality
 * provided by the CSS_DetailSectionController class
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_DetailSectionController
 */
@isTest
private class CSS_DetailSectionControllerTest {
    
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
    CSS_DetailSectionController controller = new CSS_DetailSectionController();
    controller.objectType = 'Invoice__c';
    controller.fieldSetName = 'Community_Invoice_Detail_Info_LD'; // set to a valid field set for Invoice__c

    // Verify the request field set was created
    CSS_FieldSetUtility.FieldSet fldSet = controller.getFieldSet();
    System.assert(!fldSet.fields.isEmpty(), 'Expecting a non-empty field set for the Invoice__c object.');
  }

  /** 
   * Test the generation of child records that can be used in a related list
   */
  @isTest static void testGetRecord() {
    CSS_DetailSectionController controller = new CSS_DetailSectionController();
    Opportunity opp = [SELECT Name FROM Opportunity WHERE Oppty_External_ID__c = 'css-data-opportunity-0' LIMIT 1];

    // Components assign controller variables by using assignTo
    controller.recordId = opp.Id;
    controller.objectType = 'Opportunity';
    controller.fieldSetName = 'Community_Opportunity_Key_Detail_LJD';

    // Query for children invoices of the set parent opportunity
    Test.startTest();
    Opportunity result = (Opportunity) controller.getRecord();
    System.assertEquals(opp.Id, result.Id);
    Test.stopTest();
  }

  /** 
   * Tesst the querying of records using bad setting (i.e., you should get a blank list)
   */
  @isTest static void testGetRecordsWithError() {
    CSS_DetailSectionController controller = new CSS_DetailSectionController();
  
    // Components assign controller variables by using assignTo
    controller.objectType = 'Invalid__c';
    controller.fieldSetName = 'Community_Invalid_Detail';

    // Query for children invoices of the set parent opportunity
    Test.startTest();
    try {
      SObject record = controller.getRecord();
      System.Assert(true, 'This line of code should not be reached due to expected thrown exception.');
    }
    catch (CSS_Exception csse) {
      System.Assert(csse.getMessage().contains(System.Label.CSS_Default_Error_Message),
       'Expecting a Customer Community Exception with default error message');
    }
    Test.stopTest();
  }

}