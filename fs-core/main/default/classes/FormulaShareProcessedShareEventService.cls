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

public inherited sharing class FormulaShareProcessedShareEventService {

    public static void process(List<FormulaShare_Processed_Share_Event__e> pseList) {

        Map<String,FormulaShare_Record_Log__c> processedRecords = new Map<String,FormulaShare_Record_Log__c>();
        Map<String,List<FormulaShare_Processed_Share_Event__e>> eventsByType = new Map<String,List<FormulaShare_Processed_Share_Event__e>>();
    
        for(FormulaShare_Processed_Share_Event__e pse : pseList) {
    
            // Contruct processed record logs
            if(!processedRecords.containsKey(pse.Record_Id__c)) {
                FormulaShare_Record_Log__c pr = new FormulaShare_Record_Log__c();
                pr.Object__c = pse.Object__c;
                pr.Record_Id__c = pse.Record_Id__c;
                pr.Processed_Date_Time__c = pse.Processed_Date_Time__c;
                if(pse.Related_Batch_Log_Id__c != null) {
                    pr.FormulaShare_Batch_Log__c = Id.valueOf(pse.Related_Batch_Log_Id__c);
                }
                processedRecords.put(pr.Record_Id__c, pr);
            }

            // Populate map with records split by object type
            List<FormulaShare_Processed_Share_Event__e> pseForObjectList;
            if(eventsByType.containsKey(pse.Object__c)) {
                pseForObjectList = eventsByType.get(pse.Object__c);
            }
            else {
                pseForObjectList = new List<FormulaShare_Processed_Share_Event__e>();
            }
            pseForObjectList.add(pse);
            eventsByType.put(pse.Object__c, pseForObjectList);
        }
    
        // Insert processed record objects
        List<FormulaShare_Record_Log__c> prList = processedRecords.values();
        Schema.SObjectType prType = FormulaShare_Record_Log__c.SObjectType;
        System.debug('prList.size() '+prList.size());
        if(prType.getDescribe().isAccessible() && prType.getDescribe().isCreateable()) {
            System.debug('prList.size() '+prList.size());
            insert prList;
        }
    
        // Validate automated user access to object, contruct processed record shares and insert
        Schema.SObjectType prsType = FormulaShare_Record_Log__c.SObjectType;
        if(prsType.getDescribe().isAccessible() && prsType.getDescribe().isCreateable()) {
            List<FormulaShare_Processed_Record_Share__c> processedRecordShares = getProcessedRecordShares(prList, eventsByType);
            insert processedRecordShares;
        }
    }


    private static List<FormulaShare_Processed_Record_Share__c> getProcessedRecordShares(List<FormulaShare_Record_Log__c> prList, Map<String,List<FormulaShare_Processed_Share_Event__e>> eventsByType) {
        List<FormulaShare_Processed_Record_Share__c> processedRecordShares = new List<FormulaShare_Processed_Record_Share__c>();

        Map<String,Id> insertedPrIdsMap = new Map<String,Id>();
        for(FormulaShare_Record_Log__c pr : prList) {
            insertedPrIdsMap.put(pr.Record_Id__c, pr.Id);
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

                // If status was set there's no need to query, so map to record and add to be inserted
                if(pse.Status__c != null) {
                    FormulaShare_Processed_Record_Share__c prs = mapEventToProcessedRecordShare(pse, insertedPrIdsMap, groupsMap);
                    processedRecordShares.add(prs);
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
                if(!type.getDescribe().isCustom()) {
                    FormulaShareSObjectSharesStdSelector sharesSelector = new FormulaShareSObjectSharesStdSelector(true, shareObjectType, type);
                    List<SObject> sharesList = sharesSelector.selectByParentIds(parentIdsString);
                    for(SObject share : sharesList) {
                        String shareKey = FormulaShareUtilities.getShareRecordKeyStandard(type, share);
                        shareKeySet.add(shareKey);
                        shareIdSet.add(share.Id);
                    }
                }

                // For custom objects, query for all shares and add to sets
                else {
                    String rowCausesString = FormulaShareUtilities.buildStringFromSetQuotes(sharingReasonsSet);
                    FormulaShareSObjectSharesCustomSelector sharesSelector = new FormulaShareSObjectSharesCustomSelector(true, shareObjectType);
                    List<SObject> sharesList = sharesSelector.selectByParentIdsAndRowCauses(parentIdsString, rowCausesString);
                    for(SObject share : sharesList) {
                        String shareKey = FormulaShareUtilities.getShareRecordKeyCustom(share);
                        shareKeySet.add(shareKey);
                        shareIdSet.add(share.Id);
                    }
                }

                // Set statuses based on information returned
                for(FormulaShare_Processed_Share_Event__e pse : pseWithoutStatus) {

                    FormulaShare_Processed_Record_Share__c prs = mapEventToProcessedRecordShare(pse, insertedPrIdsMap, groupsMap);

                    // For insert, check whether share record was found in queried records and set to Success if so
                    if(prs.Operation__c == 'Insert') {
                        if(shareKeySet.contains(pse.Share_Key__c)) {
                            prs.Status__c = 'Success';
                        }
                        else {
                            prs.Status__c = 'Error';
                            prs.Status_Reason__c = 'Share record to be inserted wasn\'t detected in query';
                        }
                    }

                    // For delete, check whether share record was found in queried records and set to Success if not
                    else if(prs.Operation__c == 'Delete') {
                        if(!shareIdSet.contains(pse.Share_Id__c)) {
                            prs.Status__c = 'Success';
                        }
                        else {
                            prs.Status__c = 'Error';
                            prs.Status_Reason__c = 'Share record identified for removal not actually deleted';
                        }
                    }

                    processedRecordShares.add(prs);
                }
            }
        }

        return processedRecordShares;
    }


    // Returns a map of groups corresponding to Shared_to_Id__c values in events list
    private static Map<Id,Group> getGroupsMap(List<FormulaShare_Processed_Share_Event__e> pseList) {

        // Find groups we'll need to query based on Shared_to_Id__c type
        List<Id> groupIdList = new List<Id>();
        for(FormulaShare_Processed_Share_Event__e pse : pseList) {
            Id userOrGroupId = Id.valueOf(pse.Shared_to_Id__c);
            Schema.SObjectType userOrGroupType = userOrGroupId.getSObjectType();
            if(userOrGroupType == Group.SOBjectType) {
                system.debug('group id: '+userOrGroupId);
                groupIdList.add(userOrGroupId);
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
    private static FormulaShare_Processed_Record_Share__c mapEventToProcessedRecordShare(FormulaShare_Processed_Share_Event__e pse, Map<String,Id> insertedPrIdsMap, Map<Id,Group> groupsMap) {
        FormulaShare_Processed_Record_Share__c prs = new FormulaShare_Processed_Record_Share__c();

        // Set lookup to processed record and other common fields
        prs.Processed_Record__c = insertedPrIdsMap.get(pse.Record_Id__c);
        prs.Operation__c = pse.Operation__c;
        prs.Sharing_Reason__c = pse.Sharing_Reason__c;
        prs.FormulaShare_Rule_Name__c = pse.FormulaShare_Rule_Name__c;
        prs.Access_Level__c = pse.Access_Level__c;

        // Check whether user or group share
        Id userOrGroupId = Id.valueOf(pse.Shared_to_Id__c);
        system.debug('userOrGroupId: '+ userOrGroupId);
        Schema.SObjectType userOrGroupType = userOrGroupId.getSObjectType();

        // Set status if provided
        prs.Status__c = pse.Status__c;
        prs.Status_Reason__c = pse.Failed_Status_Reason__c;

        // Populate share with type and relevant fields depending on user or group sharing
        if(userOrGroupType == User.SOBjectType) {
            prs.Shared_to_User__c = userOrGroupId;
            prs.Share_With__c = 'Users';
        }
        else if(userOrGroupType == Group.SOBjectType) {
            Group grp = groupsMap.get(userOrGroupId);
            prs.Shared_to_Role_or_Group__c = grp.DeveloperName;
            prs.Share_With__c = grp.Type;
        }

        return prs;
    }

}