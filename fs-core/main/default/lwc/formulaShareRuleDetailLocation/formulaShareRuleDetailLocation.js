import { LightningElement, track, api, wire } from 'lwc';
import getChildRelationships from '@salesforce/apex/FormulaShareRuleDetailController.getChildRelationships';

export default class FormulaShareRuleDetailLocation extends LightningElement {

//    @api ruleType;
//    @api sharedObject;
//    @api sharedObjectApiName;
//    @api relatedObjectApiName;

    @api
    get relationship() {
        return this._relationship;
    }
    set relationship(value) {
        this._relationship = value;
        this.setSelectedValues();
    }
    @track _relationship;


    relatedObjectSelected;
    parentObjectSelected;
    setSelectedValues() {
        var nextRel = this._relationship.nextRelationship;
        if(this._relationship.sharedToFieldApiName) {
            this.setSelectedLocation('thisObject');
        }
        else if(nextRel) {
            if(nextRel.lookupFromPrevObjectApiName) {
                this.parentObjectSelected = nextRel.thisObjectApiName + '|' + nextRel.lookupFromPrevObjectApiName;
                this.setSelectedLocation('parentObject');
            }
            else if(nextRel.lookupToPrevObjectApiName) {
                this.relatedObjectSelected = nextRel.thisObjectApiName + '|' + nextRel.lookupToPrevObjectApiName;
                console.log('this.relatedObjectSelected: '+this.relatedObjectSelected);
                this.setSelectedLocation('relatedObject');
            }
        }
    }

    fieldIsOnThisObject;
    fieldIsOnParentObject;
    fieldIsOnRelatedObject;

    get isfieldOnThisObject() {
        return this.fieldIsOnThisObject ? true : false;
    }
//
//    get fieldIsOnThisObject() {
//        if(!this._relationship.nextRelationship || this.selectedLocation === 'thisObject') {
//            return true;
//        }
//        else {
//            return false;
//        }
//    }
//    get fieldIsOnParentObject() {
//        //console.log('checking whether std ',this.ruleType);
//        if(this._relationship.nextRelationship.lookupFromPrevObjectApiName || this.selectedLocation === 'parentObject') {
//            return true;
//        }
//        else {
//            return false;
//        }
//    }
//    get fieldIsOnRelatedObject() {
//        //console.log('checking whether std ',this.ruleType);
//        if((this._relationship.nextRelationship && this._relationship.nextRelationship.lookupToPrevObjectApiName)
//            || this.selectedLocation === 'relatedObject') {
//            return true;
//        }
//        else {
//            return false;
//        }
//    }
//

    selectedLocation;
    handleSelectedThisObject() {
        this.setSelectedLocation('thisObject');
        this._relationship.nextRelationship = false;
        this.fireRelationshipChange(this._relationship.thisObjectApiName);
    }
    handleSelectedParentObject() {
        this.setSelectedLocation('parentObject');
        this._relationship.nextRelationship = false;
        this.fireRelationshipChange(null);
    }
    handleSelectedRelatedObject() {
        this.setSelectedLocation('relatedObject');
        this._relationship.nextRelationship = false;
        this.fireRelationshipChange(null);
    }

    setSelectedLocation(selectedLocation) {
        switch (selectedLocation) {
            case 'thisObject':
                this.fieldIsOnThisObject = true;
                this.fieldIsOnParentObject = false;
                this.fieldIsOnRelatedObject = false;
                break;
            case 'parentObject':
                this.fieldIsOnThisObject = false;
                this.fieldIsOnParentObject = true;
                this.fieldIsOnRelatedObject = false;
                break;
            case 'relatedObject':
                this.fieldIsOnThisObject = false;
                this.fieldIsOnParentObject = false;
                this.fieldIsOnRelatedObject = true;
                break;
        }
    }

    fireRelationshipChange(controllingObjectApiName) {
        const relationshipDetails = {
            relationship: this._relationship,
            controllingObjectApiName: controllingObjectApiName
        };
        const selection = new CustomEvent('ruletypechange', {
            detail: relationshipDetails
        });
        this.dispatchEvent(selection);
    }

    handleRelationshipChange(event) {
        console.log('Captured relationship change in child component: '+JSON.stringify(event.detail.relationship));
        this._relationship.nextRelationship = event.detail.relationship;
        this.fireRelationshipChange(event.detail.controllingObjectApiName);
    }


    @track relatedObjectOptions;
    @wire(getChildRelationships, { parentObjectAPIName : '$_relationship.thisObjectApiName'} )
        childRelationships({ error, data }) {
            if(data) {
                //console.log('getting related for '+this.sharedObjectApiName);
                
                let relatedObjList = [];
                data.forEach((obj) => {
                    const option = {
                        label: obj.childObjectApiName + ' (related by ' + obj.childFieldApiName + ')',
                        value: obj.childObjectApiName + '|' + obj.childFieldApiName
                    };
                    console.log('Option value: '+obj.childObjectApiName + '|' + obj.childFieldApiName);
                    relatedObjList.push(option);
                });

                // Manage enabling / disabling related object option
                var relatedOptionDisabled = this.template.querySelectorAll('input')[1].disabled;
                //console.log('relatedOptionDisabled ', relatedOptionDisabled);
                if(relatedObjList.length === 0 && !relatedOptionDisabled) {
                    this.template.querySelectorAll('input')[1].disabled = true;
                }
                else if(relatedObjList.length > 0 && relatedOptionDisabled) {
                    this.template.querySelectorAll('input')[1].disabled = false;
                }

                this.relatedObjectOptions = relatedObjList;
                this.setSelectedValues();
            }
        }

    getRelationshipSelected() {
        var splitArray = this.relatedObjectSelected.split("|");
        return {objectApiName: splitArray[0], relationshipFieldApiName: splitArray[1]};
    }
    
    handleRelatedObjectChange(event) {

        // Set relationship object based on selected field
        this.relatedObjectSelected = event.detail.value;
        var relationshipSelected = this.getRelationshipSelected();
        this._relationship.nextRelationship = {
            thisObjectApiName : relationshipSelected.objectApiName,
            lookupToPrevObjectApiName : relationshipSelected.relationshipFieldApiName 
        };

        this.fireRelationshipChange(relationshipSelected);

//        this.relatedObjectSelected = event.detail.value;
//        this.relatedObjectApiName = this.getRelationshipSelected().objectApiName;
//        //console.log('changed to ', this.relatedObjectApiName);
//
//        const relationshipDetail = {
//            relatedObjectSelected: this.relatedObjectSelected,
//            relatedObjectApiName: this.relatedObjectApiName
//        };
//
//        const selection = new CustomEvent('relatedobjectchange', {
//            detail: relationshipDetail
//        });
//        this.dispatchEvent(selection);
    }

    // Custom validation to check that related object selected when needed
    @api
    checkValidity() {
        //console.log('checking location valid');
        var relatedObjCmp = this.template.querySelector('lightning-combobox');
        //console.log('relatedObjCmp '+relatedObjCmp);
        //console.log('this.relatedObjectSelected '+this.relatedObjectSelected );
        if(relatedObjCmp && !this.relatedObjectSelected) {
            //console.log('checking location valid');
            relatedObjCmp.setCustomValidity('Complete this field.');
            relatedObjCmp.reportValidity();
            return false;
        }
        else return true;
    }
    
}