public class DailyProjectTaskEmailReminder {

    public static void sendDailyProjectTaskSummaryEmail() {
        List<Project_Task__c> allTasks = [
            SELECT Id,
                   Name,
                   Projects__c,
                   Projects__r.Name,
                   Assigned_To1__c,
                   Assigned_To1__r.Name,
                   Developer_Name__c,
                   Hours_so_Far_consumed__c,
                   Development_Start_Date__c,
                   LastModifiedDate,
                   CreatedDate,
                   RAG__c,
                   Is_Active__c,
                   Current_Task_Status__c
            FROM Project_Task__c
            WHERE Assigned_To1__c != null
                  AND Projects__c != null
                  AND Is_Active__c = true
                  AND Development_Start_Date__c != null
                  AND Current_Task_Status__c NOT IN (
                      'Task Completed', 'UAT Completed', 'UAT In Progress',
                      'On Hold', 'Deployment Issue', 'Development Completed', 'Testing In Progress'
                  )
                  AND (LastModifiedDate >= LAST_N_DAYS:15 OR CreatedDate >= LAST_N_DAYS:15)
            ORDER BY Assigned_To1__r.Name, Projects__r.Name, Developer_Name__c
        ];

        // Group: Assigned To → Project → Developer
        Map<Id, Map<Id, Map<String, List<Project_Task__c>>>> dataMap = new Map<Id, Map<Id, Map<String, List<Project_Task__c>>>>();
        Map<Id, String> assignedToNames = new Map<Id, String>();
        Map<Id, String> projectNames = new Map<Id, String>();

        for (Project_Task__c task : allTasks) {
            Id assignedToId = task.Assigned_To1__c;
            Id projectId = task.Projects__c;
            String devName = task.Developer_Name__c != null ? task.Developer_Name__c : 'N/A';

            if (!dataMap.containsKey(assignedToId)) {
                dataMap.put(assignedToId, new Map<Id, Map<String, List<Project_Task__c>>>());
                assignedToNames.put(assignedToId, task.Assigned_To1__r.Name);
            }
            if (!dataMap.get(assignedToId).containsKey(projectId)) {
                dataMap.get(assignedToId).put(projectId, new Map<String, List<Project_Task__c>>());
                projectNames.put(projectId, task.Projects__r.Name);
            }
            if (!dataMap.get(assignedToId).get(projectId).containsKey(devName)) {
                dataMap.get(assignedToId).get(projectId).put(devName, new List<Project_Task__c>());
            }

            dataMap.get(assignedToId).get(projectId).get(devName).add(task);
        }

        String body = '<html><body style="font-family: Arial;">';
        body += '<p>Hello,</p>';
        body += '<p>Here is the daily summary of developer project tasks:</p>';
        body += '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead style="background-color: #f2f2f2;">';
        body += '<tr>';
        body += '<th>Assigned To</th>';
        body += '<th>Project Name</th>';
        body += '<th>Developer Name</th>';
        body += '<th>Task Name</th>';
        body += '<th>Dev Start Date</th>';
        body += '<th>Hours Consumed</th>';
        body += '<th>Last Modified</th>';
        body += '<th>Current Status</th>';
        body += '<th>RAG</th>';
        body += '</tr></thead><tbody>';

        for (Id assignedToId : dataMap.keySet()) {
            Map<Id, Map<String, List<Project_Task__c>>> projMap = dataMap.get(assignedToId);
            Integer assignedToRowspan = 0;

            for (Map<String, List<Project_Task__c>> devMap : projMap.values()) {
                for (List<Project_Task__c> tasks : devMap.values()) {
                    assignedToRowspan += tasks.size();
                }
            }

            Boolean firstAssignedRow = true;
            for (Id projectId : projMap.keySet()) {
                Map<String, List<Project_Task__c>> devMap = projMap.get(projectId);
                Integer projectRowspan = 0;

                for (List<Project_Task__c> taskList : devMap.values()) {
                    projectRowspan += taskList.size();
                }

                Boolean firstProjectRow = true;
                for (String devName : devMap.keySet()) {
                    List<Project_Task__c> taskList = devMap.get(devName);
                    Boolean firstDevRow = true;

                    for (Project_Task__c task : taskList) {
                        body += '<tr>';

                        if (firstAssignedRow) {
                            body += '<td rowspan="' + assignedToRowspan + '">' + escapeHtml(assignedToNames.get(assignedToId)) + '</td>';
                            firstAssignedRow = false;
                        }
                        if (firstProjectRow) {
                            body += '<td rowspan="' + projectRowspan + '">' + escapeHtml(projectNames.get(projectId)) + '</td>';
                            firstProjectRow = false;
                        }
                        if (firstDevRow) {
                            body += '<td rowspan="' + taskList.size() + '">' + escapeHtml(devName) + '</td>';
                            firstDevRow = false;
                        }

                        body += '<td>' + escapeHtml(task.Name) + '</td>';
                        body += '<td>' + formatDate(task.Development_Start_Date__c) + '</td>';
                        body += '<td>' + (task.Hours_so_Far_consumed__c != null ? String.valueOf(task.Hours_so_Far_consumed__c) : '-') + '</td>';
                        body += '<td>' + formatDateTime(task.LastModifiedDate) + '</td>';
                        body += '<td>' + escapeHtml(task.Current_Task_Status__c) + '</td>';
                        body += '<td>' + escapeHtml(task.RAG__c) + '</td>';

                        body += '</tr>';
                    }
                }
            }
        }

        body += '</tbody></table>';
        body += '<p>Regards,<br/>Internal Project Admin</p>';
        body += '</body></html>';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ 'himanshu.hisharma2002@gmail.com','anurag.bhatt@saasverse.in','parag.bhatt@saasverse.in','Rohit.Jaysawal@saasverse.in','learning@saasverse.in' });
        mail.setSubject('Project Health Update - ' + DateTime.now().format('MMMM d, yyyy'));
        mail.setHtmlBody(body);
        mail.setSenderDisplayName('Internal Project Admin');

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    private static String formatDate(Date d) {
        return d != null ? d.format() : '-';
    }

    private static String formatDateTime(Datetime dt) {
        return dt != null ? dt.format('MMM d, yyyy hh:mm a') : '-';
    }

    private static String escapeHtml(String input) {
        if (String.isBlank(input)) return '';
        return input
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
    }
}