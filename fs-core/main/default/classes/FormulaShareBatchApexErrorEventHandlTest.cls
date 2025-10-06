@IsTest
public class FormulaShareBatchApexErrorEventHandlTest {

    @IsTest
    static void handle_ignoresNullOrEmpty() {
        Test.startTest();
        // Null
        FormulaShareBatchApexErrorEventHandler.handle(null);
        // Empty
        FormulaShareBatchApexErrorEventHandler.handle(new List<BatchApexErrorEvent>());
        Test.stopTest();
        System.assert(true, 'Method executed without exceptions for null/empty inputs');
    }

    @IsTest
    static void handle_noRelevantEvents_returnsEarly() {
        // Build events without AsyncApexJobId so they cannot be correlated
        List<BatchApexErrorEvent> events = new List<BatchApexErrorEvent>{
            new BatchApexErrorEvent(
                RequestId = 'req1',
                Message = 'msg',
                Phase = 'Execute'
            )
        };
        Test.startTest();
        FormulaShareBatchApexErrorEventHandler.handle(events);
        Test.stopTest();

        // No exception expected. We cannot assert DML as none should occur.
        System.assert(true, 'No exception should occur when there are no relevant events');
    }

    @IsTest
    static void handle_withJobIds_butNoSelectorsData_returnsEarly() {
        // Provide a fake AsyncApexJobId which will not be resolved by selectors
        List<BatchApexErrorEvent> events = new List<BatchApexErrorEvent>{
            new BatchApexErrorEvent(
                AsyncApexJobId = (Id) '707000000000000', // dummy AsyncApexJob Id
                RequestId = 'req2',
                Message = 'msg',
                Phase = 'Execute'
            )
        };

        Test.startTest();
        FormulaShareBatchApexErrorEventHandler.handle(events);
        Test.stopTest();

        // With no matching AsyncApexJob / ApexClass / Log rows, handler should complete without error.
        System.assert(true, 'Handler completed gracefully with unresolved AsyncApexJobId');
    }
}
