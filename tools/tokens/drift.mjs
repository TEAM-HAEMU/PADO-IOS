#!/usr/bin/env node
// 토큰과 다른 코드베이스의 색 값 비교 — 어긋난 값을 표로 보여준다 (CI에서는 --fail 로 실패 처리)
//   node tools/tokens/drift.mjs ../PADO-CLIENT/src/theme/tokens.ts [--fail]
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { colorDrift } from './lib.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const [target, flag] = process.argv.slice(2);
if (!target) { console.error('사용법: node tools/tokens/drift.mjs <비교할 파일> [--fail]'); process.exit(2); }
const tokens = JSON.parse(fs.readFileSync(path.join(root, 'tokens/pado.tokens.json'), 'utf8'));
const { diffs, onlyOther } = colorDrift(tokens, fs.readFileSync(target, 'utf8'));
console.log(`## 토큰 ↔ ${path.basename(target)} 색 비교 (Figma 모드: ${tokens.$meta.mode})\n`);
if (!diffs.length) console.log('값이 다른 색 없음');
else {
  console.log('| 토큰 | Figma | 비교 대상 |\n|---|---|---|');
  for (const d of diffs) console.log(`| ${d.key} | ${d.token} | ${d.other} |`);
}
if (onlyOther.length) console.log(`\n비교 대상에만 있는 이름: ${onlyOther.join(', ')}`);
if (flag === '--fail' && diffs.length) process.exit(1);
