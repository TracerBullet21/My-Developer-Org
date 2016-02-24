@isTest
private class ContractTransferPageControllerTests
{
	static testMethod void testConstructor()
	{
		Id agencyRecordTypeId = [ SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Agency' ].Id;
		final Integer NUM_CONTACTS = 100;

		Account testAccount = new Account();
		testAccount.Name = 'Test Acc';
		testAccount.RecordTypeId = agencyRecordTypeId;
		insert testAccount;

		List<Contact> contacts = new List<Contact>();
		for ( Integer i=0; i<NUM_CONTACTS; i++ )
		{
			Contact con = new Contact();
			con.AccountId = testAccount.Id;
			con.LastName = 'Test Name';
			contacts.add( con );
		}
		insert contacts;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController( testAccount );

		Test.startTest();
			ContactTransferPageController ctrl = new ContactTransferPageController( stdCtrl );
		Test.stopTest();
		
		System.assertNotEquals( null, ctrl, 'We expect the controller to not be null' );
		System.assertNotEquals( null, ctrl.contacts, 'We expect the list of contacts to not be null' );
		System.assertEquals( NUM_CONTACTS, ctrl.contacts.size(), 'We expect the list of contacts to be populated' );

		for ( ContactTransferPageController.ContactWrapper wrapper : ctrl.contacts )
		{
			System.assertEquals( false, wrapper.isSelected, 'Each contact should not be selected' );
			System.assertNotEquals( null, wrapper.contact, 'Each contact should not be null' );

		}
	}

	static testMethod void testTransferContacts()
	{
		Account testAccount = new Account();
		ApexPages.StandardController stdCtrl = new ApexPages.StandardController( testAccount );
		ContactTransferPageController ctrl = new ContactTransferPageController( stdCtrl );

		SLDSLookupController lookupCtrl = new SLDSLookupController();

		Test.startTest();
 			ctrl.setComponentController(lookupCtrl);
		Test.stopTest();

		System.assertNotEquals( null, ctrl.lookupController, 'The lookup controller should not be null' );
	}

	static testMethod void testTransferContacts_success()
	{
		Id agencyRecordTypeId = [ SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Agency' ].Id;
		final Integer NUM_CONTACTS = 5;

		Account originalAccount = new Account();
		originalAccount.Name = 'Test Acc';
		originalAccount.RecordTypeId = agencyRecordTypeId;
		insert originalAccount;

		Account destinationAccount = new Account();
		destinationAccount.Name = 'Test Acc';
		destinationAccount.RecordTypeId = agencyRecordTypeId;
		insert destinationAccount;

		List<Contact> contacts = new List<Contact>();
		for ( Integer i=0; i<NUM_CONTACTS; i++ )
		{
			Contact con = new Contact();
			con.AccountId = originalAccount.Id;
			con.LastName = 'Test Name';
			contacts.add( con );
		}
		insert contacts;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController( originalAccount );
		ContactTransferPageController ctrl = new ContactTransferPageController( stdCtrl );
		
		ctrl.contacts[0].isSelected = true;
		final Id SELECTED_CONTACT_ID = ctrl.contacts[0].contact.Id;

		SLDSLookupController lookupCtrl = new SLDSLookupController();
		lookupCtrl.objectId = destinationAccount.Id;
		ctrl.setComponentController(lookupCtrl);

		Test.startTest();
			ctrl.transferContacts();
		Test.stopTest();
		
		List<Contact> queriedContacts = [ SELECT Id, AccountId FROM Contact WHERE Id =: SELECTED_CONTACT_ID ];
		System.assertEquals( 1, queriedContacts.size(), 'We expect to get a single contact back' );
		System.assertEquals( destinationAccount.Id, queriedContacts[0].AccountId, 'The contact should be mapped to the destination account' );
	}

	static testMethod void testTransferContacts_noSelectedAccount()
	{
		Id agencyRecordTypeId = [ SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Agency' ].Id;
		final Integer NUM_CONTACTS = 5;

		Account originalAccount = new Account();
		originalAccount.Name = 'Test Acc';
		originalAccount.RecordTypeId = agencyRecordTypeId;
		insert originalAccount;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController( originalAccount );
		ContactTransferPageController ctrl = new ContactTransferPageController( stdCtrl );

		SLDSLookupController lookupCtrl = new SLDSLookupController();
		ctrl.setComponentController(lookupCtrl);

		Test.startTest();
			ctrl.transferContacts();
		Test.stopTest();
		
		List<String> messages = ctrl.messages;
		System.assertEquals( 1, messages.size(), 'We expect a single message to be added' );
		System.assert( messages[0].contains(ContactTransferPageController.DESTINATION_ACCOUNT_MSG), 'We expect the correct error message to be added to the page' );
	}

	static testMethod void testTransferContacts_noSelectedContact()
	{
		Id agencyRecordTypeId = [ SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Agency' ].Id;
		final Integer NUM_CONTACTS = 5;

		Account testAccount = new Account();
		testAccount.Name = 'Test Acc';
		testAccount.RecordTypeId = agencyRecordTypeId;
		insert testAccount;

		List<Contact> contacts = new List<Contact>();
		for ( Integer i=0; i<NUM_CONTACTS; i++ )
		{
			Contact con = new Contact();
			con.AccountId = testAccount.Id;
			con.LastName = 'Test Name';
			contacts.add( con );
		}
		insert contacts;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController( testAccount );
		ContactTransferPageController ctrl = new ContactTransferPageController( stdCtrl );

		SLDSLookupController lookupCtrl = new SLDSLookupController();
		lookupCtrl.objectId = testAccount.Id;
		ctrl.setComponentController(lookupCtrl);

		Test.startTest();
			ctrl.transferContacts();
		Test.stopTest();
		
		List<String> messages = ctrl.messages;
		System.assertEquals( 1, messages.size(), 'We expect a single message to be added' );
		System.assert( messages[0].contains(ContactTransferPageController.SELECT_ONE_CONTACT_MSG), 'We expect the correct error message to be added to the page' );
	}

	static testMethod void testTransferContacts_exception()
	{
		Id agencyRecordTypeId = [ SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Agency' ].Id;
		final Integer NUM_CONTACTS = 5;

		Account originalAccount = new Account();
		originalAccount.Name = 'Test Acc';
		originalAccount.RecordTypeId = agencyRecordTypeId;
		insert originalAccount;

		List<Contact> contacts = new List<Contact>();
		for ( Integer i=0; i<NUM_CONTACTS; i++ )
		{
			Contact con = new Contact();
			con.AccountId = originalAccount.Id;
			con.LastName = 'Test Name';
			contacts.add( con );
		}
		insert contacts;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController( originalAccount );
		ContactTransferPageController ctrl = new ContactTransferPageController( stdCtrl );
		
		ctrl.contacts[0].isSelected = true;
		final Id SELECTED_CONTACT_ID = ctrl.contacts[0].contact.Id;

		SLDSLookupController lookupCtrl = new SLDSLookupController();
		lookupCtrl.objectId = Account.sobjecttype.getDescribe().getKeyPrefix() + '0'.repeat(15);
		ctrl.setComponentController(lookupCtrl);

		Test.startTest();
			ctrl.transferContacts();
		Test.stopTest();
		
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		System.assertEquals( 1, msgs.size(), 'We expect there to be a single message on the page' );
	}

	private static testMethod void testGetMessages()
	{
		Id agencyRecordTypeId = [ SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Agency' ].Id;
		final Integer NUM_CONTACTS = 100;

		Account testAccount = new Account();
		testAccount.Name = 'Test Acc';
		testAccount.RecordTypeId = agencyRecordTypeId;
		insert testAccount;

		List<Contact> contacts = new List<Contact>();
		for ( Integer i=0; i<NUM_CONTACTS; i++ )
		{
			Contact con = new Contact();
			con.AccountId = testAccount.Id;
			con.LastName = 'Test Name';
			contacts.add( con );
		}
		insert contacts;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController( testAccount );
		ContactTransferPageController ctrl = new ContactTransferPageController( stdCtrl );

		final String EXPECTED_ERROR_MESSAGE = 'my error msg';
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, EXPECTED_ERROR_MESSAGE));

		Test.startTest();
			ctrl.getMessages();
		Test.stopTest();

		System.assertEquals( 1, ctrl.messages.size(), 'We expect a single message to be gathered' );
		System.assertEquals( EXPECTED_ERROR_MESSAGE, ctrl.messages[0], 'We expect the correct message to be added' );
	}
}