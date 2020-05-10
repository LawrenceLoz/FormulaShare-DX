import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getObjectApiNames from '@salesforce/apex/FormulaShareRuleDetailController.getObjectApiNames';
import getFieldApiNames from '@salesforce/apex/FormulaShareRuleDetailController.getFieldApiNames';
import getShareableObjects from '@salesforce/apex/FormulaShareRuleDetailController.getShareableObjects';
import getChildRelationships from '@salesforce/apex/FormulaShareRuleDetailController.getChildRelationships';
import getShareFieldOptions from '@salesforce/apex/FormulaShareRuleDetailController.getShareFieldOptions';

const FIELDS = [
    'FormulaShare_Rule__mdt.MasterLabel',
    'FormulaShare_Rule__mdt.DeveloperName',
    'FormulaShare_Rule__mdt.Access_Level__c',
    'FormulaShare_Rule__mdt.Active__c',
    'FormulaShare_Rule__mdt.Child_Object_Lookup_Field__c',
    'FormulaShare_Rule__mdt.Child_Object_Shared_To_Field__c',
    'FormulaShare_Rule__mdt.Child_Object_Shared_To_Field_Type__c',
    'FormulaShare_Rule__mdt.Child_Object_with_Shared_To_Field__c',
    'FormulaShare_Rule__mdt.Description__c',
    'FormulaShare_Rule__mdt.Object_Shared__c',
    'FormulaShare_Rule__mdt.Shared_To__c',
    'FormulaShare_Rule__mdt.Shared_To_Field_Type__c',
    'FormulaShare_Rule__mdt.Share_With__c',
    'FormulaShare_Rule__mdt.Sharing_Reason__c',
];

export default class FormulaShareRuleDetail extends LightningElement {
    @api ruleId = 'm05260000008f4XAAQ';
    ruleNew;
    apiNameToEntityIdMap = new Map();
    idFieldsSet = new Set();

    @track rule;
    @track ruleLabel;
    @track ruleName;
    @track ruleDescription;
    @track ruleActive;
    @track sharedObjectApiName;
    @track sharedObject;
    @track ruleType;
    @track showRelatedObjectSelection;
    @track relatedObjectSelected;
    @track shareField;
    @track shareFieldDisabled;
    @track shareWith;
    @track shareWithDisabled;
    @track shareFieldType;
    @track shareFieldTypeDisabled;

    objectWithShareField;

    // Get metadata record, and populate 
    @wire(getRecord, { recordId: '$ruleId', fields: FIELDS })
        ruleMetadata( {error, data} ) {
            if(data) {
                console.log('ruleId: '+this.ruleId);
                this.rule = data.fields;
                this.ruleLabel = this.rule.MasterLabel.value;
                this.ruleName = this.rule.DeveloperName.value;
                this.ruleDescription = this.rule.Description__c.value;
                this.ruleActive = this.ruleActive;

                console.log('rule details: ', this.ruleLabel,
                this.rule.DeveloperName,
                    this.ruleDescription)

                var objectsToCheck = [];
                objectsToCheck.push(data.fields.Object_Shared__c.value);
                objectsToCheck.push(data.fields.Child_Object_with_Shared_To_Field__c.value);
        
                getObjectApiNames({ objectEntityIds : objectsToCheck })
                .then((objectApiNamesMap) => {
                    console.log('map of entity ids to names: ' + JSON.stringify(objectApiNamesMap));
                    
                    var relatedObjectApiName;
                    for(var key in objectApiNamesMap){
                        if(key === data.fields.Object_Shared__c.value) {
                            this.sharedObjectApiName = objectApiNamesMap[key];
                        }
                        else if(key === data.fields.Child_Object_with_Shared_To_Field__c.value) {
                            relatedObjectApiName = objectApiNamesMap[key];
                            console.log('related obj: '+relatedObjectApiName);
                        }
                        console.log(key,objectApiNamesMap[key]);
                    }

                    // If related object populated, set field to indicate child rule type
                    if(relatedObjectApiName) {
                        this.ruleType = 'child';
                        this.objectWithShareField = relatedObjectApiName;
                        this.showRelatedObjectSelection = true;
                    }

                    else {
                        this.ruleType = 'standard';
                        this.objectWithShareField = this.sharedObjectApiName;
                    }

                    var fieldsToCheck = [];
                    fieldsToCheck.push(data.fields.Shared_To__c.value);
                    fieldsToCheck.push(data.fields.Child_Object_Lookup_Field__c.value);
                    fieldsToCheck.push(data.fields.Child_Object_Shared_To_Field__c.value);
                    
                    getFieldApiNames({ fieldEntityIds : fieldsToCheck })
                    .then((fieldApiNamesMap) => {

                        console.log('field names: '+fieldApiNamesMap);

                        for(var key in fieldApiNamesMap) {
                            console.log('key',key);

                            // Set share to field based on what's set in rule
                            if(key === data.fields.Shared_To__c.value || key === data.fields.Child_Object_Shared_To_Field__c.value) {
                                this.shareField = fieldApiNamesMap[key];
                                console.log('this.shareField: '+this.shareField);
                            }

                            // Set related object selected based on what's set in rule
                            if(key === data.fields.Child_Object_Lookup_Field__c.value) {
                                this.relatedObjectSelected = relatedObjectApiName + '|' + fieldApiNamesMap[key];
                                console.log('this.relatedObjectSelected: '+this.relatedObjectSelected);
                            }
                        }
                    })
                    .catch(error => {
                        console.log('Error building field map ',JSON.stringify(error));
                    });

                })
                .catch(error => {
                    console.log('Error building object map ',JSON.stringify(error));
                });
            }
            else if(error) {
                this.showError(error, 'Error retrieving rule details from Salesforce');
            }
        }

    //---------------------------- Name, label and description -----------------------------//
    handleLabelChange(event) {
        this.ruleLabel = event.detail;
    }
    handleNameChange(event) {
        this.rule.DeveloperName = event.detail;
    }
    handleDescriptionChange(event) {
        this.ruleDescription = event.detail;
    }
    handleActiveChange(event) {
        this.ruleActive = event.detail;
    }


    //---------------------------- Shared Object -----------------------------//
/*
    @track shareableObjectOptions;
    @wire(getShareableObjects)
        shareableObjects({ error, data }) {
            if(data) {
                this.shareableObjectOptions = [];

                data.forEach((obj) => {
        
                    // Populate map to store API names to entityIds for shareable objects
                    this.apiNameToEntityIdMap.set(obj.objectApiName, obj.objectId);
        
                    // Build options for dropdown, and populate in list to be returned
                    const option = {
                        label: obj.objectLabel + ' (' + obj.objectApiName + ')',
                        value: obj.objectApiName
                    };
                    this.shareableObjectOptions.push(option);
                });
            }
            else if(error) {
                console.log('error '+ JSON.stringify(error));
            }
        }
*/

    handleSetSharedObjectDetail(event) {
        this.sharedObject = event.detail;
        this.sharedObjectApiName = this.sharedObject.objectApiName;
    }

    handleSharedObjectChange(event) {
        this.handleSetSharedObjectDetail(event);

        console.log('this.sharedObjectApiName: ', this.sharedObjectApiName);
        this.objectWithShareField = this.sharedObjectApiName;
        this.relatedObjectSelected = null;
        this.ruleType = 'standard';
/*
        this.clearShareField();
        if(this.ruleType === 'child') {
            this.clearRuleType();
        }   */
    }

    //---------------------------- RuleType -----------------------------//

    get ruleTypeOptions() {
        return [
            { label: 'Field is on shared object', value: 'standard' },
            { label: 'Field is on a child object related to the shared object', value: 'child' },
        ];
    }

    handleRuleTypeChange(event) {
        this.ruleType = event.detail;

        if(this.ruleType === 'standard') {
            this.objectWithShareField = this.sharedObjectApiName;
            console.log('standard in parent');
        }
        else if(this.ruleType === 'child') {
            this.objectWithShareField = null;
        }
//        this.clearShareField();
    }

    @track renderRuleType = true;
    clearRuleType() {
        if(this.ruleType != 'standard') {
            this.ruleType = 'standard';
            this.showRelatedObjectSelection = false;
            console.log('resetting type');
            this.renderRuleType = false;
            setTimeout(() => {this.renderRuleType = true}, 0);
        }
    }
    
    //---------------------------- Related Object -----------------------------//

    @track relatedObjectOptions;
    @wire(getChildRelationships, { parentObjectAPIName : '$sharedObjectApiName'} )
        childRelationships({ error, data }) {
            if(data) {
                console.log('getting related for '+this.sharedObjectApiName);
                
                let relatedObjList = [];
                data.forEach((obj) => {
                    const option = {
                        label: obj.childObjectApiName + ' (related by ' + obj.childFieldApiName + ')',
                        value: obj.childObjectApiName + '|' + obj.childFieldApiName
                    };
                    relatedObjList.push(option);
                });
                this.relatedObjectOptions = relatedObjList;
            }
        }

    getRelationshipSelected() {
        var splitArray = this.relatedObjectSelected.split("|");
        return {objectApiName: splitArray[0], relationshipFieldApiName: splitArray[1]};
    }

    handleRelatedObjectChange(event) {
        this.relatedObjectSelected = event.detail.relatedObjectSelected;
        this.relatedObjectApiName = event.detail.relatedObjectApiName;

        console.log('changed to related obj: ', this.relatedObjectApiName);
        this.objectWithShareField = this.relatedObjectApiName;

//        this.shareFieldDisabled = false;
//        this.clearShareField();
    }

    //---------------------------- Field with sharing -----------------------------//

    @track fieldOptions;
    @wire(getShareFieldOptions, { objectApiName : '$objectWithShareField'} )
        shareFieldOptions({ error, data }) {
            if(data) {
                console.log('getting fields for '+this.objectWithShareField);
                
                this.idFieldsSet.clear();
                let fieldList = [];
                data.forEach((obj) => {
                    const option = {
                        label: obj.fieldLabel + ' (' + obj.fieldApiName + ')',
                        value: obj.fieldApiName
                    };
                    fieldList.push(option);

                    if(obj.isIdType) {
                        this.idFieldsSet.add(obj.fieldApiName)
                    }
                });
                this.fieldOptions = fieldList;
            }
            else if(error) {
                console.log('Error getting fields for object ',JSON.stringify(error));
            }
        }

    handleShareFieldChange(event) {
        this.shareField = event.detail.value;
        this.clearShareWith();
    }

    @track renderShareField = true;
    clearShareField() {
        var reRenderNeeded = false;

        console.log('this.ruleType ',this.ruleType);

        if(this.ruleType == 'standard') {
            console.log('enabling');
            this.shareField = null;
            this.shareFieldDisabled = false;
            reRenderNeeded = true;
        }
// && (this.shareField || this.shareFieldDisabled)
        else if(this.ruleType == 'child' && !this.relatedObjectSelected) {
            this.shareField = null;
            this.shareFieldDisabled = true;
            reRenderNeeded = true;
        }

        else if(this.ruleType == 'child' && this.relatedObjectSelected) {
            this.shareField = null;
            this.shareFieldDisabled = false;
            reRenderNeeded = true;
        }

        if(reRenderNeeded) {
            this.renderShareField = false;
            setTimeout(() => {this.renderShareField = true}, 0);
            this.clearShareWith();
        }
    }

    //---------------------------- Share With -----------------------------//
    get shareWithOptions() {
        return [
            { label: 'Users', value: 'users' },
            { label: 'Roles', value: 'roles' },
            { label: 'Roles and Internal Subordinates', value: 'rolesAndSubordinates' },
            { label: 'Public Groups', value: 'publicGroups' },
        ];
    }

    handleShareWithChange(event) {
        this.shareWith = event.detail.value;
        this.clearShareFieldType();
    }

    @track renderShareWith = true;
    clearShareWith() {
        var reRenderNeeded = false;

        console.log('shareField: '+this.shareField);

        // If share to field is not populated, clear and disable
        if(!this.shareField) {
            this.shareWith = null;
            this.shareWithDisabled = true;
            reRenderNeeded = true;
        }

        // If share to populated and is an id field, set to Users and disable
        else if(this.idFieldsSet.has(this.shareField) && !this.shareFieldTypeDisabled) {
            this.shareWith = 'users';
            this.shareWithDisabled = true;
            reRenderNeeded = true;
        }

        // If share to populated and not an id field, enable
        else if(!this.idFieldsSet.has(this.shareField) && this.shareWithDisabled) {
            this.shareWithDisabled = false;
            reRenderNeeded = true;
        }

        if(reRenderNeeded) {
            this.renderShareWith = false;
            setTimeout(() => {this.renderShareWith = true}, 0);
        }

        this.clearShareFieldType();
    }

    //---------------------------- Shared To Field Type -----------------------------//

    get shareFieldTypeOptions() {
        return [
            { label: 'Id of user, role or group', value: 'id' },
            { label: 'Name of role or group', value: 'name' },
        ];
    }

    handleShareFieldTypeChange(event) {
        this.shareFieldType = event.detail.value;
    }

    @track renderShareFieldType = true;
    clearShareFieldType() {
        var reRenderNeeded = false;

        // If Users selected, set to id and disable selection
        if(this.shareWith === 'users') {
            this.shareFieldType = 'id';
            this.shareFieldTypeDisabled = true;
            reRenderNeeded = true;
        }

        // If users not now selected but, but field was disabled, enable again and clear selection
        else if(this.shareFieldTypeDisabled && this.shareWith) {
            this.shareFieldType = null;
            this.shareFieldTypeDisabled = false;
            reRenderNeeded = true;
        }

        // If nothing selected, disable field and clear
        else if(!this.shareWith) {
            this.shareFieldType = null;
            this.shareFieldTypeDisabled = true;
            reRenderNeeded = true;
        }


        if(reRenderNeeded) {
            this.renderShareFieldType = false;
            setTimeout(() => {this.renderShareFieldType = true}, 0);
        }
    }
    
    //---------------------------- Access Level -----------------------------//

    //---------------------------- Sharing Reason -----------------------------//

    //---------------------------- Active -----------------------------//


}