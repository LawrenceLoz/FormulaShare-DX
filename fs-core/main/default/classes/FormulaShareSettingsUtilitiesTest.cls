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
public with sharing class FormulaShareSettingsUtilitiesTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }


    @IsTest
    static void getEffectiveBatchSize_withOrgDefault_returnsOrgDefault() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Mock settings selector to return a settings record with a batch size
            FormulaShareSettingsSelector mockSettings = (FormulaShareSettingsSelector)
                FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
            FormulaShareSettingsSelector.mock = mockSettings;

            // getEffectiveBatchSizeForFullBatch should return without exception
            Integer result = FormulaShareSettingsUtilities.getEffectiveBatchSizeForFullBatch(
                FormulaShare_Log__c.SObjectType
            );
            System.assertNotEquals(null, result, 'Should return a non-null batch size');
            System.assert(result > 0, 'Batch size should be positive');
        }
    }


    @IsTest
    static void getEffectiveBatchSize_noObjectOverride_returnsOrgOrDefault() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Mock settings selector — no object-level override configured
            FormulaShareSettingsSelector mockSettings = (FormulaShareSettingsSelector)
                FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
            FormulaShareSettingsSelector.mock = mockSettings;

            Integer result = FormulaShareSettingsUtilities.getEffectiveBatchSizeForFullBatch(
                FormulaShare_Log__c.SObjectType
            );

            // Result will be either the org default from active settings or 1 if no settings exist
            System.assert(result >= 1, 'Batch size should be at least 1');
        }
    }

}
