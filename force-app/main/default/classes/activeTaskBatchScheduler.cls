global class activeTaskBatchScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        activeTaskBatch batch = new activeTaskBatch();
       // Database.executeBatch(batch, 200);
    }
}