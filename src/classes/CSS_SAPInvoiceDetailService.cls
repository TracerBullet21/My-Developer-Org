/**
 * Invoice line item details service for the customer self service community. This service
 * leverages the SAP JM_InvoiceDetailService class, which is generated from a webMethods
 * WSDL. 
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_OrderDetailService
 */
public class CSS_SAPInvoiceDetailService {

  /**
   * Clean up the SAP invoice details coming over from SAP before sending over to the client.
   * 
   * @param detail a list of SAP invoice line items (i.e., invoice details)
   */
  private static void cleanDetails(List<InvoiceLineItem> details) {
    for (InvoiceLineItem detail : details) {
      if (String.isNotBlank(detail.unitPrice)) {
        try {
          Decimal toround = Decimal.valueOf(detail.unitPrice);
          detail.unitPrice = String.valueOf(toround.setScale(2));
        }
        catch (Exception ex) {
          CSS_Utility.logError('CSS_SAPInvoiceDetailService - Failed to Parse Unit Price', ex);
        }
      }
    }
  }

  /**
   * Call the SAP/webMethod Invoice Detail Service, parse the results and return the results,
   * using the classes wrapper classes for invoice detail and invoice line item.
   * 
   * @param invoiceNumber the invoice's unique identifier 
   * @return InvoiceDetail record that contains invoice details
   * @throws a Customer Self Service Community exception if anything goes wrong
   */
  @RemoteAction
  public static InvoiceDetail getInvoiceDetail(String invoiceNumber) {
    try {
    
      // Using the SAP/webMethods service, get invoice details for the given invoice
      System.debug(LoggingLevel.INFO, 'CSS_SAPInvoiceDetailService - Get Invoice Detail: invoice number:' + invoiceNumber);
      JM_InvoiceDetailService.JMSalesforce_InvoiceDetail_WSD_queryInvoiceDetailProvider_Port port = 
        new JM_InvoiceDetailService.JMSalesforce_InvoiceDetail_WSD_queryInvoiceDetailProvider_Port();
      JM_InvoiceDetailService.InvoiceDetailOutput output = port.queryInvoiceDetail(invoiceNumber);
      System.debug(LoggingLevel.INFO, 'CSS_SAPInvoiceDetailService - Get Invoice Detail: service output:' + output);
    
      // Parse the invoice JSON using the wrapper classes
      JSONParser parser = JSON.createParser(output.invoiceDetailJSON);
      InvoiceDetail detail = (InvoiceDetail) parser.readValueAs(InvoiceDetail.class);  
      System.debug(LoggingLevel.INFO, 'CSS_SAPInvoiceDetailService - Get Invoice Detail: invoice detail:' + detail);

      // Clean up and return the records
      cleanDetails(detail.lineItemsList);
      return detail;
    }
    catch (Exception ex) { // this is a service method so throw errors back to calling method
      CSS_Utility.logError('CSS_SAPInvoiceDetailService - Get Invoice Detail Error.', ex);
      throw new CSS_Exception(UserInfo.getUserType().equals('Standard') ? ex.getMessage() :
        System.Label.CSS_SAP_Invoice_Line_Items_Error);
    }
  }

  /** 
   * Wrapper class used for modeling an invoice detail object, which is a child of an invoice
   * header (i.e., SAP_Invoice__c).
   */
  public class InvoiceDetail {
    public String invoiceNumber; // "0901124932"
    public List<InvoiceLineItem> lineItemsList {get;set;} // "90021834"
  }

  /** 
   * Wrapper class used for modeling an invoice detail line item, which is a child of an invoice 
   * InvoiceDetail.
   */
  public class InvoiceLineItem {
    public String itemNumber {get;set;} // "000010"
    public String materialNumber {get;set;} // "90021834"
    public String materialDescription {get;set;} // "MW316  SAFB  3x16x48"
    public String quantity {get;set;} // "512   FT2"
    public String unitPrice {get;set;} // "0.3602"
    public String value {get;set;} // "184.42"
    public String poNumber {get;set;} // "test IV"
  }
  
}