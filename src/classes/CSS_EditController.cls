/**
 * Customer Self Service Community Controller for edit pages. This controller will save or create
 * new records (i.e., this controller is for both record creation and modification).
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_BaseController
 */
public with sharing virtual class CSS_EditController extends CSS_BaseController {

  public String paramNameToId;

  /** 
   * Default constructor for this standard controller extension. This constructor calls its
   * parent constructor to initialize error messages and the return url.
   *
   * @param stdController a Visualforce Standard Controller record
   */
  public CSS_EditController(ApexPages.StandardController stdController) {
    super(stdController);
    System.debug(LoggingLevel.ERROR, 'CSS_EditController - Initializing Edit Record');
    setDefaults(); // will throw an exception if query parameters are bad
  }

  public Id recordId {get;set;}

  /** 
   * Save the record to the database using an upsert operation. In other words, this method saves
   * both new and existing records to the database with one database call. If a database 
   * manipulation error (DML error) is encountered, this method will capture the error and add the 
   * error to page messages, which are displayed to the user. 
   *
   * @return a page reference to redirect the user if successful, otherwise null
   */
  public PageReference save() {
    System.debug(LoggingLevel.INFO, 'CSS_EditController - Saving Record: ' + this.controller.getRecord());
    try { // Upsert the record and return user to detail page
      upsert this.controller.getRecord();
      System.debug(LoggingLevel.ERROR, 'this.controller.getRecord().Id: ' + this.controller.getRecord().Id);
      System.debug(LoggingLevel.ERROR, 'this.controller.getRecord(): ' + this.controller.getRecord());
      
      System.debug(LoggingLevel.INFO, 'CSS_EditController - Saved Record');
  
      if (String.isNotBlank(paramNameToId))
        this.returnUrl = this.returnUrl + '&' + paramNameToId + '=' + this.controller.getRecord().Id;

      System.debug(LoggingLevel.ERROR, 'this.returnURL: ' + this.returnURL);
      return getRedirect();
    }
    catch (DmlException dmle) { // user might not have access to save the record
      System.debug(LoggingLevel.ERROR, 'CSS_EditController - Save Record Error:' + dmle);
      addDMLErrorsToPage(dmle);
      return null;
    }
    catch (Exception ex) { // DML is allowed in actions so use utility log method
      CSS_Utility.LogError('CSS_EditController - Save Record Error.', ex);
      addPageMessage(ApexPages.severity.Error, System.Label.CSS_Default_Error_Message);
      return null;
    }
  }

  /**
   * Do not perform an update, and redirect a user based on the given return URL or the default 
   * detail page. This method should be called by edit page constructors. 
   * 
   * @return a new instance of the PageReference class using the given or default return URL
   */
  public PageReference cancel() {
    System.debug(LoggingLevel.INFO, 'CSS_EditController - Canceled Edit');
    System.debug(LoggingLevel.ERROR, 'this.communityAbbreviation: ' + this.communityAbbreviation);
    return getRedirect();
  }

  /**
   * An override is needed for AC cancel functionality. When you attempt to override standard cancel
   * functionality, the values from the page do not update the controller.
   * 
   * @return a new instance of the PageReference class using the given or default return URL
   */
  public PageReference doCancel() {
    return getRedirect();
  }

  /** 
  * Using the given query parameters, set default fields. This method should only be call for
  * new records. Note this record only works with string type fields (i.e., booleans and numbers
  * are not yet configured).
  *
  * @throws a Customer Self Service Exception (CSS Exception) if query parameters cannot be parsed
  */
  protected void setDefaults() {
    try {

      System.debug(LoggingLevel.ERROR, 'Apexpages.currentPage().getParameters().get(id): ' + Apexpages.currentPage().getParameters().get('id'));
      // Assign default values for new records only
      if (String.isEmpty(Apexpages.currentPage().getParameters().get('id'))) {
    
        // Get a list of valid fields for current object
        Map<String, Schema.SObjectField> fields = this.controller.getRecord().
          getSObjectType().getDescribe().fields.getMap();
        
        // Loop through query parameters and add only the applicable values to the record
        for (String parm : ApexPages.currentPage().getParameters().keySet()) {
          System.debug(LoggingLevel.ERROR, 'CSS_EditController - Setting Defaults: checking parameter: ' + parm);
          if ((fields.containsKey(parm)) && (!parm.equalsIgnoreCase('Id'))) {
            this.controller.getRecord().put(parm,String.escapeSingleQuotes(
              ApexPages.currentPage().getParameters().get(parm)));
            System.debug(LoggingLevel.ERROR, 'CSS_EditController - Setting Defaults: found parameter: ' + parm + ':' +
              String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(parm)));
          }
        }
      }
    }
    catch (Exception ex) { // do not use utility class to log errors since DML is not allowed in constructors
      System.Debug(LoggingLevel.ERROR, 'CSS_EditController - Setting Defaults Failed: ' + ex);
      throw new CSS_Exception(System.Label.CSS_Default_Error_Message + ' System Message: ' + ex);
    }
  }

  public List<SelectOption> coatingPicklistOptions
  {
    get
    {
      if (coatingPicklistOptions == null)
        coatingPicklistOptions = getSelectOptions('Coating__c');
      return coatingPicklistOptions;
    }
    private set;
  }

  public List<SelectOption> getSelectOptions(String selectField)
  {
    List<SelectOption> options = new List<SelectOption>();
        
    for( Schema.PicklistEntry entry : developerNameToSObjectField.get( selectField ).getDescribe().getPicklistValues() )
      options.add(new SelectOption(entry.getLabel(), entry.getValue()));

    return options;
  }

  private Map<String, Schema.SObjectField> developerNameToSObjectField = 
    Schema.SObjectType.Specs_Guarantees__c.fields.getMap();
}