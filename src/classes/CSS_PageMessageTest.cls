/** 
 * Test class for displaying messages, warnings, and errors to Customer Self Service Community Users. 
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_PageMessage
 */
@isTest
private class CSS_PageMessageTest {
    
  /** Test the creation of page messages */
  @isTest static void testPageMessages() {
    CSS_PageMessage message = new CSS_PageMessage(ApexPages.severity.Error, 'Test Message');
    System.AssertEquals('Test Message', message.summary);
  }

}