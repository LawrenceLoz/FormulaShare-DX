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

public inherited sharing class FormulaShareLogs extends fflib_SObjectDomain {

    public FormulaShareLogs(List<FormulaShare_Log__c> sObjectList) {
        super(sObjectList);
    }

    public inherited sharing class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new FormulaShareLogs(sObjectList);
        }
    }

    String failedBatches;


    public void setContext(String className, Integer batchSize, String typeInScope, List<FormulaShareRule> rulesForType, String query) {

        for(FormulaShare_Log__c log : (List<FormulaShare_Log__c>) Records) {
            log.Class_Name__c = className;
            log.Type_In_Scope__c = typeInScope;
            log.Number_Of_Rules__c = rulesForType.size();
            log.Query__c = query;
            log.Batches_Processed__c = 0;
            log.Batches_Failed__c = 0;
            log.Failed_Batches__c = '';

            log.Processing_Started__c = DateTime.now();
            log.Processing_Started_Milliseconds__c = DateTime.now().getTime();

            system.debug('The query: '+query);
        }
    }

    public void logException(Exception e) {

        for(FormulaShare_Log__c log : (List<FormulaShare_Log__c>) Records) {
            log.Exception_Message__c = e.getMessage();
            log.Exception_Line_Number__c = e.getLineNumber();
            log.Exception_Stack_Trace__c = e.getStackTraceString();
            log.Exception_Type__c = e.getTypeName();
        }
    }

    public void incrementFailedBatches() {
        for(FormulaShare_Log__c log : (List<FormulaShare_Log__c>) Records) {
            log.Batches_Failed__c++;
            if(log.Failed_Batches__c == null || log.Failed_Batches__c.length() < 248) {
                log.Failed_Batches__c += String.valueOf(log.Batches_Processed__c) + ', ';
            }
        }
    }

    public void incrementBatches() {
        for(FormulaShare_Log__c log : (List<FormulaShare_Log__c>) Records) {
            log.Batches_Processed__c = log.Batches_Processed__c + 1;
        }
    }

    public void setBatchProcessingComplete() {
        for(FormulaShare_Log__c log : (List<FormulaShare_Log__c>) Records) {
            log.Batch_Finish_Complete__c = true;
        }
    }

    public void trimFailedBatches() {
        List<FormulaShare_Log__c> logs = (List<FormulaShare_Log__c>) Records;
        for(FormulaShare_Log__c log : logs) {
            if(log.Failed_Batches__c != null) {
                // Remove comma suffix and abbreviate if needed
                log.Failed_Batches__c = log.Failed_Batches__c.left(log.Failed_Batches__c.length() - 2);
                log.Failed_Batches__c = log.Failed_Batches__c.abbreviate(245);
            }
            else {
                log.Failed_Batches__c = 'None';
            }
        }
    }

    public List<FormulaShare_Log__c> setFinalisedLogs() {
        List<FormulaShare_Log__c> logs = (List<FormulaShare_Log__c>) Records;
        for(FormulaShare_Log__c log : logs) {
            log.Processing_Finished__c = DateTime.now();
            log.Processing_Finished_Milliseconds__c = DateTime.now().getTime();
        }
        return logs;
    }

}