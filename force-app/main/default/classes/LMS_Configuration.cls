public with sharing class LMS_Configuration {
    private static Boolean applicationEnabled = true;
    private static Integer scoreThreshold = 100;
    public static final String FIRSTACTIVESTATUS = 'Working';
    public static final String FIRSTSTATUS = 'New';


    public static Boolean isApplicationEnabled() {
        return applicationEnabled;
    }

    public static Integer getScoreThreshold() {
        return scoreThreshold;
    }
}