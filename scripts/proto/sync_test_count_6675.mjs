// Sync the test-count mentions (6671 -> 6675) across docs. UTF-8 safe.
import fs from "node:fs";

const FROM_COMMA = "6,671";
const TO_COMMA = "6,675";
const FROM_BADGE = "6_671×4";
const TO_BADGE = "6_675×4";

const files = [
  "README.md",
  "README.en.md",
  "TEST_REPORT.md",
  "AGENTS.md",
  "docs/known-gaps.md",
  "docs/roadmap.md",
];

for (const f of files) {
  if (!fs.existsSync(f)) continue;
  let t = fs.readFileSync(f, "utf8");
  t = t.split(FROM_COMMA).join(TO_COMMA).split(FROM_BADGE).join(TO_BADGE);
  fs.writeFileSync(f, t, "utf8");
  console.log("synced", f, (t.match(/6,675/g) || []).length, "mentions");
}
