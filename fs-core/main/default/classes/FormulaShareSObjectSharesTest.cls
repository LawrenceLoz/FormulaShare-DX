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
public with sharing class FormulaShareSObjectSharesTest {
    
    public static List<FormulaShare_Log__Share> getSharesListForLog(FormulaShare_Log__c log) {

        // Build a share object linked to the log record which is ready to be inserted
        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'AllInternalUsers'][0];
        FormulaShare_Log__Share share = new FormulaShare_Log__Share();
        share.UserOrGroupId = publicGroup.Id;
        share.ParentId = log.Id;
        share.AccessLevel = 'Read';
        share.RowCause = 'FormulaShare_Log_Share__c';

        // Create and return list with this object
        List<FormulaShare_Log__Share> sharesList = new List<FormulaShare_Log__Share>();
        sharesList.add(share);
        return sharesList;
    }

    @TestSetup
    static void makeData(){
        // Create a log object and set fields which have test rules created within apex class
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
        insert log;
    }


    @IsTest
    public static void testInsertShares() {
        
        FormulaShare_Log__c log = [SELECT Id FROM FormulaShare_Log__c WHERE Type_In_Scope__c = 'AllInternalUsers'][0];
        
        // Set constructor parameters
        List<FormulaShare_Log__Share> sharesList = getSharesListForLog(log);
        Schema.SObjectType fsLogShareType = Schema.getGlobalDescribe().get('FormulaShare_Log__Share');

        // Construct domain instance
        FormulaShareSObjectShares sharesDomain = FormulaShareSObjectShares.construct(sharesList, fsLogShareType);

        // Attempt to insert share
        sharesDomain.insertShares();

        // Look for inserted record and assert values
        List<FormulaShare_Log__Share> insertedShares = [SELECT Id, ParentId FROM FormulaShare_Log__Share WHERE RowCause = 'FormulaShare_Log_Share__c'];
        system.assert(!insertedShares.isEmpty(), 'No share record inserted');
        system.assertEquals(1, insertedShares.size(), 'More than one share record inserted');
        system.assertEquals(log.Id, insertedShares[0].ParentId, 'Share is for wrong log record');
    }


    @IsTest
    public static void testInsertExceptionCaught() {
        
        FormulaShare_Log__c log = [SELECT Id FROM FormulaShare_Log__c WHERE Type_In_Scope__c = 'AllInternalUsers'][0];
        
        // Set constructor parameters
        List<FormulaShare_Log__Share> sharesList = getSharesListForLog(log);
        sharesList[0].AccessLevel = 'Not an allowed value';
        Schema.SObjectType fsLogShareType = Schema.getGlobalDescribe().get('FormulaShare_Log__Share');

        // Construct domain instance
        FormulaShareSObjectShares sharesDomain = FormulaShareSObjectShares.construct(sharesList, fsLogShareType);

        // Attempt to insert share
        sharesDomain.insertShares();

        // Look for inserted record and check nothing found
        List<FormulaShare_Log__Share> insertedShares = [SELECT Id, ParentId FROM FormulaShare_Log__Share WHERE RowCause = 'FormulaShare_Log_Share__c'];
        system.assert(insertedShares.isEmpty(), 'Share record not deleted');
    }


    @IsTest
    public static void testDeleteExceptionCaught() {
        
        FormulaShare_Log__c log = [SELECT Id FROM FormulaShare_Log__c WHERE Type_In_Scope__c = 'AllInternalUsers'][0];
        
        // Set constructor parameters
        List<FormulaShare_Log__Share> sharesList = getSharesListForLog(log);
        Schema.SObjectType fsLogShareType = Schema.getGlobalDescribe().get('FormulaShare_Log__Share');

        // Construct domain instance
        FormulaShareSObjectShares sharesDomain = FormulaShareSObjectShares.construct(sharesList, fsLogShareType);

        // Attempt to delete share before inserting
        sharesDomain.deleteShares();

        // Check no shares
        List<FormulaShare_Log__Share> insertedShares = [SELECT Id, ParentId FROM FormulaShare_Log__Share WHERE RowCause = 'FormulaShare_Log_Share__c'];
        system.assert(insertedShares.isEmpty(), 'Share record remains');
    }

    @IsTest
    public static void testContructor() {
        FormulaShareSObjectShares.Constructor cons = new FormulaShareSObjectShares.Constructor();

        FormulaShare_Log__c log = [SELECT Id FROM FormulaShare_Log__c WHERE Type_In_Scope__c = 'AllInternalUsers'][0];
        // Set constructor parameters
        List<FormulaShare_Log__Share> sharesList = getSharesListForLog(log);
        Schema.SObjectType fsLogShareType = Schema.getGlobalDescribe().get('FormulaShare_Log__Share');

        fflib_SObjectDomain sharesDomain = cons.construct(sharesList, fsLogShareType);
        List<FormulaShare_Log__Share> shares = (List<FormulaShare_Log__Share>) sharesDomain.Records;

        system.assertEquals(log.Id, shares[0].ParentId, 'Records does not contain a share for the create log');
    }

}