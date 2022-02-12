import { createElement } from 'lwc';
import FormulaShareRulesPage from 'c/formulaShareRulesPage';

describe('c-formula-share-rules-page', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('Test opening/closing modal Help & Modal (Positive)', () => {
        const element = createElement('c-formula-share-rules-page', {
            is: FormulaShareRulesPage
        });

        document.body.appendChild(element);
        
        const lightningButtonHelpAndModal = element.shadowRoot.querySelector('lightning-button[data-name="helpAndAbout"]');
        lightningButtonHelpAndModal.click();
        expect(lightningButtonHelpAndModal).not.toBeNull();

        // Resolve a promise to wait for a rerender of the new content.
        return Promise.resolve().then(() => {
            // Check if modal opened after click on button.
            const helpAndAboutModal = element.shadowRoot.querySelector('c-formula-share-about');
            expect(helpAndAboutModal).not.toBeNull();
        })
        .then(() => {
            const helpAndAboutModal = element.shadowRoot.querySelector('c-formula-share-about');
       
            const closeEvent = new CustomEvent("close");
            
            // Trigger handleRulesLoad.
            helpAndAboutModal.dispatchEvent(closeEvent);
        })
        .then(() => {
            // Check if modal opened after click on button.
            const helpAndAboutModal = element.shadowRoot.querySelector('c-formula-share-about');
            expect(helpAndAboutModal).toBeNull();
        })
    });

    it('Test show illustration (Positive)', () => {
        const element = createElement('c-formula-share-rules-page', {
            is: FormulaShareRulesPage
        });

        document.body.appendChild(element);
        
        // Resolve a promise to wait for a rerender of the new content.
        return Promise.resolve().then(() => {
            const rulesList = element.shadowRoot.querySelector('c-formula-share-rules-list-view');

            const onRuleLoadEvent = new CustomEvent(
                "ruleload", {
                    detail: 0
            });
            
            // Trigger handleRulesLoad.
            rulesList.dispatchEvent(onRuleLoadEvent);
        })
        .then(() => {
            const noRulesIllustration = element.shadowRoot.querySelector('c-formula-share-no-rules-illustration');
            expect(noRulesIllustration).not.toBeNull();
        })
    });

    it('Test opening/closing of new rules modal window (Positive)', () => {
        const element = createElement('c-formula-share-rules-page', {
            is: FormulaShareRulesPage
        });

        document.body.appendChild(element);
        
        // Resolve a promise to wait for a rerender of the new content.
        return Promise.resolve().then(() => {
            const rulesList = element.shadowRoot.querySelector('c-formula-share-rules-list-view');

            // Expect c-formula-share-rule-create is not visibile after rendering has finished the first time.
            const ruleCreate = element.shadowRoot.querySelector('c-formula-share-rule-create');
            expect(ruleCreate).toBeNull();

            const onRuleLoadEvent = new CustomEvent(
                "ruleload", {
                    detail: 1
            });
            
            // Trigger handleRulesLoad.
            rulesList.dispatchEvent(onRuleLoadEvent);
        })
        .then(() => {
            // Check if button is visible.
            const newRuleButton = element.shadowRoot.querySelector('lightning-button[data-name="newRule"]');
            expect(newRuleButton).not.toBeNull();
            newRuleButton.click();
        })
        .then(() => {
            // Check if modal windows is open.
            const ruleCreateModal = element.shadowRoot.querySelector('c-formula-share-rule-create');
            expect(ruleCreateModal).not.toBeNull();
        })
        .then(() => {
            // Close modal window for c-formula-share-rule-create.
            const ruleCreateModal = element.shadowRoot.querySelector('c-formula-share-rule-create');
       
            const closeEvent = new CustomEvent("close");
            
            // Trigger handleRulesLoad.
            ruleCreateModal.dispatchEvent(closeEvent);
        })
        .then(() => {
            // Check if modal is closed.
            const ruleCreateModal = element.shadowRoot.querySelector('c-formula-share-rule-create');
            expect(ruleCreateModal).toBeNull();
        })
    });

    it('Test pluralise (Positive)', () => {
        const element = createElement('c-formula-share-rules-page', {
            is: FormulaShareRulesPage
        });

        document.body.appendChild(element);

        const numberOfRows = 2;
        // Resolve a promise to wait for a rerender of the new content.
        return Promise.resolve().then(() => {
            const rulesList = element.shadowRoot.querySelector('c-formula-share-rules-list-view');

            const onRuleLoadEvent = new CustomEvent(
                "ruleload", {
                    detail: numberOfRows
            });
            
            // Trigger handleRulesLoad.
            rulesList.dispatchEvent(onRuleLoadEvent);
        })
        .then(() => {
            const pageHeader = element.shadowRoot.querySelector('p.slds-page-header__meta-text.slds-text-body_small.slds-m-top_xxx-small');
            expect(pageHeader).not.toBeNull();
            const innerHTML = pageHeader.innerHTML;
            expect(innerHTML).toBe(numberOfRows + ' items');
        })
    });
});