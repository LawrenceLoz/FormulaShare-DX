public inherited sharing class FormulaShareSObjectRelationship {

    @AuraEnabled public String thisObjectApiName;
    @AuraEnabled public String thisObjectLabel;
    @AuraEnabled public String lookupFromPrevObjectApiName;
    @AuraEnabled public String lookupToPrevObjectApiName;
    @AuraEnabled public String sharedToFieldApiName;
    public String thisObjectToken;
    public String lookupFromPrevObjectToken;
    public String lookupToPrevObjectToken;
    public String sharedToFieldToken;
    public String sharedToFieldLabel;
    @AuraEnabled public FormulaShareSObjectRelationship nextRelationship;

    FormulaShare_Rule__mdt rule;


    // Simple constructor for testing
    @TestVisible
    private FormulaShareSObjectRelationship() {}

    // Constructor to created nested relationship object from metadata rule
    public FormulaShareSObjectRelationship(FormulaShare_Rule__mdt rule) {
        this.rule = rule;
        getRelationshipAtLevel(this, 0);
    }


    // Progressively builds nested relationships from the relevant fields for the relationship level
    private FormulaShareSObjectRelationship getRelationshipAtLevel(FormulaShareSObjectRelationship rel, Integer level) {
        RelationshipDetailsForLevel levelDetail = getRelationshipDetailsForLevel(level);

        rel.thisObjectToken           = levelDetail.thisObjectToken;
        rel.thisObjectApiName         = levelDetail.thisObjectApiName;
        rel.thisObjectLabel           = levelDetail.thisObjectLabel;

        rel.lookupFromPrevObjectToken  = levelDetail.lookupFromPrevObjectToken;
        rel.lookupFromPrevObjectApiName= levelDetail.lookupFromPrevObjectApiName;
        rel.lookupToPrevObjectToken    = levelDetail.lookupToPrevObjectToken;
        rel.lookupToPrevObjectApiName  = levelDetail.lookupToPrevObjectApiName;
        
        // Set shared to field if this is the last relationship
        if(!levelDetail.hasNextRel) {
            rel.sharedToFieldToken     = levelDetail.sharedToFieldToken;
            rel.sharedToFieldApiName   = levelDetail.sharedToFieldApiName;
            rel.sharedToFieldLabel     = levelDetail.sharedToFieldLabel;
        }

        // Otherwise create a nested relationship and populate this
        else {
            rel.nextRelationship = getRelationshipAtLevel(new FormulaShareSObjectRelationship(), level + 1);
        }

        return rel;
    }

    // Maps relevant metadata fields to RelationshipDetailsForLevel object. Need to retrieve fields individually from api names
    // because attributes of field / object definitions can't be refrerenced with dynamic map notation
    private RelationshipDetailsForLevel getRelationshipDetailsForLevel(Integer level) {
        RelationshipDetailsForLevel rel = new RelationshipDetailsForLevel();

        switch on level {

            when 0 {
                rel.thisObjectToken            = rule.Object_Shared__c;
                rel.thisObjectApiName          = rule.Object_Shared__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Object_Shared__r.MasterLabel;
                rel.sharedToFieldToken         = rule.Shared_To__c;
                rel.sharedToFieldApiName       = rule.Shared_To__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Shared_To__r.MasterLabel;
                rel.hasNextRel                 = rule.Child_Object_with_Shared_To_Field__c != null;
            }

            when 1 {
                rel.thisObjectToken            = rule.Child_Object_with_Shared_To_Field__c;
                rel.thisObjectApiName          = rule.Child_Object_with_Shared_To_Field__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Child_Object_with_Shared_To_Field__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_1_Lookup_from_Shared_Obj__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_1_Lookup_from_Shared_Obj__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Child_Object_Lookup_Field__c;
                rel.lookupToPrevObjectApiName  = rule.Child_Object_Lookup_Field__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Child_Object_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Child_Object_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Child_Object_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = rule.Related_Object_2__c != null;
            }

            // Note that the field API names are a bit misleading on related object 1. In FormulaShare v2.2 and below only one 
            // child object was supported, and these fields are reused for backwards compatiblity with existing subscriber org rules
            when 2 {
                rel.thisObjectToken            = rule.Related_Object_2__c;
                rel.thisObjectApiName          = rule.Related_Object_2__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Related_Object_2__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_2_Lookup_from_RO1__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_2_Lookup_from_RO1__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Related_Object_2_Lookup_to_RO1__c;
                rel.lookupToPrevObjectApiName  = rule.Related_Object_2_Lookup_to_RO1__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Related_Object_2_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Related_Object_2_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Related_Object_2_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = rule.Related_Object_3__c != null;
            }

            when 3 {
                rel.thisObjectToken            = rule.Related_Object_3__c;
                rel.thisObjectApiName          = rule.Related_Object_3__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Related_Object_3__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_3_Lookup_from_RO2__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_3_Lookup_from_RO2__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Related_Object_3_Lookup_to_RO2__c;
                rel.lookupToPrevObjectApiName  = rule.Related_Object_3_Lookup_to_RO2__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Related_Object_3_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Related_Object_3_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Related_Object_3_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = rule.Related_Object_4__c != null;
            }

            when 4 {
                rel.thisObjectToken            = rule.Related_Object_4__c;
                rel.thisObjectApiName          = rule.Related_Object_4__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Related_Object_4__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_4_Lookup_from_RO3__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_4_Lookup_from_RO3__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Related_Object_4_Lookup_to_RO3__c;
                rel.lookupToPrevObjectApiName  = rule.Related_Object_4_Lookup_to_RO3__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Related_Object_4_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Related_Object_4_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Related_Object_4_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = rule.Related_Object_5__c != null;
            }

            when 5 {
                rel.thisObjectToken            = rule.Related_Object_5__c;
                rel.thisObjectApiName          = rule.Related_Object_5__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Related_Object_5__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_5_Lookup_from_RO4__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_5_Lookup_from_RO4__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Related_Object_5_Lookup_to_RO4__c;
                rel.lookupToPrevObjectApiName  = rule.Related_Object_5_Lookup_to_RO4__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Related_Object_5_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Related_Object_5_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Related_Object_5_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = rule.Related_Object_6__c != null;
            }

            when 6 {
                rel.thisObjectToken            = rule.Related_Object_6__c;
                rel.thisObjectApiName          = rule.Related_Object_6__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Related_Object_6__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_6_Lookup_from_RO5__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_6_Lookup_from_RO5__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Related_Object_6_Lookup_to_RO5__c;
                rel.lookupToPrevObjectApiName  = rule.Related_Object_6_Lookup_to_RO5__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Related_Object_6_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Related_Object_6_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Related_Object_6_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = rule.Related_Object_7__c != null;
            }

            when 7 {
                rel.thisObjectToken            = rule.Related_Object_7__c;
                rel.thisObjectApiName          = rule.Related_Object_7__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Related_Object_7__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_7_Lookup_from_RO6__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_7_Lookup_from_RO6__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Related_Object_7_Lookup_to_RO6__c;
                rel.lookupToPrevObjectApiName  = rule.Related_Object_7_Lookup_to_RO6__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Related_Object_7_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Related_Object_7_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Related_Object_7_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = rule.Related_Object_8__c != null;
            }

            when 8 {
                rel.thisObjectToken            = rule.Related_Object_8__c;
                rel.thisObjectApiName          = rule.Related_Object_8__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Related_Object_8__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_8_Lookup_from_RO7__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_8_Lookup_from_RO7__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Related_Object_8_Lookup_to_RO7__c;
                rel.lookupToPrevObjectApiName  = rule.Related_Object_8_Lookup_to_RO7__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Related_Object_8_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Related_Object_8_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Related_Object_8_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = rule.Related_Object_9__c != null;
            }

            when 9 {
                rel.thisObjectToken            = rule.Related_Object_9__c;
                rel.thisObjectApiName          = rule.Related_Object_9__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Related_Object_9__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_9_Lookup_from_RO8__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_9_Lookup_from_RO8__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Related_Object_9_Lookup_to_RO8__c;
                rel.lookupToPrevObjectApiName  = rule.Related_Object_9_Lookup_to_RO8__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Related_Object_9_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Related_Object_9_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Related_Object_9_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = rule.Related_Object_10__c != null;
            }

            when 10 {
                rel.thisObjectToken            = rule.Related_Object_10__c;
                rel.thisObjectApiName          = rule.Related_Object_10__r.QualifiedApiName;
                rel.thisObjectLabel            = rule.Related_Object_10__r.MasterLabel;
                rel.lookupFromPrevObjectToken  = rule.Related_Object_10_Lookup_from_RO9__c;
                rel.lookupFromPrevObjectApiName= rule.Related_Object_10_Lookup_from_RO9__r.QualifiedApiName;
                rel.lookupToPrevObjectToken    = rule.Related_Object_10_Lookup_to_RO9__c;
                rel.lookupToPrevObjectApiName  = rule.Related_Object_10_Lookup_to_RO9__r.QualifiedApiName;
                rel.sharedToFieldToken         = rule.Related_Object_10_Shared_To_Field__c;
                rel.sharedToFieldApiName       = rule.Related_Object_10_Shared_To_Field__r.QualifiedApiName;
                rel.sharedToFieldLabel         = rule.Related_Object_10_Shared_To_Field__r.MasterLabel;
                rel.hasNextRel                 = false;
            }
        }

        return rel;
    }

    class RelationshipDetailsForLevel {
        String thisObjectToken;
        String thisObjectApiName;
        String thisObjectLabel;
        String lookupFromPrevObjectToken;
        String lookupFromPrevObjectApiName;
        String lookupToPrevObjectToken;
        String lookupToPrevObjectApiName;
        String sharedToFieldToken;
        String sharedToFieldApiName;
        String sharedToFieldLabel;
        Boolean hasNextRel;
    }

    /*
    private FormulaShareSObjectRelationship getRelatedObjectRel1(FormulaShare_Rule__mdt rule) {
        FormulaShareSObjectRelationship rfc1 = new FormulaShareSObjectRelationship();
        rfc1.thisObjectToken            = rule.Child_Object_with_Shared_To_Field__c;
        rfc1.thisObjectApiName          = rule.Child_Object_with_Shared_To_Field__r.QualifiedApiName;
        rfc1.thisObjectLabel            = rule.Child_Object_with_Shared_To_Field__r.MasterLabel;
        rfc1.lookupFromPrevObjectToken  = rule.Related_Object_1_Lookup_from_Shared_Obj__c;
        rfc1.lookupFromPrevObjectApiName= rule.Related_Object_1_Lookup_from_Shared_Obj__r.QualifiedApiName;
        rfc1.lookupToPrevObjectToken    = rule.Child_Object_Lookup_Field__c;
        rfc1.lookupToPrevObjectApiName  = rule.Child_Object_Lookup_Field__r.QualifiedApiName;
        if(rule.Related_Object_2__c == null) {
            rfc1.sharedToFieldToken         = rule.Child_Object_Shared_To_Field__c;
            rfc1.sharedToFieldApiName       = rule.Child_Object_Shared_To_Field__r.QualifiedApiName;
            rfc1.sharedToFieldLabel         = rule.Child_Object_Shared_To_Field__r.MasterLabel;
        }
        else {
            rfc1.nextRelationship = getRelatedObjectRel2();
        }
        return rfc1;
    }
    private FormulaShareSObjectRelationship getRelatedObjectRel2(FormulaShare_Rule__mdt rule) {
        FormulaShareSObjectRelationship rfc2 = new FormulaShareSObjectRelationship();
        rfc2.thisObjectToken            = rule.Related_Object_2__c;
        rfc2.thisObjectApiName          = rule.Related_Object_2__r.QualifiedApiName;
        rfc2.thisObjectLabel            = rule.Related_Object_2__r.MasterLabel;
        rfc2.lookupFromPrevObjectToken  = rule.Related_Object_2_Lookup_from_RO1__c;
        rfc2.lookupFromPrevObjectApiName= rule.Related_Object_2_Lookup_from_RO1__r.QualifiedApiName;
        rfc2.lookupToPrevObjectToken    = rule.Related_Object_2_Lookup_to_RO1__c;
        rfc2.lookupToPrevObjectApiName  = rule.Related_Object_2_Lookup_to_RO1__r.QualifiedApiName;
        if(rule.Related_Object_3__c == null) {
            rfc2.sharedToFieldToken         = rule.Related_Object_2_Shared_To_Field__c;
            rfc2.sharedToFieldApiName       = rule.Related_Object_2_Shared_To_Field__r.QualifiedApiName;
            rfc2.sharedToFieldLabel         = rule.Related_Object_2_Shared_To_Field__r.MasterLabel;
        }
        else {
            rfc2.nextRelationship = getRelatedObjectRel3();
        }
        return rfc2;
    }



        
        FormulaShareSObjectRelationship rfc3 = new FormulaShareSObjectRelationship();
        rfc3.thisObjectToken            = rule.Related_Object_3__c;
        rfc3.thisObjectApiName          = rule.Related_Object_3__r.QualifiedApiName;
        rfc3.thisObjectLabel            = rule.Related_Object_3__r.MasterLabel;
        rfc3.lookupFromPrevObjectToken  = rule.Related_Object_3_Lookup_from_RO2__c;
        rfc3.lookupFromPrevObjectApiName= rule.Related_Object_3_Lookup_from_RO2__r.QualifiedApiName;
        rfc3.lookupToPrevObjectToken    = rule.Related_Object_3_Lookup_to_RO2__c;
        rfc3.lookupToPrevObjectApiName  = rule.Related_Object_3_Lookup_to_RO2__r.QualifiedApiName;
        rfc2.nextRelationship = rfc3;
        if(rule.Related_Object_4__c == null) {
            rfc3.sharedToFieldToken         = rule.Related_Object_3_Shared_To_Field__c;
            rfc3.sharedToFieldApiName       = rule.Related_Object_3_Shared_To_Field__r.QualifiedApiName;
            rfc3.sharedToFieldLabel         = rule.Related_Object_3_Shared_To_Field__r.MasterLabel;
        }

        FormulaShareSObjectRelationship rfc4 = new FormulaShareSObjectRelationship();
        rfc4.thisObjectToken            = rule.Related_Object_4__c;
        rfc4.thisObjectApiName          = rule.Related_Object_4__r.QualifiedApiName;
        rfc4.thisObjectLabel            = rule.Related_Object_4__r.MasterLabel;
        rfc4.lookupFromPrevObjectToken  = rule.Related_Object_4_Lookup_from_RO3__c;
        rfc4.lookupFromPrevObjectApiName= rule.Related_Object_4_Lookup_from_RO3__r.QualifiedApiName;
        rfc4.lookupToPrevObjectToken    = rule.Related_Object_4_Lookup_to_RO3__c;
        rfc4.lookupToPrevObjectApiName  = rule.Related_Object_4_Lookup_to_RO3__r.QualifiedApiName;
        rfc3.nextRelationship = rfc4;
        if(rule.Related_Object_5__c == null) {
            rfc4.sharedToFieldToken         = rule.Related_Object_4_Shared_To_Field__c;
            rfc4.sharedToFieldApiName       = rule.Related_Object_4_Shared_To_Field__r.QualifiedApiName;
            rfc4.sharedToFieldLabel         = rule.Related_Object_4_Shared_To_Field__r.MasterLabel;
        }

        FormulaShareSObjectRelationship rfc5 = new FormulaShareSObjectRelationship();
        rfc5.thisObjectToken            = rule.Related_Object_5__c;
        rfc5.thisObjectApiName          = rule.Related_Object_5__r.QualifiedApiName;
        rfc5.thisObjectLabel            = rule.Related_Object_5__r.MasterLabel;
        rfc5.lookupFromPrevObjectToken  = rule.Related_Object_5_Lookup_from_RO4__c;
        rfc5.lookupFromPrevObjectApiName= rule.Related_Object_5_Lookup_from_RO4__r.QualifiedApiName;
        rfc5.lookupToPrevObjectToken    = rule.Related_Object_5_Lookup_to_RO4__c;
        rfc5.lookupToPrevObjectApiName  = rule.Related_Object_5_Lookup_to_RO4__r.QualifiedApiName;
        rfc4.nextRelationship = rfc5;
        if(rule.Related_Object_6__c == null) {
            rfc5.sharedToFieldToken         = rule.Related_Object_5_Shared_To_Field__c;
            rfc5.sharedToFieldApiName       = rule.Related_Object_5_Shared_To_Field__r.QualifiedApiName;
            rfc5.sharedToFieldLabel         = rule.Related_Object_5_Shared_To_Field__r.MasterLabel;
        }

        FormulaShareSObjectRelationship rfc6 = new FormulaShareSObjectRelationship();
        rfc6.thisObjectToken            = rule.Related_Object_6__c;
        rfc6.thisObjectApiName          = rule.Related_Object_6__r.QualifiedApiName;
        rfc6.thisObjectLabel            = rule.Related_Object_6__r.MasterLabel;
        rfc6.lookupFromPrevObjectToken  = rule.Related_Object_6_Lookup_from_RO5__c;
        rfc6.lookupFromPrevObjectApiName= rule.Related_Object_6_Lookup_from_RO5__r.QualifiedApiName;
        rfc6.lookupToPrevObjectToken    = rule.Related_Object_6_Lookup_to_RO5__c;
        rfc6.lookupToPrevObjectApiName  = rule.Related_Object_6_Lookup_to_RO5__r.QualifiedApiName;
        rfc5.nextRelationship = rfc6;
        if(rule.Related_Object_7__c == null) {
            rfc6.sharedToFieldToken         = rule.Related_Object_6_Shared_To_Field__c;
            rfc6.sharedToFieldApiName       = rule.Related_Object_6_Shared_To_Field__r.QualifiedApiName;
            rfc6.sharedToFieldLabel         = rule.Related_Object_6_Shared_To_Field__r.MasterLabel;
        }

        FormulaShareSObjectRelationship rfc7 = new FormulaShareSObjectRelationship();
        rfc7.thisObjectToken            = rule.Related_Object_7__c;
        rfc7.thisObjectApiName          = rule.Related_Object_7__r.QualifiedApiName;
        rfc7.thisObjectLabel            = rule.Related_Object_7__r.MasterLabel;
        rfc7.lookupFromPrevObjectToken  = rule.Related_Object_7_Lookup_from_RO6__c;
        rfc7.lookupFromPrevObjectApiName= rule.Related_Object_7_Lookup_from_RO6__r.QualifiedApiName;
        rfc7.lookupToPrevObjectToken    = rule.Related_Object_7_Lookup_to_RO6__c;
        rfc7.lookupToPrevObjectApiName  = rule.Related_Object_7_Lookup_to_RO6__r.QualifiedApiName;
        rfc6.nextRelationship = rfc7;
        if(rule.Related_Object_8__c == null) {
            rfc7.sharedToFieldToken         = rule.Related_Object_7_Shared_To_Field__c;
            rfc7.sharedToFieldApiName       = rule.Related_Object_7_Shared_To_Field__r.QualifiedApiName;
            rfc7.sharedToFieldLabel         = rule.Related_Object_7_Shared_To_Field__r.MasterLabel;
        }
        
        FormulaShareSObjectRelationship rfc8 = new FormulaShareSObjectRelationship();
        rfc8.thisObjectToken            = rule.Related_Object_8__c;
        rfc8.thisObjectApiName          = rule.Related_Object_8__r.QualifiedApiName;
        rfc8.thisObjectLabel            = rule.Related_Object_8__r.MasterLabel;
        rfc8.lookupFromPrevObjectToken  = rule.Related_Object_8_Lookup_from_RO7__c;
        rfc8.lookupFromPrevObjectApiName= rule.Related_Object_8_Lookup_from_RO7__r.QualifiedApiName;
        rfc8.lookupToPrevObjectToken    = rule.Related_Object_8_Lookup_to_RO7__c;
        rfc8.lookupToPrevObjectApiName  = rule.Related_Object_8_Lookup_to_RO7__r.QualifiedApiName;
        rfc7.nextRelationship = rfc8;
        if(rule.Related_Object_9__c == null) {
            rfc8.sharedToFieldToken         = rule.Related_Object_8_Shared_To_Field__c;
            rfc8.sharedToFieldApiName       = rule.Related_Object_8_Shared_To_Field__r.QualifiedApiName;
            rfc8.sharedToFieldLabel         = rule.Related_Object_8_Shared_To_Field__r.MasterLabel;
        }

        FormulaShareSObjectRelationship rfc9 = new FormulaShareSObjectRelationship();
        rfc9.thisObjectToken            = rule.Related_Object_9__c;
        rfc9.thisObjectApiName          = rule.Related_Object_9__r.QualifiedApiName;
        rfc9.thisObjectLabel            = rule.Related_Object_9__r.MasterLabel;
        rfc9.lookupFromPrevObjectToken  = rule.Related_Object_9_Lookup_from_RO8__c;
        rfc9.lookupFromPrevObjectApiName= rule.Related_Object_9_Lookup_from_RO8__r.QualifiedApiName;
        rfc9.lookupToPrevObjectToken    = rule.Related_Object_9_Lookup_to_RO8__c;
        rfc9.lookupToPrevObjectApiName  = rule.Related_Object_9_Lookup_to_RO8__r.QualifiedApiName;
        rfc8.nextRelationship = rfc9;
        if(rule.Related_Object_10__c == null) {
            rfc9.sharedToFieldToken         = rule.Related_Object_9_Shared_To_Field__c;
            rfc9.sharedToFieldApiName       = rule.Related_Object_9_Shared_To_Field__r.QualifiedApiName;
            rfc9.sharedToFieldLabel         = rule.Related_Object_9_Shared_To_Field__r.MasterLabel;
        }

        else {
            FormulaShareSObjectRelationship rfc10 = new FormulaShareSObjectRelationship();
            rfc10.thisObjectToken            = rule.Related_Object_10__c;
            rfc10.thisObjectApiName          = rule.Related_Object_10__r.QualifiedApiName;
            rfc10.thisObjectLabel            = rule.Related_Object_10__r.MasterLabel;
            rfc10.lookupFromPrevObjectToken  = rule.Related_Object_10_Lookup_from_RO9__c;
            rfc10.lookupFromPrevObjectApiName= rule.Related_Object_10_Lookup_from_RO9__r.QualifiedApiName;
            rfc10.lookupToPrevObjectToken    = rule.Related_Object_10_Lookup_to_RO9__c;
            rfc10.lookupToPrevObjectApiName  = rule.Related_Object_10_Lookup_to_RO9__r.QualifiedApiName;
            rfc9.nextRelationship = rfc10;

            rfc10.sharedToFieldToken         = rule.Related_Object_10_Shared_To_Field__c;
            rfc10.sharedToFieldApiName       = rule.Related_Object_10_Shared_To_Field__r.QualifiedApiName;
            rfc10.sharedToFieldLabel         = rule.Related_Object_10_Shared_To_Field__r.MasterLabel;
        }
    }   */


    // Map fields from nested relationship onto their flat metadata equivalents
    // This is used help convert an LWC component object to a metadata record which can be inserted / updated
    public FormulaShare_Rule__mdt mapRelationshipToMetadataRule(FormulaShare_Rule__mdt mdRule) {
        FormulaShareSObjectRelationship rel = nextRelationship;

        // If no nested relationships, set Shared_To__c field (on shared object) only
        if(rel == null) {
            mdRule.Shared_To__c = sharedToFieldApiName;
        }

        // Otherwise, set details for the first related object (treated specifically because API names don't follow other objects' pattern)
        else {
            mdRule.Child_Object_with_Shared_To_Field__c = rel.thisObjectApiName;
            mdRule.Related_Object_1_Lookup_from_Shared_Obj__c = rel.lookupFromPrevObjectApiName;
            mdRule.Child_Object_Lookup_Field__c = rel.lookupToPrevObjectApiName;

            // If shared field is on this object, populate details
            if(rel.sharedToFieldApiName != null) {
                mdRule.Child_Object_Shared_To_Field__c = rel.sharedToFieldApiName;
            }

            // If we have another nested relationship, process this
            else if(rel.nextRelationship != null) {
                mdRule = mapToRelationshipToMetadatRuleStructured(mdRule, rel.nextRelationship, 2);
            }
        }

        return mdRule;
    }

    // For objects lower than the shared and first related object, we can dynamically set fields on the metadata record
    private FormulaShare_Rule__mdt mapToRelationshipToMetadatRuleStructured(FormulaShare_Rule__mdt mdRule, FormulaShareSObjectRelationship rel, Integer depth) {
        System.debug('rel now: ' + rel);
        System.debug('rel lookupToPrevObjectApiName: ' + rel.lookupToPrevObjectApiName);
        System.debug('rel lookupFromPrevObjectApiName: ' + rel.lookupFromPrevObjectApiName);

        String namespacePrefix = FormulaShareUtilities.getNamespacePrefix();
        String fieldPrefix = namespacePrefix + 'Related_Object_' + depth;
        Integer lastDepth = depth - 1;

        // Set object name and lookups between this and the last object
        mdRule.put(fieldPrefix + '__c', rel.thisObjectApiName);
        mdRule.put(fieldPrefix + '_Lookup_from_RO' + lastDepth + '__c', rel.lookupFromPrevObjectApiName);
        mdRule.put(fieldPrefix + '_Lookup_to_RO' + lastDepth + '__c', rel.lookupToPrevObjectApiName);

        // If shared field is on this object, populate details
        if(rel.sharedToFieldApiName != null) {
            mdRule.put(fieldPrefix + '_Shared_To_Field__c', rel.sharedToFieldApiName);
        }

        // If we have another nested relationship, process this
        else if(rel.nextRelationship != null) {
            mdRule = mapToRelationshipToMetadatRuleStructured(mdRule, rel.nextRelationship, depth + 1);
        }

        return mdRule;
    }


    public Boolean isValid() {
        if(thisObjectApiName == null) {
            System.debug('isValid() fail: Object API name not populated for relationship: ' + this);
            return false;
        }
        if(lookupToPrevObjectApiName == null && lookupFromPrevObjectApiName == null) {
            System.debug('isValid() fail: No relationship details for relationship: ' + this);
            return false;
        }
        if(lookupToPrevObjectApiName != null && lookupFromPrevObjectApiName != null) {
            System.debug('isValid() fail: Both relationship details are populated for relationship: ' + this);
            return false;
        }
        if(sharedToFieldToken == null && nextRelationship == null) {
            System.debug('isValid() fail: No shared to field or nested relationship for relationship: ' + this);
            return false;
        }
        if(sharedToFieldToken != null && nextRelationship != null) {
            System.debug('isValid() fail: Both shared to field and nested relationship populated for relationship: ' + this);
            return false;
        }
        if(nextRelationship != null) {
            System.debug(nextRelationship);
            if(!nextRelationship.isValid()) {
                System.debug('isValid() fail: Nested relationship not valid for relationship: ');
                return false;
            }
        }
        return true;
    }

}