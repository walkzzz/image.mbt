#!/usr/bin/env node
// S06 验收：200 张带元数据的样本，三档 policy 全量脱敏，输出 0 残留。
// 运行：node scripts/mcp/sanitize_batch.mjs

import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import fs from "node:fs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../..");
const WORK = path.join(ROOT, "_build/proto/sanitize_batch");
const BIN = path.join(ROOT, "_build/native/release/build/walkzzz/image.mbt/cmd/imgtool/imgtool.exe");

const SAMPLES = 200;
const POLICIES = ["metadata", "standard", "strict"];
const SIGNATURES = ["Exif", "GPS", "XMP", "ICC_PROFILE", "Photoshop 3.0", "<x:xmpmeta", "Thumbnail"];

fs.mkdirSync(WORK, { recursive: true });

function run(args) {
  const r = spawnSync(BIN, args, { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  const line = (r.stdout || "").trim().split("\n").filter(Boolean).pop();
  try {
    return JSON.parse(line);
  } catch {
    return { ok: false, code: "spawn/failed", message: (r.stderr || "").slice(0, 200) };
  }
}

// 1) 基图
const samplePng = path.join(WORK, "base.png");
if (!fs.existsSync(samplePng)) {
  const g = spawnSync("ffmpeg", ["-v", "error", "-y", "-f", "lavfi", "-i", "testsrc2=size=640x360", "-frames:v", "1", samplePng]);
  if (g.status !== 0 || !fs.existsSync(samplePng)) {
    console.error("ffmpeg 不可用，无法生成基图");
    process.exit(2);
  }
}
const baseJpg = path.join(WORK, "base.jpg");
if (!fs.existsSync(baseJpg)) {
  const r = run(["decode", samplePng, baseJpg, "--format", "jpeg", "--quality", "92"]);
  if (!r.ok) {
    console.error("基图编码失败", r);
    process.exit(2);
  }
}

// 2) 造 200 张带 EXIF / GPS / XMP / ICC / 缩略图的 JPEG
function appSegment(marker, payload) {
  const len = payload.length + 2;
  return Buffer.concat([Buffer.from([0xff, marker, (len >> 8) & 0xff, len & 0xff]), payload]);
}

const base = fs.readFileSync(baseJpg);
const inputs = [];
for (let i = 0; i < SAMPLES; i++) {
  const exif = Buffer.concat([
    Buffer.from("Exif\0\0"),
    Buffer.from(`GPSLatitude=30.6${i};GPSLongitude=104.06${i};Make=CAM${i};`),
    Buffer.from(`Thumbnail=${"T".repeat(20 + (i % 40))};`),
  ]);
  const xmp = Buffer.from(`<x:xmpmeta>rating=${(i % 5) + 1}</x:xmpmeta>`);
  const icc = Buffer.concat([Buffer.from("ICC_PROFILE\0"), Buffer.from(`sRGB-${i}`.padEnd(64, "."))]);
  const body = Buffer.concat([
    base.subarray(0, 2),
    appSegment(0xe1, exif),
    appSegment(0xe1, xmp),
    appSegment(0xe2, icc),
    base.subarray(2),
  ]);
  const f = path.join(WORK, `in_${String(i).padStart(3, "0")}.jpg`);
  fs.writeFileSync(f, body);
  inputs.push(f);
}

function hits(file) {
  const d = fs.readFileSync(file);
  return SIGNATURES.filter((s) => d.includes(Buffer.from(s, "latin1")));
}

// 3) 三档全量脱敏
const summary = { samples: SAMPLES, runs: 0, dirtyInputs: 0, dirtyOutputs: [], failed: [] };
for (let i = 0; i < inputs.length; i++) {
  if (hits(inputs[i]).length > 0) summary.dirtyInputs++;
  const policy = POLICIES[i % POLICIES.length];
  const out = path.join(WORK, `out_${String(i).padStart(3, "0")}_${policy}.${policy === "strict" ? "png" : "jpg"}`);
  const args = ["sanitize", inputs[i], out, "--policy", policy];
  if (policy !== "metadata") args.push("--regions", "80,60,240,140", "--block", "12");
  const r = run(args);
  summary.runs++;
  if (!r.ok) {
    summary.failed.push({ file: inputs[i], policy, code: r.code, message: r.message });
    continue;
  }
  const ms = hits(out);
  if (ms.length > 0) summary.dirtyOutputs.push({ file: out, policy, signatures: ms });
  // 输出必须仍可解且尺寸不变
  const info = run(["info", out]);
  if (!info.ok || info.width !== 640 || info.height !== 360) {
    summary.failed.push({ file: out, policy, reason: "输出不可读或尺寸变化", info });
  }
}

const pass = summary.dirtyOutputs.length === 0 && summary.failed.length === 0;
console.log(
  JSON.stringify(
    {
      schema: "sanitize-batch@1",
      ok: pass,
      samples: summary.samples,
      runs: summary.runs,
      dirtyInputs: summary.dirtyInputs,
      residue: summary.dirtyOutputs.length,
      failed: summary.failed.length,
      details: summary.dirtyOutputs.slice(0, 5).concat(summary.failed.slice(0, 5)),
    },
    null,
    2,
  ),
);
process.exit(pass ? 0 : 1);
