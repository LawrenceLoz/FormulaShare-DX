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

public inherited sharing class FormulaShareHelperServiceDescendant extends FormulaShareHelperServiceRuleType {

    public List<FormulaShareRuleDescendant> rules = new List<FormulaShareRuleDescendant>();

    public FormulaShareHelperServiceDescendant(List<FormulaShareRule> rules) {
		for(FormulaShareRule rule : rules) {
			if(rule.isValid() && rule.active && rule.type == 'descendant') {
                this.rules.add((FormulaShareRuleDescendant) rule);
			}
		}
    }


	public override void processInsert(SObject newRecord) {
		System.debug('Descendant process insert');
		for(FormulaShareRuleDescendant rule : rules) {
			System.debug('Checking record ' + newRecord.get('Id') + ' for processing for descendant rule: ' + rule.developerName + '. First query step(' + rule.controllingObjectSharedToFieldAPIName + '): '+newRecord.get(rule.controllingObjectSharedToFieldAPIName));

			// If lookup towards shared on a descendant rule is populated, we might need to assess sharing for the shared object
			if(newRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != null 
				&& newRecord.get(rule.controllingObjectSharedToFieldAPIName) != null) {
				System.debug('Adding record ' + newRecord.get('Id') + ' for processing for descendant rule: ' + rule.developerName + '. First query step(' + rule.controllingObjectSharedToFieldAPIName + '): '+newRecord.get(rule.controllingObjectSharedToFieldAPIName));
				addToSets(newRecord, rule);
			}
		}
    }
    

	public override void processUpdate(SObject newRecord, SObject oldRecord) {
		for(FormulaShareRuleDescendant rule : rules) {

			// Only progress if lookup and shared to field are populated
			if(newRecord.get(rule.controllingObjectSharedToFieldAPIName) != null
				&& newRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != null) {
				
				// If lookup towards shared object has changed, we might need to assess for the new parent
				if(oldRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != newRecord.get(rule.lookupFromBottomObjTowardsSharedObj)) {
					System.debug('Adding record ' + newRecord.get('Id') + ' for processing for descendant rule: ' + rule.developerName + '. Lookup change(' + rule.lookupFromBottomObjTowardsSharedObj + '): '+newRecord.get(rule.lookupFromBottomObjTowardsSharedObj));
					addToSets(newRecord, rule);
				}

				// For descendant rules, if shared to field has changed, might need to assess
				else if(oldRecord.get(rule.controllingObjectSharedToFieldAPIName) != newRecord.get(rule.controllingObjectSharedToFieldAPIName)) {
					System.debug('Adding record ' + newRecord.get('Id') + ' for processing for descendant rule: ' + rule.developerName + '. First query step(' + rule.controllingObjectSharedToFieldAPIName + '): '+newRecord.get(rule.controllingObjectSharedToFieldAPIName));
					addToSets(newRecord, rule);
				}
			}
		}
    }

}