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

public inherited sharing class FormulaShareProcessEventPublisher {

    String contextDetail;
    String assessmentType;
    String runningUser;

    public FormulaShareProcessEventPublisher(String contextDetail, String assessmentType) {
        this.contextDetail = contextDetail;
        this.assessmentType = assessmentType;
        this.runningUser = UserInfo.getUserId();
    }

    List<FormulaShare_Processed_Share_Event__e> pseList = new List<FormulaShare_Processed_Share_Event__e>();

    List<String> rulesDeveloperNames;
    public void setRulesDeveloperNames(List<String> rulesDeveloperNames) {
        this.rulesDeveloperNames = rulesDeveloperNames;
    }

    // Log when service class has identified insert is needed
    public void addInsertEvents(Map<String,FormulaShareService.ShareDetail> shareDetails, String status, String statusReason) {

        Map<String,FormulaShare_Processed_Share_Event__e> pseMap = getEventsForRecordDetail(shareDetails, status, statusReason);

        // Add details from rule, set operation and add to list to publish
        for(String key : pseMap.keySet()) {
            FormulaShare_Processed_Share_Event__e pse = pseMap.get(key);
            FormulaShareService.ShareDetail sd = shareDetails.get(key);
            pse.FormulaShare_Rule_Name__c = sd.rule.developerName;
            pse.Operation__c = 'Insert';
            pseList.add(pse);
        }
    }

    // Log when service class has identified deletion is needed
    public void addDeleteEvents(Map<String,FormulaShareService.ShareDetail> shareDetails, String status, String statusReason) {

        Map<String,FormulaShare_Processed_Share_Event__e> pseMap = getEventsForRecordDetail(shareDetails, status, statusReason);

        // Set operation and add to list to publish
        for(FormulaShare_Processed_Share_Event__e pse : pseMap.values()) {
            pse.Operation__c = 'Delete';
            pseList.add(pse);
        }
    }

    // Log when service class processed a non-blank field but didn't find an entity
    public void addEventsForEntitiesNotFound(List<FormulaShareService.EntityNotFound> entitiesNotFound) {
        for(FormulaShareService.EntityNotFound enf : entitiesNotFound) {
            FormulaShare_Processed_Share_Event__e pse = getBasicShareEvent();
            pse.Status__c = 'Error';
            pse.Operation__c = 'Insert';
            pse.Object__c = enf.type.getDescribe().getName();
            System.debug('Mapping PSE for sharing not detected on '+ pse.Object__c);
            pse.Record_Id__c = enf.recordId;
            pse.Failed_Status_Reason__c = enf.failedStatusReason;
            pse.Access_Level__c = (String) enf.rule.accessLevel;
            pse.Sharing_Reason__c = (String) enf.rule.sharingReason;
            pse.Share_With__c = (String) enf.rule.shareWith;
            pse.FormulaShare_Rule_Name__c = enf.rule.developerName;
            pse.Rules_Assessed__c = enf.rulesAssessed;
            pseList.add(pse);
        }
    }


    public void setBatch(Id batchId) {
        for(FormulaShare_Processed_Share_Event__e pse : pseList) {
            pse.Related_Batch_Log_Id__c = String.valueOf(batchId);
        }
    }

    public void publish() {
        if(!pseList.isEmpty()) {
            EventBus.publish(pseList);
            pseList.clear();
        }
    }


    // Method to process insertion of record logs directly rather than via published events
    // This is called by the full batch job and by targeted batches with appropriate context for metrics records
    public FormulaShareProcessedShareEventService.IncrementsWithUow processForTargetedJobOrBatch(fflib_ISObjectUnitOfWork uow, FormulaShare_Log__c relatedBatchLog, String context) {
        
        // Set logs for processed shares
        FormulaShareProcessedShareEventService.IncrementsWithUow incWithUow = FormulaShareProcessedShareEventService.processForTargetedJobOrBatch(uow, pseList, relatedBatchLog, context);
        system.debug('Processing for batch. UOW3: '+uow);
        pseList.clear();

        return incWithUow;
    }


    // Map detail from share records to plaform events
    private Map<String,FormulaShare_Processed_Share_Event__e> getEventsForRecordDetail(Map<String,FormulaShareService.ShareDetail> shareDetails, String status, String statusReason) {

        Map<String,FormulaShare_Processed_Share_Event__e> pseMap = new Map<String,FormulaShare_Processed_Share_Event__e>();

        // For each share, create a platform event
        for(String key : shareDetails.keySet()) {
            FormulaShareService.ShareDetail sd = shareDetails.get(key);

            FormulaShare_Processed_Share_Event__e pse = getBasicShareEvent();
            
            pse.Object__c = sd.type.getDescribe().getName();
            System.debug('Mapping PSE for detected sharing on '+ pse.Object__c);

            SObject share = sd.shareRecord;
            pse.Shared_to_Id__c = String.valueOf(share.get('UserOrGroupId'));
            pse.Share_Id__c = share.Id;
            pse.Share_Key__c = key;
            pse.Existing_Sharing_On_Record__c = sd.existingSharingOnRecord;
            pse.Rules_Assessed__c = sd.rulesAssessed;

            // Set statuses if provided (if left blank, shares will be queried as part of processing for logs)
            pse.Status__c = status;
            pse.Failed_Status_Reason__c = statusReason;

            // Set attributes from share record according to whether standard or custom object
            FormulaShareSObjectUtilities objUtils = new FormulaShareSObjectUtilities(sd.type);
            pse.Record_Id__c = sd.recordId;
            pse.Access_Level__c = (String) share.get(objUtils.accessLevelFieldName());
            pse.Sharing_Reason__c = (String) share.get('RowCause');

            pseMap.put(key, pse);
        }

        return pseMap;
    }

    private FormulaShare_Processed_Share_Event__e getBasicShareEvent() {
        FormulaShare_Processed_Share_Event__e pse =new FormulaShare_Processed_Share_Event__e();
        pse.Context_Detail__c = this.contextDetail;
        pse.Assessment_Type_Override__c = this.assessmentType;
        pse.Running_User__c = this.runningUser;
        pse.Processed_Date_Time__c = System.now();
        return pse;
    }

}
