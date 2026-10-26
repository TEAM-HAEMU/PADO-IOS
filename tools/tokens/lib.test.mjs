import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { camel, colorDrift, letterSpacingPt, lineHeightPt, normalize, parseHex, toCss, toSwift, typographyMismatches, weightOf } from './lib.mjs';

const raw = JSON.parse(fs.readFileSync(new URL('../../tokens/figma-variables.json', import.meta.url), 'utf8'));

test('이름 변환', () => {
  assert.equal(camel('color/card-2'), 'card2');
  assert.equal(camel('color/primary-soft'), 'primarySoft');
  assert.equal(camel('text/Body Strong'), 'bodyStrong');
  assert.equal(camel('text/Number Large'), 'numberLarge');
});

test('글꼴 굵기', () => {
  assert.equal(weightOf('SemiBold'), 600);
  assert.equal(weightOf('Semi Bold'), 600);
  assert.throws(() => weightOf('Heavy'));
});

test('색 변환', () => {
  assert.deepEqual(parseHex('#FFFFFF'), { r: 1, g: 1, b: 1, a: 1 });
  assert.equal(parseHex('#4F97F280').a, 128 / 255);
  assert.throws(() => parseHex('blue'));
});

test('자간: Figma 퍼센트는 글자 크기 기준', () => {
  assert.equal(letterSpacingPt({ unit: 'PERCENT', value: -2 }, 22), -0.44);
  assert.equal(letterSpacingPt({ unit: 'PIXELS', value: 1.5 }, 22), 1.5);
  assert.equal(letterSpacingPt({ unit: 'PERCENT', value: 0 }, 22), 0);
});

test('줄 높이: AUTO는 null', () => {
  assert.equal(lineHeightPt({ unit: 'AUTO' }, 30), null);
  assert.equal(lineHeightPt({ unit: 'PIXELS', value: 30 }, 22), 30);
  assert.equal(lineHeightPt({ unit: 'PERCENT', value: 150 }, 16), 24);
});

test('실제 Figma 원본 → J 모드 토큰', () => {
  const t = normalize(raw, { codeOnly: { spacing: { md: 12 } } });
  assert.equal(t.color.page.$value, '#FFFFFF');
  assert.equal(t.color.primary.$value, '#4F97F2');
  assert.equal(t.radius.lg.$value, 22);
  assert.deepEqual(t.typography.title.$value, { fontFamily: 'Pretendard', fontWeight: 700, fontSize: 22, lineHeight: 30, letterSpacing: -0.44 });
  assert.equal(t.spacing.md.$extensions['pado.codeOnly'], true);
});

test('없는 모드는 이유와 함께 실패', () => {
  assert.throws(() => normalize(raw, { mode: 'Z' }), /모드 "Z" 없음/);
});

test('생성 코드에 모든 토큰이 들어간다', () => {
  const t = normalize(raw);
  const swift = toSwift(t), css = toCss(t);
  for (const k of Object.keys(t.color)) { assert.match(swift, new RegExp(`static let ${k} =`)); }
  assert.match(css, /--pado-color-primary-soft: #E8F2FE;/);
  assert.match(css, /--pado-radius-pill: 999px;/);
});

test('색 비교: 다른 값과 상대에만 있는 이름을 찾는다', () => {
  const t = normalize(raw);
  const { diffs, onlyOther } = colorDrift(t, "export const colors = { page: '#FFFFFF', ink3: '#647493', kakao: '#FEE500' }");
  assert.deepEqual(diffs, [{ key: 'ink3', token: '#7787A5', other: '#647493' }]);
  assert.deepEqual(onlyOther, ['kakao']);
});

test('화면 실측 글자 명세가 Figma 스타일을 덮고, 차이를 보고한다', () => {
  const t = normalize(raw, { codeOnly: { typography: { body: { fontFamily: 'Pretendard', fontWeight: 400, fontSize: 15, lineHeight: 22, letterSpacing: -0.15 } } } });
  assert.equal(t.typography.body.$value.fontSize, 15);
  assert.equal(t.typography.body.$extensions['pado.figmaStyle'].fontSize, 16);
  assert.deepEqual(typographyMismatches(t), ['body: Figma 16/22 400 -0.16pt → 화면 15/22 400 -0.15pt']);
  assert.equal(t.typography.title.$extensions, undefined); // 덮지 않은 스타일은 Figma 그대로
});
