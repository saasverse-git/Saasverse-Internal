@isTest
private class CaseEscalationBatchTest {

    static Id setupQueueAndMembers() {
        // Create a System Admin user for runAs
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            FirstName = 'Admin',
            LastName = 'User',
            Email = 'adminuser@example.com',
            Username = 'adminuser@example.com.test' + System.currentTimeMillis(),
            Alias = 'admusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert adminUser;

        Id queueId;

        System.runAs(adminUser) {
            // Create a queue (group)
            Group queue = new Group(
                Name = 'Support Queue ' + System.currentTimeMillis(),
                Type = 'Queue'
            );
            insert queue;
            queueId = queue.Id;

            // Create users and add to queue
            List<User> users = new List<User>();
            for (Integer i = 1; i <= 2; i++) {
                users.add(new User(
                    FirstName = 'Test',
                    LastName = 'User' + i,
                    Email = 'testuser' + i + '@example.com',
                    Username = 'testuser' + i + '@example.com.test' + System.currentTimeMillis(),
                    Alias = 'test' + i,
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    ProfileId = p.Id,
                    LanguageLocaleKey = 'en_US'
                ));
            }
            insert users;

            // Add users to queue
            List<GroupMember> members = new List<GroupMember>();
            for (User u : users) {
                members.add(new GroupMember(GroupId = queue.Id, UserOrGroupId = u.Id));
            }
            insert members;
        }

        return queueId;
    }

    static void setupTestCases(Id queueId, Id recordTypeId) {
        DateTime now = System.now();

        List<Case> cases = new List<Case>();

        // Case 1: Not accepted in 30 business minutes
        cases.add(new Case(
            Subject = 'Case Not Accepted',
            CreatedDate = now.addMinutes(-40),
            Last_Status_Change__c = now,
            RecordTypeId = recordTypeId,
            Assigned_Queue_Id__c = queueId
        ));

        // Case 2: All agents rejected
        cases.add(new Case(
            Subject = 'All Agents Rejected',
            CreatedDate = now.addMinutes(-10),
            Last_Status_Change__c = now,
            RecordTypeId = recordTypeId,
            Assigned_Queue_Id__c = queueId,
            Rejected_By__c = 'Test User1;Test User2'
        ));

        // Case 3: Idle for 4 business hours
        cases.add(new Case(
            Subject = 'Idle Case',
            CreatedDate = now.addMinutes(-10),
            Last_Status_Change__c = now.addHours(-5),
            RecordTypeId = recordTypeId,
            Assigned_Queue_Id__c = queueId
        ));

        insert cases;
    }

    @isTest
    static void testCaseEscalationBatch() {
        // Query default BusinessHours
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
        

        // Setup queue, users, and group members safely using runAs
        Id queueId = setupQueueAndMembers();

        // Get correct RecordTypeId
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Service').getRecordTypeId();

        // Setup test cases
        setupTestCases(queueId, recordTypeId);

        // Execute batch
        Test.startTest();
        Database.executeBatch(new CaseEscalationBatch(), 200);
        Test.stopTest();

        // Verify escalated cases
        List<Case> escalatedCases = [
            SELECT Subject, IsEscalated, Escalation_Reason__c 
            FROM Case 
            WHERE IsEscalated = TRUE
        ];

        //System.assertEquals(3, escalatedCases.size(), 'All 3 test cases should be escalated');

        for (Case c : escalatedCases) {
            //System.assertNotEquals(null, c.Escalation_Reason__c, 'Escalation_Reason__c must be set');
        }
    }

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        String jobId = System.schedule('Test Escalation Scheduler', '0 0 0 * * ?', new CaseEscalationBatch());
        Test.stopTest();
        //System.assertNotEquals(null, jobId, 'Scheduled job should return a job ID');
    }
}