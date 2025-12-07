public with sharing class LMS_LeadContactSequence {
    public static List<Contact> conOldList { get; protected set; }
    public static Map<Id, Contact> conOldMap { get; protected set; }
    public static List<Contact> conNewList { get; protected set; }
    public static Map<Id, Contact> conNewMap { get; protected set; }
    
    public static List<Lead> leadOldList { get; protected set; }
    public static Map<Id, Lead> leadOldMap { get; protected set; }
    public static List<Lead> leadNewList { get; protected set; }
    public static Map<Id, Lead> leadNewMap { get; protected set; }
    
    public static Boolean isContact;
    private static Boolean fromLeadConversion = false;
    
    /**
     * Inicjuje sekwencję dla Lead lub Contact.
     * @param triggeringObject Typ obiektu wywołującego (Lead lub Contact)
     * @param triggerCopy Kopia triggera z danymi
     * @return void
     */
    
    public static void setFromLeadConversion(Boolean value) {
        fromLeadConversion = value;
    }
    
    public static void startSequence(Schema.sObjectType triggeringObject, LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_LeadContactSequence: Entered---');
        
        isContact = (triggeringObject == Contact.sObjectType);
        
        if(isContact) {
            conOldList = (List<Contact>)triggerCopy.oldList;
            conOldMap = (Map<Id, Contact>)triggerCopy.oldMap;
            conNewList = (List<Contact>)triggerCopy.newList;
            conNewMap = (Map<Id, Contact>)triggerCopy.newMap;
        } else {
            leadOldList = (List<Lead>)triggerCopy.oldList;
            leadOldMap = (Map<Id, Lead>)triggerCopy.oldMap;
            leadNewList = (List<Lead>)triggerCopy.newList;
            leadNewMap = (Map<Id, Lead>)triggerCopy.newMap;
        }
        
        if(triggerCopy.isUpdate) {
            handleUpdate(triggerCopy);
        }
    }
    
    /**
     * Metoda obsługująca logikę przy aktualizacji Lead lub Contact.
     *
     * @param triggerCopy Kopia triggera z danymi
     * @return void
     */
    
    private static void handleUpdate(LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_LeadContactSequence: handleUpdate---');
        
        if(fromLeadConversion) {
            System.debug('---LMS_LeadContactSequence: Pomijamy, żeby ominąć pętlę---');
            return;
        }
        
        LMS_LeadConvertSequence.startSequence(leadOldMap, leadNewList);
        
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        
        if(isContact) {
            for(Contact c : conNewList) {
                contactIds.add(c.Id);
            }
        } else {
            for(Lead l : leadNewList) {
                leadIds.add(l.Id);
            }
        }
        
        List<String> activeStatusList = LMS_StatusManager.ACTIVESTATUSLIST;
        String fields = LMS_DatabaseQueryHelper.getCMFieldsToQuery();
        String whereClause = LMS_DatabaseQueryHelper.buildActiveCampaignMemberWhere(isContact, contactIds, leadIds, activeStatusList);
        List<SObject> rows = LMS_DatabaseQueryHelper.runQueryList(fields, 'CampaignMember', whereClause);
        List<CampaignMember> activeCMs = (List<CampaignMember>) rows;
        
        Map<Id, CampaignMember> cmByParentId = new Map<Id, CampaignMember>();
        for (CampaignMember cm : activeCMs) {
            Id parentId = (cm.ContactId != null) ? cm.ContactId : cm.LeadId;
            if (!cmByParentId.containsKey(parentId)) {
                cmByParentId.put(parentId, cm);
            }
        }
        
        if(isContact) {
            for (Contact cNew : conNewList) {
                Contact cOld = conOldMap.get(cNew.Id);
                
                String newStatus = (String)cNew.get(LMS_StatusManager.CONTACTSTATUSFIELD);
                String oldStatus = (String)cOld.get(LMS_StatusManager.CONTACTSTATUSFIELD);
                
                Boolean wasActive = LMS_StatusManager.ACTIVESTATUSLIST.contains(oldStatus);
                Boolean isActiveNow = LMS_StatusManager.ACTIVESTATUSLIST.contains(newStatus);
                
                if (wasActive && !isActiveNow) {
                    CampaignMember cm = cmByParentId.get(cNew.Id);
                    if (cm != null) {
                        LMS_FunnelSequence.setResponseStatus(cm);
                    }
                }
            }
        } else {
            for (Lead lNew : leadNewList) {
                Lead lOld = leadOldMap.get(lNew.Id);
                
                String newStatus = (String)lNew.get(LMS_StatusManager.LEADSTATUSFIELD);
                String oldStatus = (String)lOld.get(LMS_StatusManager.LEADSTATUSFIELD);
                
                Boolean wasActive = LMS_StatusManager.ACTIVESTATUSLIST.contains(oldStatus);
                Boolean isActiveNow = LMS_StatusManager.ACTIVESTATUSLIST.contains(newStatus);
                
                if (wasActive && !isActiveNow) {
                    CampaignMember cm = cmByParentId.get(lNew.Id);
                    if (cm != null) {
                        LMS_FunnelSequence.setResponseStatus(cm);
                    }
                }
            }
        }
        
        if (!activeCMs.isEmpty()) {
            LMS_FunnelSequence.startSequence(activeCMs);
            update activeCMs;
        }
    }
    
    /**
     * Kopiuje status Lead do powiązanego Contact podczas konwersji.
     *
     * @return void
     */
    
    public static void copyLeadStatusToContactOnConvert() {
        System.debug('---LMS_LeadContactSequence: copyLeadStatusToContactOnConvert---');
        // Zbieramy leady, które właśnie są konwertowane
        
    }
    
}