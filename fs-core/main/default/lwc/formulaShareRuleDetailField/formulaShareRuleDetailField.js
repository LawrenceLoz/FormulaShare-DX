import { LightningElement, api, track, wire } from 'lwc';
import getShareFieldOptions from '@salesforce/apex/FormulaShareRuleDetailController.getShareFieldOptions';

export default class FormulaShareRuleDetailField extends LightningElement {
    @api
    get objectWithShareField() {
        return this._objectWithShareField;
    }
    set objectWithShareField(value) {
        // Clear shareField and shareFieldType if object with share field is changed
        if(this._objectWithShareField && this._objectWithShareField != value) {
            this.shareField = null;

            // Retain id type if users selected
            if(this.shareWith != 'users') {
                this.shareFieldType = null;
            }
        }
        this._objectWithShareField = value;
    }
    _objectWithShareField;

    @api shareWith;
    get shareWith() {
        return this._shareWith;
    }
    set shareWith(value) {
        // Update options for field type if necessary
        if(this._shareWith != value) {
            console.log('setting share with: ',value);
            this._shareWith = value;
            this.updateShareFieldTypeOptions();
        }
    }
    _shareWith;

    @api shareField;
    @api shareFieldType;
    fullFieldList = [];
    namesOnlyFieldList = [];

    get shareWithOptions() {
        return [
            { label: 'Users', value: 'Users' },
            { label: 'Roles', value: 'Roles' },
            { label: 'Roles and Internal Subordinates', value: 'Roles and Internal Subordinates' },
            { label: 'Public Groups', value: 'Public Groups' },
        ];
    }

    handleShareWithChange(event) {
        this._shareWith = event.detail.value;
        console.log('share with changed: ',this._shareWith);
        const evt = new CustomEvent('sharewithchange', {
            detail: this._shareWith
        });
        this.dispatchEvent(evt);
        this.updateShareFieldTypeOptions();
        this.setFieldOptions();
        console.log('shareFieldTypeOptions ',this.shareFieldTypeOptions[0]);
    }

    @track fieldOptions;
    @wire(getShareFieldOptions, { objectApiName : '$_objectWithShareField'} )
        shareFieldOptions({ error, data }) {
            if(data) {
                console.log('getting fields for '+this._objectWithShareField);

                // Refresh lists in case previously populated from another object
                this.fullFieldList = [];
                this.namesOnlyFieldList = [];

                data.forEach((obj) => {
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
            }
            else if(error) {
                console.log('Error getting fields for object ',JSON.stringify(error));
            }
        }
    
    // Set options to include id fields (user lookups) only if "Users" selected
    setFieldOptions() {
        if(this.shareWith === 'Users') {
            console.log('setting to full list ',this.fullFieldList);
            this.fieldOptions = this.fullFieldList;
        }
        else {
            console.log('setting to names only list ',this.namesOnlyFieldList);
            this.fieldOptions = this.namesOnlyFieldList;
        }
    }

    handleShareFieldChange(event) {
        this.shareField = event.detail.value;
        const evt = new CustomEvent('sharefieldchange', {
            detail: this.shareField
        });
        this.dispatchEvent(evt);
    }
    
    @track shareFieldTypeOptions;
    updateShareFieldTypeOptions() {
        console.log('this._shareWith ',this._shareWith);
        switch (this._shareWith) {
            case 'Users':
                console.log('updated to users');
                this.shareFieldTypeOptions = [
                    { label: 'Id of user', value: 'Id' }
                ];
                this.shareFieldType = 'Id';
                console.log('this.shareFieldType ',this.shareFieldType);
                break;
            case 'Public Groups':
                console.log('updated to public groups');
                this.shareFieldTypeOptions = [
                    { label: 'Id of public group', value: 'Id' },
                    { label: 'Name of public group', value: 'Name' },
                ];
                break;
            case 'Roles':
            case 'Roles and Internal Subordinates':
                console.log('updated to roles');
                this.shareFieldTypeOptions = [
                    { label: 'Id of role', value: 'Id' },
                    { label: 'Name of role', value: 'Name' },
                ];
        }
    }

    handleShareFieldTypeChange(event) {
        this.shareFieldType = event.detail.value;
        const evt = new CustomEvent('sharefieldtypechange', {
            detail: this.shareFieldType
        });
        this.dispatchEvent(evt);        
    }          
    
}