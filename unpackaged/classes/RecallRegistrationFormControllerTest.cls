@IsTest
public class RecallRegistrationFormControllerTest {

    @IsTest
    public static void testRegisterTheCase() {
        recallProcessWrapper recallPro = new recallProcessWrapper();
        recallPro.First_Name = 'Test';
        recallPro.Last_Name = 'Metro';
        recallPro.SuppliedEmail = 'test@gmail.com';
        recallPro.ContactPhone = '23122312';
        recallPro.SuppliedPhone = '34433344';
        recallPro.Address = '9400 S Normandie Ave #14';
        recallPro.Support_Address = '6736 S Sherbourne Dr';
        recallPro.City = 'Los Angeles';
        recallPro.State = 'CA';
        recallPro.ZipCode = '90056';
        recallPro.Model_Number = '23123';
        recallPro.Purchase_Date = Date.newInstance(2024, 9, 24);
        recallPro.VisitorFingerprintId = '2331211';
        recallPro.Batch_Number = '90878';

        String caseId = RecallRegistrationFormController.registerTheCase(recallPro);
        System.assertNotEquals(null, caseId, 'Case ID should not be null');
    }

	@IsTest
    public static void testcreateDuplicateRecallRequest() {
        
        Case caseRec = new Case();
     	caseRec.Subject='Testing purpose';
        insert caseRec;
        system.debug('caseRec--'+caseRec.Id);
        system.debug('caseRec--'+caseRec.CaseNumber);
        
        recallProcessWrapper recallPro = new recallProcessWrapper();
        recallPro.First_Name = 'Test';
        recallPro.Last_Name = 'Metro';
        recallPro.SuppliedEmail = 'test@gmail.com';
        recallPro.ContactPhone = '23122312';
        recallPro.SuppliedPhone = '34433344';
        recallPro.Address = '9400 S Normandie Ave #14';
        recallPro.Support_Address = '6736 S Sherbourne Dr';
        recallPro.City = 'Los Angeles';
        recallPro.State = 'CA';
        recallPro.ZipCode = '90056';
        recallPro.Model_Number = '23123';
        recallPro.Purchase_Date = Date.newInstance(2024, 9, 24);
        recallPro.VisitorFingerprintId = '2331211';
        recallPro.Batch_Number = '90878';
		
        Case cs = [Select Id , CaseNumber FROM Case WHERE Id =: caseRec.Id];
        system.debug('cs number--'+cs.CaseNumber);
        List<String> caseId = RecallRegistrationFormController.createDuplicateRecallRequest(cs.CaseNumber, recallPro);
        System.assertNotEquals(null, caseId, 'Case ID should not be null');
    }
    
    private class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"products":{"identification":{"data":{"visitorId":"abc123"}}}}');
            return res;
        }
    }

   
    private class MockBotDetected implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{' +
                '"products": {' +
                    '"identification": {"data": {"visitorId": "abc123"}},' +
                    '"botd": {"data": {"bot": {"result": "badBot"}}}' +
                '}' +
            '}');
            return res;
        }
    }

    
    private class MockSuspiciousScore implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{' +
                '"products": {' +
                    '"identification": {"data": {"visitorId": "abc123"}},' +
                    '"suspectScore": {"data": {"result": 20}}' +
                '}' +
            '}');
            return res;
        }
    }

  
    private class MockRequestFailed implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Bad Request"}');
            return res;
        }
    }

	/*
    @IsTest
    static void testValidateRequestor_Success() {
        insert new Case(Subject='test', Visitor_Fingerprint_Id__c='differentId');
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        String result = RecallRegistrationFormController.validateRequestor('req1');
        System.assertEquals('Success', result);
    }
*/


    @IsTest
    static void testValidateRequestor_BotDetected() {
        Test.setMock(HttpCalloutMock.class, new MockBotDetected());
        String result = RecallRegistrationFormController.validateRequestor('req2');
        System.assertEquals('Request is not submitted due to bot detection.', result);
    }

    @IsTest
    static void testValidateRequestor_SuspiciousScore() {
        Test.setMock(HttpCalloutMock.class, new MockSuspiciousScore());
        String result = RecallRegistrationFormController.validateRequestor('req3');
        System.assertEquals('Suspicious activity detected. You request can not be submitted', result);
    }

    @IsTest
    static void testValidateRequestor_RequestFailed() {
        Test.setMock(HttpCalloutMock.class, new MockRequestFailed());
        String result = RecallRegistrationFormController.validateRequestor('req4');
        System.assertEquals('Request Validation Failed', result);
    }

    /*
    @IsTest
    static void testValidateRequestor_PastOffender() {
        // visitorId from API = abc123; create case matching it
        insert new Case(Subject='past offender', Visitor_Fingerprint_Id__c='abc123');
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        String result = RecallRegistrationFormController.validateRequestor('req5');
        System.assertEquals('past offenders detected. You request can not be submitted', result);
    }
	*/
    
    @IsTest
    public static void uploadMultipleFilesTest()
    {
        List<Map<String,String>> fileData = new List<Map<String,String>>();
        Map<String,String> filesMap = new Map<String,String>{
            'fileName'=>'testingFile',
            'base64'=>'3343443423243443434232323343343'
            
        };
       
            fileData.add(filesMap);
        Case caseRec = new Case();
     	caseRec.Subject='Testing purpose';
        insert caseRec;
        
        String myCaseId=caseRec.Id;
        
        RecallRegistrationFormController.uploadMultipleFiles(fileData,myCaseId);
        
    }
}