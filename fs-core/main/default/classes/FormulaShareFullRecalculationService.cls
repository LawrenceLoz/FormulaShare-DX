/**
*Copyright 2024 Lawrence Newcombe
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

public inherited sharing class FormulaShareFullRecalculationService {

	public static void recalculateAll() {
		List<Schema.SObjectType> types = getSharedObjectTypes();
		if(!types.isEmpty()) {
			FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
			Integer batchSize = settings.Recalculation_Batch_Size__c.intValue();
			Id batchJobId = Database.executeBatch(new FormulaShareProcessBatch(types, 'Full Recalculation Batch', batchSize), batchSize);
		}
	}
	

	private static List<SObjectType> getSharedObjectTypes() {

		List<SObjectType> typesList = new List<SObjectType>();
		Set<SObjectType> typesSet = new Set<SObjectType>();

		// Loop through all rules and populate set of shared objects
        FormulaShareRulesSelector rulesSelector = new FormulaShareInjectionService().getRulesSelector();

		for(String objName : rulesSelector.selectObjectsWithRules(false).keySet()) {
			SObjectType type = FormulaShareUtilities.globalDescribe.get(objName);
			typesSet.add(type);
		}

		// Get object settings to determine sequence ordering
		FormulaShareRemoveSharesSelector settingsSelector = new FormulaShareInjectionService().getRemoveSharesSelector();
		List<FormulaShare_Std_Object_to_Remove_Shares__mdt> allSettings = settingsSelector.getAllSettings();
		
		// Build map of object name to sequence for objects with settings
		Map<String, Decimal> objectNameToSequence = new Map<String, Decimal>();
		for(FormulaShare_Std_Object_to_Remove_Shares__mdt settings : allSettings) {
			String objName = settings.Standard_Object_to_Remove_Sharing__r.QualifiedApiName;
			if(settings.Sequence__c != null) {
				objectNameToSequence.put(objName, settings.Sequence__c);
			}
		}
		
		// Separate objects into those with sequence and those without
		List<SObjectType> typesWithSequence = new List<SObjectType>();
		List<SObjectType> typesWithoutSequence = new List<SObjectType>();
		Map<SObjectType, String> typeToNameCache = new Map<SObjectType, String>();
		
		for(SObjectType type : typesSet) {
			String objectName = type.getDescribe().getName();
			typeToNameCache.put(type, objectName);
			if(objectNameToSequence.containsKey(objectName)) {
				typesWithSequence.add(type);
			} else {
				typesWithoutSequence.add(type);
			}
		}
		
		// Sort objects with sequence by their sequence number
		Map<Decimal, List<SObjectType>> sequenceToTypes = new Map<Decimal, List<SObjectType>>();
		for(SObjectType type : typesWithSequence) {
			String objectName = typeToNameCache.get(type);
			Decimal sequence = objectNameToSequence.get(objectName);
			if(!sequenceToTypes.containsKey(sequence)) {
				sequenceToTypes.put(sequence, new List<SObjectType>());
			}
			sequenceToTypes.get(sequence).add(type);
		}
		
		// Get sorted sequence numbers
		List<Decimal> sortedSequences = new List<Decimal>(sequenceToTypes.keySet());
		sortedSequences.sort();
		
		// Build final list: objects with sequence first (in order), then objects without sequence
		for(Decimal sequence : sortedSequences) {
			typesList.addAll(sequenceToTypes.get(sequence));
		}
		typesList.addAll(typesWithoutSequence);

		return typesList;
	}

}
