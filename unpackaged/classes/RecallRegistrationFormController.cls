public without sharing class RecallRegistrationFormController {

    @AuraEnabled 
    public static String registerTheCase(recallProcessWrapper recallWrapper) {
        try {
            Case c = new Case();
            if (recallWrapper.First_Name != null) c.First_Name__c = recallWrapper.First_Name;
            if (recallWrapper.Last_Name != null) c.Last_Name__c = recallWrapper.Last_Name;
            if(recallWrapper.First_Name != null && recallWrapper.Last_Name != null){
                c.SuppliedName = recallWrapper.First_Name + ' ' + recallWrapper.Last_Name;
            }
            if (recallWrapper.SuppliedEmail != null) c.SuppliedEmail = recallWrapper.SuppliedEmail;
            if (recallWrapper.SuppliedPhone != null) c.SuppliedPhone = recallWrapper.SuppliedPhone;
            if (recallWrapper.ContactPhone != null) c.Home_Phone__c = recallWrapper.ContactPhone;
            if (recallWrapper.Address != null) c.Address__c = recallWrapper.Address;
            if (recallWrapper.Support_Address != null) c.Address2__c = recallWrapper.Support_Address;
            if (recallWrapper.City != null) c.City__c = recallWrapper.City;
            if (recallWrapper.State != null) c.State__c = recallWrapper.State;
            if (recallWrapper.ZipCode != null) c.ZipCode__c = recallWrapper.ZipCode;
            c.Status = 'New - Awaiting Review';
            c.Origin = 'Registration';
            c.Model__c = 'D3190';
            c.RecordTypeId = Constants.RECORD_TYPE_CASE_RECALL_REGISTRATION ; 
            if (recallWrapper.VisitorFingerprintId != null) {
                c.Visitor_Fingerprint_Id__c = recallWrapper.VisitorFingerprintId;
            }

            insert c;
            return c.Id;
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static void uploadMultipleFiles(List<Map<String, String>> filesData, Id caseId) {
        if (filesData == null || filesData.isEmpty() || caseId == null) {
            throw new AuraHandledException('Invalid upload data.');
        }

        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();

        for (Map<String, String> fileMap : filesData) {
            String fileName = fileMap.get('fileName');
            String base64Data = fileMap.get('base64');

            if (String.isBlank(fileName) || String.isBlank(base64Data)) {
                continue;
            }

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = '/' + fileName;
            contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
            contentVersionsToInsert.add(contentVersion);
        }

        insert contentVersionsToInsert;

        List<ContentVersion> insertedVersions = [ SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionsToInsert ];

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion cv : insertedVersions) {
            if (cv.ContentDocumentId != null) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.LinkedEntityId = caseId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                links.add(cdl);
            }
        }
        insert links;
    }

    @AuraEnabled(cacheable=false)
    public static String getCaseNumber(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('caseId cannot be null');
        }
        try {
            Case c = [SELECT CaseNumber, (Select id from Duplicate_Registration_Request__r) FROM Case WHERE Id = :caseId LIMIT 1];
            if(c.Duplicate_Registration_Request__r.size() > 0){
                return 'duplicate - ' +  c.CaseNumber;
            } else {
                return c.CaseNumber;
            }
        } catch (QueryException e) {
            throw new AuraHandledException('No Case found for the given caseId.');
        }
    }

    //sfdc:fingerprint
    // @AuraEnabled
    // public static Boolean isFingerprintAlreadyUsed(String visitorId) {
    //     List<Case> existingCases = [
    //         SELECT Id
    //         FROM Case
    //         WHERE Visitor_Fingerprint_Id__c = :visitorId
    //         LIMIT 1
    //     ];
    //     return !existingCases.isEmpty();
    // }

    @AuraEnabled
    public static String validateRequestor(String requestId){
        try {
            String apiKey = '0qp3SHXdRDekTVX6qw5P';
            String requestUrl = 'https://api.fpjs.io/events/' + EncodingUtil.urlEncode(requestId, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(requestUrl);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Auth-API-Key', apiKey);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                return 'Request Validation Failed';
            }
            //return res.getBody();

            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> products = (Map<String, Object>) result.get('products');
            Map<String, Object> identification = (Map<String, Object>) products.get('identification');
            Map<String, Object> idData = (Map<String, Object>) identification.get('data');
            String visitorId = (String) idData.get('visitorId');

            // STEP 3: Bot Detection
            if (products.containsKey('botd')) {
                Map<String, Object> botd = (Map<String, Object>) products.get('botd');
                Map<String, Object> botData = (Map<String, Object>) botd.get('data');
                Map<String, Object> bot = (Map<String, Object>) botData.get('bot');
                String botResult = (String) bot.get('result');

                if (botResult != 'notDetected') {
                    return 'Request is not submitted due to bot detection.';
                }
            }

            // STEP 4: Suspicious Score
            if (products.containsKey('suspectScore')) {
                Map<String, Object> score = (Map<String, Object>) products.get('suspectScore');
                Map<String, Object> scoreData = (Map<String, Object>) score.get('data');
                Object rawScore = scoreData.get('result');

                if (rawScore != null && Integer.valueOf(String.valueOf(rawScore)) > 15) {
                    return 'Suspicious activity detected. You request can not be submitted';
                }
            }

            if (visitorId != null) {

                System.debug('visitorId' + visitorId);

                List<Case> existingCases = [
                SELECT Id , caseNumber
                FROM Case
                WHERE Visitor_Fingerprint_Id__c = :visitorId
                LIMIT 1];

                if (!existingCases.isEmpty()) {
                    return 'You have already submitted this request with case : ' + existingCases[0].caseNumber + '. Do you still want to submit this request?' ;
                }
            }
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static List<String> createDuplicateRecallRequest(String casenumber , recallProcessWrapper recallWrapper){
        try {

            Case caseRec = [Select id from case where caseNumber = : casenumber Limit 1];

            List<String> recIds = new List<String>();
 
            Duplicate_Registration_Request__c c = new Duplicate_Registration_Request__c();
            if (recallWrapper.First_Name != null) c.First_Name__c = recallWrapper.First_Name;
            if (recallWrapper.Last_Name != null) c.Last_Name__c = recallWrapper.Last_Name;
            
            if (recallWrapper.SuppliedEmail != null) c.Customer_Email__c = recallWrapper.SuppliedEmail;
            if (recallWrapper.SuppliedPhone != null) c.Web_Phone__c = recallWrapper.SuppliedPhone;
            if (recallWrapper.ContactPhone != null) c.Home_Phone__c = recallWrapper.ContactPhone;
            if (recallWrapper.Address != null) c.Address__c = recallWrapper.Address;
            if (recallWrapper.Support_Address != null) c.Address2__c = recallWrapper.Support_Address;
            if (recallWrapper.City != null) c.City__c = recallWrapper.City;
            if (recallWrapper.State != null) c.State__c = recallWrapper.State;
            if (recallWrapper.ZipCode != null) c.ZipCode__c = recallWrapper.ZipCode;
            c.CaseNumber__c = caseRec.id;
            if (recallWrapper.VisitorFingerprintId != null) {
                c.Visitor_Fingerprint_Id__c = recallWrapper.VisitorFingerprintId;
            }
     


            insert c;

            recIds.add(c.Id);
            recIds.add(caseRec.id);
            return recIds;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return null;
        }
    }

}