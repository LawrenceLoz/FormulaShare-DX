import { LightningElement, wire } from 'lwc';
import rulesPageIcon from '@salesforce/resourceUrl/RulesPageIcon';
import isFullOrTargetedBatchScheduled from '@salesforce/apex/FormulaShareAsyncApexJobSelector.isFullOrTargetedBatchScheduled';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FormulaShareRulesPage extends LightningElement {
    rulesPageIcon = rulesPageIcon;
    initialBatchScheduled;

    @wire(isFullOrTargetedBatchScheduled)
    wiredBatchStatus({ error, data }) {
        if (this.initialBatchScheduled === undefined) {
            this.initialBatchScheduled = data;
        }
        if (error) {
            console.error('Error checking batch status:', error);
        }
    }

    get showBatchIllustration() {
        return this.initialBatchScheduled === false;
    }

    openNewRuleModal = false;
    handleNewRule() {
        this.openNewRuleModal = true;
    }
    closeNewRuleModal() {
        this.openNewRuleModal = false;
    }

    openAboutModal = false;
    handleAbout() {
        this.openAboutModal = true;
    }
    closeAboutModal() {
        this.openAboutModal = false;
    }

    noRules;
    pluralise = 's';
    rulesNotSetUp = false;
    processingRulesLoad = true;
    handleRulesLoad(event) {
        this.noRules = event.detail;
        if(this.noRules === 0) {
            this.rulesNotSetUp = true;
        }
        else if(this.noRules === 1) {
            this.pluralise = '';
            this.rulesNotSetUp = false;
        }
        else {
            this.pluralise = 's';
            this.rulesNotSetUp = false;
        }
        //console.log('this.rulesNotSetUp '+ this.rulesNotSetUp);
        this.processingRulesLoad = false;
    }

    get oneRuleAndNoBatch() {
        return this.noRules === 1 && !this.initialBatchScheduled;
    }

    get showBatchAndFlowButtons() {
        return !this.rulesNotSetUp && !this.oneRuleAndNoBatch;
    }

    // Call refreshView method on subheader
    async handleRefreshView() {

        try {
            this.template.querySelector('c-formula-share-rules-page-subheader').refreshView();
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error refreshing data',
                    message: error.message,
                    variant: 'error'
                })
            );
        }        
    }

    disableNewRule = false;
    handleEnableDisableNewRule(event) {
        this.disableNewRule = event.detail;
    }

    showScheduleBatchModal = false;

    handleOpenScheduleBatch() {
        this.showScheduleBatchModal = true;
    }

    handleCloseScheduleBatch() {
        this.showScheduleBatchModal = false;
    }

    showRealTimeInfo = false;

    handleOpenRealTimeInfo() {
        this.showRealTimeInfo = true;
    }

    handleCloseRealTimeInfo() {
        this.showRealTimeInfo = false;
    }
}