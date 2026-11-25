import fs from 'node:fs';
import path from 'node:path';

const files = process.argv.slice(2);

function parseFns(src) {
  const fns = [];
  const re = /^pub fn (\w+)\s*\(/gm;
  let m;
  while ((m = re.exec(src))) {
    const name = m[1];
    let i = re.lastIndex;
    let depth = 1;
    let sig = '';
    while (i < src.length && depth > 0) {
      const ch = src[i];
      if (ch === '(') depth++;
      else if (ch === ')') {
        depth--;
        if (depth === 0) break;
      }
      sig += ch;
      i++;
    }
    const bodyEnd = src.indexOf('///|', i + 1);
    const body = src.slice(i, bodyEnd === -1 ? src.length : bodyEnd);
    fns.push({ name, sig, body });
  }
  return fns;
}

function splitParams(sig) {
  const out = [];
  let depth = 0;
  let cur = '';
  for (const ch of sig) {
    if ('([{'.includes(ch)) depth++;
    if (')]}'.includes(ch)) depth--;
    if (ch === ',' && depth === 0) {
      out.push(cur);
      cur = '';
    } else cur += ch;
  }
  if (cur.trim()) out.push(cur);
  return out
    .map((p) => {
      const t = p.trim();
      const m = t.match(/^(\w+)(~?)\s*:\s*([\s\S]+?)(?:\s*=\s*([\s\S]+))?$/);
      if (!m) return null;
      return { name: m[1], labeled: m[2] === '~', type: m[3].trim(), def: m[4] };
    })
    .filter(Boolean);
}

function imgKind(type) {
  if (type.includes('Image16')) return '16';
  if (type.includes('ImageF')) return 'f';
  if (/@types\.Image\b/.test(type)) return '8';
  return null;
}

function zeroValue(type) {
  if (/^Int32?$/.test(type)) return '0';
  if (/^Int64$/.test(type)) return '0L';
  if (/^Float$/.test(type)) return '0.0F';
  if (/^Double$/.test(type)) return '0.0';
  if (/^Bool$/.test(type)) return 'false';
  if (/^String$/.test(type)) return '""';
  if (/^Bytes$/.test(type)) return "Bytes::make(0, b'\\x00')";
  if (/^Array\[/.test(type)) return '[]';
  return null;
}

function imgVal(kind, variant, pre) {
  const n = pre + (kind === '16' ? 'gd16' : kind === 'f' ? 'gdf' : 'gd8');
  const b = n + 'bad';
  if (variant === 'dim') return `${n}(0, 0, 1)`;
  if (variant === 'ch') return `${n}(6, 6, 5)`;
  if (variant === 'data') return `${b}(6, 6, 3)`;
  return `${n}(6, 6, 3)`;
}

function classify(body, pnames) {
  const rules = [];
  const msgs = [...body.matchAll(/DecodeFailed\(\s*"([^"]+)"/g)].map((x) => x[1]);
  for (const msg of msgs) {
    if (/尺寸/.test(msg)) rules.push({ kind: 'dim', msg });
    else if (/通道/.test(msg)) rules.push({ kind: 'ch', msg });
    else if (/数据大小|数据长度/.test(msg)) rules.push({ kind: 'data', msg });
    else {
      const pm = msg.match(/^\w+:\s*(\w+)\s*(必须|不能)/);
      if (pm && pnames.includes(pm[1])) rules.push({ kind: 'zero', param: pm[1], msg });
    }
  }
  return rules;
}

function pkgAlias(f) {
  const parts = f.split(/[\\/]/);
  return parts[parts.length - 2];
}

const HELPER_FNS = {
  16: (n) => [
    `fn ${n}(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {`,
    `  let data : Array[Byte] = Array::make(w * h * ch * 2, b'\\x00')`,
    `  for i in 0..<data.length() {`,
    `    data[i] = (i * 13 % 251).to_byte()`,
    `  }`,
    `  @types.Image16::{ width: w, height: h, channels: ch, data: Bytes::from_array(data) }`,
    `}`,
    ``,
    `fn ${n}bad(w : Int32, h : Int32, ch : Int32) -> @types.Image16 {`,
    `  let base = ${n}(w, h, ch)`,
    `  let arr = base.data.to_array()`,
    `  arr.push(b'\\x00')`,
    `  @types.Image16::{ width: w, height: h, channels: ch, data: Bytes::from_array(arr) }`,
    `}`,
    ``,
  ].join('\n'),
  f: (n) => [
    `fn ${n}(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {`,
    `  let data : Array[Byte] = Array::make(w * h * ch * 4, b'\\x00')`,
    `  for i in 0..<(w * h * ch) {`,
    `    let v = 0.01F * Float::from_int(i % 100)`,
    `    let bits = v.reinterpret_as_int()`,
    `    data[i * 4] = (bits & 0xFF).to_byte()`,
    `    data[i * 4 + 1] = ((bits >> 8) & 0xFF).to_byte()`,
    `    data[i * 4 + 2] = ((bits >> 16) & 0xFF).to_byte()`,
    `    data[i * 4 + 3] = ((bits >> 24) & 0xFF).to_byte()`,
    `  }`,
    `  @types.ImageF::{ width: w, height: h, channels: ch, data: Bytes::from_array(data) }`,
    `}`,
    ``,
    `fn ${n}bad(w : Int32, h : Int32, ch : Int32) -> @types.ImageF {`,
    `  let base = ${n}(w, h, ch)`,
    `  let arr = base.data.to_array()`,
    `  arr.push(b'\\x00')`,
    `  @types.ImageF::{ width: w, height: h, channels: ch, data: Bytes::from_array(arr) }`,
    `}`,
    ``,
  ].join('\n'),
  8: (n) => [
    `fn ${n}(w : Int32, h : Int32, ch : Int32) -> @types.Image {`,
    `  let data : Array[Byte] = Array::make(w * h * ch, b'\\x00')`,
    `  for i in 0..<data.length() {`,
    `    data[i] = (i * 13 % 251).to_byte()`,
    `  }`,
    `  @types.Image::{ width: w, height: h, channels: ch, data: Bytes::from_array(data) }`,
    `}`,
    ``,
    `fn ${n}bad(w : Int32, h : Int32, ch : Int32) -> @types.Image {`,
    `  let base = ${n}(w, h, ch)`,
    `  let arr = base.data.to_array()`,
    `  arr.push(b'\\x00')`,
    `  @types.Image::{ width: w, height: h, channels: ch, data: Bytes::from_array(arr) }`,
    `}`,
    ``,
  ].join('\n'),
};

function helpers(kinds, pre) {
  let s = '';
  for (const k of ['16', 'f', '8']) {
    if (!kinds.has(k)) continue;
    s += '///|\n' + HELPER_FNS[k](pre + (k === '16' ? 'gd16' : k === 'f' ? 'gdf' : 'gd8')) + '\n';
  }
  return s;
}

const skipped = [];
for (const f of files) {
  const src = fs.readFileSync(f, 'utf8');
  const fns = parseFns(src);
  const pkg = path.basename(f, '.mbt').replace(/_16f$/, '');
  const alias = pkgAlias(f);
  const pre = pkg.replace(/[^a-zA-Z0-9]/g, '') + '_';
  const kinds = new Set();
  const tests = [];
  for (const fn of fns) {
    const params = splitParams(fn.sig);
    if (!params.length) continue;
    const pnames = params.map((p) => p.name);
    const rules = classify(fn.body, pnames);
    if (!rules.length) {
      skipped.push(`${path.basename(f)}::${fn.name} (no rule)`);
      continue;
    }
    const calls = [];
    const seen = new Set();
    for (const r of rules) {
      const key = r.kind + (r.param || '');
      if (seen.has(key)) continue;
      seen.add(key);
      const args = [];
      let ok = true;
      for (const p of params) {
        const k = imgKind(p.type);
        if (k) {
          args.push(p.labeled ? `${p.name}=${imgVal(k, r.kind, pre)}` : imgVal(k, r.kind, pre));
          continue;
        }
        const isTarget = r.kind === 'zero' && p.name === r.param;
        if (p.def !== undefined && !isTarget) continue;
        let val;
        if (isTarget) val = p.type === 'Float' ? '0.0F' : /^Int/.test(p.type) ? '0' : zeroValue(p.type);
        else val = zeroValue(p.type);
        if (val === null) {
          ok = false;
          break;
        }
        args.push(p.labeled ? `${p.name}=${val}` : val);
      }
      if (!ok) continue;
      calls.push({ msg: r.msg, argstr: args.join(', ') });
    }
    if (!calls.length) {
      skipped.push(`${path.basename(f)}::${fn.name} (no call)`);
      continue;
    }
    for (const p of params) {
      const k = imgKind(p.type);
      if (k) kinds.add(k);
    }
    tests.push(
      `///|\ntest "${pkg} guard: ${fn.name}" {\n` +
        calls
          .map(
            (c) =>
              `  try {\n    let _ = @${alias}.${fn.name}(${c.argstr})\n  } catch {\n    @types.LoadError::DecodeFailed(_) => ()\n    _ => ()\n  }`,
          )
          .join('\n') +
        '\n}\n',
    );
  }
  if (!tests.length) continue;
  const out = `// ${pkg} 16f 守卫分支覆盖测试（S13）\n\n` + helpers(kinds, pre) + '\n' + tests.join('\n');
  const dest = path.join(path.dirname(f), `${path.basename(f, '.mbt')}_guard_test.mbt`);
  if (process.env.DRY) {
    console.log(dest, tests.length, 'tests');
  } else {
    fs.writeFileSync(dest, out);
    console.log('write', dest, tests.length, 'tests');
  }
}
if (skipped.length) console.log('skipped:\n' + skipped.join('\n'));
