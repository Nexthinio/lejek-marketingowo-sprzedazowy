trigger LMS_LeadTrigger on Lead(after delete, after insert, after update) {
    LMS_MainDispatcher.dispatch(Lead.sObjectType,
    new LMS_TriggerCopy(trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.size, trigger.old, trigger.oldMap, trigger.new, trigger.newMap));
}