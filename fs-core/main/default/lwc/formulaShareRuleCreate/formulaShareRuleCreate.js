import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import submitForCreate from '@salesforce/apex/FormulaShareMetadataControllerRules.submitForCreate';
import getNamespacePrefix from '@salesforce/apex/FormulaShareLWCUtilities.getNamespacePrefix';


export default class FormulaShareRuleCreate extends LightningElement {
    ruleDetails;
    @track processing = false;

    updateRule(event) {
        this.ruleDetails = event.detail;
    }

    // Subcribes to list platform event, and refresh treegrid each time event is received
    connectedCallback() {
        const messageCallback = (response) => {
            this.processing = false;

            const payload = response.data.payload;

            // Determine success and error property names (with namespace if present)
            let successPropName;
            let errorPropName;
            for(let [key, value] of Object.entries(payload)) {
                if(key.endsWith('Successful__c')) {
                    successPropName = key;
                }
                else if(key.endsWith('Error__c')) {
                    errorPropName = key;
                }
            }

            // Pop toast to confirm successful deployment
            if(payload[successPropName]) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'FormulaShare Rule created',
                        variant: 'success'
                    })
                );
                this.closeModal();
            }

            // Show error toast if response indicates errors
            else {
                let errorMessage = payload[errorPropName];
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Create Failed',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            }
        };

        // Get namespace prefix
        getNamespacePrefix()
            .then((prefix) => {
                // Invoke subscribe method of empApi. Pass reference to messageCallback
                subscribe('/event/'+prefix+'FormulaShare_Rule_DML__e', -1, messageCallback).then(response => {
                    //console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
                });
            })
            .catch(error => {
                this.showError(error, 'Error getting namespace prefix');
            });
    }

    @track saveDisabled = true;
    handleEnableSave(event) {
        if(!this.preventSave) {
            this.saveDisabled = false;
        }
    }

    // Don't allow save to be enabled if it's prevented
    preventSave = false;
    handlePreventSave(event) {
        this.saveDisabled = true;
        this.preventSave = true;
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    spinnerClasses;
    saveMethod() {

        // Check all components report positive validity
        var allValid = this.template.querySelector('c-formula-share-rule-detail').checkValidity();
        
        if(allValid) {
            //console.log('this.ruleDetails '+  JSON.stringify(this.ruleDetails));
            this.processing = true;
            this.spinnerClasses = 'processingMessage';

            // Access level field is required in the CMDT, so if it's not set explicity then set to N/A
            // This is required for team sharing where different fields are used to define access
            if(!this.ruleDetails.accessLevel) {
                this.ruleDetails.accessLevel = 'Varies';
            }

            submitForCreate({ fsRuleString : JSON.stringify(this.ruleDetails) })
                .then(() => {

                    // After submitting, wait 5 seconds and add class to display 
                    setTimeout(() => {
                        this.spinnerClasses = 'processingMessage afterProcessingMessage';
                    }, 5000);
                })
                .catch(error => {
                    this.processing = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error saving rule',
                            message: 'Message from Salesforce: ' + JSON.stringify(error),
                            variant: 'error'
                        })
                    );
                });
        }
    }
}