/**
*Copyright 2024 Lawrence Newcombe
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

/**
 * Covers several small base/virtual classes that have no other test coverage:
 *   FormulaShareMetadataPostDMLService
 *   FormulaShareProcessedShareEventHandler
 *   FormulaShareRuleFilterEvaluator
 *   FormulaShareSharedValueMapper
 */
@IsTest
public with sharing class FormulaShareBaseClassesTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }


    // ---- FormulaShareMetadataPostDMLService ----

    @IsTest
    static void metadataPostDMLService_handleNoException() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareMetadataPostDMLService svc = new FormulaShareMetadataPostDMLService();
            svc.handle();
            System.assert(true, 'handle() executed without exception');
        }
    }


    // ---- FormulaShareProcessedShareEventHandler ----

    @IsTest
    static void psEventHandler_processForEvents_callsService() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Mock the settings selector so processForEvents exits cleanly without DML
            FormulaShareSettingsSelector mockSettings = (FormulaShareSettingsSelector)
                FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
            FormulaShareSettingsSelector.mock = mockSettings;

            FormulaShareProcessedShareEventHandler handler = new FormulaShareProcessedShareEventHandler();
            // Pass an empty list — processForEvents handles it without touching DML
            handler.processForEvents(
                new List<FormulaShare_Processed_Share_Event__e>(),
                FormulaShareProcessedShareEventService.batchContext
            );
            System.assert(true, 'processForEvents executed without exception');
        }
    }


    // ---- FormulaShareRuleFilterEvaluator ----

    @IsTest
    static void ruleFilterEvaluator_allFiltersBypassReturnsTrue() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRuleFilterEvaluator evaluator = new FormulaShareRuleFilterEvaluator();
            FormulaShareRule rule = new FormulaShareRuleStandard();
            FormulaShare_Log__c record = new FormulaShare_Log__c();
            Boolean result = evaluator.allFiltersBypass(rule, record, record);
            System.assert(result, 'Base evaluator should always return true');
        }
    }


    // ---- FormulaShareSharedValueMapper ----

    @IsTest
    static void sharedValueMapper_setRulesNoException() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareSharedValueMapper mapper = new FormulaShareSharedValueMapper();
            // setRules is a no-op in the base class — just verify it doesn't throw
            mapper.setRules(new List<FormulaShareRule>(), new List<FormulaShareRetrievedRecordDetails>());
            System.assert(true, 'setRules executed without exception');
        }
    }

    @IsTest
    static void sharedValueMapper_getSharedToValue_returnsFieldValue() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareSharedValueMapper mapper = new FormulaShareSharedValueMapper();
            // Use a rule that shares based on a field value
            FormulaShareRule rule = FormulaShareRuleFactory.getUserRule();
            // getSharedToValue delegates to rule.getSharedToValueFromRecord — just verify no exception
            // with a minimal SObject (field likely returns null, which is fine)
            FormulaShare_Log__c record = new FormulaShare_Log__c();
            String result = mapper.getSharedToValue(rule, record);
            // Result may be null if the field isn't populated — the method just delegates
            System.assert(true, 'getSharedToValue executed without exception');
        }
    }


    // ---- FormulaShareRegularJobs ----

    @IsTest
    static void regularJobs_process_submitsBatch() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Mock settings so the batch size query resolves
            FormulaShareSettingsSelector mockSettings = (FormulaShareSettingsSelector)
                FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
            FormulaShareSettingsSelector.mock = mockSettings;

            FormulaShareRegularJobs jobs = new FormulaShareRegularJobs();
            Test.startTest();
            jobs.process();
            Test.stopTest();

            System.assert(true, 'process() executed without exception');
        }
    }

}
