/**
 * A simple Apex page controller that exposes the login functionality for the Self Service
 * Customer Community.
 *
 * @author Craig Poirier
 */
global with sharing class CSS_LoginController {
    
  /** Community user's username */
  global String username {get; set;}
 
  /** Community user's password */
  global String password {get; set;}
  
  /** Community user's password */
  public Boolean isForgotMode {get; set;}

  /**
   * Default controller constructor
   */
  global CSS_LoginController() {}
    
  
  /**
   * Set password forgotten mode to true.
   */
  public void setForgotModeTrue() {
    this.isForgotMode = true;
  }

  /**
   * Set password forgotten mode to false.
   */
  public void setForgotModeFalse() {
    this.isForgotMode = false;
  }    

  /**
   * Method used to "login" a user to the Customer Self Service Community.
   *
   * @return a page reference, which is determined by the landing page controller
   */
  global PageReference login() {
    String startUrl = System.currentPageReference().getParameters().get('startURL');
    return Site.login(username, password, startUrl);
  }

  /**
   * Method is invoked on login page by the apex page's action attribute. Do not put
   * any initialization code in this method.
   *
   * @return a page reference, which is determined by the landing page controller
   */ 
  global PageReference forwardToAuthPage() {
    String startUrl = System.currentPageReference().getParameters().get('startURL');
    
    // Return to the Customer Self Service Community home page
    return new PageReference(Site.getBaseUrl() + '/SiteLogin?startURL=' +
      EncodingUtil.urlEncode(startURL,'UTF-8'));
  }

  /**
   * Resets the user's password and sends an email to the user with their new password. 
   * 
   * @return a page reference to the forgot password confirmation page if successful.
   */
  public PageReference forgotPassword() {
    Boolean success = Site.forgotPassword(username);
    PageReference ref = Page.css_forgot_password_confirm;
    System.Debug(LoggingLevel.INFO,'CSS_LoginController - Forgot Password Result:' + success + '::' + ref);
    ref.setRedirect(true);
      
    if (success) {
      return ref;
    }
    return null;
  }
   
}