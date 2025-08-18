import { LightningElement } from 'lwc';
import getCaseNumber from '@salesforce/apex/RecallRegistrationFormController.getCaseNumber';

export default class RecallProcessThankyouForm extends LightningElement {

    caseId = null;
    caseNumber;
    showTemplate = false;
    duplicateRec = false;
    error;

    connectedCallback(){
        this.caseId = sessionStorage.getItem('dataZ');
        console.log('cache case', this.caseId);
        if(this.caseId!=null || this.caseId!=undefined){
            getCaseNumber({ caseId: this.caseId })
            .then(result => {
                this.caseNumber = result;
                this.error = undefined;
                this.showTemplate = true;
                if(this.caseNumber.includes("duplicate")){
                    this.caseNumber = this.caseNumber.replace('duplicate - ', '');
                    this.duplicateRec = true;
                }
            })
            .catch(error => {
                this.error = this.formatError(error);
                this.caseNumber = undefined;
            });
        }
        if(this.error){
            console.log('this.error', this.error);
        }
    }
    
}