/**
* @File Name : OrderHistoryController.cls
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

public class OrderHistoryController{

@AuraEnabled(cacheable=true)
public Static List<Order> getUserOrders(){

return [
        SELECT Id, OrderNumber, EffectiveDate, Status, TotalAmount
        FROM Order
        ORDER BY EffectiveDate DESC
    ];
}
}