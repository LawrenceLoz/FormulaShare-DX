/**
*Copyright 2019 Lawrence Newcombe
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

public inherited sharing class FormulaShareTriggerHelper extends FormulaShareHelperBase implements FormulaShareIHelper {

	private static List<sObjectType> objectsRun = new List<sObjectType>();

	// Constructor to assess sharing
	public FormulaShareTriggerHelper() {

		// Process inserts and updates only (delete and undelete of shared object won't need changes)
		sObjectType type;

		if(Trigger.isExecuting && Trigger.isAfter) {

			// Get SObject type in scope
			if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
				List<sObject> recordsChanged = Trigger.new;
				type = recordsChanged[0].getSObjectType();

				// Continue if we haven't already processed for this object (protects against calling in a loop)
				if(!objectsRun.contains(type)) {
					objectsRun.add(type);

					super.handleChanges(type, Trigger.oldMap, Trigger.newMap);
				}
			}
		}
	}

}