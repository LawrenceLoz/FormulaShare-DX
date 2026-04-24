@isTest
public with sharing class FormulaShareLWCSchedulingServiceTest {

  @IsTest
  static void testGetCurrentlyScheduledCron() {
    // GIVEN - Schedule a job to run daily at 8am
    String cronExp = '0 0 8 ? * * *';
    String jobName = 'FormulaShare Full Recalculation';
    Test.startTest();
    
    // Schedule the job
    FormulaShareProcessSchedulable scheduler = new FormulaShareProcessSchedulable();
    String jobId = System.schedule(jobName, cronExp, scheduler);
    
    // WHEN - Get the scheduled job info
    FormulaShareLWCSchedulingService.ScheduledJobInfo jobInfo = 
        FormulaShareLWCSchedulingService.getCurrentlyScheduledCron();
    
    Test.stopTest();
    
    // THEN - Verify the job info
    System.assertNotEquals(null, jobInfo, 'Should return job info');
    System.assertEquals(cronExp, jobInfo.cronExpression, 'Should return correct cron expression');
    System.assertEquals(jobName, jobInfo.jobName, 'Should return correct job name');
    System.assertNotEquals(null, jobInfo.cronTriggerId, 'Should have a cron trigger ID');
    System.assertNotEquals(null, jobInfo.nextFireTime, 'Should have next fire time');
    
    // Verify user info
    User currentUser = [SELECT Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
    System.assertEquals(currentUser.Name, jobInfo.usersName, 'Should return current user name');
    System.assertEquals(currentUser.Profile.Name, jobInfo.usersProfile, 'Should return current user profile');
    System.assertEquals(UserInfo.getUserId(), jobInfo.usersId, 'Should return current user ID');
  }

  @IsTest
  static void testGetCurrentlyScheduledCron_NoJobScheduled() {
    // GIVEN - No job scheduled
    Test.startTest();

    // WHEN - Get the scheduled job info
    FormulaShareLWCSchedulingService.ScheduledJobInfo jobInfo =
        FormulaShareLWCSchedulingService.getCurrentlyScheduledCron();

    Test.stopTest();

    // THEN - Verify null is returned
    System.assertEquals(null, jobInfo, 'Should return null when no job is scheduled');
  }


  @IsTest
  static void testGetCurrentDateTime() {
    Datetime before = Datetime.now();
    Datetime result = FormulaShareLWCSchedulingService.getCurrentDateTime();
    Datetime after = Datetime.now();

    System.assertNotEquals(null, result, 'getCurrentDateTime should return a non-null Datetime');
    System.assert(result >= before && result <= after, 'getCurrentDateTime should return a recent Datetime');
  }


  @IsTest
  static void testScheduleJob_succeeds() {
    String cronExp = '0 0 9 ? * * *';
    String jobName = 'Test FS Schedule Job';

    Test.startTest();
    Boolean result = FormulaShareLWCSchedulingService.scheduleJob(cronExp, jobName);
    Test.stopTest();

    System.assert(result, 'scheduleJob should return true on success');
  }


  @IsTest
  static void testScheduleJob_failsOnInvalidCron() {
    Test.startTest();
    Boolean result = FormulaShareLWCSchedulingService.scheduleJob('INVALID_CRON', 'Bad Job');
    Test.stopTest();

    System.assert(!result, 'scheduleJob should return false when an exception is thrown');
  }


  @IsTest
  static void testDeleteScheduledJob_succeeds() {
    String cronExp = '0 0 10 ? * * *';
    String jobName = 'Test FS Delete Schedule Job';
    FormulaShareProcessSchedulable scheduler = new FormulaShareProcessSchedulable();
    // System.schedule() returns the CronTriggerId directly
    Id cronTriggerId = System.schedule(jobName, cronExp, scheduler);

    Test.startTest();
    Boolean result = FormulaShareLWCSchedulingService.deleteScheduledJob(cronTriggerId);
    Test.stopTest();

    System.assert(result, 'deleteScheduledJob should return true on success');
  }


  @IsTest
  static void testDeleteScheduledJob_failsOnInvalidId() {
    Id fakeId = fflib_IDGenerator.generate(CronTrigger.SObjectType);

    Test.startTest();
    Boolean result = FormulaShareLWCSchedulingService.deleteScheduledJob(fakeId);
    Test.stopTest();

    System.assert(!result, 'deleteScheduledJob should return false when job does not exist');
  }

}