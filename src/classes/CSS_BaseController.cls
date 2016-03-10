/**
 * Base Visualforce controller class for Customer Self Service Community Visualforce controllers. 
 * Children controller classes should extend this class and specify with sharing in their class 
 * definitions. 
 *
 * Overall, this parent class provides return URL functionality, database modification
 * language (DML) error handing functionaly, ...
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_ListController, CSS_BaseControllerTest
 */
public virtual with sharing class CSS_BaseController {   

  /** Page messages, which should be used for page errors, warnings, and information */
  private transient List<CSS_PageMessage> pageMessages;

  /** Return URL, which defaults to the detail page if not provided */
  protected String returnURL;

  /** Apex page controller used for controller extensions */
  @testVisible protected ApexPages.StandardController controller; 

  public String communityAbbreviation
  {
    get{
      if ( communityAbbreviation == null ){
        if (String.isNotBlank(ApexPages.currentPage().getParameters().get('communityAbrev'))){
          communityAbbreviation = ApexPages.currentPage().getParameters().get('communityAbrev');
        }
        else{
          communityAbbreviation = 'css';
        }
      }
      return communityAbbreviation;
    }
    set;
  }

  /** 
   * Default constructor for custom controllers. Base classes should call this constructor before 
   * initializing their instance.
   */
  public CSS_BaseController() {
    System.debug(LoggingLevel.INFO, 'CSS_BaseController - Initializing Record');
    setReturnURL(); // set the return url to provided URL if given
  }

  /** 
   * Default constructor for standard controller extensions. Base classes should call this 
   * constructor before initializing their instance.
   *
   * @param stdController a Visualforce Standard Controller record
   */
  public CSS_BaseController(ApexPages.StandardController stdController) {
    System.debug(LoggingLevel.INFO, 'CSS_BaseController - Initializing Standard Controller Record');
    this.controller = stdController;
    setReturnURL(); // set the return url to provided URL if given
  }

  /**
   * The setReturnURL method sets the return URL instance variable. This method can be called for
   * custom controllers as well as standard controller extensions.
   *
   * @return true if return URL was set, otherwise false is returned
   */
  protected void setReturnURL() { 
    if (!String.isEmpty(ApexPages.currentPage().getParameters().get('retURL'))) {
      this.returnURL = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('retURL'));
      System.debug(LoggingLevel.INFO, 'CSS_BaseController - Setting Return URL: ' + this.returnURL);
    }
  }

  /**
   * Redirects a user's session based on the given return URL, default detail page, or home page
   * if something went wrong (i.e., if the return url is not set, standard controllers get the 
   * detail page and custom controllers get the home page).
   * 
   * @return a new instance of the PageReference class using the given or default return URL
   */
  @TestVisible
  protected PageReference getRedirect() { 
    System.debug(LoggingLevel.ERROR, 'communityAbbreviation: ' + communityAbbreviation);
    System.debug(LoggingLevel.ERROR, 'this.returnURL: ' + this.returnURL);
    PageReference pageRef;
    try {
      if (String.isNotBlank(this.returnURL)) { // use given return url
        pageRef = new PageReference(this.returnURL);
      }
      else if (this.controller <> null) { // use detail page if applicable
        if ( communityAbbreviation =='ac' ){
          pageRef = new PageReference(AC_Utility.getDetailPage(this.controller));
        }
        else{
          pageRef = new PageReference(CSS_Utility.getDetailPage(this.controller));
        }
      }
      else {
        pageRef = Page.css_home; // default to the home page
      }
    }
    catch (System.Exception ex) {
      CSS_Utility.logError('CSS_BaseController - Geting Redirect Failed.', ex);
      pageRef = Page.css_home; // default to the home page
    }
    
    // Redirect user, using given URL, detail page URL, or home page
    System.debug(LoggingLevel.Error, 'CSS_BaseController - Redirecting: ' + pageRef.getUrl());
    pageRef.setRedirect(true);
    return pageRef;
  }

  /**
   * Given a DMLException, this method will parse the custom field validation exception into a 
   * nice messages and add them to the current page context.  
   *
   * @param dmle a DMLException, which might contain a custom field validation exception
   */
  @TestVisible
  protected void addDMLErrorsToPage(DMLException dmle) {
    for (Integer i = 0; i < dmle.getNumDml(); i++) {
      if (dmle.getDmlType(i) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
        addPageMessage(ApexPages.severity.Error, dmle.getDmlMessage(i));
      }
      else if (dmle.getDmlType(i) == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY) {
        addPageMessage(ApexPages.severity.Error, System.Label.CSS_Insufficient_Access);
      }
      else if (dmle.getDmlType(i) == StatusCode.INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY) {
        addPageMessage(ApexPages.severity.Error, System.Label.CSS_Insufficient_Access);
      }
      else {
        addPageMessage(ApexPages.severity.Error, System.Label.CSS_Default_Error_Message + ' ' + 
          dmle.getDmlMessage(i));
      }
    }
  }

  /**
   * Adds a new page message to the list of page messages. Error messages associated with a 
   * specific component (i.e., VF_SERIALIZE_VIEWSTATE errors) are added automatically by 
   * Salesforce when using viewstate.
   *
   * @param severity message type (i.e., ERROR, WARNING, or INFO)
   * @param summary a summary of the error 
   */
  @TestVisible
  protected void addPageMessage(ApexPages.Severity severity, String summary) {
    System.debug(LoggingLevel.INFO, 'CSS_BaseController - Adding Page Message: ' + summary);
    if (this.pageMessages == null) {
      this.pageMessages = new List<CSS_PageMessage>();
    }
    this.pageMessages.add(new CSS_PageMessage(severity, summary));
  }

  /**
   * Returns page messages, which should be added by children controllers. Error messages 
   * associated with a specific component (i.e., VF_SERIALIZE_VIEWSTATE errors) should be displayed
   * using apex:message, which does not apply Salesforce markup.
   *
   * @return a list of error messages, which were added by child controllers.
   */
  public List<CSS_PageMessage> getPageMessages() {
    System.debug(LoggingLevel.INFO, 'CSS_BaseController - Getting Page Messages');
    if (this.pageMessages == null) { // never return a null list
      return new List<CSS_PageMessage>();
    }
    return this.pageMessages;
  }

}