import { createElement } from 'lwc';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

import FormulaShareRulesListView from 'c/formulaShareRulesListView';
import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { getTreeGridData } from '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData';

// Mocking imperative Apex method call.
/*jest.mock(
    '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);*/

// Register as Apex wire adapter. Some tests verify that provisioned values trigger desired behavior.
const getTreeGridListAdapter = registerApexTestWireAdapter(getTreeGridData);

// Import mock data to send through the wire adapter.
const mockExampleTreeGridData = require('./data/exampleTreeGridData.json');
const onlyParentRows = require('./data/onlyParentRows.json');

// Register a test wire adapter.
const getTreeGridDataWireAdapter = registerLdsTestWireAdapter(getTreeGridData);

// Sample error for imperative Apex call
const APEX_FORMULA_SHARE_RULES_ERROR = {
    body: { message: 'An internal server error has occurred' },
    ok: false,
    status: 400,
    statusText: 'Bad Request'
};

describe('c-formula-share-rules-list-view', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }

        // Prevent data saved on mocks from leaking between tests
        jest.clearAllMocks();
    });

    it('Test lightning-tree-grid with no data (Positive).', () => {
        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);
        
        getTreeGridDataWireAdapter.emit(onlyParentRows);

        // Resolve a promise to wait for a rerender of the new content.
        return Promise.resolve().then(() => {
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            expect(treeGrid).toBeNull();
        });
    });

    it('Test row with example data + columns in lightning-tree-grid (Positive).', () => {
        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        getTreeGridDataWireAdapter.emit(mockExampleTreeGridData);
        
        // Resolve a promise to wait for a rerender of the new content.
        return Promise.resolve().then(() => {
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            const parents = treeGrid.data;
            const firstChild = parents[0]._children;
            const secondChild = parents[1]._children;

            expect(parents).toHaveLength(2);
            expect(firstChild).toHaveLength(2);
            expect(secondChild).toHaveLength(4);
            
            const columns = treeGrid.columns;
            expect(columns).toHaveLength(8);
        });
    });

    it('Test row with example data + columns in lightning-tree-grid (Positive).', () => {
        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        getTreeGridDataWireAdapter.emit(mockExampleTreeGridData);
        
        // Resolve a promise to wait for a rerender of the new content.
        return Promise.resolve().then(() => {
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            const parents = treeGrid.data;
            const firstChild = parents[0]._children;
            const secondChild = parents[1]._children;

            expect(parents).toHaveLength(2);
            expect(firstChild).toHaveLength(2);
            expect(secondChild).toHaveLength(4);
            
            const columns = treeGrid.columns;
            expect(columns).toHaveLength(8);
        });
    });

    it('Test row with example data + columns in lightning-tree-grid (Negative).', () => {
        // https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/apexImperativeMethod/__tests__/apexImperativeMethod.test.js
        
        // Assign mock value for rejected Apex promise
        //jest.fn().mockRejectedValue(APEX_FORMULA_SHARE_RULES_ERROR);

        const TOAST_TITLE = 'Error fetching data from Salesforce';
        const TOAST_MESSAGE = APEX_FORMULA_SHARE_RULES_ERROR.body.message;
        const TOAST_VARIANT = 'error';

        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        // Emit error from @wire
        getTreeGridListAdapter.error();

        // Mock handler for toast event
        const handler = jest.fn();
        // Add event listener to catch toast event
        element.addEventListener(ShowToastEventName, handler);

        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise ends in the
        // rejected state
        return Promise.resolve().then(() => {
            // Check if toast event has been fired
            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].detail.title).toBe(TOAST_TITLE);
            expect(handler.mock.calls[0][0].detail.message).toBe(TOAST_MESSAGE);
            expect(handler.mock.calls[0][0].detail.variant).toBe(TOAST_VARIANT);
        });
    });
});