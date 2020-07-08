import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import submitForCreate from '@salesforce/apex/FormulaShareRuleDMLController.submitForCreate';


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
            if(response.data.payload.Successful__c) {
                console.log('Create Successful');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'FormulaShare Rule created',
                        variant: 'success'
                    })
                );

                // Fire event to refresh list view and cloe modal
                const evt = new CustomEvent('rulecreated');
                this.dispatchEvent(evt);
                this.closeModal();
            }

            else {
                console.log('Create Failed');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Create Failed',
                        message: response.data.payload.Error__c,
                        variant: 'error'
                    })
                );
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe('/event/FormulaShare_Rule_DML__e', -1, messageCallback).then(response => {
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
        });
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    saveMethod() {
        var allValid = this.template.querySelector('c-formula-share-rule-detail').checkValidity();

        console.log('allValid '+ allValid);

        console.log('this.ruleDetails '+  JSON.stringify(this.ruleDetails));
        this.processing = true;
        submitForCreate({ fsRuleString : JSON.stringify(this.ruleDetails) })
            .then(() => {
                console.log('submitted fsRuleString');
            })
            .catch(error => {
                this.processing = false;
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