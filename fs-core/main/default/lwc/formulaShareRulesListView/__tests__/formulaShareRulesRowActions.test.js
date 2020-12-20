import { createElement } from 'lwc';
import FormulaShareRulesListView from 'c/formulaShareRulesListView';

import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { getTreeGridData } from '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData';
import { activateDeactivate } from '@salesforce/apex/FormulaShareRulesListViewController.activateDeactivate';

// Use a mocked navigation plugin.
// See fs-core/test/jest-mocks/lightning/navigation.js for the mock
// and see jest.config.js for jest config to use the mock
//import { getNavigateCalledWith } from 'lightning/navigation';

// Use a mocked navigation plugin.
// fs-core/test/jest-mocks/lightning/platformShowToastEvent.js for the mock
// and see jest.config.js for jest config to use the mock
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

// Import mock data to send through the wire adapter.
const mockExampleTreeGridData = require('./data/exampleTreeGridData.json');
const batchIsProcessingTrue = require('./data/batchIsProcessingTrue.json');
const batchIsProcessingFalse = require('./data/batchIsProcessingFalse.json');

// Register a test wire adapter.
const getTreeGridDataWireAdapter = registerLdsTestWireAdapter(getTreeGridData);
//const activateDeactivateWireAdapter = registerLdsTestWireAdapter(activateDeactivate);

describe('c-formula-share-rules-list-view', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }

        // Prevent data saved on mocks from leaking between tests.
        jest.clearAllMocks();
    });

    it('Test submit for recalculation (Toast) (Positive).', () => {
        // https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/miscNotification/__tests__/miscNotification.test.js
        const TOAST_TITLE = 'Calculation currently in progress';
        const TOAST_MESSAGE = 'Cannot re-submit until current calculation completes';
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

        // Mock data.
        getTreeGridDataWireAdapter.emit(batchIsProcessingTrue);

        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise rejects.
        return Promise.resolve().then(() => {
            // Select ligthning-tree-grid.
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            // Extract parents.
            const parents = treeGrid.data;
            const firstParent = parents[0];

            const rowActionEvent = new CustomEvent(
                "rowaction", {
                    detail: {
                        action: { name: "recalculate" },
                        row: firstParent
                    }
            });
            
            // Trigger row action in lightning-tree-grid.
            treeGrid.dispatchEvent(rowActionEvent);
        })
        .then(() => {
            // Check if toast event has been fired
            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].detail.title).toBe(TOAST_TITLE);
            expect(handler.mock.calls[0][0].detail.message).toBe(TOAST_MESSAGE);
            expect(handler.mock.calls[0][0].detail.variant).toBe(TOAST_VARIANT);

        })
    });

    it('Test submit for recalculation check update processing (Positive).', () => {
        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        // Mock data.
        getTreeGridDataWireAdapter.emit(batchIsProcessingFalse);

        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise rejects.
        return Promise.resolve().then(() => {
            // Select ligthning-tree-grid.
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            // Extract parents.
            const parents = treeGrid.data;
            const firstParent = parents[0];

            const rowActionEvent = new CustomEvent(
                "rowaction", {
                    detail: {
                        action: { name: "recalculate" },
                        row: firstParent
                    }
            });
            
            // Trigger row action in lightning-tree-grid.
            treeGrid.dispatchEvent(rowActionEvent);
        })
        .then(() => {
            // Select ligthning-tree-grid.
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            // Extract parents.
            const parents = treeGrid.data;         
            // Get first child of first parent.
            const allChildren = parents[0]._children;

            // Assert if records are updated with current started processing.
            allChildren.forEach(row => {
                // @todo: Query lightning-tree-grid again and extract data to get changed row.
                expect(row.lastCalcStatus).toBe('Processing...');
                expect(row.iconName).toBe('standard:product_transfer');
                expect(row.iconAlt).toBe('Currently Processing');
            });
        })
    });

    it('Test submit for recalculation (Toast) (Negative).', () => {
        // https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/miscNotification/__tests__/miscNotification.test.js

        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        // Mock handler for toast event.
        const handler = jest.fn();
        // Add event listener to catch toast event.
        element.addEventListener(ShowToastEventName, handler);

        // Mock data.
        getTreeGridDataWireAdapter.emit(batchIsProcessingFalse);

        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise rejects.
        return Promise.resolve().then(() => {
            // Select ligthning-tree-grid.
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            // Extract parents.
            const parents = treeGrid.data;
            const firstParent = parents[0];

            const rowActionEvent = new CustomEvent(
                "rowaction", {
                    detail: {
                        action: { name: "recalculate" },
                        row: firstParent
                    }
            });
            
            // Trigger row action in lightning-tree-grid.
            treeGrid.dispatchEvent(rowActionEvent);
        })
        .then(() => {
            // Check if toast event does NOT fired.
            expect(handler).not.toHaveBeenCalled();
        });
    });

    it('Test navigate to report (Positive).', () => {
        // https://salesforce.stackexchange.com/questions/285021/lightning-web-component-unit-testing-issue-with-testing-row-action-event
        jest.spyOn(window, 'open').mockReturnValue();

        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        // Mock data.
        getTreeGridDataWireAdapter.emit(mockExampleTreeGridData);

        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise rejects.
        return Promise.resolve().then(() => {
            // Select ligthning-tree-grid.
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            // Extract parents.
            const parents = treeGrid.data;
            // Get first child of first parent.
            const firstChild = parents[0]._children;
            const firstRowOfFirstChild = firstChild[0];

            const rowActionEvent = new CustomEvent(
                "rowaction", {
                    detail: {
                        action: { name: "viewlogs" },
                        row: firstRowOfFirstChild
                    }
            });
            
            // Trigger row action in lightning-tree-grid.
            treeGrid.dispatchEvent(rowActionEvent);
        })
        .then(() => {
            // Verify window.open was executed.
            expect(window.open).toHaveBeenCalledTimes(1);
        });
    });

    it('Test edit rule (Positive).', () => {
        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        // Mock data.
        getTreeGridDataWireAdapter.emit(mockExampleTreeGridData);

        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise rejects.
        return Promise.resolve().then(() => {
            // Select ligthning-tree-grid.
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            // Extract parents.
            const parents = treeGrid.data;
            // Get first child of first parent.
            const firstChild = parents[0]._children;
            const firstRowOfFirstChild = firstChild[0];

            const rowActionEvent = new CustomEvent(
                "rowaction", {
                    detail: {
                        action: { name: "edit" },
                        row: firstRowOfFirstChild
                    }
            });
            
            // Trigger row action in lightning-tree-grid.
            treeGrid.dispatchEvent(rowActionEvent);
        })
        .then(() => {
            // Verify c-formula-share-rule-edit is present in DOM.
            const formulaShareRuleEdit = element.shadowRoot.querySelector('c-formula-share-rule-edit');
            expect(formulaShareRuleEdit).not.toBeNull();
        });
    });

    it('Test activate rule (Positive).', () => {
        // Create initial lwc element and attach to virtual DOM.
        const element = createElement('c-formula-share-rules-list-view', {
            is: FormulaShareRulesListView
        });
        document.body.appendChild(element);

        // Mock data.
        getTreeGridDataWireAdapter.emit(mockExampleTreeGridData);
        
        // Mock return value for FormulaShareRulesListViewController.activateDeactivate.
        //activateDeactivateWireAdapter.emit(mockExampleTreeGridData);
        
        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise rejects.
        return Promise.resolve().then(() => {
            // Select ligthning-tree-grid.
            const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
            // Extract parents.
            const parents = treeGrid.data;
            // Get first child of first parent.
            const firstChild = parents[0]._children;
            const firstRowOfFirstChild = firstChild[0];

            const rowActionEvent = new CustomEvent(
                "rowaction", {
                    detail: {
                        action: { name: "activate" },
                        row: firstRowOfFirstChild
                    }
            });
            
            // Trigger row action in lightning-tree-grid.
            treeGrid.dispatchEvent(rowActionEvent);
        })
        .then(() => {
            // Missing assertions. Don't know how to check if spinner appears.
        });
    });
});