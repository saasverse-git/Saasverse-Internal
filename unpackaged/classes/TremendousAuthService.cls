public with sharing class TremendousAuthService {
    
    public class TokenResponse {
        public String access_token;
        public String token_type;
        public Integer expires_in;
        public String refresh_token;
        public String scope;
    }
    
    public static void getAccessTokenWithAuthCode(String authCode) {
        
        Tremondous_Site_Setting__c orgDefaults = Tremondous_Site_Setting__c.getOrgDefaults();
        String Endpoint = orgDefaults.Endpoint__c;
        String client_id = orgDefaults.ClientId__c;
        String client_secret = orgDefaults.Client_Secret__c;
        String redirect_Url = orgDefaults.Redirect_URL__c;
            
        // Prepare the endpoint URL
        //String url = 'https://testflight.tremendous.com/oauth/token';
        
        // Create the HTTP request object
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Endpoint+'/oauth/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        // Prepare JSON body
        Map<String, Object> payload = new Map<String, Object>{
            'client_id'     => client_id,
            'client_secret' => client_secret,
            'redirect_uri'  => redirect_Url,
            'grant_type'    => 'authorization_code',
            'code'          => authCode
        };
        
        String body = JSON.serialize(payload);
        req.setBody(body);
        
        // Send callout
        Http http = new Http();
        HTTPResponse res;
        
        try {
            res = http.send(req);
        } catch (System.CalloutException e) {
            System.debug('Callout error: ' + e.getMessage());
            return ;
        }
        
        
        if (res.getStatusCode() == 200) {
            System.debug('Status: ' + res.getStatusCode());
            TokenResponse resp= (TokenResponse) JSON.deserialize(res.getBody(), TokenResponse.class);
            
            orgDefaults.Access_Token__c = EncodingUtil.base64Encode(Blob.valueOf(resp.access_token));
            orgDefaults.Refresh_Token__c = EncodingUtil.base64Encode(Blob.valueOf(resp.refresh_token));
            
            Update orgDefaults;
			
        }
        else{
            System.debug(' Error Status: ' + res.getStatusCode());
            System.debug(' Response Body: ' + res.getBody());
        }
        return ;
    }
	@future(callout=true)
    public static void getAccessTokenWithRefreshToken() {
        
        Tremondous_Site_Setting__c orgDefaults = Tremondous_Site_Setting__c.getOrgDefaults();
        String Endpoint = orgDefaults.Endpoint__c;
        String client_id = orgDefaults.ClientId__c;
        String client_secret = orgDefaults.Client_Secret__c;
        String refresh_token = orgDefaults.Refresh_Token__c;
        
        if(refresh_token != null && refresh_token != ''){
            
            // Create the HTTP request object
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Endpoint+'/oauth/token');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            string decodedRefreshToken = EncodingUtil.base64Decode(refresh_token).toString();
            // Prepare JSON body
            Map<String, Object> payload = new Map<String, Object>{
                'client_id'     => client_id,
                    'client_secret' => client_secret,
                    'grant_type'    => 'refresh_token',
                    'refresh_token' => decodedRefreshToken
                    };
                        
            String body = JSON.serialize(payload);
            req.setBody(body);
            
            // Send callout
            Http http = new Http();
            HTTPResponse res;
            
            try {
                res = http.send(req);
            } catch (System.CalloutException e) {
                System.debug('Callout error: ' + e.getMessage());
                return ;
            }
            
            
            if (res.getStatusCode() == 200) {
               System.debug('Status: ' + res.getStatusCode());
                TokenResponse resp= (TokenResponse) JSON.deserialize(res.getBody(), TokenResponse.class);
                
                orgDefaults.Access_Token__c = EncodingUtil.base64Encode(Blob.valueOf(resp.access_token));
                orgDefaults.Refresh_Token__c = EncodingUtil.base64Encode(Blob.valueOf(resp.refresh_token));
                
                Update orgDefaults;

				//return orgDefaults.Access_Token__c;
                
            }
            else{
                System.debug(' Error Status: ' + res.getStatusCode());
                System.debug(' Response Body: ' + res.getBody());
                return ;
            }
        }
        else {
            return ;
        }
    }

	
	
}