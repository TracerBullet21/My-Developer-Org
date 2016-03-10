/**
 * Test class for the Customer Self Service Community Record Sharing Service class. 
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_ShareRecordBatch
 */
@isTest
private class CSS_ShareRecordServiceTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createCommunityUsers();
  }

 /** 
   * Test generation of a unique key for object record shares. These keys are used to identify unique 
   * shares that already existing in the database to prevent to many DML statements.
   */
  @isTest static void testGetShareKey() {
    User usr = CSS_TestDataFactory.getCommunityUser();

    SAP_Invoice__Share iShare = new SAP_Invoice__Share(
      ParentId = usr.Id,
      UserOrGroupId = usr.Id,
      AccessLevel = CSS_ShareRecordService.ACCESS_LEVEL_READ,
      RowCause = Schema.SAP_Invoice__Share.RowCause.Account_Payer__c);

    CaseShare cShare = new CaseShare(
      CaseId = usr.Id,
      UserOrGroupId = usr.Id,
      CaseAccessLevel = CSS_ShareRecordService.ACCESS_LEVEL_READ,
      RowCause = Schema.CaseShare.RowCause.Manual);

    Test.startTest();
    System.assertNotEquals(CSS_ShareRecordService.getShareKey(iShare), 
      CSS_ShareRecordService.getShareKey(cShare));
    Test.stopTest();
  }


  /** 
   * Test generation of a query locator query string for orders, SAP invoices, and cases. Also,
   * test with an invalid sObjectType, which is not in the process today.
   */
  @isTest static void testShareOrders() {

    // First, get an example user and order to test with
    User usr = CSS_TestDataFactory.getCommunityUser();
    Order__c order = [SELECT Name, Ship_To_Name__c,Sold_to_Account__c 
      FROM Order__c WHERE Order_Number__c = '123456789' LIMIT 1];

    Test.startTest();

    // Erase all sharing related to example order
    List<Order__Share> shares = [SELECT Id FROM Order__Share WHERE ParentId = :order.Id
      AND RowCause = :CSS_ShareRecordService.ORDER_ROW_CAUSES];
    delete shares;

    // Verify order shares have been deleted
    shares = [SELECT Id FROM Order__Share WHERE ParentId = :order.Id
      AND RowCause = :CSS_ShareRecordService.ORDER_ROW_CAUSES];
    System.assert(shares.isEmpty(), 'Expecting an empty list of shares.');

    // Share the example order with the test user
    CSS_ShareRecordService.shareOrders(new List<Order__c> {order});

    // Verify order shares have been added for given user
    shares = [SELECT Id FROM Order__Share WHERE ParentId = :order.Id
      AND RowCause = :CSS_ShareRecordService.ORDER_ROW_CAUSES
      AND UserOrGroupId = :usr.Id]; // looking for specific shares for our user
    System.assert(!shares.isEmpty(), 'Expecting a user share record for test user.');

    Test.stopTest();
  }


  /** 
   * Test generation of a query locator query string for orders, SAP invoices, and cases. Also,
   * test with an invalid sObjectType, which is not in the process today.
   */
  @isTest static void testShareSAPInvoices() {

    // First, get an example user and invoice to test with
    User usr = CSS_TestDataFactory.getCommunityUser();
    SAP_Invoice__c invoice = [SELECT Name, Bill_To_Account__c, Sold_To_Party__c, Payer_Account__c, Ship_To_Party__c 
      FROM SAP_Invoice__c WHERE Invoice_Number__c = '123456789' LIMIT 1];

    Test.startTest();

    // Erase all sharing related to example invoice
    List<SAP_Invoice__Share> shares = [SELECT Id FROM SAP_Invoice__Share WHERE ParentId = :invoice.Id
      AND RowCause = :CSS_ShareRecordService.SAP_INVOICE_ROW_CAUSES];
    delete shares;

    // Verify invoice shares have been deleted
    shares = [SELECT Id FROM SAP_Invoice__Share WHERE ParentId = :invoice.Id
      AND RowCause = :CSS_ShareRecordService.SAP_INVOICE_ROW_CAUSES];
    System.assert(shares.isEmpty(), 'Expecting an empty list of shares.');

    // Share the example invoice with the test user
    CSS_ShareRecordService.shareSAPInvoices(new List<SAP_Invoice__c> {invoice});

    // Verify invoice shares have been added for given user
    shares = [SELECT Id FROM SAP_Invoice__Share WHERE ParentId = :invoice.Id
      AND RowCause = :CSS_ShareRecordService.SAP_INVOICE_ROW_CAUSES
      AND UserOrGroupId = :usr.Id]; // looking for specific shares for our user
    System.assert(!shares.isEmpty(), 'Expecting a user share record for test user.');

    Test.stopTest();
  }


  /** 
   * Test generation of a query locator query string for orders, SAP invoices, and cases. Also,
   * test with an invalid sObjectType, which is not in the process today.
   */
  @isTest static void testShareCases() {

    // First, get an example user and complaint to test with
    User usr = CSS_TestDataFactory.getCommunityUser();
    Case complaint = [SELECT CaseNumber, AccountId, RecordTypeId 
      FROM Case WHERE Case_External_ID__c = '123456789' LIMIT 1];

    Test.startTest();

    // Erase all sharing related to example complaint
    List<CaseShare> shares = [SELECT Id FROM CaseShare WHERE CaseId = :complaint.Id
      AND RowCause = :CSS_ShareRecordService.CASE_ROW_CAUSES];
    delete shares;

    // Verify complaint shares have been deleted
    shares = [SELECT Id FROM CaseShare WHERE CaseId = :complaint.Id
      AND RowCause = :CSS_ShareRecordService.CASE_ROW_CAUSES];
    System.assert(shares.isEmpty(), 'Expecting an empty list of shares.');

    // Share the example complaint with the test user
    CSS_ShareRecordService.shareCases(new List<Case> {complaint});

    // Verify complaint shares have been added for given user
    shares = [SELECT Id FROM CaseShare WHERE CaseId = :complaint.Id
      AND RowCause = :CSS_ShareRecordService.CASE_ROW_CAUSES
      AND UserOrGroupId = :usr.Id]; // looking for specific shares for our user
    System.assert(!shares.isEmpty(), 'Expecting a user share record for test user.');

    Test.stopTest();
  }
 
}