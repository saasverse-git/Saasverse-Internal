public with sharing class ProjectTaskImporter {

    @AuraEnabled
    public static String uploadCSV(String csvData) { 
        List<Project_Task__c> taskList = new List<Project_Task__c>();
        //List<String> rows = csvData.split('\n');commented out
                                   List<String> rows = new List<String>();
                        String[] lines = csvData.split('\n');
                        String currentRow = '';
                        Boolean insideQuotes = false;
                        
                        for (String line : lines) {
                            if (insideQuotes) {
                                currentRow += '\n' + line;
                            } else {
                                currentRow = line;
                            }
                        
                            
                            Integer quoteCount = 0;
                            for (Integer i = 0; i < currentRow.length(); i++) {
                                if (currentRow.substring(i, i + 1) == '"') {
                                    quoteCount++;
                                }
                            }
                        
                           
                            insideQuotes = Math.mod(quoteCount, 2) != 0;
                        
                            if (!insideQuotes) {
                                rows.add(currentRow);
                                currentRow = '';
                            }
                        }



        // Prepare valid picklist values
        Schema.DescribeFieldResult statusField = Project_Task__c.Current_Task_Status__c.getDescribe();
        Set<String> validStatuses = new Set<String>();
        for (Schema.PicklistEntry entry : statusField.getPicklistValues()) {
            validStatuses.add(entry.getValue());
        }
        
   


        Integer skippedRows = 0;

        if (rows.size() <= 1) {
            return 'No data rows found.';
        }

        // Preload Projects
        Map<String, Id> projectMap = new Map<String, Id>();
        for (Project__c p : [SELECT Id, Name FROM Project__c]) {
            projectMap.put(p.Name.trim().toLowerCase(), p.Id);
        }

        // Preload Developers
        Map<String, Id> developerMap = new Map<String, Id>();
        for (Resource__c d : [SELECT Id, Name FROM Resource__c]) {
            developerMap.put(d.Name.trim().toLowerCase(), d.Id);
            System.debug('Resource Name---->'+ developerMap);
        }

        // Cache last known project and developer names
        String lastProjectName = '';
        String lastDevName = '';

        for (Integer i = 1; i < rows.size(); i++) {
            String row = rows[i];
            if (String.isBlank(row)) continue;

            List<String> cols = parseCSVRow(row.replace('\r', ''));

            // Ensure 21 columns
            while (cols.size() < 21) {
                cols.add('');
            }

            try {
                Project_Task__c task = new Project_Task__c();

                String projectName = String.isNotBlank(cols[0]) ? cols[0].trim().toLowerCase() : lastProjectName;
                String devName = String.isNotBlank(cols[1]) ? cols[1].trim().toLowerCase() : lastDevName;

                lastProjectName = projectName;
                lastDevName = devName;

               String taskName = cols[2].trim();
			if (String.isBlank(taskName)) {
   				 skippedRows++;
   			 	 System.debug('Skipping row ' + i + ' due to missing Task Name: ' + row);
   				 continue;
			}


                task.External_Reference__c = projectName + '_' + taskName + '_row' + String.valueOf(i);

                if (projectMap.containsKey(projectName)) {
                    task.Projects__c = projectMap.get(projectName);
                }

                if (developerMap.containsKey(devName)) {
                    task.Assigned_To1__c = developerMap.get(devName);
                }

                task.Task_Name__c = taskName;//changes
                task.Task_Assignment_Date__c = parseDate(cols[4]);
                task.Development_Start_Date__c = parseDate(cols[5]);
                task.Description__c = cols[6].trim();
                task.Criticality__c = cols[7].trim();
               
         

                task.Business_Expected_Completion_Date__c = parseDate(cols[8]);
                task.Developer_s_Expected_Completion_Date__c = parseDate(cols[9]);
                task.Estimated_End_Date__c = parseDate(cols[10]);

                String statusVal = cols[11].trim();
                if (!String.isBlank(statusVal)) {
                    Boolean foundStatus = false;
                    for (String valid : validStatuses) {
                        if (valid.toLowerCase() == statusVal.toLowerCase()) {
                            task.Current_Task_Status__c = valid;
                            foundStatus = true;
                            break;
                        }
                    }

                    if (!foundStatus) {
                        skippedRows++;
                        System.debug('Skipping row ' + i + ' due to invalid status: ' + statusVal);
                        continue;
                    }
                }

                task.Estimated_Effort_in_hrs__c = tryParseDecimal(cols[12]);
                task.Is_Active__c = toBoolean(cols[13]);
                task.Requirement_Gathering_Competed__c = toBoolean(cols[14]);
                task.Understanding_Completed__c = toBoolean(cols[15]);
                task.Is_Working_on_Other_Tickets__c = toBoolean(cols[16]);
                task.Major_Risks_Blockers__c = cols[17].trim();
                task.Real_Business_Hours_Needed__c = tryParseDecimal(cols[18]);
                task.Hours_So_Far_Consumed__c = tryParseDecimal(cols[19]);
                task.RAG_Status__c = cols[20].trim();

                taskList.add(task);

            } catch (Exception e) {
                skippedRows++;
                System.debug('Skipping row ' + i + ' due to error: ' + e.getMessage());
            }
        }

        if (!taskList.isEmpty()) {
            upsert taskList Project_Task__c.External_Reference__c;
        }

        return taskList.size() + ' Project Tasks processed. ' + skippedRows + ' row(s) skipped due to wrong values or Empty Rows.';
    }

    private static Date parseDate(String value) {
        if (String.isBlank(value)) return null;
        try {
            List<String> parts = value.trim().split('/');
            if (parts.size() == 3) {
                return Date.newInstance(
                    Integer.valueOf(parts[2]),
                    Integer.valueOf(parts[1]),
                    Integer.valueOf(parts[0])
                );
            }
        } catch (Exception e) {}
        return null;
    }





    private static Decimal tryParseDecimal(String value) {
        try {
            return Decimal.valueOf(value.trim());
        } catch (Exception e) {
            return null;
        }
    }

    private static Boolean toBoolean(String value) {
        String v = value.trim().toLowerCase();
        return v == 'yes' || v == 'true' || v == '1';
    }

    private static List<String> parseCSVRow(String row) {
    List<String> result = new List<String>();
    Boolean inQuotes = false;
    String current = '';
    
    for (Integer i = 0; i < row.length(); i++) {
        String c = row.substring(i, i + 1);

        if (c == '"') {
            // Handle escaped quotes ("")
            if (inQuotes && i + 1 < row.length() && row.substring(i + 1, i + 2) == '"') {
                current += '"';
                i++; // Skip next quote
            } else {
                inQuotes = !inQuotes;
            }
        } else if (c == ',' && !inQuotes) {
            result.add(current);
            current = '';
        } else {
            current += c;
        }
    }
    result.add(current);

    return result;
}



    
   


}