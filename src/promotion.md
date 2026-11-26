# Tài liệu giải thích module `promotion.asm`

File nguồn: [promotion.asm](file:///d:/Computer%20Architectual%20Assignment/src/promotion.asm)  
Phụ trách: Thành viên A

---

## 1. Thủ tục `check_promotion`
* **Mục đích:** Kiểm tra quân cờ vừa đi tới (hoặc vừa nhảy ăn quân đáp xuống) ô `destination` (`$a0`) có phải là quân Tốt chạm hàng phong cấp hay không; nếu đúng thì đổi ngay thành mã quân Vua tương ứng.
* **Tham số đầu vào:** `$a0 = destination square` (`1..32`).
* **Giá trị trả về:** Không có.
* **Cách thực hiện:**
  1. **Kiểm tra an toàn phạm vi:** Từ chối ngay nếu `$a0 < 1` hoặc `$a0 > 32` (`cp_done`) để tránh đọc/ghi ngoài mảng `board`.
  2. **Đọc mã quân:** Tính địa chỉ `&board[$a0 - 1]` vào `$t1` và đọc byte mã quân bằng `lbu $t2, 0($t1)`.
  3. **Phong cấp Tốt Đỏ (`piece == 1`):**
     * Hàng cuối của Đỏ là hàng `7` (tương ứng các ô **`29..32`**).
     * Kiểm tra bằng `slti $t3, $a0, 29`: nếu `$a0 >= 29`, ghi `2` (Vua Đỏ) vào `0($t1)` bằng `sb`.
  4. **Phong cấp Tốt Đen (`piece == 3`):**
     * Hàng cuối của Đen là hàng `0` (tương ứng các ô **`1..4`**).
     * Kiểm tra bằng `slti $t3, $a0, 5`: nếu `$a0 <= 4`, ghi `4` (Vua Đen) vào `0($t1)` bằng `sb`.
  5. **Các trường hợp khác:** Ô trống (`0`), đã là Vua (`2`, `4`), hoặc Tốt chưa tới hàng cuối → giữ nguyên `board`, nhảy tới `cp_done`.

---

## 2. Thiết kế thanh ghi & Tích hợp với phần của Thành viên B
* **Thủ tục lá (Leaf procedure):** Không cần gọi `square_to_coord` (vì kiểm tra trực tiếp dải ô `29..32` và `1..4` nhanh và gọn hơn), chỉ dùng `$t0–$t3` nên **không cần cấp phát stack** và bảo toàn nguyên vẹn mọi thanh ghi `$s0–$s7`, `$ra`.
* **Tương thích hoàn toàn với `main.asm` và `capture.asm`:**
  * Trong `main.asm`, `check_promotion` được gọi ngay sau `apply_normal_move` và ngay sau `apply_capture` (trước khi gọi `check_capture` / `chain_capture`).
  * Trong `capture.asm` (`chain_capture`), `check_promotion` được gọi ngay sau mỗi bước nhảy liên hoàn trước khi vòng lặp quay lại `check_capture`. Nhờ đó, quân Tốt vừa ăn quân đáp xuống hàng cuối sẽ lập tức thành Vua và có thể **ăn lùi ngay trong cùng chuỗi ăn** đúng theo đề bài.
