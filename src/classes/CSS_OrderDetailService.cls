/**
 * Order line item details service for the customer self service community. This service
 * leverages the SAP JM_OrderDetailService class, which is generated from a webMethods
 * WSDL to obtain and display SAP order line items.
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_CommunityService, CSS_SAPInvoiceDetailService
 */
public with sharing class CSS_OrderDetailService {

  /**
   * First, lookup the associated SAP invoice records based on the given SAP order line items.
   * Next, generate a list of links to the associated SAP invoice records (i.e., SAP_Invoice__c
   * records not Invoice__c records).
   * 
   * @param detail a list of SAP order line items (i.e., order details)
   */
  private static void setInvoiceLinks(List<OrderLineItem> details) {
    
    // Loop and collect all the invoice numbers, including credit and debit memo numbers
    Set<String> invoices = new Set<String>();
    for (OrderLineItem detail : details) {
      if(detail.invoiceNumbers <> null) {
        invoices.addAll(detail.invoiceNumbers); // start with regular invoices
      }
      if(detail.creditMemoNumbers <> null) {
        invoices.addAll(detail.creditMemoNumbers); // add credit memo invoices
      }
      if(detail.debitMemoNumbers <> null) {
        invoices.addAll(detail.debitMemoNumbers); // add debit memo invoices
      }
    }

    // Loop through all the associated invoices and assign their identifiers (i.e., Invoice_Number__c=>id)
    Map<String,Id> orderMap = new Map<String,Id>();
    System.debug(LoggingLevel.INFO, 'CSS_OrderDetailService - Setting SAP Invoice Links: ' + invoices);
    Schema.DescribeSObjectResult invoiceDescribe = SAP_Invoice__c.sObjectType.getDescribe();
    System.debug(LoggingLevel.INFO, 'CSS_OrderDetailService - Does user have SAP Invoice access?: ' + invoiceDescribe.accessible);
    if (invoiceDescribe.accessible) {
      for (SAP_Invoice__c invoice : [SELECT Invoice_Number__c FROM SAP_Invoice__c WHERE Invoice_Number__c = :invoices LIMIT 10000]) {
        orderMap.put(invoice.Invoice_Number__c, invoice.Id);
      }
    }

    // Generate the links for each invoice line item
    for (OrderLineItem detail : details) {

      // First, generate invoice links
      detail.invoiceLinks = new List<Link>();
      if(detail.invoiceNumbers <> null) {
        for (String num : detail.invoiceNumbers) {
          if (orderMap.containsKey(num)) {
            detail.invoiceLinks.add(new Link (num, orderMap.get(num), Site.getPathPrefix() + '/css_sap_invoice_detail?id=' + orderMap.get(num)));
          }
          else { // user does not have access to invoice record
            detail.invoiceLinks.add(new Link (num, null, null));
          }
        } 
      }

      // Second, generate credit memo links
      detail.creditMemoLinks = new List<Link>();
      if(detail.creditMemoNumbers <> null) {
        for (String num : detail.creditMemoNumbers) {
          if (orderMap.containsKey(num)) {
            detail.creditMemoLinks.add(new Link (num, orderMap.get(num), Site.getPathPrefix() + '/css_sap_invoice_detail?id=' + orderMap.get(num)));
          }
          else { // user does not have access to credit memo record
            detail.creditMemoLinks.add(new Link (num, null, null));
          }
        }
      }

      // Third, generate debit memo links
      detail.debitMemoLinks = new List<Link>();
      if(detail.debitMemoNumbers <> null) {
        for (String num : detail.debitMemoNumbers) {
          if (orderMap.containsKey(num)) {
            detail.debitMemoLinks.add(new Link (num, orderMap.get(num), Site.getPathPrefix() + '/css_sap_invoice_detail?id=' + orderMap.get(num)));
          }
          else { // user does not have access to debit memo record
            detail.debitMemoLinks.add(new Link (num, null, null));
          }
        } 
      }
      
    }
  }


  /**
   * First, lookup the associated SAP invoice records based on the given SAP order line items.
   * Next, generate a list of links to the associated SAP invoice records (i.e., SAP_Invoice__c
   * records not Invoice__c records).
   * 
   * @param detail a list of SAP order line items (i.e., order details)
   */
  private static void cleanDetails(List<OrderLineItem> details) {
    for (OrderLineItem detail : details) {
      if (String.isNotEmpty(detail.requestedDeliveryDate)) {
        detail.requestedDeliveryDate = convertDate(detail.requestedDeliveryDate);
      }
      if (String.isNotEmpty(detail.confirmedDeliveryDate)) {
        detail.confirmedDeliveryDate = convertDate(detail.confirmedDeliveryDate);
      }
      if (String.isNotEmpty(detail.pricingDate)) {
        detail.pricingDate = convertDate(detail.pricingDate);
      }
      if (String.isNotEmpty(detail.orderQuantity)) {
        try {
          Decimal toround = Decimal.valueOf(detail.orderQuantity);
          detail.orderQuantity = String.valueOf(toround.setScale(0));
        }
        catch (Exception ex) {
          System.debug(LoggingLevel.WARN, 'CSS_OrderDetailService - Round Order Quantity Failed: ' + ex.getMessage());
        }
      }
    }
  }

  /**
   * Convert and SAP/webMethods date (i.e., yyyyMMdd) to a salesforce date (i.e., M/d/yyyy)
   * 
   * @param the SAP/webMethods date to convert
   */
  private static String convertDate(String input) {
    try {
      return Date.newInstance(
        Integer.valueOf(input.substring(0,4)),
        Integer.valueOf(input.substring(4,6)), 
        Integer.valueOf(input.substring(6,8))).format();
    }
    catch (System.Exception ex) { // StringException most likely
      System.debug(LoggingLevel.WARN, 'CSS_OrderDetailService - Convert Date Failed: ' + ex.getMessage());
      return '';
    }
  }  

  /**
   * Call the SAP/webMethod order detail service then parse and return the results, using the 
   * wrapper classes defined below for order detail and order line items.
   * 
   * @param orderNumber the order's unique identifier 
   * @return an OrderDetail record that contains order line item details
   * @throws a Customer Self Service Community exception if anything goes wrong
   */
  @RemoteAction
  public static OrderDetail getOrderDetail(String orderNumber) {
    try {
    
      // Using the SAP/webMethods service, get invoice details for the given invoice
      System.debug(LoggingLevel.INFO, 'CSS_OrderDetailService - Get Order Detail: order number:' + orderNumber);
      JM_OrderDetailService.JMSalesforce_OrderDetail_WSD_queryOrderDetailProvider_Port port = 
        new JM_OrderDetailService.JMSalesforce_OrderDetail_WSD_queryOrderDetailProvider_Port();
      JM_OrderDetailService.OrderDetailOutput output = port.queryOrderDetail(orderNumber);
      System.debug(LoggingLevel.INFO, 'CSS_OrderDetailService - Get Order Detail: service output:' + output);
    
      // Parse the invoice JSON using the wrapper classes
      JSONParser parser = JSON.createParser(output.orderDetailJSON);
      OrderDetail detail = (OrderDetail) parser.readValueAs(OrderDetail.class);  
      System.debug(LoggingLevel.INFO, 'CSS_OrderDetailService - Get Order Detail: original order detail:' + detail);

      // Append the invoice links to the records
      setInvoiceLinks(detail.lineItemsList);
      System.debug(LoggingLevel.INFO, 'CSS_OrderDetailService - Get Order Detail: order detail with links:' + detail);

      // Clean up and return the records
      cleanDetails(detail.lineItemsList);
      return detail;
    }
    catch (Exception ex) { // this is a service method so throw errors back to calling method
      CSS_Utility.logError('CSS_OrderDetailService - Get Order Detail Error.', ex);
      throw new CSS_Exception(UserInfo.getUserType().equals('Standard') ? ex.getMessage() :
        System.Label.CSS_Order_Line_Items_Error);
    }
  }

  /** 
   * Wrapper class used for modeling an order detail object, which is a child of an order header 
   * (i.e., Order__c) 
   */
  public class OrderDetail {
    public String orderNumber; // not populated like invoice detail service
    public List<OrderLineItem> lineItemsList {get;set;} // "90021834"
  }

  /** 
   * Wrapper class used for modeling an order line item details, which is a child object of order
   * detail.  Records of this class are automatically populated by the return web service JSON and 
   * Salesforce built-in JOSN parser class. In other words, you should not have to populate this
   * class manually by looping through records. 
   */
  public class OrderLineItem {
    public String material {get;set;} // "90021834"
    public String materialDescription {get;set;} // "MW316 SAFB 3x16x48"
    public String customerMaterialNumber {get;set;} // ""
    public String invoicePrice {get;set;} // "184.42"
    public String invoicePriceUOM {get;set;} // "MSF"
    public String invoicePriceCurrency {get;set;} // "USD"
    public String orderQuantity {get;set;} // "512.000"
    public String orderUOM {get;set;} // "FT2"
    public String orderUnitPrice {get;set;} // "0.36"
    public String requestedDeliveryDate {get;set;} // "20150918"
    public String confirmedDeliveryDate {get;set;} // "20150918"
    public String pricingDate {get;set;} // "20150918"
    public String plant {get;set;} // null
    public String netPrice {get;set;} // "360.20"
    public List<String> invoiceNumbers {get;set;} // ["0901124932","0202324542"]
    public List<Link> invoiceLinks {get;set;} 
    public List<String> creditMemoNumbers {get;set;} // ["0901124932","0202324542"]
    public List<Link> creditMemoLinks {get;set;} 
    public List<String> debitMemoNumbers {get;set;} // ["0901124932","0202324542"]
    public List<Link> debitMemoLinks {get;set;} 
    public String status {get;set;} // "Completely processed"
  }

  /** 
   * Wrapper class used for modeling a link in a related list, detail page, or other community
   * pages (e.g., Link class is used with both order line items and invoice line items) 
   */
  public class Link {

    /** 
     * Constructor creates a link instance
     *
     * @param label the link's label
     * @param id the id of the link's target
     * @param path the full link path
     */
    public Link(String label, String id, String path) {
      this.label = label;
      this.id = id;
      this.path = path;
    }

    /** Link label */
    public String label {get;set;}

    /** Id of the link's target */
    public String id {get;set;}

    /** Full path of the link (i.e., /site prefix/path) */
    public String path {get;set;}
  }

}