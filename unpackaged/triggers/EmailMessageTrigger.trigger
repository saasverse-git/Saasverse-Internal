trigger EmailMessageTrigger on EmailMessage (after insert) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            EmailMessageTriggerHandler.afterInsert(trigger.new);
        }
    }
}