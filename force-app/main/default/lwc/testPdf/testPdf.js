import { LightningElement } from 'lwc';
import uploadFile from '@salesforce/apex/PdfUploaderController.uploadFile';
export default class TestPdf extends LightningElement {
    fileData;
    extractedData;

    // Handle file selection and store the selected file
    handleFileUpload(event) {
        const file = event.target.files[0];  // Get the first file
        if (file) {
            this.fileData = file;  // Store the selected file
        }
    }

    // Handle file upload
    handleUpload() {
        if (this.fileData) {
            const file = this.fileData;
            const reader = new FileReader();

            // Read the file as a base64-encoded string
            reader.onloadend = () => {
                const base64FileData = reader.result.split(',')[1];  // Extract base64 part

                // Call Apex method to upload the file
                uploadFile({ base64Data: base64FileData, fileName: file.name })
                    .then((result) => {
                        // Log the result (extracted data) to the console
                        console.log('Extracted Data from PDF:', result);
                        // Store the extracted data to display in the UI
                        this.extractedData = result;
                    })
                    .catch((error) => {
                        console.error('Error uploading PDF:', error);
                    });
            };

            // Start reading the file as a DataURL (base64 string)
            reader.readAsDataURL(file);
        } else {
            console.log('No file selected.');
        }
    }
}