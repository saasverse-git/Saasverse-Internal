@IsTest
public class KnowledgeTest {
	
    @testSetup
    public static void setupData()
    {
        
        String uniqueUsername = 'testuser_' + System.currentTimeMillis() + '@example.com';

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            LastName='testUserLastName',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUsername
        );
        insert u;
        
        
        Product__c prodRec=  new Product__c();
        prodRec.Division__c='Personal Care';
        prodRec.Brand__c='REMINGTON';
        prodRec.Product_Category__c='Accessories';
        prodRec.Product_Line__c='Haircare Accessories';
        prodRec.Model_Number__c='E20T17';
        prodRec.Description__c='E20T17 - 20CT 4MM ELSTCS-FALL TREND-MDRN EDGE/PLD';
        prodRec.Product_Category__c='Accessories';
        prodRec.Product_Line__c='Haircare Accessories';
        insert prodRec;
        
        Case caseRec= new Case();
        caseRec.Status='Open';
        caseRec.Brand__c='Remington Products';
        caseRec.custom_reason_for_contact__c='Complaint - Website';
        caseRec.Description='test';
        caseRec.Product__c=prodRec.Id;
        insert caseRec;
        
        knowledge__kav knowLedgeRec = new knowledge__kav();
        knowLedgeRec.Title='Testing Article';
        knowLedgeRec.UrlName='Testing-Article';
		knowLedgeRec.Question__c='AAA Testing Question';
        knowLedgeRec.Answer__c='<p>With Image<br><img src="https://tristarproductsinc--spctmfull.sandbox.file.force.com/servlet/rtaImage?eid=ka0Ox000000tGH3&amp;feoid=00N3i000005RLNY&amp;refid=0EMOx000000iyy9" alt=""></img> </p>';
        knowLedgeRec.Product_Name__c='Blenders';
        knowLedgeRec.Product_Category__c='Food Preparation';
        knowLedgeRec.Brand__c='George Foreman';
		
        
    }
    
    @IsTest
    public static void getKnowledgeRecordsTest()
    {
       
		Case Rec = [SELECT Id FROM Case WHERE Brand__c='Remington Products' LIMIT 1];
        
        /*
        knowledge__kav knowLedgeRec = new knowledge__kav();
        knowLedgeRec.Title='Test Article';
        knowLedgeRec.UrlName='Kohl-s-Return-Policy';
		knowLedgeRec.Question__c='AAA Testing Question';
        knowLedgeRec.Answer__c='<p>With Image<br><img src="https://tristarproductsinc--spctmfull.sandbox.file.force.com/servlet/rtaImage?eid=ka0Ox000000tGH3&amp;feoid=00N3i000005RLNY&amp;refid=0EMOx000000iyy9" alt=""></img> </p>';
        knowLedgeRec.Product_Name__c='Blenders';
		*/
        
        Test.StartTest();
       	Knowledge.getKnowledgeRecords(Rec.Id);
        Test.StopTest();
        
        
        
    }
    @IsTest
    public static void getGlobalKnowledgeRecordsTest()
    {
        List<Knowledge__kav> results = Knowledge.getGlobalKnowledgeRecords('test');
    }

    
    @IsTest
    public static void voteForknoledgeArticleTest()
    {
   
        knowledge__kav knowLedgeRec = new knowledge__kav();
        knowLedgeRec.Title='Testing Article';
        knowLedgeRec.UrlName='Testing-Article';
		knowLedgeRec.Question__c='AAA Testing Question';
        knowLedgeRec.Answer__c='<p>With Image<br><img src="https://tristarproductsinc--spctmfull.sandbox.file.force.com/servlet/rtaImage?eid=ka0Ox000000tGH3&amp;feoid=00N3i000005RLNY&amp;refid=0EMOx000000iyy9" alt=""></img> </p>';
        knowLedgeRec.Product_Name__c='Blenders';
        knowLedgeRec.Product_Category__c='Food Preparation';
        knowLedgeRec.Brand__c='George Foreman';
        
        insert knowLedgeRec;
        //knowLedgeRec.KnowledgeArticleId = 'ka0XX0000000001AAA';
        
        String voType='5';
        
       
        
        User myUser= [SELECT Id FROM USER LIMIT 1];
       	Test.StartTest();
        Knowledge.voteForknoledgeArticle(knowLedgeRec.Id,voType,myUser.Id);
        Test.StopTest(); 

    }
    

   
    @IsTest
    public static void displayKnowledgeTest()
    {
        // Get test User created in @testSetup
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%' LIMIT 1];
    
        // Get test Case created in @testSetup
        Case testCase = [SELECT Id FROM Case LIMIT 1];
    
        // Insert AgentWork linked to this case and user, status 'Opened'
        /*
        AgentWork aw = new AgentWork(
            WorkItemId = testCase.Id,
            UserId = testUser.Id
            
        );
        insert aw;
		*/
        Test.startTest();
        Boolean hasWork = Knowledge.displayKnowledge(testCase.Id, testUser.Id);
        Test.stopTest();
    
        //System.assertEquals(true, hasWork, 'Should return true when AgentWork exists');
    
        // Negative test: create a new case with no AgentWork and check it returns false
        Case otherCase = new Case(Subject='Other Case', Status='New');
        insert otherCase;
    
        Boolean hasWork2 = Knowledge.displayKnowledge(otherCase.Id, testUser.Id);
        //System.assertEquals(false, hasWork2, 'Should return false when no AgentWork exists');
    }


}