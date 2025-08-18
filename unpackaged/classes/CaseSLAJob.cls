public without sharing class CaseSLAJob implements Database.Batchable<SObject>, Schedulable {

    // Define threshold in milliseconds (24 hours)
    Long SLA_LIMIT_MS = 24 * 60 * 60 * 1000;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, Subject, CreatedDate, Owner.Name, Accepted_By__c,
                   SLA_Breached__c, Last_Status_Change__c, SLA_Breach_Type__c
            FROM Case
            WHERE SLA_Breached__c = FALSE
            AND RecordTypeId = :Constants.RECORD_TYPE_CASE_CUSTOMER_SERVICE
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Case> caseList = (List<Case>)scope;
        List<Case> casesToUpdate = new List<Case>();
        Set<String> managerEmails = CaseUtility.getManagerEmails();

        Id defaultBHId = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1].Id;
        DateTime now = System.now();

        for (Case c : caseList) {
            Boolean breached = false;
            List<String> breachTypes = new List<String>();

            // SLA 1: Unassigned > 24 Business Hours since CreatedDate
            if (c.Accepted_By__c == null) {
                Long createdDiffMs = BusinessHours.diff(defaultBHId, c.CreatedDate, now);
                if (createdDiffMs != null && createdDiffMs >= SLA_LIMIT_MS) {
                    breachTypes.add('Unassigned > 24 Business Hrs');
                    breached = true;
                }
            }

            // SLA 2: No Status Change > 24 Business Hours since Last_Status_Change__c
            if (c.Last_Status_Change__c != null) {
                Long statusDiffMs = BusinessHours.diff(defaultBHId, c.Last_Status_Change__c, now);
                if (statusDiffMs != null && statusDiffMs >= SLA_LIMIT_MS) {
                    breachTypes.add('No Status Change > 24 Business Hrs');
                    breached = true;
                }
            }

            if (breached) {
                c.SLA_Breached__c = true;
                c.SLA_Breach_Timestamp__c = now;
                c.SLA_Breach_Type__c = String.join(breachTypes, ';');
                casesToUpdate.add(c);
            }
        }
        System.debug('SLA job :- ' + casesToUpdate);
        
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
            CaseUtility.sendSummaryEmail(casesToUpdate, managerEmails, 'SLA');
        }
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CaseSLAJob(), 200);
    }

    public void finish(Database.BatchableContext BC) {}
}