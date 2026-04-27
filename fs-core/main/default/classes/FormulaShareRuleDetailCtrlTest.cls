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
public with sharing class FormulaShareRuleDetailCtrlTest {

    @TestSetup
    static void setup() {
        // System Admin required: queries standard objects via USER_MODE
        FormulaShareTestUtils.setupAdmin(true);
    }


    // ---- getChildRelationships() ----

    @IsTest
    static void getChildRelationships_validObject_returnsList() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            List<FormulaShareUtilities.RelationshipDetails> result =
                FormulaShareRuleDetailController.getChildRelationships('User');
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }


    // ---- getParentRelationships() ----

    @IsTest
    static void getParentRelationships_validObject_returnsList() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            List<FormulaShareUtilities.RelationshipDetails> result =
                FormulaShareRuleDetailController.getParentRelationships('User');
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }


    // ---- getAllCustomMetadataTypes() ----

    @IsTest
    static void getAllCustomMetadataTypes_returnsMap() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            Map<String,String> result = FormulaShareRuleDetailController.getAllCustomMetadataTypes();
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }


    // ---- getTextFields() ----

    @IsTest
    static void getTextFields_validCmdt_returnsMap() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String prefix = FormulaShareTestUtils.getNamespacePrefix();
            String cmdtName = prefix + 'FormulaShare_Rule__mdt';
            Test.startTest();
            Map<String,String> result = FormulaShareRuleDetailController.getTextFields(cmdtName);
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }


    // ---- getAccountLeadShareFieldOptions() ----

    @IsTest
    static void getAccountLeadShareFieldOptions_validObject_returnsList() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            List<FormulaShareRuleDetailController.ShareFieldOption> result =
                FormulaShareRuleDetailController.getAccountLeadShareFieldOptions('Account');
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }



    // ---- getSampleData() ----

    @IsTest
    static void getSampleData_nullParams_returnsNull() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            String result = FormulaShareRuleDetailController.getSampleData(null, null);
            Test.stopTest();
            System.assertEquals(null, result, 'Null params should return null');
        }
    }

    @IsTest
    static void getSampleData_validObjectAndField_returnsString() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // User.Name is a standard text field that exists in every org and has data (at least the running user)
            Test.startTest();
            String result = FormulaShareRuleDetailController.getSampleData('User', 'Name');
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }


    // ---- Inner class: ShareableObject ----

    @IsTest
    static void shareableObject_fieldsSet() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRuleDetailController.ShareableObject so = new FormulaShareRuleDetailController.ShareableObject();
            so.objectApiName = 'Account';
            so.objectLabel = 'Account';
            so.isCustom = false;
            System.assertEquals('Account', so.objectApiName);
            System.assertEquals(false, so.isCustom);
        }
    }


    // ---- Inner class: ShareFieldOption.compareTo() ----

    @IsTest
    static void shareFieldOption_compareTo_equal() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRuleDetailController.ShareFieldOption a = new FormulaShareRuleDetailController.ShareFieldOption();
            FormulaShareRuleDetailController.ShareFieldOption b = new FormulaShareRuleDetailController.ShareFieldOption();
            a.fieldLabel = 'Same';
            b.fieldLabel = 'Same';
            System.assertEquals(0, a.compareTo(b), 'Equal labels should return 0');
        }
    }

    @IsTest
    static void shareFieldOption_compareTo_greater() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRuleDetailController.ShareFieldOption a = new FormulaShareRuleDetailController.ShareFieldOption();
            FormulaShareRuleDetailController.ShareFieldOption b = new FormulaShareRuleDetailController.ShareFieldOption();
            a.fieldLabel = 'Zebra';
            b.fieldLabel = 'Apple';
            System.assert(a.compareTo(b) > 0, 'Zebra > Apple should be positive');
        }
    }

    @IsTest
    static void shareFieldOption_compareTo_less() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRuleDetailController.ShareFieldOption a = new FormulaShareRuleDetailController.ShareFieldOption();
            FormulaShareRuleDetailController.ShareFieldOption b = new FormulaShareRuleDetailController.ShareFieldOption();
            a.fieldLabel = 'Apple';
            b.fieldLabel = 'Zebra';
            System.assert(a.compareTo(b) < 0, 'Apple < Zebra should be negative');
        }
    }

}