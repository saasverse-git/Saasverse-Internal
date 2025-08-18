public class whatsAppNotificationService {
    
       
    public static void sendWhatsAppMessage(String toPhoneNumber, String messageBody) {
        String accountSid = 'AC5088e69a11b169891ce3f439010fd4bc';
        String authToken = 'b5a883bfe6ced9d31c860bdef31fd9fb';
        String fromPhoneNumber = 'whatsapp:+14155238886'; // Twilio Sandbox number

        String endpoint = 'https://api.twilio.com/2010-04-01/Accounts/' + accountSid + '/Messages.json';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Authorization', 'Basic ' +
            EncodingUtil.base64Encode(Blob.valueOf(accountSid + ':' + authToken)));

        String body = 'From=' + EncodingUtil.urlEncode(fromPhoneNumber, 'UTF-8') +
                      '&To=' + EncodingUtil.urlEncode('whatsapp:+' + toPhoneNumber, 'UTF-8') +
                      '&Body=' + EncodingUtil.urlEncode(messageBody, 'UTF-8');

        req.setBody(body);

        Http http = new Http();
        try {
            HTTPResponse res = http.send(req);
            System.debug(' Response: ' + res.getBody());
        } catch (Exception e) {
            System.debug(' Failed to send WhatsApp message: ' + e.getMessage());
        }
    }

}