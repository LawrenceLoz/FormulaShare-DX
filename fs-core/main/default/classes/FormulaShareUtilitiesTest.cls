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

        // Check we can get a token for the field Context__c on FormulaShare_Log__c
        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        String fieldNameWithPrefix = FormulaShareTestUtils.getNamespacePrefix() + 'Context__c';
        SObjectField classNameField = FormulaShareUtilities.getSObjectFieldFromName(fieldNameWithPrefix, fsLogType);

		SObjectField sObjField = FormulaShare_Log__c.Context__c.getDescribe().getSObjectField();

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

// Method is now part of FormulaShareRule
//    @IsTest
//    public static void testGetShareRecordKeyCustom() {
//        FormulaShare_Log__Share share = new FormulaShare_Log__Share();
//        share.UserOrGroupId = UserInfo.getUserId();  // Any valid id
//        share.ParentId = UserInfo.getUserId();  // Any valid id
//        share.AccessLevel = 'Read';
//        share.RowCause = 'FormulaShare_Log_Share__c';
//
//        String shareKey = FormulaShareUtilities.getShareRecordKey(share);
//
//        String idString = FormulaShareIdUtilities.get15CharacterId(UserInfo.getUserId());
//        String expectedKey = idString + idString + 'Read' + 'FormulaShare_Log_Share__c';
//        system.assertEquals(expectedKey, shareKey);
//    }
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

        String idString = FormulaShareIdUtilities.get15CharacterId(UserInfo.getUserId());
        String expectedKey = idString + idString + 'Read';
        system.assertEquals(expectedKey, shareKey);
    }   */


    @IsTest
    public static void checkChildRelationships() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        List<FormulaShareUtilities.RelationshipDetails> crds = FormulaShareUtilities.getChildRelationships(prefix + 'FormulaShare_Log__c');
        Boolean foundRibRelationship = false;
        for(FormulaShareUtilities.RelationshipDetails crd : crds) {
            if(crd.relatedObjectApiName.contains('FormulaShare_Rule_in_Batch__c')) {
                System.assert(crd.relatedFieldApiName.contains('FormulaShare_Log__c'), 'Relationship name is different to the one expected');
                foundRibRelationship = true;
            }
        }
        System.assert(foundRibRelationship, 'Didnt find the relationship with FS rules in batch');
    }


    @IsTest
    public static void checkGetShareFields() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        List<Schema.SObjectField> fields = FormulaShareUtilities.getShareFields(prefix + 'FormulaShare_Log__c');

        // Check a user lookup and a text field are both included, but lookup to another object isn't
        Boolean foundUser = false;
        Boolean foundText = false;
        Boolean foundOtherLookup = false;
        for(Schema.SObjectField field : fields) {
            System.debug(field.getDescribe().getName());
            if(field.getDescribe().getName().contains('LastModifiedById')) foundUser = true;
            if(field.getDescribe().getName().contains('Context__c')) foundText = true;
            if(field.getDescribe().getName().contains('Related_Log_Required_for_Test_Class__c')) foundOtherLookup = true;
        }

        System.assert(foundUser, 'Didnt find user lookup');
        System.assert(foundText, 'Didnt find text lookup');
        System.assert(!foundOtherLookup, 'Other lookup also returned');
    }


    @IsTest
    public static void testGetSharingReasons() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        Map<String,String> reasons = FormulaShareUtilities.getSharingReasons(prefix + 'FormulaShare_Log__c');

        Boolean foundReason = false;
        for(String key : reasons.keySet()) {
            if(key.contains('FormulaShare_Log_Share__c')) {
                foundReason = true;
                System.assertEquals('FormulaShare Batch Log Share', reasons.get(key), 'Label mismatch');
            }
        }
        System.assert(foundReason, 'Didnt find FormulaShare Batch Log Share sharing reason');
    }

}