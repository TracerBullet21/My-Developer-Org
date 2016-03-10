/**
 * Customer Self Service Community List Page controller test class provides testing for the 
 * CSS_SetController class.
 *
 * @author Craig Poirier
 * @version 1.0   
 * @see CSS_SetController, CSS_ListController
 */
@isTest
private class CSS_SetControllerTest {

  /**
   * Avoid any issue with creating test opportunities by disabling the opportunity trigger
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
  }

  /** 
   * Test basic set controller functionality 
   */
  @isTest static void testSetController() {
    List<Opportunity> opportunities = new List<Opportunity>();
    CSS_SetController controller = new CSS_SetController();
    
    // Create a 100 opportunities and assign them to the set controller
    for (Integer i=0; i<100; i++) {
      opportunities.add(new Opportunity(
        Name = 'css-set-controller-opp-'+i,
        StageName = 'Installed',
        CloseDate = Date.today().addDays(10),
        RecordTypeId = '012i00000011WNiAAM' // Lowe's Job (should never change)
      ));
    }
    insert opportunities;
    
    Test.startTest();
    controller.setController = new ApexPages.StandardSetController([
      SELECT Name FROM Opportunity]);
    
    // Verify set controller settings
    List<sObject> opps = controller.getRecords();
    System.assert(!opps.isEmpty(), 'Expected a non-empty list of sObjects');
    System.assertEquals(true, controller.getHasNext());
    System.assertEquals(false, controller.getHasPrevious());
    System.assertEquals(false, controller.getIsEmpty());
    
    // Increase code coverage
    controller.next();
    controller.previous();
    controller.lastPage();
    controller.firstPage();
    
    Test.stopTest();
  }

  /** 
   * Test message handling provided by the set controller base class
   */
  @isTest static void testMessages() {
    Test.startTest();
    CSS_SetController controller = new CSS_SetController();

    // Test an empty list of message (i.e., verify you don't get null)
    System.assert(controller.getMessages().isEmpty(), 'Expected an-empty list of messages');
   
    // Test with a real set controller message
    controller.addMessage('Test Search Message');
    System.assertEquals('Test Search Message', controller.getMessages()[0]);

    // Test with a Salesforce Visualforce page message
    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Test Error Messsage')); 
    System.assertEquals(System.Label.CSS_search_invalid_search_criteria, controller.getMessages()[1]);
    Test.stopTest();
  }
    
}