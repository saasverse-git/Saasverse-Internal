public class ProjectTaskTrigger implements ITriggerHandler {

    public void beforeInsert(List<SObject> newList) {

    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        ProjectTaskTriggerHandler.updateHoursSoFarConsumed(
            (List<Project_Task__c>)newList
        );
    }

    public void afterInsert(List<SObject> newList) {
        ProjectTaskTriggerHandler.handleAfterInsertUpdateDelete(
            (List<Project_Task__c>)newList,
            new List<Project_Task__c>(), // no old records in insert
            true, false, false
        );
            ProjectTaskTriggerHandler.updateHoursSoFarConsumed(
            (List<Project_Task__c>)newList
        );
    }

public void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
    List<Project_Task__c> oldList = new List<Project_Task__c>();
    for (SObject sObj : oldMap.values()) {
        oldList.add((Project_Task__c)sObj);
    }

    ProjectTaskTriggerHandler.handleAfterInsertUpdateDelete(
        (List<Project_Task__c>)newList,
        oldList,
        false, true, false
    );
}


    public void beforeDelete(List<SObject> oldList) {
        // No need for logic here in your current design
    }

    public void afterDelete(List<SObject> oldList) {
        ProjectTaskTriggerHandler.handleAfterInsertUpdateDelete(
            new List<Project_Task__c>(), 
            (List<Project_Task__c>)oldList,
            false, false, true
        );
    }

    public void afterUndelete(List<SObject> newList) {
        // Optional: implement if undelete logic is needed
    }
}