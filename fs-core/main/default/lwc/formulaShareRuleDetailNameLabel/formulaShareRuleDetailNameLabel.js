import { LightningElement, api } from 'lwc';

export default class FormulaShareRuleDetailNameLabel extends LightningElement {
    @api ruleLabel;
    @api ruleName;
    @api ruleDescription;
    @api ruleActive;

    handleLabelChange(event) {
        this.ruleLabel = event.detail.value;
        const evt = new CustomEvent('labelchange', {
            detail: this.ruleLabel
        });
        this.dispatchEvent(evt);
    }

    handleNameChange(event) {
        this.ruleName = event.detail.value;
        const evt = new CustomEvent('namechange', {
            detail: this.ruleName
        });
        this.dispatchEvent(evt);
    }

    handleDescriptionChange(event) {
        this.ruleDescription = event.detail.value;
        const evt = new CustomEvent('descriptionchange', {
            detail: this.ruleDescription
        });
        this.dispatchEvent(evt);
    }

    handleActiveChange(event) {
        this.ruleActive = event.detail.value;
        const evt = new CustomEvent('activechange', {
            detail: this.ruleDescription
        });
        this.dispatchEvent(evt);        
    }

}