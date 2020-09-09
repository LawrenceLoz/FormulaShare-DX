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
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSpecificRule from '@salesforce/apex/FormulaShareRulesSelector.getSpecificRule';
import getObjectApiNames from '@salesforce/apex/FormulaShareRuleDetailController.getObjectApiNames';
import getFieldApiNames from '@salesforce/apex/FormulaShareRuleDetailController.getFieldApiNames';


export default class FormulaShareRuleDetail extends LightningElement {
//    @api ruleId = 'm05260000008f4XAAQ';

    @api
    get ruleId() {
        return this._ruleId;
    }
    set ruleId(value) {
        this._ruleId = value;
        this.populateRule();
    }
    _ruleId;

    @api isEdit;
    @api shareWith;

//    @track rule = {"Id":"m057E0000005OHSQA2","Access_Level__c":"Edit","Object_Shared__c":"01I7E00000108uj","Shared_To__c":"01I7E00000108uj.00N7E000009M1fs","Share_With__c":"Public Groups","Sharing_Reason__c":"Thematic_Area_Coordination_Group__c","Active__c":true,"Shared_To_Field_Type__c":"Name","Child_Object_Shared_To_Field_Type__c":"Id","MasterLabel":"Share to Theme Coordination Group","DeveloperName":"Share_to_Theme_Coordination_Group","Object_Shared__r":{"QualifiedApiName":"Donation__c","MasterLabel":"Donation","Id":"000000000000000AAA","DurableId":"01I7E00000108uj"},"Shared_To__r":{"QualifiedApiName":"Thematic_Area_Coordination_Group__c","MasterLabel":"Thematic Area Coordination Group","Id":"000000000000000AAA","DurableId":"01I7E00000108uj.00N7E000009M1fs"}};
    @track rule;
    @track ruleLabel;
    @track ruleName;
    @track ruleDescription;
    @track ruleActive;
//    @track sharedObjectApiName = "Donation__c";
    @track sharedObjectApiName;
    @track sharedObject;
    @track ruleType;
    @track relatedObjectSelected;   // Holds object|lookupField
    @track shareField;
    @track shareFieldType;
    @track accessLevel;
    @track contactAccess;
    @track caseAccess;
    @track opportunityAccess;
    @track sharingReason;
    
    @track objectWithShareField;

    @api
    checkValidity() {
        console.log('checking validity');
        var nameLabelValid = this.template.querySelector('c-formula-share-rule-detail-name-label').checkValidity();
        var locationValid = this.template.querySelector('c-formula-share-rule-detail-location').checkValidity();
        var fieldValid = this.template.querySelector('c-formula-share-rule-detail-field').checkValidity();
        var accessValid = this.template.querySelector('c-formula-share-rule-detail-access').checkValidity();
        var ruleDetailValid = nameLabelValid && locationValid && fieldValid && accessValid;
        console.log('ruleDetailValid '+ruleDetailValid);
        return ruleDetailValid;
    }

    connectedCallback() {
        refreshApex(this.ruleDetails);
        console.log('refreshing!');
    }

        
    populateRule() {
        console.log('_ruleId '+this._ruleid);
        getSpecificRule({ ruleId : this._ruleId })
        .then((data) => {
            console.log('retrieved rule: '+JSON.stringify(data));
            var prefix = '';
            if(data.sdfs__Object_Shared__c) {
                prefix = 'sdfs__';
            }
            this.rule = data;
            this.ruleLabel = data.MasterLabel;
            this.ruleName = data.DeveloperName;
            this.ruleDescription = data[prefix + 'Description__c'];
            this.ruleActive = data[prefix + 'Active__c'];
            this.shareWith = data[prefix + 'Share_With__c'];
            this.accessLevel = data[prefix + 'Access_Level__c'];
            this.contactAccess = data[prefix + 'Contact_Access__c'];
            this.caseAccess = data[prefix + 'Case_Access__c'];
            this.opportunityAccess = data[prefix + 'Opportunity_Access__c'];
            this.sharingReason = data[prefix + 'Sharing_Reason__c'];

            // Create array of objects to query for details
            var objectsToCheck = [];
            const objectShared = data[prefix + 'Object_Shared__c'];
            if(objectShared) {
                objectsToCheck.push(objectShared);
            }
            const relatedObject = data[prefix + 'Child_Object_with_Shared_To_Field__c'];
            if(relatedObject) {
                objectsToCheck.push(relatedObject);
            }

            console.log('objects to check: '+JSON.stringify(objectsToCheck));
            
            // Call apex to get API names for the entity IDs held on rule metadata
            getObjectApiNames({ objectEntityIds : objectsToCheck })
            .then((objectApiNamesMap) => {
                console.log('objectApiNamesMap: '+JSON.stringify(objectApiNamesMap));

                // Iterate objects with details returned
                for(var key in objectApiNamesMap){
                    console.log('objectApiName: '+key,objectApiNamesMap[key]);

                    // Set API name of shared object
                    if(key === objectShared) {
                        this.sharedObjectApiName = objectApiNamesMap[key];
                    }

                    // Keep API name of related object
                    else if(key === relatedObject) {
                        this.relatedObjectApiName = objectApiNamesMap[key];
                    }
                }

                // If related object was populated, set field to indicate child rule type
                if(this.relatedObjectApiName) {
                    this.ruleType = 'child';
                    this.objectWithShareField = this.relatedObjectApiName;
                    this.shareFieldType = data[prefix + 'Child_Object_Shared_To_Field_Type__c'];
                }

                else {
                    this.ruleType = 'standard';
                    this.objectWithShareField = this.sharedObjectApiName;
                    this.shareFieldType = data[prefix + 'Shared_To_Field_Type__c'];
                }
                
                // Create array of fields to query
                var fieldsToCheck = [];
                const sharedToField = data[prefix + 'Shared_To__c'];
                if(sharedToField) {
                    fieldsToCheck.push(sharedToField);
                }
                const sharedToFieldRelated = data[prefix + 'Child_Object_Lookup_Field__c'];
                if(sharedToFieldRelated) {
                    fieldsToCheck.push(sharedToFieldRelated);
                }
                const lookupFieldRelated = data[prefix + 'Child_Object_Shared_To_Field__c'];
                if(lookupFieldRelated) {
                    fieldsToCheck.push(lookupFieldRelated);
                }

                console.log('fieldsToCheck: '+ JSON.stringify(fieldsToCheck));
                
                // Call apex to get API names
                getFieldApiNames({ fieldEntityIds : fieldsToCheck })
                .then((fieldApiNamesMap) => {

                    console.log('field names: '+fieldApiNamesMap);

                    for(var key in fieldApiNamesMap) {
                        console.log('key',key);

                        // Set share to field based on what's set in rule
                        if(key === sharedToField || key === sharedToFieldRelated) {
                            this.shareField = fieldApiNamesMap[key];
                            console.log('this.shareField: '+this.shareField);
                        }

                        // Set related object selected based on what's set in rule
                        if(key === lookupFieldRelated) {
                            this.relatedObjectSelected = this.relatedObjectApiName + '|' + fieldApiNamesMap[key];
                            console.log('this.relatedObjectSelected: '+this.relatedObjectSelected);
                        }
                    }

                    this.fireEventWithRule();
                })
                .catch(error => {
                    console.log('Error building field map ',JSON.stringify(error));
                });

            })
            .catch(error => {
                console.log('Error building object map ',JSON.stringify(error));
            });
        })
        .catch(error => {
            console.log('Error retrieving rule details from Salesforce',JSON.stringify(error));
            this.showError(error, 'Error retrieving rule details from Salesforce');
        });
    }
    
    
    // Fire event with all details in rule
    fireEventWithRule() {

        var ruleDetails = {
            "ruleLabel" : this.ruleLabel,
            "ruleName" : this.ruleName,
            "ruleDescription" : this.ruleDescription,
            "ruleActive" : this.ruleActive,
            "sharedObjectApiName" : this.sharedObjectApiName,
            "sharedObject" : this.sharedObject,
            "ruleType" : this.ruleType,
            "relatedObjectSelected" : this.relatedObjectSelected,
            "shareField" : this.shareField,
            "shareWith" : this.shareWith,
            "shareFieldType" : this.shareFieldType,
            "accessLevel" : this.accessLevel,
            "contactAccess" : this.contactAccess,
            "caseAccess" : this.caseAccess,
            "opportunityAccess" : this.opportunityAccess,
            "sharingReason" : this.sharingReason
        }

        const evt = new CustomEvent('ruledetail', { detail: ruleDetails });
        this.dispatchEvent(evt);
    }

    //--------------------- Event handlers for NameLabel component --------------------// 

    handleLabelChange(event) {
        this.ruleLabel = event.detail;
        this.fireEventWithRule();
    }
    handleNameChange(event) {
        this.ruleName = event.detail;
        this.fireEventWithRule();
    }
    handleDescriptionChange(event) {
        this.ruleDescription = event.detail;
        this.fireEventWithRule();
    }
    handleActiveChange(event) {
        this.ruleActive = event.detail;
        this.fireEventWithRule();
    }

    //-------------------- Event handlers for SharedObject component ---------------------// 

    // Called directly on component load to pass back shared object information
    handleSetSharedObjectDetail(event) {
        console.log('handling handleSetSharedObjectDetail event ',event.detail);
        this.sharedObject = event.detail;

        // Fire event for create component to disable button
        const evt = new CustomEvent('sharedobjectselected');
        this.dispatchEvent(evt);

        this.sharedObjectApiName = this.sharedObject.objectApiName;
        this.fireEventWithRule();
    }

    handleSharedObjectChange(event) {
        this.handleSetSharedObjectDetail(event);    // Capture object details

        // On change of shared object, assume that rule will be standard
        // Clear any object specific fields
        this.ruleType = 'standard';
        this.objectWithShareField = this.sharedObjectApiName;
        this.relatedObjectSelected = null;
        this.contactAcess = null;
        this.caseAcess = null;
        this.opportunityAcess = null;
        this.fireEventWithRule();
    }

    @track accountRelatedOwd;
    handleSetAccountRelatedOwd(event) {
        this.accountRelatedOwd = event.detail;
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
        this.fireEventWithRule();
    }

    handleRelatedObjectChange(event) {
        this.relatedObjectSelected = event.detail.relatedObjectSelected;
        this.relatedObjectApiName = event.detail.relatedObjectApiName;
        this.objectWithShareField = this.relatedObjectApiName;
        this.fireEventWithRule();
    }

    //--------------------- Event handlers for Field component ---------------------// 

    handleShareFieldChange(event) {
        this.shareField = event.detail;
        this.fireEventWithRule();
    }
    handleShareWithChange(event) {
        console.log('sharewith change');
        this.shareWith = event.detail;
        this.fireEventWithRule();
    }
    handleShareFieldTypeChange(event) {
        this.shareFieldType = event.detail;
        this.fireEventWithRule();
    }

    //--------------------- Event handlers for Access component ---------------------// 

    handleAccessLevelChange(event) {
        this.accessLevel = event.detail;
        this.fireEventWithRule();
    }

    handleContactAccessChange(event) {
        this.contactAccess = event.detail;
        this.fireEventWithRule();
    }
    handleCaseAccessChange(event) {
        this.caseAccess = event.detail;
        console.log('case access change: '+JSON.stringify(event.detail));
        this.fireEventWithRule();
    }
    handleOpportunityAccessChange(event) {
        this.opportunityAccess = event.detail;
        this.fireEventWithRule();
    }

    handleSharingReasonChange(event) {
        this.sharingReason = event.detail;
        this.fireEventWithRule();
    }

    
    // Called to trigger a toast message including a system error
    showError(error, toastTitle) {
        console.log('Error received: ' + JSON.stringify(error));

        let errorMessage = 'Unknown error';
        if (Array.isArray(error.body)) {
            errorMessage = error.body.map(e => e.message).join(', ');
        }
        else if (error && error.body && error.body.message && typeof error.body.message === 'string') {
            errorMessage = error.body.message;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: toastTitle,
                message: 'Message from Salesforce: ' + errorMessage,
                variant: 'error'
            })
        );
    }    
}