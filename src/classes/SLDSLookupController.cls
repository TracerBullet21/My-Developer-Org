public with sharing class SLDSLookupController extends ComponentControllerBase
{
	public SObject sObj;

	public String sObjType {get;set;}
	public String whereClauseProp {get;set;}
	public List<String> messages {get;set;}
	
	public Id objectId {get;set;}
	public String objectName {get;set;}

	public void assignToCtrl()
	{
		return;
	}

	@RemoteAction
	public static List<SObject> searchForRecords( String sObjectType, String objectName, String whereClause )
	{
		String query = 'SELECT Name, Id FROM ' + sObjectType + ' WHERE Name LIKE \'%' + objectName + '%\' AND ' + whereClause;
		return Database.query( query );
	}

	public Id getLookupId()
	{
		return this.objectId;
	}

	public Id getLookupName()
	{
		return this.objectName;
	}
}