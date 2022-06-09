public inherited sharing class FormulaShareCMDTRetriever {

    public List<Metadata.Metadata> retrieve(List<String> mdRecordNames) {
        return Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, mdRecordNames);
    }
}
