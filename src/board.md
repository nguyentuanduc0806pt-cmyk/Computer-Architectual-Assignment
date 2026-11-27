# Tài liệu giải thích module `board.asm`

File nguồn: [board.asm](./board.asm)  
Phụ trách: Thành viên A

---

## 1. Dữ liệu dùng chung (`.data`)
`board.asm` là file duy nhất khai báo các biến toàn cục (`.globl`) để toàn bộ các module khác cùng truy cập:
* `board` (`.space 32`): Mảng 32 byte lưu 32 ô tối chơi được (`board[0..31]` ứng với ô `1..32`).
* `current_player` (`.word 3`): Lượt hiện tại (`3` = Đen đi trước, `1` = Đỏ).
* `start_square`, `destination`, `game_over`: Ô xuất phát, ô đích và cờ kết thúc ván chơi.
* `player1_color` (`.word 3`): Màu mà Người chơi 1 chọn lúc bắt đầu (`3` = Đen, `1` = Đỏ). Mặc định là `3` để các bài test chạy độc lập không bị ảnh hưởng.
* `mandatory_capture` (`.word 1`): Chế độ bắt buộc ăn quân (`1` = luật chuẩn English Checkers bắt buộc ăn nếu có thể, `0` = chế độ Casual).

---

## 2. Thủ tục `init_board`
* **Mục đích:** Đặt bàn cờ về vị trí ban đầu.
* **Cách làm:**
  * Cho biến đếm `$t1` chạy từ `0` đến `31`:
    * `0..11` (ô `1..12`): ghi `1` (Tốt Đỏ).
    * `12..19` (ô `13..20`): ghi `0` (ô trống).
    * `20..31` (ô `21..32`): ghi `3` (Tốt Đen).
  * Ghi từng ô bằng `sb` vì mỗi ô chiếm 1 byte.
* **Thanh ghi:** Thủ tục lá, chỉ dùng `$t0–$t3`, không cần cấp stack.

---

## 3. Thủ tục `print_board`
* **Mục đích:** In bàn cờ 8×8 có khung kẻ ASCII, kèm bản đồ đánh số ô `1–32` ở bên phải, chú thích ký hiệu và số quân còn lại của mỗi bên.
* **Cách làm:**
  * Lưu `$ra` và `$s0–$s4` lên stack (`24` byte) vì có gọi `coord_to_square`.
  * `$s0` là `row` (`0..7`), `$s1` là `col` (`0..7`), `$s2` giữ địa chỉ đầu mảng `board`, `$s3` đếm số quân Đỏ và `$s4` đếm số quân Đen ngay trong lúc duyệt bàn cờ.
  * Với mỗi hàng `0..7`, in làm hai phần trên cùng một dòng:
    1. **Bên trái (bàn cờ thật):** kiểm tra `(row + col) & 1`:
       * Bằng `0` → ô sáng không chơi được, in `" . |"`.
       * Bằng `1` → gọi `coord_to_square(row, col)` lấy số ô `1..32`, đọc `board[square - 1]`, tăng biến đếm quân tương ứng và in ký tự: `0` (trống), `r`/`R` (Tốt/Vua Đỏ), `b`/`B` (Tốt/Vua Đen), hoặc `?` nếu mã lỗi.
    2. **Bên phải (bản đồ số ô 1–32):** in song song số ô `1..32` vào các ô tối (canh đều 3 ký tự mỗi ô) để người chơi tra nhanh số ô cần nhập.
  * Cuối bảng in chỉ số cột `0..7`, dòng chú thích (`b/B=Black  r/R=Red  0=Empty .=Light`) và dòng đếm quân còn lại (`Pieces remaining -> Black: X | Red: Y`).
  * Không thay đổi bất kỳ byte nào trong `board`; khôi phục đầy đủ `$s0–$s4`, `$ra` trước khi `jr $ra`.
