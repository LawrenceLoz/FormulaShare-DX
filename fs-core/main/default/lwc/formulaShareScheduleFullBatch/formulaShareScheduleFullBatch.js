import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import aboutCloud from '@salesforce/resourceUrl/AboutCloud';
import getLicenseAllowance from '@salesforce/apex/FormulaSharePackageVerifier.getLicenseAllowance';

export default class FormulaShareScheduleFullBatch extends NavigationMixin(LightningElement) {
    aboutCloudLogo = aboutCloud;

    @wire(getLicenseAllowance) licence;

    get setupTabUrl() {
        return '/lightning/setup/FormulaShare/page?address=%2Fapex%2FFormulaShareSetup';
    }

    get flowsUrl() {
        return '/lightning/setup/Flows/home';
    }


    handleRefreshView() {
        this.dispatchEvent(new CustomEvent('refreshview'));
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
} 