import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import flowTemplate from '@salesforce/resourceUrl/FlowTemplate';
import getFlowVersionId from '@salesforce/apex/FormulaShareFlowController.getFlowVersionId';
import getLicenseAllowance from '@salesforce/apex/FormulaSharePackageVerifier.getLicenseAllowance';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FormulaShareRealTimeInfo extends NavigationMixin(LightningElement) {
    activeTab = 'trigger';
    flowTemplateImage = flowTemplate;
    appExchangeUrl = 'https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1';

    @wire(getLicenseAllowance) 
    license;

    get isOpenSource() {
        return this.license?.data?.Name === 'OS';
    }

    get flowsUrl() {
        return '/builder_platform_interaction/flowBuilder.app?flowDevName=Apply_FormulaShare_Rules_Synchronous';
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    @wire(getFlowVersionId, { flowApiName: 'Apply_FormulaShare_Rules_Synchronous' })
    wiredFlowVersion({ error, data }) {
        if (data) {
            this.flowId = data;
        } else if (error) {
            console.error('Error getting flow version:', error);
        }
    }

    navigateToFlows() {
        if (this.flowId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/builder_platform_interaction/flowBuilder.app?flowId=${this.flowId}`
                }
            });
        } else {
            console.error('No flow ID available');
        }
    }

    sampleTriggerCode = `trigger AccountTrigger on Account (after insert, after update, after delete, after undelete) {
    sdfs.FormulaShareHelper helper = new sdfs.FormulaShareHelper();
    insert helper.getSharesToInsert();
    delete helper.getSharesToDelete();
}`;

    sampleTestCode = `@IsTest
public class AccountTriggerTest {

    @IsTest
    static void testInsert() {
        Account acc = new Account(Name = 'FormulaShare Test');
        Test.startTest();
        insert acc;
        Test.stopTest();
        Boolean formulaShareCalled = FormulaShareHelper.wasCalledForObject(Account.SObjectType);
        System.assert(formulaShareCalled, 'Expected FormulaShareHelper to be constructed in Account trigger');
    }
}`;

    handleCopyCode(event) {
        const codeText = event.currentTarget.dataset.code === 'trigger' 
            ? this.sampleTriggerCode 
            : this.sampleTestCode;
            
        // Create a temporary textarea to copy the text
        const textarea = document.createElement('textarea');
        textarea.value = codeText;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        
        // Show success toast
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Code copied to clipboard',
                variant: 'success'
            })
        );
    }

    handleTabChange(event) {
        this.activeTab = event.target.value;
    }
} 