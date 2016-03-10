public with sharing class ExceptionHandler
{

	public static void handleBasicException( List<SObject> triggerObjects, List<SObject> dmlObjects, String dmlCommonField, Exception e )
	{
		Map<Id, SObject> triggerObjectsMap = new Map<Id, SObject>(triggerObjects);
		for ( Integer i=0; i<e.getNumDML(); i++ )
		{
			Id triggerId = (Id)dmlObjects[e.getDmlIndex(i)].get( dmlCommonField );
			triggerObjectsMap.get( triggerId ).addError( e.getDmlMessage(i) );
		}
	}

	public static void handleBasicException( List<SObject> dmlObjects, Exception e )
	{
		for ( Integer i=0; i<e.getNumDML(); i++ )
		{
			dmlObjects[i].addError( e.getDmlMessage(i) );
		}
	}

}