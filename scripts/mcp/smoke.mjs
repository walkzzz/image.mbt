#!/usr/bin/env node
// MCP 端到端用例：直接与 mcp/server.mjs 走 stdio JSON-RPC，逐条断言。
// 运行：node scripts/mcp/smoke.mjs   （退出码 0 = 全绿）

import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import fs from "node:fs";
import os from "node:os";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../..");
const WORK = path.join(ROOT, "_build/proto/mcp");
fs.mkdirSync(WORK, { recursive: true });

const BIN = path.join(
  ROOT,
  "_build/native/release/build/walkzzz/image.mbt/cmd/imgtool/imgtool.exe",
);

function sh(cmd, args) {
  const r = spawnSync(cmd, args, { encoding: "buffer" });
  return { code: r.status, err: (r.stderr || "").toString() };
}

function need(name) {
  const p = path.join(WORK, name);
  if (fs.existsSync(p)) return p;
  return null;
}

// 1) 生成样本
const sample = path.join(WORK, "sample.png");
if (!fs.existsSync(sample)) {
  sh("ffmpeg", ["-v", "error", "-y", "-f", "lavfi", "-i", "testsrc2=size=640x360", "-frames:v", "1", sample]);
}
if (!fs.existsSync(sample)) {
  console.error("无法生成测试样本（ffmpeg 不可用）");
  process.exit(2);
}

const jpeg = path.join(WORK, "base.jpg");
if (!fs.existsSync(jpeg)) {
  spawnSync(BIN, ["decode", sample, jpeg, "--format", "jpeg", "--quality", "90"]);
}

// 2) 造一张带 EXIF 的 JPEG：在 SOI 之后插入 APP1 段
const exifJpeg = path.join(WORK, "exif.jpg");
{
  const src = fs.readFileSync(jpeg);
  const payload = Buffer.concat([Buffer.from("Exif\0\0"), Buffer.from("GPSLatitude=30.6;GPSLongitude=104.06;")]);
  const seg = Buffer.concat([Buffer.from([0xff, 0xe1]), Buffer.from([0, payload.length + 2]), payload]);
  fs.writeFileSync(exifJpeg, Buffer.concat([src.subarray(0, 2), seg, src.subarray(2)]));
}

const textFile = path.join(WORK, "not-image.txt");
fs.writeFileSync(textFile, "this is not an image\n");

const truncated = path.join(WORK, "truncated.png");
{
  const src = fs.readFileSync(sample);
  fs.writeFileSync(truncated, src.subarray(0, Math.min(64, src.length)));
}

// 3) MCP 客户端
class Client {
  constructor() {
    this.child = spawn(process.execPath, [path.join(ROOT, "mcp/server.mjs")], {
      stdio: ["pipe", "pipe", "pipe"],
      env: { ...process.env, IMGTOOL_BIN: BIN },
    });
    this.buf = "";
    this.pending = new Map();
    this.id = 0;
    this.child.stdout.setEncoding("utf8");
    this.child.stdout.on("data", (d) => {
      this.buf += d;
      while (true) {
        const nl = this.buf.indexOf("\n");
        if (nl < 0) break;
        const line = this.buf.slice(0, nl).trim();
        this.buf = this.buf.slice(nl + 1);
        if (!line) continue;
        let msg;
        try {
          msg = JSON.parse(line);
        } catch {
          continue;
        }
        if (msg.id !== undefined && this.pending.has(msg.id)) {
          this.pending.get(msg.id)(msg);
          this.pending.delete(msg.id);
        }
      }
    });
  }
  request(method, params) {
    const id = ++this.id;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error(`timeout ${method}`)), 20000);
      this.pending.set(id, (m) => {
        clearTimeout(timer);
        resolve(m);
      });
      this.child.stdin.write(JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n");
    });
  }
  call(name, args) {
    return this.request("tools/call", { name, arguments: args });
  }
  close() {
    this.child.kill();
  }
}

const results = [];
function check(name, cond, detail = "") {
  results.push({ name, ok: !!cond, detail });
  console.log(`${cond ? "PASS" : "FAIL"}  ${name}${detail && !cond ? `  -> ${detail}` : ""}`);
}

function payloadOf(resp) {
  const c = resp.result?.content?.[0];
  if (!c) return null;
  try {
    return JSON.parse(c.text);
  } catch {
    return null;
  }
}

function hasImage(resp) {
  return (resp.result?.content || []).some((c) => c.type === "image" && c.data.length > 0);
}

const main = async () => {
  const t0 = Date.now();
  const c = new Client();

  const init = await c.request("initialize", { protocolVersion: "2024-11-05", capabilities: {} });
  const bootMs = Date.now() - t0;
  check("01 initialize 返回 serverInfo", init.result?.serverInfo?.name === "imgtool", JSON.stringify(init.result));
  check("02 冷启动 <= 1s", bootMs <= 1000, `${bootMs}ms`);

  const list = await c.request("tools/list", {});
  const names = (list.result?.tools || []).map((t) => t.name).sort();
  check(
    "03 tools/list 恰好 6 个且名字齐全",
    names.length === 6 &&
      ["analyze", "crop", "decode", "encode", "resize", "sanitize"].every((n) => names.includes(n)),
    names.join(","),
  );
  const schemas = list.result?.tools || [];
  check(
    "04 每个工具都有 JSON Schema inputSchema",
    schemas.every((t) => t.inputSchema && t.inputSchema.type === "object" && Array.isArray(t.inputSchema.required)),
  );

  // --- 正常路径
  const an = await c.call("analyze", { input: sample });
  const anP = payloadOf(an);
  check("05 analyze 640x360", anP?.ok === true && anP.width === 640 && anP.height === 360, JSON.stringify(anP));
  check("06 analyze 返回均值/极值数组", Array.isArray(anP?.mean) && Array.isArray(anP?.max));

  const dec = await c.call("decode", { input: sample });
  check("07 decode 内联返回图片内容", dec.result?.isError === false && hasImage(dec), JSON.stringify(dec.result).slice(0, 120));
  check(
    "08 decode 默认 png mime",
    (dec.result?.content || []).some((x) => x.type === "image" && x.mimeType === "image/png"),
  );

  const decJ = await c.call("decode", { input: sample, format: "jpeg", quality: 88, output: jpeg });
  const decJP = payloadOf(decJ);
  check("09 decode→jpeg 落盘且格式正确", decJP?.ok === true && decJP.format === "jpeg" && fs.existsSync(jpeg), JSON.stringify(decJP));

  const enc = await c.call("encode", { input: sample, format: "bmp", output: path.join(WORK, "out.bmp") });
  const encP = payloadOf(enc);
  check("10 encode→bmp", encP?.ok === true && fs.existsSync(path.join(WORK, "out.bmp")), JSON.stringify(encP));

  const rz = await c.call("resize", { input: sample, width: 128, height: 72, mode: "cover", output: path.join(WORK, "cover.png") });
  const rzP = payloadOf(rz);
  check("11 resize cover 128x72", rzP?.ok === true && rzP.width === 128 && rzP.height === 72, JSON.stringify(rzP));

  const rc = await c.call("resize", { input: sample, width: 200, height: 200, mode: "contain" });
  check("12 resize contain 200x200 内联", rc.result?.isError === false && hasImage(rc));

  const cr = await c.call("crop", { input: sample, x: 10, y: 10, width: 100, height: 60, output: path.join(WORK, "crop.png") });
  const crP = payloadOf(cr);
  check("13 crop 100x60", crP?.ok === true && crP.width === 100 && crP.height === 60, JSON.stringify(crP));

  const san = await c.call("sanitize", { input: exifJpeg, output: path.join(WORK, "clean.jpg") });
  const sanP = payloadOf(san);
  check("14 sanitize 剥掉 EXIF", sanP?.ok === true && sanP.metadata_free === true, JSON.stringify(sanP));

  const st = await c.call("sanitize", { input: exifJpeg, policy: "strict" });
  check("15 sanitize strict 强制 png", st.result?.isError === false && hasImage(st));

  const qoi = await c.call("decode", { input: sample, format: "qoi", output: path.join(WORK, "out.qoi") });
  const qoiP = payloadOf(qoi);
  check("16 decode→qoi", qoiP?.ok === true && fs.existsSync(path.join(WORK, "out.qoi")), JSON.stringify(qoiP));
  const back = await c.call("analyze", { input: path.join(WORK, "out.qoi") });
  const backP = payloadOf(back);
  check("17 qoi 可回读且尺寸一致", backP?.ok === true && backP.width === 640, JSON.stringify(backP));

  // --- 错误路径
  const miss = await c.call("analyze", { input: path.join(WORK, "no_such.png") });
  const missP = payloadOf(miss);
  check("18 缺文件 → isError + 结构化 code", miss.result?.isError === true && typeof missP?.code === "string", JSON.stringify(missP));
  check("19 错误带 hint", typeof missP?.hint === "string" && missP.hint.length > 0, JSON.stringify(missP));

  const oob = await c.call("crop", { input: sample, x: 600, y: 300, width: 100, height: 100 });
  const oobP = payloadOf(oob);
  check("20 越界裁剪被拒", oob.result?.isError === true && oobP?.ok === false, JSON.stringify(oobP));

  const badArg = await c.call("resize", { input: sample, width: 64 });
  const badArgP = payloadOf(badArg);
  check(
    "21 缺必填参数被 MCP 层拦住",
    badArg.result?.isError === true && /缺少必填参数/.test(badArgP?.message || ""),
    JSON.stringify(badArgP),
  );

  const badFmt = await c.call("decode", { input: sample, format: "heic" });
  const badFmtP = payloadOf(badFmt);
  check("22 不支持的输出格式被拒", badFmt.result?.isError === true && badFmtP?.ok === false, JSON.stringify(badFmtP));

  const budget = await c.call("analyze", { input: sample, mem_budget: 1024 });
  const budgetP = payloadOf(budget);
  check(
    "23 --mem-budget 生效（字节超限被拒）",
    budget.result?.isError === true && /limit_bytes/.test(budgetP?.code || ""),
    JSON.stringify(budgetP),
  );

  const text = await c.call("analyze", { input: textFile });
  const textP = payloadOf(text);
  check("24 非图像文件被拒", text.result?.isError === true, JSON.stringify(textP));

  const trunc = await c.call("analyze", { input: truncated });
  const truncP = payloadOf(trunc);
  check("25 截断 PNG 被拒且仍是结构化错误", trunc.result?.isError === true && typeof truncP?.code === "string", JSON.stringify(truncP));

  const unknown = await c.call("nope", {});
  check("26 未知工具 → isError", unknown.result?.isError === true, JSON.stringify(unknown.result).slice(0, 100));

  const ping = await c.request("ping", {});
  check("27 ping 正常", ping.result !== undefined);

  c.close();

  const pass = results.filter((r) => r.ok).length;
  const total = results.length;
  console.log(`\nTotal: ${total}, passed: ${pass}, failed: ${total - pass}`);
  console.log(`boot: ${bootMs}ms / bin: ${BIN}`);
  process.exit(pass === total ? 0 : 1);
};

main().catch((e) => {
  console.error(e);
  process.exit(3);
});
