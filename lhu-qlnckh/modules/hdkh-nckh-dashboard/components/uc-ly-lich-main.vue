<template>
	<div class="d-flex justify-space-between align-center mb-4">
		<h2 class="text-primary font-weight-bold text-h5">
			LÝ LỊCH KHOA HỌC
		</h2>
		<v-btn size="default" color="primary" variant="elevated" @click="ExportPDF" class="text-none">
			Xuất PDF
			<v-icon end size="small">
				mdi-file-export-outline
			</v-icon>
		</v-btn>
	</div>
	<!-- main content -->
	<div v-if="userProfile && userProfile.length > 0">
		<uc-ly-lich-so-yeu :so-yeu-ly-lich="userProfile[0][0]" :nhan-vien-id="nhanVienId"
			@on-reload="$emit('on-reload')"></uc-ly-lich-so-yeu>
		<v-divider class="my-4"></v-divider>
		<uc-ly-lich-dao-tao :items="userProfile[1]" :nhan-vien-id="nhanVienId"></uc-ly-lich-dao-tao>
		<v-divider class="my-4"></v-divider>
		<uc-ly-lich-cong-tac :items="userProfile[2]" :nhan-vien-id="nhanVienId"></uc-ly-lich-cong-tac>
		<v-divider class="my-4"></v-divider>
		<uc-ly-lich-de-tai :items="userProfile[3]" :nhan-vien-id="nhanVienId"></uc-ly-lich-de-tai>
		<v-divider class="my-4"></v-divider>
		<uc-ly-lich-cong-trinh :items="userProfile[4]" :nhan-vien-id="nhanVienId"></uc-ly-lich-cong-trinh>
	</div>
</template>

<script>
	export default {
		name: 'uc-ly-lich-main',
		props: {
			userProfile: { type: Array, default: () => [] },
			nhanVienId: { type: String, default: '' }
		},
		emits: ['on-reload'],
		data() {
			return {}
		},
		methods: {
			async convertImageUrlToBase64(url) {
				const response = await fetch(url)
				const blob = await response.blob()
				return await new Promise((resolve, reject) => {
					const reader = new FileReader()
					reader.onloadend = () => resolve(reader.result)
					reader.onerror = reject
					reader.readAsDataURL(blob)
				})
					.then((base64) => {
						return base64
					})
					.catch((err) => {
						console.log(err)
					})
			},
			formatVietnameseDate(isoString) {
				if (!isoString) return '';
				const date = new Date(isoString)
				const day = date.getDate().toString().padStart(2, "0")
				const month = (date.getMonth() + 1).toString().padStart(2, "0")
				const year = date.getFullYear()
				return `${day} tháng ${month} năm ${year}`
			},
			async ExportPDF() {
				if (!this.userProfile || this.userProfile.length < 5) return;
				
				// Bảng quá trình đào tạo
				const tableQuaTrinhDaoTao = {
					headerRows: 1,
					widths: ['*', '*', '*', '*'],
					body: [
						[
							{ text: 'Học vị', style: 'tableHeader' },
							{ text: 'Chuyên ngành', style: 'tableHeader' },
							{ text: 'Nơi đào tạo', style: 'tableHeader' },
							{ text: 'Năm tốt nghiệp', style: 'tableHeader' }
						],
						...this.userProfile[1].map(item => [
							{ text: item.HocVi || '', style: 'tableCell' },
							{ text: item.ChuyenNganh || '', style: 'tableCell' },
							{ text: item.NoiDaoTao || '', style: 'tableCell' },
							{ text: item.NamTotNghiep || '', alignment: 'center' }
						])
					]
				};
	
				// Bảng quá trình công tác
				const tableQuaTrinhCongTac = {
					headerRows: 1,
					widths: ['*', '*', '*'],
					body: [
						[
							{ text: 'Thời gian', style: 'tableHeader' },
							{ text: 'Nơi công tác', style: 'tableHeader' },
							{ text: 'Công việc đảm nhận', style: 'tableHeader' }
						],
						...this.userProfile[2].map(item => [
							{ text: item.ThoiGian || '', style: 'tableCell' },
							{ text: item.NoiCongTac || '', style: 'tableCell' },
							{ text: item.CongViecDamNhiem || '', style: 'tableCell' }
						])
					]
				};
	
				// Bảng các đề tài tham gia
				const tableCacDeTaiThamGia = {
					headerRows: 1,
					widths: ['*', '*', '15%', '25%'],
					body: [
						[
							{ text: 'Tên đề tài', style: 'tableHeader' },
							{ text: 'Cơ quan tài trợ', style: 'tableHeader' },
							{ text: 'Vai trò', style: 'tableHeader' },
							{ text: 'Thời gian thực hiện', style: 'tableHeader' }
						],
						...this.userProfile[3].map(item => [
							{ text: item.TenDeTai || '', style: 'tableCell' },
							{ text: item.CoQuanTaiTro || '', style: 'tableCell' },
							{ text: item.VaiTro || '', alignment: 'center' },
							{ text: item.ThoiGianThucHien || '', alignment: 'center' }
						])
					]
				};
	
				// Bảng các công trình khoa học
				const tableCacCongTrinhKhoaHoc = {
					headerRows: 1,
					widths: ['*', '*', '*', '*'],
					body: [
						[
							{ text: 'Tên tác giả', style: 'tableHeader' },
							{ text: 'Tên công trình', style: 'tableHeader' },
							{ text: 'Tạp chí - Hội thảo', style: 'tableHeader' },
							{ text: 'Ghi chú', style: 'tableHeader' }
						],
						...this.userProfile[4].map(item => [
							{ text: item.TenTacGia || '', style: 'tableCell' },
							{ text: item.TenCongTrinh || '', style: 'tableCell' },
							{ text: item.TapChi_HoiThao || '', style: 'tableCell' },
							{ text: item.GhiChu || '', style: 'tableCell' }
						])
					]
				};
				
				const profile = this.userProfile[0][0] || {};
				const docDefinition = {
					content: [
						{
							text: 'LÝ LỊCH KHOA HỌC',
							style: 'title',
							alignment: 'center'
						},
						{
							text: '(Dùng cho học viên cao học)',
							alignment: 'center',
							italics: true,
							margin: [0, 0, 0, 20]
						},
						[
							{
								columns: [
									[
										{ text: 'I. Sơ lược lý lịch:', style: 'section' },
										{ text: `Họ và tên: ${profile.HoTen || ''}			 Giới tính: ${profile.GioiTinh || ''}` },
										{ text: `Sinh ngày: ${this.formatVietnameseDate(profile.NgaySinh)}` },
										{ text: `Đơn vị công tác: ${profile.DonVi || ''}` },
										{ text: `Chức vụ: ${profile.ChucVu || ''}` },
										{ text: `Điện thoại di động: ${profile.DienThoai || ''}` },
										{ text: `E-mail: ${profile.Email || ''}` }
									]
								]
							},
	
							{ text: 'II. Quá trình đào tạo:', style: 'section' },
							{
								table: tableQuaTrinhDaoTao,
							},
							{ text: 'III. Quá trình công tác chuyên môn kể từ khi tốt nghiệp đại học:', style: 'section' },
							{
								table: tableQuaTrinhCongTac,
							},
							{ text: 'IV. Các đề tài đã tham gia:', style: 'section' },
							{
								table: tableCacDeTaiThamGia,
							},
							{ text: 'V. Các công trình khoa học đã công bố', style: 'section' },
							{
								table: tableCacCongTrinhKhoaHoc,
							},
						]
					],
					styles: {
						title: { fontSize: 18, bold: true },
						section: { fontSize: 14, bold: true, margin: [0, 10, 0, 5] },
						tableHeader: { bold: true, fontSize: 12, alignment: 'center' },
						tableCell: { alignment: 'left' }
					}
				}
	
				pdfMake.createPdf(docDefinition).download(`ly-lich-khoa-hoc-${profile.HoTen || 'GV'}.pdf`);
			}
		}
	}
</script>