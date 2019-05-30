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

        try {
            if(type.getDescribe().isAccessible() && type.getDescribe().isCreateable()) {
                insert shares;
            }
        }
        catch(Exception e) {
            system.debug('Insert of share records failed. Message from Salesforce: '+e.getMessage());
        }
    }

    // To remove sharing identified by FormulaShareService as no longer being required
    public void deleteShares() {
        List<SObject> shares = Records;

        try {
            if(type.getDescribe().isAccessible() && type.getDescribe().isDeletable()) {
                delete shares;
            }
        }
        catch(Exception e) {
            system.debug('Deletion of share records failed. Message from Salesforce: '+e.getMessage());
        }
    }

}
