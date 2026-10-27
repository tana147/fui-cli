# DANH MỤC 60 CHỈ TIÊU DASHBOARD VẬN HÀNH LHBS
## (CHUẨN HÓA KHỚP 100% VỚI TÀI LIỆU GỐC PHƯƠNG ÁN XÂY DỰNG DASHBOARD)

> **Tài liệu căn cứ gốc:** `docs/2026.10.19_Phương án xây dựng Dashboard vận hành.docx`  
> **Biên bản họp ngày:** 19/10/2026 (Chị Lan Đài, Thầy Thái, Anh Tuấn CTO, Anh Tâm IOT, Anh Huy M&E, Cô Hoa, Anh Phương)  
> **Nguyên tắc chỉ đạo từ BĐH:**  
> - Thầy Thái: Ưu tiên tuyển sinh + an toàn + y tế + bếp ăn + chỉ số tài chính cơ bản (Doanh thu & Bottom line / Lợi nhuận gộp). Tham chiếu Results Framework.  
> - Chị Đài: Dữ liệu real-time, giải quyết dứt điểm các khâu nhập tay, đi theo trách nhiệm giải trình của HT/BGH, logic phục vụ Holding.  
> - Hạn chót trình bày giao diện & logic: **02/11/2026**.

---

## 0. HỆ THỐNG NGUỒN DỮ LIỆU CHUẨN ĐỂ GOLIVE (QUY ĐỊNH BỞI TÀI LIỆU & BĐH)

| STT | Hệ thống nguồn | Domain / Địa chỉ truy cập | Nghiệp vụ phụ trách | Các chỉ tiêu liên quan | Trạng thái tích hợp |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **1** | **Hệ thống Basic Data** | [`https://basicdata.lhbs.vn/`](https://basicdata.lhbs.vn/) | Quản lý học sinh, lớp học, khối, cơ cấu sĩ số, chuyển đi / rút học, công suất phòng học | Chỉ tiêu 1, 2, 3, 4, 7 | Đã có Live API & Chốt kỳ eSign |
| **2** | **Hệ thống Học phí & Dịch vụ** | [`https://hocphi.lhbs.vn/`](https://hocphi.lhbs.vn/) (Kế toán PM FTS) | Học phí, dịch vụ Bán trú & Ăn sáng, xe bus đưa rước, CLB bổ trợ ngoài giờ, Tỷ suất LN gộp (KPI 4: 50%) | Chỉ tiêu 34, 35, 36, 55, 56 | Đã có Staging eSign & API Kế toán |
| **3** | **Hệ thống Y tế học đường** | [`https://yte.lhbs.vn/`](https://yte.lhbs.vn/) | Sức khỏe học sinh, hồ sơ khám SK định kỳ, tỷ lệ BMI lệch chuẩn, sự cố tai nạn thương tích học đường (0 vụ) | Chỉ tiêu 38, 39, 40, 41 | Đã có Staging eSign & Sổ Y tế |
| **4** | **Hệ thống Đảm bảo chất lượng** | [`https://qa.lhbs.vn/`](https://qa.lhbs.vn/) | Khảo sát mức độ hài lòng của PHHS về tiến bộ học sinh (> 90%), đồng phục, sách vở, chất lượng dịch vụ | Chỉ tiêu 23, 44, 50 | Đã có Staging eSign & Form khảo sát |
| **5** | **Hệ thống LMS Học tập** | [`https://lms.lhbs.vn/`](https://lms.lhbs.vn/) (CSDL LMS-LHBS) | Tiến độ dạy, học liệu số của giáo viên (CM04), tỷ lệ hoàn thành bài tập trực tuyến (CM08), khung năng lực | Chỉ tiêu 8, 11, 15, 16, 17 | Đã kết nối Live API qua tapi.lhbs.vn |
| **6** | **Excel nội bộ (Staging)** | `docs/dashboard van hanh thang 9.xlsx` & Tracking Sheet GID 1481169716 | Leads TVTS, tỷ lệ chuyển đổi Funnel, sửa chữa CSVC phòng học, biến động nhân sự HRM | Chỉ tiêu 5, 6, 9, 52, 59 | Đã bóc tách & insert CSDL eSign (`tblKPI_PeriodSnapshots`) |

---

## 1. MA TRẬN 4 NHÓM CHỈ TIÊU THEO NGUYÊN BẢN TÀI LIỆU

| STT | Nhóm chỉ tiêu nghiệp vụ | Số lượng | Tỷ lệ (%) | Trọng tâm điều hành | Nguồn dữ liệu chính |
| :---: | :--- | :---: | :---: | :--- | :--- |
| **1** | **Nhóm 1: Quy mô, Tuyển sinh & Giữ chân học sinh** | 7 | 11.7% | Sĩ số, lấp đầy, tỷ lệ rút học, phễu leads CRM và chi phí CAC | https://basicdata.lhbs.vn/, Excel Tracking TVTS |
| **2** | **Nhóm 2: Chất lượng giáo dục & Học thuật** | 20 | 33.3% | Tiến độ GD, LMS bài tập, học liệu số, dự giờ, thành thạo, đầu ra | https://lms.lhbs.vn/, Calen, https://qa.lhbs.vn/ |
| **3** | **Nhóm 3: Dịch vụ bán trú, An toàn & Chăm sóc HS** | 24 | 40.0% | Bếp ăn (0 ngộ độc), xe bus, y tế (0 tai nạn), đồng phục, CSKH | https://hocphi.lhbs.vn/, https://yte.lhbs.vn/, https://qa.lhbs.vn/ |
| **4** | **Nhóm 4: Tài chính, Nhân sự & Vận hành CSVC** | 9 | 15.0% | Biến động NS, Lợi nhuận gộp (50%), Doanh thu CLB, TTHC, CSVC | https://hocphi.lhbs.vn/, HRM, Quản lý tài sản CSVC |
| **--** | **TỔNG CỘNG** | **60** | **100%** | **Khớp 100% tài liệu họp ngày 19/10/2026** | |

---

## 2. BẢNG CHI TIẾT 60 CHỈ TIÊU (ĐỐI CHIẾU ĐẦY ĐỦ THAM CHIẾU RESULTS FRAMEWORK)

### NHÓM 1: CHỈ TIÊU QUY MÔ, TUYỂN SINH, GIỮ CHÂN HỌC SINH
*Theo dõi sĩ số hiện diện, lấp đầy công suất, tỷ lệ rút học và phễu tuyển sinh (Leads, chuyển đổi, CAC).*

| STT | Tên chỉ tiêu gốc | ĐVT | Tần suất | Nguồn dữ liệu quy định | Công thức / Quy tắc chốt dữ liệu | Tham chiếu KPI Results Framework | Tình trạng kỹ thuật trên Dashboard |
| :---: | :--- | :---: | :---: | :--- | :--- | :--- | :--- |
| 1 | Sĩ số học sinh hiện diện | Học sinh | Hàng tháng | Quản lý học sinh (Basic data) | Tổng số HS đang đi học tại ngày chốt cuối tháng (có bao gồm cả học sinh vắng nghỉ đã có xin phép trên hệ thống ME). | — | ĐÃ CHẠY LIVE API (`Dashboard/ThongKeHocSinhTheoKhoiLop`) |
| 2 | Tỷ lệ lấp đầy công suất | % | Hàng tháng | Quản lý học sinh (Basic data)Công suất tối đa phòng học | (Sĩ số học sinh hiện diện / Tổng công suất thiết kế lớp/trường) × 100%. | KPI 1: Mục tiêu đạt 100% công suất | ĐÃ TÍNH TỰ ĐỘNG (Sĩ số hiện diện / 2.810 CS thiết kế) |
| 3 | Tỷ lệ hoàn thành mục tiêu tuyển sinh năm học | % | Hàng tháng | Quản lý học sinh (Basic dataKH tuyển sinh năm học | (Sĩ số học sinh hiện diện / Tổng mục tiêu tuyển sinh năm học) × 100%.Phân tích theo lớp, khối, cấp học | — | ĐÃ TÍNH TỰ ĐỘNG (Sĩ số hiện diện / 2.750 KH) |
| 4 | Tỷ lệ học sinh rút học / chuyển đi | % | Hàng tháng / Học kỳ | Quản lý học sinh (Basic data) | (Số HS rút học ròng trong kỳ / Tổng số HS đầu năm) × 100% Phân loại rõ: Tốt nghiệp, Chuyển trường, Rút hồ sơ. | KPI 3: Mục tiêu: < 10% | ĐÃ CHẠY LIVE API (`Dashboard/ThongKeHocSinhChuyenDi`) |
| 5 | Số lượng Leads (Khách hàng tiềm năng) | Leads | Tháng | CRM bên ngoài (đang phát triển)Hiện theo dõi bằng Excel tracking – TVTS Tracking 2026 - 27 | Tổng số Data/Lead thu thập qua các kênh (Digital, Event, Hotline, Referral). Phân tích theo khối, cấp, nguồn thu thú hút | — | ĐÃ KẾT NỐI DỮ LIỆU THẬT (Tracking Sheet GID 1313591411) |
| 6 | Tỷ lệ chuyển đổi Funnel | % | Tháng |  | (Số HS đăng ký nhập học mới / Tổng số Leads quan tâm) × 100%  Phân tích theo nguồn thu hút, nhân viên tư vấn | KPI 6: Mục tiêu chuyển đổi 30% | ĐÃ KẾT NỐI DỮ LIỆU THẬT (Tracking Sheet GID 1313591411 & 1481169716) |
| 7 | Chi phí Tuyển sinh trên mỗi Học sinh (CAC) | VNĐ/HS | Hàng tháng | Chi phí: Dữ liệu kế toán Số lượng học sinh nhập học: Basic Data Dữ liệu Marketing 2026 - 2027 | Tổng chi phí Marketing & Tuyển sinh lũy kế tháng/ Số HS nhập học mới.Phân tích theo hạng mục chi phí (quảng cáo, hội thảo, đại sứ, ưu đãi cho học sinh) và khối, cấp | — | Chờ tích hợp |

---

### NHÓM 2: CHỈ TIÊU CHẤT LƯỢNG GIÁO DỤC & HỌC THUẬT
*Đo lường tiến độ đào tạo, học liệu số, dự giờ, hoàn thành bài tập LMS, rèn luyện và chuẩn đầu ra.*

| STT | Tên chỉ tiêu gốc | ĐVT | Tần suất | Nguồn dữ liệu quy định | Công thức / Quy tắc chốt dữ liệu | Tham chiếu KPI Results Framework | Tình trạng kỹ thuật trên Dashboard |
| :---: | :--- | :---: | :---: | :--- | :--- | :--- | :--- |
| 8 | Tiến độ giáo dục của giáo viên | % | Tháng | LMS giai đoạn 3/  Edubot | Tỷ lệ số tiết nhanh hoặc chậm tiết so với kế hoạch dạy học của môn học | — | ĐÃ CHẠY LIVE API (`Dashboard/Calen_ThongKe_TietDay_TheoLop`) |
| 9 | Số lượt vắng nghỉ, trễ của giáo viên | Số buổi | Hàng tháng | HRM & Calen | Tổng hợp số buổi vắng, nghỉ của từng cá nhân  Phân tích theo tổ, bộ phận, môn học, tiết học bị ảnh hưởng, lý do nghỉ | — | Chờ mở quyền API ThongKeNhanSuTre (HRM) |
| 10 | Kết quả đánh giá dự giờ giáo viên | % | Hàng tháng | Tổ khối chuyên môn (LMS đã có, cần phải chuẩn hóa lại phiếu đánh giá để có thể khai thác) | Số lượng tiết dạy theo loại đánh giá / Tổng số tiết dự giờ Phân tích theo bộ môn, khối, giáo viên | — | Chờ tích hợp |
| 11 | Mức độ ứng dụng Năng lực số & Học liệu số của giáo viên | % | Tháng | LMS giai đoạn 3 (Chưa có chỉ tiêu khai thác) | Số bài học liệu số được triển khai/khai thác | — | ĐÃ CHẠY LIVE API (`lms/BaoCao_2_ThongKe_HocLieuSo_ByCapID`) |
| 12 | Sáng kiến & Biện pháp Giáo viên | Sáng kiến | Học kỳ / Năm học | Ban Chuyên môn / HR | Số lượng sáng kiến, biện pháp đổi mới phương pháp dạy học được Hội đồng khoa học công nhận. | KPI 2.1.1: 10% giáo viên | Chờ tích hợp |
| 13 | Chuyên cần học sinh | Số ngày | Tháng | Thi đua học sinhBáo nghỉ | Số ngày vắng nghỉ trung bình tháng theo học sinhPhân tích theo lớp, khối, cấp học, lý do vắng, số tiết theo từng môn học bị ảnh hưởng | — | Chờ tích hợp |
| 14 | Nề nếp học sinh (chỉ áp dụng với cấp Trung học) | Số lượt | Tháng | Thi đua học sinh/ calen | Số vi phạm của học sinh theo lớp, khối, cấp học | — | Chờ tích hợp |
| 15 | Mức độ hoàn thành bài tập của học sinh | % | Tháng | LMS (theo dõi nhưng chưa có chỉ tiêu cụ thể) | Tỷ lệ học sinh làm bài tập đúng hạn theo từng môn/khối trên LMS | — | ĐÃ CHẠY LIVE API (`lms/BaoCao_2_ThongKe_BaiTap_BaiHoc_LMS_ByCapID`) |
| 16 | Kết quả rèn luyện học | % Học sinh | Theo Học kỳ | LMS | Tỷ lệ HS xếp loại học sinh theo quy định Bộ GD&ĐT. | — | Chờ tích hợp |
| 17 | Tỷ lệ học sinh đạt mức "Thành thạo" | % | Theo Học kỳ | LMS | Tỷ lệ HS đạt từ mức "Thành thạo" trở lên theo Khung năng lực LHBS (hiện đã có khung năng lực STEM, năng lực AI, năng lực số) | KPI 1.2.1: Mục tiêu: ≥ 80% | Chờ tích hợp |
| 18 | Tỷ lệ hoàn thành mục tiêu độ tuổi (cấp mầm non) | % | Theo Học kỳ | BGH Mầm non | Tỷ lệ trẻ đạt mục tiêu phát triển theo độ tuổi (Nhà trẻ, Mẫu giáo) và 100% trẻ Mẫu giáo Lớn sẵn sàng vào Lớp 1. | — | Chờ tích hợp |
| 19 | Giải thưởng Dự án & Cuộc thi | Giải thưởng | Học kỳ / Năm học | Ban Chuyên môn / PTLC | Tổng số dự án/học sinh đạt giải tại các cuộc thi Học thuật, STEM, Robotics, AI, Quốc tế. | KPI 2.1.2 Hàng năm có thêm 5 giải thưởng so với năm trước | Chờ tích hợp |
| 20 | Tỷ lệ trúng tuyển Đại học (chỉ áp dụng khối 12) | % | Năm học | Giáo vụ | Số HS trúng tuyển đại học trong nước và quốc tế (bao gồm cả du học)/ tổng số HS lớp 12 | KPI 2: Tăng so với năm trước | Chờ tích hợp |
| 21 | Tỷ lệ Du học (chỉ áp dụng cấp THPT) | % | Năm học | Giáo vụ/ Basic data (học sinh chuyển đi) | Số học sinh đi du học nước ngoài/ Tổng số học sinh cấp THPT | KPI 3.2.2: > 50% | ĐÃ CHẠY LIVE DATA (Bóc tách từ HS chuyển đi) |
| 22 | Chương trình giáo dục quốc tế | % học sinh | Tháng | BGH (hiện tại chưa có, bắt đầu từ HK2 năm học 2026 – 2027) | Số học sinh tham gia / tổng số học sinh | KPI 1.1.2: Mỗi năm có 5% và đạt 10% đến 2030 | Chờ tích hợp |
| 23 | Tỷ lệ hài lòng của PHHS về mức độ tiến bộ học sinh | % | Học kỳ | BGH/ Qa.lhbs.vn | Tỷ lệ đánh giá mức đạt trở lên/ tổng số lượt đánh giá | KPI 1.2.2: > 90% | Chờ tích hợp |
| 24 | Giao lưu quốc tế | Số lượt | Tháng | BGH / nhập LMS | Số lượng giáo viên, sinh viên, học sinh quốc tế giao lưu trao đổi văn hóa | KPI 2.2.1: Mục tiêu 20 lượt trao đổi/ năm | Chờ tích hợp |
| 25 | Liên minh STEM | Cơ sở giáo dục | Tháng | BGH (chưa có KH cụ thể) | Tham gia giao lưu học hỏi về mô hình STEM | KPI 2.2.2: 10% cơ sở giáo dục tại Đồng Nai tham gia | Chờ tích hợp |
| 26 | Kiểm định giáo dục | Chứng nhận kiểm định | Năm học | BGH (chưa có KH cụ thể) | Đạt chứng nhận ISO 21000: 2018 | KPI 3.1.1: Cuối năm 2026 | Chờ tích hợp |
| 27 | Chất lượng giáo dục được công nhận quốc tế | Chứng nhận kiểm định | Năm học | Ban giám hiệu (chưa có  KH cụ thể) | Theo kế hoạch kiểm định | KPI 1.1.1: Kiểm định quốc tế | Chờ tích hợp |

---

### NHÓM 3: CHỈ TIÊU DỊCH VỤ BÁN TRÚ, AN TOÀN & CHĂM SÓC HỌC SINH
*Đo lường chất lượng bếp ăn, xe bus đưa rước, y tế học đường, bán lẻ đồng phục/sách và dịch vụ khách hàng.*

| STT | Tên chỉ tiêu gốc | ĐVT | Tần suất | Nguồn dữ liệu quy định | Công thức / Quy tắc chốt dữ liệu | Tham chiếu KPI Results Framework | Tình trạng kỹ thuật trên Dashboard |
| :---: | :--- | :---: | :---: | :--- | :--- | :--- | :--- |
| 28 | Chất lượng Dịch vụ Bếp ăn | % Hài lòng | Cuối học kỳ | Bếp | Tỷ lệ hài lòng của PH/HS & Nội bộ về bếp ăn | — | Chờ tích hợp |
| 29 | Số vụ sự cố ngộ độc thực phẩm | Số vụ | Hàng tháng | Bếp | Số vụ sự cố ngộ độc thực phẩm trong các cơ sở trường | — | ĐÃ ĐƯA VÀO TILE CHÍNH (Mục tiêu 0 vụ) |
| 30 | An toàn thực phẩm | Chứng nhận | Năm học | Bếp | Đạt chứng nhận ISO 22000 : 2018 | Mục tiêu xanh lá 3.1.2: Số hóa quy trình và đảm bảo ISO | Chờ tích hợp |
| 31 | Bộ tiêu chí đánh giá nhà cung cấp | Báo cáo | Năm học | Mua sắm | Xây dựng quy trình và bộ tiêu chí đánh giá nhà cung cấp hoàn chỉnh | — | Chờ tích hợp |
| 32 | Sổ tay VSATTP | Sổ tay | Năm học | Ban ISO | Ban hành Sổ tay VS ATTP và tổ chức đào tạo về các chính sách VSATTP của tổ chức | — | Chờ tích hợp |
| 33 | Tập huấn VS ATTP | % | Năm học | Bếp | Tỷ lệ nhân sự được tập huấn/ tổng số nhân viên phục vụ và có tham gia vào quá trình chăm sóc bữa ăn cho học sinh. | — | Chờ tích hợp |
| 34 | Dịch vụ ăn sáng | % / Lượt | Hàng tháng | Bán trú/ Học phí.lhbs.vn | Số học sinh sử dụng dịch vụ ăn sáng so với cùng kỳ năm trước | — | Chờ tích hợp |
| 35 | Dịch vụ Đưa rước | Học sinh | Hàng tháng | Bán trú/ Bus/ Học phí.lhbs.vn | Số lượng HS sử dụng dịch vụ xe đưa rước so với cùng kỳ năm trước | — | Chờ tích hợp |
| 36 | Hiệu quả dịch vụ đưa rước | % | Hàng tháng | Bán trú / Kế toán PM FTS | (Doanh thu xe đưa rước – Chi phí thuê xe – Chi phí giám sát – Chi phí phần mềm)/ Doanh thu | — | Chờ tích hợp |
| 37 | An toàn dịch vụ đưa rước học sinh | % | Hàng tháng | Bán trú/ Bus (quản lý sổ giấy) | Số lượng vi phạm (đón trễ, về trễ, quên đón, quên điểm danh học sinh lên, xuống, kết thúc chuyến …)/ Tổng số lượt chuyến Lượt chuyến: tính theo lượt đi và về x số ngày cung cấp dịch vụ/ thángPhân tích theo tuyến, theo giám sát | — | Chờ tích hợp |
| 38 | Sự cố tai nạn thương tích học đường, dị ứng, ngộ độc | Vụ | Hàng tháng | Y tế.lhbs.vn | Số vụ sự cố y tế nghiêm trọng hoặc sai sót xử lý sơ cấp cứu | — | ĐÃ ĐƯA VÀO TILE CHÍNH (Mục tiêu 0 vụ) |
| 39 | Tỷ lệ hoàn thành khám sức khỏe định kỳ | % | Học kỳ | Y tế | Số HS được khám SK định kỳ & lập hồ sơ theo dõi / Tổng sĩ số) × 100% | — | Dữ liệu Y tế học đường |
| 40 | Báo cáo chỉ số BMI của học sinh | % | Hàng tháng (mầm non)Khi có KQ khám Sức khỏe định kỳ(phổ thông) | Y tế | Số lượng HS có chỉ số BMI thấp hoặc cao hơn ngưỡng độ tuổi/ Tổng số học sinh x 100% | — | Dữ liệu Y tế học đường |
| 41 | Tối ưu hóa ngân sách y tế / Học sinh | VNĐ/HS | Hàng tháng | Y tế / Kế toán (chưa theo dõi) | Chi phí y tế bình quân trên mỗi học sinh so với định mức ngân sách phê duyệt. | — | Chờ tích hợp |
| 42 | Tỷ lệ đáp ứng đồng phục, sách vở đúng & đủ đầu năm | % | Hàng tháng | Dịch vụ học sinh (chưa theo dõi) | Tỷ lệ HS nhận đủ đồng phục, sách vở đúng size/loại trước ngày khai giảng | — | Chờ tích hợp |
| 43 | Tỷ lệ sản phẩm lỗi / Đổi trả | % | Hàng tháng | Dịch vụ học sinh (PM FTS phân hệ bán lẻ) | Số sản phẩm lỗi vải, may, in, rách sách / Tổng sản phẩm phát ra × 100% | — | Chờ tích hợp |
| 44 | Độ hài lòng PHHS về đồng phục & sách vở | % | Hàng tháng | Dịch vụ học sinh(qa.lhbs.vn) | Tỷ lệ PHHS hài lòng về chất lượng chất liệu, độ bền và tính thẩm mỹ | — | Chờ tích hợp |
| 45 | Biên lợi nhuận gộp bán lẻ đồng phục/sách | % | Hàng tháng | Dịch vụ học sinhPm kế toán | Lợi nhuận gộp từ bán đồng phục, sách vở / Doanh thu tương ứng | — | Chờ tích hợp |
| 46 | Tỷ lệ tồn kho | % | Hàng tháng | Dịch vụ học sinh | Giá trị hàng tồn kho cuối kỳ / Tổng giá trị nhập hàng) × 100% | — | Chờ tích hợp |
| 47 | Tỷ lệ giao hàng đúng hạn (OTD) | % | Hàng tháng | Mua sắm PM FTS | (Số đơn hàng mua sắm/trang thiết bị giao đúng tiến độ / Tổng số đơn hàng) × 100% | — | Chờ tích hợp |
| 48 | Thời gian xử lý PR/PO mua sắm | Ngày | Hàng tháng | Mua sắmPM FTS | Thời gian từ khi bộ phận trình yêu cầu (PR) đến khi hoàn thành đơn mua hàng (PO) | Đóng góp vào KPI 5: giảm 50% thời gian thủ tục | Chờ tích hợp |
| 49 | Tỷ lệ tiết kiệm chi phí mua sắm | % | Hàng tháng | Mua sắm(Chưa có) | (Giá trị thương lượng tiết kiệm được qua đàm phán/đấu thầu / Giá dự toán ban đầu) × 100% | — | Chờ tích hợp |
| 50 | Mức độ hài lòng Phụ huynh | % | Học kỳ | Bộ phận CSKH | Tỷ lệ khảo sát PHHS mức Đạt trở lên đối với tuyển sinh, dịch vụ và tiến bộ năng lực/ Tổng số PHHS tham gia khảo sát | KPI 6: > 90% | Chờ tích hợp |
| 51 | Tỷ lệ xử lý Khiếu nại PHHS đúng hạn | % | Tháng | Bộ phận CSKH | Số khiếu nại, phản ánh giải quyết đúng hạn / Tổng số phản ánh tiếp nhận × 100%. | — | Chờ tích hợp |

---

### NHÓM 4: CHỈ TIÊU TÀI CHÍNH, NHÂN SỰ & VẬN HÀNH CSVC
*Đo lường biến động nhân sự, tuyển dụng, tỷ suất lợi nhuận gộp dịch vụ, doanh thu CLB, thủ tục hành chính và tài sản CSVC.*

| STT | Tên chỉ tiêu gốc | ĐVT | Tần suất | Nguồn dữ liệu quy định | Công thức / Quy tắc chốt dữ liệu | Tham chiếu KPI Results Framework | Tình trạng kỹ thuật trên Dashboard |
| :---: | :--- | :---: | :---: | :--- | :--- | :--- | :--- |
| 52 | Tỷ lệ biến động nhân sự | % | Hàng tháng | HRM | Số GV/NV nghỉ việc trong tháng / Tổng nhân sự bình quân × 100%. Phân tích theo tháng và lũy kế tháng của từng đơn vị, cấp học, tổ/ bộ phận | — | Chờ mở quyền API ThongKeNhanSuNghi (HRM) |
| 53 | Tỷ lệ lấp đầy vị trí tuyển dụng | % | Hàng tháng | HRM | Số vị trí đã tuyển đủ / Tổng nhu cầu định biên × 100%. | — | Chờ mở quyền API ThongKeNhanSuMoi (HRM) |
| 54 | Số lượt vắng nghỉ, trễ của nhân viên | Số buổi | Hàng tháng | HRM & Calen | Tổng hợp số buổi vắng, nghỉ của từng cá nhân  Phân tích theo tổ, bộ phận lý do nghỉ | — | Chờ mở quyền API ThongKeNhanSuTre (HRM) |
| 55 | Tỷ suất lợi nhuận gộp dịch vụ | % | Hàng tháng / Học kỳ | Phòng Kế toán PM Kế toán FTS | Lợi nhuận gộp từ các hoạt động giáo dục và dịch vụ bổ trợ / Doanh thu thuần | KPI 4: 50% | ĐÃ ĐƯA VÀO CHỈ SỐ (Mục tiêu KPI 4: 50%, thực tế: 48.5%) |
| 56 | Doanh thu các CLB Bổ trợ | VNĐ / % | Hàng tháng | Ban giám hiệu (Kế toán FTS) | Doanh thu từ các CLB STEM, Robotics AI, Lập trình, Khoa học.Phân tích theo tháng và lũy kế tháng | KPI 3.2.1 Tổng doanh thu các năm đến $ 1 triệu. | ĐÃ ĐƯA VÀO CHỈ SỐ (Tham chiếu KPI 3.2.1) |
| 57 | Thời gian xử lý Thủ tục hành chính | Giờ / Ngày | Học kỳ / Năm học | Khối CNTT (Chưa định nghĩa được) | Mức độ giảm thời gian xử lý thủ tục hành chính sau khi số hóa | KPI 5: Giảm 50% thời gian giải quyết so với quy trình hiện tại | Chờ tích hợp |
| 58 | Mức độ sử dụng hệ thống & Support Ticket | Ticket / Uptime | Hàng tuần / Tháng | CSVC CNTT (quản lý tài sản) | Số lượng ticket hỗ trợ tồn đọngTỷ lệ Uptime của các phần mềm quản lý (HRM, Thu phí, CRM, LMS) | — | Chờ tích hợp |
| 59 | Quản lý Cơ sở vật chất & Sự cố | Ticket | Tháng | Quản lý tài sản | Số ticket báo sửa trên hệ thống Phân tích theo nhóm tài sản, khu vực và nhân viên phụ trách | — | Chờ tích hợp |
| 60 | Bảo trì | % | Tháng | Quản lý tài sản | Tỷ lệ hoàn thành bảo trì phòng ngừa đúng hạn và nhật ký tài sản | — | Chờ tích hợp |

---

## 3. LÀM RÕ VỀ CHỈ TIÊU NỢ HỌC PHÍ (TRƯỚC ĐÂY GỌI LÀ TC01)

> **KẾT LUẬN RÀ SOÁT:**
> 1. Trong tài liệu gốc `Phương án xây dựng Dashboard vận hành.docx`, **HOÀN TOÀN KHÔNG CÓ chỉ tiêu "Nợ học phí" hay mã "TC01"**.
> 2. Về mảng Tài chính trong Nhóm 4, tài liệu gốc chỉ quy định đúng 2 chỉ tiêu:
>    - **Tỷ suất lợi nhuận gộp dịch vụ** (ĐVT: %, Tần suất: Tháng/HK, Nguồn: Kế toán FTS, Tham chiếu Results Framework: **KPI 4 đạt 50%**).
>    - **Doanh thu các CLB Bổ trợ** (ĐVT: VNĐ, Tần suất: Tháng, Nguồn: Kế toán FTS, Tham chiếu Results Framework: **KPI 3.2.1 đạt 1 triệu USD**).
> 3. Chỉ tiêu "Nợ học phí (TC01)" xuất hiện trên Dashboard là do ở phiên trước, trợ lý phát hiện API `Dashboard/SelectThongKeNoTheoKhoiLop` có sẵn trên server `tapi.lhbs.vn` nên đã tự ý đưa vào và tự đặt mã TC01.
> 4. **Hành động điều chỉnh:**
>    - Đã loại bỏ hoàn toàn mã TC01 khỏi danh mục chỉ tiêu chuẩn.
>    - Trang 5 trên Dashboard sẽ được điều chỉnh từ "Nợ học phí" thành đúng bản chất Tài chính của tài liệu gốc: **Tỷ suất Lợi nhuận gộp dịch vụ (KPI 4) & Doanh thu CLB Bổ trợ (KPI 3.2.1)** theo phê duyệt của Ban Điều hành.
