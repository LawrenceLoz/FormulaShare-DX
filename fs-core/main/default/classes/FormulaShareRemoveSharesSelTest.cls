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
public with sharing class FormulaShareRemoveSharesSelTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }

    @IsTest
    static void construct_returnsInstance() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRemoveSharesSelector sel = FormulaShareRemoveSharesSelector.construct();
            System.assertNotEquals(null, sel);
        }
    }

    @IsTest
    static void getSettingsList_returnsListForAccount() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRemoveSharesSelector sel = new FormulaShareRemoveSharesSelector();
            // Account is a standard object likely to have settings configured
            List<FormulaShare_Std_Object_to_Remove_Shares__mdt> results = sel.getSettingsList('Account');
            // Result may be empty if no CMDT record configured — just verify no exception
            System.assertNotEquals(null, results);
        }
    }

    @IsTest
    static void getAllSettings_returnsList() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRemoveSharesSelector sel = new FormulaShareRemoveSharesSelector();
            List<FormulaShare_Std_Object_to_Remove_Shares__mdt> results = sel.getAllSettings();
            System.assertNotEquals(null, results);
        }
    }

    @IsTest
    static void getSettingsForType_queriesAndCaches() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRemoveSharesSelector sel = new FormulaShareRemoveSharesSelector();
            // First call — queries and caches
            FormulaShare_Std_Object_to_Remove_Shares__mdt first = sel.getSettingsForType(Account.SObjectType);
            // Second call — should return from cache (no second query)
            FormulaShare_Std_Object_to_Remove_Shares__mdt second = sel.getSettingsForType(Account.SObjectType);
            // Both calls return same result (either null if not configured, or the CMDT record)
            System.assertEquals(first, second, 'Second call should return cached result');
        }
    }

    @IsTest
    static void getObjectsWhereFullBatchUnsupported_returnsEmptySet() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRemoveSharesSelector sel = new FormulaShareRemoveSharesSelector();
            Set<String> result = sel.getObjectsWhereFullBatchUnsupported();
            System.assertNotEquals(null, result);
            System.assert(result.isEmpty(), 'Base implementation should return empty set');
        }
    }

}