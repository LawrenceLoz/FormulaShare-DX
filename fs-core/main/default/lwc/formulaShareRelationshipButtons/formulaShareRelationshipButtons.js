import { LightningElement, api, wire } from 'lwc';
import getParentRelationships from '@salesforce/apex/FormulaShareRuleDetailController.getParentRelationships';
import getChildRelationships from '@salesforce/apex/FormulaShareRuleDetailController.getChildRelationships';

export default class FormulaShareRelationshipButtons extends LightningElement {
    
    @api objectApiName;
    @api objectLabel;
    @api
    get traverse() {
        return _traverse;
    }
    set traverse(value) {
        this._traverse = value;
        this.setButtonDivProperties('traverseSetter');
    }
    _traverse;

    firstRenderCall = true;
    renderedCallback() {
        this.setButtonDivProperties('renderedCallback');
    }

    setButtonDivProperties(source) {
        var parentButtonDiv = this.template.querySelector('div[id*="parentButtonDiv"]');
        var childButtonDiv  = this.template.querySelector('div[id*="childButtonDiv"]');

        // Continue if traverse populated and component rendered for the 
        if(this._traverse && parentButtonDiv && childButtonDiv && 
            (this.firstRenderCall || source === 'traverseSetter')) {
            this.firstRenderCall = false;

            // Get width of buttons and set CSS variables. Used for message position and animation
            var parentButtonWidth = parentButtonDiv.clientWidth;
            var childButtonWidth  = childButtonDiv.clientWidth;
            parentButtonDiv.style.setProperty('--parent-button-width', parentButtonWidth);
            childButtonDiv.style.setProperty('--child-button-width', childButtonWidth);
            this.checkAndDisableButtons();
        }

    }

    parentButtonDisabled = false;
    childButtonDisabled = false;
    checkAndDisableButtons() {

        // If we're not able to change traverse direction again, disable relevant button
        if(this._traverse.sequence === 2) {
            if(this._traverse.direction === 'childToParent') {
                this.disableChild('Direction of consecutive relationships can only be changed once');
            }
            else {
                this.disableParent('Direction of consecutive relationships can only be changed once');
            }
        }

        // If we've reached maximum depth, disable relevant button
        if(this._traverse.depth === 5) {
            if(this._traverse.direction === 'childToParent') {
                this.disableParent('Only 5 consecutive child to parent relationships are supported');
            }
            else {
                this.disableChild('Only 5 consecutive parent to child relationships are supported');
            }
        }
    }

    // Set CSS classes and variables to disable buttons with appropriate messages
    parentButtonClasses = 'slideDownButton';
    parentButtonMessage;
    disableParent(message) {
        this.parentButtonDisabled = true;
        this.parentButtonClasses += ' disabledParent';
        this.parentButtonMessage = message;
    }
    childButtonClasses = 'slideDownButton';
    childButtonMessage;
    disableChild(message) {
        this.childButtonDisabled = true;
        this.childButtonClasses += ' disabledChild';
        this.childButtonMessage = message;
    }

    // Getters for button labels
    get parentLabel() {
        return 'Parent of '+ this.objectLabel;
    }
    get childLabel() {
        return 'Child of '+ this.objectLabel;
    }
    

    // Retrieve all child relationships
    objectNameToLabelMap = new Map();
    childObjectOptions;
    @wire(getChildRelationships, { parentObjectAPIName : '$objectApiName'} )
    childRelationships({ error, data }) {
        if(data) {
            if(Object.keys(data).length === 0) {
                this.disableChild(this.objectLabel + ' does not have any child objects');
            }
            else {
                this.childObjectOptions = this.buildRelatedObjList(data);
            }
        }
    }

    // Retrieve all parent relationships
    parentObjectOptions;
    @wire(getParentRelationships, { childObjectAPIName : '$objectApiName'} )
    parentRelationships({ error, data }) {
        if(data) {
            if(Object.keys(data).length === 0) {
                this.disableParent(this.objectLabel + ' does not have any parent objects');
            }
            else {
                this.parentObjectOptions = this.buildRelatedObjList(data);
            }
        }
    }

    // Constructs array of options for parent / child picklists
    buildRelatedObjList(data) {
        let relatedObjList = [];

        data.forEach((obj) => {
            const option = {
                label: obj.relatedObjectLabel + ' (related by ' + obj.relatedFieldApiName + ')',
                value: obj.relatedObjectApiName + '|' + obj.relatedFieldApiName
            };
            relatedObjList.push(option);

            this.objectNameToLabelMap.set(obj.relatedObjectApiName, obj.relatedObjectLabel);
        });

        return relatedObjList;
    }

    
    // Handle button selection
    showParentButton = true;
    showChildButton = true;
    showTwoButtons = true;
    typeSelected;
    relatedObjectSelected;
    relatedObjectOptions;

    handleSelectedParent() {
        this.showChildButton = false;
        this.showTwoButtons = false;
        this.relatedObjectOptions = this.parentObjectOptions;
        this.parentButtonClasses = 'slideFromLeftButton';

        setTimeout(() => {
            this.typeSelected = 'parent';
        }, 500);
    }
    handleSelectedChild() {
        this.childButtonClasses = 'slideFromRightButton';
        this.showParentButton = false;
        this.showTwoButtons = false;
        this.relatedObjectOptions = this.childObjectOptions;

        setTimeout(() => {
            this.typeSelected = 'child';
        }, 500);
    }

    handleRelatedObjectChange(event) {

        // Set relationship object based on selected field
        var splitArray = event.detail.value.split("|");
        var thisObjectName = splitArray[0];
        var thisObjectLabel = this.objectNameToLabelMap.get(thisObjectName);

        const relationship = {
            relationshipType: this.typeSelected,
            objectApiName: splitArray[0],
            objectLabel: thisObjectLabel,
            relationshipFieldApiName: splitArray[1]
        };

        const selection = new CustomEvent('relationshipselected', {
            detail: relationship
        });
        this.dispatchEvent(selection);
    }

}