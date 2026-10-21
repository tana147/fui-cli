-- SCRIPT KHÔI PHỤC LẠI 6 CỘT VÀ DỮ LIỆU ĐÃ DROP NGÀY 21/10/2026

-- 1. Tạo lại 6 cột trong các bảng
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AnPham') AND name = 'TapSoTrang')
    ALTER TABLE AnPham ADD TapSoTrang NVARCHAR(100) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AnPham') AND name = 'ThangDang')
    ALTER TABLE AnPham ADD ThangDang TINYINT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AnPham') AND name = 'TheLoaiBienSoanID')
    ALTER TABLE AnPham ADD TheLoaiBienSoanID INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AnPham_TacGia') AND name = 'VaiTroID')
    ALTER TABLE AnPham_TacGia ADD VaiTroID INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AnPham_TacGia') AND name = 'Is_TacGiaLienHe')
    ALTER TABLE AnPham_TacGia ADD Is_TacGiaLienHe BIT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('ThiKHCN_KhenThuong') AND name = 'NoiCapVanBang')
    ALTER TABLE ThiKHCN_KhenThuong ADD NoiCapVanBang NVARCHAR(255) NULL;

-- 2. Tạo lại các ràng buộc khóa ngoại (Foreign Keys)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_AnPham_TheLoaiBienSoan')
    ALTER TABLE AnPham ADD CONSTRAINT FK_AnPham_TheLoaiBienSoan FOREIGN KEY (TheLoaiBienSoanID) REFERENCES tblHDKH_DM_TheLoaiBienSoan(ID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_AnPhamTacGia_VaiTro')
    ALTER TABLE AnPham_TacGia ADD CONSTRAINT FK_AnPhamTacGia_VaiTro FOREIGN KEY (VaiTroID) REFERENCES tblHDKH_DM_VaiTro(ID);

-- 3. Khôi phục lại dữ liệu của hồ sơ bài báo AnPhamID 8579 (cô Văn Thị Bích nộp lúc 07:12:41)
UPDATE AnPham
SET TapSoTrang = N'SỐ 27/2026'
WHERE AnPhamID = 8579;

UPDATE AnPham_TacGia
SET VaiTroID = 7, Is_TacGiaLienHe = 0
WHERE AnPhamID = 8579 AND MaNhanVien = 'NV0000563';
