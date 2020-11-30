@IsTest
public with sharing class FormulaShareSObjectUtilitiesTest {

    @IsTest
    public static void testGetShareKey() {
        String prefix = FormulaShareTestUtils.getNamespacePrefix();

        Schema.SObjectType type = FormulaShare_Log__c.SObjectType;
        FormulaShareSObjectUtilities utils = new FormulaShareSObjectUtilities(type);

        FormulaShare_Log__Share share = new FormulaShare_Log__Share();
        share.AccessLevel = 'Read';
        share.ParentId = UserInfo.getUserId();      // Any valid id is fine
        share.UserOrGroupId = UserInfo.getUserId();
        share.RowCause = prefix + 'FormulaShare_Log_Share__c';
        
        String shareKey = utils.getShareKey(share);

        String id15chars = ((String) UserInfo.getUserId()).left(15);
        String expectedShareKey = id15chars + id15chars + share.RowCause;

        System.assertEquals(expectedShareKey, shareKey, 'Share key not in expected format');
    }

    @IsTest
    public static void testRemoveSharesCustom() {
        Schema.SObjectType type = FormulaShare_Log__c.SObjectType;
        FormulaShareSObjectUtilities utils = new FormulaShareSObjectUtilities(type);

        Boolean removeShares = utils.removeSharesForObject();

        System.assert(removeShares, 'Shares from custom object should always be removed');
    }

    @IsTest
    public static void testRemoveSharesStandard() {
        Schema.SObjectType type = Account.SObjectType;
        FormulaShareSObjectUtilities utils = new FormulaShareSObjectUtilities(type);

        Boolean removeShares = utils.removeSharesForObject();

        List<FormulaShare_Std_Object_to_Remove_Shares__mdt> removalLinesToReturn = 
            [SELECT Id
            FROM FormulaShare_Std_Object_to_Remove_Shares__mdt
            WHERE Standard_Object_to_Remove_Sharing__r.QualifiedApiName = 'Account'];
        
        Boolean expectToRemoveShares = false;
        if(!removalLinesToReturn.isEmpty()) {
            expectToRemoveShares = true;
        }
        System.assertEquals(expectToRemoveShares, removeShares, 'Removal indicator does not match settings in FormulaShare_Std_Object_to_Remove_Shares__mdt metadata');
    }
}
