import { LightningElement, api, wire, track } from 'lwc';
import getTaskById from '@salesforce/apex/ProjectTaskController.getTaskById';

export default class ProjectTaskDetail extends LightningElement {
    @api recordId = 'a03gK0000047resQAA';
    @track task;

    @wire(getTaskById, { taskId: '$recordId' })
    wiredTask({ error, data }) {
        if (data) {
            this.task = data;
        } else if (error) {
            this.task = null;
        }
    }
}