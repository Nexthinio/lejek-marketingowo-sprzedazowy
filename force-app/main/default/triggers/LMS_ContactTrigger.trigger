trigger LMS_ContactTrigger on Contact(before delete, before insert,  before update) {
    LMS_MainDispatcher.dispatch(Contact.sObjectType,
    new LMS_TriggerCopy(trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.size, trigger.old, trigger.oldMap, trigger.new, trigger.newMap));
}