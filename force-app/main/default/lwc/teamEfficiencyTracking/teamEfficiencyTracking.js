import { LightningElement, wire } from 'lwc';
import getResourceEfficiencyData from '@salesforce/apex/teamEfficiencyTrackingController.getResourceEfficiencyData';
import ChartJS from '@salesforce/resourceUrl/ChartJS';
import { loadScript } from 'lightning/platformResourceLoader';

export default class ResourceEfficiencyChart extends LightningElement {
    chart;
    chartjsInitialized = false;
    chartjsLoaded = false;
    resourceData;

    @wire(getResourceEfficiencyData)
    wiredResources({ error, data }) {
        if (data) {
            this.resourceData = data;
            this.tryInitializeChart(); 
        } else if (error) {
            console.error('Data error: ', error);
        }
    }

    renderedCallback() {
        if (this.chartjsInitialized) return;
        this.chartjsInitialized = true;

        loadScript(this, ChartJS)
            .then(() => {
                this.chartjsLoaded = true;
                this.tryInitializeChart(); 
            })
            .catch(error => {
                console.error('ChartJS Load Error: ', error);
            });
    }

    tryInitializeChart() {
        if (!this.chartjsLoaded || !this.resourceData || this.chart) {
            return;
        }

        const canvas = this.template.querySelector('canvas');
        const ctx = canvas.getContext('2d');

        const resourceNames = this.resourceData.map(res => {
            const parts = res.Name.split(' ');
            return parts.length > 1
                ? [parts[0], parts.slice(1).join(' ')]
                : [res.Name];
        });

        const efficiencies = this.resourceData.map(res => Math.round(res.Efficiency__c));

        const barCount = this.resourceData.length;
        const widthPerBar = 150;
        canvas.height = 400;
        canvas.width = barCount > 5 ? barCount * widthPerBar : this.template.querySelector('.scroll-wrapper').clientWidth;

        this.chart = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels: resourceNames,
                datasets: [{
                    label: 'Efficiency (%)',
                    data: efficiencies,
                    backgroundColor: efficiencies.map(eff => eff > 100 ? 'red' : '	#6495ED'),
                    borderWidth: 0,
                    barThickness: 20,
                    maxBarThickness: 30,
                    categoryPercentage: 0.6,
                    barPercentage: 0.8
                }]
            },
            options: {
                indexAxis: 'x',
                responsive: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        displayColors: false,
                        callbacks: {
                            label: function (context) {
                                return context.parsed.y + '%';
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 150,
                        grid: {
                            display: false,
                            drawBorder: false
                        },
                        title: {
                            display: true,
                            text: 'Efficiency (%)'
                        },
                        ticks: {
                            font: { size: 14 },
                            stepSize: 25,
                            callback: function (value) {
                                return value + '%';
                            }
                        }
                    },
                    x: {
                        grid: {
                            display: false,
                            drawBorder: false
                        },
                        ticks: {
                            autoSkip: false,
                            font: { size: 14 },
                            maxRotation: 0,
                            minRotation: 0
                        }
                    }
                }
            }
        });
    }
}