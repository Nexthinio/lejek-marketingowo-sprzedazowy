public with sharing class LMS_Utils {
    
    /**
     * Konwertuje wartość obiektu na Integer.
     *
     * @param value Wartość do konwersji
     * @return Integer Przekonwertowana wartość
     */
    
    public static Integer toInt(Object value) {
        if (value == null) return 0;
        return ((Decimal)value).intValue();
    }
    
    /**
     * Sprawdza, czy pole o podanej nazwie istnieje na obiekcie o podanej nazwie.
     *
     * @param sObjectApiName Nazwa API obiektu
     * @param fieldApiName Nazwa API pola
     * @return void
     */
    
    public static void fieldExists(String sObjectApiName, String fieldApiName) {
        if(fieldApiName == 'STATUS' || fieldApiName == 'STAGE') {
            return;
        }
        
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(sObjectApiName)) {
            throw new IllegalArgumentException('Obiekt o nazwie API ' + sObjectApiName + ' nie istnieje.');
        }
        
        Schema.DescribeSObjectResult d = gd.get(sObjectApiName).getDescribe();
        if (!d.fields.getMap().containsKey(fieldApiName)) {
            throw new IllegalArgumentException('Pole o nazwie API ' + fieldApiName + ' nie istnieje na obiekcie ' + sObjectApiName + '.');
        }
    }
    
}