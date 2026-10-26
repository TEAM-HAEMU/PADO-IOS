// 화면 글자 명세 감사 — 화면 프레임 안 텍스트가 텍스트 스타일에 연결됐는지, 실제로 어떤 명세를 쓰는지 센다.
// Figma MCP/플러그인에서 실행. 결과로 tokens/code-only.json의 typography를 정한다.
const FRAMES = ['275:35023', '275:36297', '275:37692']; // J 2.1 지도 홈, 2.2 핀 미리보기, 2.3 재생
await figma.setCurrentPageAsync(await figma.getNodeByIdAsync('101:2'));
const result = {};
for (const id of FRAMES) {
  const frame = await figma.getNodeByIdAsync(id);
  const texts = frame.findAllWithCriteria({ types: ['TEXT'] });
  const specs = {};
  let styled = 0;
  for (const t of texts) {
    if (typeof t.textStyleId === 'string' && t.textStyleId) styled++;
    if (typeof t.fontName !== 'object') continue;
    const key = `${t.fontName.family} ${t.fontName.style} ${t.fontSize}/${t.lineHeight.unit === 'PIXELS' ? t.lineHeight.value : 'auto'} ${t.letterSpacing.value}%`;
    specs[key] = (specs[key] || 0) + 1;
  }
  result[frame.name] = { texts: texts.length, linkedToTextStyle: styled, specs };
}
return result;
