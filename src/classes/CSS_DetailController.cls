/**
 * Community Self Service Detail Page Controller, which provides basic functionality for record
 * detail pages (e.g., order, invoice, case, and opportunity detail pages).
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_BaseController
 */
public without sharing class CSS_DetailController extends CSS_BaseController {

  /** 
   * Default constructor for standard controller extension
   *
   * @param stdController a Visualforce Standard Controller record
   */
  public CSS_DetailController(ApexPages.StandardController stdController) {
    super(stdController);
    CSS_Utility.allowDML = false;
    System.debug(LoggingLevel.INFO, 'CSS_DetailController - Initializing Detail Record');
  }
  
  /** 
   * Return the return URL for this detail page, including the detail tab indicator.
   *
   * @param the encoded URL  for this detail page with the detail tab query parameter
   */
  public String getDetailsURL() {
    return EncodingUtil.urlEncode(CSS_Utility.getDetailPage(this.controller) + 
      '&tab=details', 'UTF-8');
  }

  /** 
   * Return the return URL for this detail page, including the related tab indicator.
   *
   * @param the encoded URL for this detail page with the related tab query parameter
   */
  public String getRelatedURL() {
    return EncodingUtil.urlEncode(CSS_Utility.getDetailPage(this.controller) + 
      '&tab=related', 'UTF-8');
  }
}