trigger DonationTrigger on Donation__c (after insert, after update) {
	FormulaShareTriggerHelper.run();
}