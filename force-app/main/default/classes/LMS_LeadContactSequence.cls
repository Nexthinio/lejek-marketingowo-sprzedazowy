public with sharing class LMS_LeadContactSequence {
    public static void startSequence(Schema.sObjectType triggeringObject, LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_LeadContactSequence: Entered---');
        System.debug(triggeringObject);
    }
}