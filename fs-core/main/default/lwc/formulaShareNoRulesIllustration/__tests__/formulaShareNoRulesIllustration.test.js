import { createElement } from 'lwc';
import FormulaShareNoRulesIllustration from 'c/formulaShareNoRulesIllustration';

describe('c-formula-share-no-rules-illustration', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('Test structure of lightning-card (Positive).', () => {
        const element = createElement('c-formula-share-no-rules-illustration', {
            is: FormulaShareNoRulesIllustration
        });
        document.body.appendChild(element);
        
        // Verify component has a lightning-card.
        const lightningCard = element.shadowRoot.querySelector('lightning-card');
        expect(lightningCard).not.toBeNull();

        // Check image and it's parameter.
        const image = element.shadowRoot.querySelector('img');
        expect(image).not.toBeNull();
        expect(image.src.replace('http://localhost', '')).toBe('/img/chatter/OpenRoad.svg');
        expect(image.alt).toBe('');

        // Get header3.
        const heading = element.shadowRoot.querySelector('h3');
        expect(heading).not.toBeNull();
        expect(heading.innerHTML).toBe('No rules yet');

        // Get the first <p> with class .slds-text-body_regular
        const subtitle = element.shadowRoot.querySelector('p.slds-text-body_regular');
        expect(subtitle).not.toBeNull();
        expect(subtitle.innerHTML).toBe('But you\'re in the right place! Click below to create the first FormulaShare rule');

        // Check if lightning-card has a slot with the name "footer".
        const slot = element.shadowRoot.querySelector('div[slot="footer"]');
        expect(slot).not.toBeNull();

        // Check attributes from lightning-button.
        const listOfLightningButtonInFooter = element.shadowRoot.querySelectorAll('div > lightning-button');
        expect(listOfLightningButtonInFooter).toHaveLength(1);
        const createNewRuleButton = listOfLightningButtonInFooter[0];
        expect(createNewRuleButton.variant).toBe('brand');
        expect(createNewRuleButton.label).toBe('Create Rule');
    });
});