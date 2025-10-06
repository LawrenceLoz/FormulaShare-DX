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

}
