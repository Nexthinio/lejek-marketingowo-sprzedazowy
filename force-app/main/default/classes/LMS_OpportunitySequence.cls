public with sharing class LMS_OpportunitySequence {
    private static List<Opportunity> oppOldList = new List<Opportunity>();
    private static Map<Id, Opportunity> oppOldMap = new Map<Id, Opportunity>();
    private static List<Opportunity> oppNewList = new List<Opportunity>();
    private static Map<Id, Opportunity> oppNewMap = new Map<Id, Opportunity>();
    
    /**
     * Inicjuje sekwencję dla Opportunity.
     *
     * @param triggerCopy Kopia triggera z danymi
     * @return void
     */
    
    public static void startSequence(LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_OpportunitySequence: Entered---');
        
        oppOldList = (List<Opportunity>)triggerCopy.oldList;
        oppOldMap = (Map<Id, Opportunity>)triggerCopy.oldMap;
        
        if(!triggerCopy.isDelete) {
            oppNewList = (List<Opportunity>)triggerCopy.newList;
            oppNewMap = (Map<Id, Opportunity>)triggerCopy.newMap;
        }
        
        if(triggerCopy.isInsert) {
            handleInsert();
        } else if(triggerCopy.isDelete) {
            handleDelete();
        } else if(triggerCopy.isUpdate) {
            handleUpdate();
        }
    }
    
    private static void handleInsert() {
        System.debug('---LMS_OpportunitySequence: handleInsert---');
        List<Opportunity> oppsToEvaluate = new List<Opportunity>();
        
        for(Opportunity o : oppNewList) {
            //jeśli kontakt przypisany to dodajemy do listy
            if(o.LMS_FunnelContact__c != null) oppsToEvaluate.add(o);
        }
        
        if(oppsToEvaluate.size() > 0) {
            attachFunnel(oppsToEvaluate);
        }
    }
    
    private static void handleUpdate() {
        System.debug('---LMS_OpportunitySequence: handleUpdate---');
        List<Opportunity> oppsToEvaluate = new List<Opportunity>();
        
        for(Integer i = 0; i < oppNewList.size(); i++) {
            Opportunity oldOpp = oppOldList[i];
            Opportunity newOpp = oppNewMap.get(oldOpp.Id);
            //dodano funnel contact
            if(oldOpp.LMS_FunnelContact__c == null & newOpp.LMS_FunnelContact__c != null) {
                oppsToEvaluate.add(oppNewList[i]);
            }
        }
        
        if(oppsToEvaluate.size() > 0) {
            attachFunnel(oppsToEvaluate);
        }
    }
    
    private static void attachFunnel(List<Opportunity> opps) {
        System.debug('---LMS_OpportunitySequence: attachFunnel---');
        Set<Id> contactIds = new Set<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<CampaignMember> cmsToUpdate = new List<CampaignMember>();
        List<Contact> contactsToUpdate = new List<Contact>();
        for(Opportunity o : opps) {
            contactIds.add(o.LMS_FunnelContact__c);
        }
        
        String fields = LMS_DatabaseQueryHelper.getCMFieldsToQuery();
        String whereClause = LMS_DatabaseQueryHelper.buildActiveCampaignMemberWhere(true, contactIds, null);
        List<CampaignMember> activeCMs = (List<CampaignMember>) LMS_DatabaseQueryHelper.runQueryList(fields, 'CampaignMember', whereClause);
        
        Map<Id, CampaignMember> cmByParentId = new Map<Id, CampaignMember>();
        for (CampaignMember cm : activeCMs) {
            Id parentId = (cm.ContactId != null) ? cm.ContactId : cm.LeadId;
            if (!cmByParentId.containsKey(parentId) && cm.LMS_OpportunityName__c == null) {
                cmByParentId.put(parentId, cm);
            }
        }
        
        if(cmByParentId.size() == 0) return;
        System.debug('cmByParentId: ' + cmByParentId);
        
        for(Opportunity o : opps) {
            System.debug('ID OPKI: ' + o.Id);
            contactsToUpdate.add(
                new Contact(Id = o.LMS_FunnelContact__c, LMS_ContactStatus__c = LMS_StatusManager.getActiveOppStatus())
                );
            Id cmId = cmByParentId.get(o.LMS_FunnelContact__c).Id;
            oppsToUpdate.add(
                new Opportunity(
                Id = o.Id,
            LMS_ResponseID__c = cmId
                )
                );
            CampaignMember cm = new CampaignMember(Id = cmId, LMS_OpportunityName__c = o.Id);
            System.debug('Oppka na CMie:' + cm.LMS_OpportunityName__c);
            if(cm != null) cmsToUpdate.add(cm);
        }
        LMS_LeadContactSequence.setTurnOffTriggers(true);
        if(contactsToUpdate.size() > 0) update contactsToUpdate;
        if(oppsToUpdate.size() > 0) update oppsToUpdate;
        LMS_LeadContactSequence.setTurnOffTriggers(false);
        if(cmsToUpdate.size() > 0) update cmsToUpdate;
    }
    
    private static void handleDelete() {
        System.debug('---LMS_OpportunitySequence: handleDelete---');
        List<CampaignMember> cmsToClose = new List<CampaignMember>();
        List<Contact> contactsToClose = new List<Contact>();
        for(Opportunity opp : oppOldList) {
            contactsToClose.add(
                new Contact(Id = opp.LMS_FunnelContact__c, LMS_ContactStatus__c = LMS_StatusManager.getNurtureStatus())
                );
            CampaignMember cm = new CampaignMember(Id = opp.LMS_ResponseID__c, LMS_ResponseStatus__c = LMS_StatusManager.RESOLVEDOPPORTUNITYDELETED);
            if(cm != null) cmsToClose.add(cm);
        }
        try {
            if(cmsToClose.size() > 0) update cmsToClose;
            if(contactsToClose.size() > 0) update contactsToClose;
        } catch(Exception e) {
            
        }
    }
}