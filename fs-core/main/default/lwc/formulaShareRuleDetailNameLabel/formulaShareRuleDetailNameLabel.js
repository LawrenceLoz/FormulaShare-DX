import { LightningElement, api } from 'lwc';

export default class FormulaShareRuleDetailNameLabel extends LightningElement {
    @api ruleLabel;
    @api ruleName;
    @api ruleDescription;
    @api ruleActive;
    @api isEdit;

    // If name is blank, replace with label with special characters replaced with underscores
    autoPopulateName() {
        console.log('autopop username');
        if(!this.ruleName) {
            console.log(this.ruleLabel.replace(/[^a-zA-Z0-9]/g,'_').replace(/_{2,}/g,'_'));
            this.ruleName = this.ruleLabel.replace(/[^a-zA-Z0-9]/g,'_').replace(/_{2,}/g,'_');
            this.dispatchNameChange();
        }
    }

    handleLabelChange(event) {
        this.ruleLabel = event.detail.value;
        const evt = new CustomEvent('labelchange', {
            detail: this.ruleLabel
        });
        this.dispatchEvent(evt);
    }

    handleNameChange(event) {
        this.ruleName = event.detail.value;
        this.dispatchNameChange();
    }

    dispatchNameChange() {
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