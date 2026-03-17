import { LightningElement, api, track, wire } from 'lwc';
import getSampleData from '@salesforce/apex/FormulaShareRuleDetailController.getSampleData';

export default class FormulaShareBrowseFieldContents extends LightningElement {
    @api
    get objectApiName() {
        return this._objectApiName;
    }
    set objectApiName(value) {
        this._objectApiName = value;
    }
    _objectApiName;

    @api
    get fieldApiName() {
        return this._fieldApiName;
    }
    set fieldApiName(value) {
        this._fieldApiName = value;
    }
    _fieldApiName;

    @api fieldFormula;

    @track fieldSample;
    loadingSample = true;
    @wire(getSampleData, {objectApiName : '$objectApiName', fieldApiName : '$fieldApiName'})
    wiredSampleData(value) {
        const { data, error } = value;
        // Ignore provisional state (data and error both undefined) - keep spinner showing
        if(data === undefined && error === undefined) {
            return;
        }
        if(data) {
            this.fieldSample = data;
        }
        else if(error) {
            // Safely access error message, guarding against non-standard error shapes
            this.fieldSample = (error.body && error.body.message)
                ? error.body.message
                : 'Unable to retrieve sample data';
        }
        this.loadingSample = false;
    }

}