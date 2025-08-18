public without sharing class CaseFollowUpFormController {
    public String ticketNumber { get; set; }
    public Boolean isSubmitted { get; set; }
    public Boolean isValidTicket { get; set; }
    public Case relatedCase { get; set; }
    public String customerName { get; set; }
    public String customerEmail { get; set; }

    public CaseFollowUpFormController() {
        String decodedTicket = ApexPages.currentPage().getParameters().get('ticket');
        if (String.isBlank(decodedTicket)) {
            isValidTicket = false;
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Missing or invalid ticket. Please use the original link from your email.'
            ));
            return;
        }
        try {
            Blob decodedBlob = EncodingUtil.base64Decode(decodedTicket);
            ticketNumber = decodedBlob.toString();
            validateTicket();
        } catch (Exception e) {
            isValidTicket = false;
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Unable to read ticket. The link may be corrupted or expired.'
            ));
        }
        validateTicket();
    }
    
    private void validateTicket() {
        if(String.isBlank(ticketNumber)) {
            isValidTicket = false;
            return;
        }
        
        try {
            relatedCase = [SELECT Id, CaseNumber, ContactEmail, Status, Brand__c, Model__c, Form_Submitted_Date__c, SuppliedName, SuppliedEmail
                          FROM Case 
                          WHERE CaseNumber = :ticketNumber
                          And Status in ('New', 'Open')
                          LIMIT 1];
            
            System.debug('relatedCase:- '+ relatedCase);
            isValidTicket = true;
            customerName = relatedCase.SuppliedName;
            customerEmail = relatedCase.SuppliedEmail;
            isSubmitted = (relatedCase.Form_Submitted_Date__c != null);
        } catch(QueryException e) {
            isValidTicket = false;
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Invalid or expired ticket number. Please check your email for the correct link.'
            ));
        }
    }
    
    public PageReference submitForm() {
        isSubmitted = true;
        try {
            Map<String, String> params = ApexPages.currentPage().getParameters();
            Case updatedCase = CaseFormHelper.constructCaseRecord(params);  
            Case existingCase = [select Id, Support_Address__c from Case where CaseNumber = :ticketNumber];
            
            updatedCase.Id = existingCase.Id;
            Id queueId = CaseFormHelper.getKeywordRelatedQueue(
                updatedCase.Subject + ' ' + updatedCase.Description, existingCase.Support_Address__c);
            
            updatedCase.OwnerId = (queueId != null) ? queueId : Constants.QUEUE_ID_CCS_GENERAL;
            
            update updatedCase;
			List<Case> caseList = new List<Case>();
			if(updatedCase.custom_reason_for_contact__c != null &&(updatedCase.custom_reason_for_contact__c == 'Injury' || updatedCase.custom_reason_for_contact__c == 'Property Damage' ||
                                                                   updatedCase.custom_reason_for_contact__c == 'Recall' )){
                                                                      caseList.add(updatedCase);
                                                                       CaseTriggerHandler.handleCriticalCase(caseList); 
                                                                   }
            CaseFormHelper.insertAttachments(updatedCase.Id, params);
            
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.CONFIRM,
                'Thank you! Your case has been updated successfully.'
            ));
            
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
}