public with sharing class LMS_LeadConvertSequence {
    private static Map<Id, Lead> leadOldMap;
    private static List<Lead> leadNewList;
    
    public static void startSequence(Map<Id, Lead> lOldMap, List<Lead> lNewList) {
        System.debug('---LMS_LeadConvertSequence: Entered---');
        leadOldMap = lOldMap;
        leadNewList = lNewList;
        
        Map<Id, String> convertedContactIds = new Map<Id, String>();
        
        for (Lead lNew : leadNewList) {
            Lead lOld = leadOldMap.get(lNew.Id);
            if (lOld == null) continue;
            
            System.debug('Stary, konwersja: ' + lOld.IsConverted + ', Nowy, konwersja: ' + lNew.IsConverted + ', ContactID, nowy: ' + lNew.ConvertedContactId);
            
            // wykrycie konwersji
            if (!lOld.IsConverted && lNew.IsConverted && lNew.ConvertedContactId != null) {
                String leadStatus = (String) lOld.get(LMS_StatusManager.getLeadStatusField());
                if (leadStatus != null) {
                    convertedContactIds.put(lNew.ConvertedContactId, leadStatus);
                }
            }
        }
        
        if(convertedContactIds.isEmpty()) {
            return;
        }
        
        List<Contact> convertedContacts = LMS_DatabaseQueryHelper.runQueryList(
            'Id, CreatedDate, ' + LMS_StatusManager.getContactStatusField(),
        'Contact',
        LMS_DatabaseQueryHelper.inIds('Id', new Set<Id>(convertedContactIds.keySet()))
            );
        
        Map<Contact, String> newConvertedContactIds = new Map<Contact, String>();
        Map<Id, String> oldConvertedContactIds = new Map<Id, String>();
        List<Contact> oldConvertedContacts = new List<Contact>();
        
        for (Contact c : convertedContacts) {
            if(c.CreatedDate > System.now().addMinutes(-1)) { // tylko świeżo utworzone kontakty
                newConvertedContactIds.put(c, convertedContactIds.get(c.Id));
            } else {
                oldConvertedContactIds.put(c.Id, convertedContactIds.get(c.Id));
                oldConvertedContacts.add(c);
            }
        }
        
        if(newConvertedContactIds.size() > 0) {
            syncContactStatusFromLeadToContact(newConvertedContactIds);
        }
        
        if(oldConvertedContactIds.size() > 0) {
            handleLeadConversionToExistingContact(oldConvertedContactIds, oldConvertedContacts);
        }
    }
    
    private static void handleLeadConversionToExistingContact(Map<Id, String> contactIdToCheck, List<Contact> contacts) {
        System.debug('---LMS_LeadConvertSequence: handleLeadConversionToExistingContact---');
        List<String> activeStatusList = LMS_StatusManager.getActiveStatusList();
        List<CampaignMember> activeCMs;
        Map<Contact, String> contactsToUpdate = new Map<Contact, String>();
        
        for(Contact c : contacts) {
            String contactStatus = (String)c.get(LMS_StatusManager.getContactStatusField());
            String leadStatus = contactIdToCheck.get(c.Id);
            
            if(!LMS_StatusManager.getActiveStatusList().contains(leadStatus)) {
                // Status leada nie kwalifikuje go do aktywnego lejka, nic nie robimy
                continue;
            }
            
            Id leadId;
            for (Lead l : leadNewList) {
                if (l.ConvertedContactId == c.Id) {
                    leadId = l.Id;
                    break;
                }
            }
            
            String fields = LMS_DatabaseQueryHelper.getCMFieldsToQuery();
            String whereClause;
            
            System.debug('Contact Status: ' + contactStatus + ', Lead Status: ' + leadStatus);
            System.debug('Contact Status index: ' + activeStatusList.indexOf(contactStatus) + ', Lead Status index: ' + activeStatusList.indexOf(leadStatus));
            
            if(activeStatusList.indexOf(contactStatus) >= activeStatusList.indexOf(leadStatus)) {
                // Status kontaktu jest równy lub wyższy niż status leada
                whereClause = LMS_DatabaseQueryHelper.buildActiveCampaignMemberWhere(false, null, new Set<Id>{leadId});
            } else {
                // Status kontaktu jest niższy niż status leada
                contactsToUpdate.put(c, leadStatus);
                whereClause = LMS_DatabaseQueryHelper.buildActiveCampaignMemberWhere(true, new Set<Id>{c.Id}, null);
            }
            
            List<SObject> rows = LMS_DatabaseQueryHelper.runQueryList(fields, 'CampaignMember', whereClause);
            activeCMs = (List<CampaignMember>) rows;
            
            //ustawiamy Response status na 'Resolved - Merged' zamykając lejek, prowadzić go będziemy na dalszym lejku
            if(activeCMs.size() > 0) {
                for(CampaignMember cm : activeCMs) {
                    LMS_FunnelSequence.setResponseStatus(cm, LMS_StatusManager.RESOLVEDMERGED);
                }
            }
        }
        if(contactsToUpdate.size() > 0) syncContactStatusFromLeadToContact(contactsToUpdate);
        if(activeCMs != null && activeCMs.size() > 0) update activeCMs;
    }
    
    private static void syncContactStatusFromLeadToContact(Map<Contact, String> contactsToUpdate) {
        System.debug('---LMS_LeadConvertSequence: syncContactStatusFromLeadToContact---');
        
        List<Contact> contactsList = new List<Contact>();
        
        for (Contact c : contactsToUpdate.keySet()) {
            c.put(LMS_StatusManager.getContactStatusField(), contactsToUpdate.get(c));
            contactsList.add(c);
        }
        
        LMS_LeadContactSequence.setFromLeadConversion(true);
        update contactsList;
        LMS_LeadContactSequence.setFromLeadConversion(false);
    }
    
    
    private static void handleLeadConversionToOpportunity(LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_LeadConvertSequence: handleLeadConversionToOpportunity---');
        
        // TODO
    }
}