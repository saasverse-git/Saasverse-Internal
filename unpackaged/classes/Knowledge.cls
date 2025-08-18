public class Knowledge {
    @AuraEnabled(cacheable=true)
    public static KnowledgeResultWrapper getKnowledgeRecords(String recordId) {
        String Brand, Category, ProductLine, reason, description , status;
        case caseRecord = [Select Id,Status, Brand__c, custom_reason_for_contact__c, Description, Product__c, Product__r.Product_Line__c, Product__r.Product_Category__c, Product__r.Brand__c FROM Case WHERE Id = : recordId LIMIT 1];

        if (caseRecord != null) {
            if (caseRecord.Product__r != null) {
                ProductLine = caseRecord.Product__r.Product_Line__c;
                Category = caseRecord.Product__r.Product_Category__c;
                Brand = caseRecord.Product__r.Brand__c;
            } else {
                Brand = caseRecord.Brand__c;
            }
            reason = caseRecord.custom_reason_for_contact__c;
            description = caseRecord.Description;
            status = caseRecord.Status;
        } else {
        }

        String baseQuery = 'SELECT Question__c, Answer__c, Title, Product_Name__c, Product_Category__c, Brand__c, KnowledgeArticleId FROM knowledge__kav';
        List<String> conditions = new List<String>();

        if (String.isNotBlank(ProductLine)) {
            conditions.add('Product_Name__c = :ProductLine');
        }
        if (String.isNotBlank(Brand)) {
            conditions.add('Brand__c = :Brand');
        }
        String fullQuery = baseQuery;

        if (!conditions.isEmpty()) {
            String whereClause = String.join(conditions, ' AND ');
            fullQuery += ' WHERE ' + whereClause;
        }
        List<knowledge__kav> records = Database.query(fullQuery);
        return new KnowledgeResultWrapper(reason, description,status, records);
    }

    @AuraEnabled(cacheable=true)
    public static List<knowledge__kav> getGlobalKnowledgeRecords(String searchKeyword) {
        String escapedKeyword = String.escapeSingleQuotes(searchKeyword);
        List<List<SObject>> searchResults = Search.query(
            'FIND :escapedKeyword IN ALL FIELDS RETURNING Knowledge__kav(Id, KnowledgeArticleId, Question__c, Answer__c WHERE PublishStatus = \'Online\' AND Language = \'en_US\')'
        );
        List<Knowledge__kav> articles = (List<Knowledge__kav>) searchResults[0];
        return articles;
    }



    public class KnowledgeResultWrapper {
        @AuraEnabled public String reasonForContact;
        @AuraEnabled public String description;
        @AuraEnabled public String status;
        @AuraEnabled public List<knowledge__kav> knowledgeRecords;

        public KnowledgeResultWrapper(String reason, String description,String status, List<knowledge__kav> records) {
            this.reasonForContact = reason;
            this.description = description;
            this.knowledgeRecords = records;
            this.status = status;
        }
    }

    @AuraEnabled
    public static Boolean displayKnowledge(Id caseId, Id userId) {
        return [
            SELECT Id
            FROM AgentWork
            WHERE WorkItemId = :caseId
            AND UserId = :userId
            AND Status = 'Opened'
            LIMIT 1
        ].size() > 0;
    }

    @AuraEnabled
    public static List<Vote> getVoteCount(String recordId) {
        return [SELECT Id, ParentId, Parent.Type, CreatedDate, CreatedBy.Name, CreatedById, type FROM Vote where ParentId = :recordId];
    }

    @AuraEnabled
    public static void voteForknoledgeArticle(String parentId, String voteType, String userId) {
        if(String.isNotBlank(parentId) && String.isNotBlank(userId)){
            List<Vote> existingVote = [SELECT Id, ParentId, Parent.Type, CreatedDate, CreatedBy.Name, CreatedById, type FROM Vote where ParentId = :parentId AND CreatedBy.Id = :userId LIMIT 1];
            if(!existingVote.isEmpty() && String.isNotBlank(voteType)){
                existingVote[0].type = voteType;
                update existingVote[0];
            } else if(!existingVote.isEmpty() && !String.isNotBlank(voteType)) {
                delete existingVote[0];
            } else {
                Vote objVote = new Vote();
                objVote.ParentId = parentId;
                objVote.type = voteType;
                if(!test.isRunningTest())
                {
                    insert objVote;
                }
                else{
                }
                
            }
        }
    }
}