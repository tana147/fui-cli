<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Nhóm vật tư" class="border-b">
			<template v-slot:append>
				<v-btn color="primary" prepend-icon="mdi-swap-horizontal" variant="flat"
					:disabled="selectedRows.length === 0" @click="openMoveDialog()">Chuyển Nhóm</v-btn>
				<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="openAddDialog()">Thêm mới</v-btn>
				<v-btn color="primary" prepend-icon="mdi-file-excel-outline" variant="flat" @click="exportExcel()">Xuất
					excel</v-btn>
			</template>
		</v-app-bar>

		<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows"
			height="calc(100vh - 48px)" :options="tableOptions" />

		<uc-modal-add v-model="isAddDialogOpen" :nhomTinhChatList="nhomTinhChatList" @onReload="initData" />
		<uc-modal-edit v-model="isEditDialogOpen" :editItem="editItem" :nhomTinhChatList="nhomTinhChatList"
			@onReload="initData" />
		<uc-modal-move v-model="isMoveDialogOpen" :selectedRows="selectedRows" :nhomTinhChatList="nhomTinhChatList"
			:clearSelected="clearSelection" @onReload="initData" />
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
					selectable: true,
				},
				nhomTinhChatList: [],
				selectedRows: [],
				isAddDialogOpen: false,
				isEditDialogOpen: false,
				isMoveDialogOpen: false,
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
			async initData() {
				this.isTableReady = false
				try {
					this.isLoading = true
					this.resetSelection()
					await Promise.all([this.fetchTinhChatList(), this.fetchLoaiDanhMuc()])
					this.initTableHeaders()
				} catch (error) {
					console.error("Lỗi khi tải dữ liệu khởi tạo:", error)
				} finally {
					this.isLoading = false
					this.isTableReady = true
					this.bindSelectionEvents()
				}
			},
			async fetchTinhChatList() {
				this.nhomTinhChatList = await apiCallPromise("work/HH_PhanLoai_TinhChat_Select_Dropdown")
			},
			async fetchLoaiDanhMuc() {
				this.tableRows = await apiCallPromise("work/HH_PhanLoai_NhomVatTu_Select")
			},
			initTableHeaders() {
				this.tableHeaders = [
					{
						title: "",
						formatter: "rowSelection",
						titleFormatter: "rowSelection",
						hozAlign: "center",
						headerSort: false,
						width: 50,
					},
					{
						title: "#",
						formatter: "rownum",
						width: 80,
						hozAlign: "center",
					},
					{
						title: "Tên nhóm vật tư",
						field: "TenNhomVatTu",
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
						title: "Nhóm tính chất",
						field: "TenTinhChat",
						headerSort: true,
						headerFilter: "input",
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
			bindSelectionEvents() {
				this.$nextTick(() => {
					const table = this.$refs.refTable?.table
					if (!table) return
					table.off?.("rowSelectionChanged")
					table.on?.("rowSelectionChanged", (data) => {
						this.selectedRows = data || []
					})
				})
			},
			openAddDialog() {
				this.isAddDialogOpen = true
			},
			openEditDialog(item) {
				this.isEditDialogOpen = true
				this.editItem = { ...item }
			},
			openMoveDialog() {
				this.isMoveDialogOpen = true
			},
			deleteItem(record) {
				const params = { PhanLoai_NhomVatTu_Id: record.PhanLoai_NhomVatTu_Id }
				showConfirm(`Bạn chắc chắn muốn xóa nhóm vật tư? <br/> <b>${record.TenNhomVatTu}</b>`, () => {
					apiCall("work/HH_PhanLoai_NhomVatTu_Delete", params, () => {
						showToast.success("Thành công")
						this.initData()
					})
				})
			},
			clearSelection() {
				this.selectedRows = []
				this.$refs.refTable?.table?.deselectRow?.()
			},
			resetSelection() {
				this.selectedRows = []
			},
			exportExcel() {
				this.$refs.refTable.exportExcel("DanhSachNhomVatTu")
			},
		},
	}
</script>