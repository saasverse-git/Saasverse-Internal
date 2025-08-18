trigger assignBuddyFeedback on Buddy_Feedback__c (before insert) {
	
    if(trigger.isBefore){
        if(trigger.isInsert){
            Set<String> developerName = new Set<String>();
            Set<String> ProjectName = new Set<String>();
            for(Buddy_Feedback__c feedbackRec : trigger.new){
            	developerName.add(feedbackRec.Buddy_Name__c);
                developerName.add(feedbackRec.Evaluated_Developer__c);
                ProjectName.add(feedbackRec.Project_Name__c);
            }
            
            Map<String,Id> developerIds = new Map<String,Id>();
            Map<String,Id> projectIds = new Map<String,Id>();
            
            for(Resource__c resourceRec : [Select id,Name from Resource__c where name in : developerName]){
                developerIds.put(resourceRec.name,resourceRec.id);
            }
            
            for(Project__c projectRec : [Select id,Name from Project__c where name in : ProjectName]){
                projectIds.put(projectRec.name,projectRec.id);
            }
            
            for(Buddy_Feedback__c feedbackRec : trigger.new){
                feedbackRec.Buddy_Assigned__c = developerIds.get(feedbackRec.Buddy_Name__c);
                feedbackRec.Developer_Assigned__c = developerIds.get(feedbackRec.Evaluated_Developer__c); 
                feedbackRec.Project_Assigned__c = projectIds.get(feedbackRec.Project_Name__c);
            }
            
        }
    }
}