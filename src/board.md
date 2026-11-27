# Tài liệu giải thích module `board.asm`

File nguồn: [board.asm](./board.asm)  
Phụ trách: Thành viên A

---

## 1. Dữ liệu dùng chung (`.data`)
`board.asm` là file duy nhất khai báo các biến toàn cục (`.globl`) để toàn bộ các module khác cùng truy cập:
* `board` (`.space 50`): Mảng 50 byte lưu tối đa 50 ô tối chơi được (`board[0..31]` cho luật Anh-Mỹ 8×8, `board[0..49]` cho luật Quốc tế 10×10).
* `captured_mask` (`.space 50`): Mảng đánh dấu các quân đã bị nhảy qua trong cùng chuỗi ăn ở luật Quốc tế (`1` = đã bị ăn, giữ trên bàn làm vật cản đến hết lượt rồi mới xóa).
* `current_player` (`.word 3`): Lượt hiện tại (`3` = Đen đi trước, `1` = Đỏ).
* `start_square`, `destination`, `game_over`: Ô xuất phát, ô đích và cờ kết thúc ván chơi.
* `player1_color` (`.word 3`): Màu mà Người chơi 1 chọn lúc bắt đầu (`3` = Đen, `1` = Đỏ).
* `mandatory_capture` (`.word 1`): Chế độ bắt buộc ăn quân (`1` = bắt buộc ăn, `0` = Casual ở luật Anh-Mỹ).
* `ruleset` (`.word 0`): Loại luật (`0` = Anh-Mỹ 8×8, `1` = Quốc tế 10×10).
* `board_dim` (`.word 8`), `num_squares` (`.word 32`), `squares_per_row` (`.word 4`): Kích thước động của bàn cờ (`8/32/4` cho Anh-Mỹ; `10/50/5` cho Quốc tế).
* `in_capture_chain` (`.word 0`): Cờ bật `1` trong khi đang thực hiện chuỗi ăn (để luật Quốc tế hoãn xóa quân bị ăn tới cuối lượt).

---

## 2. Thủ tục `init_board`
* **Mục đích:** Xóa sạch toàn bộ 50 byte của `board` và `captured_mask`, đồng bộ `board_dim`/`num_squares`/`squares_per_row` theo `ruleset`, rồi xếp quân ban đầu:
  * **Luật Anh-Mỹ (`ruleset == 0`, 8×8):** `1..12` = Tốt Đỏ (`1`), `13..20` = trống (`0`), `21..32` = Tốt Đen (`3`).
  * **Luật Quốc tế (`ruleset == 1`, 10×10):** `1..20` = Tốt Đỏ (`1`), `21..30` = trống (`0`), `31..50` = Tốt Đen (`3`).

---

## 3. Thủ tục `print_board` (Hỗ trợ 8×8, 10×10 và Xoay bàn 180°)
* **Mục đích:** In bàn cờ có khung kẻ ASCII (tự co giãn theo `board_dim` bằng hàm phụ `print_board_border`), kèm bản đồ đánh số ô (`1–32` hoặc `1–50`) bên phải, chú thích ký hiệu và số quân còn lại của mỗi bên.
* **Xoay bàn theo lượt người chơi:**
  * Đọc `current_player`: nếu là **Đen (`3`)**, in góc nhìn bình thường (`row = 0..dim-1`, `col = 0..dim-1`, quân Đen ở dưới đi lên).
  * Nếu là **Đỏ (`1`)**, tự động **xoay bàn cờ 180°** (`row = dim-1..0`, `col = dim-1..0`, kể cả bản đồ số ô bên phải và chỉ số hàng/cột), giúp quân Đỏ luôn nằm ở phía dưới đi lên mà không làm thay đổi dữ liệu mảng `board`.
* **Hiển thị quân bị ăn giữa chuỗi:** Nếu `captured_mask[sq - 1] == 1` (luật Quốc tế đang ăn liên hoàn), ô đó hiển thị ký tự `x`.
* **Stack:** Cấp `36` byte lưu `$s0–$s7` và `$ra`, bảo toàn dữ liệu `board`.
