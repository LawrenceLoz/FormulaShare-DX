import { LightningElement, track, api } from 'lwc';

export default class FormulaShareRulesPage extends LightningElement {
    openNewRuleModal = false;

    handleNewRule() {
        this.openNewRuleModal = true;
    }

    closeNewRuleModal() {
        this.openNewRuleModal = false;
    }

    @track noRules;
    @track pluralise = 's';
    @track rulesNotSetUp = false;
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
        console.log('this.rulesNotSetUp '+ this.rulesNotSetUp);
    }
}