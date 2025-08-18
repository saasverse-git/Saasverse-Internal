import { LightningElement, track } from 'lwc';
import getTaskRecordsByDate from '@salesforce/apex/ProjectTaskController.getTaskRecordsByDate';
import { NavigationMixin } from 'lightning/navigation';

export default class TaskRecordCountByDate extends NavigationMixin(LightningElement) {
    @track selectedDate;
    @track createdTasks = [];
    @track updatedTasks = [];
    @track error;

    handleDateChange(event) {
        this.selectedDate = event.target.value;
        if (this.selectedDate) {
            getTaskRecordsByDate({ selectedDate: this.selectedDate })
                .then(result => {
                    this.createdTasks = result.created;
                    this.updatedTasks = result.updated;
                    this.error = undefined;
                })
                .catch(error => {
                    this.error = error;
                    this.createdTasks = [];
                    this.updatedTasks = [];
                });
        }
    }

    handleTaskClick(event) {
        const taskId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: taskId,
                objectApiName: 'Project_Task__c',
                actionName: 'view'
            }
        });
    }
}




// import { LightningElement, track } from 'lwc';
// import getRecordCountByDate from '@salesforce/apex/ProjectTaskController.getRecordCountByDate';

// export default class TaskRecordCountByDate extends LightningElement {
//     @track selectedDate;
//     @track createdCount = 0;
//     @track updatedCount = 0;
//     @track error;

//     handleDateChange(event) {
//         this.selectedDate = event.target.value;
//         if (this.selectedDate) {
//             getRecordCountByDate({ selectedDate: this.selectedDate })
//                 .then(result => {
//                     this.createdCount = result.created;
//                     this.updatedCount = result.updated;
//                     this.error = undefined;
//                 })
//                 .catch(error => {
//                     this.error = error;
//                     this.createdCount = 0;
//                     this.updatedCount = 0;
//                 });
//         }
//     }
// }



// import { LightningElement, track } from 'lwc';
// import getRecordCountByDate from '@salesforce/apex/ProjectTaskController.getRecordCountByDate';

// export default class DateFilterCount extends LightningElement {
//     @track selectedDate;
//     @track recordCount;
//     @track error;

//     handleDateChange(event) {
//         this.selectedDate = event.target.value;
//     }

//     handleCheckCount() {
//         if (!this.selectedDate) return;

//         getRecordCountByDate({ selectedDate: this.selectedDate })
//             .then(result => {
//                 this.recordCount = result;
//                 this.error = undefined;
//             })
//             .catch(error => {
//                 this.error = error;
//                 this.recordCount = undefined;
//             });
//     }
// }