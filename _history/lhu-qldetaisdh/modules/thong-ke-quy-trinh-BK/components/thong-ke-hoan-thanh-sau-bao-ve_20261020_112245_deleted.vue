<template>
	<div>
		<v-btn class="mb-3" @click="onPrint" color="success" :loading="isLoadingExport"><v-icon
				left>mdi-microsoft-excel</v-icon> Xuất file
			excel</v-btn>

		<v-card>
			<v-card-title class="primary--text">
				{{ labelTable }}
				<v-spacer />
				<v-text-field v-model="search" append-icon="mdi-magnify" label="Tìm kiếm mã học viên..." single-line
					hide-details dense style="max-width: 400px" />
			</v-card-title>

			<v-data-table class="table-frozen-cols" item-key="STT" v-model="selectedItems" show-select
				:items="DsHoanThanhSBV" :headers="tableHeader" :search="search" dense items-per-page="-1"
				:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
				<template v-slot:item.HoTenMaSV="{ item }">
					<span class="primary--text">
						<b> {{ item.HoSV }} {{ item.TenSV }}</b>
					</span>
					<br />
					<b>{{ item.StudentID }}</b>
					<span class="amber--text"> [{{ item.LopID }}]</span>
				</template>

				<template v-slot:item.SoDienThoai="{ item }">
					<b>{{item.SoDienThoai}}</b>
					<p>{{item.Email}}</p>
				</template>
			</v-data-table>
		</v-card>
	</div>
</template>

<script>
	export default {
		props: ['dshoanthanhsbv'],
		data() {
			return {
				isLoadingExport: false,
	
				search: "",
				selectedItems: [],
	
				tableHeader: [
					{
						text: 'STT',
						value: 'STT',
						sortable: false,
						align: 'center',
						width: 60,
					},
					{
						text: 'Họ tên',
						value: 'HoTenMaSV',
						sortable: false,
						width: 200,
					},
					{
						text: 'Giới tính',
						value: 'GioiTinh',
						sortable: false,
						align: 'center',
						width: 90,
					},
					{
						text: 'Ngày sinh',
						value: 'NgaySinh',
						sortable: false,
						align: 'center',
					},
					{
						text: 'Ngành',
						value: 'TenNganh',
						sortable: false,
						width: 200,
					},
					{
						text: 'Niên khóa',
						value: 'Nien_Khoa',
						sortable: false,
						align: 'center',
						width: 100,
					},
					{
						text: 'SĐT/Email',
						value: 'SoDienThoai',
						sortable: false,
						width: 150,
					},
					{
						text: 'Đề tài',
						value: 'ThesisName',
						sortable: false,
						width: 300,
					},
					{
						text: 'Chủ tịch',
						value: 'ChuTich',
						sortable: false,
						width: 180,
					},
					{
						text: 'Phản biện 1',
						value: 'Pb_1',
						sortable: false,
						width: 180,
					},
					{
						text: 'Phản biện 2',
						value: 'Pb_2',
						sortable: false,
						width: 180,
					},
					{
						text: 'Ủy viên',
						value: 'UyVien',
						sortable: false,
						align: 'center',
						width: 180,
					},
					{
						text: 'Thư ký',
						value: 'ThuKy',
						sortable: false,
						width: 180,
					},
	
	
				]
			}
		},
		mounted() { },
		computed: {
			labelTable() {
				const total = this.dshoanthanhsbv.length
				const selected = this.selectedItems.length
				return `Danh sách học viên (${total})${selected > 0 ? ` - Đã chọn (${selected})` : ''}`
			},
	
			DsHoanThanhSBV() {
				return this.dshoanthanhsbv.map((item, index) => {
					return {
						...item,
						HoTenMaSV: `${item.HoSV} ${item.TenSV} ${item.Student_ID} ${item.LopID}`
					};
				});
			},
		},
		watch: {},
		methods: {
			async onPrint() {
				this.isLoadingExport = true
				const dataArr = this.selectedItems.map((item, index) => {
					return {
						STT: index + 1,
						MSHV: item.StudentID ?? "",
						HoHV: item.HoSV ?? "",
						TenHV: item.TenSV ?? "",
						GioiTinh: item.GioiTinh ?? "",
						NgaySinh: item.NgaySinh ?? "",
						Nganh: item.TenNganh ?? "",
						NienKhoa: item.Nien_Khoa ?? "",
						LopID: item.LopID ?? "",
						SoMonHoc: '0',
						DiemTBHocTap: '0',
						DiemTBTotNghiep: '0',
						DiemBaoVe: item.DiemHoiDong.toString() ?? "",
						DeTai: item.ThesisName ?? "",
						GVHD1: item.ThesisesProf1 ?? "",
						GVHD2: item.ThesisesProf2 ?? "",
						ChuTich: item.ChuTich ?? "",
						PB1: item.Pb_1 ?? "",
						PB2: item.Pb_2 ?? "",
						UyVien: item.UyVien ?? "",
						ThuKy: item.ThuKy ?? "",
						SoDT: item.SoDienThoai ?? "",
						Email: item.Email ?? "",
					}
				})
	
				const HeSoLuanvan = 15
				for (let item of dataArr) {
					const diemArray = await this.onLoadDiemThanhPhan(item.MSHV).then((data) => {
						return data.filter((diemItem) => {
							const monHocID = diemItem?.MonHocID
							if (monHocID === null || monHocID === undefined) {
								return true
							}
	
							const monHocIDStr = String(monHocID).replace(/\D/g, '')
							return monHocIDStr.slice(-3) !== '815'
						})
					})
					const countMonHoc = diemArray.length
					const totalDtb = diemArray.reduce((sum, diemItem) => {
						if (diemItem.HeSo !== HeSoLuanvan) {
							return sum + diemItem.DiemTBMon * diemItem.HeSo
						}
						return sum
					}, 0)
	
					const totalHeSo = diemArray.reduce((sum, diemItem) => sum + diemItem.HeSo, 0)
					const parseDiemBaoVe = item.DiemBaoVe ? parseFloat(item.DiemBaoVe) : 0
	
					item.SoMonHoc = countMonHoc.toString()
	
					// Tính Điểm trung bình học tập: try/catch và isFinite để gán chuỗi rỗng '' thay vì in ra NaN, Infinity
					try {
						const dtbHocTap = totalDtb / (totalHeSo - HeSoLuanvan)
						item.DiemTBHocTap = isFinite(dtbHocTap) && !isNaN(dtbHocTap) ? dtbHocTap.toFixed(1) : ''
					} catch (e) {
						item.DiemTBHocTap = ''
					}
	
					// Tính Điểm trung bình tốt nghiệp: try/catch và isFinite để gán chuỗi rỗng '' nếu có lỗi chia/dữ liệu rỗng
					try {
						const dtbTotNghiep = (totalDtb + parseDiemBaoVe * HeSoLuanvan) / totalHeSo
						item.DiemTBTotNghiep = isFinite(dtbTotNghiep) && !isNaN(dtbTotNghiep) ? dtbTotNghiep.toFixed(2) : ''
					} catch (e) {
						item.DiemTBTotNghiep = ''
					}
				}
	
				const apiData = {
					DanhSach: dataArr,
				}
	
				const myHeaders = new Headers()
				myHeaders.append('Content-Type', 'application/json')
				const requestOptions = {
					method: 'POST',
					headers: myHeaders,
					body: JSON.stringify(apiData),
					redirect: 'follow',
				}
	
				// https://gendocx.iotsoftvn.com
				// http://localhost:5244
				fetch('https://gendocx.iotsoftvn.com/api/generate-xlsx/hoan-thanh-sau-bao-ve', requestOptions)
					.then((response) => response.blob())
					.then((blob) => {
						const url = window.URL.createObjectURL(blob)
						const a = document.createElement('a')
						a.href = url
						a.download = `Danh sách hoàn thành sau bảo vệ.xlsx`
						document.body.appendChild(a)
						a.click()
						a.remove()
						this.isLoadingExport = false
					})
					.catch((error) => {
						console.error(error)
						this.isLoadingExport = false
					})
			},
	
			onLoadDiemThanhPhan(studentID) {
				return new Promise(function (resolve, reject) {
					$.ajax({
						type: 'GET',
						headers: {
							authorization: $awt,
						},
						url: `https://tapi.lhu.edu.vn/mark/MarkViewer_GetBangDiem?studentId=${studentID}`,
						contentType: 'application/json; charset=utf-8',
						dataType: 'json',
						crossDomain: true,
						success: function (res) {
							const data = res.data.map((item, index) => ({
								...item,
								STT: index + 1,
								DiemThanhPhanList: JSON.parse(item.DiemThanhPhan),
							}))
							resolve(data)
						},
						error: function (xhr) {
							reject(xhr.responseJSON.Message)
							$.dialog({
								icon: 'fas fa-exclamation',
								title: 'Error',
								content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
								type: 'red',
								columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
								closeIcon: true,
								buttons: {
									ok: {
										text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
										btnClass: 'btn-blue',
									},
								},
							})
						},
						complete: function () { },
					})
				})
			},
		},
	}
</script>