public class EmailServiceUtility {

    public class EmailPayload {
        public List<String> toAddress;
        public String templateId;
        public Map<String, String> tokens;
        public String senderAddressId;
        public Id parentId;
        public Id parentEmailMessageId;
        public String replyToId;
        public String finalSubject;
        public String finalBody;
        public Boolean isReply;
    }

    public static void sendEmails(List<EmailPayload> emailPayloads) {
        if (emailPayloads == null || emailPayloads.isEmpty()) return;

        Set<Id> templateIds = new Set<Id>();
        Set<Id> parentCaseIds = new Set<Id>();
        Set<Id> senderAddressIds = new Set<Id>();
        
        for (EmailPayload payload : emailPayloads) {
            if (payload.templateId != null) {
                templateIds.add(payload.templateId);
            }
            if (payload.parentId != null && payload.isReply) {
                parentCaseIds.add(payload.parentId);
            }
            if (payload.senderAddressId != null) {
                senderAddressIds.add((Id)payload.senderAddressId);
            }
        }

        Map<Id, EmailTemplate> templateMap = new Map<Id, EmailTemplate>(
            [SELECT Id, Subject, HtmlValue, Body 
             FROM EmailTemplate 
             WHERE Id IN :templateIds]
        );

        Map<Id, OrgWideEmailAddress> senderInfoMap = new Map<Id, OrgWideEmailAddress>(
            [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Id IN :senderAddressIds]
        );

        Map<Id, EmailMessage> latestCaseEmailMap = new Map<Id, EmailMessage>();
        if (!parentCaseIds.isEmpty()) {
            List<EmailMessage> latestEmails = [
                SELECT Id, ParentId, FromAddress, FromName, Subject, TextBody, HtmlBody, 
                       CreatedDate, MessageIdentifier, ToAddress
                FROM EmailMessage 
                WHERE ParentId IN :parentCaseIds 
                ORDER BY CreatedDate DESC
            ];
            
            for (EmailMessage em : latestEmails) {
                if (!latestCaseEmailMap.containsKey(em.ParentId)) {
                    latestCaseEmailMap.put(em.ParentId, em);
                }
            }
        }

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (EmailPayload payload : emailPayloads) {
            EmailTemplate template = templateMap.get(payload.templateId);
            if (template == null) continue;

            String subject = template.Subject;
            String body = (template.HtmlValue != null && !String.isEmpty(template.HtmlValue.trim()))
              ? template.HtmlValue 
              : template.Body;
   
            if (payload.tokens != null && !payload.tokens.isEmpty()) {
                if (body != null && body.contains('{{')) {
                    body = applyMergeTokens(body, payload.tokens);
                }
                if (subject != null && subject.contains('{{')) {
                    subject = applyMergeTokens(subject, payload.tokens);
                }
            }

            EmailMessage originalEmail = null;
            if (payload.isReply) {
                if (payload.parentId != null) {
                    CaseUtility.insertLog('latestCaseEmailMap',JSON.serialize(latestCaseEmailMap), 'Generic Email');
                    CaseUtility.insertLog('payload.parentId',JSON.serialize(payload.parentId), 'Generic Email');
                    CaseUtility.insertLog('latestCaseEmailMap key',JSON.serialize(latestCaseEmailMap.keySet()), 'Generic Email');
                    originalEmail = latestCaseEmailMap.get(payload.parentId);
                    CaseUtility.insertLog('originalEmail',JSON.serialize(originalEmail), 'Generic Email');

                }

                if (originalEmail != null) {
                    payload.replyToId = originalEmail.MessageIdentifier;
                    payload.parentEmailMessageId = originalEmail.Id;

                    if (payload.isReply) {
                        CaseUtility.insertLog('Inserting old payload','test', 'Generic Email');
                        body = appendOriginalMessage(body, originalEmail);
                    }
                }
            }

            payload.finalSubject = subject;
            payload.finalBody = body;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            // Set threading headers for replies
            if (payload.replyToId != null) {
                mail.setInReplyTo(payload.replyToId);
                mail.setReferences(payload.replyToId);
            }

            mail.setToAddresses(payload.toAddress);
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setOrgWideEmailAddressId(payload.senderAddressId);
            mail.setSaveAsActivity(false);

            if (payload.parentId != null) {
                mail.setWhatId(payload.parentId);
            }
           
            emailsToSend.add(mail);
        }

        List<EmailMessage> messagesToInsert = new List<EmailMessage>();
        if (!emailsToSend.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend, false);
            for (Integer i = 0; i < results.size(); i++) {
                Messaging.SendEmailResult res = results[i];
                EmailPayload payload = emailPayloads[i];
                OrgWideEmailAddress senderInfo = senderInfoMap.get(payload.senderAddressId);

                String senderEmail = senderInfo != null ? senderInfo.Address : 'Unknown';
                String senderName  = senderInfo != null ? senderInfo.DisplayName : 'Unknown';

                String logPayload = JSON.serializePretty(new Map<String, Object>{
                    'To' => payload.toAddress,
                    'TemplateId' => payload.templateId,
                    'SenderEmail' => senderEmail,
                    'SenderName' => senderName,
                    'IsReply' => payload.isReply
                });

                if (!res.isSuccess()) {
                    String errorMsg = res.getErrors()[0].getMessage();
                    CaseUtility.insertLog('Email Failed', 'Error: ' + errorMsg + '\nPayload:\n' + logPayload, 'Generic Email');
                } else {
                    CaseUtility.insertLog('Email Sent', 'Success\nPayload:\n' + logPayload, 'Generic Email');
                    if (payload.parentId != null) {
                        messagesToInsert.add(new EmailMessage(
                            RelatedToId = payload.parentId,
                            ParentId = payload.parentId,
                            Subject = payload.finalSubject,
                            HtmlBody = payload.finalBody,
                            FromAddress = senderEmail,
                            ToAddress = payload.toAddress != null && !payload.toAddress.isEmpty() ? payload.toAddress[0] : null,
                            FromName = senderName,
                            Incoming = false,
                            Status = '3',
                            MessageDate = System.now(),
                            MessageIdentifier = payload.replyToId != null ? payload.replyToId : null,
                            ReplyToEmailMessageId = payload.parentEmailMessageId != null ? payload.parentEmailMessageId : null
                        ));
                    }
                }
            }
        }
        if (!messagesToInsert.isEmpty()) {
            insert messagesToInsert;
        }
    }

    private static String appendOriginalMessage(String currentBody, EmailMessage originalEmail) {
        if (originalEmail == null) return currentBody;

        String separator = '<br/><br/>------------------------ Original Message ------------------------<br/>';

        // From
        if (originalEmail.FromName != null && originalEmail.FromAddress != null) {
            separator += 'From: ' + originalEmail.FromName + ' [' + originalEmail.FromAddress + ']<br/>';
        } else if (originalEmail.FromAddress != null) {
            separator += 'From: ' + originalEmail.FromAddress + '<br/>';
        }

        // Date
        if (originalEmail.CreatedDate != null) {
            separator += 'Sent: ' + originalEmail.CreatedDate.format('M/d/yyyy h:mm a') + '<br/>';
        }

        // To
        if (originalEmail.ToAddress != null) {
            separator += 'To: ' + originalEmail.ToAddress + '<br/>';
        }

        // Subject
        if (originalEmail.Subject != null) {
            separator += 'Subject: ' + originalEmail.Subject + '<br/><br/>';
        }

        // Body
        if (!String.isEmpty(originalEmail.HtmlBody)) {
            separator += originalEmail.HtmlBody;
        } else if (!String.isEmpty(originalEmail.TextBody)) {
            separator += originalEmail.TextBody.replaceAll('\n', '<br/>');
        }


        return currentBody + separator;
    }



    private static String applyMergeTokens(String input, Map<String, String> tokens) {
        String output = input;
        for (String key : tokens.keySet()) {
            output = output.replace('{{' + key + '}}', tokens.get(key));
        }
        return output;
    }
}