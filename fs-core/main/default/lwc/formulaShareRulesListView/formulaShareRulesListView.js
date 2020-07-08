import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import getTreeGridData from '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData';
import recalculateSharing from '@salesforce/apex/FormulaShareRulesListViewController.recalculateSharing';
import activateDeactivate from '@salesforce/apex/FormulaShareRulesListViewController.activateDeactivate';

export default class TreeGrid extends LightningElement {
    
    @track data = [];
    @track columns = [
        {type: 'text', fieldName: 'tableLabel', label: 'Shared Object'
//        , initialWidth: 150
    },
        {type: 'text', fieldName: 'shareWith', label: 'Share With', sortable: true
//        , initialWidth: 150
    },
        {type: 'url', fieldName:'sharedToLink', label:'Specified in Field', 
//        initialWidth: 250,
            typeAttributes: {label: {fieldName:'sharedToLinkLabel'}, target:'_blank'} },
        {type: 'text', fieldName: 'controllingObject', label: 'On Object'
//        , initialWidth: 150
    },
        {type: 'text', fieldName: 'accessLevel', label: 'Access'
//        , initialWidth: 75
    },
//        {type: 'text', fieldName: 'sharingReason', label: 'Sharing Reason'
//        , initialWidth: 200
//    },
        {type: 'text', fieldName: 'lastCalcStatus', label: 'Last Full Assessment'
        , initialWidth: 160
    },
        {type: 'boolean', fieldName: 'active', label: 'Active'
        , initialWidth: 75
    },
        {type: 'action', typeAttributes: {rowActions: this.getRowActions} }
    ];


    // Core method to load treegrid data from handler
    refreshReason;
    refreshObjectLabel;
    provisionedValue;
    firstLoad = true;
    @track treeItems;
    @track currentExpanded;
    @track processingLoad = true;

    @api
    get refreshList() {}
    set refreshList(value) {
        if(value == true) {
            refreshApex(this.provisionedValue);
        }
    }

    @wire(getTreeGridData)
    wireTreeData(value) {
        const { data, error } = value;
        this.provisionedValue = value;

        if (data) {
            let tempjson = JSON.parse(JSON.stringify(data).split('items').join('_children'));
            this.treeItems = tempjson;
            console.log('this.treeItems: '+JSON.stringify(this.treeItems));
            console.log('loading data');

            if(this.firstLoad) {
                this.expandAllRows(tempjson);
                this.manageRefreshEvents();     // Subscribe to event channel
                this.firstLoad = false;
            }

            else {
                this.notifyDataUpdates();   // Pop toast with details of update
            }

            this.processingLoad = false;
        }

        else if(error) {
            console.log('Error fetching data from Salesforce');
            this.showError(error, 'Error fetching data from Salesforce');
        }
    }

    // Populate keys into currentExpanded to expand all
    expandAllRows(tempjson) {
        this.currentExpanded = [];
        for(var i = 0; i < tempjson.length; i++) {
            this.currentExpanded.push(tempjson[i].key);

            var children = tempjson[i]._children;
            for(var j = 0; j < children.length; j++) {
                this.currentExpanded.push(children[j].key);
            }
        }
    }

    // Pop notification on data load with what's updated (from refresh reason)
    notifyDataUpdates() {
        console.log('refreshReason : '+ this.refreshReason);

        // Set a message to show for activation changes
        let message;
        switch (this.refreshReason) {
            case 'activate':
                message = 'Rule activated';
                break;
            case 'deactivate':
                message = 'Rule deactivated';
                break;
            case 'recalculation':
                message = 'Full sharing calculation for ' + this.refreshObjectLabel + ' complete';
                break;
        }
        
        // Display toast if message is populated no modal is open
        if(message && !this.openModal) {
            console.log('message :'+ message);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: message,
                    variant: 'success'
                })
            );
        }

        this.refreshReason = null;
        this.refreshObjectLabel = null;
    }

    // Subcribes to list platform event, and refresh treegrid each time event is received
    @track channelName = '/event/FormulaShare_List_Update__e';
    manageRefreshEvents() {
        const messageCallback = (response) => {
            this.refreshReason = response.data.payload.Type__c;
            this.refreshObjectLabel = response.data.payload.Object_Label__c;
            refreshApex(this.provisionedValue);
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
        });
    }


    // Set available drop-down actions for each grid row
    getRowActions(row, doneCallback) {
        const actions =[];
        const isActive = row['active'];
        const isParentRow = row['isParentRow'];
            if(isParentRow) {
                actions.push({
                    'label': 'Recalculate Sharing',
                    'name': 'recalculate'
                });
            }
            else {
            actions.push({
                'label': 'Edit',
                'name': 'edit'
            });
            if (isActive) {
                    actions.push({
                        'label': 'Deactivate',
                        'name': 'deactivate'
                    });
                } else {
                    actions.push({
                        'label': 'Activate',
                        'name': 'activate'
                    });
                }
            }

            // simulate a trip to the server
            setTimeout(() => {
                doneCallback(actions);
            }, 200);
    }


    // Delegate processing of treegrid actions
    handleRowAction(event) {

        const actionName = event.detail.action.name;
        const row = event.detail.row;

        console.log('action: '+actionName);

        switch (actionName) {
            case 'recalculate':
                this.submitForRecalc(row);
                break;
            case 'edit':
                this.editRule(row);
                break;
            case 'activate':
            case 'deactivate':
                this.activateDeactivate(row, actionName);
                break;
        }
    }


    // Action method to trigger FormulaShareBatch for the specified object
    submitForRecalc(row) {

        console.log('last calc: ' + row['batchIsProcessing']);
        console.log('key: ' + row['key']);

        if(row['batchIsProcessing']) {
            return this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Calculation currently in progress',
                    message: 'Cannot re-submit until current calculation completes',
                    variant: 'error'
                })
            );
        }

        const rowApiName = row['objectApiName'];
        const rowObjectLabel = row['key'];
        recalculateSharing({ objectApiName : rowApiName })
            .then(() => {
                // Refresh table to reflect processing status
                refreshApex(this.provisionedValue);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Submitted ' + rowObjectLabel + ' for full sharing calculation',
                        variant: 'info'
                    })
                );
            })
            .catch(error => {
                console.log('Error submitting for recalculation');
                this.showError(error, 'Error submitting for recalculation')
            });
    }


    // Action method to update a rule to active/inactive
    activateDeactivate(row, actionName) {
        const rowDeveloperName = row['developerName'];
        activateDeactivate({ ruleName : rowDeveloperName, type : actionName })
            .then(() => {
                const actToastTitle = actionName === 'activate' ? 'Queued for activation' : 'Queued for deactivation';
                this.processingLoad = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: actToastTitle,
                        variant: 'info'
                    })
                );
            })
            .catch(error => {
                console.log('Error changing activation status');
                this.showError(error, 'Error changing activation status')
            });
    }


    // Called to trigger a toast message including a system error
    showError(error, toastTitle) {
        let errorMessage = 'Unknown error';
        if (Array.isArray(error.body)) {
            errorMessage = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            errorMessage = error.body.message;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: toastTitle,
                message: 'Message from Salesforce: ' + errorMessage,
                variant: 'error'
            })
        );
    }

    handleRuleUpdated() {
        refreshApex(this.provisionedValue);
    }

    @track openModal
    @track rowRuleId
    editRule(row) {
        console.log('row: ' + JSON.stringify(row));
        this.rowRuleId = row['ruleId'];
        this.openModal = true;
    }

    closeModal() {
        this.openModal = false;
    }

}