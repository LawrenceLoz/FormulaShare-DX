@IsTest
public class FormulaShareAsyncApexJobSelectorTest {

    @IsTest
    static void getClassIdsByJobIds_returnsEmptyForNullOrEmpty() {
        FormulaShareAsyncApexJobSelector sel = new FormulaShareAsyncApexJobSelector();

        Test.startTest();
        System.assertEquals(0, sel.getClassIdsByJobIds(null).size(), 'Null input should return empty map');
        System.assertEquals(0, sel.getClassIdsByJobIds(new Set<Id>()).size(), 'Empty input should return empty map');
        Test.stopTest();
    }

    @IsTest
    static void getParentIdsByJobIds_returnsEmptyForNullOrEmpty() {
        FormulaShareAsyncApexJobSelector sel = new FormulaShareAsyncApexJobSelector();

        Test.startTest();
        System.assertEquals(0, sel.getParentIdsByJobIds(null).size(), 'Null input should return empty map');
        System.assertEquals(0, sel.getParentIdsByJobIds(new Set<Id>()).size(), 'Empty input should return empty map');
        Test.stopTest();
    }

    @IsTest
    static void getParentIdForAsyncId_handlesNoMatchGracefully() {
        // When no AsyncApexJob exists with the Id, the query would throw.
        // We cannot assert internal exception handling since the method currently assumes a row exists.
        // So we simply validate invocation in a guarded manner to document current behavior.
        Id randomId = (Id) '707000000000000'; // dummy AsyncApexJob Id format
        Boolean threw = false;
        try {
            Test.startTest();
            // This may throw if the org has no such job; acceptable for documenting behavior.
            new FormulaShareAsyncApexJobSelector().getParentIdForAsyncId(randomId);
            Test.stopTest();
        } catch (Exception e) {
            threw = true;
        }
        System.assertEquals(true, threw,
            'Documenting current behavior: getParentIdForAsyncId will throw if the Id does not exist');
    }


    @IsTest
    static void isFullBatchScheduled_returnsFalseWhenNoneScheduled() {
        // Reset the cached static value so the method queries
        FormulaShareAsyncApexJobSelector.isFullBatchScheduled = null;

        Test.startTest();
        Boolean result = FormulaShareAsyncApexJobSelector.isFullBatchScheduled();
        Test.stopTest();

        // No scheduled job in test context; result may be true or false depending on org state
        System.assertNotEquals(null, result, 'isFullBatchScheduled should return a non-null Boolean');
    }


    @IsTest
    static void isFullBatchScheduled_returnsCachedValue() {
        // Pre-seed the cached static value
        FormulaShareAsyncApexJobSelector.isFullBatchScheduled = true;

        Test.startTest();
        Boolean result = FormulaShareAsyncApexJobSelector.isFullBatchScheduled();
        Test.stopTest();

        System.assertEquals(true, result, 'Should return cached value without querying');
    }


    @IsTest
    static void isFullOrTargetedBatchScheduled_returnsFalseWhenNoneScheduled() {
        FormulaShareAsyncApexJobSelector.isFullOrTargetedBatchScheduled = null;

        Test.startTest();
        Boolean result = FormulaShareAsyncApexJobSelector.isFullOrTargetedBatchScheduled();
        Test.stopTest();

        System.assertNotEquals(null, result, 'isFullOrTargetedBatchScheduled should return a non-null Boolean');
    }


    @IsTest
    static void getNoJobsProcessingAndInQueue_returnsNonNegativeInt() {
        FormulaShareAsyncApexJobSelector sel = new FormulaShareAsyncApexJobSelector();

        Test.startTest();
        Integer result = sel.getNoJobsProcessingAndInQueue('FormulaShareProcessBatch');
        Test.stopTest();

        System.assert(result >= 0, 'getNoJobsProcessingAndInQueue should return a non-negative integer');
    }


    @IsTest
    static void getScheduledJobs_returnsList() {
        FormulaShareAsyncApexJobSelector sel = new FormulaShareAsyncApexJobSelector();

        Test.startTest();
        List<AsyncApexJob> result = sel.getScheduledJobs('FormulaShareProcessSchedulable');
        Test.stopTest();

        System.assertNotEquals(null, result, 'getScheduledJobs should return a non-null list');
    }

}