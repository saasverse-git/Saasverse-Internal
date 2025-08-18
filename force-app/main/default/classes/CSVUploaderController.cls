public with sharing class CSVUploaderController {
    @AuraEnabled
    public static String uploadCSV(String csvData) {
        List<String> rows = csvData.split('\n');
        List<Timesheet_Entry__c> recordsToUpsert = new List<Timesheet_Entry__c>();
        List<String> errors = new List<String>();

        Map<String, Id> cachedResourceIds = new Map<String, Id>();
        Map<String, Id> cachedProjectIds = new Map<String, Id>();
        Map<String, Timesheet_Entry__c> existingTimesheetsMap = new Map<String, Timesheet_Entry__c>();

        Set<String> compositeKeys = new Set<String>();

        // Loop #1: Prepare lookups & collect composite keys
        for (Integer i = 1; i < rows.size(); i++) {
            List<String> columns = rows[i].split(',');
            if (columns.size() < 10) continue;

            String devName = columns[0].trim();
            String projName = columns[1].trim();
            String startDateStr = columns[2].trim();
            String endDateStr = columns[3].trim();

            Date startDate, endDate;
            try { startDate = Date.valueOf(startDateStr); } catch (Exception e) { continue; }
            try { endDate = Date.valueOf(endDateStr); } catch (Exception e) { continue; }

            // Cache Resource__c
            if (!cachedResourceIds.containsKey(devName)) {
                List<Resource__c> resList = [SELECT Id FROM Resource__c WHERE Name = :devName LIMIT 1];
                if (resList.isEmpty()) continue;
                cachedResourceIds.put(devName, resList[0].Id);
            }

            // Cache Project__c
            if (!cachedProjectIds.containsKey(projName)) {
                List<Project__c> projList = [SELECT Id FROM Project__c WHERE Name = :projName LIMIT 1];
                if (projList.isEmpty()) continue;
                cachedProjectIds.put(projName, projList[0].Id);
            }

            String key = cachedResourceIds.get(devName) + '|' + cachedProjectIds.get(projName) + '|' + startDate + '|' + endDate;
            compositeKeys.add(key);
        }

        // Query existing timesheet records with matching composite keys
        if (!compositeKeys.isEmpty()) {
            List<Timesheet_Entry__c> existingRecords = [
                SELECT Id, Resource__c, Project__c, Start_Date__c, End_Date__c
                FROM Timesheet_Entry__c
                WHERE Resource__c IN :cachedResourceIds.values()
                  AND Project__c IN :cachedProjectIds.values()
            ];
            for (Timesheet_Entry__c rec : existingRecords) {
                String key = rec.Resource__c + '|' + rec.Project__c + '|' + rec.Start_Date__c + '|' + rec.End_Date__c;
                existingTimesheetsMap.put(key, rec);
            }
        }

        // Loop #2: Create or update records
        for (Integer i = 1; i < rows.size(); i++) {
            List<String> columns = rows[i].split(',');
            System.debug('columns size is --->'+columns.size());
            if(columns.size() < 10) {
                System.debug('Reached Here !!!');
                errors.add('Row ' + i + ' skipped: Insufficient columns.');
                continue;
            }

            String devName        = columns[0].trim();
            String projName       = columns[1].trim();
            String startDateStr   = columns[2].trim();
            String endDateStr     = columns[3].trim();
            String workedDaysStr  = columns[4].trim();
            String actualDaysStr  = columns[5].trim();
            String capturedHours  = columns[6].trim();
            
            String approvedStr    = columns[7].trim();
            String submittedOnStr = columns[8].trim();
            String status         = columns[9].trim();
            system.debug('Status ==:'+Status);
            Date startDate, endDate;
            try { startDate = Date.valueOf(startDateStr); } catch (Exception e) {
                errors.add('Row ' + i + ': Invalid Start Date - ' + startDateStr); continue;
            }
            try { endDate = Date.valueOf(endDateStr); } catch (Exception e) {
                errors.add('Row ' + i + ': Invalid End Date - ' + endDateStr); continue;
            }

            Id resourceId = cachedResourceIds.get(devName);
            if (resourceId == null) {
                errors.add('Row ' + i + ': Developer not found - ' + devName);
                continue;
            }

            Id projectId = cachedProjectIds.get(projName);
            if (projectId == null) {
                errors.add('Row ' + i + ': Project not found - ' + projName);
                continue;
            }

            String key = resourceId + '|' + projectId + '|' + startDate + '|' + endDate;
            Timesheet_Entry__c ts = existingTimesheetsMap.containsKey(key) ?
                existingTimesheetsMap.get(key) :
                new Timesheet_Entry__c(Resource__c = resourceId, Project__c = projectId, Start_Date__c = startDate, End_Date__c = endDate);

            try {
                ts.Worked_Days__c        = Integer.valueOf(workedDaysStr);
            } catch (Exception e) { ts.Worked_Days__c = 0; }
/*
            try {
                ts.Actual_Days_worked__c = Integer.valueOf(actualDaysStr);
            } catch (Exception e) { ts.Actual_Days_worked__c = 0; }
*/         
            try {
                ts.Captured_Hours__c = Integer.valueOf(capturedHours);
            } catch (Exception e) { ts.Captured_Hours__c = 0; }
            

            //ts.Billable__c           = billableStr.toLowerCase() == 'yes';
            ts.Approved__c           = approvedStr.toLowerCase() == 'yes';

            try {
                ts.Submitted_On__c = Datetime.valueOf(submittedOnStr);
            } catch (Exception e) {
                ts.Submitted_On__c = null;
            }

            ts.Status__c = status;

            recordsToUpsert.add(ts);
        }

        if (!recordsToUpsert.isEmpty()) {
            upsert recordsToUpsert;
        }

        return '✅ Processed: ' + recordsToUpsert.size() +
               '\n⚠️ Skipped: ' + errors.size() +
               (errors.isEmpty() ? '' : '\n\n❌ Errors:\n' + String.join(errors, '\n'));
    }
}