public with sharing class LMS_CampaignMemberSequence {
    public static List<CampaignMember> cmOldList { get; protected set; }
    public static Map<Id, CampaignMember> cmOldMap { get; protected set; }
    
    public static List<CampaignMember> cmNewList { get; protected set; }
    public static Map<Id, CampaignMember> cmNewMap { get; protected set; }
    
    public static final List<String> ACTIVESTATUSLIST = new List<String>{
        'Working',
        'Attempted Contact',
        'Qualified',
        'Active Opportunity'
    };
    
    public static final String RESOLVEDALREADYACTIVE = 'Resolved - Already In Funnel';
    public static final String RESOLVEDNOTATTHRESHOLD = 'Resolved - Not Qualified';
    public static final String NOTARESPONSE = 'Not a Response';
    
    private static void saveCMData (LMS_TriggerCopy triggerCopy) {
        cmOldList = (List<CampaignMember>)triggerCopy.oldList;
        cmOldMap = (Map<Id, CampaignMember>)triggerCopy.oldMap;
        
        if(!triggerCopy.isDelete) {
            cmNewList = new List<CampaignMember>();
            for (SObject sobj : triggerCopy.newList) {
                cmNewList.add((CampaignMember) sobj);
            }
            cmNewMap = (Map<Id, CampaignMember>)triggerCopy.newMap;
        }
    }
    
    public static void startSequence(LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_CampaignMemberSequence: Entered---');
        saveCMData(triggerCopy);
        
        if(triggerCopy.isDelete) {
            Set<Id> contactIds = new Set<Id>();
            Set<Id> leadIds = new Set<Id>();
            Map<Id, SObject> relatedMap = new Map<Id, SObject>();
            
            for(CampaignMember cm : cmOldList) {
                //Zmieniamy status tylko jeśli usuwany CM jest aktywny
                if(ACTIVESTATUSLIST.contains(cm.LMS_ResponseStatus__c)) {
                    if (cm.ContactId != null) {
                        contactIds.add(cm.ContactId);
                    }
                    else {
                        leadIds.add(cm.leadId);
                    }
                }
            }
            
            for (Lead l : [SELECT Id, Status FROM Lead WHERE Id IN :leadIds]) {
                relatedMap.put(l.Id, l);
            }
            
            for (Contact c : [SELECT Id, LMS_ContactStatus__c FROM Contact WHERE Id IN :contactIds]) {
                relatedMap.put(c.Id, c);
            }
            
            for(SObject sobj : relatedMap.values()) {
                if(sobj.getSObjectType() == Contact.SObjectType) {
                    Contact c = (Contact)sobj;
                    c.LMS_ContactStatus__c = LMS_Configuration.FIRSTSTATUS;
                } else if(sobj.getSObjectType() == Lead.SObjectType) {
                    Lead l = (Lead)sobj;
                    l.Status = LMS_Configuration.FIRSTSTATUS;
                }
            }
            update relatedMap.values();
        }
        
        if(triggerCopy.isInsert) {
            List<CampaignMember> respondedCMs = new List<CampaignMember>();
            List<CampaignMember> nonRespondedCMs = new List<CampaignMember>();
            
            for(CampaignMember cm : cmNewList) {
                //Make initial updates to override any changes made by the user
                cm.LMS_ResponseDate__c = null;
                cm.LMS_ResponseStatus__c = null;
                
                List<String> respondedStatuses = new List<String>();
                for (CampaignMemberStatus cms : [SELECT Label, HasResponded FROM CampaignMemberStatus WHERE CampaignId = :cm.CampaignId AND HasResponded = true]) {
                    respondedStatuses.add(cms.Label);
                }
                
                //This is a response
                if (respondedStatuses.contains(cm.Status)) {
                    cm.LMS_Inquiry__c = true;
                    cm.LMS_InquiryDate__c = System.today();
                    cm.LMS_ResponseDate__c = System.today();
                    respondedCMs.add(cm);
                }
                //Not a response
                else {
                    cm.LMS_ResponseStatus__c = NOTARESPONSE;
                    nonRespondedCMs.add(cm);
                }
            }
            
            //Szukamy powiązanych rekordów
            
            //Sety aby uniknąć duplikatów
            Map<Id, SObject> relatedMap = new Map<Id, SObject>();
            Set<Id> contactIds = new Set<Id>();
            Set<Id> leadIds = new Set<Id>();
            Set<Id> campaignIds = new Set<Id>();
            
            //Szykujemy dane do zapytania
            for (CampaignMember cm : cmNewList) {
                if (cm.ContactId != null) {
                    contactIds.add(cm.ContactId);
                }
                else {
                    leadIds.add(cm.leadId);
                }
                campaignIds.add(cm.CampaignId);
            }
            
            
            //Wykonujemy zapytania
            
            for (Lead l : [SELECT Id, LMS_FunnelScore__c, LMS_NurtureTimeout__c, Status FROM Lead WHERE Id IN :leadIds]) {
                relatedMap.put(l.Id, l);
            }
            
            for (Contact c : [SELECT Id, LMS_FunnelScore__c, LMS_NurtureTimeout__c, LMS_ContactStatus__c FROM Contact WHERE Id IN :contactIds]) {
                relatedMap.put(c.Id, c);
            }
            
            Map<Id, Campaign> campaignMap = new Map<Id, Campaign>(
                [SELECT Id, LMS_CampaignScore__c, LMS_BypassNurtureTimeout__c FROM Campaign WHERE Id IN :campaignIds]
                );
            
            Map<CampaignMember, Boolean> evaluatedCMs = evaluateQualification(respondedCMs, relatedMap, campaignMap);
            
            // Wszystkie CMy powiązane z leadami lub kontaktami
            Map<Id, List<CampaignMember>> parentToCMs = new Map<Id, List<CampaignMember>>();
            
            for (CampaignMember cm : [SELECT Id, ContactId, LeadId, LMS_ResponseStatus__c FROM CampaignMember WHERE ContactId IN :contactIds OR LeadId IN :leadIds]) {
                Id parentId = cm.ContactId != null ? cm.ContactId : cm.LeadId;
                if (!parentToCMs.containsKey(parentId)) {
                    parentToCMs.put(parentId, new List<CampaignMember>());
                }
                parentToCMs.get(parentId).add(cm);
            }
            
            
            for(CampaignMember cm : evaluatedCMs.keySet()) {
                SObject relatedRecord = relatedMap.get(cm.ContactId != null ? cm.ContactId : cm.LeadId);
                Id parentId = cm.ContactId != null ? cm.ContactId : cm.LeadId;
                
                Boolean isAlreadyActive = false;
                if (parentToCMs.size() > 0 && parentToCMs.containsKey(parentId)) {
                    for (CampaignMember otherCM : parentToCMs.get(parentId)) {
                        
                        if (otherCM.Id == cm.Id) continue; // pomiń bieżący CM
                        
                        // Sprawdź, czy status innego CM jest aktywny
                        if (otherCM.LMS_ResponseStatus__c != null && ACTIVESTATUSLIST.contains(otherCM.LMS_ResponseStatus__c)) {
                            isAlreadyActive = true;
                            break;
                        }
                    }
                }
                
                if(isAlreadyActive) {
                    cm.LMS_ResponseStatus__c = RESOLVEDALREADYACTIVE;
                } else if(evaluatedCMs.get(cm) == true) {
                    if(relatedRecord.getSObjectType() == Contact.SObjectType) {
                        Contact c = (Contact)relatedRecord;
                        c.LMS_ContactStatus__c = LMS_Configuration.FIRSTACTIVESTATUS;
                    } else if(relatedRecord.getSObjectType() == Lead.SObjectType) {
                        Lead l = (Lead)relatedRecord;
                        l.Status = LMS_Configuration.FIRSTACTIVESTATUS;
                    }
                    cm.LMS_ResponseStatus__c = LMS_Configuration.FIRSTACTIVESTATUS;
                    cm.LMS_MQL__c = true;
                    cm.LMS_MQLDate__c = System.today();
                } else {
                    cm.LMS_ResponseStatus__c = RESOLVEDNOTATTHRESHOLD;
                }
            }
            
            // Aktualizacja Contact/Lead
            update relatedMap.values();
            
        }
    }
    
    public static Integer toInt(Object value) {
        if (value == null) return 0;
        return ((Decimal)value).intValue();
    }
    
    
    private static Map<CampaignMember, Boolean> evaluateQualification (List<CampaignMember> cmList, Map<Id, SObject> relatedMap, Map<Id, Campaign> campaignMap) {
        System.debug('---LMS_CampaignMemberSequence: evaluateQualification---');
        Map<CampaignMember, Boolean> cmQualificationMap = new Map<CampaignMember, Boolean>();
        
        //Obliczamy finalny score i zwracamy mapę, gdzie każdy CM ma swój score
        for(CampaignMember cm : cmList) {
            SObject relatedRecord = relatedMap.get(cm.ContactId != null ? cm.ContactId : cm.LeadId);
            
            Campaign cmCampaign = campaignMap.get(cm.CampaignId);
            
            Integer relatedRecordScore = LMS_Utils.toInt(relatedRecord.get('LMS_FunnelScore__c'));
            Integer campaignScore = LMS_Utils.toInt(cmCampaign.get('LMS_CampaignScore__c'));
            
            Integer finalScore = relatedRecordScore + campaignScore;
            
            Boolean campaignBypass = (Boolean)cmCampaign.get('LMS_BypassNurtureTimeout__c');
            Date timeout = (Date)relatedRecord.get('LMS_NurtureTimeout__c');
            Boolean timeoutExpired = (timeout == null || timeout < System.today());
            
            if(finalScore >= LMS_Configuration.getScoreThreshold()) {
                if(campaignBypass || timeoutExpired) {
                    cmQualificationMap.put(cm, true);
                }
            } else {
                cmQualificationMap.put(cm, false);
            }
            
        }
        return cmQualificationMap;
    }
}