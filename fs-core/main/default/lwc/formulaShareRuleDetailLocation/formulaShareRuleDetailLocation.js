import { LightningElement, track, api } from 'lwc';

export default class FormulaShareRuleDetailLocation extends LightningElement {

    @api
    get relationship() {
        return this._relationship;
    }
    set relationship(value) {
        // Reset relationship only if shared object has changed
        if(!this._relationship || this._relationship.thisObjectApiName != value.thisObjectApiName) {
            this._relationship = value;
            this.setSelectedValues();
        }
    }
    @track _relationship;

    selectedLocation;
    controllingObjectApiName;

    // Called when shared object is changed
    @api
    setSelectedLocationToThisObject() {
        this.selectedLocation = 'thisObject';
    }

    // Check the relationship and determine whether sharing based on this object or a related object
    setSelectedValues() {
        var nextRel = this._relationship.nextRelationship;
        if(this._relationship.sharedToFieldApiName) {
            this.selectedLocation = 'thisObject';
        }
        else if(nextRel) {
            this.selectedLocation = 'relatedObject';
        }
    }

    get fieldIsOnThisObject() {
        return this.selectedLocation === 'thisObject';
    }
    get fieldIsOnRelatedObject() {
        return this.selectedLocation === 'relatedObject';
    }
    initialTraverse = {sequence: 0, depth: 0};  // relationship-object component operates on this

    // Event handlers for button selection of rule type. Update type and fire event to parent
    handleSelectedThisObject() {
        console.log('handleSelectedThisObject');
        this.selectedLocation = 'thisObject';

        // Copy top level (shared object) relationship without subordinate relationships removed
        // We won't overwrite _relationship or controllingObjectApiName so these can be referenced later if the button is switched again
        var relCopy = {
            thisObjectApiName: this._relationship.thisObjectApiName,
            thisObjectLabel: this._relationship.thisObjectLabel
        };
        var controllingObject = relCopy.thisObjectApiName;

        this.fireRelationshipChange(controllingObject, relCopy);
    }
    handleSelectedRelatedObject() {
        console.log('handleSelectedRelatedObject: '+JSON.stringify(this._relationship));
        this.selectedLocation = 'relatedObject';
        
        var controllingObject = this.controllingObjectApiName;

        this.fireRelationshipChange(controllingObject, this._relationship);
        this.scrollDown();  // Scroll to ensure relationship component is in view
    }

    // Clones relationship to pass to shared object
    // We use a copy and keep original relationship in case button switched back
    updateRelationshipWithControllingObjectAsSharedObject() {
        var relCopy = { ..._relationship }  // Should return shallow clone, but we'll remove nextRelationship property just in case
        delete relCopy.nextRelationship;

        var controllingObject = relCopy.thisObjectApiName;
        this.fireRelationshipChange(controllingObject, relCopy);
    }

    // Scroll after 50 ms
    scrollDown() {
        setTimeout(() => {
            if(this.template.querySelector('c-formula-share-relationship-object')) {
                console.log('found element');
                this.template.querySelector('c-formula-share-relationship-object').scrollIntoView();
            }
        });
    }

    // Detect and fire event for parent when change in relationship-object components
    handleRelationshipChange(event) {
        console.log('Captured relationship change in child component: '+JSON.stringify(event.detail.relationship));
        this._relationship = event.detail.relationship;
        this.controllingObjectApiName = event.detail.controllingObjectApiName;
        this.fireRelationshipChange(event.detail.controllingObjectApiName, this._relationship);
    }

    fireRelationshipChange(controllingObjectApiName, newRelationship) {
        console.log('notifying parent detail component');
        const relationshipDetails = {
            relationship: newRelationship,
            controllingObjectApiName: controllingObjectApiName
        };
        const selection = new CustomEvent('relationshipchange', {
            detail: relationshipDetails
        });
        this.dispatchEvent(selection);
    }
    
}