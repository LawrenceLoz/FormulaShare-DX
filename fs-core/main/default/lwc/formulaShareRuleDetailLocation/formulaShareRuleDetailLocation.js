import { LightningElement, track, api } from 'lwc';

export default class FormulaShareRuleDetailLocation extends LightningElement {

    @api
    get relationship() {
        return this._relationship;
    }
    set relationship(value) {
        this._relationship = value;
        this.setSelectedValues();
    }
    @track _relationship;

    selectedLocation;

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
        this.selectedLocation = 'thisObject';
        this._relationship.nextRelationship = false;
        this.fireRelationshipChange(this._relationship.thisObjectApiName);
    }
    handleSelectedRelatedObject() {
        this.selectedLocation = 'relatedObject';
        this._relationship.nextRelationship = false;
        this.fireRelationshipChange(null);
        this.scrollDown();  // Scroll to ensure relationship component is in view
    }

    // Scroll after 50 ms
    scrollDown() {
        setTimeout(() => {
            console.log('trying to scroll');
            if(this.template.querySelector('c-formula-share-relationship-object')) {
                console.log('found element');
                this.template.querySelector('c-formula-share-relationship-object').scrollIntoView();
            }
        });
    }

    // Detect and fire event for parent when change in relationship-object components
    handleRelationshipChange(event) {
        console.log('Captured relationship change in child component: '+JSON.stringify(event.detail.relationship));
        this._relationship.nextRelationship = event.detail.relationship;
        this.fireRelationshipChange(event.detail.controllingObjectApiName);
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
    
}