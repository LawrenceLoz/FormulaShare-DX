import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import submitForEdit from '@salesforce/apex/FormulaShareRuleDMLController.submitForEdit';
import getNamespacePrefix from '@salesforce/apex/FormulaShareUtilities.getNamespacePrefix';


export default class FormulaShareRuleEdit extends LightningElement {
    @api ruleId;
    ruleDetails;
    @track processingEdit = false;

    updateRule(event) {
        this.ruleDetails = event.detail;
    }

    // Subcribes to list platform event, and refresh treegrid each time event is received
    connectedCallback() {
        const messageCallback = (response) => {
            this.processingEdit = false;
            if(response.data.payload.Successful__c) {
                console.log('Update Successful');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'FormulaShare Rule updated',
                        variant: 'success'
                    })
                );

                // Close modal
                this.closeModal();
            }

            else {
                console.log('Update Failed');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Update Failed',
                        message: response.data.payload.Error__c,
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
                    console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
                });
            })
            .catch(error => {
                console.log('Error getting namespace prefix');
                this.showError(error, 'Error getting namespace prefix');
            });
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    saveMethod() {
        var allValid = this.template.querySelector('c-formula-share-rule-detail').checkValidity();

        console.log('allValid '+ allValid);

        if(allValid) {
            console.log('this.ruleDetails '+  JSON.stringify(this.ruleDetails));
            this.processingEdit = true;
            submitForEdit({ fsRuleString : JSON.stringify(this.ruleDetails) })
                .then(() => {
                    console.log('submitted fsRuleString');
                })
                .catch(error => {
                    this.processingEdit = false;
                    console.log('Error saving rule: '+error);
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