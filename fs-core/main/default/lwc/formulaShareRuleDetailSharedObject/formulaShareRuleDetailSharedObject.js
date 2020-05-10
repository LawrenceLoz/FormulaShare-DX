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

                data.forEach((obj) => {
        
                    // Populate map to store API names to entityIds for shareable objects
/*                    const objectDetails = {
                        objectApiName: obj.objectApiName,
                        entityId: obj.objectId,
                        label: obj.objectLabel,
                        pluralLabel: obj.pluralLabel,
                        detailUrl: obj.detailUrl
                    };  */
//                    this.apiNameToObjectDetailsMap = new Map();
                    this.apiNameToObjectDetailsMap.set(obj.objectApiName, obj);
                    console.log('setting: '+obj.objectApiName);
        
                    // Build options for dropdown, and populate in list to be returned
                    const option = {
                        label: obj.objectLabel + ' (' + obj.objectApiName + ')',
                        value: obj.objectApiName
                    };
                    this.shareableObjectOptions.push(option);
                });

                // Fire event so parent receives object details
                console.log('thisApiName',this.sharedObjectApiName);
                console.log('full map ',this.apiNameToObjectDetailsMap);
                console.log('Got from map: ',this.apiNameToObjectDetailsMap.get(this.sharedObjectApiName));
                this.sharedObject = this.apiNameToObjectDetailsMap.get(this.sharedObjectApiName);
                this.fireSharedObjectEvent('setsharedobjectdetail');
            }

            else if(error) {
                console.log('error '+ JSON.stringify(error));
            }
        }

    handleSharedObjectChange(event) {
        this.sharedObjectApiName = event.detail.value;

        console.log('thisApiName',this.sharedObjectApiName);
        console.log('full map ',this.apiNameToObjectDetailsMap);
        console.log('Got from map: ',this.apiNameToObjectDetailsMap.get(this.sharedObjectApiName));

        this.sharedObject = this.apiNameToObjectDetailsMap.get(this.sharedObjectApiName);
        this.fireSharedObjectEvent('sharedobjectchange');
    }

    fireSharedObjectEvent(eventName) {
        console.log('setEvent ',this.sharedObject);
        const selection = new CustomEvent(eventName, {
            detail: this.sharedObject
        });
        this.dispatchEvent(selection);
    }
}