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
public with sharing class FormulaShareLogsTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }

    private static FormulaShareLogs buildDomain() {
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Batches_Processed__c = 0;
        log.Batches_Failed__c = 0;
        log.Failed_Batches__c = '';
        return new FormulaShareLogs(new List<FormulaShare_Log__c>{ log });
    }

    private static FormulaShare_Log__c getLog(FormulaShareLogs domain) {
        return ((List<FormulaShare_Log__c>) domain.Records)[0];
    }


    @IsTest
    static void setContext_setsAllFields() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            List<FormulaShareRule> rules = new List<FormulaShareRule>{
                new FormulaShareRuleStandard()
            };
            domain.setContext('MyBatchClass', 200, 'Account', rules, 'SELECT Id FROM Account');
            FormulaShare_Log__c log = getLog(domain);
            System.assertEquals('MyBatchClass', log.Class_Name__c);
            System.assertEquals('Account', log.Type_In_Scope__c);
            System.assertEquals(1, log.Number_Of_Rules__c);
            System.assertEquals(200, log.Batch_Size__c);
            System.assertEquals(0, log.Batches_Processed__c);
            System.assertEquals(0, log.Batches_Failed__c);
            System.assertEquals('', log.Failed_Batches__c);
            System.assertNotEquals(null, log.Processing_Started__c);
            System.assertNotEquals(null, log.Processing_Started_Milliseconds__c);
        }
    }

    @IsTest
    static void logException_populatesFields() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            Exception e;
            try {
                String s = null;
                s.length();
            } catch(NullPointerException npe) {
                e = npe;
            }
            domain.logException(e);
            FormulaShare_Log__c log = getLog(domain);
            System.assertNotEquals(null, log.Exception_Type__c);
            System.assertNotEquals(null, log.Exception_Message__c);
            System.assertNotEquals(null, log.Exception_Line_Number__c);
        }
    }

    @IsTest
    static void incrementBatches_singleIncrement() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            domain.incrementBatches();
            System.assertEquals(1, getLog(domain).Batches_Processed__c);
        }
    }

    @IsTest
    static void incrementBatches_multipleIncrements() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            domain.incrementBatches();
            domain.incrementBatches();
            domain.incrementBatches();
            System.assertEquals(3, getLog(domain).Batches_Processed__c);
        }
    }

    @IsTest
    static void incrementFailedBatches_incrementsCounterAndString() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            domain.incrementBatches();  // Batches_Processed__c = 1
            domain.incrementFailedBatches();
            FormulaShare_Log__c log = getLog(domain);
            System.assertEquals(1, log.Batches_Failed__c);
            System.assert(log.Failed_Batches__c.contains('1'), 'Failed_Batches__c should record batch number: ' + log.Failed_Batches__c);
        }
    }

    @IsTest
    static void incrementFailedBatches_doesNotAppendWhenStringTooLong() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            // Pre-fill the string to beyond the 248-char guard
            String longString = 'x'.repeat(250);
            ((List<FormulaShare_Log__c>) domain.Records)[0].Failed_Batches__c = longString;
            domain.incrementFailedBatches();
            FormulaShare_Log__c log = getLog(domain);
            // String should not have grown (guard condition: length() < 248)
            System.assert(log.Failed_Batches__c.length() <= 251, 'String should not have grown significantly');
        }
    }

    @IsTest
    static void setBatchProcessingComplete_setsFlag() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            domain.setBatchProcessingComplete();
            System.assertEquals(true, getLog(domain).Batch_Finish_Complete__c);
        }
    }

    @IsTest
    static void trimFailedBatches_removesTrailingComma() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            ((List<FormulaShare_Log__c>) domain.Records)[0].Failed_Batches__c = '1, 2, ';
            domain.trimFailedBatches();
            System.assertEquals('1, 2', getLog(domain).Failed_Batches__c);
        }
    }

    @IsTest
    static void trimFailedBatches_setsNoneWhenNull() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            ((List<FormulaShare_Log__c>) domain.Records)[0].Failed_Batches__c = null;
            domain.trimFailedBatches();
            System.assertEquals('None', getLog(domain).Failed_Batches__c);
        }
    }

    @IsTest
    static void setFinalisedLogs_setsTimestamps() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareLogs domain = buildDomain();
            List<FormulaShare_Log__c> logs = domain.setFinalisedLogs();
            System.assertNotEquals(null, logs[0].Processing_Finished__c);
            System.assertNotEquals(null, logs[0].Processing_Finished_Milliseconds__c);
        }
    }

}