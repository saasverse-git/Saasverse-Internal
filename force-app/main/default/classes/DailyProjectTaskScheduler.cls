global class DailyProjectTaskScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        DailyProjectTaskEmailReminder.sendDailyProjectTaskSummaryEmail();
    }
}