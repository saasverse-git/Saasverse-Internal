public class Constants {

    // Queues Constants

    public static Id QUEUE_ID_AWAITING_INFO = getQueueId('Awaiting_Info');
    public static Id QUEUE_ID_CCS_GENERAL = getQueueId('CCS_General');
    


    // EmailTemplate Constants

    public static Id EMAIL_TEMPLATE_ID_CUSTOMER_ACKNOWLEDGEMENT = 
        getEmailTemplateId('Acknowledgement_For_Case_Submission_E2C');

    public static Id EMAIL_TEMPLATE_ID_PRODUCT_DETAILS_INFO = 
        getEmailTemplateId('Product_Details_Form_Follow_Up_Email_E2C');

    public static Id EMAIL_TEMPLATE_ID_CASE_FOLLOWUP_REMINDER = 
        getEmailTemplateId('Case_Follow_Up_Reminder_to_Submit_Form');

    public static Id EMAIL_TEMPLATE_ID_CASE_CLOSURE_NO_RESPONSE = 
        getEmailTemplateId('Final_Case_Closure_No_Customer_Response');
    
    public static Id EMAIL_TEMPLATE_ID_RECALL_ACCEPTED = 
        getEmailTemplateId('Recall_Accepted_Email_Template');

    public static Id EMAIL_TEMPLATE_ID_CSAT_FORM = 
        getEmailTemplateId('Case_Closed_CSAT_Survey_Request');
    
    
    // Org Wide Default Constants

    public static Id ORG_WIDE_ADDRESS_ID_CUSTOMER_SERVICE = 
        getOrgWideEmailAddressIdByEmail('cssfnoreply@spectrumbrands.com');

    
    
    
    
    // RecordType Constants
    public static Id RECORD_TYPE_CASE_RECALL_REGISTRATION = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Recall Registration').getRecordTypeId();
    public static Id RECORD_TYPE_CASE_CUSTOMER_SERVICE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Service').getRecordTypeId();
    
    
    // Sites Constants
    public static String SITE_LINK_CASE_FOLLOW_UP_FORM = Label.Site_Link_Case_Follow_Up_Form;

    public static String SITE_LINK_NEW_CASE_SUBMIT = Label.Site_Link_New_Case_Submit;





    // Helper Methods
    private static Id getQueueId(String queueName) {
        Group queue = [
            SELECT Id FROM Group 
            WHERE Type = 'Queue' AND DeveloperName = :queueName 
            LIMIT 1
        ];
        return queue.Id;
    }

    private static Id getEmailTemplateId(String templateDeveloperName) {
        EmailTemplate template = [
            SELECT Id FROM EmailTemplate 
            WHERE DeveloperName = :templateDeveloperName 
            LIMIT 1
        ];
        return template.Id;
    }

    private static Id getOrgWideEmailAddressIdByEmail(String email) {
        OrgWideEmailAddress orgwd = [
            SELECT Id FROM OrgWideEmailAddress
            WHERE Address = :email
            LIMIT 1
        ];
        return orgwd.Id;
    }

}