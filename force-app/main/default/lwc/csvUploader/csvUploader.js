import { LightningElement } from 'lwc';
import uploadCSV from '@salesforce/apex/CSVUploaderController.uploadCSV';

export default class CsvUploader extends LightningElement {
    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = () => {
                uploadCSV({ csvData: reader.result })
                    .then(result => {
                        alert('Upload Successful: ' + result);
                    })
                    .catch(error => {
                        alert('Error: ' + JSON.stringify(error));
                    });
            };
            reader.readAsText(file);
        }
    }
}