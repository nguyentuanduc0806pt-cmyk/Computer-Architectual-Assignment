# Tài liệu giải thích module `movement.asm`

File nguồn: [movement.asm](./movement.asm)  
Phụ trách: Thành viên A

---

## 1. Thủ tục `validate_normal_move`
* **Mục đích:** Kiểm tra nước đi thường 1 bước chéo từ `start` (`$a0`) đến `destination` (`$a1`) có hợp lệ cho `current_player` (`$a2`) hay không. **Chỉ đọc, không sửa `board`.**
* **Giá trị trả về:** `$v0 = 1` nếu hợp lệ, `0` nếu không hợp lệ.
* **Các bước kiểm tra:**
  1. Cả `start` và `destination` phải nằm trong `1..32`.
  2. Đọc `board[start - 1]`, kiểm tra quân ở ô xuất phát đúng thuộc về `current_player` (`1/2` cho Đỏ, `3/4` cho Đen).
  3. Ô đích `board[destination - 1]` phải đang trống (`0`).
  4. Dùng `square_to_coord` đổi hai ô sang `(r1, c1)` và `(r2, c2)`, tính `d_row = r2 - r1`, `d_col = c2 - c1`.
  5. Kiểm tra `|d_col| == 1`.
  6. Kiểm tra hướng `d_row`:
     * Tốt Đỏ (`1`): chỉ đi xuống (`d_row == +1`).
     * Tốt Đen (`3`): chỉ đi lên (`d_row == -1`).
     * Vua (`2` hoặc `4`): đi được cả hai hướng (`|d_row| == 1`).
* **Stack:** Cấp `24` byte lưu `$s0–$s4` và `$ra`.

---

## 2. Thủ tục `apply_normal_move`
* **Mục đích:** Di chuyển quân từ `start` (`$a0`) sang `destination` (`$a1`) sau khi đã kiểm tra hợp lệ.
* **Cách làm:** Chặn an toàn `1..32`, đọc mã quân ở `board[start - 1]`, ghi sang `board[destination - 1]` rồi xóa ô cũ bằng `sb $zero`.
* **Thanh ghi:** Thủ tục lá (`$t0–$t3`), không cần stack.

---

## 3. Thủ tục `has_normal_move`
* **Mục đích:** Kiểm tra nhanh xem quân tại ô `$a0` của người chơi `$a1` có còn ít nhất một nước đi thường hợp lệ hay không. Dùng cho việc hiện nước đi hợp lệ và phát hiện đối thủ bị khóa hết nước (trap win). **Không sửa `board`.**
* **Giá trị trả về:** `$v0 = 1` nếu còn ít nhất 1 nước đi thường, `0` nếu không.
* **Cách làm:**
  * Kiểm tra nhanh `$a0` trong `1..32` và quân ở `board[$a0 - 1]` đúng thuộc về `$a1` (bỏ qua ngay ô trống hoặc quân địch).
  * Duyệt 4 hướng chéo trong bảng `mv_dr` / `mv_dc` (`(-1,-1), (-1,+1), (+1,-1), (+1,+1)`), gọi `coord_to_square` rồi `validate_normal_move`. Gặp nước hợp lệ đầu tiên thì trả `1` ngay.
* **Stack:** Cấp `24` byte lưu `$s0–$s4` và `$ra`.

---

## 4. Thủ tục `print_normal_moves`
* **Mục đích:** In tất cả các ô đích đi thường hợp lệ của quân tại `$a0` (thuộc người chơi `$a1`), cách nhau bởi dấu cách và theo thứ tự tăng dần số ô. **Không sửa `board`.**
* **Giá trị trả về:** `$v0` = số lượng nước đi hợp lệ đã in.
* **Cách làm:** Dùng chung bảng `mv_dr` / `mv_dc` và `validate_normal_move`, mỗi ô hợp lệ thì in số ô bằng syscall `1` và tăng biến đếm `$s5`.
* **Stack:** Cấp `32` byte lưu `$s0–$s6` và `$ra`.
