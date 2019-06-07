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
public with sharing class FormulaSharePostInstallTest {
    
    @IsTest
    static void testJobScheduledOnFirstInstall() {

        FormulaSharePostInstall postInstall = new FormulaSharePostInstall();

        // Use a different job name so unit tests not affected by existing scheduled jobs
        String jobName = 'Apex unit test FormulaShare Full Recal';
        postInstall.jobName = jobName;

        // Carry out a mock installation
        Test.testInstall(postInstall, null);

		// Check that cron job created correctly
        List<CronJobDetail> cjd = [SELECT Id, Name, JobType FROM CronJobDetail WHERE Name = :jobName];
        System.assert(cjd.size() == 1);
        System.assertEquals('7', cjd[0].JobType);
    }
}
