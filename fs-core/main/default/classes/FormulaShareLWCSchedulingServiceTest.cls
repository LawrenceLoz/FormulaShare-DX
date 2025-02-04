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

  @IsTest
  static void testGetCurrentlyScheduledCron_WithoutUserAccess() {
    // GIVEN - Schedule a job
    String cronExp = '0 0 8 ? * * *';
    String jobName = 'FormulaShare Full Recalculation';
    FormulaShareProcessSchedulable scheduler = new FormulaShareProcessSchedulable();
    String jobId = System.schedule(jobName, cronExp, scheduler);
    
    // Create a user without access to User object
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
    User testUser = new User(
        Alias = 'standt',
        Email = 'standarduser@testorg.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Testing',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'standarduser@testorg.com' + System.currentTimeMillis()
    );
    
    Test.startTest();
    
    System.runAs(testUser) {
        // WHEN - Get the scheduled job info as restricted user
        FormulaShareLWCSchedulingService.ScheduledJobInfo jobInfo = 
            FormulaShareLWCSchedulingService.getCurrentlyScheduledCron();
        
        // THEN - Verify job info returned with hidden user details
        System.assertNotEquals(null, jobInfo, 'Should return job info');
        System.assertEquals('<hidden>', jobInfo.usersName, 'Should hide user name');
        System.assertEquals('<hidden>', jobInfo.usersProfile, 'Should hide user profile');
        System.assertEquals(null, jobInfo.usersId, 'Should not return user ID');
    }
    
    Test.stopTest();
  }
}