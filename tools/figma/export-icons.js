// Figma 아이콘 컴포넌트 → SVG 내보내기 (Figma MCP/플러그인에서 실행, 결과 JSON을 tools/figma/out/icons.json에 저장)
// 그다음 `node tools/figma/icons-to-assets.mjs` 로 SwiftUI 에셋 카탈로그를 만든다.
const ids = { music: '13:90', pin: '13:57', pause: '13:32', play: '13:28', heart: '13:35', heartFill: '105:11213', comment: '13:38', external: '13:41', more: '13:62', chevronDown: '13:53', chevronLeft: '13:47', map: '13:19', playlist: '13:85', plus: '13:25', bell: '13:11', user: '13:15', close: '13:68', locate: '13:73', vote: '13:80', spotify: '14:8', appleMusic: '14:12', youtubeMusic: '14:17' };
const out = {};
for (const [k, id] of Object.entries(ids)) out[k] = await (await figma.getNodeByIdAsync(id)).exportAsync({ format: 'SVG_STRING' });
return JSON.stringify(out);
