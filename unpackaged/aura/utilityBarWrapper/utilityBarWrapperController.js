({
    handleOpenUtility : function(component, event, helper) {
        helper.openUtilityBar(component);
    },
    
    handleCall : function(component, event, helper) {
        console.log('Aura method called from LWC');
    }
})