@isTest
public class CaseTriggerHandlerTest {

    // Step 1: Mock class (no @isTest here!)
    private class TremendousRewardMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"order":{"rewards":[{"delivery":{"link":"https://fake-reward-link.example.com"}}]}}');
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup
    static void setup() {
        // Insert Product__c for keyword validation logic
        insert new Product__c(
            Brand__c = 'REMINGTON',
            Product_Line__c = 'Pasta Makers',
            Model_Number__c = 'MNUM',
            Division__c = 'Appliance Home',
            Product_Category__c = 'Cooking'
        );

        	
        Case testCase = new Case(
            SuppliedName = 'Test User',
            SuppliedEmail = 'testuser@example.com',
            Model__c = 'DUAF-005',  // Should map to '98' denomination
            Status = 'New',
            Subject = 'Test reward case'
        );
        insert testCase;
        // Insert Groups (Queues)
        //
         /*
        List<Group> queues = new List<Group>{
            new Group(Name = 'CCS Generals', DeveloperName = 'CCS_Generals', Type = 'Queue'),
            new Group(Name = 'Testing Queue for Skill Baseds', DeveloperName = 'Testing_queue_for_Skill_Baseds', Type = 'Queue')
        };
        insert queues;
        */
        
         Group testGroup = new Group(
            Name = 'Testing queue for Skill Based',
            Type = 'Queue'
        );
        insert testGroup;
        
        
        

        // Create a user to be added to the group
        User testUser = new User(
            FirstName = 'Testing',
            LastName = 'User',
            Email = 'test.user@example.com',
            Username = 'testing.user@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            Alias = 'tuser',
            CommunityNickname = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;

		//Test.StartTest();
        // Create a GroupMember record to add the user to the group
        System.runAs(testUser){
            QueueSobject queueSobject = new QueueSobject(
            QueueId = testGroup.Id,
            SObjectType = 'Case'  // This is REQUIRED for assigning Case to the queue
        );
        insert queueSobject;
            GroupMember gm = new GroupMember(
                GroupId = testGroup.Id,
                UserOrGroupId = testUser.Id
            );
            insert gm;
        }
     //   Test.StopTest();
        
        

        
        Contact con = new Contact();
        con.lastName = 'testRec';
        insert con;
        
        /* dml not allowed on Community
        community com= new community();
        com.Name='Spectrum CSAT Form';
        insert com;
		*/
    }

    @isTest
    static void testCaseTriggerHandlerFullFlow() {
        // Step 2: Register mock
        Test.setMock(HttpCalloutMock.class, new TremendousRewardMock());
        
        Contact con = [Select id from contact where lastname = 'testRec' limit 1];
        
        
        // Get RecordType
        RecordType recallRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Recall_Registration' LIMIT 1];

        Test.startTest();

        // BEFORE INSERT & AFTER INSERT
        Case c1 = new Case(
            Subject = 'Recall',
            Description = 'Recall with keyword',
            Origin = 'Email',
            Status = 'New - Awaiting Review',
            SuppliedEmail='test@gmail.com',
            SuppliedName='testing',
            ContactId = con.Id
        );
        insert c1;

        Case c = new Case(Subject = 'Attachment Test', Status = 'New', Origin = 'Email');
        insert c;

        // BEFORE UPDATE - trigger Last_Status_Change__c
        c1.Status = 'Closed';
        c1.Is_Refund_Request_Approved__c=true;
        //c1.SuppliedEmail='test@gmail.com';
        //c1.SuppliedName='testing';
        update c1;

        // Refund approval flow
        Case c2 = new Case(
            Subject = 'Refund',
            Description = 'Test refund case',
            Brand__c = 'Remington Products',
            Origin = 'Web',
            Raw_Product_Line__c = 'PLINE',
            Raw_Model_Number__c = 'DUAF-005', // must be in your denomination map
            SuppliedName = 'Refund User',
            SuppliedEmail = 'refund@example.com',
            Is_Refund_Request_Approved__c = false
        );
        insert c2;

        c2.Is_Refund_Request_Approved__c = true;
        update c2;

        // Additional critical case reason
        Case c3 = new Case(
            Subject = 'Class Action',
            Description = 'Legal',
            Brand__c = 'Remington Products',
            Origin = 'Web',
            Raw_Product_Line__c = 'PLINE',
            Raw_Model_Number__c = 'MNUM',
            custom_reason_for_contact__c = 'Class_Action_Lawsuit'
        );
        insert c3;

        Test.stopTest();
    }

    @isTest
    public static void handleCriticalCaseTest() {
        
        User u = TestUtils.createTestUser();
        insert u;
        
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            RelatedRecordId = u.Id
        );
        insert sr;
        
        // Create Skill and ServiceResourceSkill
        Id mySkill = [SELECT Id FROM Skill WHERE DeveloperName = 'PIR' LIMIT 1].Id;

        ServiceResourceSkill ser = new ServiceResourceSkill(
            ServiceResourceId = sr.Id,
            EffectiveStartDate = System.today(),
            SkillId = mySkill
        );
        insert ser;
        
        Test.startTest();

        List<Case> caseRec = new List<Case>();

        Case case1 = new Case(
            Subject = 'Test class subject 1',
            Description = 'Legal',
            Brand__c = 'Remington Products',
            Origin = 'Web',
            Raw_Product_Line__c = 'PLINE',
            Raw_Model_Number__c = 'MNUM',
            custom_reason_for_contact__c = 'Property Damage',
            SuppliedEmail='test@gmail.com',
            SuppliedName='Testing Case'
        );
        insert case1;

        Case case2 = new Case(
            Subject = 'Testing class Subject 1',
            Description = 'Legal',
            Brand__c = 'Remington Products',
            Origin = 'Web',
            Raw_Product_Line__c = 'PLINE',
            Raw_Model_Number__c = 'MNUM',
            custom_reason_for_contact__c = 'Property Damage'
        );
        insert case2;

        caseRec.add(case1);
        caseRec.add(case2);

        // Call method directly
        CaseTriggerHandler.handleCriticalCase(caseRec);

        Test.stopTest();
    }
    
    @isTest
    public static void assignToQueueTest(){
        
        Test.startTest();
        
        List<Case> caseRec = new List<Case>();

        Case case1 = new Case(
            Subject = 'Test class subject 1',
            Description = 'Legal',
            Brand__c = 'Remington Products',
            Origin = 'Web',
            Raw_Product_Line__c = 'PLINE',
            Raw_Model_Number__c = 'MNUM',
            custom_reason_for_contact__c = 'Property Damage',
            SuppliedEmail='test@gmail.com',
            SuppliedName='Testing Case'
        );
        //insert case1;

        Case case2 = new Case(
            Subject = 'Testing class Subject 1',
            Description = 'Legal',
            Brand__c = 'Remington Products',
            Origin = 'Web',
            Raw_Product_Line__c = 'PLINE',
            Raw_Model_Number__c = 'MNUM',
            custom_reason_for_contact__c = 'Property Damage'
        );
        //insert case2;

        caseRec.add(case1);
        caseRec.add(case2);

        // Call method directly
        CaseTriggerHandler.handleCriticalCase(caseRec);

        Test.stopTest();
    }
    
}