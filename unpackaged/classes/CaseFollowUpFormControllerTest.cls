@isTest
private class CaseFollowUpFormControllerTest {

    @testSetup
    static void setupTestData() {
        Case testCase = new Case(
            Subject = 'Test Case',
            SuppliedName = 'Jane Doe',
            SuppliedEmail = 'janedoe@example.com',
            Status = 'Open'
        );
        insert testCase;
    }

    @isTest
    static void testMissingTicketParam() {
        Test.startTest();
        ApexPages.currentPage().getParameters().clear();
        new CaseFollowUpFormController();
        Test.stopTest();
    }

    @isTest
    static void testInvalidBase64Ticket() {
        Test.startTest();
        ApexPages.currentPage().getParameters().put('ticket', 'invalidbase64==');
        new CaseFollowUpFormController();
        Test.stopTest();
    }

    @isTest
    static void testValidTicketInitialization() {
        Case c = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        String encodedTicket = EncodingUtil.base64Encode(Blob.valueOf(c.CaseNumber));
        Test.startTest();
        ApexPages.currentPage().getParameters().put('ticket', encodedTicket);
        new CaseFollowUpFormController();
        Test.stopTest();
    }

    @isTest
    static void testSubmitForm() {
        Case c = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        String encodedTicket = EncodingUtil.base64Encode(Blob.valueOf(c.CaseNumber));

        ApexPages.currentPage().getParameters().put('ticket', encodedTicket);
        ApexPages.currentPage().getParameters().put('Subject', 'New Subject');
        ApexPages.currentPage().getParameters().put('Description', 'Updated description');
        ApexPages.currentPage().getParameters().put('Product__c', 'Some Product');
        ApexPages.currentPage().getParameters().put('Brand__c', 'Sample Brand');
        ApexPages.currentPage().getParameters().put('Model__c', 'Sample Model');

        Test.startTest();
        CaseFollowUpFormController controller = new CaseFollowUpFormController();
        controller.submitForm();
        Test.stopTest();
    }

    @isTest
    static void testRemoteActions() {
        Test.startTest();
        CaseFollowUpFormController.getBrandOptions();
        CaseFollowUpFormController.getReasonForContactOptions();
        CaseFollowUpFormController.getModelMap('TestBrand');
        Test.stopTest();
    }
}