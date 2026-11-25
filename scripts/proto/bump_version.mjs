import fs from "node:fs";

const FROM = "0.1.2";
const TO = "0.1.3";
const mods = [
  "moon.mod",
  "image.core/moon.mod",
  "image.codec/moon.mod",
  "image.process/moon.mod",
  "image.photography/moon.mod",
  "image.vision/moon.mod",
  "image.domain/moon.mod",
];
for (const f of mods) {
  let t = fs.readFileSync(f, "utf8");
  t = t.replace(new RegExp(`^version = "${FROM}"`, "m"), `version = "${TO}"`);
  fs.writeFileSync(f, t, "utf8");
}

let facade = fs.readFileSync("image.mbt", "utf8");
facade = facade.replace(`pub let version : String = "${FROM}"`, `pub let version : String = "${TO}"`);
fs.writeFileSync("image.mbt", facade, "utf8");

for (const f of ["README.md", "README.en.md"]) {
  let t = fs.readFileSync(f, "utf8");
  t = t.replace(new RegExp(`version-${FROM}-orange`, "g"), `version-${TO}-orange`);
  t = t.replace(new RegExp(`mooncakes-${FROM}-orange`, "g"), `mooncakes-${TO}-orange`);
  fs.writeFileSync(f, t, "utf8");
}
console.log("bumped", FROM, "->", TO);

