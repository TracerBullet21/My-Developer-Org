global class Grab
{
	global static Object Grab( String field, sObject obj )
	{
		if (field.contains('.'))
		{
			return pluckCrossObject(field, obj);
		}
		else
		{
			return obj.get( field );
		}
	}

	private static Object pluckCrossObject( String field, sObject obj )
	{
		List<String> fieldPath = field.split('\\.');
		sObject currentObj = obj;
		String actualField = fieldPath[0];
		for (Integer i = 0; i < fieldPath.size()-1; i++)
		{
			currentObj = currentObj.getSObject(actualField);
			if (currentObj == null) return null;
			actualField = fieldPath[i+1];
		}

		return currentObj.get( actualField );
	}

	global static Set<Object> Grab( String field, List<sObject> objs )
	{
		Set<Object> grabbed = new Set<Object>();

		for ( sObject obj : objs )
		{
			Object val = Grab( field, obj );
			if ( val != null )
			{
				grabbed.add( val );
			}
		}

		return grabbed;
	}

	global static Date pluckDate( String field, sObject obj )
	{
		return (Date)Grab( field, obj );
	}

	global static Set<Date> dates( String field, Map<Id, sObject> objs )
	{
		return dates( field, objs.values() );
	}

	global static Set<Date> dates( String field, List<sObject> objs )
	{
		Set<Date> grabbed = new Set<Date>();

		for ( sObject obj : objs )
		{
			Date val = pluckDate( field, obj );
			if ( val != null )
			{
				grabbed.add( val );
			}
		}

		return grabbed;
	}

	global static Datetime pluckDatetime( String field, sObject obj )
	{
		return (Datetime)Grab( field, obj );
	}

	global static Set<Datetime> datetimes( String field, Map<Id, sObject> objs )
	{
		return datetimes( field, objs.values() );
	}

	global static Set<Datetime> datetimes( String field, List<sObject> objs )
	{
		Set<Datetime> grabbed = new Set<Datetime>();

		for ( sObject obj : objs )
		{
			Datetime val = pluckDatetime( field, obj );
			if ( val != null )
			{
				grabbed.add( val );
			}
		}

		return grabbed;
	}

	global static Decimal pluckDecimal( String field, sObject obj )
	{
		return (Decimal)Grab( field, obj );
	}

	global static Set<Decimal> decimals( String field, Map<Id, sObject> objs )
	{
		return decimals( field, objs.values() );
	}

	global static Set<Decimal> decimals( String field, List<sObject> objs )
	{
		Set<Decimal> grabbed = new Set<Decimal>();

		for ( sObject obj : objs )
		{
			Decimal val = pluckDecimal( field, obj );
			if ( val != null )
			{
				grabbed.add( val );
			}
		}

		return grabbed;
	}

	global static Integer pluckInteger( String field, sObject obj )
	{
		return (Integer)Grab( field, obj );
	}

	global static Set<Integer> integers( String field, Map<Id, sObject> objs )
	{
		return integers( field, objs.values() );
	}

	global static Set<Integer> integers( String field, List<sObject> objs )
	{
		Set<Integer> grabbed = new Set<Integer>();

		for ( sObject obj : objs )
		{
			Integer val = pluckInteger( field, obj );
			if ( val != null )
			{
				grabbed.add( val );
			}
		}

		return grabbed;
	}

	global static Map<Id, Set<sObject>> fieldToSObjects(String field, List<sObject>objs)
	{
		Map<Id, Set<sObject>> objTosObjects = new Map<Id, Set<sObject>>();
		for( sObject obj : objs )
		{
			Id fieldVal = (Id)obj.get( field );
			if( !objTosObjects.containsKey( fieldVal ) )
				objTosObjects.put( fieldVal, new Set<sObject>() );
			objTosObjects.get( fieldVal ).add( obj );
		}
		return objTosObjects;
	}

	global static Set<Id> ids( List<sObject> objs )
	{
		Map<Id, sObject> objectMap = new Map<Id, sObject>();
		objectMap.putAll( objs );
		return objectMap.keySet().clone();
	}

	global static Set<Id> ids( Map<Id, sObject> objs )
	{
		return ids( objs.values() );
	}

	global static Id pluckId( String field, sObject obj )
	{
		return (Id)Grab( field, obj );
	}

	global static Set<Id> ids( String field, Map<Id, sObject> objs )
	{
		return ids( field, objs.values() );
	}

	global static Set<Id> ids( String field, List<sObject> objs )
	{
		Set<Id> grabbed = new Set<Id>();

		for ( sObject obj : objs )
		{
			Id val = pluckId( field, obj );
			if ( val != null )
			{
				grabbed.add( val );
			}
		}

		return grabbed;
	}

	global static String pluckString( String field, sObject obj )
	{
		return (String)Grab( field, obj );
	}

	global static Set<String> strings( String field, Map<Id, sObject> objs )
	{
		return strings( field, objs.values() );
	}

	global static Set<String> strings( String field, List<sObject> objs )
	{
		Set<String> grabbed = new Set<String>();

		for ( sObject obj : objs )
		{
			String val = pluckString( field, obj );
			if ( val != null )
			{
				grabbed.add( val );
			}
		}

		return grabbed;
	}
}