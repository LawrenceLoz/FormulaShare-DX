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
public with sharing class FormulaShareBatchLogsSelectorTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }

    @IsTest
    static void selectLogsOlderThanDate_returnsLocator() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareBatchLogsSelector sel = new FormulaShareBatchLogsSelector();
            DateTime cutoff = DateTime.now();
            Database.QueryLocator locator = sel.selectLogsOlderThanDate(cutoff);
            System.assertNotEquals(null, locator, 'QueryLocator should not be null');
        }
    }

    @IsTest
    static void getByParentJobIds_emptySet_returnsEmptyMap() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareBatchLogsSelector sel = new FormulaShareBatchLogsSelector();
            Map<String, FormulaShare_Log__c> result = sel.getByParentJobIds(new Set<Id>());
            System.assertNotEquals(null, result);
            System.assert(result.isEmpty(), 'Empty input should return empty map');
        }
    }

    @IsTest
    static void getByParentJobIds_nullSet_returnsEmptyMap() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareBatchLogsSelector sel = new FormulaShareBatchLogsSelector();
            Map<String, FormulaShare_Log__c> result = sel.getByParentJobIds(null);
            System.assertNotEquals(null, result);
            System.assert(result.isEmpty(), 'Null input should return empty map');
        }
    }

    @IsTest
    static void getByParentJobIds_matchingRecord_returnsLog() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Insert a log with a fake parent job id (stored as a string field)
            Id fakeJobId = fflib_IDGenerator.generate(AsyncApexJob.SObjectType);
            FormulaShare_Log__c log = new FormulaShare_Log__c(
                AsyncApexJobParentId__c = fakeJobId
            );
            insert log;

            FormulaShareBatchLogsSelector sel = new FormulaShareBatchLogsSelector();
            Map<String, FormulaShare_Log__c> result = sel.getByParentJobIds(new Set<Id>{ fakeJobId });

            System.assertEquals(1, result.size(), 'Should find one log matching the parent job Id');
            System.assert(result.containsKey(String.valueOf(fakeJobId)), 'Map key should be the parent job Id string');
        }
    }

}
