trigger TaskTrigger on Project_Task__c (before insert, before Update, before delete, after Insert, After Update, After Delete,  after undelete) {
    
  
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        
        //ProjectTaskTriggerHandler.calculateEffort(Trigger.new, Trigger.oldMap);
        ProjectTaskTriggerHandler.calculateHoursSoFarConsumed(Trigger.new, Trigger.oldMap);  
        ProjectTaskTriggerHandler.calculateTestingHoursSoFarConsumed(Trigger.new, Trigger.oldMap);
        ProjectTaskTriggerHandler.autoUpdateCurrentTaskStatus(Trigger.new, Trigger.oldMap);
        ProjectTaskTriggerHandler.autoUpdateTaskTestingStatus(Trigger.new);
        //ProjectTaskTriggerHandler.updateIsWorkingOnOtherTickets(trigger.New);     
    }
     
    if(Trigger.isAfter){
        if (Trigger.isInsert || Trigger.isUpdate ||  Trigger.isUndelete) {
            ProjectTaskTriggerHandler.calculateEffort(Trigger.new, Trigger.oldMap, Trigger.isDelete);
            ProjectTaskTriggerHandler.updateIsWorkingOnOtherTickets(Trigger.newMap.keySet());
            //ProjectTaskTriggerHandler.calculateTestingHoursSoFarConsumed(Trigger.new, Trigger.oldMap);
            
            //ProjectTaskTriggerHandler.sendEmailToApprover(Trigger.new);
            
        }
         if(Trigger.isDelete){
            ProjectTaskTriggerHandler.updateIsWorkingOnOtherTickets(Trigger.oldMap.keySet());
             ProjectTaskTriggerHandler.calculateEffort(Trigger.new, Trigger.oldMap, Trigger.isDelete);
        }
    }
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete || Trigger.isUndelete)) {
        Set<Id> taskIds = Trigger.isDelete ? Trigger.oldMap.keySet() : Trigger.newMap.keySet();
        ProjectTaskTriggerHandler.updateProjectTaskScore(taskIds);
    } 
    // Added by Anurag Bhatt
    If(Trigger.isAfter){
        If(trigger.IsUpdate){
            System.debug('In Update Scenario !!!');
           ProjectTaskTriggerHandler.updateDevelopmentEndDate(Trigger.new, Trigger.oldMap);
           //ProjectTaskTriggerHandler.checkForStatusDowngrade(Trigger.new, Trigger.oldMap);            
        }
    }


        
}