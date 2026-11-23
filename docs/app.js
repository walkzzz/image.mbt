import {
  img_version,
  img_qr_png_hex,
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

/* ---------- 演示动作 ---------- */

let lastHex = "";
let lastKind = "";

function runQr() {
  const text = $("#qr-text").value;
  const modulePx = Number($("#qr-module").value);
  const started = performance.now();
  const hex = img_qr_png_hex(text, modulePx, 2);
  if (!hex) {
    setText("#qr-out", "生成失败：请输入文本");
    return;
  }
  const bytes = showPng($("#qr-img"), hex);
  lastHex = hex;
  lastKind = "QR";
  const ms = (performance.now() - started).toFixed(1);
  setText("#qr-out", `PNG ${bytes} 字节 · 模块 ${modulePx}px · ${ms} ms`);
  setText("#hero-size", `${bytes} B`);
  $("#qr-img").alt = `二维码：${text}`;
}

function runFilter() {
  const text = $("#filter-text").value;
  const brightness = Number($("#filter-brightness").value);
  const blur = Number($("#filter-blur").value);
  const started = performance.now();
  const hex = img_qr_filter_png_hex(text, brightness, blur);
  if (!hex) {
    setText("#filter-out", "处理失败：请输入文本");
    return;
  }
  const bytes = showPng($("#filter-img"), hex);
  lastHex = hex;
  lastKind = "滤镜";
  const ms = (performance.now() - started).toFixed(1);
  setText(
    "#filter-out",
    `亮度 ${brightness} · 方框模糊 ${blur}px · PNG ${bytes} 字节 · ${ms} ms`,
  );
  setText("#hero-size", `${bytes} B`);
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

/* ---------- 初始化 ---------- */

setText("#hero-version", img_version());
setText("#hero-exports", "4");

try {
  const heroHex = img_qr_png_hex("image.mbt", 4, 2);
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