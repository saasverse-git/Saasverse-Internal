// import { LightningElement, wire, api } from 'lwc';
// import { CurrentPageReference } from 'lightning/navigation';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getTasksByDeveloper from '@salesforce/apex/ProjectTaskController.getTasksByDeveloper';

// export default class ShowDeveloperAllTask extends LightningElement {
//     @api developerName;
//     tasks;
//     error;
//     startDate;
//     endDate;
//     tasksAllData;
    

//     get showResetButton(){
//         if(this.startDate != null || this.endDate != null){
//             return true;
//         }
//         return false;
//     }

//     columns = [
//         { label: 'S.N', fieldName: 'srNo' },
//         { label: 'Task No', fieldName: 'Name' },
//         { label: 'Project Name', fieldName: 'projectName' },
//         { label: 'RAG Status', fieldName: 'RAG' },
//         { label: 'Status', fieldName: 'Status' },
//         { label: 'Is Active', fieldName: 'Is Active', type: 'boolean' },
//         { label: 'Working on Other Tickets', fieldName: 'Working on Other Tickets', type: 'boolean' },
//         { label: 'Real Business hours needed', fieldName: 'Real Business hours needed' },
//         { label: 'Hours so Far consumed', fieldName: 'Hours so Far consumed' },
//         { label: 'Testing Status', fieldName: 'Testing Status' },
//         { label: 'Description', fieldName: 'Description' },
//         { label: 'Development Start', fieldName: 'Development Start' },
//         { label: 'Created Date', fieldName: 'Created Date', type: 'date' },
//         { label: 'Modified Date', fieldName: 'Modified Date', type: 'date' }
//     ];

//     @wire(CurrentPageReference)
//     getStateParams(currentPageReference) {
//         if (currentPageReference && currentPageReference.state) {
//             this.developerName = currentPageReference.state.c__developerName;
//         }
//     }

//     @wire(getTasksByDeveloper, { developerName: '$developerName' })
//     wiredTasks({ error, data }) {
//         if (data) {
//             this.tasks = data.map((row, index) => ({
//                 // ...row,
//                 // srNo: index + 1,
//                 // projectName: row.Projects__r?.Name || ''
//                 srNo: index + 1,
//                 Name: row.Name,
//                 projectName: row.Projects__r?.Name || '',
//                 RAG: row.RAG__c,
//                 Status: row.Current_Task_Status__c,
//                 'Is Active': row.Is_Active__c,
//                 'Working on Other Tickets': row.Is_Working_on_Other_Tickets__c,
//                 'Real Business hours needed': row.Real_Business_hours_needed__c,
//                 'Hours so Far consumed': row.Hours_so_Far_consumed__c,
//                 'Testing Status': row.Task_Testing_Status__c,
//                 'Description': row.Description__c,
//                 'Development Start': row.Development_Start_Date__c,
//                 'Modified Date': row.Modified_Date__c,
//                 'Created Date': row.CreatedDate
                

//             })); 
//             this.tasksAllData = this.tasks;
//             this.error = undefined;
//         } else if (error) {
//             this.error = error;
//             this.tasks = undefined;
//             console.error('Error loading tasks:', error);
//         }
//     }

//     handleDownloadCSV() {
//         if (!this.tasks || !this.tasks.length) {
//             return;
//         }
//         console.log('FINAL DATA', JSON.stringify(this.tasks));
//         const csv = this.convertArrayOfObjectsToCSV(this.tasks);
//         if (csv === null) {
//             return;
//         }

//         const element = document.createElement('a');
//         element.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
//         element.target = '_self';
//         element.download = 'AllTask.csv';
//         document.body.appendChild(element);
//         element.click();
//         document.body.removeChild(element);
//     }

//     convertArrayOfObjectsToCSV(objectRecords) {
//         if (!objectRecords || !objectRecords.length) {
//             return null;
//         }
//         const columnDelimiter = ',';
//         const lineDelimiter = '\n';
//         const keys = Object.keys(objectRecords[0]);

//         let result = '';
//         result += keys.join(columnDelimiter);
//         result += lineDelimiter;

//         objectRecords.forEach(record => {
//             let ctr = 0;
//             keys.forEach(key => {
//                 if (ctr > 0) result += columnDelimiter;
//                 const val = record[key];
//                 // Escape quotes in values
//                 const escapedVal = typeof val === 'string' ? val.replace(/"/g, '""') : val;
//                 result += (escapedVal !== undefined && escapedVal !== null ? `"${escapedVal}"` : '');
//                 ctr++;
//             });
//             result += lineDelimiter;
//         });
//         return result;
//     }

//     handleDateChange(event){
//         console.log('check date',event.target.name);
//         if(event.target.name == 'StartDate' ){
//             this.startDate = event.target.value;
//         }else{
//             this.endDate = event.target.value;
//         }
//         console.log('check start date',this.startDate );
//         console.log('check end date',this.endDate);
//     }

//     heandleSearch(){
//         if((this.startDate != null || this.startDate != undefined) && (this.endDate != null || this.endDate != undefined)){
//             if (this.startDate > this.endDate) {
//                 this.dispatchEvent(new ShowToastEvent({
//                     title: 'Invalid Date Range',
//                     message: 'Start Date cannot be later than End Date.',
//                     variant: 'error'
//                 }));
//                 return;
//             }
//             console.log(JSON.stringify(this.tasks));
//             this.tasks = this.tasksAllData;
//             this.tasks = this.tasks.filter(task => {
//                 if (!task['Modified Date']) return false;
//                 const modifiedDate = task['Modified Date'].split('T')[0];
//                 return modifiedDate >= this.startDate && modifiedDate <= this.endDate;
//             });
//         }else{
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Missing Date',
//                 message: 'Please select both Start Date and End Date before clicking Search.',
//                 variant: 'warning'
//             }));
//         }
//     }

//     handleRefresh(){
//         if(this.startDate != null || this.endDate != null){
//             this.startDate = null;
//             this.endDate = null;

//         }
//     }

    

// }


import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTasksByDeveloper from '@salesforce/apex/ProjectTaskController.getTasksByDeveloper';

export default class ShowDeveloperAllTask extends LightningElement {
    @api developerName;
    tasks = [];
    tasksAllData = [];
    error;
    startDate = null;
    endDate = null;

    columns = [
        { label: 'S.N', fieldName: 'srNo' },
        { label: 'Task No', fieldName: 'Name' },
        { label: 'Project Name', fieldName: 'projectName' },
        { label: 'RAG Status', fieldName: 'RAG' },
        { label: 'Status', fieldName: 'Status' },
        { label: 'Is Active', fieldName: 'Is Active', type: 'boolean' },
        { label: 'Working on Other Tickets', fieldName: 'Working on Other Tickets', type: 'boolean' },
        { label: 'Real Business hours needed', fieldName: 'Real Business hours needed' },
        { label: 'Hours so Far consumed', fieldName: 'Hours so Far consumed' },
        { label: 'Testing Status', fieldName: 'Testing Status' },
        { label: 'Description', fieldName: 'Description' },
        { label: 'Development Start', fieldName: 'Development Start' },
        { label: 'Created Date', fieldName: 'Created Date', type: 'date' },
        { label: 'Modified Date', fieldName: 'Modified Date', type: 'date' }
    ];

    @wire(CurrentPageReference)
    getStateParams(currentPageReference) {
        if (currentPageReference?.state?.c__developerName) {
            this.developerName = currentPageReference.state.c__developerName;
        }
    }

    connectedCallback() {
        this.refreshData();
    }

    refreshData() {
        getTasksByDeveloper({ developerName: this.developerName })
            .then(data => {
                this.tasks = data.map((row, index) => ({
                    srNo: index + 1,
                    Name: row.Name,
                    projectName: row.Projects__r?.Name || '',
                    RAG: row.RAG__c,
                    Status: row.Current_Task_Status__c,
                    'Is Active': row.Is_Active__c,
                    'Working on Other Tickets': row.Is_Working_on_Other_Tickets__c,
                    'Real Business hours needed': row.Real_Business_hours_needed__c,
                    'Hours so Far consumed': row.Hours_so_Far_consumed__c,
                    'Testing Status': row.Task_Testing_Status__c,
                    'Description': row.Description__c,
                    'Development Start': row.Development_Start_Date__c,
                    'Modified Date': row.Modified_Date__c,
                    'Created Date': row.CreatedDate
                }));
                this.tasksAllData = [...this.tasks];
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.tasks = [];
                console.error('Error fetching tasks:', error);
            });
    }

    handleDownloadCSV() {
        if (!this.tasks?.length) return;

        const csv = this.convertArrayOfObjectsToCSV(this.tasks);
        if (!csv) return;

        const safeDevName = this.developerName?.replace(/\s+/g, '_').replace(/[^a-zA-Z0-9_]/g, '') || 'UnknownDeveloper';
        const fileName = `AllTask_${safeDevName}.csv`;

        const element = document.createElement('a');
        element.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
        element.download = fileName;
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }

    convertArrayOfObjectsToCSV(objectRecords) {
        if (!objectRecords?.length) return null;

        const keys = Object.keys(objectRecords[0]);
        const columnDelimiter = ',';
        const lineDelimiter = '\n';

        let result = keys.join(columnDelimiter) + lineDelimiter;

        objectRecords.forEach(record => {
            result += keys.map(key => {
                const val = record[key];
                const safeVal = typeof val === 'string' ? val.replace(/"/g, '""') : val;
                return `"${safeVal ?? ''}"`;
            }).join(columnDelimiter) + lineDelimiter;
        });

        return result;
    }

    handleDateChange(event) {
        const { name, value } = event.target;
        if (name === 'StartDate') {
            this.startDate = value;
        } else if (name === 'EndDate') {
            this.endDate = value;
        }
    }

    heandleSearch() {
        if (!this.startDate || !this.endDate) {
            this.showToast('Missing Date', 'Please select both Start Date and End Date before clicking Search.', 'warning');
            return;
        }

        if (this.startDate > this.endDate) {
            this.showToast('Invalid Date Range', 'Start Date cannot be later than End Date.', 'error');
            return;
        }

        this.tasks = this.tasksAllData.filter(task => {
            if (!task['Modified Date']) return false;
            const modifiedDate = task['Modified Date'].split('T')[0];
            return modifiedDate >= this.startDate && modifiedDate <= this.endDate;
        });
    }

    handleRefresh() {
        this.startDate = null;
        this.endDate = null;
        this.refreshData();
    }

    showToast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get showResetButton() {
        return this.startDate || this.endDate;
    }
}