/**
*Copyright 2018 Lawrence Newcombe
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

public with sharing class FormulaShareSettings {
	
	public class FormulaShareException extends Exception{}

	static FormulaShare_Settings__mdt settings;

	public static FormulaShare_Settings__mdt getFormulaShareSettings() {

		if(settings == null) {
			settings = queryFormulaShareSettings();
		}

		return settings;
	}

	private static FormulaShare_Settings__mdt queryFormulaShareSettings() {
		
		List<FormulaShare_Settings__mdt> settingsList =
			[SELECT DeveloperName, Recalculation_Batch_Size__c, Remove_Shares_for_Standard_Objects__c
			FROM FormulaShare_Settings__mdt WHERE Active__c = true];

		if(!settingsList.isEmpty()) {
			// Return the first active setting
			return settingsList[0];
		}

		else throw new FormulaShareException();
	}

}