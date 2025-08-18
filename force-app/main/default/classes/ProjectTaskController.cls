/**
* @File Name : projectTaskChartController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 17, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 17, 2025 |   | Initial Version
**/

public with sharing class ProjectTaskController {
    @AuraEnabled(cacheable=true)
    public static List<DeveloperTaskCount> getTaskCountsByDeveloper() {
        List<AggregateResult> results = [SELECT Developer_Name__c, COUNT(Id) taskCount FROM Project_Task__c GROUP BY Developer_Name__c]; 
        List<DeveloperTaskCount> counts = new List<DeveloperTaskCount>();

        for (AggregateResult ar : results) {
            counts.add(new DeveloperTaskCount((String)ar.get('Developer_Name__c'),(Integer)ar.get('taskCount')));                
        }
        return counts;
    }

    public class DeveloperTaskCount {
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public Integer count { get; set; }
        public DeveloperTaskCount(String developerName, Integer count) {
            this.developerName = developerName;
            this.count = count;
        }
    }


	@AuraEnabled(cacheable=true)
	public static List<Project_Task__c> getTasksByDeveloper(String developerName) {
		return [
			SELECT Id, Name, Developer_Name__c, Projects__r.Name, Assigned_To1__c, Description__c, Comments__c, Is_Working_on_Other_Tickets__c,
                Current_Task_Status__c, Is_Active__c, Real_Business_hours_needed__c, Requirement_Gathering_Competed__c, Major_Risks_Blockers__c,
                Understanding_completed__c,Task_Name__c, Task_Assignment_Date__c,  CreatedDate,  LastModifiedDate, Modified_Date__c,RAG__c,
                Development_Start_Date__c, Hours_so_Far_consumed__c, Task_Testing_Status__c
                FROM Project_Task__c WHERE Developer_Name__c = :developerName 
                ORDER BY Modified_Date__c DESC
            //AND Current_Task_Status__c = 'Development Completed'	
		];
	}


    //This Funcation call by ShowProjectTaskDetails
    @AuraEnabled(cacheable=true)
	public static List<Project_Task__c> getTodaysTasks() {

		return [SELECT Id, Name, Task_Approver__c, Developer_Name__c, Projects__r.Name,Assigned_To1__c, Description__c, Comments__c, 
                Current_Task_Status__c, Is_Active__c, Real_Business_hours_needed__c, Requirement_Gathering_Competed__c, 
                Understanding_completed__c,Task_Name__c, Task_Assignment_Date__c,  CreatedDate,  LastModifiedDate, Modified_Date__c
                FROM Project_Task__c
                WHERE CreatedDate = TODAY OR Modified_Date__c = TODAY];       
		                                   
	}


    
    @AuraEnabled(cacheable=true)
    public static List<String> getAllDeveloperNames() {

        Set<String> devNames = new Set<String>();

        for (Project_Task__c pt : [SELECT Developer_Name__c, Projects__r.Name FROM Project_Task__c WHERE Developer_Name__c != null]) {
            devNames.add(pt.Developer_Name__c);
        }
        return new List<String>(devNames);
    }


   //This Funcatin call by ProjectTaskDetails
    @AuraEnabled(cacheable=true)
    public static Project_Task__c getTaskById(Id taskId) {
        return [
            SELECT Id, Name, Projects__r.Name, Developer_Name__c, Current_Task_Status__c, RAG__c, Hours_so_Far_consumed__c,
            Estimated_Effort_in_hrs__c, Project_Task_Name__c
            FROM Project_Task__c WHERE Id = :taskId LIMIT 1
         ];       
    }



    // @AuraEnabled(cacheable=true)
    // public static Map<String, Object> getTaskStatusHistory(Id taskId) {
    //     List<Map<String, String>> historyList = new List<Map<String, String>>();
    //     String taskName = '';

    //     Project_Task__c task = [SELECT Project_Task_name__c, Current_Task_Status__c, CreatedDate FROM Project_Task__c WHERE Id = :taskId LIMIT 1];
    //     taskName = task.Project_Task_name__c;

    //     for (Project_Task__History hist : [
    //         SELECT Field, OldValue, NewValue, CreatedDate
    //         FROM Project_Task__History
    //         WHERE ParentId = :taskId AND Field = 'Current_Task_Status__c'
    //         ORDER BY CreatedDate ASC
    //     ]) {
    //         Map<String, String> entry = new Map<String, String>();
    //         entry.put('status', String.valueOf(hist.NewValue));
    //         entry.put('date', String.valueOf(hist.CreatedDate.date()));
    //         historyList.add(entry);
    //     }

    //     if(historyList.isEmpty()){
    //         Map<String, String> entry = new Map<String, String>();
    //         entry.put('status', String.valueOf(task.Current_Task_Status__c));
    //         entry.put('date', String.valueOf(task.CreatedDate.date()));
    //         historyList.add(entry);
    //     }

    //     return new Map<String, Object>{
    //         'taskName' => taskName,
    //         'history' => historyList
    //     };
    // }

    @AuraEnabled(cacheable=true)
public static Map<String, Object> getTaskStatusHistory(Id taskId) {
    List<Map<String, String>> historyList = new List<Map<String, String>>();
    String taskName = '';

    Project_Task__c task = [
        SELECT Project_Task_name__c, Current_Task_Status__c, CreatedDate, Projects__r.Name
        FROM Project_Task__c
        WHERE Id = :taskId
        LIMIT 1
    ];
    taskName = task.Project_Task_name__c;

    // Fetch the history
    List<Project_Task__History> histories = [
        SELECT Field, OldValue, NewValue, CreatedDate
        FROM Project_Task__History
        WHERE ParentId = :taskId AND Field = 'Current_Task_Status__c'
        ORDER BY CreatedDate ASC
    ];

    // 🔹 Add the original status from creation time FIRST
    if (!histories.isEmpty()) {
        Map<String, String> initialEntry = new Map<String, String>();
        initialEntry.put('status', String.valueOf(histories[0].OldValue)); // Use first OldValue
        initialEntry.put('date', String.valueOf(task.CreatedDate.date()));
        historyList.add(initialEntry);
    } else {
        // No history = use current value only
        Map<String, String> onlyEntry = new Map<String, String>();
        onlyEntry.put('status', String.valueOf(task.Current_Task_Status__c));
        onlyEntry.put('date', String.valueOf(task.CreatedDate.date()));
        historyList.add(onlyEntry);
    }

    // 🔹 Now add the rest of the historical changes
    for (Project_Task__History hist : histories) {
        Map<String, String> entry = new Map<String, String>();
        entry.put('status', String.valueOf(hist.NewValue));
        entry.put('date', String.valueOf(hist.CreatedDate.date()));
        historyList.add(entry);
    }

    return new Map<String, Object>{
        'taskName' => taskName,
        'history' => historyList
    };
}

    


    //This Funcation calling By ShowTaskWithRAG
    @AuraEnabled(cacheable=true)
    public static List<Project_Task__c> getTasksByRag(String ragValue) {
        return [
            SELECT Id, Name, RAG__c, Developer_Name__c, Projects__r.Name,Current_Task_Status__c
            FROM Project_Task__c
            WHERE RAG__c =: ragValue AND Current_Task_Status__c != 'Task Completed'];
    }



    //This mathod Call By taskRecordCountByDate
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Project_Task__c>> getTaskRecordsByDate(Date selectedDate) {
        if (selectedDate == null) return new Map<String, List<Project_Task__c>>();

        DateTime startOfDay = DateTime.newInstance(selectedDate, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay = startOfDay.addDays(1);

        List<Project_Task__c> createdTasks = [
            SELECT Id, Name, Projects__r.Name
            FROM Project_Task__c
            WHERE CreatedDate >= :startOfDay AND CreatedDate < :endOfDay
        ];

        List<Project_Task__c> updatedTasks = [
            SELECT Id, Name, Projects__r.Name
            FROM Project_Task__c
            WHERE Modified_Date__c >= :startOfDay AND Modified_Date__c < :endOfDay
            AND Id NOT IN :createdTasks
        ];

        return new Map<String, List<Project_Task__c>>{
            'created' => createdTasks,
            'updated' => updatedTasks
        };
    }



    @AuraEnabled(cacheable=true)
    public static List<Project_Task__c> getTasksByDate(String dateString) {
        Date selectedDate = Date.valueOf(dateString);
        Date startOfDay = selectedDate;
        Date endOfDay = selectedDate.addDays(1);

        return [
            SELECT Id, Name, Developer_Name__c, Projects__r.Name, CreatedDate, Modified_Date__c
            FROM Project_Task__c
            WHERE 
                (CreatedDate >= :startOfDay AND CreatedDate < :endOfDay)
                OR 
                (Modified_Date__c >= :startOfDay AND Modified_Date__c < :endOfDay)
        ];
    }


    //This Matoh Call By showTaskStatusPath
    @AuraEnabled(cacheable=true)
    public static String getCurrentTaskStatus(Id taskId){

        Project_Task__c task = [SELECT Current_Task_Status__c, Projects__r.Name FROM Project_Task__c WHERE Id = :taskId LIMIT 1];
        return task.Current_Task_Status__c;
    }



    // This matoh Call By showDeveloperTaskDowngade
    // @AuraEnabled(cacheable=true)
    // public static List<Map<String, Object>> getDeveloperDowngradeData() {
    //     List<Project_Task__History> history = [
    //         SELECT ParentId, CreatedDate, Field, OldValue, NewValue,
    //             Parent.Developer_Name__c
    //         FROM Project_Task__History
    //         WHERE Field = 'Current_Task_Status__c'
    //         ORDER BY Parent.Developer_Name__c, ParentId, CreatedDate
    //     ];

    //     Map<String, Integer> statusRank = new Map<String, Integer>{
    //         'Task Created' => 1,
    //         'On Hold' => 2,
    //         'Requirement Gathering' => 3,
    //         'Documentation Work' => 4,
    //         'Deployment Issue' => 5,
    //         'Development In Progress' => 6,
    //         'Testing In Progress' => 7,
    //         'Development Completed' => 8,
    //         'UAT In Progress' => 9,
    //         'Unit Testing Completed' => 10,
    //         'UAT Completed' => 11,
    //         'Task Completed' => 12
    //     };

    //     Map<String, Integer> downgradeCountPerDeveloper = new Map<String, Integer>();

    //     Map<Id, Integer> lastStatusPerTask = new Map<Id, Integer>();

    //     for (Project_Task__History h : history) {
    //         String dev = h.Parent.Developer_Name__c;
    //         if (String.isBlank(dev)) continue;

    //         Integer oldVal = statusRank.get(String.valueOf(h.OldValue));
    //         Integer newVal = statusRank.get(String.valueOf(h.NewValue));

    //         if (oldVal != null && newVal != null && newVal < oldVal) {
    //             downgradeCountPerDeveloper.put(dev,
    //                 downgradeCountPerDeveloper.get(dev) != null ?
    //                 downgradeCountPerDeveloper.get(dev) + 1 : 1
    //             );
    //         }
    //     }

    //     List<Map<String, Object>> result = new List<Map<String, Object>>();
    //     for (String devName : downgradeCountPerDeveloper.keySet()) {
    //         result.add(new Map<String, Object>{
    //             'developer' => devName,
    //             'downgradeCount' => downgradeCountPerDeveloper.get(devName)
    //         });
    //     }

    //     return result;
    // }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDeveloperDowngradeData() {
        // Status order mapping
        Map<String, Integer> statusRank = new Map<String, Integer>{
            'Task Created' => 1,
            'On Hold' => 2,
            'Requirement Gathering' => 3,
            'Documentation Work' => 4,
            'Deployment Issue' => 5,
            'Development In Progress' => 6,
            'Testing In Progress' => 7,
            'Development Completed' => 8,
            'Unit Testing Completed' => 9,
            'UAT In Progress' => 10,
            'UAT Completed' => 11,
            'Task Completed' => 12
        };

        // Query task history only for status changes
        List<Project_Task__History> history = [
            SELECT ParentId, CreatedDate, Field, OldValue, NewValue,
                Parent.Name,
                Parent.Projects__r.Name,
                Parent.Developer_Name__c
            FROM Project_Task__History
            WHERE Field = 'Current_Task_Status__c'
            ORDER BY Parent.Developer_Name__c, ParentId, CreatedDate
        ];

        // Store unique task IDs per developer
        Map<String, Set<Id>> downgradedTasksPerDeveloper = new Map<String, Set<Id>>();

        for (Project_Task__History h : history) {
            String dev = h.Parent.Developer_Name__c;
            if (String.isBlank(dev)) continue; // skip if no developer

            Integer oldRank = statusRank.get(String.valueOf(h.OldValue));
            Integer newRank = statusRank.get(String.valueOf(h.NewValue));

            // Count as downgrade only if moving to an earlier rank
            if (oldRank != null && newRank != null && newRank < oldRank) {
                if (!downgradedTasksPerDeveloper.containsKey(dev)) {
                    downgradedTasksPerDeveloper.put(dev, new Set<Id>());
                }
                downgradedTasksPerDeveloper.get(dev).add(h.ParentId);
            }
        }

        // Prepare final output
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (String devName : downgradedTasksPerDeveloper.keySet()) {
            result.add(new Map<String, Object>{
                'developer' => devName,
                'downgradeCount' => downgradedTasksPerDeveloper.get(devName).size()
            });
        }

        return result;
    }



    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDowngradedTasksByDeveloper(String developerName) {
        List<Project_Task__History> history = [
            SELECT ParentId, Parent.Name,  Parent.Projects__r.Name, Field, OldValue, NewValue
            FROM Project_Task__History
            WHERE Field = 'Current_Task_Status__c'
            AND Parent.Developer_Name__c = :developerName
            ORDER BY ParentId, CreatedDate
        ];

        Map<String, Integer> statusRank = new Map<String, Integer>{
            'Task Created' => 1,
            'On Hold' => 2,
            'Requirement Gathering' => 3,
            'Documentation Work' => 4,
            'Deployment Issue' => 5,
            'Development In Progress' => 6,
            'Testing In Progress' => 7,
            'Development Completed' => 8,
            'Unit Testing Completed' => 9,
            'UAT In Progress' => 10,
            'UAT Completed' => 11,
            'Task Completed' => 12
       
        };

        Set<Id> downgradedTaskIds = new Set<Id>();

        for (Project_Task__History h : history) {
            Integer oldVal = statusRank.get(String.valueOf(h.OldValue));
            Integer newVal = statusRank.get(String.valueOf(h.NewValue));

            if (oldVal != null && newVal != null && newVal < oldVal) {
                downgradedTaskIds.add(h.ParentId);
            }
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        if (!downgradedTaskIds.isEmpty()) {
            for (Project_Task__c task : [
                SELECT Name, Projects__r.Name, Id, Developer_Name__c
                FROM Project_Task__c
                WHERE Id IN :downgradedTaskIds
            ]) {
                result.add(new Map<String, Object>{
                    'taskName' => task.Name,
                    'projectName' => task.Projects__r != null ? task.Projects__r.Name : '',
                    'Id' => task.Id,
                    'DeveloperName' => task.Developer_Name__c

                });
            }
        }

        return result;
    }



    //This Matod Call By ShowTaskTestingSatusPath
    @AuraEnabled(cacheable=true)
    public static String getTestingStatus(Id taskId) {
        Project_Task__c task = [SELECT Task_Testing_Status__c, Projects__r.Name FROM Project_Task__c WHERE Id = :taskId LIMIT 1];
        return task.Task_Testing_Status__c;
    }

    //This Mathod call by showDeveloperNDaysTask
   
    @AuraEnabled(cacheable=true)
    public static List<Project_Task__c> getTasksForDeveloperLast7Days(String developerName) {
        Date sevenDaysAgo = Date.today().addDays(-7);

        return [
            SELECT Id, Name, Current_Task_Status__c, Modified_Date__c, Projects__r.Name, CreatedDate
            FROM Project_Task__c
            WHERE Developer_Name__c = :developerName
            AND Modified_Date__c >= :sevenDaysAgo
            ORDER BY Modified_Date__c DESC
        ];
    }

    


}