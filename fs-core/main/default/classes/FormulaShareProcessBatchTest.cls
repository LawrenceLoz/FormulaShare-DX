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
public with sharing class FormulaShareProcessBatchTest {

    static void setMocks() {
        FormulaShareService mockFSService = (FormulaShareService) FormulaShareMockUtil.createMock(FormulaShareService.class);
        FormulaShareService.mock = mockFSService;

        FormulaShareSObjectShares mockFSSObjectShares = (FormulaShareSObjectShares) FormulaShareMockUtil.createMock(FormulaShareSObjectShares.class);
        FormulaShareSObjectShares.mock = mockFSSObjectShares;

        FormulaShareRulesSelector mockFSRulesSelector = (FormulaShareRulesSelector) FormulaShareMockUtil.createMock(FormulaShareRulesSelector.class);
        FormulaShareRulesSelector.mock = mockFSRulesSelector;
    }

    @IsTest
    static void checkBatchRunsAsExpected() {
        setMocks();

        // Create a log object in scope of mock rule so that execute method can be invoked
        FormulaShare_Log__c log = new FormulaShare_Log__c();
        log.Type_In_Scope__c = 'AllInternalUsers';    // Share with group (name)
        log.Exception_Type__c = UserInfo.getUserId();  // Share with user (Id)
        insert log;

        List<Schema.SObjectType> types = new List<Schema.SObjectType>();
        Schema.SObjectType fsLogType = FormulaShare_Log__c.SObjectType;
        types.add(fsLogType);
        FormulaShareProcessBatch batchObj = new FormulaShareProcessBatch(types, 1);

        // Call recalculate method to set sharing (mocks are set so only DML should be the log record itself)
        test.startTest();
		Id batchJobId = Database.executeBatch(batchObj, 1);
        test.stopTest();

        // Check one log has been inserted for process
        List<FormulaShare_Log__c> insertedLogs = [SELECT Query__c, Batches_Processed__c, Exception_Type__c 
            FROM FormulaShare_Log__c WHERE Type_In_Scope__c LIKE '%FormulaShare_Log__c'];

        system.debug('*** inserted logs: '+insertedLogs);

        system.assert(!insertedLogs.isEmpty(), 'No log record created for batch process');
        system.assertEquals(1, insertedLogs.size(), 'Only one log expected, but more than one created');
        system.assertEquals(1, insertedLogs[0].Batches_Processed__c);
    }

}
