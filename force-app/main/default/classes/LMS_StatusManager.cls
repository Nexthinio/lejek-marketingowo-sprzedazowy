public with sharing class LMS_StatusManager {
    //Contact + Lead related Statuses
    private static String NURTURESTATUS;
    private static String FIRSTACTIVESTATUS;
    private static List<String> ACTIVESTATUSLIST;
    //'Working', 'Attempting Contact', 'Qualified', 'Active Opportunity'
    private static String ACTIVEOPPSTATUS;
    
    //CM related statuses - not configurable
    public static final String RESOLVEDALREADYACTIVE = 'Resolved - Already In Funnel';
    public static final String RESOLVEDNOTATTHRESHOLD = 'Resolved - Not Qualified';
    public static final String NOTARESPONSE = 'Not a Response';
    public static final String RESOLVEDMERGED = 'Resolved - Merged';
    public static final String RESOLVEDOPPORTUNITYDELETED = 'Resolved - Opportunity Deleted';
    
    //Status related fields
    private static String CONTACTSTATUSFIELD;
    private static String LEADSTATUSFIELD;
    private static String OPPORTUNITYSTAGEFIELD;
    
    private static LMS_Configuration__mdt configuration = LMS_Configuration__mdt.getInstance('default');
    
    public static String getNurtureStatus() {
        if(configuration == null) {
            NURTURESTATUS = 'Nurture';
        } else if(NURTURESTATUS == null) {
            NURTURESTATUS = configuration.LMS_Nurture_Status__c;
        }
        return NURTURESTATUS;
    }
    
    public static String getFirstActiveStatus() {
        if(configuration == null) {
            FIRSTACTIVESTATUS = 'Working';
        } else if(FIRSTACTIVESTATUS == null) {
            FIRSTACTIVESTATUS = configuration.LMS_Active_Statuses_List__c.split(',')[0];
        }
        return FIRSTACTIVESTATUS;
    }
    
    public static List<String> getActiveStatusList() {
        if(configuration == null) {
            ACTIVESTATUSLIST = new List<String>{'Working', 'Attempting Contact', 'Qualified', 'Active Opportunity'};
        } else if(ACTIVESTATUSLIST == null) {
            ACTIVESTATUSLIST = configuration.LMS_Active_Statuses_List__c.split(',');
        }
        return ACTIVESTATUSLIST;
    }
    
    public static String getActiveOppStatus() {
        if(configuration == null) {
            ACTIVEOPPSTATUS = 'Active Opportunity';
        } else if(ACTIVEOPPSTATUS == null) {
            List<String> statuses = configuration.LMS_Active_Statuses_List__c.split(',');
            ACTIVEOPPSTATUS = statuses[statuses.size() - 1];
        }
        return ACTIVEOPPSTATUS;
    }
    
    public static String getContactStatusField() {
        if(configuration == null) {
            CONTACTSTATUSFIELD = 'LMS_ContactStatus__c';
        } else if(CONTACTSTATUSFIELD == null) {
            CONTACTSTATUSFIELD = configuration.LMS_Contact_Status_Field__c;
        }
        return CONTACTSTATUSFIELD;
    }
    
    public static String getLeadStatusField() {
        if(configuration == null) {
            LEADSTATUSFIELD = 'Status';
        } else if(LEADSTATUSFIELD == null) {
            LEADSTATUSFIELD = configuration.LMS_Lead_Status_Field__c;
        }
        return LEADSTATUSFIELD;
    }
    
    public static String getOpportunityStageField() {
        if(configuration == null) {
            OPPORTUNITYSTAGEFIELD = 'StageName';
        } else if(OPPORTUNITYSTAGEFIELD == null) {
            OPPORTUNITYSTAGEFIELD = configuration.LMS_Opportunity_Stage_Field__c;
        }
        return OPPORTUNITYSTAGEFIELD;
    }
}