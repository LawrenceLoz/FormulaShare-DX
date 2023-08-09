# FormulaShare, apex sharing for admins

![build status](https://github.com/LawrenceLoz/FormulaShare-DX/actions/workflows/validate-branch-deployable.yml/badge.svg)

This repository contains the sharing framework for the [open-core](https://en.wikipedia.org/wiki/Open-core_model) project FormulaShare. FormulaShare is offered as an [app on the Salesforce AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1), which embeds code from this repository and extends with features and capabilities to enable a dynamic and responsive sharing model for orgs of all scales.

The framework is provided as open source so that organisations using the app can understand the design approach and be confident the app is built in a secure and performant way. We also welcome contributions from our community of users or others who would like to collaborate and improve the framework. The code can also be used in part or in its entirety to support other projects.

## What problem are we solving?

Salesforce provides great in-platform config options to share records, but none of these effectively address the common use case of needing to control access based on a record's relationship to other records - sharing Cases, Opportunities or Custom Objects according to an associated Account, Country, Office or Team record for example. FormulaShare provides click-and-configure rules to do exactly this, letting you use fields from the controlling objects and values of formula fields to determine sharing.

## How does it work?

The framework in this repository allows:

* Records to be shared to a user, role or group specified in a formula, lookup or text field on the shared object
* A regular batch to be scheduled to apply sharing changes
* Dynamic sharing to be implemented for standard and custom objects

The [AppExchange app](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1) embeds this framework and provides features to enable:
* Real time sharing on creation and update of records
* Sharing to users, roles and groups on records related by a series of lookups (parent or child) to the shared object
* Sharing to other entity types such as Manager Groups and Account or Opportunity Default Teams
* Targeted Assessment Jobs to apply changes for a subset of records for more frequent and performant batch jobs
* Control over each object's recursion strategy
* A full Lightning setup interface
* Reduced performance overhead. The security-reviewed package provides FormulaShare with separate governor limits for DML statements, SOQL query rows and other transaction resources, minimising risk of limits being exceeded

Behind the scenes, FormulaShare creates and removes [apex managed sharing](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_bulk_sharing_creating_with_apex.htm) to match access to the conditions specified in rules.

## Example applications

* In a recruitment system, share job records and applications to the relevant hiring manager user
* In a global org, share records to the relevant roles specified on a linked custom country object
* Share cases to account executive teams, but only when these are not flagged as containing sensitive data
* Share records to all users with the same role as the record owner
* Conditionally share records based on the value in a lookup or formula field (field types not available in standard sharing rules)

## Design approach

Apex managed sharing is very difficult to implement well - by using a batch job to efficiently reassess all records on a schedule FormulaShare ensures that sharing is up to date after each batch run, regardless of the nature of changes in the shared record or related records involved in sharing.

Creating a rule in the app is just a few clicks, and is as simple as creating a Salesforce sharing rule. Rules are stored as custom metadata, so are copied to sandboxes and can be deployed through change sets or other means. The app also allows for capturing, retaining and removing logs for monitoring and reporting.

## Installing to your org

The recommended way to deploy FormulaShare is to install the security reviewed [AppExchange package](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1). The app has a full Lightning setup interface, and additional features to apply sharing in real time, share to other types of entities such as Manager Groups and Default Account or Opportunity Teams, create targeted calculation jobs for more frequent batch assessment and much more. The package also ensures you benefit from increased and separate transaction limits, automatic package upgrades and technical support. The framework can also be used by developers directly in their projects - for information on deployment, see the section [Deploying to an Org](#deploying-to-an-org).

## Getting started

The basics of how to get up and running once FormulaShare is installed are below. For more details on post-installation setup [check the guide](https://cloudsundial.com/node/40).

* **Assign permissions** Assign the permission set FormulaShare Admin to anyone who will be creating or managing rules
* **Schedule batch recalculation of FormulaShare rules** [Schedule the apex class](https://help.salesforce.com/articleView?id=code_schedule_batch_apex.htm&type=5) FormulaShareProcessSchedulable to recalculate all rules on a regular basis

## Setting up a FormulaShare rule

### Create sharing field
A custom field is needed on the object to be shared which indicates who should get access.

* For rules sharing with users, the field should contain the ID of the user who should be granted access to the record (either 15 or 18 character versions are fine).
* For rules sharing with groups, the field should contain the name (developer name) of the public group which should be given access.
* For rules sharing with roles or roles and subordinates, either the ID or name of the role can be used.

The field type can be either a formula returning text with the ID or name, a lookup field (which is treated as an ID), or a text field populated through automation.

Formula fields can be used to reference records from parent, grandparent or ancestor objects up to 5 levels. In the AppExchange app, it's also possible to select fields from objects which are related to the shared object through a series of parent or child lookup relationships, so sharing can be based on related records elsewhere in the schema.

### Create sharing reason (custom objects only)
FormulaShare creates entries in the object's share table with a sharing reason, which ensures it can keep track of sharing applied by each rule and remove sharing which is no longer needed. Set up a sharing reason (Classic interface only) from the custom object's setup page in the section "Apex Sharing Reasons". If your org uses Lightning, sharing reasons can be set up by temporarily switching to Salesforce Classic.

For standard objects, sharing reasons aren't available. As an alternative, FormulaShare provides options to process rules either as additive (so object sharing is not removed if data conditions change), or fully managed (meaning FormulaShare assumes all records in the object's share table are provided by the configured rule and removes sharing which doesn't meet the criteria of the rule).

### Create FormulaShare rule record
Rules are set up from the FormulaShare Rules tab of the FormulaShare app.

![Creating a rule](img/CreateRule.gif)

For full details around what can be set here, check the [online guide](https://cloudsundial.com/formulashare-creating-a-rule).

### Test it works!

Create a record in the shared object, and recalculate sharing from the FormulaShare Rules tab.

As a system admin, the easiest way to check that the sharing is applied is to use the "Sharing" button from the record page. The summary should show that the record is shared to the user, role, role and subordinates or public group which is linked through the shared to field.

### Logs and monitoring

[Logging objects](https://cloudsundial.com/formulashare-monitoring) are used to capture information relevant to successful processing and any errors or warnings, and the summary of logs is represented on the FormulaShare Dashboard tab of the Lightning app. The data structure used for logs is below:

![Logging and metrics objects](img/LogsERD.png)

Logs are removed based on a retention schedule, which by default is 8 days for Record Logs and 365 days for Batch Logs. These parameters can be changed, or logging disabled, using a [FormulaShare Settings override](https://cloudsundial.com/formulashare-settings-overrides).

### Limitations

Known limitations are outlined in the guide: https://cloudsundial.com/formulashare-limits-and-limitations

## Deploying to an org

There are a few ways to deploy depending on how you're planning to use or contribute:

### Install from the AppExchange
_Best for_: Using the package as it's designed
 - Install to a sandbox or production from the [AppEchange listing](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FR5TCUA1)
 - Complete post-installation steps described in [Technical configuration](#technical-configuration)

This is the simplest and most convenient way to introduce FormulaShare for your organisation. The package can be installed in a few clicks and is kept up to date through an automated release process. Since the app has been security reviewed, it's given its own set of limits and won't contribute to most limits in your org.

### Deploy to a scratch org without using the namespace
_Best for_: Working independently on contributions or custom versions using a scratch org workflow
 - Clone or fork the repo
 - Run the [shell script](buildScratchOrg.sh) (Mac) or [batch script](buildScratchOrg.bat) (Windows). This creates a scratch org, deploys everything, assigns permission sets to the default user, creates test data and schedules the batch

This workflow enables development using scratch orgs and a version which doesn't reference the namespace of the FormulaShare managed package. FormulaShare is designed to work correctly whether the namespace is in place or not, and this approach is probably best if you're adapting FormulaShare for use in your own organisation or app, or if you want to contribute changes to the project.

### Deploy to a scratch org configured to use the FormulaShare package namespace
_Best for_: Working on complex changes to the core project which will become part of the managed package. Note that to support this workflow, temporary admin access to your dev hub will be required by the owner of the FormulaShare packaging org
 - Clone or fork the repo
 - Create an issue with title "Namespace Access Request: Username" to request authorisation to work with the namespace (further instructions will be sent in response to the issue)
 - Once authorisation and other configuration is complete, the batch/shell script can be used as described above

This process enables development using a dev hub and scratch orgs which can simulate the package namespace, and gives the most accurate development representation of the packaging org. This is ideal when changes involve complex dynamic metadata references and should therefore be tested with the namespace in place to ensure they work correctly.

## Ethos

FormulaShare-DX is the open source element of the FormulaShare open-core project. Review, contributions, collaborations and feedback relating to the framework managed in this repository are welcome. Feel free to raise issues for enhancements or fixes, and fork the repo and submit a pull request if you'd like to contribute your own work to the project.