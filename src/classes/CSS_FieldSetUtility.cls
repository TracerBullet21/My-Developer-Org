/** 
  * The Customer Self Service Community Field Set Utility class helps with the querying of field
  * sets when given the field set name and object type.  
  *
  * Using the get Field Set method defined below, calling methods will receive individual field
  * information for fields defined within a field set such as field name, label, type, and if
  * the field is the first field in the field set.
  *
  * @author Craig Poirier
  * @version 1.0
  * @see CSS_ListController,CSS_DetailSectionController,CSS_RelatedListController
  */
public with sharing class CSS_FieldSetUtility {
    
  /**
   * Obtain a FieldSet record using the given field set api name. The return FieldSet
   * record is based on the FieldSet inner class defined below. If no field set is found
   * with the given field set name and/or give object type, an empty field set is returned.
   *
   * @param fieldSet name of field set
   * @param objectType API name of the object
   * @return a newly created FieldSet record based on the FieldSet inner class defined below
   */
  public static FieldSet getFieldSet(String fieldSet, String objectType) {
    FieldSet fldSet = new FieldSet(); // start with an empty field set
    
    try { // catch bad field sets defined by invalid field sets or object types

      // Loop through found fields and create a field set
      for(Schema.FieldSetMember fieldSetMember : readFieldSet(fieldSet,objectType)) {
        fldSet.fieldNames.add(fieldSetMember.getFieldPath());
        fldSet.fields.add(new Field(
          fieldSetMember.getFieldPath(), // field API name
          fieldSetMember.getLabel(), // field label
          fieldSetMember.getType() + '')); // field type (e.g., STRING, PICKLIST)
      }

      // Set the first field in field set indicator
      if (fldSet.fields.size() > 0) {
        fldSet.fields[0].first = true;
      }
    }
    catch (System.Exception ex) {
      CSS_Utility.logError('CSS_FieldSetUtility - Get Field Set Failed.', ex);
    }
    return fldSet; // return an empty field set if field set was not defined
  }

  /** 
   * Get the list of fields in the given field sets
   *
   * @param fieldSet API name of field set
   * @param objectType API name of the object
   * @return list of field set member records
   * @throws a null pointer exception if fieldSet and/or object type is invalid
   */
  public static List<Schema.FieldSetMember> readFieldSet(String fieldSet, String objectType) {
    System.debug(LoggingLevel.ERROR, fieldSet);
    System.debug(LoggingLevel.ERROR, objectType);
    Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(objectType);
    Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
    Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSet);
    System.debug(LoggingLevel.INFO, 'CSS_FieldSetUtility - Read Field Set: ' + 
      DescribeSObjectResultObj.FieldSets.getMap().get(fieldSet));
    return fieldSetObj.getFields(); 
  }  

  /** 
   * Wrapper class for field sets 
   */
  public class FieldSet {

    /** list of field names (API names) */
    public List<String> fieldNames {get;set;}

    /** list of fields with attributes (i.e., names, labels, type) */
    public List<Field> fields {get;set;}

    /** Default constructor, which initializes member variables */
    public FieldSet() {
      this.fieldNames = new List<String>();
      this.fields = new List<Field>();
    }
  }

  /** 
   * Wrapper class for field records and their attributes 
   */
  public class Field {

    /** API name of field */
    public String name {get;set;}

    /** Field label */
    public String label {get;set;}

    /** Field type */
    public String type {get;set;}

    /** Set to true if field is first in set */
    public Boolean first {get;set;}

    /** Default constructor for Field records */
    public Field(String name, String label, String type) {
      this.name = name;
      this.label = label;
      this.type = type;
    }
  }
}