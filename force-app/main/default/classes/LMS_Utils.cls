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
}