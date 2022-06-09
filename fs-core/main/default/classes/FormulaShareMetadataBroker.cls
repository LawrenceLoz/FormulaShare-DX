public inherited sharing class FormulaShareMetadataBroker {

    public List<Metadata.Metadata> retrieve(List<String> mdRecordNames) {
        return Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, mdRecordNames);
    }

    public Id enqueueDeployment(Metadata.DeployContainer container, Metadata.DeployCallback callback) {
        return Metadata.Operations.enqueueDeployment(container, callback);        
    }
}
