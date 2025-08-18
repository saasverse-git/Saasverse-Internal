public class VendorTriggerHandler implements ITriggerHandler {

    public void beforeInsert(List<SObject> newList) {
        List<Vendor__c> vendors = (List<Vendor__c>) newList;
        Set<Id> projectIds = new Set<Id>();

        for (Vendor__c v : vendors) {
            if (v.Project__c != null) {
                projectIds.add(v.Project__c);
            }
        }

        Map<Id, Project__c> projectMap = new Map<Id, Project__c>(
            [SELECT Id, Name FROM Project__c WHERE Id IN :projectIds]
        );

        for (Vendor__c v : vendors) {
            if (v.Project__c != null && projectMap.containsKey(v.Project__c)) {
                v.Name = projectMap.get(v.Project__c).Name + ' Vendor';
            }
        }
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Vendor__c> vendors = (List<Vendor__c>) newList;
        Set<Id> projectIds = new Set<Id>();

        for (Vendor__c v : vendors) {
            if (v.Project__c != null) {
                projectIds.add(v.Project__c);
            }
        }

        Map<Id, Project__c> projectMap = new Map<Id, Project__c>(
            [SELECT Id, Name FROM Project__c WHERE Id IN :projectIds]
        );

        for (Vendor__c v : vendors) {
            if (v.Project__c != null && projectMap.containsKey(v.Project__c)) {
                v.Name = projectMap.get(v.Project__c).Name + ' Vendor';
            }
        }
    }

    public void beforeDelete(List<SObject> oldList) {}
    public void afterInsert(List<SObject> newList) {}
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {}
    public void afterDelete(List<SObject> oldList) {}
    public void afterUndelete(List<SObject> newList) {}
}