public with sharing class LMS_CampaignMemberSequence {
    
    // ======================================================
    //  STATIC PROPERTIES
    // ======================================================
    
    public static List<CampaignMember> cmOldList { get; protected set; }
    public static Map<Id, CampaignMember> cmOldMap { get; protected set; }
    public static List<CampaignMember> cmNewList { get; protected set; }
    public static Map<Id, CampaignMember> cmNewMap { get; protected set; }
    
    public static final List<String> ACTIVESTATUSLIST = new List<String>{
        'Working', 'Attempted Contact', 'Qualified', 'Active Opportunity'
    };
    
    public static final String RESOLVEDALREADYACTIVE = 'Resolved - Already In Funnel';
    public static final String RESOLVEDNOTATTHRESHOLD = 'Resolved - Not Qualified';
    public static final String NOTARESPONSE = 'Not a Response';
    
    // ======================================================
    //  ENTRY POINT
    // ======================================================
    
    public static void startSequence(LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_CampaignMemberSequence: Entered---');
        saveCMData(triggerCopy);
        
        if (triggerCopy.isDelete) {
            handleDelete();
            return;
        }
        if (triggerCopy.isInsert) {
            handleInsert();
            return;
        }
        if (triggerCopy.isUpdate) {
            handleUpdate();
            return;
        }
    }
    
    // ======================================================
    //  SAVE TRIGGER DATA
    // ======================================================
    
    private static void saveCMData(LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_CampaignMemberSequence: saveCMData---');
        
        cmOldList = (List<CampaignMember>) triggerCopy.oldList;
        cmOldMap  = (Map<Id, CampaignMember>) triggerCopy.oldMap;
        
        if (!triggerCopy.isDelete) {
            cmNewList = new List<CampaignMember>();
            for (SObject sobj : triggerCopy.newList) {
                cmNewList.add((CampaignMember) sobj);
            }
            cmNewMap = (Map<Id, CampaignMember>) triggerCopy.newMap;
        }
    }
    
    // ======================================================
    //  DELETE LOGIC
    // ======================================================
    
    private static void handleDelete() {
        System.debug('---LMS_CampaignMemberSequence: handleDelete---');
        
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds    = new Set<Id>();
        
        for (CampaignMember cm : cmOldList) {
            if (ACTIVESTATUSLIST.contains(cm.LMS_ResponseStatus__c)) {
                if (cm.ContactId != null) contactIds.add(cm.ContactId);
                else leadIds.add(cm.LeadId);
            }
        }
        
        Map<Id, SObject> parents = fetchParent(leadIds, contactIds);
        
        for (SObject sobj : parents.values()) {
            if (sobj.getSObjectType() == Contact.SObjectType) {
                ((Contact)sobj).LMS_ContactStatus__c = LMS_Configuration.FIRSTSTATUS;
            } else {
                ((Lead)sobj).Status = LMS_Configuration.FIRSTSTATUS;
            }
        }
        
        update parents.values();
    }
    
    // ======================================================
    //  INSERT LOGIC
    // ======================================================
    
    private static void handleInsert() {
        System.debug('---LMS_CampaignMemberSequence: handleInsert---');
        
        List<CampaignMember> responded = detectResponses();
        if (responded.isEmpty()) return;
        
        Set<Id> contactIds = extractContactIds(cmNewList);
        Set<Id> leadIds = extractLeadIds(cmNewList);
        Set<Id> campaignIds = extractCampaignIds(cmNewList);
        
        Map<Id, SObject> parents = fetchParent(leadIds, contactIds);
        Map<Id, Campaign> campaigns = fetchCampaigns(campaignIds);
        
        Map<CampaignMember, Boolean> qualified = evaluateQualification(responded, parents, campaigns);
        
        applyQualificationResults(qualified, parents);
        
        update parents.values();
    }
    
    // ======================================================
    //  UPDATE LOGIC
    // ======================================================
    
    private static void handleUpdate() {
        // TO DO
    }
    
    // ======================================================
    //  HELPER: DETECT RESPONSES
    // ======================================================
    
    private static List<CampaignMember> detectResponses() {
        
        List<CampaignMember> responded = new List<CampaignMember>();
        
        for (CampaignMember cm : cmNewList) {
            
            cm.LMS_ResponseDate__c = null;
            cm.LMS_ResponseStatus__c = null;
            
            List<String> respondedStatuses = new List<String>();
            for (CampaignMemberStatus cms : [
                SELECT Label 
                FROM CampaignMemberStatus 
                WHERE CampaignId = :cm.CampaignId 
                    AND HasResponded = true]) {
                respondedStatuses.add(cms.Label);
            }
            
            if (respondedStatuses.contains(cm.Status)) {
                cm.LMS_Inquiry__c = true;
                cm.LMS_InquiryDate__c = Date.today();
                cm.LMS_ResponseDate__c = Date.today();
                responded.add(cm);
            } else {
                cm.LMS_ResponseStatus__c = NOTARESPONSE;
            }
        }
        return responded;
    }
    
    // ======================================================
    //  HELPER: FETCHING
    // ======================================================
    
    private static Map<Id, SObject> fetchParent(Set<Id> leadIds, Set<Id> contactIds) {
        Map<Id, SObject> parents = new Map<Id, SObject>();
        
        if (!leadIds.isEmpty()) {
            for (Lead l : [
                SELECT Id, LMS_FunnelScore__c, LMS_NurtureTimeout__c, Status 
                FROM Lead WHERE Id IN :leadIds])
            {
                parents.put(l.Id, l);
            }
        }
        
        if (!contactIds.isEmpty()) {
            for (Contact c : [
                SELECT Id, LMS_FunnelScore__c, LMS_NurtureTimeout__c, LMS_ContactStatus__c 
                FROM Contact WHERE Id IN :contactIds])
            {
                parents.put(c.Id, c);
            }
        }
        
        return parents;
    }
    
    private static Map<Id, Campaign> fetchCampaigns(Set<Id> campaignIds) {
        return new Map<Id, Campaign>([
            SELECT Id, LMS_CampaignScore__c, LMS_BypassNurtureTimeout__c 
            FROM Campaign 
            WHERE Id IN :campaignIds
            ]);
    }
    
    // ======================================================
    //  HELPER: ID EXTRACTION
    // ======================================================
    
    private static Set<Id> extractLeadIds(List<CampaignMember> cms) {
        Set<Id> ids = new Set<Id>();
        for (CampaignMember cm : cms) if (cm.LeadId != null) ids.add(cm.LeadId);
        return ids;
    }
    
    private static Set<Id> extractContactIds(List<CampaignMember> cms) {
        Set<Id> ids = new Set<Id>();
        for (CampaignMember cm : cms) if (cm.ContactId != null) ids.add(cm.ContactId);
        return ids;
    }
    
    private static Set<Id> extractCampaignIds(List<CampaignMember> cms) {
        Set<Id> ids = new Set<Id>();
        for (CampaignMember cm : cms) ids.add(cm.CampaignId);
        return ids;
    }
    
    // ======================================================
    //  HELPER: APPLY QUALIFICATION RESULTS
    // ======================================================
    
    private static void applyQualificationResults(Map<CampaignMember, Boolean> qualified, Map<Id, SObject> parents) {
        
        for (CampaignMember cm : qualified.keySet()) {
            
            Id pid = cm.ContactId != null ? cm.ContactId : cm.LeadId;
            SObject parent = parents.get(pid);
            
            Boolean alreadyActive = false;
            
            if (parent.getSObjectType() == Contact.SObjectType) {
                Contact c = (Contact) parent;
                alreadyActive = ACTIVESTATUSLIST.contains(c.LMS_ContactStatus__c);
            }
            else if (parent.getSObjectType() == Lead.SObjectType) {
                Lead l = (Lead) parent;
                alreadyActive = ACTIVESTATUSLIST.contains(l.Status);
            }
            
            // Parent already active
            if (alreadyActive) {
                cm.LMS_ResponseStatus__c = RESOLVEDALREADYACTIVE;
                continue;
            }
            
            // Fully qualified
            if (qualified.get(cm) == true) {
                if (parent.getSObjectType() == Contact.SObjectType) {
                    ((Contact)parent).LMS_ContactStatus__c =
                        LMS_Configuration.FIRSTACTIVESTATUS;
                } else {
                    ((Lead)parent).Status =
                        LMS_Configuration.FIRSTACTIVESTATUS;
                }
                
                cm.LMS_ResponseStatus__c = LMS_Configuration.FIRSTACTIVESTATUS;
                cm.LMS_MQL__c = true;
                cm.LMS_MQLDate__c = Date.today();
            }
            // Not at threshold
            else {
                cm.LMS_ResponseStatus__c = RESOLVEDNOTATTHRESHOLD;
            }
        }
    }
    
    // ======================================================
    //  HELPER: QUALIFICATION
    // ======================================================
    
    private static Map<CampaignMember, Boolean> evaluateQualification(
        List<CampaignMember> cms,
    Map<Id, SObject> parents,
    Map<Id, Campaign> campaigns
    ) {
        Map<CampaignMember, Boolean> result = new Map<CampaignMember, Boolean>();
        
        for (CampaignMember cm : cms) {
            
            SObject parent = parents.get(cm.ContactId != null ? cm.ContactId : cm.LeadId);
            Campaign camp = campaigns.get(cm.CampaignId);
            
            Integer parentScore   = LMS_Utils.toInt(parent.get('LMS_FunnelScore__c'));
            Integer campaignScore = LMS_Utils.toInt(camp.get('LMS_CampaignScore__c'));
            Integer finalScore    = parentScore + campaignScore;
            
            Boolean bypass  = (Boolean) camp.get('LMS_BypassNurtureTimeout__c');
            Date timeout    = (Date) parent.get('LMS_NurtureTimeout__c');
            Boolean expired = (timeout == null || timeout < Date.today());
            
            if (finalScore >= LMS_Configuration.getScoreThreshold() &&
            (bypass || expired)) {
                result.put(cm, true);
            } else {
                result.put(cm, false);
            }
        }
        return result;
    }
}