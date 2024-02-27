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
import { ruleDetailLocation, ruleDetailTeamAccess } from 'c/formulaShareLWCInjectionService';
import getSpecificRule from '@salesforce/apex/FormulaShareRulesQueriesController.getSpecificRule';
import versionSupportsRelatedRules from '@salesforce/apex/FormulaShareInjectionService.versionSupportsRelatedRules';

export default class FormulaShareRuleDetail extends LightningElement {

    // Components allowing overrides initialised dynamically
    ruleDetailLocationConstructor;
    ruleDetailTeamAccessConstructor;
    connectedCallback() {
        const concreteRuleDetailLocation = ruleDetailLocation();
        if(concreteRuleDetailLocation) {
            import(concreteRuleDetailLocation)
                .then(({ default: ctor }) => (this.ruleDetailLocationConstructor = ctor))
                .catch((err) => console.log("Error importing ruleDetailLocation component"));
        }

        const concreteRuleDetailTeamAccess = ruleDetailTeamAccess();
        if(concreteRuleDetailTeamAccess) {
            import(concreteRuleDetailTeamAccess)
                .then(({ default: ctor }) => (this.ruleDetailTeamAccessConstructor = ctor))
                .catch((err) => console.log("Error importing ruleDetailTeamAccess component"));
        }
    }
    
    @api
    get ruleId() {
        return this._ruleId;
    }
    set ruleId(value) {
        this._ruleId = value;

        //console.log('Set rule from id: '+value);
        this.populateRule();
    }
    _ruleId;

    @api isEdit;
    @track sharedObjectDetail;

    @api
    checkValidity() {
        //console.log('checking validity');
        const componentsValid = [
            this.template.querySelector('c-formula-share-rule-detail-name-label'),
            this.template.querySelector('c-formula-share-rule-detail-location'),
            this.template.querySelector('c-formula-share-rule-detail-field'),
            this.template.querySelector('c-formula-share-rule-detail-access')
        ].reduce((validSoFar, inputCmp) => {
            if(inputCmp) {
                return validSoFar && inputCmp.checkValidity();
            }
            else {
                return validSoFar;
            }
        }, true);
        return componentsValid;
    }

    @track rule = {};

    @wire(versionSupportsRelatedRules) supportsRelated;    

    // Fixed test data for offline component updates
    //    rule = {"accessLevel":"Read","active":true,"caseAccess":"None","contactAccess":"None","controllingObjectApiName":"sdfs__Programme_Support_Officer__c","controllingObjectLabel":"Programme Support Officer","controllingObjectSharedToFieldAPIName":"sdfs__User__c","controllingObjectSharedToFieldLabel":"User","controllingObjectSharedToFieldToken":"01I26000000cvxA.00N260000063Lub","controllingObjectSharedToFieldType":"Id","developerName":"Share_Countries_with_Prog_Support_Office","label":"Share Countries with Prog Support Office","objectSharedAPIName":"sdfs__Country__c","objectSharedLabel":"Country","opportunityAccess":"None","relationship":{"nextRelationship":{"lookupToPrevObjectApiName":"sdfs__Country__c","nextRelationship":{"lookupToPrevObjectApiName":"sdfs__Programme__c","sharedToFieldApiName":"sdfs__User__c","thisObjectApiName":"sdfs__Programme_Support_Officer__c"},"thisObjectApiName":"sdfs__Programme__c"},"thisObjectApiName":"sdfs__Country__c"},"ruleId":"m00260000000nmlAAA","shareWith":"Users","type":"descendant"};

    savedRuleType;
    populateRule() {
        //console.log('_ruleId '+this._ruleid);
        getSpecificRule({ ruleId : this._ruleId })
        .then((data) => {
            //console.log('retrieved rule: '+JSON.stringify(data));
            this.rule = data;
            this.savedRuleType = this.rule.type;
            this.shareWithDefaultTeam = this.rule.shareWith === 'Default Account Teams of Users' || this.rule.shareWith === 'Default Opportunity Teams of Users';
            this.fireEventWithRule();
        });
    }
    
    // Fire event with all details in rule
    fireEventWithRule() {
        //console.log('firing: '+JSON.stringify(this.rule, null, 2));
        const evt = new CustomEvent('ruledetail', { detail : this.rule });
        this.dispatchEvent(evt);
    }

    // Getters for ruleDetailField component - return CMDT type and field if set, otherwise SObject type and field
    get objectWithShareField() {
        if(this.rule.mdMappingType) {
            return this.rule.mdMappingType;
        }
        else {
            return this.rule.controllingObjectApiName;
        }
    }
    get shareField() {
        if(this.rule.mdMappingType) {
            return this.rule.mdMappingSharedToField;
        }
        else {
            return this.rule.controllingObjectSharedToFieldAPIName;
        }
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

        // Fire event for create component to enable save button
        const evt = new CustomEvent('enablesave');
        this.dispatchEvent(evt);

        this.rule.objectSharedAPIName = this.sharedObjectDetail.objectApiName;
        this.fireEventWithRule();
    }

    // Propogate preventing save button to create rule component
    handlePreventSave(event) {
        const evt = new CustomEvent('preventsave');
        this.dispatchEvent(evt);
    }

    selectedLocation;
    handleSharedObjectChange(event) {
        
        // On change of shared object, assume that rule will be standard
        // Default object with share field to be the selected object (ensures field list populates)
        this.rule.controllingObjectApiName = event.detail.objectApiName;
        this.rule.objectSharedLabel = event.detail.objectLabel;

        this.rule.relationship = {thisObjectApiName: this.rule.controllingObjectApiName, thisObjectLabel: event.detail.objectLabel};

        this.selectedLocation = 'thisObject';
        this.disableEnableShareFieldSelect();

        // Clear any object specific fields
        this.rule.controllingObjectSharedToFieldAPIName = null;
        this.rule.contactAccess = null;
        this.rule.caseAccess = null;
        this.rule.opportunityAccess = null;

        //console.log('Cleared values after shared obj change. Current rule: '+JSON.stringify(this.rule));

        this.handleSetSharedObjectDetail(event);    // Capture object details
    }

    // Capture and cascade object's OWD passed up by ruleDetailSharedObject component
    @track accountRelatedOwd;
    handleSetAccountRelatedOwd(event) {
        this.accountRelatedOwd = event.detail;
    }

    disableShareField = false;
    disableEnableShareFieldSelect() {
        if(this.selectedLocation === 'relatedObject' && !this.rule.relationship.nextRelationship) {
            this.disableShareField = true;
        }
        else {
            this.disableShareField = false;
        }
    }


    //--------------------- Event handlers for Location component ---------------------// 

    // Replace with handlers for generic change of relationship
    handleRelationshipChange(event) {

        this.rule.relationship = event.detail.relationship;

        this.rule.controllingObjectApiName = event.detail.controllingObjectApiName;
        const lastRel = this.getLastRelationship(event.detail.relationship);
        //console.log('Last rel: '+JSON.stringify(lastRel));

        // If CMDT relationship, set shared to field to the selected match field on the last custom object
        if(lastRel.isCmdtRelationship === true) {
            this.rule.controllingObjectSharedToFieldAPIName = lastRel.objectMappingMatchField;
            this.rule.mdMappingType = lastRel.thisObjectApiName;
            this.rule.mdMappingMatchField = lastRel.cmdtMappingMatchField;
            this.rule.mdMappingSharedToField = null;
        }

        // If not CMDT, clear all CMDT-specific fields
        else {
            this.rule.mdMappingType = null;
            this.rule.mdMappingMatchField = null;
            this.rule.mdMappingSharedToField = null;
        }

        this.selectedLocation = event.detail.selectedLocation;
        this.disableEnableShareFieldSelect();

        this.fireEventWithRule();
    }

    // Use iterative method to navigate to bottom object, and update each level using spread
    getLastRelationship(rel) {
        if(rel && rel.nextRelationship) {
            return this.getLastRelationship(rel.nextRelationship);
        }
        else return rel;
    }
    //--------------------- Event handlers for Field component ---------------------// 

    handleShareFieldChange(event) {
        if(this.rule.mdMappingType) {
            this.rule.mdMappingSharedToField = event.detail;
        }
        else {
            this.rule.controllingObjectSharedToFieldAPIName = event.detail;
            // Also set field in controlling object in relationship (this is referenced in rule DML)
            this.rule.relationship = this.getRelationshipWithNewControllingDetails(this.rule.relationship);
            //console.log('Updated relationship after field change: '+JSON.stringify(this.rule.relationship));
        }
        this.fireEventWithRule();
    }

    shareWithDefaultTeam = false;
    handleShareWithChange(event) {
        //console.log('sharewith change');
        this.rule.shareWith = event.detail;
        this.shareWithDefaultTeam = this.rule.shareWith === 'Default Account Teams of Users' || this.rule.shareWith === 'Default Opportunity Teams of Users';
        this.fireEventWithRule();
    }
    handleShareFieldTypeChange(event) {
        this.rule.controllingObjectSharedToFieldType = event.detail;
        this.fireEventWithRule();
    }

    // Use iterative method to navigate to bottom object, and update each level using spread
    getRelationshipWithNewControllingDetails(rel) {

        // If relationship exists and there's another embedded, iteratively build the relationship
        if(rel && rel.nextRelationship) {
            return {...rel, nextRelationship: this.getRelationshipWithNewControllingDetails(rel.nextRelationship)};
        }

        // Otherwise (standard rules and the final relationship) return the final controlling object
        else {
            let lastRel = {
                thisObjectApiName: this.rule.controllingObjectApiName,
                thisObjectLabel: this.rule.controllingObjectLabel,
                sharedToFieldApiName: this.rule.controllingObjectSharedToFieldAPIName
            }

            // If a relationship was set, also ensure we capture label and lookups
            if(rel) {
                lastRel.thisObjectLabel = rel.thisObjectLabel;
                lastRel.lookupToPrevObjectApiName = rel.lookupToPrevObjectApiName;
                lastRel.lookupFromPrevObjectApiName = rel.lookupFromPrevObjectApiName;
                lastRel.isCmdtRelationship = rel.isCmdtRelationship;
                lastRel.objectMappingMatchField = rel.objectMappingMatchField;
                lastRel.cmdtMappingMatchField = rel.cmdtMappingMatchField;
            }

            return lastRel;
        }
    }


    //-------- Event handlers for Account / Opp Default Team access component --------// 

    handleTeamAccessUpdate(event) {
        
        switch (event.detail.type) {
            case 'accessForTeam':
                //console.log('contact access updated');
                this.rule.accessForTeam = event.detail.setting;
                break;
            case 'accessForOwnerOfTeamsUserIsOn':
                this.rule.accessForOwnerOfTeamsUserIsOn = event.detail.setting;
                break;
            case 'accessForTeamComembers':
                this.rule.accessForTeamComembers = event.detail.setting;
        }
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

    // Only used for for debugging
    get ruleDetail() {
        return JSON.stringify(this.rule);
    }
}