trigger DonationTrigger on Donation__c (after insert, after update) {
	FormulaShareTriggerHelper helper = new FormulaShareTriggerHelper();
    insert helper.getSharesToInsert();
    delete helper.getSharesToDelete();
}