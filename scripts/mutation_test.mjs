import fs from 'node:fs';
import { spawnSync } from 'node:child_process';

const ROOT = process.cwd();

const MUTANTS = [
  {
    id: 'M01',
    pkg: 'walkzzz/image.codec/codec',
    file: 'image.codec/codec/png_decode.mbt',
    find: '  if pa <= pb && pa <= pc {\n    a',
    replace: '  if pa <= pb && pa <= pc {\n    b',
    desc: 'PNG Paeth 预测选中 a 改为 b',
  },
  {
    id: 'M02',
    pkg: 'walkzzz/image.codec/codec',
    file: 'image.codec/codec/png_decode.mbt',
    find: '3 => (raw_byte + (a + b) / 2) & 0xFF',
    replace: '3 => (raw_byte + (a + b) / 3) & 0xFF',
    desc: 'PNG Average 滤波除数 2 → 3',
  },
  {
    id: 'M03',
    pkg: 'walkzzz/image.codec/codec',
    file: 'image.codec/codec/png_decode.mbt',
    find: '4 => (raw_byte + paeth_predict(a, b, c)) & 0xFF',
    replace: '4 => (raw_byte + paeth_predict(a, b, b)) & 0xFF',
    desc: 'PNG Paeth 第三参数 c → b',
  },
  {
    id: 'M04',
    pkg: 'walkzzz/image.codec/codec',
    file: 'image.codec/codec/bmp_decode.mbt',
    find: 'let row_size = (abs_width * bytes_per_pixel + 3) / 4 * 4',
    replace: 'let row_size = (abs_width * bytes_per_pixel + 3) / 2 * 2',
    desc: 'BMP 行对齐 4 字节 → 2 字节',
  },
  {
    id: 'M05',
    pkg: 'walkzzz/image.codec/codec',
    file: 'image.codec/codec/qoi_decode.mbt',
    find: 'if tag == 0xFE {',
    replace: 'if tag == 0xFD {',
    desc: 'QOI OP_RGB tag 0xFE → 0xFD',
  },
  {
    id: 'M06',
    pkg: 'walkzzz/image.codec/codec',
    file: 'image.codec/codec/qoi_decode.mbt',
    find: 'let dg = (tag & 0x3F) - 32',
    replace: 'let dg = (tag & 0x3F) - 31',
    desc: 'QOI LUMA 亮度差分基准 -32 → -31',
  },
  {
    id: 'M07',
    pkg: 'walkzzz/image.core/types',
    file: 'image.core/types/image_types.mbt',
    find: 'if width <= 0 || height <= 0 || channels <= 0 {',
    replace: 'if width < 0 || height <= 0 || channels <= 0 {',
    desc: 'check_dims 允许 width == 0',
  },
  {
    id: 'M08',
    pkg: 'walkzzz/image.core/types',
    file: 'image.core/types/image_types.mbt',
    find: 'if width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION {',
    replace: 'if width >= MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION {',
    desc: 'check_dims 上限 > 改 >=',
  },
  {
    id: 'M09',
    pkg: 'walkzzz/image.process/color',
    file: 'image.process/color/colormap.mbt',
    find: '(r * 299 + g * 587 + b * 114) / 1000',
    replace: '(r * 299 + g * 587 + b * 114) / 999',
    desc: '灰度 BT.601 除数 1000 → 999',
  },
  {
    id: 'M10',
    pkg: 'walkzzz/image.codec/lib',
    file: 'image.codec/lib/animation.mbt',
    find: 'if delays.length() != frames.length() {',
    replace: 'if false {',
    desc: 'encode_apng 去掉延迟长度校验',
  },
  {
    id: 'M11',
    pkg: 'walkzzz/image.codec/lib',
    file: 'image.codec/lib/region.mbt',
    find: '@types.ImageFormat::Bmp => @codec.decode_bmp_region(data, x, y, w, h)',
    replace: '@types.ImageFormat::Bmp => @codec.decode_qoi_region(data, x, y, w, h)',
    desc: 'decode_region BMP 分派到 QOI 解码器',
  },
  {
    id: 'M12',
    pkg: 'walkzzz/image.codec/lib',
    file: 'image.codec/lib/region.mbt',
    find: '"decode_region 暂只支持 PNG / BMP / QOI"',
    replace: '"decode_region: unsupported format"',
    desc: 'decode_region 不支持格式错误文案变化（应存活：仅文案）',
  },
];

function countOccurrences(s, sub) {
  return s.split(sub).length - 1;
}

function runTests(pkg) {
  const r = spawnSync(
    'moon',
    ['test', '-p', pkg, '--target', 'native'],
    { cwd: ROOT, encoding: 'utf8', shell: false },
  );
  const out = (r.stdout || '') + (r.stderr || '');
  const failedMatch = out.match(/failed:\s*(\d+)/);
  const totalMatch = out.match(/Total tests:\s*(\d+)/);
  const compiled = totalMatch !== null;
  const failed = failedMatch ? Number(failedMatch[1]) : null;
  return {
    compiled,
    failed,
    total: totalMatch ? Number(totalMatch[1]) : null,
    out,
    status: r.status,
  };
}

const results = [];
let baselineOk = true;
const pkgs = [...new Set(MUTANTS.map((m) => m.pkg))];
for (const pkg of pkgs) {
  const base = runTests(pkg);
  const ok = base.compiled && base.failed === 0;
  console.log(`baseline ${pkg}: ${ok ? 'pass' : 'FAIL'} (failed=${base.failed}/${base.total})`);
  if (!ok) baselineOk = false;
}
if (!baselineOk) {
  console.error('基线测试未通过，终止变异测试');
  process.exit(2);
}

for (const m of MUTANTS) {
  const path = `${ROOT}/${m.file}`;
  const original = fs.readFileSync(path, 'utf8');
  const occ = countOccurrences(original, m.find);
  if (occ !== 1) {
    results.push({ ...m, verdict: occ === 0 ? 'find_missing' : `find_ambiguous(${occ})` });
    console.log(`${m.id} ${m.verdict}: ${m.desc}`);
    continue;
  }
  fs.writeFileSync(path, original.replace(m.find, m.replace));
  let res;
  try {
    res = runTests(m.pkg);
  } finally {
    fs.writeFileSync(path, original);
  }
  let verdict;
  if (!res.compiled) verdict = 'compile_error';
  else if (res.failed === null) verdict = 'unknown';
  else if (res.failed > 0) verdict = 'killed';
  else verdict = 'survived';
  results.push({
    ...m,
    verdict,
    failed: res.failed,
    total: res.total,
  });
  console.log(`${m.id} ${verdict} (failed=${res.failed}/${res.total}) ${m.desc}`);
}

const killed = results.filter((r) => r.verdict === 'killed').length;
const scorable = results.filter((r) => ['killed', 'survived'].includes(r.verdict)).length;
const score = scorable ? (killed / scorable) * 100 : 0;
fs.mkdirSync(`${ROOT}/_build`, { recursive: true });
fs.writeFileSync(
  `${ROOT}/_build/mutation.json`,
  JSON.stringify({ killed, scorable, score, results }, null, 2),
);
console.log(`mutation score: ${killed}/${scorable} = ${score.toFixed(1)}%`);
process.exit(killed >= 9 ? 0 : 1);
