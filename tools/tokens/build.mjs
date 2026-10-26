#!/usr/bin/env node
// 토큰 생성: tokens/figma-variables.json (+ code-only.json) → tokens/pado.tokens.json, Swift, React Native, CSS
//   npm run tokens            (기본 모드: J · 스카이 퓨어)
//   TOKENS_MODE="B · Deep" npm run tokens
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { DEFAULT_MODE, normalize, toCss, toSwift, toTypeScript } from './lib.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const read = p => JSON.parse(fs.readFileSync(path.join(root, p), 'utf8'));
const write = (p, s) => { fs.mkdirSync(path.dirname(path.join(root, p)), { recursive: true }); fs.writeFileSync(path.join(root, p), s); console.log('  ✓', p); };

const tokens = normalize(read('tokens/figma-variables.json'), { mode: process.env.TOKENS_MODE || DEFAULT_MODE, codeOnly: read('tokens/code-only.json') });
console.log(`[tokens] 모드 "${tokens.$meta.mode}" — 색 ${Object.keys(tokens.color).length}, 반경 ${Object.keys(tokens.radius).length}, 간격 ${Object.keys(tokens.spacing).length}, 글자 ${Object.keys(tokens.typography).length}`);
write('tokens/pado.tokens.json', JSON.stringify(tokens, null, 2) + '\n');
write('Packages/PADODesignSystem/Sources/PADODesignSystem/Tokens/PADOTokens.generated.swift', toSwift(tokens));
write('generated/react-native/tokens.ts', toTypeScript(tokens));
write('generated/web/tokens.css', toCss(tokens));
