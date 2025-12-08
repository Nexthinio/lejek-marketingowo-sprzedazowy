public with sharing class LMS_StatusManager {
    //Contact + Lead related Statuses
    public static String NURTURESTATUS = 'Nurture';
    public static String FIRSTACTIVESTATUS = 'Working';
    public static List<String> ACTIVESTATUSLIST = new List<String>{
        'Working', 'Attempting Contact', 'Qualified', 'Active Opportunity'
    };
    
    //CM related statuses - not configurable
    public static final String RESOLVEDALREADYACTIVE = 'Resolved - Already In Funnel';
    public static final String RESOLVEDNOTATTHRESHOLD = 'Resolved - Not Qualified';
    public static final String NOTARESPONSE = 'Not a Response';
    
    //Status related fields
    public static String CONTACTSTATUSFIELD = 'LMS_ContactStatus__c';
    public static String LEADSTATUSFIELD = 'Status';
    public static String OPPORTUNITYSTAGEFIELD = 'StageName';
    
    private static LMS_Configuration__mdt configuration = LMS_Configuration__mdt.getInstance('default');
    
    public static String getNurtureStatus() {
        if(NURTURESTATUS == null) {
            NURTURESTATUS = configuration.LMS_Nurture_Status__c;
        }
        return NURTURESTATUS;
    }
    
    public static String getFirstActiveStatus() {
        if(FIRSTACTIVESTATUS == null) {
            FIRSTACTIVESTATUS = configuration.LMS_Active_Statuses_List__c.split(',')[0];
        }
        return FIRSTACTIVESTATUS;
    }
    
    public static List<String> getActiveStatusList() {
        if(ACTIVESTATUSLIST == null) {
            ACTIVESTATUSLIST = configuration.LMS_Active_Statuses_List__c.split(',');
        }
        return ACTIVESTATUSLIST;
    }
    
    public static String getContactStatusField() {
        if(CONTACTSTATUSFIELD == null) {
            CONTACTSTATUSFIELD = configuration.LMS_Contact_Status_Field__c;
        }
        return CONTACTSTATUSFIELD;
    }
    
    public static String getLeadStatusField() {
        if(LEADSTATUSFIELD == null) {
            LEADSTATUSFIELD = configuration.LMS_Lead_Status_Field__c;
        }
        return LEADSTATUSFIELD;
    }
    
    public static String getOpportunityStageField() {
        if(OPPORTUNITYSTAGEFIELD == null) {
            OPPORTUNITYSTAGEFIELD = configuration.LMS_Opportunity_Stage_Field__c;
        }
        return OPPORTUNITYSTAGEFIELD;
    }
}