import { createElement } from 'lwc';
import FormulaShareAbout from 'c/formulaShareAbout';

describe('c-formula-share-about', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('Test if the modal window opens with backdrop (Positive).', () => {
        const element = createElement('c-formula-share-about', {
            is: FormulaShareAbout
        });
        document.body.appendChild(element);

        // Verify modal about is displayed.
        const modalSection = element.shadowRoot.querySelector('section');
        expect(modalSection).not.toBeNull();

        // Check if modal is in front of the underlying screen.
        const backdrop = element.shadowRoot.querySelector('.slds-backdrop');
        expect(backdrop).not.toBeNull();
    });

    it('Test if the modal window has a footer + one lightning-button (Positive).', () => {
        const element = createElement('c-formula-share-about', {
            is: FormulaShareAbout
        });
        document.body.appendChild(element);

        // Check if modal has a footer.
        const footer = element.shadowRoot.querySelector('footer');
        expect(footer).not.toBeNull();

        // Find all lightning-button within footer.
        const listOfLightningButtonInFooter = element.shadowRoot.querySelectorAll('footer > lightning-button');
        expect(listOfLightningButtonInFooter.length).toBe(1);

        // Check attributes from lightning-button.
        const closeButton = listOfLightningButtonInFooter[0];
        expect(closeButton).not.toBeNull();
        expect(closeButton.label).toBe('Close');
        expect(closeButton.variant).toBe('neutral');
    });

    it('Test firing a CustomEvent when you click on close button.', () => {
        const element = createElement('c-formula-share-about', {
            is: FormulaShareAbout
        });
        document.body.appendChild(element);

        // Select close button
        const closeButton = element.shadowRoot.querySelector('lightning-button');
        closeButton.click();

        // No assertions here because hide and show is handled in parent component.
    });

    it('Test urls + email (Positive)', () => {
        const element = createElement('c-formula-share-about', {
            is: FormulaShareAbout
        });
        document.body.appendChild(element);

        const listOfLightningFormattedUrl = element.shadowRoot.querySelectorAll('lightning-formatted-url');

        let mapOfExpectedUrlByLabel = new Map()
            .set('Cloud Sundial', 'https://cloudsundial.com/')
            .set('help guide', 'https://cloudsundial.com/node/40/')
            .set('AppExchange', 'https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1');

        // Check url related to label of lightning-formatted-url.
        listOfLightningFormattedUrl.forEach(lightningFormattedUrl => {
            const actualUrl = lightningFormattedUrl.value;
            const actualLabel = lightningFormattedUrl.label;

            const expectedUrl = mapOfExpectedUrlByLabel.has(actualLabel) ? mapOfExpectedUrlByLabel.get(actualLabel) : null;
            expect(actualUrl).toBe(expectedUrl);
        })

        // Check total number of lightning-formatted-url.
        const numberOfLightningFormattedUrl = listOfLightningFormattedUrl.length;
        expect(numberOfLightningFormattedUrl).toEqual(3);

        // Check total number of lightning-formatted-email.
        const listOfLightningFormattedEmail = element.shadowRoot.querySelectorAll('lightning-formatted-email');
        const numberOfLightningFormattedEmail = listOfLightningFormattedEmail.length;
        expect(numberOfLightningFormattedEmail).toEqual(1);
    });
})