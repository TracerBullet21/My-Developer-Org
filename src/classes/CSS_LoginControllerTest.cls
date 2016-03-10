/** 
 * The Customer Self Service Login Controller test class ensures that community users are 
 * authenticated
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_LandingController, CSS_LoginController
 */
@isTest
private class CSS_LoginControllerTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
  }

  /** 
   * Test the landing controller's forward to start page method with a guest user. Every community 
   * has a guest profile with a guest user assign to that profile. 
   */
  @isTest static void testForwardToStartPageWithGuest() {
    Test.startTest();
    pageReference ref = new pageReference('www.google.com?startURL=testURL');
    test.setCurrentPageReference(ref);
    
    CSS_LoginController controller = new CSS_LoginController();
    System.assertEquals(new PageReference(Site.getPathPrefix() + '/SiteLogin?startURL=' +
      EncodingUtil.urlEncode('testURL','UTF-8')).getURL(), controller.forwardToAuthPage().getURL());
   
    controller.setForgotModeTrue();
    system.assertEquals(true, controller.isForgotMode);
    
    controller.setForgotModeFalse();
    system.assertEquals(false, controller.isForgotMode);
    
    ref = controller.login();
    system.assertEquals(null, ref);
    
    ref = controller.forgotPassword();
    system.assertEquals(null, ref);
    
    Test.stopTest();
  }
  
}