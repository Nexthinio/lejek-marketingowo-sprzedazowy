public with sharing class LMS_StatusManager {
    //Contact + Lead related Statuses
    public static final String FIRSTSTATUS = 'New';
    public static final String NURTURESTATUS = 'Nurture';
    public static final String FIRSTACTIVESTATUS = 'Working';
    public static final List<String> ACTIVESTATUSLIST = new List<String>{
        'Working', 'Attempting Contact', 'Qualified', 'Active Opportunity'
    };
    
    //CM related statuses
    public static final String RESOLVEDALREADYACTIVE = 'Resolved - Already In Funnel';
    public static final String RESOLVEDNOTATTHRESHOLD = 'Resolved - Not Qualified';
    public static final String NOTARESPONSE = 'Not a Response';
    
    //Status related fields
    public static final String CONTACTSTATUSFIELD = 'LMS_ContactStatus__c';
    public static final String LEADSTATUSFIELD = 'Status';
    public static final String OPPORTUNITYSTAGEFIELD = 'StageName';
    
}