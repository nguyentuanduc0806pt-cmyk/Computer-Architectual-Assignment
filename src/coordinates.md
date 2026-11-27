# Tài liệu giải thích module `coordinates.asm`

File nguồn: [coordinates.asm](./coordinates.asm)  
Phụ trách: Thành viên A

---

## 1. Thủ tục `square_to_coord`
* **Mục đích:** Chuyển số ô (`1..num_squares`, tức `1..32` với 8×8 hoặc `1..50` với 10×10) trong `$a0` sang tọa độ zero-based `(row, col)` (`$v0, $v1`).
* **Kiểm tra đầu vào:**
  * Đọc `num_squares` (`32` hoặc `50`). Nếu `$a0 < 1` hoặc `$a0 > num_squares` → trả về `$v0 = -1`, `$v1 = -1`.
* **Công thức & Lệnh MIPS:**
  * Đọc `squares_per_row` (`4` cho 8×8, `5` cho 10×10).
  * `idx = $a0 - 1`
  * `div $t0, $t4` → `row = mflo` (`idx / squares_per_row`), `rem = mfhi` (`idx % squares_per_row`).
  * `row_parity = row & 1`
  * `col = 2 * rem + 1 - row_parity`
* **Thanh ghi sử dụng:** `$t0–$t4`, thủ tục lá (không cần stack).

---

## 2. Thủ tục `coord_to_square`
* **Mục đích:** Chuyển tọa độ `(row, col)` (`$a0, $a1`) sang số ô `1..num_squares` (`$v0`), trả về `-1` nếu nằm ngoài bàn cờ hoặc là ô sáng.
* **Kiểm tra đầu vào:**
  * Đọc `board_dim` (`8` hoặc `10`): kiểm tra `0 <= row < board_dim` và `0 <= col < board_dim`.
  * Kiểm tra ô tối chơi được: `(row + col) & 1 == 1`.
* **Công thức & Lệnh MIPS:**
  * Đọc `squares_per_row` (`4` hoặc `5`).
  * `square = row * squares_per_row + (col >> 1) + 1` (dùng lệnh `mul` để tương thích cả 8×8 và 10×10).
* **Thanh ghi sử dụng:** `$t0–$t4`, thủ tục lá (không cần stack).
