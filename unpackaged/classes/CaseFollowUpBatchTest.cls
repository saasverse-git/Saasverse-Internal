@isTest
private class CaseFollowUpBatchTest {
    
    static testmethod void testBatchWithFollowUpsAndClosure() {
        // Prepare test data
        List<Case> testCases = new List<Case>();
        
        // Case needing first follow up (Created 2 days ago, no First_Follow_Up_Sent_On__c)
        Case caseFirstFollow = new Case(
            Origin = 'Email',
            Status = 'New',
            SuppliedEmail = 'test1@example.com',
            Support_Address__c = 'test address',
            CreatedDate = DateTime.now().addDays(-2),
            Test_Created_Date__c = DateTime.now().addDays(-2)
        );
        // Case needing closure (First_Follow_Up_Sent_On__c 3 days ago)
        Case caseClosure = new Case(
            Origin = 'Web',
            Status = 'New',
            SuppliedEmail = 'test2@example.com',
            Support_Address__c = 'test address',
            CreatedDate = DateTime.now().addDays(-5),
            Test_Created_Date__c = DateTime.now().addDays(-5),
            First_Follow_Up_Sent_On__c = DateTime.now().addDays(-3)
        );
        testCases.addAll(new List<Case>{ caseFirstFollow, caseClosure });
        
        // Insert test cases
        insert testCases;
        
        // Get their IDs
        Set<Id> testCaseIds = new Set<Id>();
        for (Case c : testCases) {
            testCaseIds.add(c.Id);
        }

        // Mock Constants if needed (only if not already present)
        // Otherwise, make sure Constants.EMAIL_TEMPLATE_ID_CASE_FOLLOWUP_REMINDER, etc. exist
        // Use Custom Metadata or create dummy values in Constants

        // Start test context
        Test.startTest();
        
        // Run the batch (using constructor with IDs)
        CaseFollowUpBatch batchWithIds = new CaseFollowUpBatch(testCaseIds);
        Database.executeBatch(batchWithIds, 200);
        
        // Also test schedulable part
        CaseFollowUpBatch schedulableBatch = new CaseFollowUpBatch();
        schedulableBatch.execute(null);
        
        Test.stopTest();

        // Assert updates happened
        List<Case> updatedCases = [SELECT Id, First_Follow_Up_Sent_On__c, Status FROM Case WHERE Id IN :testCaseIds];
        Boolean foundFollowUpSent = false;
        Boolean foundClosed = false;

        for (Case c : updatedCases) {
            if (c.First_Follow_Up_Sent_On__c != null) {
                foundFollowUpSent = true;
            }
            if (c.Status == 'Closed - no cm response') {
                foundClosed = true;
            }
        }

        System.assert(foundFollowUpSent, 'Should have sent first follow up and updated field');
        System.assert(foundClosed, 'Should have closed the case after final email');
    }

    static testmethod void testBatchWithoutIds() {
        // Prepare a case matching the valid origin
        Case testCase = new Case(
            Origin = 'Email',
            Status = 'New',
            SuppliedEmail = 'test3@example.com',
            Support_Address__c = 'test address',
            CreatedDate = DateTime.now().addDays(-2),
            Test_Created_Date__c = DateTime.now().addDays(-2)
        );
        insert testCase;

        Test.startTest();
        // Run batch without passing IDs
        Database.executeBatch(new CaseFollowUpBatch(), 200);
        Test.stopTest();

        // Confirm follow-up sent
        testCase = [SELECT Id, First_Follow_Up_Sent_On__c FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals(null, testCase.First_Follow_Up_Sent_On__c, 'Follow up should have been sent');
    }
}