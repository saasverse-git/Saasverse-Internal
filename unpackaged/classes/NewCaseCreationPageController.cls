global without sharing class NewCaseCreationPageController {

    public Boolean isSubmitted { get; set; }
    public String createdCaseNumber { get; set; }

    public NewCaseCreationPageController() {
        isSubmitted = false;
    }
	
    
    public PageReference submitForm() {
        try {
            isSubmitted = true;
            Map<String, String> params = ApexPages.currentPage().getParameters();
            Case caseRec = CaseFormHelper.constructCaseRecord(params);
            caseRec.OwnerId = Constants.QUEUE_ID_AWAITING_INFO;
            caseRec.Origin = 'Email';
            insert caseRec;

            Case insertedCase = [select Id, CaseNumber, SuppliedEmail from Case where Id = :caseRec.Id];
            createdCaseNumber = insertedCase.CaseNumber;

            isSubmitted = true;

            CaseFormHelper.insertAttachments(insertedCase.Id, params);
            sendAcknowledgementMail(insertedCase);
        } catch (Exception e) {
            System.debug('exception:- ' +e);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
        } 
        return null;
    }


    @RemoteAction
    public static Map<String, List<String>> getModelMap(String brandName) {
        return CaseFormHelper.getModelMap(brandName);
    }

    @RemoteAction
    public static List<String> getReasonForContactOptions() {
       return CaseFormHelper.getReasonForContactOptions();
    }

    @RemoteAction
    public static List<String> getBrandOptions() {
       return CaseFormHelper.getBrandOptions();
    }

    private static void sendAcknowledgementMail(Case insertedCase) {
        List<EmailServiceUtility.EmailPayload> emailsToSend = new List<EmailServiceUtility.EmailPayload>();
        EmailServiceUtility.EmailPayload finalEmail = new EmailServiceUtility.EmailPayload();
        finalEmail.toAddress = new List<String> { insertedCase.SuppliedEmail };
        finalEmail.templateId = Constants.EMAIL_TEMPLATE_ID_CUSTOMER_ACKNOWLEDGEMENT;
        finalEmail.senderAddressId = Constants.ORG_WIDE_ADDRESS_ID_CUSTOMER_SERVICE;
        finalEmail.ParentId = insertedCase.Id;
        finalEmail.tokens = new Map<String, String>{
                'TICKET_NO' => insertedCase.CaseNumber
        };
        emailsToSend.add(finalEmail);
        if (!emailsToSend.isEmpty()) {
            EmailServiceUtility.sendEmails(emailsToSend);
        }
    }
}