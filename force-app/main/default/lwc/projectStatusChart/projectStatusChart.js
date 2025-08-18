// import { LightningElement, wire, track } from 'lwc';
// import getAllProjectsDetails from '@salesforce/apex/projectStatusChartController.getAllProjectsDetails';

// export default class ProjectList extends LightningElement {
//     @track projects ; 
//     error;

//     @track selectedStage; // To store selected combobox value

//     @track projectOptions = [
//         { label: 'In Progress', value: 'In Progress' },
//         { label: 'On Hold', value: 'On Hold' },
//         { label: 'Completed', value: 'Completed' },
//         { label: 'Not Started', value: 'Not Started' }
//     ];

//     // Handle combobox value change
//     handleProjectChange(event) {
//         this.selectedStage = event.detail.value;
//         console.log('Selected Stage:', this.selectedStage);
//         this.filterProjects(); // filter projects after selection
//     }

//     allProjects = []; // to store original fetched projects
//     showAllProject(){
//         this.projects = true;
//     }

//     @wire(getAllProjectsDetails)
//     wiredProjects({ error, data }) {
//         if (data) {
//             // Store all projects first
//             this.allProjects = data.map((project, index) => {
//                 let rowClass = '';
//                 if (project.Status__c === 'Completed') {
//                     rowClass = 'row-red';
//                     console.log(`Completed Project: ${project.Name}`);
//                 }
//                 if (project.Status__c === 'On Hold' || project.Status__c === 'Not Started') {
//                     rowClass = 'row-orange';
//                     console.log(`On Hold/Not Started Project: ${project.Name}`);
//                 }
//                 return {
//                     ...project,
//                     rowClass,
//                     rowNumber: index + 1
//                 };
//             });
//             // Initially, show all projects
//             this.projects = [...this.allProjects];
//             this.error = undefined;
//         } else if (error) {
//             this.error = error.body.message;
//             this.projects = undefined;
//         }
//     }

//     // Filter projects based on selected stage
//     filterProjects() {
//         if (this.selectedStage) {
//             this.projects = this.allProjects.filter(project => 
//                 project.Status__c === this.selectedStage
//             );
//         } else {
//             // If no selection, show all
//             this.projects = [...this.allProjects];
//         }
//     }
// }




import { LightningElement, wire, track } from 'lwc';
import getAllProjectsDetails from '@salesforce/apex/projectStatusChartController.getAllProjectsDetails';

export default class ProjectList extends LightningElement {
    @track projects; 
    error;
    allProjects = []; // to store original fetched projects
    @track selectedStage; // To store selected combobox value

    @track projectOptions = [
        { label: 'In Progress', value: 'In Progress' },
        { label: 'On Hold', value: 'On Hold' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Not Started', value: 'Not Started' }
    ];

    // Handle combobox value change
    handleProjectChange(event) {
        this.selectedStage = event.detail.value;
        console.log('Selected Stage:', this.selectedStage);
        this.filterProjects(); // filter projects after selection
    }

    // Show all projects
    showAllProject() {
        this.selectedStage = undefined;  // Reset the combobox selection
        this.projects = [...this.allProjects]; // Show all projects
    }

    @wire(getAllProjectsDetails)
    wiredProjects({ error, data }) {
        if (data) {
            // Store all projects first
            this.allProjects = data.map((project, index) => {
                let rowClass = '';
                if (project.Status__c === 'Completed') {
                    rowClass = 'row-red';
                    console.log(`Completed Project: ${project.Name}`);
                }
                if (project.Status__c === 'On Hold') {
                    rowClass = 'row-yellow';
                    console.log(`On Hold/Not Started Project: ${project.Name}`);
                }
                if (project.Status__c === 'Not Started') {
                    rowClass = 'row-green';
                    console.log(`Not Started Project: ${project.Name}`);
                }
                return {
                    ...project,
                    rowClass,
                    rowNumber: index + 1
                };
            });
            // Initially, show all projects
            this.projects = [...this.allProjects];
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.projects = undefined;
        }
    }

    // Filter projects based on selected stage
    filterProjects() {
        if (this.selectedStage) {
            // Filter projects based on the selected stage
            this.projects = this.allProjects
                .filter(project => project.Status__c === this.selectedStage)
                .map(project => {
                    return { ...project, rowClass: '' }; // Remove rowClass to disable color
                });
        } else {
            // If no selection, show all projects with their original rowClass
            this.projects = [...this.allProjects];
        }
    }
}