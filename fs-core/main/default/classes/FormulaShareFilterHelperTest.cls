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
public with sharing class FormulaShareFilterHelperTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }


    // ---- parseFilter ----

    @IsTest
    static void parseFilter_validString() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.FilterDetail fd = FormulaShareFilterHelper.parseFilter('Status__c|Equals|Active');
            System.assertEquals('Status__c', fd.fieldApiName);
            System.assertEquals('Equals', fd.operator);
            System.assertEquals('Active', fd.value);
        }
    }

    @IsTest
    static void parseFilter_blankReturnsNull() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            System.assertEquals(null, FormulaShareFilterHelper.parseFilter(''));
            System.assertEquals(null, FormulaShareFilterHelper.parseFilter(null));
        }
    }

    @IsTest
    static void parseFilter_malformedReturnsNull() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            System.assertEquals(null, FormulaShareFilterHelper.parseFilter('NoPipeHere'));
        }
    }

    @IsTest
    static void parseFilter_multiConditionTakesFirst() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.FilterDetail fd = FormulaShareFilterHelper.parseFilter('A__c|Equals|X||B__c|Is Blank');
            System.assertEquals('A__c', fd.fieldApiName);
            System.assertEquals('Equals', fd.operator);
            System.assertEquals('X', fd.value);
        }
    }


    // ---- parseObjectFilter ----

    @IsTest
    static void parseObjectFilter_twoConditions() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.ObjectFilterDetail ofd = FormulaShareFilterHelper.parseObjectFilter('Status__c|Equals|Active||Active__c|Is Not Blank');
            System.assertEquals(2, ofd.fieldConditions.size());
            System.assertEquals('Status__c', ofd.fieldConditions[0].fieldApiName);
            System.assertEquals('Active__c', ofd.fieldConditions[1].fieldApiName);
        }
    }

    @IsTest
    static void parseObjectFilter_blankReturnsEmpty() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.ObjectFilterDetail ofd = FormulaShareFilterHelper.parseObjectFilter('');
            System.assert(ofd.fieldConditions.isEmpty());
        }
    }


    // ---- toContracted ----

    @IsTest
    static void toContracted_equalsWithValue() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String result = FormulaShareFilterHelper.toContracted('Field__c', 'Equals', 'Val');
            System.assertEquals('Field__c|Equals|Val', result);
        }
    }

    @IsTest
    static void toContracted_isBlankNoValue() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String result = FormulaShareFilterHelper.toContracted('Field__c', 'Is Blank', null);
            System.assertEquals('Field__c|Is Blank', result);
        }
    }

    @IsTest
    static void toContracted_nullFieldReturnsNull() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            System.assertEquals(null, FormulaShareFilterHelper.toContracted(null, 'Equals', 'Val'));
        }
    }


    // ---- objectFilterToContracted ----

    @IsTest
    static void objectFilterToContracted_roundTrip() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.ObjectFilterDetail ofd = new FormulaShareFilterHelper.ObjectFilterDetail();
            FormulaShareFilterHelper.FilterDetail fd1 = new FormulaShareFilterHelper.FilterDetail();
            fd1.fieldApiName = 'Status__c';
            fd1.operator = 'Equals';
            fd1.value = 'Active';
            FormulaShareFilterHelper.FilterDetail fd2 = new FormulaShareFilterHelper.FilterDetail();
            fd2.fieldApiName = 'Active__c';
            fd2.operator = 'Is Not Blank';
            ofd.fieldConditions.add(fd1);
            ofd.fieldConditions.add(fd2);

            String contracted = FormulaShareFilterHelper.objectFilterToContracted(ofd);
            FormulaShareFilterHelper.ObjectFilterDetail parsed = FormulaShareFilterHelper.parseObjectFilter(contracted);

            System.assertEquals(2, parsed.fieldConditions.size());
            System.assertEquals('Status__c', parsed.fieldConditions[0].fieldApiName);
            System.assertEquals('Equals', parsed.fieldConditions[0].operator);
            System.assertEquals('Active', parsed.fieldConditions[0].value);
            System.assertEquals('Active__c', parsed.fieldConditions[1].fieldApiName);
        }
    }

    @IsTest
    static void objectFilterToContracted_nullReturnsNull() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            System.assertEquals(null, FormulaShareFilterHelper.objectFilterToContracted(null));
        }
    }


    // ---- toSoqlCondition ----

    @IsTest
    static void toSoqlCondition_isBlank() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'MyField__c';
            fd.operator = 'Is Blank';
            String result = FormulaShareFilterHelper.toSoqlCondition(fd);
            System.assert(result.contains('= NULL'), 'Expected NULL condition: ' + result);
        }
    }

    @IsTest
    static void toSoqlCondition_isNotBlank() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'MyField__c';
            fd.operator = 'Is Not Blank';
            String result = FormulaShareFilterHelper.toSoqlCondition(fd);
            System.assert(result.contains('!= NULL'), 'Expected NOT NULL condition: ' + result);
        }
    }

    @IsTest
    static void toSoqlCondition_equalsString() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Status__c';
            fd.operator = 'Equals';
            fd.value = 'Active';
            String result = FormulaShareFilterHelper.toSoqlCondition(fd);
            System.assertEquals('Status__c = \'Active\'', result);
        }
    }

    @IsTest
    static void toSoqlCondition_equalsBoolean() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'IsActive__c';
            fd.operator = 'Equals';
            fd.value = 'TRUE';
            String result = FormulaShareFilterHelper.toSoqlCondition(fd);
            System.assertEquals('IsActive__c = TRUE', result);
        }
    }

    @IsTest
    static void toSoqlCondition_equalsNumber() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Count__c';
            fd.operator = 'Equals';
            fd.value = '42';
            String result = FormulaShareFilterHelper.toSoqlCondition(fd);
            System.assertEquals('Count__c = 42', result);
        }
    }


    // ---- toSoqlConditionWithPath ----

    @IsTest
    static void toSoqlConditionWithPath_prependsPath() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Status__c';
            fd.operator = 'Equals';
            fd.value = 'Active';
            String result = FormulaShareFilterHelper.toSoqlConditionWithPath('Account__r', fd);
            System.assertEquals('Account__r.Status__c = \'Active\'', result);
        }
    }

    @IsTest
    static void toSoqlConditionWithPath_blankPath() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Status__c';
            fd.operator = 'Is Blank';
            String result = FormulaShareFilterHelper.toSoqlConditionWithPath('', fd);
            System.assertEquals('Status__c = NULL', result);
        }
    }


    // ---- evaluateFilter ----

    @IsTest
    static void evaluateFilter_equalsMatch() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c(Type_In_Scope__c = 'Batch');
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Type_In_Scope__c';
            fd.operator = 'Equals';
            fd.value = 'Batch';
            System.assert(FormulaShareFilterHelper.evaluateFilter(log, fd));
        }
    }

    @IsTest
    static void evaluateFilter_equalsNoMatch() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c(Type_In_Scope__c = 'Trigger');
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Type_In_Scope__c';
            fd.operator = 'Equals';
            fd.value = 'Batch';
            System.assert(!FormulaShareFilterHelper.evaluateFilter(log, fd));
        }
    }

    @IsTest
    static void evaluateFilter_isBlankWhenNull() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Type_In_Scope__c';
            fd.operator = 'Is Blank';
            System.assert(FormulaShareFilterHelper.evaluateFilter(log, fd));
        }
    }

    @IsTest
    static void evaluateFilter_isNotBlankWhenPopulated() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c(Type_In_Scope__c = 'Batch');
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Type_In_Scope__c';
            fd.operator = 'Is Not Blank';
            System.assert(FormulaShareFilterHelper.evaluateFilter(log, fd));
        }
    }

    @IsTest
    static void evaluateFilter_equalsNullValue() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Field is null; filter value is 'NULL' — Equals should return true
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Type_In_Scope__c';
            fd.operator = 'Equals';
            fd.value = 'NULL';
            System.assert(FormulaShareFilterHelper.evaluateFilter(log, fd));
        }
    }

    @IsTest
    static void evaluateFilter_nullFilterReturnsTrue() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            System.assert(FormulaShareFilterHelper.evaluateFilter(log, null));
        }
    }


    // ---- evaluateObjectFilter ----

    @IsTest
    static void evaluateObjectFilter_allPass() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c(Type_In_Scope__c = 'Batch', Class_Name__c = 'MyClass');
            FormulaShareFilterHelper.ObjectFilterDetail ofd = new FormulaShareFilterHelper.ObjectFilterDetail();
            FormulaShareFilterHelper.FilterDetail fd1 = new FormulaShareFilterHelper.FilterDetail();
            fd1.fieldApiName = 'Type_In_Scope__c';
            fd1.operator = 'Equals';
            fd1.value = 'Batch';
            FormulaShareFilterHelper.FilterDetail fd2 = new FormulaShareFilterHelper.FilterDetail();
            fd2.fieldApiName = 'Class_Name__c';
            fd2.operator = 'Is Not Blank';
            ofd.fieldConditions.add(fd1);
            ofd.fieldConditions.add(fd2);
            System.assert(FormulaShareFilterHelper.evaluateObjectFilter(log, ofd));
        }
    }

    @IsTest
    static void evaluateObjectFilter_oneFails() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c(Type_In_Scope__c = 'Trigger');
            FormulaShareFilterHelper.ObjectFilterDetail ofd = new FormulaShareFilterHelper.ObjectFilterDetail();
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Type_In_Scope__c';
            fd.operator = 'Equals';
            fd.value = 'Batch';
            ofd.fieldConditions.add(fd);
            System.assert(!FormulaShareFilterHelper.evaluateObjectFilter(log, ofd));
        }
    }

    @IsTest
    static void evaluateObjectFilter_emptyConditionsReturnsTrue() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c();
            FormulaShareFilterHelper.ObjectFilterDetail ofd = new FormulaShareFilterHelper.ObjectFilterDetail();
            System.assert(FormulaShareFilterHelper.evaluateObjectFilter(log, ofd));
        }
    }


    // ---- evaluateFilterWithPath ----

    @IsTest
    static void evaluateFilterWithPath_noPathDelegatesToDirect() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c(Type_In_Scope__c = 'Batch');
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Type_In_Scope__c';
            fd.operator = 'Equals';
            fd.value = 'Batch';
            System.assert(FormulaShareFilterHelper.evaluateFilterWithPath(log, '', fd));
        }
    }

    @IsTest
    static void evaluateFilterWithPath_nullRelatedRecord_isBlankPasses() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Insert a log with no parent lookup populated, then query it back including
            // the parent relationship. getSObject returns null (LEFT OUTER JOIN result) —
            // Is Blank should return true for a null related record.
            // Relationship API name for Related_Log_Required_for_Test_Class__c is
            // Related_Log_Required_for_Test_Class__r.
            insert new FormulaShare_Log__c();
            FormulaShare_Log__c log = [
                SELECT Id, Related_Log_Required_for_Test_Class__r.Type_In_Scope__c
                FROM FormulaShare_Log__c
                WITH USER_MODE
                LIMIT 1
            ];
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Type_In_Scope__c';
            fd.operator = 'Is Blank';
            Boolean result = FormulaShareFilterHelper.evaluateFilterWithPath(log, 'Related_Log_Required_for_Test_Class__r', fd);
            System.assert(result, 'Is Blank on null related record should return true');
        }
    }

    @IsTest
    static void evaluateFilterWithPath_unknownFieldReturnsTrue() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // When a field can't be retrieved (getSObject throws SObjectException),
            // the catch block returns true — treating the condition as passing (no filter).
            FormulaShare_Log__c log = new FormulaShare_Log__c(Type_In_Scope__c = 'Batch');
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'NonExistentField__c';
            fd.operator = 'Equals';
            fd.value = 'Batch';
            // Path traversal to a non-existent relationship triggers catch → returns true
            Boolean result = FormulaShareFilterHelper.evaluateFilterWithPath(log, 'NonExistentRel__r', fd);
            System.assert(result, 'Unresolvable path should return true (treat as passing)');
        }
    }


    // ---- evaluateObjectFilterWithPath ----

    @IsTest
    static void evaluateObjectFilterWithPath_allPass() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShare_Log__c log = new FormulaShare_Log__c(Type_In_Scope__c = 'Batch');
            FormulaShareFilterHelper.ObjectFilterDetail ofd = new FormulaShareFilterHelper.ObjectFilterDetail();
            FormulaShareFilterHelper.FilterDetail fd = new FormulaShareFilterHelper.FilterDetail();
            fd.fieldApiName = 'Type_In_Scope__c';
            fd.operator = 'Equals';
            fd.value = 'Batch';
            ofd.fieldConditions.add(fd);
            // Blank path — delegates to direct evaluation
            System.assert(FormulaShareFilterHelper.evaluateObjectFilterWithPath(log, '', ofd));
        }
    }

}
