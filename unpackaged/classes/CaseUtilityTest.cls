@isTest
public class CaseUtilityTest {
    
    @testSetup
    public static void setupData() {
        // Create sample cases for use in tests
        List<Case> caseList = new List<Case>();
        for (Integer i = 0; i < 2; i++) {
            caseList.add(new Case(
                Subject = 'Test Case ' + i,
                Description = 'Testing case utility logic',
                Status = i == 0 ? 'New' : 'Working'
            ));
        }
        insert caseList;

        // Update one to simulate status change for CaseHistory
        Case c = caseList[0];
        c.Status = 'Open';
        update c;
        
    }

    @isTest
    public static void test_isValidKeywordFound() {
        List<String> keywords = new List<String>{ 'abc', 'xyz' };
        String content1 = 'Hello xyz customer';
        String content2 = 'Nothing special here';

        Boolean result1 = CaseUtility.isValidKeywordFound(keywords, content1);
        Boolean result2 = CaseUtility.isValidKeywordFound(keywords, content2);
    }

    @isTest
    public static void test_insertLog() {
        // Just validate that it runs without error
        CaseUtility.insertLog('TestCause', 'TestMessage', 'TestContext');
    }

    @isTest
    public static void test_getManagerEmails() {
        // Assumes a group with DeveloperName = 'Manager_Queue' and members exists in org
        Test.startTest();
        Set<String> emails = CaseUtility.getManagerEmails();
        Test.stopTest();
    }

    @isTest
    public static void test_calculateBusinessHoursBetweenStatuses() {
        
        Id defaultBH = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1].Id;
        Case testCase = [SELECT Id FROM Case WHERE Status = 'Open' LIMIT 1];
        
        Case caseRec= new Case();
        caseRec.Subject = 'Subject Cases';
        caseRec.Description = 'Testing case utility logic';
        caseRec.Status = 'Working';
        insert caseRec;
        
        caseRec.Status='New';
        update caseRec;
        
        
       
        
        CaseHistory caseHis= new CaseHistory();
        caseHis.CaseId=caseRec.Id;
        caseHis.Field='Status';
        insert caseHis;


        Test.StartTest();
		System.debug('caseHistory-->'+[SELECT CaseId, OldValue, NewValue, CreatedDate
            FROM CaseHistory
            WHERE CaseId = :caseRec.Id AND Field = 'Status'
            ORDER BY CreatedDate ASC]);
        System.debug('caseHistory all=>'+[SELECT CaseId, OldValue, NewValue, CreatedDate,Field
            FROM CaseHistory]);
        
        Map<Id, Decimal> result = CaseUtility.calculateBusinessHoursBetweenStatuses(
            new Set<Id>{ caseRec.Id }, 'New', 'Working', defaultBH
        );
        Test.StopTest();
    }

    @isTest
    public static void test_getCaseStatusHistory() {
        Case testCase = [SELECT Id FROM Case WHERE Status = 'Open' LIMIT 1];
        Map<Id, List<CaseHistory>> historyMap = CaseUtility.getCaseStatusHistory(new Set<Id>{ testCase.Id });
    }

    @isTest
    public static void test_sendSummaryEmail_SLA() {
        Set<String> recipients = new Set<String>{ 'test@example.com' };
        Case testCase = [SELECT Id, CaseNumber, Subject, CreatedDate, Last_Status_Change__c,
                         SLA_Breach_Type__c, Owner.Name FROM Case LIMIT 1];

        List<Case> testCases = new List<Case>{ testCase };
        Test.startTest();
        CaseUtility.sendSummaryEmail(testCases, recipients, 'SLA');
        Test.stopTest();
    }

    @isTest
    public static void test_sendSummaryEmail_Escalation() {
        Set<String> recipients = new Set<String>{ 'test2@example.com' };
        Case testCase = [SELECT Id, CaseNumber, Subject, Description, CreatedDate, Rejected_By__c,
                         Escalation_Reason__c, Escalation_Timestamp__c FROM Case LIMIT 1];

        List<Case> testCases = new List<Case>{ testCase };
        Test.startTest();
        CaseUtility.sendSummaryEmail(testCases, recipients, 'Escalation');
        Test.stopTest();
    }
}