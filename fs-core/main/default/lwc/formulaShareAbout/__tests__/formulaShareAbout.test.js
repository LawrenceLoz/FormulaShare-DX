import { createElement } from 'lwc';
import FormulaShareAbout from 'c/formulaShareAbout';

describe('c-formula-share-about', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('Test if the modal window opens.', () => {
        const element = createElement('c-formula-share-about', {
            is: FormulaShareAbout
        });
        document.body.appendChild(element);

        // Verify modal about is displayed.
        const modalSection = element.shadowRoot.querySelector('section');
        expect(modalSection).not.toBeNull();
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
}