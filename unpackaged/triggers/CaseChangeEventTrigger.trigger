trigger CaseChangeEventTrigger on CaseChangeEvent (after insert) {
    CaseChangeEventHandler.handleAfterInsert(Trigger.new);
}