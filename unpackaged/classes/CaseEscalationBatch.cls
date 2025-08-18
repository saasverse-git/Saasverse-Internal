public without sharing class CaseEscalationBatch implements Database.Batchable<SObject>, Schedulable {

    Integer UNACCEPTED_MINUTES = 60;
    Integer STATUS_IDLE_HOURS = 4;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, Subject, Description, CreatedDate, Status, OwnerId, 
                   Rejected_By__c, Last_Status_Change__c, IsEscalated, Assigned_Queue_Id__c, Escalation_Reason__c,
                   Escalation_Timestamp__c, Accepted_By__c
            FROM Case
            WHERE IsEscalated = FALSE
            AND RecordTypeId = :Constants.RECORD_TYPE_CASE_CUSTOMER_SERVICE
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Case> caseList = (List<Case>)scope;
        List<Case> casesToUpdate = new List<Case>();
        Set<String> managerEmails = CaseUtility.getManagerEmails();

        // Load default Business Hours
        Id bhId = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1].Id;
        DateTime now = System.now();

        // Get all queue sizes
        Set<Id> queueIds = new Set<Id>();
        for (Case c : caseList) {
            if (c.Assigned_Queue_Id__c != null) {
                queueIds.add(c.Assigned_Queue_Id__c);
            }
        }

        Map<Id, Integer> queueMemberCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT GroupId, COUNT(Id) memberCount
            FROM GroupMember
            WHERE GroupId IN :queueIds
            GROUP BY GroupId
        ]) {
            queueMemberCounts.put((Id)ar.get('GroupId'), (Integer)ar.get('memberCount'));
        }

        // ESCALATION RULES BASED ON BUSINESS HOURS
        for (Case c : caseList) {
            Boolean shouldEscalate = false;
            List<String> escalationReasons = new List<String>();

            // Rule 1: Not accepted within 30 business minutes
            if (c.Accepted_By__c == null) {
                Long createdDiffMs = BusinessHours.diff(bhId, c.CreatedDate, now);
                if (createdDiffMs != null) {
                    Decimal businessMins = Decimal.valueOf(createdDiffMs) / (1000 * 60);
                    if (businessMins >= UNACCEPTED_MINUTES) {
                        shouldEscalate = true;
                        escalationReasons.add('Not Accepted in 60 Business Minutes');
                    }
                }

                // Rule 2: All agents in queue rejected
                if (c.Rejected_By__c != null) {
                    List<String> rejectedUsers = c.Rejected_By__c.split(';');
                    Integer queueUserCount = queueMemberCounts.get(c.Assigned_Queue_Id__c);
                    if (queueUserCount != null && rejectedUsers.size() >= queueUserCount) {
                        shouldEscalate = true;
                        escalationReasons.add('All Agents Rejected');
                    }
                }
            }

            // Rule 3: No status change in 4 business hours
            if (c.Last_Status_Change__c != null) {
                Long idleDiffMs = BusinessHours.diff(bhId, c.Last_Status_Change__c, now);
                if (idleDiffMs != null) {
                    Decimal idleHours = Decimal.valueOf(idleDiffMs) / (1000 * 60 * 60);
                    if (idleHours >= STATUS_IDLE_HOURS) {
                        shouldEscalate = true;
                        escalationReasons.add('No Status Change in 4 Business Hours');
                    }
                }
            }

            if (shouldEscalate) {
                c.IsEscalated = true;
                c.Escalation_Timestamp__c = now;
                c.Escalation_Reason__c = String.join(escalationReasons, ';');
                casesToUpdate.add(c);
            }
        }
        

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
            CaseUtility.sendSummaryEmail(casesToUpdate, managerEmails, 'Escalation');
        }
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CaseEscalationBatch(), 200);
    }

    public void finish(Database.BatchableContext BC) {}
}