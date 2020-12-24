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
