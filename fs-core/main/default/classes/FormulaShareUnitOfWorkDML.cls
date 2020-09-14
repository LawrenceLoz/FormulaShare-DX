public inherited sharing class FormulaShareUnitOfWorkDML implements fflib_SObjectUnitOfWork.IDML {
	public void dmlInsert(List<SObject> objList) { DMLManager.insertAsUser(objList); }
	public void dmlUpdate(List<SObject> objList) { DMLManager.updateAsUser(objList); }
	public void dmlDelete(List<SObject> objList) { DMLManager.deleteAsUser(objList); }

    public void eventPublish(List<SObject> records) {
        if (records == null || records.size() == 0) return; // avoid wasting any cycles
        EventBus.publish(records);
	}

	public void emptyRecycleBin(List<SObject> objList) {
		if (objList.isEmpty())
		{
			return;
		}
		Database.emptyRecycleBin(objList);
	}
}