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
public with sharing class FormulaShareUtilitiesTest {

    @IsTest
    public static void testGetSObjectFieldFromName() {

        // Check we can get a token for the field Class_Name__c on FormulaShare_Log__c
        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        String fieldNameWithPrefix = FormulaShareTestUtils.getNamespacePrefix() + 'Class_Name__c';
        SObjectField classNameField = FormulaShareUtilities.getSObjectFieldFromName(fieldNameWithPrefix, fsLogType);

		SObjectField sObjField = FormulaShare_Log__c.Class_Name__c.getDescribe().getSObjectField();

        system.assertEquals(sObjField, classNameField);
    }


    @IsTest
    public static void testGetSObjectFieldFromRelatedName() {

        // Look for the field on Contact with the relationship name "Account" (this should be the AccountId field)
        Schema.SObjectType conType = Contact.SObjectType;
        SObjectField accuontFieldOnContact = FormulaShareUtilities.getSObjectFieldFromRelatedName('Account', conType);

		SObjectField sObjField = Contact.AccountId.getDescribe().getSObjectField();

        system.assertEquals(sObjField, accuontFieldOnContact);
    }


    @IsTest
    public static void testGetShareRecordKeyCustom() {
        FormulaShare_Log__Share share = new FormulaShare_Log__Share();
        share.UserOrGroupId = UserInfo.getUserId();  // Any valid id
        share.ParentId = UserInfo.getUserId();  // Any valid id
        share.AccessLevel = 'Read';
        share.RowCause = 'FormulaShare_Log_Share__c';

        String shareKey = FormulaShareUtilities.getShareRecordKeyCustom(share);

        String idString = FormulaShareUtilities.get15CharacterId(UserInfo.getUserId());
        String expectedKey = idString + idString + 'Read' + 'FormulaShare_Log_Share__c';
        system.assertEquals(expectedKey, shareKey);
    }
/*
    @IsTest
    public static void testGetShareRecordKeyStandard() {

        // Get token for an SObject (we use FormulaShare_Log__c rather than a standard object because we know it will have a share table)
        Schema.SObjectType fsLogType = Schema.getGlobalDescribe().get('FormulaShare_Log__c');

        FormulaShare_Log__Share share = new FormulaShare_Log__Share();
        share.UserOrGroupId = UserInfo.getUserId();  // Any valid id
        share.ParentId = UserInfo.getUserId();  // Any valid id
        share.AccessLevel = 'Read';

        String shareKey = FormulaShareUtilities.getShareRecordKeyStandard(fsLogType, share);

        String idString = FormulaShareUtilities.get15CharacterId(UserInfo.getUserId());
        String expectedKey = idString + idString + 'Read';
        system.assertEquals(expectedKey, shareKey);
    }   */


    @IsTest 
    public static void testPassNullIdToGet15CharacterId() {
        FormulaShareUtilities fsUtil = FormulaShareUtilities.construct();   // Will run code to generate non-mock object
        String idStringFromNull = fsUtil.get15CharacterIdInstance(null);    // Runs instance implementation without mocking
        system.assertEquals(null, idStringFromNull);        // Checks that static implementation returns null if passed null
    }

}
