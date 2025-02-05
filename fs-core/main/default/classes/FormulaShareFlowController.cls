public with sharing class FormulaShareFlowController {

    @AuraEnabled(cacheable=true)
    public static String getFlowVersionId(String flowApiName) {
        String namespace = FormulaShareUtilities.getNamespaceNoUnderscores();
        try {
            // Query the latest active version of the flow
            List<FlowVersionView> flowVersionList = [
                SELECT DurableId
                FROM FlowVersionView
                WHERE FlowDefinitionView.ApiName = :flowApiName
                AND FlowDefinitionView.NamespacePrefix = :namespace
                WITH USER_MODE
                ORDER BY VersionNumber DESC 
                LIMIT 1
            ];
            
            if (!flowVersionList.isEmpty()) {
                return flowVersionList[0].DurableId;
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving flow: ' + e.getMessage());
        }
    }
}