/**
*Copyright 2022 Lawrence Newcombe
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

public inherited sharing virtual class FormulaShareMetadataDMLRulesActivate extends FormulaShareMetadataDMLBase {

    public FormulaShareMetadataDMLRulesActivate() {
        super();

        // The only field to be set is Active__c - we won't have values for any others
        this.fieldsToSetOrClear = new Set<String> { namespacePrefix + 'Active__c' };

        this.mdNamePrefix = 'FormulaShare_Rule.';
    }

    // Kept in class variable so we can test it populates
    @TestVisible
    private List<FormulaShare_List_Update__e> eventsViewList = new List<FormulaShare_List_Update__e>();

    public override void handleDeploySuccess(Metadata.DeployResult result) {
        FormulaShare_List_Update__e updateEvent = new FormulaShare_List_Update__e();
        updateEvent.Type__c = 'activate';
        eventsViewList.add(updateEvent);
        List<Database.SaveResult> results = EventBus.publish(eventsViewList);
        system.debug('Published activate/deactivate');
    }

    public override void handleDeployError(Metadata.DeployResult result) {
        System.debug('Error with rule activation');
    }

}
