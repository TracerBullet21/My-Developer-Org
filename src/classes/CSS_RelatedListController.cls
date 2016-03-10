/**
 * Customer Self Service Community Related List Page controller class provides basic set controller
 * functionality for related lists
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_BaseController
 */
public with sharing class CSS_RelatedListController extends CSS_BaseController {
//public without sharing class CSS_RelatedListController extends CSS_BaseController {
  /** Field set with defined fields */
  private CSS_FieldSetUtility.FieldSet fieldSet;
  
  /** List of childen records to display */
  private List<SObject> records;


  /** Salesforce identifier of parent record */
  public Id parentId {get;set;} 

  /** Object relationship field to parent record */
  public String parentField {get;set;}

  /** Salesforce identifier of selected record */
  public String recordId {get;set;} 

  /** sObject token name for this related list */
  public String objectType {get;set;} 

  /** Name of field set for this related list */
  public String fieldSetName {get;set;} 

  /* Name of the community, used to build the edit page urls */
  public String communityName {get;set;}


  /** 
   * Default controller contructor, which takes no arguments (i.e., only standard controllers and
   * extensions for Visualforce pages take arguments).
   *
   * Order of Operation for Visualforce Components:
   * 1. This constructor method is called, instantiating the controller objects.
   * 2. The attributes on the component are set and then the page executes all assignTo attributes 
   * 3. After the assignTo methods are executed, expressions are evaluated, the action attribute on 
   *    the component is evaluated, and all other method calls, such as getting or setting a property
   *    value, are made.
   */
  public CSS_RelatedListController() { }

  /**
   * Get a populated field set that represents the given related list, using the Customer Self
   * Service Community Field Set Utility class.
   *
   * @return a populated field set that represents the given related list.
   */
  public CSS_FieldSetUtility.FieldSet getFieldSet(){
    System.debug(LoggingLevel.INFO, 'this.fieldSetName: ' + this.fieldSetName);
    System.debug(LoggingLevel.INFO, 'this.objectType: ' + this.objectType);
    if (this.fieldSet == null) {
      this.fieldSet = CSS_FieldSetUtility.getFieldSet(this.fieldSetName, this.objectType);
    }
    return this.fieldSet;
  }

  /**
   * Generate a SOQL statement based on the following two items: 
   *   1. Given field set
   *   2. Given object type.
   *
   * @return a SOQL statement that can be used to return the requested related list
   */
  private String getSOQLStmt() {
    String stmt = 'SELECT ' + String.join(getFieldSet().fieldNames,',') + ' FROM ' + this.objectType + ' ';
    stmt += ' WHERE ' + parentField + ' = :parentId LIMIT 100'; 
    return stmt;
  }

  /**
   * Query Salesforce for the requested records (i.e., query Salesforce using the given object
   * type and fieldset. Upon error, this method will return an empty list. Note that DML is allowed
   * in page controllers, but not allowed in constructors or getters and setters.  Thus, don't call
   * CSS Utility log error in this method since it requires a database update.
   *
   * @return list of records representing the requested related list
   */
  public List<SObject> getRecords() {
    try { 
      System.debug(LoggingLevel.INFO, 'CSS_RelatedListController - Getting Records: ' + getSOQLStmt());
      return Database.query(getSOQLStmt());
    }
    catch (System.Exception ex) { // something went seriously wrong so return a message and an empty list
      System.debug(LoggingLevel.ERROR, 'CSS_RelatedListController - Getting Records Failed:' + ex);
      addPageMessage(ApexPages.severity.Error, System.Label.CSS_Default_Error_Message);
      return new List<SObject>();
    }
  }

  /**
   * Delete the selected record (i.e., delete the record that is populated in the recordId
   * instance variable). This method also deletes any related attachments if applicable.
   *
   * The calling Visualforce page should rerender the table, which displays the associated
   * records because after the delete one will be missing.
   */
  public void deleteRecord() {
    Savepoint sp = Database.setSavepoint();

    try {

      // Delete the records and associated attachments if applicable
      System.debug(LoggingLevel.INFO, 'CSS_RelatedListController - Deleting Record: ' + recordId);
      delete Schema.getGlobalDescribe().get(this.objectType).newSObject(recordId);      
      if (this.objectType == 'Attachment_JM_Obj__c') {
        deleteAttachment(recordId);
      }

    }
    catch (DmlException dmle) { // user might not have access to delete the record
      System.debug(LoggingLevel.ERROR, 'CSS_EditController - Save Record Error:' + dmle);
      addDMLErrorsToPage(dmle);
      Database.rollback(sp);
    }
    catch (Exception ex) { 
      CSS_Utility.logError('CSS_RelatedListController - Delete Failed.', ex);
      addPageMessage(ApexPages.severity.Error, System.Label.CSS_Default_Error_Message);
      Database.rollback(sp);
    }
  }

  /**
   * Delete any attachments associated with the given parent record (i.e., parent opportunity or
   * parent case).
   *
   * @param parentId Salesforce identifier for the parent record
   * @throws a DmlException if the record could not be deleted
   */
  private void deleteAttachment(String parentId){
    List<Attachment> attachments = [SELECT Name FROM Attachment WHERE ParentId =:parentId];
    System.debug(LoggingLevel.INFO, 'CSS_RelatedListController - Deleting Attachment: ' + attachments);
    delete attachments;
  }

  /** 
   * Create the return URL for an edit page. Warning, an id query parameter is required for this
   * page to render correctly.
   *
   * @param return URL for an edit page, without the required id query parameter 
   * @param throws a null pointer exception if instance variable objectType isn't set
   */
  public String getEditPageURL() {
    if (communityName == 'ac')
      return Site.getPathPrefix() + '/ac_' + objectType.removeEndIgnoreCase('__c').toLowerCase() + '_edit';
    else
      return Site.getPathPrefix() + '/css_' + objectType.removeEndIgnoreCase('__c').toLowerCase() + '_edit';
  }

}