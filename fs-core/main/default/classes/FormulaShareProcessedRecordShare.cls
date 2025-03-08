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

public virtual inherited sharing class FormulaShareProcessedRecordShare {

    // Adds record sharing level DML into supplied unit of work
    public fflib_ISObjectUnitOfWork uow;
    public List<PRSWrapper> wrappedRecordShares = new List<PRSWrapper>();

    protected Set<Id> recordsSharingAppliedFirstTime = new Set<Id>();
    protected Set<Id> recordsAllSharingRemoved = new Set<Id>();
    protected Set<Id> noRecordsSharingUpdated = new Set<Id>();
    protected Set<Id> recordsWithFailedDeletes = new Set<Id>();

    // Record ids kept in wrapper so we can count unique records shared
    public inherited sharing class PRSWrapper {
        public PRSWrapper(FormulaShare_Processed_Record_Share__c processedRecordShare, Id recordId) {
            this.processedRecordShare = processedRecordShare;
            this.recordId = recordId;
        }
        public FormulaShare_Processed_Record_Share__c processedRecordShare;
        public Id recordId;
    }

    public virtual fflib_ISObjectUnitOfWork prepare(fflib_ISObjectUnitOfWork uow, String context, List<FormulaShare_Record_Log__c> recordLogs, Map<String,List<FormulaShare_Processed_Share_Event__e>> eventsByType, Boolean createRecordLogs) {
        this.uow = uow;
        processRecordShares(recordLogs, eventsByType, createRecordLogs);
        return uow;
    }
    
    public Integer getRecordsSharingAppliedFirstTime() {
        return recordsSharingAppliedFirstTime.size();
    }
    public Integer getRecordsAllSharingRemoved() {
        return recordsAllSharingRemoved.size();
    }
    public Integer getNoRecordsSharingUpdated() {
        return noRecordsSharingUpdated.size();
    }


    protected void processRecordShares(List<FormulaShare_Record_Log__c> recordLogs, Map<String,List<FormulaShare_Processed_Share_Event__e>> eventsByType, Boolean createRecordLogs) {

        Map<String,FormulaShare_Record_Log__c> recordLogsMap = new Map<String,FormulaShare_Record_Log__c>();
        for(FormulaShare_Record_Log__c recordLog : recordLogs) {
            recordLogsMap.put(recordLog.Record_Id__c, recordLog);
        }

        for(String objectName : eventsByType.keySet()) {

            // Build sets of record ids and sharing reasons for query
            Set<String> recordIdsSet = new Set<String>();
            Set<String> sharingReasonsSet = new Set<String>();
            List<FormulaShare_Processed_Share_Event__e> pseForObjectList = eventsByType.get(objectName);
            List<FormulaShare_Processed_Share_Event__e> pseWithoutStatus = new List<FormulaShare_Processed_Share_Event__e>();

            // Query for details of relevant groups
            Map<Id,Group> groupsMap = getGroupsMap(pseForObjectList);

            for(FormulaShare_Processed_Share_Event__e pse : pseForObjectList) {

                // If status was set (e.g. if entity not found) there's no need to query, so map to record and add to be inserted
                if(pse.Status__c != null) {
                    System.debug('Adding share with status set: '+pse);
                    FormulaShare_Processed_Record_Share__c prs = mapEventToProcessedRecordShare(pse, recordLogsMap, groupsMap, createRecordLogs);
                    PRSWrapper prsWrapper = new PRSWrapper(prs, pse.Record_Id__c);
                    wrappedRecordShares.add(prsWrapper);

                    // Indicate sharing exists on record
                    assessExistingSharing(pse.Existing_Sharing_On_Record__c, prs.Operation__c, prs.Status__c, pse.Record_Id__c);
                }

                // Otherwise track in list to be augmented with status
                if(pse.Status__c == null) {
                    pseWithoutStatus.add(pse);
                    recordIdsSet.add(pse.Record_Id__c);
                    sharingReasonsSet.add(pse.Sharing_Reason__c);    // Note this will be null for standard objects
                }
            }

            // If we found shares without status, query for these to check status and add details
            if(!recordIdsSet.isEmpty()) {

                String parentIdsString = FormulaShareUtilities.buildStringFromSetQuotes(recordIdsSet);

                // Get SOBject types for queries
                SOBjectType type = FormulaShareUtilities.getSObjectTypeFromName(objectName);
                SObjectType shareObjectType = FormulaShareUtilities.getShareObject(type);

                // Build sets of share keys and record ids for existing sharing on the records in scope
                Set<String> shareKeySet = new Set<String>();
                Set<Id> shareIdSet = new Set<Id>();

                // For standard objects, query for all shares and add keys & ids to sets
                List<SObject> sharesList;
                FormulaShareSObjectSharesSelector sharesSelector = new FormulaShareSObjectSharesSelector(true, shareObjectType, type);
                if(!type.getDescribe().isCustom()) {
                    sharesList = sharesSelector.selectByParentIds(parentIdsString);
                }

                // For custom objects, query for all shares and add to sets
                else {
                    String rowCausesString = FormulaShareUtilities.buildStringFromSetQuotes(sharingReasonsSet);
                    sharesList = sharesSelector.selectByParentIdsAndRowCauses(parentIdsString, rowCausesString);
                }

                for(SObject share : sharesList) {
                    FormulaShareSOBjectUtilities objectUtils = new FormulaShareSOBjectUtilities(type);
                    String shareKey = objectUtils.getShareKey(share);
                    shareKeySet.add(shareKey);
                    shareIdSet.add(share.Id);
                }

                // Set statuses based on information returned
                for(FormulaShare_Processed_Share_Event__e pse : pseWithoutStatus) {

                    FormulaShare_Processed_Record_Share__c prs = mapEventToProcessedRecordShare(pse, recordLogsMap, groupsMap, createRecordLogs);

                    // For insert, check whether share record was found in queried records and set to Success if so
                    if(prs.Operation__c == 'Insert') {
                        if(shareKeySet.contains(pse.Share_Key__c)) {
                            System.debug('Found the record for this share: '+pse.Share_Key__c);
                            prs.Status__c = 'Success';
                        }
                        else {
                            System.debug('No record found for this share : '+pse.Share_Key__c);
                            prs.Status__c = 'Error';
                            prs.Status_Reason__c = 'Share record to be inserted wasn\'t detected in query';
                        }
                    }

                    // For delete, check whether share record was found in queried records and set to Success if not
                    else if(prs.Operation__c == 'Delete') {
                        if(!shareIdSet.contains(pse.Share_Id__c)) {
                            System.debug('Confirmed this share was deleted: '+pse.Share_Key__c);
                            prs.Status__c = 'Success';
                        }
                        else {
                            System.debug('Expected this share to be deleted (record still exists): '+pse.Share_Key__c);
                            prs.Status__c = 'Error';
                            prs.Status_Reason__c = 'Share record identified for removal not actually deleted';
                        }
                    }

                    assessExistingSharing(pse.Existing_Sharing_On_Record__c, prs.Operation__c, prs.Status__c, pse.Record_Id__c);

                    PRSWrapper prsWrapper = new PRSWrapper(prs, pse.Record_Id__c);
                    wrappedRecordShares.add(prsWrapper);
                }

                // Set indication that all sharing removed if all deletion successful
                recordsAllSharingRemoved.removeAll(recordsWithFailedDeletes);
            }
        }

        if(createRecordLogs) {
            processRecordLogUpdates(recordLogs);
        }

        System.debug('Full wrappedRecordShares list: '+wrappedRecordShares);
    }


    // Sets indication that sharing is for a record which is shared for first time, or has had all sharing removed
    private void assessExistingSharing(Boolean existingSharingOnRecord, String operation, String status, Id recordId) {

        // If there was no existing sharing identified on the record other than for this change
        // this could indcate it's the first time this record is shared, or that all sharing is removed
        if(!existingSharingOnRecord) {
            if(operation == 'Insert' && status == 'Success') {
                recordsSharingAppliedFirstTime.add(recordId);   // Note we don't failed inserts in totals
            }
            else if(operation == 'Delete') {
                if(status == 'Success') {
                    recordsAllSharingRemoved.add(recordId);
                }
                else {
                    recordsWithFailedDeletes.add(recordId);
                    noRecordsSharingUpdated.add(recordId);
                }
            }
        }

        // Otherwise, we consider that this record should be part of the count of existing shared records
        else {
            noRecordsSharingUpdated.add(recordId);
        }

        // Note that records which had any kind of error won't be counted in the total
    }


    // If creating record logs, update these to have correct values for usage:
    // Sharing_Applied_for_First_Time__c - Set if any successful share created and sharing didn't already exist
    // All_Sharing_Removed__c - Set if all sharing 
    protected void processRecordLogUpdates(List<FormulaShare_Record_Log__c> recordLogs) {
        for(FormulaShare_Record_Log__c log : recordLogs) {
            if(recordsSharingAppliedFirstTime.contains((Id) log.Record_Id__c)) {
                log.Sharing_Applied_for_First_Time__c = true;
            }
            else if(recordsAllSharingRemoved.contains((Id) log.Record_Id__c)) {
                log.All_Sharing_Removed__c = true;
            }
        }
    }


    // Returns a map of groups corresponding to Shared_to_Id__c values in events list
    private Map<Id,Group> getGroupsMap(List<FormulaShare_Processed_Share_Event__e> pseList) {

        // Find groups we'll need to query based on Shared_to_Id__c type
        List<Id> groupIdList = new List<Id>();
        for(FormulaShare_Processed_Share_Event__e pse : pseList) {
            if(pse.Shared_to_Id__c != null) {
                Id userOrGroupId = Id.valueOf(pse.Shared_to_Id__c);
                Schema.SObjectType userOrGroupType = userOrGroupId.getSObjectType();

                if(userOrGroupType == Group.SOBjectType) {
                    system.debug('group id: '+userOrGroupId);
                    groupIdList.add(userOrGroupId);
                }
            }
        }
        
        // Build map of groups to populate details on processed records
        Map<Id,Group> groupsMap = new Map<Id,Group>();
        if(!groupIdList.isEmpty()) {
            groupsMap = new Map<Id,Group>([SELECT Id, DeveloperName, Type FROM Group WHERE Id IN :groupIdList]);
        }

        return groupsMap;
    }


    // Returns a record based on the event, which is populated with group details and success / failure info
    private FormulaShare_Processed_Record_Share__c mapEventToProcessedRecordShare(FormulaShare_Processed_Share_Event__e pse, Map<String,FormulaShare_Record_Log__c> recordLogsMap, Map<Id,Group> groupsMap, Boolean createRecordLogs) {
        FormulaShare_Processed_Record_Share__c prs = new FormulaShare_Processed_Record_Share__c();

        // Set lookup to processed record and other common fields
        prs.Operation__c = pse.Operation__c;
        prs.Sharing_Reason__c = pse.Sharing_Reason__c;
        prs.FormulaShare_Rule_Name__c = pse.FormulaShare_Rule_Name__c;
        prs.Access_Level__c = pse.Access_Level__c;

        // Set status if provided
        prs.Status__c = pse.Status__c;
        prs.Status_Reason__c = pse.Failed_Status_Reason__c;

        // Populate share with type and relevant fields depending on user or group sharing
        // Check whether user or group share
        if(pse.Shared_to_Id__c != null) {
            Id userOrGroupId = Id.valueOf(pse.Shared_to_Id__c);
            system.debug('userOrGroupId: '+ userOrGroupId);
            Schema.SObjectType userOrGroupType = userOrGroupId.getSObjectType();
            if(userOrGroupType == User.SOBjectType) {
                prs.Shared_to_User__c = userOrGroupId;
                prs.Share_With__c = 'Users';
            }
            else if(userOrGroupType == Group.SOBjectType) {
                Group grp = groupsMap.get(userOrGroupId);
                prs.Shared_to_Role_or_Group__c = grp.DeveloperName;
                prs.Share_With__c = grp.Type;
            }
        }

        // If share with wasn't populated based on id type (e.g. if entity not found), set this from attribute
        // (we don't do this for all logs because share with isn't known for deletes)
        else {
            prs.Share_With__c = pse.Share_With__c;
        }

        if(createRecordLogs) {
            // Set master detail relationship
            FormulaShare_Record_Log__c recordLog = recordLogsMap.get(pse.Record_Id__c);
            uow.registerNew(prs, FormulaShare_Processed_Record_Share__c.Processed_Record__c, recordLog);
        }

        return prs;
    }    

}
