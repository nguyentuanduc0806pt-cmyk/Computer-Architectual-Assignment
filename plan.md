# CO2008 – Kế hoạch triển khai Checkers bằng MIPS

> **Mục đích:** Đây là tài liệu chung để cả hai thành viên biết rõ ai phụ trách phần nào, các phần kết nối với nhau ra sao, những quy ước kỹ thuật nào phải tuân thủ và cần kiểm thử những gì trước khi nộp bài.
>
> **Nguyên tắc làm việc:** Thống nhất giao diện và quy ước chung trước khi lập trình. Sau đó, hai thành viên có thể phát triển hai phần song song và tích hợp sau từng cột mốc. **Không đợi đến khi hoàn thành toàn bộ mới ghép code.**

---

## 1. Tổng quan phân chia công việc

| Hạng mục | Thành viên A | Thành viên B |
|---|---|---|
| Nhiệm vụ chính | Bàn cờ, tọa độ, nước đi thông thường, quân Vua và phong cấp | Ăn quân, ăn liên tiếp, vòng lặp trò chơi, lượt chơi và điều kiện thắng/kết thúc |
| Phụ trách chính | Các module về bàn cờ và di chuyển | Các module về ăn quân và điều khiển trò chơi; `main` |
| Sản phẩm cần hoàn thành | Hệ thống bàn cờ và phần di chuyển thông thường đã được kiểm thử | Hệ thống ăn quân và bộ điều khiển trò chơi có thể chơi được, đã được kiểm thử |
| Công việc chung | Tích hợp, kiểm thử toàn bộ, rà soát báo cáo và chuẩn bị thuyết trình | Tích hợp, kiểm thử toàn bộ, rà soát báo cáo và chuẩn bị thuyết trình |

**Lưu ý:** Người phụ trách một phần là người chịu trách nhiệm chính về việc triển khai, không có nghĩa là làm việc hoàn toàn độc lập. Cả hai cần hiểu toàn bộ chương trình và kiểm tra phần code của nhau.

## 2. Nhiệm vụ và sản phẩm của từng thành viên

### Thành viên A – Bàn cờ và di chuyển

**Phụ trách triển khai:**

- [ ] `init_board` – Khởi tạo 32 ô có thể chơi trên bàn cờ.
- [ ] `print_board` – In toàn bộ bàn cờ 8 × 8 bằng cách tái tạo 32 ô có thể chơi và 32 ô không thể chơi.
- [ ] `square_to_coord` và `coord_to_square` – Chuyển đổi giữa số ô mà người chơi nhập và tọa độ hàng/cột.
- [ ] Các hàm hỗ trợ tra cứu ô và quân cờ, nếu thiết kế chung cần dùng.
- [ ] Kiểm tra tính hợp lệ của nước đi thông thường của quân Tốt.
- [ ] Kiểm tra nước đi của quân Vua, bao gồm cả hướng đi ngược.
- [ ] `apply_normal_move` – Thực hiện nước đi thông thường và xóa quân khỏi ô xuất phát.
- [ ] `check_promotion` – Phong cấp quân Tốt khi quân đến hàng phong cấp.

**Sản phẩm bàn giao:** Một module bàn cờ đã được kiểm thử, có thể khởi tạo và hiển thị bàn cờ, chuyển đổi chính xác số ô và tọa độ, đồng thời kiểm tra và thực hiện nước đi thông thường của quân Tốt và quân Vua, bao gồm cả phong cấp.

**Các bài kiểm thử A phụ trách:** Khởi tạo/hiển thị bàn cờ, chuyển đổi tọa độ và chuyển đổi ngược, di chuyển Tốt/Vua, phong cấp. Thành viên B rà soát, đặc biệt là trường hợp phong cấp sau khi ăn quân.

### Thành viên B – Ăn quân và điều khiển trò chơi

**Phụ trách triển khai:**

- [x] `validate_capture` – Kiểm tra một nước ăn quân có hợp lệ hay không.
- [x] Xác định quân bị ăn và triển khai `apply_capture` – Di chuyển quân đang ăn và loại bỏ quân nằm ở giữa.
- [x] `check_capture` – Kiểm tra từ một ô nhất định xem còn nước ăn quân nào hay không.
- [x] `chain_capture` – Yêu cầu người chơi nhập và thực hiện các nước ăn liên tiếp bằng cùng một quân.
- [ ] Nhập dữ liệu từ người chơi và quản lý lượt chơi.
- [ ] Chuyển lượt và cho phép nhập lại khi nước đi không hợp lệ.
- [x] `check_winner` – Tối thiểu phải phát hiện trường hợp một bên không còn quân cờ.
- [ ] Kết thúc trò chơi và hiển thị kết quả cuối cùng.
- [ ] `main` và vòng lặp điều khiển toàn bộ trò chơi.

**Sản phẩm bàn giao:** Một module ăn quân và bộ điều khiển trò chơi đã được kiểm thử, có thể quản lý việc ăn quân, ăn liên tiếp, lượt chơi và điều kiện thắng tối thiểu được yêu cầu.

**Các bài kiểm thử B phụ trách:** Kiểm tra/thực hiện ăn quân, ăn liên tiếp, chuyển lượt và xác định người thắng. Thành viên A rà soát, đặc biệt là trường hợp phong cấp trong chuỗi ăn quân.

### Công việc cả hai cùng chịu trách nhiệm

- Thống nhất cách lưu bàn cờ và giao diện các thủ tục trước khi triển khai.
- Tích hợp các module sau mỗi cột mốc lớn.
- Cùng chạy kiểm thử từ đầu đến cuối và sửa các lỗi phát sinh khi kết nối module.
- Cùng đọc, rà soát toàn bộ source code, báo cáo và bài thuyết trình.
- Cả hai phải chuẩn bị để giải thích toàn bộ chương trình và tham gia phần trình diễn, trả lời câu hỏi.

---

## 3. Quy ước kỹ thuật chung – Không tự ý thay đổi

Đây là **quy ước chung giữa hai module**. Cả hai thành viên phải sử dụng cùng cách biểu diễn bàn cờ, giá trị quân cờ, hệ tọa độ, biến dùng chung và ý nghĩa của các thủ tục. Nếu muốn thay đổi, cần trao đổi và thống nhất trước khi sửa code.

### 3.1. Cách biểu diễn bàn cờ

Sử dụng **chính xác 32 ô có thể chơi** trong một mảng byte tên là `board`.

| Giá trị lưu trong mảng | Ý nghĩa |
|---:|---|
| `0` | Ô có thể chơi nhưng đang trống |
| `1` | Quân Tốt Đỏ |
| `2` | Quân Vua Đỏ |
| `3` | Quân Tốt Đen |
| `4` | Quân Vua Đen |

- Số ô mà người chơi sử dụng là từ **1 đến 32**.
- Chỉ số trong mảng = `square_number - 1`.
- Khi in bàn cờ, chương trình phải tái tạo các ô không thể chơi để hiển thị đầy đủ bàn cờ 8 × 8.
- Tất cả module phải sử dụng đúng các giá trị mã hóa quân cờ trên. Không tự tạo một bộ mã khác trong module riêng.

### 3.2. Các biến trò chơi dùng chung

| Biến | Ý nghĩa |
|---|---|
| `current_player` | `1` = Đỏ; `3` = Đen |
| `start_square` | Số ô xuất phát do người chơi nhập |
| `destination` | Số ô đích do người chơi nhập |
| `game_over` | `0` khi trò chơi còn tiếp tục; khác `0` khi trò chơi kết thúc |

Khi tích hợp, cả hai module phải dùng cùng tên biến và cùng ý nghĩa như bảng trên.

### 3.3. Quy ước tọa độ

Sử dụng hệ tọa độ **bắt đầu từ 0 (zero-based)**:

- Hàng `0` là hàng trên cùng; hàng `7` là hàng dưới cùng.
- Cột `0` là cột ngoài cùng bên trái; cột `7` là cột ngoài cùng bên phải.
- Hàng và cột đều nằm trong phạm vi `0..7`.
- Một tọa độ là ô có thể chơi khi thỏa mãn `(row + column) mod 2 = 1`.

| Chuyển đổi | Công thức |
|---|---|
| Số ô → hàng | `row = floor((n - 1) / 4)` |
| Số ô → cột | `col = 2 * ((n - 1) mod 4) + 1 - (row mod 2)` |
| Tọa độ → số ô | `n = 4 * row + floor(col / 2) + 1` |
| Kiểm tra ô có thể chơi | `(row + col) mod 2 = 1` |

**Yêu cầu khi chuyển đổi tọa độ:**

- Kiểm tra số ô nằm trong phạm vi `1..32` trước khi chuyển đổi.
- Khi chuyển tọa độ thành số ô, phải kiểm tra hàng/cột có nằm trong phạm vi hợp lệ và tọa độ có đúng là ô có thể chơi hay không.
- `coord_to_square` trả về `-1` nếu tọa độ không hợp lệ.
- Kiểm thử toàn bộ số ô từ `1` đến `32`; sau đó chuyển số ô → tọa độ → số ô và xác nhận kết quả cuối cùng phải bằng số ô ban đầu.

### 3.4. Quy ước thanh ghi và thủ tục

| Thanh ghi | Quy ước dùng chung |
|---|---|
| `$a0-$a3` | Truyền các tham số đầu vào cho thủ tục |
| `$v0-$v1` | Chứa giá trị trả về từ thủ tục |
| `$t0-$t9` | Thanh ghi tạm; bên gọi không được giả định giá trị trong các thanh ghi này vẫn còn nguyên sau khi gọi một thủ tục khác |
| `$s0-$s7`, `$ra`, `$sp` | Phải bảo toàn các thanh ghi `$s` đã thay đổi và `$ra` khi có lời gọi thủ tục lồng nhau; cần tuân theo quy tắc sử dụng stack thống nhất |

Cần ghi rõ tham số đầu vào, giá trị trả về và tác động lên dữ liệu của từng thủ tục. Bên gọi không được dựa vào việc một thanh ghi tạm vẫn giữ nguyên giá trị sau lời gọi thủ tục.

### 3.5. Quy tắc quan trọng nhất về trạng thái bàn cờ

> **Thủ tục kiểm tra chỉ kiểm tra; thủ tục thực thi mới được thay đổi bàn cờ.**

- Các thủ tục kiểm tra (`validate_normal_move`, `validate_capture`) **không được thay đổi** `board`.
- Các thủ tục thực thi (`apply_normal_move`, `apply_capture`) chịu trách nhiệm cập nhật bàn cờ.
- Phải kiểm tra phong cấp ngay sau khi một nước đi đưa quân Tốt đến hàng phong cấp – kể cả khi đó là nước ăn quân.
- Trong chuỗi ăn quân, nếu quân Tốt được phong cấp thành Vua, quân Vua mới có thể tiếp tục ăn ngay, bao gồm cả hướng ngược nếu nước ăn đó hợp lệ.

---

## 4. Quy ước giao diện các thủ tục

Có thể đổi tên thủ tục nếu cả hai cùng đồng ý, nhưng **ý nghĩa đầu vào/đầu ra phải được giữ nguyên**. Cần giữ giao diện ổn định để mỗi thành viên có thể phát triển và kiểm thử phần của mình một cách độc lập.

| Thủ tục | Tham số đầu vào | Giá trị trả về / tác động | Phụ trách |
|---|---|---|---|
| `square_to_coord` | `$a0 = square number` | `$v0 = row`; `$v1 = column` | A |
| `coord_to_square` | `$a0 = row`; `$a1 = column` | `$v0 = square number`, hoặc `-1` nếu không hợp lệ | A |
| `validate_normal_move` | `$a0 = start`; `$a1 = destination`; `$a2 = current player` | `$v0 = 1` nếu hợp lệ, `0` nếu không hợp lệ; không thay đổi bàn cờ | A |
| `apply_normal_move` | `$a0 = start`; `$a1 = destination` | Di chuyển quân đến ô đích và xóa quân ở ô xuất phát | A |
| `check_promotion` | `$a0 = destination square` | Đổi quân Tốt thành quân Vua tương ứng nếu quân đã đến hàng phong cấp | A |
| `validate_capture` | `$a0 = start`; `$a1 = destination`; `$a2 = current player` | `$v0 = 1` nếu hợp lệ, `0` nếu không hợp lệ; không thay đổi bàn cờ | B |
| `apply_capture` | `$a0 = start`; `$a1 = destination` | Di chuyển quân ăn và loại bỏ quân bị ăn ở ô giữa | B |
| `check_capture` | `$a0 = current square` | `$v0 = 1` nếu có ít nhất một nước ăn quân; ngược lại trả về `0` | B |
| `chain_capture` | `$a0 = current square` | Yêu cầu người chơi nhập nước ăn tiếp theo và đọc quân từ bàn cờ | B |
| `check_winner` | `$a0 = player to check` | Tối thiểu phát hiện xem người chơi đó có còn quân hay không | B |

### Các quy tắc khi kết nối thủ tục

1. Tất cả thủ tục cần đọc thông tin quân cờ phải truy cập cùng một mảng `board` dùng chung.
2. Thủ tục kiểm tra chỉ xác định nước đi có hợp lệ hay không. Chúng không được thay đổi bất kỳ byte nào trong `board`.
3. Thủ tục `apply` mới thực hiện các thay đổi thực tế lên bàn cờ.
4. Sau một nước đi thông thường, gọi thủ tục thực hiện nước đi rồi kiểm tra phong cấp.
5. Sau một nước ăn quân, gọi thủ tục thực hiện ăn quân rồi kiểm tra phong cấp ngay lập tức.
6. Sau khi ăn quân, kiểm tra xem còn nước ăn tiếp theo hay không. Nếu còn, tiếp tục bằng **cùng quân cờ và cùng người chơi**.
7. Chỉ chuyển lượt khi lượt hiện tại đã hoàn tất và trò chơi chưa kết thúc.

### Luồng tích hợp chính – Thành viên B phụ trách

1. In bàn cờ.
2. Đọc ô xuất phát và ô đích do người chơi nhập.
3. Kiểm tra dữ liệu đầu vào cơ bản và xác nhận ô xuất phát chứa quân của người đang chơi.
4. Gọi `validate_normal_move`.
5. Nếu nước đi thông thường hợp lệ, gọi `apply_normal_move`, sau đó gọi `check_promotion`.
6. Nếu nước đi thông thường không hợp lệ, kiểm tra xem đó có phải là một nước ăn quân hợp lệ bằng `validate_capture` hay không.
7. Nếu nước ăn quân hợp lệ, gọi `apply_capture`, sau đó gọi `check_promotion`.
8. Sau khi ăn quân, gọi `check_capture`. Nếu còn nước ăn tiếp theo, gọi `chain_capture` và tiếp tục với cùng quân cờ, cùng người chơi.
9. Khi lượt chơi hoàn tất, kiểm tra điều kiện thắng.
10. Chỉ chuyển người chơi nếu trò chơi chưa kết thúc; nếu đã kết thúc, hiển thị kết quả và dừng chương trình.

---

## 5. Các cột mốc phát triển

Hai thành viên có thể làm song song sau khi thống nhất quy ước chung. Thành viên B không cần chờ A hoàn thành toàn bộ: phần hình học ăn quân và khung điều khiển trò chơi có thể được phát triển dựa trên giao diện bàn cờ/tọa độ đã thống nhất.

| Cột mốc | Thành viên A – Bàn cờ và di chuyển | Thành viên B – Ăn quân và điều khiển | Điểm cần tích hợp/kiểm tra |
|---|---|---|---|
| **1. Nền tảng** | Khai báo dữ liệu bàn cờ và hằng số quân cờ; triển khai `init_board`. | Thống nhất quy ước dữ liệu/thanh ghi; phác thảo luồng điều khiển trò chơi và các bàn cờ dùng để kiểm thử. | Xác nhận mảng bàn cờ, mã quân cờ, biến và quy ước gọi thủ tục giống nhau. |
| **2. Bàn cờ và hàm hỗ trợ** | Triển khai `print_board` và các hàm chuyển đổi tọa độ; kiểm thử cả 32 ô. | Xây dựng phần nhập dữ liệu và khung kiểm tra dựa trên giao diện đã thống nhất. | B có thể gọi các hàm tọa độ của A; cả hai thống nhất cách đánh số ô. |
| **3. Di chuyển** | Triển khai di chuyển thông thường của quân Tốt và `apply_normal_move`. | Triển khai logic hình học ăn quân và `validate_capture` bằng các hàm tọa độ của A. | Kiểm thử thủ tục kiểm tra nước đi thông thường và nước ăn quân trên cùng các trạng thái bàn cờ. |
| **4. Quân Vua và ăn quân** | Triển khai di chuyển quân Vua và `check_promotion`. | Triển khai `apply_capture` và `check_capture`. | Kiểm tra hướng di chuyển của Vua, cập nhật khi ăn quân và hành vi phong cấp. |
| **5. Tích hợp** | Bàn giao các thủ tục di chuyển và phong cấp đã kiểm thử. | Triển khai `chain_capture`, `main`, chuyển lượt và xác định người thắng. | Chạy trọn vẹn một lượt chơi thông qua các lời gọi thủ tục thực tế. |
| **6. Kiểm thử chung** | Sửa lỗi bàn cờ, di chuyển và phong cấp. | Sửa lỗi ăn quân, ăn liên tiếp, lượt chơi và kết thúc trò chơi. | Chạy tất cả tình huống kiểm thử cần thiết và hoàn thành các ván chơi từ đầu đến cuối. |

**Không đợi đến Cột mốc 6 mới tích hợp.** Sau mỗi cột mốc, hãy ghép những thủ tục đã hoàn thành và chạy ít nhất một bài kiểm thử thực tế qua giao diện chung.

---

## 6. Cấu trúc file source code đề xuất

Trong quá trình phát triển, nên chia thủ tục thành các file riêng hoặc tách thành từng khu vực rõ ràng trong source. Cần kiểm tra cách MARS mà nhóm sử dụng xử lý việc assemble nhiều file. Nếu MARS không ghép các module một cách ổn định, hãy kết hợp các thủ tục vào **một file `.asm` cuối cùng** để nộp.

```text
project/
├── main.asm                     # Điểm bắt đầu và vòng lặp trò chơi (B)
├── modules/
│   ├── board.asm                # Khởi tạo và hiển thị bàn cờ (A)
│   ├── coordinates.asm          # Chuyển đổi số ô/tọa độ (A)
│   ├── movement.asm             # Kiểm tra và thực hiện di chuyển thường (A)
│   ├── promotion.asm            # Phong cấp Tốt thành Vua (A)
│   ├── capture.asm              # Kiểm tra/thực hiện ăn quân và ăn liên tiếp (B)
│   └── game_control.asm         # Nhập dữ liệu, lượt chơi, người thắng, kết thúc (B)
├── tests/                       # Các trường hợp kiểm thử riêng (Cả hai)
└── README.md                    # Hướng dẫn chạy, quy ước và test cases (Cả hai)
```

| File | Nội dung chính | Phụ trách |
|---|---|---|
| `main.asm` | Điểm bắt đầu và vòng lặp trò chơi | B; cùng tích hợp |
| `modules/board.asm` | Khởi tạo và hiển thị bàn cờ | A |
| `modules/coordinates.asm` | Chuyển đổi số ô và tọa độ | A |
| `modules/movement.asm` | Kiểm tra và thực hiện di chuyển thông thường | A |
| `modules/promotion.asm` | Phong cấp Tốt thành Vua | A |
| `modules/capture.asm` | Kiểm tra, thực hiện ăn quân và xử lý chuỗi ăn quân | B |
| `modules/game_control.asm` | Nhập dữ liệu, quản lý lượt, xác định người thắng và kết thúc | B |
| `tests/` và `README.md` | Test cases, hướng dẫn chạy, quy ước và các trường hợp kiểm thử | Cả hai |

---

## 7. Kế hoạch kiểm thử và tiêu chí hoàn thành

Mỗi bài kiểm thử nên ghi rõ trạng thái bàn cờ ban đầu, hành động/dữ liệu nhập vào và kết quả mong đợi. Với nước đi không hợp lệ, phải xác nhận rõ rằng **bàn cờ không bị thay đổi**.

| # | Tình huống | Kết quả mong đợi | Người phụ trách chính |
|---:|---|---|---|
| 1 | Bàn cờ ban đầu | Có 12 quân Đỏ, 12 quân Đen và 8 ô có thể chơi đang trống | A |
| 2 | Chuyển đổi tọa độ | Cả 32 số ô được chuyển đổi chính xác; chuyển đổi ngược trả về đúng số ô ban đầu | A |
| 3 | Nước đi hợp lệ cho mỗi bên | Quân cờ di chuyển đến đúng ô chéo theo luật | A |
| 4 | Ô xuất phát trống / chứa quân đối phương | Nước đi bị từ chối; bàn cờ không thay đổi | A; B rà soát |
| 5 | Ô đích đã có quân / đi sai hướng | Nước đi bị từ chối; bàn cờ không thay đổi | A |
| 6 | Ăn quân hợp lệ | Quân đang ăn đến đúng ô đích và quân bị ăn được loại bỏ | B |
| 7 | Ăn quân không hợp lệ | Nước đi bị từ chối và toàn bộ các ô trên bàn cờ giữ nguyên | B |
| 8 | Phong cấp ở cả hai đầu bàn cờ | Quân Tốt được đổi ngay sang mã quân Vua tương ứng | A |
| 9 | Quân Vua di chuyển ngược | Quân Vua có thể di chuyển và ăn quân theo cả hai hướng | A; B rà soát |
| 10 | Ăn nhiều quân liên tiếp | Cùng một quân tiếp tục ăn cho đến khi không còn nước ăn nào | B |
| 11 | Phong cấp trong chuỗi ăn quân | Quân vừa phong cấp thành Vua có thể tiếp tục ăn ngay theo hướng ngược | B; A rà soát |
| 12 | Đối phương hết quân | Người thắng được thông báo và trò chơi kết thúc | B |
| 13 | Một ván chơi hoàn chỉnh | Lượt chơi, di chuyển, ăn quân, phong cấp và kết thúc hoạt động cùng nhau | Cả hai |

### Những gì Thành viên A cần chứng minh

- Khởi tạo bàn cờ đúng số lượng và vị trí quân cờ.
- Hiển thị đúng 32 ô có thể chơi trên bàn cờ 8 × 8.
- Tất cả phép chuyển đổi số ô/tọa độ tuân theo công thức đã thống nhất.
- Thủ tục kiểm tra nước đi thông thường không làm thay đổi bàn cờ.
- Thủ tục thực hiện nước đi cập nhật ô đích và xóa ô xuất phát.
- Quân Tốt và quân Vua di chuyển đúng quy định; phong cấp diễn ra ở đúng đầu bàn cờ.

### Những gì Thành viên B cần chứng minh

- Thủ tục kiểm tra ăn quân không làm thay đổi bàn cờ.
- Thủ tục thực hiện ăn quân di chuyển quân đang ăn và loại bỏ đúng quân ở ô giữa.
- `check_capture` xác định chính xác việc còn nước ăn tiếp theo hay không.
- Chuỗi ăn quân sử dụng cùng một quân và cùng một người chơi cho đến khi không còn nước ăn.
- Khi ăn quân mà được phong cấp, việc phong cấp diễn ra ngay và quân Vua mới có thể tiếp tục chuỗi ăn.
- Nước đi không hợp lệ cho phép người chơi nhập lại mà không làm thay đổi bàn cờ hoặc chuyển lượt.
- Xác định người thắng và kết thúc trò chơi hoạt động đúng với điều kiện tối thiểu.

### Những gì cả hai cần chứng minh

- Chương trình sau khi tích hợp assemble và chạy được trên cấu hình MARS mà nhóm thống nhất.
- Các module sử dụng cùng mảng, mã quân cờ, biến và quy ước thủ tục.
- Các ván chơi từ đầu đến cuối hoạt động mà không phát sinh lỗi giao diện hoặc cập nhật trạng thái.

---

## 8. Quy trình làm việc với Git và phối hợp nhóm

1. Tạo một Git repository dùng chung và thống nhất quy tắc đặt tên branch, file và commit.
2. Phân công quyền phụ trách từng file module. Tránh để cả hai cùng sửa `main.asm` hoặc phần khai báo dữ liệu dùng chung cùng lúc.
3. Commit các thay đổi nhỏ, đã chạy được, với nội dung mô tả rõ ràng. Ví dụ:
   - `Add square-to-coordinate conversion`
   - `Implement capture validation`
   - `Add promotion test cases`
4. Trước khi merge, mỗi thành viên phải tự kiểm thử module của mình trong MARS và ghi rõ đầu vào, đầu ra, tác động của từng thủ tục.
5. Tích hợp thường xuyên. Khi có xung đột về giao diện hoặc quy ước, hai người cùng giải quyết; không tự ý thay đổi quy ước chung.
6. Giữ lại một phiên bản đã chạy ổn định trước khi thực hiện các thay đổi tích hợp lớn để có thể quay lại khi cần.

**Thói quen commit đề xuất:** Commit sau khi hoàn thành một thủ tục hoặc một cải tiến nhỏ đã kiểm thử, thay vì chờ đến khi toàn bộ module hoàn thành.

---

## 9. Phân chia báo cáo và thuyết trình

Cả hai thành viên cần hiểu toàn bộ chương trình. Bài tập đánh giá tính đúng đắn của chương trình, độ dễ đọc của code, cấu trúc tổng thể, mức độ hiểu MIPS Assembly và chất lượng báo cáo/thuyết trình.

| Phần báo cáo / thuyết trình | Người trình bày chính | Người rà soát |
|---|---|---|
| Kiến trúc hệ thống, biểu diễn và khởi tạo bàn cờ | A | B |
| Hệ tọa độ và thuật toán di chuyển | A | B |
| Kiểm tra ăn quân, thực hiện ăn quân và ăn liên tiếp | B | A |
| Vòng lặp trò chơi, điều khiển lượt và điều kiện thắng | B | A |
| Kết quả kiểm thử và hạn chế | Cả hai | Cả hai |
| Trình diễn trực tiếp và trả lời câu hỏi | Cả hai | Cả hai |

### Cả hai cần chuẩn bị giải thích

- Các thủ tục do mình viết, có thể giải thích từng lệnh khi cần.
- Cách các thủ tục của mình tương tác với module của thành viên còn lại.
- Cách sử dụng thanh ghi và quy ước gọi thủ tục.
- Cách bảo toàn stack/thanh ghi, đặc biệt khi có lời gọi thủ tục lồng nhau.
- Cách đánh chỉ số bàn cờ và chuyển đổi giữa số ô với tọa độ.
- Thứ tự cập nhật trạng thái trò chơi, bao gồm ăn quân và phong cấp.

**Không chỉ học phần mình viết.** Mỗi thành viên cần mô tả được toàn bộ chương trình và trả lời câu hỏi về cách các phần phối hợp với nhau.

---

## 10. Những điểm hai thành viên cần thống nhất trước khi triển khai

Kế hoạch gốc đã xác định các giao diện chính, nhưng vẫn còn một số chi tiết triển khai cần cả hai cùng quyết định. Hãy ghi lại phương án đã thống nhất ở đây hoặc trong comment của code trước khi tích hợp hai module.

- [ ] **Cấu trúc source cuối cùng:** MARS có thể assemble các module cùng nhau không, hay nhóm sẽ nộp một file `.asm` đã ghép?
- [ ] **Cách `chain_capture` báo kết thúc:** Thủ tục báo hiệu chuỗi ăn quân đã kết thúc bằng cách nào (ví dụ: giá trị trả về được quy định rõ hoặc một quy ước luồng điều khiển cụ thể)? Mô tả giao diện hiện tại nói thủ tục yêu cầu nhập các nước ăn tiếp theo nhưng chưa quy định giá trị trả về cụ thể.
- [ ] **Nơi khai báo dữ liệu dùng chung:** File nào chịu trách nhiệm khai báo duy nhất các biến `board`, `current_player`, `start_square`, `destination` và `game_over`? Các module khác nên tham chiếu đến chúng, không khai báo bản sao.
- [ ] **Kiểm tra dữ liệu nhập:** Thống nhất cách từ chối số ô ngoài phạm vi và dữ liệu người dùng nhập sai định dạng trước khi gọi các thủ tục kiểm tra di chuyển/ăn quân.
- [ ] **Các luật cụ thể của đề bài:** Kiểm tra lại những luật di chuyển hoặc luật trò chơi chưa được liệt kê trong kế hoạch này bằng đề bài gốc. Không tự giả định một luật nếu đề bài chưa quy định.

---

## 11. Checklist cuối cùng của nhóm

### Quy ước chung

- [ ] Mọi module đều sử dụng cùng một mảng `board` gồm 32 byte và cùng 5 mã quân cờ.
- [ ] Số ô là `1..32`; chỉ số mảng được tính bằng `square_number - 1`.
- [ ] Tọa độ bắt đầu từ 0; hàng 0 ở trên cùng và cột 0 ở bên trái.
- [ ] Hai thành viên đã thống nhất biến dùng chung, quy ước thanh ghi và giá trị trả về.
- [ ] Thủ tục kiểm tra không thay đổi bàn cờ; thủ tục thực thi chịu trách nhiệm cập nhật bàn cờ.
- [ ] Kiểm tra phong cấp ngay sau mọi nước đi có thể đưa quân đến hàng phong cấp, bao gồm cả nước ăn quân.

### Phần triển khai

- [ ] A đã hoàn thành và kiểm thử bàn cờ, tọa độ, di chuyển thông thường, di chuyển quân Vua và phong cấp.
- [ ] B đã hoàn thành và kiểm thử ăn quân, ăn liên tiếp, vòng lặp trò chơi, điều khiển lượt và xác định người thắng.
- [ ] Giao diện và tác động của từng thủ tục đã được ghi chú.
- [ ] Các module đã được tích hợp sau từng cột mốc.

### Nộp bài và trình diễn

- [ ] Source cuối cùng assemble và chạy được trên cấu hình MARS mà nhóm đã thống nhất.
- [ ] Các tình huống kiểm thử cần thiết đều đã chạy và cho kết quả đúng.
- [ ] Test cases và hướng dẫn chạy được đưa vào `tests/` và `README.md` theo thống nhất của nhóm.
- [ ] Cả hai thành viên đã rà soát toàn bộ chương trình và báo cáo.
- [ ] Cả hai có thể giải thích toàn bộ chương trình và tham gia trình diễn.

---

## 12. Điều quan trọng nhất cần nhớ

**Rủi ro lớn nhất của dự án là lỗi khi tích hợp, không đơn thuần là số lượng code phải viết.** Hãy giữ ổn định cách biểu diễn bàn cờ và giao diện thủ tục, ghi rõ tác động của từng thủ tục, kiểm thử từng module riêng biệt và thường xuyên ghép các phần lại với nhau.
