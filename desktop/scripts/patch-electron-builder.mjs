import { readFileSync, writeFileSync } from "node:fs";

// Remove once electron-builder ships https://github.com/electron-userland/electron-builder/pull/10172.
const { version } = JSON.parse(
    readFileSync("node_modules/app-builder-lib/package.json", "utf8"),
);
if (version !== "26.15.3")
    throw new Error(
        `app-builder-lib ${version}: review or remove the keychain patch`,
    );

const file = "node_modules/app-builder-lib/out/codeSign/macCodeSign.js";
let source = readFileSync(file, "utf8");

const replacements = [
    [
        "importCerts(keychainFile, certPaths, cscPasswords)",
        "importCerts(keychainFile, certPaths, cscPasswords, keychainPassword)",
    ],
    [
        "async function importCerts(keychainFile, paths, keyPasswords)",
        "async function importCerts(keychainFile, paths, keyPasswords, keychainPassword)",
    ],
    [
        '"-s", "-k", password, keychainFile',
        '"-s", "-k", keychainPassword, keychainFile',
    ],
];

for (const [before, after] of replacements) {
    if (source.includes(after)) continue;
    if (!source.includes(before))
        throw new Error(
            "electron-builder signing code changed; review the keychain patch",
        );
    source = source.replace(before, after);
}

writeFileSync(file, source);
