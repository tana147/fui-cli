<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Nhóm nhà cung cấp" class="border-b">
			<template v-slot:append>
				<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="openAddModal()">Thêm mới</v-btn>
				<v-menu>
					<template v-slot:activator="{ props }">
						<v-btn color="primary" prepend-icon="mdi-tune" append-icon="mdi-chevron-down" variant="flat"
							v-bind="props">Thao tác</v-btn>
					</template>
					<v-list density="compact">
						<v-list-item @click="exportExcel()" prepend-icon="mdi-file-excel-outline" title="Xuất excel">
						</v-list-item>
					</v-list>
				</v-menu>
			</template>
		</v-app-bar>

		<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows"
			height="calc(100vh - 48px)" :options="tableOptions" />

		<uc-modal-add v-model="isAddModalOpen" @onReload="initData" />
		<uc-modal-edit v-model="isEditModalOpen" @onReload="initData" :editItem="editItem" />
	</z-layout>
</template>

<script>
	export default {
	    data() {
	        return {
	            isTableReady: false,
	            isLoading: false,
	            tableHeaders: [],
	            tableRows: [],
	            tableOptions: {
	                pagination: true,
	            },
	            isAddModalOpen: false,
	            isEditModalOpen: false,
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
	            this.tableRows = await apiCallPromise("work/HH_PhanLoai_NCC_Select")
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
	                    title: "Tên nhóm phân loại",
	                    field: "TenNhomPhanLoai",
	                    headerSort: true,
	                    headerFilter: "input",
	                    cellClick: (e, cell) => {
	                        const item = cell.getRow().getData()
	                        this.openEditModal(item)
	                    },
	                    formatter: (cell) => {
	                        return `<div class="font-weight-bold text-primary cursor-pointer back-link-hover">${cell.getValue()}</div>`
	                    },
	                },
	                {
	                    title: "Ghi chú",
	                    field: "GhiChu",
	                    headerSort: true,
	                    headerFilter: "input",
	                },
	                {
	                    title: "Tạm khóa",
	                    field: "Is_TamKhoa",
	                    headerSort: true,
	                    headerFilter: "input",
	                    formatter: (cell) => {
	                        return cell.getValue() ? '<i class="icon-table mdi mdi-lock text-primary"></i>' : ""
	                    },
	                    hozAlign: "center",
	                    width: 120,
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
	        openAddModal() {
	            this.isAddModalOpen = true
	        },
	        openEditModal(item) {
	            this.isEditModalOpen = true
	            this.editItem = { ...item }
	        },
	        deleteItem(record) {
	            const params = {
	                PhanLoai_NhaCungCap_Id: record.PhanLoai_NhaCungCap_Id,
	            }
	            showConfirm(`Bạn chắc chắn muốn xóa nhóm phân loại? <br/> <b>${record.TenNhomPhanLoai}</b>`, () => {
	                apiCall("work/HH_PhanLoai_NCC_Delete", params, () => {
	                    showToast.success("Xoá nhóm phân loại thành công")
	                    this.initData()
	                })
	            })
	        },
	        exportExcel() {
	            this.$refs.refTable.exportExcel("DanhSachPhanLoaiNCC")
	        },
	    },
	}
</script>