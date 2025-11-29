public with sharing class LMS_FunnelSequence {
    public static final Map<String, String> FUNNELSTATUSLIST = new Map<String, String>{
        'Inquiry' => 'RESPONSE',
        'MQL' => 'ACTIVERESPONSE',
        'SAL' => 'STATUSCHANGE.PARENT.Attempted Contact',
        'SQL' => 'STATUSCHANGE.PARENT.Qualified',
        'SQO' => 'NEWOPPORTUNITY',
        'Won' => 'STATUSCHANGE.OPPORTUNITY.Won'
    };
    
    public static void checkFunnelFields(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            checkFunnelFields(cm);
        }
    }
    
    public static void checkFunnelFields(CampaignMember cm) {
        for(String funnelStage : FUNNELSTATUSLIST.keySet()) {
            String def = FUNNELSTATUSLIST.get(funnelStage);
            LMS_FunnelAction action = LMS_FunnelAction.parse(def);
            System.debug('AKCJA: ' + action.action);
            
            switch on action.action {
                when 'STATUSCHANGE'     { handleStatusUpdate(cm, action, funnelStage); }
                when 'NEWOPPORTUNITY'   { System.debug('NEWOPPORTUNITY not implemented'); }
            }
        }
    }
    
    private static void handleStatusUpdate(CampaignMember cm, LMS_FunnelAction fa, String funnelStage) {
        System.debug('---STATUSCHANGE--- action=' + fa.action +
            ' target=' + fa.target +
            ' value=' + fa.fieldValue);
        
        if(fa.target == 'PARENT') {
            
            if(cm.ContactId != null) {
                Contact c = [
                    SELECT Id, LMS_ContactStatus__c 
                    FROM Contact 
                    WHERE Id = :cm.ContactId 
                    LIMIT 1
                ];
                
                if(c.LMS_ContactStatus__c == fa.fieldValue) {
                    setFunnelStage(cm, funnelStage);
                }
            }
            
            if(cm.LeadId != null) {
                Lead l = [
                    SELECT Id, Status 
                    FROM Lead 
                    WHERE Id = :cm.LeadId 
                    LIMIT 1
                ];
                
                if(l.Status == fa.fieldValue) {
                    setFunnelStage(cm, funnelStage);
                }
            }
        }
    }
    
    private static void setFunnelStage(CampaignMember cm, String funnelStage) {
        
        // najpierw ustaw aktualny stage
        cm.put(getFunnelFieldName(funnelStage), true);
        cm.put(getFunnelFieldDateName(funnelStage), Date.today());
        
        // przejdź przez wszystkie inne stages
        for (String stage : FUNNELSTATUSLIST.keySet()) {
            if (stage == funnelStage) {
                break; // pomijamy ten sam stage
            }
            
            String fieldName = getFunnelFieldName(stage);
            String fieldDate = getFunnelFieldDateName(stage);
            
            
            // jeśli pola nie istnieją (czyli są null)
            Boolean value = (Boolean)cm.get(fieldName);
            Date dateValue = (Date)cm.get(fieldDate);
            
            if (value == null && dateValue == null) {
                cm.put(fieldName, true);
                cm.put(fieldDate, date.today());
            }
        }
    }
    
    private static String getFunnelFieldName(String funnelStage) {
        return 'LMS_' + funnelStage + '__c';
    }
    
    private static String getFunnelFieldDateName(String funnelStage) {
        return 'LMS_' + funnelStage + 'Date__c';
    }
    
    private static void clearResponseInfo(List<CampaignMember> cmList) {
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
            if(cm.LMS_Inquiry__c == false && cm.LMS_InquiryDate__c == null) {
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
            if(cm.LMS_MQL__c == false && cm.LMS_MQLDate__c == null) {
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
    
    // public static void setSAL(List<CampaignMember> cmList) {
        //     for (CampaignMember cm : cmList) {
            //         if(LMS_SAL__c = false && LMS_SALDate__c == null) {
                //             setSAL(cm);
            //         }
        //     }
        //     setMQL(cmList);
    // }
    
    // public static void setSAL(CampaignMember cmList) {
        //     System.debug('---LMS_FunnelSequence: setSAL---');
        //     cm.LMS_SAL__c = true;
        //     cm.LMS_SALDate__c = Date.today();
    // }
    
    // public static void setSQL(List<CampaignMember> cmList) {
        //     for (CampaignMember cm : cmList) {
            //         if(LMS_SQL__c = false && LMS_SQLDate__c == null) {
                //             setSQL(cm);
            //         }
        //     }
        //     setSAL(cmList);
    // }
    
    // public static void setSQL(List<CampaignMember> cmList) {
        //     System.debug('---LMS_FunnelSequence: setSQL---');
        //     cm.LMS_SQL__c = true;
        //     cm.LMS_SQLDate__c = Date.today();
    // }
    
    // public static void setSQO(List<CampaignMember> cmList) {
        //     for (CampaignMember cm : cmList) {
            //         if(LMS_SQO__c = false && LMS_SQODate__c == null) {
                //             setSQO(cm);
            //         }
        //     }
        //     setSQL(cmList);
    // }
    
    // public static void setSQO(List<CampaignMember> cmList) {
        //     System.debug('---LMS_FunnelSequence: setSQO---');
        //     cm.LMS_SQO__c = true;
        //     cm.LMS_SQODate__c = Date.today();
    // }
    
    // public static void setWon(List<CampaignMember> cmList) {
        //     for (CampaignMember cm : cmList) {
            //         if(LMS_Won__c = false && LMS_WonDate__c == null) {
                //             setWon(cm);
            //         }
        //     }
        //     setSQO(cmList);
    // }
    
    // public static void setWon(List<CampaignMember> cmList) {
        //     System.debug('---LMS_FunnelSequence: setWon---');
        //     cm.LMS_Won__c = true;
        //     cm.LMS_WonDate__c = Date.today();
    // }
    
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