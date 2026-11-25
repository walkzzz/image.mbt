#!/usr/bin/env node
// S07 dogfood：把 imgtool 当产品用一遍（真实批处理流水线 + 摩擦探针），产出 JSON 报告。
// 运行：node scripts/dogfood.mjs [--keep]
// 说明：只读输入、只写 _build/proto/dogfood/，不动仓库其它文件。

import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import fs from "node:fs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "..");
const WORK = path.join(ROOT, "_build/proto/dogfood");
const BIN = path.join(ROOT, "_build/native/release/build/walkzzz/image.mbt/cmd/imgtool/imgtool.exe");

fs.mkdirSync(WORK, { recursive: true });

function run(args, opts = {}) {
  const t0 = process.hrtime.bigint();
  const r = spawnSync(BIN, args, { encoding: "utf8", maxBuffer: 128 * 1024 * 1024, ...opts });
  const ms = Number(process.hrtime.bigint() - t0) / 1e6;
  const lines = (r.stdout || "").trim().split("\n").filter(Boolean);
  let json = null;
  try {
    json = JSON.parse(lines[lines.length - 1] || "");
  } catch {
    json = null;
  }
  return { ms: Math.round(ms), code: r.status, json, stderr: (r.stderr || "").trim().slice(0, 300) };
}

const findings = [];
const note = (kind, id, title, evidence) => findings.push({ kind, id, title, evidence });

function ff(args) {
  const r = spawnSync("ffmpeg", ["-v", "error", "-y", ...args], { encoding: "utf8" });
  if (r.status !== 0) throw new Error(`ffmpeg 失败: ${args.join(" ")}\n${r.stderr}`);
}

// ---------- 0. 造真实输入 ----------
const SRC = [
  { name: "shot_640.png", args: ["-f", "lavfi", "-i", "testsrc2=size=640x360", "-frames:v", "1"] },
  { name: "photo_1920.jpg", args: ["-f", "lavfi", "-i", "testsrc2=size=1920x1080", "-frames:v", "1", "-q:v", "3"] },
  { name: "photo_1920.webp", args: ["-f", "lavfi", "-i", "testsrc2=size=1920x1080", "-frames:v", "1", "-c:v", "libwebp", "-lossless", "1"] },
  { name: "flat_1080.bmp", args: ["-f", "lavfi", "-i", "testsrc2=size=1920x1080", "-frames:v", "1"] },
  { name: "gray_800.png", args: ["-f", "lavfi", "-i", "testsrc2=size=800x600", "-vf", "format=gray", "-frames:v", "1"] },
  { name: "alpha_800.png", args: ["-f", "lavfi", "-i", "testsrc2=size=800x600", "-vf", "format=rgba", "-frames:v", "1"] },
  { name: "big_4096.png", args: ["-f", "lavfi", "-i", "testsrc2=size=4096x4096", "-frames:v", "1"] },
  { name: "band_1080.png", args: ["-f", "lavfi", "-i", "gradients=size=1920x1080", "-frames:v", "1"] },
];
for (const s of SRC) {
  const p = path.join(WORK, s.name);
  if (!fs.existsSync(p)) ff([...s.args, p]);
}

// ---------- 1. 批处理流水线（这是我自己的工作流） ----------
const pipeline = [];
for (const s of SRC) {
  const src = path.join(WORK, s.name);
  const steps = [];
  let cur = src;
  const base = path.basename(src, path.extname(src));

  const info = run(["info", cur]);
  steps.push({ op: "info", ok: info.json?.ok === true, ms: info.ms });

  const jpg = path.join(WORK, `${base}_q85.jpg`);
  const dec = run(["decode", cur, jpg, "--format", "jpeg", "--quality", "85"]);
  steps.push({ op: "decode→jpeg q85", ok: dec.json?.ok === true, ms: dec.ms, bytes: dec.json?.bytes });
  if (dec.json?.ok) cur = jpg;

  const thumb = path.join(WORK, `${base}_thumb.png`);
  const rz = run(["resize", cur, thumb, "--width", "320", "--height", "180", "--mode", "cover"]);
  steps.push({ op: "resize cover 320x180", ok: rz.json?.ok === true, ms: rz.ms, bytes: rz.json?.bytes });

  const clean = path.join(WORK, `${base}_clean.jpg`);
  const san = run(["sanitize", cur, clean, "--policy", "standard", "--regions", "120,80,220,260"]);
  steps.push({ op: "sanitize standard", ok: san.json?.ok === true, ms: san.ms, residue: san.json?.metadata_free });

  const an = run(["analyze", cur]);
  steps.push({ op: "analyze", ok: an.json?.ok === true, ms: an.ms });

  const inv = run(["info", thumb]);
  steps.push({
    op: "info thumb 复核",
    ok: inv.json?.width === 320 && inv.json?.height === 180,
    ms: inv.ms,
  });

  pipeline.push({ input: s.name, srcBytes: fs.statSync(src).size, steps });
}

const totalMs = pipeline.reduce((a, p) => a + p.steps.reduce((b, s) => b + s.ms, 0), 0);
const failed = pipeline.flatMap((p) => p.steps.filter((s) => !s.ok).map((s) => `${p.input}: ${s.op}`));

// ---------- 2. 摩擦探针 ----------
// P1 help / version
const p1a = run([]);
const p1b = run(["--help"]);
const p1c = run(["version"]);
note(
  p1a.json?.code === "process/invalid_argument" && p1c.json?.ok !== true ? "friction" : "ok",
  "P1",
  "没有 help/version：新用户第一件事就是敲 --help / version",
  { argv0: p1a.json, help: p1b.json, version: p1c.json },
);

// P2 输出格式推断：out.jpg 但没 --format
const p2 = run(["decode", path.join(WORK, "shot_640.png"), path.join(WORK, "p2_out.jpg")]);
const p2f = fs.existsSync(path.join(WORK, "p2_out.jpg")) ? fs.readFileSync(path.join(WORK, "p2_out.jpg")).subarray(0, 8) : Buffer.alloc(0);
const p2IsPng = p2f.subarray(1, 4).toString("latin1") === "PNG";
note(
  p2IsPng ? "friction" : "ok",
  "P2",
  "扩展名不参与决策：decode x.png out.jpg 写出的是 PNG 字节（扩展名骗人）",
  { json: p2.json, sniffed: p2f.toString("hex") },
);

// P3 crop 恒写 png，无论扩展名
const p3 = run(["crop", path.join(WORK, "shot_640.png"), path.join(WORK, "p3_cut.jpg"), "--x", "0", "--y", "0", "--width", "200", "--height", "100"]);
const p3f = fs.existsSync(path.join(WORK, "p3_cut.jpg")) ? fs.readFileSync(path.join(WORK, "p3_cut.jpg")).subarray(1, 4).toString("latin1") : "";
note(p3.json?.ok === true && p3f === "PNG" ? "friction" : "ok", "P3", "crop 不接受 --format，恒输出 png（下游要做 jpeg 得再跑一次 decode）", { json: p3.json });

// P4 sanitize 输出扩展名与输入冲突
const p4 = run(["sanitize", path.join(WORK, "photo_1920.jpg"), path.join(WORK, "p4_clean.png")]);
const p4f = fs.existsSync(path.join(WORK, "p4_clean.png")) ? fs.readFileSync(path.join(WORK, "p4_clean.png")).subarray(0, 3).toString("hex") : "";
note(p4.json?.format === "jpeg" && p4f.startsWith("ffd8") ? "friction" : "ok", "P4", "sanitize out.png 实际写 jpeg 字节（policy 默认沿用输入格式，扩展名被忽略）", { json: p4.json, head: p4f });

// P5 错误消息的可操作性
const p5a = run(["decode", path.join(WORK, "nope.png"), path.join(WORK, "x.png")]);
const p5b = run(["resize", path.join(WORK, "shot_640.png"), path.join(WORK, "nodir/x.png"), "--width", "10", "--height", "10"]);
note(p5a.json?.ok === false && p5b.json?.ok === false ? "ok" : "friction", "P5", "输入不存在 / 输出目录不存在时的错误是否可执行", { missingInput: p5a.json, missingOutDir: p5b.json });

// P6 12MP 级别的端到端耗时（4096² → 缩略图）
const p6 = run(["resize", path.join(WORK, "big_4096.png"), path.join(WORK, "p6_thumb.png"), "--width", "320", "--height", "180"]);
note(p6.json?.ok === true && p6.ms < 4000 ? "ok" : "friction", "P6", "4096²(16MP) → 320x180 端到端耗时（含进程启动）", { ms: p6.ms, bytes: p6.json?.bytes });

// P7 webp 无损往返体积与耗时
const p7 = run(["decode", path.join(WORK, "shot_640.png"), path.join(WORK, "p7.webp"), "--format", "webp"]);
note(p7.json?.ok === true ? "ok" : "friction", "P7", "webp 无损编码可用性与体积", { ms: p7.ms, bytes: p7.json?.bytes });

// P8 MCP 侧同一操作（验证出口一致性）
const mcp = spawnSync(process.execPath, [path.join(ROOT, "mcp/server.mjs")], {
  input: [
    JSON.stringify({ jsonrpc: "2.0", id: 1, method: "initialize", params: { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "dogfood", version: "0" } } }),
    JSON.stringify({ jsonrpc: "2.0", id: 2, method: "tools/call", params: { name: "sanitize", arguments: { input: path.join(WORK, "photo_1920.jpg"), policy: "standard", regions: "120,80,220,260", output: path.join(WORK, "p8_clean.jpg") } } }),
  ].join("\n") + "\n",
  encoding: "utf8",
  env: { ...process.env, IMGTOOL_BIN: BIN },
  timeout: 30000,
});
let p8ok = false;
try {
  const last = mcp.stdout.trim().split("\n").pop();
  p8ok = JSON.parse(last).result?.isError === false;
} catch {
  p8ok = false;
}
note(p8ok ? "ok" : "friction", "P8", "MCP 出口跑同一条 sanitize 是否一致", { ok: p8ok, stderr: mcp.stderr.slice(0, 200) });

// ---------- 3. 报告 ----------
const report = {
  schema: "dogfood@1",
  ok: failed.length === 0 && findings.every((f) => f.kind === "ok"),
  pipeline: {
    inputs: SRC.length,
    ops: pipeline.reduce((a, p) => a + p.steps.length, 0),
    totalMs: Math.round(totalMs),
    failed,
  },
  findings,
};
console.log(JSON.stringify(report, null, 2));
process.exit(0);
