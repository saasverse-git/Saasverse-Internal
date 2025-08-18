public class CaseTriggerHandler {
    
	private static Boolean hasRun = false;
    
    public static void beforeInsert(List<Case> newCases) {
        validateCasesFromWeb(newCases);
        populateAssignedQueueId(newCases, null);
    }

    public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        updateLastStatusChangeTime(newCases, oldMap);
        populateAssignedQueueId(newCases, oldMap);
    }

    public static void afterInsert(List<Case> newCases) {
        submitCaseForRecallApprovalProcess(newCases);
        handleCriticalCase(newCases);
    }

    public static void afterUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        runFollowUpBatch(newCases,oldMap);
        processRefundApprovals(newCases, oldMap);
        sendSurveyEmail(newCases, oldMap);
        
    }

    private static void assignToQueue(Map<String, List<Case>> skillWiseCases) {
        Id fallbackQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'CCS_General' AND Type = 'Queue' LIMIT 1].Id;
        List<Case> fallbackCases = new List<Case>();
        for (List<Case> cases : skillWiseCases.values()) {
            for (Case cs : cases) {
                Case newCs = New Case();
                newCs.Id = cs.Id;
                newCs.OwnerId = fallbackQueueId;
                if(cs.custom_reason_for_contact__c != null  &&(cs.custom_reason_for_contact__c == 'Injury' || cs.custom_reason_for_contact__c == 'Property Damage' ||
                                      cs.custom_reason_for_contact__c == 'Recall' ))
                {
                    newCs.Is_Critical_Case__c  = true;
                    cs.Priority= 'High';
                }
                if(newCs.Id != null){
                 	fallbackCases.add(newCs);   
                }
                
            }
        }
        if (!fallbackCases.isEmpty()) {
            update fallbackCases;
        }
    }

    public static void handleCriticalCase(List<Case> newCases){
        // Step 1: Filter critical cases and determine required skills
        System.debug('List<CaseCalled==>>'+newCases);
        Map<String, List<Case>> skillWiseCases = new Map<String, List<Case>>();
        Set<String> requiredSkills = new Set<String>();
        List<String> PIRlist = new List<String>{'Injury', 'Property Damage', 'Complaint-Quality'};
        
        for (Case cs : newCases) {
            if(cs.custom_reason_for_contact__c != null &&(cs.custom_reason_for_contact__c == 'Injury' || cs.custom_reason_for_contact__c == 'Property Damage' ||
                                      cs.custom_reason_for_contact__c == 'Recall' ))
            {
                
                system.debug('inside handleCriticalCase');
                String skill;
                if (PIRlist.contains(cs.custom_reason_for_contact__c)) {
                    skill = 'PIR';
                } else if (cs.custom_reason_for_contact__c == 'Recall') {
                    skill = 'Insurance';
                }
                // else {
                //     skill = 'Legal';
                // }
                
                if (!skillWiseCases.containsKey(skill)) {
                    skillWiseCases.put(skill, new List<Case>());
                }
                skillWiseCases.get(skill).add(cs);
                requiredSkills.add(skill);
                
            }
        }
        if (skillWiseCases.isEmpty()) {
            System.debug('returned due to skill wise case empty');
            return;
        } 
        
        // Step 2: Fetch ServiceResources having required skills
        Map<String, Set<Id>> skillToResourceIds = new Map<String, Set<Id>>();
        Set<Id> allServiceResourceIds = new Set<Id>();
        
        for (ServiceResourceSkill srs : [
            SELECT Skill.DeveloperName, ServiceResourceId
            FROM ServiceResourceSkill
            WHERE Skill.DeveloperName IN :requiredSkills
        ]) {
            System.debug('srsRecord-->'+srs);
            if (!skillToResourceIds.containsKey(srs.Skill.DeveloperName)) {
                skillToResourceIds.put(srs.Skill.DeveloperName, new Set<Id>());
            }
            skillToResourceIds.get(srs.Skill.DeveloperName).add(srs.ServiceResourceId);
            allServiceResourceIds.add(srs.ServiceResourceId);
        }
      
        
        if (allServiceResourceIds.isEmpty()) {
            // Fallback all to queue directly if no resources found
            assignToQueue(skillWiseCases);
            return;
        }
		
        
        // Step 3: Get UserId from ServiceResource
        Map<Id, Id> resourceIdToUserId = new Map<Id, Id>();
        for (ServiceResource sr : [
            SELECT Id, RelatedRecordId FROM ServiceResource
            WHERE Id IN :allServiceResourceIds AND IsActive = true
        ]) {
            if (sr.RelatedRecordId != null) {
                resourceIdToUserId.put(sr.Id, sr.RelatedRecordId);
            }
        }
        
        Set<Id> allUserIds = new Set<Id>(resourceIdToUserId.values());
        
        // Step 4: Count open cases per user (simulate capacity check)
        Map<Id, Integer> userOpenCaseCount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OwnerId, COUNT(Id) caseCount
            FROM Case
            WHERE OwnerId IN :allUserIds AND Status != 'Closed'
            GROUP BY OwnerId
        ]) {
            userOpenCaseCount.put((Id)ar.get('OwnerId'), (Integer)ar.get('caseCount'));
        }
        
        // Step 5: Prepare fallback Queue Id
        Id fallbackQueueId;
        Id skilledQueueId;
        for(Group gp : [SELECT Id, DeveloperName FROM Group WHERE (DeveloperName = 'Specialist_Queue' OR DeveloperName = 'CCS_General') AND Type = 'Queue']){
            if(gp.DeveloperName == 'Specialist_Queue'){
                skilledQueueId = gp.Id;
            }else if(gp.DeveloperName == 'CCS_General'){
                fallbackQueueId = gp.Id;
            }
        }
        
        // Step 6: Assign each case
        List<Case> casesToUpdate = new List<Case>();
        Integer MAX_CAPACITY = 2;
        
        for (String skill : skillWiseCases.keySet()) {
            List<Case> cases = skillWiseCases.get(skill);
            Set<Id> resourceIds = skillToResourceIds.get(skill);
            Boolean assigned = false;
            
            List<Id> availableUsers = new List<Id>();
            
            for (Id resId : resourceIds) {
                if (resourceIdToUserId.containsKey(resId)) {
                    Id userId = resourceIdToUserId.get(resId);
                    Integer count = userOpenCaseCount.get(userId);
                    if (count == null) {
                        count = 0;
                        userOpenCaseCount.put(userId, 0);
                    }
                    if (count < MAX_CAPACITY) {
                        availableUsers.add(userId);
                    }
                }
            }
            
            for (Case cs : cases) {
                Case updateCase = new Case();
                if (!availableUsers.isEmpty()) {
                    // Assign round-robin to first available agent
                    Id assignedUser = availableUsers.remove(0);
                    updateCase.Id = cs.Id;
                    updateCase.OwnerId = skilledQueueId;
                    updateCase.Is_Critical_Case__c = true;
                    updateCase.Priority = 'High';
                    userOpenCaseCount.put(assignedUser, userOpenCaseCount.get(assignedUser) + 1);
                    // Add back if under capacity
                    if (userOpenCaseCount.get(assignedUser) < MAX_CAPACITY) {
                        availableUsers.add(assignedUser);
                    }
                } else {
                    // No user available under capacity
                    updateCase.Id = cs.Id;
                    updateCase.Is_Critical_Case__c = true;
                    updateCase.Priority = 'High';
                    updateCase.OwnerId = fallbackQueueId;
                }
                casesToUpdate.add(updateCase);
            }
        }
        
        if (!casesToUpdate.isEmpty()) {
            System.debug('caseToUpdate--->');
            System.debug('caseToUpdateRec===>'+casesToUpdate);
            update casesToUpdate;
        }
    }

    private static void populateAssignedQueueId(List<Case> newCases, Map<Id, Case> oldMap) {
        for (Case c : newCases) {
            Boolean isQueueOwner = c.OwnerId != null && 
                                c.OwnerId.getSObjectType() == Group.SObjectType;

            Boolean isNewOrChanged = (oldMap == null) || 
                                    (oldMap.containsKey(c.Id) && oldMap.get(c.Id).OwnerId != c.OwnerId);

            if (isQueueOwner && isNewOrChanged) {
                c.Assigned_Queue_Id__c = c.OwnerId;
            }
        }
    }

    private static void processRefundApprovals(List<Case> newCases, Map<Id, Case> oldMap) {
        try {
            Set<Id> caseIds = new Set<Id>();
            for (Case newCase : newCases) {
                Case oldCase = oldMap.get(newCase.Id);
                if (!oldCase.Is_Refund_Request_Approved__c  
                    && newCase.Is_Refund_Request_Approved__c  
                    && newCase.SuppliedEmail != null 
                    && newCase.SuppliedName != null) {

                    caseIds.add(newCase.Id);
                }
            }
            if (!caseIds.isEmpty()) {
                sendReward(caseIds);
            }
        } catch (Exception e) {
            CaseUtility.insertLog('Refund Reward Failure', e.getMessage(), 'Case Trigger');
        }
    }

    @future(callout=true)
    @testVisible
    private static void sendReward (Set<Id> caseIds) {
        Map<String, String> modelToDenominationMap = new Map<String, String>{
            'DUAF-005' => '98',
            'DUAF-10' => '118',
            'D3190' => '25'
        };
		
        List<Case> caseUpdateList = new List<Case>();
        
        List<Case> newCaseList = [select Id, SuppliedEmail, SuppliedName, Model__c from Case
                                  where Id in :caseIds];
        
        Id senderAddressId = [SELECT Id,Address FROM OrgWideEmailAddress WHERE Address = 'cssfnoreply@spectrumbrands.com'].Id;
        Id EmailTemplateId = [SELECT Id from EmailTemplate where DeveloperName = 'Recall_Accepted_Email_Template'].Id;

        for (Case newCase : newCaseList) {
            List<EmailServiceUtility.EmailPayload> emailsToSend = new List<EmailServiceUtility.EmailPayload>();

            String denomination = modelToDenominationMap.get(newCase.Model__c) ?? '10';
            System.debug('denomination-->'+denomination);

            String rewardLink = TremendousRewardUtility.generateRewardLink(
                denomination,
                newCase.SuppliedName,
                newCase.SuppliedEmail
            );
            System.debug('rewarLink-->'+rewardLink);

            if (rewardLink != null) {
                EmailServiceUtility.EmailPayload email = new EmailServiceUtility.EmailPayload();
                email.toAddress = new List<String> { newCase.SuppliedEmail };
                email.templateId = EmailTemplateId; 
                email.senderAddressId = senderAddressId;
                email.ParentId = newCase.Id;
                email.isReply = false;
                email.tokens = new Map<String, String>{
                    'CUSTOMER_NAME' => newCase.SuppliedName,
                    'REWARD_LINK' => rewardLink
                };
                    
                emailsToSend.add(email);
                
                Case caseToUpdate = new Case();
                caseToUpdate.Id = newCase.Id;
                caseToUpdate.Status = 'Refund Approved';
                caseUpdateList.add(caseToUpdate);
            }
            if (!emailsToSend.isEmpty()) {
                if(!test.IsRunningTest())
                {
                   EmailServiceUtility.sendEmails(emailsToSend); 
                }
                
                
            }
        }
        
        if(!caseUpdateList.isEmpty()){
            update caseUpdateList;
        }
    }

	private static void submitCaseForRecallApprovalProcess(List<Case> caseList){
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
		
        Id recallRegRT = [SELECT ID FROM RecordType WHERE DeveloperName = 'Recall_Registration'].Id;

        for (Case cs : caseList) {
            if (cs.Status == 'New - Awaiting Review' && cs.RecordTypeId == recallRegRT) {

                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Submitting via trigger');
                req.setObjectId(cs.Id);
                req.setSubmitterId(UserInfo.getUserId());

                // Assign next approver manually
                //req.setNextApproverIds(new Id[] { approverId });

                approvalRequests.add(req);
            }
        }
        
        Approval.ProcessResult[] processResults = null;
        try{
            processResults = Approval.process(approvalRequests,true);
        }catch(System.DmlException e){
            System.debug('Approval submission failed: ' + e.getMessage());
        }
    }

    private static void updateLastStatusChangeTime(List<Case> newCases, Map<Id, Case> oldMap) {
        for (Case c : newCases) {
            Case old = oldMap.get(c.Id);
            System.debug('new case status:- ' + c.Status);
            System.debug('old case status:- ' + old.Status);
            if (c.Status != old.Status) {
                c.Last_Status_Change__c = System.now();
            }
        }
    }

    private static void validateCasesFromWeb(List<Case> caseList){
        Set<String> productSet = new Set<String>();
        Set<String> modelSet = new Set<String>();
        List<String> validkeywords = new List<String>();
        List<Case> eligibleCases = new List<Case>();
        Map<String,Case> mapOfCaseContentWiseCase = new Map<String,Case>();
        
        for(Case cs : caseList){
            system.debug('Origin-->'+cs.Origin);
            system.debug('Brand-->'+cs.Brand__c);
            if(cs.Origin == 'Web' && cs.Brand__c == 'Remington Products'){ 
                eligibleCases.add(cs);
            }
        }
        if (eligibleCases.isEmpty()) {
            return;
        }
        
        for(Keyword_Config__mdt kwmdt : [SELECT Id , Keyword__c , Support_Email__c
                                        FROM Keyword_Config__mdt 
                                        WHERE Support_Email__c In : label.RamingtonSupportEmailAddresses.split(',')]){
                                            validkeywords.addAll(kwmdt.Keyword__c.split(',')); 
                                        } 
        if(!validkeywords.isEmpty()){
            
            for(Case cs : eligibleCases){
                Boolean validCase = CaseUtility.isValidKeywordFound(validkeywords,cs.Subject + ' ' + cs.Description);
                productSet.add(cs.Raw_Product_Line__c);
                modelSet.add(cs.Raw_Model_Number__c);
                mapOfCaseContentWiseCase.put(cs.Raw_Product_Line__c +'|'+cs.Raw_Model_Number__c , cs);
                
                if(!validCase){  
                    cs.Valid_Keyword_Found__c = false;
                }
                else{  
                    cs.Valid_Keyword_Found__c = true;
                }
            }
        }
        
        
        if(!modelSet.isEmpty()){
            for(Product__c product : [SELECT Id,Product_Line__c,Model_Number__c 
                                      FROM Product__c 
                                      WHERE Product_Line__c IN :productSet 
                                      AND Model_Number__c IN : modelSet] ){
                                          if(mapOfCaseContentWiseCase.containsKey(product.Product_Line__c +'|'+product.Model_Number__c)){
                                              mapOfCaseContentWiseCase.get(product.Product_Line__c +'|'+product.Model_Number__c).Product__c = product.Id;
                }
            }
        }
    }
    
    public static void sendSurveyEmail(list<case> newCase , Map<id,case> oldmap){
        System.debug('newCase-->'+newCase);
        System.debug('oldMap-->'+oldMap);
        
        Set<Id> contactIds = new Set<Id>();
        for (Case c : newCase) {
            if (c.Status == 'Closed' && c.ContactId != null) {
                contactIds.add(c.ContactId);
            }
        }
        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, FirstName,name, Email, Last_Closed_Case_Number__c
            FROM Contact
            WHERE Id IN :contactIds
        ]);
        
        
        List<Survey> survey = [SELECT Id FROM Survey WHERE Name = 'Spectrum CSAT Form' LIMIT 1];
        
        system.debug('survey :: '+survey);

        Network community = [SELECT Id FROM Network WHERE Name = 'Spectrum CSAT Form'];
        
        List<SurveyInvitation> surveyInvitationList = new List<SurveyInvitation>();
        
        for(Case newCaseRec : newCase ){
         	
            if(newCaseRec.status == 'Closed' && oldmap.get(newCaseRec.id).status != newCaseRec.status){
              	String uniqueName = newCaseRec.CaseNumber;
                
                Contact con = contactMap.get(newCaseRec.contactId);
            	con.Last_Closed_Case_Number__c = newCaseRec.casenumber;
                contactMap.put(con.Id,con);
            
                if(survey.size() > 0){
                   SurveyInvitation invite = new SurveyInvitation(Name = uniqueName,SurveyId = survey[0].Id,ParticipantId = newCaseRec.contactId,CommunityId = community.Id,OptionsAllowGuestUserResponse= true);
                    surveyInvitationList.add(invite); 
                }
                	  
            }   
        }
        
        if(surveyInvitationList.size() > 0){
            insert surveyInvitationList;
        }
        
        
        set<id> newSurveyInvitationId = new set<id>();
        
        for(SurveyInvitation surInvRec : surveyInvitationList){
            newSurveyInvitationId.add(surInvRec.Id);
        }
        
        List<SurveyInvitation> surveyInvitationListId =  [
            SELECT Id, InvitationLink, ParticipantId
            FROM SurveyInvitation
            WHERE Id In :newSurveyInvitationId
        ];
        
        EmailTemplate surveyEmailTemplate = [SELECT Id, HtmlValue, DeveloperName FROM EmailTemplate where DeveloperName = 'Case_Closed_CSAT_Survey_Request' limit 1];
        
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        for(SurveyInvitation surInvRec : surveyInvitationListId){
            
            String htmlBody =  surveyEmailTemplate.HtmlValue;
            
            Contact con = contactMap.get(surInvRec.ParticipantId);
            
            String invitationUrl = surInvRec.InvitationLink; 
            
            htmlBody = htmlBody.replace('{!Contact.FirstName}', con.name);
            htmlBody = htmlBody.replace('{!Contact.Last_Closed_Case_Number__c}', con.Last_Closed_Case_Number__c);
            htmlBody = htmlBody.replace('[[SURVEY_INVITATION_URL]]', invitationUrl);
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { con.Email });
            mail.setSubject('We’d love your feedback!');
            mail.setHtmlBody(htmlBody);
            mail.setOrgWideEmailAddressId(Constants.ORG_WIDE_ADDRESS_ID_CUSTOMER_SERVICE);
            mail.setSaveAsActivity(false);
            mailList.add(mail);
        }
        
        Messaging.sendEmail(mailList);
        
        
    }

    public static void runFollowUpBatch(list<case> newCase , Map<id,case> oldmap){
        if (hasRun) return; // prevent double execution
        hasRun = true;
        
        Boolean shouldRunBatch = false;
        for(Case cs : newCase){
            if((cs.Test_Created_Date__c != null && cs.Test_Created_Date__c != oldMap.get(cs.Id).Test_Created_Date__c) 
               ||( cs.First_Follow_Up_Sent_On__c != null && cs.First_Follow_Up_Sent_On__c != oldMap.get(cs.Id).First_Follow_Up_Sent_On__c)){
                  shouldRunBatch = true;
                   break;
               }
        }
        if(shouldRunBatch){
             Database.executeBatch(new CaseFollowUpBatch(), 200);
        }
    }
   
}