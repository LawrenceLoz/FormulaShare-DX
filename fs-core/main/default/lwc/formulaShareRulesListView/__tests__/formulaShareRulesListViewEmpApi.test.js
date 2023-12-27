import { createElement } from 'lwc';
import {setImmediate} from 'timers';
import FormulaShareRulesListView from 'c/formulaShareRulesListView';
import getTreeGridData from '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData';
import getNamespacePrefix from '@salesforce/apex/FormulaShareLWCUtilities.getNamespacePrefix';

import { jestMockPublish } from 'lightning/empApi';

// Import mock data to send through the wire adapter.
const mockExampleTreeGridData = require('./data/exampleTreeGridData.json');
const NAMESPACE_PREFIX = 'sfds__';

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
// Mock getNamespacePrefix imperitive function
jest.mock(
    '@salesforce/apex/FormulaShareLWCUtilities.getNamespacePrefix',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }    
);

// eslint-disable-next-line no-undef
const flushPromises = () => new Promise(setImmediate);

describe('c-formula-share-rules-list-view', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }

        // Prevent data saved on mocks from leaking between tests
        jest.clearAllMocks();
    });

    describe('getTreeGridData @wire', () => {
        it('Test activate events (Positive).', async () => {

            // Create initial lwc element and attach to virtual DOM.
            const element = createElement('c-formula-share-rules-list-view', {
                is: FormulaShareRulesListView
            });
            document.body.appendChild(element);

            getNamespacePrefix.mockResolvedValue(NAMESPACE_PREFIX);
            getTreeGridData.emit(mockExampleTreeGridData);

            // Make sure async subscribe call in connectedCallback completes
            await flushPromises();

            // connectedCallback is now complete, but no Platform Events have 
            // been published yet.  Make assertions here about the state of your 
            // component prior to receiving the Platform Events.

            // Mock-publish a Platform Event and await the promise
            await jestMockPublish('/event/FormulaShare_List_Update__e', {
                data: {
                    payload: {
                        Object_Label__c: 'Account',
                        Type__c: 'activate'
                    }
                }
            });
            // Now any DOM updates that depend on the Platform Event should 
            // have rendered; assert about them here.
        });
    });
});