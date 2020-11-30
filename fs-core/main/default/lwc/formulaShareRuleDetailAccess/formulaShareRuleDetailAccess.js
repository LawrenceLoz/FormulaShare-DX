import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import infoCloud from '@salesforce/resourceUrl/InfoCloud';
import getClassicDomain from '@salesforce/apex/FormulaShareUtilities.getClassicDomain';
import getSharingReasons from '@salesforce/apex/FormulaShareUtilities.getSharingReasons';

export default class FormulaShareRuleDetailAccess extends LightningElement {

    infoCloudLogo = infoCloud;

    @api
    get internalSharingModel() {
        return this._internalSharingModel;
    }
    set internalSharingModel(value) {
        this._internalSharingModel = value;
        this.updateAccessLevelOptions();
    }
    _internalSharingModel;

    @api
    get externalSharingModel() {
        return this._externalSharingModel;
    }
    set externalSharingModel(value) {
        this._externalSharingModel = value;
        this.updateAccessLevelOptions();
    }
    _externalSharingModel;

    accessLevelLabel;
    showAccountRelatedAccess;
    @api
    get sharedObjectLabel() {}
    set sharedObjectLabel(value) {

        // Clear fields if shared object is updated
        if(this._sharedObjectLabel && this._sharedObjectLabel != value) {
            this.updateAccessLevel(null);
            this.updateSharingReason(null);
        }
        this._sharedObjectLabel = value;

        // Set access level options
        this.updateAccessLevelOptions();

        // Set label and visibility of depending on whether account or not
        // Also set field attributes for related objects
        if(this._sharedObjectLabel === 'Account') {
            this.accessLevelLabel = 'Account and Contract Access';
            this.assessAccountRelatedAccess();
        }
        else {
            this.accessLevelLabel = 'Access Level';
            this.showAccountRelatedAccess = false;
        }
    }
    _sharedObjectLabel;

    @api
    get sharedObjectId() {}
    set sharedObjectId(value) {
        this._sharedObjectId = value;
        this.buildSharingReasonsSetupLink();
    }
    _sharedObjectId;

    @api
    get accountRelatedOwd() {}
    set accountRelatedOwd(value) {
        this._accountRelatedOwd = value;
        //console.log('accountrelated OWD: ' +JSON.stringify(this._accountRelatedOwd));
        this.assessAccountRelatedAccess();
    }
    _accountRelatedOwd;

    assessAccountRelatedAccess() {

        // Proceed only if all required attributes are set and shared object is Account
        if(this._accountRelatedOwd
            && this._sharedObjectLabel === 'Account') {

            // Set options for case and opportunity
            this.updateAccessLevelOption('case', this._accountRelatedOwd.caseAccess);
            this.updateAccessLevelOption('opportunity', this._accountRelatedOwd.opportunityAccess);
            this.updateAccessLevelOption('contact', this._accountRelatedOwd.contactAccess);

            // Show fields to set access levels
            this.showAccountRelatedAccess = true;
        }
    }

    @api sharedObjectApiName;
    @api isCustom;
    @api accessLevel;
    @api contactAccess;
    @api caseAccess;
    @api opportunityAccess;
    @api sharingReason;

    @api
    checkValidity() {
        const allValid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        //console.log('Access valid: '+allValid);
        return allValid;
    }

    @track sharingReasonsHelpBox = false;
    toggleSharingReasonsHelpBox() {
        this.sharingReasonsHelpBox ? this.sharingReasonsHelpBox = false : this.sharingReasonsHelpBox = true;
    }

    // Get custom Salesforce classic domain on component load
    classicDomain;
    connectedCallback() {
        getClassicDomain()
        .then((domainName) => {
            //console.log('found dom '+domainName);
            this.classicDomain = domainName;
            this.buildSharingReasonsSetupLink();
        });
    }
    
    // Set link to object's sharing reasons. Proceeds only if both domain and object id are populated
    @track sharingReasonsSetupLink;
    buildSharingReasonsSetupLink() {
        if(this.classicDomain && this._sharedObjectId) {
            this.sharingReasonsSetupLink = this.classicDomain + '/' + this._sharedObjectId + '?setupid=CustomObjects#CustomRowCauses_target';
        }
    }

    // Build access level options of Read and/or Read/Write
    @track accessLevelOptions;
    @track accessLevelIsReadOnly;
    @track accessLevelHelpText;
    updateAccessLevelOptions() {
        
        if(this._internalSharingModel && this._externalSharingModel && this._sharedObjectLabel) {
            var options = [];

            // Set help text
            this.accessLevelHelpText = 'Organisation-wide default sharing for '+this._sharedObjectLabel+': '+this._internalSharingModel+' (intenal), ' +this._externalSharingModel+' (external)';
    
            // Include Read Only option if either internal or external OWD is private
            if(this._internalSharingModel === 'Private' || this._externalSharingModel === 'Private') {
                options.push( { label: 'Read Only', value: 'Read' } );
//                this.accessLevelHelpText = null;
                this.accessLevelIsReadOnly = false;
            }
    
            // Otherwise disable field, default to only option and add help text
            else {
                this.accessLevelIsReadOnly = true;
//                this.accessLevelHelpText = 'Access level must be more permissive than the organisation-wide default, which is set to Public Read Only for ' + this._sharedObjectLabel;
                this.updateAccessLevel('Edit');
            }

            // Always include Read/Write as an option
            options.push( { label: 'Read/Write', value: 'Edit' } );

            this.accessLevelOptions = options;
        }
    }

    handleAccessLevelChange(event) {
        this.updateAccessLevel(event.detail.value);
    }

    updateAccessLevel(value) {
        this.accessLevel = value;
        const evt = new CustomEvent('accesslevelchange', {
            detail: this.accessLevel
        });
        this.dispatchEvent(evt);
    }

    handleContactAccessChange(event) {
        this.updateRelatedAccess('contact', event.detail.value);
    }
    handleCaseAccessChange(event) {
        this.updateRelatedAccess('case', event.detail.value);
    }
    handleOpportunityAccessChange(event) {
        this.updateRelatedAccess('opportunity', event.detail.value);
    }

    updateRelatedAccess(type, value) {
        switch (type) {
            case 'contact':
                //console.log('contact access updated');
                this.contactAccess = value;
                break;
            case 'case':
                this.caseAccess = value;
                break;
            case 'opportunity':
                this.opportunityAccess = value;
        }
        const evt = new CustomEvent(type + 'accesschange', {
            detail: value
        });
        this.dispatchEvent(evt);        
    }

    @track contactAccessOptions;
    @track contactAccessIsReadOnly;
    @track contactAccessHelpText;
    @track caseAccessOptions;
    @track caseAccessIsReadOnly;
    @track caseAccessHelpText;
    @track opportunityAccessOptions;
    @track opportunityAccessIsReadOnly;
    @track opportunityAccessHelpText;
    updateAccessLevelOption(type, internalSharing) {
        var options = [];
        var isReadOnly = true;
        var helpText = 'Internal organisation-wide default sharing for '+type+': '+internalSharing;

        // Set options which include default and higher access only
        // To create account sharing, it's required to specify sharing for case and opp and also contact 
        // (unless controlled by parent). This sharing must be OWD for these objects or higher
        if(internalSharing === 'Private') {
            options.push( { label: 'None', value: 'None' } );
            options.push( { label: 'Read Only', value: 'Read' } );
            options.push( { label: 'Read/Write', value: 'Edit' } );
            isReadOnly = false;
        }
        else if(internalSharing === 'Read') {
            options.push( { label: 'Read Only', value: 'Read' } );
            options.push( { label: 'Read/Write', value: 'Edit' } );
            isReadOnly = false;
        }
        else if(internalSharing === 'ReadWrite' || internalSharing === 'ReadWriteTransfer') {
            options.push( { label: 'Read/Write', value: 'Edit' } );
            this.updateRelatedAccess(type, 'Edit');     // Default to only option
            isReadOnly = true;
        }
        else if(internalSharing === 'ControlledByParent') {
            options.push( { label: 'Controlled By Parent', value: 'ControlledByParent' } );
            this.updateRelatedAccess(type, 'ControlledByParent');   // Default to only option
            isReadOnly = true;
        }

        // Set field attributes for object
        if(type === 'contact') {
            this.contactAccessOptions = options;
            this.contactAccessIsReadOnly = isReadOnly;
            this.contactAccessHelpText = helpText;
        }
        else if(type === 'case') {
            this.caseAccessOptions = options;
            this.caseAccessIsReadOnly = isReadOnly;
            this.caseAccessHelpText = helpText;
        }
        else if(type === 'opportunity') {
            this.opportunityAccessOptions = options;
            this.opportunityAccessIsReadOnly = isReadOnly;
            this.opportunityAccessHelpText = helpText;
        }
    }

    handleSharingReasonChange(event) {
        this.updateSharingReason(event.detail.value);
    }

    updateSharingReason(value) {
        this.sharingReason = value;
        const evt = new CustomEvent('sharingreasonchange', {
            detail: this.sharingReason
        });
        this.dispatchEvent(evt);
    }


//    // Check that a share record can be instantiated with this reason
//    handleSharingReasonValidation(event) {
//        //console.log('event '+JSON.stringify(event));
//
//        //console.log('id and reason ' + this.sharedObjectApiName, this.sharingReason);
//
//        validateShareable({ objectApiName : this.sharedObjectApiName, sharingReason : this.sharingReason})
//        .then((isShareable) => {
//            //console.log('isShareable '+isShareable);
//
//            // Find attribute by custom data-* attribtue as this is available in the DOM
//            let sharingReasonField = this.template.querySelector("[data-id='sharingReason']");
//
//            // Show error if share cannot be created with this reason
//            if(isShareable) {
//                //console.log('setting valitity');
//                sharingReasonField.setCustomValidity("No sharing reason found with this name");
//                sharingReasonField.reportValidity();
//            }
//
//            else {
//                sharingReasonField.setCustomValidity('');
//                sharingReasonField.reportValidity();
//            }
//        })
//        .catch(error => {
//            //console.log('Error checking shareable ',JSON.stringify(error));
//        });
//        
//    }

    @track oneOrMoreReasons;
    @track sharingReasonOptions = [];
    @track loadingReasons = true;
    reasons;
    @wire(getSharingReasons, { objectApiName : '$sharedObjectApiName'} )
    wiredSharingReasons(value) {
        this.reasons = value;
        const { data, error } = value;
        if(data) {
            //console.log('retrieved options: '+JSON.stringify(data));

            this.sharingReasonOptions = [];
            this.oneOrMoreReasons = false;

            for(var key in data) {
                this.oneOrMoreReasons = true;
                const option = {
                    value: key,
                    label: data[key]
                };
                this.sharingReasonOptions.push(option);
            }
            this.loadingReasons = false;
        }
    }
    
    
    refreshReasons() {
        //console.log('Getting more reasons');
        this.loadingReasons = true;
        refreshApex(this.reasons)
        .then(() => {
            this.loadingReasons = false;
        });
    }

}