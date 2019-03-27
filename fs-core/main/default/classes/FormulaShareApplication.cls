public with sharing class FormulaShareApplication {
	// Configure and create the SelectorFactory for this Application
	public static final fflib_Application.SelectorFactory Selector = 
		new fflib_Application.SelectorFactory(
			new Map<SObjectType, Type> {
					FormulaShare_Rule__mdt.SObjectType => FormulaShareRulesSelector.class,
					FormulaShare_Settings__mdt.sObjectType => FormulaShareSettingsSelector.class });
}
