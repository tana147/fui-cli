<template>
	<z-layout>
		<!-- Header + Title -->
		<v-app-bar density="compact" :elevation="0" title="Quản lý công thức">
			<template v-slot:append>
				<v-btn @click="onExport()" color="primary" prepend-icon="mdi-microsoft-excel" variant="flat">Xuất
					Excel</v-btn>
				<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="onCreate()">Thêm
					mới</v-btn>
			</template>
		</v-app-bar>

		<z-table v-if="isInitTable" ref="refTable" :headers="tableHeader" :items="tableData" @onEdit="onSave"
			height="calc(100vh - 49px)" :options="tableConfig" />

		<!-- Modals -->
		<uc-chi-tiet-cong-thuc :key="recipeKey" :DsDiaDiemSanXuat="DsDiaDiemSanXuat" :DsDiaDiemSuDung="DsDiaDiemSuDung"
			:DsKhuVucCheBien="DsKhuVucCheBien" v-model="isShowRecipe" @onReload="reloadData" @callData="callData"
			:DsDonViTinh="DsDonViTinh" :statusOptions="statusOptions" />

	</z-layout>
</template>

<script>
	export default {
		props: {
			label: {
				type: String,
				default: ''
			},
			action: {
				type: Object,
				default: () => ({})
			}
		},
		data() {
			return {
				vueData,
				vueAction,
	
				isInitTable: false,
				isLoading: false,
				tableHeader: [],
				tableData: [],
				tableConfig: {
					pagination: true,
				},
	
	
				DsCongThuc: [],
				DsDiaDiemSanXuat: [],
				DsDiaDiemSuDung: [],
				DsKhuVucCheBien: [],
				DsDonViTinh: [],
	
				isShowRecipe: false,
				recipeKey: 0,
	
				statusOptions: [
					{ title: 'NHÁP', value: 'NHAP' },
					{ title: 'ĐANG SỬ DỤNG', value: 'DANG_SU_DUNG' },
					{ title: 'NGỪNG SỬ DỤNG', value: 'NGUNG_SU_DUNG' },
					{ title: 'ĐANG TEST', value: 'TEST' },
				],
			}
		},
	
		computed: {},
	
		watch: {},
	
		mounted() {
			const $this = this
			$this.initData()
		},
	
		methods: {
			async getData() {
				const $this = this
				const resData = await apiCallPromise("/work/MT_CongThuc_Select", null)
				$this.tableData = resData ?? []
				// console.log('Table Data: ', $this.tableData)
			},
			async initData() {
				const $this = this
				$this.isInitTable = false
				try {
					$this.isLoading = true
					await Promise.all([$this.getData()])
					$this.initHeader()
				} catch (error) {
					console.error("Lỗi khi tải dữ liệu khởi tạo:", error)
				} finally {
					$this.isLoading = false
					$this.isInitTable = true
				}
			},
			initHeader() {
				const $this = this
				$this.tableHeader = [
					{ title: '#', formatter: "rownum", hozAlign: "center", width: 60 },
					{
						title: 'Mã hàng hóa', field: 'MaNoiBo', headerSort: true, headerFilter: "input", width: 150,
					},
					{
						title: 'Tên hàng hóa', field: 'TenHangHoa', headerSort: true, headerFilter: "input", width: 270,
						cellClick: (e, cell) => {
							const item = cell.getRow().getData()
							this.onEdit(item)
						},
						formatter: (cell) => {
							return `<div class="font-weight-bold text-primary cursor-pointer back-link-hover">${cell.getValue()}</div>`
						},
					},
					{ title: 'Đơn vị ĐL', field: 'DinhLuong_TenDonViTinh', headerSort: true, headerFilter: "input", width: 110, hozAlign: "center" },
					{
						title: 'Loại NL', field: 'LoaiNguyenLieu', width: 100, hozAlign: "center",
						headerSort: true,
						headerFilter: 'list',
						headerFilterParams: {
							values: {
								'': 'Tất cả',
								TP: 'TP',
								BTP: 'BTP',
							},
						},
					},
					{
						title: 'Trạng thái',
						field: 'TrangThai',
						headerSort: true,
						headerFilter: "input",
						width: 160,
						hozAlign: "center",
						formatter: (cell) => {
							const status = cell.getValue()
	
							const text = this.getStatusText(status)
							const color = this.getStatusColor(status)
							const icon = this.getStatusIcon(status)
	
							return `<div class="chip chip-${color}"><span>${text}</span></div>`
						}
					},
					{ title: 'Địa điểm sản xuất', field: 'TenDiaDiem', headerSort: true, headerFilter: "input", width: 170 },
					{ title: 'Khu vực chế biến', field: 'TenKhuVuc', headerSort: true, headerFilter: "input", width: 170 },
					{ title: 'Địa điểm sử dụng', field: 'TenDiaDiemSuDung', headerSort: true, headerFilter: "input", width: 170 },
					{ title: 'HSD (giờ)', field: 'HanSuDung_Gio', width: 130, headerSort: true, headerFilter: "input", hozAlign: 'center' },
					{ title: 'Thiết bị bảo quản', field: 'BaoQuan_ThietBi', headerSort: true, headerFilter: "input", width: 170 },
					{ title: 'Nơi bảo quản', field: 'BaoQuan_NoiBaoQuan', headerSort: true, headerFilter: "input", width: 170 },
					{ title: 'Ghi chú', field: 'GhiChu', headerSort: true, headerFilter: "input", width: 150 },
					{
						title: 'Tạm khóa', field: 'Is_TamKhoa', headerSort: true, hozAlign: "center", width: 115,
						formatter: (cell) => {
							const isLock = cell.getValue()
							return isLock ? `<i class="icon-table text-red mdi mdi-lock"></i>` : ""
						},
					},
					{
						title: "",
						width: 60,
						hozAlign: "center",
						headerSort: false,
						formatter: () => {
							return `<i class="icon-table text-red mdi mdi-trash-can-outline"></i>`
						},
						cellClick: (e, cell) => {
							const item = cell.getRow().getData()
							this.onDelete(item)
						},
					},
				]
			},
	
			onLoadDiaDiemSanXuat() {
				apiCall(
					"/work/HH_DiaDiem_Select",
					null,
					(res) => {
						this.DsDiaDiemSanXuat = res.data
						this.DsDiaDiemSuDung = res.data
					}
				)
			},
	
			onLoadKhuVucCheBien() {
				apiCall(
					"/work/HH_KhuVuc_Select",
					null,
					(res) => {
						this.DsKhuVucCheBien = res.data
					}
				)
			},
	
			onLoadDonViTinh() {
				apiCall(
					"/work/HH_DonViTinh_Select",
					null,
					(res) => {
						this.DsDonViTinh = res.data
					}
				)
			},
	
			onSave() {
	
			},
	
			callData() {
				this.onLoadDiaDiemSanXuat()
				this.onLoadKhuVucCheBien()
				this.onLoadDonViTinh()
			},
	
			reloadData() {
				const $this = this
				$this.initData()
			},
	
			getStatusText(status) {
				const colors = {
					'NHAP': 'NHÁP',
					'DANG_SU_DUNG': 'ĐANG SỬ DỤNG',
					'NGUNG_SU_DUNG': 'NGƯNG SỬ DỤNG',
					'TEST': 'ĐANG TEST',
				}
				return colors[status] || ''
			},
	
			getStatusColor(status) {
				const colors = {
					'NHAP': 'warning',
					'DANG_SU_DUNG': 'success',
					'NGUNG_SU_DUNG': 'error',
					'TEST': 'blue-grey',
				}
				return colors[status] || 'grey'
			},
	
			getStatusIcon(status) {
				const icons = {
					'NHAP': 'mdi-file-outline',
					'DANG_SU_DUNG': 'mdi-check-circle',
					'NGUNG_SU_DUNG': 'mdi-close-circle',
					'TEST': 'mdi-pause-circle',
				}
				return icons[status]
			},
	
			onCreate() {
				this.isShowRecipe = false
				vueData.CongThuc_Id = null
				vueData.TenHangHoa = null
				vueData.MaNoiBo = null
				this.isShowRecipe = true
				// if (this.vueAction) {
				// 	this.vueAction({
				// 		CALL: 'openRecipeDetail',
				// 	})
				// }
			},
	
			onEdit(item) {
				vueData.CongThuc_Id = item.CongThuc_Id
				vueData.TenHangHoa = item.TenHangHoa
				vueData.MaNoiBo = item.MaNoiBo
				this.isShowRecipe = true
			},
	
			openDetail(item) {
				vueData.CongThuc_Id = item.CongThuc_Id
				vueData.TenHangHoa = item.TenHangHoa
				vueData.MaNoiBo = item.MaNoiBo
				if (this.vueAction) {
					this.vueAction({
						CALL: 'openRecipeDetail',
					})
				}
			},
	
			onDelete(record) {
				showConfirm(
					`Bạn chắc chắn muốn xóa công thức "${record.TenHangHoa}"?`,
					() => {
						apiCall(
							"/work/MT_CongThuc_Delete",
							{ CongThuc_Id: record.CongThuc_Id },
							() => {
								this.reloadData()
								showToast.success("Xóa công thức thành công!")
							}
						)
					}
				)
			},
	
			onExport() {
				const $this = this
				$this.$refs.refTable.exportExcel("DanhSachBangCongThuc")
			},
		}
	}
</script>