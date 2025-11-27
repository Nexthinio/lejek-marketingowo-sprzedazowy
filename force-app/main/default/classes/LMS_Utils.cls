public with sharing class LMS_Utils {
    public static Integer toInt(Object value) {
        if (value == null) return 0;
        return ((Decimal)value).intValue();
    }
}