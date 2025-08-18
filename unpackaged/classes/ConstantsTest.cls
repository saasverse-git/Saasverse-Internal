@isTest
private class ConstantsTest {

    @isTest
    static void testConstantsInitialization() {
        // Insert dummy Queue (Group) records
         /*
        Group awaitingInfoQueue = new Group(
            Name = 'Awaiting Info Queue',
            DeveloperName = 'Awaiting_Info',
            Type = 'Queue'
        );
        insert awaitingInfoQueue;
		
        Group ccsGeneralQueue = new Group(
            Name = 'CCS General Queue',
            DeveloperName = 'CCS_General',
            Type = 'Queue'
        );
        insert ccsGeneralQueue;
*/

        // Insert dummy EmailTemplate records
        EmailTemplate customerAckTemplate = new EmailTemplate(
            Name = 'Customer Ack Template',
            DeveloperName = 'Acknowledgement_For_Case_Submission_E2C',
            Subject = 'Test',
            HtmlValue = 'Test',
            TemplateType = 'text',
            FolderId = UserInfo.getUserId()
        );
        insert customerAckTemplate;

        EmailTemplate productDetailsTemplate = new EmailTemplate(
            Name = 'Product Details Template',
            DeveloperName = 'Product_Details_Form_Follow_Up_Email_E2C',
            Subject = 'Test',
            HtmlValue = 'Test',
            TemplateType = 'text',
            FolderId = UserInfo.getUserId()
        );
        insert productDetailsTemplate;

        EmailTemplate followUpReminderTemplate = new EmailTemplate(
            Name = 'Case FollowUp Reminder',
            DeveloperName = 'Case_Follow_Up_Reminder_to_Submit_Form',
            Subject = 'Test',
            HtmlValue = 'Test',
            TemplateType = 'text',
            FolderId = UserInfo.getUserId()
        );
        insert followUpReminderTemplate;

        EmailTemplate closureNoResponseTemplate = new EmailTemplate(
            Name = 'Closure No Response',
            DeveloperName = 'Final_Case_Closure_No_Customer_Response',
            Subject = 'Test',
            HtmlValue = 'Test',
            TemplateType = 'text',
            FolderId = UserInfo.getUserId()
        );
        insert closureNoResponseTemplate;

        EmailTemplate recallAcceptedTemplate = new EmailTemplate(
            Name = 'Recall Accepted',
            DeveloperName = 'Recall_Accepted_Email_Template',
            Subject = 'Test',
            HtmlValue = 'Test',
            TemplateType = 'text',
            FolderId = UserInfo.getUserId()
        );
        insert recallAcceptedTemplate;

        EmailTemplate csatFormTemplate = new EmailTemplate(
            Name = 'CSAT Form',
            DeveloperName = 'Case_Closed_CSAT_Survey_Request',
            Subject = 'Test',
            HtmlValue = 'Test',
            TemplateType = 'text',
            FolderId = UserInfo.getUserId()
        );
        insert csatFormTemplate;

        // Insert dummy OrgWideEmailAddress record
        /*
        OrgWideEmailAddress orgWide = new OrgWideEmailAddress(
            DisplayName = 'Customer Service',
            Address = 'cssfnoreply@spectrumbrands.com'
        );
        insert orgWide;*/

        // Test: reference all public static fields to trigger static initializers
        
        Test.startTest();
        Test.stopTest();
		
        // Optional: assert they are not null
        System.assertNotEquals(null, Constants.QUEUE_ID_AWAITING_INFO);
        System.assertNotEquals(null, Constants.QUEUE_ID_CCS_GENERAL);
        System.assertNotEquals(null, Constants.EMAIL_TEMPLATE_ID_CUSTOMER_ACKNOWLEDGEMENT);
        System.assertNotEquals(null, Constants.EMAIL_TEMPLATE_ID_PRODUCT_DETAILS_INFO);
        System.assertNotEquals(null, Constants.EMAIL_TEMPLATE_ID_CASE_FOLLOWUP_REMINDER);
        System.assertNotEquals(null, Constants.EMAIL_TEMPLATE_ID_CASE_CLOSURE_NO_RESPONSE);
        System.assertNotEquals(null, Constants.EMAIL_TEMPLATE_ID_RECALL_ACCEPTED);
        System.assertNotEquals(null, Constants.EMAIL_TEMPLATE_ID_CSAT_FORM);
        System.assertNotEquals(null, Constants.ORG_WIDE_ADDRESS_ID_CUSTOMER_SERVICE);
    }
}