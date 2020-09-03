import { LightningElement, track, api, wire } from 'lwc';
import infoCloud from '@salesforce/resourceUrl/InfoCloud';
import getShareableObjects from '@salesforce/apex/FormulaShareRuleDetailController.getShareableObjects';
import getLightningDomain from '@salesforce/apex/FormulaShareUtilities.getLightningDomain';

export default class FormulaShareRuleDetailSharedObject extends LightningElement {

    infoCloudLogo = infoCloud;

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

    @track owdHelpText = false;
    toggleOwdHelpText() {
        this.owdHelpText ? this.owdHelpText = false : this.owdHelpText = true;
    }

    // Build sharing settings setup menu link
    setupSharingSettings;
    connectedCallback() {
        getLightningDomain()
            .then((domainName) => {
                this.setupSharingSettings = domainName + '/lightning/setup/SecuritySharing/home';
            });
        this.fireAccountRelatedOwdEvent();
    }


    // Set details of the object selected to be shared and fire event
    // Method should only progress if the shared object API name is set
    // and the map of api names and details map is populated
    setSharedObject() {
        if(this._sharedObjectApiName && this.apiNameToObjectDetailsMap.size > 0) {
            this.sharedObject = this.apiNameToObjectDetailsMap.get(this.sharedObjectApiName);
            this.fireNotifyObjectSharingEvent('setsharedobjectdetail', this.sharedObject);
        }
    }

    @track apiNameToObjectDetailsMap = new Map();
    @track shareableObjectOptions;
    contactAccess;
    caseAccess;
    opportunityAccess;
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

                    // Fire event to capture internal sharing model of contact, opp and case (for account sharing)
                    this.setAccountRelatedOwdSharing(obj);
                });
                this.fireAccountRelatedOwdEvent();

                // Set shared object and fire event
                this.setSharedObject();
            }

            else if(error) {
                console.log('error '+ JSON.stringify(error));
            }
        }

    // Notify parent of sharing details for contact, case and opp
    setAccountRelatedOwdSharing(obj) {
        switch (obj.objectApiName) {
            case 'Contact' :
//                this.fireNotifyObjectSharingEvent('contactsharingdetail', obj);
                this.contactAccess = obj;
                break;
            case 'Case' :
//                this.fireNotifyObjectSharingEvent('casesharingdetail', obj);
                this.caseAccess = obj;
                break;
            case 'Opportunity' :
//                this.fireNotifyObjectSharingEvent('opportunitysharingdetail', obj);
                this.opportunityAccess = obj;
                break;
        }
    }

    fireAccountRelatedOwdEvent() {

        if(this.contactAccess && this.caseAccess && this.opportunityAccess) {
            var accountRelatedSharing = {
                "contactAccess" : this.contactAccess,
                "caseAccess" : this.caseAccess,
                "opportunityAccess" : this.opportunityAccess
            }
    
            const evt = new CustomEvent('accountrelatedowd', { detail: accountRelatedSharing });
            this.dispatchEvent(evt);
        }
    }

    // On open, increase height of modal if no previous selection (ensures there's space to see options)
    sharedObjectOpen = false;
    handleSharedObjectOpen(event) {
        if(!this.sharedObject) this.sharedObjectOpen = true;
    }

    handleClickedOut(event) {
        this.sharedObjectOpen = false;
    }

    // On change, set shared object details and fire event
    handleSharedObjectChange(event) {
        this.sharedObjectOpen = false;
        this._sharedObjectApiName = event.detail.value;
        this.sharedObject = this.apiNameToObjectDetailsMap.get(this._sharedObjectApiName);
        this.fireNotifyObjectSharingEvent('sharedobjectchange', this.sharedObject);
    }

    // Notify parent component of shared object details when initally set or changed
    fireNotifyObjectSharingEvent(eventName, obj) {
        const selection = new CustomEvent(eventName, {
            detail: obj
        });
        this.dispatchEvent(selection);
    }

}