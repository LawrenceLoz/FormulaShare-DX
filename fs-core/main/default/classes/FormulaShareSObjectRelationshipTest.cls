@IsTest
public with sharing class FormulaShareSObjectRelationshipTest {

    static String prefix = FormulaShareTestUtils.getNamespacePrefix();

    @IsTest
    public static void checkRelationshipBuiltFromComplexSibling() {
        FormulaShare_Rule__mdt rule = FormulaShareRuleFactory.getComplexSiblingMetadataRule();

        String expectedSharedObjectName = rule.Object_Shared__c;
        String expectedObjectName = rule.Related_Object_2__c;
        String expectedLookupFieldName = rule.Related_Object_2_Lookup_from_RO1__c;
        String expectedSharedToFieldName = rule.Related_Object_10_Shared_To_Field__c;
        
        Test.startTest();
        FormulaShareSObjectRelationship rel = new FormulaShareSObjectRelationship(rule);
        Test.stopTest();

        // Check all attributes we expect are populated
        System.assertEquals(expectedSharedObjectName, rel.thisObjectToken, 'Shared object should be in the first relationship');

        // Check no extra attributes set
        System.assertEquals(null, rel.lookupFromPrevObjectToken, 'Lookup from previous should not be populated for first object');
        System.assertEquals(null, rel.lookupToPrevObjectToken, 'Lookup to previous should not be populated for first object');
        System.assertEquals(null, rel.sharedToFieldToken, 'Shared to should not be set on shared object relationship');

        FormulaShareSObjectRelationship thisRel = rel;
        System.debug('thisRel: '+thisRel);

        // Traverse 5 relationships up and check all are set correctly
        for(Integer i=1; i < 6; i++) {
            thisRel = thisRel.nextRelationship;
            System.debug('thisRel: '+thisRel);

            // Check all attributes we expect are populated
            System.assertEquals(expectedObjectName, thisRel.thisObjectToken, 'Related object name not set for rel '+i);
            System.assertEquals(expectedLookupFieldName, thisRel.lookupFromPrevObjectToken, 'Lookup from previous should be set for rel '+i);

            // Check no extra attributes set
            System.assertEquals(null, thisRel.lookupToPrevObjectToken, 'Lookup to previous should not be populated for parent rel '+i);
            System.assertEquals(null, thisRel.sharedToFieldToken, 'Shared to should not be set on intermediate rel '+i);
        }

        // Traverse 4 relationships down and check set correctly
        for(Integer i=6; i < 10; i++) {
            thisRel = thisRel.nextRelationship;
            System.debug('thisRel: '+thisRel);

            // Check all attributes we expect are populated
            System.assertEquals(expectedObjectName, thisRel.thisObjectToken, 'Related object name not set for rel '+i);
            System.assertEquals(expectedLookupFieldName, thisRel.lookupToPrevObjectToken, 'Lookup to previous should be set for rel '+i);
            
            // Check no extra attributes set
            System.assertEquals(null, thisRel.lookupFromPrevObjectToken, 'Lookup from previous should not be populated for child rel '+i);
            System.assertEquals(null, thisRel.sharedToFieldToken, 'Shared to should not be set on intermediate rel '+i);
        }

        // Move to final relationship
        thisRel = thisRel.nextRelationship;
        System.debug('thisRel: '+thisRel);

        // Check all attributes we expect are populated
        System.assertEquals(expectedObjectName, thisRel.thisObjectToken, 'Related object name not set');
        System.assertEquals(expectedLookupFieldName, thisRel.lookupToPrevObjectToken, 'Lookup to previous should be set');
        System.assertEquals(expectedSharedToFieldName, thisRel.sharedToFieldToken, 'Shared to should be set on final rel');
        
        // Check no extra attributes set
        System.assertEquals(null, thisRel.lookupFromPrevObjectToken, 'Lookup from previous should not be populated for child rel');
        System.assertEquals(null, thisRel.nextRelationship, 'No more relationships should be set');
    }


    @IsTest
    static void checkRelationshipBuiltFromComplexInlaw() {
        FormulaShare_Rule__mdt rule = FormulaShareRuleFactory.getComplexInlawMetadataRule();

        String expectedSharedObjectName = rule.Object_Shared__c;
        String expectedObjectName = rule.Related_Object_2__c;
        String expectedLookupFieldName = rule.Related_Object_2_Lookup_to_RO1__c;
        String expectedSharedToFieldName = rule.Related_Object_9_Shared_To_Field__c;
        
        Test.startTest();
        FormulaShareSObjectRelationship rel = new FormulaShareSObjectRelationship(rule);
        Test.stopTest();

        // Check all attributes we expect are populated
        System.assertEquals(expectedSharedObjectName, rel.thisObjectToken, 'Shared object should be in the first relationship');

        // Check no extra attributes set
        System.assertEquals(null, rel.lookupFromPrevObjectToken, 'Lookup from previous should not be populated for first object');
        System.assertEquals(null, rel.lookupToPrevObjectToken, 'Lookup to previous should not be populated for first object');
        System.assertEquals(null, rel.sharedToFieldToken, 'Shared to should not be set on shared object relationship');

        FormulaShareSObjectRelationship thisRel = rel;
        System.debug('thisRel: '+thisRel);

        // Traverse 5 relationships DOWN and check all are set correctly
        for(Integer i=1; i < 6; i++) {
            thisRel = thisRel.nextRelationship;
            System.debug('thisRel: '+thisRel);

            // Check all attributes we expect are populated
            System.assertEquals(expectedObjectName, thisRel.thisObjectToken, 'Related object name not set for rel '+i);
            System.assertEquals(expectedLookupFieldName, thisRel.lookupToPrevObjectToken, 'Lookup to previous should be set for rel '+i);
            
            // Check no extra attributes set
            System.assertEquals(null, thisRel.lookupFromPrevObjectToken, 'Lookup from previous should not be populated for child rel '+i);
            System.assertEquals(null, thisRel.sharedToFieldToken, 'Shared to should not be set on intermediate rel '+i);
        }

        // Traverse 3 relationships UP and check set correctly
        for(Integer i=6; i < 9; i++) {
            thisRel = thisRel.nextRelationship;
            System.debug('thisRel: '+thisRel);

            // Check all attributes we expect are populated
            System.assertEquals(expectedObjectName, thisRel.thisObjectToken, 'Related object name not set for rel '+i);
            System.assertEquals(expectedLookupFieldName, thisRel.lookupFromPrevObjectToken, 'Lookup from previous should be set for rel '+i);

            // Check no extra attributes set
            System.assertEquals(null, thisRel.lookupToPrevObjectToken, 'Lookup to previous should not be populated for parent rel '+i);
            System.assertEquals(null, thisRel.sharedToFieldToken, 'Shared to should not be set on intermediate rel '+i);
        }

        // Move to final relationship (9 levels in rule)
        thisRel = thisRel.nextRelationship;
        System.debug('thisRel: '+thisRel);

        // Check all attributes we expect are populated
        System.assertEquals(expectedObjectName, thisRel.thisObjectToken, 'Related object name not set');
        System.assertEquals(expectedLookupFieldName, thisRel.lookupFromPrevObjectToken, 'Lookup from previous should be set');
        System.assertEquals(expectedSharedToFieldName, thisRel.sharedToFieldToken, 'Shared to should be set on final rel');
        
        // Check no extra attributes set
        System.assertEquals(null, thisRel.lookupToPrevObjectToken, 'Lookup to previous should not be populated for child rel');
        System.assertEquals(null, thisRel.nextRelationship, 'No more relationships should be set');        
    }
}
