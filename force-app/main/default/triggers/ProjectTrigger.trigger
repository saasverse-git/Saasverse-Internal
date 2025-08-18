trigger ProjectTrigger on Project__c (After Insert, After Update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            ProjectTriggerHandler.handleProjectResourceUpdate(Trigger.new, Trigger.oldMap);
        }
    }

}