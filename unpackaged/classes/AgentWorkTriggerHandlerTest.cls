@isTest
private class AgentWorkTriggerHandlerTest {
	
    @testSetup
    static void setupTestData() {
        // Create test User (agent)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User agent = new User( 
            Username = 'agent_test@example.com.test',
            Alias = 'atest',
            Email = 'agent_test@example.com',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            ProfileId = p.Id,
            LastName = 'test'
        );
        insert agent;

        // Create a case or work item
        Case c = new Case(Subject = 'Test AgentWork Trigger', Status = 'New', Origin = 'Email');
        insert c;

        // Query a real ServiceChannel for Case
        ServiceChannel sc = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'Case_Routing' LIMIT 1];

        // Simulate PendingServiceRouting (not always directly creatable in test context)
        // Normally created by Omni-Channel, so skip it or mock the ID
        // We'll create a dummy Id for demonstration
        Id dummyRoutingId = Schema.SObjectType.PendingServiceRouting.getKeyPrefix() + '000000000000001';

        // Insert AgentWork
        /*
        AgentWork work = new AgentWork(
            ServiceChannelId = sc.Id,
            WorkItemId = c.Id,
            UserId = agent.Id,
            PendingServiceRoutingId = dummyRoutingId
        );
        insert work;
		*/
        
    }

    @isTest
    static void testHandlerWithRejectedStatus() {
        User agent = [SELECT Id, Name FROM User LIMIT 1];
        Case c = [SELECT Id FROM Case LIMIT 1];
Integer randomInt = Math.abs(Crypto.getRandomInteger());
String paddedRandom = String.valueOf(randomInt).leftPad(15, '0');
Id fakeId = (Id)('0Bz' + paddedRandom);
        // Fake old AgentWork record with old status
        AgentWork oldAw = new AgentWork(
            Id = fakeId,
            WorkItemId = c.Id,
            UserId = agent.Id
        );
        //oldAw.put('Status', 'DeclinedOnPushTimeout'); // use dynamic method to bypass read-only

        // Fake new AgentWork record with new status
        AgentWork newAw = oldAw.clone(false, false, false, false);
        //newAw.put('Status', 'DeclinedOnPushTimeout');
		List<List<AgentWork>> agentworkRecList= new List<List<AgentWork>>();
        List<AgentWork> agentWorkList = new List<AgentWork>{newAw , oldAw};
        agentworkRecList.add(agentWorkList);
        Test.startTest();
            AgentWorkTriggerHandler.afterUpdate(agentworkRecList);
        Test.stopTest();
    }

    @isTest
    static void testHandlerWithAcceptedStatus() {
        User agent = [SELECT Id FROM User LIMIT 1];
        Case c = [SELECT Id FROM Case LIMIT 1];
        
Integer randomInt = Math.abs(Crypto.getRandomInteger());
String paddedRandom = String.valueOf(randomInt).leftPad(15, '0');
Id fakeId = (Id)('0Bz' + paddedRandom);

        // Fake old AgentWork record with old status
        AgentWork oldAw = new AgentWork(
            Id = fakeId,
            WorkItemId = c.Id,
            UserId = agent.Id
        );
        //oldAw.put('Status', 'DeclinedOnPushTimeout'); // dynamic put for read-only field

        // Fake new AgentWork with Opened status
        AgentWork newAw = oldAw.clone(false, false, false, false);
        //newAw.put('Status', 'DeclinedOnPushTimeout');
		
        List<List<AgentWork>> agentworkRecList= new List<List<AgentWork>>();
        List<AgentWork> agentWorkList = new List<AgentWork>{newAw , oldAw};
        agentworkRecList.add(agentWorkList);
        
        Test.startTest();
            AgentWorkTriggerHandler.afterUpdate(agentworkRecList);
        Test.stopTest();
    }


}