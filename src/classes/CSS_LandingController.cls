/** 
 * The Customer Self Service Landing Controller ensures that community users are navigated to the
 * proper pages (i.e., login page vs. home page)
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_LoginController
 */
public with sharing class CSS_LandingController {
  
  /**
   * The forwardToStartPage should be invoke on page load for guest pages
   *
   * @return a page reference to the appropriate start page
   */ 
  public PageReference forwardToStartPage() {
    System.debug(LoggingLevel.INFO, 'CSS_LandingController - Communities Landing Page: ' 
      + Network.communitiesLanding());

    // Determine start page
    String startUrl = System.currentPageReference().getParameters().get('startURL');
    if (UserInfo.getUserType()=='Guest') {
      return Page.css_login;
    } 
    else if (!String.isEmpty(startUrl)) {
      PageReference pageRef = new PageReference(startURL);
      return pageRef;
    } 
    else {
      return Page.css_home;
    }
  }
    
}