import { LightningElement, api, track } from 'lwc';

export default class FormulaShareRelationshipSharedObject extends LightningElement {

    // On component load set label for shared object and populate next relationship JSON
    @api
    get relationship() {
        return this._relationship;
    }
    set relationship(value) {
        this._relationship = value;
        this.processNextRelationship(this._relationship.nextRelationship);
    }
    @track _relationship;

    @api isSharedObject;

    // Receives the current state and direction of the object hierarhcy
    @api
    get traverse() {
        return this._traverse;
    }
    set traverse(value) {
        this._traverse = value;
        this.setNextRelationshipTraverse();
    }
    _traverse;

    nextRelationship;
    objectFrameClasses;


    processNextRelationship(nextRel) {
        console.log('Relationship provided: '+JSON.stringify(nextRel));

        // Set object frame and object text css to baseline
        this.objectFrameClasses = 'slds-box';
        this.objectTextClasses = 'slds-text-heading_small objectLabel';

        // If another relationship from this object, set traverse, remove icon and add link line 
        if(nextRel) {
            this.nextRelationship = nextRel;
            this.setNextRelationshipTraverse();
            this.closeButtonsAndAddLink();
        }

        // Otherwise, set icon to display a plus button
        else {
            this.closeButtonsAndIconToPlus();
            this.objectTextClasses += ' slds-p-bottom_medium';
            this.objectFrameClasses += ' slds-p-bottom_medium';
            this.addBlueFrame();
        }
    }


    // Set traverse details to provide for the next object component
    nextRelationshipTraverse = {};
    setNextRelationshipTraverse() {

        // Process only if we have the traverse details, and we've set the next relationship
        if(this._traverse && this.nextRelationship) {
            console.log('this._traverse: '+JSON.stringify(this._traverse));

            // Set direction depending on next relationship
            if(this.nextRelationship.lookupFromPrevObjectApiName) {
                this.nextRelationshipTraverse['direction'] = 'childToParent';
            }
            else if(this.nextRelationship.lookupToPrevObjectApiName) {
                this.nextRelationshipTraverse['direction'] = 'parentToChild';
            }
    
            // Keep sequence and increment depth if direction of traverse is the same
            if(this._traverse['direction'] === this.nextRelationshipTraverse['direction']) {
                this.nextRelationshipTraverse['sequence'] = this._traverse['sequence'];
                this.nextRelationshipTraverse['depth'] = this._traverse['depth'] + 1;
            }
            // Otherwise increment sequence and reset depth
            else {
                this.nextRelationshipTraverse['sequence'] = this._traverse['sequence'] + 1;
                this.nextRelationshipTraverse['depth'] = 1;
            }
        }
    }
    

    // When relationship selected in dropdown, set details for next relationship
    handleRelationshipSelected(event) {
        var rel = {
            thisObjectApiName: event.detail.objectApiName,
            thisObjectLabel: event.detail.objectLabel
        };

        if(event.detail.relationshipType === 'parent') {
            rel['lookupFromPrevObjectApiName'] = event.detail.relationshipFieldApiName;
        }
        else {
            rel['lookupToPrevObjectApiName'] = event.detail.relationshipFieldApiName;
        }

        this.processNextRelationship(rel);
        this.fireRelationshipChange(event.detail.objectApiName);
    }

    // If relationship updated in child component, communicate to parent
    handleRelationshipChange(event) {
        console.log('Captured relationship change in child component: '+JSON.stringify(event.detail.relationship));
        this._relationship.nextRelationship = event.detail.relationship;
        this.fireRelationshipChange(event.detail.controllingObjectApiName);
    }

    // Fire event for parent component to be made aware of changes to relationship
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

    showButtons;
    iconClasses = 'baselineIconStyle plusIconStyle';
    iconType = 'plus';
    iconDisplayed = 'utility:add';
    iconTooltip = 'Add another relationship';
    iconVariant = 'inverse';
    handleIconClicked() {
        if(this.iconType === 'plus') {
            this.openButtonsAndIconToCross();
        }
        else if(this.iconType === 'cross') {
            this.closeButtonsAndIconToPlus();
            this.addBlueFrame();
        }
    }

    linkToNext;
    closeButtonsAndAddLink() {
        this.linkToNext = true;
        this.closeButtonsAndIconToPlus();
    }
    
    openButtonsAndIconToCross() {
        this.showButtons = true;
        this.iconDisplayed = 'utility:add';
        this.iconClasses = 'baselineIconStyle crossIconStyle rotate45Animated';
        this.iconTooltip = 'Cancel';
        this.iconVariant = '';
        this.iconType = 'cross';
        this.objectFrameClasses = 'slds-box slds-p-bottom_medium';
    }

    closeButtonsAndIconToPlus() {
        this.showButtons = false;
        this.iconDisplayed = 'utility:add';
        this.iconClasses = 'baselineIconStyle plusIconStyle';
        this.iconTooltip = 'Add another relationship';
        this.iconVariant = 'inverse';
        this.iconType = 'plus';
    }

    addBlueFrame() {
        // Include blue highlight if anything other than the shared object
        if(this._relationship.lookupFromPrevObjectApiName || this._relationship.lookupToPrevObjectApiName) {
            this.objectFrameClasses += ' selectedObjectFrame';
        }
    }


    get nextObjectIsParent() {
        if(this.nextRelationship.lookupFromPrevObjectApiName) {
            return true;
        }
        else {
            return false;
        }
    }

}