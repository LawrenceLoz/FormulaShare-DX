/**
*Copyright 2019 Lawrence Newcombe
*
*Permission is hereby granted, free of charge, to any person obtaining a copy 
*of this software and associated documentation files (the "Software"), to deal 
*in the Software without restriction, including without limitation the rights 
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
*of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all 
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
*FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
*COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
*IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
*CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

public inherited sharing class FormulaShareSObjectShares extends fflib_SObjectDomain {

    public static FormulaShareSObjectShares mock;
    public static FormulaShareSObjectShares construct(List<SObject> sObjectList, Schema.SObjectType type) {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
        else {
            return new FormulaShareSObjectShares(sObjectList, type);
        }
    }
    
    public class FormulaShareException extends Exception {}    

    public Schema.SObjectType type;

    public FormulaShareSObjectShares(List<SObject> sObjectList, Schema.SObjectType type) {
        super(sObjectList, type);
        this.type = type;
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable2 {

        // Defined type constructor must be implemented but isn't required
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return null;
        }

        // Dynamic type constructor is used
        public fflib_SObjectDomain construct(List<SObject> sObjectList, Schema.SObjectType type) {
            return new FormulaShareSObjectShares(sObjectList, type);
        }
    }


    // To insert sharing records identified by FormulaShare as being required
    public void insertShares() {
        List<SObject> shares = Records;

        // Check that object can be created by current or requesting user (or bypass if this is a test run)
        if(type.getDescribe().isAccessible() && type.getDescribe().isCreateable()) {
            // Insert the sharing record
            // NOTE - in the case where a share exists for this entity and reason at a lower level, this will 
            // update the existing share rather than create a new one. For this reason, assessment of sharing will only
            // delete shares if there is no sharing of any level to be applied
            insert shares;
            system.debug('DML inserted shares '+ shares);
        }

        else if(!type.getDescribe().isAccessible()) {
            throw new FormulaShareException('Share insert failed - share object not accessible to running user. Ensure object supports sharing and that batch running user has Modify All permission for the object');
        }

        else if(!type.getDescribe().isCreateable()) {
            throw new FormulaShareException('Share insert failed - share object not creatable for running user. Ensure object supports sharing and that batch running user has Modify All permission for the object');
        }
    }

    // To remove sharing identified by FormulaShareService as no longer being required
    public void deleteShares() {
        List<SObject> shares = Records;

        // Check that object can be deleted by current or requesting user (or bypass if this is a test run)
        if(type.getDescribe().isAccessible() && type.getDescribe().isDeletable()) {
            system.debug('DML shares to be deleted '+ shares);
            delete shares;
        }

        else if(!type.getDescribe().isAccessible()) {
            throw new FormulaShareException('Share delete failed - share object not accessible to running user. Ensure object supports sharing and that batch running user has Modify All permission for the object');
        }

        else if(!type.getDescribe().isDeletable()) {
            throw new FormulaShareException('Share delete failed - share object not deleteable for running user. Ensure object supports sharing and that batch running user has Modify All permission for the object');
        }
    }

}
