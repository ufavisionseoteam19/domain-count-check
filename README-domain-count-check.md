# domain-count-check

นับจำนวน request ต่อ **โดเมน** จาก access log ของทุกเว็บบนเซิร์ฟเวอร์ หาเว็บที่โดนยิงหนักสุด ด้วย Bash รันตรงจาก GitHub

จับ **เว็บที่โดน traffic / bot / โจมตี หนักที่สุด** — ตัวที่ทำให้ server load พุ่ง — แล้วจัดอันดับจากมากสุดไปน้อยสุด เซฟเป็นไฟล์ `.txt`

> รันอย่างเดียว 100% ไม่ลบ ไม่แก้ ไม่แตะไฟล์เว็บ — ปลอดภัย รันกี่ครั้งก็ได้

---

## ทำไมต้องมีตัวนี้

ตอน server load สูง คำถามแรกคือ "เว็บไหนเป็นตัวการ?" — บนเซิร์ฟเวอร์ที่มีเป็นพันเว็บ การไล่ดูทีละเว็บเป็นไปไม่ได้

สคริปต์นี้นับ request ของทุกเว็บในครั้งเดียว แล้วเรียงให้เห็นทันทีว่า:
- เว็บไหนโดนยิงเยอะสุด (ตัวที่กิน CPU)
- เว็บไหนโดน brute force มากสุด (ใส่ filter `wp-login.php`)
- โดเมนนั้นอยู่ user ไหน (ชื่อไฟล์บอก domain + เจ้าของ)

คู่กับ `ip-count-check` (หา "IP ไหนยิง") — ตัวนี้หา "เว็บไหนโดนยิง" ใช้ร่วมกันจะเห็นภาพครบ

---

## คุณสมบัติ

- นับ request ต่อโดเมนจากทุกเว็บ (`*ssl_log`) ในครั้งเดียว
- เรียงจากโดนยิงมากสุด → น้อยสุด อัตโนมัติ
- รับ filter เฉพาะ path ได้ เช่น `wp-login.php`, `xmlrpc.php`
- ตั้งจำนวน TOP ที่แสดงบนจอได้
- มี progress bar บอกความคืบหน้าทีละเว็บ (ไม่งงว่าค้าง)
- แสดงทั้ง domain และ user เจ้าของ
- เซฟผลเป็นไฟล์ `.txt` พร้อม timestamp
- เร็วมาก (ใช้ `wc -l` นับทั้งไฟล์ ไม่ต้องอ่านทีละบรรทัด)
- ไม่แตะไฟล์เว็บ ปลอดภัย รันซ้ำได้

---

## วิธีใช้

### รันตรงจาก GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/ufavisionseoteam19/domain-count-check/main/domain-count-check.sh | bash
```

### โหลดเก็บไว้ (แนะนำ — ใช้ filter/TOP ได้)

```bash
curl -fsSL https://raw.githubusercontent.com/ufavisionseoteam19/domain-count-check/main/domain-count-check.sh -o /root/domain-count-check.sh
chmod +x /root/domain-count-check.sh
/root/domain-count-check.sh
```

---

## ตัวอย่างการใช้งาน

```bash
# เว็บไหนโดนยิงเยอะสุด (ภาพรวม) — แสดง TOP 30
./domain-count-check.sh

# เว็บไหนโดน brute force มากสุด
./domain-count-check.sh wp-login.php

# เว็บไหนโดนยิง xmlrpc มากสุด แสดง TOP 50
./domain-count-check.sh xmlrpc.php 50

# แสดง TOP 100 (ภาพรวม) — argument แรกเว้นว่างด้วย ""
./domain-count-check.sh "" 100
```

> **รูปแบบ argument:** `./domain-count-check.sh [filter] [จำนวน TOP]`

---

## ตัวอย่างผลลัพธ์

```
domain (.user)                                     จำนวนครั้ง
-------------------------------------------------- ----------
superc4.com.y2026m01migrate                        45821
gamo88.org.y2026m05migrate                         38104
ufa9888.org.y2026m05migrate                        29512
...
```

ไฟล์เซฟที่: `/root/domain_count_<โหมด>_<วันที่>_<เวลา>.txt`

---

## การตั้งค่า

แก้ตัวแปรด้านบนของสคริปต์:

| ตัวแปร | ค่าเริ่มต้น | คำอธิบาย |
|---|---|---|
| `LOGDIR` | `/etc/apache2/logs/domlogs` | โฟลเดอร์ log (cPanel เก่าใช้ `/usr/local/apache/domlogs`) |
| `OUTDIR` | `/root` | โฟลเดอร์เก็บไฟล์ผลลัพธ์ |

---

## ใช้คู่กับ ip-count-check

| คำถาม | ใช้ตัวไหน |
|---|---|
| "IP ไหนยิงเยอะสุด?" | `ip-count-check` |
| "เว็บไหนโดนยิงเยอะสุด?" | `domain-count-check` (ตัวนี้) |
| "เว็บนี้โดนใครยิง?" | ทั้งสองตัว + เจาะ log เว็บนั้น |

---

## ข้อควรรู้

- ต้องรันด้วยสิทธิ์ที่อ่าน log ได้ (ปกติคือ `root`)
- 1 ไฟล์ log = 1 โดเมน → นับจำนวนบรรทัด = จำนวน request ของโดเมนนั้น
- เว็บที่ขึ้นอันดับสูงไม่ได้แปลว่า "ผิด" เสมอไป — อาจเป็นเว็บยอดนิยมที่มีคนเข้าจริง ต้องดู IP/User-Agent ประกอบ
- การแก้ที่ต้นเหตุ: ถ้าเว็บโดน bot ให้บล็อก User-Agent, ถ้าโดน brute force ให้ rate limit wp-login, ถ้า traffic จริงสูงให้ทำ cache

---

## License

ใช้ภายในทีมได้อย่างอิสระ
