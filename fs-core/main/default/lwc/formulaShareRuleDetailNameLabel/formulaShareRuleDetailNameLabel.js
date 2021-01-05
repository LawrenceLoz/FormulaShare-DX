import { LightningElement, api } from 'lwc';

export default class FormulaShareRuleDetailNameLabel extends LightningElement {
    @api ruleLabel;
    @api ruleName;
    @api ruleDescription;
    @api ruleActive;
    @api isEdit;

    // If name is blank, replace with label with special characters replaced with underscores
    autoPopulateName() {

        if(!this.ruleName && this.ruleLabel) {
            //console.log(this.ruleLabel.replace(/[^a-zA-Z0-9]/g,'_').replace(/_{2,}/g,'_'));
            this.ruleName = this.ruleLabel.replace(/[^a-zA-Z0-9]/g,'_').replace(/_{2,}/g,'_');

            // Remove leading underscore if needed
            //console.log('first char ' +this.ruleName.charAt(0));
            if(this.ruleName.charAt(0) === '_') {
                this.ruleName = this.ruleName.substring(1);
            }

            // Remove final underscore if needed
            //console.log('last char ' +this.ruleName.charAt(this.ruleName.length -1));
            if(this.ruleName.charAt(this.ruleName.length -1) === '_') {
                this.ruleName = this.ruleName.substring(0, this.ruleName.length -1);
            }

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

    
    @api
    checkValidity() {
        //console.log('checking name valid ');
        const arr = [...this.template.querySelectorAll('lightning-input')];
        arr.concat([...this.template.querySelectorAll('lightning-textarea')]);
        //console.log('arr '+JSON.stringify(arr));
        const allValid = arr
            .reduce((validSoFar, inputCmp) => {
                //console.log('inputCmp '+JSON.stringify(inputCmp));
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid;
    }

}