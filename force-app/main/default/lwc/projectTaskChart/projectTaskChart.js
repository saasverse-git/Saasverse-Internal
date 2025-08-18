import { LightningElement, api, wire, track } from 'lwc';
import getTaskCountsByDeveloper from '@salesforce/apex/ProjectTaskController.getTaskCountsByDeveloper';
import getTasksByDeveloper from '@salesforce/apex/ProjectTaskController.getTasksByDeveloper';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';
import ChartJSDatalabels from '@salesforce/resourceUrl/ChartJSDatalabels';
import { NavigationMixin } from 'lightning/navigation';

export default class ProjectTaskCount extends NavigationMixin(LightningElement) {
    chart;
    chartJsInitialized = false;
    taskCounts;
    @api rag;
    @track showModal = false;
    @track selectedDeveloper = '';
    @track developerTasks = [];
    @track loadingTasks = false;
    @track showSummaryModal = false;
    @track summaryData = {};
    @track searchValue = '';
    @track developerSuggestions = [];
    @track showSuggestions = false;
    @track searchError = '';
    @api developerName;

    @wire(getTaskCountsByDeveloper)
    wiredCounts({ error, data }) {
        if (data) {
            this.taskCounts = data;
            this.renderChart();
        } else if (error) {
            console.error('Wire error:', error);
        }
    }

    renderedCallback() {
        if (this.chartJsInitialized) return;
        this.loadJS();
    }

    async loadJS() {
        try {
            await loadScript(this, ChartJS);
            await loadScript(this, ChartJSDatalabels);
            this.chartJsInitialized = true;
            this.renderChart();
        } catch (error) {
            console.error('ChartJS load failed:', error);
        }
    }

    renderChart() {
        if (!this.chartJsInitialized || !this.taskCounts) return;

        const canvas = this.template.querySelector('canvas.donutChart');
        if (!canvas) return;

        if (this.chart) {
            this.chart.destroy();
        }

        const sortedData = [...this.taskCounts].sort((a, b) =>
            a.developerName.localeCompare(b.developerName)
        );

        const labels = sortedData.map(item => item.developerName);
        const data = sortedData.map(item => item.count);
        const total = data.reduce((sum, val) => sum + val, 0);
        const backgroundColors = [
            '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF', '#FF9F40', '#00C49F', '#FFBB28'
        ];

        const centerTextPlugin = {
            id: 'centerText',
            afterDraw(chart) {
                const { ctx, chartArea: { width, height } } = chart;
                ctx.save();
                ctx.font = 'bold 20px Arial';
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                ctx.fillStyle = '#333';
                ctx.fillText(total, width / 2, height / 2);
                ctx.font = '12px Arial';
                ctx.fillText('Total', width / 2, height / 2 + 20);
                ctx.restore();
            }
        };

        this.chart = new window.Chart(canvas, {
            type: 'doughnut',
            data: {
                labels,
                datasets: [{
                    label: 'Task Count',
                    data,
                    backgroundColor: backgroundColors.slice(0, labels.length),
                }]
            }, 
            options: {
                responsive: true,
                plugins: {
                    title: { display: true, text: 'Project Task Count by Developer' },
                    legend: { display: false },
                    datalabels: {
                        color: '#fff',
                        font: { weight: 'bold', size: 14 },
                        formatter: value => value
                    }
                }
            },
            plugins: [window.ChartDataLabels, centerTextPlugin]
        });
    }

    // Search input logic
    handleSearchInput(event) {
        this.searchValue = event.target.value;
        if (!this.searchValue) {
            this.clearSearch();
            return;
        }
        const input = this.searchValue.toLowerCase();
        this.developerSuggestions = this.taskCounts
            ?.map(tc => tc.developerName)
            .filter(name => name?.toLowerCase().includes(input));
        this.showSuggestions = this.developerSuggestions.length > 0;
        this.searchError = this.developerSuggestions.length === 0 ? 'No developer found.' : '';
    }

    handleSuggestionClick(event) {
        const name = event.currentTarget.dataset.name;
        this.searchValue = name;
        this.showSuggestions = false;
        this.openDeveloperModal(name);
    }

    handleSearchKeydown(event) {
        if (event.key === 'Enter' && this.searchValue) {
            const match = this.taskCounts?.find(
                tc => tc.developerName.toLowerCase() === this.searchValue.toLowerCase()
            );
            if (match) {
                this.showSuggestions = false;
                this.openDeveloperModal(match.developerName);
            } else {
                this.searchError = 'No developer found with that name.';
            }
        }
    }

    openDeveloperModal(developerName) {
        this.selectedDeveloper = developerName;
        this.showModal = true;
        this.loadingTasks = true;

        getTasksByDeveloper({ developerName })
            .then(result => {
                this.developerTasks = result;
                this.loadingTasks = false;
                // Immediately show summary modal (skip detail table)
                this.prepareSummary();
            })
            .catch(() => {
                this.developerTasks = [];
                this.loadingTasks = false;
                this.searchError = 'Failed to load tasks';
            });
    }

    prepareSummary() {
        const tasks = this.developerTasks || [];
        
        const totalTasks = tasks.length;
        const completedTasks = tasks.filter(t =>['Task Completed'].includes(t.Current_Task_Status__c)).length; 
        const uncompletedTasks = totalTasks - completedTasks;
        const totalEstimatedEffort = tasks.reduce((sum, t) => sum + (parseFloat(t.Estimated_Effort_in_hrs__c) || 0), 0);
        const totalConsumed = tasks.reduce((sum, t) => sum + (parseFloat(t.Hours_so_Far_consumed__c) || 0), 0).toFixed(2);
        const totalRealBusinessHrs = tasks.reduce((sum, t) => sum + (parseFloat(t.Real_Business_hours_needed__c) || 0), 0);
        const redRagTasks = tasks.filter(t => t.RAG__c === '🔴 Red').length;
        const orangeRagTasks = tasks.filter(t => t.RAG__c === '🟠 Orange').length;
        const greenRagTasks = tasks.filter(t => t.RAG__c === '🟢 Green').length;

        this.summaryData = {
            totalTasks,
            completedTasks,
            uncompletedTasks,
            totalEstimatedEffort,
            totalConsumed,
            totalRealBusinessHrs,
            redRagTasks,
            orangeRagTasks,
            greenRagTasks
        };
        this.showSummaryModal = true;
    }

    clearSearch() {
        this.searchValue = '';
        this.developerSuggestions = [];
        this.showSuggestions = false;
        this.searchError = '';
    }

    closeSummaryModal() {
        this.showSummaryModal = false;
        this.showModal = false;
    }

    get developerTasksWithIndex() {
        return (this.developerTasks || []).map((task, index) => ({
            ...task,
            srNo: index + 1
        }));
    }

    // Child method trigger
    handleShowRed() {
        console.log('redcliked' );
        this.refs.ragViewer.showRagTasks('🔴 Red');
    }

    handleShowOrange() {
        console.log('orangecliked' );
        this.refs.ragViewer.showRagTasks('🟠 Orange');
    }

    handleShowAllTask() {
        const baseUrl = window.location.origin;
        const url = `${baseUrl}/lightning/n/Show_Developer_All_Task?c__developerName=${encodeURIComponent(this.selectedDeveloper)}`;
        window.open(url, '_blank');
    }


}