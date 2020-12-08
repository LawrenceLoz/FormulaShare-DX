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

        console.log('Set rule from id: '+value);
        this.populateRule();
//        .then(() => {
//            fireEventWithRule();
//        });
    }
    _ruleId;

    @api isEdit;
    @track sharedObjectDetail;

    
//    @track objectWithShareFieldApiName;

//    @api shareWith;
//    @api shareFieldType;
//
////    @track rule = {"Id":"m057E0000005OHSQA2","Access_Level__c":"Edit","Object_Shared__c":"01I7E00000108uj","Shared_To__c":"01I7E00000108uj.00N7E000009M1fs","Share_With__c":"Public Groups","Sharing_Reason__c":"Thematic_Area_Coordination_Group__c","Active__c":true,"Shared_To_Field_Type__c":"Name","Child_Object_Shared_To_Field_Type__c":"Id","MasterLabel":"Share to Theme Coordination Group","DeveloperName":"Share_to_Theme_Coordination_Group","Object_Shared__r":{"QualifiedApiName":"Donation__c","MasterLabel":"Donation","Id":"000000000000000AAA","DurableId":"01I7E00000108uj"},"Shared_To__r":{"QualifiedApiName":"Thematic_Area_Coordination_Group__c","MasterLabel":"Thematic Area Coordination Group","Id":"000000000000000AAA","DurableId":"01I7E00000108uj.00N7E000009M1fs"}};
//    @track rule;
//    @track ruleLabel;
//    @track ruleName;
//    @track ruleDescription;
//    @track ruleActive;
////    @track sharedObjectApiName = "Donation__c";
//    @track sharedObjectApiName;
//    @track ruleType;
//    @track relatedObjectSelected;   // Holds object|lookupField
//    @track shareField;
//    @track accessLevel;
//    @track contactAccess;
//    @track caseAccess;
//    @track opportunityAccess;
//    @track sharingReason;
//    

    @api
    checkValidity() {
        //console.log('checking validity');
        var nameLabelValid = this.template.querySelector('c-formula-share-rule-detail-name-label').checkValidity();
//        var locationValid = this.template.querySelector('c-formula-share-rule-detail-location').checkValidity();
        var fieldValid = this.template.querySelector('c-formula-share-rule-detail-field').checkValidity();
        var accessValid = this.template.querySelector('c-formula-share-rule-detail-access').checkValidity();
        var ruleDetailValid = nameLabelValid && locationValid && fieldValid && accessValid;
        //console.log('ruleDetailValid '+ruleDetailValid);
        return ruleDetailValid;
    }

//    connectedCallback() {
//        refreshApex(this.wiredRule);
//        this.rule = this.wiredRule;
//        fireEventWithRule();
//        console.log('refreshed!');
//    }

    @track rule = {};
//    rule = {"accessLevel":"Read","active":true,"caseAccess":"None","contactAccess":"None","controllingObjectApiName":"sdfs__Programme_Support_Officer__c","controllingObjectLabel":"Programme Support Officer","controllingObjectSharedToFieldAPIName":"sdfs__User__c","controllingObjectSharedToFieldLabel":"User","controllingObjectSharedToFieldToken":"01I26000000cvxA.00N260000063Lub","controllingObjectSharedToFieldType":"Id","developerName":"Share_Countries_with_Prog_Support_Office","label":"Share Countries with Prog Support Office","objectSharedAPIName":"sdfs__Country__c","objectSharedLabel":"Country","opportunityAccess":"None","relationship":{"nextRelationship":{"lookupToPrevObjectApiName":"sdfs__Country__c","nextRelationship":{"lookupToPrevObjectApiName":"sdfs__Programme__c","sharedToFieldApiName":"sdfs__User__c","thisObjectApiName":"sdfs__Programme_Support_Officer__c"},"thisObjectApiName":"sdfs__Programme__c"},"thisObjectApiName":"sdfs__Country__c"},"ruleId":"m00260000000nmlAAA","shareWith":"Users","type":"descendant"};
    populateRule() {
        //console.log('_ruleId '+this._ruleid);
        getSpecificRule({ ruleId : this._ruleId })
        .then((data) => {
            console.log('retrieved rule: '+JSON.stringify(data));
            this.rule = data;
            this.fireEventWithRule();
        });
    }
    
    // Fire event with all details in rule
    fireEventWithRule() {
//
//        var ruleDetails = {
//            "ruleLabel" : this.ruleLabel,
//            "ruleName" : this.ruleName,
//            "ruleDescription" : this.ruleDescription,
//            "ruleActive" : this.ruleActive,
//            "sharedObjectApiName" : this.sharedObjectApiName,
//            "sharedObject" : this.sharedObject,
//            "ruleType" : this.ruleType,
//            "relatedObjectSelected" : this.relatedObjectSelected,
//            "shareField" : this.shareField,
//            "shareWith" : this.shareWith,
//            "shareFieldType" : this.shareFieldType,
//            "accessLevel" : this.accessLevel,
//            "contactAccess" : this.contactAccess,
//            "caseAccess" : this.caseAccess,
//            "opportunityAccess" : this.opportunityAccess,
//            "sharingReason" : this.sharingReason
//        }

        const evt = new CustomEvent('ruledetail', { detail : this.rule });
        this.dispatchEvent(evt);
    }

    //--------------------- Event handlers for NameLabel component --------------------// 

    handleLabelChange(event) {
        this.rule.label = event.detail;
        this.fireEventWithRule();
    }
    handleNameChange(event) {
        this.rule.developerName = event.detail;
        this.fireEventWithRule();
    }
    handleDescriptionChange(event) {
        this.rule.description = event.detail;
        this.fireEventWithRule();
    }
    handleActiveChange(event) {
        this.rule.active = event.detail;
        this.fireEventWithRule();
    }

    //-------------------- Event handlers for SharedObject component ---------------------// 

    // Called directly on component load to pass back shared object information
    handleSetSharedObjectDetail(event) {
        this.sharedObjectDetail = event.detail;

        // Fire event for create component to disable button
        const evt = new CustomEvent('sharedobjectselected');
        this.dispatchEvent(evt);

        this.rule.objectSharedAPIName = this.sharedObjectDetail.objectApiName;
        this.fireEventWithRule();
    }

    handleSharedObjectChange(event) {
        
        // On change of shared object, assume that rule will be standard
        // Default object with share field to be the selected object (ensures field list populates)
        this.rule.controllingObjectApiName = event.detail.objectApiName;
        this.rule.relationship = {thisObjectApiName: this.rule.controllingObjectApiName, thisObjectLabel: event.detail.objectLabel};
        this.template.querySelector('c-formula-share-rule-detail-location').setSelectedLocationToThisObject();
        this.rule.type = 'standard';

        // Clear any object specific fields
        this.rule.contactAccess = null;
        this.rule.caseAccess = null;
        this.rule.opportunityAccess = null;

        console.log('Cleared values after shared obj change. Current rule: '+JSON.stringify(this.rule));

        this.handleSetSharedObjectDetail(event);    // Capture object details
    }

    // Capture and cascade object's OWD passed up by ruleDetailSharedObject component
    @track accountRelatedOwd;
    handleSetAccountRelatedOwd(event) {
        this.accountRelatedOwd = event.detail;
    }

    //--------------------- Event handlers for Location component ---------------------// 

    // Replace with handlers for generic change of relationship
    handleRelationshipChange(event) {
        console.log('Captured relationship change in top component: '+JSON.stringify(event.detail.relationship));
        this.rule.relationship = event.detail.relationship;
        this.rule.controllingObjectApiName = event.detail.controllingObjectApiName;
        this.fireEventWithRule();
    }

    //--------------------- Event handlers for Field component ---------------------// 

    handleShareFieldChange(event) {
        this.rule.controllingObjectSharedToFieldAPIName = event.detail;
        this.fireEventWithRule();
    }
    handleShareWithChange(event) {
        //console.log('sharewith change');
        this.rule.shareWith = event.detail;
        this.fireEventWithRule();
    }
    handleShareFieldTypeChange(event) {
        this.rule.controllingObjectSharedToFieldType = event.detail;
        this.fireEventWithRule();
    }

    //--------------------- Event handlers for Access component ---------------------// 

    handleAccessLevelChange(event) {
        this.rule.accessLevel = event.detail;
        this.fireEventWithRule();
    }

    handleContactAccessChange(event) {
        this.rule.contactAccess = event.detail;
        this.fireEventWithRule();
    }
    handleCaseAccessChange(event) {
        this.rule.caseAccess = event.detail;
        //console.log('case access change: '+JSON.stringify(event.detail));
        this.fireEventWithRule();
    }
    handleOpportunityAccessChange(event) {
        this.rule.opportunityAccess = event.detail;
        this.fireEventWithRule();
    }

    handleSharingReasonChange(event) {
        this.rule.sharingReason = event.detail;
        this.fireEventWithRule();
    }

    
    // Called to trigger a toast message including a system error
    showError(error, toastTitle) {
        //console.log('Error received: ' + JSON.stringify(error));

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