import { LightningElement, api } from 'lwc';
import warningCloud from '@salesforce/resourceUrl/WarningCloud';

export default class FormulaShareScheduleJobDescription extends LightningElement {
    warningCloud = warningCloud;
    @api setupUrl;

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}