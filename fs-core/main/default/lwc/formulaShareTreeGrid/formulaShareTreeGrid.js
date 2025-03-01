import LightningDatatable from 'lightning/datatable';
import groupHeadingTemplate from './groupHeadingColumnType.html';
import { api } from 'lwc';

export default class FormulaShareTreeGrid extends LightningDatatable {
    static customTypes = {
        treeGridName: {
            template: groupHeadingTemplate,
            typeAttributes: ['isParent']
        }
    };
    
    _treeData = [];

    @api
    get rows() {
        return this._treeData;
    }
    set rows(value) {
        this._treeData = value;
        this.processData();
    }

    connectedCallback() {
        super.connectedCallback();
        this.processData();
    }

    processData() {
        if (!this._treeData || !Array.isArray(this._treeData)) {
            console.warn('Invalid or missing tree data');
            this.data = [];
            return;
        }
        
        const processedData = [];
        this._treeData.forEach(item => {
            if (!item[this.keyField]) {
                console.warn(`Row missing ${this.keyField} field:`, item);
                return;
            }
            
            // Add parent row
            const parentRow = { ...item };
            parentRow.isParent = true;
            parentRow._children = item._children || [];
            processedData.push(parentRow);

            // Add child rows if parent is has children
            if (parentRow._children) {
                parentRow._children.forEach(child => {
                    const childRow = { ...child };
                    childRow.isParent = false;
                    childRow._parentKey = parentRow[this.keyField];
                    processedData.push(childRow);
                });
            }
        });
        this.data = processedData;
    }

} 