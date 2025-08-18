public class ProjectHealthScheduler1 implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        ProjectHealthMonitor1.runCheckProjectHealth();
    }
}