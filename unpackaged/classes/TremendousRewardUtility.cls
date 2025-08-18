public class TremendousRewardUtility {

    public static String generateRewardLink(String denomination, String receipientName, String receipientEmail) {
		
        Tremondous_Site_Setting__c orgDefaults = Tremondous_Site_Setting__c.getOrgDefaults();
        String Endpoint = orgDefaults.Endpoint__c;
        String Access_Token = orgDefaults.Access_Token__c;
        
        if(Access_Token == null || Access_Token == ''){
            return null;
        }
        String decodedAccessToken = EncodingUtil.base64Decode(Access_Token).toString();
        HttpRequest req = new HttpRequest();
        Http http = new Http();

        req.setEndpoint(Endpoint+'/api/v2/orders');
        req.setMethod('POST');
        req.setHeader('Authorization','Bearer '+decodedAccessToken);
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'payment' => new Map<String, Object>{ 'funding_source_id' => 'BALANCE' },
            'reward' => new Map<String, Object>{
                'value' => new Map<String, Object>{
                    'denomination' => denomination,
                    'currency_code' => 'USD'
                },
                'delivery' => new Map<String, Object>{
                    'method' => 'LINK'
                },
                'recipient' => new Map<String, Object>{
                    'name' => receipientName,
                    'email' => receipientEmail
                },
                'products' => new List<String>{ 'Q24BD9EZ332JT' }
            }
        };

        req.setBody(JSON.serialize(payload));

        try {
            HttpResponse res = http.send(req);
        	system.debug('Response Code'+res.getStatusCode());
            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> order = (Map<String, Object>) response.get('order');
                List<Object> rewards = (List<Object>) order.get('rewards');
                Map<String, Object> reward = (Map<String, Object>) rewards[0];
                Map<String, Object> delivery = (Map<String, Object>) reward.get('delivery');
                return (String) delivery.get('link');
            } else {
            
                CaseUtility.insertLog('Tremendous Error', 'Code: ' + res.getStatusCode() + ', Body: ' + res.getBody(), 'Reward Utility');
            }
        } catch (Exception e) {
            CaseUtility.insertLog('Tremendous Exception', e.getMessage(), 'Reward Utility');
        }
        return null;
    }

}