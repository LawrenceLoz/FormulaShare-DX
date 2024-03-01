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
        console.log('looking for object');
        const { data, error } = value;
        if(data) {
            this.fieldSample = data;
        }
        else if(error) {
            this.fieldSample = error.body.message;   // Show warning message inside box - consider using a warning popover box in future
            //console.log(JSON.stringify(error));
        }
        this.loadingSample = false;
    }

}