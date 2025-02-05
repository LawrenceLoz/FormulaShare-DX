import { LightningElement } from 'lwc';

export default class FormulaShareScheduleBatchIllustration extends LightningElement {
    handleScheduleBatch() {
        this.dispatchEvent(new CustomEvent('openschedulebatch'));
    }

    handleCloseModal() {
        this.dispatchEvent(new CustomEvent('closeschedulebatch'));
    }

    handleOpenRealTimeInfo() {
        this.dispatchEvent(new CustomEvent('openrealtimeinfo'));
    }
}