public class ProjectHealthScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        ProjectHealthMonitor.runCheck();
    }
}