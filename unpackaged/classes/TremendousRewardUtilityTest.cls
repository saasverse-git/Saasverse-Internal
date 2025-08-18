@IsTest
private class TremendousRewardUtilityTest {
    
    // Stub to prevent compile errors if CaseUtility isn't available in this test context
    public class CaseUtility {
        public  void insertLog(String title, String message, String source) {
            System.debug('LOG => ' + title + ' | ' + message + ' | ' + source);
        }
    }
    
    // HTTP mock class for success/failure simulation
    private class TremendousRewardHttpMock implements HttpCalloutMock {
        Integer statusCode;
        String bodyContent;
        TremendousRewardHttpMock(Integer code, String body) {
            statusCode = code;
            bodyContent = body;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(bodyContent);
            return res;
        }
    }
    
    @TestSetup
    static void setupData() {
        Tremondous_Site_Setting__c setting = new Tremondous_Site_Setting__c(
            Endpoint__c = 'https://api.test.com',
            ClientId__c = 'client123',
            Client_Secret__c = 'secret123',
            Redirect_URL__c = 'https://callback.url',
            Access_Token__c = EncodingUtil.base64Encode(Blob.valueOf('access123')),
            Refresh_Token__c = ''
        );
        insert setting;
    }
    
    @IsTest
    static void testGenerateRewardLink_Success() {
        String mockBody = '{"order":{"rewards":[{"delivery":{"link":"https://reward-link.com"}}]}}';
        Test.setMock(HttpCalloutMock.class, new TremendousRewardHttpMock(200, mockBody));
        
        Test.startTest();
        String link = TremendousRewardUtility.generateRewardLink('10', 'John Doe', 'john@example.com');
        Test.stopTest();
        
        System.assertEquals('https://reward-link.com', link);
    }
    
    @IsTest
    static void testGenerateRewardLink_Failure() {
        Test.setMock(HttpCalloutMock.class, new TremendousRewardHttpMock(400, '{"error":"invalid_request"}'));
        
        Test.startTest();
        String result = TremendousRewardUtility.generateRewardLink('10', 'John Doe', 'john@example.com');
        Test.stopTest();
        
        System.assertEquals(null, result);
    }
    
}