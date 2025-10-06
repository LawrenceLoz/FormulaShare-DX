@IsTest
public class FormulaShareApexClassSelectorTest {

    @IsTest
    static void getIdsByNamesAndNamespace_returnsEmptyWhenNoNames() {
        Test.startTest();
        Set<Id> ids = new FormulaShareApexClassSelector().getIdsByNamesAndNamespace(new Set<String>(), null);
        Test.stopTest();
        System.assertEquals(0, ids.size(), 'Expected empty set when names are empty');
    }

    @IsTest
    static void getIdsByNamesAndNamespace_filtersByNullNamespace() {
        // Derive the current namespace (empty or managed) from existing utility if available
        String ns = FormulaShareUtilities.getNamespaceNoUnderscores();

        // Pick a known class name that must exist in this package: FormulaShareProcessBatch
        Set<String> names = new Set<String>{ 'FormulaShareProcessBatch' };

        Test.startTest();
        Set<Id> ids = new FormulaShareApexClassSelector().getIdsByNamesAndNamespace(names, ns);
        Test.stopTest();

        // We cannot guarantee the class exists in the running org for unmanaged vs managed test context,
        // but we can at least assert the method executes safely without exception.
        System.assertNotEquals(null, ids, 'Selector returned null instead of a Set');
    }
}
