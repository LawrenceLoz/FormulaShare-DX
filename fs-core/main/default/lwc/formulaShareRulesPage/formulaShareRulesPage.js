import { LightningElement, track, api } from 'lwc';
import rulesPageIcon from '@salesforce/resourceUrl/RulesPageIcon';

export default class FormulaShareRulesPage extends LightningElement {
    rulesPageIcon = rulesPageIcon;

    openNewRuleModal = false;
    handleNewRule() {
        this.openNewRuleModal = true;
    }
    closeNewRuleModal() {
        this.openNewRuleModal = false;
    }

    openAboutModal = false;
    handleAbout() {
        this.openAboutModal = true;
    }
    closeAboutModal() {
        this.openAboutModal = false;
    }

    @track noRules;
    @track pluralise = 's';
    @track rulesNotSetUp = false;
    @track processingRulesLoad = true;
    handleRulesLoad(event) {
        this.noRules = event.detail;
        if(this.noRules === 0) {
            this.rulesNotSetUp = true;
        }
        else if(this.noRules === 1) {
            this.pluralise = '';
            this.rulesNotSetUp = false;
        }
        else {
            this.pluralise = 's';
            this.rulesNotSetUp = false;
        }
        //console.log('this.rulesNotSetUp '+ this.rulesNotSetUp);
        this.processingRulesLoad = false;
    }
}