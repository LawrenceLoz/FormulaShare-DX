/**
*Copyright 2018 Lawrence Newcombe
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

@isTest
public with sharing class FormulaShareServiceTest {
	
	@isTest
	public static void recalculateAllTest() {

		UserRole roleForTest = [SELECT Id, DeveloperName FROM UserRole LIMIT 1][0];

		Contact con = new Contact();

		// Set fields which have test rules created within apex class
		con.FirstName = roleForTest.DeveloperName;	// Share with role (name)
		con.LastName = roleForTest.Id;				// Share with role and subordinates (Id)
		con.Description = 'AllInternalUsers';		// Share with group (name)
		con.AssistantName = UserInfo.getUserId();	// Share with user (Id)
		insert con;

		test.startTest();
		FormulaShareService.recalculateAll();
		test.stopTest();

//		contactRequery = [SELECT Id FROM Contact WHERE Id = :con.Id][0];
		List<ContactShare> shares = [SELECT Id FROM ContactShare WHERE Id = :con.Id];
		system.debug('SharesFound:'+shares.size());
	}
}