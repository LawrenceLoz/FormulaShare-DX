import { LightningElement, track, api, wire } from 'lwc';
import getShareableObjects from '@salesforce/apex/FormulaShareRuleDetailController.getShareableObjects';

export default class FormulaShareRuleDetailSharedObject extends LightningElement {

    @api sharedObjectApiName;
    @api sharedObject;
    @track apiNameToObjectDetailsMap = new Map();

    @track shareableObjectOptions;
    @wire(getShareableObjects)
        shareableObjects({ error, data }) {
            if(data) {
                this.shareableObjectOptions = [];
                console.log('geting shared objects');

                // Build list of options to populate in shared object dropdown
                data.forEach((obj) => {
                    this.apiNameToObjectDetailsMap.set(obj.objectApiName, obj);
                    console.log('setting: '+obj.objectApiName);
        
                    // Include label and api name (object api name used as key)
                    const option = {
                        label: obj.objectLabel + ' (' + obj.objectApiName + ')',
                        value: obj.objectApiName
                    };
                    this.shareableObjectOptions.push(option);
                });

                // Set details of the object selected to be shared and fire event
                this.sharedObject = this.apiNameToObjectDetailsMap.get(this.sharedObjectApiName);
                this.fireSharedObjectEvent('setsharedobjectdetail');
            }

            else if(error) {
                console.log('error '+ JSON.stringify(error));
            }
        }

    // On change, set shared object details and fire event
    handleSharedObjectChange(event) {
        this.sharedObjectApiName = event.detail.value;
        this.sharedObject = this.apiNameToObjectDetailsMap.get(this.sharedObjectApiName);
        this.fireSharedObjectEvent('sharedobjectchange');
    }

    // Notify parent component of shared object details when initally set or changed
    fireSharedObjectEvent(eventName) {
        console.log('setEvent ',this.sharedObject);
        const selection = new CustomEvent(eventName, {
            detail: this.sharedObject
        });
        this.dispatchEvent(selection);
    }
}