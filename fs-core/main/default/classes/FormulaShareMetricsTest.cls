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

@IsTest
public with sharing class FormulaShareMetricsTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }

    private static fflib_ISObjectUnitOfWork newUow() {
        return FormulaShareApplication.unitOfWork.newInstance(new FormulaShareUnitOfWorkDML());
    }

    private static FormulaShareMetrics buildDomain(List<FormulaShare_Metrics__c> records) {
        return new FormulaShareMetrics(records);
    }

    private static FormulaShare_Metrics__c makeMetrics(String ruleName, String ctx) {
        FormulaShare_Metrics__c m = new FormulaShare_Metrics__c();
        m.FormulaShare_Rule_Name__c = ruleName;
        m.Context__c = ctx;
        m.Successful_Inserts__c = 0;
        m.Failed_Inserts__c = 0;
        return m;
    }


    @IsTest
    static void getBlankMetrics_createsOnePerRule() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Set<String> ruleNames = new Set<String>{ 'Rule_A', 'Rule_B' };
            List<FormulaShare_Metrics__c> result = FormulaShareMetrics.getBlankMetrics(ruleNames, 'Test Context');
            System.assertEquals(2, result.size());
            for(FormulaShare_Metrics__c m : result) {
                System.assertEquals(0, m.Successful_Inserts__c);
                System.assertEquals(0, m.Failed_Inserts__c);
                System.assertEquals('Test Context', m.Context__c);
            }
        }
    }

    @IsTest
    static void setBlankMetrics_addsToRecords() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareMetrics domain = buildDomain(new List<FormulaShare_Metrics__c>());
            domain.setBlankMetrics(new Set<String>{ 'Rule_C' }, 'ctx');
            System.assertEquals(1, domain.Records.size());
        }
    }

    @IsTest
    static void augmentMetrics_incrementsExistingRecord() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Metrics__c m = makeMetrics('Rule_A', 'batch');
            m.Successful_Inserts__c = 5;
            m.Failed_Inserts__c = 1;
            FormulaShareMetrics domain = buildDomain(new List<FormulaShare_Metrics__c>{ m });

            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            inc.noSuccessfulInserts = 3;
            inc.noFailedInserts = 2;
            Map<String, FormulaShareMetrics.Increment> incMap = new Map<String, FormulaShareMetrics.Increment>{
                'Rule_A' => inc
            };

            domain.augmentMetrics(newUow(), incMap);
            System.assertEquals(8, m.Successful_Inserts__c);
            System.assertEquals(3, m.Failed_Inserts__c);
        }
    }

    @IsTest
    static void augmentMetrics_skipsRuleWithNoMatchingIncrement() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Metrics__c m = makeMetrics('Rule_A', 'batch');
            m.Successful_Inserts__c = 10;
            FormulaShareMetrics domain = buildDomain(new List<FormulaShare_Metrics__c>{ m });

            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            inc.noSuccessfulInserts = 5;
            Map<String, FormulaShareMetrics.Increment> incMap = new Map<String, FormulaShareMetrics.Increment>{
                'Other_Rule' => inc
            };

            domain.augmentMetrics(newUow(), incMap);
            System.assertEquals(10, m.Successful_Inserts__c, 'Unmatched rule should not be modified');
        }
    }

    @IsTest
    static void augmentMetrics_registersNewForNullId() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Metrics__c m = makeMetrics('Rule_A', 'batch');
            // No Id — registerNew path
            FormulaShareMetrics domain = buildDomain(new List<FormulaShare_Metrics__c>{ m });
            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            Map<String, FormulaShareMetrics.Increment> incMap = new Map<String, FormulaShareMetrics.Increment>{
                'Rule_A' => inc
            };
            // Should complete without exception
            domain.augmentMetrics(newUow(), incMap);
            System.assert(true, 'registerNew path executed without exception');
        }
    }

    @IsTest
    static void augmentMetrics_registersDirtyForExistingId() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Metrics__c m = makeMetrics('Rule_A', 'batch');
            m.Id = fflib_IDGenerator.generate(FormulaShare_Metrics__c.SObjectType);
            FormulaShareMetrics domain = buildDomain(new List<FormulaShare_Metrics__c>{ m });
            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            Map<String, FormulaShareMetrics.Increment> incMap = new Map<String, FormulaShareMetrics.Increment>{
                'Rule_A' => inc
            };
            domain.augmentMetrics(newUow(), incMap);
            System.assert(true, 'registerDirty path executed without exception');
        }
    }

    @IsTest
    static void augmentMetrics_setsDateFields() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Metrics__c m = makeMetrics('Rule_A', 'batch');
            FormulaShareMetrics domain = buildDomain(new List<FormulaShare_Metrics__c>{ m });

            DateTime now = DateTime.now();
            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            inc.LastSuccessfulOperation = now;
            inc.lastFailedOperation = now;
            inc.LastSuccessfulBatch = now;
            inc.lastFailedBatch = now;
            Map<String, FormulaShareMetrics.Increment> incMap = new Map<String, FormulaShareMetrics.Increment>{
                'Rule_A' => inc
            };

            domain.augmentMetrics(newUow(), incMap);
            System.assertEquals(now, m.Last_Successful_Operation__c);
            System.assertEquals(now, m.Last_Failed_Operation__c);
            System.assertEquals(now, m.Last_Successful_Batch__c);
            System.assertEquals(now, m.Last_Failed_Batch__c);
        }
    }

    @IsTest
    static void overwriteMetrics_setsAbsoluteValues() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Metrics__c m = makeMetrics('Rule_A', 'batchFinish');
            m.Successful_Inserts__c = 100;
            m.Failed_Inserts__c = 50;
            // Give metrics an Id so it takes the registerDirty path (avoids registerNew + registerRelationship ordering issues)
            m.Id = fflib_IDGenerator.generate(FormulaShare_Metrics__c.SObjectType);
            FormulaShareMetrics domain = buildDomain(new List<FormulaShare_Metrics__c>{ m });

            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            inc.noSuccessfulInserts = 7;
            inc.noFailedInserts = 3;
            Map<String, FormulaShareMetrics.Increment> incMap = new Map<String, FormulaShareMetrics.Increment>{
                'Rule_A' => inc
            };

            // Insert a real log to use as parent for registerRelationship
            FormulaShare_Log__c batchLog = new FormulaShare_Log__c();
            insert batchLog;
            domain.overwriteMetrics(newUow(), incMap, batchLog);
            System.assertEquals(7, m.Successful_Inserts__c, 'Overwrites should replace, not add');
            System.assertEquals(3, m.Failed_Inserts__c);
        }
    }

    @IsTest
    static void overwriteMetrics_setsProcessingFinished() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Metrics__c m = makeMetrics('Rule_A', 'batchFinish');
            m.Id = fflib_IDGenerator.generate(FormulaShare_Metrics__c.SObjectType);
            FormulaShareMetrics domain = buildDomain(new List<FormulaShare_Metrics__c>{ m });

            DateTime finishTime = DateTime.now();
            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            inc.processingFinished = finishTime;
            Map<String, FormulaShareMetrics.Increment> incMap = new Map<String, FormulaShareMetrics.Increment>{
                'Rule_A' => inc
            };

            FormulaShare_Log__c batchLog = new FormulaShare_Log__c();
            insert batchLog;
            domain.overwriteMetrics(newUow(), incMap, batchLog);
            System.assertEquals(finishTime, m.Processing_Finished__c);
        }
    }

    @IsTest
    static void overwriteMetrics_doesNotSetProcessingFinishedWhenNull() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Metrics__c m = makeMetrics('Rule_A', 'batchFinish');
            m.Id = fflib_IDGenerator.generate(FormulaShare_Metrics__c.SObjectType);
            DateTime existingFinish = DateTime.now().addHours(-1);
            m.Processing_Finished__c = existingFinish;
            FormulaShareMetrics domain = buildDomain(new List<FormulaShare_Metrics__c>{ m });

            FormulaShareMetrics.Increment inc = new FormulaShareMetrics.Increment();
            // processingFinished left null
            Map<String, FormulaShareMetrics.Increment> incMap = new Map<String, FormulaShareMetrics.Increment>{
                'Rule_A' => inc
            };

            FormulaShare_Log__c batchLog = new FormulaShare_Log__c();
            insert batchLog;
            domain.overwriteMetrics(newUow(), incMap, batchLog);
            System.assertEquals(existingFinish, m.Processing_Finished__c, 'Should not overwrite when null');
        }
    }

}
