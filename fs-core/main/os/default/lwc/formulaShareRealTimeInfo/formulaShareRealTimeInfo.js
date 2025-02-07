import { LightningElement } from 'lwc';

export default class FormulaShareRealTimeInfo extends LightningElement {
    appExchangeUrl = 'https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1';

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}