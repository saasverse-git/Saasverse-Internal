public class ProjectTaskTriggerHandler {
    
    //updated code(25.07.25) -- After Trigger
    public static void calculateEffort(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap, Boolean isDelete) {
        Set<String> developerNames = new Set<String>();
    
        if (newList != null) {
            for (Project_Task__c task : newList) {
                if (task.Developer_Name__c != null) {
                    developerNames.add(task.Developer_Name__c);
                }
            }
        }
    
        if (oldMap != null) {
            for (Project_Task__c oldTask : oldMap.values()) {
                if (oldTask.Developer_Name__c != null) {
                    developerNames.add(oldTask.Developer_Name__c);
                }
            }
        }
    
        if (developerNames.isEmpty()) return;
    
        // Fetch all tasks for these developers
        List<Project_Task__c> allTasks = [
            SELECT Id, Projects__c, Is_Active__c, Current_Task_Status__c, Estimated_Effort_in_hrs__c, Developer_Name__c 
            FROM Project_Task__c 
            WHERE Developer_Name__c IN :developerNames
        ];
    
        // Group tasks by Developer_Name__c
        Map<String, List<Project_Task__c>> tasksByDeveloper = new Map<String, List<Project_Task__c>>();
    
        for (Project_Task__c task : allTasks) {
            if (!tasksByDeveloper.containsKey(task.Developer_Name__c)) {
                tasksByDeveloper.put(task.Developer_Name__c, new List<Project_Task__c>());
            }
            tasksByDeveloper.get(task.Developer_Name__c).add(task);
        }
    
        List<Project_Task__c> tasksToUpdate = new List<Project_Task__c>();       
        Set<String> effortStatuses = new Set<String>{'Development In Progress', 'Development Issue', 'Requirement Gathering','Documentation Work','Testing In Progress','Development Completed'};

        // Recalculate effort per developer
        for (String devName : tasksByDeveloper.keySet()) {
            List<Project_Task__c> tasks = tasksByDeveloper.get(devName);
            List<Project_Task__c> eligibleTasks = new List<Project_Task__c>();
    
            for (Project_Task__c task : tasks) {
                if (task.Is_Active__c && effortStatuses.contains(task.Current_Task_Status__c)) {
                    eligibleTasks.add(task);
                }
            }
    
            Integer count = eligibleTasks.size();
            Decimal newEffort = count > 0 ? (8.0 / count) : 0;
    
            for (Project_Task__c task : tasks) {
                Decimal expectedEffort = (task.Is_Active__c && effortStatuses.contains(task.Current_Task_Status__c))
                    ? newEffort
                    : 0;
    
                if (task.Estimated_Effort_in_hrs__c != expectedEffort) {
                    task.Estimated_Effort_in_hrs__c = expectedEffort;
                    tasksToUpdate.add(task);
                }
            }
        }
    
        if (!tasksToUpdate.isEmpty()) {
            try {
                update tasksToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating Estimated Effort: ' + e.getMessage());
            }
        }
    }
    

  
    //updated code Before Trigger
    public static void calculateHoursSoFarConsumed(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;
    
        // Statuses for calculation
        Set<String> calcStatuses = new Set<String>{'Requirement Gathering',	'Development Completed', 'Testing IN Progress', 'Development In Progress', 'Documentation Work'  };

        // Statuses for skipping calculation
        Set<String> skipStatuses = new Set<String>{ 'Task Completed', 'Unit Testing Completed', 'UAT In Progress', 'UAT Completed', 'On Hold' };
      
        for (Project_Task__c task : newList) {
            try {
                Project_Task__c oldTask = oldMap != null ? oldMap.get(task.Id) : null;
                Boolean isNew = (oldTask == null); 
                //Boolean isModified = false;
    			Boolean isModified = (oldTask != null);
                /*if (!isNew && oldTask != null) {
                    isModified = (
                        task.Development_Start_Date__c     != oldTask.Development_Start_Date__c ||
                        task.Current_Task_Status__c        != oldTask.Current_Task_Status__c ||
                        task.Is_Active__c                  != oldTask.Is_Active__c ||
                        task.Estimated_Effort_in_hrs__c    != oldTask.Estimated_Effort_in_hrs__c
                    );
                }*/
    
                // On creation: always calculate if active
                // On update: calculate only if status is in calcStatuses
                Boolean shouldCalculate = false;
                if (isNew) {
                    shouldCalculate = true;
                } else {
                    if (calcStatuses.contains(task.Current_Task_Status__c)) {
                        shouldCalculate = true;
                    }
                    // If status is in skipStatuses, do NOT calculate or update
                    if (skipStatuses.contains(task.Current_Task_Status__c)) {
                        shouldCalculate = false;
                    }
                }
    
                if (shouldCalculate) {
                    // Calculate working days between start and now
                    Date startDate = task.Development_Start_Date__c;
                    Date endDate = task.LastModifiedDate.date();
    
                    Integer workingDays = 0;
                    Integer totalDays = startDate.daysBetween(endDate) + 1;
    
                    for (Integer i = 0; i < totalDays; i++) {
                        Date currentDate = startDate.addDays(i);
                        Integer dayOfWeek = Integer.valueOf(DateTime.newInstance(currentDate, Time.newInstance(0, 0, 0, 0)).format('u'));
                        // Mon–Fri
                        if (dayOfWeek < 6) { 
                            workingDays++;
                        }
                    }
    
                    Decimal totalHours = workingDays * (task.Estimated_Effort_in_hrs__c != null ? task.Estimated_Effort_in_hrs__c : 0);
                    // Never allow overwriting a nonzero value with 0
                    if (totalHours > 0 || (task.Hours_so_Far_consumed__c == null || task.Hours_so_Far_consumed__c == 0)) {
                        task.Hours_so_Far_consumed__c = totalHours.setScale(2);
                    }
                }
                // If should not calculate, do nothing (do not zero out)
            } catch (Exception e) {
                System.debug('Error calculating consumed hours for task: ' + task.Id + ' - ' + e.getMessage());
            }
        }
    }

    
 // updated (25.07.25)
 	public static void updateIsWorkingOnOtherTickets(Set<Id> taskIds) {
        Set<String> developerNames = new Set<String>();
    
        for (Project_Task__c task : [SELECT Id, Developer_Name__c FROM Project_Task__c WHERE Id IN :taskIds AND Developer_Name__c != null ]) {
        	developerNames.add(task.Developer_Name__c);
        }
    
        if (developerNames.isEmpty()) return;
    
        // Step 2: Fetch all tasks assigned to those developers
        List<Project_Task__c> allTasks = [SELECT Id, Developer_Name__c, Is_Active__c, Is_Working_on_Other_Tickets__c, Current_Task_Status__c
            						     FROM Project_Task__c WHERE Developer_Name__c IN :developerNames ];
      
    
        // Step 3: Group by developer name
        Map<String, List<Project_Task__c>> tasksByDeveloper = new Map<String, List<Project_Task__c>>();
        
        for (Project_Task__c task : allTasks) {
            if (!tasksByDeveloper.containsKey(task.Developer_Name__c)) {
                tasksByDeveloper.put(task.Developer_Name__c, new List<Project_Task__c>());
            }
            tasksByDeveloper.get(task.Developer_Name__c).add(task);
        }
    
        List<Project_Task__c> tasksToUpdate = new List<Project_Task__c>();
    
        Set<String> devStatuses = new Set<String>{'Development In Progress', 'Documentation Work', 'Testing In Progress', 'Requirement Gathering', 'Deployment Issue'};

        Set<String> uatStatuses = new Set<String>{'UAT In Progress', 'Unit Testing Completed', 'UAT Completed'  };
    
        // Step 4: Apply logic per developer
        for (String dev : tasksByDeveloper.keySet()) {
            List<Project_Task__c> taskList = tasksByDeveloper.get(dev);
    
            List<Project_Task__c> activeTasks = new List<Project_Task__c>();
            List<Project_Task__c> devGroup = new List<Project_Task__c>();
            List<Project_Task__c> uatGroup = new List<Project_Task__c>();
    
            for (Project_Task__c pt : taskList) {
                if (pt.Is_Active__c) {
                    activeTasks.add(pt);
                    if (devStatuses.contains(pt.Current_Task_Status__c)) {
                        devGroup.add(pt);
                    } else if (uatStatuses.contains(pt.Current_Task_Status__c)) {
                        uatGroup.add(pt);
                    }
                } else {
                    // Always set inactive tasks to false
                    if (pt.Is_Working_on_Other_Tickets__c != false) {
                        pt.Is_Working_on_Other_Tickets__c = false;
                        tasksToUpdate.add(pt);
                    }
                }
            }
    
            // Scenario 3: All active tasks are UAT group
            if (activeTasks.size() > 0 && devGroup.isEmpty() && uatGroup.size() == activeTasks.size()) {
                for (Project_Task__c pt : uatGroup) {
                    if (pt.Is_Working_on_Other_Tickets__c != false) {
                        pt.Is_Working_on_Other_Tickets__c = false;
                        tasksToUpdate.add(pt);
                    }
                }
            }
            // Scenario 1: Only one dev task, rest UAT
            else if (devGroup.size() == 1 && uatGroup.size() >= 1 && (devGroup.size() + uatGroup.size() == activeTasks.size())) {
                for (Project_Task__c pt : uatGroup) {
                    if (pt.Is_Working_on_Other_Tickets__c != true) {
                        pt.Is_Working_on_Other_Tickets__c = true;
                        tasksToUpdate.add(pt);
                    }
                }
                for (Project_Task__c pt : devGroup) {
                    if (pt.Is_Working_on_Other_Tickets__c != false) {
                        pt.Is_Working_on_Other_Tickets__c = false;
                        tasksToUpdate.add(pt);
                    }
                }
            }
            // Scenario 2: Multiple dev tasks and at least one UAT, or all dev
            else if (devGroup.size() > 1 && (uatGroup.size() >= 1 || devGroup.size() == activeTasks.size())) {
                for (Project_Task__c pt : activeTasks) {
                    if (pt.Is_Working_on_Other_Tickets__c != true) {
                        pt.Is_Working_on_Other_Tickets__c = true;
                        tasksToUpdate.add(pt);
                    }
                }
            }
            // Fallback: Only one active task of any type
            else if (activeTasks.size() == 1) {
                Project_Task__c pt = activeTasks[0];
                if (pt.Is_Working_on_Other_Tickets__c != false) {
                    pt.Is_Working_on_Other_Tickets__c = false;
                    tasksToUpdate.add(pt);
                }
            }
        }
    
        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }

    
    
    
    public static void updateProjectTaskScore(Set<Id> taskIds) {
        // Step 1: Get related Project IDs
        Set<Id> projectIds = new Set<Id>();
        for (Project_Task__c task : [SELECT Id, Projects__c FROM Project_Task__c WHERE Id IN :taskIds ]){
     
            if (task.Projects__c != null) {
                projectIds.add(task.Projects__c);
            }
        }
        if (projectIds.isEmpty()) return;
    
        // Step 2: Query all ACTIVE tasks for those projects
        List<Project_Task__c> allTasks = [SELECT Id, Projects__c, RAG__c, Is_Active__c, Real_Business_hours_needed__c FROM Project_Task__c
                						  WHERE Projects__c IN :projectIds AND Is_Active__c = true  ];
    
        // Step 3: Group tasks by project
        Map<Id, List<Project_Task__c>> tasksByProject = new Map<Id, List<Project_Task__c>>();
        for (Project_Task__c task : allTasks) {
            if (!tasksByProject.containsKey(task.Projects__c)) {
                tasksByProject.put(task.Projects__c, new List<Project_Task__c>());
            }
            tasksByProject.get(task.Projects__c).add(task);
        }
    
        // Step 4: Calculate and update Task Score on Projects
        List<Project__c> projectsToUpdate = new List<Project__c>();
    
        for (Id projectId : tasksByProject.keySet()) {
            List<Project_Task__c> taskList = tasksByProject.get(projectId);
    
            Integer totalScore = 0;
            Integer totalValidTasks = 0;
    
            for (Project_Task__c task : taskList) {
                // Only include tasks with non-null Real Business Hours
                if (task.Real_Business_hours_needed__c != null) {
                    totalValidTasks++;
    
                    if (task.RAG__c == '🟢 Green') {
                        totalScore += 1;
                    } else if (task.RAG__c == '🟠 Orange') {
                        totalScore += 2;
                    } else if (task.RAG__c == '🔴 Red') {
                        totalScore += 3;
                    }
                }
            }
    
            Decimal avgScore = (totalValidTasks > 0) ? 
                Decimal.valueOf(totalScore) / totalValidTasks : null;
    
            projectsToUpdate.add(new Project__c(
                Id = projectId,
                Task_Score__c = (avgScore != null) ? avgScore.setScale(2) : null
            ));
        }

        if (!projectsToUpdate.isEmpty()) {
            update projectsToUpdate;
        }
    }

    
    // updated by Anurag Bhatt
    // this method populates the Task complete Date
        
    public static void updateDevelopmentEndDate(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap) {
        Set<String> allowedStatuses = new Set<String>{'UAT In Progress', 'UAT Completed', 'Task Completed'};
        List<Project_Task__c> tasksToUpdate = new List<Project_Task__c>();

        for (Project_Task__c task : newList) {
            Project_Task__c oldTask = oldMap.get(task.Id);

            // Check if status changed from 'Unit Test Completed' to allowed statuses
            if (
                oldTask.Current_Task_Status__c == 'Unit Testing Completed' &&
                task.Current_Task_Status__c != null &&
                allowedStatuses.contains(task.Current_Task_Status__c)
            ) {
                Project_Task__c updateTask = new Project_Task__c(
                    Id = task.Id,
                    Developer_s_Expected_Completion_Date__c = Date.today() // or Date.today() for just the date
                );
                System.debug('task to be updated is --->'+updateTask);
                tasksToUpdate.add(updateTask);
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }
    
    
    
    // this method Send Email To Approver    
    public static void sendEmailToApprover(List<Project_Task__c> taskList) {
        Set<Id> approverIds = new Set<Id>();
        Set<Id> taskIds = new Set<Id>();
    
        for (Project_Task__c task : taskList) {
            if (task.Task_Approver__c != null) {
                approverIds.add(task.Task_Approver__c);
                taskIds.add(task.Id);
            }
        }
    
        if (approverIds.isEmpty()) return;
    
        // Get approver emails from Resource__c
        Map<Id, Resource__c> resourceMap = new Map<Id, Resource__c>(
            [SELECT Id, Name, Contact_Email__c FROM Resource__c WHERE Id IN :approverIds]
        );
    
        List<Project_Task__c> enrichedTasks = [SELECT Id, Name, Task_Approver__c, Task_Approver__r.Name, Projects__r.Name, Developer_Name__c
            								   FROM Project_Task__c WHERE Id IN :taskIds ];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    
        for (Project_Task__c task : enrichedTasks) {
            if (task.Task_Approver__c != null && resourceMap.containsKey(task.Task_Approver__c)) {
                Resource__c approver = resourceMap.get(task.Task_Approver__c);
    
                if (String.isNotBlank(approver.Contact_Email__c)) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
                    mail.setToAddresses(new List<String>{ approver.Contact_Email__c });
                    mail.setSubject('Task Approval Assigned: ' + task.Developer_Name__c);
                    String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
					String recordUrl = baseUrl + '/' + task.Id;

    
                    mail.setPlainTextBody(
                        'Hi ' + task.Task_Approver__r.Name + ',\n\n' +
                        'You have been assigned as the approver for the following task:\n\n' +
                        'Task No:- ' + task.Name + '\n' +
                        'Project Name:- ' +  task.Projects__r.Name  + '\n' +
                        'Created By:- ' + task.Developer_Name__c + '\n\n' + 
                        'You can view the task here:-\n' + recordUrl + '\n\n' +
                        'Please review this task at your earliest convenience.\n\n' +
                        'Best regards,\n' +
                        'Project Management System'
                    );
    
                    emails.add(mail);
                }
            }
        }
    
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    
    
    //This Mathod Auto Updat Current_Task_Status__c (if Current_Task_Status__c = Development Completed )
    //
    public static void autoUpdateCurrentTaskStatus(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap) {
        for (Project_Task__c task : newList) {             
            if (task.Current_Task_Status__c == 'Development Completed'){
                task.Current_Task_Status__c = 'UAT In Progress';
            }
        }
    }
    
    
    
    //This Mathod Auto Update Task_Testing_Status__c
    public static void autoUpdateTaskTestingStatus(List<Project_Task__c> newList) {
        Set<Id> taskIds = new Set<Id>();
        Map<Id, Boolean> hadRelevantStatus = new Map<Id, Boolean>();
    
        // Step 1: Prepare initial map and track IDs
        for (Project_Task__c task : newList) {
            taskIds.add(task.Id);
    
            // If task is being created with required status
            if (task.Current_Task_Status__c == 'UAT In Progress' || task.Current_Task_Status__c == 'Development Completed') {
                hadRelevantStatus.put(task.Id, true);
            } else {
                hadRelevantStatus.put(task.Id, false);
            }
        }
    
        // Step 2: Query history to check if status was ever UAT In Progress or Development Completed
        for (Project_Task__History h : [
            SELECT ParentId, NewValue, Field
            FROM Project_Task__History
            WHERE Field = 'Current_Task_Status__c' AND ParentId IN :taskIds
        ]) {
            String newStatus = String.valueOf(h.NewValue);
            
            if (newStatus == 'UAT In Progress' || newStatus == 'Development Completed') {
                hadRelevantStatus.put(h.ParentId, true);
            }
        }
    
        // Step 3: Set Task_Testing_Status__c based on current status and history
        for (Project_Task__c task : newList) {
            Boolean isEligible = hadRelevantStatus.get(task.Id);
    
            if (!isEligible) {
                task.Task_Testing_Status__c = null;
                continue;
            }
    
            String status = task.Current_Task_Status__c;
    
            if (status == 'UAT In Progress') {
                task.Task_Testing_Status__c = 'In Progress';
            } else if (
                status == 'Deployment Issue' ||
                status == 'Development In Progress' ||
                status == 'Documentation Work' ||
                status == 'Requirement Gathering' ||
                status == 'Testing In Progress'
            ) {
                task.Task_Testing_Status__c = 'Fail';
            } else if (
                status == 'Unit Testing Completed' ||
                status == 'UAT Completed' ||
                status == 'Task Completed'
            ) {
                task.Task_Testing_Status__c = 'Pass';
            } else {
                task.Task_Testing_Status__c = null;
            }
        }
    }

   
    // This Math Calculate Testing Hrs So Far Consumed
    public static void calculateTestingHoursSoFarConsumed2(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap) {
        Set<Id> taskIds = new Set<Id>();
        for (Project_Task__c task : newList) {
            taskIds.add(task.Id);
        }
        Map<Id, List<Project_Task__History>> taskHistoryMap = new Map<Id, List<Project_Task__History>>();
        
        for (Project_Task__History h : [SELECT ParentId, Field, OldValue, NewValue, CreatedDate FROM Project_Task__History
            							WHERE Field = 'Current_Task_Status__c' AND ParentId IN :taskIds ORDER BY CreatedDate ASC ]) {
                                            
            if (!taskHistoryMap.containsKey(h.ParentId)) {
                taskHistoryMap.put(h.ParentId, new List<Project_Task__History>());
            }
            taskHistoryMap.get(h.ParentId).add(h);
        }

        for (Project_Task__c task : newList) {
            List<Project_Task__History> history = taskHistoryMap.get(task.Id);
            
            if (history == null || history.isEmpty()) continue;

            Date startDate;
            Date endDate;

            for (Project_Task__History h : history) {
                if (String.valueOf(h.NewValue) == 'Development Completed' ||  String.valueOf(h.NewValue) == 'UAT In Progress'){
               
                  startDate =  Date.newInstance(h.CreatedDate.year(), h.CreatedDate.month(), h.CreatedDate.day()); //task.Testing_Date__c;
                    //startDate = task.Testing_Date__c;
                }

                if ( startDate != null &&(String.valueOf(h.NewValue) == 'Task Completed')) {  
                    endDate = Date.newInstance(h.CreatedDate.year(), h.CreatedDate.month(), h.CreatedDate.day());
                    break;
                }
            }

            if (startDate != null) {
                Date finalEnd = endDate != null ? endDate : Date.today();
                Integer businessDays = 0;

                for (Date d = startDate; d <= finalEnd; d = d.addDays(1)) {
                    Integer dow = Integer.valueOf(DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('u'));
                    if (dow >= 1 && dow <= 5) businessDays++;
                }

                Decimal hours = businessDays * 8;
                task.Testing_Hours_So_Far_Consumed__c = hours;
            }
        }
    }
    
    
    public static void calculateTestingHoursSoFarConsumed(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap) {
        Date startDate;
        Date endDate;
        
        for(Project_Task__c pt : newList){
            if (pt.Current_Task_Status__c == 'Development Completed' ||  pt.Current_Task_Status__c == 'UAT In Progress' ||
                pt.Current_Task_Status__c == 'Unit Testing Completed' || pt.Current_Task_Status__c == 'UAT Completed'){
                    
                if(pt.CreatedDate != null){
                    startDate =  Date.newInstance(pt.CreatedDate.year(), pt.CreatedDate.month(), pt.CreatedDate.day()); //task.Testing_Date__c;
                    //startDate = task.Testing_Date__c;
                } else {
                    startDate = Date.today();
                }
            }
            
            if (startDate != null && pt.Current_Task_Status__c == 'Task Completed' || pt.Current_Task_Status__c == 'On Hold') {  
                if(pt.CreatedDate != null){
                	endDate = Date.newInstance(pt.CreatedDate.year(), pt.CreatedDate.month(), pt.CreatedDate.day());
                }
            }
            
            if(startDate != null){
                Date finalEnd = endDate != null ? endDate : Date.today();
                Integer businessDays = 0;

                for (Date d = startDate; d <= finalEnd; d = d.addDays(1)) {
                    Integer dow = Integer.valueOf(DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('u'));
                    if (dow >= 1 && dow <= 5) businessDays++;
                }
                Decimal hours = businessDays * 8;
                pt.Testing_Hours_So_Far_Consumed__c = hours;
            }
        }
    }
    
    
    //this Mathod sned email when task Status is Downgraded
    public static void checkForStatusDowngrade(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap) {
         if (newList == null || oldMap == null) return;
    
            Map<String, Integer> statusOrder = new Map<String, Integer>{
                'Task Created' => 1,
                'On Hold' => 2,
                'Requirement Gathering' => 3,
                'Documentation Work' => 4,
                'Deployment Issue' => 5,
                'Development In Progress' => 6,
                'Testing In Progress' => 7,
                'Development Completed' => 8,
                'UAT In Progress' => 9,
                'Unit Testing Completed' => 10,
                'UAT Completed' => 11,
                'Task Completed' => 12
            };
    
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (Project_Task__c task : newList) {
                Project_Task__c oldTask = oldMap.get(task.Id);
                if (oldTask == null) continue;
    
                String oldStatus = oldTask.Current_Task_Status__c;
                String newStatus = task.Current_Task_Status__c;
    
                if (!statusOrder.containsKey(oldStatus) || !statusOrder.containsKey(newStatus)) continue;
    
                Integer oldIndex = statusOrder.get(oldStatus);
                Integer newIndex = statusOrder.get(newStatus);
    
                if (newIndex < oldIndex ) {
                    // Downgrade from above "Development Completed" to below
                    sendDowngradeEmail(task, oldStatus, newStatus);
                }
            }    
        }
    
        public static void sendDowngradeEmail(Project_Task__c task, String oldStatus, String newStatus) {
            
            String managerEmail = 'abhishek.verma@saasverse.in';       
            String body = ''
                + 'Hi,\n\n'
                + 'This is to inform you that the status of the following task has been downgraded :\n\n'
                + '• Task No.       : ' + task.Name + '\n'
                //+ '• Project         : ' + (task.Projects__r != null ? task.Projects__r.Name : 'N/A') + '\n'
                + '• Developer Name  : ' + task.Developer_Name__c + '\n'
                + '• Previous Status : ' + oldStatus + '\n'
                + '• Current Status  : ' + newStatus + '\n'
                + '• Last Updated On : ' + String.valueOf(task.LastModifiedDate) + '\n\n'
                + 'This may indicate a potential issue or rollback. Please review the task details and coordinate with the concerned team.\n\n'
                + 'Regards,\n'
                + 'Salesforce Task Monitoring System';
        
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { managerEmail });
            email.setSubject(' Task Status Downgraded: ' + task.Name);
            email.setPlainTextBody(body);
        
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
      }

   
}












///////////old working mathod

/*public static void calculateHoursSoFarConsumed(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap) {
        
        if (newList == null || newList.isEmpty() || oldMap == null || oldMap.isEmpty() ) return;
    
        for (Project_Task__c task : newList) {
            try {
                // Inactive or Completed task → Set hours to 0
                //if (task.Is_Active__c == false || task.Current_Task_Status__c == 'Task Completed' ||task.Current_Task_Status__c == 'On Hold' ||
                   // task.Development_Start_Date__c == null || task.Estimated_Effort_in_hrs__c == null ) {
                  //task.Hours_so_Far_consumed__c = 0;
                  //  continue;
                //} 
              
                // Else, calculate based on working days
                Date startDate = task.Development_Start_Date__c;
                Date endDate = task.LastModifiedDate.date();
    
                Integer workingDays = 0;
                Integer totalDays = startDate.daysBetween(endDate) + 1;
    
                for (Integer i = 0; i < totalDays; i++) {
                    Date currentDate = startDate.addDays(i);
                    Integer dayOfWeek = Integer.valueOf(
                        DateTime.newInstance(currentDate, Time.newInstance(0, 0, 0, 0)).format('u')
                    );
                    if (dayOfWeek < 6) {
                        workingDays++;
                    }
                }
    
                Decimal totalHours = workingDays * task.Estimated_Effort_in_hrs__c;
                task.Hours_so_Far_consumed__c += totalHours.setScale(2);
    
            } catch (Exception e) {
                System.debug('Error calculating consumed hours for task: ' + task.Id + ' - ' + e.getMessage());
            }
        }
	}*/  


/* public static void updateProjectTaskScore(Set<Id> taskIds) {
    // Step 1: Get related Project IDs
        Set<Id> projectIds = new Set<Id>();
        for (Project_Task__c task : [SELECT Id, Projects__c FROM Project_Task__c WHERE Id IN :taskIds]) {
            if (task.Projects__c != null) {
                projectIds.add(task.Projects__c);
            }
        }
        if (projectIds.isEmpty()) return;
    
        // Step 2: Query all ACTIVE tasks with RAG for these projects
        List<Project_Task__c> allTasks = [
            SELECT Id, Projects__c, RAG__c, Is_Active__c,Real_Business_hours_needed__c 
            FROM Project_Task__c
            WHERE Projects__c IN :projectIds AND Is_Active__c = true AND Real_Business_hours_needed__c  != NULL
        ];
    
        // Step 3: Group tasks by project
        Map<Id, List<Project_Task__c>> tasksByProject = new Map<Id, List<Project_Task__c>>();
        for (Project_Task__c task : allTasks) {
            if (!tasksByProject.containsKey(task.Projects__c)) {
                tasksByProject.put(task.Projects__c, new List<Project_Task__c>());
            }
            tasksByProject.get(task.Projects__c).add(task);
        }
    
        // Step 4: Calculate average score and update Projects
        List<Project__c> projectsToUpdate = new List<Project__c>();
    
        for (Id projectId : tasksByProject.keySet()) {
            List<Project_Task__c> taskList = tasksByProject.get(projectId);
    
            Integer totalScore = 0;
            Integer totalActiveTasks = taskList.size();
    
            for (Project_Task__c task : taskList) {
                if (task.RAG__c == '🟢 Green') {
                    totalScore += 1;
                } else if (task.RAG__c == '🟠 Orange') {
                    totalScore += 2;
                } else if (task.RAG__c == '🔴 Red') {
                    totalScore += 3;
                }
            }
    
            Decimal averageScore = totalActiveTasks > 0 ? Decimal.valueOf(totalScore) / totalActiveTasks : 0;
    
            projectsToUpdate.add(new Project__c(
                Id = projectId,
                Task_Score__c = averageScore.setScale(2)
            ));
        }
    
        if (!projectsToUpdate.isEmpty()) {
            update projectsToUpdate;
        }
	}*/



/*public static void updateIsWorkingOnOtherTickets(List<Project_Task__c> newList) {
        System.debug('newList RESULT::' + newList);
        
        Map<String,List<Project_Task__c>> mapOfProjectTask = new Map<String,List<Project_Task__c>>();
        for (Project_Task__c pt : newList) {
            if (!mapOfProjectTask.containsKey(pt.Project_Task_Name__c)) {
                mapOfProjectTask.put(pt.Project_Task_Name__c, new List<Project_Task__c>());
            }
            mapOfProjectTask.get(pt.Project_Task_Name__c).add(pt);
        }
        for(Project_Task__c pt : newList){
            List<Project_Task__c> ptList = mapOfProjectTask.get(pt.Project_Task_Name__c);
            if(ptList.size() > 1){
                if(pt.Is_Working_on_Other_Tickets__c != pt.Is_Active__c){
                pt.Is_Working_on_Other_Tickets__c = pt.Is_Active__c;
            	}
            }
        }
    }*/


/*public static void calculateEffort(List<Project_Task__c> newList, Map<Id, Project_Task__c> oldMap, Boolean isDelete) {
        Set<Id> projectIds = new Set<Id>();

        // Collect project IDs from Trigger.new and Trigger.old
        if (newList != null) {
            for (Project_Task__c task : newList) {
                if (task.Projects__c != null) {
                    projectIds.add(task.Projects__c);
                }
            }
        }

        if (oldMap != null) {
            for (Project_Task__c oldTask : oldMap.values()) {
                if (oldTask.Projects__c != null) {
                    projectIds.add(oldTask.Projects__c);
                }
            }
        }

        if (projectIds.isEmpty()) return;

        // Fetch all tasks under affected projects
        List<Project_Task__c> allTasks = [SELECT Id, Projects__c, Is_Active__c, Current_Task_Status__c, Estimated_Effort_in_hrs__c
            						      FROM Project_Task__c WHERE Projects__c IN :projectIds ];
    
        // Group tasks by project
        Map<Id, List<Project_Task__c>> projectToTasks = new Map<Id, List<Project_Task__c>>();
        
        for (Project_Task__c task : allTasks) {
            if (!projectToTasks.containsKey(task.Projects__c)) {
                projectToTasks.put(task.Projects__c, new List<Project_Task__c>());
            }
            projectToTasks.get(task.Projects__c).add(task);
        }

        List<Project_Task__c> tasksToUpdate = new List<Project_Task__c>();

        // Recalculate efforts for each project
        for (Id projectId : projectToTasks.keySet()) {
            List<Project_Task__c> tasks = projectToTasks.get(projectId);
            List<Project_Task__c> activeTasks = new List<Project_Task__c>();
            //List<String> taskStatusList = new List<String>{'Requirement Gathering','Documentation Work','Deployment Issue','Development In Progress','Testing In Progress'};


            // Step 1: Count active & non-completed tasks
            for (Project_Task__c task : tasks) {
                if (task.Is_Active__c && (task.Current_Task_Status__c != 'Task completed'))
               {
                                         
                    activeTasks.add(task);
                }
            }

            Integer activeCount = activeTasks.size();
            Decimal newEffort = activeCount > 0 ? (8.0 / activeCount) : 0;

            // Step 2: Assign efforts
            for (Project_Task__c task : tasks) {
                Decimal expectedEffort = (task.Is_Active__c && task.Current_Task_Status__c != 'Task Completed')
                    ? newEffort
                    : 0;

                if (task.Estimated_Effort_in_hrs__c != expectedEffort) {
                    task.Estimated_Effort_in_hrs__c = expectedEffort;
                    tasksToUpdate.add(task);
                }
                
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            try {
                update tasksToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating Estimated Effort: ' + e.getMessage());
            }
        }
    }*/


	/*public static void updateIsWorkingOnOtherTickets(Set<Id> taskIds) {
        Set<Id> projectIds = new Set<Id>();
        
        for(Project_Task__c task : [SELECT Id, Projects__c  FROM Project_Task__c WHERE Id IN :taskIds]){
            projectIds.add(task.Projects__c );
        }
 
        if(projectIds.isEmpty()) return;

        List<Project_Task__c> allTasks = [SELECT Id, Projects__c , Is_Active__c, Is_Working_on_Other_Tickets__c FROM Project_Task__c 
             							  WHERE Projects__c  IN :projectIds ];
            
        
        //Group tasks by project
        Map<Id, List<Project_Task__c>> tasksByProject = new Map<Id, List<Project_Task__c>>();
        
        for(Project_Task__c pt : allTasks){
            if (!tasksByProject.containsKey(pt.Projects__c)) {
    			tasksByProject.put(pt.Projects__c, new List<Project_Task__c>());
			}
			tasksByProject.get(pt.Projects__c).add(pt); 
        }
 
        List<Project_Task__c> tasksToUpdate = new List<Project_Task__c>();
 
        //  Apply logic per project
        for(Id projId : tasksByProject.keySet()){
            List<Project_Task__c> taskList = tasksByProject.get(projId);
            List<Project_Task__c> activeTasks = new List<Project_Task__c>();
 
            for(Project_Task__c pt : taskList){
                if(pt.Is_Active__c){
                    activeTasks.add(pt);
                }
            }
 
            Boolean moreThanOneActive = activeTasks.size() > 1;
 
            for(Project_Task__c pt : taskList){
                Boolean shouldBeTrue = pt.Is_Active__c && moreThanOneActive;
                if(pt.Is_Working_on_Other_Tickets__c != shouldBeTrue){
                    pt.Is_Working_on_Other_Tickets__c = shouldBeTrue;
                    tasksToUpdate.add(pt);
                }
            }
        }
 
        if(!tasksToUpdate.isEmpty()){
            update tasksToUpdate;
        }
    }*/