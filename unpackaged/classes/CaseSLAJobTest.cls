@isTest
private class CaseSLAJobTest {

    @testSetup
    static void setup() {
        // Get Default Business Hours (must exist in org)
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

        // Get RecordType for Case
        RecordType rt = [SELECT Id FROM RecordType 
                         WHERE SObjectType = 'Case' 
                         AND DeveloperName = 'Customer_Service' 
                         LIMIT 1];

        // Use 10 days ago to ensure >24 business hours
        DateTime oldDate = System.now().addDays(-10);

        List<Case> testCases = new List<Case>{
            new Case(
                Subject = 'Unassigned > 24 Hrs',
                RecordTypeId = rt.Id,
                CreatedDate = oldDate,
                SLA_Breached__c = false
            ),
            new Case(
                Subject = 'Stale Status > 24 Hrs',
                RecordTypeId = rt.Id,
                CreatedDate = System.now(),
                Accepted_By__c = UserInfo.getUserId(),
                Last_Status_Change__c = oldDate,
                SLA_Breached__c = false
            ),
            new Case(
                Subject = 'Non-Breached',
                RecordTypeId = rt.Id,
                CreatedDate = System.now(),
                Accepted_By__c = UserInfo.getUserId(),
                Last_Status_Change__c = System.now(),
                SLA_Breached__c = false
            )
        };

        insert testCases;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new CaseSLAJob(), 200);
        Test.stopTest();

        // Optionally verify that cases were updated:
        List<Case> updatedCases = [
            SELECT SLA_Breached__c, SLA_Breach_Timestamp__c, SLA_Breach_Type__c 
            FROM Case 
            WHERE Subject IN ('Unassigned > 24 Hrs', 'Stale Status > 24 Hrs')
        ];

        // You can uncomment assertions if needed
        // System.debug(updatedCases);
    }

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2050';
        System.schedule('Test_SLA_Job', cronExp, new CaseSLAJob());
        Test.stopTest();
    }
}