import { LightningElement } from 'lwc';

export default class FormulaShareNoRulesIllustration extends LightningElement {

    handleNewRule() {
        const evt = new CustomEvent('newrule');
        this.dispatchEvent(evt);
    }
}