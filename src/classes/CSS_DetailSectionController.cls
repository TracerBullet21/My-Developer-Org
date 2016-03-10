/**
 * The Customer Self Service Community Detail Section displays record details for the specified
 * record. This class should be used be components that assign the following instance variables:
 * recordId, objectType, and fieldSetName.
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_BaseController
 */
 public with sharing class CSS_DetailSectionController {
//public without sharing class CSS_DetailSectionController {
  /** Field set with defined fields */
  private CSS_FieldSetUtility.FieldSet fieldSet;
  
  /** Record to display */
  private SObject record;


  /** Identifier of record to display */
  public Id recordId {get;set;} 

  /** Object type for this customer controller */
  public String objectType {get;set;} 

  /** Object controller is being used for */
  public String fieldSetName {get;set;} 


  /** 
   * Default controller contructor, which takes no arguments (i.e., only standard controllers 
   * and extensions for Visualforce pages take arguments)
   *
   * Order of operation:
   * 1. This constructor method is called, instantiating the controller objects.
   * 2. The attributes on the component are set and then the page executes all assignTo attributes 
   * 3. After the assignTo methods are executed, expressions are evaluated, the action attribute on 
   *    the component is evaluated, and all other method calls, such as getting or setting a property
   *     value, are made.
   */
  public CSS_DetailSectionController() { }

  /**
   * Get a populated field set that represents the given related list, using the Customer Self
   * Service Community Field Set Utility class.
   *
   * @return a populated field set that represents the given related list.
   */
  public CSS_FieldSetUtility.FieldSet getFieldSet(){
    if(this.fieldSet == null) {
      this.fieldSet = CSS_FieldSetUtility.getFieldSet(this.fieldSetName, this.objectType);
    }
    return this.fieldSet;
  }

  /**
   * Generate a SOQL statement based on the given field set and object type, which should be
   * set as instance variables (i.e., fieldSetName and objectType).
   * 
   * @return a SOQL statement for the given objectType and record Id
   */
  private String getSOQLStmt() {
    String stmt = 'SELECT ' + String.join(getFieldSet().fieldNames,',') + ' ';
    stmt += ' FROM ' + this.objectType + ' WHERE Id = :recordId LIMIT 1';
    return stmt;
  }

 /**
   * Query Salesforce for the given record specified by instance variable recordId. Note that 
   * DML is allowed in page controllers, but not allowed in constructors or getters and setters.
   * Thus, don't call CSS Utility log error in this method since it requires a database update.
   *
   * @return a Salesforce record which has the record id passed in by the component
   */
  public SObject getRecord() {
    try {
      if (this.record == null) {  
        System.debug(LoggingLevel.INFO, 'CSS_DetailSectionController - Searching...');
        this.record = Database.query(getSOQLStmt());
      }
    }
    catch (Exception ex) { // something went seriously wrong so redirect user to error page
      System.debug(LoggingLevel.ERROR, 'CSS_DetailSectionController - Getting Record Failed:' + ex);
      throw new CSS_Exception(System.Label.CSS_Default_Error_Message + ' System Message: ' + ex);
    }
    return this.record;
  }

}