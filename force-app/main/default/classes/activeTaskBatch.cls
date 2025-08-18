global class activeTaskBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name, Current_Task_Status__c, Estimated_End_Date__c,
                   Is_Active__c, Development_Start_Date__c, Hours_so_Far_consumed__c
            FROM Project_Task__c 
            WHERE Current_Task_Status__c != 'Completed'
              AND Estimated_End_Date__c = null
              AND Is_Active__c = true
              AND Development_Start_Date__c != null
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Project_Task__c> taskRecords) {
        /*Date today = Date.today();

        for (Project_Task__c task : taskRecords) {
           try {
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
                update task; 

            } catch (Exception e) {
                System.debug(' Error updating task Id: ' + task.Id + ' - ' + e.getMessage());
            }
        }*/
    }

    global void finish(Database.BatchableContext BC) {
        System.debug(' Batch job completed.');
    }
}