import { createElement } from 'lwc';
import FormulaShareRulesListView from 'c/formulaShareRulesListView';
import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { getTreeGridData } from '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData';

// Import mock data to send through the wire adapter.
const mockExampleTreeGridData = require('./data/exampleTreeGridData.json');

// Register a test wire adapter.
const getTreeGridDataWireAdapter = registerLdsTestWireAdapter(getTreeGridData);

describe('c-formula-share-rules-list-view', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
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
});