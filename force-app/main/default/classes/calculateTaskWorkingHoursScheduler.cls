global class calculateTaskWorkingHoursScheduler implements Schedulable  {
    
    global void execute(SchedulableContext sc) {
        List<Project_Task__c> tasksToUpdate = [
            SELECT Id, Development_Start_Date__c, Hours_so_Far_consumed__c 
            FROM Project_Task__c 
            WHERE Development_Start_Date__c != null
        ];

        List<Project_Task__c> updatedTasks = new List<Project_Task__c>();

        for (Project_Task__c task : tasksToUpdate) {
            Integer workingDays = 0;
            Date startDate = task.Development_Start_Date__c;
            Date endDate = Date.today();
            Integer dayOfWeek = 0;

            if (startDate <= endDate) {
                Date currentDate = startDate;

                while (currentDate <= endDate) {
                     //currentDate.dayOfWeek; // no parentheses

                    // Skip Sundays (1) and Saturdays (7)
                    if (dayOfWeek != 1 && dayOfWeek != 7) {
                        workingDays++;
                    }

                    currentDate = currentDate.addDays(1);
                }

                task.Hours_so_Far_consumed__c = workingDays * 8;
                updatedTasks.add(task);
            }
        }

        if (!updatedTasks.isEmpty()) {
            update updatedTasks;
        }
    }
}