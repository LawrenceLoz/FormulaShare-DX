import { LightningElement, api } from 'lwc';

export default class FormulaShareRelationshipLink extends LightningElement {
    @api nextObjectIsParent;
    @api lookupApiName;
    @api objectApiName;

    relationshipLabelClasses;
    deleteIconClasses;

    showRelationshipDetails;
    handleMouseOverLink() {
        // Stop timers if we'd previously started removing
        clearTimeout(this.relationshipDetailsFadeTimer);
        clearTimeout(this.relationshipDetailsRemoveTimer);

        // Set classes to fade in 
        this.relationshipLabelClasses = 'slds-text-body_small relationshipLabel fadeIn';
        this.deleteIconClasses = 'deleteIconStyle fadeIn';
        this.showRelationshipDetails = true;
    }

    relationshipDetailsFadeTimer;
    relationshipDetailsRemoveTimer;
    fadeOutDuration = 700;
    handleMouseLeaveLink() {
        // After 2 seconds, add classes to begin fade out
        this.relationshipDetailsFadeTimer = setTimeout(() => {
            this.relationshipLabelClasses += ' fadeOut';
            this.deleteIconClasses += ' fadeOut';

            // After 0.7 seconds (length of the fade), remove components from DOM
            this.relationshipDetailsRemoveTimer = setTimeout(() => {
                this.showRelationshipDetails = false;
            }, this.fadeOutDuration);
        }, 2000);
    }

    handleDeleteRelationship() {
        this.dispatchEvent(new CustomEvent('deleterelationship'));
    }

}