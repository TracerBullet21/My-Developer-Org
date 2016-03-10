/** 
 * The Customer Self Service Landing Controller test class ensures that community users are 
 * navigated to the proper pages (i.e., login page vs. home page)
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_LandingController, CSS_LoginController
 */
@isTest
private class CSS_LandingControllerTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createCommunityUsers();
  }

  /** 
   * Test the landing controller's forward to start page method with a guest user. Every community 
   * has a guest profile with a guest user assign to that profile. 
   */
  @isTest static void testForwardToStartPageWithGuest() {
    Test.startTest();
    CSS_LandingController controller = new CSS_LandingController();
    
    // Use the Customer Self Service community guest user
    System.RunAs(CSS_TestDataFactory.getGuestUser()) {
      PageReference pageRef = controller.forwardToStartPage();
      System.assertEquals('/apex/css_login', pageRef.getURL());
    }     
    
    Test.stopTest();
  }

  /** 
   * Test landing controller's forward to start page method with a logged in user
   */
  @isTest static void testForwardToStartPageWithNonGuest() {
    Test.startTest();
    CSS_LandingController controller = new CSS_LandingController();
    
    // Test with an internal person (i.e., system admin)
    PageReference pageRef = controller.forwardToStartPage();
    System.assertEquals('/apex/css_home', pageRef.getURL());
   
    // Test with an actual community user
    System.RunAs(CSS_TestDataFactory.getCommunityUser()) {
      pageRef = controller.forwardToStartPage();
      System.assertEquals('/apex/css_home', pageRef.getURL());
    }
    
    Test.stopTest();
  }
    
  /** 
   * Test landing controller's forward to start page method 
   */
  @isTest static void testForwardToStartPageWithStartUrl() {
    Test.startTest();
    CSS_LandingController controller = new CSS_LandingController();
    
    // Test with an internal person (i.e., system admin)
    test.setCurrentPageReference(new PageReference('/css_start_page?' +
      'startURL=' + Site.getPathPrefix() + '/css_start_page'));
    PageReference pageRef = controller.forwardToStartPage();
    System.assertEquals('/css_start_page', pageRef.getURL());
   
    Test.stopTest();
  }

}