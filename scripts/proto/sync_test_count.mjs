import fs from "node:fs";

const files = ["README.md", "README.en.md", "TEST_REPORT.md"];
for (const f of files) {
  let t = fs.readFileSync(f, "utf8");
  t = t.replace(/tests-6_664×4/g, "tests-6_671×4");
  t = t.replace(/6,664 测试 × 4 目标/g, "6,671 测试 × 4 目标");
  t = t.replace(/6,664 tests × 4 targets/g, "6,671 tests × 4 targets");
  t = t.replace(/6,664 × 4 目标/g, "6,671 × 4 目标");
  t = t.replace(/（6,664 × 4 目标）/g, "（6,671 × 4 目标）");
  t = t.replace(/\| 6,664 \|/g, "| 6,671 |");
  t = t.replace(/6,664 测试/g, "6,671 测试");
  t = t.replace(/6,664 tests/g, "6,671 tests");
  fs.writeFileSync(f, t, "utf8");
  console.log("updated", f);
}
