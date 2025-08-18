({
    openUtilityBar : function(component) {
        console.log('openUtilityBar Called Again');
        const utilityAPI = component.find("utilitybar");
        utilityAPI.openUtility();

        /*utilityAPI.getUtilityInfo()
            .then(result => {
                //console.log('RESULTTTT', JSON.stringify(result));
                utilityAPI.openUtility();
                const utilities = result.utilities || [];
                console.log('Utility bar items:', utilities);

                // Find any utility that is currently open
                const openUtility = utilities.find(u => u.isOpen == true);
                if (openUtility) {
                    console.log(`Closing currently open utility: ${openUtility.label}`);

                    // Close the currently open utility bar item
                    return utilityAPI.closeUtility({ utilityId: openUtility.utilityId })
                        .catch(err => {
                            console.warn('closeUtility failed, trying minimizeUtility', err);
                            // fallback to minimize if close fails
                            return utilityAPI.minimizeUtility();
                        });
                } else {
                    // No utility currently open, resolve immediately
                    return Promise.resolve();
                }
            })
            .then(() => {
                // Open the utility bar item of this component (your Aura wrapper)
                return utilityAPI.openUtility();
            })
            .then(() => {
                console.log('Opened the utility bar item.');
            })
            .catch(error => {
                console.error('Error managing utility bars:', error);
            });*/
    }
})