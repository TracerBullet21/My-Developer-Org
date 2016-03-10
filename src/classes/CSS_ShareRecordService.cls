/** 
 * This record sharing service class grants access to records based on associated accounts (e.g.,
 * order ship to, order sold to, SAP invoice bill to, SAP invoice sold to, SAP invoice payer, and 
 * case account).
 *
 * Granting access to these records is only applicable to external community partner users
 * in the Customer Self Service Portal (i.e., user must have a specific license type). Do not use 
 * this class for internal sharing, instead use sharing rules.
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_ShareRecordService, CSS_ShareRecordUtility, CSS_Utility
 */
public without sharing class CSS_ShareRecordService {

  /** Order, invoice, and case access level granted to community users (R should be capitalized) */
  public static final String ACCESS_LEVEL_READ = 'Read';

  /** Complaint record type identifier, which should never change */
  public static final String RECORD_TYPE_ID_COMPLAINT = '012i00000011WNIAA2';

  /** Applicable row causes for orders */
  public static final List<String> ORDER_ROW_CAUSES = new List<String> {
    Schema.Order__Share.RowCause.Account_Ship_To__c, 
    Schema.Order__Share.RowCause.Account_Sold_To__c};

  /** Applicable row causes for SAP invoices */
  public static final List<String> SAP_INVOICE_ROW_CAUSES = new List<String> {
    Schema.SAP_Invoice__Share.RowCause.Account_Bill_To__c, 
    Schema.SAP_Invoice__Share.RowCause.Account_Sold_To__c,
    Schema.SAP_Invoice__Share.RowCause.Account_Payer__c,
    Schema.SAP_Invoice__Share.RowCause.Account_Ship_To__c};
  
  /** Applicable row causes for standard Salesforce cases */
  public static final List<String> CASE_ROW_CAUSES = new List<String> {
    Schema.CaseShare.RowCause.Manual};


  /**
   * Generate a unique key for a share record, using ParentId, UserOrGroupId, AccessLevel,
   * and RowCause. Standard objects, like Case, use a different set of share fields; however,
   * they serve the same purpose.
   *
   * @param share the standard or custom share record the generated key is based on
   * @return a unique share key based on key share record fields
   */
  @TestVisible
  private static String getShareKey(SObject share) {
    if (share instanceof CaseShare) { // standard object shares are different
      return share.get('CaseId') + '::' + share.get('UserOrGroupId') + '::' + 
        share.get('CaseAccessLevel') + '::' + share.get('RowCause');
    }
    else { // Order__Share and SAP_Invoice__Share records
      return share.get('ParentId') + '::' + share.get('UserOrGroupId') + '::' + 
        share.get('AccessLevel') + '::' + share.get('RowCause');
    }
  }

  /**
   * Share orders based on account "ship to" and account "sold to" relationships. I.e., Customer 
   * Self Service partner community users will be given access to a order record if their 
   * associated account is either a "ship to" account or "sold to" account on the record.
   *
   * @param orders list of orders to grant access to; records must contain the following fields: 
   *         1) Ship_To_Name__c
   *         2) Sold_to_Account__c
   */
  public static void shareOrders(List<Order__c> orders) {
    
    // Collect all the applicable accounts
    List<String> accountIds = new List<String>();
    for (Order__c order : orders) {
      accountIds.add(order.Ship_To_Name__c);
      accountIds.add(order.Sold_to_Account__c);
    }
    
    // Share orders with all applicable users under specified accounts
    shareOrders(orders, CSS_ShareRecordUtility.getCommunityUsers(accountIds));
  }

  /**
   * Share orders based on account "ship to" and account "sold to" relationships. I.e., Customer 
   * Self Service partner community users will be given access to records if their associated 
   * account is either a "ship to" account or "sold to" account.
   *
   * @param orders list of orders to grant access to; records must contain the following fields: 
   *         1) Ship_To_Name__c
   *         2) Sold_to_Account__c
   * @param accountMap a map of accounts to community users who need access
   */
  public static void shareOrders(List<Order__c> orders, Map<Id,CSS_ShareRecordUtility.PartnerAccount> accountMap) {
    
    // Loop through orders and create new sharing rules
    Map<String,Order__Share> shares = new Map<String,Order__Share>();
    for (Order__c order : orders) {
      if (String.isNotEmpty(order.Ship_To_Name__c)) {
        if (accountMap.containsKey(order.Ship_To_Name__c)) {
          for (Id userId : accountMap.get(order.Ship_To_Name__c).userIds) {
            Order__Share share = new Order__Share(
              ParentId = order.Id,
              UserOrGroupId = userId,
              AccessLevel = ACCESS_LEVEL_READ,
              RowCause = Schema.Order__Share.RowCause.Account_Ship_To__c);
            shares.put(getShareKey(share), share);
          }
        }
      }
      if (String.isNotEmpty(order.Sold_to_Account__c)) {
        if (accountMap.containsKey(order.Sold_to_Account__c)) {
          for (Id userId : accountMap.get(order.Sold_to_Account__c).userIds) {
            Order__Share share = new Order__Share(
              ParentId = order.Id,
              UserOrGroupId = userId,
              AccessLevel = ACCESS_LEVEL_READ,
              RowCause = Schema.Order__Share.RowCause.Account_Sold_To__c);
            shares.put(getShareKey(share), share);
          }
        }
      }
    }

    // Delete old shares and save new shares
    deleteSharesByCause(shares, orders, ORDER_ROW_CAUSES); // Account Payer TBD
    saveShares(shares.values());
  }

  /**
   * Share SAP invoices based on the various account relationship (i.e., "ship to" is not in scope). 
   * Customer Self Service partner users will be given access to records if their associated account is 
   * the "bill to" account.
   *
   * @param invoices list of invoices to grant access to; records must contain the following fields: 
   *        1) Bill_To_Account__c
   *        2) Sold_To_Party__c
   *        3) Payer_Account__c
   *        4) Ship_to_Party__c
   */
  public static void shareSAPInvoices(List<SAP_Invoice__c> invoices) {
    
    // Collect all the applicable accounts
    List<String> accountIds = new List<String>();
    for (SAP_Invoice__c invoice : invoices) {
      accountIds.add(invoice.Bill_To_Account__c);
      accountIds.add(invoice.Sold_To_Party__c);
      accountIds.add(invoice.Payer_Account__c); 
      accountIds.add(invoice.Ship_To_Party__c);
    }
    
    // Share invoices with all applicable users under specified accounts
    Set<Id> grantees = CSS_ShareRecordUtility.findGranteesByPermission(
      CSS_ShareRecordUtility.PERMISSION_VIEW_SAP_INVOICES);
    shareSAPInvoices(invoices, CSS_ShareRecordUtility.getCommunityUsers(accountIds, grantees));
  }

  /**
   * Share SAP invoices based on the various account relationship (i.e., "ship to" is not in scope). 
   * Customer Self Service partner users will be given access to records if their associated account is 
   * the "bill to" account.
   *
   * @param invoices list of invoices to grant access to; records must contain the following fields: 
   *        1) Bill_To_Account__c
   *        2) Sold_To_Party__c
   *        3) Payer_Account__c
   *        4) Ship_to_Party__c
   * @param accountUserMap a map of accounts to community users
   */
  public static void shareSAPInvoices(List<SAP_Invoice__c> invoices, Map<Id,CSS_ShareRecordUtility.PartnerAccount> accountMap) {
     
    // Loop through SAP invoices and create new sharing rules
    Map<String,SAP_Invoice__Share> shares = new Map<String,SAP_Invoice__Share>();
    for (SAP_Invoice__c invoice : invoices) {
      
      // Share with Account Bill To partner users
      if (String.isNotEmpty(invoice.Bill_To_Account__c)) {
        if (accountMap.containsKey(invoice.Bill_To_Account__c)) {
          for (Id userId : accountMap.get(invoice.Bill_To_Account__c).userIds) {
            SAP_Invoice__Share share = new SAP_Invoice__Share(
              ParentId = invoice.Id,
              UserOrGroupId = userId,
              AccessLevel = ACCESS_LEVEL_READ,
              RowCause = Schema.SAP_Invoice__Share.RowCause.Account_Bill_To__c);
            shares.put(getShareKey(share), share);
          }
        }
      }

      // Share with Account Sold To partner users
      if (String.isNotEmpty(invoice.Sold_To_Party__c)) {
        if (accountMap.containsKey(invoice.Sold_To_Party__c)) {
          for (Id userId : accountMap.get(invoice.Sold_To_Party__c).userIds) {
            SAP_Invoice__Share share = new SAP_Invoice__Share(
              ParentId = invoice.Id,
              UserOrGroupId = userId,
              AccessLevel = ACCESS_LEVEL_READ,
              RowCause = Schema.SAP_Invoice__Share.RowCause.Account_Sold_To__c);
            shares.put(getShareKey(share), share);
          }
        }
      }
      
      // Share with Account Payer partner users
      if (String.isNotEmpty(invoice.Payer_Account__c)) {
        if (accountMap.containsKey(invoice.Payer_Account__c)) {
          for (Id userId : accountMap.get(invoice.Payer_Account__c).userIds) {
            SAP_Invoice__Share share = new SAP_Invoice__Share(
              ParentId = invoice.Id,
              UserOrGroupId = userId,
              AccessLevel = ACCESS_LEVEL_READ,
              RowCause = Schema.SAP_Invoice__Share.RowCause.Account_Payer__c);
            shares.put(getShareKey(share), share);
          }
        }
      }

      // Share with Account Ship To partner users
      if (String.isNotEmpty(invoice.Ship_to_Party__c)) {
        if (accountMap.containsKey(invoice.Ship_to_Party__c)) {
          if (accountMap.get(invoice.Ship_to_Party__c).isShipToFinancials) { // double check flag
            for (Id userId : accountMap.get(invoice.Ship_to_Party__c).userIds) {
              SAP_Invoice__Share share = new SAP_Invoice__Share(
                ParentId = invoice.Id,
                UserOrGroupId = userId,
                AccessLevel = ACCESS_LEVEL_READ,
                RowCause = Schema.SAP_Invoice__Share.RowCause.Account_Ship_To__c);
              shares.put(getShareKey(share), share);
            }
          }
        }
      }

    } 

    // Delete old shares and save new shares
    deleteSharesByCause(shares, invoices, SAP_INVOICE_ROW_CAUSES);
    saveShares(shares.values());
  }

  /**
   * Share cases based on the case account relationship. Customer Self Service partner users 
   * will be given access to the given case records base on the associated account. Unfortunately
   * Salesforce doesn't support Apex Sharing Rules for case records; thus, manual sharing is
   * used instead.
   *
   * @param cases list of cases to grant access to based on associated case account 
   */
  public static void shareCases(List<Case> cases) {

    // Collect all the applicable accounts
    List<String> accountIds = new List<String>();
    for (Case complaint : cases) {
      accountIds.add(complaint.AccountId);
    }
    
    // Share cases with all applicable users under specified accounts
    Set<Id> grantees = CSS_ShareRecordUtility.findGranteesByPermission(
      CSS_ShareRecordUtility.PERMISSION_VIEW_COMPLAINTS);
    shareCases(cases, CSS_ShareRecordUtility.getCommunityUsers(accountIds, grantees)); 
  }

  /**
   * Share cases based on the case account relationship. Customer Self Service partner users 
   * will be given access to the given case records base on the associated account. Unfortunately
   * Salesforce doesn't support Apex Sharing Rules for case records; thus, manual sharing is
   * used instead.
   *
   * @param cases list of cases to grant access to based on associated case account
   * @param accountUserMap a map of accounts to community users 
   */
  public static void shareCases(List<Case> cases, Map<Id,CSS_ShareRecordUtility.PartnerAccount> accountMap) {

    // Loop through cases and create new sharing rules
    Map<String,CaseShare> shares = new Map<String,CaseShare>();
    for (Case complaint : cases) {
      if (complaint.recordTypeId == RECORD_TYPE_ID_COMPLAINT) {
        if (String.isNotEmpty(complaint.AccountId)) {
          if (accountMap.containsKey(complaint.AccountId)) {
            for (Id userId : accountMap.get(complaint.AccountId).userIds) {
              CaseShare share = new CaseShare(
                CaseId = complaint.Id,
                UserOrGroupId = userId,
                CaseAccessLevel = ACCESS_LEVEL_READ,
                RowCause = Schema.CaseShare.RowCause.Manual);
              shares.put(getShareKey(share), share);
            } 
          }
        }
      }
    } 
    
    // Delete old shares and save new shares
    deleteSharesByCause(shares, cases, CASE_ROW_CAUSES); 
    saveShares(shares.values());
  }

  /**
   * Deletes the current list of shares that meet the following criteria: 1. associated with the 
   * given list of parent records; 2. associated with the given share type (e.g., SAP_Invoice__share,
   * CaseShare, Order__Share); 3. associated with the given row cause; 4. are not being re-added; 
   * and 5. are of record type complaint (i.e., only work with complain cases).
   *
   * @param newShares list of shares to saved (WARNING: this list will be modified if shares already exist)
   * @param parents list of parent records with shares on them, which sould be deleted
   * @param causes rows causes for sharing (e.g., Account_Bill_To__c). Do not pass manual sharing 
   */
  private static void deleteSharesByCause(Map<String,SObject> newShares, List<SObject> parents, List<String> causes) {
    List<SObject> expired = new List<SObject>(); // list of shares to delete
    
    String query; // determine query to used based on share type
    if (parents instanceof List<Order__c>) {
      query = 'SELECT ParentId, UserOrGroupId, AccessLevel, RowCause FROM Order__Share ' +
        'WHERE RowCause = :causes AND ParentId = :parents';
    }
    else if (parents instanceof List<SAP_Invoice__c>) {
      query = 'SELECT ParentId, UserOrGroupId, AccessLevel, RowCause FROM SAP_Invoice__Share ' +
        'WHERE RowCause = :causes AND ParentId = :parents';
    }
    else if (parents instanceof List<Case>) {
      query = 'SELECT CaseId, UserOrGroupId, CaseAccessLevel, RowCause FROM CaseShare ' +
        'WHERE RowCause = :causes AND CaseId =:parents ' +
        'AND Case.RecordTypeId = :RECORD_TYPE_ID_COMPLAINT';
    }
    System.debug(LoggingLevel.INFO, 'CSS_RecordSharing - Deleting Shares Query: ' + query);

    // Loop through each share and filter out existing shares
    System.debug(LoggingLevel.INFO, 'CSS_RecordSharing - Try Saving ' + newShares.size() + ' New Share(s)');
    for (SObject oldShare : Database.query(query)) {
      
      // Share already exists, so remove it from the newShares
      if (newShares.containsKey(getShareKey(oldShare))) {
        newShares.remove(getShareKey(oldShare));
      }
      else { // share does not exist, so add it to expired
        expired.add(oldShare);
      }
    }
    
    // Log some sharing removal details to help with debugging
    System.debug(LoggingLevel.INFO, 'CSS_RecordSharing - Now Saving ' + newShares.size() + ' New Share(s)');
    System.debug(LoggingLevel.INFO, 'CSS_RecordSharing - Now Deleting ' + expired.size() + ' Old Share(s)');

    // Delete sharing records and process database operation result (false parameter allows for partial processing)
    String errorLog = '';
    List<Database.DeleteResult> results = Database.delete(expired, false);
    for (Integer i=0;i<results.size();i++) {
      if (!results[i].isSuccess()) {
        for (Database.Error error : results[i].getErrors()) {
          System.debug(LoggingLevel.ERROR, 'CSS_RecordSharing - Sharing Error: ' + 
            'unable to update the following share record: ' + expired[i] + '. ' + error.getMessage() + '. ');
          errorLog += 'CSS_RecordSharing - Sharing Error: ' + 
            'unable to update the following share record: ' + expired[i]  + '. ' + error.getMessage() + '. ';
        }
      }
    }

    // Log any error messages to the database
    if (String.isNotBlank(errorLog)) {
      CSS_Utility.logError(errorLog);
    }
  }

  /**
   * Saves a list of share records to the Salesforce database. This method will not throw an error
   * sharing failed. Instead, it will log the complete set of failures to the database.
   *
   * @param shares the records (i.e., order__share, sap_invoice__share records) to grant access to
   */
  private static void saveShares(List<SObject> shares) {
    System.debug(LoggingLevel.INFO, 'CSS_RecordSharing - Saving Shares: ' + shares);
    String errorLog = '';

    // Insert records and process database operation result (false parameter allows for partial processing)
    List<Database.SaveResult> results = Database.insert(shares, false);
    for (Integer i=0;i<results.size();i++) {
      if (!results[i].isSuccess()) {
        for (Database.Error error : results[i].getErrors()) {
          
          // Ignore database errors that are due to trivial access sharing
          if(!(error.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION && error.getMessage().contains('AccessLevel'))) {
            System.debug(LoggingLevel.WARN, 'CSS_RecordSharing - Sharing Warning: ' + 
              'unable to update the following share record: ' +  shares[i]);
            System.debug(LoggingLevel.WARN, 'CSS_RecordSharing - Sharing Warning: the following error is related to a trivial ' + 
              'access level (i.e., access levels equal or more permissive than the objects default access level are not allowed): ' + 
              error.getMessage());
          }
          else {
            System.debug(LoggingLevel.ERROR, 'CSS_RecordSharing - Sharing Error: ' + 
              'unable to update the following share record: ' + shares[i] + '. ' + error.getMessage() + '. ');
            errorLog += 'CSS_RecordSharing - Sharing Error: ' + 
              'unable to update the following share record: ' + shares[i]  + '. ' + error.getMessage() + '. ';
          }
        }
      }
    }

    // Log any error messages to the database
    if (String.isNotBlank(errorLog)) {
      CSS_Utility.logError(errorLog);
    }
  }

}