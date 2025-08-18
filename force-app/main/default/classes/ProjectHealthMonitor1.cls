public class ProjectHealthMonitor1 {

    public static void runCheckProjectHealth() {
        List<Project__c> allProjects = [SELECT Id, Name FROM Project__c];

        for (Project__c project : allProjects) {
            List<Project_Health_Update__c> updates = [
                SELECT Id, Health_Status__c, CreatedDate 
                FROM Project_Health_Update__c
                WHERE Project__c = :project.Id
                ORDER BY CreatedDate DESC 
                LIMIT 5
            ];

            Integer redCount = 0;
            Integer orangeCount = 0;

            for (Project_Health_Update__c healthUpdate : updates) {
                if (healthUpdate.Health_Status__c == 'Red') {
                    redCount++;
                } else if (healthUpdate.Health_Status__c == 'Orange') {
                    orangeCount++;
                }
            }

          
            if (redCount >= 3) {
                sendEmailToAddress('vipinsingh@saasverse.in', '2F00XNS000008XObd'); 
            } 
            else if (orangeCount == 5) {
                sendEmailToAddress('vipinsingh@saasverse.in', '2F00XNS000008XHET'); 
            }
        }
    }

   
    private static void sendEmailToAddress(String toAddress, Id templateId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { toAddress });
        mail.setTemplateId(templateId);
        mail.setSaveAsActivity(false);

        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

}