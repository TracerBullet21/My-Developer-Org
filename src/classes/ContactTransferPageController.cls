public with sharing class ContactTransferPageController extends PageControllerBase{
	
	public List<ContactWrapper> contacts {get;set;}

	private ApexPages.StandardController stdCtrl;
  	@TestVisible private transient List<String> messages;
	@TestVisible private static String DESTINATION_ACCOUNT_MSG = 'Please select a destination account.';
	@TestVisible private static String SELECT_ONE_CONTACT_MSG = 'Please select at least one Contact.';

	/*
	* Methods used to access custom lookup controller functionality
	*/
	@TestVisible private SLDSLookupController lookupController;
	public override void setComponentController(ComponentControllerBase compController) {
		lookupController = (SLDSLookupController)compController;
	}


	public ContactTransferPageController( ApexPages.StandardController stdCtrl)
	{
		contacts = new List<ContactWrapper>();
		this.stdCtrl = stdCtrl;
		search( stdCtrl.getId() );
	}

	private PageReference search( Id accountId )
	{
		List<String> selectClause = new List<String>();
		for ( Schema.FieldSetMember fieldMember : SObjectType.Contact.FieldSets.Transfer_Fields.getFields() )
			selectClause.add( fieldMember.getFieldPath() );

		String query = 'SELECT ' + String.join( selectClause, ',' ) + ' FROM Contact WHERE AccountId = :accountId';

		for ( Contact contact : (List<Contact>)Database.query( query ) )
			contacts.add( new ContactWrapper( contact ) );
		
		return null;
	}

	public PageReference transferContacts()
	{
		Id lookupRecordId = lookupController.getLookupId();
		if ( lookupRecordId == null ){
			addMessage( DESTINATION_ACCOUNT_MSG );
			return null;
		}

		List<Contact> contactsToUpdate = new List<Contact>();
		for ( ContactWrapper conWrapper : contacts ){
			if ( conWrapper.isSelected ){
				conWrapper.contact.AccountId = lookupRecordId;
				contactsToUpdate.add( conWrapper.contact );
			}
		}

		if ( contactsToUpdate.isEmpty() ){
			addMessage( SELECT_ONE_CONTACT_MSG );
			return null;
		}

		try{
			update contactsToUpdate;
		}
		catch( DmlException dmlEx ){
			ApexPages.addMessages(dmlEx);
			return null;
		}

		return new PageReference( '/' + lookupRecordId );
	}

	@TestVisible
	private void addMessage(String msg)
	{
		if (this.messages == null)
			this.messages = new List<String>();

		this.messages.add(msg);
	}

	public List<String> getMessages()
	{
		if (this.messages == null)
			this.messages = new List<String>();

		// If a page error is found, output to logs and inform user
		for (ApexPages.Message message : ApexPages.getMessages()){
			addMessage(message.getSummary());
		}

		return this.messages;
	}

	@TestVisible
	private class ContactWrapper
	{
		public Boolean isSelected{get;set;}
		public Contact contact{get;set;}

		public ContactWrapper( Contact contact )
		{
			this.contact = contact;
			this.isSelected = false;
		}
	}
}