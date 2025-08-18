public without sharing class CaseUtility {

    public static boolean isValidKeywordFound(List<String> keywords, String emailContent) {

        Boolean matchFound = false;
        for (String keyword : keywords) {
            if (emailContent.containsIgnoreCase(keyword)) {
                return true;
            }
        }
        return false;
    }

    public static List<Keyword_Config__mdt> getKeywordConfigMdtBySupportEmail(String supportAddress) {
        return [SELECT Support_Email__c, Keyword__c, Routing_Queue_Name__c,
                       Case_Record_Type__c, Case_Origin__c, Case_Priority__c 
                FROM Keyword_Config__mdt
                WHERE Support_Email__c = :supportAddress];
    }

    public static void insertLog(String cause, String message, String execContext) {
        try {
            BV2__Log__c log = new BV2__Log__c();
            log.BV2__Exception_Cause__c = cause;
            log.BV2__Exception_Message__c = message;
            log.BV2__Execution_Context__c = execContext;
            insert log;
        } catch (Exception e) {
            System.debug('Log Insertion Failed: ' + e.getMessage());
        }
    }

    public static void sendSummaryEmail(List<Case> caseList, Set<String> recipientEmails, String reportType) {
        String orgBaseUrl = Url.getOrgDomainUrl().toExternalForm();
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        String subject = '';
        String body = '';
        String fileName = '';
        String csvData = '';

        if (reportType == 'Escalation') {
            subject = 'Escalated Case Summary Report';
            body = 'Attached is the Escalation report for today.\n\nPlease review the cases that met escalation conditions.';
            fileName = 'Escalation_Report.csv';
            csvData = 'Case Number,Subject,Description,Created Date,Rejected By,Escalation Reason,Escalation Time,Case Link\n';

            for (Case c : caseList) {
                csvData += '"' + c.CaseNumber + '","' + c.Subject + '","' + c.Description + '","' +
                        c.CreatedDate + '","' + c.Rejected_By__c + '","' + c.Escalation_Reason__c + '","' + c.Escalation_Timestamp__c + '","' +
                        orgBaseUrl + '/lightning/r/Case/' + c.Id + '/view"\n';
            }
        }
        else if (reportType == 'SLA') {
            subject = 'SLA Breach Case Summary Report';
            body = 'Attached is the SLA Breach report for today.\n\nPlease review the cases that violated SLA conditions.';
            fileName = 'SLA_Report.csv';
            csvData = 'Case Number,Subject,Created Date,Last Status Update,Breach Type,Owner,Case Link\n';

            for (Case c : caseList) {
                csvData += '"' + c.CaseNumber + '","' + c.Subject + '","' + 
                        c.CreatedDate + '","' + c.Last_Status_Change__c + '","' +
                        c.SLA_Breach_Type__c + '","' + c.Owner.Name + '","' +
                        orgBaseUrl + '/lightning/r/Case/' + c.Id + '/view"\n';
            }
        }

        // Send only if there's data
        if (!String.isBlank(csvData)) {
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(fileName);
            attachment.setBody(Blob.valueOf(csvData));
            attachment.setContentType('text/csv');

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>(recipientEmails));
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setOrgWideEmailAddressId(Constants.ORG_WIDE_ADDRESS_ID_CUSTOMER_SERVICE);
            email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        }
    }

    public static Set<String> getManagerEmails() {
        Set<Id> userIds = new Set<Id>();
        for (GroupMember gm : [
            SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Manager_Queue'
        ]) {
            userIds.add(gm.UserOrGroupId);
        }

        List<User> users = [SELECT Email FROM User WHERE Id IN :userIds];
        Set<String> emails = new Set<String>();
        for (User u : users) {
            if (u.Email != null) {
                emails.add(u.Email);
            }
        }
        return emails;
    }

    public static Map<Id, Decimal> calculateBusinessHoursBetweenStatuses(Set<Id> caseIds, String fromStatus, 
        String toStatus, Id businessHoursId) {

        if (caseIds == null || caseIds.isEmpty() || String.isBlank(toStatus)) {
            return null;
        }
        Map<Id, Decimal> result = new Map<Id, Decimal>();

        if (businessHoursId == null) {
            businessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1].Id;
        }
        Map<Id, Case> caseMap = new Map<Id, Case>(
            [SELECT Id, CreatedDate FROM Case WHERE Id IN :caseIds]
        );

        List<CaseHistory> allHistories = [
            SELECT CaseId, OldValue, NewValue, CreatedDate
            FROM CaseHistory
            WHERE CaseId IN :caseIds AND Field = 'Status'
            ORDER BY CreatedDate ASC
        ];

        Map<Id, List<CaseHistory>> caseHistoryMap = new Map<Id, List<CaseHistory>>();
        for (CaseHistory ch : allHistories) {
            if (!caseHistoryMap.containsKey(ch.CaseId)) {
                caseHistoryMap.put(ch.CaseId, new List<CaseHistory>());
            }
            caseHistoryMap.get(ch.CaseId).add(ch);
        }

        for (Id caseId : caseIds) {
            List<CaseHistory> historyList = caseHistoryMap.get(caseId);
            if (historyList == null || historyList.isEmpty()) {
                result.put(caseId, null);
                continue;
            }

            DateTime fromTimestamp = null;
            DateTime toTimestamp = null;

            for (CaseHistory h : historyList) {
                if (!String.isBlank(fromStatus) && fromTimestamp == null && h.NewValue == fromStatus) {
                    fromTimestamp = h.CreatedDate;
                }

                if (String.isBlank(fromStatus) && fromTimestamp == null) {
                    // ✅ Use Case.CreatedDate if fromStatus is null
                    fromTimestamp = caseMap.containsKey(caseId) ? caseMap.get(caseId).CreatedDate : null;
                }

                if (fromTimestamp != null && h.NewValue == toStatus) {
                    toTimestamp = h.CreatedDate;
                    break;
                }
            }

            if (fromTimestamp != null && toTimestamp != null && toTimestamp > fromTimestamp) {
                Long ms = BusinessHours.diff(businessHoursId, fromTimestamp, toTimestamp);
                Decimal hours = Decimal.valueOf(ms) / (1000 * 60 * 60);
                result.put(caseId, hours.setScale(2));
            } else {
                result.put(caseId, null);
            }
        }

        return result;
    }

    public static Map<Id, List<CaseHistory>> getCaseStatusHistory(Set<Id> caseIds) {
        Map<Id, List<CaseHistory>> historyMap = new Map<Id, List<CaseHistory>>();
        for (CaseHistory ch : [
            SELECT CaseId, OldValue, NewValue, CreatedDate
            FROM CaseHistory
            WHERE CaseId IN :caseIds AND Field = 'Status'
            ORDER BY CreatedDate ASC
        ]) {
            if (!historyMap.containsKey(ch.CaseId)) {
                historyMap.put(ch.CaseId, new List<CaseHistory>());
            }
            historyMap.get(ch.CaseId).add(ch);
        }
        return historyMap;
    }

}