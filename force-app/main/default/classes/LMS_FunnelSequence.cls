public with sharing class LMS_FunnelSequence {
    public static final String RESOLVEDALREADYACTIVE = 'Resolved - Already In Funnel';
    public static final String RESOLVEDNOTATTHRESHOLD = 'Resolved - Not Qualified';
    public static final String NOTARESPONSE = 'Not a Response';
    
    public static void clearResponseInfo(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            clearResponseInfo(cm);
        }
    }
    
    public static void clearResponseInfo(CampaignMember cm) {
        System.debug('---LMS_FunnelSequence: clearResponseInfo---');
        cm.LMS_ResponseStatus__c = null;
        cm.LMS_ResponseDate__c = null;
    }
    
    public static void setInquiry(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            if(LMS_Inquiry__c = false && LMS_InquiryDate__c == null) {
                setInquiry(cm);
            }
        }
    }
    
    public static void setInquiry(CampaignMember cm) {
        System.debug('---LMS_FunnelSequence: setInquiry---');
        cm.LMS_Inquiry__c = true;
        cm.LMS_InquiryDate__c = Date.today();
        cm.LMS_ResponseDate__c = Date.today();
    }
    
    public static void setMQL(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            if(LMS_MQL__c = false && LMS_MQLDate__c == null) {
                setMQL(cm);
            }
        }
        setInquiry(cmList);
    }
    
    public static void setMQL(CampaignMember cm) {
        System.debug('---LMS_FunnelSequence: setMQL---');
        cm.LMS_MQL__c = true;
        cm.LMS_MQLDate__c = Date.today();
    }
    
    public static void setSAL(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            if(LMS_SAL__c = false && LMS_SALDate__c == null) {
                setSAL(cm);
            }
        }
        setMQL(cmList);
    }
    
    public static void setSAL(List<CampaignMember> cmList) {
        System.debug('---LMS_FunnelSequence: setSAL---');
        cm.LMS_SAL__c = true;
        cm.LMS_SALDate__c = Date.today();
    }
    
    public static void setSQL(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            if(LMS_SQL__c = false && LMS_SQLDate__c == null) {
                setSQL(cm);
            }
        }
        setSAL(cmList);
    }
    
    public static void setSQL(List<CampaignMember> cmList) {
        System.debug('---LMS_FunnelSequence: setSQL---');
        cm.LMS_SQL__c = true;
        cm.LMS_SQLDate__c = Date.today();
    }
    
    public static void setSQO(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            if(LMS_SQO__c = false && LMS_SQODate__c == null) {
                setSQO(cm);
            }
        }
        setSQL(cmList);
    }
    
    public static void setSQO(List<CampaignMember> cmList) {
        System.debug('---LMS_FunnelSequence: setSQO---');
        cm.LMS_SQO__c = true;
        cm.LMS_SQODate__c = Date.today();
    }
    
    public static void setWon(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            if(LMS_Won__c = false && LMS_WonDate__c == null) {
                setWon(cm);
            }
        }
        setSQO(cmList);
    }
    
    public static void setWon(List<CampaignMember> cmList) {
        System.debug('---LMS_FunnelSequence: setWon---');
        cm.LMS_Won__c = true;
        cm.LMS_WonDate__c = Date.today();
    }
    
    public static void setResponseStatus(List<CampaignMember> cmList, String status) {
        for (CampaignMember cm : cmList) {
            setResponseStatus(cm, status);
        }
    }
    
    public static void setResponseStatus(CampaignMember cm, String status) {
        System.debug('---LMS_FunnelSequence: setResponseStatus---');
        cm.LMS_ResponseStatus__c = status;
    }
}