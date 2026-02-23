"""IC Markets 전체 심볼 목록을 카테고리별 마크다운 표로 변환"""
import json
import os
from collections import defaultdict
from datetime import datetime

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(script_dir, "..", "Files", "ic_markets_symbols.json")
    json_path = os.path.normpath(json_path)

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # 카테고리 → 서브카테고리 → 심볼 정리
    cat_sub = defaultdict(lambda: defaultdict(list))
    for s in data:
        cat = s["category"] or "기타"
        sub = s["subcategory"] or "-"
        cat_sub[cat][sub].append(s)

    # 카테고리 순서 (개수 내림차순)
    cat_order = sorted(cat_sub.keys(), key=lambda c: -sum(len(v) for v in cat_sub[c].values()))

    lines = []
    lines.append(f"# IC Markets 브로커 금융상품 전체 목록")
    lines.append(f"\n> 조회 시각: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lines.append(f"> 브로커: Raw Trading Ltd (IC Markets) | 서버: ICMarketsSC-Demo")
    lines.append(f"> **총 {len(data):,}개 금융상품**\n")

    lines.append("## 카테고리별 요약\n")
    lines.append("| 카테고리 | 심볼 수 |")
    lines.append("|:---|---:|")
    for cat in cat_order:
        cnt = sum(len(v) for v in cat_sub[cat].values())
        lines.append(f"| {cat} | {cnt:,}개 |")
    lines.append(f"| **합계** | **{len(data):,}개** |")

    lines.append("\n---\n")

    # 각 카테고리별 표
    for cat in cat_order:
        total = sum(len(v) for v in cat_sub[cat].values())
        lines.append(f"\n## {cat} ({total:,}개)\n")

        # 서브카테고리별로 묶어서 표 출력
        for sub in sorted(cat_sub[cat].keys()):
            symbols_in_sub = cat_sub[cat][sub]
            if sub != "-":
                lines.append(f"\n### {sub} ({len(symbols_in_sub)}개)\n")

            lines.append("| # | 심볼 | 설명 | 기준통화 | 결제통화 | 소수점 |")
            lines.append("|---:|:---|:---|:---:|:---:|:---:|")
            for i, s in enumerate(sorted(symbols_in_sub, key=lambda x: x["symbol"]), 1):
                desc = s["description"].replace("|", "\\|")
                lines.append(f"| {i} | `{s['symbol']}` | {desc} | {s['currency_base']} | {s['currency_profit']} | {s['digits']} |")

    md_content = "\n".join(lines)

    out_path = os.path.join(script_dir, "..", "Files", "ic_markets_symbols.md")
    out_path = os.path.normpath(out_path)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(md_content)

    print(f"마크다운 변환 완료: {out_path}")
    print(f"파일 크기: {os.path.getsize(out_path):,} bytes")

if __name__ == "__main__":
    main()
