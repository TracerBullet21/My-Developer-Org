/**
 * The Customer Self Service Community Test Controller for editing notes and attachments. This
 * Test class will verify the saving and creating of new attachment records.
 *
 * @author Craig Poirier
 * @version 1.0
 * @created 09-20-2015
 */
@isTest
private class CSS_EditAttachmentControllerTest {
    
  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createTestData();
    CSS_TestDataFactory.createCommunityUsers();
  }

  /** 
   * Test the saving of an existing attachment
   */
  @isTest static void testSaveExisting() {

    // Lookup existing test attachment
    Attachment_JM_Obj__c attach = [SELECT Title__c FROM Attachment_JM_Obj__c WHERE 
      AttachmentNotes_External_ID__c = 'css-data-attachment-0' LIMIT 1];
    PageReference pageRef = Page.css_opportunity_detail;
    pageRef.getParameters().put('id', attach.Id); // standard controller will be assign this record
    Test.setCurrentPage(pageRef);
    
    // Generate the standard controller and edit attachment controller
    ApexPages.StandardController stdController = new ApexPages.StandardController(attach);
    CSS_EditAttachmentController controller = new CSS_EditAttachmentController(stdController);

    Test.startTest();

    // Set and save the new attachment
    Attachment file = controller.getAttachment();
    file.Name = 'css-new-attachment-0';
    file.Body = Blob.valueof('body');
    controller.saveAttachment();
    System.Assert(controller.getPageMessages().isEmpty(), 'Expected an empty list of errors.');
    
    Test.stopTest();
  }

  /** 
   * Test the saving of a new attachment
   */
  @isTest static void testSaveNew() {

    // Lookup existing opportunity and create a new attachment for it
    Opportunity opp = [SELECT Name FROM Opportunity WHERE Oppty_External_ID__c = 'css-data-opportunity-0'];
    Attachment_JM_Obj__c attach = new Attachment_JM_Obj__c(
      Title__c = 'css-data-attachment-0',
      Type__c = 'Scope of Work');
    PageReference pageRef = Page.css_opportunity_detail;
    pageRef.getParameters().put('Opportunity_R__c',opp.id);
    Test.setCurrentPage(pageRef);
    
    // Generate the standard controller and edit attachment controller
    ApexPages.StandardController stdController = new ApexPages.StandardController(attach);
    CSS_EditAttachmentController controller = new CSS_EditAttachmentController(stdController);

    Test.startTest();
    
    // Set and save the new attachment
    Attachment file = controller.getAttachment();
    file.Name = 'css-new-attachment-0';
    file.Body = Blob.valueof('body');
    controller.saveAttachment();
    System.Assert(controller.getPageMessages().isEmpty(), 'Expected an empty list of errors.');
    
    Test.stopTest();
  }

  /** 
   * Test the updating of an existing internal attachment by an external user, who should not have
   * access to update the attachment.
   */
  @isTest static void testSaveExistingWithNoAccess() {

    // Lookup existing test attachment
    Attachment_JM_Obj__c attach = [SELECT Title__c FROM Attachment_JM_Obj__c WHERE 
      AttachmentNotes_External_ID__c = 'css-data-attachment-0' LIMIT 1];
    PageReference pageRef = Page.css_opportunity_detail;
    pageRef.getParameters().put('id', attach.Id); // standard controller will be assign this record
    Test.setCurrentPage(pageRef);
    
    // Generate the standard controller and edit attachment controller
    ApexPages.StandardController stdController = new ApexPages.StandardController(attach);
    CSS_EditAttachmentController controller = new CSS_EditAttachmentController(stdController);

    Test.startTest();

    // Test with an external Customer Self Service Community User
    System.runAs(CSS_TestDataFactory.getCommunityUser()) {

      // Save the new attachment using an external user
      Attachment file = controller.getAttachment();
      file.Name = 'css-new-attachment-0';
      file.Body = Blob.valueof('Different Body');
      controller.saveAttachment();
      System.Assert(!controller.getPageMessages().isEmpty(), 'Expected a non-empty list of errors.');
    }
    
    Test.stopTest();
  }

}