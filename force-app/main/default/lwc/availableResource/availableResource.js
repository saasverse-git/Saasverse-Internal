import { LightningElement, track } from 'lwc';
import getResource from '@salesforce/apex/resourceController.getAvailableResource';

export default class AvailableResource extends LightningElement {

    @track allResource = [];
    @track resourceId = '';

    connectedCallback() {
        getResource()
            .then(result => {
                this.allResource = result.map(res => ({
                    label: res.Name,
                    value: res.Id
                }));
            })
            .catch(error => {
                console.error('Error fetching resources:', error);
            });
    }

    handleResource(event) {
        const selectedId = event.detail.value;
        console.log('Selected Resource ID:', selectedId);
    }
    
}