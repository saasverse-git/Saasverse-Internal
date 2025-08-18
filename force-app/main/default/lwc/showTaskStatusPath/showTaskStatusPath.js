import { LightningElement, api, wire, track } from 'lwc';
import getTaskStatus from '@salesforce/apex/ProjectTaskController.getCurrentTaskStatus';

export default class ShowTaskStatusPath extends LightningElement {
    @api recordId;
    @track currentStatus;

    statusSteps = [
        'Task Created',
        'On Hold',
        'Requirement Gathering',
        'Documentation Work',
        'Development In Progress',
        'Testing In Progress',
        'Deployment Issue',
        'Development Completed',    
        'UAT In Progress',
        'Unit Testing Completed',
        'UAT Completed',
        'Task Completed'
    ];

    @wire(getTaskStatus, { taskId: '$recordId' })
    wiredStatus({ error, data }) {
        if (data) {
            this.currentStatus = data;
        } else if (error) {
            console.error('Error fetching task status', error);
        }
    }

    get stepsWithClass() {
        const currentIndex = this.statusSteps.indexOf(this.currentStatus);
        return this.statusSteps.map((step, index) => {
            return {
                label: step,
                cssClass:
                    index < currentIndex
                        ? 'slds-path__item slds-is-complete'
                        : index === currentIndex
                        ? 'slds-path__item slds-is-current slds-is-active'
                        : 'slds-path__item',
                isCurrent: index === currentIndex,
                iconName: index <= currentIndex ? 'utility:check' : 'utility:close'
            };
        });
    }
}