public inherited sharing class FormulaShareApplication {

	// Standard unit of work for logs and metrics
	public static final fflib_Application.UnitOfWorkFactory unitOfWork =
	new fflib_Application.UnitOfWorkFactory(
		new List<SObjectType> {
			FormulaShare_Log__c.SObjectType,
			FormulaShare_Rule_in_Batch__c.SObjectType,
			FormulaShare_Record_Log__c.SObjectType,
			FormulaShare_Processed_Record_Share__c.SObjectType,
			FormulaShare_Metrics__c.SObjectType
		}
	);
	
	// Configure and create the SelectorFactory for this Application
	public static final fflib_Application.SelectorFactory Selector = 
	new fflib_Application.SelectorFactory(
		new Map<SObjectType, Type> {
			FormulaShare_Rule__mdt.SObjectType => FormulaShareRulesSelector.class,
			FormulaShare_Settings__mdt.sObjectType => FormulaShareSettingsSelector.class
		}
	);
	
}