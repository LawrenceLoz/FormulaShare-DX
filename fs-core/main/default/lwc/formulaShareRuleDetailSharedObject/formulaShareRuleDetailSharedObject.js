import { LightningElement, track, api, wire } from 'lwc';
import infoCloud from '@salesforce/resourceUrl/InfoCloud';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getShareableObjects from '@salesforce/apex/FormulaShareRuleDetailController.getShareableObjects';
import getLightningDomain from '@salesforce/apex/FormulaShareLWCUtilities.getLightningDomain';
import isContactSharingControlledByAccount from '@salesforce/apex/FormulaShareLWCUtilities.isContactSharingControlledByAccount';

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
            if(this.sharedObject) {
                this.fireNotifyObjectSharingEvent('setsharedobjectdetail', this.sharedObject);
            }
            else {
                this.objectNotSharedError(this._sharedObjectApiName);
            }
        }
    }

    objectNotSharedError(objectName) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Object cannot be shared'
                , message: 'It looks like the organisation-wide default sharing for ' + objectName
                    + ' no longer allow sharing. Check Setup -> Sharing Settings to review this.'
                , variant: 'error'
                , mode: 'sticky'
            })
        );
    }


    @track apiNameToObjectDetailsMap = new Map();
    @track shareableObjectOptions;
    contactAccess;
    caseAccess;
    opportunityAccess;
    @wire(getShareableObjects)
        shareableObjects({ error, data }) {
            if(data) {

                // Check whether contact controlled by parent
                isContactSharingControlledByAccount()
                .then((contactControlledByAccount) => {

                    // Set contact related sharing if controlled by parent
                    //console.log('controlled by account: '+contactControlledByAccount);
                    if(contactControlledByAccount) {
                        this.contactAccess = 'ControlledByParent';
                    }

                    // Build list of options to populate in shared object dropdown
                    this.shareableObjectOptions = [];
                    //console.log('geting shared objects');
                    data.forEach((obj) => {
                        this.apiNameToObjectDetailsMap.set(obj.objectApiName, obj);

                        // Include label and api name (object api name used as key)
                        const option = {
                            label: obj.objectLabel + ' (' + obj.objectApiName + ')',
                            value: obj.objectApiName
                        };

                        // Capture internal sharing model of contact, opp and case (for account sharing), and add to shareable options list
                        switch (obj.objectApiName) {
                            case 'Contact':
                                // Only include in shareable list if not controlled by account
                                if(!contactControlledByAccount) {
                                    this.contactAccess = obj.internalSharingModel;
                                    this.shareableObjectOptions.push(option);
                                }
                                break;
                            case 'Case':
                                this.caseAccess = obj.internalSharingModel;
                                this.shareableObjectOptions.push(option);
                                break;
                            case 'Opportunity':
                                this.opportunityAccess = obj.internalSharingModel;
                                this.shareableObjectOptions.push(option);
                                break;
                            default:
                                this.shareableObjectOptions.push(option);
                        }

                    });

                    // For any account related objects not considered so far, access level must be Read/Write
                    if(!this.contactAccess) {
                        this.contactAccess = 'ReadWrite';
                    }
                    if(!this.caseAccess) {
                        this.caseAccess = 'ReadWrite';
                    }
                    if(!this.opportunityAccess) {
                        this.opportunityAccess = 'ReadWrite';
                    }
                    this.fireAccountRelatedOwdEvent();

                    // Set shared object and fire event
                    this.setSharedObject();
                });
            }

            else if(error) {
                //console.log('error '+ JSON.stringify(error));
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
        //console.log('selection: '+JSON.stringify(selection));
    }

}