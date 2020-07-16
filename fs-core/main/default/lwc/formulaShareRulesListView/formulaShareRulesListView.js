import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import getTreeGridData from '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData';
import recalculateSharing from '@salesforce/apex/FormulaShareRulesListViewController.recalculateSharing';
import activateDeactivate from '@salesforce/apex/FormulaShareRulesListViewController.activateDeactivate';

export default class TreeGrid extends LightningElement {

    @track data = [];
    @track columns = [];

    w0;
    w1;
    w15;
    w2;
    w3;
    w4;
    w5;
    setWidths() {
        if(this.template.querySelector('div')) {
            var el = this.template.querySelector('div');
            var windowWidth = el.clientWidth;
            this.w1 = windowWidth / 13;
            this.w15 = this.w1*1.5
            this.w2 = this.w1*1.8;
            this.w3 = this.w1*2.5;
            this.w4 = this.w1*3;
            this.w5 = this.w1*3.5;
            this.w0 = this.w1*0.7;
            console.log('width '+ windowWidth+ ' w1: '+this.w1 + ' w2 '+this.w2);
            refreshApex(this.provisionedValue);
        }
    }

    setColumns() {
        this.columns = [
            {type: 'text'
                , fieldName: 'tableLabel'
                , label: 'Object and Rule'
                , cellAttributes: {class: {fieldName: 'sharedObjectClass'} }
//                , typeAttributes: {label: {fieldName:'tableLabel'}, target: '_blank', tooltip: 'Click to open'}
                , initialWidth: this.w5
            },
            {type: 'text'
                , fieldName: 'shareWith'
                , label: 'Shares With'
                , sortable: true
                , initialWidth: this.w15
            },
            {type: 'url'
                , fieldName:'sharedToLink'
                , label:'Specified in Field'
                , typeAttributes: {label: {fieldName:'sharedToLinkLabel'}, target:'_blank', tooltip: 'Open field in setup menu'}
                , initialWidth: this.w3
            },
            {type: 'text'
                , fieldName: 'controllingObject'
                , label: 'On Object'
                , initialWidth: this.w15
            },
            {type: 'text'
                , fieldName: 'accessLevel'
                , label: 'Access'
                , initialWidth: this.w0
            },
        //        {type: 'text', fieldName: 'sharingReason', label: 'Sharing Reason'
        //        , initialWidth: 200
        //    },
            {type: 'text'
                , fieldName: 'lastCalcStatus'
                , label: 'Last Full Assessment'
                , cellAttributes: {iconName: {fieldName: 'iconName'}, iconAlternativeText: {fieldName: 'iconAlt'} }
                , initialWidth: this.w2
            },
            {type: 'boolean'
                , fieldName: 'active'
                , label: 'Active'
                , initialWidth: this.w0
            },
            {type: 'action'
                , typeAttributes: {rowActions: this.getRowActions} 
            }
        ];

    }

    // Core method to load treegrid data from handler
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
            if(!this.w1) this.setWidths();   // Set all width variables if not set already
            let tempjson = JSON.parse(JSON.stringify(data).split('items').join('_children'));
            this.treeItems = tempjson;
            console.log('this.treeItems: '+JSON.stringify(this.treeItems));
            console.log('loading data');

            this.setColumns();
            this.countRows(tempjson);

            if(this.firstLoad) {
                this.expandAllRows(tempjson);
                this.manageRefreshEvents();     // Subscribe to event channel
                this.firstLoad = false;
            }

            this.processingLoad = false;
        }

        else if(error) {
            console.log('Error fetching data from Salesforce');
            this.showError(error, 'Error fetching data from Salesforce');
        }
    }


    countRows(tempjson) {
        var noRules = 0;
        for(var i = 0; i < tempjson.length; i++) {

            var children = tempjson[i]._children;
            for(var j = 0; j < children.length; j++) {
                noRules++;
            }
        }

        const evt = new CustomEvent('ruleload', {
            detail: noRules
        });
        this.dispatchEvent(evt);
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


    // Subcribes to list platform event, and refresh treegrid each time event is received
    @track channelName = '/event/FormulaShare_List_Update__e';
    manageRefreshEvents() {
        const messageCallback = (response) => {
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


        // Set icons for all rules for this object to show it's recalculating (commented out - treeitem updates don't reflect in tree-grid)
//        for(var rowNo in this.treeItems) {
//            console.log('PR '+JSON.stringify(rowNo));
//            console.log('parentRow.objectApiName === rowApiName '+this.treeItems[rowNo].objectApiName+'row api nmae '+rowApiName);
//            if(this.treeItems[rowNo].objectApiName === rowApiName) {
//                for(var ruleRowNo in this.treeItems[rowNo]._children) {
//                    console.log('Updating row');
//                    this.treeItems[rowNo]._children[ruleRowNo].iconName = 'standard:today';
//                    this.treeItems[rowNo]._children[ruleRowNo].iconAlt = 'Now Processing';
//                    this.treeItems[rowNo]._children[ruleRowNo].lastCalcStatus = 'Now...';
//                }
//            }
//        }
//        console.log('Updated this.treeItems: '+JSON.stringify(this.treeItems));

        recalculateSharing({ objectApiName : rowApiName })
            .then(() => {
                // Refresh table to reflect processing status
                refreshApex(this.provisionedValue);
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
                this.processingLoad = true;
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