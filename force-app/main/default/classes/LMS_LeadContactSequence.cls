public with sharing class LMS_LeadContactSequence {
    private static List<Contact> conOldList = new List<Contact>();
    private static Map<Id, Contact> conOldMap = new Map<Id, Contact>();
    private static List<Contact> conNewList = new List<Contact>();
    private static Map<Id, Contact> conNewMap = new Map<Id, Contact>();
    
    private static List<Lead> leadOldList = new List<Lead>();
    private static Map<Id, Lead> leadOldMap = new Map<Id, Lead>();
    private static List<Lead> leadNewList = new List<Lead>();
    private static Map<Id, Lead> leadNewMap = new Map<Id, Lead>();
    
    private static Boolean isContact;
    private static Boolean turnOffTriggers = false;
    
    /**
     * Inicjuje sekwencję dla Lead lub Contact.
     * @param triggeringObject Typ obiektu wywołującego (Lead lub Contact)
     * @param triggerCopy Kopia triggera z danymi
     * @return void
     */
    
    public static void setTurnOffTriggers(Boolean value) {
        turnOffTriggers = value;
    }

    public static Boolean getTurnOffTriggers() {
        return turnOffTriggers;
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
        
        if(turnOffTriggers) {
            /* To co miało zostać obsłużone podczas konwersji leadów zostało już obsłużone, nie musimy tego robić ponownie.
             * Wchodzimy tu ponownie przez aktualizację statusu kontaktu
             */
            return;
        }
        
        if(!isContact) {
            LMS_LeadConvertSequence.startSequence(leadOldMap, leadNewList);
        }
        
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
        
        String fields = LMS_DatabaseQueryHelper.getCMFieldsToQuery();
        String whereClause = LMS_DatabaseQueryHelper.buildActiveCampaignMemberWhere(isContact, contactIds, leadIds);
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
                
                String newStatus = (String)cNew.get(LMS_StatusManager.getContactStatusField());
                String oldStatus = (String)cOld.get(LMS_StatusManager.getContactStatusField());
                
                Boolean wasActive = LMS_StatusManager.getActiveStatusList().contains(oldStatus);
                Boolean isActiveNow = LMS_StatusManager.getActiveStatusList().contains(newStatus);
                
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
                
                String newStatus = (String)lNew.get(LMS_StatusManager.getLeadStatusField());
                String oldStatus = (String)lOld.get(LMS_StatusManager.getLeadStatusField());
                
                Boolean wasActive = LMS_StatusManager.getActiveStatusList().contains(oldStatus);
                Boolean isActiveNow = LMS_StatusManager.getActiveStatusList().contains(newStatus);
                
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
            turnOffTriggers = true;
            update activeCMs;
            turnOffTriggers = false;
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