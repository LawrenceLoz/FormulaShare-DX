# FormulaShare, apex sharing for admins

Click-and-configure rules to share records based on related data.

Salesforce provides great in-platform options for sharing records - ownership based, criteria based, manual sharing and apex sharing.
But there's a key feature missing - sharing to users identified through related data.

FormulaShare let's you do that and more without resorting to complex development!

* Records are shared to a user, role or group specified in a formula or lookup field
* Sharing changes are assessed in real time as shared records are created and modified
* Records can be shared with Read or Edit levels of access
* Rules are custom metadata, so can be managed by admins and packaged for deployment
* Standard and custom objects are supported
* Works with Classic and Lightning
* Powered by Salesforce apex / managed sharing

(note this repo is in DX metadata format)

## Example applications

* In a recruitment system, share job records and applications to the relevant hiring manager user and recruitment team
* Share cases to account executive teams, but only when these are not flagged as containing sensitive data
* In a global org, share records to the relevant roles specified on a linked custom country object with a single rule
* Share records to all users with the same role as the record owner
* Conditionally share records based on the value in a lookup or formula field (field types not available in standard sharing rules)
* Provide a field on a record for users to share ad hoc to colleagues

## How does it work?

By leveraging standard formula fields, FormulaShare lets admins quickly specify how records should be shared using a familiar feature. Complex relationships and conditions can be set where needed. Rules in custom metadata point FormulaShare to the relevant fields and objects.

Suppose custom objects A (representing a country, for example) and B (for instance a job opportunity for that country) are related through a lookup. If we want the to make sure users linked to object A should have access to related records in object B, that's not possible with out of the box Salesforce functionality.

With FormulaShare, we can set a rule to reference a formula field on object B which specifies who the record should be shared with. The field could be a formula populating with a user, role or a group which is indicated on object A.

We can even reference parents or grandparent objects of object A - up to 5 levels are supported.

Once established, the rule will recalculate relevant sharing in real time when object B records are created or changed, and catch up on any other changes with scheduled batch jobs.

## Design approach

Real time sharing calculation if needed is kicked off from apex triggers, but only one line of code needs to the trigger or handler class needs to be added to make sure this happens. Processing is delegated to a queueable apex method to preserve performance and governer limits - no additional synchronous SOQL is called within the trigger transaction.

Apex sharing is notoriously difficult to implement well - FormulaShare processes the core scenarios where real time recalculation is needed (for example creation of records and changes to formula field values), and handles all other changes which in a catch-up batch job (this includes changes to parent objects referenced in the formula field).

## Technical configuration

Once code from the repo is implemented, two key steps are needed to set up FormulaShare:

* **Call FormulaShareService from shared object triggers** One line of code is needed to call FormulaShare. Add this line to any triggers or any handler code called by your triggers: `FormulaShareService.triggerHandler();` This calls a method to assesses whether changes are needed for created or modified records when the trigger is called. If you use a trigger framework with a central delegating handler, the line can be added in this class instead of each object's trigger.

* **Schedule batch recalculation of FormulaShare rules** [Schedule the apex class](https://help.salesforce.com/articleView?id=code_schedule_batch_apex.htm&type=5) FormulaShareProcessSchedulable to recalculate all rules on a regular basis

## Setting up a FormulaShare rule

The following steps can be carried out by an admin when a new sharing requirement is identified:

### Create sharing field
A custom field is needed on the object which should be shared. For rules sharing with users, the field should contain the Id of the user who should be granted access to the record (either 15 or 18 character versions are fine). For rules sharing with groups, the field should contain the name (developer name) of the public group which should be given access. For rules sharing with roles or roles and subordinates, either the Id or name of the role can be used. The field could be a formula returning text with the Id or name, but could alternatively be a lookup field or a text field populated through automation.

### Create sharing reason (custom objects only)
FormulaShare creates entries in the object's share table with a sharing reason, which ensures FormulaShare can keep track of everything shared by a rule and remove sharing which isn't required. Set up a sharing reason (Classic interface only) from the custom object's setup page in the section "Apex Sharing Reasons". Note that if using the Lightning interface, sharing reasons can be set up by temporarily switching to Salesforce Classic.

For standard objects, sharing reasons aren't available. As an alternative, FormulaShare provides options to process rules either as additive (so object sharing is not removed if data conditions change), or fully managed (meaning FormulaShare assumes all records in the object's share table are provided by the configured rule and removes sharing which doesn't meet the criteria of the rule).

### Create FormulaShare rule record
From the Setup menu, type "Custom Metadata Types" and click "Manage Records" for FormulaShare Rule. Each of the custom metadata records are the settings for a single rule. The following fields define the setup of each rule:
* **Name** and **Label**: Add something to distinguish this rule from others
* **Shared Object**: The API name (including "__c") of the object with records to be shared. Object must be set to Private (for Read or Edit access levels) or Public Read Only (for Edit access level), and must support sharing - child objects in a master-detail relationship and some standard objects do not support independent sharing rules
* **Shared To Field**: The API name (including "__c") of the field on the object above which identifies who to share records with. The field can return either the Salesforce 15 or 18 character Id of the entity to be shared to, or the role or group name (developer name) when the rule provides this sharing
* **Shared_To_Field_Type__c**: Either "Id" or "Name", depending on return type of the Shared To Field
* **Share With**: The type of entity this rule should share with. Options are "Users", "Roles", "Roles and Internal Subordinates" and "Public Groups"
* **Sharing Reason**: For custom objects, the "Reason Name" of the sharing reason related to the rule
* **Access Level**: Set to Read or Edit

### Test configuration

Create a record in the shared object. As a system admin, the easiest way to check that the sharing is set up is to use the "Sharing" button from the record detail page (Classic interface only). The summary should include a share record for the user, role, role and subordinates or public group which is linked through the shared to field.

## Areas for future development

The project is currently in beta. Code provided should work but no promises! The following is a list of areas which will be worked on in due course:
* Apex unit tests for all code
* Automated deployment of triggers and sharing reasons using metadata API (a la the wonderful [DeclareativeLookupRollupSummary](https://github.com/afawcett/declarative-lookup-rollup-summaries))
* Full adoption of the Enterprise Apex Pattern design approach (abstracting of selector layer)
* Packaging and publication on AppExchange
* Managed scheduling of batch job and configuration parameters in managed package setup
* Lightning interface for metadata rule configuration
* Improved error handling and validation
* Ability to process standard object sharing as either additive or fully managed
* Support for account teams and territory groups
* Support for assessing user roles directly without a formula field being needed

## Ethos

FormulaShare is developed as a community project and is free to use and distribute. Contributions, collaborations, feedback and suggestions are welcome.
