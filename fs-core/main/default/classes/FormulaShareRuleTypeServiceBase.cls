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

public abstract inherited sharing class FormulaShareRuleTypeServiceBase {

	protected String sharedObjectName;
	public List<FormulaShareRule> allRules;		// All rules on this object (included invalid and inactive)
	public Set<FormulaShareRule> relevantRules = new Set<FormulaShareRule>();	// Rules which might be directly affected by field changes
	public Set<FormulaShareRule> fullRules 	   = new Set<FormulaShareRule>();	// All rules of this type which should apply
	public Set<SObject> recordsShared = new Set<SObject>();		// New/updated records which could be affected by relevant rules
	public Set<Id> recordsToQuery = new Set<Id>();				// Any additional records which may need to be queried

    // Methods must be implemented
	public abstract void setRules(String sharedObjectName, List<FormulaShareRule> rulesSharingObject, List<FormulaShareRule> rulesObjectInfluences);
    public abstract void processInsert(SObject newRecord);
    public abstract void processUpdate(SObject newRecord, SObject oldRecord);
	public abstract Boolean sharesProcessedObject();	// Returns true when service may need to check all rules, not just those where sharing could change
	public abstract Map<String,FormulaShareServiceDetailsForType> makeUpdatedDetailsMap(Map<String,FormulaShareServiceDetailsForType> detailsMap, Map<Id,SObject> fullQueriedRecords, String processedObjectKey);

}
