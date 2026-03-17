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
import getNamespacePrefix from '@salesforce/apex/FormulaShareLWCUtilities.getNamespacePrefix';
import getShareFieldOptions from '@salesforce/apex/FormulaShareRuleDetailController.getShareFieldOptions';
import isManagerSharingSupported from '@salesforce/apex/FormulaShareRuleDetailController.isManagerSharingSupported';
import isAccountTeamSharingSupported from '@salesforce/apex/FormulaShareRuleDetailController.isAccountTeamSharingSupported';
import isOpportunityTeamSharingSupported from '@salesforce/apex/FormulaShareRuleDetailController.isOpportunityTeamSharingSupported';
import isDefaultTeamShareWithEnabled from '@salesforce/apex/FormulaShareRuleDetailController.isDefaultTeamShareWithEnabled';
import supportsUsersWithFieldMatch from '@salesforce/apex/FormulaShareLwcAvailabilityController.supportsUsersWithFieldMatch';
import getUserFieldMatchOptions from '@salesforce/apex/FormulaShareLwcAvailabilityController.getUserFieldMatchOptions';
import supportsTeamSharing from '@salesforce/apex/FormulaShareLwcAvailabilityController.supportsTeamSharing';
import getActiveTeamMappings from '@salesforce/apex/FormulaShareLwcAvailabilityController.getActiveTeamMappings';
import getTeamFieldOptions from '@salesforce/apex/FormulaShareLwcAvailabilityController.getTeamFieldOptions';
import getTeamObjectLabel from '@salesforce/apex/FormulaShareLwcAvailabilityController.getTeamObjectLabel';

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
        // When getting the value, return legacy "Users with Matching Field Value" if in matching mode
        if (this._shareWith === 'Users' && this.userSharingMode === 'matching') {
            return 'Users with Matching Field Value';
        }
        return this._shareWith;
    }
    set shareWith(value) {
        // Handle legacy "Users with Matching Field Value" value
        if (value === 'Users with Matching Field Value') {
            const wasChanged = this._shareWith !== 'Users' || this.userSharingMode !== 'matching';
            this._shareWith = 'Users';
            this.userSharingMode = 'matching';
            if (wasChanged) {
                this.updateShareFieldTypeOptions();
                this.updateshareWithFlags();
            }
        } 
        // Update if shareWith value is different
        else if(this._shareWith !== value) {
            //console.log('setting share with: ',value);
            this._shareWith = value;
            // Reset to default mode if switching to Users from another option
            if (value === 'Users' && this.userSharingMode !== 'specified') {
                this.userSharingMode = 'specified';
            }
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

    // Dynamic label for the record-side field depending on Share With option and user sharing mode
    get shareFieldLabel() {
        if (this._shareWith === 'Users' && this.userSharingMode === 'matching') {
            return 'Record Field';
        }
        return 'Specified in Field';
    }

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

    // ---- Team mapping API properties (passed from ruleDetail) ---- //
    @api sharedObjectApiName;

    @api
    get selectedTeamMapping() {
        return this._selectedTeamMapping;
    }
    set selectedTeamMapping(value) {
        if (this._selectedTeamMapping !== value) {
            this._selectedTeamMapping = value;
            this.onTeamMappingChanged();
        }
    }
    _selectedTeamMapping;

    @api
    get selectedTeamField() {
        return this._selectedTeamField;
    }
    set selectedTeamField(value) {
        this._selectedTeamField = value;
    }
    _selectedTeamField;

    @api
    get selectedTeamFieldType() {
        return this._selectedTeamFieldType;
    }
    set selectedTeamFieldType(value) {
        this._selectedTeamFieldType = value;
    }
    _selectedTeamFieldType;

    // ---- Team mapping internal state ---- //
    @track teamMappingOptions = [];
    @track teamFieldOptions = [];
    @track teamContainingTypeOptions = [];
    _allTeamContainingTypeOptions = []; // full options set by mapping; preserved for non-Id fields
    teamContainingTypeValue = 'Id';

    // Disable when there's only one option (no name field on mapping) or field is a lookup (Id type)
    get teamContainingTypeDisabled() {
        return this.teamContainingTypeOptions.length <= 1;
    }
    loadingTeamFields = false;
    loadingTeamMappings = false;
    teamMappingsByDevName = {};
    teamConfigSetupLink;
    teamsHelpBox = false;

    // Browse field contents for team field
    @track viewTeamFieldDetails = false;
    teamFieldDetailsClosed = 'Browse Field Contents';
    teamFieldDetailsOpen = 'Hide Field Contents';
    @track teamFieldDetailsToggleText = 'Browse Field Contents';

    toggleTeamsHelpBox() {
        this.teamsHelpBox = !this.teamsHelpBox;
    }

    toggleViewTeamFieldDetails() {
        if (this.viewTeamFieldDetails) {
            this.viewTeamFieldDetails = false;
            this.teamFieldDetailsToggleText = this.teamFieldDetailsClosed;
        } else {
            this.viewTeamFieldDetails = true;
            this.teamFieldDetailsToggleText = this.teamFieldDetailsOpen;
        }
    }

    fullFieldList = [];
    namesOnlyFieldList = [];

    usersLink;
    rolesLink;
    publicGroupsLink;
    queuesLink;
    connectedCallback() {
        Promise.all([getLightningDomain(), getNamespacePrefix()])
            .then(([domainName, nsPrefix]) => {
                this.usersLink = domainName + '/lightning/setup/ManageUsers/home';
                this.rolesLink = domainName + '/lightning/setup/Roles/home';
                this.publicGroupsLink = domainName + '/lightning/setup/PublicGroups/home';
                this.queuesLink = domainName + '/lightning/setup/Queues/home';
                this.teamConfigSetupLink = domainName + '/lightning/n/' + nsPrefix + 'FormulaShare_Setup?c__page=team-and-user-groups';
            });
    }


    supportsUsersWithFieldMatchFlag = false;
    @track userFieldMatchOptions = [];
    @track loadingUserFields = false;
    @api
    get selectedUserFieldForMatching() {
        return this._selectedUserFieldForMatching;
    }
    set selectedUserFieldForMatching(value) {
        this._selectedUserFieldForMatching = value;
    }
    _selectedUserFieldForMatching; // stores API name to persist to CMDT User_Field_For_Matching__c
    shareWithFlags = {}; // Initialize to empty object to prevent undefined errors
    
    // Track the user sharing mode: 'specified' or 'matching'
    userSharingMode = 'specified';
    
    // Getter for user sharing mode options
    get userSharingModeOptions() {
        const options = [
            { label: 'Specified in a record field', value: 'specified' }
        ];
        
        // Only show the matching option if the feature is supported
        if (this.supportsUsersWithFieldMatchFlag) {
            options.push({ 
                label: 'With a User field matching the record field', 
                value: 'matching' 
            });
        }
        
        return options;
    }
    
    // Show user sharing mode toggle when Users is selected
    get showUserSharingModeToggle() {
        return this._shareWith === 'Users';
    }

    get shareWithOptions() {
        console.log('shareWithOptions getter called - supportsUsersWithFieldMatchFlag:', this.supportsUsersWithFieldMatchFlag);
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

        if(this.atmSharingSupported && this.defaultTeamShareWithEnabled) {
            optionsList.push( { label: 'Default Account Teams of Users', value: 'Default Account Teams of Users' } );
        }

        if(this.otmSharingSupported && this.defaultTeamShareWithEnabled) {
            optionsList.push( { label: 'Default Opportunity Teams of Users', value: 'Default Opportunity Teams of Users' } );
        }

        if(this.teamSharingSupported) {
            optionsList.push( { label: 'Teams', value: 'Teams' } );
        }

        // Note: "Users with Matching Field Value" is now handled via toggle when Users is selected
        // No longer added as a separate option in the list

        return optionsList;
    }

    updateShareWithOptions() {
        // This method is now a no-op since shareWithOptions is a getter
        // Kept for backwards compatibility with calls from wire adapters
        console.log('updateShareWithOptions called (now using getter)');
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

    defaultTeamShareWithEnabled = false;
    @wire(isDefaultTeamShareWithEnabled)
    wiredIsDefaultTeamShareWithEnabled({ data, error }) {
        if(data !== undefined) {
            this.defaultTeamShareWithEnabled = data === true;
            this.updateShareWithOptions();
        } else if(error) {
            console.log('Error with wire service: '+error);
        }
    }

    // Detect availability of managed-only option and fetch user field options
    @wire(supportsUsersWithFieldMatch)
    wiredSupportsUsersWithFieldMatch(value) {
        const { data, error } = value;
        console.log('Wire adapter called - data:', data, 'error:', error);
        if(data !== undefined) {
            this.supportsUsersWithFieldMatchFlag = data === true;
            this.updateShareWithOptions();
            if(this.supportsUsersWithFieldMatchFlag) {
                // Fetch user field options for matching picklist
                getUserFieldMatchOptions()
                    .then((opts) => {
                        this.userFieldMatchOptions = (opts || []).map(o => {
                            return {
                                label: o.fieldLabel + ' (' + o.fieldApiName + ')',
                                value: o.fieldApiName
                            };
                        });
                        console.log('User field match options loaded:', this.userFieldMatchOptions.length);
                    })
                    .catch((e) => {
                        // eslint-disable-next-line no-console
                        console.log('Error getting user match fields ', e);
                    });
            }
        } else if(error) {
            // eslint-disable-next-line no-console
            console.log('Error detecting supportsUsersWithFieldMatch ', error);
        }
    }

    // Detect availability of Teams share-with option
    teamSharingSupported = false;
    @wire(supportsTeamSharing)
    wiredSupportsTeamSharing({ data, error }) {
        if(data !== undefined) {
            this.teamSharingSupported = data === true;
            this.updateShareWithOptions();
        } else if(error) {
            console.log('Error detecting supportsTeamSharing ', error);
        }
    }

    // ---- Wire: Active Team Mappings for embedded team mapping selector ---- //
    @wire(getActiveTeamMappings)
    wiredTeamMappings({ data, error }) {
        if (data) {
            this.teamMappingOptions = data.map(m => ({
                label: m.label,
                value: m.developerName
            }));
            data.forEach(m => {
                this.teamMappingsByDevName[m.developerName] = m;
            });
            // If a mapping was already set (edit mode), load dependent data
            if (this._selectedTeamMapping) {
                this.onTeamMappingChanged();
            }
        } else if (error) {
            console.error('Error loading team mappings:', error);
        }
    }

    // ---- Team mapping reactive methods ---- //

    onTeamMappingChanged() {
        const mapping = this.teamMappingsByDevName[this._selectedTeamMapping];
        if (mapping) {
            this.loadTeamObjectLabel(mapping.teamObjectApiName);
            this.loadTeamFields();
        }
    }

    loadTeamFields() {
        const mapping = this.teamMappingsByDevName[this._selectedTeamMapping];
        if (!mapping || !this._objectWithShareField) return;

        this.loadingTeamFields = true;
        getTeamFieldOptions({
            objectApiName: this._objectWithShareField,
            teamObjectApiName: mapping.teamObjectApiName,
            sharedObjectApiName: this.sharedObjectApiName || this._objectWithShareField
        })
            .then(result => {
                this.teamFieldOptions = result.map(f => ({
                    label: f.fieldLabel + ' (' + f.fieldApiName + ')',
                    value: f.fieldApiName,
                    isIdType: f.isIdType
                }));
                // If a lookup field is already selected (edit mode), collapse options to Id-only
                const currentField = this.teamFieldOptions.find(f => f.value === this._selectedTeamField);
                if (currentField && currentField.isIdType) {
                    this.teamContainingTypeOptions = this._allTeamContainingTypeOptions.filter(o => o.value === 'Id');
                    this.teamContainingTypeValue = 'Id';
                }
                this.loadingTeamFields = false;
            })
            .catch(err => {
                console.error('Error loading team field options:', err);
                this.loadingTeamFields = false;
            });
    }

    loadTeamObjectLabel(teamObjectApiName) {
        const mapping = this.teamMappingsByDevName[this._selectedTeamMapping];
        getTeamObjectLabel({ teamObjectApiName })
            .then(label => {
                const idOption = { label: 'Id of ' + label + ' record', value: 'Id' };
                const options = [idOption];
                if (mapping && mapping.teamNameFieldApiName) {
                    const nameOption = {
                        label: 'Text matching the ' + mapping.teamNameFieldApiName + ' field on ' + label + ' record',
                        value: 'Name'
                    };
                    options.push(nameOption);
                }
                this._allTeamContainingTypeOptions = options;
                this.teamContainingTypeOptions = options;
                // Restore from saved value if available, otherwise default to Id
                if (this._selectedTeamFieldType && options.some(o => o.value === this._selectedTeamFieldType)) {
                    this.teamContainingTypeValue = this._selectedTeamFieldType;
                } else {
                    this.teamContainingTypeValue = 'Id';
                }
            })
            .catch(err => {
                console.error('Error loading team object label:', err);
                this.teamContainingTypeOptions = [
                    { label: 'Record Id', value: 'Id' }
                ];
                this.teamContainingTypeValue = 'Id';
            });
    }

    refreshTeamMappings() {
        if (this.loadingTeamMappings) return;
        this.loadingTeamMappings = true;
        getActiveTeamMappings()
            .then(data => {
                this.teamMappingOptions = data.map(m => ({
                    label: m.label,
                    value: m.developerName
                }));
                data.forEach(m => {
                    this.teamMappingsByDevName[m.developerName] = m;
                });
                this.loadingTeamMappings = false;
                // Reload fields with fresh mapping data if one is selected
                if (this._selectedTeamMapping) {
                    this.onTeamMappingChanged();
                }
            })
            .catch(err => {
                console.error('Error refreshing team mappings:', err);
                this.loadingTeamMappings = false;
            });
    }

    refreshTeamFields() {
        if (this.loadingTeamFields) return;
        this.loadTeamFields();
    }

    handleTeamMappingChange(event) {
        this._selectedTeamMapping = event.detail.value;
        this.onTeamMappingChanged();

        // Clear the field selection and containing type when mapping changes
        this._selectedTeamField = null;
        this._selectedTeamFieldType = null;
        this.teamContainingTypeValue = 'Id';

        this.dispatchEvent(new CustomEvent('teammappingchange', {
            detail: this._selectedTeamMapping
        }));

        // Also fire field change to clear it in parent
        this.dispatchEvent(new CustomEvent('teamfieldchange', {
            detail: { fieldApiName: null, fieldType: null }
        }));
    }

    handleTeamContainingTypeChange(event) {
        this.teamContainingTypeValue = event.detail.value;
        this._selectedTeamFieldType = this.teamContainingTypeValue;

        this.dispatchEvent(new CustomEvent('teamfieldchange', {
            detail: {
                fieldApiName: this._selectedTeamField,
                fieldType: this._selectedTeamFieldType
            }
        }));
    }

    handleTeamFieldChangeInternal(event) {
        this._selectedTeamField = event.detail.value;

        // If the selected field is a lookup (Id type), force Containing Type to Id and disable
        const selectedOption = this.teamFieldOptions.find(f => f.value === this._selectedTeamField);
        if (selectedOption && selectedOption.isIdType) {
            this.teamContainingTypeOptions = this._allTeamContainingTypeOptions.filter(o => o.value === 'Id');
            this.teamContainingTypeValue = 'Id';
        } else {
            this.teamContainingTypeOptions = this._allTeamContainingTypeOptions;
        }
        this._selectedTeamFieldType = this.teamContainingTypeValue;

        this.dispatchEvent(new CustomEvent('teamfieldchange', {
            detail: {
                fieldApiName: this._selectedTeamField,
                fieldType: this._selectedTeamFieldType
            }
        }));
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

    refreshUserFields() {
        console.log('refreshing user fields');
        this.loadingUserFields = true;
        getUserFieldMatchOptions()
            .then((opts) => {
                this.userFieldMatchOptions = (opts || []).map(o => {
                    return {
                        label: o.fieldLabel + ' (' + o.fieldApiName + ')',
                        value: o.fieldApiName
                    };
                });
                this.loadingUserFields = false;
                console.log('User field match options refreshed:', this.userFieldMatchOptions.length);
            })
            .catch((e) => {
                this.loadingUserFields = false;
                // eslint-disable-next-line no-console
                console.log('Error refreshing user match fields ', e);
            });
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
                // For Users with Matching Field Value, use Name type for text field matching
                if (this.userSharingMode === 'matching') {
                    this.shareFieldTypeOptions = [
                        { label: 'Name/text field to match', value: 'Name' }
                    ];
                    this.fieldTypeIsReadOnly = true;
                } else {
                    this.shareFieldTypeOptions = [
                        { label: 'Id of User', value: 'Id' }
                    ];
                    this.fieldTypeIsReadOnly = true;
                }
                break;
            case 'Managers of Users':
            case 'Users and Manager Subordinates':
            case 'Default Account Teams of Users':
            case 'Default Opportunity Teams of Users':

                this.shareFieldTypeOptions = [
                    { label: 'Id of User', value: 'Id' }
                ];
                this.fieldTypeIsReadOnly = true;
                break;
            case 'Public Groups':
                //console.log('updated to public groups');
                this.shareFieldTypeOptions = [
                    { label: 'Group or Queue Name (DeveloperName)', value: 'Name' },
                    { label: 'Group or Queue Id', value: 'Id' },
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


    updateshareWithFlags() {
        this.shareWithFlags = {};
        
        // Handle Users option - check the mode to determine if it's matching
        if (this._shareWith === 'Users') {
            if (this.userSharingMode === 'matching') {
                this.shareWithFlags.usersWithFieldMatch = true;
                this.shareWithFlags.usersOrUsersWithFieldMatch = true;
            } else {
                this.shareWithFlags.users = true;
                this.shareWithFlags.usersOrUsersWithFieldMatch = true;
            }
        }
        
        switch (this._shareWith) {
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
            case 'Teams':
                this.shareWithFlags.teams = true;
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

    @track viewUserFieldDetails;
    userFieldDetailsClosed = 'Browse field contents';
    userFieldDetailsOpen = 'Hide field contents';
    @track userFieldDetailsToggleText = this.userFieldDetailsClosed;
    toggleViewUserFieldDetails() {
        if(this.viewUserFieldDetails) {
            this.viewUserFieldDetails = false;
            this.userFieldDetailsToggleText = this.userFieldDetailsClosed;
        }
        else {
            this.viewUserFieldDetails = true;
            this.userFieldDetailsToggleText = this.userFieldDetailsOpen;
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
        
        // Reset user sharing mode when Users is selected
        if (this._shareWith === 'Users') {
            this.userSharingMode = 'specified';
        }
        
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
    
    handleUserSharingModeChange(event) {
        this.userSharingMode = event.detail.value;
        
        // Update field type options based on the new mode (Name for matching, Id for specified)
        this.updateShareFieldTypeOptions();
        
        // Update the actual field type value (must be done after updating options)
        this.updateShareFieldType(this.userSharingMode === 'matching' ? 'Name' : 'Id');
        
        // Update the flags based on the new mode
        this.updateshareWithFlags();
        
        // Dispatch sharewithchange event so parent gets updated shareWith value
        const shareWithEvt = new CustomEvent('sharewithchange', {
            detail: this.shareWith  // This getter will return the appropriate value
        });
        this.dispatchEvent(shareWithEvt);
        
        // Also dispatch specific mode change event
        const modeEvt = new CustomEvent('usersharingmodechange', {
            detail: this.userSharingMode
        });
        this.dispatchEvent(modeEvt);
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
        // Skip this check when Teams is selected - the team mapping component manages its own field list
        else if(this._shareField && this.fieldsMap && this.fieldsMap.size > 0 && !this.shareWithFlags.teams) {
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

        // For Users with Matching Field Value, type should be Name (for text field matching)
        if(this.shareWith === 'Users' && this.userSharingMode === 'matching') {
            this._shareFieldType = 'Name';
        }
        // For other user-related sharing, type should always be Id
        else if(this.shareWith && 
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

    // Event to persist the selected user field for matching back to parent
    handleUserFieldForMatchingChange(event) {
        this.selectedUserFieldForMatching = event.detail.value;
        console.log('***Set userFieldForMatching: '+this.selectedUserFieldForMatching);
        const evt = new CustomEvent('userfieldformatchingchange', {
            detail: this.selectedUserFieldForMatching
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
