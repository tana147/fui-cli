<template>
	<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows" height="calc(100vh - 86px)"
		:options="tableOptions" />
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				vueData,
				isTableReady: false,
				isLoading: false,
				tableHeaders: [],
				tableRows: [],
				tableOptions: {
					pagination: true,
				},
			}
		},
		mounted() {
			this.initData()
		},
		computed: {},
		watch: {},
		methods: {
			async fetchList() {
				this.tableRows = await apiCallPromise("/work/HH_DiaDiem_Select")
			},
			async initData() {
				this.isTableReady = false
				try {
					this.isLoading = true
					await Promise.all([this.fetchList()])
					this.initTableHeaders()
				} catch (error) {
					console.error("Lỗi khi tải dữ liệu khởi tạo:", error)
				} finally {
					this.isLoading = false
					this.isTableReady = true
				}
			},
			initTableHeaders() {
				this.tableHeaders = [
					{
						title: "#",
						formatter: "rownum",
						width: 80,
						hozAlign: "center",
					},
					{
						title: "THÔNG TIN HÀNG HÓA",
						columns: [
							{ title: "Mã hàng hóa", field: "MaHangHoa", width: 140, headerSort: true, headerFilter: "input", },
							{
								title: "Tên hàng hóa", field: "TenHangHoa", hozAlign: "center", width: 150, headerSort: true, headerFilter: "input",
							},
							{ title: "ĐVT", field: "DonViTinh", hozAlign: "center", width: 80, headerSort: true, headerFilter: "input", },
							{
								title: "Phân loại hàng hóa", field: "PhanLoaiHangHoa", hozAlign: "center", width: 170, headerSort: true, headerFilter:
									"input",
							},
							{
								title: "Thông tin NCC", field: "ThongTinNhaCungCap", hozAlign: "center", width: 150, headerSort: true, headerFilter:
									"input",
							},
						],
					},
					{
						title: "THÔNG TIN NHÀ CUNG CẤP",
						columns: [
							{ title: "Mã NCC", field: "MaNhaCungCap", width: 140, headerSort: true, headerFilter: "input", },
							{ title: "Tên NCC", field: "TenNhaCungCap", hozAlign: "center", width: 150, headerSort: true, headerFilter: "input", },
							{
								title: "Nhóm NCC", field: "NhomNhaCungCap", hozAlign: "center", width: 170, headerSort: true, headerFilter: "input",
							},
						],
					},
					{
						title: "THÔNG TIN CHI PHÍ",
						columns: [
							{ title: "Thuế suất (%)", field: "ThueSuat", hozAlign: "center", width: 150, headerSort: true, headerFilter: "input", },
							{ title: "Tiền thuế", field: "TienThue", hozAlign: "center", width: 150, headerSort: true, headerFilter: "input", },
							{ title: "Trước thuế", field: "ChiPhiTruocThue", width: 150, headerSort: true, headerFilter: "input", },
							{ title: "Sau thuế", field: "ChiPhiSauThue", hozAlign: "center", width: 150, headerSort: true, headerFilter: "input", },
						],
					},
					{
						title: "CHỈ TIÊU TÍNH TOÁN CHI PHÍ",
						columns: [
							{
								title: "Giá BQ lũy kế", field: "GiaBQLuyKe", hozAlign: "center", width: 150, headerSort: true, headerFilter: "input",
							},
							{
								title: "Chênh lệch giá BQ", field: "ChenhLechBQ", hozAlign: "center", width: 170, headerSort: true, headerFilter:
									"input",
							},
							{ title: "CP mua hàng tăng", field: "ChiPhiMuaHangTang", width: 170, headerSort: true, headerFilter: "input", },
							{
								title: "Tổng chênh lệch CP", field: "TongChenhLechChiPhi", hozAlign: "center", width: 180, headerSort: true,
								headerFilter: "input",
							},
						],
					},
				]
			},
	
			onCreate() {
				showToast.success('Tạo báo cáo thành công!')
			},
	
			onReload() {
				showToast.success('Làm mới báo cáo thành công!')
			}
		},
	}
</script>