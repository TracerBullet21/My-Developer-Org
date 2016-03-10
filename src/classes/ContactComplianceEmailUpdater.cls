public class ContactComplianceEmailUpdater
{
	private List<Account> allRelatedAccounts;
	private List<Contact> allRelatedContacts;
	private Set<Id> triggerContactIds;

	public ContactComplianceEmailUpdater( List<Contact> contacts )
	{
		List<Contact> filteredContacts = filterComplianceContacts(contacts);
		this.triggerContactIds = Grab.ids(filteredContacts);
		updateTriggeringRecords( filteredContacts );
		getRelatedAccountsAndContacts( filteredContacts );
	}

	@testVisible private Map<Id, AccountWrapper> getRelatedAccountsAndContacts( List<Contact> filteredContacts )
	{
		this.allRelatedAccounts = new List<Account>();
		this.allRelatedContacts = new List<Contact>();
		return buildAccountWrappers( Grab.ids('AccountId', filteredContacts), new Map<Id, AccountWrapper>() );
	}
	

	private Map<Id, AccountWrapper> buildAccountWrappers( Set<Id> accountIds, Map<Id, AccountWrapper> accountIdToWrapper )
	{
		if ( accountIds.isEmpty() )
			return accountIdToWrapper;

		List<Account> contactsAccounts = [ SELECT Compliance_Email_Address__c, ParentId,
											(SELECT Compliance_Email_Address__c FROM Contacts WHERE Id NOT IN :this.triggerContactIds),
											(SELECT Compliance_Email_Address__c FROM ChildAccounts)
											FROM Account 
											WHERE Id IN :accountIds ];

		System.debug( LoggingLevel.ERROR, 'contactsAccounts.size(): ' + contactsAccounts.size() );

		for ( Account acc : contactsAccounts )
		{
			AccountWrapper tempWrapper = new AccountWrapper();
			tempWrapper.childContacts = acc.Contacts;
			tempWrapper.accountObj = acc;

			AccountWrapper parentAccount = findAccountWrapper( accountIdToWrapper.values(), acc.ParentId );
			if ( parentAccount != null )
				parentAccount.childAccounts.add( tempWrapper );
			else
				accountIdToWrapper.put( acc.Id, tempWrapper );

			//accountIdToWrapper.put( acc.Id, tempWrapper );
			
			tempWrapper.childAccounts = buildAccountWrappers(Grab.ids(acc.ChildAccounts), accountIdToWrapper).values();
		}
		return accountIdToWrapper;
	}

	//private AccountWrapper findAccountWrapper( Id parentAccountId, Map<Id, AccountWrapper> accountIdToWrapper )
	//{
	//	if ( parentAccountId == null )
	//		return new AccountWrapper();

	//	Map<Id, AccountWrapper> wrappers = new List<AccountWrapper> (accountIdToWrapper.values());
	//	Boolean foundAccount = false;
	//	while( !foundAccount )
	//	{
	//		for ( AccountWrapper wrapper : wrappers )
	//		{
	//			if ( wrapper.accountObj.Id == parentAccountId )
	//				return 
	//		}
	//	}
	//}

	@testVisible private static AccountWrapper findAccountWrapper( List<AccountWrapper> wrappers, Id parentId  )
	{
		AccountWrapper foundWrapper;
		for ( AccountWrapper wrapper : wrappers )
		{
			if( wrapper.accountObj.Id == parentId )
				return wrapper;

			foundWrapper = findAccountWrapper( wrapper.childAccounts, parentId );

			if ( foundWrapper != null )
				break;
		}
		return foundWrapper;
	}

	private void updateTriggeringRecords( List<Contact> validContacts )
	{
		for ( Contact con : validContacts )
			con.Compliance_Email_Address__c = con.Email;
	}

	private List<Contact> filterComplianceContacts( List<Contact> contacts )
	{
		List<Contact> filteredContacts = new List<Contact>();
		for ( Contact con : contacts )
		{
			if ( con.Compliance_Contact__c == TRUE && String.isNotBlank(con.Email) )
				filteredContacts.add( con );
		}
		return filteredContacts;
	}

	@testVisible private class AccountWrapper
	{
		public Account accountObj;
		public List<Contact> childContacts;
		public List<AccountWrapper> childAccounts;

		public AccountWrapper()
		{
			this.accountObj = new Account();
			this.childContacts = new List<Contact>();
			this.childAccounts = new List<AccountWrapper>();
		}
	}
}