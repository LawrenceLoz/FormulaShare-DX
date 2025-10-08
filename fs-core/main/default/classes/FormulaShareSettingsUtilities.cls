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
            FormulaShareRemoveSharesSelector objSelector = new FormulaShareInjectionService().getRemoveSharesSelector();
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

}