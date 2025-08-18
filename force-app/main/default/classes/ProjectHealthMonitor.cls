public class ProjectHealthMonitor {

    public static void runCheck() {
        List<Project__c> allProjects = [SELECT Id, Name FROM Project__c];

       
        for (Project__c project : allProjects) {
            
            List<Project_Health_Update__c> updates = [SELECT Id, Health_Status__c, CreatedDate FROM Project_Health_Update__c
                								      WHERE Project__c = :project.Id ORDER BY CreatedDate DESC LIMIT 5];
                

            if (updates.size() >= 3 && updates[0].Health_Status__c == 'Red' && updates[1].Health_Status__c == 'Red' && updates[2].Health_Status__c == 'Red'){
                
               sendEmail(project.Id, '2F00XNS000008XObd'); // Red alert
            }

            if (updates.size() == 5 && updates[0].Health_Status__c == 'Orange' && 
               						   updates[1].Health_Status__c == 'Orange' &&
                					   updates[2].Health_Status__c == 'Orange' &&
               						   updates[3].Health_Status__c == 'Orange' &&
               						   updates[4].Health_Status__c == 'Orange'   ){
                                           
                sendEmail(project.Id, '2F00XNS000008XHET'); // Orange alert
            }
        }
    }

    private static void sendEmail(Id projectId, Id templateId) {
        Id userId = '2F005NS00000JUINx'; 

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(userId); // Who receives email
        mail.setTemplateId(templateId); // Your email template
        mail.setSaveAsActivity(false);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}