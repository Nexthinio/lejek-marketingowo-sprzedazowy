trigger LMS_ContactTrigger on Contact(after delete, after insert, after update) {
    LMS_MainDispatcher.dispatch(Contact.sObjectType,
    new LMS_TriggerCopy(trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.size, trigger.old, trigger.oldMap, trigger.new, trigger.newMap));
}