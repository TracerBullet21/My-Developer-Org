@isTest
private class ContactComplianceEmailUpdaterTests
{
	static testMethod void testGetRelatedAccountsAndContacts_bulk()
	{
		final Integer NUM_OF_CONTACTS = 3;
		final Integer NUM_ORIGINAL_ACCOUNTS = 10;
		final Integer NUM_CHILD_ACCOUNTS = 5;

		List<Account> originalAccounts = new List<Account>();
		for ( Integer i=0; i<NUM_ORIGINAL_ACCOUNTS; i++ )
		{
			originalAccounts.add( new Account( Name = 'originalAccount' + i ) );
		}
		insert originalAccounts;
		Set<Id> originalAccountIds = Grab.ids( originalAccounts );

		List<Account> children = new List<Account>();
		for ( Account acc : originalAccounts )
		{	
			for ( Integer i=0; i<NUM_CHILD_ACCOUNTS; i++ )
			{
				Account child = new Account();
				child.Name = acc.Name + ' - TestAcc' +  i;
				child.ParentId = acc.Id;
				children.add( child );
			}
		}
		insert children;
		Set<Id> childIds = Grab.ids( children );

		List<Account> grandChildren = new List<Account>();
		for ( Account child : children )
		{
			for ( Integer i=0; i<NUM_CHILD_ACCOUNTS; i++ )
			{
				Account grandChild = new Account();
				grandChild.Name = child.Name + ' - TestAcc' +  i;
				grandChild.ParentId = child.Id;
				grandChildren.add(grandChild);
			}
		}
		insert grandChildren;
		Set<Id> grandChildIds = Grab.ids( grandChildren );

		List<Account> allAccounts = new List<Account>(originalAccounts);
		allAccounts.addAll( children );
		allAccounts.addAll( grandChildren );

		List<Contact> allContacts = TestingUtilities.buildContacts(allAccounts, NUM_OF_CONTACTS);
		insert allContacts;

		List<Contact> originalContacts = [SELECT AccountId FROM Contact WHERE AccountId IN :originalAccountIds ];
		ContactComplianceEmailUpdater updater = new ContactComplianceEmailUpdater(new List<Contact>());
		Test.startTest();
			Map<Id, ContactComplianceEmailUpdater.AccountWrapper> accountWrappers = updater.getRelatedAccountsAndContacts( originalContacts );
		Test.stopTest();

		System.assertEquals( NUM_ORIGINAL_ACCOUNTS, accountWrappers.size(), 'The map should contain one entry for each original account' );

		System.assert( accountWrappers.keySet().containsAll(originalAccountIds), 'The map should contain all the original account Ids' );
		System.assert( originalAccountIds.containsAll( accountWrappers.keySet() ), 'The map should contain all the original account Ids' );

		Set<Id> accountIds = Grab.ids(allAccounts);
		for ( ContactComplianceEmailUpdater.AccountWrapper wrapper : accountWrappers.values() )
		{
			System.assertEquals( NUM_OF_CONTACTS, wrapper.childContacts.size(), 'Each wrapper should have the expected number of contacts' );
			System.assertNotEquals( null, wrapper.accountObj, 'The account object should not be null' );
			System.assertEquals( TRUE, originalAccountIds.contains(wrapper.accountObj.Id), 'The account wrapper should contain the correct account' );
			System.assertEquals( NUM_CHILD_ACCOUNTS, wrapper.childAccounts.size(), 'Each account wrapper should have the correct number of related children' );
			for ( ContactComplianceEmailUpdater.AccountWrapper childWrapper : wrapper.childAccounts )
			{			
				System.assertEquals( NUM_OF_CONTACTS, childWrapper.childContacts.size(), 'Each childWrapper should have the expected number of contacts' );
				System.assertNotEquals( null, childWrapper.accountObj, 'The account object should not be null' );
				System.assertEquals( TRUE, childIds.contains(childWrapper.accountObj.Id), 'The account childWrapper should contain the correct account' );
				System.assertEquals( NUM_CHILD_ACCOUNTS, childWrapper.childAccounts.size(), 'Each account childWrapper should have the correct number of related children' );
				for ( ContactComplianceEmailUpdater.AccountWrapper grandChildWrapper : childWrapper.childAccounts )
				{
					System.assertEquals( NUM_OF_CONTACTS, grandChildWrapper.childContacts.size(), 'Each grandChildWrapper should have the expected number of contacts' );
					System.assertNotEquals( null, grandChildWrapper.accountObj, 'The account object should not be null' );
					System.assertEquals( TRUE, grandChildIds.contains(grandChildWrapper.accountObj.Id), 'The account grandChildWrapper should contain the correct account' );
					System.assertEquals( TRUE, grandChildWrapper.childAccounts.isEmpty(), 'Each account grandChildWrapper should have the correct number of related children' );
				}
			}
		}
	}

	static testMethod void testGetRelatedAccountsAndContacts_multipleRelationships()
	{
		final Integer NUM_OF_ACCOUNT_RELATIONSHIPS = 5;
		final Integer NUM_OF_CONTACTS = 10;

		Account originalAccount = new Account( Name = 'originalAccount' );
		insert originalAccount;
		
		List<Contact> contacts = new List<Contact>();
		contacts.addAll( TestingUtilities.buildContacts( originalAccount.Id, NUM_OF_CONTACTS ) );
		Contact originalContact = contacts[0];

		List<Account> accounts = new List<Account>{originalAccount};
		for ( Integer i=0; i<NUM_OF_ACCOUNT_RELATIONSHIPS - 1; i++ )
		{
			Account acc = new Account();
			acc.Name = 'TestAcc' + i;
			acc.ParentId = accounts[i].Id;
			insert acc;
			accounts.add( acc );

			contacts.addAll( TestingUtilities.buildContacts( acc.Id, NUM_OF_CONTACTS ) );
		}
		insert contacts;

		ContactComplianceEmailUpdater updater = new ContactComplianceEmailUpdater(new List<Contact>());
		Test.startTest();
			Map<Id, ContactComplianceEmailUpdater.AccountWrapper> accountWrappers = updater.getRelatedAccountsAndContacts( new List<Contact>{originalContact} );
		Test.stopTest();

		System.assertEquals( 1, accountWrappers.size(), 'The map should contain a single entry' );
		System.assert( accountWrappers.containsKey( originalAccount.Id ), 'The map should contain the original account' );

		ContactComplianceEmailUpdater.AccountWrapper wrapper = accountWrappers.get( originalAccount.Id );

		for ( Integer i=0; i<NUM_OF_ACCOUNT_RELATIONSHIPS - 1; i++ )
		{
			System.assertEquals( NUM_OF_CONTACTS, wrapper.childContacts.size(), 'Each wrapper should have the expected number of contacts' );
			System.assertNotEquals( null, wrapper.accountObj, 'The account object should not be null' );
			System.assertEquals( 1, wrapper.childAccounts.size(), 'Each account wrapper should have a single related child' );
			wrapper = wrapper.childAccounts[0];
		}

		System.assertNotEquals( null, wrapper, 'There should be the correct number of relationships retrieved' );
	}


	static Account grandParentAccount = new Account( Id = TestingUtilities.getFakeId(Account.getSObjectType()) );

	static List<Account> parentAccounts = new List<Account>{ new Account( Id = TestingUtilities.getFakeId(Account.getSObjectType()) ),
														new Account( Id = TestingUtilities.getFakeId(Account.getSObjectType()) ) };

	static List<Account> childAccounts = new List<Account>{ new Account( Id = TestingUtilities.getFakeId(Account.getSObjectType()) ), 
														new Account( Id = TestingUtilities.getFakeId(Account.getSObjectType()) ), 
														new Account( Id = TestingUtilities.getFakeId(Account.getSObjectType()) ) };

	static List<ContactComplianceEmailUpdater.AccountWrapper> buildAccountWrappers()
	{
		ContactComplianceEmailUpdater.AccountWrapper childWrapper1 = new ContactComplianceEmailUpdater.AccountWrapper();
		childWrapper1.accountObj = childAccounts[0];

		ContactComplianceEmailUpdater.AccountWrapper childWrapper2 = new ContactComplianceEmailUpdater.AccountWrapper();
		childWrapper2.accountObj = childAccounts[1];

		ContactComplianceEmailUpdater.AccountWrapper childWrapper3 = new ContactComplianceEmailUpdater.AccountWrapper();
		childWrapper3.accountObj = childAccounts[2];
		List<ContactComplianceEmailUpdater.AccountWrapper> childWrapperList = new List<ContactComplianceEmailUpdater.AccountWrapper>{childWrapper1, childWrapper2, childWrapper3};

		ContactComplianceEmailUpdater.AccountWrapper parentWrapper1 = new ContactComplianceEmailUpdater.AccountWrapper();
		parentWrapper1.accountObj = parentAccounts[0];

		ContactComplianceEmailUpdater.AccountWrapper parentWrapper2 = new ContactComplianceEmailUpdater.AccountWrapper();
		parentWrapper2.accountObj = parentAccounts[1];
		parentWrapper2.childAccounts = childWrapperList;

		List<ContactComplianceEmailUpdater.AccountWrapper> parentWrappers = new List<ContactComplianceEmailUpdater.AccountWrapper>{parentWrapper1, parentWrapper2};

		ContactComplianceEmailUpdater.AccountWrapper grandParentWrapper = new ContactComplianceEmailUpdater.AccountWrapper();
		grandParentWrapper.accountObj = grandParentAccount;
		grandParentWrapper.childAccounts = parentWrappers;

		Account otherAccount = new Account( Id = TestingUtilities.getFakeId(Account.getSObjectType()) );
		ContactComplianceEmailUpdater.AccountWrapper otherWrapper = new ContactComplianceEmailUpdater.AccountWrapper();
		otherWrapper.accountObj = otherAccount;

		Account otherAccount2 = new Account( Id = TestingUtilities.getFakeId(Account.getSObjectType()) );
		ContactComplianceEmailUpdater.AccountWrapper otherWrapper2 = new ContactComplianceEmailUpdater.AccountWrapper();
		otherWrapper2.accountObj = otherAccount2;
		return new List<ContactComplianceEmailUpdater.AccountWrapper>{ otherWrapper, grandParentWrapper, otherWrapper2 };
	}

	static /*testMethod*/ void testGetAccountWrapper()
	{
		List<ContactComplianceEmailUpdater.AccountWrapper> wrapperList = buildAccountWrappers();
		Id desiredObjectId = parentAccounts[0].Id;

		Test.startTest();
			ContactComplianceEmailUpdater.AccountWrapper foundWrapper = ContactComplianceEmailUpdater.findAccountWrapper( wrapperList, desiredObjectId );
		Test.stopTest();

		System.assertNotEquals( null, foundWrapper, 'We expect to get a non-null wrapper back');
		System.assertNotEquals( null, foundWrapper.accountObj, 'We expect the wrapper to have a non-null account object');
		System.assertEquals( desiredObjectId, foundWrapper.accountObj.Id, 'We expect to get the correct wrapper');
	}

	static /*testMethod*/ void testGetAccountWrapper_findGrandChild()
	{
		List<ContactComplianceEmailUpdater.AccountWrapper> wrapperList = buildAccountWrappers();
		Id desiredObjectId = childAccounts[2].Id;

		Test.startTest();
			ContactComplianceEmailUpdater.AccountWrapper foundWrapper = ContactComplianceEmailUpdater.findAccountWrapper( wrapperList, desiredObjectId );
		Test.stopTest();

		System.assertNotEquals( null, foundWrapper, 'We expect to get a non-null wrapper back');
		System.assertNotEquals( null, foundWrapper.accountObj, 'We expect the wrapper to have a non-null account object');
		System.assertEquals( desiredObjectId, foundWrapper.accountObj.Id, 'We expect to get the correct wrapper');
	}

	static /*testMethod*/ void testGetAccountWrapper_firstLevel()
	{
		List<ContactComplianceEmailUpdater.AccountWrapper> wrapperList = buildAccountWrappers();
		Id desiredObjectId = grandParentAccount.Id;

		Test.startTest();
			ContactComplianceEmailUpdater.AccountWrapper foundWrapper = ContactComplianceEmailUpdater.findAccountWrapper( wrapperList, desiredObjectId );
		Test.stopTest();

		System.assertNotEquals( null, foundWrapper, 'We expect to get a non-null wrapper back');
		System.assertNotEquals( null, foundWrapper.accountObj, 'We expect the wrapper to have a non-null account object');
		System.assertEquals( desiredObjectId, foundWrapper.accountObj.Id, 'We expect to get the correct wrapper');
	}

	static /*testMethod*/ void testGetAccountWrapper_nothingFound()
	{
		List<ContactComplianceEmailUpdater.AccountWrapper> wrapperList = buildAccountWrappers();
		Id desiredObjectId = TestingUtilities.getFakeId(Account.getSObjectType());

		Test.startTest();
			ContactComplianceEmailUpdater.AccountWrapper foundWrapper = ContactComplianceEmailUpdater.findAccountWrapper( wrapperList, desiredObjectId );
		Test.stopTest();

		System.assertEquals( null, foundWrapper, 'We expect to get a null wrapper back');
	}
}