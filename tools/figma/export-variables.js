// Figma 변수·텍스트 스타일 내보내기 — Figma 플러그인 콘솔이나 Figma MCP(use_figma)에서 실행한다.
// 결과 JSON을 tokens/figma-variables.json에 그대로 저장하고 `npm run tokens` 로 코드를 만든다.
// 파일: PADO (y6lbJzKDLdJA73qvs6kkQM), 컬렉션: "PADO Theme"
const toHex = c => '#' + [c.r, c.g, c.b].map(x => Math.round(x * 255).toString(16).padStart(2, '0')).join('').toUpperCase()
  + (c.a !== undefined && c.a < 1 ? Math.round(c.a * 255).toString(16).padStart(2, '0').toUpperCase() : '');

const collections = [];
for (const c of await figma.variables.getLocalVariableCollectionsAsync()) {
  const variables = [];
  for (const id of c.variableIds) {
    const v = await figma.variables.getVariableByIdAsync(id);
    if (!v) continue;
    const values = {};
    for (const m of c.modes) {
      const raw = v.valuesByMode[m.modeId];
      values[m.name] = raw && typeof raw === 'object' && 'r' in raw ? toHex(raw)
        : raw && typeof raw === 'object' && raw.type === 'VARIABLE_ALIAS' ? { alias: raw.id }
        : raw;
    }
    variables.push({ name: v.name, type: v.resolvedType, scopes: v.scopes, values });
  }
  collections.push({ name: c.name, modes: c.modes.map(m => m.name), variables });
}
const textStyles = (await figma.getLocalTextStylesAsync()).map(s => ({
  name: s.name, fontFamily: s.fontName.family, fontStyle: s.fontName.style, fontSize: s.fontSize,
  lineHeight: s.lineHeight, letterSpacing: s.letterSpacing,
}));
return { source: { fileKey: figma.fileKey ?? 'y6lbJzKDLdJA73qvs6kkQM', exportedAt: new Date().toISOString() }, collections, textStyles };
