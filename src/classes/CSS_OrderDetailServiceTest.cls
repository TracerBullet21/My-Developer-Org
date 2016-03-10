/**
 * Order line item details service test class for the customer self service community test the 
 * services offered by the CSS_OrderDetailService and JM_OrderDetailService classes.
 *
 * This test class implments the WebServiceMock interface to instruct the Apex runtime engine to 
 * generate a fake response whenever WebServiceCallout.invoke is called. This class is public to
 * allow other test methods to use it's mock web service. 
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_OrderDetailService
 */
@isTest
public class CSS_OrderDetailServiceTest implements WebServiceMock {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class. For this test class, we just need to bypass triggers and validations.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true); // bypass triggers and validations
  }

  /** 
   * Test retrieval of SAP order line items (i.e., details) using a mock web service.
   */
  @isTest static void testGetOrderDetail() {
    Test.setMock(WebServiceMock.class, new CSS_OrderDetailServiceTest());

    Test.startTest();
    CSS_OrderDetailService.OrderDetail detail = 
      CSS_OrderDetailService.getOrderDetail('0911111111');

    // Validate each line item field
    System.assertEquals('90021834',detail.lineItemsList[0].material);
    System.assertEquals('MW316 SAFB 3x16x48',detail.lineItemsList[0].materialDescription);
    System.assertEquals('',detail.lineItemsList[0].customerMaterialNumber);
    System.assertEquals('184.42',detail.lineItemsList[0].invoicePrice);
    System.assertEquals('MSF',detail.lineItemsList[0].invoicePriceUOM);
    System.assertEquals('USD',detail.lineItemsList[0].invoicePriceCurrency);
    System.assertEquals('512',detail.lineItemsList[0].orderQuantity); // rounded
    System.assertEquals('FT2',detail.lineItemsList[0].orderUOM);
    System.assertEquals('0.36',detail.lineItemsList[0].orderUnitPrice);
    System.assertEquals('9/18/2015',detail.lineItemsList[0].requestedDeliveryDate);
    System.assertEquals('9/19/2015',detail.lineItemsList[0].confirmedDeliveryDate);
    System.assertEquals('9/20/2015',detail.lineItemsList[0].pricingDate);
    System.assertEquals(null,detail.lineItemsList[0].plant); // null is still null
    System.assertEquals('360.20',detail.lineItemsList[0].netPrice);
    System.assertEquals('Completely processed',detail.lineItemsList[0].status);

    Test.stopTest();
  }

  /** 
   * Test the linking of order line items to SAP invoice line items
   */
  @isTest static void testGetOrderDetailLinking() {
    Test.setMock(WebServiceMock.class, new CSS_OrderDetailServiceTest());
    
    // Create a fake invoice so that each order line item can link to it
    SAP_Invoice__c invoice = new SAP_Invoice__c (Name='test-invoice', Invoice_Number__c='0901124932');
    insert invoice;

    Test.startTest();
    CSS_OrderDetailService.OrderDetail detail = 
      CSS_OrderDetailService.getOrderDetail('0911111111');

    // Validate SAP invoice linking was configured correctly
    System.assert(detail.lineItemsList[0].invoiceLinks[0].path.contains('css_sap_invoice_detail?id='),
      'Order line item does not contain expected SAP invoice link.');
    Test.stopTest();
  }

  /** 
   * Test that the proper error message is displayed when the service is down
   */
  @isTest static void testGetOrderDetailWithError() {
    Test.startTest();
    try {
      CSS_OrderDetailService.OrderDetail detail = 
        CSS_OrderDetailService.getOrderDetail('0911111111');
      System.assert(false,'Code execution should not reach this point due to an expected thrown exception.');
    }
    catch (Exception ex) {
      System.assert(String.isNotBlank(ex.getMessage()), 'Expecting an error message due to thrown exception.');
    }
    Test.stopTest();
  }

  /** 
   * When you create an Apex class from a WSDL, the methods in the auto-generated class call 
   * WebServiceCallout.invoke, which performs the callout to the external service. To test these
   * these methods such as GetInvoiceDetail, we need to instruct the Apex runtime to generate a 
   * fake response whenever WebServiceCallout.invoke is called. 
   *
   * To do so, we implemented the WebServiceMock interface (see above) and specifed a fake response 
   * for the Apex runtime to send within this method.
   */
  public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint,
    String soapAction, String requestName, String responseNS, String responseName, String responseType) {
    
    // Create a fake web service output
    JM_OrderDetailService.OrderDetailOutput output = new JM_OrderDetailService.OrderDetailOutput();
    output.orderDetailJSON = '{"lineItemsList":[{';
    output.orderDetailJSON += '"material":"90021834",';
    output.orderDetailJSON += '"materialDescription":"MW316 SAFB 3x16x48",';
    output.orderDetailJSON += '"customerMaterialNumber":"",';
    output.orderDetailJSON += '"invoicePrice":"184.42",';
    output.orderDetailJSON += '"invoicePriceUOM":"MSF",';
    output.orderDetailJSON += '"invoicePriceCurrency":"USD",';
    output.orderDetailJSON += '"orderQuantity":"512.000",';
    output.orderDetailJSON += '"orderUOM":"FT2",';
    output.orderDetailJSON += '"orderUnitPrice":"0.36",';
    output.orderDetailJSON += '"requestedDeliveryDate":"20150918",';
    output.orderDetailJSON += '"confirmedDeliveryDate":"20150919",';
    output.orderDetailJSON += '"pricingDate":"20150920",';
    output.orderDetailJSON += '"plant":null,';
    output.orderDetailJSON += '"netPrice":"360.20",';
    output.orderDetailJSON += '"invoiceNumbers":["0901124932"],';
    output.orderDetailJSON += '"creditMemoNumbers":["0901124932"],';
    output.orderDetailJSON += '"debitMemoNumbers":["0901124932"],';
    output.orderDetailJSON += '"status":"Completely processed"}]}';

    // Create response element from the autogenerated class add it to the response parameter
    JM_OrderDetailService.queryOrderDetailResponse element = 
      new JM_OrderDetailService.queryOrderDetailResponse();
    element.OrderDetailOutput = output;
    response.put('response_x', element); 
  }
}