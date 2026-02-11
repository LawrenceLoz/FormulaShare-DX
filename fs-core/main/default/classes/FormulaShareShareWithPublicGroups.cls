/**
 * Handler for sharing to public groups where the group name matches the field value exactly.
 * No prefix is applied - the field value must match the Group.DeveloperName directly.
 */
public inherited sharing class FormulaShareShareWithPublicGroups 
    extends FormulaShareShareWithPrefixedGroups {

    public FormulaShareShareWithPublicGroups(FormulaShareService service) {
        this.service = service;
    }

    protected override String getPrefix() {
        return '';
    }

    protected override String getShareWithLabel() {
        return 'Public Groups';
    }

}