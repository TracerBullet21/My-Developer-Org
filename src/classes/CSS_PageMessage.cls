/** 
 * Message class for displaying messages, warnings, and errors to Customer Self Service Community
 * Users. This class is used instead of the out-of-box Visualforce errors since those errors are
 * not responsive.
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_BaseController, ApexPages
 */
public with sharing class CSS_PageMessage {

  /** Serverity of page message (e.g., ERROR, WARNING, INFO) */
  public String severity {get;set;}

  /** Detailed summary of page messasge (i.e., message that will be displayed to the user) */
  public String summary {get; set;}

  /** Page message theme based on Salesforce Lightning Design System (SLDS) */
  public String theme {get; private set;}

  /** Message themes used for display */
  private static final transient Map<ApexPages.Severity,String> MESSAGE_THEMES
    = new Map<ApexPages.Severity, String> {
    ApexPages.Severity.ERROR => 'slds-theme--error',
    ApexPages.Severity.CONFIRM => 'slds-theme--succes',
    ApexPages.Severity.FATAL => 'slds-theme--error',
    ApexPages.Severity.WARNING => 'slds-theme--warning',
    ApexPages.Severity.INFO => 'slds-theme--succes'
  };

  /** 
   * Class constructor, which creates a new page message instance
   *
   * @param severity the severity of the page message (e.g., ApexPages.severity.Error)
   * @param summary a short description of the page message
   */
  public CSS_PageMessage(ApexPages.Severity severity, String summary) {
    this.severity = severity.name();
    this.summary = summary;
    this.theme = MESSAGE_THEMES.get(severity);
  }

}