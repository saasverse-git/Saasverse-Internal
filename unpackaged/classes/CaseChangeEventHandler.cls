public class CaseChangeEventHandler {

    public static void handleAfterInsert(List<CaseChangeEvent> changeEvents) {
        List<CaseChangeEvent> createEvents = new List<CaseChangeEvent>();
        List<CaseChangeEvent> updateEvents = new List<CaseChangeEvent>();

        for (CaseChangeEvent eventRec : changeEvents) {
            EventBus.ChangeEventHeader header = eventRec.ChangeEventHeader;
			
            if (header.changeType == 'CREATE') {
                createEvents.add(eventRec);
            } else if (header.changeType == 'UPDATE') {
                updateEvents.add(eventRec);
            }
        }

        if (!createEvents.isEmpty()) {
            handleCreateEvents(createEvents);
        }

        if (!updateEvents.isEmpty()) {
            handleUpdateEvents(updateEvents);
        }
    }

    private static void handleCreateEvents(List<CaseChangeEvent> createEvents) {
        Set<Id> caseIds = new Set<Id>();

        for (CaseChangeEvent e : createEvents) {
            List<String> recordIds = e.ChangeEventHeader.getRecordIds();
            for (String recordId : recordIds) {
                caseIds.add((Id)recordId);
            }
        }

        if (!caseIds.isEmpty()) {
            handleContactLinking(caseIds, null);
        }
    }

    private static void handleUpdateEvents(List<CaseChangeEvent> updateEvents) {
        Set<Id> updatedCaseIds = new Set<Id>();
        Map<Id, List<String>> caseFieldChanges = new Map<Id, List<String>>();

        for (CaseChangeEvent e : updateEvents) {
            EventBus.ChangeEventHeader header = e.ChangeEventHeader;
            List<String> fieldSet = header.getChangedFields();

            for (Id caseId : e.ChangeEventHeader.getRecordIds()) {
                updatedCaseIds.add(caseId);
                caseFieldChanges.put(caseId, fieldSet);
            }
        }

        if (!updatedCaseIds.isEmpty()) {
            system.debug('Handle case change update');
            handleContactLinking(updatedCaseIds, caseFieldChanges);
            populateCaseMetrics(updatedCaseIds, caseFieldChanges);
            handleChatterPost(updatedCaseIds, caseFieldChanges);
        }
    }
	
        
    private static void handleChatterPost(Set<Id> caseIds, Map<Id, List<String>> changedFieldsMap) {
        System.debug('Inside handleChatterPost');
        System.debug('updated caseIds:- ' + caseIds);
        
        List<Case> caseList = [ SELECT Id, custom_reason_for_contact__c FROM Case WHERE Id IN :caseIds ];
    
    List<FeedItem> postsToInsert = new List<FeedItem>();
    
    for (Case c : caseList) {

        if (
            c.custom_reason_for_contact__c == 'Complaint-Quality' ||
            c.custom_reason_for_contact__c == 'Injury' ||
            c.custom_reason_for_contact__c == 'Property Damage'
        ) {
            FeedItem fi = new FeedItem();
            fi.ParentId = c.Id;
            fi.Body =
                'Agent Reminder\n'
                + '*  Verify TS Product.  Advise to Stop Use.  Requests photos, docs, proof of purchase.\n\n'
                + '• Requested outcome: Replacement/Refund (Use Additional Reason for Contact: option Refund Replacement or Settlement request dependencies)\n'
                + '• Do you have the original instruction booklet?  Yes/No (Instruction Booklet)\n'
                + '\tCan you provide the manual code on the back of the manual? (Instruction Booklet number)  if yes then Instruction Booklet Field should be populated)\n'
                + '• Please describe what happened (and please provide any details you might remember such what settings were used, what were you cooking.)\n'
                + '• Please include the following pictures with your reply:\n'
                + '  o Both ends of the cord\n'
                + '  o The prongs/location where the cord plugs into the unit\n'
                + '  o Silver product label on the back of the product.\n'
                + '  o Front and side views of the product\n'
                + '  o Picture of the unit in the location where it was being used.\n'
                + '  o If cm purchased from retailer, please include a picture or COPY of the proof of purchase.\n\n'
                + 'Provide the customer with the following information\n'
                + 'Thank you, {CustomerName} Here is your ticket number: XXXXX\n'
                + 'If you have any questions you can reach us directly at 973-287-5134\n'
                + 'If we have asked for documentation, advise that the customer can attach in their email and send to customerservice@tristarproductsinc.com.\n'
                + 'Only offer the fax if customer is unable to email - 973-575-6897.';
                    fi.Type = 'TextPost';
                    postsToInsert.add(fi);
                }
        
        if(c.custom_reason_for_contact__c == 'Arbitration Opt-Out'){
             FeedItem fi2 = new FeedItem();
                fi2.ParentId = c.Id;
                fi2.Body =
                    'Agent Reminder – please complete the following information\n\n'
                    + 'Purchaser:\n'
                    + '   Full name\n'
                    + '   Phone number\n'
                    + '   E-mail address\n'
                    + '   Mailing address\n\n'
                    + 'Product:\n'
                    + '   Name of the product:\n'
                    + '   Model:\n'
                    + '   Place of purchase:\n'
                    + '   Date of purchase:\n'
                    + '   Order number (if available):\n\n'
                    + 'Advise customer:  Please remember to keep a copy of your proof of purchase in a safe place.';
                fi2.Type = 'TextPost';
                postsToInsert.add(fi2);
        }
        
        if(c.custom_reason_for_contact__c == 'Fraud Credit Card'){
             FeedItem fi3 = new FeedItem();
             fi3.ParentId = c.Id;
             fi3.Body =
                'Agent Reminder\n\n'
                + 'Please ask the customer the following questions.\n'
                + 'Do you remember the name of the agent you spoke with?\n'
                + 'May I have the day and time you called, if you can remember?\n'
                + 'Please provide the phone number you use to call and place your order.\n'
                + 'Search for or ask for the order number or confirmation number.  Enter here.\n\n'
                + 'Can you tell what items were purchased?\n'
                + 'Can you provide the name, phone number, address of the vendor and date on the fraudulent entry (or entries)?\n'
                + 'Do have information that provides the name, phone number and address of the recipient?\n'
                + 'Did you inform your credit card company about the issue?\n'
                + 'Can our call center manager call you directly if they need more information?';
            fi3.Type = 'TextPost';
           postsToInsert.add(fi3);
    	}
         if (c.custom_reason_for_contact__c == 'Fraud Order') { 
            FeedItem fi4 = new FeedItem();
            fi4.ParentId = c.Id;
            fi4.Body =
                'Agent Reminder\n\n'
                + 'Please ask the customer the following questions.\n'
                + 'Is there anyone else in the house hold that might have placed the order?\n'
                + 'Did you inform your credit card company about the issue?\n\n'
                + 'Are there any other charges on your credit card that you do not recognize?\n'
                + 'If customer answers yes ask the * questions:\n'
                + '*  Can you provide the date, name, phone number, address of the vendor on the entry (or entries)?\n'
                + '*  Do have information that provides the name, phone number and address of the recipient?\n'
                + '*  Can our call center manager call you directly if they need more information?';
            fi4.Type = 'TextPost';
            postsToInsert.add(fi4);
        }
    }
    if (!postsToInsert.isEmpty()) {
        insert postsToInsert;
    }
    }
    
    private static void handleContactLinking(Set<Id> caseIds, Map<Id, List<String>> changedFieldsMap) {
    Set<Id> filteredIds = new Set<Id>();

    for (Id caseId : caseIds) {
        if (changedFieldsMap == null || 
            (changedFieldsMap.containsKey(caseId) && changedFieldsMap.get(caseId).contains('SuppliedEmail'))) {
            filteredIds.add(caseId);
        }
    }

    if (filteredIds.isEmpty()) return;

    List<Case> caseList = [
        SELECT Id, SuppliedEmail, SuppliedName, SuppliedPhone, ContactId
        FROM Case
        WHERE Id IN :filteredIds AND SuppliedEmail != null
    ];

    Map<String, List<Case>> emailToCases = new Map<String, List<Case>>();
    Set<String> emailKeys = new Set<String>();

    for (Case c : caseList) {
        String emailKey = c.SuppliedEmail.trim().toLowerCase();
        emailKeys.add(emailKey);
        if (!emailToCases.containsKey(emailKey)) {
            emailToCases.put(emailKey, new List<Case>());
        }
        emailToCases.get(emailKey).add(c);
    }

    Map<String, Contact> existingContactMap = new Map<String, Contact>();
    for (Contact con : [SELECT Id, Email, LastName, Phone FROM Contact WHERE Email IN :emailKeys]) {
        existingContactMap.put(con.Email.trim().toLowerCase(), con);
    }

    List<Contact> contactsToInsert = new List<Contact>();
    Map<String, Contact> newEmailToContact = new Map<String, Contact>();

    for (String emailKey : emailToCases.keySet()) {
        if (!existingContactMap.containsKey(emailKey) && !newEmailToContact.containsKey(emailKey)) {
            Case sample = emailToCases.get(emailKey)[0];
            Contact con = new Contact(
                LastName = String.isNotBlank(sample.SuppliedName) ? sample.SuppliedName : 'Unknown',
                Email = sample.SuppliedEmail.trim(),
                Phone = sample.SuppliedPhone
            );
            contactsToInsert.add(con);
            newEmailToContact.put(emailKey, con);
        }
    }

    if (!contactsToInsert.isEmpty()) {
        try {
            insert contactsToInsert;
            for (Contact con : contactsToInsert) {
                newEmailToContact.put(con.Email.trim().toLowerCase(), con);
            }
        } catch (DmlException ex) {
            for (Integer i = 0; i < ex.getNumDml(); i++) {
                if (ex.getDmlMessage(i).containsIgnoreCase('DUPLICATES_DETECTED')) {
                    CaseUtility.insertLog(
                        'Duplicate Contact Skipped',
                        'Blocked Contact: ' + JSON.serialize(contactsToInsert[i]),
                        'CaseChangeEventHandler'
                    );
                }
            }
        }
    }

    // 🆕 Update existing contact details
    List<Contact> contactsToUpdate = new List<Contact>();
    for (String emailKey : emailToCases.keySet()) {
        if (existingContactMap.containsKey(emailKey)) {
            Contact con = existingContactMap.get(emailKey);
            Case sample = emailToCases.get(emailKey)[0];

            Boolean needsUpdate = false;

            if (String.isNotBlank(sample.SuppliedName) && sample.SuppliedName != con.LastName) {
                con.LastName = sample.SuppliedName;
                needsUpdate = true;
            }

            if (String.isNotBlank(sample.SuppliedPhone) && sample.SuppliedPhone != con.Phone) {
                con.Phone = sample.SuppliedPhone;
                needsUpdate = true;
            }

            if (needsUpdate) {
                contactsToUpdate.add(con);
            }
        }
    }

    if (!contactsToUpdate.isEmpty()) {
        update contactsToUpdate;
    }

    Map<String, Contact> allEmailToContact = new Map<String, Contact>();
    allEmailToContact.putAll(existingContactMap);
    allEmailToContact.putAll(newEmailToContact);

    List<Case> casesToUpdate = new List<Case>();
    for (String emailKey : emailToCases.keySet()) {
        Contact matched = allEmailToContact.get(emailKey);
        if (matched != null) {
            for (Case c : emailToCases.get(emailKey)) {
                c.ContactId = matched.Id;
                casesToUpdate.add(c);
            }
        }
    }

    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
    }
}


    /*private static void handleContactLinking(Set<Id> caseIds, Map<Id, List<String>> changedFieldsMap) {
        Set<Id> filteredIds = new Set<Id>();

        for (Id caseId : caseIds) {
            // For CREATEs: changedFieldsMap might be null
            if (changedFieldsMap == null || 
                (changedFieldsMap.containsKey(caseId) && changedFieldsMap.get(caseId).contains('SuppliedEmail'))) {

                filteredIds.add(caseId);
            }
        }

        if (filteredIds.isEmpty()) return;

        List<Case> caseList = [
            SELECT Id, SuppliedEmail, SuppliedName, ContactId
            FROM Case
            WHERE Id IN :filteredIds AND SuppliedEmail != null
        ];

        Map<String, List<Case>> emailToCases = new Map<String, List<Case>>();
        Set<String> emailKeys = new Set<String>();

        for (Case c : caseList) {
            String emailKey = c.SuppliedEmail.trim().toLowerCase();
            emailKeys.add(emailKey);
            if (!emailToCases.containsKey(emailKey)) {
                emailToCases.put(emailKey, new List<Case>());
            }
            emailToCases.get(emailKey).add(c);
        }

        Map<String, Contact> existingContactMap = new Map<String, Contact>();
        for (Contact con : [SELECT Id, Email FROM Contact WHERE Email IN :emailKeys]) {
            existingContactMap.put(con.Email.trim().toLowerCase(), con);
        }

        List<Contact> contactsToInsert = new List<Contact>();
        Map<String, Contact> newEmailToContact = new Map<String, Contact>();

        for (String emailKey : emailToCases.keySet()) {
            if (!existingContactMap.containsKey(emailKey) && !newEmailToContact.containsKey(emailKey)) {
                Case sample = emailToCases.get(emailKey)[0];
                Contact con = new Contact(
                    LastName = String.isNotBlank(sample.SuppliedName) ? sample.SuppliedName : 'Unknown',
                    Email = sample.SuppliedEmail.trim()
                );
                contactsToInsert.add(con);
                newEmailToContact.put(emailKey, con);
            }
        }

        if (!contactsToInsert.isEmpty()) {
            try {
                insert contactsToInsert;
                for (Contact con : contactsToInsert) {
                    newEmailToContact.put(con.Email.trim().toLowerCase(), con);
                }
            } catch (DmlException ex) {
                for (Integer i = 0; i < ex.getNumDml(); i++) {
                    if (ex.getDmlMessage(i).containsIgnoreCase('DUPLICATES_DETECTED')) {
                        CaseUtility.insertLog(
                            'Duplicate Contact Skipped',
                            'Blocked Contact: ' + JSON.serialize(contactsToInsert[i]),
                            'CaseChangeEventHandler'
                        );
                    }
                }
            }
        }

        Map<String, Contact> allEmailToContact = new Map<String, Contact>();
        allEmailToContact.putAll(existingContactMap);
        allEmailToContact.putAll(newEmailToContact);

        List<Case> casesToUpdate = new List<Case>();
        for (String emailKey : emailToCases.keySet()) {
            Contact matched = allEmailToContact.get(emailKey);
            if (matched != null) {
                for (Case c : emailToCases.get(emailKey)) {
                    c.ContactId = matched.Id;
                    casesToUpdate.add(c);
                }
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }*/

    private static void populateCaseResolutionTime(Set<Id> caseIds, Map<Id, List<String>> changedFieldsMap) {
        Set<Id> statusChangedIds = new Set<Id>();
        for (Id caseId : caseIds) {
            if (changedFieldsMap.get(caseId).contains('Status')) {
                statusChangedIds.add(caseId);
            }
        }
        if (statusChangedIds.isEmpty()) return;

        List<Case> caseList = [
            SELECT Id, Status 
            FROM Case 
            WHERE Id IN :statusChangedIds AND Status = 'Closed'
        ];

        Set<Id> closedCaseIds = new Set<Id>();
        for (Case c : caseList) {
            closedCaseIds.add(c.Id);
        }

        List<Case> toUpdate = new List<Case>();

        if (!closedCaseIds.isEmpty()) {
            Map<Id, Decimal> timeMap = CaseUtility.calculateBusinessHoursBetweenStatuses(
                closedCaseIds,
                null,
                'Closed',
                null
            );

            for (Case c : caseList) {
                if (timeMap.containsKey(c.Id)) {
                    c.Case_Resolution_Time__c = timeMap.get(c.Id);
                    toUpdate.add(c);
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static void populateCaseMetrics(Set<Id> caseIds, Map<Id, List<String>> changedFieldsMap) {
        Set<Id> statusChangedIds = new Set<Id>();
        for (Id caseId : caseIds) {
            if (changedFieldsMap.get(caseId).contains('Status')) {
                statusChangedIds.add(caseId);
            }
        }
        if (statusChangedIds.isEmpty()) return;
		system.debug('Inside populateCaseMetrics');
        List<Case> caseList = [
            SELECT Id, Status, CreatedDate, Accepted_By__c, Case_Resolution_Time__c, First_Response_Time_hrs__c
            FROM Case 
            WHERE Id IN :statusChangedIds
        ];

        Set<Id> toCalculateResolution = new Set<Id>();
        Set<Id> toCalculateFirstResponse = new Set<Id>();

        for (Case c : caseList) {
           if ((c.Status == 'Closed' || 
                c.Status == 'Closed - no cm response' || 
                c.Status == 'Closed - Fwded to TS_TM') 
                && c.Case_Resolution_Time__c == null) {

                toCalculateResolution.add(c.Id);
            }
            system.debug('LIne 343--'+c.Accepted_By__c);    
            system.debug('LIne 344--'+c.First_Response_Time_hrs__c);  
            system.debug('LIne 345--'+c.Status);  
            if (c.Accepted_By__c != null && c.First_Response_Time_hrs__c == null && c.Status == 'Open') {
                toCalculateFirstResponse.add(c.Id);
            }
        }

        // Fetch CaseHistories once
        Map<Id, List<CaseHistory>> historyMap = CaseUtility.getCaseStatusHistory(caseIds);

        // Process metrics
        Map<Id, Decimal> resolutionMap = new Map<Id, Decimal>();
        Map<Id, Decimal> responseMap = new Map<Id, Decimal>();

        if (!toCalculateResolution.isEmpty()) {
            resolutionMap = CaseUtility.calculateBusinessHoursBetweenStatuses(
                toCalculateResolution,
                null,
                'Closed',
                null
            );
        }
		system.debug('toCalculateFirstResponse-->'+toCalculateFirstResponse);
        if (!toCalculateFirstResponse.isEmpty()) {
            system.debug('toCalculateFirstResponse inside-->'+toCalculateFirstResponse);
            responseMap = CaseUtility.calculateBusinessHoursBetweenStatuses(
                toCalculateFirstResponse,
                null,
                'Open',
                null
            );
        }
		system.debug('resolutionMap-->'+resolutionMap);
        List<Case> toUpdate = new List<Case>();

        for (Case c : caseList) {
            Boolean changed = false;
            if (resolutionMap.containsKey(c.Id)) {
                c.Case_Resolution_Time__c = resolutionMap.get(c.Id);
                changed = true;
            }
            if (responseMap.containsKey(c.Id)) {
                c.First_Response_Time_hrs__c = responseMap.get(c.Id);
                changed = true;
            }
            if (changed) {
                toUpdate.add(c);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
 
    public static void handleAfterInsert_simulated(Set<Id> caseIds, String changeType, Map<Id, List<String>> changedFieldsMap) {
        if (changeType == 'CREATE') {
            handleContactLinking(caseIds, null);
        } else if (changeType == 'UPDATE') {
            
            handleContactLinking(caseIds, changedFieldsMap);
            populateCaseMetrics(caseIds, changedFieldsMap);
             populateCaseResolutionTime(caseIds, changedFieldsMap);
        }
}
}