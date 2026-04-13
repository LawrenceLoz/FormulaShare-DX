/**
*Copyright 2026 Lawrence Newcombe
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
public with sharing class FormulaShareRulesQueriesCtrlTest {

    @TestSetup
    static void setup() {
        // System Admin required: code queries standard objects with USER_MODE
        FormulaShareTestUtils.setupAdmin(true);
    }


    // ---- getSpecificRule(): non-existent Id format — returns null or throws QueryException ----

    @IsTest
    static void getSpecificRule_nonExistentId_noUnhandledException() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Query with a well-formed but non-matching Id should return null gracefully
            Id fakeId = fflib_IDGenerator.generate(FormulaShare_Log__c.SObjectType);
            Test.startTest();
            FormulaShareRule result = FormulaShareRulesQueriesController.getSpecificRule(fakeId);
            Test.stopTest();
            System.assertEquals(null, result, 'Non-matching Id should return null');
        }
    }


    // ---- getFilterableFieldsForObject(): blank object name — returns empty list ----

    @IsTest
    static void getFilterableFieldsForObject_blankObject_returnsEmpty() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            List<Map<String,String>> result = FormulaShareRulesQueriesController.getFilterableFieldsForObject('');
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(0, result.size(), 'Empty object name should return empty list');
        }
    }


    // ---- getFilterableFieldsForObject(): valid object using prefix — returns non-empty list ----

    @IsTest
    static void getFilterableFieldsForObject_validObject_returnsList() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String prefix = FormulaShareTestUtils.getNamespacePrefix();
            String logObject = String.isBlank(prefix) ? 'FormulaShare_Log__c' : prefix + 'FormulaShare_Log__c';
            Test.startTest();
            List<Map<String,String>> result = FormulaShareRulesQueriesController.getFilterableFieldsForObject(logObject);
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(!result.isEmpty(), 'Valid object should return a non-empty list of fields');
        }
    }


    // ---- getFilterableFieldsForObject(): invalid object — returns empty list (exception caught) ----

    @IsTest
    static void getFilterableFieldsForObject_invalidObject_returnsEmpty() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            List<Map<String,String>> result = FormulaShareRulesQueriesController.getFilterableFieldsForObject('InvalidObject__c');
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(0, result.size(), 'Invalid object name should return empty list (exception caught)');
        }
    }

}
