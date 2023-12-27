import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';
import getTreeGridData from '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData';
import recalculateSharing from '@salesforce/apex/FormulaShareRulesListViewController.recalculateSharing';
import activateDeactivate from '@salesforce/apex/FormulaShareMetadataControllerRules.activateDeactivate';
import getNamespacePrefix from '@salesforce/apex/FormulaShareLWCUtilities.getNamespacePrefix';
import versionSupportsRelatedRules from '@salesforce/apex/FormulaShareInjectionService.versionSupportsRelatedRules';
import processOnActionClick from '@salesforce/apex/FormulaShareInjectionService.processOnActionClick';

export default class TreeGrid extends NavigationMixin(LightningElement) {

    @track data = [];
    @track columns = [];

    setColumns(supportsRelated) {

        // Add shared object, shares wtih and shared to field
        this.columns = [
            {type: 'text'
                , fieldName: 'tableLabel'
                , label: 'Object and Rule'
                , cellAttributes: {class: {fieldName: 'sharedObjectClass'} }
            },
            {type: 'text'
                , fieldName: 'shareWith'
                , label: 'Shares With'
                , sortable: true
            },
            {type: 'url'
                , fieldName:'sharedToLink'
                , label:'Specified in Field'
                , typeAttributes: {label: {fieldName:'sharedToLinkLabel'}, target:'_blank', tooltip: 'Open field in setup menu'}
            }
        ];

        // Add controlling object column if related sharing supported
        if(supportsRelated) {
            this.columns.push(
                {type: 'text'
                    , fieldName: 'controllingObject'
                    , label: 'On Object'
                },
            );
        }

        // Add assessment status and no records shared
        this.columns.push(
            {type: 'text'
                , fieldName: 'lastCalcStatus'
                , label: 'Last Full Assessment'
                , cellAttributes: {iconName: {fieldName: 'iconName'}, iconAlternativeText: {fieldName: 'iconAlt'} }
            },
            {type: 'number'
                , fieldName: 'noSharesApplied'
                , label:'Records Shared'
            }
        );

        // Iterate all child rows to check for warnings
        var showWarnings = false;
        for(var rowNo in this.treeItems) {
            for(var ruleRowNo in this.treeItems[rowNo]._children) {
                var thisRow = this.treeItems[rowNo]._children[ruleRowNo];

                // If we have a warning, push column with relevant type for the warning
                if(thisRow.warningUrlLabel && thisRow.active) {

                    // If we have schedule warnings (included for all rowx)
                    // we'll need to push a column with a button to open modal
                    if(thisRow.warningUrlLabel === 'Schedule batch job') {
                        showWarnings = 'scheduleWarning';                            
                        this.scheduleWarningsUrl = thisRow.warningUrl;
                        break;
                    }

                    // Otherwise, we'll push a column which allows link to be set by row
                    else {
                        showWarnings = 'rowSpecificWarnings';
                        break;                        
                    }
                }
            }
        }

        // Add approriate warning column if any warnings found
        if(showWarnings === 'scheduleWarning') {
            this.columns.push(
                {   type: 'button'
                    , fieldName: 'warningUrl'
                    , label: 'Warnings'
                    , typeAttributes: {
                        name: 'scheduleWarning'
                        , title: {fieldName: 'warningTooltip'}
                        , label: {fieldName: 'warningUrlLabel'}
                        , variant: 'base'
                    }
                }
            );
        }
        else if(showWarnings === 'rowSpecificWarnings') {
            this.columns.push(
                {type: 'url'
                    , fieldName: 'warningUrl'
                    , label:'Warnings'
                    , typeAttributes: {
                        label: {fieldName:'warningUrlLabel'}
                        , target:'_blank'
                        , tooltip: {fieldName:'warningTooltip'}
                    }
                }
            );
        }

        // Add active column and row actions
        this.columns.push(
            {type: 'boolean'
                , fieldName: 'active'
                , label: 'Active'
            },
            {type: 'action'
                , typeAttributes: {rowActions: this.getRowActions} 
            }
        );
    }


    // Core method to load treegrid data from handler
    provisionedValue;
    firstLoad = true;
    @track treeItems;
    @track currentExpanded;
    @track processingLoad = true;

    @wire(getTreeGridData)
    wireTreeData(value) {
        const { data, error } = value;
        this.provisionedValue = value;

        if (data) {
            let tempjson = JSON.parse(JSON.stringify(data).split('items').join('_children'));
            this.treeItems = tempjson;

            versionSupportsRelatedRules()
                .then((supportsRelated) => {
                    this.setColumns(supportsRelated);
                    this.countRows(tempjson);
        
                    // Expand all rows when table first loaded, and subscribe to events
                    if(this.firstLoad) {
                        this.expandAllRows(tempjson);
                        this.manageRefreshEvents();     // Subscribe to event channel
                        this.firstLoad = false;
                    }
        
                    // Expand all rows if a rule was just set up or modified
                    if(this.createOrUpdate) {
                        this.expandAllRows(tempjson);
                        this.createOrUpdate = false;
                    }

                    this.processingLoad = false;
                })
                .catch(error => {
                    this.showError(error, 'Error checking for related object support');
                });
        }

        else if(error) {
            //console.log('Error fetching data from Salesforce');
            this.showError(error, 'Error fetching data from Salesforce');
        }
    }


    rulesNotSetUp = true;
    countRows(tempjson) {
        var noRules = 0;
        for(var i = 0; i < tempjson.length; i++) {

            var children = tempjson[i]._children;
            for(var j = 0; j < children.length; j++) {
                noRules++;
            }
        }

        if(noRules === 0) {
            this.rulesNotSetUp = true;
        }
        else {
            this.rulesNotSetUp = false;
        }

        const evt = new CustomEvent('ruleload', {
            detail: noRules
        });
        //console.log('noRules '+noRules);
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
    createOrUpdate = false;
    manageRefreshEvents() {

        // Get namespace prefix
        getNamespacePrefix()
            .then((prefix) => {
                //console.log('Got namespace: '+prefix);

                // Subscribe to list update events (raised by batch job and on rule activate/deactivate)
                const listUpdateCallback = (response) => {
                    //console.log('Received Refresh Event');
                    this.refreshView();
                };
                subscribe('/event/'+prefix+'FormulaShare_List_Update__e', -1, listUpdateCallback).then(response => {
                    //console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
                });

                // Scubscribe to dml events (raised by on rule create/edit)
                const dmlUpdateCallback = (response) => {
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

                    // Refresh list if successful event recieved
                    if(payload[successPropName]) {
                        //console.log('Received FormulaShare_Rule_DML__e');
                        this.createOrUpdate = true;
                        this.refreshView();
                    }
                };
                subscribe('/event/'+prefix+'FormulaShare_Rule_DML__e', -1, dmlUpdateCallback).then(response => {
                    //console.log('List component subscribed to : ', JSON.stringify(response.channel));
                });

            })
            .catch(error => {
                //console.log('Error getting namespace prefix');
                this.showError(error, 'Error getting namespace prefix');
            });
    }


    // Set available drop-down actions for each grid row
    getRowActions(row, doneCallback) {
        // Check the retention days before populating (this is used in an action label)
        //console.log('loading actions');

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
                'label': 'View / Edit',
                'name': 'edit'
            });

            if (isActive) {
                actions.push({
                    'label': 'Deactivate',
                    'name': 'deactivate'
                });
            }
            else {
                actions.push({
                    'label': 'Activate',
                    'name': 'activate',
                    'disabled': row['enableActivate']
                });
            }

            // Set label according to whether logs will be restricted to the last batch
            var viewLogsLabel = 'View Records Shared';
            if(row['lastBatchId']) {
                viewLogsLabel += ' Since Last Batch';
            }
            actions.push({
                'label': viewLogsLabel,
                'name': 'viewlogs'
            });
        }

        // simulate a trip to the server
        setTimeout(() => {
            doneCallback(actions);
        }, 200);

        //console.log('loaded actions');
    }

    baseURL;
    renderedCallback() {
        this.baseURL = window.location.origin;
    }

    // Delegate processing of treegrid actions
    handleRowAction(event) {
        processOnActionClick({ baseUrl : this.baseURL.toString() })
            .then(result => {
                // console.log('Processed apex on action click: ',result);
            })
            .catch(error => {
                // console.log('Error processing apex on action click: ',error);
            });

        // If click is on a schedule warning button, toggle the modal
        if(event.detail.action.name === 'scheduleWarning') {
            this.doOpenScheduleModal();
        }

        const actionName = event.detail.action.name;
        const row = event.detail.row;

        //console.log('action: '+actionName);

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
            case 'viewlogs':
                this.openLogsReport(row);
                break;
        }
    }

    scheduleWarningsUrl;
    openScheduleModal = false;
    doOpenScheduleModal() {
        //console.log('opening schedule modal');
        this.openScheduleModal = true;
    }
    closeScheduleModal() {
        this.openScheduleModal = false;
    }

    // Action method to trigger FormulaShareBatch for the specified object
    submitForRecalc(row) {

        // Check whether recalculation in progress, show error and return if so
        if(row['batchIsProcessing']) {
            return this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Calculation currently in progress',
                    message: 'Cannot re-submit until current calculation completes',
                    variant: 'error'
                })
            );
        }

        // Update tree items to show that recalculation has been submitted
        var newTreeItems = JSON.parse(JSON.stringify(this.treeItems));
        for(var rowNo in newTreeItems) {

            // If object matches the one clicked...
            if(newTreeItems[rowNo].key === row['key']) {

                // Set flag indicating processing started
                newTreeItems[rowNo].batchIsProcessing = true;

                // Update processing status to show this is submitted
                for(var ruleRowNo in newTreeItems[rowNo]._children) {
                    newTreeItems[rowNo]._children[ruleRowNo].lastCalcStatus = 'Processing...';
                    newTreeItems[rowNo]._children[ruleRowNo].iconName = 'standard:product_transfer';
                    newTreeItems[rowNo]._children[ruleRowNo].iconAlt = 'Currently Processing';
                }
            }
        }
        this.treeItems = newTreeItems;

        //console.log('last calc: ' + row['batchIsProcessing']);
        //console.log('key: ' + row['key']);

        // Submit object for processing
        const rowApiName = row['objectApiName'];
        recalculateSharing({ objectApiName : rowApiName })
            .catch(error => {
                //console.log('Error submitting for recalculation');
                this.showError(error, 'Error submitting for recalculation')
            });
    }

    // Refreshes provisioned list of rules
    refreshView() {
        refreshApex(this.provisionedValue);
        const evt = new CustomEvent('refreshview');
        this.dispatchEvent(evt);
    }

    // Action method to update a rule to active/inactive
    spinnerClasses;
    activateDeactivate(row, actionName) {
        const rowDeveloperName = row['developerName'];
        activateDeactivate({ ruleName : rowDeveloperName, type : actionName })
            .then(() => {
                this.processingLoad = true;
                this.spinnerClasses = 'processingMessage';

                // After submitting, wait 5 seconds and add class to display 
                /*setTimeout(() => {
                    this.spinnerClasses = 'processingMessage afterProcessingMessage';
                }, 5000);*/
            })
            .catch(error => {
                console.error('>>>error: ' +  JSON.stringify(error, null, '\t'));
                this.showError(error, 'Error changing activation status')
            });
    }


    openLogsReport(row) {
        if(!row['recordLogsReportId']) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Unable to load report',
                    message: 'System permissions "Run Reports" and "View Reports in Public Folders" are required to view summaries of sharing applied',
                    variant: 'error'
                })
            );
        }

        // Set filter parameter for report ("fv0" is the convention for the first filter)
        var params = {};
        params['fv0'] = encodeURI(row['developerName']);

        // Set parameters for last batch and batch finish time if batch has run
        if(row['lastBatchId']) {
            params['fv1'] = encodeURI(row['lastBatchId']);
            params['fv2'] = encodeURI(row['batchFinishEpoch']);
        }

        // Open report in a new tab
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row['recordLogsReportId'],
                objectApiName: 'Report',
                actionName: 'view',
            },
            state: params   //  Filter set via query string parameter
        }).then(url => {
             window.open(url);
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

    @track openModal
    @track rowRuleId
    editRule(row) {
        this.rowRuleId = row['ruleId'];
        this.openModal = true;
    }

    closeModal() {
        this.openModal = false;
    }

}