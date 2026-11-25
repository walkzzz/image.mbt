// npm 包自测：只用 Node 标准库，不依赖 Pillow / 外部样本。
import assert from 'node:assert/strict';
import { info, convert, convertMeta, resize, resizeMeta, formats } from './index.mjs';

let passed = 0;
let failed = 0;

function check(name, fn) {
  try {
    fn();
    passed += 1;
    console.log(`  ok  ${name}`);
  } catch (err) {
    failed += 1;
    console.log(`  FAIL ${name}: ${err.message}`);
  }
}

function ppm(w, h) {
  const px = Buffer.alloc(w * h * 3);
  for (let i = 0; i < px.length; i++) px[i] = (i * 7 + 3) % 256;
  return Buffer.concat([Buffer.from(`P6\n${w} ${h}\n255\n`), px]);
}

const sig = (buf, n = 8) => buf.subarray(0, n).toString('hex');

check('info: PPM 4x3', () => {
  const r = info(ppm(4, 3));
  assert.equal(r.format, 'pnm');
  assert.equal(r.width, 4);
  assert.equal(r.height, 3);
  assert.equal(r.bytes, ppm(4, 3).length);
});

check('convert: PPM -> PNG', () => {
  const out = convert(ppm(4, 3), { format: 'png' });
  assert.equal(sig(out), '89504e470d0a1a0a');
  const r = info(out);
  assert.equal(r.format, 'png');
  assert.equal(r.width, 4);
  assert.equal(r.height, 3);
});

check('convert: PPM -> JPEG (q=90)', () => {
  const out = convert(ppm(32, 24), { format: 'jpeg', quality: 90 });
  assert.equal(sig(out, 3), 'ffd8ff');
  assert.equal(info(out).format, 'jpeg');
});

check('convert: PPM -> WebP', () => {
  const out = convert(ppm(16, 12), { format: 'webp' });
  assert.equal(out.subarray(0, 4).toString(), 'RIFF');
  assert.equal(out.subarray(8, 12).toString(), 'WEBP');
  assert.equal(info(out).format, 'webp');
});

check('convert: PPM -> QOI', () => {
  const out = convert(ppm(16, 12), { format: 'qoi' });
  assert.equal(out.subarray(0, 4).toString(), 'qoif');
  assert.equal(info(out).format, 'qoi');
});

check('convert: PPM -> BMP', () => {
  const out = convert(ppm(8, 8), { format: 'bmp' });
  assert.equal(out.subarray(0, 2).toString(), 'BM');
  assert.equal(info(out).format, 'bmp');
});

check('convert: best 选最小', () => {
  const out = convertMeta(ppm(16, 12), { format: 'best', quality: 90 });
  assert.ok(out.data.length > 0);
  assert.ok(['png', 'jpeg', 'webp', 'gif', 'qoi'].includes(out.format));
});

check('convertMeta: 元信息与输出一致', () => {
  const r = convertMeta(ppm(10, 5), { format: 'png' });
  assert.equal(r.width, 10);
  assert.equal(r.height, 5);
  assert.equal(r.channels, 3);
  assert.equal(info(r.data).width, 10);
});

check('resize: cover 32x24 -> 64x64', () => {
  const src = ppm(32, 24);
  const out = resize(src, { width: 64, height: 64, mode: 'cover', format: 'png' });
  const r = info(out);
  assert.equal(r.width, 64);
  assert.equal(r.height, 64);
});

check('resize: contain 32x24 -> 64x64 白底', () => {
  const out = resizeMeta(ppm(32, 24), {
    width: 64,
    height: 64,
    mode: 'contain',
    format: 'png',
  });
  assert.equal(out.width, 64);
  assert.equal(out.height, 64);
});

check('resize: 参数校验', () => {
  assert.throws(() => resize(ppm(4, 3), { width: 0, height: 3 }), TypeError);
});

check('错误输入抛带 code 的错', () => {
  assert.throws(
    () => info(Buffer.from('definitely not an image')),
    (err) => {
      assert.equal(err.code, 'decode/unsupported_format');
      assert.ok(err.message.length > 0);
      assert.ok(err.hint.length > 0);
      return true;
    },
  );
});

check('空输入直接拒绝', () => {
  assert.throws(() => convert(Buffer.alloc(0)), TypeError);
});

check('大图触发内存增长（1000x1000 PPM -> PNG）', () => {
  const out = convert(ppm(1000, 1000), { format: 'png', quality: 90 });
  const r = info(out);
  assert.equal(r.width, 1000);
  assert.equal(r.height, 1000);
  assert.ok(out.length > 1000);
});

check('formats 列表', () => {
  for (const f of ['png', 'jpeg', 'webp', 'gif', 'bmp', 'qoi', 'pnm', 'tga', 'best']) {
    assert.ok(formats.includes(f), `缺少 ${f}`);
  }
});

console.log(`\n${passed}/${passed + failed} passed`);
if (failed > 0) process.exit(1);
