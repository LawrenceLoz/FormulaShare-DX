import { LightningElement, track, api, wire } from 'lwc';
import getChildRelationships from '@salesforce/apex/FormulaShareRuleDetailController.getChildRelationships';

export default class FormulaShareRuleDetailLocation extends LightningElement {

    @api ruleType;
    @api sharedObject;
    @api sharedObjectApiName;
    @api relatedObjectSelected;
    @api relatedObjectApiName;

    get isStandard() {
        if(this.ruleType === 'standard') {
            return true;
        }
        else {
            return false;
        }
    }
    get isChild() {
        console.log('checking whether std ',this.ruleType);
        if(this.ruleType === 'child') {
            return true;
        }
        else {
            return false;
        }
    }

    handleSelectedStandard() {
        this.ruleType = 'standard';
        this.fireRuleTypeChange();
    }
    handleSelectedChild() {
        this.ruleType = 'child';
        this.fireRuleTypeChange();
    }

    fireRuleTypeChange() {
        const selection = new CustomEvent('ruletypechange', {
            detail: this.ruleType
        });
        this.dispatchEvent(selection);
    }

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

                // Manage enabling / disabling related object option
                var relatedOptionDisabled = this.template.querySelectorAll('input')[1].disabled;
                console.log('relatedOptionDisabled ', relatedOptionDisabled);
                if(relatedObjList.length === 0 && !relatedOptionDisabled) {
                    this.template.querySelectorAll('input')[1].disabled = true;
                }
                else if(relatedObjList.length > 0 && relatedOptionDisabled) {
                    this.template.querySelectorAll('input')[1].disabled = false;
                }

                this.relatedObjectOptions = relatedObjList;
            }
        }

    getRelationshipSelected() {
        var splitArray = this.relatedObjectSelected.split("|");
        return {objectApiName: splitArray[0], relationshipFieldApiName: splitArray[1]};
    }
    
    handleRelatedObjectChange(event) {
        this.relatedObjectSelected = event.detail.value;
        this.relatedObjectApiName = this.getRelationshipSelected().objectApiName;
        console.log('changed to ', this.relatedObjectApiName);

        const relationshipDetail = {
            relatedObjectSelected: this.relatedObjectSelected,
            relatedObjectApiName: this.relatedObjectApiName
        };

        const selection = new CustomEvent('relatedobjectchange', {
            detail: relationshipDetail
        });
        this.dispatchEvent(selection);
    }

    // Custom validation to check that related object selected when needed
    @api
    checkValidity() {
        console.log('checking location valid');
        var relatedObjCmp = this.template.querySelector('lightning-combobox');
        console.log('relatedObjCmp '+relatedObjCmp);
        console.log('this.relatedObjectSelected '+this.relatedObjectSelected );
        if(relatedObjCmp && !this.relatedObjectSelected) {
            console.log('checking location valid');
            relatedObjCmp.setCustomValidity('Complete this field.');
            relatedObjCmp.reportValidity();
            return false;
        }
        else return true;
    }
    
}