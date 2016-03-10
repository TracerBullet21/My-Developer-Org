/**
 * Community Self Service Detail Page Controller test class, which tests the functionality 
 * provided by the CSS_DetailController class.
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_BaseController
 */
@isTest
private class CSS_DetailControllerTest {

  /** 
   * Test the generation of a detail page URL, which has the details query parameter
   */
  @isTest static void testGetDetailsURL() {
    ApexPages.StandardController stdController = new ApexPages.StandardController(new Opportunity());
    CSS_DetailController controller = new CSS_DetailController(stdController);
    System.assertEquals(
      EncodingUtil.urlEncode('/css_opportunity_detail?id=null&tab=details', 'UTF-8'), 
      controller.getDetailsURL());
  }

  /** 
   * Test the generation of a detail page URL, which has the related query parameter
   */
  @isTest static void testGetRelatedURL() {
    ApexPages.StandardController stdController = new ApexPages.StandardController(new Opportunity());
      CSS_DetailController controller = new CSS_DetailController(stdController);
    System.assertEquals(
      EncodingUtil.urlEncode('/css_opportunity_detail?id=null&tab=related', 'UTF-8'), 
      controller.getRelatedURL());
  }

}