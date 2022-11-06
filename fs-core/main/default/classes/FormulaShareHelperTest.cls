/**
*Copyright 2019 Lawrence Newcombe
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
public with sharing class FormulaShareHelperTest {

    @TestSetup
    public static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }

    @IsTest
    public static void testCorrectDefaultType() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
            FormulaShareSettingsSelector.mock = mockFSSettingsSelector;

            FormulaShareHelper helper = new FormulaShareHelper();

            system.assert(helper.iHelper instanceof FormulaShareTriggerHelper, 'Expected an instance of FormulaShareTriggerHelper');
        }
    }

    @IsTest
    public static void testGetSharesToInsert() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
            FormulaShareSettingsSelector.mock = mockFSSettingsSelector;

            FormulaShareHelper helper = new FormulaShareHelper();

            List<FormulaShare_Log__Share> sharesToInsert = (List<FormulaShare_Log__Share>) helper.getSharesToInsert();

            system.assert(sharesToInsert.isEmpty(), 'No records expected (implementation not run from trigger context)');
        }
    }

    @IsTest
    public static void testGetSharesToDelete() {

        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareSettingsSelector mockFSSettingsSelector = (FormulaShareSettingsSelector) FormulaShareMockUtil.createMock(FormulaShareSettingsSelector.class);
            FormulaShareSettingsSelector.mock = mockFSSettingsSelector;

            FormulaShareHelper helper = new FormulaShareHelper();

            List<FormulaShare_Log__Share> sharesToDelete = (List<FormulaShare_Log__Share>) helper.getSharesToDelete();

            system.assert(sharesToDelete.isEmpty(), 'No records expected (implementation not run from trigger context)');
        }
    }
    
}