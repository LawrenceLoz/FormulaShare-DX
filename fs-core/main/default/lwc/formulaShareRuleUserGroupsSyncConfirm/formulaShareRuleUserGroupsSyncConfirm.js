import { LightningElement, api } from 'lwc';

export default class FormulaShareRuleUserGroupsSyncConfirm extends LightningElement {
    @api isEdit = false;

    get title() {
        return this.isEdit ? 'Update User Field Matching Rule' : 'Create User Field Matching Rule';
    }

    get message() {
        return 'Rules of this kind will only apply after public groups have been automatically created for the unique combination of values on user records. ' +
               'This process will take place during the first FormulaShare batch process each day, or you can initiate as a one-off process from FormulaShare Settings.';
    }

    get recommendation() {
        return 'We recommend you also submit this reassessment now.';
    }

    handleSyncNow() {
        this.dispatchEvent(new CustomEvent('syncnow'));
    }

    handleWaitForBatch() {
        this.dispatchEvent(new CustomEvent('waitforbatch'));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}
