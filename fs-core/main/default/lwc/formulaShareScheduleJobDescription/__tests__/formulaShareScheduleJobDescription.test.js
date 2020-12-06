import { createElement } from 'lwc';
import FormulaShareScheduleJobDescription from 'c/formulaShareScheduleJobDescription';

describe('c-formula-share-schedule-job-description', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('Test if the modal window opens with backdrop (Positive).', () => {
        const element = createElement('c-formula-share-schedule-job-description', {
            is: FormulaShareScheduleJobDescription
        });
        document.body.appendChild(element);

        // Verify modal about is displayed.
        const modalSection = element.shadowRoot.querySelector('section');
        expect(modalSection).not.toBeNull();

        // Check if modal is in front of the underlying screen.
        const backdrop = element.shadowRoot.querySelector('.slds-backdrop');
        expect(backdrop).not.toBeNull();
    });

    it('Test structure of section (Positive).', () => {
        const element = createElement('c-formula-share-schedule-job-description', {
            is: FormulaShareScheduleJobDescription
        });
        // Set @api-attribut to test lightning-formatted-url.
        element.setupUrl = 'http://<domain>-dev-ed.lightning.force.com/lightning/setup/ApexClasses/home';
        document.body.appendChild(element);

        // Get header2 and check innerHTML value.
        const heading = element.shadowRoot.querySelector('h2');
        expect(heading).not.toBeNull();
        expect(heading.innerHTML).toBe('Schedule Batch Job');

        // Test total number of lightning-formatted-url.
        const listOfLightningFormattedUrl = element.shadowRoot.querySelectorAll('lightning-formatted-url');
        expect(listOfLightningFormattedUrl).toHaveLength(1);

        // Check relative url path to setup page for apex classes.
        const lightningFormattedUrl = listOfLightningFormattedUrl[0];
        const actualUrl = lightningFormattedUrl.value;
        expect(actualUrl).toEqual(
            expect.stringContaining('/lightning/setup/ApexClasses/home')
        )

        // Check the total number of paragraphs in div with specific class attributes. 
        const divWithParagraphs = element.shadowRoot.querySelectorAll('div.slds-text-longform.slds-p-top_small > p');
        expect(divWithParagraphs).toHaveLength(2);

        // the total number of li in ul with specific class attribute.
        const ulWithLis = element.shadowRoot.querySelectorAll('ul.slds-list_dotted > li');
        expect(ulWithLis).toHaveLength(3);

        // Find all lightning-button within footer.
        const listOfLightningButtonInFooter = element.shadowRoot.querySelectorAll('footer > lightning-button');
        expect(listOfLightningButtonInFooter).toHaveLength(1);

        // Check attributes from lightning-button.
        const closeButton = listOfLightningButtonInFooter[0];
        expect(closeButton).not.toBeNull();
        expect(closeButton.label).toBe('Close');
        expect(closeButton.variant).toBe('neutral');
    });
});