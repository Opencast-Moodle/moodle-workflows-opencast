const core = require('@actions/core');

try {
    let {
        "main-db": mainDb,
        "main-php": mainPhp,
        "main-moodle": mainMoodle,
        "main-oc": mainOc,
        "moodle-php": moodlePhp,
        "dbs": dbs,
        "ocs": ocs,
        "moodle-plugin-ci": moodlePluginCi
    } = JSON.parse(core.getInput('input'));

    mainDb ??= "pgsql";
    dbs ??= ["pgsql", "mariadb", "mysqli"];

    core.setOutput("moodle_plugin_ci", moodlePluginCi);

    core.setOutput("static_matrix", JSON.stringify({
        include: [{
            "php": mainPhp,
            "moodle-branch": mainMoodle,
            "database": mainDb
        }]
    }));

    const testmatrix = [];

    for (const [moodle, phps] of Object.entries(moodlePhp)) {
        for (const php of phps) {
            testmatrix.push({
                "php": php,
                "moodle-branch": moodle,
                "database": mainDb,
                "opencast": mainOc,
            })
        }
    }

    for (const db of dbs) {
        if (db === mainDb)
            continue;
        testmatrix.push({
            "php": mainPhp,
            "moodle-branch": mainMoodle,
            "database": db,
            "opencast": mainOc
        })
    }

    for (const oc of ocs) {
        if (oc === mainOc)
            continue;
        testmatrix.push({
            "php": mainPhp,
            "moodle-branch": mainMoodle,
            "database": mainDb,
            "opencast": oc
        });
    }

    core.setOutput("test_matrix", JSON.stringify({
        include: testmatrix
    }));

} catch (error) {
    core.setFailed(error.message);
}
