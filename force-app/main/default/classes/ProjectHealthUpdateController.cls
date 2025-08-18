public with sharing class ProjectHealthUpdateController {

    // Wrapper class to hold project health update data
    public class ProjectHealthWrapper {
        @AuraEnabled public Id projectId;
        @AuraEnabled public String projectName;
        @AuraEnabled public List<Date> updateDates;
        @AuraEnabled public List<String> healthStatuses;
    }

    // Method to fetch health data for a specific project
    @AuraEnabled(cacheable=true)
    public static List<Project_Health_Update__c> getProjectHealthData(Id projectId) {
        return [SELECT Update_Date__c, Health_Status__c 
                FROM Project_Health_Update__c 
                WHERE Project__c = :projectId 
                AND CreatedDate = LAST_N_DAYS:30];
    }

    // Method to fetch all project names
    @AuraEnabled(cacheable=true)
    public static List<Project__c> getAllProjectName() {
        return [SELECT Id, Name FROM Project__c];
    }

    // Method to fetch health data for all projects
    @AuraEnabled(cacheable=true)
    public static List<ProjectHealthWrapper> getAllProjectsHealthData() {
        List<Project_Health_Update__c> allData = [
            SELECT Project__c, Project__r.Name, Update_Date__c, Health_Status__c
            FROM Project_Health_Update__c 
            WHERE CreatedDate = LAST_N_DAYS:30
            ORDER BY Project__c, Update_Date__c
        ];

        // Map to group data by projectId
        Map<Id, ProjectHealthWrapper> projectMap = new Map<Id, ProjectHealthWrapper>();

        // Group data by projectId
        for (Project_Health_Update__c record : allData) {
            if (!projectMap.containsKey(record.Project__c)) {
                ProjectHealthWrapper wrapper = new ProjectHealthWrapper();
                wrapper.projectId = record.Project__c;
                wrapper.projectName = record.Project__r.Name;
                wrapper.updateDates = new List<Date>();
                wrapper.healthStatuses = new List<String>();
                projectMap.put(record.Project__c, wrapper);
            }

            ProjectHealthWrapper existing = projectMap.get(record.Project__c);
            existing.updateDates.add(record.Update_Date__c);
            existing.healthStatuses.add(record.Health_Status__c);
        }

        // Return grouped data
        return projectMap.values();
    }
}