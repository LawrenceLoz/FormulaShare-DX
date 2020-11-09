public inherited sharing class FormulaShareRemoveSharesSelector {

    public static FormulaShareRemoveSharesSelector construct() {
        return new FormulaShareRemoveSharesSelector();
    }

    // fflib selector pattern isn't used because it fails for metadata relationship fields.
    // The basic query below is sufficient - FLS and sharing checks aren't needed 
    // since custom metadata does not support either.
    public List<FormulaShare_Std_Object_to_Remove_Shares__mdt> getRemovalLinesForType(Schema.sObjectType type) {

		String objectName = type.getDescribe().getName();

		List<FormulaShare_Std_Object_to_Remove_Shares__mdt> removalLinesToReturn = 
            [SELECT Id
			FROM FormulaShare_Std_Object_to_Remove_Shares__mdt
			WHERE Standard_Object_to_Remove_Sharing__r.QualifiedApiName = :objectName];

        return removalLinesToReturn;
    }
}
