import { LightningElement, track } from 'lwc';
import getTasksForDeveloperLast7Days from '@salesforce/apex/ProjectTaskController.getTasksForDeveloperLast7Days';

export default class DeveloperRecentTasks extends LightningElement {
    @track groupedData = [];
    @track error;

    developerName = 'Abhinav Maharshi';

    connectedCallback() {
        // Step 1: generate last 7 weekdays
        const dates = this.getLast7Weekdays();

        getTasksForDeveloperLast7Days({ developerName: this.developerName })
            .then(result => {
            const createdMap = {};
            const updatedMap = {};

            result.forEach(task => {
                const createdDate = new Date(task.CreatedDate).toLocaleDateString();
                const modifiedDate = new Date(task.Modified_Date__c).toLocaleDateString();

                // Created Tasks
                if (createdDate === modifiedDate) {
                    if (!createdMap[createdDate]) {
                        createdMap[createdDate] = {
                            taskList: [],
                            projectSet: new Set()
                        };
                    }
                    createdMap[createdDate].taskList.push(task.Name);
                    if (task.Projects__r?.Name) {
                        createdMap[createdDate].projectSet.add(task.Projects__r.Name);
                    }
                } else {
                    // Updated Tasks
                    if (!updatedMap[modifiedDate]) {
                        updatedMap[modifiedDate] = {
                            taskList: [],
                            projectSet: new Set()
                        };
                    }
                    updatedMap[modifiedDate].taskList.push(task.Name);
                    if (task.Projects__r?.Name) {
                        updatedMap[modifiedDate].projectSet.add(task.Projects__r.Name);
                    }
                }
            });

            // Step 2: Create full data for 7 weekdays
            const dates = this.getLast7Weekdays();
            this.groupedData = dates.map(dateObj => {
                const key = dateObj.label;

                const createdData = createdMap[key];
                const updatedData = updatedMap[key];

                return {
                    date: key,
                    day: dateObj.day,
                    createdTasks: createdData ? createdData.taskList.join(', ') : '',
                    updatedTasks: updatedData ? updatedData.taskList.join(', ') : '',
                    projectList: createdData || updatedData
                        ? Array.from(new Set([
                            ...(createdData?.projectSet || []),
                            ...(updatedData?.projectSet || [])
                        ])).join(', ')
                        : ''
                };
            });

            this.error = undefined;
        })

    }

    getLast7Weekdays() {
        const weekdays = [];
        let date = new Date();

        while (weekdays.length < 7) {
            const dayOfWeek = date.getDay();
            if (dayOfWeek !== 0 && dayOfWeek !== 6) { // not Sun/Sat
                weekdays.unshift({
                    label: date.toLocaleDateString(), // e.g., 28/07/2025
                    day: date.toLocaleDateString('en-US', { weekday: 'short' }) // Mon, Tue
                });
            }
            date.setDate(date.getDate() - 1);
        }

        return weekdays;
    }
}