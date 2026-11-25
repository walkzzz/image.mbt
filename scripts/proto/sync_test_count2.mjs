import fs from "node:fs";

let en = fs.readFileSync("README.en.md", "utf8");
en = en.replace(/# Run tests \(6,664 × 4 targets\)/, "# Run tests (6,671 × 4 targets)");
en = en.replace(/3378 → 6574 → 6664/, "3378 → 6574 → 6,671");
fs.writeFileSync("README.en.md", en, "utf8");

let zh = fs.readFileSync("README.md", "utf8");
zh = zh.replace(/3378 → 6574 → 6664/, "3378 → 6574 → 6,671");
fs.writeFileSync("README.md", zh, "utf8");

let ag = fs.readFileSync("AGENTS.md", "utf8");
ag = ag.replace(/6664 \(native\) × 4 目标/, "6,671 (native) × 4 目标");
ag = ag.replace(/四目标各 6664/, "四目标各 6,671");
fs.writeFileSync("AGENTS.md", ag, "utf8");
console.log("done");
