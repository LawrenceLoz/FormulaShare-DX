/**
*Copyright 2025 Lawrence Newcombe
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

// Adapted from https://github.com/schandlergarcia/lwc-scheduler-service
public with sharing class FormulaShareLWCSchedulingService {

  public class ScheduledJobInfo {
    @AuraEnabled public Id id;
    @AuraEnabled public Id cronTriggerId;
    @AuraEnabled public String cronExpression;
    @AuraEnabled public Datetime nextFireTime;
    @AuraEnabled public String jobName;
    @AuraEnabled public String usersName;
    @AuraEnabled public String usersProfile;
    @AuraEnabled public Id usersId;
  }

  /**
   * The setup utilities are used to manage scheduled jobs throughout the app. With these you can see the details
   * of a schedule job, schedule a job, or delete a scheduled job.
   */
  @AuraEnabled
  public static Datetime getCurrentDateTime() {
    return Datetime.now();
  }

  @AuraEnabled
  public static ScheduledJobInfo getCurrentlyScheduledCron() {

    // Return both FormulaShareSchedulableSubmitter and FormulaShareProcessSchedulable in case wrong class is scheduled
    List<String> classNames = new List<String>{'FormulaShareProcessSchedulable', 'FormulaShareSchedulableSubmitter'};
    List<AsyncApexJob> asyncApexJobs = new FormulaShareAsyncApexJobSelector().getScheduledJobsWithCronTriggerFields(classNames);

    // Construct ScheduledJobInfo from AsyncApexJob if one exists
    if (!asyncApexJobs.isEmpty()) {
      AsyncApexJob asyncApexJob = asyncApexJobs[0];   // Just use the first one
      ScheduledJobInfo jobInfo = new ScheduledJobInfo();

      // Need to query separately as we can't use related syntax for the job owner
      List<User> uList = [
        SELECT Name, Profile.Name FROM User 
        WHERE Id = :asyncApexJobs[0].CronTrigger.OwnerId 
        WITH SECURITY_ENFORCED
        LIMIT 1];
    
      // If running user doesn't have permissions list could be empty
      if(asyncApexJobs[0].CronTrigger.OwnerId == null || uList.isEmpty()) {
        String usersName = '<hidden>';
        String usersProfile = '<hidden>';
      }
      // Otherwise return user's name
      else {
        jobInfo.usersName = uList[0].Name;
        jobInfo.usersProfile = uList[0].Profile.Name;
        jobInfo.usersId = asyncApexJobs[0].CronTrigger.OwnerId;
      }

      jobInfo.id = asyncApexJob.Id;
      jobInfo.cronTriggerId = asyncApexJob.CronTriggerId;
      jobInfo.cronExpression = asyncApexJob.CronTrigger.CronExpression;
      jobInfo.jobName = asyncApexJob.CronTrigger.CronJobDetail.Name;

      // Next fire time is a DateTime field, but cron triggers are managed in UTC(GMT), so convert
      Datetime nextFireTimeDt = asyncApexJob.CronTrigger.NextFireTime;
      jobInfo.nextFireTime = Datetime.newInstanceGmt(
        nextFireTimeDt.year(),
        nextFireTimeDt.month(),
        nextFireTimeDt.day(),
        nextFireTimeDt.hour(),
        nextFireTimeDt.minute(),
        nextFireTimeDt.second());
      return jobInfo;
    }
    else {
      return null;
    }
  }

  @AuraEnabled
  public static Boolean scheduleJob(String cronString, String cronJobName) {
    try {
      FormulaShareProcessSchedulable scheduler = new FormulaShareProcessSchedulable();
      System.schedule(cronJobName, cronString, scheduler);
      return true;
    } catch (Exception e) {
      System.debug(e.getMessage());
      return false;
    }
  }

  @AuraEnabled
  public static Boolean deleteScheduledJob(Id cronTriggerId) {
    try {
      System.abortJob(cronTriggerId);
      return true;
    } catch (Exception e) {
      System.debug(e.getMessage());
      return false;
    }
  }
}
