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
  public List<SObject> retrieveSharedObjects(
    Schema.SObjectType type,
    List<FormulaShareRule> rules,
    Set<Id> sharedObjIdSet
  ) {
    // Configure to disable object and field security for tests (can't guarantee permissions of running user)
    Boolean enforceObjectAndFieldSecurity = Test.isRunningTest() ? false : true;
    FormulaShareSObjectsSelector sharedObjectSelector = new FormulaShareInjectionService()
      .getSObjectsSelector(enforceObjectAndFieldSecurity, type);

    // Populate all details for query of shared object
    for (FormulaShareRule rule : rules) {
      // Add relevant field from shared object for each rule
      // Inlaw and descendant rules aren't based on fields from shared object, so pathFromSharedObject will be null
      if (rule.pathFromSharedObject != null) {
        sharedObjectSelector.addFieldString(rule.pathFromSharedObject);
      }

      // Add filter fields to SELECT so in-memory post-query evaluation can reference them
      FormulaShareFilterHelper.ObjectFilterDetail ofd = FormulaShareFilterHelper.parseObjectFilter(
        rule.sharedObjectFilterContracted
      );
      if (ofd != null) {
        for (FormulaShareFilterHelper.FilterDetail fd : ofd.fieldConditions) {
          if (String.isNotBlank(fd.fieldApiName)) {
            sharedObjectSelector.addFieldString(fd.fieldApiName);
          }
        }
      }

      // For cross-object rules, add shared-side intermediary filter fields to SELECT via dot-notation
      // so in-memory evaluation in buildRecordRules() can access them on the shared record.
      // Only add contexts where evaluateAgainstSharedRecord = true: those are genuine parent-lookup
      // paths traversable from the shared record (ancestor/sibling rules).
      // Skip controlling-side contexts (evaluateAgainstSharedRecord = false): their relationshipPath
      // is expressed from the controlling record upward and is invalid in SOQL SELECT on the shared object.
      for (
        FormulaShareRule.IntermediaryFilterContext ctx : rule.getIntermediaryFilterContexts()
      ) {
        if (!ctx.evaluateAgainstSharedRecord)
          continue;
        FormulaShareFilterHelper.ObjectFilterDetail intermediaryOfd = FormulaShareFilterHelper.parseObjectFilter(
          ctx.filterContracted
        );
        if (intermediaryOfd != null) {
          for (
            FormulaShareFilterHelper.FilterDetail fd : intermediaryOfd.fieldConditions
          ) {
            if (String.isNotBlank(fd.fieldApiName)) {
              sharedObjectSelector.addFieldString(
                ctx.relationshipPath + '.' + fd.fieldApiName
              );
            }
          }
        }
      }

      // Also add the OwnerId field if rule shares to users (required for later comparisons)
      if (rule.shareWith == 'Users') {
        sharedObjectSelector.addFieldString('OwnerId');
      }
    }

    System.debug('sharedObjIdSet: ' + sharedObjIdSet);

    List<SObject> sharedRecords = sharedObjectSelector.selectWithFields(
      sharedObjIdSet,
      new List<String>()
    );
    return sharedRecords;
  }
}