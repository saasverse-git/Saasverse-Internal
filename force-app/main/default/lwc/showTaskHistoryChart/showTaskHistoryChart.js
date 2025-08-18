import { LightningElement,api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getTaskStatusHistory from '@salesforce/apex/ProjectTaskController.getTaskStatusHistory';
import ChartJS from '@salesforce/resourceUrl/ChartJS';
import ChartJSDatalabels from '@salesforce/resourceUrl/ChartJSDatalabels';
import { loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';

//export default class ShowTaskHistoryChart extends LightningElement {
export default class ShowTaskHistoryChart extends NavigationMixin(LightningElement) {

    @track chartData = [];
    @track taskName = '';
    chartOn = true ;
    @track loading = true;
    chart;
    @api taskId;
    chartJsLoaded = false;
    lastRenderedTaskId;


    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef?.state?.c__taskId) {
            const newTaskId = pageRef.state.c__taskId;
            if (newTaskId !== this.taskId) {
                this.taskId = newTaskId;
                this.chartOn = true;
                if (this.chartJsLoaded) {
                    this.loadChartForTask(this.taskId); // refresh chart data
                }
            }
        }
    }


    renderedCallback() {
        if (this.chartJsLoaded || !this.template.querySelector('canvas')) return;

        Promise.all([
            loadScript(this, ChartJS),
            loadScript(this, ChartJSDatalabels)
        ])
        .then(() => {
            this.chartJsLoaded = true;
            if (this.taskId) {
                this.loadChartForTask(this.taskId);
            }
        })
        .catch(error => {
            console.error('ChartJS load failed:', error);
        });
    }


    loadChartForTask(taskId) {
        if (!taskId) return;

        this.lastRenderedTaskId = taskId;
        this.loading = true;

        getTaskStatusHistory({ taskId })
            .then(data => {
                console.log('getTaskStatusHistory Data', JSON.stringify(data));
                this.taskName = data.taskName;
                this.chartData = data.history;
                this.chartOn = true;
                this.renderChart();
            })
            .catch(error => {
                console.error('Apex data fetch failed:', error);
                this.chartOn = false;
            })
            .finally(() => {
                this.loading = false;
            });
    }


    //use multipal clr in chart
    renderChart() {
        if (!this.chartData.length) {
            this.chartOn = false;
            return;
        }

        const statusToIndex = {
            'Task Created': 1,
            'On Hold': 2,
            'Requirement Gathering': 3,
            'Documentation Work': 4,
            'Deployment Issue': 5,
            'Development In Progress': 6,
            'Testing In Progress': 7,
            'Development Completed': 8,
            'UAT In Progress': 9,
            'Unit Testing Completed': 10,
            'UAT Completed': 11,
            'Task Completed': 12
        };

        const labels = this.chartData.map(d => d.date);
        const values = this.chartData.map(d => statusToIndex[d.status] || 0);
        const devCompletedIndex = 8;

        const canvas = this.template.querySelector('canvas');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        if (this.chart) this.chart.destroy();

        const segments = [];
        for (let i = 1; i < values.length; i++) {
            const prev = values[i - 1];
            const curr = values[i];

            let color = '#0070d2'; // default gray
            color = curr > prev ? 'green' : 'red' ;
            // if (prev >= devCompletedIndex && curr >= devCompletedIndex) {
            //     color = curr > prev ? 'green' : 'red' ;
            // }
            if((curr > prev) && (curr <= 8)){
                color = '#0070d2';
            } else if((prev > curr) && (curr >= 8)){
                color = 'green';
            }

            segments.push({ start: i - 1, end: i, color });
        }

        const data = {
            labels,
            datasets: [{
                label: 'Task Status Over Time',
                data: values,
                borderColor: function(context) {
                    const index = context.p0DataIndex;
                    const seg = segments.find(s => s.start === index);
                    return seg ? seg.color : '#808080';
                },
                segment: {
                    borderColor: ctx => {
                        const index = ctx.p0DataIndex;
                        const seg = segments.find(s => s.start === index);
                        return seg ? seg.color : '#808080';
                    }
                },
                borderWidth: 3,
                fill: false,
                tension: 0,
                pointRadius: 5
            }]
        };

        const options = {
            responsive: true,
            plugins: {
                title: {
                    display: true,
                    text: this.taskName || 'Task Status Chart',
                    font: { size: 18 }
                }
            },
            scales: {
                y: {
                    min: 1,
                    max: 12,
                    ticks: {
                        stepSize: 1,
                        callback: value => {
                            const entry = Object.entries(statusToIndex).find(([, v]) => v === value);
                            return entry ? entry[0] : '';
                        }
                    },
                    title: { display: true, text: 'Status' }
                },
                x: {
                    title: { display: true, text: 'Date' }
                }
            }
        };

        this.chart = new window.Chart(ctx, {
            type: 'line',
            data,
            options
        });
    }

    handleGoBack() {
        // If window has no history (opened via window.open), close the tab
        if (window.opener != null && window.opener !== window) {
            window.close(); // closes the tab opened via window.open
        } else {
            window.history.back(); // goes back to previous view in Lightning
        }
    }

    handleOpenRecord() {
        if (!this.taskId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.taskId,
                objectApiName: 'Project_Task__c',
                actionName: 'view'
            }
        });
    }  

}




//only One clr chart
// renderChart() {
    //     if (!this.chartData.length) {
    //         console.log('Task IDD', this.taskId);
    //         console.log('NO VALUE FOR THIS');
    //         this.chartOn = false;
    //         return;
    //     }
    //     const labels = this.chartData.map(d => d.date);
    //     const values = this.chartData.map(d => {
    //         switch (d.status) {
    //             case 'Task Created': return 1;
    //             case 'On Hold': return 2;
    //             case 'Requirement Gathering': return 3;
    //             case 'Documentation Work': return 4;
    //             case 'Deployment Issue': return 5;
    //             case 'Development In Progress': return 6;
    //             case 'Testing In Progress': return 7;
    //             case 'Development Completed': return 8;                                
    //             case 'UAT In Progress': return 9;
    //             case 'Unit Testing Completed': return 10;
    //             case 'UAT Completed': return 11;      
    //             case 'Task Completed': return 12;
    //             default: return 0;
    //         }
    //     });

    //     const canvas = this.template.querySelector('canvas');
    //     if (!canvas) return;

    //     const ctx = canvas.getContext('2d');
    //     if (this.chart) this.chart.destroy();

    //     this.chart = new window.Chart(ctx, {
    //         type: 'line',
    //         data: {
    //             labels,
    //             datasets: [{
    //                 label: 'Task Status Over Time',
    //                 data: values,
    //                 borderColor: '#0070d2',
    //                 //tension: 0.3,
    //                 tension: 0,
    //                 pointRadius: 5,
    //                 borderWidth: 2,
    //                 fill: false
    //             }]
    //         },
    //         options: {
    //             responsive: true,
    //             plugins: {
    //                 title: {
    //                     display: true,
    //                     text: this.taskName || 'Task Status Chart',
    //                     font: { size: 18 }
    //                 }
    //             },
    //             scales: {
    //                 y: {
    //                     min: 1,
    //                     max: 12,
    //                     ticks: {
    //                         stepSize: 1,
    //                         callback: value => {
    //                             switch (value) {
    //                                 case 1: return 'Task Created';
    //                                 case 2: return 'On Hold';
    //                                 case 3: return 'Requirement Gathering';
    //                                 case 4: return 'Documentation Work';
    //                                 case 5: return 'Deployment Issue'
    //                                 case 6: return 'Development In Progress';
    //                                 case 7: return 'Testing In Progress';
    //                                 case 8: return 'Development Completed';                                    
    //                                 case 9: return 'UAT In Progress';
    //                                 case 10: return 'Unit Testing Completed'; 
    //                                 case 11: return 'UAT Completed';
    //                                 case 12: return 'Task Completed';
    //                                 default: return '';
    //                             }
    //                         }
    //                     },
    //                     title: { display: true, text: 'Status' }
    //                 },
    //                 x: {
    //                     title: { display: true, text: 'Date' }
    //                 }
    //             }
    //         }
    //     });
    // }




// import { LightningElement, wire, track } from 'lwc';
// import { CurrentPageReference } from 'lightning/navigation';
// import getTaskStatusHistory from '@salesforce/apex/ProjectTaskController.getTaskStatusHistory';
// import ChartJS from '@salesforce/resourceUrl/ChartJS';
// import ChartJSDatalabels from '@salesforce/resourceUrl/ChartJSDatalabels';
// import { loadScript } from 'lightning/platformResourceLoader';

// export default class ShowTaskHistoryChart extends LightningElement {
//     @track chartData = [];
//     taskId;
//     chart;
//     chartJsLoaded = false;

//     // track current value to detect taskId change
//     lastRenderedTaskId;

//     @wire(CurrentPageReference)
//     getPageRef(pageRef) {
//         if (pageRef?.state?.c__taskId) {
//             this.taskId = pageRef.state.c__taskId;
//             // if ChartJS already loaded, refresh the chart for new task
//             if (this.chartJsLoaded && this.taskId !== this.lastRenderedTaskId) {
//                 this.loadChartForTask(this.taskId);
//             }
//         }
//     }

//     renderedCallback() {
//         if (this.chartJsLoaded || !this.template.querySelector('canvas')) return;

//         Promise.all([
//             loadScript(this, ChartJS),
//             loadScript(this, ChartJSDatalabels)
//         ])
//         .then(() => {
//             this.chartJsLoaded = true;
//             if (this.taskId) {
//                 this.loadChartForTask(this.taskId);
//             }
//         })
//         .catch(error => {
//             console.error('ChartJS load failed:', error);
//         });
//     }

//     loadChartForTask(taskId) {
//         if (!taskId) return;

//         this.lastRenderedTaskId = taskId;
//         getTaskStatusHistory({ taskId })
//             .then(data => {
//                 this.chartData = data;
//                 this.renderChart();
//             })
//             .catch(error => {
//                 console.error('Apex data fetch failed:', error);
//             });
//     }

//     renderChart() {
//         const labels = this.chartData.map(d => d.date);
//         const values = this.chartData.map(d => {
//             switch (d.status) {
//                 case 'Task Created': return 1;
//                 case 'On Hold': return 2;
//                 case 'Requirement Gathering': return 3;
//                 case 'Documentation Work': return 4;
//                 case 'Development In Progress': return 5;
//                 case 'Development Completed': return 6;
//                 case 'Testing In Progress': return 7;
//                 case 'Unit Testing Completed': return 8;
//                 case 'UAT In Progress': return 9;
//                 case 'UAT Completed': return 10;
//                 case 'Deployment Issue': return 11;
//                 case 'Task Completed': return 12;
//                 default: return 0;
//             }
//         });

//         const canvas = this.template.querySelector('canvas');
//         if (!canvas) return;

//         const ctx = canvas.getContext('2d');
//         if (this.chart) this.chart.destroy();

//         this.chart = new window.Chart(ctx, {
//             type: 'line',
//             data: {
//                 labels,
//                 datasets: [{
//                     label: 'Task Status Over Time',
//                     data: values,
//                     borderColor: '#0070d2',
//                     tension: 0.3,
//                     fill: false
//                 }]
//             },
//             options: {
//                 responsive: true,
//                 scales: {
//                     y: {
//                         ticks: {
//                             callback: value => {
//                                 switch (value) {
//                                     case 1: return 'Task Created';
//                                     case 2: return 'On Hold';
//                                     case 3: return 'Requirement Gathering';
//                                     case 4: return 'Documentation Work';
//                                     case 5: return 'Development In Progress';
//                                     case 6: return 'Development Completed';
//                                     case 7: return 'Testing In Progress';
//                                     case 8: return 'Unit Testing Completed';
//                                     case 9: return 'UAT In Progress';
//                                     case 10: return 'UAT Completed';
//                                     case 11: return 'Deployment Issue';
//                                     case 12: return 'Task Completed';
//                                     default: return '';
//                                 }
//                             }
//                         },
//                         title: { display: true, text: 'Status' }
//                     },
//                     x: {
//                         title: { display: true, text: 'Date' }
//                     }
//                 }
//             }
//         });
//     }
// }