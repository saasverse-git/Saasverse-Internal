/**
* @File Name : ProjectTaskUploaderController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : May 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 23, 2025 |   | Initial Version
**/

public with sharing class ProjectTaskUploaderController {

    @AuraEnabled
    public static Integer parseCSVandInsertTasks(Id contentVersionId) {
		System.debug('contentVersionId---->'+contentVersionId);
        ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
        Blob csvBlob = cv.VersionData;

        List<Project_Task__c> tasks = ProjectTaskImporter.parseCSV(csvBlob);
        return tasks.size();
    }
}