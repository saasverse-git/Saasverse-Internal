trigger ResourceTrigger on Resource__c (before insert, before update, before delete,
    after insert, after update, after delete, after undelete) {
   TriggerDispatcher.dispatch(new ResourceTriggerHandler());

}