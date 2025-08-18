import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadCSV from '@salesforce/apex/ProjectTaskImporter.uploadCSV';
import { NavigationMixin } from 'lightning/navigation';

export default class ProjectTaskUploader extends NavigationMixin(LightningElement) {
    showModal = false;
   

    handleOpenModal() {
        this.showModal = true;
    }

    handleCloseModal() {
        this.showModal = false;
    }

    handleFileChange(event) {
        const file = event.target.files[0];

        if (file && file.name.endsWith('.csv')) {
            const reader = new FileReader();
            reader.onload = () => {
                const csvContent = reader.result;

                uploadCSV({ csvData: csvContent })
                    .then(result => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: result,
                                variant: 'success'
                            })
                        );

                        this.showModal = false;

                        this[NavigationMixin.Navigate]({
                            type: 'standard__objectPage',
                            attributes: {
                             objectApiName: 'Project_Task__c', // Replace with your object API name
                                actionName: 'list'
                            }
                        });

                    })
                    .catch(error => {
                            console.error('Upload Error:', JSON.stringify(error)); // Optional: log the full error for debugging
                         let message = 'Unknown error';

    // Handle different formats of Apex errors
    if (error?.body) {
        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error.body.message) {
            message = error.body.message;
        }
    }
                        this.dispatchEvent(
                            new ShowToastEvent({
                                
                              title: 'Error Uploading Tasks',
                             
                             
                               
                                message: error.body.message,
                              
                                variant: 'error'
                            })
                        );
                    });
            };
            reader.readAsText(file);
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid File',
                    message: 'Please upload a valid .csv file.',
                    variant: 'error'
                })
            );
        }
    }
}