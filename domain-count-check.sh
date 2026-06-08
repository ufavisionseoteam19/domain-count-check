#!/bin/bash
# ============================================================
# domain-count-check.sh  (v2 - มี EXCLUDE กรองเครื่องมือลูกค้า)
# นับจำนวน request ต่อ "โดเมน" จาก access log ทุกเว็บบนเซิร์ฟเวอร์
# เรียงจากโดนยิงมากสุด -> น้อยสุด -> เซฟเป็นไฟล์ .txt
#
# v2: เพิ่ม EXCLUDE = ไม่นับ request ของเครื่องมือลูกค้า (เช่น VisionCheck)
# ============================================================

# ---------- ตั้งค่า ----------
LOGDIR="/etc/apache2/logs/domlogs"        # โฟลเดอร์ log
OUTDIR="/root"                            # โฟลเดอร์เก็บผลลัพธ์
FILTER="${1:-}"                           # คำกรอง เช่น wp-login.php
TOPN="${2:-30}"                           # แสดง TOP กี่อันดับบนจอ
EXCLUDE="VisionCheck"                     # ไม่นับเครื่องมือลูกค้า (คั่นหลายตัวด้วย |)
# --------------------------------

if [ -z "$FILTER" ]; then TAG="all"; else TAG=$(echo "$FILTER" | tr -cd '[:alnum:]'); fi
OUT="$OUTDIR/domain_count_${TAG}.txt"
TMP=$(mktemp /tmp/domcount.XXXXXX)
trap 'rm -f "$TMP"' EXIT

if [ ! -d "$LOGDIR" ]; then
  echo "ไม่พบโฟลเดอร์ log: $LOGDIR"
  echo "   cPanel เก่าลองใช้: /usr/local/apache/domlogs"
  exit 1
fi

shopt -s nullglob
FILES=("$LOGDIR"/*ssl_log)
TOTAL=${#FILES[@]}
if [ "$TOTAL" -eq 0 ]; then echo "ไม่พบไฟล์ log ใน $LOGDIR"; exit 1; fi

echo "============================================"
echo " Domain Count Check (v2)"
echo "============================================"
if [ -z "$FILTER" ]; then echo " โหมด    : นับทุก request"
else echo " โหมด    : กรองเฉพาะ \"$FILTER\""; fi
if [ -n "$EXCLUDE" ]; then echo " ไม่นับ   : $EXCLUDE (เครื่องมือลูกค้า)"; fi
echo " Log dir : $LOGDIR"
echo " โดเมน    : $TOTAL เว็บ"
echo "============================================"
echo ""

i=0
for f in "${FILES[@]}"; do
  i=$((i+1))
  domain=$(basename "$f" | sed 's/-ssl_log$//; s/\.cp$//')

  # นับจำนวน request (ตัด EXCLUDE ออก)
  if [ -n "$EXCLUDE" ]; then
    if [ -z "$FILTER" ]; then
      count=$(grep -vcE "$EXCLUDE" "$f" 2>/dev/null)
    else
      count=$(grep "$FILTER" "$f" 2>/dev/null | grep -vcE "$EXCLUDE")
    fi
  else
    if [ -z "$FILTER" ]; then
      count=$(wc -l < "$f" 2>/dev/null)
    else
      count=$(grep -c "$FILTER" "$f" 2>/dev/null)
    fi
  fi
  [ -z "$count" ] && count=0
  [ "$count" -gt 0 ] && echo "$count $domain" >> "$TMP"

  pct=$(( i * 100 / TOTAL )); filled=$(( pct / 5 ))
  bar=""; e=""
  j=0; while [ $j -lt $filled ]; do bar="$bar#"; j=$((j+1)); done
  j=0; while [ $j -lt $((20-filled)) ]; do e="$e."; j=$((j+1)); done
  printf "\r[%s%s] %3d%%  (%d/%d) %-30.30s" "$bar" "$e" "$pct" "$i" "$TOTAL" "$domain"
done

echo ""; echo ""
echo "กำลังจัดอันดับโดเมน..."

sort -nr "$TMP" \
| awk 'BEGIN {
         printf "%-50s %s\n", "domain (.user)", "จำนวนครั้ง"
         printf "%-50s %s\n", "--------------------------------------------------", "----------"
       }
       { printf "%-50s %s\n", $2, $1 }' > "$OUT"

TOTAL_DOM=$(grep -cE '[0-9]+$' "$OUT")
TOTAL_REQ=$(awk '{s+=$1} END{print s}' "$TMP")

echo ""
echo "============================================"
echo " เสร็จแล้ว (ไม่รวมเครื่องมือลูกค้า: ${EXCLUDE:-ไม่มี})"
echo " ไฟล์ผลลัพธ์ : $OUT"
echo " โดเมนที่มี request : $TOTAL_DOM"
echo " request รวม        : $TOTAL_REQ"
echo "============================================"
echo ""
echo "===== TOP $TOPN โดเมนที่โดนยิงเยอะสุด (ไม่รวมลูกค้า) ====="
head -$((TOPN+2)) "$OUT"
echo ""
echo "ดูทั้งหมด: cat $OUT"
