

CREATE PROC spAPI_AI_Help_Menu 

@ChucNangCanTim NVARCHAR(MAX),
--@Content NVARCHAR(MAX)
@SYS_FunctionRight VARCHAR(50),
@SYS_SystemRight INT
AS
BEGIN
	DECLARE @Prompt NVARCHAR(MAX)
	DECLARE @Content NVARCHAR(MAX)
	SET @Prompt = N'Với vai trò là end user có system right = '+ cast( @SYS_SystemRight as varchar) + N', function right =' + @SYS_FunctionRight+' chỉ cho tôi url ' + @ChucNangCanTim
	set @Content = N'Với data có cấu trúc json như sau {
   "ProjectName": "LHBS LMS System",
   "title": "LMS SYSTEM",
   "apiDomain": "https://tapi.lhbs.vn/",
   "login": "https://login.lhbs.vn/",
   "userInfo": "https://tapi.lhbs.vn/acc/UserInfo/lms",
   "apiFile": "https://file.lhbs.vn/lms/upload/FileData",
   "urlReadFile": "https://file.lhbs.vn/lms/",
   "urlReturnFile": "https://file.lhbs.vn/lms",
   "urlAvatarPhuHuynh": "https://file.lhbs.vn/me/avatarOrigin/",
   "urlAvatarHocSinh": "https://file.lhbs.vn/student/StudentImage/",
   "menuLeft": [
      {
         "name": "Cấp 1 - Giáo viên",
         "icon": "mdi-human-male-board",
         "right": {
            "FunctionRight": [
               "10"
            ],
            "SystemRight": [
               1,
               2,
               5,
               9
            ]
         },
         "submenu": [
            {
               "name": "Danh sách học sinh",
               "url": "/fui-gv-ds-hoc-sinh-lop?capid=1",
               "right": {
                  "SystemRight": [
                     1,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Nhập nhận xét tháng",
               "url": "/gv-nhan-xet-thang?capid=1",
               "right": {
                  "SystemRight": [
                     1,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Xem nhận xét Tháng",
               "url": "/gv-xem-lai-nhan-xet?capid=1",
               "right": {
                  "SystemRight": [
                     1,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Nhập điểm / Đánh giá",
               "url": "/fui-gv-nhap-diem?capid=1",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "GV Bộ Môn gửi điểm",
               "url": "/gv-bm-gui-diem?capid=1",
               "right": {
                  "SystemRight": [
                     2,
                     9
                  ]
               }
            },
            {
               "name": "Duyệt điểm",
               "url": "/gv-duyet-diem-c1",
               "right": {
                  "SystemRight": [
                     1,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Tổng quá trình bảng điểm",
               "url": "/fui-tong-qua-trinh-bang-diem?capid=1",
               "right": {
                  "SystemRight": [
                     1,
                     9
                  ]
               }
            },
            {
               "name": "Xem ý kiến phụ huynh",
               "url": "/gv-xem-y-kien-phu-huynh?capid=1",
               "right": {
                  "SystemRight": [
                     1,
                     9
                  ]
               }
            },
            {
               "name": "Khen thưởng",
               "url": "/gv-khen-thuong?capid=1",
               "right": {
                  "SystemRight": [
                     1,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Chữ kí của tôi",
               "url": "/fui-cap-nhat-chu-ky",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     9
                  ]
               }
            }
         ]
      },
      {
         "name": "Cấp 1 - Tổ trưởng",
         "icon": "mdi-account-tie",
         "right": {
            "FunctionRight": [
               "10"
            ],
            "SystemRight": [
               5,
               9
            ]
         },
         "submenu": [
            {
               "name": "Duyệt điểm",
               "url": "/fui-tt-duyet-diem?capid=1"
            },
            {
               "name": "Duyệt nhận xét tháng",
               "url": "/tt-duyet-nhan-xet-thang?capid=1"
            },
            {
               "name": "TA - Duyệt điểm - Theme",
               "url": "/tt-duyet-diem-theme"
            },
            {
               "name": "Xem duyệt điểm",
               "url": "/tt-xem-duyet-diem?capid=1"
            },
            {
               "name": "Bảng điểm Theo Khối",
               "url": "/bang-diem-chi-tiet-mon-hoc?capid=1"
            },
            {
               "name": "Tổng kết HK",
               "url": "/gv-xem-tong-ket-hoc-ki-c1?capid=1"
            },
            {
               "name": "DS Khen thưởng",
               "url": "/gv-xem-tong-ket-ds-khen-thuong?capid=1"
            },
            {
               "name": "SL Khen thưởng",
               "url": "/gv-xem-tong-ket-ty-le-khen-thuong?capid=1"
            }
         ]
      },
      {
         "name": "Cấp 1 - Ban Giám Hiệu",
         "icon": "mdi-account-tie",
         "right": {
            "FunctionRight": [
               "10"
            ],
            "SystemRight": [
               3,
               9
            ]
         },
         "submenu": [
            {
               "name": "Duyệt điểm",
               "url": "/bgh-duyet-diem?capid=1"
            },
            {
               "name": "Duyệt nhận xét tháng",
               "url": "/tt-duyet-nhan-xet-thang?capid=1"
            },
            {
               "name": "Bảng điểm Theo Khối",
               "url": "/bang-diem-chi-tiet-mon-hoc?capid=1"
            },
            {
               "name": "Tổng kết HK",
               "url": "/gv-xem-tong-ket-hoc-ki-c1?capid=1"
            },
            {
               "name": "DS Khen thưởng",
               "url": "/gv-xem-tong-ket-ds-khen-thuong?capid=1"
            },
            {
               "name": "SL Khen thưởng",
               "url": "/gv-xem-tong-ket-ty-le-khen-thuong?capid=1"
            }
         ]
      },
      {
         "name": "Cấp 2 - Giáo viên",
         "icon": "mdi-human-male-board",
         "right": {
            "FunctionRight": [
               "20"
            ],
            "SystemRight": [
               1,
               2,
               3,
               5,
               9
            ]
         },
         "submenu": [
            {
               "name": "Danh sách học sinh",
               "url": "/fui-gv-ds-hoc-sinh-lop?capid=2",
               "right": {
                  "SystemRight": [
                     1,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Nhập nhận xét tháng",
               "url": "/gv-nhan-xet-thang?capid=2",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Xem nhận xét Tháng",
               "url": "/gv-xem-lai-nhan-xet?capid=2",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Nhập điểm / Đánh giá",
               "url": "/fui-gv-nhap-diem?capid=2",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Xem điểm",
               "url": "/gv-xem-diem?capid=2",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Bảng điểm Theo Khối",
               "url": "/bang-diem-chi-tiet-mon-hoc?capid=2"
            },
            {
               "name": "Tổng kết HK",
               "url": "/gv-xem-tong-ket-hoc-ki?capid=2",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Thống kê Học tập - Rèn luyện",
               "url": "/thong-ke-hoc-luc-hanh-kiem?capid=2",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Tổng quá trình bảng điểm",
               "url": "/fui-tong-qua-trinh-bang-diem?capid=2",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     9
                  ]
               }
            },
            {
               "name": "Xem ý kiến phụ huynh",
               "url": "/gv-xem-y-kien-phu-huynh?capid=2",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     9
                  ]
               }
            },
            {
               "name": "Chữ kí của tôi",
               "url": "/fui-cap-nhat-chu-ky",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     3,
                     9
                  ]
               }
            }
         ]
      },
      {
         "name": "Cấp 2 - Ban Giám Hiệu",
         "icon": "mdi-account-tie",
         "right": {
            "FunctionRight": [
               "20"
            ],
            "SystemRight": [
               3,
               5,
               9
            ]
         },
         "submenu": [
            {
               "name": "Duyệt điểm",
               "url": "/bgh-duyet-diem-c2"
            },
            {
               "name": "Duyệt nhận xét tháng",
               "url": "/tt-duyet-nhan-xet-thang?capid=2"
            },
            {
               "name": "Xem duyệt điểm",
               "url": "/tt-xem-duyet-diem?capid=2"
            },
            {
               "name": "Bảng điểm Theo Khối",
               "url": "/bang-diem-chi-tiet-mon-hoc?capid=2"
            },
            {
               "name": "Tổng kết HK",
               "url": "/gv-xem-tong-ket-hoc-ki?capid=2"
            },
            {
               "name": "Thống kê Học tập - Rèn luyện",
               "url": "/thong-ke-hoc-luc-hanh-kiem?capid=2"
            }
         ]
      },
      {
         "name": "Cấp 3 - Giáo viên",
         "icon": "mdi-human-male-board",
         "right": {
            "FunctionRight": [
               "30"
            ],
            "SystemRight": [
               1,
               2,
               3,
               5,
               9
            ]
         },
         "submenu": [
            {
               "name": "Danh sách học sinh",
               "url": "/fui-gv-ds-hoc-sinh-lop?capid=3",
               "right": {
                  "SystemRight": [
                     1,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Nhập Nhận xét Tháng",
               "url": "/gv-nhan-xet-thang?capid=3",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Xem nhận xét Tháng",
               "url": "/gv-xem-lai-nhan-xet?capid=3",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Nhập điểm / Đánh giá",
               "url": "/fui-gv-nhap-diem?capid=3",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Xem điểm",
               "url": "/gv-xem-diem?capid=3",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Bảng điểm Theo Khối",
               "url": "/bang-diem-chi-tiet-mon-hoc?capid=3"
            },
            {
               "name": "Xem tổng kết HK",
               "url": "/gv-xem-tong-ket-hoc-ki?capid=3",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Thống kê Học tập - Rèn luyện",
               "url": "/thong-ke-hoc-luc-hanh-kiem?capid=3",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Tổng quá trình bảng điểm",
               "url": "/fui-tong-qua-trinh-bang-diem?capid=3",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Xem ý kiến phụ huynh",
               "url": "/gv-xem-y-kien-phu-huynh?capid=3",
               "right": {
                  "SystemRight": [
                     1,
                     3,
                     5,
                     9
                  ]
               }
            },
            {
               "name": "Chữ kí của tôi",
               "url": "/fui-cap-nhat-chu-ky",
               "right": {
                  "SystemRight": [
                     1,
                     2,
                     3,
                     5,
                     9
                  ]
               }
            }
         ]
      },
      {
         "name": "Cấp 3 - Ban Giám Hiệu",
         "icon": "mdi-account-tie",
         "right": {
            "FunctionRight": [
               "30"
            ],
            "SystemRight": [
               3,
               5,
               9
            ]
         },
         "submenu": [
            {
               "name": "Duyệt điểm",
               "url": "/bgh-duyet-diem-c3"
            },
            {
               "name": "Duyệt nhận xét tháng",
               "url": "/tt-duyet-nhan-xet-thang?capid=3"
            },
            {
               "name": "Xem duyệt điểm",
               "url": "/tt-xem-duyet-diem?capid=3"
            },
            {
               "name": "Bảng điểm Theo Khối",
               "url": "/bang-diem-chi-tiet-mon-hoc?capid=3"
            },
            {
               "name": "Tổng kết Học Kì",
               "url": "/gv-xem-tong-ket-hoc-ki?capid=3"
            },
            {
               "name": "Thống kê Học tập - Rèn luyện",
               "url": "/thong-ke-hoc-luc-hanh-kiem?capid=3"
            }
         ]
      },
      {
         "name": "Báo cáo chung",
         "icon": "mdi-clipboard-text-outline",
         "right": {
            "FunctionRight": [
               "10",
               "20",
               "30"
            ],
            "SystemRight": [
               3,
               5,
               9
            ]
         },
         "submenu": [
            {
               "name": "C1-Tổng quan chung",
               "url": "/bgh-thong-ke-danh-hieu?CapID=1"
            },
            {
               "name": "C2-Tổng quan chung",
               "url": "/bgh-thong-ke-danh-hieu?CapID=2"
            },
            {
               "name": "C3-Tổng quan chung",
               "url": "/bgh-thong-ke-danh-hieu?CapID=3"
            },
            {
               "name": "C2-Thống kê HL&RL",
               "url": "/thong-ke-hoc-luc-hanh-kiem?capid=3"
            },
            {
               "name": "C3-Thống kê HL&RL",
               "url": "/thong-ke-hoc-luc-hanh-kiem?capid=3"
            },
            {
               "name": "C1-Phân phối điểm",
               "url": "/dashboard-tong-quan-tinh-hinh-hoc-tap-cap-1"
            },
            {
               "name": "C1-Điểm MH theo Khối",
               "url": "/thongke-monhoc-theokhoi?capid=1"
            },
            {
               "name": "C2-Phân phối điểm",
               "url": "/dashboard-tong-quan-tinh-hinh-hoc-tap-cap-2"
            },
            {
               "name": "C2-Điểm MH theo Khối",
               "url": "/thongke-monhoc-theokhoi?capid=2"
            },
            {
               "name": "C3-Phân phối điểm",
               "url": "/dashboard-tong-quan-tinh-hinh-hoc-tap-cap-3"
            },
            {
               "name": "C3-Điểm MH theo Khối",
               "url": "/thongke-monhoc-theokhoi?capid=3"
            }
         ]
      },
      {
         "name": "Báo cáo Tiếng Anh",
         "icon": "mdi-clipboard-text-outline",
         "right": {
            "FunctionRight": [
               "10",
               "20",
               "30"
            ],
            "SystemRight": [
               3,
               5,
               9
            ]
         },
         "submenu": [
            {
               "name": "C1-Tổng quan",
               "url": "/dashboard-tong-quan-tinh-hinh-hoc-tap-ta-cap-1",
               "right": {
                  "FunctionRight": [],
                  "SystemRight": [
                     9999999999999
                  ]
               }
            },
            {
               "name": "C1-Phát triển Năng lực",
               "url": "/dashboard-phat-trien-nang-luc-ta-cap-1",
               "right": {
                  "FunctionRight": [],
                  "SystemRight": [
                     9999999999999
                  ]
               }
            },
            {
               "name": "C2-Kỹ năng-Chủ đề",
               "url": "/dashboard-tong-quan-tinh-hinh-hoc-tap-ta-cap-2"
            },
            {
               "name": "C2-Phát triển Năng lực",
               "url": "/dashboard-phat-trien-nang-luc-ta-cap-2"
            },
            {
               "name": "C3-Kỹ năng-Chủ đề",
               "url": "/dashboard-tong-quan-tinh-hinh-hoc-tap-ta-cap-3"
            },
            {
               "name": "C3-Phát triển Năng lực",
               "url": "/dashboard-phat-trien-nang-luc-ta-cap-3"
            },
            {
               "name": "C3 - IELTS",
               "url": "/dashboard-tinh-hinh-hoc-tap-ta-cap-3-ielts"
            },
            {
               "name": "C3 - Thống kê TA2",
               "url": "/thong-ke-bang-diem-AV2"
            },
            {
               "name": "C3 - Theme",
               "url": "/English-report"
            },
            {
               "name": "C3 - Grade",
               "url": "/dashboard-Theme-TA2-Theo-Khoi"
            }
         ]
      },
      {
         "name": "Khen thưởng cuối năm",
         "icon": "mdi-clipboard-text-outline",
         "right": {
            "FunctionRight": [
               "10",
               "20",
               "30"
            ],
            "SystemRight": [
               5,
               9
            ]
         },
         "submenu": [
            {
               "name": "TH-Tổng kết HK",
               "url": "/gv-xem-tong-ket-hoc-ki-c1?capid=1"
            },
            {
               "name": "TH-Danh sách KT",
               "url": "/gv-xem-tong-ket-ds-khen-thuong?capid=1"
            },
            {
               "name": "TH-Số lượng KT",
               "url": "/gv-xem-tong-ket-ty-le-khen-thuong?capid=1"
            },
            {
               "name": "THCS-Tổng kết HK",
               "url": "/gv-xem-tong-ket-hoc-ki?capid=2"
            },
            {
               "name": "THPT-Tổng kết HK",
               "url": "/gv-xem-tong-ket-hoc-ki?capid=3"
            },
            {
               "name": "Cập nhật Danh Hiệu",
               "url": "/sys-danh-hieu"
            },
            {
               "name": "Cập nhật Số/Ngày QĐ",
               "url": "/cap-nhat-so-ngay-qd"
            }
         ]
      },
      {
         "name": "Hệ thống",
         "icon": "mdi-security",
         "right": {
            "FunctionRight": [
               "10",
               "20",
               "30"
            ],
            "SystemRight": [
               9
            ]
         },
         "submenu": [
            {
               "name": "Phân công giáo viên",
               "url": "/bgh-phan-cong-giao-vien"
            },
            {
               "name": "Danh sách chữ kí giáo viên",
               "url": "/fui-chu-ky"
            },
            {
               "name": "Danh sách giáo viên",
               "url": "/ds-giao-vien"
            },
            {
               "name": "Môn học lớp",
               "url": "/fui-mon-hoc-lop"
            },
            {
               "name": "Môn học - Tiểu học",
               "url": ""
            },
            {
               "name": "Môn học - THCS",
               "url": ""
            },
            {
               "name": "Môn học - THPT",
               "url": ""
            },
            {
               "name": "Đồng bộ điểm - Tiểu học",
               "url": "/gv-xem-diem-c1"
            },
            {
               "name": "Đồng bộ điểm - THCS",
               "url": "/gv-xem-diem?capid=2"
            },
            {
               "name": "Đồng bộ điểm - THPT",
               "url": "/gv-xem-diem?capid=3"
            },
            {
               "name": "Cấu trúc điểm - Tiểu học",
               "url": "/cau-hinh-mau-bang-diem?capid=1"
            },
            {
               "name": "Cấu trúc điểm - THCS",
               "url": "/cau-hinh-mau-bang-diem?capid=2"
            },
            {
               "name": "Cấu trúc điểm - THPT",
               "url": "/cau-hinh-mau-bang-diem?capid=3"
            }
         ]
      },
      {
         "name": "Hướng dẫn sử dụng",
         "icon": "mdi-book",
         "url": ""
      },
      {
         "name": "Hỗ trợ sự cố",
         "icon": "mdi-help-circle-outline",
         "url": "/support"
      }
   ],
   "menuComponent": [
      {
         "el": "uc-vaitro"
      }
   ]
}'


	select dbo.httpAPI('POST','https://api.fap.vn/ai/auth/AI_Responses','',
			N'{
			"Prompt":' + dbo.JSON_Stringify(@Prompt)+ ',
			"Content":' + dbo.JSON_Stringify(@Content)+ '
			}')

END