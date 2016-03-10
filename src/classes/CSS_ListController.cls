/**
 * Customer Self Service Community List Page controller class provides the search functionality
 * for all community associated records (e.g., orders, SAP invoices, cases, and opportunities).
 *
 * @author Craig Poirier
 * @version 1.0
 * @see CSS_SetController
 */
public with sharing class CSS_ListController extends CSS_SetController {

  /** Default page size for list of records **/
  private Integer pageSize = 25;


  /** Field set with defined fields */
  public CSS_FieldSetUtility.FieldSet fieldSet {get; private set;}

  /** Object this controller is being used for */
  public String objectType {get; private set;}

  /** Each object type should have a default date field **/
  public String defaultDate {get; private set;}

  /** Page header title */
  public String title {get;set;}

  /** Page header icon */
  public String icon {get;set;}

  /** Choosen order by field **/
  public String orderBy {get;set;}

  /** Choosen sort ascending or decending **/
  public Boolean isAscending {get;set;}

  /** Search Criteria #1: key word search criteria **/
  public String keys {get;set;}

  /** Search Criteria #2: record type */
  public String recordType {get;set;}
  
  /** Search Criteria #3: stage (opportunity only) */
  public List<String> stageName {get;set;} 

  /** Search Criteria #4: order type (order only) */
  public String orderType {get;set;} 

  /** Search Criteria #5: invoice type (invoice only) */
  public String invoiceType {get;set;} 

  /** Search Criteria #6: status (case only) */
  public String status {get;set;} 

  /** Search Criteria #7: priority (case only) */
  public List<String> priority {get;set;} 

  /** Search Criteria #8: date from */
  public Date dateFrom {get;set;} 

  /** Search Criteria #9: date to */
  public Date dateTo {get;set;}
  
   /** Search Criteria #10: account type*/
  public String accountType {get;set;}

  public String recordTypeDeveloperName {get;set;}

  /** Account type field options **/
  public List<SelectOption> accountTypeOptions{
    get
    {
      if ( accountTypeOptions == null )
      {
        accountTypeOptions = new List<SelectOption>{ new SelectOption('', 'None') };
        for ( Schema.PicklistEntry entry : Account.Type.getDescribe().getPickListValues() )
          accountTypeOptions.add(new SelectOption( entry.getValue(), entry.getLabel() ));
      }
      return accountTypeOptions;
    }
    private set;
  }

  /**
  * Search Criteria #11: account rating
  * All AC account searches need to exclude inactive account ratings
  */
  public String accountRating {get;set;}

    /**
  * Search Criteria #12: contact inactive
  * All AC contact searches need to exclude inactive contacts
  */
  public Boolean filterOnContactInactive =false;

  public String community
  {
    get
    {
      if (community == null)
      {
        community = ApexPages.currentPage().getParameters().get('community');
        if ( String.isBlank(community) )
          community = 'CSS';
      }
      return community;
    }
    private set;
  }

  /** 
   * Default contructor, which initalizes the instance variables with query parameters. This 
   * Visualforce page controller also performs the initial search based on passed query 
   * parameters.
   */
  public CSS_ListController() {
    System.debug(LoggingLevel.ERROR, 'community: ' + community);
    // Initialize other instance variables & perform initial search
    this.isAscending = true;
      
    // Determine object type being used (e.g., case, order__c, opportunity)
    if (String.isEmpty(ApexPages.currentPage().getParameters().get('type'))) {
      this.objectType = 'Opportunity'; // default to opportunity
    }
    else {
      this.objectType = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('type'));
    }
    System.debug(LoggingLevel.INFO, 'CSS_ListController - Initializing: object type: ' + this.objectType); 

    if( community == 'AC' )
        initDefaultsAC(); // each object has defaults such as title, icon, and field set
    else
        initDefaults();

    search(); // perform the initial search; all exceptions should be caught a reported
  }

  /**
   * Sets default title, icon, order by, date fields, and fieldset for each of the searchable
   * objects (e.g., order, case, invoice, and opportunity).
   *
   * @throws a Customer Community Self Service exception if a non-searchable object type is provide
   */
  private void initDefaults() {
    System.debug(LoggingLevel.ERROR, 'init defaults CSS');
    if (this.objectType.equalsIgnoreCase('Order__c')){
      this.title = 'Orders';
      this.icon = '/assets/icons/standard/orders_60.png';
      this.orderBy = 'PO_Date__c';
      this.defaultDate = 'PO_Date__c';
      this.isAscending = false;
      this.fieldSet = CSS_FieldSetUtility.getFieldSet('Community_Order_List_View', this.objectType);
    }
    else if (this.objectType.equalsIgnoreCase('SAP_Invoice__c')){
      this.title = 'Invoices';
      this.icon = '/assets/icons/standard/document_60.png';
      this.orderBy = 'Invoice_Date__c';
      this.defaultDate  = 'Invoice_Date__c';
      this.isAscending = false;
      this.fieldSet = CSS_FieldSetUtility.getFieldSet('Community_SAP_Invoice_List_View', this.objectType);
    }
    else if (this.objectType.equalsIgnoreCase('Case')){
      this.title = 'Cases';
      this.icon = '/assets/icons/standard/case_60.png';
      this.orderBy = 'CreatedDate';
      this.defaultDate  = 'CreatedDate';
      this.isAscending = false;
      this.fieldSet = CSS_FieldSetUtility.getFieldSet('Community_Case_List_View', this.objectType);
    }
    else if (this.objectType.equalsIgnoreCase('Opportunity')){
      this.title = 'Opportunities';
      this.icon = '/assets/icons/standard/opportunity_60.png';
      this.orderBy = 'CreatedDate';
      this.defaultDate = 'CreatedDate';
      this.isAscending = false;
        this.fieldSet = CSS_FieldSetUtility.getFieldSet('Community_Opportunity_List_View', this.objectType);
    }
    else {
      throw new CSS_Exception('Please provide a valid search type (e.g., case, opportunity)');
    }
    System.debug(LoggingLevel.INFO, 'CSS_ListController - Defaults: fieldSet: ' + 
      this.fieldSet + '; orderBy: ' + this.orderBy + '; ascending: ' + isAscending); 
  }

  /**
   * Initialization method for Agent Community
   * Sets default title, icon, order by, date fields, and fieldset for each of the searchable
   * objects (e.g., order, case, invoice, and opportunity). 
   *
   * @throws a Customer Community Self Service exception if a non-searchable object type is provide
   */
  private void initDefaultsAC()
  {
    System.debug(LoggingLevel.ERROR, 'init defaults AC');
    if (this.objectType.equalsIgnoreCase('Opportunity')){
      this.title = 'Opportunities';
      this.icon = '/assets/icons/standard/opportunity_60.png';
      this.orderBy = 'Bid_Date__c';
      this.defaultDate = 'CreatedDate';
      this.isAscending = false;
      this.fieldSet = CSS_FieldSetUtility.getFieldSet('Agent_Community_Oppty_List_View', this.objectType);
    }
    else if (this.objectType.equalsIgnoreCase('Account')){
      this.accountRating = 'Inactive';
      this.title = 'Accounts';
      this.icon = '/assets/icons/standard/opportunity_60.png';
      this.orderBy = 'Name';
      this.defaultDate = 'CreatedDate';
      this.isAscending = true;
      this.fieldSet = CSS_FieldSetUtility.getFieldSet('Agent_Community_Account_List_View', this.objectType);
    }
    else if (this.objectType.equalsIgnoreCase('Contact')){
      this.filterOnContactInactive = true;
      this.title = 'Contacts';
      this.icon = '/assets/icons/standard/opportunity_60.png';
      this.orderBy = 'Name';
      this.defaultDate = 'CreatedDate';
      this.isAscending = true;
      this.fieldSet = CSS_FieldSetUtility.getFieldSet('Agent_Community_Contact_List_View', this.objectType);
      this.recordTypeDeveloperName = 'StandardContact';
    }
    else {
      throw new CSS_Exception('Please provide a valid search type (e.g., case, opportunity)');
    }
  }

  /**
   * Generate a SOQL statement based on the following the choosen fieldset
   */
  private String getSOQLStmt() {
    String stmt = 'SELECT ' + String.join(this.fieldSet.fieldNames,',') + ' ';
    stmt += ' FROM ' + this.objectType + ' ';
    stmt += getWhereStmt();    
    stmt += ' LIMIT 1500';
    return stmt;
  }

  /**
   * Generate a SOQL statement based on the following the choosen fieldset
   */
  private String getSOSLStmt() {
    String stmt = 'FIND :keys IN ALL FIELDS RETURNING ' + this.objectType + ' ( ';
    stmt += String.join(this.fieldSet.fieldNames,',') + ' ';
    stmt += getWhereStmt();
    stmt += ') LIMIT 1500';
    return stmt;
  }  

  /** 
   * Generate the where clause and order by clause here. Add more filter conditions here as 
   * necessary (i.e., each new search box field will require another filter)
   */
  private String getWhereStmt() {
    String stmt = ' WHERE ';
    
    // Append search criteria if a single string is populated
    stmt += (!String.isEmpty(this.recordTypeDeveloperName)) ? 'RecordType.DeveloperName = :recordTypeDeveloperName AND ' : '';
    stmt += (!String.isEmpty(this.recordType)) ? 'RecordTypeId = :recordType AND ' : '';
    stmt += (!String.isEmpty(this.accountType)) ? 'Type = :accountType AND ' : '';
    stmt += (!String.isEmpty(this.accountRating)) ? 'Rating != :accountRating AND ' : '';
    stmt += (!String.isEmpty(this.orderType)) ? 'Order_Type__c = :orderType AND ' : '';
    stmt += (!String.isEmpty(this.invoiceType)) ? 'Invoice_Type__c = :invoiceType AND ' : ''; 
    stmt += (!String.isEmpty(this.status)) ? 'status = :status AND ' : '';
    stmt += (filterOnContactInactive) ? 'Inactive__c = FALSE AND ' : '';

    // Append search criteria if multi-select picklists are populated
    stmt += (this.stageName <> null && this.stageName.size() > 0) ? 'StageName IN :stageName AND ' : '';
    stmt += (this.priority <> null && this.priority.size() > 0) ? 'priority IN :priority AND ' : '';

    // Append search criteria if month and year are populated
    if ( community == 'AC' ){
      stmt += ( this.objectType == 'Opportunity' ) ? getACOpportunityParameters(): '';
    }
    else{
      stmt += (this.dateFrom <> null) ? this.defaultDate + ' >= :dateFrom AND ' : '';
      stmt += (this.dateTo <> null) ? this.defaultDate + ' <= :dateTo AND ' : '';
    }

    // Clean up the where clause
    stmt = stmt.trim().removeEnd('WHERE');
    stmt = stmt.trim().removeEnd('AND');
    stmt += (!String.isEmpty(this.orderBy)) ? ' ORDER BY ' + orderBy + (isAscending ? ' ASC ' : ' DESC ') : '';
    System.debug(LoggingLevel.ERROR, 'this.recordTypeDeveloperName: ' + this.recordTypeDeveloperName);
    System.debug(LoggingLevel.ERROR, 'stmt: ' + stmt);
    return stmt;
  }

  private String getACOpportunityParameters()
  {
    String stmt = 'RecordType.DeveloperName = \'Master\' AND ';
    if ( dateFrom != null )
      stmt += 'Bid_Date__c > :dateFrom AND ';
    if ( dateTo != null )
      stmt += 'Bid_Date__c < :dateTo AND ';
    return stmt;
  }

  /** 
   * Clear out keys and all search criteria then perform a new search. The setController instance
   * variable is populated with the cleared search results; thus, pages need to rerender after
   * calling this method.
   */
  public void clear() {
    
    // Clear out all search criteria
    keys = null;
    recordType = null;
    accountType = null;
    stageName = null;
    orderType = null;
    invoiceType = null;
    priority = null;
    status = null;
    dateFrom = null;
    dateTo = null;

    // Perform another search with no search criteria
    search();
  }

  /** 
   * Using the populated search criteria, perforn a SOQL or SOQL search. The setController
   * instance variable is populated with the search results; thus, pages need to rerender after
   * calling this method.
   */
  public void search() {
    List<SObject> results;
    try {
      if (String.isEmpty(keys)) { // basic query
        System.debug(LoggingLevel.ERROR, 'CSS_ListController - Searching: ' + getSOQLStmt());
        results = Database.query(getSOQLStmt());
      }
      else { // key word search query
        System.debug(LoggingLevel.INFO, 'CSS_ListController - Searching: ' + getSOSLStmt());
        List<List<SObject>> searchList = search.query(getSOSLStmt());
        if (searchList.size() > 0) {
          results = searchList[0];
        }
        else {
          results = new List<Opportunity>();
        }
      }
      
      // Initialize standard set controller with list of records (max 2000)
      setController = new ApexPages.StandardSetController(results);
      setController.setPageSize(pageSize);

      // Add a page message if the search result had no errors
      System.debug(LoggingLevel.INFO, 'CSS_ListController - Searching: result size: ' + setController.getResultSize());
      if (setController.getResultSize() < 1) {
        addMessage(System.Label.CSS_Search_No_Records_Found);
      }
    }
    catch (System.SearchException se) {
      System.debug(LoggingLevel.ERROR, 'CSS_ListController - Find Failed: ' + se);
      setController = new ApexPages.StandardSetController(new List<Opportunity>());
      addMessage(System.Label.CSS_Search_No_Records_Found);
    }
    catch (System.Exception ex) {
      System.debug(LoggingLevel.ERROR, 'CSS_ListController - Search Failed: ' + ex);
      setController = new ApexPages.StandardSetController(new List<Opportunity>());
      addMessage(System.Label.CSS_Search_No_Records_Found);
    }
  }

}