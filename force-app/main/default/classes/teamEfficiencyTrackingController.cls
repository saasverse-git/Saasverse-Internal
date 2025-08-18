/**
* @File Name : teamEfficiencyTrackingController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 14, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 14, 2025 |   | Initial Version
**/

public  with sharing class teamEfficiencyTrackingController {
	
	@AuraEnabled(cacheable=true)
	public static List<Resource__c> getResourceEfficiencyData(){
		return [ Select Id, Name, Efficiency__c From Resource__c Where Experience__c != NUll];
	}
	
}