#!/usr/bin/env node
// 展示页门禁：构建 playground.js、验证导出与语义、检查页面结构与模块链接、核对口径数字。

import { existsSync, copyFileSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DOCS = join(ROOT, "docs");
const INDEX = join(DOCS, "index.html");
const APP = join(DOCS, "app.js");
const CSS = join(DOCS, "style.css");
const JS_BUILD = join(
  ROOT,
  "_build/js/release/build/walkzzz/image.mbt/playground/playground.js",
);
const JS_DOCS = join(DOCS, "playground.js");

let failures = 0;
let checks = 0;
function check(name, ok, detail) {
  checks += 1;
  console.log(`${ok ? "PASS" : "FAIL"}  ${name}${detail ? `  (${detail})` : ""}`);
  if (!ok) failures += 1;
}

check("docs/index.html exists", existsSync(INDEX));
if (!existsSync(INDEX)) process.exit(1);

const html = readFileSync(INDEX, "utf8");
const appJs = readFileSync(APP, "utf8");
const css = readFileSync(CSS, "utf8");

check("index.html mentions image.mbt + 18 种格式", html.includes("image.mbt") && html.includes("18 种"));
check("index.html loads app.js / style.css", html.includes("app.js") && html.includes("style.css"));
check("app.js imports playground.js", appJs.includes('from "./playground.js"'));

const sections = ["features", "demo", "start", "api", "quality", "docs"];
check(
  "分区锚点齐全",
  sections.every((id) => html.includes(`id="${id}"`) && html.includes(`href="#${id}"`)),
  sections.join(", "),
);
check("顶部导航存在", html.includes('class="nav"'));

const hooks = [
  "hero-qr",
  "hero-version",
  "hero-exports",
  "hero-size",
  "hero-status",
  "qr-text",
  "qr-module",
  "qr-img",
  "qr-out",
  "filter-text",
  "filter-brightness",
  "filter-blur",
  "filter-img",
  "filter-out",
  "summary-out",
];
for (const id of hooks) check(`演示钩子: ${id}`, html.includes(`id="${id}"`));
for (const run of ["qr", "filter", "summary"]) {
  check(`演示动作: data-run=${run}`, html.includes(`data-run="${run}"`));
}

check("主题切换按钮", html.includes('id="theme-toggle"'));
check("主题持久化", appJs.includes("image-mbt-theme") && appJs.includes("localStorage"));
check("深浅主题样式", css.includes("[data-theme='dark']"));
check("无外链 CDN 静态资源", !/https?:\/\/[^"']+\.(css|js)(\?|")/.test(html));
check(
  "Open Graph 信息",
  ["og:title", "og:description", "og:url"].every((key) => html.includes(key)),
);

const moduleLinks = [...html.matchAll(/blob\/main\/([^")\s]+)\/README\.md/g)].map(
  (match) => match[1],
);
check(
  "模块链接 ≥ 10 且文件存在",
  moduleLinks.length >= 10 && moduleLinks.every((pkg) => existsSync(join(ROOT, pkg, "README.md"))),
  `${moduleLinks.length} 个链接`,
);
check(
  "6 个顶层模块均有文档入口",
  [
    "image.core",
    "image.codec",
    "image.process",
    "image.photography",
    "image.vision",
    "image.domain",
  ].every((pkg) => html.includes(`${pkg}/README.md`) || html.includes(`${pkg}/README.md`)),
);

const moonVersion =
  readFileSync(join(ROOT, "moon.mod"), "utf8").match(/version = "([^"]+)"/)?.[1] ?? "";
check("页面版本 = moon.mod", moonVersion.length > 0 && html.includes(`v${moonVersion}`), moonVersion);

const readme = readFileSync(join(ROOT, "README.md"), "utf8");
const badgeTests = Number(
  (readme.match(/badge\/tests-([\d_]+)/)?.[1] ?? "").replace(/_/g, ""),
);
const badgeCoverage = readme.match(/badge\/coverage-([\d.]+)/)?.[1] ?? "";
const badgePackages = Number(readme.match(/badge\/packages-(\d+)/)?.[1] ?? 0);
check(
  "页面每后端测试数 = README",
  badgeTests > 0 && html.includes(`${badgeTests} × 4`),
  `README=${badgeTests}`,
);
check(
  "页面四后端合计",
  badgeTests > 0 && html.includes(String(badgeTests * 4)),
  String(badgeTests * 4),
);
check(
  "页面覆盖率 = README",
  badgeCoverage.length > 0 && html.includes(`覆盖率 ${badgeCoverage}%`),
  badgeCoverage,
);
check("页面包数 = README", badgePackages > 0 && html.includes(String(badgePackages)), String(badgePackages));
check("页面变异 12 / 12", html.includes("12 / 12"));

const build = spawnSync("moon", ["build", "--target", "js", "--release", "playground"], {
  cwd: ROOT,
  encoding: "utf8",
  shell: process.platform === "win32",
  timeout: 1800000,
});
check("build playground js", build.status === 0, (build.stderr ?? "").slice(0, 300));
if (build.status !== 0) process.exit(1);
check("playground.js build exists", existsSync(JS_BUILD));
if (!existsSync(JS_BUILD)) process.exit(1);

copyFileSync(JS_BUILD, JS_DOCS);
check("docs/playground.js exists", existsSync(JS_DOCS));

const mod = await import(pathToFileURL(JS_DOCS).href);
for (const name of [
  "img_version",
  "img_qr_png_hex",
  "img_qr_filter_png_hex",
  "img_png_summary",
]) {
  check(`export: ${name}`, typeof mod[name] === "function");
}

check("img_version = moon.mod", mod.img_version() === moonVersion, mod.img_version());
const qr = mod.img_qr_png_hex("hello", 4, 2);
check(
  "QR 生成 PNG（签名 + 体积）",
  qr.startsWith("89504e47") && qr.length > 1000,
  `${qr.length} hex chars`,
);
const summary = mod.img_png_summary(qr);
check(
  "PNG 摘要含格式与尺寸",
  summary.includes("PNG") && /\d+x\d+/.test(summary),
  summary,
);
const filtered = mod.img_qr_filter_png_hex("hello", 30, 1);
check(
  "滤镜输出为有效 PNG 且与原图不同",
  filtered.startsWith("89504e47") && filtered !== qr,
  `${filtered.length} hex chars`,
);
const dark = mod.img_qr_filter_png_hex("hello", -100, 3);
check("滤镜参数生效（不同结果）", dark !== filtered && dark !== qr);

console.log(`\n=== pages check: ${failures === 0 ? "PASS" : `FAIL (${failures})`} · ${checks} checks ===`);
if (failures > 0) process.exit(1);