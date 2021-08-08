// Sets the namespace to as value provided in the command line
// Called by CI and org build scripts

const fs = require('fs');

const scratchDefFile = 'config/project-scratch-def.json';
const scratchDef = fs.readFileSync(scratchDefFile);
let scratchDefJson = JSON.parse(scratchDef);

// Namespace provided as a command line argument
const namespace = process.argv[2];

// Set or update namespace in JSON if required
if(scratchDefJson["namespace"] != namespace) {
    scratchDefJson["namespace"] = namespace;

    // Update JSON file with updated tag
    const scratchDefJsonString = JSON.stringify(scratchDefJson, null, 4);
    fs.writeFile(scratchDefFile, scratchDefJsonString, 'utf8', function (err) {
        if (err) {
            console.log('Error updating project-scratch-def.json: ' + err);
            process.exit(1);
        }
        console.log('Set namespace in config/project-scratch-def.json');
    });
    
}
