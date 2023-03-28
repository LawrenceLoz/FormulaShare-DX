/**
*Copyright 2020 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy 
*of this software and associated documentation files (the "Software"), to deal 
*in the Software without restriction, including without limitation the rights 
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
*of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all 
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

public inherited sharing class FormulaShareApplication {

	// Standard unit of work for logs and metrics
	public static final fflib_Application.UnitOfWorkFactory unitOfWork =
	new fflib_Application.UnitOfWorkFactory(
		new List<SObjectType> {
			FormulaShare_Log__c.SObjectType,
			FormulaShare_Rule_in_Batch__c.SObjectType,
			FormulaShare_Record_Log__c.SObjectType,
			FormulaShare_Processed_Record_Share__c.SObjectType,
			FormulaShare_Metrics__c.SObjectType	//
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