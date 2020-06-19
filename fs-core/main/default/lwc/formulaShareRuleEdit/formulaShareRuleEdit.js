import { LightningElement, api } from 'lwc';

export default class FormulaShareRuleEdit extends LightningElement {
    @api ruleId;
    ruleDetails;

    updateRule(event) {
        this.ruleDetails = event.detail;
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    saveMethod() {
        console.log('this.ruleDetails '+  JSON.stringify(this.ruleDetails));
    }
}