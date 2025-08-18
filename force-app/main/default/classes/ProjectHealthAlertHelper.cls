public class ProjectHealthAlertHelper {
    
    public static void processHealthAlerts(Set<Id> projectIds) {
        
        List<Project_Health_Update__c> allUpdates = [SELECT Id, Project__c, Health_Status__c, Update_Date__c, Project__r.Name, Resource__r.Name
            										 FROM Project_Health_Update__c WHERE Project__c IN :projectIds
            										 ORDER BY Project__c, Update_Date__c DESC ];
        
         Map<Id, List<Project_Health_Update__c>> projectToUpdates = new Map<Id, List<Project_Health_Update__c>>();

        for (Project_Health_Update__c upd : allUpdates) {
            if (!projectToUpdates.containsKey(upd.Project__c)) {
                projectToUpdates.put(upd.Project__c, new List<Project_Health_Update__c>());
            }

            // Keep only the latest 5 updates
            if (projectToUpdates.get(upd.Project__c).size() < 5) {
                projectToUpdates.get(upd.Project__c).add(upd);
            }
        }

        for (Id projectId : projectToUpdates.keySet()) {
            List<Project_Health_Update__c> updates = projectToUpdates.get(projectId);

            if (updates == null || updates.isEmpty()) continue;

            String latest = updates[0].Health_Status__c;

            //  Case 1: Direct jump from GREEN to RED
            /*if (updates.size() >= 2) {
                if (updates[0].Health_Status__c == 'RED' && updates[1].Health_Status__c == 'GREEN') {
                    sendEmail(projectId, 'Alert: 🔴 Project jumped from GREEN to RED', updates);
                    continue;
                }
            }*/
            if (updates.size() >= 2) {
                if (updates[0].Health_Status__c == 'RED') {
                    sendEmail(projectId, 'Alert: 🔴 Project jumped', updates);
                    continue;
                }
            }

            //  Case 2: Three consecutive RED
            if (updates.size() >= 3) {
                Boolean allRed = true;
                for (Integer i = 0; i < 3; i++) {
                    if (updates[i].Health_Status__c != 'RED') {
                        allRed = false;
                        break;
                    }
                }
                if (allRed) {
                    sendEmail(projectId, 'Critical: 3x  🔴 RED alerts', updates);
                    continue;
                }
            }

            //  Case 3: Five ORANGE or 4 ORANGE + 1 RED (no GREEN)
            if (updates.size() >= 5) {
                Integer orangeCount = 0;
                Integer redCount = 0;
                Integer greenCount = 0;

                for (Integer i = 0; i < 5; i++) {
       
                    String status = updates[i].Health_Status__c;

                    if (status == 'ORANGE') orangeCount++;
                    else if (status == 'RED') redCount++;
                    else if (status == 'GREEN') greenCount++;
                }

                if (greenCount == 0 && (orangeCount == 3 || orangeCount == 5 || (orangeCount == 4 && redCount == 1))) {
                    sendEmail(projectId, 'Warning: Orange/Red health trend', updates);
                }
            }
        }
    }

    
    private static void sendEmail(Id projectId, String subject, List<Project_Health_Update__c> updates) {
    
        List<User> targetUsers = [SELECT Id, Email FROM User WHERE Name = 'Test User' AND IsActive = true];
        						//SELECT Id, Email FROM User WHERE Name = 'Saasverse Sales' AND IsActive = true
            					//WHERE Name IN ('Saasverse Sales', 'Saasverse Finance') AND IsActive = true
    
        if (targetUsers.isEmpty()) {
            System.debug('No target users found.');
            return;
        }
    
        Project_Health_Update__c latest = updates[0];
    
        String body = 'Dear Team,\n\n';
        body += 'This is an important update regarding the Health Status of the project:- ' + latest.Project__r.Name + '\n';
        body += 'Resource Name:- '+ latest.Resource__r.Name + '\n';
        body += 'Latest Health:- ' + latest.Health_Status__c + '\n';
        body += '\nRecent Health Updates:- \n';
    
        for (Project_Health_Update__c u : updates) {
            body += u.Update_Date__c.format() + ':- ' + u.Health_Status__c + '\n';
        }
    
        body += '\nThe project has entered or remained in a critical state and requires your attention.\n Please review the project status and coordinate with the assigned resource for immediate actions.\n \nBest Regards,\nSaasverse Technologies';
    
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    
        for (User u : targetUsers) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(u.Id);
            mail.setSaveAsActivity(false);
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            mails.add(mail);
        }
    
        Messaging.sendEmail(mails);
    }
}