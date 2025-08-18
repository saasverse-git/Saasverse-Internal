// import { LightningElement, track } from 'lwc';
// import { loadScript } from 'lightning/platformResourceLoader';
// import ChartJS from '@salesforce/resourceUrl/ChartJS';

// import getAllProjectsHealthData from '@salesforce/apex/ProjectHealthUpdateController.getAllProjectsHealthData';
// import getProjectHealthData from '@salesforce/apex/ProjectHealthUpdateController.getProjectHealthData';
// import getAllProjectName from '@salesforce/apex/ProjectHealthUpdateController.getAllProjectName';

// export default class AllProjectCharts extends LightningElement {
//     @track projectOptions = [];
//     @track allChartsData = [];
//     @track recordId;
//     @track chartOn = false;
//     @track showAllProject=true;
//     chartJsInitialized = false;
//     chart;
    
    

//     healthMap = { 'Red': 0, 'Orange': 1, 'Green': 2 };
//     colorMap = { Red: 'rgba(255, 0, 0, 1)', Orange: 'rgba(255, 159, 64, 1)', Green: 'rgba(0, 128, 0, 1)' };

//     connectedCallback() {
//         this.loadProjectOptions();
//     }

//     renderedCallback() {
//         if (this.chartJsInitialized) return;
//         loadScript(this, ChartJS)
//             .then(() => {
//                 this.chartJsInitialized = true;
//                 this.loadAllCharts();
//             })
//             .catch(console.error);
//     }

//     loadProjectOptions() {
//         getAllProjectName()
//             .then(result => {
//                 this.projectOptions = result.map(p => ({ label: p.Name, value: p.Id }));
//             })
//             .catch(console.error);
//     }

//     handleProjectChange(event) {
//         this.showAllProject=false;
//         this.recordId = event.detail.value;
//         this.chartOn = true;

//         if (!this.chartJsInitialized) {
//             loadScript(this, ChartJS)
//                 .then(() => {
//                     this.chartJsInitialized = true;
//                     this.loadSingleChart();
//                 })
//                 .catch(console.error);
//         } else {
//             this.loadSingleChart();
//         }
//     }



//     showAllProjectCharts() {
//         this.showAllProject = true;
//        this.chartOn = false;
       
//         if (!this.chartJsInitialized) {
//             this.chartJsInitialized = true;
//             Promise.all([loadScript(this, ChartJS)]).then(() => {
//                 this.loadAllCharts();
//             }).catch(error => {
//                 console.error('Error loading ChartJS:', error);
//             });
//         } else {
//             this.loadAllCharts(); // refresh on every click
//         }
//     }

//     loadSingleChart() {
//         getProjectHealthData({ projectId: this.recordId })
//             .then(data => {
//                 const labels = data.map(item => item.Update_Date__c);
//                 const dataPoints = data.map(item => this.healthMap[item.Health_Status__c]);
//                 const pointColors = data.map(item => this.colorMap[item.Health_Status__c] || 'gray');

//                 const ctx = this.template.querySelector('canvas')?.getContext('2d');
//                 if (!ctx) return;

//                 if (this.chart) this.chart.destroy();

//                 this.chart = new Chart(ctx, {
//                     type: 'line',
//                     data: {
//                         labels,
//                         datasets: [{
//                             label: 'Health Status',
//                             data: dataPoints,
//                             borderColor: 'gray',
//                             borderWidth: 2,
//                             fill: false,
//                             tension: 0.1,
//                             pointRadius: 6,
//                             pointHoverRadius: 8,
//                             pointBackgroundColor: pointColors
//                         }]
//                     },
//                     options: this.getChartOptions('Health Status', 'Update Date')
//                 });
//             })
//             .catch(console.error);
//     }

// loadAllCharts() {
//     getAllProjectsHealthData()
//         .then(result => {
//             console.log('Wrapper result:', result);

//             // Map and filter out wrappers with no health data
//             this.allChartsData = result
//                 .map(wrapper => {
//                     return {
//                         projectId: wrapper.projectId,
//                         projectName: wrapper.projectName,
//                         labels: wrapper.updateDates,
//                         dataPoints: wrapper.healthStatuses.map(h => this.healthMap[h]),
//                         pointColors: wrapper.healthStatuses.map(h => this.colorMap[h] || 'gray')
//                     };
//                 })
//                 .filter(chart => chart.labels.length > 0 && chart.dataPoints.length > 0); // Filter out empty charts

//             Promise.resolve().then(() => {
//                 this.allChartsData.forEach(chartData => {
//                     const canvas = this.template.querySelector(`canvas[data-id="${chartData.projectId}"]`);
//                     if (!canvas) {
//                         console.warn(`Canvas not found for project: ${chartData.projectName}`);
//                         return;
//                     }

//                     const ctx = canvas.getContext('2d');
//                     if (!ctx) return;

//                     new Chart(ctx, {
//                         type: 'line',
//                         data: {
//                             labels: chartData.labels,
//                             datasets: [{
//                                 label: chartData.projectName,
//                                 data: chartData.dataPoints,
//                                 borderColor: '#9ca3af',
//                                 backgroundColor: 'transparent',
//                                 pointBackgroundColor: chartData.pointColors,
//                                 tension: 0.1,
//                                 fill: true
//                             }]
//                         },
//                         options: this.getChartOptions('Health', 'Date')
//                     });
//                 });
//             });
//         })
//         .catch(error => {
//             console.error('Error loading all charts:', error);
//         });
// }



//     getChartOptions(yLabel, xLabel) {
//         return {
//             responsive: true,
//             scales: {
//                 y: {
//                     beginAtZero: true,
//                     ticks: {
//                         callback: value => ['Red', 'Orange', 'Green'][value] || value
//                     },
//                     title: {
//                         display: true,
//                         text: yLabel
//                     }
//                 },
//                 x: {
//                     title: {
//                         display: true,
//                         text: xLabel
//                     }
//                 }
//             }
//         };
//     }
       
// }


import { LightningElement, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';
import getTaskCountsByDeveloper from '@salesforce/apex/ProjectTaskController.getTaskCountsByDeveloper';

export default class ProjectTaskChart extends LightningElement {
    chart;
    chartjsInitialized = false;
    chartData = [];

    @wire(getTaskCountsByDeveloper)
    wiredTasks({ error, data }) {
        if (data) {
            console.log('Received data:', data);
            this.chartData = Object.entries(data).map(([label, value]) => ({
                label,
                value
            }));
            this.renderChart(); // Try to render if already loaded
        } else if (error) {
            console.error('Error loading data:', error);
        }
    }

    renderedCallback() {
        if (this.chartjsInitialized) return;

        this.chartjsInitialized = true;
        loadScript(this, ChartJS + '/chart.min.js')
            .then(() => {
                console.log('ChartJS Loaded:', window.Chart);
                this.renderChart();
            })
            .catch((error) => {
                console.error('Failed to load ChartJS:', error);
            });
    }

    renderChart() {
        if (!this.chartData.length || !window.Chart) {
            console.warn('Chart data missing or ChartJS not loaded yet');
            return;
        }

        const canvas = this.template.querySelector('canvas');
        if (!canvas) {
            console.warn('Canvas not found yet');
            return;
        }

        const ctx = canvas.getContext('2d');
        if (this.chart) {
            this.chart.destroy();
        }

        this.chart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: this.chartData.map(d => d.label),
                datasets: [{
                    data: this.chartData.map(d => d.value),
                    backgroundColor: [
                        '#4caf50', '#ff9800', '#f44336',
                        '#2196f3', '#9c27b0', '#00bcd4',
                        '#8bc34a', '#ffc107'
                    ]
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { position: 'bottom' },
                    title: {
                        display: true,
                        text: 'Project Task Count by Developer'
                    }
                }
            }
        });
    }
}