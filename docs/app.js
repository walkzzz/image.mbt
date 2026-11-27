import {
  img_version,
  img_qr_png_hex,
  img_qr_max_bytes,
  img_qr_filter_png_hex,
  img_png_summary,
} from "./playground.js";

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => Array.from(document.querySelectorAll(sel));
const setText = (id, text) => {
  const node = $(id);
  if (node) node.textContent = text;
};

/* ---------- 主题 ---------- */

const THEME_KEY = "image-mbt-theme";
const themeToggle = $("#theme-toggle");

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  if (themeToggle) {
    themeToggle.textContent = theme === "dark" ? "◐" : "☀";
    themeToggle.setAttribute(
      "aria-label",
      theme === "dark" ? "切换到浅色主题" : "切换到深色主题",
    );
    themeToggle.title = themeToggle.getAttribute("aria-label");
  }
}

if (themeToggle) {
  themeToggle.addEventListener("click", () => {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    applyTheme(next);
    try {
      localStorage.setItem(THEME_KEY, next);
    } catch {
      /* 隐私模式忽略 */
    }
  });
  applyTheme(document.documentElement.dataset.theme === "light" ? "light" : "dark");
}

/* ---------- hex → PNG ---------- */

function hexToBytes(hex) {
  if (!hex || hex.length === 0 || hex.length % 2 !== 0) return null;
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) {
    const value = Number.parseInt(hex.slice(i * 2, i * 2 + 2), 16);
    if (Number.isNaN(value)) return null;
    out[i] = value;
  }
  return out;
}

function showPng(image, hex) {
  const bytes = hexToBytes(hex);
  if (!bytes) return 0;
  if (image.dataset.url) URL.revokeObjectURL(image.dataset.url);
  const url = URL.createObjectURL(new Blob([bytes], { type: "image/png" }));
  image.src = url;
  image.dataset.url = url;
  image.style.display = "block";
  return bytes.length;
}

/** 生成失败时清掉旧图，避免「报错但画面仍是上一次的二维码」。 */
function hidePng(image) {
  if (!image) return;
  if (image.dataset.url) {
    URL.revokeObjectURL(image.dataset.url);
    delete image.dataset.url;
  }
  image.removeAttribute("src");
  image.style.display = "none";
}

/* ---------- 演示动作 ---------- */

// ISO 18004 要求二维码四周静区 ≥ 4 模块；后端也会把更小的值夹到 4。
const QR_QUIET_ZONE = 4;

let qrMaxBytes = 17;
try {
  qrMaxBytes = img_qr_max_bytes();
} catch {
  /* 旧构建产物兜底：v1-L 固定 17 字节 */
}

let lastHex = "";
let lastKind = "";

/** 输入变化后，之前的 PNG 摘要不再代表当前参数，必须显式失效。 */
function invalidateSummary() {
  lastHex = "";
  lastKind = "";
  setText("#summary-out", "参数已变更，请重新生成后再取摘要");
}

function utf8Length(text) {
  return new TextEncoder().encode(text).length;
}

function qrFailureText(text) {
  const bytes = utf8Length(text.trim());
  if (bytes === 0) return "生成失败：请输入文本";
  return `生成失败：${bytes} 字节超出 ${qrMaxBytes} 字节上限（UTF-8，中文 1 字 = 3 字节）`;
}

function runQr() {
  const text = $("#qr-text").value;
  const modulePx = Number($("#qr-module").value);
  const image = $("#qr-img");
  const started = performance.now();
  const hex = img_qr_png_hex(text, modulePx, QR_QUIET_ZONE);
  if (!hex) {
    hidePng(image);
    lastHex = "";
    lastKind = "";
    setText("#qr-out", qrFailureText(text));
    setText("#hero-size", "—");
    return;
  }
  const bytes = showPng(image, hex);
  lastHex = hex;
  lastKind = "QR";
  const ms = (performance.now() - started).toFixed(1);
  setText("#qr-out", `PNG ${bytes} 字节 · 模块 ${modulePx}px · 静区 ${QR_QUIET_ZONE} · ${ms} ms`);
  setText("#hero-size", `${bytes} B`);
  image.alt = `二维码：${text}`;
}

function runFilter() {
  const text = $("#filter-text").value;
  const brightness = Number($("#filter-brightness").value);
  const blur = Number($("#filter-blur").value);
  const image = $("#filter-img");
  const started = performance.now();
  const hex = img_qr_filter_png_hex(text, brightness, blur);
  if (!hex) {
    hidePng(image);
    lastHex = "";
    lastKind = "";
    setText("#filter-out", qrFailureText(text).replace("生成失败", "处理失败"));
    setText("#hero-size", "—");
    return;
  }
  const bytes = showPng(image, hex);
  lastHex = hex;
  lastKind = "滤镜";
  const ms = (performance.now() - started).toFixed(1);
  setText(
    "#filter-out",
    `亮度 ${brightness} · 方框模糊 ${blur}px · PNG ${bytes} 字节 · ${ms} ms`,
  );
  setText("#hero-size", `${bytes} B`);
  image.alt = `滤镜二维码：${text}（亮度 ${brightness}，模糊 ${blur}px）`;
}

function runSummary() {
  if (!lastHex) {
    setText("#summary-out", "先生成一张 PNG（QR 或滤镜）");
    return;
  }
  try {
    const summary = img_png_summary(lastHex);
    setText("#summary-out", summary ? `${lastKind}：${summary}` : "解码失败");
  } catch {
    setText("#summary-out", "解码失败");
  }
}

const ACTIONS = { qr: runQr, filter: runFilter, summary: runSummary };

$$("button[data-run]").forEach((button) => {
  button.addEventListener("click", () => {
    const action = ACTIONS[button.dataset.run];
    if (action) action();
  });
});

const ENTER_ACTIONS = [
  ["#qr-text", "qr"],
  ["#filter-text", "filter"],
];

ENTER_ACTIONS.forEach(([selector, action]) => {
  const field = $(selector);
  if (!field) return;
  field.addEventListener("keydown", (event) => {
    if (event.key !== "Enter") return;
    event.preventDefault();
    const button = $(`button[data-run="${action}"]`);
    if (button) button.click();
  });
});

["#qr-text", "#filter-text", "#qr-module"].forEach((selector) => {
  const field = $(selector);
  if (!field) return;
  field.addEventListener("input", () => {
    if (lastHex) invalidateSummary();
  });
});

/* ---------- 复制 ---------- */

async function copyText(text) {
  if (navigator.clipboard && window.isSecureContext) {
    await navigator.clipboard.writeText(text);
    return;
  }
  const area = document.createElement("textarea");
  area.value = text;
  area.setAttribute("readonly", "");
  area.style.position = "fixed";
  area.style.opacity = "0";
  document.body.appendChild(area);
  area.select();
  document.execCommand("copy");
  document.body.removeChild(area);
}

$$("[data-copy-target]").forEach((button) => {
  button.addEventListener("click", async () => {
    const target = document.getElementById(button.dataset.copyTarget);
    if (!target) return;
    const original = button.textContent;
    try {
      await copyText(target.textContent.trim());
      button.textContent = "已复制";
    } catch {
      button.textContent = "复制失败";
    }
    setTimeout(() => {
      button.textContent = original;
    }, 1400);
  });
});

/* ---------- 导航高亮 ---------- */

const navLinks = $$(".nav a");
const sections = navLinks
  .map((link) => document.querySelector(link.getAttribute("href")))
  .filter(Boolean);

if ("IntersectionObserver" in window && sections.length > 0) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        navLinks.forEach((link) => {
          link.classList.toggle(
            "active",
            link.getAttribute("href") === `#${entry.target.id}`,
          );
        });
      });
    },
    { rootMargin: "-45% 0px -50% 0px", threshold: 0 },
  );
  sections.forEach((section) => observer.observe(section));
}

/* ---------- 移动端导航（< 960px 折叠为抽屉） ---------- */

const nav = $(".nav");
const navToggle = $("#nav-toggle");

if (nav && navToggle) {
  const setOpen = (open) => {
    nav.dataset.open = open ? "true" : "false";
    navToggle.setAttribute("aria-expanded", open ? "true" : "false");
  };
  setOpen(false);
  navToggle.addEventListener("click", () => {
    setOpen(nav.dataset.open !== "true");
  });
  $$(".nav a").forEach((link) => {
    link.addEventListener("click", () => setOpen(false));
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") setOpen(false);
  });
}

/* ---------- 初始化 ---------- */

setText("#hero-version", img_version());
setText("#hero-exports", "5");

try {
  const heroHex = img_qr_png_hex("image.mbt", 4, QR_QUIET_ZONE);
  const heroBytes = showPng($("#hero-qr"), heroHex);
  if (heroBytes > 0) {
    setText("#hero-size", `${heroBytes} B`);
    setText("#hero-status", "已就绪 · 本地计算");
  } else {
    setText("#hero-status", "生成失败");
  }
} catch {
  setText("#hero-status", "运行失败");
}

runQr();
