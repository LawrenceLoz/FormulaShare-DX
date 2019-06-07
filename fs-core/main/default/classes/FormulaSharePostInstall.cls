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

global class FormulaSharePostInstall implements InstallHandler {

    @TestVisible private String jobName = 'FormulaShare full recalculation';

    global void onInstall(InstallContext context) {

        // Schedule batch job on first install
        if(context.previousVersion() == null) {

            // Schedule to run job daily at 11pm
            String sch = '0 0 23 ? * *';

            // Create log record
			FormulaShare_Log__c log = new FormulaShare_Log__c();
			List<FormulaShare_Log__c> logsList = new List<FormulaShare_Log__c>();
			logsList.add(log);
			FormulaShareLogs fsLogs = new FormulaShareLogs(logsList);

            try {
                String jobId = System.schedule(jobName, sch, new FormulaShareProcessSchedulable());
                fsLogs.setContext('FormulaSharePostInstall', 'onInstall', 'Batch recalculation job scheduled for 11pm each day');
            }
            catch(Exception e) {
                fsLogs.setContext('FormulaSharePostInstall', 'onInstall', 'Batch recalculation job could not be scheduled, see exception details');
                fsLogs.logException(e);
            }
            finally {
                fsLogs.upsertLogs();
            }
        }
    }
}