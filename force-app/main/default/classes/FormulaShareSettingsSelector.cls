public inherited sharing class FormulaShareSettingsSelector extends fflib_SObjectSelector {

	public class FormulaShareSettingsSelectorException extends Exception{}

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            FormulaShare_Settings__mdt.DeveloperName,
            FormulaShare_Settings__mdt.Recalculation_Batch_Size__c,
            FormulaShare_Settings__mdt.Remove_Shares_for_Standard_Objects__c};
    }

    public Schema.SObjectType getSObjectType() {
        return FormulaShare_Settings__mdt.sObjectType;
    }

    // Return the single active setting
    public FormulaShare_Settings__mdt selectActiveSettings() {
        List<FormulaShare_Settings__mdt> settings = (List<FormulaShare_Settings__mdt>) Database.query(
            newQueryFactory().
            setCondition('Active__c = true').
            setLimit(1).
            toSOQL());
        
        if(settings.isEmpty()) {
            throw new FormulaShareSettingsSelectorException();
        }

        else return settings[0];
    }

}