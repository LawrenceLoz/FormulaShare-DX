public inherited sharing class FormulaShareOrgControls implements FormulaShareIOrgControls {

    public Boolean preventSharingInserts() {
        return false;
    }

    public String getErrorForPreventedSharingInserts() {
        return 'n/a';
    }
}