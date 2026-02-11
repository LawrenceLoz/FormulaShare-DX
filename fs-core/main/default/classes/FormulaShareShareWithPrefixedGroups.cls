/**
 * Abstract base class for sharing to public groups based on prefix + field value pattern.
 * Subclasses implement getPrefix() and getShareWithLabel() to define their specific behavior.
 * 
 * This class provides common logic for:
 * - Querying groups by DeveloperName matching prefix + field value
 * - Handling mismatch behaviors (Log Error, Share With Default, Do Not Share)
 * - Efficient bulk processing by collecting names and querying once
 */
public abstract inherited sharing class FormulaShareShareWithPrefixedGroups 
    extends FormulaShareShareWithBase {

    protected Set<String> groupNames = new Set<String>();

    /**
     * Returns the prefix to prepend to field values when constructing group names.
     * Example: 'FSUSR_' for user groups, 'FSTEAM_' for team groups
     */
    protected abstract String getPrefix();

    /**
     * Returns the label shown in UI for this sharing type.
     * This is used to identify which rules this handler should process.
     */
    protected abstract String getShareWithLabel();

    public override Schema.SObjectType getSharedToType() {
        return Schema.Group.getSObjectType();
    }

    public override void checkAndAdd(String sharedToString, 
        FormulaShareService.RecordRule recRule) {
        
        if (recRule.rule.shareWith == getShareWithLabel()) {

            if (recRule.rule.controllingObjectSharedToFieldType == 'Id') {
                // ID-based sharing - validate and share immediately
                if (FormulaShareIdUtilities.construct().isValidIdType(
                    sharedToString, sharedToType)) {
                    
                    service.updateShareMaps(recRule.recordToShare.Id, 
                        (Id) sharedToString, recRule.rule.accessLevel, recRule.rule);
                } else {
                    handleIdMismatch(sharedToString, recRule);
                }
            } else if (recRule.rule.controllingObjectSharedToFieldType == 'Name') {
                // Name-based sharing - collect names for bulk query
                String fullDevName = getFullDeveloperName(sharedToString, recRule);
                groupNames.add(fullDevName);
                recordRules.add(recRule);
                addShareToFallbackNameToCollection(groupNames, recRule);
            }
        }
    }

    public override void assess() {
        if (recordRules.isEmpty()) {
            return;
        }

        Map<String, Id> groupsMap = getGroupsFromNames(groupNames);

        for (FormulaShareService.RecordRule recRule : recordRules) {

            String sharedToName = (String) recRule.sharedToString;
            String fullDevName = getFullDeveloperName(sharedToName, recRule);
            Id groupId = groupsMap.get(fullDevName);

            if (groupId != null) {
                service.updateShareMaps(recRule.recordToShare.Id, groupId, 
                    recRule.rule.accessLevel, recRule.rule);
            } else {
                handleNameMismatch(sharedToName, fullDevName, recRule, groupsMap);
            }
        }
    }

    /**
     * Constructs the full developer name for the group. 
     * Default implementation just prepends prefix, but subclasses can override 
     * for more complex naming (e.g. including field name).
     */
    protected virtual String getFullDeveloperName(String sharedToString, FormulaShareService.RecordRule recRule) {
        return getPrefix() + sharedToString;
    }

    /**
     * Handles cases where an ID value doesn't match a valid group
     */
    private void handleIdMismatch(String sharedToString, 
        FormulaShareService.RecordRule recRule) {
        
        if (recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
            
            if (FormulaShareIdUtilities.construct().isValidIdType(
                recRule.rule.fallbackShareToFieldMismatch, sharedToType)) {
                
                service.updateShareMaps(recRule.recordToShare.Id, 
                    (Id) recRule.rule.fallbackShareToFieldMismatch, 
                    recRule.rule.accessLevel, recRule.rule);
            } else {
                String logMessage = 'Expected default provided in rule to ' + 
                    'contain valid group id. Instead found: ' + 
                    recRule.rule.fallbackShareToFieldMismatch;
                service.captureEntityNotFound(recRule, logMessage);
            }
        } else if (recRule.rule.behaviourShareToFieldMismatch == 'Log Error') {
            String logMessage = 'Expected field to contain valid group id. ' + 
                'Instead found: ' + sharedToString;
            service.captureEntityNotFound(recRule, logMessage);
        }
    }

    /**
     * Handles cases where a name value doesn't match a valid group
     */
    private void handleNameMismatch(String sharedToName, String prefixedName, 
        FormulaShareService.RecordRule recRule, Map<String, Id> groupsMap) {
        
        if (recRule.rule.behaviourShareToFieldMismatch == 'Share With Default') {
            String fallbackPrefixedName = getPrefix() + 
                recRule.rule.fallbackShareToFieldMismatch;
            Id fallbackGroupId = groupsMap.get(fallbackPrefixedName);
            
            if (fallbackGroupId != null) {
                service.updateShareMaps(recRule.recordToShare.Id, fallbackGroupId, 
                    recRule.rule.accessLevel, recRule.rule);
            } else {
                String logMessage = 'Rule default \'' + 
                    recRule.rule.fallbackShareToFieldMismatch + 
                    '\' should correspond to an active public group with name \'' + 
                    fallbackPrefixedName + 
                    '\', but no group was found with this name';
                service.captureEntityNotFound(recRule, logMessage);
            }
        } else if (recRule.rule.behaviourShareToFieldMismatch == 'Log Error') {
            String logMessage = 'Field value \'' + sharedToName + 
                '\' should correspond to an active public group with name \'' + 
                prefixedName + '\', but no group was found with this name';
            service.captureEntityNotFound(recRule, logMessage);
        }
    }

    /**
     * Queries for groups matching the collected names
     */
    private static Map<String, Id> getGroupsFromNames(Set<String> groupNames) {
        Map<String, Id> groups = new Map<String, Id>();

        for (Group grp : [
            SELECT Id, DeveloperName FROM Group 
            WHERE DeveloperName IN :groupNames
            AND (Type = 'Regular' OR Type = 'Queue' OR Type = 'Organization')
            WITH SECURITY_ENFORCED]) {
            
            groups.put(grp.DeveloperName, grp.Id);
        }
        return groups;
    }
}
