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
public with sharing class FormulaShareLWCUtilitiesTest {

    @TestSetup
    static void setup() {
        FormulaShareTestUtils.setupAdmin();
    }

    @IsTest
    static void getNamespacePrefix_returnsString() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String ns = FormulaShareLWCUtilities.getNamespacePrefix();
            // Returns either 'sdfs__' or '' — just verify it doesn't throw and is non-null
            System.assertNotEquals(null, ns, 'Namespace prefix should not be null');
        }
    }

    @IsTest
    static void getLightningDomain_returnsLightningUrl() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String domain = FormulaShareLWCUtilities.getLightningDomain();
            System.assertNotEquals(null, domain, 'Lightning domain should not be null');
            System.assert(domain.contains('lightning.force.com'), 'Should contain lightning.force.com: ' + domain);
        }
    }

    @IsTest
    static void getClassicDomain_returnsUrl() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            String domain = FormulaShareLWCUtilities.getClassicDomain();
            System.assertNotEquals(null, domain, 'Classic domain should not be null');
            System.assert(domain.startsWith('https://'), 'Should be an https URL: ' + domain);
        }
    }

    @IsTest
    static void getSharingReasons_returnsMap() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            // FormulaShare_Log__c has sharing reasons defined
            Map<String, String> reasons = FormulaShareLWCUtilities.getSharingReasons(
                FormulaShareTestUtils.getNamespacePrefix() + 'FormulaShare_Log__c'
            );
            System.assertNotEquals(null, reasons, 'Sharing reasons map should not be null');
        }
    }

    @IsTest
    static void isContactSharingControlledByAccount_returnsBoolean() {
        System.runAs(FormulaShareTestUtils.getAdmin()) {
            Boolean result = FormulaShareLWCUtilities.isContactSharingControlledByAccount();
            // Result is org-dependent — just verify it executes without exception
            System.assertNotEquals(null, result);
        }
    }

}
