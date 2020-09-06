@IsTest
public with sharing class FormulaShareRuleDetailControllerTest {

    @IsTest
    public static void testGetObjectApiNames() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        String logObjName = prefix + 'FormulaShare_Log__c';
        List<EntityDefinition> edList = [SELECT DurableId FROM EntityDefinition WHERE QualifiedApiName = :logObjName];
        List<String> objectEntityIds = new List<String>{edList[0].DurableId};

        Map<String,String> entityIdMap = FormulaShareRuleDetailController.getObjectApiNames(objectEntityIds);

        System.assert(entityIdMap.containsKey(edList[0].DurableId), 'Doesnt include log object');
    }

    @IsTest
    public static void testGetFieldApiNames() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        String logObjName = prefix + 'FormulaShare_Log__c';
        List<EntityDefinition> edList = [SELECT DurableId FROM EntityDefinition WHERE QualifiedApiName = :logObjName];
        String fieldName = prefix + 'Context__c';
        List<FieldDefinition> fdList = [SELECT DurableId FROM FieldDefinition WHERE EntityDefinitionId = :edList[0].DurableId AND QualifiedApiName = :fieldName];
        List<String> fieldIds = new List<String>{fdList[0].DurableId};

        Map<String,String> fieldDefMap = FormulaShareRuleDetailController.getFieldApiNames(fieldIds);

        System.assert(fieldDefMap.containsKey(fdList[0].DurableId), 'Doesnt include class name field on fs log object');
    }


    @IsTest
    public static void testGetShareableObjects() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();

        List<FormulaShareRuleDetailController.ShareableObject> soList = FormulaShareRuleDetailController.getShareableObjects();
        Boolean foundObject = false;
        for(FormulaShareRuleDetailController.ShareableObject so : soList) {
            if(so.objectApiName == prefix + 'FormulaShare_Log__c') {
                foundObject = true;
                System.assert(so.isCustom, 'Should be marked as custom object');
            }
        }
    }


    @IsTest 
    public static void testGetShareFieldOptions() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        List<FormulaShareRuleDetailController.ShareFieldOption> sfoList = FormulaShareRuleDetailController.getShareFieldOptions(prefix + 'FormulaShare_Log__c');

        Boolean foundUser = false;
        Boolean foundText = false;
        Boolean foundOtherLookup = false;
        for(FormulaShareRuleDetailController.ShareFieldOption sfo : sfoList) {
            if(sfo.fieldApiName.contains('LastModifiedById')) {
                foundUser = true;
                System.assertEquals('Id', sfo.type, 'User lookup should indicate Id');
                System.assert(sfo.isIdType, 'Should have id flag set to true');
            }
            if(sfo.fieldApiName.contains('Context__c')) {
                foundText = true;
                System.assertEquals('Text', sfo.type, 'User lookup should indicate Text');
            }
            if(sfo.fieldApiName.contains('Related_Log_Required_for_Test_Class__c')) foundOtherLookup = true;
        }

        System.assert(foundUser, 'Didnt find user lookup');
        System.assert(foundText, 'Didnt find text lookup');
        System.assert(!foundOtherLookup, 'Other lookup also returned');
    }


    @IsTest
    public static void testGetSampleData() {

        // Insert FS log to check field contents returned
        FormulaShare_Log__c fsLog = new FormulaShare_Log__c();
        fsLog.Context__c = 'Testing';
        insert fsLog;

        String prefix = FormulaShareTestUtils.getNamespacePrefix();
        String objectApiName = prefix + 'FormulaShare_Log__c';
        String fieldApiName = prefix + 'Context__c';

        String sampleDataString = FormulaShareRuleDetailController.getSampleData(objectApiName, fieldApiName);

        System.assertEquals('"Testing"', sampleDataString, 'String not populated with value from record');
    }


}