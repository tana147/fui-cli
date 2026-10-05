<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Danh sách hàng hóa">
			<template v-slot:append>
				<v-btn @click="onExport" color="primary" prepend-icon="mdi-microsoft-excel" variant="flat">Xuất
					excel</v-btn>
				<v-btn color="primary" prepend-icon="mdi-plus" variant="flat">Thêm mới</v-btn>
			</template>
		</v-app-bar>
		<z-table v-if="isInitTable" ref="refTable" :headers="tableHeader" :items="tableData" @onEdit="onSave"
			height="calc(100vh - 48px)" :options="tableConfig" />
	</z-layout>
</template>

<script>
	export default {
		data() {
			return {
				isInitTable: false,
				isLoading: false,
				tableHeader: [],
				tableData: [],
				tableConfig: {
					pagination: true
				},
			}
		},
		mounted() {
			const $this = this
			$this.initData()
		},
		methods: {
			async getData() {
				const $this = this
				const params = {
					TimKiem: "",
					LoaiNguyenLieu: "",
					DoUuTien: "",
					DonGiaNhap: "",
					DonGiaBan: "",
					Operator_Nhap: "=",
					Operator_Ban: "=",
					TrangThai: "",
					PageIndex: 1,
					PageSize: 2000,
				}
				const resData = await apiCallPromise("/work/MT_NguyenLieu_Select", params)
				$this.tableData = resData[1] ?? []
				console.log($this.tableData)
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
					{ title: "#", formatter: "rownum", width: 80, hozAlign: "center" },
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
					{
						title: "Mã nội bộ",
						field: "MaNoiBo",
						headerSort: true,
						headerFilter: "input",
						width: 100,
						formatter: function (cell) {
							return `<div class="link-table text-primary">${cell.getValue()}</div>`
						},
					},
					{ title: "Nguyên liệu", field: "TenHangHoa", headerSort: true, headerFilter: "input", width: 320 },
					{ title: "Loại NL", field: "LoaiNguyenLieu", headerSort: true, headerFilter: "input", width: 100, hozAlign: "center" },
					{ title: "Nhóm tính chất", field: "TenTinhChat", headerSort: true, headerFilter: "input", width: 230 },
					{ title: "Nhóm vật tư", field: "TenNhomVatTu", headerSort: true, headerFilter: "input", width: 230 },
					{ title: "Nhóm sản phẩm", field: "TenNhomSanPham", headerSort: true, headerFilter: "input", width: 230 },
					{ title: "Đơn giá nhập", field: "DonGiaNhap", headerSort: true, headerFilter: "input", width: 180, hozAlign: "end" },
					{ title: "Đơn giá bán", field: "DonGiaBan", headerSort: true, headerFilter: "input", width: 180, hozAlign: "end" },
					{ title: "ĐV nhập", field: "TenDonVi", headerSort: true, headerFilter: "input", width: 120, hozAlign: "center" },
					{ title: "Tổng ĐV quy đổi", field: "TongDonViQuyDoi", headerSort: true, headerFilter: "input", width: 160, hozAlign: "center" },
					{ title: "Tổng địa điểm áp dụng", field: "TongDiaDiemApDung", headerSort: true, headerFilter: "input", width: 160, hozAlign: "center" },
					{ title: "Trạng thái", field: "TrangThai", headerSort: true, headerFilter: "input", width: 350 },
					{
						title: "Tạm khóa",
						field: "Is_TamKhoa",
						headerSort: true,
						headerFilter: "input",
						width: 120,
						hozAlign: "center",
						formatter: (cell) => {
							const isLock = cell.getValue()
							return isLock ? `<i class="icon-table text-red mdi mdi-lock"></i>` : ""
						},
						cellClick: (e, cell) => {
							const item = cell.getRow().getData()
							this.onToggleLock(item)
						},
					},
				]
			},
			onSave: function (item) {
				showConfirm(`Bạn có chắc muốn cập nhật hàng hóa? <br/><b>${item.MaNoiBo} - ${item.TenHangHoa}</b>`, () => {
					console.log(item)
				})
			},
			onExport() {
				const $this = this
				$this.$refs.refTable.exportExcel("DataExport")
			},
			onDelete(item) {
				showConfirm(`Bạn có chắc muốn xóa hàng hóa? <br/><b>${item.MaNoiBo} - ${item.TenHangHoa}</b>`, () => {
					console.log(item)
				})
			},
			onToggleLock(item) {
				console.log(item)
			},
		},
	}
</script>