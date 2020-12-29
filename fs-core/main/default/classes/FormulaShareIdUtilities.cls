/**
*Copyright 2020 Lawrence Newcombe
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

public inherited sharing class FormulaShareIdUtilities {

    public static FormulaShareIdUtilities mock;
    public static FormulaShareIdUtilities construct() {
        if(Test.isRunningTest() && mock != null ) {
            return mock;
        }
        else {
            return new FormulaShareIdUtilities();
        }
    }

    
    // Static implementation will never be mocked
	public static String get15CharacterId(Id longId) {
		if(longId != null) {
			String shortId = ((String) longId).left(15);
			return shortId;
		}
		else {
			return null;
		}
	}
	
	// Instance implementation for mocking
	public String get15CharacterIdInstance(Id longId) {
		return get15CharacterId(longId);
	}


	public Boolean isValidIdType(String candidateId, Schema.SObjectType shareWithType) {
		
		// Accetable if null
		if(candidateId == null) {
			return true;
		}

		else {
			
			// Check Id is valid
			Id idValueToCheck;
			if(isValidIdType(candidateId)) {
				idValueToCheck = (Id) candidateId;
			}
			else {
				return false;
			}

			// Check that Id is the expected type
			if(idValueToCheck.getSObjectType() == shareWithType) {
				return true;
			}
			else {
				return false;
			}
		}
	}

	public Boolean isValidIdType(String candidateId) {
		
		// Check we can cast to an Id
		Id idValueToCheck;
		try {
			idValueToCheck = (Id) candidateId;
		}
		catch(Exception e) {
			return false;
		}
		return true;
	}


}
