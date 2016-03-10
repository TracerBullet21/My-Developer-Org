/**
 * Account Summary Service for the Customer Self Service Community. This service queries Salesforce
 * for user and account information and offers up this information via a service. In the future,
 * account summary might be a seperate object; however, for now this information is part of the 
 * Account object.
 *
 * @author Craig Poirier
 * @version 1.0   
 * @see CSS_CommunityService
 */
public with sharing class CSS_AccountSummaryService { 

  /** Invalid user message for service methods */
  public static final String MESSAGE_INVALID_USER = 
    'Current user is not a community user. Please provide a valid user and try again. ';

  /**
   * Get account summary data for the current portal user. This service is not available 
   * for internal Saleforce users and will return null 
   * 
   * @param detail a list of SAP order line items (i.e., order details)
   * @return an account record with account summary information
   */
  @RemoteAction public static AccountSummary getAccountSummary() {
    String userId = UserInfo.getUserId();
    List<Account> accounts = [SELECT Name, Revenue_YTD_Net__c FROM Account WHERE id IN (
      SELECT AccountId FROM User WHERE Id = :userId)];
    System.debug(LoggingLevel.INFO, 'CSS_AccountSummaryService - Get Account Summary: Accounts: ' + accounts);
    
    if (!accounts.isEmpty()) {
      Account acct = accounts[0];
      AccountSummary summary = new AccountSummary();
      summary.name = acct.Name;
      summary.ytdNetRevenue = acct.Revenue_YTD_Net__c <> null ? acct.Revenue_YTD_Net__c.intValue().format() : '';
      return summary;
    }
    throw new CSS_Exception(MESSAGE_INVALID_USER);
  }

  /** 
   * Wrapper class for an account summary object. This wrapper is expected to grwo in the future;
   * however, for right now, its just name and year-to-date net revenue.
   */
  public class AccountSummary {
    public String name;
    public String ytdNetRevenue;
  }

}