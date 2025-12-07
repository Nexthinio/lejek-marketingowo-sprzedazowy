public with sharing class LMS_MainDispatcher {

    /**
     * Dispatcher główny aplikacji, który kieruje logikę do odpowiednich sekwencji na podstawie typu obiektu wywołującego.
     *
     * @param triggeringObject Typ obiektu wywołującego (Contact, Lead, Opportunity, CampaignMember)
     * @param triggerCopy Kopia triggera z danymi
     * @return void
     */
    
    public static void dispatch(Schema.sObjectType triggeringObject, LMS_TriggerCopy triggerCopy) {
        System.debug('---LMS_MainDispatcher: Entered---');
        System.debug(triggeringObject);

        if(!LMS_Configuration.isApplicationEnabled()) {
            System.debug('---LMS_MainDispatcher: Application is disabled. Quitting.---');
            return;
        }

        if(triggeringObject == Contact.sObjectType || triggeringObject == Lead.sObjectType) {
            LMS_LeadContactSequence.startSequence(triggeringObject, triggerCopy);
        } else if (triggeringObject == Opportunity.sObjectType) {
            LMS_OpportunitySequence.startSequence(triggerCopy);
        } else if (triggeringObject == CampaignMember.sObjectType) {
            LMS_CampaignMemberSequence.startSequence(triggerCopy);
        }
    }
}