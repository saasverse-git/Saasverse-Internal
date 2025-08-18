public with sharing class taskTriggerHandler extends triggerHandler {
    Private List<Project_Task__c> newTaskList;
    Private Map<Id, Project_Task__c> newTaskMap;
    Private Map<Id, Project_Task__c> oldTaskMap;
    
    Public taskTriggerHandler(){
        this.newTaskList = (List<Project_Task__c>)trigger.new;
        this.newTaskMap = (Map<Id, Project_Task__c>)trigger.newMap;
        this.oldTaskMap = (Map<Id, Project_Task__c>)trigger.oldMap;
    }
    public override void beforeInsert(){
        updateTask();
    } 
    public override void afterInsert(){
        updateTask();
    }
    public override void afterUpdate(){
        updateTask();
    }
    
    private void updateTask(){
        Date today = Date.today();
        List<Project_Task__c> recordsToUpdate = new List<Project_Task__c>();

        for (Project_Task__c task : newTaskList) {
            try {
                // Ensure only records that match batch criteria are processed
                if (
                    task.Current_Task_Status__c != 'Completed' &&
                    task.Estimated_End_Date__c == null &&
                    task.Is_Active__c == true &&
                    task.Development_Start_Date__c != null
                ) {
                    Date startDate = task.Development_Start_Date__c;

                    if (startDate > today) continue;

                    Integer workingDays = 0;
                    Integer totalDays = today.daysBetween(startDate) + 1;

                    for (Integer i = 0; i < totalDays; i++) {
                        Date currentDate = startDate.addDays(i);
                        Integer dayOfWeek = Integer.valueOf(
                            DateTime.newInstance(currentDate, Time.newInstance(0, 0, 0, 0)).format('u')
                        );
                        if (dayOfWeek < 6) { // Monday to Friday
                            workingDays++;
                        }
                    }

                    task.Hours_so_Far_consumed__c = workingDays * 8;
                    recordsToUpdate.add(task);
                }

            } catch (Exception e) {
                System.debug('Error processing task Id: ' + task.Id + ' - ' + e.getMessage());
            }
        }

        if (!recordsToUpdate.isEmpty()) {
            try {
                update recordsToUpdate;
            } catch (Exception e) {
                System.debug('Error during update: ' + e.getMessage());
            }
        }
    } 
    
}