<template>
	<div>
		<uc-topbar :selectedYear="selectedYear" :dsNam="dsNam" :hasData="hasData" @on-year-change="handleYearChange"
			@on-get-summary="getSummary" @on-submit="submit" @on-export="exportPDF" @on-export-excel="exportExcel" />

		<uc-stats v-if="hasData" :stats="statsData" />

		<uc-main-view v-if="hasData" :ThongKeTheoKhoa="ThongKeTheoKhoa" :dsDat="dsDat" :dsKhongDat="dsKhongDat"
			:headerTableTheoKhoa="headerTableTheoKhoa" :headerTableNhanVien="headerTableNhanVien" />

		<v-card v-else class="d-flex flex-column align-center justify-center pa-8 rounded-sm elevation-1"
			min-height="250" style="border: 2px dashed #e0e0e0;">
			<v-icon size="64" color="grey lighten-1">mdi-database-search-outline</v-icon>
			<div class="text-h6 grey--text text--darken-1 mt-4">Vui lòng chọn năm học và bấm "Xem trước báo cáo"</div>
			<div class="text-caption grey--text mt-1">Dữ liệu tổng hợp sẽ được hiển thị trực quan sau khi tải thành
				công.</div>
		</v-card>
	</div>
</template>

<script>
	export default {
		name: "uc-main-page",
		data() {
			return {
				selectedYear: null,
				ThongKeTheoKhoa: [],
				dsDat: [],
				dsKhongDat: [],
				hasData: false,
				headerTableTheoKhoa: [
					{ "title": "Đơn vị", "key": "DonVi", "align": "left" },
					{ "title": "Tổng số GV", "key": "TongSoGiangVien", "align": "end" },
					{ "title": "Đạt", "key": "Dat", "align": "end" },
					{ "title": "Chưa đạt", "key": "KhongDat", "align": "end" },
					{ "title": "% Đạt", "key": "TyLeDat", "align": "end", "el": "span", "innerHTML": "{{item.TyLeDat}} %" },
					{ "title": "% Chưa đạt", "key": "TyLeKhongDat", "align": "end", "el": "span", "innerHTML": "{{item.TyLeKhongDat}} %" }
				],
				headerTableNhanVien: [
					{ "title": "Mã NV", "key": "MaNV" },
					{ "title": "Họ tên", "key": "HoTen" },
					{ "title": "Đơn vị", "key": "TenDonVi" },
					{ "title": "Nhiệm vụ", "key": "NhiemVuTrongDonVi", "align": "end" },
					{ "title": "Miễn giảm", "key": "MienGiamDinhMuc", "align": "end", "el": "span", "innerHTML": "{{item.MienGiamDinhMuc}} giờ" },
					{ "title": "Giờ quy đổi", "key": "SoGioQuyDoiTrongNam", "align": "end", "el": "span", "innerHTML": "{{item.SoGioQuyDoiTrongNam}} giờ" },
					{ "title": "Nợ năm trước", "key": "SoGioThieuNamTruoc", "align": "end", "el": "span", "innerHTML": "{{item.SoGioThieuNamTruoc}} giờ" },
					{ "title": "Bảo lưu trước", "key": "SoGioBaoLuuNamTruoc", "align": "end", "el": "span", "innerHTML": "{{item.SoGioBaoLuuNamTruoc}} giờ" },
					{ "title": "Giờ chuẩn duyệt", "key": "SoGioChuanDuocChuyen", "align": "end", "el": "span", "innerHTML": "{{item.SoGioChuanDuocChuyen}} giờ" },
					{ "title": "Nghĩa vụ", "key": "NghiaVuTrongNam", "align": "end", "el": "span", "innerHTML": "{{item.NghiaVuTrongNam}} giờ" },
					{ "title": "Phải thực hiện", "key": "SoGioPhaiThucHien", "align": "end", "el": "span", "innerHTML": "{{item.SoGioPhaiThucHien}} giờ" },
					{ "title": "Bảo lưu/Thiếu", "key": "SoGioBaoLuu_Thieu", "align": "end", "el": "span", "innerHTML": "{{item.SoGioBaoLuu_Thieu}} giờ" },
					{ "title": "Bảo lưu sau", "key": "SoGioBaoLuuNamTiepTheo", "align": "end", "el": "span", "innerHTML": "{{item.SoGioBaoLuuNamTiepTheo}} giờ" },
					{ "title": "Lý do miễn", "key": "LyDoMienGiam", "align": "end" }
				]
			};
		},
		computed: {
			dsNam() {
				const year = new Date().getFullYear();
				let arrYear = [];
				for (let i = 0; i <= 4; i++) arrYear.push(year - i);
				return arrYear;
			},
			statsData() {
				let tongGV = 0;
				const dat = this.dsDat ? this.dsDat.length : 0;
				const khongDat = this.dsKhongDat ? this.dsKhongDat.length : 0;
	
				if (this.ThongKeTheoKhoa && this.ThongKeTheoKhoa.length > 0) {
					tongGV = this.ThongKeTheoKhoa.reduce((acc, curr) => acc + (Number(curr.TongSoGiangVien) || 0), 0);
				} else {
					tongGV = dat + khongDat;
				}
	
				const tyLeDat = tongGV > 0 ? ((dat / tongGV) * 100).toFixed(1) : 0;
				const tyLeKhongDat = tongGV > 0 ? ((khongDat / tongGV) * 100).toFixed(1) : 0;
	
				return {
					tongGV,
					dat,
					khongDat,
					tyLeDat,
					tyLeKhongDat
				};
			}
		},
		methods: {
			async handleYearChange(year) {
				this.selectedYear = year;
				if (year) {
					await this.getSummary();
				} else {
					this.hasData = false;
					this.ThongKeTheoKhoa = [];
					this.dsDat = [];
					this.dsKhongDat = [];
				}
			},
			async getSummary() {
				if (!this.selectedYear) {
					Vue.$toast.info("Vui lòng chọn năm học!", { position: 'top' });
					return;
				}
				const res = await ajaxCALLPromise('/HDKH_Admin_GetBaoCaoTongHop', { NamHoc: this.selectedYear });
				if (res) {
					this.ThongKeTheoKhoa = res[0] || [];
					this.dsDat = res[1] || [];
					this.dsKhongDat = res[2] || [];
					this.hasData = true;
				}
			},
			submit() {
				confirm({
					icon: "mdi mdi-alert",
					type: "red",
					title: `<b>Lưu ý</b>`,
					message: `<i>Hành động này sẽ tính toán và lưu trữ vĩnh viễn kết quả NCKH của năm học ${this.selectedYear}. Dữ liệu bảo lưu và còn thiếu sẽ được chuyển sang năm học tiếp theo. Bạn có chắc chắn muốn tiếp tục? Hành động này không thể hoàn tác.</i>`,
					action: async () => {
						try {
							const res = await ajaxCALLPromise('/HDKH_Admin_ChotSoNamHoc', { NamHocCanChot: this.selectedYear });
							if (res) {
								Vue.$toast.success("Chốt sổ thành công!", { position: 'top' });
								this.selectedYear = null;
								this.ThongKeTheoKhoa = [];
								this.dsDat = [];
								this.dsKhongDat = [];
								this.hasData = false;
							}
						} catch (error) {
							Vue.$toast.error("Có lỗi xảy ra!", { position: 'top' });
						}
					}
				});
			},
			exportPDF() {
				let summaryTheoKhoa = {
					TongSoGiangVien: 0,
					Dat: 0,
					KhongDat: 0,
					TyLeDat: 0,
					TyLeKhongDat: 0
				};
	
				const tableThongKeTheoKhoa = {
					headerRows: 1,
					widths: [30, '*', '*', 60, 60, 60, 60, '*'],
					body: [
						[
							{ text: 'STT', style: 'tableHeader' },
							{ text: 'Đơn vị', style: 'tableHeader' },
							{ text: 'Tổng số giảng viên', style: 'tableHeader' },
							{ text: 'Đạt', style: 'tableHeader' },
							{ text: 'Không đạt', style: 'tableHeader' },
							{ text: 'Tỷ lệ đạt', style: 'tableHeader' },
							{ text: 'Tỷ lệ không đạt', style: 'tableHeader' },
							{ text: 'Ghi chú', style: 'tableHeader' }
						],
						...this.ThongKeTheoKhoa.map((item, index) => {
							summaryTheoKhoa.TongSoGiangVien += (Number(item.TongSoGiangVien) || 0);
							summaryTheoKhoa.Dat += (Number(item.Dat) || 0);
							summaryTheoKhoa.KhongDat += (Number(item.KhongDat) || 0);
							summaryTheoKhoa.TyLeDat += (Number(item.TyLeDat) || 0);
							summaryTheoKhoa.TyLeKhongDat += (Number(item.TyLeKhongDat) || 0);
							return [
								{ text: index + 1, style: 'tableCellCenter' },
								{ text: item.DonVi || '', style: 'tableCellLeft' },
								{ text: item.TongSoGiangVien || 0, style: 'tableCellCenter' },
								{ text: item.Dat || 0, style: 'tableCellCenter' },
								{ text: item.KhongDat || 0, style: 'tableCellCenter' },
								{ text: `${item.TyLeDat || 0}%`, style: 'tableCellCenter' },
								{ text: `${item.TyLeKhongDat || 0}%`, style: 'tableCellCenter' },
								{ text: '', style: 'tableCellCenter' }
							];
						})
					]
				};
	
				const KhoaLength = this.ThongKeTheoKhoa.length || 1;
				tableThongKeTheoKhoa.body.push([
					{ text: '', style: 'tableCellCenter', colSpan: 2 },
					{},
					{ text: summaryTheoKhoa.TongSoGiangVien, style: 'tableCellCenter' },
					{ text: summaryTheoKhoa.Dat, style: 'tableCellCenter' },
					{ text: summaryTheoKhoa.KhongDat, style: 'tableCellCenter' },
					{ text: `${(summaryTheoKhoa.TyLeDat / KhoaLength).toFixed(2)}%`, style: 'tableCellCenter' },
					{ text: `${(summaryTheoKhoa.TyLeKhongDat / KhoaLength).toFixed(2)}%`, style: 'tableCellCenter' },
					{ text: '', style: 'tableCellCenter' }
				]);
	
				const dsDatLength = this.dsDat.length;
				const tableDsDat = {
					headerRows: 1,
					widths: [30, 60, 60, 80, 60, '*', '*', '*', '*', '*', '*', 80],
					body: [
						[
							{ text: 'STT', style: 'tableHeader' },
							{ text: 'Mã NV', style: 'tableHeader' },
							{ text: 'Họ tên', style: 'tableHeader' },
							{ text: 'Đơn vị', style: 'tableHeader' },
							{ text: 'Nhiệm vụ trong đơn vị', style: 'tableHeader' },
							{ text: 'Miễn/giảm định mức hoạt động KHCN', style: 'tableHeader' },
							{ text: 'Số giờ chuẩn quy đổi trong năm', style: 'tableHeader' },
							{ text: 'Số giờ chuẩn được chuyển', style: 'tableHeader' },
							{ text: 'Nghĩa vụ trong năm', style: 'tableHeader' },
							{ text: 'Số giờ chuẩn phải thực hiện', style: 'tableHeader' },
							{ text: 'Đánh giá kết quả hoạt động KHCN', style: 'tableHeader' },
							{ text: 'Lý do Miễn/giảm định mức hoạt động KHCN', style: 'tableHeader' }
						],
						...this.dsDat.map((item, index) => [
							{ text: index + 1, style: 'tableCellCenter' },
							{ text: item.MaNV || '', style: 'tableCellLeft' },
							{ text: item.HoTen || '', style: 'tableCellLeft' },
							{ text: item.TenDonVi || '', style: 'tableCellLeft' },
							{ text: item.NhiemVuTrongDonVi || '', style: 'tableCellLeft' },
							{ text: item.MienGiamDinhMuc || 0, style: 'tableCellCenter' },
							{ text: item.SoGioQuyDoiTrongNam || 0, style: 'tableCellCenter' },
							{ text: item.SoGioChuanDuocChuyen || 0, style: 'tableCellCenter' },
							{ text: item.NghiaVuTrongNam || 0, style: 'tableCellCenter' },
							{ text: item.SoGioPhaiThucHien || 0, style: 'tableCellCenter' },
							{ text: item.DanhGiaKetQua || '', style: 'tableCellCenter' },
							{ text: item.LyDoMienGiam || '', style: 'tableCellLeft' }
						])
					]
				};
	
				const dsKhongDatLength = this.dsKhongDat.length;
				const tableDsKhongDat = {
					headerRows: 1,
					widths: [30, 60, 60, 80, 60, '*', '*', '*', '*', '*', '*', 80],
					body: [
						[
							{ text: 'STT', style: 'tableHeader' },
							{ text: 'Mã NV', style: 'tableHeader' },
							{ text: 'Họ tên', style: 'tableHeader' },
							{ text: 'Đơn vị', style: 'tableHeader' },
							{ text: 'Nhiệm vụ trong đơn vị', style: 'tableHeader' },
							{ text: 'Miễn/giảm định mức hoạt động KHCN', style: 'tableHeader' },
							{ text: 'Số giờ chuẩn quy đổi trong năm', style: 'tableHeader' },
							{ text: 'Số giờ chuẩn được chuyển', style: 'tableHeader' },
							{ text: 'Nghĩa vụ trong năm', style: 'tableHeader' },
							{ text: 'Số giờ chuẩn phải thực hiện', style: 'tableHeader' },
							{ text: 'Đánh giá kết quả hoạt động KHCN', style: 'tableHeader' },
							{ text: 'Lý do Miễn/giảm định mức hoạt động KHCN', style: 'tableHeader' }
						],
						...this.dsKhongDat.map((item, index) => [
							{ text: index + 1, style: 'tableCellCenter' },
							{ text: item.MaNV || '', style: 'tableCellLeft' },
							{ text: item.HoTen || '', style: 'tableCellLeft' },
							{ text: item.TenDonVi || '', style: 'tableCellLeft' },
							{ text: item.NhiemVuTrongDonVi || '', style: 'tableCellLeft' },
							{ text: item.MienGiamDinhMuc || 0, style: 'tableCellCenter' },
							{ text: item.SoGioQuyDoiTrongNam || 0, style: 'tableCellCenter' },
							{ text: item.SoGioChuanDuocChuyen || 0, style: 'tableCellCenter' },
							{ text: item.NghiaVuTrongNam || 0, style: 'tableCellCenter' },
							{ text: item.SoGioPhaiThucHien || 0, style: 'tableCellCenter' },
							{ text: item.DanhGiaKetQua || '', style: 'tableCellCenter' },
							{ text: item.LyDoMienGiam || '', style: 'tableCellLeft' }
						])
					]
				};
	
				const docDefinition = {
					pageSize: 'A4',
					pageOrientation: 'landscape',
					pageMargins: [40, 30, 40, 0],
					content: [
						{
							columns: [
								{
									width: '50%',
									text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG\nTRUNG TÂM NCKH&ƯD',
									style: 'headerCenter'
								},
								{
									width: '50%',
									text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\nĐộc lập – Tự do – Hạnh phúc',
									style: 'headerCenter'
								}
							]
						},
						{ text: ' ', margin: [0, 5] },
						{
							text: `BÁO CÁO KẾT QUẢ\nTHỰC HIỆN NGHĨA VỤ NGHIÊN CỨU KHOA HỌC NĂM HỌC ${this.selectedYear}`,
							style: 'title',
							alignment: 'center'
						},
						{
							text: '(Kèm theo Báo cáo số ........./BC-TT.NCKH&UD ngày ...... tháng ...... năm .......\ncủa Trung tâm Nghiên cứu Khoa học và Ứng dụng)',
							style: 'subTitle',
							alignment: 'center',
							margin: [0, 0, 0, 10]
						},
						{
							table: tableThongKeTheoKhoa,
							layout: {
								fillColor: function (rowIndex, node, columnIndex) {
									return (rowIndex === 0) ? '#CCCCCC' : null;
								},
								hLineWidth: function (i, node) { return 0.5; },
								vLineWidth: function (i, node) { return 0.5; },
								hLineColor: function (i, node) { return '#000'; },
								vLineColor: function (i, node) { return '#000'; }
							}
						},
						{ text: '\n' },
						{
							columns: [
								{
									width: '50%',
									text: 'KT. HIỆU TRƯỞNG\nPHÓ HIỆU TRƯỞNG\n\n\n\n\n\nNguyễn Vũ Quỳnh',
									alignment: 'center',
									bold: true
								},
								{
									width: '50%',
									text: 'GIÁM ĐỐC\n\n\n\n\n\n\nNguyễn Thanh Sơn',
									alignment: 'center',
									bold: true
								}
							]
						},
						{
							pageBreak: 'before',
							columns: [
								{
									width: '50%',
									text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG\nTRUNG TÂM NCKH&ƯD',
									style: 'headerCenter'
								},
								{
									width: '50%',
									text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\nĐộc lập – Tự do – Hạnh phúc',
									style: 'headerCenter'
								}
							]
						},
						{ text: ' ', margin: [0, 5] },
						{
							text: `DANH SÁCH\nGIẢNG VIÊN ĐẠT NGHĨA VỤ NGHIÊN CỨU KHOA HỌC NĂM HỌC ${this.selectedYear}`,
							style: 'title',
							alignment: 'center'
						},
						{
							text: '(Kèm theo Báo cáo số ........./BC-TT.NCKH&UD ngày ...... tháng ...... năm .......\ncủa Trung tâm Nghiên cứu Khoa học và Ứng dụng) ',
							style: 'subTitle',
							alignment: 'center',
							margin: [0, 0, 0, 10]
						},
						{
							table: tableDsDat,
							layout: {
								fillColor: function (rowIndex, node, columnIndex) {
									return (rowIndex === 0) ? '#CCCCCC' : null;
								},
								hLineWidth: function (i, node) { return 0.5; },
								vLineWidth: function (i, node) { return 0.5; },
								hLineColor: function (i, node) { return '#000'; },
								vLineColor: function (i, node) { return '#000'; }
							}
						},
						{
							text: `Danh sách có ${dsDatLength} giảng viên`,
							margin: [0, 5]
						},
						{
							columns: [
								{
									width: '50%',
									text: 'KT. HIỆU TRƯỞNG\nPHÓ HIỆU TRƯỞNG\n\n\n\n\n\nNguyễn Vũ Quỳnh',
									alignment: 'center',
									bold: true
								},
								{
									width: '50%',
									text: 'GIÁM ĐỐC\n\n\n\n\n\n\nNguyễn Thanh Sơn',
									alignment: 'center',
									bold: true
								}
							]
						},
						{
							pageBreak: 'before',
							columns: [
								{
									width: '50%',
									text: 'TRƯỜNG ĐẠI HỌC LẠC HỒNG\nTRUNG TÂM NCKH&ƯD',
									style: 'headerCenter'
								},
								{
									width: '50%',
									text: 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\nĐộc lập – Tự do – Hạnh phúc',
									style: 'headerCenter'
								}
							]
						},
						{ text: ' ', margin: [0, 5] },
						{
							text: `DANH SÁCH\nGIẢNG VIÊN KHÔNG ĐẠT NGHĨA VỤ NGHIÊN CỨU KHOA HỌC NĂM HỌC ${this.selectedYear}`,
							style: 'title',
							alignment: 'center'
						},
						{
							text: '(Kèm theo Báo cáo số ........./BC-TT.NCKH&UD ngày ...... tháng ...... năm .......\ncủa Trung tâm Nghiên cứu Khoa học và Ứng dụng) ',
							style: 'subTitle',
							alignment: 'center',
							margin: [0, 0, 0, 10]
						},
						{
							table: tableDsKhongDat,
							layout: {
								fillColor: function (rowIndex, node, columnIndex) {
									return (rowIndex === 0) ? '#CCCCCC' : null;
								},
								hLineWidth: function (i, node) { return 0.5; },
								vLineWidth: function (i, node) { return 0.5; },
								hLineColor: function (i, node) { return '#000'; },
								vLineColor: function (i, node) { return '#000'; }
							}
						},
						{
							text: `Danh sách có ${dsKhongDatLength} giảng viên`,
							margin: [0, 5]
						},
						{
							columns: [
								{
									width: '50%',
									text: 'KT. HIỆU TRƯỞNG\nPHÓ HIỆU TRƯỞNG\n\n\n\n\n\nNguyễn Vũ Quỳnh',
									alignment: 'center',
									bold: true
								},
								{
									width: '50%',
									text: 'GIÁM ĐỐC\n\n\n\n\n\n\nNguyễn Thanh Sơn',
									alignment: 'center',
									bold: true
								}
							]
						}
					],
					styles: {
						headerLeft: { bold: true, fontSize: 11 },
						headerRight: { bold: true, fontSize: 11 },
						headerCenter: { bold: true, fontSize: 11, alignment: 'center' },
						title: { bold: true, fontSize: 12 },
						subTitle: { italic: true, fontSize: 10 },
						tableHeader: { bold: true, fontSize: 10, alignment: 'center' },
						tableCellLeft: { fontSize: 10, alignment: 'left' },
						tableCellCenter: { fontSize: 10, alignment: 'center' },
						tableCellRightr: { fontSize: 10, alignment: 'right' }
					}
				};
	
				pdfMake.createPdf(docDefinition).download(`bao-cao-tong-ket-${this.selectedYear}.pdf`);
			},
			exportExcel() {
				const excelSheets = [
					{ name: 'Thong_Ke', data: this.ThongKeTheoKhoa || [] },
					{ name: 'DS_Dat', data: this.dsDat || [] },
					{ name: 'DS_Khong_Dat', data: this.dsKhongDat || [] }
				];
	
				jsonToExcel({
					sheets: excelSheets,
					filename: `${this.label || 'BaoCao'}.xlsx`
				});
			},
		}
	}
</script>