/** 
  * The Customer Self Service Community Field Set Utility test class helps test the querying of 
  * field sets when given the field set name and object type.  
  *
  * @author Craig Poirier
  * @version 1.0
  * @see CSS_FieldSetUtility, CSS_DetailSectionController
  */
@isTest
private class CSS_FieldSetUtilityTest {
    
  /** Test the retrieval of a field set using an opportunity example */
  @isTest static void testGetFieldSet() {
    CSS_FieldSetUtility.FieldSet fieldSet = CSS_FieldSetUtility.getFieldSet('Community_Opportunity_List_View', 'Opportunity');
    System.assert(!fieldSet.fields.isEmpty(),'Expecting a non-empty field set.');
  }
  
  /** Test the retrieval of an empty field set using an invalid field set name */
  @isTest static void testGetFieldSetWithError() {
    CSS_FieldSetUtility.FieldSet fieldSet = CSS_FieldSetUtility.getFieldSet('Bad_Object_List_View', 'Opportunity');
    System.assert(fieldSet.fields.isEmpty(),'Expecting an empty field set.');
  } 
}