@IsTest
private class TremendousAuthServiceTest {
    
    // Mock class for HTTP callouts
    private class TremendousHttpMock implements HttpCalloutMock {
        Integer statusCode;
        String bodyContent;
        
        TremendousHttpMock(Integer code, String body) {
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
        // Create default org settings record
        Tremondous_Site_Setting__c setting = new Tremondous_Site_Setting__c(
            // Adapt if these are required fields in your org
            Endpoint__c = 'https://api.test.com',
            ClientId__c = 'client123',
            Client_Secret__c = 'secret123',
            Redirect_URL__c = 'https://callback.url',
            Access_Token__c = '',
            Refresh_Token__c = ''
        );
        insert setting;
    }
    
    @IsTest
    static void testGetAccessTokenWithAuthCode_Success() {
        // Prepare a fake token response JSON
        String mockBody = '{"access_token":"abc123","token_type":"bearer","expires_in":3600,"refresh_token":"ref123","scope":"all"}';
        
        Test.setMock(HttpCalloutMock.class, new TremendousHttpMock(200, mockBody));
        
        Test.startTest();
        TremendousAuthService.getAccessTokenWithAuthCode('AUTH_CODE_TEST');
        Test.stopTest();
        
        Tremondous_Site_Setting__c updatedSetting = [SELECT Access_Token__c, Refresh_Token__c FROM Tremondous_Site_Setting__c LIMIT 1];
        System.assertNotEquals(null, updatedSetting.Access_Token__c, 'Access token should be stored');
        System.assertNotEquals(null, updatedSetting.Refresh_Token__c, 'Refresh token should be stored');
    }
    
    @IsTest
    static void testGetAccessTokenWithAuthCode_Failure() {
        // Simulate error response
        Test.setMock(HttpCalloutMock.class, new TremendousHttpMock(400, '{"error":"invalid_request"}'));
        
        Test.startTest();
        TremendousAuthService.getAccessTokenWithAuthCode('BAD_CODE');
        Test.stopTest();
        // No exception expected, just debug logs
    }
    
    @IsTest
    static void testGetAccessTokenWithRefreshToken_Success() {
        // Update the record with a refresh token
        Tremondous_Site_Setting__c setting = [SELECT Id, Refresh_Token__c FROM Tremondous_Site_Setting__c LIMIT 1];
        setting.Refresh_Token__c = EncodingUtil.base64Encode(Blob.valueOf('ref123'));
        update setting;
        
        String mockBody = '{"access_token":"newAccess","token_type":"bearer","expires_in":3600,"refresh_token":"newRefresh","scope":"all"}';
        Test.setMock(HttpCalloutMock.class, new TremendousHttpMock(200, mockBody));
        
        Test.startTest();
        TremendousAuthService.getAccessTokenWithRefreshToken();
        Test.stopTest();
        
        Tremondous_Site_Setting__c updatedSetting = [SELECT Access_Token__c, Refresh_Token__c FROM Tremondous_Site_Setting__c LIMIT 1];
        System.assertNotEquals(null, updatedSetting.Access_Token__c, 'New access token should be stored');
        System.assertNotEquals(null, updatedSetting.Refresh_Token__c, 'New refresh token should be stored');
    }
    
    @IsTest
    static void testGetAccessTokenWithRefreshToken_Failure() {
        // Set refresh token
        Tremondous_Site_Setting__c setting = [SELECT Id, Refresh_Token__c FROM Tremondous_Site_Setting__c LIMIT 1];
        setting.Refresh_Token__c = EncodingUtil.base64Encode(Blob.valueOf('ref123'));
        update setting;
        
        Test.setMock(HttpCalloutMock.class, new TremendousHttpMock(401, '{"error":"invalid_token"}'));
        
        Test.startTest();
        TremendousAuthService.getAccessTokenWithRefreshToken();
        Test.stopTest();
    }
    
    @IsTest
    static void testGetAccessTokenWithRefreshToken_NoToken() {
        // No refresh token case
        Tremondous_Site_Setting__c setting = [SELECT Id, Refresh_Token__c FROM Tremondous_Site_Setting__c LIMIT 1];
        setting.Refresh_Token__c = null;
        update setting;
        
        Test.startTest();
        TremendousAuthService.getAccessTokenWithRefreshToken();
        Test.stopTest();
        // Should simply return without doing anything
    }
}