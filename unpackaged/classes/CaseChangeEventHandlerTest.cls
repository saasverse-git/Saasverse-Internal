@isTest
private class CaseChangeEventHandlerTest {

    @isTest
    static void testHandleAfterInsert_CreatePath() {
        // Case with SuppliedEmail to trigger contact linking
        Test.enableChangeDataCapture();
        Case c = new Case(
            Subject = 'Create Event Case',
            SuppliedEmail = 'createuser@example.com',
            SuppliedName = 'John Create'
        );
        insert c;
        Test.getEventBus().deliver();

        Set<Id> caseIds = new Set<Id>{c.Id};

        Test.startTest();
        CaseChangeEventHandler.handleAfterInsert_simulated(caseIds, 'CREATE', null);
        Test.stopTest();

        Case updated = [SELECT ContactId FROM Case WHERE Id = :c.Id];
        //System.assertNotEquals(null, updated.ContactId, 'Contact should be linked');
    }

    @isTest
    static void testHandleAfterInsert_UpdatePath() {
        // Create User for Accepted_By__c
        User u = new User(
            FirstName = 'Agent',
            LastName = 'User',
            Email = 'updateuser@example.com',
            Username = 'updateuser' + System.currentTimeMillis() + '@example.com.test',
            Alias = 'uuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        Case c = new Case(
            Subject = 'Update Event Case',
            SuppliedEmail = u.Email,
            Status = 'Open',
            Accepted_By__c = u.Id
        );
        insert c;

        Map<Id, List<String>> changedFieldsMap = new Map<Id, List<String>>();
        changedFieldsMap.put(c.Id, new List<String>{'SuppliedEmail', 'Status'});

        Test.startTest();
        CaseChangeEventHandler.handleAfterInsert_simulated(new Set<Id>{c.Id}, 'UPDATE', changedFieldsMap);
        Test.stopTest();

        Case updated = [SELECT ContactId, First_Response_Time_hrs__c FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, updated.ContactId, 'Contact should remain linked');
        //System.assertNotEquals(null, updated.First_Response_Time_hrs__c, 'First Response should be calculated');
    }

    @isTest
    static void testHandleAfterInsert_UpdateForResolution() {
        Case c = new Case(
            Subject = 'Closed Event Case',
            Status = 'Closed'
        );
        insert c;

        Map<Id, List<String>> changedFieldsMap = new Map<Id, List<String>>();
        changedFieldsMap.put(c.Id, new List<String>{'Status'});

        Test.startTest();
        CaseChangeEventHandler.handleAfterInsert_simulated(new Set<Id>{c.Id}, 'UPDATE', changedFieldsMap);
        Test.stopTest();

        Case updated = [SELECT Case_Resolution_Time__c FROM Case WHERE Id = :c.Id];
        //System.assertNotEquals(null, updated.Case_Resolution_Time__c, 'Resolution time should be calculated');
    }

    @isTest
    static void testHandleAfterInsert_NonMatchField() {
        Case c = new Case(Subject = 'No Field Match', SuppliedEmail = 'nomatch@example.com');
        insert c;

        Map<Id, List<String>> changedFieldsMap = new Map<Id, List<String>>();
        changedFieldsMap.put(c.Id, new List<String>{'OtherField'});

        Test.startTest();
        CaseChangeEventHandler.handleAfterInsert_simulated(new Set<Id>{c.Id}, 'UPDATE', changedFieldsMap);
        Test.stopTest();

        // Just check no error
        //System.assert(true, 'No exception should occur');
    }
}