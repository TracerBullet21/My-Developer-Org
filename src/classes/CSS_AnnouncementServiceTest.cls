/**
 * Announcement Service test class for the Customer Self Service Community. This test class tests
 * the Customer Self Service Community Announcement Service class, which queries Salesforce for 
 * recent customer announcements, session alerts, helpful links, and carousel images.
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_AccountSummaryService
 */
@isTest
private class CSS_AnnouncementServiceTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createCommunityUsers();
  }

 /** 
   * Test retrieval of community alerts using the CSS_AnnouncementService class
   */
  @isTest static void testCommunityAlerts() {
    
    // Create some helpful links
    List<SObject> alerts = new List<SObject>();
    Id recordTypeId = CSS_TestDataFactory.getRecordTypeIds(Announcement__c.sObjectType).
      get(CSS_AnnouncementService.RECORD_TYPE_ALERT);
    
    alerts.add(new Announcement__c(
      Name = 'css-test-alert-1',
      Summary__c = 'css-test-alert-1',
      Status__c = CSS_AnnouncementService.STATUS_ACTIVE,
      Start_Date__c = Date.today(),
      End_Date__c = Date.today().addDays(1),
      RecordTypeId = recordTypeId
    ));
    insert alerts;

    Test.startTest();
  
    // Test with a Customer Self Service Community User
    System.runAs(CSS_TestDataFactory.getCommunityUser()) {
 
      // Test basic retrieval of an alert
      List<Announcement__c> communications = CSS_AnnouncementService.getAlerts();
      System.assert(!communications.isEmpty(), 'No community alerts found.');
      System.assertEquals('css-test-alert-1',communications[0].Summary__c);
 
      // Test registering and hiding an alert
      CSS_AnnouncementService.registerAlert(communications[0].Id);
      communications = CSS_AnnouncementService.getAlerts();
      System.assert(communications.isEmpty(), 'Community alert should be hidden.');
    } 
    Test.stopTest();
  }

  /** 
   * Test retrieval of helpfil links using the CSS_AnnouncementService class
   */
  @isTest static void testHelpfulLinks() {
    
    // Create some helpful links
    List<SObject> links = new List<SObject>();
    Id recordTypeId = CSS_TestDataFactory.getRecordTypeIds(Announcement__c.sObjectType).
      get(CSS_AnnouncementService.RECORD_TYPE_HELPFUL_LINK);
    
    links.add(new Announcement__c(
      Title__c = 'css-test-link-1',
      Link_URL__c = 'http://css-test-link-1.com',
      Status__c = CSS_AnnouncementService.STATUS_ACTIVE,
      Start_Date__c = Date.today(),
      Visibility__c = CSS_TestDataFactory.TEST_PROFILE,
      RecordTypeId = recordTypeId
    ));
    insert links;

    Test.startTest();
  
    // Test with a Customer Self Service Community User
    System.runAs(CSS_TestDataFactory.getCommunityUser()) {

      List<Announcement__c> communications = CSS_AnnouncementService.getHelpfulLinks();
      System.assert(!communications.isEmpty(), 'No helpful links found.');
      System.assertEquals('http://css-test-link-1.com',communications[0].Link_URL__c);
    } 
    Test.stopTest();
  }

  /** 
   * Test retrieval of helpfil links using the CSS_AnnouncementService class
   */
  @isTest static void testCarouselImages() {
    
    // Create some helpful links
    List<SObject> images = new List<SObject>();
    Id recordTypeId = CSS_TestDataFactory.getRecordTypeIds(Announcement__c.sObjectType).
      get(CSS_AnnouncementService.RECORD_TYPE_CAROUSEL_IMAGE);
    
    images.add(new Announcement__c(
      Title__c = 'css-test-image-1',
      Caption__c = 'css-test-image-1',
      Priority__c = '5',
      Link_URL__c = 'http://css-test-image-1.com/image.png',
      Status__c = CSS_AnnouncementService.STATUS_ACTIVE,
      Start_Date__c = Date.today(),
      RecordTypeId = recordTypeId
    ));
    insert images;

    Test.startTest();
  
    // Test with a Customer Self Service Community User
    System.runAs(CSS_TestDataFactory.getCommunityUser()) {

      List<Announcement__c> communications = CSS_AnnouncementService.getCarouselImages();
      System.assert(!communications.isEmpty(), 'No carousel images found.');
      System.assertEquals('http://css-test-image-1.com/image.png',communications[0].Link_URL__c);
    } 
    Test.stopTest();
  }

  /** 
   * Test retrieval of helpfil links using the CSS_AnnouncementService class
   */
  @isTest static void testAnnouncements() {
    
    // Create some helpful links
    List<SObject> announcements = new List<SObject>();
    Id recordTypeId = CSS_TestDataFactory.getRecordTypeIds(Announcement__c.sObjectType).
      get(CSS_AnnouncementService.RECORD_TYPE_ANNOUNCEMENT);
    
    announcements.add(new Announcement__c(
      Title__c = 'css-test-announcement-title-1', 
      Summary__c = 'css-test-announcement-summary-1', 
      Body__c = 'css-test-announcement-body-1',
      Status__c = CSS_AnnouncementService.STATUS_ACTIVE,
      Start_Date__c = Date.today(),
      Visibility__c = CSS_TestDataFactory.TEST_PROFILE,
      RecordTypeId = recordTypeId
    ));
    insert announcements;

    Test.startTest();
  
    // Test with a Customer Self Service Community User
    System.runAs(CSS_TestDataFactory.getCommunityUser()) {

      List<Announcement__c> communications = CSS_AnnouncementService.getAnnouncements();
      System.assert(!communications.isEmpty(), 'No customer announcements found.');
      System.assertEquals('css-test-announcement-summary-1',communications[0].Summary__c);
    } 
    Test.stopTest();
  }

  /** 
   * Test retrieval of account summary information using a invalid user. The method should throw
   * a Customer Self Service Community Exception because the invalid user used is not a community
   * user.
   */
  @isTest static void testServicesWithInvalidUser() {
    Test.startTest();

    System.runAs(CSS_TestDataFactory.getBogusUser()) {
      try { // an exception should be thrown since this is not a community user
        List<Announcement__c> communications = CSS_AnnouncementService.getHelpfulLinks();
        System.assert(false,'This statement should never be reached.');
      }
      catch (CSS_Exception csse) {
        System.assert(String.isNotBlank(csse.getMessage()),'No Exception message found.');
      }
    } 
    Test.stopTest();
  }


}