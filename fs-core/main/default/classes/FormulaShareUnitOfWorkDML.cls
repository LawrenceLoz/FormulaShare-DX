public inherited sharing class FormulaShareUnitOfWorkDML implements fflib_SObjectUnitOfWork.IDML {

	// Override standard fflibs methods to check object and field access
	public void dmlInsert(List<SObject> objList) {

		// Strip inaccessible fields (true parameter requests object checks as well - exception if no object access)
		SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.CREATABLE, objList, true);
		System.debug('Fields removed by stripInaccessible: '+securityDecision.getRemovedFields());
		insert securityDecision.getRecords();

		// Assign ids back to objects to enable fflibs to resolve relationships
		Integer i = 0;
		for(SObject obj : objList) {
			obj.Id = securityDecision.getRecords()[i].Id;
			i++;
		}
	}

	public void dmlUpdate(List<SObject> objList) {
		SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, objList, true);
		System.debug('Fields removed by stripInaccessible: '+securityDecision.getRemovedFields());
		update securityDecision.getRecords();
	}

	// Check object is accessible and deleteable
	// If mulitple types in uow, fflibs will split these and call dmlDelete by object 
	// so we only need to check one record to know the type
	public void dmlDelete(List<SObject> objList) {
		if(objList.isEmpty()) {
			return;
		}
		Schema.SObjectType type = objList[0].getSObjectType();
		if(type.getDescribe().isAccessible() && type.getDescribe().isDeletable()) {
			delete objList;
		}
	}

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