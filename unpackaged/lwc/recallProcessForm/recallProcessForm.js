import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import registerTheCase from '@salesforce/apex/RecallRegistrationFormController.registerTheCase';
import createDuplicateRecallRequest from '@salesforce/apex/RecallRegistrationFormController.createDuplicateRecallRequest';
import uploadMultipleFiles from '@salesforce/apex/RecallRegistrationFormController.uploadMultipleFiles';
import validateRequestor from '@salesforce/apex/RecallRegistrationFormController.validateRequestor'; 
import IMAGE_URL from '@salesforce/resourceUrl/imageOfCordCut';
import STATE_LABELS from '@salesforce/label/c.State_List';
import FINGERPRINT_HTML from '@salesforce/resourceUrl/fingerprintprowrapper'; 
import PUBLIC_KEY from '@salesforce/label/c.Fingerprint_Public_Key';

 
export default class RecallProcessForm extends NavigationMixin(LightningElement) {
    @track isLoading = false;
    @track duplicateCaseError = false;
    @track fingerprintMessage;
    registrationDataAll = {};
    @track stateOptions = [];
    // @track modelOptions = [
    //     { label: 'DUAF-005', value: 'DUAF-005' },
    //     { label: 'DUAF-10', value: 'DUAF-10' }
    // ];
    imageUrl = IMAGE_URL;
    filesData = [];
    files = [];
    photosUploaded = false;
    dontHavePhotos = false;
    @track filePreviews = [];
    fingerprint_visitor_id;
    fingerprint_request_id;

    get fingerprintHtmlUrl() {
        return `${FINGERPRINT_HTML}/fingerprint-pro-wrapper.html?token=${PUBLIC_KEY}`;
    }


    connectedCallback(){
        console.log('Inside connectedCallback');
        this.stateOptions = this.parseLabel(STATE_LABELS);

         window.addEventListener('message', this.handleFingerprintData);
           
        //this.getVisitorId();
    }
    disconnectedCallback() {
        window.removeEventListener('message', this.handleFingerprintData);
    }
    handleFingerprintData = (event) => {
        const { visitorId, requestId, error } = event.data || {};
        if (error) {
        console.error('FingerprintJS Error:', error);
        } else {
            this.fingerprint_visitor_id = visitorId;
            this.fingerprint_request_id = requestId;
            // validateRequestor({ requestId: this.fingerprint_request_id })
            // .then((response) => {
            //     if (response) {
            //         console.log('response:-', response);
            //         this.fingerprintMessage = response
            //          this.duplicateCaseError = true;
            //          this.isLoading = false;
            //         return;
            //     }
               
            // })
            // .catch((error) => {
            //     console.error('Error checking fingerprint:', error);
            //     this.isLoading = false;
            // });
            console.log('Visitor ID:', visitorId);
            console.log('Request ID:', requestId);
        }
   }


    // async getVisitorId() {
    //     try {
    //         await this.loadFingerprint();

    //         // ✅ Use global FingerprintJS v3
    //         const fpPromise = FingerprintJS.load({
    //             apiKey: "qv6GqJhAXXdc2ZRQxlls",
    //         })
    //         const fp = await fpPromise;
    //         const result = await fp.get();

    //         this.visitorId = result.visitorId;
    //         console.log('Visitor ID is:', this.visitorId);
    //         console.log('Visitor ID is:', result.requestId);
    //     } catch (error) {
    //         console.error('Could not get visitor ID:', error);
    //     }
    // }

    // loadFingerprint() {
    //     return new Promise((resolve, reject) => {
    //         if (window.FingerprintJS) {
    //             resolve();
    //             return;
    //         }

    //         const script = document.createElement('script');
    //         script.src = FINGERPRINT;
    //         script.onload = resolve;
    //         script.onerror = reject;
    //         document.head.appendChild(script);
    //     });
    // }


    parseLabel(labelString) {
        return labelString.split(',').map(entry => {
            const [value, label] = entry.trim().split(':');
            return { label, value };
        });
    }

    handleOnchange(event){
        console.log('Handle on change event', event.target.name);
        //this.validateFields([event.target]);
    }

    handleBlur(event){
        console.log('handleBlur', event.target.name);
        //this.validateFields([event.target]);
    }

    _findLabelForInput(input) {
        const parent = input.closest('.box');
        return parent ? parent.querySelector('label') : null;
    }

    handleRegistration(event){
        this.isLoading = true;
        console.log('handleRegistration');
        const allInputFields = this.template.querySelectorAll('input , select.inline-input');
        const isValid = this.validateFields(allInputFields);

        if (!isValid) {
            console.log('Validation failed. Submission stopped.');
            this.isLoading = false;
            return;
        }

        console.log('photosUploaded , dontHavePhotos', this.photosUploaded , this.dontHavePhotos);
        if(!this.photosUploaded && !this.dontHavePhotos){
            alert('Please upload at least one image or check the checkbox below image upload.');
            this.isLoading = false;
            return;
        }

        if (!this.fingerprint_visitor_id) {
            alert('Fingerprint ID not ready yet. Please wait and try again.');
            this.isLoading = false;
            return;
        }

        validateRequestor({ requestId: this.fingerprint_request_id })
            .then((response) => {
                if (response) {
                    if (response === 'Success') {
                        this.proceedWithCaseSubmission(allInputFields);
                    } else {
                        console.log('response:-', response);
                        this.fingerprintMessage = response;
                        this.duplicateCaseError = true;
                        this.isLoading = false;
                        return;
                    }
                }
            })
            .catch((error) => {
                console.error('Error checking fingerprint:', error);
                this.isLoading = false;
            });
    }

    proceedWithCaseSubmission(allInputFields) {
        if (allInputFields != null) {
            let registrationData = {};
            allInputFields.forEach(inputField => {
                registrationData[inputField.name] = inputField.value;
            });
            console.log('while submitting:- ', this.fingerprint_visitor_id);
            this.registrationDataAll = { 
                ...this.registrationDataAll, 
                ...registrationData, 
                VisitorFingerprintId: this.fingerprint_visitor_id 
            };
        }

        registerTheCase({ recallWrapper: this.registrationDataAll })
            .then(caseId => {
                console.log('Case created:', caseId);
                if (!this.dontHavePhotos) {
                    return uploadMultipleFiles({ filesData: this.filesData, caseId: caseId })
                        .then(() => {
                            console.log('Files uploaded!');
                            this.navigateUserToThankyou(caseId);
                        })
                        .catch(error => {
                            console.error('Upload error:', error);
                            alert('Upload failed.');
                        });
                } else {
                    this.navigateUserToThankyou(caseId);
                }
            })
            .catch(error => {
                console.error('Error creating case:', error);
                alert('Case creation failed. Please try again.');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    handlePicklistChange(event){
        console.log('handle Picklist change', event.target.name);
    }

    validateFields(fields) {
        let allValid = true;

        fields.forEach(input => {
            const value = input.value?.trim();
            const inputId = input.id;
            console.log('Input--'+inputId);
            const labelElement = this.template.querySelector(`label[for="${inputId}"]`) 
                || this.template.querySelector(`label[for=${inputId}]`) 
                || this._findLabelForInput(input);

            const isRequired = labelElement && labelElement.textContent.includes('*');

            if (isRequired && !value) {
                input.setCustomValidity('This field is required.');
                allValid = false;
            } else {
                input.setCustomValidity('');
                if (inputId == 'SuppliedEmail-18') {
                    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

                    if (!emailPattern.test(value)) {
                        input.setCustomValidity('Please enter a valid email address (e.g., user@example.com).');
                        allValid = false;
                    } else {
                        input.setCustomValidity('');
                    }
                }
                if (inputId == 'SuppliedPhone-18' || (inputId == 'ContactPhone-18' && value)) {
                    const phonePattern = /^\d{10}$/;
                    console.log('Input for phone--'+inputId);
                    if (!phonePattern.test(value)) {
                        input.setCustomValidity('Please enter a valid phone number with 10 digits only.');
                        allValid = false;
                    } else {
                        input.setCustomValidity('');
                    }
                }
            }

            input.reportValidity();
        });
        return allValid;
    }

    closeFingerprintModal() {
        this.duplicateCaseError = false;
    }


    handleFileOnChange(event) {
        const files = [...event.target.files];
        event.target.value = null;
        this.isLoading = true;
        this.photosUploaded = false;
        console.log('files', files);
        Promise.all(files.map(file => this.readFileAsBase64(file)))
            .then(newFiles => {
                if (!this.filesData) this.filesData = [];
                if (!this.filePreviews) this.filePreviews = [];

                newFiles.forEach(newFile => {
                    if(this.filesData != null || this.filesData != undefined){
                        const dataIndex = this.filesData.findIndex(f => f.fileName === newFile.fileName);
                        if (dataIndex !== -1) {
                            this.filesData[dataIndex] = newFile;
                        } else {
                            this.filesData.push(newFile);
                        }
                    }else{
                        this.filesData.push(newFile);
                    }
                    const newPreview = {
                        name: newFile.fileName,
                        previewUrl: `data:image/jpeg;base64,${newFile.base64}`
                    };
                    if(this.filePreviews != null || this.filePreviews != undefined){
                        const previewIndex = this.filePreviews.findIndex(f => f.name === newFile.fileName);
                        if (previewIndex !== -1) {
                            this.filePreviews[previewIndex] = newPreview;
                        } else {
                            this.filePreviews.push(newPreview);
                        }
                    }else{
                        this.filePreviews.push(newPreview);
                    }
                    
                });

                this.filesData = [...this.filesData];
                this.filePreviews = [...this.filePreviews];

                console.log('All base64 files ready:', this.filesData);
                this.photosUploaded = true;
            })
            .catch(error => {
                console.error('Error reading files', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
            
    }

    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                resolve({
                    fileName: file.name,
                    base64: base64
                });
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    handleCheckboxChange(event){
        this.dontHavePhotos = event.target.checked;
        this.filesData = [];
        this.filePreviews = [];
        this.photosUploaded = false;
    }

    allowOnlyDigits(event) {
        const charCode = event.charCode;
        if (charCode < 48 || charCode > 57) {
            event.preventDefault();
        }
    }

    handleRemoveFile(event) {
        event.stopPropagation();
        event.preventDefault();
        const fileName = event.currentTarget.dataset.name;
        this.tempFilesData = this.filesData.filter(file => file.fileName !== fileName);
        this.tempFilePreviews = this.filePreviews.filter(preview => preview.name !== fileName);
        this.filesData = [];
        this.filePreviews = [];
        this.filesData = [...this.tempFilesData];
        this.filePreviews = [...this.tempFilePreviews];
        if (this.filesData.length === 0) {
            this.photosUploaded = false;
        }
    }

    navigateUserToThankyou(caseId){
        this.isLoading = false;
        console.log('before test');
        sessionStorage.setItem('dataZ', caseId);
        console.log('after test');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/recall-process-thankyou`
            }
        });
        console.log('after test');
    }

    duplicateSubmitRecord(){
        const caseNumber = this.fingerprintMessage.match(/\b\d{8}\b/);
        console.log(caseNumber[0]);

        const allInputFields = this.template.querySelectorAll('input , select.inline-input');

        if (allInputFields != null) {
            let registrationData = {};
            allInputFields.forEach(inputField => {
                registrationData[inputField.name] = inputField.value;
            });
            console.log('while submitting:- ', this.fingerprint_visitor_id);
            this.registrationDataAll = { 
                ...this.registrationDataAll, 
                ...registrationData, 
                VisitorFingerprintId: this.fingerprint_visitor_id 
            };
        }

        createDuplicateRecallRequest({ casenumber : caseNumber[0] , recallWrapper: this.registrationDataAll })
            .then(recIds => {
                var duplicateRequestId = recIds[0];
                var caseId = recIds[1];
                console.log('duplicateRequest created:', duplicateRequestId);
                if (!this.dontHavePhotos) {
                    return uploadMultipleFiles({ filesData: this.filesData, caseId: duplicateRequestId })
                        .then(() => {
                            console.log('Files uploaded!');
                            this.navigateUserToThankyou(caseId);
                        })
                        .catch(error => {
                            console.error('Upload error:', error);
                            alert('Upload failed.');
                        });
                } else {
                    this.navigateUserToThankyou(caseId);
                }
            })
            .catch(error => {
                console.error('Error creating case:', error);
                alert('Case creation failed. Please try again.');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

}