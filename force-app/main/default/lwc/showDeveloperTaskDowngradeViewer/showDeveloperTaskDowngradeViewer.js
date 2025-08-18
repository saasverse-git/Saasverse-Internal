import { LightningElement, wire, track } from 'lwc';
import getDeveloperDowngradeData from '@salesforce/apex/ProjectTaskController.getDeveloperDowngradeData';
import getDowngradedTasksByDeveloper from '@salesforce/apex/ProjectTaskController.getDowngradedTasksByDeveloper';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';
import { NavigationMixin } from 'lightning/navigation';

export default class DeveloperDowngradeChart extends NavigationMixin(LightningElement) {
    @track chart;
    @track isModalOpen = false;
    @track modalTasks = [];
    @track modalDeveloper = '';

    chartJsInitialized = false;

    renderedCallback() {
        if (this.chartJsInitialized) {
            return;
        }
        this.chartJsInitialized = true;
        loadScript(this, ChartJS)
            .then(() => {
                this.loadChart();
            })
            .catch(error => {
                console.error('Error loading ChartJS', error);
            });
    }

    loadChart() {
        getDeveloperDowngradeData()
            .then(data => {
                const labels = data.map(item => item.developer.split(' ')[0]); // first name only
                const counts = data.map(item => item.downgradeCount);

                const ctx = this.template.querySelector('canvas').getContext('2d');

                this.chart = new window.Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: labels,
                        datasets: [{
                            label: 'Downgrades',
                            data: counts,
                            backgroundColor: 'rgba(75, 192, 192, 0.6)',
                            borderColor: 'rgba(75, 192, 192, 1)',
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            x: {
                                ticks: {
                                    callback: function(value) {
                                        let label = this.getLabelForValue(value);
                                        return label.split(' ')[0]; // only first name
                                    },
                                    autoSkip: false,
                                    maxRotation: 0,
                                    minRotation: 0
                                },
                                grid: { display: false }
                            },
                            y: {
                                beginAtZero: true,
                                title: {
                                    display: true,
                                    text: 'Downgrade Count'
                                },
                                grid: { display: false }
                            }
                        },
                        onClick: (evt, activeEls) => {
                            if (activeEls.length > 0) {
                                const index = activeEls[0].index;
                                const clickedDeveloper = data[index].developer;
                                this.handleBarClick(clickedDeveloper);
                            }
                        }
                    }
                });
            })
            .catch(error => {
                console.error('Error fetching downgrade data', error);
            });
    }

    // handleBarClick(developerName) {
    //     this.modalDeveloper = developerName;
    //     getDowngradedTasksByDeveloper({ developerName: developerName })
    //         .then(tasks => {
    //             this.modalTasks = tasks;
    //             console.log('modeltask',JSON.stringify(this.modalTasks));
    //             this.isModalOpen = true;
    //         })
    //         .catch(error => {
    //             console.error('Error fetching downgraded tasks', error);
    //         });
    // }
    handleBarClick(developerName) {
    this.modalDeveloper = developerName;
    getDowngradedTasksByDeveloper({ developerName: developerName })
        .then(tasks => {
            console.log('modeltask', JSON.stringify(tasks));

            // Add serial number mapping correctly
            this.modalTasks = tasks.map((task, index) => ({
                srNo: index + 1, // Serial number starting from 1
                taskNo: task.taskNo,
                taskName: task.taskName,
                projectName: task.projectName,
                Id: task.Id
            }));

            this.isModalOpen = true;
        })
        .catch(error => {
            console.error('Error fetching downgraded tasks', error);
        });
}


    closeModal() {
        this.isModalOpen = false;
        this.modalTasks = [];
        this.modalDeveloper = '';
    }

    handleTaskClick(event) {
        const taskId = event.currentTarget.dataset.taskId;
        const baseUrl = window.location.origin;
        const url = `${baseUrl}/lightning/n/Show_Task_History?c__taskId=${taskId}`;
        window.open(url, '_blank'); 
    }
}