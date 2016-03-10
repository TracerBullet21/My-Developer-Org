/**
 * Utility class for Customer Self Service Community sharing records functionality. Methods in this
 * record sharing utility class can return exceptions, so please double check error handling when
 * calling these methods.
 * 
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_ShareRecordService
 */
public without sharing class CSS_ShareRecordUtility {

  /** Partner user licenses for the Customer Self Service Community  */
  public static final List<String> PARTNER_LICENSES = new List<String> {'Partner Community'};

  /** Custom permission for viewing SAP Invoices */
  public static final String PERMISSION_VIEW_SAP_INVOICES = 'CSS_View_SAP_Invoices';

  /** Custom permission for viewing Case Complaints */
  public static final String PERMISSION_VIEW_COMPLAINTS = 'CSS_View_Complaints';


  /**
   * Given a custom permission and a list of licenses (defined above), the Find Grantees method 
   * returns a complete set of active partner users who are granted access to the given permission, 
   * which should be less than 1,000.
   *
   * @param permission the custom permission to query for and find associated grantees
   * @return a complete set of partner users that are granted the given custom permission
   */
  public static Set<Id> findGranteesByPermission(String permission) {
    Set<Id> grantees = new Set<Id>(); // a set has to be used instead of a list to prevent dups
    
    // First, find permission id for given custom permission
    List<CustomPermission> permissions = 
      [SELECT Id FROM CustomPermission WHERE DeveloperName = :permission];
    
    // Second, using the permission id, find all partner users with the given permission
    if (!permissions.isEmpty()) {
      String permissionId = permissions[0].Id;
    
      // Find active users granted access to given custom permission
      for (PermissionSetAssignment assignment : [
        SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN (
          SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId = :permissionId)
        AND Assignee.isActive = true AND Assignee.Profile.UserLicense.Name = :PARTNER_LICENSES]) {
        
        // Gather all the active partner users granted access
        grantees.add(assignment.AssigneeId);
      }
    }
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordUtility - Found Grantees: ' + grantees);
    return grantees; 
  }

  /**
   * Retreive a list of active community partner users under the given accounts. For example, this
   * method will return all the community partner users under both a "ship to" and "sold to"
   * account if both accounts are passed in via the accounts list. 
   *
   * Triggers should cache the returned user list when calling shareOrders, shareSAPInvoices, 
   * and shareCases.
   *
   * @param childIds a list of accounts identifiers (i.e., ship to, sold to, bill to, and case accounts)
   * @return a map of accounts to a set of community partner user Salesforce identifiers
   */
  public static Map<Id,PartnerAccount> getCommunityUsers(List<Id> childIds) {
    return getCommunityUsers(childIds, null);
  }

  /**
   * Retreive a list of active community partner users under the given accounts. For example, this
   * method will return all the community partner users under both a "ship to" and "sold to"
   * account if both accounts are passed in via the accounts list. 
   *
   * Triggers should cache the returned user list when calling shareOrders, shareSAPInvoices, 
   * and shareCases. 
   *
   * @param a list of accounts identifiers (i.e., ship to, sold to, bill to, and case accounts)
   * @param a set of users who are allowed access (i.e., all other users should be filtered out)
   * @return a map of accounts to a set of community partner user Salesforce identifiers
   */
  public static Map<Id,PartnerAccount> getCommunityUsers(List<Id> childIds, Set<Id> grantees) {
    Map<Id,PartnerAccount> accountMap = createPartnerAccountMap(childIds);
    Set<Id> accountIds = getAccountIds(accountMap.values()); // both children and parents
   
    // Generate query to get list of partner users for both child and parent accounts
    String query = 'SELECT Contact.AccountId FROM User ';
    query += 'WHERE isActive = true AND Profile.UserLicense.Name = :PARTNER_LICENSES ';
    query += 'AND Contact.AccountId = :accountIds ';
    query += grantees <> null ? 'AND id = :grantees ' : '';
    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordUtility - Getting Community Users Query: ' + query);

    // Populate the partner account map with users, including parent account users
    for (user usr : Database.query(query)) {  // loop through each returned user
      for (PartnerAccount partner : accountMap.values()) { // loop through each partner account
      
        // Add users to partner account if user belongs to that account
        if (partner.accountId == usr.Contact.AccountId) {
          partner.userIds.add(usr.id);
        } // Add users to partner account if user belongs to a parent
        else if (partner.parentIds.contains(usr.Contact.AccountId)) {
          partner.userIds.add(usr.id);
        }
      }
    }

    System.debug(LoggingLevel.INFO, 'CSS_ShareRecordUtility - Getting Community Users: ' + accountMap);
    return accountMap;
  }

  /** 
   * Given a list of account identifiers, this method will create a map of account ids to 
   * instances of Partner Accounts, which contain both child and parent users. This methods 
   * reaches six levels deep when is comes to ancestors, which is Salesforce's limit per SOQL
   * query. 
   *
   * @param a list of child account identifiers, which might have parent accounts
   * @return a map of account ids to Partner Accounts, which contain both child and parent users
   */
  public static Map<Id,PartnerAccount> createPartnerAccountMap(List<Id> childIds) {
    Map<Id,PartnerAccount> accountMap = new Map<Id,PartnerAccount>();

    // Loop through all child acconts, getting their ancestors (six levels deep)
    for (Account acct : [SELECT Ship_To_Financials__c,
      ParentId,
      Parent.ParentId,
      Parent.Parent.ParentId,
      Parent.Parent.Parent.ParentId,
      Parent.Parent.Parent.Parent.ParentId,
      Parent.Parent.Parent.Parent.Parent.ParentId
      FROM Account WHERE id = :childIds]) {
        
      // Add the primary child partner account for this iteration
      PartnerAccount child = new PartnerAccount(acct.Id, acct.Ship_To_Financials__c);
      accountMap.put(child.accountId, child);
      
      // Loop through all parent accounts, adding thier ids
      integer i = 0; // watch out for circular references!
      Account parent = (Account) acct.getSObject('Parent');
      while ((parent <> null) && (i++<10)) {
        System.debug(LoggingLevel.INFO, 'CSS_ShareRecordUtility - Found Ancestor Account: ' + 
          parent.Id + ' of ' + child.accountId); 
        child.parentIds.add(parent.Id); 
        parent = (Account) parent.getSObject('Parent');
      }
    }
    return accountMap;
  }

  /** 
   * Given a list of parent account identifiers, this method will return all the children account
   * identifiers of those given parents. This method will go six levels deep, which is Salesforce's
   * limit for SOQL queries. Only partner child accounts are returned.
   *
   * @param parentIds list of parent account identifiers
   * @return a list of child account identifiers 
   */
  public static List<Id> getChildrenAccounts(List<Id> parentIds) {
    Map<Id,Account> childMap = new Map<Id,Account>([
      SELECT Name FROM Account
      WHERE isPartner = true 
        AND (ParentId = :parentIds
        OR Parent.ParentId = :parentIds
        OR Parent.Parent.ParentId = :parentIds
        OR Parent.Parent.Parent.ParentId = :parentIds
        OR Parent.Parent.Parent.Parent.ParentId = :parentIds
        OR Parent.Parent.Parent.Parent.Parent.ParentId = :parentIds)]);
    return new List<Id>(childMap.keySet());
  }

  /** 
   * static method used to return all account identifiers in a single set, including both
   * the child and parent account identifiers.
   * 
   * @param acconts a list of partner accounts, which should contain account ids
   * @return all account ids in a single set, including both child and parent account ids
   */
  public static Set<Id> getAccountIds(List<PartnerAccount> accounts) {
    Set<Id> identifiers = new Set<Id>();
    for (PartnerAccount partner : accounts) {
      identifiers.add(partner.accountId); // add account identifier
      identifiers.addAll(partner.parentIds); // add all parent identifiers
    }
    return identifiers; 
  }

  /** 
   * The Partner Account inner class is used to model a partner community account with users and 
   * parent accounts.
   */
  public class PartnerAccount {

    /** Set to true for accounts that should see invoices if they are the ship to account */
    public Boolean isShipToFinancials;

    /** The community partner account Salesforce 18 alphanumeric identifier */
    public Id accountId;

    /** 
     * A set of enabled community partner user identifiers for this partner account. Defaulting
     * an empty to list of users to speed things up (i.e., code doesn't have to check fo null).
     * This list should contain all user identifiers, including those of the parent community
     * partner accounts.
     */
    public Set<Id> userIds = new Set<Id>();

    /** 
     * A set of parent partner account identifiers for this child account. Order is not important
     * (i.e., only need a set of parent identifiers to verify if account is a parent account)
     */
    public Set<Id> parentIds = new Set<Id>(); 

    /** 
     * Default constructor used to instantiate a partner account. 
     * 
     * @param accountId the Salesforce alphanumeric identifier
     */
    public PartnerAccount(Id accountId, Boolean isShipToFinancials) {
      this.accountId = accountId;
      this.isShipToFinancials = isShipToFinancials;
    }

  }

}