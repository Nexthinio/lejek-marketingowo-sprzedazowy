public with sharing class LMS_DatabaseQueryHelper {
    public static final Map<String, String> FUNNELSTATUSLIST = LMS_FunnelSequence.getFunnelStatusList();
    
    /**
     * Pobiera zestaw wymaganych pól do zapytania dla rodzica CampaignMember (Contact lub Lead). Używa w tym celu etapów lejka.
     *
     * @param isContact Czy rodzic to Contact (true) czy Lead (false)
     * @return Set<String> Zestaw nazw pól do zapytania
     */
    
    public static Set<String> requiredFieldsForParent(Boolean isContact) {
        System.debug('---LMS_DatabaseQueryHelper: requiredFieldsForParent---');
        String sObj = isContact ? 'Contact' : 'Lead';
        Set<String> fields = new Set<String>{ 'Id' };
        
        for (String def : FUNNELSTATUSLIST.values()) {
            LMS_FunnelAction fa = LMS_FunnelAction.parse(def);
            if (fa.action != 'PARENTUPDATE') continue;
            if (String.isBlank(fa.fieldApi)) continue;
            
            if(fa.fieldApi == 'STATUS') {
                if(isContact) {
                    fields.add(LMS_StatusManager.getContactStatusField());
                } else {
                    fields.add(LMS_StatusManager.getLeadStatusField());
                }
            } else {
                fields.add(fa.fieldApi);
            }
        }
        return fields;
    }
    
    /**
     * Pobiera zestaw wymaganych pól do zapytania dla Opportunity powiązanej z CampaignMember. Używa w tym celu etapów lejka.
     *
     * @return Set<String> Zestaw nazw pól do zapytania
     */
    
    public static String requiredFieldsForOpportunity() {
        System.debug('---LMS_DatabaseQueryHelper: requiredFieldsForOpportunity---');
        Set<String> fields = new Set<String>{ 'Id', 'LMS_FunnelContact__c', 'LMS_ResponseID__c' };
        
        for (String def : FUNNELSTATUSLIST.values()) {
            LMS_FunnelAction fa = LMS_FunnelAction.parse(def);
            if (fa.action != 'OPPORTUNITYUPDATE') continue;
            if (String.isBlank(fa.fieldApi)) continue;
            
            if(fa.fieldApi == 'STAGE') {
                fields.add(LMS_StatusManager.getOpportunityStageField());
            } else {
                fields.add(fa.fieldApi);
            }
        }
        List<String> ordered = new List<String>();
        ordered.addAll(fields);
        ordered.sort();
        return String.join(ordered, ',');
    }
    
    /**
     * Pobiera rodzica (Contact lub Lead) dla podanego CampaignMember używając zwróconych pól z metody requiredFieldsForParent.
     *
     * @return SObject Zbudowane zapytanie
     */
    
    public static SObject queryParent(CampaignMember cm) {
        System.debug('---LMS_DatabaseQueryHelper: queryParent---');
        Boolean isContact = (cm.ContactId != null);
        String sObj = isContact ? 'Contact' : 'Lead';
        Id parentId = isContact ? cm.ContactId : cm.LeadId;
        
        Set<String> fields = requiredFieldsForParent(isContact);
        
        List<String> fieldList = new List<String>();
        fieldList.addAll(fields);
        fieldList.sort();
        
        String soql =
            'SELECT ' + String.join(fieldList, ',') +
            ' FROM ' + sObj +
            ' WHERE Id = :parentId';
        
        return Database.query(soql);
    }
    
    /**
     * Pobiera Opportunity powiązaną z podanym CampaignMember używając zwróconych pól z metody requiredFieldsForOpportunity.
     *
     * @return SObject Zbudowane zapytanie
     */
    
    public static SObject queryOpportunity(CampaignMember cm) {
        String fields = requiredFieldsForOpportunity();
        Id oppId = cm.LMS_OpportunityName__c;
        
        String soql =
            'SELECT ' + fields +
            ' FROM Opportunity WHERE Id = :oppId';
        
        return Database.query(soql);
    }
    
    /**
     * Pobiera pola do zapytania dla CampaignMember używając etapów lejka.
     *
     * @return String Pola do zapytania
     */
    
    public static String getCMFieldsToQuery() {
        System.debug('---LMS_FunnelSequence: getFunnelListFields---');
        
        Set<String> fields = new Set<String>{
            'Id', 'ContactId', 'LeadId', 'CampaignId', 'Status', 'LMS_ResponseStatus__c', 'IsDeleted, LMS_OpportunityName__c, LMS_OpportunityName__r.IsWon, LMS_OpportunityName__r.IsClosed'
        };
        
        fields.add('Contact.' + LMS_StatusManager.getContactStatusField());
        fields.add('Lead.' + LMS_StatusManager.getLeadStatusField());
        
        for (String funnelStage : FUNNELSTATUSLIST.keySet()) {
            fields.add(LMS_FunnelSequence.getFunnelFieldName(funnelStage));
            fields.add(LMS_FunnelSequence.getFunnelFieldDateName(funnelStage));
        }
        
        List<String> ordered = new List<String>();
        ordered.addAll(fields);
        ordered.sort();
        return String.join(ordered, ',');
    }
    
    /**
     * Buduje klauzulę WHERE do zapytania SOQL znajdującą aktywne lejki dla podanych kontaktów/leadów.
     *
     * @param isContact Flaga, ustalająca czy mamy do czynienia z kontaktami czy leadami
     * @param contactIds ID kontaktów
     * @param leadIds ID leadów
     * @return String Klauzula WHERE do zapytania SOQL
     */
    
    public static String buildActiveCampaignMemberWhere(Boolean isContact, Set<Id> contactIds, Set<Id> leadIds) {
        List<String> clauses = new List<String>();
        List<String> activeStatusList = LMS_StatusManager.getActiveStatusList();
        
        if (isContact) {
            clauses.add(inIds('ContactId', contactIds));
        } else {
            clauses.add(inIds('LeadId', leadIds));
        }
        
        clauses.add(LMS_DatabaseQueryHelper.inStrings('LMS_ResponseStatus__c', activeStatusList));
        clauses.add('IsDeleted = false');
        
        return String.join(clauses, ' AND ');
    }
    
    /**
     * Wykonuje zapytanie SOQL i zwraca wynik w postaci List<SObject> dzięki czemu funkcja jest uniwersalna. Pozwala wykonywać dynamiczne zapytania.
     * @param fields Pola do zwrócenia
     * @param sObjectName Nazwa obiektu
     * @param whereClause Klauzula WHERE
     * @return List<SObject> Wynik zapytania
     */
    
    public static List<SObject> runQueryList(String fields, String sObjectName, String whereClause) {
        System.debug('---LMS_DatabaseQueryHelper: runQueryList---');
        String soql = 'SELECT ' + fields + ' FROM ' + sObjectName +
            (String.isBlank(whereClause) ? '' : ' WHERE ' + whereClause);
        return Database.query(soql);
    }
    
    /**
     * Pozwala stworzyć klauzulę WHERE, w której chcemy znaleźć rekordy o danych ID.
     * @param fieldApi Nazwa API pola które porównujemy
     * @param ids ID których szukamy
     * @return String Zwraca tekst zawierający zbudowaną klauzulę where.
     */
    
    public static String inIds(String fieldApi, Set<Id> ids) {
        if (ids == null || ids.isEmpty()) return null;
        List<String> q = new List<String>();
        for (Id i : ids) q.add('\'' + String.valueOf(i) + '\'');
        return fieldApi + ' IN (' + String.join(q, ',') + ')';
    }
    
    /**
     * Pozwala stworzyć klauzulę WHERE, w której chcemy znaleźć rekordy, które posiadają dane pole o podanych wartościach.
     * @param fieldApi Nazwa API pola które porównujemy
     * @param vals Szukane wartości
     * @return String Zwraca tekst zawierający zbudowaną klauzulę where.
     */
    
    public static String inStrings(String fieldApi, List<String> vals) {
        if (vals == null || vals.isEmpty()) return null;
        List<String> q = new List<String>();
        for (String v : vals) q.add('\'' + String.escapeSingleQuotes(v) + '\'');
        return fieldApi + ' IN (' + String.join(q, ',') + ')';
    }
}