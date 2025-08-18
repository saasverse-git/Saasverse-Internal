import { LightningElement, track, api } from 'lwc';
import getTasksByRag from '@salesforce/apex/ProjectTaskController.getTasksByRag';
import { NavigationMixin } from 'lightning/navigation';

export default class ShowTaskWithRAG extends NavigationMixin(LightningElement) {
    @track tasks = [];
    @track showModal = false;
    @track currentFilter = '';
    @track error;

    @api
    showRagTasks(ragValue) {
        console.log('ragvalue',ragValue);
        this.currentFilter = ragValue;
        getTasksByRag({ ragValue })
            .then(result => {
                console.log(JSON.stringify(result));
                const sorted = [...result].sort((a, b) => {
                    const nameA = a.Projects__r?.Name?.toLowerCase() || '';
                    const nameB = b.Projects__r?.Name?.toLowerCase() || '';
                    return nameA.localeCompare(nameB);
                });

                this.tasks = sorted;
                this.showModal = true;
                this.error = undefined;
                console.log(this.showModal);
            })
            .catch(error => {
                this.error = error;
                this.tasks = [];
                this.showModal = false;
            });
    }

     handleTaskClick(event) {
        const taskId = event.currentTarget.dataset.taskId;
        const baseUrl = window.location.origin;
        const url = `${baseUrl}/lightning/n/Show_Task_History?c__taskId=${taskId}`;
        window.open(url, '_blank'); 
    }

    closeModal() {
        this.showModal = false;
    }

    get tasksWithIndex() {
        return this.tasks.map((task, index) => ({
            ...task,
            srNo: index + 1,
            projectsName: task.Projects__r?.Name ? task.Projects__r.Name : ''
        }));
    }

    get totalCount() {
        return this.tasks.length;
    }

    get modalTitle() {
        return `Total ${this.currentFilter} Tasks: ${this.totalCount}`;
    }
}