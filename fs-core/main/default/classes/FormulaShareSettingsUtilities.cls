public inherited sharing class FormulaShareSettingsUtilities {

    // Returns the effective batch size for full recalculation batches
    // Precedence: providedBatchSize (if > 0) > Object Override_Batch_Size__c > Org Recalculation_Batch_Size__c
    public static Integer getEffectiveBatchSizeForFullBatch(Schema.SObjectType type) {

        // Resolve org default
        FormulaShare_Settings__mdt orgSettings = FormulaShareSettingsSelector.construct().selectActiveSettings();
        Integer orgDefault = (orgSettings == null || orgSettings.Recalculation_Batch_Size__c == null)
            ? 1
            : orgSettings.Recalculation_Batch_Size__c.intValue();

        // Attempt to resolve object override
        try {
            FormulaShareRemoveSharesSelector objSelector = new FormulaShareRemoveSharesSelector();
            FormulaShare_Std_Object_to_Remove_Shares__mdt objSettings = objSelector.getSettingsForType(type);
            if (objSettings != null
                && objSettings.Override_Batch_Size__c != null
                && objSettings.Override_Batch_Size__c > 0) {
                return objSettings.Override_Batch_Size__c.intValue();
            }
        } catch (Exception e) {
            // Fall back to org default if any error occurs
        }

        return orgDefault;
    }

    // Returns the effective batch size for targeted jobs
    // Precedence: job.Override_Batch_Size > Object Override_Batch_Size__c > Org Recalculation_Batch_Size__c
    public static Integer getEffectiveBatchSizeForTargetedJob(FormulaShareTargetedJob job) {
        // Job-level override takes precedence if valid
        if (job != null && job.Override_Batch_Size != null && job.Override_Batch_Size > 0) {
            return job.Override_Batch_Size;
        }

        Schema.SObjectType type = FormulaShareUtilities.getSObjectTypeFromName(job.Object_QualifiedApiName);

        Integer effectiveBatchSizeForObject = getEffectiveBatchSizeForFullBatch(type);
        return effectiveBatchSizeForObject;
    }
}
