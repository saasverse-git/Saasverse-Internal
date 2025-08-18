trigger projectHealthAlert on Project_Health_Update__c (before insert, before update, before delete,
    after insert, after update, after delete, after undelete) {
    
     if(Trigger.isAfter && Trigger.isInsert){
        
        Set<Id> projectIds = new Set<Id>();
        for (Project_Health_Update__c update1 : Trigger.new) {
            if (update1.Project__c != null) {
                projectIds.add(update1.Project__c);
            }
        } 
        
        if (!projectIds.isEmpty()) {
            ProjectHealthAlertHelper.processHealthAlerts(projectIds);
        }
    }

}