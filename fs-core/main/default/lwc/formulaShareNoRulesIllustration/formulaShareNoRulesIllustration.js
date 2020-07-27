import { LightningElement } from 'lwc';

export default class FormulaShareNoRulesIllustration extends LightningElement {

    handleNewRule() {
        const evt = new CustomEvent('newrule');
        console.log('new rule clicked');
        this.dispatchEvent(evt);
    }

}