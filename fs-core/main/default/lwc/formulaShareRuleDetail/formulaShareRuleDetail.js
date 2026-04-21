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
import getSpecificRule from '@salesforce/apex/FormulaShareRulesQueriesController.getSpecificRule';
import versionSupportsRelatedRules from '@salesforce/apex/FormulaShareInjectionService.versionSupportsRelatedRules';

export default class FormulaShareRuleDetail extends LightningElement {
    
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
            this.rule = data || {};
            if(this.rule && this.rule.type === 'standard' && !this.rule.mdMappingType) {
                this.savedRuleType = 'standard';
            }
            else {
                this.savedRuleType = 'related';
            }
            if(this.rule) {
                this.shareWithDefaultTeam = this.rule.shareWith === 'Default Account Teams of Users' || this.rule.shareWith === 'Default Opportunity Teams of Users';
                this.shareWithTeams = this.rule.shareWith === 'Teams';
            }

            // Build conditions map from the loaded rule data
            this.buildConditionsMapFromRule();

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
        if(!this.rule) {
            return null;
        }
        if(this.rule.mdMappingType) {
            return this.rule.mdMappingType;
        }
        else {
            return this.rule.controllingObjectApiName;
        }
    }
    get shareField() {
        if(!this.rule) {
            return null;
        }
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
        // Clear conditions when shared object changes (relationship will be replaced, skip mutating old nodes)
        this.showConditionsPanel = false;
        this.clearConditions(true);

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
        // Clear conditions when the relationship chain changes (relationship will be replaced, skip mutating old nodes)
        this.showConditionsPanel = false;
        this.clearConditions(true);

        this.rule.relationship = event.detail.relationship;

        this.rule.controllingObjectApiName = event.detail.controllingObjectApiName;
        const lastRel = this.getLastRelationship(event.detail.relationship);

        // If CMDT relationship, set shared to field to the selected match field on the last custom object
        if(lastRel.isCmdtRelationship === true) {
            this.rule.controllingObjectSharedToFieldAPIName = lastRel.objectMappingMatchField;
            this.rule.mdMappingType = lastRel.thisObjectApiName;
            this.rule.mdMappingMatchField = lastRel.cmdtMappingMatchField;
            this.rule.mdMappingSharedToField = null;
        }

        // If not CMDT, clear all CMDT-specific fields and controllingObjectSharedToFieldAPIName
        else {
            this.rule.mdMappingType = null;
            this.rule.mdMappingMatchField = null;
            this.rule.mdMappingSharedToField = null;
            this.rule.controllingObjectSharedToFieldAPIName = null;
            this.rule.behaviourMdMatchFieldMismatch = null;
            this.rule.fallbackMdMatchFieldMismatch = null;            
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
    shareWithTeams = false;
    handleShareWithChange(event) {
        //console.log('sharewith change');
        this.rule.shareWith = event.detail;
        this.shareWithDefaultTeam = this.rule.shareWith === 'Default Account Teams of Users' || this.rule.shareWith === 'Default Opportunity Teams of Users';
        this.shareWithTeams = this.rule.shareWith === 'Teams';
        
        // Clear userFieldForMatching when switching away from Users or from matching mode
        if(this.rule.shareWith !== 'Users' && this.rule.shareWith !== 'Users with Matching Field Value') {
            this.rule.userFieldForMatching = null;
        }

        // Clear team mapping fields when switching away from Teams
        if(!this.shareWithTeams) {
            this.rule.teamMappingDeveloperName = null;
        }
        
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

    handleMismatchFieldChange(event) {
        this.rule[event.detail.fieldName] = event.detail.value;
//        console.log('***Set property: '+event.detail.fieldName+' to: '+event.detail.value);
        
        this.fireEventWithRule();
    }

    handleUserFieldForMatchingChange(event) {
        this.rule.userFieldForMatching = event.detail;
        console.log('***Set userFieldForMatching: '+event.detail);
        this.fireEventWithRule();
    }

    handleUserSharingModeChange(event) {
        // When switching from matching to specified mode, clear userFieldForMatching
        if(event.detail !== 'matching') {
            this.rule.userFieldForMatching = null;
        }
        // Note: shareWith will be updated via handleShareWithChange event
        this.fireEventWithRule();
    }

    handleFilterChange(event) {
        this.rule.filterFieldApiName = event.detail.filterFieldApiName;
        this.rule.filterOperator     = event.detail.filterOperator;
        this.rule.filterValue        = event.detail.filterValue;
        this.fireEventWithRule();
    }

    // ─── Conditions panel management ──────────────────────────────────────────

    showConditionsPanel = false;
    @track conditionsMap = {};

    handleToggleConditions() {
        this.showConditionsPanel = !this.showConditionsPanel;
    }

    // Called when the conditions component removes its last condition
    handleConditionsClose() {
        this.showConditionsPanel = false;
        this.clearConditions();
        this.fireEventWithRule();
    }

    // Reset all condition state
    // skipRelationship: pass true when the relationship itself is also being replaced
    // (avoids replacing old reactive proxy nodes during event dispatch)
    clearConditions(skipRelationship = false) {
        this.conditionsMap = {};
        if(this.rule) {
            this.rule.conditionsMap = {};
            this.rule.filterFieldApiName = null;
            this.rule.filterOperator = null;
            this.rule.filterValue = null;
            this.rule.filterContracted = null;
            if(!skipRelationship && this.rule.relationship) {
                const seenCounts = this._buildSeenCounts();
                this.rule.relationship = this._relationshipWithConditions(this.rule.relationship, {}, 0, seenCounts);
            }
        }
    }

    // Build list of objects in the rule for the conditions component
    // Each object has: {apiName, label, depth}
    get ruleObjectsForConditions() {
        const objects = [];
        if(!this.rule || !this.rule.objectSharedAPIName) {
            return objects;
        }

        // Always include the shared object
        objects.push({
            apiName: this.rule.objectSharedAPIName,
            label: this.rule.objectSharedLabel || this.rule.objectSharedAPIName,
            depth: 0
        });

        // Walk the relationship chain to collect all related objects
        if(this.rule.relationship && this.rule.relationship.nextRelationship) {
            this.collectRelationshipObjects(this.rule.relationship.nextRelationship, 1, objects);
        }

        return objects;
    }

    collectRelationshipObjects(rel, depth, objects) {
        if(!rel || rel.isCmdtRelationship) return;
        objects.push({
            apiName: rel.thisObjectApiName,
            label: rel.thisObjectLabel || rel.thisObjectApiName,
            depth: depth
        });
        if(rel.nextRelationship) {
            this.collectRelationshipObjects(rel.nextRelationship, depth + 1, objects);
        }
    }

    // When conditions change, update the rule's filter properties
    // The conditionsMap keys use ':depth' suffix for duplicate object API names (e.g. 'Account:0', 'Account:1')
    handleConditionsChange(event) {
        const newConditionsMap = event.detail.conditionsMap;
        this.conditionsMap = newConditionsMap;

        // rule.filterContracted / filterFieldApiName / filterOperator / filterValue must hold the
        // CONTROLLING OBJECT's filter string.  For standard rules the controlling object is the
        // shared object, so they coincide.  For cross-object rules the controlling object is the
        // deepest related object.  Apex's getMetadataRule syncs rule.filterContracted back onto
        // the controlling relationship node before writing CMDT fields, so if this is wrong the
        // node's correctly-set filterContracted gets overwritten with the wrong value.
        // The controlling object is the LAST (deepest) entry in ruleObjectsForConditions.
        const seenCounts = this._buildSeenCounts();
        const allObjects = this.ruleObjectsForConditions;
        const controllingObjInfo = [...allObjects].reverse().find(o => o.apiName === this.rule.controllingObjectApiName);
        const controllingKey = this._conditionsMapKey(this.rule.controllingObjectApiName, controllingObjInfo ? controllingObjInfo.depth : 0, seenCounts);
        const controllingObjFilter = newConditionsMap[controllingKey] ?? null;
        if(controllingObjFilter) {
            const parts = controllingObjFilter.split('||')[0].split('|');
            this.rule.filterFieldApiName = parts[0] || null;
            this.rule.filterOperator = parts[1] || null;
            this.rule.filterValue = parts.length >= 3 ? parts[2] : null;
        } else {
            this.rule.filterFieldApiName = null;
            this.rule.filterOperator = null;
            this.rule.filterValue = null;
        }
        this.rule.filterContracted = controllingObjFilter;

        // Store the full conditions map on the rule for serialization
        this.rule.conditionsMap = newConditionsMap;

        // Rebuild relationship tree with filter conditions applied and reassign so LWC
        // propagates the new reference through @api chains to child components.
        if(this.rule.relationship) {
            this.rule.relationship = this._relationshipWithConditions(this.rule.relationship, newConditionsMap, 0, seenCounts);
        }

        this.fireEventWithRule();
    }

    // Returns a new relationship tree (immutable update) with filter conditions stamped onto
    // each node from the conditions map.  Returning a new object reference ensures LWC
    // propagates the change through @api bindings to child components.
    // depth matches the depth values in ruleObjectsForConditions (shared object = 0).
    _relationshipWithConditions(rel, conditionsMap, depth, seenCounts) {
        if(!rel) return rel;

        const key = this._conditionsMapKey(rel.thisObjectApiName, depth, seenCounts);
        const filter = conditionsMap[key] ?? null;

        let filterFieldApiName = null;
        let filterOperator = null;
        let filterValue = null;
        if(filter) {
            // Parse first condition (for backwards compat with single-filter properties)
            const parts = filter.split('||')[0].split('|');
            filterFieldApiName = parts[0] || null;
            filterOperator = parts[1] || null;
            filterValue = parts.length >= 3 ? parts[2] : null;
        }

        const updatedNext = rel.nextRelationship
            ? this._relationshipWithConditions(rel.nextRelationship, conditionsMap, depth + 1, seenCounts)
            : rel.nextRelationship;

        return {
            ...rel,
            filterFieldApiName,
            filterOperator,
            filterValue,
            filterContracted: filter,
            nextRelationship: updatedNext
        };
    }

    // Populate conditionsMap from the rule when loading a saved rule.
    // Keys use ':depth' suffix for duplicate object API names (mirrors buildConditionsMap in conditions component).
    buildConditionsMapFromRule() {
        const cm = {};
        if(!this.rule) {
            this.conditionsMap = cm;
            this.showConditionsPanel = false;
            return;
        }

        const seenCounts = this._buildSeenCounts();

        // Shared object filter lives on the level-0 relationship node (rule.relationship.filterContracted),
        // NOT on rule.filterContracted — for cross-object rules, rule.filterContracted holds the
        // *controlling* (deepest) object's filter instead.  Fall back to individual properties for
        // older saved rules that pre-date the filterContracted field.
        const sharedRelFilter = this.rule.relationship && this.rule.relationship.filterContracted;
        const sharedKey = this.rule.objectSharedAPIName
            ? this._conditionsMapKey(this.rule.objectSharedAPIName, 0, seenCounts)
            : null;
        if(sharedKey && sharedRelFilter) {
            cm[sharedKey] = sharedRelFilter;
        } else if(sharedKey && this.rule.filterFieldApiName &&
                  this.rule.controllingObjectApiName === this.rule.objectSharedAPIName) {
            // Standard rule only: filterFieldApiName is the shared-object filter
            cm[sharedKey] =
                this.rule.filterFieldApiName + '|' + this.rule.filterOperator +
                (this.rule.filterValue ? '|' + this.rule.filterValue : '');
        }

        // Walk relationship chain
        if(this.rule.relationship && this.rule.relationship.nextRelationship) {
            this.buildConditionsFromRelationship(this.rule.relationship.nextRelationship, cm, 1, seenCounts);
        }

        this.conditionsMap = cm;
        this.showConditionsPanel = Object.keys(cm).length > 0;
    }

    buildConditionsFromRelationship(rel, cm, depth, seenCounts) {
        if(!rel || rel.isCmdtRelationship) return;

        const key = this._conditionsMapKey(rel.thisObjectApiName, depth, seenCounts);
        // Check for filterContracted first (full multi-condition string), fall back to individual properties
        if(rel.filterContracted) {
            cm[key] = rel.filterContracted;
        } else if(rel.filterFieldApiName) {
            cm[key] = 
                rel.filterFieldApiName + '|' + rel.filterOperator + 
                (rel.filterValue ? '|' + rel.filterValue : '');
        }

        if(rel.nextRelationship) {
            this.buildConditionsFromRelationship(rel.nextRelationship, cm, depth + 1, seenCounts);
        }
    }

    // Returns 'apiName:depth' when that apiName appears more than once in the relationship chain,
    // otherwise returns plain 'apiName'.  Mirrors the key format used by buildObjectOptions in
    // the conditions component.
    _conditionsMapKey(apiName, depth, seenCounts) {
        return seenCounts[apiName] > 1 ? apiName + ':' + depth : apiName;
    }

    // Builds a map of { apiName → count } for all objects in the rule relationship chain.
    _buildSeenCounts() {
        const seen = {};
        const objects = this.ruleObjectsForConditions;
        for(const obj of objects) {
            seen[obj.apiName] = (seen[obj.apiName] || 0) + 1;
        }
        return seen;
    }

    // ─── End conditions panel management ──────────────────────────────────────


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


    //-------- Event handlers for Team Mapping component --------// 

    handleTeamMappingChange(event) {
        this.rule.teamMappingDeveloperName = event.detail;
        this.fireEventWithRule();
    }

    handleTeamFieldChange(event) {
        // When the team mapping component changes the field, update the controlling object field
        if(event.detail.fieldApiName) {
            this.rule.controllingObjectSharedToFieldAPIName = event.detail.fieldApiName;
            this.rule.controllingObjectSharedToFieldType = event.detail.fieldType;
            // Also update sharedToFieldApiName on the relationship leaf node so it's persisted to metadata
            this.rule.relationship = this.getRelationshipWithNewControllingDetails(this.rule.relationship);
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