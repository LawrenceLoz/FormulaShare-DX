/**
*Copyright 2020 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy 
*of this software and associated documentation files (the "Software"), to deal 
*in the Software without restriction, including without limitation the rights 
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
*of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all 
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import infoCloud from '@salesforce/resourceUrl/InfoCloud';
import getLightningDomain from '@salesforce/apex/FormulaShareLWCUtilities.getLightningDomain';
import getShareFieldOptions from '@salesforce/apex/FormulaShareRuleDetailController.getShareFieldOptions';
import isManagerSharingSupported from '@salesforce/apex/FormulaShareRuleDetailController.isManagerSharingSupported';
import isAccountTeamSharingSupported from '@salesforce/apex/FormulaShareRuleDetailController.isAccountTeamSharingSupported';
import isOpportunityTeamSharingSupported from '@salesforce/apex/FormulaShareRuleDetailController.isOpportunityTeamSharingSupported';

export default class FormulaShareRuleDetailField extends LightningElement {

    infoCloudLogo = infoCloud;

    @api disableShareField;

    @api
    get objectWithShareField() {
        return this._objectWithShareField;
    }
    set objectWithShareField(value) {
        // Clear shareField and shareFieldType if object with share field is changed
        if(this._objectWithShareField && this._objectWithShareField !== value) {
            this.updateShareField(null);
            this.updateShareFieldType(null);

            this.fieldDetailsToggleText = this.viewFieldDetailsClosed;
            this.viewAdvancedSettings = false;
            this.advancedSettingsToggleText = 'Show advanced settings';
        }
        this._objectWithShareField = value;
        //console.log('Set object with share field: '+this._objectWithShareField);
    }
    _objectWithShareField;

    @api
    get shareWith() {
        return this._shareWith;
    }
    set shareWith(value) {
        // Update options for field type if necessary
        if(this._shareWith !== value) {
            //console.log('setting share with: ',value);
            this._shareWith = value;
            this.updateShareFieldTypeOptions();
            this.updateshareWithFlags();            
        }
    }
    _shareWith;

    @api
    get internalSharingModel() {
        return this._internalSharingModel;
    }
    set internalSharingModel(value) {
        this._internalSharingModel = value;
        this.updateShareWithOptions();
    }
    _internalSharingModel;

    @api
    get externalSharingModel() {
        return this._externalSharingModel;
    }
    set externalSharingModel(value) {
        this._externalSharingModel = value;
        this.updateShareWithOptions();
    }
    _externalSharingModel;
    
    @api
    get shareField() {
        return this._shareField;
    }
    set shareField(value) {
        this._shareField = value;
        this.updateFieldDetails();
    }
    _shareField;

    @api
    get shareFieldType() {
        return this._shareFieldType;
    }
    set shareFieldType(value) {
        this._shareFieldType = value;
    }
    _shareFieldType;

    @api
    get mdMappingType() {
        return this._mdMappingType;
    }
    set mdMappingType(value) {
        this._mdMappingType = value;
    }
    _mdMappingType;

    @api mdMappingMatchField;
//    @api controllingObjectApiName;    // Would be used in help text, but doesn't seem to be set after setting CMDT relationship for first time
    @api controllingObjectSharedToFieldApiName;

    // Set default if values are currently null
    @api
    get behaviourMdMatchFieldMismatch() {
        return this._behaviourMdMatchFieldMismatch;
    }
    set behaviourMdMatchFieldMismatch(value) {
        if(value) {
            this._behaviourMdMatchFieldMismatch = value;
        }
        else {
            this._behaviourMdMatchFieldMismatch = 'Log Error';
        }
    }
    _behaviourMdMatchFieldMismatch;
    @api
    get behaviourShareToFieldMismatch() {
        return this._behaviourShareToFieldMismatch;
    }
    set behaviourShareToFieldMismatch(value) {
        if(value) {
            this._behaviourShareToFieldMismatch = value;
        }
        else {
            this._behaviourShareToFieldMismatch = 'Log Error';
//            this.updateMismatchField('behaviourShareToFieldMismatch', this._behaviourShareToFieldMismatch);
        }
    }
    _behaviourShareToFieldMismatch;

    @api fallbackMdMatchFieldMismatch;
    @api fallbackShareToFieldMismatch;

    fullFieldList = [];
    namesOnlyFieldList = [];

    usersLink;
    rolesLink;
    publicGroupsLink;
    queuesLink;
    connectedCallback() {
        getLightningDomain()
            .then((domainName) => {
                this.usersLink = domainName + '/lightning/setup/ManageUsers/home';
                this.rolesLink = domainName + '/lightning/setup/Roles/home';
                this.publicGroupsLink = domainName + '/lightning/setup/PublicGroups/home';
                this.queuesLink = domainName + '/lightning/setup/Queues/home';
            });
    }


    @track shareWithOptions;
    updateShareWithOptions() {
        var optionsList = [
            { label: 'Users', value: 'Users' },
            { label: 'Roles', value: 'Roles' },
        ];

        // If object is private or public read-only for internal, include roles and internal subordinates sharing
        if(this._internalSharingModel === 'Private' || this._internalSharingModel === 'Read') {
            optionsList.push( { label: 'Roles and Internal Subordinates', value: 'Roles and Internal Subordinates' } );
        }

        // If object is private or public read-only for external, include roles and internal subordinates sharing
        if(this._externalSharingModel === 'Private' || this._externalSharingModel === 'Read') {
            optionsList.push( { label: 'Roles, Internal and Portal Subordinates', value: 'Roles, Internal and Portal Subordinates' } );
        }

        optionsList.push( { label: 'Public Groups or Queues', value: 'Public Groups' } );

        if(this.managerSharingSupported) {
            optionsList.push( { label: 'Managers of Users', value: 'Managers of Users' } );
            optionsList.push( { label: 'Users and Manager Subordinates', value: 'Users and Manager Subordinates' } );
        }

        if(this.atmSharingSupported) {
            optionsList.push( { label: 'Default Account Teams of Users', value: 'Default Account Teams of Users' } );
        }

        if(this.otmSharingSupported) {
            optionsList.push( { label: 'Default Opportunity Teams of Users', value: 'Default Opportunity Teams of Users' } );
        }

        this.shareWithOptions = optionsList;
    }

    managerSharingSupported;
    @wire(isManagerSharingSupported)
    wiredIsManagerSharingSupported(value) {
        const { data, error } = value;
        if(data) {
            this.managerSharingSupported = data;
            this.updateShareWithOptions();
        }
        else if(error) {
            console.log('Error with wire service: '+error);
        }
    }

    atmSharingSupported;
    @wire(isAccountTeamSharingSupported)
    wiredIsAccountTeamSharingSupported(value) {
        const { data, error } = value;
        if(data) {
            this.atmSharingSupported = data;
            this.updateShareWithOptions();
        }
        else if(error) {
            console.log('Error with wire service: '+error);
        }
    }

    otmSharingSupported;
    @wire(isOpportunityTeamSharingSupported)
    wiredIsOpportunityTeamSharingSupported(value) {
        const { data, error } = value;
        if(data) {
            this.otmSharingSupported = data;
            this.updateShareWithOptions();
        }
        else if(error) {
            console.log('Error with wire service: '+error);
        }
    }



    @track fieldOptions;
    shareFieldOptions;
    fieldsMap = new Map();
    loadingFields = true;
    @wire(getShareFieldOptions, { objectApiName : '$_objectWithShareField'} )
    wiredShareFieldOptions(value) {
        this.shareFieldOptions = value;
        const { data, error } = value;
        if(data) {
            //console.log('getting fields for '+this._objectWithShareField);

            // Refresh lists in case previously populated from another object
            this.fieldsMap.clear();
            this.fullFieldList = [];
            this.namesOnlyFieldList = [];

            data.forEach((obj) => {
                this.fieldsMap.set(obj.fieldApiName,obj);
                const option = {
                    label: obj.fieldLabel + ' (' + obj.fieldApiName + ')',
                    value: obj.fieldApiName
                };
                this.fullFieldList.push(option);

                if(!obj.isIdType) {
                    this.namesOnlyFieldList.push(option);
                }
            });

            this.setFieldOptions();
            this.updateShareWithOptions();
            this.updateFieldDetails();
        }
        else if(error) {
            //console.log('Error getting fields for object ',JSON.stringify(error));
        }
    }

    refreshFields() {
        //console.log('refreshing');
        this.loadingFields = true;
        refreshApex(this.shareFieldOptions)
        .then(() => {
            this.loadingFields = false;
        })
    }
    
    // Set options to include id fields (user lookups) only if Users or a Manager Groups option selected
    setFieldOptions() {
        if(['Users'
            , 'Managers of Users'
            , 'Users and Manager Subordinates'
            , 'Default Account Teams of Users'
            , 'Default Opportunity Teams of Users'].includes(this.shareWith)) {
            //console.log('setting to full list ',this.fullFieldList);
            this.fieldOptions = this.fullFieldList;
        }
        else {
            //console.log('setting to names only list ',this.namesOnlyFieldList);
            this.fieldOptions = this.namesOnlyFieldList;
        }
        this.loadingFields = false;
    }

    @track shareFieldTypeOptions;
    @track fieldTypeIsReadOnly;
    updateShareFieldTypeOptions() {

        //console.log('this._shareWith ',this._shareWith);
        switch (this._shareWith) {
            case 'Users':
            case 'Managers of Users':
            case 'Users and Manager Subordinates':
            case 'Default Account Teams of Users':
            case 'Default Opportunity Teams of Users':

                this.shareFieldTypeOptions = [
                    { label: 'Id of user', value: 'Id' }
                ];
                this.fieldTypeIsReadOnly = true;
                break;
            case 'Public Groups':
                //console.log('updated to public groups');
                this.shareFieldTypeOptions = [
                    { label: 'Name of Public Group or Queue', value: 'Name' },
                    { label: 'Id of Public Group or Queue', value: 'Id' },
                ];
                this.fieldTypeIsReadOnly = false;
                break;
            case 'Roles':
            case 'Roles and Internal Subordinates':
            case 'Roles, Internal and Portal Subordinates':
                //console.log('updated to roles');
                this.shareFieldTypeOptions = [
                    { label: 'Name of role', value: 'Name' },
                    { label: 'Id of role', value: 'Id' },
                ];
                this.fieldTypeIsReadOnly = false;
                break;
            default:
        }
    }


    shareWithFlags;
    updateshareWithFlags() {
        this.shareWithFlags = {};
        switch (this._shareWith) {
            case 'Users':
                this.shareWithFlags.users = true;
                break;
            case 'Roles':
                this.shareWithFlags.roles = true;
                break;
            case 'Roles and Internal Subordinates':
                this.shareWithFlags.rolesAndInternalSubordinates = true;
                break;
            case 'Roles, Internal and Portal Subordinates':
                this.shareWithFlags.rolesInternalAndPortalSubordinates = true;
                break;
            case 'Public Groups':
                this.shareWithFlags.publicGroups = true;
                break;
            case 'Managers of Users':
                this.shareWithFlags.managersOfusers = true;
                break;
            case 'Users and Manager Subordinates':
                this.shareWithFlags.usersAndManagerSubordinates = true;
                break;
            case 'Default Account Teams of Users':
                this.shareWithFlags.defaultAccountTeamsOfUsers = true;
                break;
            case 'Default Opportunity Teams of Users':
                this.shareWithFlags.defaultOpportunityTeamsOfUsers = true;
                break;
            default:
        }
    }


    setDefaultFieldType() {
        // Default share type to 'Name' if shareWith allows this (otherwise will set to 'Id')
        this.updateShareFieldType('Name');
    }

    viewHowWorks;
    viewHowWorksClosed = 'How does this work?';
    viewHowWorksOpen = 'Hide';
    viewHowWorksToggleText = this.viewHowWorksClosed;
    toggleViewHowWorks() {
        if(this.viewHowWorks) {
            this.viewHowWorks = false;
            this.viewHowWorksToggleText = this.viewHowWorksClosed;
        }
        else {
            this.viewHowWorks = true;
            this.viewHowWorksToggleText = this.viewHowWorksOpen;
        }
    }


    viewFieldDetails;
    viewFieldDetailsClosed = 'Browse field contents';
    viewFieldDetailsOpen = 'Hide field contents';
    fieldDetailsToggleText = this.viewFieldDetailsClosed;
    toggleViewFieldDetails() {
        if(this.viewFieldDetails) {
            this.viewFieldDetails = false;
            this.fieldDetailsToggleText = this.viewFieldDetailsClosed;
        }
        else {
            this.viewFieldDetails = true;
            this.fieldDetailsToggleText = this.viewFieldDetailsOpen;
        }
    }

    // Toggle display and labels for advanced settings
    get showAdvancedSettingsToggle() {
        return this.shareWith && this.shareField && this.shareFieldType;
    }

    viewAdvancedSettings;
    advancedSettingsToggleText = 'Show advanced settings';
    toggleAdvancedSettings() {
        if(this.viewAdvancedSettings) {
            this.viewAdvancedSettings = false;
            this.advancedSettingsToggleText = 'Show advanced settings';
        }
        else {
            this.setNoMatchBehaviourOptions();
            this.viewAdvancedSettings = true;
            this.advancedSettingsToggleText = 'Hide advanced settings';
        }
    }

    userRoleOrGroup;
    noMatchBehaviourOptions;
    setNoMatchBehaviourOptions() {
        switch (this._shareWith) {
            case 'Users':
            case 'Managers of Users':
            case 'Users and Manager Subordinates':
            case 'Default Account Teams of Users':
            case 'Default Opportunity Teams of Users':
                this.userRoleOrGroup = 'User';
                break;
            case 'Public Groups':
                this.userRoleOrGroup = 'Public Group or Queue';
                break;
            case 'Roles':
            case 'Roles and Internal Subordinates':
            case 'Roles, Internal and Portal Subordinates':
                this.userRoleOrGroup = 'Role'
                break;
            default:
        }

        this.noMatchBehaviourOptions = [
            {
                value: 'Log Error', 
                label: 'Log an Error', 
                description: 'Create a FormulaShare Record Log indicating that a match was expected but couldn\'t be found'
            },
            {
                value: 'Share With Default',
                label: 'Share to a Default '+this.userRoleOrGroup,
                description: 'Add the '+this.shareFieldType+' of the '+this.userRoleOrGroup+' to receive access instead'
            },
            {
                value: 'Do Not Share',
                label: 'Take No Action',
                description: 'Do not share this record but don\'t log this as an error',
            }
        ];
    }

    // Getters for UI display of advanced settings fields
    get behaviourShareToFieldMismatchHelpText() {
        return 'Action to be taken when \"'+this.shareField+'\" contains a value that does not match the '+this.shareFieldType+' of an active '+this.userRoleOrGroup;
    }
    get behaviourMdMatchFieldMismatchHelpText() {
        return 'Action to be taken when \"'+this.controllingObjectSharedToFieldApiName+'\" contains a value, but there is no \"'+this.mdMappingType+'\" record with \"'+this.mdMappingMatchField+'\" matching this value';
    }
    get behaviourShareToFieldMismatchDefault() {
        return this.behaviourShareToFieldMismatch === 'Share With Default';
    }
    get behaviourMdMatchFieldMismatchDefault() {
        return this.behaviourMdMatchFieldMismatch === 'Share With Default';
    }


    handleShareWithChange(event) {
        this._shareWith = event.detail.value;
        //console.log('share with changed: ',this._shareWith);
        const evt = new CustomEvent('sharewithchange', {
            detail: this._shareWith
        });
        this.dispatchEvent(evt);
        this.updateShareFieldTypeOptions();
        this.updateshareWithFlags();
        this.setDefaultFieldType();
        this.setFieldOptions();
        this.setNoMatchBehaviourOptions();
    }

    handleShareFieldChange(event) {
        this.updateShareField(event.detail.value);
    }

    updateShareField(value) {
        this._shareField = value;
        this.updateFieldDetails();
        const evt = new CustomEvent('sharefieldchange', {
            detail: this._shareField
        });
        this.dispatchEvent(evt);
    }

    @track fieldType;
    @track fieldFormula;
    updateFieldDetails() {

        // Clear details if field has been cleared
        if(this._shareField === null) {
            this.fieldType = null;
            this.fieldFormula = null;
            this.viewFieldDetails = null;
            this.fieldDetailsToggleText = this.viewFieldDetailsClosed;
            //console.log('cleared text '+this.fieldDetailsToggleText);
        }

        // Otherwise, if field details map is built then set details for this field
        else if(this.fieldsMap.get(this._shareField)) {
            const fieldOption = this.fieldsMap.get(this._shareField);
            //console.log('fieldOption: '+JSON.stringify(fieldOption));
            this.fieldType = fieldOption.type;
            this.fieldFormula = fieldOption.formula;
        }

        // Or if field and fields map populated but no match, show error
        else if(this._shareField && this.fieldsMap && this.fieldsMap.size > 0) {
            this.fieldNotAvailableForSharingError(this._shareField);
        }
    }

    fieldNotAvailableForSharingError(fieldName) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Field not suitable for sharing'
                , message: 'It looks like the field currently set on this rule (' + fieldName
                    + ') is not of a type fully compatible with FormulaShare. Consider updating the field'
                    + ' type, or changing the field to an alternative of one of the following'
                    + ': Formula (returning text), Text or Lookup (to user object).'
                , variant: 'error'
                , mode: 'sticky'
            })
        );
    }
    
    handleShareFieldTypeChange(event) {
        this.updateShareFieldType(event.detail.value);
    }

    updateShareFieldType(value) {

        // If sharing to users or manager groups, type should always be Id
        if(this.shareWith && 
            ['Users'
            , 'Managers of Users'
            , 'Users and Manager Subordinates'
            , 'Default Account Teams of Users'
            , 'Default Opportunity Teams of Users'].includes(this.shareWith)) {
            this._shareFieldType = 'Id';
        }

        // Otherwise set to provided value (either 'Id' 'Name' or null)
        else {
            this._shareFieldType = value;
        }
 
        const evt = new CustomEvent('sharefieldtypechange', {
            detail: this.shareFieldType
        });
        this.dispatchEvent(evt);
        this.setNoMatchBehaviourOptions();
    }

    // Handlers for advanced settings changes
    handleBehaviourShareToFieldMismatchUpdate(event) {
        this.updateMismatchField('behaviourShareToFieldMismatch', event.detail.value);
    }
    handleFallbackShareToFieldMismatchUpdate(event) {
        this.updateMismatchField('fallbackShareToFieldMismatch', event.detail.value);
    }
    handleBehaviourMdMatchFieldMismatchUpdate(event) {
        this.updateMismatchField('behaviourMdMatchFieldMismatch', event.detail.value);
    }
    handleFallbackMdMatchFieldMismatchUpdate(event) {
        this.updateMismatchField('fallbackMdMatchFieldMismatch', event.detail.value);
    }
    updateMismatchField(fieldName, value) {
        //console.log('Updating mismatch: '+fieldName+' to '+value);
        const evt = new CustomEvent('mismatchfieldchange', {
            detail: {
                fieldName: fieldName,
                value: value
            }
        });
        this.dispatchEvent(evt);
    }


    @api
    checkValidity() {
        const allValid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        //console.log('Detail field valid? '+allValid);
        return allValid;
    }

}