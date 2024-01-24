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

public with sharing class FormulaShareInjectionService {

    @AuraEnabled(cacheable=true)
    public static Boolean versionSupportsRelatedRules() {
        return false;
    }

    @AuraEnabled(cacheable=false)
    public static void processOnActionClick(String baseUrl) {
        return;
    }


    public FormulaShareRulesSelector getRulesSelector() {
        return FormulaShareRulesSelector.construct();
    }

    public Type getRulesSelectorType() {
        return FormulaShareRulesSelector.class;
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

    public FormulaShareProcessedRecordShare getProcessedRecordShare() {
        return new FormulaShareProcessedRecordShare();
    }

    public FormulaShareBatchService getBatchService(Schema.SObjectType typeInThisBatch, String contextDetail, List<FormulaShareRule> rulesForType) {
        return new FormulaShareBatchService(typeInThisBatch, contextDetail, rulesForType);
    }

    public FormulaShareIOrgControls getOrgControls() {
        return new FormulaShareOrgControls();        
    }

    public FormulaShareRemoveSharesSelector getRemoveSharesSelector() {
        return new FormulaShareRemoveSharesSelector();
    }



    public Set<String> getExtraRelationshipFields() {
        return new Set<String>();
    }

    public List<String> getExtraSettingsFields() {
        return new List<String>();
    }

    public Boolean versionSupportsTeamSharing() {
        return false;
    }

    public List<FormulaShareShareWithBase> getShareWithClasses(FormulaShareService service) {
        return new List<FormulaShareShareWithBase> {
            new FormulaShareShareWithUsers(service),
            new FormulaShareShareWithRoles(service),
            new FormulaShareShareWithPublicGroups(service)
        };
    }

}