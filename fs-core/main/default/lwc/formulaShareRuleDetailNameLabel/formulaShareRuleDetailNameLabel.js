import { LightningElement, api } from 'lwc';

export default class FormulaShareRuleDetailNameLabel extends LightningElement {
    @api ruleLabel;
    @api ruleName;
    @api ruleDescription;
    @api ruleActive;

    handleLabelChange() {
        this.ruleLabel = event.detail.value;
        const evt = new CustomEvent('labelchange', {
            detail: this.ruleLabel
        });
        this.dispatchEvent(evt);
    }

    handleNameChange() {
        this.ruleName = event.detail.value;
        const evt = new CustomEvent('namechange', {
            detail: this.ruleName
        });
        this.dispatchEvent(evt);
    }

    handleDescriptionChange() {
        this.ruleDescription = event.detail.value;
        const evt = new CustomEvent('descriptionchange', {
            detail: this.ruleDescription
        });
        this.dispatchEvent(evt);
    }

    handleActiveChange() {
        this.ruleActive = event.detail.value;
        const evt = new CustomEvent('activechange', {
            detail: this.ruleDescription
        });
        this.dispatchEvent(evt);        
    }

}