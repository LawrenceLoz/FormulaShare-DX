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

    @track rule;
    @track ruleLabel;
    @track ruleName;
    @track ruleDescription;
    @track ruleActive;
    @track sharedObjectApiName;
    @track sharedObject;
    @track ruleType;
    @track relatedObjectSelected;   // Holds object|lookupField
    @track shareField;
    @track shareWith;
    @track shareFieldType;
    @track accessLevel;
    @track sharingReason;

    @track objectWithShareField;

    // Get FormulaShareRule metadata record, and populate variables to display summary of rule
    // Apex methods are called to access names and labels from entity attributes
    @wire(getRecord, { recordId: '$ruleId', fields: FIELDS })
        ruleMetadata( {error, data} ) {
            if(data) {
                this.rule = data.fields;
                this.ruleLabel = this.rule.MasterLabel.value;
                this.ruleName = this.rule.DeveloperName.value;
                this.ruleDescription = this.rule.Description__c.value;
                this.ruleActive = this.rule.Active__c.value;
                this.shareWith = this.rule.Share_With__c.value;
                this.accessLevel = this.rule.Access_Level__c.value;
                this.sharingReason = this.rule.Sharing_Reason__c.value;

                // Create array of objects to query for details
                var objectsToCheck = [];
                objectsToCheck.push(data.fields.Object_Shared__c.value);
                objectsToCheck.push(data.fields.Child_Object_with_Shared_To_Field__c.value);
                
                // Call apex to get API names for the entity IDs held on rule metadata
                getObjectApiNames({ objectEntityIds : objectsToCheck })
                .then((objectApiNamesMap) => {

                    // Iterate objects with details returned
                    for(var key in objectApiNamesMap){

                        // Set API name of shared object
                        if(key === data.fields.Object_Shared__c.value) {
                            this.sharedObjectApiName = objectApiNamesMap[key];
                        }

                        // Keep API name of related object
                        else if(key === data.fields.Child_Object_with_Shared_To_Field__c.value) {
                            this.relatedObjectApiName = objectApiNamesMap[key];
                        }
                        console.log(key,objectApiNamesMap[key]);
                    }

                    // If related object was populated, set field to indicate child rule type
                    if(this.relatedObjectApiName) {
                        this.ruleType = 'child';
                        this.objectWithShareField = this.relatedObjectApiName;
                        this.shareFieldType = this.rule.Child_Object_Shared_To_Field_Type__c.value;
                    }

                    else {
                        this.ruleType = 'standard';
                        this.shareFieldType = this.rule.Shared_To_Field_Type__c.value;
                        this.objectWithShareField = this.sharedObjectApiName;
                    }
                    
                    // Create array of fields to query
                    var fieldsToCheck = [];
                    fieldsToCheck.push(data.fields.Shared_To__c.value);
                    fieldsToCheck.push(data.fields.Child_Object_Lookup_Field__c.value);
                    fieldsToCheck.push(data.fields.Child_Object_Shared_To_Field__c.value);
                    
                    // Call apex to get API names
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
                                this.relatedObjectSelected = this.relatedObjectApiName + '|' + fieldApiNamesMap[key];
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

    //--------------------- Event handlers for NameLabel component --------------------// 

    handleLabelChange(event) {
        this.ruleLabel = event.detail;
    }
    handleNameChange(event) {
        this.ruleName = event.detail;
    }
    handleDescriptionChange(event) {
        this.ruleDescription = event.detail;
    }
    handleActiveChange(event) {
        this.ruleActive = event.detail;
    }

    //-------------------- Event handlers for SharedObject component ---------------------// 

    // Called directly on component load to pass back shared object information
    handleSetSharedObjectDetail(event) {
        this.sharedObject = event.detail;
        this.sharedObjectApiName = this.sharedObject.objectApiName;
    }

    handleSharedObjectChange(event) {
        this.handleSetSharedObjectDetail(event);    // Capture object details

        // On change of shared object, assume that rule will be standard
        this.ruleType = 'standard';
        this.objectWithShareField = this.sharedObjectApiName;
        this.relatedObjectSelected = null;
    }

    //--------------------- Event handlers for Location component ---------------------// 

    handleRuleTypeChange(event) {
        this.ruleType = event.detail;

        // Set object with share field based on rule type
        if(this.ruleType === 'standard') {
            this.objectWithShareField = this.sharedObjectApiName;
        }
        else if(this.ruleType === 'child') {
            this.objectWithShareField = this.relatedObjectApiName;  // Will be null unless pre-selected from previous action
        }
    }

    handleRelatedObjectChange(event) {
        this.relatedObjectSelected = event.detail.relatedObjectSelected;
        this.relatedObjectApiName = event.detail.relatedObjectApiName;
        this.objectWithShareField = this.relatedObjectApiName;
    }

    //--------------------- Event handlers for Field component ---------------------// 

    handleShareFieldChange(event) {
        this.shareField = event.detail;
    }
    handleShareWithChange(event) {
        console.log('sharewith change');
        this.shareWith = event.detail;
    }
    handleShareFieldTypeChange(event) {
        this.shareFieldType = event.detail;
    }

    //--------------------- Event handlers for Access component ---------------------// 

    handleAccessLevelChange(event) {
        this.accessLevel = event.detail;
    }

    handleSharingReasonChange(event) {
        this.sharingReason = event.detail;
    }
    
}