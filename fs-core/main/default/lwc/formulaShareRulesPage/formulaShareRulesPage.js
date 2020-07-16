import { LightningElement, track, api } from 'lwc';

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

    @track noRules;
    @track pluralise = 's';
    handleRulesLoad(event) {
        this.noRules = event.detail;
        if(this.noRules === 1) this.pluralise = '';
    }
}