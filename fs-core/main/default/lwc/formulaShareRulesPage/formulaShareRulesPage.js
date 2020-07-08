import { LightningElement, track } from 'lwc';

export default class FormulaShareRulesPage extends LightningElement {
    openNewRuleModal = false;

    handleNewRule() {
        this.openNewRuleModal = true;
    }

    closeNewRuleModal() {
        this.openNewRuleModal = false;
    }

    @track refreshList = false;
    handleRuleCreated() {
        this.refreshList = true;
    }
}