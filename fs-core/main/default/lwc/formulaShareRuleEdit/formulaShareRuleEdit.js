import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import submitForEdit from '@salesforce/apex/FormulaShareMetadataControllerRules.submitForEdit';
import getNamespacePrefix from '@salesforce/apex/FormulaShareLWCUtilities.getNamespacePrefix';


export default class FormulaShareRuleEdit extends LightningElement {
    @api ruleId;
    ruleDetails;
    originalRuleDetails;
    @track processingEdit = false;
    @track showGroupsSyncDialog = false;
    @track waitingForGroupsSync = false;
    namespacePrefix = '';
    isEdit = true;

    updateRule(event) {
        this.ruleDetails = event.detail;
        // Store original rule details on first update for comparison
        if(!this.originalRuleDetails) {
            this.originalRuleDetails = JSON.parse(JSON.stringify(event.detail));
        }
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

            // Success attribute contains package namespace
            if(payload[successPropName]) {
                // If we're not waiting for groups sync, close modal and show success
                if(!this.waitingForGroupsSync) {
                    this.processingEdit = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'FormulaShare Rule updated',
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

            // Indicate update failure in toast
            else {
                this.processingEdit = false;
                this.waitingForGroupsSync = false;
                let errorMessage = payload[errorPropName];
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Update Failed',
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
            
            this.processingEdit = false;
            this.waitingForGroupsSync = false;
            
            if(payload[statusPropName] === 'Success') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'FormulaShare Rule updated and user groups synchronized',
                        variant: 'success'
                    })
                );
                this.closeModal();
            }
            else {
                // Rule was saved but groups sync failed
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Rule updated but groups sync failed',
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

    // Don't allow save to be enabled if it's prevented
    saveDisabled = false;
    handlePreventSave(event) {
        this.saveDisabled = true;
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    spinnerClasses;
    spinnerMessage = 'Updating rule metadata';
    
    // Check if rule requires groups sync confirmation
    get shouldShowGroupsSyncDialog() {
        if(!this.ruleDetails || !this.originalRuleDetails) {
            return false;
        }
        
        const isNowMatchingRule = this.ruleDetails.shareWith === 'Users with Matching Field Value';
        const wasMatchingRule = this.originalRuleDetails.shareWith === 'Users with Matching Field Value';
        
        // Show if:
        // 1. Now a matching rule (newly changed or already was)
        if(isNowMatchingRule) {
            // If it wasn't before, always show
            if(!wasMatchingRule) {
                return true;
            }
            // If it was before, show only if record field or user field changed
            if(this.ruleDetails.controllingObjectSharedToFieldAPIName !== this.originalRuleDetails.controllingObjectSharedToFieldAPIName ||
               this.ruleDetails.userFieldForMatching !== this.originalRuleDetails.userFieldForMatching) {
                return true;
            }
        }
        
        return false;
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
        this.processingEdit = true;
        this.spinnerClasses = 'processingMessage';
        this.spinnerMessage = 'Updating rule metadata';
        
        submitForEdit({ fsRuleString : JSON.stringify(this.ruleDetails) })
            .then(() => {
                // After submitting, wait 5 seconds and add class to display 
                setTimeout(() => {
                    this.spinnerClasses = 'processingMessage afterProcessingMessage';
                }, 5000);
            })
            .catch(error => {
                this.processingEdit = false;
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
            // Show confirmation dialog if groups sync is needed
            if(this.shouldShowGroupsSyncDialog) {
                this.showGroupsSyncDialog = true;
            }
            else {
                this.ruleDetails.syncGroupsOnSave = false;
                this.submitRule();
            }
        }
    }

    addAfterMessage() {
        this.spinnerClasses = 'deployMessage afterMessage';
    }
}