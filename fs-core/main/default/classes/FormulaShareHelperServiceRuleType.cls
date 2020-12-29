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

public abstract inherited sharing class FormulaShareHelperServiceRuleType {

	public Set<FormulaShareRule> relevantRules = new Set<FormulaShareRule>();
	public Set<Id> recordsToQuery = new Set<Id>();
	public List<BottomObjectRecordRule> recordRules = new List<BottomObjectRecordRule>();

    // Methods must be implemented
    public abstract void processInsert(SObject newRecord);
    public abstract void processUpdate(SObject newRecord, SObject oldRecord);


    // Populates record id to be queried, and sets record rules to be matched after query
    protected virtual void addToSets(SObject record, FormulaShareRule rule) {
		relevantRules.add(rule);
		recordsToQuery.add(record.Id);

		BottomObjectRecordRule details = new BottomObjectRecordRule();
		details.bottomObjectRecordId = record.Id;
		details.rule = rule;
		recordRules.add(details);
    }

	public class BottomObjectRecordRule {
		public Id bottomObjectRecordId;
		public FormulaShareRule rule;
	}
}
