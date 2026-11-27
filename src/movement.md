# Tài liệu giải thích module `movement.asm`

File nguồn: [movement.asm](./movement.asm)  
Phụ trách: Thành viên A

---

## 1. Thủ tục `validate_normal_move`
* **Mục đích:** Kiểm tra nước đi thường từ `start` (`$a0`) đến `destination` (`$a1`) có hợp lệ cho `current_player` (`$a2`) theo `ruleset` hiện tại hay không. **Chỉ đọc, không sửa `board`.**
* **Giá trị trả về:** `$v0 = 1` nếu hợp lệ, `0` nếu không hợp lệ.
* **Các bước kiểm tra:**
  1. Cả `start` và `destination` nằm trong `1..num_squares` (`32` hoặc `50`) và `start != destination`.
  2. Quân tại `board[start - 1]` thuộc về `current_player`; `board[destination - 1] == 0`.
  3. Đổi sang `(r1, c1)` và `(r2, c2)`, tính `dr = r2 - r1`, `dc = c2 - c1`.
  4. **Quân Tốt (cả 2 luật) và Vua luật Anh-Mỹ (`ruleset == 0`):**
     * `|dc| == 1`; Tốt Đỏ `dr == +1`, Tốt Đen `dr == -1`, Vua Anh-Mỹ `|dr| == 1`.
  5. **Vua bay luật Quốc tế (`ruleset == 1`, `piece == 2` hoặc `4`):**
     * Yêu cầu `|dr| == |dc|` và `|dr| >= 1`.
     * Duyệt từng ô trung gian dọc theo tia chéo `(sr, sc)` từ `(r1 + sr, c1 + sc)` đến `(r2 - sr, c2 - sc)` — mọi ô trung gian phải trống (`0`).
* **Stack:** Cấp `36` byte lưu `$s0–$s7` và `$ra`.

---

## 2. Thủ tục `apply_normal_move`
* **Mục đích:** Di chuyển quân từ `start` (`$a0`) sang `destination` (`$a1`) trong phạm vi `1..num_squares` rồi xóa ô cũ.
* **Thanh ghi:** Thủ tục lá (`$t0–$t4`), không cần stack.

---

## 3. Thủ tục `has_normal_move`
* **Mục đích:** Kiểm tra quân tại `$a0` của người chơi `$a1` có ít nhất một nước đi thường hợp lệ hay không (ngay cả Vua bay luật Quốc tế cũng chỉ có nước đi khi và chỉ khi có ít nhất 1 ô chéo kề trống). **Không sửa `board`.**
* **Stack:** Cấp `24` byte lưu `$s0–$s4` và `$ra`.

---

## 4. Thủ tục `print_normal_moves`
* **Mục đích:** In toàn bộ các ô đích đi thường hợp lệ của quân tại `$a0` (thuộc `$a1`), trả về số lượng ô đã in trong `$v0`. **Không sửa `board`.**
* **Hỗ trợ Vua bay:** Khi `ruleset == 1` và quân là Vua, duyệt từng tia trong 4 hướng chéo với khoảng cách `k = 1, 2, ...` cho tới khi gặp quân cản hoặc biên bàn cờ, in tất cả các ô trống đi tới được.
* **Stack:** Cấp `36` byte lưu `$s0–$s7` và `$ra`.
