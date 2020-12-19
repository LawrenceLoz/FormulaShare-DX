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

    // Receive current state and direction of the object hierarhcy
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


    // Set UI details when a nested relationship is provided
    processNextRelationship(nextRel) {

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


    // Populate variables used for the link component labels to describe the relationship
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


    // Set traverse details to be checked against limits in the next object component
    nextRelationshipTraverse = {};
    setNextRelationshipTraverse() {

        // Process only if we have the traverse details, and we've set the next relationship
        if(this._traverse && this.nextRelationship) {

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


    // Informs the relationship-link component of the direction of the relationship
    get nextObjectIsParent() {
        if(this.nextRelationship.lookupFromPrevObjectApiName) {
            return true;
        }
        else {
            return false;
        }
    }


    // ----------------- Functions to dynamically update CSS and labels on interaction ----------------- //

    showButtons;
    iconClasses = 'baselineIconStyle plusIconStyle';
    iconType = 'plus';
    iconDisplayed = 'utility:add';
    iconTooltip = 'Add another relationship';
    iconVariant = '';
    handleIconClicked() {
        if(this.iconType === 'plus') {
            this.childComponentClasses = '';    // Removes fadeOut if previously applied
            this.openButtonsAndIconToCross();
        }
        else if(this.iconType === 'cross') {
            this.iconClasses = 'baselineIconStyle crossIconStyle rotate45Backwards';
            this.childComponentClasses = 'fadeOut';

            // Remove validation message indicating selection was needed if one is set
            this.dispatchEvent(new CustomEvent('addrelationshipcancelled'));
    
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
        this.iconVariant = '';
        this.iconType = 'plus';
    }

    addBlueFrame() {
        // Include blue highlight if anything other than the shared object
        if(this._relationship.lookupFromPrevObjectApiName || this._relationship.lookupToPrevObjectApiName) {
            this.objectFrameClasses += ' selectedObjectFrame';
        }
    }

    // Add blue background to plus on hover
    mouseOverIcon() {
        if(this.iconType === 'plus') {
            this.iconClasses = 'baselineIconStyle plusIconActive';
            this.iconVariant = 'inverse';
        }
    }
    mouseLeaveIcon() {
        if(this.iconType === 'plus') {
            this.iconClasses = 'baselineIconStyle plusIconStyle';
            this.iconVariant = '';
        }
    }
    
    // ------------------- Handlers for relationship updates in child components -------------- //

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

        var newRelationship = this.getCopyOfRelationshipWithNewNext(newNextRelationship);
        this.childComponentClasses = '';  // Set component to fade in when added
        this.childComponentClasses = 'fadeIn';  // Set component to fade in when added
        this.processNextRelationship(newNextRelationship);
        this.fireRelationshipChange(event.detail.objectApiName, newRelationship);   // newRelationship or newNextRelationship?
    }


    // If relationship updated in child component, communicate to parent
    handleRelationshipChange(event) {
        var newRelationship = this.getCopyOfRelationshipWithNewNext(event.detail.relationship);
        this.fireRelationshipChange(event.detail.controllingObjectApiName, newRelationship);
    }


    // When delete button beside link icon is clicked, clear next relationship
    childComponentClasses;
    handleDeleteRelationship() {

        // Fade child components and remove from DOM after fade time (0.7s)
        this.childComponentClasses = 'fadeOut';
        setTimeout(() => {
            this.linkToNext = false;

            // Get a copy of this relationship without the nested nextRelationship which was deleted
            var newRelationship = this.getCopyOfRelationshipWithoutNext();
            this.fireRelationshipChange(newRelationship.thisObjectApiName, newRelationship);
        }, this.fadeOutDuration);
    }
    

    // Called to get a copy of this relationship with an updated nextRelationship
    // We need to clone avoid exception changing inner properties of _relationship in this context
    getCopyOfRelationshipWithNewNext(newNextRelationship) {
        var newRelationship = this.getCopyOfRelationshipWithoutNext();
        newRelationship['nextRelationship'] = newNextRelationship;
        return newRelationship;
    }

    // Creates new object to replace relationship without nested nextRelationship attribute
    getCopyOfRelationshipWithoutNext() {
        var newRelationship = {
            thisObjectApiName: this._relationship.thisObjectApiName,
            thisObjectLabel: this._relationship.thisObjectLabel,
            lookupToPrevObjectApiName: this._relationship.lookupToPrevObjectApiName,
            lookupFromPrevObjectApiName: this._relationship.lookupFromPrevObjectApiName
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


    // Report errors from child relationships, or from this relationship if it's the lowest one
    @api
    getError() {

        // If another child component, check validity on child
        if(this.linkToNext) {
            const childRelationship = this.template.querySelector('c-formula-share-relationship-object');
            return childRelationship ? childRelationship.getError() : null;
        }

        // If user has clicked to add an object but not selected one yet, indicate object needs to be selected
        else if(this.showButtons) {
            return 'Select the object where the field is located';
        }

        // If no related objects have been selected (only the shared object is shown), then indicate an object needs to be selected
        else if(this._traverse.sequence === 0 && this._traverse.depth === 0) {
            return 'Click to add a related object where the field is located';
        }

        else {
            return null;
        }
    }
}