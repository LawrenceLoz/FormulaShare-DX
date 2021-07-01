// Script is required because Sharing_Reason__c must include the package namespace of any sharing rules
// Rules from the sample app are deployed with in the FormulaShare namespace if the scratch org
// namespace is used, so script converts sample metadata to include namespace if it's present in 
// the project-scratch-def.json

const fs = require('fs');

const scratchDefFile = 'config/project-scratch-def.json';
const sampleMetaDir = 'fs-sample-app/main/default/customMetadata';   // Convert metadata in sample app namespace

const scratchDef = fs.readFileSync(scratchDefFile);
const scratchDefJson = JSON.parse(scratchDef);

let namespace = scratchDefJson["namespace"];
if(namespace) {
    fs.readdir(sampleMetaDir, function (err, files) {
        if (err) {
            console.error("Error in script: Could not list the directory "+err);
            process.exit(1);
        }
        const xml2js = require('xml2js');

        // Cycle through custom metadata files in sample app
        files.forEach(function (file) {

            // For metadata which represents a rule
            if(file.startsWith("FormulaShare_Rule")) {

                // Get file contents
                const fileLocation = sampleMetaDir + '/' + file;
                const ruleMeta = fs.readFileSync(fileLocation);

                // Convert XML to JSON
                xml2js.parseString(ruleMeta, (err, result) => {
                    let fileUpdateRequired = false;

                    // Iterate over values array (each item contains field & value tags)
                    let values = result["CustomMetadata"]["values"];
                    values.forEach(function(item) {

                        // For items corresponding to a Sharing_Reason__c field
                        if(item["field"] == "Sharing_Reason__c") {

                            // If value tag has an atribute of string (implies not nil)
                            // And namespace not already included in value
                            if(item["value"][0].$["xsi:type"] == "xsd:string"
                                && !item["value"][0]._.startsWith(namespace + "__")) {

                                // Update value tag contents with namespace prefix
                                item["value"][0]._ = namespace + "__" + item["value"][0]._;
                                fileUpdateRequired = true;
                            }
                        }
                    });

                    if(fileUpdateRequired) {

                        // Convert JSON back to XML
                        const builder = new xml2js.Builder();
                        const newRuleMetaXML = builder.buildObject(result);

                        // Update original file
                        fs.writeFile(fileLocation, newRuleMetaXML, 'utf8', function (err) {
                            if (err) {
                                console.log('Error updating custom metadata record: ' + err);
                                process.exit(1);
                            }
                            console.log('Appended namespace to custom metadata '+file);
                        });
                    }
                });
            }
        });
    });
}
