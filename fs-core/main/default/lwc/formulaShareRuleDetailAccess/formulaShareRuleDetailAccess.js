import { LightningElement, api, track } from 'lwc';
import getClassicDomain from '@salesforce/apex/FormulaShareUtilities.getClassicDomain';

export default class FormulaShareRuleDetailAccess extends LightningElement {
    
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

    @api
    get sharedObjectLabel() {}
    set sharedObjectLabel(value) {
        this._sharedObjectLabel = value;
        this.updateAccessLevelOptions();
    }
    _sharedObjectLabel;

    @api
    get sharedObjectId() {}
    set sharedObjectId(value) {
        this._sharedObjectId = value;
        this.buildSharingReasonsSetupLink();
    }
    _sharedObjectId;

    @api isCustom;
    @api accessLevel;
    @api sharingReason;

    @track sharingReasonsHelpBox = false;
    toggleSharingReasonsHelpBox() {
        this.sharingReasonsHelpBox ? this.sharingReasonsHelpBox = false : this.sharingReasonsHelpBox = true;
    }

    // Get custom Salesforce classic domain on component load
    classicDomain;
    connectedCallback() {
        getClassicDomain()
        .then((domainName) => {
            console.log('found dom '+domainName);
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
            options.push( { label: 'Read/Write', value: 'Edit' } );
    
            // Include Read Only option if either internal or external OWD is private
            if(this._internalSharingModel === 'Private' || this._externalSharingModel === 'Private' || this.accessLevel === 'Read') {
                options.push( { label: 'Read Only', value: 'Read' } );
                this.accessLevelHelpText = null;
                this.accessLevelIsReadOnly = false;
            }
    
            // Otherwise disable field, default to only option and add help text
            else {
                this.accessLevelIsReadOnly = true;
                this.accessLevelHelpText = 'Access level must be more permissive than the organisation-wide default, which is set to Public Read Only for ' + this._sharedObjectLabel;
                this.accessLevel = 'Edit';
            }
            this.accessLevelOptions = options;
        }
    }

    handleAccessLevelChange(event) {
        this.accessLevel = event.detail.value;
        const evt = new CustomEvent('accesslevelchange', {
            detail: this.accessLevel
        });
        this.dispatchEvent(evt);
    }

    handleSharingReasonChange(event) {
        this.sharingReason = event.detail.value;
        const evt = new CustomEvent('sharingreasonchange', {
            detail: this.sharingReason
        });
        this.dispatchEvent(evt);
    }

}