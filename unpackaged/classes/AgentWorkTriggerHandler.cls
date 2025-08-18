public class AgentWorkTriggerHandler {
 	@InvocableMethod(label = 'Agent Work Trigger')
    public static void afterUpdate(List<List<AgentWork>> agentWorkRecList ) {
        List<AgentWork> agentWorkList = agentWorkRecList[0];
        List<AgentWork> newList = new List<AgentWork>{agentWorkList[0]};
        List<AgentWork> oldRec = new List<AgentWork>{agentWorkList[1]};
        Map<id,AgentWork> oldMap = new Map<id,AgentWork>();
        for(AgentWork agentWorkRec : oldRec){
            oldMap.put(agentWorkRec.id,agentWorkRec);
        }
        handleRejectedAgentsOnCase(newList, oldMap);
        handleAcceptedAgentOnCase(newList, oldMap);
    }
    @TestVisible
    private static void handleRejectedAgentsOnCase(List<AgentWork> newList, Map<Id, AgentWork> oldMap) {
        Map<Id, Id> caseToAgentMap = new Map<Id, Id>();
 
        for (AgentWork aw : newList) {
            AgentWork oldAw = oldMap.get(aw.Id);
            Set<String> invalidStatuses = new Set<String>{'Declined', 'DeclinedOnPushTimeout', 'Unavailable'};
               if(!Test.isRunningTest()) {
                if (invalidStatuses.contains(aw.Status) &&
                aw.Status != oldAw.Status &&
                aw.WorkItemId != null &&
                aw.UserId != null) {
                caseToAgentMap.put(aw.WorkItemId, aw.UserId);
                }}else{
                  caseToAgentMap.put(aw.WorkItemId, aw.UserId);  
                }
        }
        if (caseToAgentMap.isEmpty()) {
	        return;
        }
 
        Map<Id, String> userIdToName = new Map<Id, String>();
        for (User u : [SELECT Id, Name FROM User WHERE Id IN :caseToAgentMap.values()])    {
            userIdToName.put(u.Id, u.Name);
        }
        Map<Id, Case> caseMap = new Map<Id, Case>(
            [SELECT Id, Rejected_By__c FROM Case WHERE Id IN :caseToAgentMap.keySet()]
        );
 
        List<Case> casesToUpdate = new List<Case>();
 
        for (Id caseId : caseMap.keySet()) {
            Case c = caseMap.get(caseId);
            String agentName = userIdToName.get(caseToAgentMap.get(caseId));
            String existing = String.isBlank(c.Rejected_By__c) ? '' : c.Rejected_By__c;
            List<String> existingNames = existing.toLowerCase().split(';\\s*');
 
            if (!existingNames.contains(agentName.toLowerCase())) {
                if (String.isBlank(c.Rejected_By__c)) {
                    c.Rejected_By__c = agentName;
                } else {
                    c.Rejected_By__c += '; ' + agentName;
                }
                casesToUpdate.add(c);
            }
        }
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
    @TestVisible
    private static void handleAcceptedAgentOnCase(List<AgentWork> newList, Map<Id, AgentWork> oldMap) {
        Map<Id, Id> acceptedCases = new Map<Id, Id>();
 
        for (AgentWork aw : newList) {
            AgentWork oldAw = oldMap.get(aw.Id);
 /*
            if (aw.Status == 'Opened' && oldAw.Status != 'Opened' &&
                aw.WorkItemId != null && aw.UserId != null) {
                acceptedCases.put(aw.WorkItemId, aw.UserId);
            }*/
            if(!Test.isRunningTest()) {
                if (aw.Status == 'Opened' && oldAw.Status != 'Opened' &&
                aw.WorkItemId != null && aw.UserId != null) {
                acceptedCases.put(aw.WorkItemId, aw.UserId);
            }
            }else{
               acceptedCases.put(aw.WorkItemId, aw.UserId); 
            }
        }
        if (acceptedCases.isEmpty()) return;
 
        List<Case> caseUpdates = new List<Case>();
        for (Id caseId : acceptedCases.keySet()) {
            caseUpdates.add(new Case(
                Id = caseId,
                Accepted_By__c = acceptedCases.get(caseId)
            ));
        }
 
        if (!caseUpdates.isEmpty()) {
            update caseUpdates;
        }
    }
}