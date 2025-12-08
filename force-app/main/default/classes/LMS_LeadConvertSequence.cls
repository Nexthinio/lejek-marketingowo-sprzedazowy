public with sharing class LMS_LeadConvertSequence {
    
    
    public static void startSequence(Map<Id, Lead> leadOldMap, List<Lead> leadNewList) {
        System.debug('---LMS_LeadConvertSequence: Entered---');
        
        handleLeadConversionToContact(leadOldMap, leadNewList);
    }
    
    private static void handleLeadConversionToContact(Map<Id, Lead> leadOldMap, List<Lead> leadNewList) {
        System.debug('---LMS_LeadConvertSequence: handleLeadConversionToContact---');
        
        Map<Id, String> contactIdToLeadStatus = new Map<Id, String>();
        
        for (Lead lNew : leadNewList) {
            Lead lOld = leadOldMap.get(lNew.Id);
            if (lOld == null) continue;
            
            System.debug('Stary, konwersja: ' + lOld.IsConverted + ', Nowy, konwersja: ' + lNew.IsConverted + ', ContactID, nowy: ' + lNew.ConvertedContactId);
            
            // wykrycie startu konwersji
            if (!lOld.IsConverted && lNew.IsConverted && lNew.ConvertedContactId != null) {
                String leadStatus = (String) lOld.get(LMS_StatusManager.getLeadStatusField());
                if (leadStatus != null) {
                    contactIdToLeadStatus.put(lNew.ConvertedContactId, leadStatus);
                }
            }
        }
        
        if (contactIdToLeadStatus.isEmpty()) return;
        
        // Update kontaktów
        List<Contact> toUpdate = new List<Contact>();
        for (Id conId : contactIdToLeadStatus.keySet()) {
            Contact c = new Contact(
                Id = conId
                );
            c.put(LMS_StatusManager.getContactStatusField(), contactIdToLeadStatus.get(conId));
            toUpdate.add(c);
        }
        
        LMS_LeadContactSequence.setFromLeadConversion(true);
        update toUpdate;
        LMS_LeadContactSequence.setFromLeadConversion(false);
    }
    
    private static void handleLeadConversionToOpportunity(LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_LeadConvertSequence: handleLeadConversionToOpportunity---');
        
        // TODO
    }
}