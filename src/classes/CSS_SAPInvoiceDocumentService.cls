/**
 * The Invoice Document Service for the customer self service community leverages SAP and
 * webMethods to generate a PDF document. This service leverages the SAP JM_InvoiceDocumentService
 * class, which is generated from a webMethods WSDL.
 *
 * Note that this class would be a lot less complex if the functionality did not have to support
 * Internet Explorer. Currently, Internet Explorer does not support the use of DATA URIs as the 
 * source of iFrames and pages. In other words, the following code works in Chrome and Firefox,
 * but does not work in IE:
 *
 * <apex:commandLink id="loadDocumentButton" action="{!LoadDocument}" reRender="loadDocumentButton" 
 *  oncomplete="window.location.href='data:application/pdf;base64,{!document}'">
 *   <button class="slds-button slds-button--neutral">Print</button>
 * </apex:commandLink> 
 *
 * Using the code above, we can directly display the pdf encoded blob directly to the user! However, 
 * this simplistic approach is not yet supported by IE. The alternative approach until Internet 
 * Explorer supports DATA URI is to save the PDF blob as an attachment and forward the user to 
 * Salesforce's built in file download servlet (i.e., "/servlet/servlet.FileDownload?file=id").
 *
 * @author Craig Poirier
 * @version 1.0
 * @see JM_InvoiceDocumentService, CSS_SAPInvoiceDetailService
 */
public without sharing class CSS_SAPInvoiceDocumentService {

  /** Temporary invoice document name (used to prevent duplicates) */
  private static final String INVOICE_DOCUMENT_NAME = 'invoice.pdf';

  /** webMethods timeout custom setting */
  private static final String CUSTOM_SETTING_TIMEOUT = 'webMTimeoutDocumentService';


  /**
   * The printDocument method calls SAP/webMethod Invoice Generator Service and parses the results
   * using wrapper classes defined below. This method saves the results as a document attachement
   * and returns the Salesforce identifier of the new document. 
   *
   * This method asks for both the Salesforce invoice id and the SAP invoice number in order to 
   * save on database calls (i.e., given both the identifier and number, we don't have to call the 
   * database). Calling methods should have both of these identifiers.
   * 
   * @param invoiceId the invoice's Salesforce identifier
   * @param invoiceNumber the invoice's unique SAP identifier 
   * @return the newly saved invoice identifier 
   */
  @RemoteAction
  public static String printDocument(String invoiceId, String invoiceNumber) {
    try {
    
      // Using the SAP/webMethods service, get invoice details for the given invoice
      System.debug(LoggingLevel.INFO, 'CSS_SAPInvoiceDocumentService - Print Document: invoice number: ' + invoiceNumber);
      JM_InvoiceDocumentService.JMSalesforce_InvoicePdf_WSD_getInvoicePdfProvider_Port port = 
        new JM_InvoiceDocumentService.JMSalesforce_InvoicePdf_WSD_getInvoicePdfProvider_Port();
      
      // Set the timeout in milliseconds. Salesforce default timeout is 10 seconds.
      String timeout = Utilities.getParameter(CUSTOM_SETTING_TIMEOUT);
      port.timeout_x = String.isEmpty(timeout) ? 30000 : Integer.valueOf(timeout);

      // Call webservice callout with timeout defined above
      JM_InvoiceDocumentService.InvoicePdfOutput output = port.getInvoicePdfFile(invoiceNumber);
      System.debug(LoggingLevel.INFO, 'CSS_SAPInvoiceDocumentService - Print Document: output: ' + output);

      // Parse and decode the invoice PDF document
      JSONParser parser = JSON.createParser(output.invoicePdfImageJson);
      InvoiceFile iFile = (InvoiceFile) parser.readValueAs(InvoiceFile.class);  
      Blob decodedFile = EncodingUtil.base64Decode(iFile.invoicePdfImage);
      
      // Clean temporary documents then save and return the identifier of the document
      cleanDocuments(invoiceId); 
      return saveDocument(invoiceId, decodedFile);
    }
    catch (Exception ex) { // this is a service method so throw errors back to calling method
      CSS_Utility.logError('CSS_SAPInvoiceDocumentService - Print Document Error.', ex);
      throw new CSS_Exception(UserInfo.getUserType().equals('Standard') ? ex.getMessage() :
        System.Label.CSS_Print_Invoice_Error_Message);
    }
  }

  /** 
   * Saves a document (i.e., PDF) blob as an attachement and returns the new salesforce 
   * identifier of the newly saved document. This class has to have without sharing on to allow
   * invoice attachments to be saved.
   *
   * @param invoiceId the invoice's salesforce identifier
   * @param document the invoice's binary body
   * @throws DMLException if document could not be saved
   */
  private static String saveDocument(String invoiceId, Blob document) {
    System.debug(LoggingLevel.INFO, 'CSS_SAPInvoiceDocumentService - Saving Document: invoice id: ' + invoiceId);
    Attachment attach = new Attachment(); 
    attach.Name = INVOICE_DOCUMENT_NAME;
    attach.Body = document;    
    attach.ContentType = 'application/pdf'; 
    attach.ParentID = invoiceId;    
    insert attach;
    return attach.id;
  }

  /** 
   * Clean up temporary documents for both the requested document and documents over 15 minutes
   * old. This method catches and logs errors; however, it will not throw any error because 
   * document deletion failures will not prevent the new invoice print requests from going through.
   * 
   * @param invoiceId the invoice's salesforce identifier
   */
  private static void cleanDocuments(String invoiceId) {
    System.debug(LoggingLevel.INFO, 'CSS_SAPInvoiceDocumentService - Cleaning Up Document: invoice id: ' + invoiceId);
    try {
      DateTime buffer = DateTime.now().addMinutes(-15); // created 15 minutes in the past
      List<Attachment> attachments = [SELECT Id FROM Attachment WHERE Parent.Type = 'SAP_Invoice__c' 
        AND Name = :INVOICE_DOCUMENT_NAME AND ParentId = :invoiceId];
      attachments.addAll([SELECT Id FROM Attachment WHERE Parent.Type = 'SAP_Invoice__c' 
        AND Name = :INVOICE_DOCUMENT_NAME AND ParentId <> :invoiceId AND CreatedDate < :buffer LIMIT 25]);
      System.debug(LoggingLevel.INFO, 'CSS_SAPInvoiceDocumentService - Cleaning Up Document: documents: ' + attachments);
      delete attachments;
    }
    catch (Exception ex) {
      CSS_Utility.logError('CSS_SAPInvoiceDocumentService - Cleaning Up Documents Error.', ex);
    }
  }

  /** 
   * Wrapper class for modeling a pdf file recieved from the Invoice Generator webMethod web 
   * serivce. This wrapper class must match the returned JSON in order for parsing to work 
   * correctly.
   */
  public class InvoiceFile {
    public String contentType;
    public String invoicePdfImage;
  }

}