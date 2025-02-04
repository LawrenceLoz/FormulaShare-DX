@isTest
private class FormulaShareLWCSchedulingServiceTest {

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
    User currentUser = [SELECT Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
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

}