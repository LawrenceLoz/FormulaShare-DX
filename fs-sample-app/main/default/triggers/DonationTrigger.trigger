trigger DonationTrigger on Donation__c (after insert, after update) {
	FormulaShareHelper helper = new FormulaShareHelper();
    insert helper.getSharesToInsert();
    delete helper.getSharesToDelete();
}