// Implements approach suggested by sfdcfox: https://salesforce.stackexchange.com/a/149360

public class FormulaSharePackageVerifier {

    public class LicenseAllowance {
        @AuraEnabled public String Name;
        @AuraEnabled public Boolean unlimitedStandardRules;
        @AuraEnabled public Boolean unlimitedCrossObjectRules;
        @AuraEnabled public Boolean unlimitedRecordsShared;
        @AuraEnabled public Integer maxStandardRules;
        @AuraEnabled public Integer maxCrossObjectRules;
        @AuraEnabled public Integer maxRecordsShared;
        @AuraEnabled public Integer maxRecordsBuffer;
        @AuraEnabled public Integer hardMaxRecordsShared;
        @AuraEnabled public Boolean enableTargetedCalculationJobs;
        @AuraEnabled public Boolean enableTeamSharing;
        @AuraEnabled public Boolean enableRecursionControls;
    }

    private static LicenseAllowance la;
    @AuraEnabled(cacheable=true)
    public static LicenseAllowance getLicenseAllowance() {

        if(la == null) {
            // Used to indicate whether features are present in the OS version of FormulaShare
            // (managed package includes additional features not in OS repo)
            la = new LicenseAllowance();
            la.Name = 'OS';
            la.unlimitedStandardRules = true;
            la.unlimitedCrossObjectRules = false;
            la.unlimitedRecordsShared = true;
            la.maxStandardRules = 0;
            la.maxCrossObjectRules = 0;
            la.maxRecordsShared = 0;
            la.maxRecordsBuffer = 20;
            la.hardMaxRecordsShared = 0;
            la.enableTargetedCalculationJobs = false;
            la.enableTeamSharing = false;
            la.enableRecursionControls = false;
        }

        System.debug('Licence level: '+JSON.serializePretty(la));
        return la;
    }

}