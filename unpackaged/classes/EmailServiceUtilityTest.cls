@isTest
public class EmailServiceUtilityTest {

    static Id replyTemplateId;
    static Id nonReplyTemplateId;

    @testSetup
    static void setupData() {
       
        insert new List<Case>{
            new Case(Subject = 'Reply test case'),
            new Case(Subject = 'Non-reply test case')
        };

        
    String uniqueUsername = 'testuser_' + System.currentTimeMillis() + '@example.com';

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            LastName='testUserLastName',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUsername
        );
        insert u;

        System.runAs(u) {
           
            EmailTemplate replyTemplate = new EmailTemplate(
                Name = 'ReplyTemplate',
                DeveloperName = 'Reply_Template',
                HtmlValue = 'Hi {{name}}, responding to your case {{caseNumber}}.',
                Subject = 'RE: Case {{caseNumber}}',
                TemplateType = 'custom',
                FolderId = UserInfo.getUserId()
            );

            EmailTemplate nonReplyTemplate = new EmailTemplate(
                Name = 'NonReplyTemplate',
                DeveloperName = 'NonReply_Template',
                HtmlValue = 'Hello {{name}}, your case {{caseNumber}} has been received.',
                Subject = 'Case {{caseNumber}} Received',
                TemplateType = 'custom',
                FolderId = UserInfo.getUserId()
            );

            insert new List<EmailTemplate>{ replyTemplate, nonReplyTemplate };

            // Assign template Ids to static variables
            replyTemplateId = replyTemplate.Id;
            nonReplyTemplateId = nonReplyTemplate.Id;
        }
    }

    @isTest
    static void testSendEmail_NonReply_Success() {
        Case c = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Reply test case' LIMIT 1];
        OrgWideEmailAddress owEmail = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        Map<String, String> tokens = new Map<String, String>{
            'name' => 'NonReply User',
            'caseNumber' => c.CaseNumber
        };

        EmailServiceUtility.EmailPayload payload = new EmailServiceUtility.EmailPayload();
        payload.toAddress = new List<String>{'noreply@example.com'};
        payload.templateId = nonReplyTemplateId;
        payload.tokens = tokens;
        payload.senderAddressId = owEmail.Id;
        payload.parentId = c.Id;
        payload.isReply = false;

        Test.startTest();
        EmailServiceUtility.sendEmails(new List<EmailServiceUtility.EmailPayload>{ payload });
        Test.stopTest();
    }

    @isTest
    static void testSendEmail_Reply_Success_Recall_processFAQ() {
        Case c = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Non-reply test case' LIMIT 1];

        EmailMessage originalEmail = new EmailMessage(
            RelatedToId = c.Id,
            ParentId = c.Id,
            FromName = 'Customer Name',
            FromAddress = 'customer@example.com',
            ToAddress = 'testingforwarding05@gmail.com',
            Subject = 'Original Case Subject',
            HtmlBody = '<p>Original message content</p>',
            TextBody = 'Original message content',
            Incoming = true,
            Status = '3',
            MessageDate = System.now(),
            MessageIdentifier = 'OriginalMsg123'
        );
        insert originalEmail;

        OrgWideEmailAddress owEmail = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        Map<String, String> tokens = new Map<String, String>{
            'name' => 'Reply User',
            'caseNumber' => c.CaseNumber
        };

        EmailServiceUtility.EmailPayload payload = new EmailServiceUtility.EmailPayload();
        payload.toAddress = new List<String>{'reply@example.com'};
        payload.templateId = replyTemplateId;
        payload.tokens = tokens;
        payload.senderAddressId = owEmail.Id;
        payload.parentId = c.Id;
        payload.isReply = true;

        Test.startTest();
        EmailServiceUtility.sendEmails(new List<EmailServiceUtility.EmailPayload>{ payload });
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmail_Reply_Success() {
        Case c = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Non-reply test case' LIMIT 1];

        EmailMessage originalEmail = new EmailMessage(
            RelatedToId = c.Id,
            ParentId = c.Id,
            FromName = 'Customer Name',
            FromAddress = 'customer@example.com',
            ToAddress = 'agent@example.com',
            Subject = 'Original Case Subject',
            HtmlBody = '<p>Original message content</p>',
            TextBody = 'Original message content',
            Incoming = true,
            Status = '3',
            MessageDate = System.now(),
            MessageIdentifier = 'OriginalMsg123'
        );
        insert originalEmail;

        OrgWideEmailAddress owEmail = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        Map<String, String> tokens = new Map<String, String>{
            'name' => 'Reply User',
            'caseNumber' => c.CaseNumber
        };

        EmailServiceUtility.EmailPayload payload = new EmailServiceUtility.EmailPayload();
        payload.toAddress = new List<String>{'reply@example.com'};
        payload.templateId = replyTemplateId;
        payload.tokens = tokens;
        payload.senderAddressId = owEmail.Id;
        payload.parentId = c.Id;
        payload.isReply = true;

        Test.startTest();
        EmailServiceUtility.sendEmails(new List<EmailServiceUtility.EmailPayload>{ payload });
        Test.stopTest();
    }

    @isTest
    static void testSendEmail_NullPayloadList() {
        Test.startTest();
        EmailServiceUtility.sendEmails(null);
        Test.stopTest();
    }

    @isTest
    static void testSendEmail_EmptyPayloadList() {
        Test.startTest();
        EmailServiceUtility.sendEmails(new List<EmailServiceUtility.EmailPayload>());
        Test.stopTest();
    }

    @isTest
    static void testSendEmail_InvalidTemplate() {
        OrgWideEmailAddress owEmail = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        Case testCase = new Case(Subject = 'Invalid template test');
        insert testCase;

        EmailServiceUtility.EmailPayload payload = new EmailServiceUtility.EmailPayload();
        payload.toAddress = new List<String>{'invalid@example.com'};
        payload.senderAddressId = owEmail.Id;
        payload.parentId = testCase.Id;
        payload.isReply = false;

        Test.startTest();
        EmailServiceUtility.sendEmails(new List<EmailServiceUtility.EmailPayload>{ payload });
        Test.stopTest();
    }
}