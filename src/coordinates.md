# Tài liệu giải thích module `coordinates.asm`

File nguồn: [coordinates.asm](file:///d:/Computer%20Architectual%20Assignment/src/coordinates.asm)  
Phụ trách: Thành viên A

---

## 1. Thủ tục `square_to_coord`
* **Mục đích:** Chuyển số ô `1..32` (trong `$a0`) sang tọa độ zero-based `(row, col)` (`$v0, $v1`).
* **Kiểm tra đầu vào:**
  * Nếu `$a0 < 1` hoặc `$a0 > 32` → nhảy tới `s2c_invalid`, trả về `$v0 = -1`, `$v1 = -1`.
* **Công thức & Lệnh MIPS (dùng dịch bit cho tối ưu):**
  * `idx = $a0 - 1` (`addi`)
  * `row = idx / 4` → `srl $v0, $t0, 2`
  * `rem = idx % 4` → `andi $t1, $t0, 3`
  * `row_parity = row % 2` → `andi $t2, $v0, 1`
  * `col = 2 * rem + 1 - row_parity` → `sll` 1 bit, `+ 1`, rồi `subu` cho `row_parity`.
* **Thanh ghi sử dụng:** `$t0–$t2`, không gọi hàm con nên không cần stack.

---

## 2. Thủ tục `coord_to_square`
* **Mục đích:** Chuyển tọa độ `(row, col)` (`$a0, $a1`) sang số ô `1..32` (`$v0`), trả về `-1` nếu không hợp lệ.
* **Kiểm tra đầu vào:**
  * `0 <= row <= 7` (`bltz` và `slti ..., 8`)
  * `0 <= col <= 7` (`bltz` và `slti ..., 8`)
  * Ô tối chơi được: `(row + col) & 1 == 1` (nếu `== 0` là ô sáng không chơi được → trả về `-1`).
* **Công thức & Lệnh MIPS:**
  * `square = 4 * row + (col / 2) + 1` → `(row << 2) + (col >> 1) + 1`.
* **Thanh ghi sử dụng:** `$t0–$t1`, không gọi hàm con.
