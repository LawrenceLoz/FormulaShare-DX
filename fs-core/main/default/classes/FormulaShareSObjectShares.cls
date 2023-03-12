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

// Domain class isn't used so we can pass to methods directly for mocking
public inherited sharing class FormulaShareSObjectShares {
    
    private Schema.SObjectType type;
    public class FormulaShareException extends Exception {}    

    public static FormulaShareSObjectShares mock;
    public static FormulaShareSObjectShares construct(Schema.SObjectType type) {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
        else {
            return new FormulaShareSObjectShares(type);
        }
    }

    public FormulaShareSObjectShares(Schema.SObjectType type) {
        this.type = type;
    }


    // To insert sharing records identified by FormulaShare as being required
    public void insertShares(List<SObject> shares) {

        // Check that object can be created by current or requesting user (or bypass if this is a test run)
        // Note there's no need to check field security as this can't be set on share records
        if(type.getDescribe().isAccessible() && type.getDescribe().isCreateable()) {

            // Insert the sharing record
            // NOTE - in the case where a share exists for this entity and reason at a lower level, this will 
            // update the existing share rather than create a new one. For this reason, assessment of sharing will only
            // delete shares if there is no sharing of any level to be applied

            // NOPMD required (false apexcrudviolation)
            // Batch operates on a single object and all shares will be of this type (access checked above)
            insert shares;  //NOPMD

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
    public void deleteShares(List<SObject> shares) {

        // Check that object can be deleted by current or requesting user (or bypass if this is a test run)
        if(type.getDescribe().isAccessible() && type.getDescribe().isDeletable()) {
            system.debug('DML shares to be deleted '+ shares);

            // NOPMD required (false apexcrudviolation)
            // Batch operates on a single object and all shares will be of this type (access checked above)
            delete shares;  //NOPMD
        }

        else if(!type.getDescribe().isAccessible()) {
            throw new FormulaShareException('Share delete failed - share object not accessible to running user. Ensure object supports sharing and that batch running user has Modify All permission for the object');
        }

        else if(!type.getDescribe().isDeletable()) {
            throw new FormulaShareException('Share delete failed - share object not deleteable for running user. Ensure object supports sharing and that batch running user has Modify All permission for the object');
        }
    }

}
