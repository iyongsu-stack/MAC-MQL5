"""IC Markets 전체 금융상품(심볼) 목록 조회 및 저장"""
import MetaTrader5 as mt5
import json
import os
from collections import Counter

def main():
    if not mt5.initialize():
        print(f"MT5 초기화 실패: {mt5.last_error()}")
        return

    symbols = mt5.symbols_get()
    print(f"총 심볼 수: {len(symbols)}")

    data = []
    for s in symbols:
        path_parts = s.path.replace("\\", "/").split("/")
        category = path_parts[0] if path_parts else ""
        subcategory = path_parts[1] if len(path_parts) > 1 else ""
        data.append({
            "symbol": s.name,
            "description": s.description,
            "category": category,
            "subcategory": subcategory,
            "path": s.path,
            "currency_base": s.currency_base,
            "currency_profit": s.currency_profit,
            "currency_margin": s.currency_margin,
            "digits": s.digits,
            "spread": s.spread,
            "visible": s.visible,
        })

    # 카테고리별 집계
    cats = Counter(d["category"] for d in data)
    print("\n=== 카테고리별 집계 ===")
    for k, v in sorted(cats.items(), key=lambda x: -x[1]):
        print(f"  {k}: {v}개")

    # JSON 저장
    script_dir = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(script_dir, "..", "Files", "ic_markets_symbols.json")
    out_path = os.path.normpath(out_path)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\n저장 완료: {out_path}")
    mt5.shutdown()

if __name__ == "__main__":
    main()
