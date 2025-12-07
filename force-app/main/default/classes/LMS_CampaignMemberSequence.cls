public with sharing class LMS_CampaignMemberSequence {
    public static List<CampaignMember> cmOldList { get; protected set; }
    public static Map<Id, CampaignMember> cmOldMap { get; protected set; }
    public static List<CampaignMember> cmNewList { get; protected set; }
    public static Map<Id, CampaignMember> cmNewMap { get; protected set; }
    
    
    /**
     * Zaczyna sekwencję przetwarzania dla obiektu CampaignMember na podstawie danych z triggera.
     *
     * @param triggerCopy TriggerCopy obiekt zawierający dane z triggera
     * @return void
     */
    
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
    
    /**
     * Zapisuje dane CampaignMember z obiektu TriggerCopy do zmiennych statycznych klasy.
     *
     * @param triggerCopy TriggerCopy obiekt zawierający dane z triggera
     * @return void
     */
    
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
    
    /**
     * Obsługuje logikę usuwania dla obiektów CampaignMember.
     *
     * @return void
     */
    
    private static void handleDelete() {
        System.debug('---LMS_CampaignMemberSequence: handleDelete---');
        
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        
        
        //musimy tylko coś zrobić, jeśli usuwany CM był aktywny w lejku
        for (CampaignMember cm : cmOldList) {
            if (LMS_StatusManager.ACTIVESTATUSLIST.contains(cm.LMS_ResponseStatus__c)) {
                if (cm.ContactId != null) contactIds.add(cm.ContactId);
                else leadIds.add(cm.LeadId);
            }
        }
        
        if (contactIds.isEmpty() && leadIds.isEmpty()) {
            return;
        }
        
        Map<Id, SObject> parents = fetchParent(leadIds, contactIds);
        
        //ustawiamy status rodzica na Nurture
        for (SObject sobj : parents.values()) {
            if (sobj.getSObjectType() == Contact.SObjectType) {
                ((Contact)sobj).LMS_ContactStatus__c = LMS_StatusManager.NURTURESTATUS;
            } else {
                ((Lead)sobj).Status = LMS_StatusManager.NURTURESTATUS;
            }
        }
        
        update parents.values();
    }
    
    /**
     * Obsługuje logikę wstawiania dla obiektów CampaignMember.
     *
     * @return void
     */
    
    private static void handleInsert() {
        System.debug('---LMS_CampaignMemberSequence: handleInsert---');
        
        List<CampaignMember> responded = detectResponses(cmNewList);
        if (responded.isEmpty()) return;
        else LMS_FunnelSequence.setInquiry(responded);
        
        evaluateCMs(responded);
    }
    
    /**
     * Zaczyna sekwencję przetwarzania dla obiektu CampaignMember na podstawie danych z triggera.
     *
     * @param triggerCopy TriggerCopy obiekt zawierający dane z triggera
     * @return void
     */
    
    private static void handleUpdate() {
        System.debug('---LMS_CampaignMemberSequence: handleUpdate---');
        
        List<CampaignMember> toEvaluate = new List<CampaignMember>();
        
        for (Integer i = 0; i < cmNewList.size(); i++) {
            CampaignMember newCm = cmNewList[i];
            CampaignMember oldCM = cmOldMap.get(newCm.Id);
            
            // jeśli CM staje się responsem
            if(newCm.LMS_ResponseStatus__c == LMS_StatusManager.NOTARESPONSE && detectResponse(newCM, true)) {
                toEvaluate.add(newCm);
            }
        }
        if(toEvaluate.isEmpty()) return;
        LMS_FunnelSequence.setInquiry(toEvaluate);
        evaluateCMs(toEvaluate);
    }
    
    /**
     * Ocena kwalifikacji dla listy CampaignMember i aktualizacja odpowiednich rekordów rodzica.
     *
     * @param cmList Lista obiektów CampaignMember do oceny
     * @return void
     */
    
    private static void evaluateCMs (List<CampaignMember> cmList) {
        System.debug('---LMS_CampaignMemberSequence: evaluateCMs---');
        Set<Id> contactIds = extractContactIds(cmList);
        Set<Id> leadIds = extractLeadIds(cmList);
        Set<Id> campaignIds = extractCampaignIds(cmList);
        
        Map<Id, SObject> parents = fetchParent(leadIds, contactIds);
        Map<Id, Campaign> campaigns = fetchCampaigns(campaignIds);
        
        Map<CampaignMember, Boolean> qualified = evaluateQualification(cmList, parents, campaigns);
        
        applyQualificationResults(qualified, parents);
        
        update parents.values();
    }
    
    /**
     * Wykrywa odpowiedzi wśród listy CampaignMember. Domyślnie wykonuje DML, aby ustawić status odpowiedzi na "Not a Response" dla nieodpowiadających rekordów.
     *
     * @param cmList Lista obiektów CampaignMember do sprawdzenia
     * @param doDML Flaga określająca, czy zaktualizować ResponseStatus przy braku odpowiedzi
     * @return List<CampaignMember> Lista obiektów CampaignMember, które odpowiedziały
     */
    
    private static List<CampaignMember> detectResponses(List<CampaignMember> cmList) {
        return detectResponses(cmList, true);
    }
    
    private static List<CampaignMember> detectResponses(List<CampaignMember> cmList, Boolean doDML) {
        
        List<CampaignMember> responded = new List<CampaignMember>();
        
        for (CampaignMember cm : cmList) {
            if(detectResponse(cm, doDML)) {
                responded.add(cm);
                continue;
            }
        }
        return responded;
    }
    
    /**
     * Wykrywa odpowiedź dla pojedynczego obiektu CampaignMember. Pozwala wykonać aktualizację ResponseStatus przy braku odpowiedzi.
     *
     * @param cm Rekord CampaignMember do sprawdzenia
     * @param doDML Flaga określająca, czy zaktualizować ResponseStatus przy braku odpowiedzi
     * @return Boolean True, jeśli CampaignMember odpowiedział; w przeciwnym razie False
     */
    
    private static Boolean detectResponse(CampaignMember cm, Boolean doDML) {
        System.debug('---LMS_CampaignMemberSequence: detectResponse---');
        List<String> respondedStatuses = new List<String>();
        for (CampaignMemberStatus cms : [
                SELECT Label 
                FROM CampaignMemberStatus 
                WHERE CampaignId = :cm.CampaignId 
                    AND HasResponded = true]) {
            respondedStatuses.add(cms.Label);
        }
        
        if (respondedStatuses.contains(cm.Status) || cm.LMS_ResponseDate__c != null) {
            return true;
        } else {
            if(doDML) {
                LMS_FunnelSequence.setResponseStatus(cm, LMS_StatusManager.NOTARESPONSE);
            }
            return false;
        }
    }
    
    /**
     * Wykonuje zapytanie na rodzicach CampaignMember (Lead lub Contact).
     *
     * @param leadIds Zestaw identyfikatorów Leadów
     * @param contactIds Zestaw identyfikatorów Kontaktów
     * @return Map<Id, SObject> Mapa identyfikatorów rodziców do obiektów SObject (Lead lub Contact)
     */
    
    private static Map<Id, SObject> fetchParent(Set<Id> leadIds, Set<Id> contactIds) {
        System.debug('---LMS_CampaignMemberSequence: fetchParent---');
        Map<Id, SObject> parents = new Map<Id, SObject>();
        
        if (!leadIds.isEmpty()) {
            List<Lead> leads = LMS_DatabaseQueryHelper.runQueryList('Id, LMS_FunnelScore__c, LMS_NurtureTimeout__c, ' + LMS_StatusManager.LEADSTATUSFIELD,
            'Lead', LMS_DatabaseQueryHelper.inIds('Id', leadIds));
            for (Lead l : leads) {
                parents.put(l.Id, l);
            }
        }
        
        if (!contactIds.isEmpty()) {
            List<Contact> contacts = LMS_DatabaseQueryHelper.runQueryList('Id, LMS_FunnelScore__c, LMS_NurtureTimeout__c, ' + LMS_StatusManager.CONTACTSTATUSFIELD,
            'Contact', LMS_DatabaseQueryHelper.inIds('Id', contactIds));
            for (Contact c : contacts) {
                parents.put(c.Id, c);
            }
        }
        
        return parents;
    }
    
    /**
     * Wykonuje zapytanie na kampaniach powiązanych z CampaignMember.
     *
     * @param campaignIds Zestaw identyfikatorów Kampanii
     * @return Map<Id, Campaign> Mapa identyfikatorów Kampanii
     */
    
    private static Map<Id, Campaign> fetchCampaigns(Set<Id> campaignIds) {
        System.debug('---LMS_CampaignMemberSequence: fetchCampaigns---');
        if (campaignIds.isEmpty()) return new Map<Id, Campaign>();
        List<Campaign> campaigns = LMS_DatabaseQueryHelper.runQueryList('Id, LMS_CampaignScore__c, LMS_BypassNurtureTimeout__c',
        'Campaign', LMS_DatabaseQueryHelper.inIds('Id', campaignIds));
        return new Map<Id, Campaign>(campaigns);
    }
    
    /**
     * Te metody zwracają zestaw identyfikatorów z listy CampaignMember dla wybranego Obiektu.
     *
     * @param cms Lista CampaignMemberów
     * @return Set<Id> Zestaw zwróconych identyfikatorów
     */
    
    private static Set<Id> extractLeadIds(List<CampaignMember> cms) {
        System.debug('---LMS_CampaignMemberSequence: extractLeadIds---');
        Set<Id> ids = new Set<Id>();
        for (CampaignMember cm : cms) if (cm.LeadId != null) ids.add(cm.LeadId);
        return ids;
    }
    
    private static Set<Id> extractContactIds(List<CampaignMember> cms) {
        System.debug('---LMS_CampaignMemberSequence: extractContactIds---');
        Set<Id> ids = new Set<Id>();
        for (CampaignMember cm : cms) if (cm.ContactId != null) ids.add(cm.ContactId);
        return ids;
    }
    
    private static Set<Id> extractCampaignIds(List<CampaignMember> cms) {
        System.debug('---LMS_CampaignMemberSequence: extractCampaignIds---');
        Set<Id> ids = new Set<Id>();
        for (CampaignMember cm : cms) ids.add(cm.CampaignId);
        return ids;
    }
    
    /**
     * Ocena kwalifikacji dla listy CampaignMember na podstawie wyniku rodzica, kampanii, nurture timeout.
     *
     * @param cms Lista CampaignMemberów
     * @param parents Mapa identyfikatorów rodziców do obiektów SObject (Lead lub Contact)
     * @param campaigns Mapa identyfikatorów Kampanii
     * @return Map<CampaignMember, Boolean> Mapa CampaignMember do wartości kwalifikacji (true/false)
     */
    
    private static Map<CampaignMember, Boolean> evaluateQualification(
        List<CampaignMember> cms,
    Map<Id, SObject> parents,
    Map<Id, Campaign> campaigns
    ) {
        System.debug('---LMS_CampaignMemberSequence: evaluateQualification---');
        Map<CampaignMember, Boolean> result = new Map<CampaignMember, Boolean>();
        
        for (CampaignMember cm : cms) {
            
            SObject parent = parents.get(cm.ContactId != null ? cm.ContactId : cm.LeadId);
            Campaign camp = campaigns.get(cm.CampaignId);
            
            Integer parentScore = LMS_Utils.toInt(parent.get('LMS_FunnelScore__c'));
            Integer campaignScore = LMS_Utils.toInt(camp.get('LMS_CampaignScore__c'));
            Integer finalScore = parentScore + campaignScore;
            
            Boolean bypass = (Boolean) camp.get('LMS_BypassNurtureTimeout__c');
            Date timeout = (Date) parent.get('LMS_NurtureTimeout__c');
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
    
    /**
     * Zastosowuje wyniki kwalifikacji do CampaignMember i aktualizuje odpowiednie rekordy rodzica.
     *
     * @param qualified Mapa CampaignMember do wartości kwalifikacji (true/false)
     * @param parents Mapa identyfikatorów rodziców do obiektów SObject (Lead lub Contact)
     * @return void
     */
    
    private static void applyQualificationResults(Map<CampaignMember, Boolean> qualified, Map<Id, SObject> parents) {
        System.debug('---LMS_CampaignMemberSequence: applyQualificationResults---');
        List <CampaignMember> toUpdate = new List<CampaignMember>();
        
        for (CampaignMember cm : qualified.keySet()) {
            
            Id pid = cm.ContactId != null ? cm.ContactId : cm.LeadId;
            SObject parent = parents.get(pid);
            
            Boolean alreadyActive = false;
            
            if (parent.getSObjectType() == Contact.SObjectType) {
                Contact c = (Contact) parent;
                alreadyActive = LMS_StatusManager.ACTIVESTATUSLIST.contains(c.LMS_ContactStatus__c);
            }
            else if (parent.getSObjectType() == Lead.SObjectType) {
                Lead l = (Lead) parent;
                alreadyActive = LMS_StatusManager.ACTIVESTATUSLIST.contains(l.Status);
            }
            
            // Parent already active
            if (alreadyActive) {
                LMS_FunnelSequence.setResponseStatus(cm, LMS_StatusManager.RESOLVEDALREADYACTIVE);
                continue;
            }
            
            // Fully qualified
            if (qualified.get(cm) == true) {
                if (parent.getSObjectType() == Contact.SObjectType) {
                    ((Contact)parent).LMS_ContactStatus__c =
                        LMS_StatusManager.FIRSTACTIVESTATUS;
                } else {
                    ((Lead)parent).Status =
                        LMS_StatusManager.FIRSTACTIVESTATUS;
                }
                LMS_FunnelSequence.setResponseStatus(cm, LMS_StatusManager.FIRSTACTIVESTATUS);
                toUpdate.add(cm);
            }
            // Not at threshold
            else {
                LMS_FunnelSequence.setResponseStatus(cm, LMS_StatusManager.RESOLVEDNOTATTHRESHOLD);
            }
        }
        LMS_FunnelSequence.setMQL(toUpdate);
        LMS_FunnelSequence.startSequence(toUpdate);
    }
}