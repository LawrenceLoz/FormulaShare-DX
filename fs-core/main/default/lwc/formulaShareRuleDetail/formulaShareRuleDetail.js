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

    @track rule = {"Id":"m057E0000005OHSQA2","Access_Level__c":"Edit","Object_Shared__c":"01I7E00000108uj","Shared_To__c":"01I7E00000108uj.00N7E000009M1fs","Share_With__c":"Public Groups","Sharing_Reason__c":"Thematic_Area_Coordination_Group__c","Active__c":true,"Shared_To_Field_Type__c":"Name","Child_Object_Shared_To_Field_Type__c":"Id","MasterLabel":"Share to Theme Coordination Group","DeveloperName":"Share_to_Theme_Coordination_Group","Object_Shared__r":{"QualifiedApiName":"Donation__c","MasterLabel":"Donation","Id":"000000000000000AAA","DurableId":"01I7E00000108uj"},"Shared_To__r":{"QualifiedApiName":"Thematic_Area_Coordination_Group__c","MasterLabel":"Thematic Area Coordination Group","Id":"000000000000000AAA","DurableId":"01I7E00000108uj.00N7E000009M1fs"}};
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

    // Get FormulaShareRule metadata record, and populate variables to display summary of rule
    // Apex methods are called to access names and labels from entity attributes
//    @wire(getSpecificRule, { ruleId : '$ruleId'} )
//        ruleDetails({ error, data }) {
//            if(data) {
//            }
//            else if(error) {
//                console.log('error: '+JSON.stringify(error));
//                this.showError(error, 'Error retrieving rule details from Salesforce');
//            }
            
        populateRule() {
            console.log('_ruleId '+this._ruleid);
            getSpecificRule({ ruleId : this._ruleId })
            .then((data) => {
                console.log('retrieved rule: '+JSON.stringify(data));
                this.rule = data;
                this.ruleLabel = data.MasterLabel;
                this.ruleName = data.DeveloperName;
                this.ruleDescription = data.Description__c;
                this.ruleActive = data.Active__c;
                this.shareWith = data.Share_With__c;
                this.accessLevel = data.Access_Level__c;
                this.contactAccess = data.Contact_Access__c;
                this.caseAccess = data.Case_Access__c;
                this.opportunityAccess = data.Opportunity_Access__c;
                this.sharingReason = data.Sharing_Reason__c;

                // Create array of objects to query for details
                var objectsToCheck = [];
                objectsToCheck.push(data.Object_Shared__c);
                objectsToCheck.push(data.Child_Object_with_Shared_To_Field__c);
                
                // Call apex to get API names for the entity IDs held on rule metadata
                getObjectApiNames({ objectEntityIds : objectsToCheck })
                .then((objectApiNamesMap) => {

                    // Iterate objects with details returned
                    for(var key in objectApiNamesMap){

                        // Set API name of shared object
                        if(key === data.Object_Shared__c) {
                            this.sharedObjectApiName = objectApiNamesMap[key];
                        }

                        // Keep API name of related object
                        else if(key === data.Child_Object_with_Shared_To_Field__c) {
                            this.relatedObjectApiName = objectApiNamesMap[key];
                        }
                        console.log('objectApiName: '+key,objectApiNamesMap[key]);
                    }

                    // If related object was populated, set field to indicate child rule type
                    if(this.relatedObjectApiName) {
                        this.ruleType = 'child';
                        this.objectWithShareField = this.relatedObjectApiName;
                        this.shareFieldType = this.rule.Child_Object_Shared_To_Field_Type__c;
                    }

                    else {
                        this.ruleType = 'standard';
                        this.shareFieldType = this.rule.Shared_To_Field_Type__c;
                        this.objectWithShareField = this.sharedObjectApiName;
                    }
                    
                    // Create array of fields to query
                    var fieldsToCheck = [];
                    fieldsToCheck.push(data.Shared_To__c);
                    fieldsToCheck.push(data.Child_Object_Lookup_Field__c);
                    fieldsToCheck.push(data.Child_Object_Shared_To_Field__c);
                    
                    // Call apex to get API names
                    getFieldApiNames({ fieldEntityIds : fieldsToCheck })
                    .then((fieldApiNamesMap) => {

                        console.log('field names: '+fieldApiNamesMap);

                        for(var key in fieldApiNamesMap) {
                            console.log('key',key);

                            // Set share to field based on what's set in rule
                            if(key === data.Shared_To__c || key === data.Child_Object_Shared_To_Field__c) {
                                this.shareField = fieldApiNamesMap[key];
                                console.log('this.shareField: '+this.shareField);
                            }

                            // Set related object selected based on what's set in rule
                            if(key === data.Child_Object_Lookup_Field__c) {
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

//    handleContactSharingDetails(event) {
//        console.log('Set contact detail: '+JSON.stringify(this.contactObjectDetail))
//    }
//
//    handleCaseSharingDetails(event) {
//        this.caseObjectDetail = event.detail;
//        console.log('Set case detail: '+JSON.stringify(this.caseObjectDetail))
//    }
//
//    handleOpportunitySharingDetails(event) {
//        this.opportunityObjectDetail = event.detail;
//        console.log('Set opp detail: '+JSON.stringify(this.opportunityObjectDetail))
//    }

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
        let errorMessage = 'Unknown error';
        if (Array.isArray(error.body)) {
            errorMessage = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
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