/**
 * The Customer Self Service Navigation service provides session management for true breadcrumbs
 * and other community related navigation functionality. If pages want to be listed as 
 * breadcrumbs, they need to be registered with a name and a link.
 *
 * @author Craig Poirier
 * @version 1.0
 */
public with sharing class CSS_NavigationService {
//public  without sharing class CSS_NavigationService {
    
  /** Maximum size of the breadcrumb list */
  private static final Integer MAX_SIZE = 3;

  /** Session platform cache partition for managing breadcrumbs */
  private static Cache.SessionPartition session = 
    Cache.Session.getPartition('CSSPlatformCache');
  

  /**
   * Register a page as a breadcrumb. Only a few pages can be registered at once; thus, old pages 
   * will be erased.  Duplicate pages will not be registered again.
   * 
   * @param name the name of the page that is registering
   * @param link http link to the page that is registering
   */
  @RemoteAction public static void register(String name, String link) {
    List<Breadcrumb> crumbs = session.get('breadcrumbs') == null ? 
      new List<Breadcrumb>() : (List<Breadcrumb>)session.get('breadcrumbs');

    // Create a new breadcrumb and add it to the list if not a duplicate
    if ((crumbs.isEmpty()) || (crumbs[crumbs.size()-1].name <> name)) {
      crumbs.add(new Breadcrumb(name, link));
    }

    // Shrink that list of bredcrumbs down to save space
    Integer size = crumbs.size();
    System.debug(LoggingLevel.INFO, 'CSS_BreadcrumbService - Current Size: ' + size);
    for (Integer i=0; i < size-MAX_SIZE; i++) {
      crumbs.remove(i);
    }

    // Push the breadcrumbs back to the session cache
    session.put('breadcrumbs', crumbs); // add crumbs back to session
    System.debug(LoggingLevel.INFO, 'CSS_BreadcrumbService - Registered: ' + crumbs);
  }

  
  /**
   * Get a list of breadcrumbs. Calling methods must pass in a current breadcrumb name so that 
   * blank lists and duplicates are shown appropriately 
   * 
   * @return the current list of breadcrumbs from the user's session
   */
  @RemoteAction public static List<Breadcrumb> getBreadcrumbs() {
    try {
      return session.get('breadcrumbs') == null ? new List<Breadcrumb>() :
        (List<Breadcrumb>)session.get('breadcrumbs');
    }
    catch (cache.Session.SessionCacheException sce) {
      System.debug(LoggingLevel.ERROR, 'CSS_NavigationService - Get Breadcrumbs Failed: ' + sce.getMessage());
      System.debug(LoggingLevel.ERROR, sce.getStackTraceString());
      session.remove('breadcrumbs'); // reset the current user's breadcrumb
      return new List<Breadcrumb>();
    }
  }


  /**
   * The Breadcrumb inner class models a single bread crumb (i.e., models a single name/link pair)
   */
  public class Breadcrumb {

    /** Creates a new Breadcrumb instance */
    public Breadcrumb(String name, String link) {
      this.name = name;
      this.link = link;
    }

    /** Name of breadcrumb (i.e., link name) */
    public String name {get; set;}

    /** Link of breadcrumb */
    public String link {get; set;}
  }

}