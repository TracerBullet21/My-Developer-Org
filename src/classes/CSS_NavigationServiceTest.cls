/**
 * Test the navigation services for the Customer Self Service Community.
 *
 * @author Craig Poirier
 * @version 1.0   
 * @see CSS_NavigationService
 */
@isTest
private class CSS_NavigationServiceTest {
    
  /** Test registering and retrieval of breadcrumbs */
  @isTest static void testBreadcrumbs() {
    Test.startTest();
    
    // Create four breadcrumbs, and the first will be disgarded
    CSS_NavigationService.register('MSN', 'www.msn.com');
    CSS_NavigationService.register('Google', 'www.google.com');
    CSS_NavigationService.register('Yahoo', 'www.yahoo.com');
    CSS_NavigationService.register('Bing', 'www.bing.com');
    
    // Retrieve the breadcrumbs and validate the first
    List<CSS_NavigationService.Breadcrumb> crumbs = CSS_NavigationService.getBreadcrumbs();
    System.assertEquals('Google', crumbs[0].name);
    System.assertEquals('www.google.com', crumbs[0].link);
    
    Test.stopTest();
  }
    
}