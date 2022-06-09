public inherited sharing class FormulaShareMetadataDMLObjectSettings extends FormulaShareMetadataDMLBase {

    public FormulaShareMetadataDMLObjectSettings() {
        this.fieldsToSet = new List<String>{
            namespacePrefix + 'Retain_Sharing_After_Record_Changes__c',
            namespacePrefix + 'Standard_Object_to_Remove_Sharing__r'
        };
        this.mdNamePrefix = 'FormulaShare_Std_Object_to_Remove_Shares__mdt.';
    }

    public override void handleDeploySuccess(Metadata.DeployResult result) {
        System.debug('Successfully deployed settings DML');
    }
    public override void handleDeployError(Metadata.DeployResult result) {
        System.debug('Error deploying settings DML');
    }

}
