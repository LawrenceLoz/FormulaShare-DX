import { LightningElement, track, api, wire } from 'lwc';
import getShareableObjects from '@salesforce/apex/FormulaShareRuleDetailController.getShareableObjects';

export default class FormulaShareRuleDetailSharedObject extends LightningElement {

    @api
    get sharedObjectApiName() {
        return this._sharedObjectApiName;
    }
    set sharedObjectApiName(value) {
        this._sharedObjectApiName = value;

        // If wire service has populated api names map (true after first time 
        // a rule is opened) then set shared object and fire event
        this.setSharedObject();
    }
    @track _sharedObjectApiName;
    @track sharedObject;

    // Set details of the object selected to be shared and fire event
    // Method should only progress if the shared object API name is set
    // and the map of api names and details map is populated
    setSharedObject() {
        if(this._sharedObjectApiName && this.apiNameToObjectDetailsMap.size > 0) {
            this.sharedObject = this.apiNameToObjectDetailsMap.get(this.sharedObjectApiName);
            this.fireSharedObjectEvent('setsharedobjectdetail');
        }
    }

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

                    // Include label and api name (object api name used as key)
                    const option = {
                        label: obj.objectLabel + ' (' + obj.objectApiName + ')',
                        value: obj.objectApiName
                    };
                    this.shareableObjectOptions.push(option);
                });

                // Set shared object and fire event
                this.setSharedObject();
            }

            else if(error) {
                console.log('error '+ JSON.stringify(error));
            }
        }

    // On change, set shared object details and fire event
    handleSharedObjectChange(event) {
        this._sharedObjectApiName = event.detail.value;
        this.sharedObject = this.apiNameToObjectDetailsMap.get(this._sharedObjectApiName);
        this.fireSharedObjectEvent('sharedobjectchange');
    }

    // Notify parent component of shared object details when initally set or changed
    fireSharedObjectEvent(eventName) {
        const selection = new CustomEvent(eventName, {
            detail: this.sharedObject
        });
        this.dispatchEvent(selection);
    }
}