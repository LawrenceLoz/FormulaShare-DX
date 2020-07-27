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

    List<FormulaShare_Processed_Share_Event__e> pseList = new List<FormulaShare_Processed_Share_Event__e>();

    public void addInsertEvents(Map<String,FormulaShareService.ShareDetail> shareDetails, String status, String statusReason) {

        // Continue only if logging is enabled
        FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        if(settings.Log_Processing_Events__c == 'Deleted Sharing Only' || settings.Log_Processing_Events__c == 'None') {
            return;
        }

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


    public void addDeleteEvents(Map<String,FormulaShareService.ShareDetail> shareDetails, String status, String statusReason) {

        // Continue only if logging is enabled
        FormulaShare_Settings__mdt settings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        if(settings.Log_Processing_Events__c == 'Inserted Sharing Only' || settings.Log_Processing_Events__c == 'None') {
            return;
        }

        Map<String,FormulaShare_Processed_Share_Event__e> pseMap = getEventsForRecordDetail(shareDetails, status, statusReason);

        // Set operation and add to list to publish
        for(FormulaShare_Processed_Share_Event__e pse : pseMap.values()) {
            pse.Operation__c = 'Delete';
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
    public void processDirectly() {
        if(!pseList.isEmpty()) {
            FormulaShareProcessedShareEventService.process(pseList);
            pseList.clear();
        }
    }


    // Map detail from share records to plaform events
    private Map<String,FormulaShare_Processed_Share_Event__e> getEventsForRecordDetail(Map<String,FormulaShareService.ShareDetail> shareDetails, String status, String statusReason) {

        Map<String,FormulaShare_Processed_Share_Event__e> pseMap = new Map<String,FormulaShare_Processed_Share_Event__e>();

        // For each share, create a platform event
        for(String key : shareDetails.keySet()) {
            FormulaShareService.ShareDetail sd = shareDetails.get(key);

            FormulaShare_Processed_Share_Event__e pse = new FormulaShare_Processed_Share_Event__e();
            Schema.DescribeSObjectResult typeDesc = sd.type.getDescribe();
            String objectName = typeDesc.getName();
            system.debug('obj name *** '+objectName);
            pse.Object__c = objectName;

            SObject share = sd.shareRecord;
            pse.Shared_to_Id__c = String.valueOf(share.get('UserOrGroupId'));
            pse.Share_Id__c = share.Id;
            pse.Share_Key__c = key;
            pse.Processed_Date_Time__c = System.now();

            // Set statuses if provided (if left blank, shares will be queried as part of processing for logs)
            pse.Status__c = status;
            pse.Failed_Status_Reason__c = statusReason;

            // Set attributes from share record according to whether standard or custom object
            if(!typeDesc.isCustom()) {
                pse.Record_Id__c = String.valueOf(share.get(objectName + 'Id'));
                pse.Access_Level__c = (String) share.get(objectName + 'AccessLevel');
            }
            else {
                pse.Record_Id__c = String.valueOf(share.get('ParentId'));
                pse.Access_Level__c = (String) share.get('AccessLevel');
                pse.Sharing_Reason__c = (String) share.get('RowCause');
            }

            pseMap.put(key, pse);
        }

        return pseMap;
    }
}
