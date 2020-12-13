import { LightningElement, track, api } from 'lwc';

export default class FormulaShareRuleDetailLocation extends LightningElement {

    @api
    get relationship() {
        return this._relationship;
    }
    set relationship(value) {
        console.log('received rule: '+JSON.stringify(value));
        // Reset relationship only if shared object has changed
        if(!this._relationship || this._relationship.thisObjectApiName != value.thisObjectApiName) {
            this._relationship = value;
            this.setSelectedValues();
        }

    }
    @track _relationship;

    @api
    get controllingObjectApiName() {
        return this._controllingObjectApiName;
    }
    set controllingObjectApiName(value) {
        // Set controlling object when initially provided by retrieved rule, but don't overrite if previously set
        // This allows us to cache controlling object to switch back if rule is swapped from related to shared and back again
        if(!this._controllingObjectApiName) {
            this._controllingObjectApiName = value;
        }
    }
    _controllingObjectApiName;
    
    // Updated when shared object is changed
    @api 
    get selectedLocation() {
        return this._selectedLocation;
    }
    set selectedLocation(value) {
        if(value) {
            this._selectedLocation = value;
        }
    }
    _selectedLocation;

    // Check the relationship and determine whether sharing based on this object or a related object
    setSelectedValues() {
        var nextRel = this._relationship.nextRelationship;
        if(this._relationship.sharedToFieldApiName) {
            this._selectedLocation = 'thisObject';
        }
        else if(nextRel) {
            this._selectedLocation = 'relatedObject';
        }
    }

    get fieldIsOnThisObject() {
        return this._selectedLocation === 'thisObject';
    }
    get fieldIsOnRelatedObject() {
        return this._selectedLocation === 'relatedObject';
    }

    initialTraverse = {sequence: 0, depth: 0};  // relationship-object component operates on this

    // Event handlers for button selection of rule type. Update type and fire event to parent
    handleSelectedThisObject() {
        console.log('handleSelectedThisObject');
        this._selectedLocation = 'thisObject';

        // Copy top level (shared object) relationship without subordinate relationships removed
        // We won't overwrite _relationship or _controllingObjectApiName so these can be referenced later if the button is switched again
        const relCopy = {
            thisObjectApiName: this._relationship.thisObjectApiName,
            thisObjectLabel: this._relationship.thisObjectLabel
        };
        const controllingObject = relCopy.thisObjectApiName;
        this.fireRelationshipChangeAndClearErrorMessage(controllingObject, relCopy);
    }
    handleSelectedRelatedObject() {
        console.log('handleSelectedRelatedObject: '+JSON.stringify(this._relationship));
        this._selectedLocation = 'relatedObject';
        
        const controllingObject = this._controllingObjectApiName;
        this.fireRelationshipChangeAndClearErrorMessage(controllingObject, this._relationship);
    }

    // Detect and fire event for parent when change in relationship-object components
    handleRelationshipChange(event) {
        console.log('Captured relationship change in child component: '+JSON.stringify(event.detail.relationship));
        this._relationship = event.detail.relationship;
        this._controllingObjectApiName = event.detail.controllingObjectApiName;
        this.fireRelationshipChangeAndClearErrorMessage(event.detail.controllingObjectApiName, this._relationship);
    }

    // Notify parent so it's always up to date with which object controls the sharing
    fireRelationshipChangeAndClearErrorMessage(controllingObjectApiName, newRelationship) {
        this.errorMessage = null;
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

    // Remove any error if adding relationship cancelled
    handleAddRelationshipCancelled() {
        this.errorMessage = null;
    }
    
    errorMessage;
    @api
    checkValidity() {
        console.log('checking validity location');

        if(this.fieldIsOnRelatedObject) {
            var relationshipComponent = this.template.querySelector('c-formula-share-relationship-object');
            this.errorMessage = relationshipComponent.getError();

            // If relationship component implies error, fail validation and show an error
            if(this.errorMessage) {
                return false;
            }
        }
        else {
            this.errorMessage = null;
        }

        // Always valid if field is on this object or no valitity errors on relationship components
        return true;
    }


}