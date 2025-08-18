import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTasksByDate from '@salesforce/apex/ProjectTaskController.getTasksByDate';
import getAllDeveloperNames from '@salesforce/apex/ProjectTaskController.getAllDeveloperNames';

export default class ShowTodayTasks extends NavigationMixin(LightningElement) {
    @track showModal = false;
    @track loadingTasks = false;
    @track allDevelopers = [];
    @track tasks = [];
    @track error;
    @track developerSummary = [];
    @track selectedDate = this.getToday();

    getToday() {
        return new Date().toISOString().slice(0, 10);
    }

    handleShowTasks() {
        this.showModal = true;
        this.fetchData();
    }

    fetchData() {
        this.loadingTasks = true;
        Promise.all([
            getAllDeveloperNames(),
            getTasksByDate({ dateString: this.selectedDate })
        ])
        .then(([devs, tasks]) => {
            this.allDevelopers = devs;
            this.tasks = tasks.map(task => {
                const created = task.CreatedDate?.slice(0, 10);
                const updated = task.Modified_Date__c?.slice(0, 10);
                if (created === this.selectedDate) {
                    return { ...task, todayType: 'Created' };
                } else if (updated === this.selectedDate) {
                    return { ...task, todayType: 'Updated' };
                }
                return null;
            }).filter(t => t !== null);
            this.createDeveloperSummary();
        })
        .catch(error => {
            this.error = error;
            this.tasks = [];
            this.developerSummary = [];
        })
        .finally(() => {
            this.loadingTasks = false;
        });
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
        this.fetchData(); 
    }

    

    createDeveloperSummary() {
    const tasksByDev = {};
    this.tasks.forEach(task => {
        const dev = task.Developer_Name__c || 'Unknown';
        if (!tasksByDev[dev]) {
            tasksByDev[dev] = [];
        }
        tasksByDev[dev].push(task);
    });

    let summary = this.allDevelopers.map(devName => {
        const devTasks = tasksByDev[devName] || [];
        const createdTasks = [];
        const updatedTasks = [];
        const projectNamesSet = new Set();

        devTasks.forEach(t => {
            if (t.Projects__r?.Name) {
                projectNamesSet.add(t.Projects__r.Name);
            }
            if (t.todayType === 'Created') {
                createdTasks.push({ id: t.Id, name: t.Name });
            } else if (t.todayType === 'Updated') {
                updatedTasks.push({ id: t.Id, name: t.Name });
            }
        });

        return {
            name: devName,
            count: devTasks.length,
            projectNames: Array.from(projectNamesSet).join(', '),
            createdTaskObjs: createdTasks,
            updatedTaskObjs: updatedTasks,
            rowKey: devName + '_row'
        };
    });

    //  Sort by developer name alphabetically
    summary.sort((a, b) => a.name.localeCompare(b.name));

    // ➕ Add serial number after sorting
    this.developerSummary = summary.map((item, idx) => ({
        ...item,
        srNo: idx + 1
    }));
}


    closeModal() {
        this.showModal = false;
    }

    // handleTaskClick(event) {
    //     const taskId = event.currentTarget.dataset.taskId;
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__navItemPage',
    //         attributes: { apiName: 'Show_Task_History' },
    //         state: { c__taskId: taskId }
    //     });
    // }

    // Opens in a new browser tab
    handleTaskClick(event) {
        const taskId = event.currentTarget.dataset.taskId;
        const baseUrl = window.location.origin;
        const url = `${baseUrl}/lightning/n/Show_Task_History?c__taskId=${taskId}`;
        window.open(url, '_blank'); 
    }

}