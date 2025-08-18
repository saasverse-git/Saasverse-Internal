trigger CaseTrigger on Case (before insert , before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            CaseTriggerHandler.beforeInsert(trigger.new);
        }
        if (Trigger.isUpdate) {
            CaseTriggerHandler.beforeUpdate(trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CaseTriggerHandler.afterInsert(trigger.new);
        }
        if (Trigger.isUpdate) {
            
            CaseTriggerHandler.afterUpdate(trigger.new, Trigger.oldMap);
        }
    }
}