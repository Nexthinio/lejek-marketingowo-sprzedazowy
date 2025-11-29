public with sharing class LMS_Configuration {
    private static Boolean applicationEnabled = true;
    private static Integer scoreThreshold = 100;


    public static Boolean isApplicationEnabled() {
        return applicationEnabled;
    }

    public static Integer getScoreThreshold() {
        return scoreThreshold;
    }
}