@isTest
private class ExceptionHandlerTests
{
	static testMethod void testHandleBasicException_differing_trigger_obj()
	{
		Account testAccount = new Account( Id = TestingUtilities.getFakeId( Account.sObjectType ) );

		Contact testContact = new Contact( AccountId = testAccount.Id );

		Exception ex;
		try{
			update testContact;
		}
		catch( Exception e )
		{
			ex = e;
		}

		Test.startTest();
			ExceptionHandler.handleBasicException(new List<SObject>{testAccount}, new List<SObject>{testContact}, 'AccountId', ex);
		Test.stopTest();

		System.assert( ApexPages.hasMessages(), 'We expect an error to be added to the page.' );
	}

	static testMethod void testHandleBasicException_one_to_one()
	{
		final Integer NUM_ACCOUNTS = 200;
		List<Account> testAccounts = new List<Account>();

		for( Integer i=0; i<NUM_ACCOUNTS; i++ )
			testAccounts.add( new Account( Id = TestingUtilities.getFakeId( Account.sObjectType ) ) );


		Exception ex;
		try{
			update testAccounts;
		}
		catch( Exception e )
		{
			ex = e;
		}

		Test.startTest();
			ExceptionHandler.handleBasicException( testAccounts, ex);
		Test.stopTest();

		System.assert( ApexPages.hasMessages(), 'We expect an error to be added to the page.' );
	}

}