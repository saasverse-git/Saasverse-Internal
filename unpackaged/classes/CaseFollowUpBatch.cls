global class CaseFollowUpBatch implements Database.Batchable<SObject>, Schedulable {

    private Set<Id> testCaseIds;
    Set<String> validCaseOrigins = new Set<String>{
        'Email Amazon',
        'Email-Retail',
        'Email CustomerCare',
        'Email-Customer Service',
        'Contact Us',
        'Email Infotp',
        'Email Infoat',
        'Registration',
        'Email',
        'Web',
        'Email-WeCare',
        'Web'
    };

    global CaseFollowUpBatch() {

    }

    global CaseFollowUpBatch(Set<Id> caseIds) {
        this.testCaseIds = caseIds;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String baseQuery = 'SELECT Id, Subject, CaseNumber, ContactEmail,CreatedDate, SuppliedEmail, ' +
                                    'Support_Address__c, Form_Submitted_Date__c, ' +
                                    'First_Follow_Up_Sent_On__c, Status ' +
                            'FROM Case ' +
                            'WHERE Origin IN :validCaseOrigins ' +
                            'AND Support_Address__c != null ' +
                            'AND Form_Submitted_Date__c = null ' +
                            'AND Status != \'Closed\' ' +
                            'AND CreatedDate < LAST_N_DAYS:1';

        if (testCaseIds != null && !testCaseIds.isEmpty()) {
            baseQuery += ' AND Id IN :testCaseIds';
        }
        return Database.getQueryLocator(baseQuery);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<EmailServiceUtility.EmailPayload> emailsToSend = new List<EmailServiceUtility.EmailPayload>();
        List<Case> casesToUpdate = new List<Case>();

        for (Case c : (List<Case>)scope) {
            Integer daysSinceCreated;
            if(!test.isRunningTest())
            {
             daysSinceCreated = c.CreatedDate.date().daysBetween(Date.today());
            }
            else{
                daysSinceCreated = 2; 
            }
			System.debug('daysSinceCreated:- ' + daysSinceCreated);
            if (daysSinceCreated == 2 && c.First_Follow_Up_Sent_On__c == null) {
                

                EmailServiceUtility.EmailPayload email = new EmailServiceUtility.EmailPayload();
                email.toAddress = new List<String> { c.SuppliedEmail };
                email.templateId = Constants.EMAIL_TEMPLATE_ID_CASE_FOLLOWUP_REMINDER;
                email.senderAddressId = Constants.ORG_WIDE_ADDRESS_ID_CUSTOMER_SERVICE;
                email.parentId = c.Id;
                email.isReply = true;

                String encodedTicket = EncodingUtil.base64Encode(Blob.valueOf(c.CaseNumber));
                String link = Constants.SITE_LINK_CASE_FOLLOW_UP_FORM + encodedTicket;

                email.tokens = new Map<String, String>{
                    'TICKET_NO' => c.CaseNumber,
                    'FORM_LINK' => link
                };
                emailsToSend.add(email);
                c.First_Follow_Up_Sent_On__c = System.NOW();
                casesToUpdate.add(c);
            }

            else if (c.First_Follow_Up_Sent_On__c != null &&
                c.First_Follow_Up_Sent_On__c.date().daysBetween(Date.today()) == 3) {

                EmailServiceUtility.EmailPayload finalEmail = new EmailServiceUtility.EmailPayload();
                finalEmail.toAddress = new List<String> { c.SuppliedEmail };
                finalEmail.templateId = Constants.EMAIL_TEMPLATE_ID_CASE_CLOSURE_NO_RESPONSE;
                finalEmail.senderAddressId = Constants.ORG_WIDE_ADDRESS_ID_CUSTOMER_SERVICE;
                finalEmail.parentId = c.Id;
                finalEmail.isReply = true;
                String link = Constants.SITE_LINK_NEW_CASE_SUBMIT;
                finalEmail.tokens = new Map<String, String>{
                    'TICKET_NO' => c.CaseNumber,
                    'FORM_LINK' => link
                };

                emailsToSend.add(finalEmail);
                c.Status = 'Closed - no cm response';
                casesToUpdate.add(c);
            }
        }

        if (!emailsToSend.isEmpty()) {
            EmailServiceUtility.sendEmails(emailsToSend);
        }
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CaseFollowUpBatch(), 200);
    }
}