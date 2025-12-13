public with sharing class LMS_Configuration {
    private static Boolean APPLICATIONENABLED;
    private static Integer SCORETHRESHOLD;
    private static LMS_Configuration__mdt configuration = LMS_Configuration__mdt.getInstance('default');
    
    /**
     * Zwraca informację o tym, czy aplikacja powinna reagować na zmiany
     * @return Boolean
     */
    
    public static Boolean isApplicationEnabled() {
        /* Nigdy nie powinno się to zdarzyć biorąc pod uwagę, że te rekordy tworzone są podczas deploymentu, ale trzeba sprawdzić i obsłużyć nulla.
         * Sprawdzenie czy aplikacja jest włączona jest zawsze pierwsze, więc wystarczy, że sprawdzimy tutaj.
         */
        if(configuration == null) {
            APPLICATIONENABLED = true;
        } else if(APPLICATIONENABLED == null) {
            APPLICATIONENABLED = configuration.LMS_Application_Enabled__c;
        }
        return APPLICATIONENABLED;
    }
    
    /**
     * Zwraca informację o granicy punktowej, poniżej której CampaignMember nie zostanie zakwalifikowany
     * @return Integer
     */

    public static Integer getScoreThreshold() {
        if(configuration == null) {
            SCORETHRESHOLD = 100;
        } else if(SCORETHRESHOLD == null) {
            SCORETHRESHOLD = Integer.valueOf(configuration.LMS_Score_Threshold__c);
        }
        return SCORETHRESHOLD;
    }
}