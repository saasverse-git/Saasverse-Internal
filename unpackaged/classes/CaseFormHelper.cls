public without sharing class CaseFormHelper {

    public static Id getProductId(String brand, String productLine, String model) {
        List<Product__c> products = [
            SELECT Id FROM Product__c 
            WHERE Brand__c LIKE :brand 
              AND Product_Line__c LIKE :productLine 
              AND Model_Number__c LIKE :model 
            LIMIT 1
        ];
        return products.isEmpty() ? null : products[0].Id;
    }

    public static Id getKeywordRelatedQueue(String emailContent, String supportAddress) {
        List<Keyword_Config__mdt> configList = CaseUtility.getKeywordConfigMdtBySupportEmail(supportAddress);
        if (!configList.isEmpty() && 
            CaseUtility.isValidKeywordFound(configList[0].Keyword__c.split(',\\s*'), emailContent)) {

            Group queue = [SELECT Id FROM Group 
                           WHERE Name = :configList[0].Routing_Queue_Name__c 
                           AND Type = 'Queue' 
                           LIMIT 1];

            return queue.Id;
        }
        return null;
    }

    public static Case constructCaseRecord(Map<String, String> params) {
        Case c = new Case();
        try {
            System.debug('params:- ' + params);
            c.SuppliedName            = params.get('name');
            c.SuppliedEmail           = params.get('email');
            c.SuppliedPhone           = params.get('phone');
            c.Subject                 = params.get('subject');
            c.Description             = params.get('description');
            c.Custom_Reason_for_Contact__c = params.get('Reason_for_Contact__c');
            c.Form_Submitted_Date__c  = System.now();
            c.Product__c              = getProductId(params.get('Brand__c'), params.get('Raw_Product_Line__c'), params.get('Raw_Model_Number__c'));
        } catch (Exception e) {
            System.debug('exception occured in constructCaseRecord:- ' + e.getMessage());
        }
        return c;
    }

    public static void insertAttachments(Id caseId, Map<String, String> params) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        Integer index = 0;

        while (true) {
            String nameKey = 'fileName' + index;
            String contentKey = 'fileContent' + index;

            if (!params.containsKey(nameKey) || !params.containsKey(contentKey)) break;

            String fileName = params.get(nameKey);
            String fileContent = params.get(contentKey);

            if (String.isNotBlank(fileName) && String.isNotBlank(fileContent)) {
                contentVersions.add(new ContentVersion(
                    Title = fileName,
                    PathOnClient = '/' + fileName,
                    VersionData = EncodingUtil.base64Decode(fileContent)
                ));
            }
            index++;
        }

        if (contentVersions.isEmpty()) return;

        List<Id> insertedIds = new List<Id>();
        for (Database.SaveResult res : Database.insert(contentVersions, false)) {
            if (res.isSuccess()) insertedIds.add(res.getId());
        }

        if (insertedIds.isEmpty()) return;

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :insertedIds AND ContentDocumentId != null
        ]) {
            links.add(new ContentDocumentLink(
                LinkedEntityId = caseId,
                ContentDocumentId = cv.ContentDocumentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }

        if (!links.isEmpty()) insert links;
    }

    public static Map<String, List<String>> getModelMap(String brandName) {
        Map<String, List<String>> modelMap = new Map<String, List<String>>();

        for (Product__c pm : 
            [SELECT Brand__c, Model_Number__c, Product_Line__c 
             FROM Product__c 
             WHERE Brand__c = :brandName]) {

            if (!modelMap.containsKey(pm.Product_Line__c)) {
                modelMap.put(pm.Product_Line__c, new List<String>());
            }
            modelMap.get(pm.Product_Line__c).add(pm.Model_Number__c);
        }
        return modelMap;
    }

    public static List<String> getReasonForContactOptions() {
        /*List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Case.Custom_Reason_for_Contact__c.getDescribe();

        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            options.add(entry.getValue());
        }*/
        
        String resonForContact = System.Label.ReasonForContactForCustomer;
        List<String> options = resonForContact.split(',');
        
        return options;
    }

    public static List<String> getBrandOptions() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Product__c.Brand__c.getDescribe();

        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            options.add(entry.getValue()); 
        }
        return options;
    }

}