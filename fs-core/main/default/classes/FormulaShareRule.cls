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


// Class variables are primitive types representing the FormulaShareRule custom metadata
// fields. This is required because mocking of custom metadata relationships isn't possible

public inherited sharing class FormulaShareRule {

	public String objectSharedAPIName;
	public String sharedToAPIName;
	public String shareWith;
	public String accessLevel;
	public Boolean active;
	public String sharedToFieldType;
	public String sharingReason;


    // Return a populated share record with appropriate values for this rule and a record and user combination
	public SObject getShareRecord(Schema.SObjectType type, Id recordId, Id sharedTo) {
		Schema.SObjectType shareType = FormulaShareUtilities.getShareObject(type);
		SObject newShare = shareType.newSObject();

        // Populate values if object is custom
        if(type.getDescribe().isCustom()) {
            newShare.put('AccessLevel', accessLevel);
            newShare.put('ParentId', recordId);
            newShare.put('UserOrGroupId', sharedTo);
            newShare.put('RowCause', sharingReason);
        }

        // Populate values if object is standard (format of share records is a bit different)
        else {
            newShare.put(type + 'AccessLevel', accessLevel);
            newShare.put(type + 'Id', recordId);
            newShare.put('UserOrGroupId', sharedTo);
    //		newShare.put('RowCause','Manual');		// Only reason supported for standard objects is manual (set by default)
        }

		return newShare;
	}

}
