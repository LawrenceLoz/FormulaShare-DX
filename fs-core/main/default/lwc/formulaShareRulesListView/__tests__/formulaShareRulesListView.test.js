import { createElement } from 'lwc';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

import FormulaShareRulesListView from 'c/formulaShareRulesListView';
//import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
//import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { getTreeGridData } from '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData';

// Register as Apex wire adapter. Some tests verify that provisioned values trigger desired behavior.
//const getTreeGridListAdapter = registerApexTestWireAdapter(getTreeGridData);

// Import mock data to send through the wire adapter.
const mockExampleTreeGridData = require('./data/exampleTreeGridData.json');
const onlyParentRows = require('./data/onlyParentRows.json');

// Mock getTreeGridData Apex wire adapter
jest.mock(
    '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData',
    () => {
        const {
            createApexTestWireAdapter
        } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true } 
);

// Register a test wire adapter.
//const getTreeGridDataWireAdapter = registerLdsTestWireAdapter(getTreeGridData);

async function flushPromises() {
    return Promise.resolve();
}

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
        
        getTreeGridData.emit(onlyParentRows);

        // Resolve a promise to wait for a rerender of the new content.
        return Promise.resolve().then(() => {
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            expect(treeGrid).toBeNull();
        });
    });

    it('Test row with example data + columns in lightning-tree-grid (Positive).', async () => {
        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        getTreeGridData.emit(mockExampleTreeGridData);

        // Resolve a promise to wait for a rerender of the new content.
        await flushPromises();

        const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
        const parents = treeGrid.data;
        const firstChild = parents[0]._children;
        const secondChild = parents[1]._children;

        expect(parents).toHaveLength(2);
        expect(firstChild).toHaveLength(2);
        expect(secondChild).toHaveLength(4);

        // Check that important columns present
        const columns = treeGrid.columns;
        const populatedCols = new Set();
        for (let col of columns.entries()) {
            populatedCols.add(col.fieldName);
        }
        expect(populatedCols.has("sharedObjectClass"));
        expect(populatedCols.has("tableLabel"));
        expect(populatedCols.has("sharedToLink"));
    });

    it('Test row with example data + columns in lightning-tree-grid (Negative).', () => {
        // https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/apexImperativeMethod/__tests__/apexImperativeMethod.test.js

        const TOAST_TITLE = 'Error fetching data from Salesforce';
        const TOAST_MESSAGE = 'Message from Salesforce: ';
        const TOAST_VARIANT = 'error';

        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        // Mock handler for toast event
        const handler = jest.fn();
        // Add event listener to catch toast event
        element.addEventListener(ShowToastEventName, handler);

        // Emit error from @wire
        getTreeGridData.error();

        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise ends in the
        // rejected state
        return Promise.resolve().then(() => {
            // Check if toast event has been fired
            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].detail.title).toBe(TOAST_TITLE);
            expect(handler.mock.calls[0][0].detail.message).toEqual(expect.stringContaining(TOAST_MESSAGE));
            expect(handler.mock.calls[0][0].detail.variant).toBe(TOAST_VARIANT);
        })
    });

    it('Test opening/closing modal c-formula-share-schedule-job-description (Positive).', () => {
        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        // Mock data.
        getTreeGridData.emit(mockExampleTreeGridData);

        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise rejects.
        return Promise.resolve().then(() => {
            // Select ligthning-tree-grid.
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');

            const rowActionEvent = new CustomEvent(
                "rowaction", {
                    detail: {
                        action: { name: 'scheduleWarning' },
                    }
            });
            
            // Trigger row action in lightning-tree-grid.
            treeGrid.dispatchEvent(rowActionEvent);
        })
        .then(() => {
            // Test opening modal window of c-formula-share-schedule-job-description.
            const scheduleJobDescriptionModal = element.shadowRoot.querySelector('c-formula-share-schedule-job-description');

            expect(scheduleJobDescriptionModal).not.toBeNull();
        })
        .then(() => {
            // Select c-formula-share-schedule-job-description.
            const scheduleJobDescriptionModal = element.shadowRoot.querySelector('c-formula-share-schedule-job-description');

            // Prepare close event.
            const closeEvent = new CustomEvent('close');

            // Trigger custom event in c-formula-share-schedule-job-description.
            scheduleJobDescriptionModal.dispatchEvent(closeEvent);
        })
        .then(() => {
            // Test if modal window is closed.
            const scheduleJobDescriptionModal = element.shadowRoot.querySelector('c-formula-share-schedule-job-description');

            expect(scheduleJobDescriptionModal).toBeNull();
        })
    });
});