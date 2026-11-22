# Tài liệu giải thích module `movement.asm`

File nguồn: [movement.asm](file:///d:/Computer%20Architectual%20Assignment/src/movement.asm)  
Phụ trách: Thành viên A

---

## 1. Thủ tục `validate_normal_move`
* **Mục đích:** Kiểm tra nước đi thường (không ăn quân) từ `start` (`$a0`) đến `destination` (`$a1`) có hợp lệ cho `current_player` (`$a2`) hay không. **Tuyệt đối không sửa mảng `board`.**
* **Giá trị trả về:** `$v0 = 1` nếu hợp lệ, `$v0 = 0` nếu không hợp lệ.
* **Các bước kiểm tra tuần tự:**
  1. **Kiểm tra phạm vi ô:** Cả `start` và `destination` phải nằm trong `1..32`.
  2. **Kiểm tra quyền sở hữu quân:** Đọc `piece = board[start - 1]`:
     * Nếu `current_player == 1` (Đỏ): `piece` phải là `1` (Tốt Đỏ) hoặc `2` (Vua Đỏ).
     * Nếu `current_player == 3` (Đen): `piece` phải là `3` (Tốt Đen) hoặc `4` (Vua Đen).
  3. **Kiểm tra ô đích trống:** `board[destination - 1]` phải bằng `0`.
  4. **Chuyển đổi tọa độ:** Gọi `square_to_coord(start)` được `(r1, c1)` và `square_to_coord(destination)` được `(r2, c2)`. Tính `d_row = r2 - r1`, `d_col = c2 - c1`.
  5. **Kiểm tra bước ngang:** `|d_col|` phải bằng `1` (đi chéo 1 cột).
  6. **Kiểm tra hướng dọc theo loại quân:**
     * Tốt Đỏ (`1`): chỉ được đi xuống → `d_row == +1`.
     * Tốt Đen (`3`): chỉ được đi lên → `d_row == -1`.
     * Vua (`2` hoặc `4`): được đi cả hai hướng → `|d_row| == 1`.
* **Quản lý thanh ghi:** Lưu `$ra` và `$s0–$s4` lên stack (`24` byte) trước khi gọi `square_to_coord`, khôi phục đầy đủ trước khi `jr $ra`.

---

## 2. Thủ tục `apply_normal_move`
* **Mục đích:** Thực hiện nước đi thường sau khi đã kiểm tra hợp lệ.
* **Cách thực hiện:**
  * Kiểm tra an toàn `1 <= start, destination <= 32`.
  * Đọc mã quân ở `board[start - 1]` bằng `lb`.
  * Ghi mã quân đó vào `board[destination - 1]` bằng `sb`.
  * Xóa ô cũ bằng `sb $zero` tại `board[start - 1]`.
* **Thanh ghi sử dụng:** `$t0–$t3`, không gọi hàm con.
