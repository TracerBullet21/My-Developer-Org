/**
 * Test class for the Customer Self Service Community, which tests functionality provided by the
 * Utility class 
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_UtilityTest
 */
@isTest
private class CSS_ShareRecordUtilityTest {

  /**
   * The setup method is use to create test records once then access them in every test method
   * in this test class.
   */
  @testSetup static void setup() {
    CSS_TestDataFactory.setEnviroment(true, true);
    CSS_TestDataFactory.createCommunityUsers();
    CSS_TestDataFactory.createTestData();
  }

  /** 
   * Test initialization of account user map (i.e., child/parent hierarchy)
   */
  @isTest static void testCreatePartnerAccountMap() {
    Account outsider = [SELECT Id FROM Account WHERE Account_External_ID__c = 'css-data-account-0'];
    Account child = [SELECT Id FROM Account WHERE Account_External_ID__c = 'css-test-account-0'];
    Account parent = [SELECT Id FROM Account WHERE Account_External_ID__c = 'css-test-parent-0'];
    
    // Generate an account user map with an empty user list 
    Map<Id,CSS_ShareRecordUtility.PartnerAccount> accountMap = 
      CSS_ShareRecordUtility.createPartnerAccountMap(new List<Id>{outsider.Id, child.id});
    
    // Verify oustider account and that it has not parents
    System.assertEquals(outsider.Id, accountMap.get(outsider.Id).accountId);
    System.assert(accountMap.get(outsider.Id).userIds.isEmpty(), 'Expected empty user list.');
    System.assert(accountMap.get(outsider.Id).parentIds.isEmpty(), 'Expected no parents.');   

    // Verify child account and that the parent account id is present
    System.assertEquals(child.Id, accountMap.get(child.Id).accountId);
    System.assert(accountMap.get(child.Id).userIds.isEmpty(), 'Expected empty user list.'); 
    System.assert(accountMap.get(child.Id).parentIds.contains(parent.Id), 'Expected a parent.');    
  }

  /** 
   * Test retrieval of community users
   */
  @isTest static void testGetCommunityUsers() {
    Account outsider = [SELECT Id FROM Account WHERE Account_External_ID__c = 'css-data-account-0'];
    Account child = [SELECT Id FROM Account WHERE Account_External_ID__c = 'css-test-account-0'];
    Account parent = [SELECT Id FROM Account WHERE Account_External_ID__c = 'css-test-parent-0'];
    User usr = CSS_TestDataFactory.getCommunityUser();

    // Get the community users make sure both the account and parent point to the same test user
    Map<Id,CSS_ShareRecordUtility.PartnerAccount> accountMap = 
      CSS_ShareRecordUtility.getCommunityUsers(new List<Id>{outsider.Id, child.id});

    // Verify oustider account and that it has not parents
    System.assertEquals(outsider.Id, accountMap.get(outsider.Id).accountId);
    System.assert(accountMap.get(outsider.Id).userIds.isEmpty(), 'Expected empty user list.');
    System.assert(accountMap.get(outsider.Id).parentIds.isEmpty(), 'Expected no parents.');   

    // Verify child account and that the parent account id is present
    System.assertEquals(child.Id, accountMap.get(child.Id).accountId);
    System.assert(accountMap.get(child.Id).userIds.contains(usr.Id), 'Expected community user.'); 
    System.assert(accountMap.get(child.Id).parentIds.contains(parent.Id), 'Expected a parent.');  
  }

  /** 
   * Test finding grantees by permission
   */
  @isTest static void testFindGranteesByPermission() {
    Set<Id> users = CSS_ShareRecordUtility.findGranteesByPermission(
      CSS_ShareRecordUtility.PERMISSION_VIEW_SAP_INVOICES);
  }

  /** 
   * Test finding children accounts when given parent accounts.
   */
  @isTest static void testGetChildrenAccounts() {
    Account child = [SELECT Id FROM Account WHERE Account_External_ID__c = 'css-test-account-0'];
    Account parent = [SELECT Id FROM Account WHERE Account_External_ID__c = 'css-test-parent-0'];
    
    // Verify the child account was returned when given a parent account identifier
    List<id> childIds = CSS_ShareRecordUtility.getChildrenAccounts(new List<Id>{parent.id});
    System.assert((new Set<Id>(childIds)).contains(child.Id),'Expected child account in list.');
  }
  
}