public class ProjectTriggerHandler {
    public static void handleProjectResourceUpdate(List<Project__c> newList, Map<Id, Project__c> oldMap) {
       
        Set<Id> resourceIdsToRecount = new Set<Id>();

        for (Project__c newProj : newList) {
            Project__c oldProj = oldMap != null ? oldMap.get(newProj.Id) : null;

            // Add new resource to recount
            if (newProj.Resource__c != null) {
                resourceIdsToRecount.add(newProj.Resource__c);
            }

            // If resource changed, also add the old resource
            if (oldProj != null && oldProj.Resource__c != null && oldProj.Resource__c != newProj.Resource__c) {
                resourceIdsToRecount.add(oldProj.Resource__c);
            }
        }

        if (resourceIdsToRecount.isEmpty()) return;

        // Step 1: Count how many projects are assigned to each resource
        Map<Id, Integer> projectCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Resource__c, COUNT(Id) total
            FROM Project__c
            WHERE Resource__c IN :resourceIdsToRecount
            GROUP BY Resource__c
        ]) {
            Id resId = (Id) ar.get('Resource__c');
            Integer count = (Integer) ar.get('total');
            projectCountMap.put(resId, count);
        }

        // Step 2: Update resource records accordingly
        List<Resource__c> updates = new List<Resource__c>();
        for (Id resId : resourceIdsToRecount) {
            Integer count = projectCountMap.containsKey(resId) ? projectCountMap.get(resId) : 0;

            Resource__c res = new Resource__c(
                Id = resId,
                Totel_Project_Assigned__c = count,
                Is_Available_for_Assignment__c = (count == 0) // ✅ true if no projects
            );
            updates.add(res);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }




}