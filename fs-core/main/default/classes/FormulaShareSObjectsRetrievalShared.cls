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

public inherited sharing class FormulaShareSObjectsRetrievalShared {

    
    public List<SObject> retrieveSharedObjects(Schema.SObjectType type, List<FormulaShareRule> rules, Set<Id> sharedObjIdSet) {

        Map<String, SObjectField> fieldMap = FormulaShareUtilities.getFieldMap(type);

		// Configure to disable object and field security for tests (can't guarantee permissions of running user)
		Boolean enforceObjectAndFieldSecurity = Test.isRunningTest() ? false : true;
		FormulaShareSObjectsSelector sharedObjectSelector = new FormulaShareInjectionService().getSObjectsSelector(enforceObjectAndFieldSecurity, type);

        // Populate all details for query of shared object
        for(FormulaShareRule rule : rules) {

            // Add relevant field from shared object for each rule
            Schema.SObjectField fieldToQuery = fieldMap.get(rule.pathFromSharedObject);
            System.debug('Adding field: '+fieldToQuery.getDescribe().getName());
            sharedObjectSelector.addField(fieldToQuery);
            
            // Also add the OwnerId field if rule shares to users (required for later comparisons)
            if(rule.shareWith == 'Users') {
                Schema.SObjectField ownerIdField = fieldMap.get('OwnerId');
                sharedObjectSelector.addField(ownerIdField);
            }

        }

        System.debug('sharedObjIdSet: '+sharedObjIdSet);

		List<SObject> sharedRecords = sharedObjectSelector.selectWithFields(sharedObjIdSet);
        return sharedRecords;        
    }
}