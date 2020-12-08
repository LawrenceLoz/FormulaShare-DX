import { LightningElement, api, track } from 'lwc';

export default class FormulaShareRelationshipSharedObject extends LightningElement {

    // On component load set label for shared object and populate next relationship JSON
    @api
    get relationship() {
        return this._relationship;
    }
    set relationship(value) {
        console.log('called setter');
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
    linkToNext;     // Controls whether child components are rendered
    objectFrameClasses;
    fadeOutDuration = 700;

    processNextRelationship(nextRel) {
        console.log('Relationship provided: '+JSON.stringify(nextRel));

        // Set object frame and object text css to baseline
        this.objectFrameClasses = 'slds-box';
        this.objectTextClasses = 'slds-text-heading_small objectLabel';

        // If another relationship from this object, set traverse, remove icon and add link line 
        if(nextRel) {
            this.nextRelationship = nextRel;
            this.setNextRelationshipTraverse();
            this.setDetailsForLinkLabel();
            this.closeButtonsAndIconToPlus();   // Change button to plus (shown again if relationship cancelled or removed)
            this.linkToNext = true;
        }

        // Otherwise, set icon to display a plus button
        else {
            this.closeButtonsAndIconToPlus();
            this.objectTextClasses += ' slds-p-bottom_medium';
            this.objectFrameClasses += ' slds-p-bottom_medium';
            this.addBlueFrame();
            this.linkToNext = false;
        }
    }

    // Populate the name of the relationship field between this object and the next one and the object this field sits on
    relationshipField;
    relationshipFieldOnObject;
    setDetailsForLinkLabel() {
        if(this.nextRelationship.lookupFromPrevObjectApiName) {
            this.relationshipField = this.nextRelationship.lookupFromPrevObjectApiName;
            this.relationshipFieldOnObject = this._relationship.thisObjectApiName;
        }
        else if(this.nextRelationship.lookupToPrevObjectApiName) {
            this.relationshipField = this.nextRelationship.lookupToPrevObjectApiName;
            this.relationshipFieldOnObject = this.nextRelationship.thisObjectApiName;
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
        var newNextRelationship = {
            thisObjectApiName: event.detail.objectApiName,
            thisObjectLabel: event.detail.objectLabel
        };

        if(event.detail.relationshipType === 'parent') {
            newNextRelationship['lookupFromPrevObjectApiName'] = event.detail.relationshipFieldApiName;
        }
        else {
            newNextRelationship['lookupToPrevObjectApiName'] = event.detail.relationshipFieldApiName;
        }

        var newRelationship = this.getCopyOfRelationship(newNextRelationship);
        console.log('newRel: '+JSON.stringify(newRelationship));
        this.childComponentClasses = '';  // Set component to fade in when added
        this.childComponentClasses = 'fadeIn';  // Set component to fade in when added
        this.processNextRelationship(newNextRelationship);
        this.fireRelationshipChange(event.detail.objectApiName, newRelationship);   // newRelationship or newNextRelationship?
    }

    // If relationship updated in child component, communicate to parent
    handleRelationshipChange(event) {
        console.log('Captured relationship change in child component: '+JSON.stringify(event.detail.relationship));

        var newRelationship = this.getCopyOfRelationship(event.detail.relationship);
//        this._relationship = newRelationship;

        this.fireRelationshipChange(event.detail.controllingObjectApiName, newRelationship);
    }

    // When delete button beside link icon is clicked, clear next relationship
    childComponentClasses;
    handleDeleteRelationship() {

        // Fade child components and remove from DOM after fade time (0.7s)
        this.childComponentClasses = 'fadeOut';
        setTimeout(() => {
            this.linkToNext = false;
    
            console.log('handling delete');
            console.log('this._relationship after del: '+JSON.stringify(this._relationship));
            var newRelationship = this.getCopyOfRelationship(null);
    
            // Revert all attributes which were set when relationship added
    //        this.processNextRelationship(null);
            this.fireRelationshipChange(newRelationship.thisObjectApiName, newRelationship);
        }, this.fadeOutDuration);
    }
    
    // Creates new object to replace relationship
    // Required to avoid exception changing inner properties of _relationship in this context
    getCopyOfRelationship(newNextRelationship) {
        var newRelationship = {
            thisObjectApiName: this._relationship.thisObjectApiName,
            thisObjectLabel: this._relationship.thisObjectLabel,
            lookupToPrevObjectApiName: this._relationship.lookupToPrevObjectApiName,
            lookupFromPrevObjectApiName: this._relationship.lookupFromPrevObjectApiName,
            nextRelationship: newNextRelationship
        };
        return newRelationship;
    }

    // Fire event for parent component to be made aware of changes to relationship
    fireRelationshipChange(controllingObjectApiName, thisRel) {
        const relationshipDetails = {
            relationship: thisRel,
            controllingObjectApiName: controllingObjectApiName
        };
        const selection = new CustomEvent('relationshipchange', {
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
            this.childComponentClasses = '';    // Removes fadeOut if previously applied
            this.openButtonsAndIconToCross();
        }
        else if(this.iconType === 'cross') {
            this.childComponentClasses = 'fadeOut';
            setTimeout(() => {
                this.linkToNext = false;
                this.closeButtonsAndIconToPlus();
                this.addBlueFrame();
            }, this.fadeOutDuration);
        }
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