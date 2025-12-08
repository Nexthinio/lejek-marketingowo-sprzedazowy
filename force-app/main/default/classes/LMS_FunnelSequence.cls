public with sharing class LMS_FunnelSequence {
    private static List<LMS_Funnel_Rule__mdt> funnelConfiguration;
    // public static final Map<String, String> FUNNELSTATUSLIST = new Map<String, String>{
        //     'Inquiry' => 'RESPONSE',
        //     'MQL' => 'ACTIVERESPONSE',
        //     'SAL' => 'PARENTUPDATE.STATUS.Attempting Contact',
        //     'SQL' => 'PARENTUPDATE.STATUS.Qualified',
        //     'SQO' => 'NEWOPPORTUNITY',
        //     'Won' => 'OPPORTUNITYUPDATE.STAGE.Won'
    // };
    
    private static Map<String, String> FUNNELSTATUSLIST = new Map<String, String>();
    
    /**
     * Inicjuje sekwencję lejka dla podanej listy CampaignMemberów.
     *
     * @return void
     */
    
    public static void startSequence(List<CampaignMember> cmList) {
        System.debug('---LMS_FunnelSequence: startSequence---');
        
        for (CampaignMember cm : cmList) {
            checkFunnelFields(cm);
        }
    }
    
    public static Map<String, String> getFunnelStatusList() {
        if(FUNNELSTATUSLIST.isEmpty()) {
            initializeConfiguration();
        }
        return FUNNELSTATUSLIST;
    }
    
    private static void initializeConfiguration() {
        if (funnelConfiguration == null) {
            funnelConfiguration = [SELECT LMS_Funnel_Stage_Name__c, LMS_Field_API_Name__c, LMS_Expected_Value__c, LMS_Is_Active__c, LMS_Sequence_Order__c, LMS_Trigger__c FROM LMS_Funnel_Rule__mdt
                WHERE LMS_Is_Active__c = true
                ORDER BY LMS_Sequence_Order__c ASC];
        }
        
        /* Nigdy nie powinno się to zdarzyć, podobnie jak z konfiguracją aplikacji, ale trzeba sprawdzić i obsłużyć nulla.
         * Rzucamy error.
         */
        if (funnelConfiguration.size() == 0) {
            throw new IllegalArgumentException('Brak aktywnych reguł lejka w konfiguracji LMS_Funnel_Rule__mdt. Proszę dodać co najmniej jedną regułę.');
        }
        
        // Parsowanie do Map<nazwa etapu lejka, definicja>
        for(LMS_Funnel_Rule__mdt rule : funnelConfiguration) {
            String criteria = rule.LMS_Trigger__c;
            if (rule.LMS_Field_API_Name__c != null) {
                if(rule.LMS_Trigger__c == 'PARENTUPDATE') {
                    LMS_Utils.fieldExists('Lead', rule.LMS_Field_API_Name__c);
                    LMS_Utils.fieldExists('Contact', rule.LMS_Field_API_Name__c);
                } else if (rule.LMS_Trigger__c == 'OPPORTUNITYUPDATE') {
                    LMS_Utils.fieldExists('Opportunity', rule.LMS_Field_API_Name__c);
                }
                criteria += '.' + rule.LMS_Field_API_Name__c + '.' + rule.LMS_Expected_Value__c;
            }
            FUNNELSTATUSLIST.put(rule.LMS_Funnel_Stage_Name__c, criteria);
        }
    }
    
    /**
     * Na podstawie definicji etapów lejka, rozprowadza logikę do odpowiednich metod.
     *
     * @param cm CampaignMember do sprawdzenia
     * @return void
     */
    
    public static void checkFunnelFields(CampaignMember cm) {
        System.debug('---LMS_FunnelSequence: checkFunnelFields---');
        for(String funnelStage : getFunnelStatusList().keySet()) {
            String def = getFunnelStatusList().get(funnelStage);
            LMS_FunnelAction action = LMS_FunnelAction.parse(def);
            
            switch on action.action {
                when 'PARENTUPDATE'     { handleParentUpdate(cm, action, funnelStage); }
                when 'OPPORTUNITYUPDATE' { handleOPPORTUNITYUPDATE(cm, action, funnelStage); }
                when 'NEWOPPORTUNITY'   { System.debug('NEWOPPORTUNITY not implemented'); }
            }
        }
    }
    
    /**
     * Sprawdza czy dany etap lejka powinien zostać ustawiony na podstawie zmian w rodzicu (Contact lub Lead).
     *
     * @param cm CampaignMember podlegający pod aktualizowanego rodzica.
     * @param fa Definicja etapu lejka.
     * @param funnelStage Nazwa obecnie rozpatrywanego etapu lejka.
     * @return void
     */
    
    private static void handleParentUpdate(CampaignMember cm, LMS_FunnelAction fa, String funnelStage) {
        System.debug('---LMS_FunnelSequence: handleParentUpdate---');
        
        Contact c = null;
        Lead l = null;
        
        if (cm.ContactId != null) {
            c = (Contact) LMS_DatabaseQueryHelper.queryParent(cm);
        } else {
            l = (Lead) LMS_DatabaseQueryHelper.queryParent(cm);
        }
        
        String contactStatusName = LMS_StatusManager.getContactStatusField();
        String leadStatusName = LMS_StatusManager.getLeadStatusField();
        
        if(fa.fieldApi == 'STATUS') {
            if(c != null) {
                if(c.get(contactStatusName) == fa.expected) {
                    setFunnelStage(cm, funnelStage);
                }
            } else {
                if(l.get(leadStatusName) == fa.expected) {
                    setFunnelStage(cm, funnelStage);
                }
            }
        } else {
            if(c != null) {
                if(c.get(fa.fieldApi) == fa.expected) {
                    setFunnelStage(cm, funnelStage);
                }
            } else {
                if(l.get(fa.fieldApi) == fa.expected) {
                    setFunnelStage(cm, funnelStage);
                }
            }
        }
    }
    
    /**
     * Sprawdza czy dany etap lejka powinien zostać ustawiony na podstawie zmian w powiązanej Opportunity.
     *
     * @param cm CampaignMember podlegający pod aktualizowaną Opportunity.
     * @param fa Definicja etapu lejka.
     * @param funnelStage Nazwa obecnie rozpatrywanego etapu lejka
     * @return void
     */
    
    private static void handleOPPORTUNITYUPDATE(CampaignMember cm, LMS_FunnelAction fa, String funnelStage) {
        System.debug('---LMS_FunnelSequence: handleOPPORTUNITYUPDATE---');
    }
    
    /**
     * Ustawia etap lejka na podanym CampaignMemberze oraz uzupełnia wcześniejsze etapy lejka, jeśli były puste.
     *
     * @param cm CampaignMember do ustawienia etapu lejka.
     * @param funnelStage Nazwa etapu lejka do ustawienia.
     * @return void
     */
    
    private static void setFunnelStage(CampaignMember cm, String funnelStage) {
        System.debug('---LMS_FunnelSequence: setFunnelStage---');
        // najpierw ustaw aktualny stage
        cm.put(getFunnelFieldName(funnelStage), true);
        cm.put(getFunnelFieldDateName(funnelStage), Date.today());
        
        setResponseStatus(cm);
        
        // przejdź przez wszystkie inne stages
        for (String stage : getFunnelStatusList().keySet()) {
            System.debug('Sprawdzany stage: ' + stage);
            if (stage == funnelStage) {
                break;
            }
            
            String fieldName = getFunnelFieldName(stage);
            String fieldDate = getFunnelFieldDateName(stage);
            
            Boolean value = (Boolean)cm.get(fieldName);
            Date dateValue = (Date)cm.get(fieldDate);
            
            if (value == false && dateValue == null) {
                cm.put(fieldName, true);
                cm.put(fieldDate, date.today());
            }
        }
    }
    
    /**
     * Ustawia status odpowiedzi na CampaignMember na podstawie statusu rodzica (Contact lub Lead).
     *
     * @param cm CampaignMember do sprawdzenia
     * @return void
     */
    
    public static void setResponseStatus(CampaignMember cm) {
        System.debug('---LMS_FunnelSequence: setResponseStatus---');
        if(cm.ContactId != null) {
            cm.put('LMS_ResponseStatus__c', cm.Contact.get(LMS_StatusManager.getContactStatusField()) );
        } else {
            cm.put('LMS_ResponseStatus__c', cm.Lead.get(LMS_StatusManager.getLeadStatusField()));
        }
    }
    
    /**
     * Ustawia status odpowiedzi na CampaignMember na podstawie podanego statusu.
     *
     * @param cmList Lista CampaignMemberów do ustawienia statusu
     * @param status Status do ustawienia
     * @return void
     */
    
    public static void setResponseStatus(List<CampaignMember> cmList, String status) {
        for (CampaignMember cm : cmList) {
            setResponseStatus(cm, status);
        }
    }
    
    /**
     * Ustawia status odpowiedzi na CampaignMember na podstawie podanego statusu.
     *
     * @param cm CampaignMember do ustawienia statusu
     * @param status Status do ustawienia
     * @return void
     */
    
    public static void setResponseStatus(CampaignMember cm, String status) {
        System.debug('---LMS_FunnelSequence: setResponseStatus---');
        cm.LMS_ResponseStatus__c = status;
    }
    
    /**
     * Pobiera nazwę pola etapu lejka na podstawie nazwy etapu.
     *
     * @param funnelStage Nazwa etapu lejka
     * @return void
     */
    
    public static String getFunnelFieldName(String funnelStage) {
        System.debug('---LMS_FunnelSequence: getFunnelFieldName---');
        return 'LMS_' + funnelStage + '__c';
    }
    
    /**
     * Pobiera nazwę pola daty etapu lejka na podstawie nazwy etapu.
     *
     * @param funnelStage Nazwa etapu lejka
     * @return void
     */
    
    public static String getFunnelFieldDateName(String funnelStage) {
        System.debug('---LMS_FunnelSequence: getFunnelFieldDateName---');
        return 'LMS_' + funnelStage + 'Date__c';
    }
    
    /**
     * Czyści informacje o odpowiedzi na podanej liście CampaignMemberów (wykorzystywane aby wymazać manualne ustawienie wartości przez użytkownika przy tworzeniu CMa).
     *
     * @param cmList Lista CampaignMemberów do wyczyszczenia
     * @return void
     */
    
    private static void clearResponseInfo(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            clearResponseInfo(cm);
        }
    }
    
    /**
     * Czyści informacje o odpowiedzi dla podanego CMa.
     *
     * @param cm CampaignMember do wyczyszczenia
     * @return void
     */
    
    public static void clearResponseInfo(CampaignMember cm) {
        System.debug('---LMS_FunnelSequence: clearResponseInfo---');
        cm.LMS_ResponseStatus__c = null;
        cm.LMS_ResponseDate__c = null;
    }
    
    /**
     * Ustawia Inquiry na podanej liście CampaignMemberów.
     *
     * @param cmList Lista CampaignMemberów do ustawienia Inquiry
     * @return void
     */
    
    public static void setInquiry(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            if(cm.LMS_Inquiry__c == false && cm.LMS_InquiryDate__c == null) {
                setInquiry(cm);
            }
        }
    }
    
    /**
     * Ustawia Inquiry na podanym CampaignMemberze.
     *
     * @param cm CampaignMember do ustawienia Inquiry
     * @return void
     */
    
    public static void setInquiry(CampaignMember cm) {
        System.debug('---LMS_FunnelSequence: setInquiry---');
        cm.LMS_Inquiry__c = true;
        cm.LMS_InquiryDate__c = Date.today();
        cm.LMS_ResponseDate__c = Date.today();
    }
    
    /**
     * Ustawia MQL na podanej liście CampaignMemberów.
     *
     * @param cmList Lista CampaignMemberów do ustawienia MQL
     * @return void
     */
    
    public static void setMQL(List<CampaignMember> cmList) {
        for (CampaignMember cm : cmList) {
            if(cm.LMS_MQL__c == false && cm.LMS_MQLDate__c == null) {
                setMQL(cm);
            }
        }
        setInquiry(cmList);
    }
    
    /**
     * Ustawia MQL na podanym CampaignMemberze.
     *
     * @param cm CampaignMember do ustawienia MQL
     * @return void
     */
    
    public static void setMQL(CampaignMember cm) {
        System.debug('---LMS_FunnelSequence: setMQL---');
        cm.LMS_MQL__c = true;
        cm.LMS_MQLDate__c = Date.today();
    }
}