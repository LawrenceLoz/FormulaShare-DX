import { LightningElement } from 'lwc';

export default class FormulaShareAbout extends LightningElement {
    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}