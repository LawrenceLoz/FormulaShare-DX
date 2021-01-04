@IsTest
public with sharing class FormulaShareIdUtilitiesTest {

    @IsTest 
    public static void testPassNullIdToGet15CharacterId() {
        FormulaShareIdUtilities idUtil = FormulaShareIdUtilities.construct();   // Will run code to generate non-mock object
        String idStringFromNull = idUtil.get15CharacterIdInstance(null);    // Runs instance implementation without mocking
        system.assertEquals(null, idStringFromNull);        // Checks that static implementation returns null if passed null
    }

}
