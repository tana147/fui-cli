<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Nhóm hàng hoá" class="border-b">
			<template v-slot:append>
				<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="openAddDialog()">Thêm mới</v-btn>
				<v-btn color="primary" prepend-icon="mdi-file-excel-outline" variant="flat" @click="exportExcel()">Xuất
					excel</v-btn>
			</template>
		</v-app-bar>

		<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows"
			height="calc(100vh - 48px)" :options="tableOptions" />

		<uc-modal-add v-model="isAddDialogOpen" @onReload="initData" />
		<uc-modal-edit v-model="isEditDialogOpen" :editItem="editItem" @onReload="initData" />
	</z-layout>
</template>

<script>
	export default {
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
				isAddDialogOpen: false,
				isEditDialogOpen: false,
				editItem: {},
			}
		},
		mounted() {
			this.initData()
		},
		computed: {
			formatDateTime() {
				return window.formatDateTime
			},
		},
		watch: {},
		methods: {
			escapeHtml(value) {
				if (value === null || value === undefined) return ""
				return value
					.toString()
					.replace(/&/g, "&amp;")
					.replace(/</g, "&lt;")
					.replace(/>/g, "&gt;")
					.replace(/"/g, "&quot;")
					.replace(/'/g, "&#39;")
			},
			formatNgayGio(Ngay, Gio) {
				const date = Ngay?.split("T")[0] ?? ""
				const time = Gio?.slice(0, 8) ?? ""
				if (!date && !time) return ""
				return this.formatDateTime(date + " " + time)
			},
			buildAuditCell(userValue, dateValue, timeValue, emptyText) {
				const displayUserValue = userValue === "SYSTEM_AT" ? "Hệ thống" : userValue
				const userText = this.escapeHtml(displayUserValue || emptyText)
				const dateTimeText = this.escapeHtml(this.formatNgayGio(dateValue, timeValue) || emptyText)
	
				return `
				<div style="padding:4px 0;line-height:16px;">
					<div style="font-weight:600;color:#344054;">${userText}</div>
					<div style="font-size:11px;color:#667085;">${dateTimeText}</div>
				</div>
				`
			},
			async fetchList() {
				this.tableRows = await apiCallPromise("work/HH_PhanLoai_NhomSanPham_Select")
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
						title: "Tên nhóm hàng hoá",
						field: "TenNhomSanPham",
						headerSort: true,
						headerFilter: "input",
						cellClick: (e, cell) => {
							const item = cell.getRow().getData()
							this.openEditDialog(item)
						},
						formatter: (cell) => {
							return `<div class="font-weight-bold text-primary cursor-pointer back-link-hover">${cell.getValue()}</div>`
						},
					},
					{
						title: "Tạm khóa",
						field: "Is_TamKhoa",
						headerSort: true,
						headerFilter: "input",
						width: 120,
						hozAlign: "center",
						formatter: (cell) => {
							return cell.getValue() ? '<i class="icon-table mdi mdi-lock text-primary"></i>' : ""
						},
					},
					{
						title: "Tạo",
						field: "NguoiTao",
						headerSort: true,
						headerFilter: "input",
						width: 220,
						formatter: (cell) => {
							const item = cell.getRow().getData()
							return this.buildAuditCell(item.NguoiTao, item.NgayTao, item.GioTao, "Chưa rõ")
						},
					},
					{
						title: "Sửa",
						field: "NguoiSua",
						headerSort: true,
						headerFilter: "input",
						width: 220,
						formatter: (cell) => {
							const item = cell.getRow().getData()
							return this.buildAuditCell(item.NguoiSua, item.NgaySua, item.GioSua, "Chưa cập nhật")
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
							this.deleteItem(item)
						},
					},
				]
			},
			openAddDialog() {
				this.isAddDialogOpen = true
			},
			openEditDialog(item) {
				this.isEditDialogOpen = true
				this.editItem = { ...item }
			},
			deleteItem(record) {
				const params = { PhanLoai_NhomSanPham_Id: record.PhanLoai_NhomSanPham_Id }
				showConfirm(`Bạn chắc chắn muốn xóa nhóm hàng hoá? <br/> <b>${record.TenNhomSanPham}</b>`, () => {
					apiCall(
						"work/HH_PhanLoai_NhomSanPham_Delete",
						params,
						() => {
							showToast.success("Thành công")
							this.initData()
						}
					)
				})
			},
			exportExcel() {
				this.$refs.refTable.exportExcel("DanhSachNhomHangHoa")
			},
		},
	}
</script>