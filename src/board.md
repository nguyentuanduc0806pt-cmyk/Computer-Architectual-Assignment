# Tài liệu giải thích module `board.asm`

File nguồn: [board.asm](file:///d:/Computer%20Architectual%20Assignment/src/board.asm)  
Phụ trách: Thành viên A

---

## 1. Dữ liệu dùng chung (`.data`)
Giữ nguyên các biến toàn cục (`.globl`) đã khai báo trong khung sườn để các module khác (kể cả phần của Thành viên B) truy cập chung:
* `board` (`.space 32`): Mảng 32 byte đại diện cho 32 ô tối có thể chơi (`board[0..31]` tương ứng ô `1..32`).
* `current_player` (`.word 3`): Người chơi hiện tại (`3` = Đen đi trước, `1` = Đỏ).
* `start_square`, `destination`, `game_over`: Các biến trạng thái dùng chung trong vòng lặp game.

---

## 2. Thủ tục `init_board`
* **Mục đích:** Khởi tạo trạng thái bàn cờ ban đầu.
* **Cách thực hiện:**
  * Dùng vòng lặp biến đếm `$t1` chạy từ `0` đến `31`.
  * Nếu `$t1 < 12` (ô `1..12`): ghi giá trị `1` (Tốt Đỏ).
  * Nếu `12 <= $t1 < 20` (ô `13..20`): ghi giá trị `0` (Ô trống).
  * Nếu `20 <= $t1 < 32` (ô `21..32`): ghi giá trị `3` (Tốt Đen).
  * Lưu từng giá trị vào `board` bằng lệnh `sb` (store byte) vì mỗi ô chiếm 1 byte.
* **Thanh ghi sử dụng:** Chỉ dùng `$t0–$t3`, không gọi hàm con nên không cần dùng stack.

---

## 3. Thủ tục `print_board`
* **Mục đích:** In toàn bộ bàn cờ 8×8 ra terminal của MARS đúng định dạng yêu cầu của đề bài.
* **Cách thực hiện:**
  * Lưu `$ra` và `$s0, $s1, $s2` lên stack (`16` byte) vì thủ tục có gọi `coord_to_square`.
  * Dùng 2 vòng lặp lồng nhau: `$s0` là `row` (`0..7`), `$s1` là `col` (`0..7`), `$s2` giữ địa chỉ gốc của `board`.
  * Kiểm tra tính hợp lệ của ô bằng `(row + col) & 1`:
    * Bằng `0` → ô sáng (không chơi): in ký tự `'_'` (ASCII `95`).
    * Bằng `1` → ô tối (chơi được): gọi `coord_to_square($s0, $s1)` để lấy số ô `1..32` trong `$v0`, kiểm tra an toàn `1 <= $v0 <= 32` (tránh truy cập ngoài mảng nếu `coord_to_square` chưa hoàn thiện, khi đó in `'?'`), rồi đọc `board[$v0 - 1]` bằng `lb`.
  * Ánh xạ mã quân cờ sang ký tự:
    * `0` → `'0'` (ASCII `48`)
    * `1` → `'r'` (ASCII `114`)
    * `2` → `'R'` (ASCII `82`)
    * `3` → `'b'` (ASCII `98`)
    * `4` → `'B'` (ASCII `66`)
  * In khoảng trắng `' '` giữa các cột (`col < 7`) và xuống dòng `'\n'` sau mỗi hàng.
  * Khôi phục `$s0–$s2`, `$ra` và trả stack trước khi `jr $ra`.
