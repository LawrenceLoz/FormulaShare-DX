import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import submitForCreate from '@salesforce/apex/FormulaShareMetadataControllerRules.submitForCreate';
import getNamespacePrefix from '@salesforce/apex/FormulaShareLWCUtilities.getNamespacePrefix';


export default class FormulaShareRuleCreate extends LightningElement {
    ruleDetails;
    @track processing = false;
    @track showGroupsSyncDialog = false;
    @track waitingForGroupsSync = false;
    namespacePrefix = '';
    isEdit = false;

    updateRule(event) {
        this.ruleDetails = event.detail;
    }

    // Subcribes to list platform event, and refresh treegrid each time event is received
    connectedCallback() {
        // Get namespace prefix for platform events
        getNamespacePrefix()
            .then((prefix) => {
                this.namespacePrefix = prefix;
                this.subscribeToRuleDMLEvents(prefix);
                this.subscribeToGroupsUpdateEvents(prefix);
            })
            .catch(error => {
                this.showError(error, 'Error getting namespace prefix');
            });
    }
    
    subscribeToRuleDMLEvents(prefix) {
        const messageCallback = (response) => {
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
                // If we're not waiting for groups sync, close modal and show success
                if(!this.waitingForGroupsSync) {
                    this.processing = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'FormulaShare Rule created',
                            variant: 'success'
                        })
                    );
                    this.closeModal();
                }
                // Otherwise, update spinner message to indicate groups sync in progress
                else {
                    this.spinnerClasses = 'processingMessage';
                    this.spinnerMessage = 'Synchronising user public groups';
                }
            }

            // Show error toast if response indicates errors
            else {
                this.processing = false;
                this.waitingForGroupsSync = false;
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

        subscribe('/event/'+prefix+'FormulaShare_Rule_DML__e', -1, messageCallback).then(response => {
            //console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
        });
    }
    
    subscribeToGroupsUpdateEvents(prefix) {
        const messageCallback = (response) => {
            // Only process if we're waiting for groups sync
            if(!this.waitingForGroupsSync) {
                return;
            }
            
            const payload = response.data.payload;
            
            // Find property names (accounting for namespace)
            let prefixPropName, statusPropName, errorPropName;
            for(let [key, value] of Object.entries(payload)) {
                if(key.endsWith('Prefix__c')) {
                    prefixPropName = key;
                }
                else if(key.endsWith('Status__c')) {
                    statusPropName = key;
                }
                else if(key.endsWith('Error_Message__c')) {
                    errorPropName = key;
                }
            }
            
            // Only process events for user field groups (FSUSR_ prefix)
            if(payload[prefixPropName] !== 'FSUSR_') {
                return;
            }
            
            this.processing = false;
            this.waitingForGroupsSync = false;
            
            if(payload[statusPropName] === 'Success') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'FormulaShare Rule created and user groups synchronized',
                        variant: 'success'
                    })
                );
                this.closeModal();
            }
            else {
                // Rule was saved but groups sync failed
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Rule created but groups sync failed',
                        message: 'The rule was saved successfully, but there was an error synchronising user public groups: ' + (payload[errorPropName] || 'Unknown error'),
                        variant: 'warning'
                    })
                );
                this.closeModal();
            }
        };
        
        subscribe('/event/'+prefix+'FormulaShare_Groups_Update__e', -1, messageCallback).then(response => {
            //console.log('Successfully subscribed to groups update events');
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
    spinnerMessage = 'Updating rule metadata';
    
    // Check if rule requires groups sync confirmation
    get isMatchingUserFieldRule() {
        return this.ruleDetails && 
               this.ruleDetails.shareWith === 'Users with Matching Field Value';
    }
    
    handleGroupsSyncNow() {
        this.showGroupsSyncDialog = false;
        this.waitingForGroupsSync = true;
        this.ruleDetails.syncGroupsOnSave = true;
        this.submitRule();
    }
    
    handleGroupsWaitForBatch() {
        this.showGroupsSyncDialog = false;
        this.ruleDetails.syncGroupsOnSave = false;
        this.submitRule();
    }
    
    handleGroupsSyncCancel() {
        this.showGroupsSyncDialog = false;
    }
    
    submitRule() {
        this.processing = true;
        this.spinnerClasses = 'processingMessage';
        this.spinnerMessage = 'Updating rule metadata';

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
                this.waitingForGroupsSync = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error saving rule',
                        message: 'Message from Salesforce: ' + JSON.stringify(error),
                        variant: 'error'
                    })
                );
            });
    }
    
    saveMethod() {
        // Check all components report positive validity
        var allValid = this.template.querySelector('c-formula-share-rule-detail').checkValidity();
        
        if(allValid) {
            // Show confirmation dialog if this is a matching user field rule
            if(this.isMatchingUserFieldRule) {
                this.showGroupsSyncDialog = true;
            }
            else {
                this.ruleDetails.syncGroupsOnSave = false;
                this.submitRule();
            }
        }
    }
}