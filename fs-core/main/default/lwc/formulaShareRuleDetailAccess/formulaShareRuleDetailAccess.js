import { LightningElement, api, track } from 'lwc';

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

    @api isCustom;
    @api accessLevel;
    @api sharingReason;

    // Build access level options of Read and/or Read/Write
    @track accessLevelOptions;
    updateAccessLevelOptions() {
        var options = [];
        // Include Read Only option if either internal or external OWD is private
        if(this._internalSharingModel === 'Private' || this._externalSharingModel === 'Private' ) {
            options.push( { label: 'Read Only', value: 'Read' } );
        }
        options.push( { label: 'Read/Write', value: 'Edit' } );
        this.accessLevelOptions = options;
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