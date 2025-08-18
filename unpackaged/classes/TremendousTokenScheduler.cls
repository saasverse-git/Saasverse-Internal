global class TremendousTokenScheduler implements Schedulable, Database.AllowsCallouts {
    
    global void execute(SchedulableContext sc) {
        System.debug('Tremendous token refresh job started...');
        
        try {
            TremendousAuthService.getAccessTokenWithRefreshToken();
            System.debug('Tremendous token refresh completed.');
     } catch (Exception e) {System.debug('Error in TremendousTokenScheduler: ' + e.getMessage());}
    }
}