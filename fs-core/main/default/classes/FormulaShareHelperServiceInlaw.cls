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

public inherited sharing class FormulaShareHelperServiceInlaw extends FormulaShareHelperServiceRuleType {

    public List<FormulaShareRuleInlaw> rules = new List<FormulaShareRuleInlaw>();

    public FormulaShareHelperServiceInlaw(List<FormulaShareRule> rules) {
		for(FormulaShareRule rule : rules) {
			if(rule.isValid() && rule.active && rule.type == 'inlaw') {
                this.rules.add((FormulaShareRuleInlaw) rule);
			}
		}
    }


	public override void processInsert(SObject newRecord) {
		for(FormulaShareRuleInlaw rule : rules) {

			if(newRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != null 
				&& newRecord.get(rule.lookupFromBottomObjTowardsControllingObj) != null) {
				addToSets(newRecord, rule);
			}
		}
	}


	public override void processUpdate(SObject newRecord, SObject oldRecord) {
		for(FormulaShareRuleInlaw rule : rules) {

			// Only progress if both lookups on bottom object are populated
			if(newRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != null
				&& newRecord.get(rule.lookupFromBottomObjTowardsControllingObj) != null) {
				
				// If lookup towards shared object has changed, check sharing
				if(oldRecord.get(rule.lookupFromBottomObjTowardsSharedObj) != newRecord.get(rule.lookupFromBottomObjTowardsSharedObj)) {
					addToSets(newRecord, rule);
				}

				// If lookup towards controlling object has changed, check sharing
				else if(newRecord.get(rule.lookupFromBottomObjTowardsControllingObj) != newRecord.get(rule.lookupFromBottomObjTowardsControllingObj)) {
					addToSets(newRecord, rule);
				}
			}
		}
    }

}