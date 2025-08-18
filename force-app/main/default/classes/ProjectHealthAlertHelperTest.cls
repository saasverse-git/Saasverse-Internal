@isTest
public class ProjectHealthAlertHelperTest {
    
    @testSetup
    static void setupData() {
        // Create a test user to match the filter 'Name = Test User'
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
    }

    static Project__c createProject(String name) {
        Project__c project = new Project__c(Name = name);
        insert project;
        return project;
    }

    static void insertHealthUpdates(Project__c project, List<String> statuses) {
        List<Project_Health_Update__c> updates = new List<Project_Health_Update__c>();
        Date d = Date.today();
        for (Integer i = 0; i < statuses.size(); i++) {
            updates.add(new Project_Health_Update__c(
                Project__c = project.Id,
                Health_Status__c = statuses[i]
                //Update_Date__c = d.addDays(-i)
            ));
        }
        insert updates;
    }

    @isTest
    static void testGreenToRedAlert() {
        Project__c project = createProject('GreenToRed Project');
        insertHealthUpdates(project, new List<String>{'RED', 'GREEN'});

        Test.startTest();
        ProjectHealthAlertHelper.processHealthAlerts(new Set<Id>{project.Id});
        Test.stopTest();
    }

    @isTest
    static void testThreeRedAlert() {
        Project__c project = createProject('ThreeRed Project');
        insertHealthUpdates(project, new List<String>{'RED', 'RED', 'RED'});

        Test.startTest();
        ProjectHealthAlertHelper.processHealthAlerts(new Set<Id>{project.Id});
        Test.stopTest();
    }

    @isTest
    static void testFiveOrangeAlert() {
        Project__c project = createProject('FiveOrange Project');
        insertHealthUpdates(project, new List<String>{'ORANGE', 'ORANGE', 'ORANGE', 'ORANGE', 'ORANGE'});

        Test.startTest();
        ProjectHealthAlertHelper.processHealthAlerts(new Set<Id>{project.Id});
        Test.stopTest();
    }

    @isTest
    static void testFourOrangeOneRedAlert() {
        Project__c project = createProject('Mixed Project');
        insertHealthUpdates(project, new List<String>{'ORANGE', 'ORANGE', 'ORANGE', 'ORANGE', 'RED'});

        Test.startTest();
        ProjectHealthAlertHelper.processHealthAlerts(new Set<Id>{project.Id});
        Test.stopTest();
    }

    @isTest
    static void testNoTriggerCondition() {
        Project__c project = createProject('Safe Project');
        insertHealthUpdates(project, new List<String>{'GREEN', 'GREEN', 'GREEN', 'ORANGE', 'GREEN'});

        Test.startTest();
        ProjectHealthAlertHelper.processHealthAlerts(new Set<Id>{project.Id});
        Test.stopTest();
    }
}