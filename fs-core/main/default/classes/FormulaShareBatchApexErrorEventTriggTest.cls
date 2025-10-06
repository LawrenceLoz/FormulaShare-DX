@IsTest
private class FormulaShareBatchApexErrorEventTriggTest {

    @isTest
    static void testErrorEventTrigger() {
        // Create a simulated BatchApexErrorEvent
        BatchApexErrorEvent eventRecord = new BatchApexErrorEvent(
            JobScope = '[{"records":["001xxxxxxxxxxxx"],"size":1}]',
            ExceptionType = 'System.NullPointerException',
            Message = 'Attempt to de-reference a null object',
            StackTrace = 'Trigger.MyBatchTrigger: line 42, column 1',
            AsyncApexJobId = '707xxxxxxxxxxxx'
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(eventRecord);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Event should be published successfully');
        System.assert(FormulaShareBatchApexErrorEventHandler.wasCalled, 'Trigger called handler method');
    }

}
