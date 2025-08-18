/**
* @File Name : resourceController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 11, 2025 |   | Initial Version
**/

 public with sharing class resourceController {
	
	@AuraEnabled(cacheable=true)
     public static List<Resource__c> getAvailableResource(){
        return [SELECT Id, Name FROM Resource__c WHERE Id NOT IN (SELECT Resource__c FROM Project__c)];

    }
}