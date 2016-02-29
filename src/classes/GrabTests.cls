@isTest
private class GrabTests
{
	private static testMethod void grabTest()
	{
		Lead johnny = new Lead( FirstName = 'Johnny', LastName = 'Five', Company = 'Johnny Co' );

		Test.startTest();
			Object actualName = grab.grab( 'FirstName', johnny );
		Test.stopTest();

		System.assertEquals( johnny.FirstName, actualName, 'The sObject Name should be grabbed' );
	}

	private static testMethod void grabCrossObjectRelationship()
	{
		Account testAccount = new Account(Name='Test Account');
		Contact johnny = new Contact( FirstName = 'Johnny', LastName = 'Five');
		johnny.account = testAccount;

		Test.startTest();
			Object actualName = grab.grab( 'Account.Name', johnny );
		Test.stopTest();

		System.assertEquals( testAccount.Name, actualName, 'The parent sObject Name should be grabbed' );
	}

	private static testMethod void grabCrossObjectRelationship_Null()
	{
		Contact johnny = new Contact( FirstName = 'Johnny', LastName = 'Five');

		Test.startTest();
			Object actualName = grab.grab( 'Account.Name', johnny );
		Test.stopTest();

		System.assertEquals( null, actualName, 'The parent sObject Name should be null if the relationship is null' );
	}

	private static testMethod void grabIgnoresNulls()
	{
		Lead johnny = new Lead();

		Test.startTest();
			Set<Object> actualIds = grab.grab( 'Id', new List<sObject>{ johnny } );
		Test.stopTest();

		System.assert( actualIds.isEmpty(), 'null values should be ignored' );
	}

	private static testMethod void grabBulkTest()
	{
		Lead johnny = new Lead( FirstName = 'Johnny', LastName = 'Five', Company = 'Johnny Co' );
		Lead julie  = new Lead( FirstName = 'Julie', LastName = 'Five', Company = 'Julie Co' );
		Lead jamby = new Lead( FirstName = 'Jamby', LastName = 'Five', Company = 'Jamby Co' );

		List<Lead> allLeads = new List<Lead>{ johnny, julie, jamby };

		Test.startTest();
			Set<Object> actualNames = grab.grab( 'FirstName', allLeads );
		Test.stopTest();

		System.assert( actualNames.contains( johnny.FirstName ), 'The FirstNames of the sObjects should be grabbed' );
		System.assert( actualNames.contains( julie.FirstName ), 'The FirstNames of the sObjects should be grabbed' );
		System.assert( actualNames.contains( jamby.FirstName ), 'The FirstNames of the sObjects should be grabbed' );
	}

	private static testMethod void grabDateTest()
	{
		Date tomorrow = Date.today().addDays(1);
		Opportunity bigSale = new Opportunity( Name = 'Sell a lot', CloseDate = tomorrow, StageName = 'Qualification' );

		Test.startTest();
			Date actualDate = grab.grabDate( 'CloseDate', bigSale );
		Test.stopTest();

		System.assertEquals( tomorrow, actualDate, 'The sObject Created Date should be grabbed' );
	}

	private static testMethod void grabDatesIgnoresNulls()
	{
		Lead johnny = new Lead();

		Test.startTest();
			Set<Date> actualDates = grab.dates( 'CreatedDate', new List<sObject>{ johnny } );
		Test.stopTest();

		System.assert( actualDates.isEmpty(), 'null values should be ignored' );
	}

	private static testMethod void grabDatesTest()
	{
		Date tomorrow = Date.today().addDays(1);
		Date nextWeek = Date.today().addDays(7);
		Date nextMonth = Date.today().addDays(30);
		Opportunity bigSale = new Opportunity( Name = 'Sell a lot', CloseDate = tomorrow, StageName = 'Qualification' );
		Opportunity biggerSale = new Opportunity( Name = 'Sell it all', CloseDate = nextWeek, StageName = 'Qualification' );
		Opportunity biggestSale = new Opportunity( Name = 'Permanent vacation', CloseDate = nextMonth, StageName = 'Qualification' );

		List<Opportunity> allOpportunitiesList = new List<Opportunity>{ bigSale, biggerSale, biggestSale };
		Map<Id, Opportunity> allOpportunitiesMap = new Map<Id, Opportunity>{
			'00Q0000000XXXXX' => bigSale,
			'00Q0000000XXXXY' => biggerSale,
			'00Q0000000XXXXZ' => biggestSale
		};

		Test.startTest();
			Set<Date> actualDatesList = grab.dates( 'CloseDate', allOpportunitiesList );
			Set<Date> actualDatesMap = grab.dates( 'CloseDate', allOpportunitiesMap );
		Test.stopTest();

		System.assert( actualDatesList.contains( tomorrow ), 'The sObject Close Date should be grabbed' );
		System.assert( actualDatesList.contains( nextWeek ), 'The sObject Close Date should be grabbed' );
		System.assert( actualDatesList.contains( nextMonth ), 'The sObject Close Date should be grabbed' );
		System.assert( actualDatesMap.contains( tomorrow ), 'The sObject Close Date should be grabbed' );
		System.assert( actualDatesMap.contains( nextWeek ), 'The sObject Close Date should be grabbed' );
		System.assert( actualDatesMap.contains( nextMonth ), 'The sObject Close Date should be grabbed' );
	}

	private static testMethod void grabDatetimeTest()
	{
		Event birthdayParty = new Event( ActivityDateTime = DateTime.now() );

		Test.startTest();
			Datetime actualDatetime = grab.grabDatetime( 'ActivityDateTime', birthdayParty );
		Test.stopTest();

		System.assertEquals( birthdayParty.ActivityDateTime, actualDatetime, 'The sObject Created Date should be grabbed' );
	}

	private static testMethod void grabDatetimesIgnoresNulls()
	{
		Lead johnny = new Lead();

		Test.startTest();
			Set<Datetime> actualDatetimes = grab.datetimes( 'CreatedDate', new List<sObject>{ johnny } );
		Test.stopTest();

		System.assert( actualDatetimes.isEmpty(), 'null values should be ignored' );
	}

	private static testMethod void grabDatetimesTest()
	{
		Event birthdayParty = new Event( ActivityDateTime = DateTime.now() );
		Event cookout = new Event( ActivityDateTime = DateTime.now().addDays( 1 ) );
		Event boxSocial = new Event( ActivityDateTime = DateTime.now().addDays( 2 ) );

		List<Event> allEvents = new List<Event>{ birthdayParty, cookout, boxSocial };
		Map<Id, Event> allEventsMap = new Map<Id, Event>{
			'00Q0000000XXXXU' => birthdayParty,
			'00Q0000000XXXXW' => cookout,
			'00Q0000000XXXXX' => boxSocial
		};

		Test.startTest();
			Set<Datetime> actualDatetimesList = grab.datetimes( 'ActivityDateTime', allEvents );
			Set<Datetime> actualDatetimesMap = grab.datetimes( 'ActivityDateTime', allEventsMap );
		Test.stopTest();

		System.assert( actualDatetimesList.contains( birthdayParty.ActivityDateTime ), 'The sObjects Created Date should be grabbed' );
		System.assert( actualDatetimesList.contains( cookout.ActivityDateTime ), 'The sObjects Created Date should be grabbed' );
		System.assert( actualDatetimesList.contains( boxSocial.ActivityDateTime ), 'The sObjects Created Date should be grabbed' );
		System.assert( actualDatetimesMap.contains( birthdayParty.ActivityDateTime ), 'The sObjects Created Date should be grabbed' );
		System.assert( actualDatetimesMap.contains( cookout.ActivityDateTime ), 'The sObjects Created Date should be grabbed' );
		System.assert( actualDatetimesMap.contains( boxSocial.ActivityDateTime ), 'The sObjects Created Date should be grabbed' );
	}

	private static testMethod void grabDecimalTest()
	{
		Decimal tonsOfMoney = 1337.02;
		Opportunity bigSale = new Opportunity( Name = 'Sell a lot', CloseDate = Date.today(), Amount = tonsOfMoney, StageName = 'Qualification' );

		Test.startTest();
			Decimal actualDecimal = grab.grabDecimal( 'Amount', bigSale );
		Test.stopTest();

		System.assertEquals( tonsOfMoney, actualDecimal, 'The sObject Amount should be grabbed' );
	}

	private static testMethod void grabDecimalsIgnoresNulls()
	{
		Opportunity bigSale = new Opportunity();

		Test.startTest();
			Set<Decimal> actualDecimals = grab.decimals( 'Amount', new List<sObject>{ bigSale } );
		Test.stopTest();

		System.assert( actualDecimals.isEmpty(), 'null values should be ignored' );
	}

	private static testMethod void grabDecimalsTest()
	{
		Decimal tonsOfMoney = 1337.02;
		Decimal evenMoreMoney = 42069.96;
		Decimal notALot = 2.13;
		Opportunity bigSale = new Opportunity( Name = 'Sell a lot', CloseDate = Date.today(), Amount = tonsOfMoney, StageName = 'Qualification' );
		Opportunity biggerSale = new Opportunity( Name = 'Sell a lot', CloseDate = Date.today(), Amount = evenMoreMoney, StageName = 'Qualification' );
		Opportunity smallSale = new Opportunity( Name = 'Sell a lot', CloseDate = Date.today(), Amount = notALot, StageName = 'Qualification' );

		List<Opportunity> allOpportunities = new List<Opportunity>{ bigSale, biggerSale, smallSale };
		Map<Id, Opportunity> allOpportunitiesMap = new Map<Id, Opportunity>{
			'00Q0000000XXXXX' => bigSale,
			'00Q0000000XXXXY' => biggerSale,
			'00Q0000000XXXXZ' => smallSale
		};

		Test.startTest();
			Set<Decimal> actualDecimalsList = grab.decimals( 'Amount', allOpportunities );
			Set<Decimal> actualDecimalsMap = grab.decimals( 'Amount', allOpportunitiesMap );
		Test.stopTest();

		System.assert( actualDecimalsList.contains( tonsOfMoney ), 'The sObject Amount should be grabbed' );
		System.assert( actualDecimalsList.contains( evenMoreMoney ), 'The sObject Amount should be grabbed' );
		System.assert( actualDecimalsList.contains( notALot ), 'The sObject Amount should be grabbed' );
		System.assert( actualDecimalsMap.contains( tonsOfMoney ), 'The sObject Amount should be grabbed' );
		System.assert( actualDecimalsMap.contains( evenMoreMoney ), 'The sObject Amount should be grabbed' );
		System.assert( actualDecimalsMap.contains( notALot ), 'The sObject Amount should be grabbed' );
	}

	private static testMethod void grabIntegerTest()
	{
		Integer smallFirm = 60;
		Account smallAccount = new Account( NumberOfEmployees = smallFirm );

		Test.startTest();
			Integer actualInteger = grab.grabInteger( 'NumberOfEmployees', smallAccount );
		Test.stopTest();

		System.assertEquals( smallFirm, actualInteger, 'The sObject Employees should be grabbed' );
	}

	private static testMethod void grabIntegersIgnoresNulls()
	{
		Account smallAccount = new Account();

		Test.startTest();
			Set<Integer> actualIntegers = grab.integers( 'NumberOfEmployees', new List<sObject>{ smallAccount } );
		Test.stopTest();

		System.assert( actualIntegers.isEmpty(), 'null values should be ignored' );
	}

	private static testMethod void grabIntegersTest()
	{
		Integer smallFirm = 75;
		Integer mediumFirm = 90;
		Integer tinyFirm = 2;
		Account smallAccount = new Account( NumberOfEmployees = smallFirm );
		Account mediumAccount = new Account( NumberOfEmployees = mediumFirm );
		Account tinyAccount = new Account( NumberOfEmployees = tinyFirm );

		List<Account> allAccounts = new List<Account>{ smallAccount, mediumAccount, tinyAccount };
		Map<Id, Account> allAccountsMap = new Map<Id, Account>{
			'00Q0000000XXXXX' => smallAccount,
			'00Q0000000XXXXY' => mediumAccount,
			'00Q0000000XXXXZ' => tinyAccount
		};

		Test.startTest();
			Set<Integer> actualIntegersList = grab.integers( 'NumberOfEmployees', allAccounts );
			Set<Integer> actualIntegersMap = grab.integers( 'NumberOfEmployees', allAccountsMap );
		Test.stopTest();

		System.assert( actualIntegersList.contains( smallFirm ), 'The sObject Employees should be grabbed' );
		System.assert( actualIntegersList.contains( mediumFirm ), 'The sObject Employees should be grabbed' );
		System.assert( actualIntegersList.contains( tinyFirm ), 'The sObject Employees should be grabbed' );
		System.assert( actualIntegersMap.contains( smallFirm ), 'The sObject Employees should be grabbed' );
		System.assert( actualIntegersMap.contains( mediumFirm ), 'The sObject Employees should be grabbed' );
		System.assert( actualIntegersMap.contains( tinyFirm ), 'The sObject Employees should be grabbed' );
	}

	private static testMethod void grabIdTest()
	{
		Lead johnny = new Lead( Id = '00Q0000000XXXXX', FirstName = 'Johnny', LastName = 'Five', Company = 'Johnny Co' );

		Test.startTest();
			Id actualId = grab.grabId( 'Id', johnny );
		Test.stopTest();

		System.assertEquals( johnny.Id, actualId, 'The sObject id should be grabbed' );
	}

	private static testMethod void grabIdsIgnoresNulls()
	{
		Lead johnny = new Lead();

		Test.startTest();
			Set<Id> actualIds = grab.ids( 'Id', new List<sObject>{ johnny } );
		Test.stopTest();

		System.assert( actualIds.isEmpty(), 'null values should be ignored' );
	}

	private static testMethod void fieldToSObjects()
	{
		final Id OPPTY_1 = '0067000000Us9A1AAJ';
		final Id OPPTY_2 = '0069000000Us7U1AAN';
		OpportunityLineItem oppty1Product1 = new OpportunityLineItem( Id = '00k7000000N0aqdAAB', OpportunityId = OPPTY_1 );
		OpportunityLineItem oppty1Product2  = new OpportunityLineItem( Id = '00k7000000N0aqdAAC', OpportunityId = OPPTY_1 );
		OpportunityLineItem oppty2Product1  = new OpportunityLineItem( Id = '00k7000000N0aqdAAD', OpportunityId = OPPTY_2 );
		Map<Id, Set<sObject>> expectedOpptyToOLI = new Map<Id, Set<sObject>>{ OPPTY_1 => new Set<sObject>{oppty1Product1, oppty1Product2}, OPPTY_2 => new Set<sObject>{oppty2Product1} };

		Test.startTest();
			Map<Id, Set<sObject>> opptyToOLI = grab.fieldToSObjects( 'OpportunityId', new List<OpportunityLineItem>{oppty2Product1, oppty1Product1, oppty1Product2});
		Test.stopTest();
		System.assertEquals(2, opptyToOLI.size(), 'There are two distinct opportunity ids in this list of opportunity line items' + opptyToOLI);
		for( Id opptyId : opptyToOLI.keySet() )
		{
			System.assertEquals( true, expectedOpptyToOLI.containsKey( opptyId ) );
			System.assertEquals( expectedOpptyToOLI.get( opptyId ).size(), opptyToOLI.get( opptyId ).size(), 'The number of opportunity line items belonging to this opportunity is' + expectedOpptyToOLI + ':' + opptyToOLI);
			for(sObject oli : expectedOpptyToOLI.get( opptyId ) )
			{
				System.assertEquals( true, opptyToOLI.get( opptyId ).contains( oli ), 'The following opportunity should belong to this opportunity. Opportunity : ' + opptyId + ' oli ' + oli );
			}
		}
	}

	private static testMethod void grabIdsTest()
	{
		Lead johnny = new Lead( Id = '00Q0000000XXXX1', FirstName = 'Johnny', LastName = 'Five', Company = 'Johnny Co' );
		Lead julie  = new Lead( Id = '00Q0000000XXXX2', FirstName = 'Julie', LastName = 'Five', Company = 'Julie Co' );
		Lead jamby = new Lead( Id = '00Q0000000XXXX3', FirstName = 'Jamby', LastName = 'Five', Company = 'Jamby Co' );

		List<Lead> allLeads = new List<Lead>{ johnny, julie, jamby };
		Map<Id, Lead> allLeadsMap = new Map<Id, Lead>{
			'00Q0000000XXXXX' => johnny,
			'00Q0000000XXXXY' => julie,
			'00Q0000000XXXXZ' => jamby
		};

		Test.startTest();
			Set<Id> actualIdsList = grab.ids( 'Id', allLeads );
			Set<Id> actualIdsMap = grab.ids( 'Id', allLeadsMap );
		Test.stopTest();

		System.assert( actualIdsList.contains( johnny.Id ), 'The Ids of the sObjects should be grabbed' );
		System.assert( actualIdsList.contains( julie.Id ), 'The Ids of the sObjects should be grabbed' );
		System.assert( actualIdsList.contains( jamby.Id ), 'The Ids of the sObjects should be grabbed' );
		System.assert( actualIdsMap.contains( johnny.Id ), 'The Ids of the sObjects should be grabbed' );
		System.assert( actualIdsMap.contains( julie.Id ), 'The Ids of the sObjects should be grabbed' );
		System.assert( actualIdsMap.contains( jamby.Id ), 'The Ids of the sObjects should be grabbed' );
	}

	private static testMethod void grabIdsModifySetTest()
	{
		Lead julie  = new Lead( Id = '00Q0000000XXXX2', FirstName = 'Julie', LastName = 'Five', Company = 'Julie Co' );
		Lead jamby = new Lead( Id = '00Q0000000XXXX3', FirstName = 'Jamby', LastName = 'Five', Company = 'Jamby Co' );

		List<Lead> allLeads = new List<Lead>{  julie };

		Test.startTest();
			Set<Id> idsList = grab.ids( allLeads );


			idsList.add(jamby.Id);
		Test.stopTest();

        System.assertEquals( 2, idsList.size(), 'The Set returned from grab.ids should be modifiable');
	}

	private static testMethod void grabIdsAssumeIdField()
	{
		Lead jamby = new Lead( Id = '00Q0000000XXXX3', FirstName = 'Jamby', LastName = 'Five', Company = 'Jamby Co' );

		List<Lead> allLeadsList = new List<Lead>{ jamby };
		Map<Id, Lead> allLeadsMap = new Map<Id, Lead>{ '00Q0000000XXXXX' => jamby };

		Test.startTest();
			Set<Id> actualIdsList = grab.ids( allLeadsList );
			Set<Id> actualIdsMap = grab.ids( allLeadsMap );
		Test.stopTest();

		System.assert( actualIdsList.contains( jamby.Id ), 'The Ids of the sObjects should be grabbed from the list' );
		System.assert( actualIdsMap.contains( jamby.Id ), 'The Ids of the sObjects should be grabbed from the map' );
	}

	private static testMethod void grabIdsAssumeIdField_Duplicates()
	{
		final Id DUMMY_LEAD_ID = '00Q0000000XXXX3';
		Lead jamby = new Lead( Id = DUMMY_LEAD_ID, FirstName = 'Jamby', LastName = 'Five', Company = 'Jamby Co' );
		Lead jambyDupe = new Lead( Id = DUMMY_LEAD_ID, FirstName = 'Jamby', LastName = 'Five', Company = 'Jamby Co' );

		List<Lead> allLeadsList = new List<Lead>{ jamby, jambyDupe };

		ListException unexpectedListEx;
		Set<Id> actualIds;
		Test.startTest();
			try
			{
				actualIds = grab.ids( allLeadsList );
			}
			catch( ListException listEx )
			{
				unexpectedListEx = listEx;
			}
		Test.stopTest();
		System.assertEquals( null, unexpectedListEx, 'There should be no list exception' );
		System.assert( actualIds.contains( jamby.Id ), 'The Ids of the sObjects should be grabbed from the list' );
	}

	private static testMethod void grabStringTest()
	{
		Lead johnny = new Lead( FirstName = 'Johnny', LastName = 'Five', Company = 'Johnny Co' );

		Test.startTest();
			String actualName = grab.grabString( 'FirstName', johnny );
		Test.stopTest();

		System.assertEquals( johnny.FirstName, actualName, 'The sObject Name should be grabbed' );
	}

	private static testMethod void grabStringsIgnoresNulls()
	{
		Lead johnny = new Lead();

		Test.startTest();
			Set<String> actualStrings = grab.strings( 'FirstName', new List<sObject>{ johnny } );
		Test.stopTest();

		System.assert( actualStrings.isEmpty(), 'null values should be ignored' );
	}

	private static testMethod void grabStringsTest()
	{
		Lead johnny = new Lead( FirstName = 'Johnny', LastName = 'Five', Company = 'Johnny Co' );
		Lead julie  = new Lead( FirstName = 'Julie', LastName = 'Five', Company = 'Julie Co' );
		Lead jamby = new Lead( FirstName = 'Jamby', LastName = 'Five', Company = 'Jamby Co' );

		List<Lead> allLeads = new List<Lead>{ johnny, julie, jamby };
		Map<Id, Lead> allLeadsMap = new Map<Id, Lead>{
			'00Q0000000XXXXX' => johnny,
			'00Q0000000XXXXY' => julie,
			'00Q0000000XXXXZ' => jamby
		};

		Test.startTest();
			Set<String> actualNamesList = grab.strings( 'FirstName', allLeads );
			Set<String> actualNamesMap = grab.strings( 'FirstName', allLeadsMap );
		Test.stopTest();

		System.assert( actualNamesList.contains( johnny.FirstName ), 'The FirstNames of the sObjects should be grabbed' );
		System.assert( actualNamesList.contains( julie.FirstName ), 'The FirstNames of the sObjects should be grabbed' );
		System.assert( actualNamesList.contains( jamby.FirstName ), 'The FirstNames of the sObjects should be grabbed' );
		System.assert( actualNamesMap.contains( johnny.FirstName ), 'The FirstNames of the sObjects should be grabbed' );
		System.assert( actualNamesMap.contains( julie.FirstName ), 'The FirstNames of the sObjects should be grabbed' );
		System.assert( actualNamesMap.contains( jamby.FirstName ), 'The FirstNames of the sObjects should be grabbed' );
	}
}