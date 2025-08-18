public without sharing class EmailMessageTriggerHandler {
   public static void afterInsert(List<EmailMessage> emailMessages) {
        sendProductDetailInfoMail(emailMessages);
        sendAcknowledgementMail(emailMessages);
    }

    private static void sendProductDetailInfoMail(List<EmailMessage> emailMessages) {
        Map<Id, EmailMessage> caseToEmailMessageRecord = new Map<Id, EmailMessage>();
    
        String noFollowUpEmail = System.Label.EmailForNoFollowUp.toLowerCase();
        
        String acknowledgementEmail = System.Label.EmailForAcknowledgement.toLowerCase();
        
        for (EmailMessage em : emailMessages) {
            if (em.Incoming &&
                em.ParentId != null &&
                em.ParentId.getSObjectType() == Case.SObjectType &&
                !String.isBlank(em.FromAddress) &&
                !String.isBlank(em.ToAddress) &&
                !noFollowUpEmail.contains(String.ValueOf(em.ToAddress).toLowerCase()) &&
                !acknowledgementEmail.contains(String.ValueOf(em.ToAddress).toLowerCase())) {
                    
                    caseToEmailMessageRecord.put(em.ParentId, em);
                    
                }
        }
        if (caseToEmailMessageRecord.isEmpty()) return;

        Map<Id, Case> caseMap = new Map<Id, Case>(
            [SELECT Id, CaseNumber, ContactEmail, Subject, Status, Origin 
            FROM Case 
            WHERE Id IN :caseToEmailMessageRecord.keySet()]
        );

        Map<Id, Integer> emailCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT ParentId, COUNT(Id) cnt
            FROM EmailMessage
            WHERE ParentId IN :caseMap.keySet()
            GROUP BY ParentId
        ]) {
            emailCounts.put((Id)ar.get('ParentId'), (Integer)ar.get('cnt'));
        }

        List<EmailServiceUtility.EmailPayload> emailsToSend = new List<EmailServiceUtility.EmailPayload>();

        for (Id caseId : caseMap.keySet()) {
            Integer count = emailCounts.containsKey(caseId) ? emailCounts.get(caseId) : 0;
            if (count > 1) continue;

            EmailServiceUtility.EmailPayload email = new EmailServiceUtility.EmailPayload();
            email.toAddress = new List<String> { caseToEmailMessageRecord.get(caseId).FromAddress };
            email.templateId = Constants.EMAIL_TEMPLATE_ID_PRODUCT_DETAILS_INFO; 
            email.senderAddressId = Constants.ORG_WIDE_ADDRESS_ID_CUSTOMER_SERVICE;
            email.ParentId = caseId;
            email.isReply = true;

            String caseNumber = caseMap.get(caseId).CaseNumber;
            Blob ticketBlob = Blob.valueOf(caseNumber);
            String encodedTicket = EncodingUtil.base64Encode(ticketBlob);
            String link = Constants.SITE_LINK_CASE_FOLLOW_UP_FORM + encodedTicket;

            email.tokens = new Map<String, String>{
                'FORM_LINK' => link
            };

            emailsToSend.add(email);
        }
        if (!emailsToSend.isEmpty()) {
            EmailServiceUtility.sendEmails(emailsToSend);
            List<Case> casesToUpdate = new List<Case>();

            for (Id caseId : caseToEmailMessageRecord.keySet()) {
                casesToUpdate.add(new Case(
                    Id = caseId,
                    Status = 'New',
                    Support_Address__c = caseToEmailMessageRecord.get(caseId).ToAddress));
            }
            update casesToUpdate;
        }
    }

    private static void sendAcknowledgementMail(List<EmailMessage> emailMessages) {
        
        Map<Id, EmailMessage> caseToEmailMessageRecord = new Map<Id, EmailMessage>();
    
        String noFollowUpEmail = System.Label.EmailForNoFollowUp.toLowerCase();
        
        String acknowledgementEmail = System.Label.EmailForAcknowledgement.toLowerCase();
        
        for (EmailMessage em : emailMessages) {
            if (em.Incoming &&
                em.ParentId != null &&
                em.ParentId.getSObjectType() == Case.SObjectType &&
                !String.isBlank(em.FromAddress) &&
                !String.isBlank(em.ToAddress) &&
                !noFollowUpEmail.contains(String.ValueOf(em.ToAddress).toLowerCase()) &&
                acknowledgementEmail.contains(String.ValueOf(em.ToAddress).toLowerCase())) {
                    
                    caseToEmailMessageRecord.put(em.ParentId, em);
                    
                }
        }
        if (caseToEmailMessageRecord.isEmpty()) return;

        Map<Id, Case> caseMap = new Map<Id, Case>(
            [SELECT Id, CaseNumber, ContactEmail, Subject, Status, Origin 
            FROM Case 
            WHERE Id IN :caseToEmailMessageRecord.keySet()]
        );

        Map<Id, Integer> emailCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT ParentId, COUNT(Id) cnt
            FROM EmailMessage
            WHERE ParentId IN :caseMap.keySet()
            GROUP BY ParentId
        ]) {
            emailCounts.put((Id)ar.get('ParentId'), (Integer)ar.get('cnt'));
        }

        List<EmailServiceUtility.EmailPayload> emailsToSend = new List<EmailServiceUtility.EmailPayload>();

        for (Id caseId : caseMap.keySet()) {
            Integer count = emailCounts.containsKey(caseId) ? emailCounts.get(caseId) : 0;
            if (count > 1) continue;

            EmailServiceUtility.EmailPayload email = new EmailServiceUtility.EmailPayload();
            email.toAddress = new List<String> { caseToEmailMessageRecord.get(caseId).FromAddress };
            email.templateId = Constants.EMAIL_TEMPLATE_ID_CUSTOMER_ACKNOWLEDGEMENT; 
            email.senderAddressId = Constants.ORG_WIDE_ADDRESS_ID_CUSTOMER_SERVICE;
            email.ParentId = caseId;
            email.isReply = false;

            String caseNumber = caseMap.get(caseId).CaseNumber;

            email.tokens = new Map<String, String>{
                'TICKET_NO' => caseNumber
            };

            emailsToSend.add(email);
        }
        if (!emailsToSend.isEmpty()) {
            EmailServiceUtility.sendEmails(emailsToSend);

        }
        
    }
}