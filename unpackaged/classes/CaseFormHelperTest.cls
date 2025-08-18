@isTest
private class CaseFormHelperTest {

    @testSetup
    static void setupTestData() {
        // Insert test queue
        insert new Group(Name = 'Test Queue', Type = 'Queue');

        // Insert test product
        insert new Product__c(
            Brand__c = 'Baby Cakes',
            Product_Line__c = 'AFTO',
            Model_Number__c = 'TestModel',
            Division__c = 'Appliance Home',
            Product_Category__c = 'Cooking'
        );
    }

    @isTest
    static void testGetProductId() {
        CaseFormHelper.getProductId('TestBrand', 'TestLine', 'TestModel');
        CaseFormHelper.getProductId('InvalidBrand', 'InvalidLine', 'InvalidModel');
    }

    @isTest
    static void testConstructCaseRecord() {
        Map<String, String> params = new Map<String, String>{
            'name' => 'Test User',
            'email' => 'test@example.com',
            'phone' => '1234567890',
            'subject' => 'Test Subject',
            'description' => 'This is a test',
            'Reason_for_Contact__c' => 'Support',
            'Brand__c' => 'TestBrand',
            'Raw_Product_Line__c' => 'TestLine',
            'Raw_Model_Number__c' => 'TestModel'
        };
        CaseFormHelper.constructCaseRecord(params);
    }

    @isTest
    static void testInsertAttachments() {
        Case c = new Case(Subject = 'Attachment Test', Status = 'New', Origin = 'Email');
        insert c;

        // One valid file
        Map<String, String> params = new Map<String, String>{
            'fileName0' => 'test.txt',
            'fileContent0' => EncodingUtil.base64Encode(Blob.valueOf('test content'))
        };
        CaseFormHelper.insertAttachments(c.Id, params);

        // No file (skip loop)
        Map<String, String> noParams = new Map<String, String>();
        CaseFormHelper.insertAttachments(c.Id, noParams);
    }

    @isTest
    static void testGetModelMap() {
        CaseFormHelper.getModelMap('TestBrand');
        CaseFormHelper.getModelMap('InvalidBrand');
    }

    @isTest
    static void testGetReasonForContactOptions() {
        CaseFormHelper.getReasonForContactOptions();
    }

    @isTest
    static void testGetBrandOptions() {
        CaseFormHelper.getBrandOptions();
    }

    @isTest
    static void testGetKeywordRelatedQueue() {
        // Since we can't insert custom metadata, and CaseUtility is not stubbed,
        // this test will only execute the `return null` path.
        CaseFormHelper.getKeywordRelatedQueue('This is a test email', 'dummy@example.com');
    }
}