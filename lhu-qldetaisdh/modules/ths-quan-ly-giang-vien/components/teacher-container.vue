<template>
	<div>
		<dialog-add-single-teacher :dsgiangvien="DsGiangVien" />
		<dialog-add-teacher-by-excel :nganhgiangday="vueData.NganhGiangDay" :dsgiangvien="DsGiangVien" />
		<dialog-update-teacher :teacheredit="teacherEditData" :dsgiangvien="DsGiangVien" />

		<div class="d-flex justify-end align-center mb-3">
			<v-select v-model="NganhIDSelected" outlined dense hide-details label="Lọc theo ngành" multiple clearable
				:items="DsNganh" item-text="TenNganh" item-value="NganhID" chips style="max-width: 500px;"
				class="mr-3" />
			<v-btn class="mr-3" color="indigo" @click="onPrintExcel" dark>
				<v-icon left>mdi-microsoft-excel</v-icon>
				Xuất danh sách giảng viên
			</v-btn>
			<v-btn color="success" @click="vueData.isExcelDialog = true">
				<v-icon left>mdi-microsoft-excel</v-icon>Thêm
				Giảng viên bằng file excel
			</v-btn>
			<v-btn class="ml-3" @click="vueData.isAddTeacherDialog = true" color="primary">
				<v-icon left>mdi-plus</v-icon> Thêm giảng viên
			</v-btn>
		</div>

		<v-card>
			<v-card-title>
				<p class="mb-0 primary--text">{{labelTable}} ({{FilteredDsGiangVien.length}})</p>
				<v-spacer></v-spacer>
				<div class="wrapSearch">
					<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm..." single-line
						hide-details />
				</div>
			</v-card-title>

			<v-data-table v-model="GiangVienSelectArr" show-select item-key="GiangVienID" class="table-frozen-cols"
				:headers="headerTable" :items="FilteredDsGiangVien" isSearch dense="true" :search="search"
				:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" itemsPerPage="-1">
				<template v-slot:item.btnChucNang="{ item }">
					<div class="d-flex align-center, justify-center">
						<v-btn @click="deleteGiangVien(item.GiangVienID)" x-small fab icon>
							<v-icon color="red darken-3">mdi-trash-can-outline</v-icon>
						</v-btn>
						<v-btn @click="editDialog(item)" x-small fab icon>
							<v-icon color="green darken-2">mdi-square-edit-outline</v-icon>
						</v-btn>
					</div>
				</template>
				<template v-slot:item.TenNganHang="{ item }">
					<div>
						<b>{{ item.TenNganHang }}</b>
						<p>{{ item.SoTKNganHang }}</p>
					</div>
				</template>
				<template v-slot:item.HocHamHoTen="{ item }">
					<div>
						<b class="primary--text selectEdit" @click="editDialog(item)">{{ item.HocHamHoTen }}</b>
					</div>
				</template>
				<template v-slot:item.FileVanBang_ID="{ item }">
					<div>
						<div v-if="item.FileVanBang_ID">
							<v-chip label outlined class="mb-3" color="deep-purple accent-4">
								<v-icon left>mdi-file-check-outline</v-icon>
								<a :href="vueData.v_Set.urlReadFile + item.FileVanBang_Url" target="_blank"
									style="color: deep-purple accent-4">File văn bằng</a>
							</v-chip>
						</div>

						<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label> Chưa upload file
						</v-chip>
					</div>
				</template>
				<template v-slot:item.FileLyLichKH_ID="{ item }">
					<div>
						<div v-if="item.FileLyLichKH_ID">
							<v-chip label outlined class="mb-3" color="deep-purple accent-4">
								<v-icon left>mdi-file-check-outline</v-icon>
								<a :href="vueData.v_Set.urlReadFile + item.FileLyLichKH_Url" target="_blank"
									style="color: deep-purple accent-4">File lý lịch</a>
							</v-chip>
						</div>

						<v-chip v-else class="mb-3" color="deep-purple accent-4" outlined label> Chưa upload file
						</v-chip>
					</div>
				</template>
				<template v-slot:item.SoDienThoai="{ item }">
					<div>
						<b>{{ item.SoDienThoai }}</b>
						<p>{{ item.Email_GV }}</p>
					</div>
				</template>
			</v-data-table>
		</v-card>

	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				search: null,
	
				NganhIDSelected: ['All'],
				FilteredDsGiangVien: [],
				GiangVienSelectArr: [],
				// DsHeDaoTao: [],
				// HeArr: [],
				type: '',
				teacherEditData: {},
				labelTable: 'Danh sách giảng viên',
	
				headerTable: [
					{
						text: 'STT',
						value: 'stt',
						sortable: false,
						align: 'center',
						width: 50,
					},
					{
						text: 'Họ tên',
						value: 'HocHamHoTen',
						sortable: false,
						width: 200,
					},
					{
						text: 'Ngành giảng dạy',
						value: 'NganhGiangDay',
						sortable: false,
						width: 180,
					},
					{
						text: 'Cơ quan công tác',
						value: 'CoQuanCongTac',
						width: 220,
						sortable: false,
					},
					{
						text: 'Cơ quan công tác (tiếng Việt)',
						value: 'CoQuanCongTacTiengViet',
						width: 220,
						sortable: false,
					},
					{
						text: 'SĐT/Email',
						value: 'SoDienThoai',
						sortable: false,
						width: 180,
					},
					{
						text: 'Ngân hàng',
						value: 'TenNganHang',
						sortable: false,
						width: 150,
					},
					{
						text: 'Mã số thuế',
						value: 'MaSoThue',
						sortable: false,
						width: 150,
					},
					{
						text: 'Địa chỉ',
						value: 'DiaChi',
						width: 220,
						sortable: false,
					},
					{
						text: 'File văn bằng',
						value: 'FileVanBang_ID',
						sortable: false,
						align: 'center',
					},
					{
						text: 'File lý lịch',
						value: 'FileLyLichKH_ID',
						sortable: false,
						align: 'center',
					},
					{
						text: 'Chức năng',
						value: 'btnChucNang',
						sortable: false,
						align: 'center',
					},
				],
			}
		},
		mounted() {
			this.onLoadHocHamHocVi()
			this.getHeDaoTao()
		},
		computed: {
			DsGiangVien() {
				return vueData.DsGiangVien || []
			},
			DsNganh() {
				const obj = {
					TenNganh: '- Tất cả -',
					NganhID: 'All'
				}
				const arr = [...(vueData.NganhGiangDay || [])]
				arr.unshift(obj)
				return arr
			},
		},
		watch: {
			'vueData.nganhGiangDay': function (val) {
				console.log('val', val)
			},
			// Theo dõi biến chọn ngành để lọc giảng viên và xử lý logic filter "Tất cả"
			NganhIDSelected(newVal, oldVal) {
				if (!newVal || newVal.length === 0) {
					this.NganhIDSelected = ['All']
					return
				}
	
				const hasAllNew = newVal.includes('All')
				const hasAllOld = oldVal ? oldVal.includes('All') : false
	
				if (hasAllNew && !hasAllOld && newVal.length > 1) {
					// Nếu đang chọn các phần tử khác mà select "Tất cả" thì loại bỏ các phần tử đã chọn khác
					this.NganhIDSelected = ['All']
				} else if (hasAllNew && hasAllOld && newVal.length > 1) {
					// Nếu đang chọn "Tất cả" mà select phần tử khác thì bỏ select phần tử "Tất cả"
					this.NganhIDSelected = newVal.filter(item => item !== 'All')
				}
	
				// Cập nhật lại danh sách lọc
				this.filterData()
			},
			// Theo dõi danh sách giảng viên gốc để cập nhật lại danh sách hiển thị
			DsGiangVien: {
				handler: function (val) {
					this.filterData()
				},
				deep: true
			}
		},
		methods: {
			onPrintExcel() {
				const dataArr = this.GiangVienSelectArr
					// .sort((a, b) => a.TenHV.localeCompare(b.HoTenGiangVien, 'vi'))
					.map((item, index) => {
						return {
							STT: index + 1,
							HocHamHocVi: item.HocViHocHam,
							HoTen: item.HoTenGiangVien,
							NganhGiangDay: item.NganhGiangDay,
							CoQuanCongTac: item.CoQuanCongTac,
							SoDienThoai: item.SoDienThoai,
							Email: item.Email_GV,
							MaSoThue: item.MaSoThue,
							NganHang: item.TenNganHang,
							SoTaiKhoan: item.SoTKNganHang,
							DiaChi: item.DiaChi,
						}
					})
	
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
				fetch('https://gendocx.iotsoftvn.com/api/generate-xlsx/giang-vien-hoi-dong', requestOptions)
					.then((response) => response.blob())
					.then((blob) => {
						const url = window.URL.createObjectURL(blob)
						const a = document.createElement('a')
						a.href = url
						a.download = `Danh sách giảng viên hội đồng.xlsx`
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
	
			// Hàm thực hiện lọc mảng gốc sang mảng hiển thị dựa theo điều kiện ngành
			filterData() {
				if (!this.DsGiangVien || this.DsGiangVien.length === 0) return
	
				if (!this.NganhIDSelected || this.NganhIDSelected.length === 0 || this.NganhIDSelected.includes('All')) {
					this.FilteredDsGiangVien = [...this.DsGiangVien]
				} else {
					this.FilteredDsGiangVien = this.DsGiangVien.filter(item => {
						return this.NganhIDSelected.some(selectedID => selectedID == item.NganhID)
					})
				}
			},
			editDialog(item) {
				this.teacherEditData = item
				vueData.isUpdDialog = true
			},
			onLoadHocHamHocVi() {
				ajaxCALL(
					'/HocViHocHam_Get',
					null,
					(res) => {
						vueData.DsGetHocHam = res.data
						console.log('this.DsHocHamHocVi', vueData.DsGetHocHam)
					},
					(error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
						console.log('Fail to load hoc ham hoc vi', error)
					},
				)
			},
	
			async getHeDaoTao() {
				vueData.NganhGiangDay = await getNganhCaoHocPromise();
			},
	
		},
	}
</script>