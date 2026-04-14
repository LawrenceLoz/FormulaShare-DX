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
public with sharing class FormulaShareTeamMappingSvcTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin(true);
    }


    // ---- FormulaShareTeamMappingService (base/core class) ----

    @IsTest
    static void baseClass_getActiveTeamMappings_returnsEmptyList() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            FormulaShareTeamMappingService svc = new FormulaShareTeamMappingService();
            List<FormulaShareTeamMappingService.TeamMappingOption> result = svc.getActiveTeamMappings();
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(0, result.size(), 'Base class should return empty list');
        }
    }

    @IsTest
    static void baseClass_getTeamFieldOptions_returnsEmptyList() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            FormulaShareTeamMappingService svc = new FormulaShareTeamMappingService();
            List<FormulaShareTeamMappingService.TeamFieldOption> result =
                svc.getTeamFieldOptions('User', 'User', 'User');
            Test.stopTest();
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(0, result.size(), 'Base class should return empty list');
        }
    }

    @IsTest
    static void baseClass_getTeamObjectLabel_returnsEmptyString() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Test.startTest();
            FormulaShareTeamMappingService svc = new FormulaShareTeamMappingService();
            String result = svc.getTeamObjectLabel('User');
            Test.stopTest();
            System.assertEquals('', result, 'Base class should return empty string');
        }
    }

    @IsTest
    static void teamMappingOption_fieldsSet() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareTeamMappingService.TeamMappingOption opt = new FormulaShareTeamMappingService.TeamMappingOption();
            opt.developerName = 'TestMapping';
            opt.label = 'Test Mapping';
            opt.teamObjectApiName = 'Account';
            opt.teamNameFieldApiName = 'Name';
            System.assertEquals('TestMapping', opt.developerName);
            System.assertEquals('Account', opt.teamObjectApiName);
        }
    }

    @IsTest
    static void teamFieldOption_fieldsSet() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareTeamMappingService.TeamFieldOption opt = new FormulaShareTeamMappingService.TeamFieldOption();
            opt.fieldApiName = 'Name';
            opt.fieldLabel = 'Full Name';
            opt.fieldCategory = 'Text';
            opt.isIdType = false;
            System.assertEquals('Name', opt.fieldApiName);
            System.assertEquals(false, opt.isIdType);
        }
    }

}
