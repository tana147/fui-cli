<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Địa điểm" class="border-b">
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
						<v-list-item @click="openImportModal()" prepend-icon="mdi-database-import-outline"
							title="Import excel"> </v-list-item>
					</v-list>
				</v-menu>
			</template>
		</v-app-bar>
		<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows"
			height="calc(100vh - 48px)" :options="tableOptions" />
		<uc-modal-add v-model="isAddModalOpen" @onReload="initData" />
		<uc-modal-edit v-model="isEditModalOpen" @onReload="initData" :editItem="editItem" />
		<uc-modal-import v-model="isImportModalOpen" @onReload="initData" />
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
	            isAddModalOpen: false,
	            isEditModalOpen: false,
	            isImportModalOpen: false,
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
	        buildLocationCell(item) {
	            const tenDiaDiem = this.escapeHtml(item.TenDiaDiem || "")
	
	            return `<div class="font-weight-bold text-primary cursor-pointer back-link-hover">${tenDiaDiem}</div>`
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
	                    width: 60,
	                    hozAlign: "center",
	                },
	                {
	                    title: "Tên địa điểm",
	                    field: "TenDiaDiem",
	                    headerSort: true,
	                    headerFilter: "input",
	                    width: 575,
	                    cellClick: (e, cell) => {
	                        const item = cell.getRow().getData()
	                        this.openEditModal(item)
	                    },
	                    formatter: (cell) => {
	                        const item = cell.getRow().getData()
	                        return this.buildLocationCell(item)
	                    },
	                },
	                {
	                    title: "Ghi chú",
	                    field: "GhiChu",
	                    headerSort: true,
	                    headerFilter: "input",
	                    width: 555,
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
	                    width: 50,
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
	            ].map((header) => ({
	                vertAlign: "middle",
	                ...header,
	            }))
	        },
	        openAddModal() {
	            this.isAddModalOpen = true
	        },
	        openEditModal(item) {
	            this.isEditModalOpen = true
	            this.editItem = { ...item }
	        },
	        deleteItem(record) {
	            showConfirm(`Bạn chắc chắn muốn xóa địa điểm? <br/> <b>${record.TenDiaDiem}</b>`, () => {
	                apiCall("/work/HH_DiaDiem_Delete", { DiaDiem_Id: record.DiaDiem_Id }, () => {
	                    this.initData()
	                    showToast.success("Xóa địa điểm thành công!")
	                })
	            })
	        },
	        exportExcel() {
	            this.$refs.refTable.exportExcel("DanhSachDiaDiem")
	        },
	        openImportModal() {
	            this.isImportModalOpen = true
        },
    },
}
</script>