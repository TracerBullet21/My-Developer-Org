/**
 * Customer Self Service Community List Page controller class provides basic set controller
 * functionality.
 *
 * @author Craig Poirier
 * @version 1.0   
 * @see CSS_ListController
 */
public with sharing virtual class CSS_SetController {

  /** Page messages, which should be used for simple messages such as no records founds */
  private transient List<String> messages;

  /** Standard set controller used for pages, list views, and related lists */
  public ApexPages.StandardSetController setController {get;set;}


  /**
   * Default constructor. If this constructor is used, make sure child classes call it using 
   * super method.
   */
  public CSS_SetController() {}    

  /** Return the currest list (i.e., page) of records */
  public virtual List<sObject> getRecords() {
    return (List<sObject>) setController.getRecords();
  }

  /** Navigate to the first page of the standard set controller */
  public void firstPage() {
    setController.first();
  }

  /** Navigate to the last page of the standard set controller */
  public void lastPage() {
    setController.last();
  }

  /** Navigate to the previous page of the standard set controller */
  public Boolean getHasNext() {
    return setController.getHasNext();
  }

  /** Navigate to the previous page of the standard set controller */
  public Boolean getHasPrevious() {
    return setController.getHasPrevious();
  }

  /** Return an empty indicator */
  public Boolean getIsEmpty() {
    System.debug(LoggingLevel.INFO, 'CSS_SetController: is empty? '  + (setController.getResultSize() == 0));
    return setController.getResultSize() == 0;
  }

  /** Navigate to the next page of the standard set controller */
  public void next() {
    System.debug(LoggingLevel.INFO, 'CSS_SetController: going to next page? ' 
      + setController.getHasNext());
    if(setController.getHasNext()) {     
      setController.next();
    }
  }

  /** Navigate to the previous page of the standard set controller */
  public void previous() {
    System.debug(LoggingLevel.INFO, 'CSS_SetController: going to previous page? ' 
      + setController.getHasPrevious());
    if(setController.getHasPrevious()) {
      setController.previous();
    }
  }

  /**
   * Adds a new messages, including built in Apex Page messages, which are not associated with
   * a component. Messages associated with a component (i.e., VF_SERIALIZE_VIEWSTATE errors) 
   * should be displayed using apex:message, which does not apply Salesforce markup.
   *
   * @param msg a simple text message
   */
  @TestVisible
  protected void addMessage(String msg) {
    System.debug(LoggingLevel.INFO, 'CSS_SetController - Adding Page Message: ' + msg);
    if (this.messages == null) {
      this.messages = new List<String>();
    }
    this.messages.add(msg);
  }

  /**
   * Returns a list of simple messages such as invalid search criteria or no record found messages.
   *
   * @return a list of error messages, includ standard Salesforce controller messages 
   */
  public List<String> getMessages() {
    System.debug(LoggingLevel.INFO, 'CSS_SetController - Getting Messages');
    if (this.messages == null) {
      this.messages = new List<String>();
    }
   
    // If a page error is found, output to logs and inform user
    for (ApexPages.Message message : ApexPages.getMessages()) {
      addMessage(System.Label.CSS_search_invalid_search_criteria);
      System.debug(LoggingLevel.INFO, 'CSS_SetController - Found ApexPage Message: ' +
        message.getSummary());
      break;
    }

    return this.messages;
  }
}