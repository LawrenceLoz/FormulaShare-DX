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
public with sharing class FormulaShareRuleConverterStdTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }


    @IsTest
    static void getRule_returnsStandardRule() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // Instantiate directly — InjectionService returns FormulaShareRuleConverterAllTypes in main layer
            FormulaShareRuleConverterStandard converter = new FormulaShareRuleConverterStandard();
            FormulaShareRule sourceRule = FormulaShareRuleFactory.getUserRule();
            FormulaShare_Rule__mdt mdRule = converter.getMetadataRule(sourceRule);

            // Convert back to a rule via getRule
            FormulaShareRule result = converter.getRule(mdRule);

            System.assertNotEquals(null, result, 'getRule should return a non-null rule');
            System.assertEquals('standard', result.type, 'Rule type should be standard');
            System.assertNotEquals(null, result.developerName, 'Developer name should be set');
        }
    }

    @IsTest
    static void getMetadataRule_roundTrip() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRuleConverterStandard converter = new FormulaShareRuleConverterStandard();
            FormulaShareRule sourceRule = FormulaShareRuleFactory.getUserRule();

            FormulaShare_Rule__mdt mdRule = converter.getMetadataRule(sourceRule);

            System.assertNotEquals(null, mdRule, 'getMetadataRule should return a non-null record');
            System.assertEquals(
                sourceRule.controllingObjectSharedToFieldAPIName,
                mdRule.Shared_To__c,
                'Shared_To__c should match the source rule field'
            );
            System.assertEquals(
                sourceRule.controllingObjectSharedToFieldType,
                mdRule.Shared_To_Field_Type__c,
                'Shared_To_Field_Type__c should match'
            );
        }
    }

    @IsTest
    static void getMetadataRuleFromString_deserializesCorrectly() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            FormulaShareRuleConverterStandard converter = new FormulaShareRuleConverterStandard();
            FormulaShareRule sourceRule = FormulaShareRuleFactory.getUserRule();

            String ruleJson = JSON.serialize(sourceRule);
            FormulaShare_Rule__mdt mdRule = converter.getMetadataRuleFromString(ruleJson);

            System.assertNotEquals(null, mdRule, 'getMetadataRuleFromString should return a non-null record');
        }
    }

}
