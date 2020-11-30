public with sharing class FormulaShareSObjectUtilities {

    public Schema.SObjectType type;
    public Schema.DescribeSObjectResult typeDescribe;
    public Boolean isCustom;
    public String objectName;
    private Boolean removeSharesForObject;

    public FormulaShareSObjectUtilities(Schema.SObjectType type) {
        this.type = type;
        this.typeDescribe = type.getDescribe();
        this.isCustom = typeDescribe.isCustom();
        this.objectName = typeDescribe.getName();
    }

	public String accessLevelFieldName() {
        if(isCustom) {
            return 'AccessLevel';
        }
        else {
            return objectName + 'AccessLevel';
        }
    }

	public String parentIdFieldName() {
        if(isCustom) {
            return 'ParentId';
        }
        else {
            return objectName + 'Id';
        }
    }

	public String getShareKey(SObject share) {
        String shareKeyBase = getShareKeyBase(share);
        if(isCustom) {
            String rowCause = (String) share.get('RowCause');
            String shareKey = shareKeyBase + rowCause;
            return shareKey;
        }
        else {
            return shareKeyBase;
        }
    }
    
    private String getShareKeyBase(SObject share) {
        System.debug('share base: '+share);
		Id parentId = (Id) share.get(parentIdFieldName());
		Id userOrGroupId = (Id) share.get('UserOrGroupId');
        System.debug('share parentId: '+parentId);
		String parentId15 = FormulaShareUtilities.get15CharacterId(parentId);
        System.debug('share parentId15: '+parentId15);
		String userOrGroupId15 = FormulaShareUtilities.get15CharacterId(userOrGroupId);
        String shareKeyBase = parentId15 + userOrGroupId15;
        return shareKeyBase;
    }

    public Boolean removeSharesForObject() {
        if(removeSharesForObject == null) {

            // Always remove for custom objects as we distinguish by row cause
            removeSharesForObject = true;

            // Otherwise check custom metadata setting for this object
            if(!isCustom) {
                FormulaShareRemoveSharesSelector selector = FormulaShareRemoveSharesSelector.construct();
                List<FormulaShare_Std_Object_to_Remove_Shares__mdt> removalLines = selector.getRemovalLinesForType(type);
                if(removalLines.isEmpty()) {
                    removeSharesForObject = false;
                }
            }
        }
        return removeSharesForObject;
    }
}