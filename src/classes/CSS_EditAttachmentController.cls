/**
 * Customer Self Service Community Controller for editing notes and attachments. This controller
 * will save or create new note and attachment records (i.e., this controller is for record 
 * creation and modification)
 *
 * @author Craig Poirier
 * @version 1.0
 * @created 09-20-2015
 */
public with sharing virtual class CSS_EditAttachmentController extends CSS_EditController {

  /** Notes & Attachments document type for notes */
  private static final String TYPE_NOTE = 'Note'; 

  /** Notes & Attachments security type for community users */
  private static final String SECURITY_EXTERNAL = 'External'; 

  /** Attachment object is set to transient to avoid any state view limit exceptions */
  public transient Attachment attachment;

  /** 
   * Default constructor for this standard controller extension, which is specifically for the
   * customized notes and attachments object (i.e., Attachment_JM_Obj__c). This constructor calls
   * its parent constructor to initialize passed in values, error messages, and the return url.
   *
   * @param stdController a Visualforce Standard Controller record
   */
  public CSS_EditAttachmentController(ApexPages.StandardController stdController) {
    Super(stdController);
    System.debug(LoggingLevel.INFO, 'CSS_EditAttachmentController - Initializing Edit Record');
    setAttachmentDefaults(); // will throw an exception if attachment is bad
  }

  /** 
   * This method sets default fields for new and existing attachments. For new attachments,
   * the methods assigns private flag and security settings. For existing attachments, this
   * method loads in the existing attachment. This method should be called by the class
   * constructor.
   *
   * @throws a Customer Self Service Exception (CSS Exception) if default assigment failed
   */
  private void setAttachmentDefaults() {
    try {
      Attachment_JM_Obj__c note = (Attachment_JM_Obj__c) this.controller.getRecord();
      if (String.isEmpty(Apexpages.currentPage().getParameters().get('id'))) { // new record
        note.Private__c = false;
        note.Security__c = SECURITY_EXTERNAL;
      }
      else { // configure existing record, including existing attachment
        List<Attachment> attachments = [SELECT Name, ParentId FROM Attachment WHERE ParentId =:note.Id];
        System.debug(LoggingLevel.INFO, 'CSS_EditAttachmentController - Loading Existing Attachment: ' + attachments);
        if (!attachments.isEmpty()) {
          this.attachment = attachments[0];
        }
      }
    }
    catch (Exception ex) { // do not use utility class to log errors since DML is not allowed in constructors
      System.debug(LoggingLevel.ERROR, 'CSS_EditController - Setting Defaults Failed: ' + ex.getMessage());
      throw new CSS_Exception(System.Label.CSS_Default_Error_Message + ' System Message: ' + ex);
    }

  }

  /**
   * The getAttachment method returns a new attachment record or the existing attachment record.
   *
   * @return a newly create attachment record or the existing attachment record
   */
  public Attachment getAttachment() {
    if (this.attachment == null) {
      this.attachment = new Attachment();  
    }
    return this.attachment;
  } 

  /** 
   * Save the record to the database using an upsert operation. In other words, save new
   * existing records to the database.
   *
   * If a database manipulation error (DML error) is encountered, this method will not 
   * through an error. Instead, errors will be added to page messages, which are displayed 
   * to the user. 
   */
  public PageReference saveAttachment() {
    System.debug(LoggingLevel.INFO, 'CSS_EditAttachmentController - Saving Record: ' + this.controller.getRecord());
    System.debug(LoggingLevel.INFO, 'CSS_EditAttachmentController - Saving Attachment: ' + this.attachment);
    
    // Create a savepoint before updating JM and Salesforce attachment records
    Savepoint savePoint = Database.setSavepoint();

    try { 
      Attachment_JM_Obj__c note = (Attachment_JM_Obj__c) this.controller.getRecord();
      
      // Upsert the note record
      upsert note;

      // Configure and insert the attachment record if a new attachment is selected
      if (this.attachment.Name <> null) {
        uploadAttachment(note);
      }

      // After a successful upsert, set the return page based on return URL
      System.debug(LoggingLevel.INFO, 'CSS_EditAttachmentController - Saved Record');
      return getRedirect();
    }
    catch (DmlException dmle) { // user might not have access to save the record
      System.debug(LoggingLevel.ERROR, 'CSS_EditAttachmentController - Save Record Error:' + dmle);
      Database.rollback(savePoint);
      addDMLErrorsToPage(dmle);
      return null;
    }
    catch (Exception ex) { // DML is allowed in actions so use utility log method
      CSS_Utility.logError('CSS_EditAttachmentController - Save Record Error.', ex);
      Database.rollback(savePoint);
      addPageMessage(ApexPages.severity.Error, System.Label.CSS_Default_Error_Message);
      return null;
    }
  }  

  /**
   * Upload a new attachment and link the attachment to the given note. Previously uploaded
   * attachments will be deleted.
   *
   * @param note the JM Attachment and Note record to associate the new attachment to
   */
  private void uploadAttachment(Attachment_JM_Obj__c note) {

    // First, delete existing attachments associated with note record
    List<Attachment> attachments = [SELECT Name FROM Attachment WHERE ParentId =:note.Id];
    System.debug(LoggingLevel.INFO, 'CSS_EditAttachmentController - Deleting Attachment: ' + attachments);
    delete attachments;
    
    // Second link and insert new attachment record
    Attachment newAttachment = new Attachment(
      Name = this.attachment.Name,
      ParentId = note.Id,
      OwnerId = UserInfo.getUserId(),
      Body = this.attachment.Body
    );
    System.debug(LoggingLevel.INFO, 'CSS_EditAttachmentController - Inserting Attachment: ' + newAttachment);
    insert newAttachment;

    // Update the note record once again
    note.attachmentLink__c = newAttachment.Id;
    note.fileName__c = newAttachment.Name; 
    System.debug(LoggingLevel.INFO, 'CSS_EditAttachmentController - Updating Note: ' + note);
    update note;
  }

}