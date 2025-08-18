/**
* @File Name : projectStatusChartController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 22, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 22, 2025 |   | Initial Version
**/

public class projectStatusChartController {
	
	@AuraEnabled(cacheable=true)
	public static List<Project__c> getAllProjectsDetails(){

		return [select Id, name, status__c From Project__c  Order By Name Asc];
	}
}