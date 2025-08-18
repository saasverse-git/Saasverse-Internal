import { LightningElement, wire, track,api } from 'lwc';
import getTimesheets from '@salesforce/apex/TimesheetViewerController.getTimesheets';
import createInvoice from '@salesforce/apex/TimesheetViewerController.createInvoice';
import getTimesheetsForIncompletePayment from '@salesforce/apex/TimesheetViewerController.getTimesheetsForIncompletePayment';
import pdfjsLib from '@salesforce/resourceUrl/pdfjsLib';
import uploadCSV from '@salesforce/apex/CSVUploaderController.uploadCSV';
import { loadScript } from 'lightning/platformResourceLoader';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    { label: 'Developer', fieldName: 'DeveloperName', sortable: true },
    { label: 'Project', fieldName: 'ProjectName', sortable: true },
    { label: 'Start Date', fieldName: 'Start_Date__c', type: 'date', sortable: true },
    { label: 'End Date', fieldName: 'End_Date__c', type: 'date', sortable: true },
    { label: 'Worked Days', fieldName: 'Worked_Days__c', type: 'number', sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'Actual Days', fieldName: 'Actual_Days_worked__c', type: 'number', sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'Captured Hour', fieldName: 'Captured_Hours__c', type: 'number' , cellAttributes: { alignment: 'center' } },
    { label: 'Approved Days', fieldName: 'Approved_Days__c', type: 'number' ,editable: true, cellAttributes: { alignment: 'center' } },
    { label: 'Approved', fieldName: 'Approved__c', type: 'boolean', cellAttributes: { alignment: 'center' } },
    { label: 'Submitted On', fieldName: 'Submitted_On__c', type: 'date', sortable: true, cellAttributes: { alignment: 'center' } },
    // { label: 'Final Payment', fieldName: 'Final_Payment__c',type: 'boolean',  cellAttributes: { alignment: 'center' }},
          
    {
        type: 'button',
        typeAttributes: {
            label: 'Validate',
            name: 'validate',
            variant: 'brand'
        }
    }
];

export default class FinalTimesheetComponent extends NavigationMixin(LightningElement) {

    @track allData = [];
    @track pagedData = [];
    @track selectedRow = null;
    @track columns = COLUMNS;
    @track selectedProjectName = '';
    @track selectedRecordId = '';
    @track selectedResourceName = '';
    @track sortBy;
    @track sortDirection;
    @track fileData;
    @track draftValues = [];
    @track fileName = '';
    @track timesheetId;
    pdfjsInitialized = false;
    @track isToggleOn = false;


    getTimesheetRecords(){
        getTimesheets()
        .then(result => {
            this.allData = result.map(row => ({
                ...row,
                DeveloperName: row.Resource__r?.Name,
                ProjectName: row.Project__r?.Name
            }));
            this.pagedData = [...this.allData];
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error loading timesheets',
                message: error.body.message,
                variant: 'error'
            }));
        });
    }

    connectedCallback() {
        this.getTimesheetRecords();
        this.fetchTimesheetEntries();
        loadScript(this, pdfjsLib)
            .then(() => {
                window.pdfjsLib = pdfjsLib; // Add this line to make pdfjsLib accessible

                
                this.pdfjsInitialized = true;
                console.log(' PDF.js loaded and ready');
            })
            .catch((error) => {
                console.error(' Error loading PDF.js library', error);
            });
            return refreshApex(this.wiredTimesheets);
            
    }

    //change 1
    // CSV Upload
    handleFileChange(event) {
        const file = event.target.files[0];
        if (file && file.name.endsWith('.csv')) {
            const reader = new FileReader();
            reader.onload = () => {
                uploadCSV({ csvData: reader.result })
                    .then(result => {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'CSV Upload Success',
                            message: result,
                            variant: 'success'
                        }));
                    })
                    .catch(error => {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'CSV Upload Failed',
                            message: error.body.message,
                            variant: 'error'
                        }));
                    });
            };
            reader.readAsText(file);
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        this.selectedRow = event.detail.row;
        this.selectedProjectName = this.selectedRow.ProjectName;
        this.selectedResourceName = this.selectedRow.DeveloperName;
        this.selectedRecordId = this.selectedRow.Id;

        console.log('selectedRow ---> ' + this.selectedRow.Id);

        if (actionName === 'Update') {
            this.showModel = true;
        }

        if (actionName === 'validate') {
            const approvedDays = this.selectedRow.Approved_Days__c;
            const actualDays = this.selectedRow.Actual_Days_worked__c;

            if (approvedDays === actualDays) {
                // Update Status__c locally
                this.pagedData = this.pagedData.map(rec => {
                    if (rec.Id === this.selectedRow.Id) {
                        return { ...rec, Status__c: 'Validated' };
                    }
                    return rec;
                });

                // Call createInvoice Apex
                createInvoice({ timesheetId: this.selectedRow.Id })
                .then(invoiceId => {
                    this.showToast('Success', 'Record validated and invoice created!', 'success');

                    // Navigate to Invoice record
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: invoiceId,
                            objectApiName: 'Invoice__c',
                            actionName: 'view'
                        }
                    });
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });

            } else {
                this.pagedData = this.pagedData.map(rec => {
                    if (rec.Id === this.selectedRow.Id) {
                            return { ...rec, Status__c: 'Not Validated' };
                    }
                    return rec;
                });
                this.showToast('Error', 'Approved Days and Actual Days do not match.', 'error');
            }
        }
    }

    handleSave(event) {
    const today = new Date().toISOString();
    const draftValues = event.detail.draftValues;

    const recordInputs = draftValues.map(draft => {
        const row = this.pagedData.find(rec => rec.Id === draft.Id);

        // Check condition Approved Days == Actual Days
        let status = '';
        if (row && draft.Approved_Days__c === row.Actual_Days_worked__c) {
            status = 'validated';
        }

        const fields = {
            ...draft,
            Submitted_On__c: today,
            Status__c: status   // <-- You are setting Status__c now!
        };

        return { fields };
    });

    const promises = recordInputs.map(recordInput => updateRecord(recordInput));

    Promise.all(promises)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Records updated successfully',
                    variant: 'success'
                })
            );
            this.draftValues = [];
            this.getTimesheetRecords();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating records',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    handleToggleChange(event) {
        this.isToggleOn = event.target.checked;
        this.fetchTimesheetEntries();
    }

    fetchTimesheetEntries() {
        if (this.isToggleOn) {
            getTimesheetsForIncompletePayment()
                .then(result => {
                    this.pagedData = result.map(row => ({
                        ...row,
                        DeveloperName: row.Resource__r?.Name,
                        ProjectName: row.Project__r?.Name
                    }));
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
        } else {
            getTimesheets()
                .then(result => {
                    this.pagedData = result.map(row => ({
                        ...row,
                        DeveloperName: row.Resource__r?.Name,
                        ProjectName: row.Project__r?.Name
                    }));
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
        }
    }

}