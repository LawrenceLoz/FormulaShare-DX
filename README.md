# FormulaShare, apex sharing for admins

![build status](https://github.com/LawrenceLoz/FormulaShare-DX/actions/workflows/validate-branch-deployable.yml/badge.svg)

Click-and-configure rules to share records based on parent records and formula field contents. Salesforce provides great in-platform config options to share records, but none of these effectively address these common use cases.

FormulaShare lets you do this and more without resorting to complex development.

FormulaShare is published on the AppExchange as a free managed package https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1. Using the package version means separate governor limits are allocated, minimising the risk of your org's limits being exceeded.

## Deprecation notice - Related object sharing
Please be aware that related object sharing, the functionality to share by selecting fields based on objects other than the shared object, will be removed from the main branch of this repo by approximately early July 2022.

Further details on what this might mean for your org are outlined in the related issue: https://github.com/LawrenceLoz/FormulaShare-DX/issues/84

## How does it work?

* Records are shared to a user, role or group specified in a formula, lookup or text field
* Information from a parent object can be used to determine sharing access by using a formula field
* Sharing assessment can be carried out in real time by calling FormulaShare from trigger handlers
* A regular batch applies any updates to sharing changes not initiated by triggers
* Standard and custom objects are supported

By leveraging standard formula fields, FormulaShare lets admins and app builders quickly specify how records should be shared using a familiar feature, and complex relationships and conditions can be set where needed. Behind the scenes, FormulaShare creates and removes [apex managed sharing](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_bulk_sharing_creating_with_apex.htm) to match access to the conditions specified in rules.

The FormulaShare app is the control and monitoring centre for your org:

* Creating a rule in the app takes just a few clicks, and as simple as creating a standard Salesforce sharing rule
* Rules are stored as custom metadata, so are copied to sandboxes and can be deployed through change sets or other means
* Log records are created for monitoring and reporting, and removed in line with customisable retention periods

## Example applications

* In a recruitment system, share job records and applications to the relevant hiring manager user
* In a global org, share records to the relevant roles specified on a linked custom country object
* Share cases to account executive teams, but only when these are not flagged as containing sensitive data
* Share records to all users with the same role as the record owner
* Conditionally share records based on the value in a lookup or formula field (field types not available in standard sharing rules)

## Design approach

Apex managed sharing is notoriously difficult to implement well - FormulaShare covers core scenarios where real time recalculation might be needed (for example creation of records and changes to formula field values), and handles all other scenarios (e.g. changes to parent objects referenced in a formula field) in a catch-up batch job.

Real time assessment of sharing if needed is called from apex triggers - just 3 lines of code need to be added to a trigger or handler class.

## Installing to your org

The recommended way to deploy FormulaShare is to install the security reviewed [AppExchange package](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1). This ensures you can benefit from increased and separate transaction limits, automatic package upgrades, extra features and technical support. For information on deploying without the package, see the section [Deploying to an Org](#deploying-to-an-org).

## Getting started

The basics of how to get up and running once FormulaShare is installed are below. For more details on post-installation setup [check the guide](https://cloudsundial.com/node/40).

* **Assign permissions** Assign the permission set FormulaShare Admin to anyone who will be creating or managing rules
* **Schedule batch recalculation of FormulaShare rules** [Schedule the apex class](https://help.salesforce.com/articleView?id=code_schedule_batch_apex.htm&type=5) FormulaShareProcessSchedulable to recalculate all rules on a regular basis
* _Optional_ **Call FormulaShareService from shared object triggers** The following code can be added to any trigger or trigger handler code called during the after insert, update, delete and undelete invocations of a trigger to manage sharing changes for this object:
```
sdfs.FormulaShareHelper helper = new sdfs.FormulaShareHelper();
insert helper.getSharesToInsert();
delete helper.getSharesToDelete();
```
Note that if you've deployed metadata from this repo directly rather than by installing the managed package, the package namespace should be removed from the first line:
```
FormulaShareHelper helper = new FormulaShareHelper();
```

If you have a trigger framework with centralised handler logic, FormulaShare can be called using the same code in a central shared class instead of individually for each object.

If there are no rules sharing an object and a trigger for this object calls FormulaShare, the app will cease processing after a single (efficient) metadata query checking for rules so performance overhead is minimal.

## Setting up a FormulaShare rule

### Create sharing field
A custom field is needed on the object to be shared which indicates who should get access.

* For rules sharing with users, the field should contain the ID of the user who should be granted access to the record (either 15 or 18 character versions are fine).
* For rules sharing with groups, the field should contain the name (developer name) of the public group which should be given access.
* For rules sharing with roles or roles and subordinates, either the ID or name of the role can be used.

The field type can be either a formula returning text with the ID or name, a lookup field (which is treated as an ID), or a text field populated through automation.

To share based on a parent record, first create a text or lookup field on the parent object to hold the ID or name. Next create a field on the object to be shared which populates with this value - this will be the field we use in the FormulaShare rule.

Formula fields allow for referencing records from parent, grandparent or anscestor objects up to 5 levels.


### Create sharing reason (custom objects only)
FormulaShare creates entries in the object's share table with a sharing reason, which ensures FormulaShare can keep track of everything shared by a rule and remove sharing which isn't required. Set up a sharing reason (Classic interface only) from the custom object's setup page in the section "Apex Sharing Reasons". If your org uses Lightning, sharing reasons can be set up by temporarily switching to Salesforce Classic.

For standard objects, sharing reasons aren't available. As an alternative, FormulaShare provides options to process rules either as additive (so object sharing is not removed if data conditions change), or fully managed (meaning FormulaShare assumes all records in the object's share table are provided by the configured rule and removes sharing which doesn't meet the criteria of the rule).

### Create FormulaShare rule record
Rules are set up from the FormulaShare Rules tab of the FormulaShare app.

![Creating a rule](img/CreateRule.gif)

For full details around what can be set here, check the [online guide](https://cloudsundial.com/formulashare-creating-a-rule).

### Test it works!

Create a record in the shared object - if you have a trigger in place this should apply sharing right away, otherwise recalculate sharing for the object from the FormulaShare Rules tab.

As a system admin, the easiest way to check that the sharing is applied is to use the "Sharing" button from the record page. The summary should show that the record is shared to the user, role, role and subordinates or public group which is linked through the shared to field.

### Logs and monitoring

[Logging objects](https://cloudsundial.com/formulashare-monitoring) are used to capture information relevant to successful processing and any errors or warnings, and the summary of logs is represented on the FormulaShare Dashboard tab of the Lightning app. The data structure used for logs is below:

![Logging and metrics objects](img/LogsERD.png)

Logs are removed based on a retention schedule, which by default is 8 days for Record Logs and 365 days for Batch Logs. These parameters can be changed, or logging disabled, using a [FormulaShare Settings override](https://cloudsundial.com/formulashare-settings-overrides).

### Limitations

Known limitations are outlined in the guide: https://cloudsundial.com/formulashare-limits-and-limitations

## Deploying to an org

There are a few ways to deploy FormulaShare depending on how you're planning to use, adapt or contribute:

### Install from the AppExchange
_Best for_: Using the package as it's designed
 - Install to a sandbox or production from the [AppEchange listing](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1)
 - Complete post-installation steps described in [Technical configuration](#technical-configuration)

This is the simplest and most convenient way to introduce FormulaShare for your organisation. The package can be installed in a few clicks and is kept up to date through an automated release process. Since the app has been security reviewed, it's given its own set of limits and won't contribute to most limits in your org.

### Deploy directly to a sandbox or production
_Best for_: Getting source code into your own environment using traditional development methodologies
 - Clone or fork the repo, and use VS Code, Salesforce DX command line or another tool to deploy the source files to your org
 - Complete post-installation steps described in [Technical configuration](#technical-configuration)
 - Optionally, call execute FSSampleAppDataGenerationService.run(_noTestDonations_) to generate a set of test data in the sample app

This is the simplest way of getting source files into an org with your configuration and the ability to view and edit components. If you'd like to contribute enhancements or fixes, just fork the repo, deploy, retrieve your changes, create an issue in GitHub and submit a PR.

### Deploy to a scratch org without using the namespace
_Best for_: Working independently on contributions or custom versions using a scratch org workflow
 - Clone or fork the repo
 - Run the [shell script](buildScratchOrg.sh) (Mac) or [batch script](buildScratchOrg.bat) (Windows). This creates a scratch org, deploys everything, assigns permission sets to the default user, creates test data and schedules the batch

This workflow enables development using scratch orgs and a version which doesn't reference the namespace of the FormulaShare managed package. FormulaShare is designed to work correctly whether the namespace is in place or not, and this approach is probably best if you're adapting FormulaShare for use in your own organisation or app and work with scratch orgs, or if you have ideas or enhancements to contribute to the project which don't impact dynamic metadata references.

### Deploy to a scratch org configured to use the FormulaShare package namespace
_Best for_: Working on complex changes to the core project which will become part of the managed package. Note that to support this workflow, temporary admin access to your dev hub will be required by the owner of the FormulaShare packaging org
 - Clone or fork the repo
 - Create an issue with title "Namespace Access Request: Username" to request authorisation to work with the namespace (further instructions will be sent in response to the issue)
 - Once authorisation and other configuration is complete, the batch/shell script can be used as described above

This process enables development using a dev hub and scratch orgs which can simulate the package namespace, and gives the most accurate development representation of the packaging org. This is ideal when changes involve complex dynamic metadata references and should therefore be tested with the namespace in place to ensure they work correctly.

## Ethos

FormulaShare is a community project and is free to use and distribute. Contributions, collaborations, feedback and suggestions are welcome. Feel free to raise issues for enhancements or fixes, and fork the repo and submit a pull request if you'd like to contribute your own work to the project.