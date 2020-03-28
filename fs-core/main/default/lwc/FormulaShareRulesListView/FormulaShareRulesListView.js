import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import getTreeGridData from '@salesforce/apex/FormulaShareRulesListViewController.getTreeGridData';
 
export default class TreeGrid extends LightningElement {
    @track columns = [{
            type: 'text',
            fieldName: 'name',
            label: 'Shared Object',
            initialWidth: 150
        },
        {
            type: 'text',
            fieldName: 'controllingObject',
            label: 'Shared To Field On',
            initialWidth: 150
        },
        {
            type: 'text',
            fieldName: 'label',
            label: 'Rule Description',
            initialWidth: 300
        },
        {
            type: 'text',
            fieldName: 'shareWith',
            label: 'Share With',
            sortable: true,
            initialWidth: 150
        },
        {
            type: 'url', 
            fieldName:'sharedToLink', 
            label:'Shared To', 
            initialWidth: 250,
            typeAttributes: {label: {fieldName:'sharedToLinkLabel'}, target:'_blank'}
        },
        {
            type: 'text',
            fieldName: 'sharingReason',
            label: 'Sharing Reason',
            initialWidth: 200
        },
        {
            type: 'text',
            fieldName: 'accessLevel',
            label: 'Access',
            initialWidth: 75
        },
        {
            type: 'boolean',
            fieldName: 'active',
            label: 'Active',
            initialWidth: 75
        }
    ];
     @track treeItems;
     @track error;
     @wire(getTreeGridData)
     wireTreeData({
         error,
         data
     }) {
         if (data) {
             //  alert(data);
             var res = data;
             var tempjson = JSON.parse(JSON.stringify(data).split('items').join('_children'));
             console.log(tempjson);
             this.treeItems = tempjson;
             console.log(JSON.stringify(tempjson, null, '\t'));
         } else {
             this.error = error;
             //  alert('error' + error);
         }
     }
}