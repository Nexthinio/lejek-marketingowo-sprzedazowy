public with sharing class LMS_Configuration {
    private static Boolean APPLICATIONTHRESHOLD;
    private static Integer SCORETHRESHOLD;
    private static LMS_Configuration__mdt configuration = LMS_Configuration__mdt.getInstance('default');
    
    
    public static Boolean isApplicationEnabled() {
        /* Nigdy nie powinno się to zdarzyć biorąc pod uwagę, że te rekordy tworzone są podczas deploymentu, ale trzeba sprawdzić i obsłużyć nulla.
         * Sprawdzenie czy aplikacja jest włączona jest zawsze pierwsze, więc wystarczy, że sprawdzimy tutaj.
         */
        if(configuration == null) {
            throw new IllegalArgumentException('Brak rekordu konfiguracji LMS_Configuration__mdt. Proszę utworzyć rekord konfiguracyjny o nazwie "default".');
        }
        if(APPLICATIONTHRESHOLD == null) {
            APPLICATIONTHRESHOLD = configuration.LMS_Application_Enabled__c;
        }
        return APPLICATIONTHRESHOLD;
    }
    
    public static Integer getScoreThreshold() {
        if(SCORETHRESHOLD == null) {
            SCORETHRESHOLD = Integer.valueOf(configuration.LMS_Score_Threshold__c);
        }
        return SCORETHRESHOLD;
    }
}