/**
*Copyright 2023 Lawrence Newcombe
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

// Class specifies with sharing, so should only be called from front end
public with sharing class FormulaShareLWCUtilities {

    @AuraEnabled(cacheable=true)
    public static String getNamespacePrefix() {
        return FormulaShareUtilities.getNamespacePrefix();
    }

	// Used by controller to build links to setup menu items
	@AuraEnabled(cacheable=true)
	public static String getLightningDomain(){
        return getMyDomain() + '.lightning.force.com';
    }

	@AuraEnabled(cacheable=true)
	public static String getClassicDomain(){
        return URL.getSalesforceBaseUrl().toExternalForm();
    }

    private static String getMyDomain(){
        return URL.getOrgDomainUrl().getHost().split('\\.')[0].toLowerCase();
	}

	@AuraEnabled(cacheable=true)
	public static Map<String,String> getSharingReasons(String objectApiName) {
        return FormulaShareUtilities.getSharingReasons(objectApiName);
    }

	@AuraEnabled(cacheable=true)
	public static Boolean isContactSharingControlledByAccount() {
        return FormulaShareUtilities.isContactSharingControlledByAccount();
    }

}