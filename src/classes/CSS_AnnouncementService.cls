/**
 * Announcement Service for the Customer Self Service Community. This service class queries 
 * Salesforce for recent customer announcements, session alerts, helpful links, and carousel
 * images.
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_AccountSummaryService
 */
public with sharing class CSS_AnnouncementService {

  /** Invalid user message for service methods */
  public static final String MESSAGE_INVALID_USER = 
    'Current user is not a community user. Please provide a valid user and try again. ';

  /** Session platform cache partition for managing session alerts */
  private static Cache.SessionPartition session = 
    Cache.Session.getPartition('CSSPlatformCache');

  /** Community alerts are stored in a users session using this key */
  private static final String SESSION_ID_VIEWED_ALERTS = 'alerts'; 

  /** Status of announcement or alert */
  public static final String STATUS_ACTIVE = 'Active';  

  /** Record type for generic community announcement */
  public static final String RECORD_TYPE_ANNOUNCEMENT = 'Announcement'; 

  /** Record type for session alerts */
  public static final String RECORD_TYPE_ALERT = 'Alert';
  
  /** Record type for helpful links */
  public static final String RECORD_TYPE_HELPFUL_LINK = 'Link'; 
  
  /** Record type for carousel images */
  public static final String RECORD_TYPE_CAROUSEL_IMAGE = 'Carousel_Image'; 


  /**
   * Registers an alert as viewed. Call this method to register a session alert as viewed by a 
   * community partner user so that is doesn't show up again until the user's next sesion.
   * 
   * @param alertId the alert's Salesforce 18 digit alphanumeric identifier
   */
  @RemoteAction public static void registerAlert(String alertId) {
    List<Id> alerts = session.get(SESSION_ID_VIEWED_ALERTS) == null ? 
      new List<Id>() : (List<Id>)session.get(SESSION_ID_VIEWED_ALERTS);
    alerts.add(alertId); // add alert to list of registered alerts
    session.put(SESSION_ID_VIEWED_ALERTS, alerts); // add alerts back to session
    System.debug(LoggingLevel.INFO, 'CSS_AnnouncementService - Registered Alerts: ' + alerts);
  }

  /**
   * Queries Salesforce for a limited number of session alerts and returns these session alerts
   * as a service.
   *
   * @return a list of session alerts with summaries using the Announcement__c object
   * @throws a Customer Self Service Community exception if anything goes wrong
   */
  @RemoteAction public static List<Announcement__c> getAlerts() {
    try { // catch and log any errors, but since this is a service throw an exception if applicable
      
      // Get list of alerts already registered as views
      List<Id> viewed = session.get(SESSION_ID_VIEWED_ALERTS) == null ? 
        new List<Id>() : (List<Id>)session.get(SESSION_ID_VIEWED_ALERTS);
      System.debug(LoggingLevel.INFO, 'CSS_AnnouncementService - Get Alerts: viewed alerts: ' + viewed);

      // Get list of applicable alerts using current profile and view alerts
      List<Announcement__c> alerts = [
        SELECT Summary__c
        FROM Announcement__c 
        WHERE RecordType.DeveloperName = :RECORD_TYPE_ALERT
          AND Status__c = :STATUS_ACTIVE
          AND (Start_Date__c = NULL OR Start_Date__c <= TODAY)
          AND (End_Date__c = NULL OR End_Date__c > TODAY)
          AND Id <> :viewed
        ORDER BY CreatedDate DESC LIMIT 20];
    
      System.debug(LoggingLevel.INFO, 'CSS_AnnouncementService - Returning Alerts: ' + alerts);
      return alerts; 
    }
    catch (cache.Session.SessionCacheException sce) {
      CSS_Utility.logError('CSS_AnnouncementService - Get Alerts Error.', sce);
      session.remove(SESSION_ID_VIEWED_ALERTS); // reset the current user's viewed alerts
      throw new CSS_Exception('Alerts is not available at this time. Please try again later.');
    }
    catch (Exception ex) {
      CSS_Utility.logError('CSS_AnnouncementService - Get Alerts Error.', ex);
      throw new CSS_Exception('Alerts is not available at this time. Please try again later.');
    }
  }

  /**
   * Queries Salesforce for a list of helpful links based on the current user's profile.
   *
   * @return a list of helpful links based on the current user's profile
   * @throws a Customer Self Service Community exception if anything goes wrong
   */
  @RemoteAction public static List<Announcement__c> getHelpfulLinks() {
    try { // catch and log any errors, but since this is a service throw an exception if applicable
      String profileName = getProfileName();

      List<Announcement__c> links = [
        SELECT Title__c, Link_URL__c
        FROM Announcement__c 
        WHERE RecordType.DeveloperName = :RECORD_TYPE_HELPFUL_LINK
          AND Status__c = :STATUS_ACTIVE
          AND (Start_Date__c = NULL OR Start_Date__c <= TODAY)
          AND (End_Date__c = NULL OR End_Date__c > TODAY)
          AND Visibility__c includes (:profileName)
        ORDER BY CreatedDate DESC LIMIT 20];

      System.debug(LoggingLevel.INFO, 'CSS_AnnouncementService - Returning Helpful Links: ' + links);
      return links; 
    }
    catch (System.Exception ex) {
      CSS_Utility.logError('CSS_AnnouncementService -  Get Helpful Links Error.', ex);
      throw new CSS_Exception('Helpful Links are not available at this time. Please try again later.');
    }
  }
 
  /**
   * Queries Salesforce for a list of carousel images.
   *
   * @return a list of helpful links based on the current user's profile
   * @throws a Customer Self Service Community exception if anything goes wrong
   */
  @RemoteAction public static List<Announcement__c> getCarouselImages() {
    try { 
      List<Announcement__c> images = [
        SELECT Caption__c, Link_URL__c 
        FROM Announcement__c 
        WHERE RecordType.DeveloperName = :RECORD_TYPE_CAROUSEL_IMAGE
          AND Status__c = :STATUS_ACTIVE
          AND (Start_Date__c = NULL OR Start_Date__c <= TODAY)
          AND (End_Date__c = NULL OR End_Date__c > TODAY)
        ORDER BY Priority__c ASC LIMIT 20];
      
      System.debug(LoggingLevel.INFO, 'CSS_AnnouncementService - Returning Carousel Images: ' + images);
      return images; 
    }
    catch (System.Exception ex) {
      CSS_Utility.logError('CSS_AnnouncementService -  Get Carousel Images Error.', ex);
      throw new CSS_Exception('Carousel Images are not available at this time. Please try again later.');
    }
  }

  /**
   * Queries Salesforce for a limited number of announcements and returns these announcements
   * as a service.
   */
  public static List<Announcement__c> getAnnouncements() {
    List<Announcement__c> announcements = new List<Announcement__c>();

    try { // return a blank list of announcements if exception is thrown
      String profileName = getProfileName();

      announcements = [SELECT Title__c, Summary__c, Body__c, Start_Date__c 
        FROM Announcement__c 
        WHERE RecordType.DeveloperName = :RECORD_TYPE_ANNOUNCEMENT
          AND Status__c = :STATUS_ACTIVE
          AND (Start_Date__c = NULL OR Start_Date__c <= TODAY)
          AND (End_Date__c = NULL OR End_Date__c > TODAY)
          AND Visibility__c includes (:profileName)
        ORDER BY CreatedDate DESC LIMIT 20];
    }
    catch (System.Exception ex) {
      System.debug(LoggingLevel.ERROR, 'CSS_AnnouncementService - Get Announcements Error: ' + ex.getMessage());
      System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
    }

    System.debug(LoggingLevel.INFO, 'CSS_AnnouncementService - Get Announcements: ' + announcements);
    return announcements; 
  }

  /**
   * Use the getProfileName class to return the current user's profile name. Profile has to be type of
   * customer community otherwise an exception will be thrown.
   *
   * @param the current user's profile name.
   */
  private static String getProfileName() {
    String profileId = UserInfo.getProfileId();
    List<Profile> profiles = [
      SELECT Name FROM Profile 
      WHERE UserLicense.Name = :CSS_Utility.PARTNER_LICENSES 
      AND id = :profileId];
    
    // Double check for a valid community profile
    if (profiles.isEmpty()) {
      throw new CSS_Exception(MESSAGE_INVALID_USER);
    }
    System.debug(LoggingLevel.INFO, 'CSS_AnnouncementService - Get Profile Name: ' + profiles[0].Name);
    return profiles[0].Name;
  }

}