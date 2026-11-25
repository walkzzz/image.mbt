#!/usr/bin/env node
/**
 * S11 CLI 冒烟：8 个子命令 + --dry-run + stdin/stdout 管道。
 *
 * 不依赖 Pillow / ImageMagick：样本用 PPM(P6) 现造，校验也只看 PPM 头与 JSON 字段。
 * 用法：
 *   node scripts/cli_smoke.mjs            # 先 moon build --release cmd/imgtool
 *   IMGTOOL=path/to/imgtool.exe node scripts/cli_smoke.mjs
 */
import { execFileSync, spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const exe =
  process.env.IMGTOOL ??
  path.join(root, "_build", "native", "release", "build", "walkzzz", "image.mbt", "cmd", "imgtool", "imgtool.exe");

if (!fs.existsSync(exe)) {
  console.log("building imgtool ...");
  execFileSync("moon", ["build", "--release", "cmd/imgtool"], { cwd: root, stdio: "inherit" });
}
if (!fs.existsSync(exe)) {
  console.error(`imgtool not found: ${exe}`);
  process.exit(1);
}

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "imgtool-smoke-"));
const results = [];

function run(args) {
  const r = spawnSync(exe, args, { encoding: "buffer" });
  const stderr = r.stderr.toString("utf8").trim();
  const stdout = r.stdout.toString("utf8").trim();
  const jsonText = stderr || stdout;
  let json = null;
  try {
    json = JSON.parse(jsonText.split("\n").pop());
  } catch {
    // 非 JSON（例如 help/version）时保持 null
  }
  return { status: r.status, stdout, stderr, json };
}

function check(name, fn) {
  try {
    const detail = fn() ?? "";
    results.push({ name, ok: true, detail });
    console.log(`ok   ${name}${detail ? " — " + detail : ""}`);
  } catch (e) {
    results.push({ name, ok: false, detail: String(e?.message ?? e) });
    console.log(`FAIL ${name} — ${e?.message ?? e}`);
  }
}

function expect(cond, msg) {
  if (!cond) throw new Error(msg);
}

// 64×48 渐变 PPM（P6，maxval 255）
function makePpm(w, h) {
  const header = Buffer.from(`P6\n${w} ${h}\n255\n`, "ascii");
  const body = Buffer.alloc(w * h * 3);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const o = (y * w + x) * 3;
      body[o] = Math.round((x * 255) / (w - 1));
      body[o + 1] = Math.round((y * 255) / (h - 1));
      body[o + 2] = 128;
    }
  }
  return Buffer.concat([header, body]);
}

const sample = path.join(tmp, "sample.ppm");
fs.writeFileSync(sample, makePpm(64, 48));

// 1) info
check("info", () => {
  const r = run(["info", sample]);
  expect(r.status === 0, "exit != 0");
  expect(r.json?.ok === true, "ok != true");
  expect(r.json.width === 64 && r.json.height === 48, "尺寸不对");
  expect(r.json.format === "pnm", "format 应为 pnm");
  return `${r.json.width}×${r.json.height} ${r.json.format}`;
});

// 2) convert + 扩展名推断
check("convert -> png", () => {
  const out = path.join(tmp, "out.png");
  const r = run(["convert", sample, out]);
  expect(r.status === 0, "exit != 0");
  expect(r.json.format === "png", "应写出 png");
  expect(fs.existsSync(out) && fs.statSync(out).size === r.json.bytes, "落盘体积与 JSON 不一致");
  return `${r.json.bytes} B`;
});

// 3) convert --best + --max-bytes 拒绝
check("convert --best", () => {
   const r = run(["convert", sample, path.join(tmp, "best.bin"), "--best"]);
  expect(r.status === 0, "exit != 0");
  expect(["png", "jpeg", "webp", "qoi"].includes(r.json.format), `format=${r.json.format}`);
  expect(r.json.format_source === "best", "format_source 应为 best");
  return `${r.json.format} ${r.json.bytes} B`;
});
check("convert --best --max-bytes 超限", () => {
  const r = run(["convert", sample, path.join(tmp, "limit.bin"), "--best", "--max-bytes", "1"]);
  expect(r.status === 1, "应失败退出");
  expect(r.json.code === "budget/limit_bytes", `code=${r.json.code}`);
  return r.json.code;
});

// 4) --dry-run 不落盘
check("convert --dry-run", () => {
  const out = path.join(tmp, "dry.webp");
  const r = run(["convert", sample, out, "--dry-run"]);
  expect(r.status === 0, "exit != 0");
  expect(r.json.dry_run === true && r.json.wrote === false, "dry-run 字段不对");
  expect(!fs.existsSync(out), "dry-run 不应落盘");
  return `${r.json.format} ${r.json.bytes} B 未落盘`;
});

// 5) resize / crop
check("resize cover", () => {
  const out = path.join(tmp, "thumb.ppm");
  const r = run(["resize", sample, out, "--width", "32", "--height", "32"]);
  expect(r.status === 0, "exit != 0");
  expect(r.json.width === 32 && r.json.height === 32, "输出尺寸不对");
  return `${r.json.width}×${r.json.height}`;
});
check("crop", () => {
  const out = path.join(tmp, "crop.ppm");
  const r = run(["crop", sample, out, "--x", "8", "--y", "8", "--width", "16", "--height", "12"]);
  expect(r.status === 0, "exit != 0");
  expect(r.json.width === 16 && r.json.height === 12, "裁剪尺寸不对");
  return `${r.json.width}×${r.json.height}`;
});

// 6) filter：四个算子各跑一遍
for (const [op, extra] of [
  ["box", ["--radius", "2"]],
  ["gaussian", ["--radius", "2", "--sigma", "1.2"]],
  ["sharpen", ["--amount", "1.0"]],
  ["median", ["--ksize", "3"]],
]) {
  check(`filter ${op}`, () => {
    const out = path.join(tmp, `f-${op}.ppm`);
    const r = run(["filter", sample, out, "--op", op, ...extra]);
    expect(r.status === 0, "exit != 0");
    expect(r.json.op === op, "op 回显不对");
    expect(fs.existsSync(out), "未落盘");
    return `${r.json.bytes} B`;
  });
}

// 7) sanitize（区域打码必须真的改像素）
check("sanitize standard + region", () => {
  const clean = path.join(tmp, "clean.ppm");
  const r = run(["sanitize", sample, clean, "--policy", "standard", "--regions", "0,0,32,24"]);
  expect(r.status === 0, "exit != 0");
  expect(r.json.regions_redacted === 1, "应打码 1 个区域");
  const a = fs.readFileSync(sample);
  const b = fs.readFileSync(clean);
  expect(a.length === b.length, "PPM 体积应变");
  let diff = 0;
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) diff++;
  expect(diff > 0, "打码后像素未变化");
  return `${diff} 字节不同`;
});

// 8) bench
check("bench", () => {
  const r = run(["bench", sample, "--iters", "2", "--formats", "png,qoi"]);
  expect(r.status === 0, "exit != 0");
  expect(typeof r.json.decode_us === "number" && r.json.decode_us > 0, "decode_us 缺失");
  expect(typeof r.json.encode?.qoi?.us === "number", "qoi 编码耗时缺失");
  return `decode ${r.json.decode_us.toFixed(0)} us`;
});

// 9) 管道：stdin -> stdout，JSON 走 stderr
check("pipe stdin/stdout", () => {
  const r = spawnSync(exe, ["convert", "-", "-", "--format", "ppm"], {
    input: fs.readFileSync(sample),
    encoding: "buffer",
  });
  expect(r.status === 0, "exit != 0");
  const out = r.stdout.toString("latin1");
  expect(out.startsWith("P6\n64 48\n255\n"), "stdout 不是 64×48 PPM");
  const meta = JSON.parse(r.stderr.toString("utf8").trim().split("\n").pop());
  expect(meta.to_stdout === true, "to_stdout 应为 true");
  return `${r.stdout.length} B 二进制 + stderr JSON`;
});

// 10) info 从 stdin
check("info -", () => {
  const r = spawnSync(exe, ["info", "-"], { input: fs.readFileSync(sample), encoding: "buffer" });
  const meta = JSON.parse(r.stdout.toString("utf8").trim().split("\n").pop());
  expect(r.status === 0 && meta.width === 64 && meta.height === 48, "stdin info 失败");
  return `${meta.width}×${meta.height}`;
});

const failed = results.filter((r) => !r.ok);
console.log(`\n${results.length - failed.length}/${results.length} passed`);
fs.rmSync(tmp, { recursive: true, force: true });
if (failed.length > 0) process.exit(1);
