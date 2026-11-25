#!/usr/bin/env node
// imgtool MCP server —— stdio JSON-RPC 2.0，无第三方依赖。
// 设计：本进程只做协议 + 参数校验 + 文件桥接，真正的解码/编码/处理在 MoonBit 侧
// (cmd/imgtool)。这样 CLI 与 MCP 走同一条代码路径，行为不会漂移。

import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import fs from "node:fs";
import os from "node:os";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(HERE, "../..");

const SERVER_INFO = { name: "imgtool", version: "0.1.5" };

function findBinary() {
  const candidates = [
    process.env.IMGTOOL_BIN,
    path.join(
      REPO_ROOT,
      "_build/native/release/build/walkzzz/image.mbt/cmd/imgtool/imgtool.exe",
    ),
    path.join(
      REPO_ROOT,
      "_build/native/release/build/walkzzz/image.mbt/cmd/imgtool/imgtool",
    ),
    path.join(REPO_ROOT, "target/release/imgtool.exe"),
  ].filter(Boolean);
  for (const c of candidates) {
    try {
      if (fs.statSync(c).isFile()) return c;
    } catch {}
  }
  throw new Error(
    "找不到 imgtool 可执行文件，请先 `moon build --release cmd/imgtool`，或用 IMGTOOL_BIN 指定路径",
  );
}

const BIN = (() => {
  try {
    return findBinary();
  } catch (e) {
    return null;
  }
})();

const MIME = {
  png: "image/png",
  jpeg: "image/jpeg",
  webp: "image/webp",
  bmp: "image/bmp",
  qoi: "image/qoi",
  gif: "image/gif",
};

function runImgTool(args) {
  return new Promise((resolve) => {
    if (!BIN) {
      resolve({
        ok: false,
        code: "process/invalid_argument",
        message: "imgtool 二进制缺失",
        hint: "先运行 moon build --release cmd/imgtool，或设置 IMGTOOL_BIN",
      });
      return;
    }
    const child = spawn(BIN, args, { windowsHide: true });
    let out = "";
    let err = "";
    child.stdout.on("data", (d) => (out += d));
    child.stderr.on("data", (d) => (err += d));
    child.on("error", (e) =>
      resolve({
        ok: false,
        code: "decode/decode_failed",
        message: `启动 imgtool 失败: ${e.message}`,
        hint: "检查可执行文件权限与路径",
      }),
    );
    child.on("close", () => {
      const line = out.trim().split("\n").filter(Boolean).pop();
      if (line) {
        try {
          resolve(JSON.parse(line));
          return;
        } catch {}
      }
      resolve({
        ok: false,
        code: "decode/decode_failed",
        message: (err || out || "imgtool 无输出").slice(0, 400),
        hint: "检查输入文件是否为有效图像",
      });
    });
  });
}

// ---------------------------------------------------------------------------
// 工具定义：6 个工具覆盖 读 / 写 / 变换 / 体检 / 脱敏
// ---------------------------------------------------------------------------

const str = (description) => ({ type: "string", description });
const int = (description, minimum) => ({
  type: "integer",
  description,
  ...(minimum ? { minimum } : {}),
});
const outProp = str("输出文件路径；省略则直接以内联图片返回（base64）");

const TOOLS = [
  {
    name: "analyze",
    description:
      "读取图像头信息并统计像素（宽高、通道、均值、标准差、最小/最大）。不写文件，最快的体检入口。",
    inputSchema: {
      type: "object",
      properties: { input: str("输入图像路径（任意支持格式）") },
      required: ["input"],
      additionalProperties: false,
    },
  },
  {
    name: "decode",
    description: "解码任意支持格式并归一化为目标格式（默认 png），可同时缩放体积。",
    inputSchema: {
      type: "object",
      properties: {
        input: str("输入图像路径"),
        format: str("输出格式: png|jpeg|webp|bmp|qoi（默认 png）"),
        quality: int("jpeg/webp 质量 1-100（默认 90）", 1),
        output: outProp,
      },
      required: ["input"],
      additionalProperties: false,
    },
  },
  {
    name: "encode",
    description: "把图像写成指定格式文件；与 decode 同路径，但必须显式给 format。",
    inputSchema: {
      type: "object",
      properties: {
        input: str("输入图像路径"),
        format: str("输出格式: png|jpeg|webp|bmp|qoi（必填）"),
        quality: int("有损格式质量 1-100（默认 90）", 1),
        output: outProp,
      },
      required: ["input", "format"],
      additionalProperties: false,
    },
  },
  {
    name: "resize",
    description:
      "缩放。mode=cover 等比铺满后居中裁切；mode=contain 等比装入并留白。",
    inputSchema: {
      type: "object",
      properties: {
        input: str("输入图像路径"),
        width: int("目标宽（像素）", 1),
        height: int("目标高（像素）", 1),
        mode: str("cover（默认）或 contain"),
        format: str("输出格式，默认沿用输入格式"),
        quality: int("有损格式质量 1-100（默认 90）", 1),
        output: outProp,
      },
      required: ["input", "width", "height"],
      additionalProperties: false,
    },
  },
  {
    name: "crop",
    description: "矩形裁剪，越界直接报错（不静默裁）。",
    inputSchema: {
      type: "object",
      properties: {
        input: str("输入图像路径"),
        x: int("左上角 x", 0),
        y: int("左上角 y", 0),
        width: int("裁切宽", 1),
        height: int("裁切高", 1),
        output: outProp,
      },
      required: ["input", "x", "y", "width", "height"],
      additionalProperties: false,
    },
  },
  {
    name: "sanitize",
    description:
      "脱敏：重编码剥元数据（EXIF/GPS/XMP/ICC/缩略图）+ 对已知区域做块均值打码 + strict 档整图模糊。policy=metadata/standard/strict。",
    inputSchema: {
      type: "object",
      properties: {
        input: str("输入图像路径"),
        policy: str("metadata（默认，只剥元数据）/ standard（+已知区域打码）/ strict（+整图模糊）"),
        regions: str("打码区域，逗号分隔可多块：\"x,y,w,h\" 或 \"x,y,w,h;x,y,w,h\""),
        block: int("打码块边长像素（默认 12）", 1),
        blur: int("strict 档 box blur 半径（默认 8）", 1),
        format: str("policy=metadata/standard 时的输出格式，默认沿用输入"),
        quality: int("有损格式质量 1-100（默认 90）", 1),
        output: outProp,
      },
      required: ["input"],
      additionalProperties: false,
    },
  },
];

// ---------------------------------------------------------------------------
// 参数 → argv
// ---------------------------------------------------------------------------

function requireArgs(params, required) {
  for (const k of required) {
    if (params[k] === undefined || params[k] === null) {
      return `缺少必填参数: ${k}`;
    }
  }
  return null;
}

function tmpOut(ext) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "imgtool-"));
  return path.join(dir, `out.${ext}`);
}

const EXT_BY_FORMAT = { png: "png", jpeg: "jpg", jpg: "jpg", webp: "webp", bmp: "bmp", qoi: "qoi", gif: "gif" };

function extFor(fmt, fallback = "png") {
  return EXT_BY_FORMAT[fmt || fallback] || fallback;
}

function guessExt(file) {
  const e = path.extname(file).replace(".", "").toLowerCase();
  return EXT_BY_FORMAT[e] || e || "png";
}

async function callTool(name, params, budget) {
  const tool = TOOLS.find((t) => t.name === name);
  if (!tool) {
    return {
      isError: true,
      payload: { ok: false, code: "process/invalid_argument", message: `未知工具: ${name}`, hint: "调用 tools/list 查看可用工具" },
    };
  }
  const missing = requireArgs(params, tool.inputSchema.required);
  if (missing) {
    return {
      isError: true,
      payload: { ok: false, code: "process/invalid_argument", message: missing, hint: "对照 inputSchema 传参" },
    };
  }

  const base = budget ? ["--mem-budget", String(budget)] : [];
  const target = params.output || tmpOut(extFor(params.format, guessExt(params.input)));
  const inline = !params.output;

  let sub;
  let rest = [];
  switch (name) {
    case "analyze":
      sub = "analyze";
      rest = [params.input];
      break;
    case "decode":
    case "encode":
      sub = "decode";
      rest = [params.input, target];
      if (params.format) rest.push("--format", params.format);
      if (params.quality) rest.push("--quality", String(params.quality));
      break;
    case "resize":
      sub = "resize";
      rest = [params.input, target, "--width", String(params.width), "--height", String(params.height)];
      if (params.mode) rest.push("--mode", params.mode);
      if (params.format) rest.push("--format", params.format);
      if (params.quality) rest.push("--quality", String(params.quality));
      break;
    case "crop":
      sub = "crop";
      rest = [
        params.input,
        target,
        "--x", String(params.x),
        "--y", String(params.y),
        "--width", String(params.width),
        "--height", String(params.height),
      ];
      break;
    case "sanitize":
      sub = "sanitize";
      rest = [params.input, target];
      if (params.policy) rest.push("--policy", params.policy);
      if (params.regions) rest.push("--regions", params.regions);
      if (params.block) rest.push("--block", String(params.block));
      if (params.blur) rest.push("--blur", String(params.blur));
      if (params.format) rest.push("--format", params.format);
      if (params.quality) rest.push("--quality", String(params.quality));
      break;
  }

  const args = [sub, ...base, ...rest];

  const res = await runImgTool(args);
  if (!res.ok) return { isError: true, payload: res };

  if (name === "analyze") return { isError: false, payload: res };

  const content = [{ type: "text", text: JSON.stringify(res) }];
  if (inline) {
    try {
      const bytes = fs.readFileSync(target);
      const fmt = res.format || guessExt(target);
      content.push({
        type: "image",
        data: bytes.toString("base64"),
        mimeType: MIME[fmt] || "application/octet-stream",
      });
    } catch (e) {
      return {
        isError: true,
        payload: { ok: false, code: "process/process_failed", message: `读回输出失败: ${e.message}`, hint: "检查临时目录权限" },
      };
    }
  }
  return { isError: false, payload: res, content };
}

function toolResult(r) {
  if (r.isError) {
    const p = r.payload;
    return {
      isError: true,
      content: [
        {
          type: "text",
          text: JSON.stringify({ ok: false, code: p.code, message: p.message, hint: p.hint }),
        },
      ],
    };
  }
  return { isError: false, content: r.content || [{ type: "text", text: JSON.stringify(r.payload) }] };
}

// ---------------------------------------------------------------------------
// JSON-RPC 循环
// ---------------------------------------------------------------------------

let memBudget = process.env.IMGTOOL_MEM_BUDGET || 0;

function handle(msg) {
  const id = msg.id;
  const method = msg.method;
  if (method === "initialize") {
    return {
      jsonrpc: "2.0",
      id,
      result: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: { listChanged: false } },
        serverInfo: SERVER_INFO,
        instructions:
          "图像工具箱：analyze 体检、decode/encode 转格式、resize 缩放、crop 裁剪、sanitize 去元数据。失败统一返回 {ok:false,code,message,hint}。",
      },
    };
  }
  if (method === "notifications/initialized" || method === "initialized") return null;
  if (method === "ping") return { jsonrpc: "2.0", id, result: {} };
  if (method === "tools/list") {
    return { jsonrpc: "2.0", id, result: { tools: TOOLS } };
  }
  if (method === "tools/call") {
    const name = msg.params?.name;
    const args = msg.params?.arguments || {};
    const budget = args.mem_budget || memBudget;
    return callTool(name, args, budget).then((r) => ({
      jsonrpc: "2.0",
      id,
      result: toolResult(r),
    }));
  }
  if (method === "shutdown" || method === "exit") {
    process.exit(0);
  }
  return {
    jsonrpc: "2.0",
    id,
    error: { code: -32601, message: `未实现的方法: ${method}` },
  };
}

let buf = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", async (chunk) => {
  buf += chunk;
  while (true) {
    const nl = buf.indexOf("\n");
    if (nl < 0) break;
    const line = buf.slice(0, nl).trim();
    buf = buf.slice(nl + 1);
    if (!line) continue;
    let msg;
    try {
      msg = JSON.parse(line);
    } catch {
      process.stdout.write(
        JSON.stringify({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "JSON 解析失败" } }) + "\n",
      );
      continue;
    }
    try {
      const reply = await handle(msg);
      if (reply) process.stdout.write(JSON.stringify(reply) + "\n");
    } catch (e) {
      process.stdout.write(
        JSON.stringify({
          jsonrpc: "2.0",
          id: msg?.id ?? null,
          error: { code: -32603, message: String(e && e.message ? e.message : e) },
        }) + "\n",
      );
    }
  }
});
