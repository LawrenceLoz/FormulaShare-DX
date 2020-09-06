import { LightningElement } from 'lwc';
import aboutCloud from '@salesforce/resourceUrl/AboutCloud';

export default class FormulaShareAbout extends LightningElement {
    aboutCloudLogo = aboutCloud;

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}