import fs from "node:fs";

const TO = process.argv[2] || "6,697";
const files = ["README.md", "README.en.md", "AGENTS.md", "docs/known-gaps.md"];
for (const f of files) {
  let t = fs.readFileSync(f, "utf8");
  t = t.split("6_691").join("6_697");
  t = t.split("6,691").join("6,697");
  t = t.split("6691").join("6697");
  fs.writeFileSync(f, t, "utf8");
  console.log("synced", f);
}
