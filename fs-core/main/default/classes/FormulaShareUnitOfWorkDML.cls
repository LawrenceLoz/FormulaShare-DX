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

	public void dmlDelete(List<SObject> objList) {
		if(objList.isEmpty()) {
			return;
		}
		Schema.SObjectType type = objList[0].getSObjectType();
		if(type.getDescribe().isAccessible() && type.getDescribe().isDeletable()) {

            // NOPMD required (false apexcrudviolation)
			// If mulitple types in uow, fflibs will split these and call dmlDelete by object
			// so we only need to check one record to know the type
			delete objList;  //NOPMD
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