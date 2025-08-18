/**
* @File Name : ChatGPTService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 30, 2025 |   | Initial Version
**/

public class ChatGPTService {
    public static String callChatGPT(String prompt) {
        String apiKey = 'Bearer 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';
        String endpoint = 'https://api.openai.com/v1/chat/completions';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Authorization', apiKey);
        request.setHeader('Content-Type', 'application/json');

        String body = JSON.serialize(new Map<String, Object>{
            'model' => 'gpt-3.5-turbo',
            'messages' => new List<Object>{
                new Map<String, Object>{'role' => 'user', 'content' => prompt}
            }
        });

        request.setBody(body);

        HttpResponse response = http.send(request);
		System.debug('response ---> '+response.getBody());
        if (response.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            List<Object> choices = (List<Object>)result.get('choices');
            if (!choices.isEmpty()) {
                Map<String, Object> choice = (Map<String, Object>)choices[0];
                Map<String, Object> message = (Map<String, Object>)choice.get('message');
                return (String)message.get('content');
            }
        }
        return 'Error: ' + response.getBody();
    }
}