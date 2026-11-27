# Tài liệu giải thích module `promotion.asm`

File nguồn: [promotion.asm](./promotion.asm)  
Phụ trách: Thành viên A

---

## 1. Thủ tục `check_promotion`
* **Mục đích:** Kiểm tra quân cờ tại ô `destination` (`$a0`) có phải là quân Tốt đang đứng trên hàng phong cấp (king-row) hay không; nếu đúng thì đổi thành mã quân Vua tương ứng.
* **Hỗ trợ cả hai kích thước bàn cờ:** Đọc động `num_squares` (`32` hoặc `50`) và `squares_per_row` (`4` hoặc `5`):
  * **Tốt Đỏ (`1` → `2`):** phong cấp khi `destination > num_squares - squares_per_row` (ô **`29..32`** trên bàn 8×8, ô **`46..50`** trên bàn 10×10).
  * **Tốt Đen (`3` → `4`):** phong cấp khi `destination <= squares_per_row` (ô **`1..4`** trên bàn 8×8, ô **`1..5`** trên bàn 10×10).
* **Thanh ghi:** Thủ tục lá (`$t0–$t6`), không cần cấp phát stack.

---

## 2. Thời điểm gọi theo từng loại luật
* **Nước đi thường (cả 2 luật):** gọi `check_promotion` ngay sau `apply_normal_move`.
* **Nước ăn quân — Luật Anh-Mỹ (`ruleset == 0`, theo `american_checkers.pdf` footnote 7):**
  * Gọi `check_promotion` ngay sau khi đáp xuống ô đích. Nếu quân Tốt **vừa được phong Vua** trên hàng cuối, **lượt đi kết thúc ngay lập tức** (không nhảy tiếp).
* **Nước ăn quân — Luật Quốc tế (`ruleset == 1`, theo ItsYourTurn):**
  * **Không** phong cấp giữa chuỗi ăn: nếu Tốt chỉ đi ngang qua hàng phong cấp và vẫn còn nước ăn lùi, nó tiếp tục nhảy với tư cách quân Tốt.
  * Chỉ gọi `check_promotion` **sau khi toàn bộ chuỗi ăn kết thúc** (nếu quân dừng lượt tại hàng phong cấp).
