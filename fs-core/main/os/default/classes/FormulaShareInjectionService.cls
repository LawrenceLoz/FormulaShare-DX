/**
*Copyright 2022 Lawrence Newcombe
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

public inherited sharing class FormulaShareInjectionService {

    @AuraEnabled(cacheable=true)
    public static Boolean versionSupportsRelatedRules() {
        return false;
    }

    public FormulaShareRulesSelector getRulesSelector() {
        return FormulaShareRulesSelector.construct();
    }

    public Type getRulesSelectorType() {
        return FormulaShareRulesSelector.class;
    }

    public List<FormulaShareRuleTypeServiceBase> getRuleTypeServices() {
        return new List<FormulaShareRuleTypeServiceBase>{
            new FormulaShareRuleTypeServiceStandard()
        };
    }

    public FormulaShareRuleConverterBase getRuleConverter() {
        return new FormulaShareRuleConverterStandard();
    }

    public System.StubProvider getMockProviderRulesSelector() {
        return new FormulaShareMockProvRulesSelector();
    }

    public FormulaShareSObjectsRetrievalServiceBase getSObjectsRetrievalService() {
        return new FormulaShareSObjectsRetrievalServiceStd();
    }
    
    public FormulaShareSObjectsSelector getSObjectsSelector(Boolean enforceObjectAndFieldSecurity, Schema.SObjectType type) {
        return new FormulaShareSObjectsSelector(enforceObjectAndFieldSecurity, type);
    }

    public FormulaShareRecursionService getRecursionService() {
        return new FormulaShareRecursionService();
    }

    public FormulaShareRegularJobs getRegularJobs() {
        return new FormulaShareRegularJobs();
    }

    public Set<String> getExtraRelationshipFields() {
        return new Set<String>();
    }

}