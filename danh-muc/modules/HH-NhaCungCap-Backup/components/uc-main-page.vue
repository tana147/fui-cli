<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Quản lý nhà cung cấp" class="border-b">
			<template v-slot:append>
				<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="openAddDialog">Thêm mới</v-btn>
				<v-menu>
					<template v-slot:activator="{ props }">
						<v-btn color="primary" prepend-icon="mdi-tune" append-icon="mdi-chevron-down" variant="flat"
							v-bind="props">Thao tác</v-btn>
					</template>
					<v-list density="compact">
						<v-list-item @click="exportExcel" prepend-icon="mdi-file-excel-outline" title="Xuất excel" />
					</v-list>
				</v-menu>
			</template>
		</v-app-bar>

		<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows"
			height="calc(100vh - 48px)" :options="tableOptions" />

		<uc-modal-add v-model:isShow="isAddDialogOpen" :loadData="initData" :dsTrangThai="statusOptions"
			:dsPhanLoaiSuplier="phanLoaiSuplierRows" />
		<uc-modal-edit v-model:isShow="isEditDialogOpen" :selectedItem="selectedSuplier" :loadData="initData"
			:dsTrangThai="statusOptions" :dsPhanLoaiSuplier="phanLoaiSuplierRows" />
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
	            phanLoaiSuplierRows: [],
	            selectedSuplier: {},
	            statusOptions: [
	                {
	                    title: 'Đang sử dụng',
	                    value: 'DANG_SU_DUNG',
	                },
	                {
	                    title: 'Ngừng sử dụng',
	                    value: 'NGUNG_SU_DUNG',
	                },
	            ],
	        }
	    },
	    mounted() {
	        this.initData()
	    },
	    watch: {
	        isAddDialogOpen(value) {
	            if (value) {
	                this.loadPhanLoaiSuplier()
	            }
	        },
	        isEditDialogOpen(value) {
	            if (value) {
	                this.loadPhanLoaiSuplier()
	            }
	        },
	    },
	    methods: {
	        async initData() {
	            this.isTableReady = false
	            try {
	                this.isLoading = true
	                await this.loadSuppliers()
	                this.initTableHeaders()
	            } catch (error) {
	                console.error('Lỗi khi tải dữ liệu nhà cung cấp:', error)
	            } finally {
	                this.isLoading = false
	                this.isTableReady = true
	                loadingPage.hide()
	            }
	        },
	        async loadSuppliers() {
	            const response = await apiCallPromise('work/HH_NhaCungCap_Select')
	            this.tableRows = response.map((item) => {
	                return {
	                    ...item,
	                    dsFilesParse: item.DanhSachFile ? JSON.parse(item.DanhSachFile) : [],
	                    dsNhomPhanLoaiSuplier: item.TenNhomPhanLoai
	                        ? item.TenNhomPhanLoai
	                            .split(',')
	                            .map((group) => group.trim())
	                            .filter(Boolean)
	                        : [],
	                }
	            })
	            loadingPage.hide()
	        },
	        loadPhanLoaiSuplier() {
	            apiCall('work/HH_PhanLoai_NCC_Select', null, (response) => {
	                this.phanLoaiSuplierRows = response.data
	            })
	        },
	        escapeHtml(value) {
	            if (value === null || value === undefined) return ''
	            return value
	                .toString()
	                .replace(/&/g, '&amp;')
	                .replace(/</g, '&lt;')
	                .replace(/>/g, '&gt;')
	                .replace(/"/g, '&quot;')
	                .replace(/'/g, '&#39;')
	        },
	        buildSupplierNameCell(item) {
	            const supplierName = this.escapeHtml(item.TenNhaCungCap || '')
	            const groupTags = (item.dsNhomPhanLoaiSuplier || [])
	                .map((group) => {
	                    const label = this.escapeHtml(group)
	                    return `<span style="display:inline-flex;align-items:center;padding:0 6px;border-radius:999px;background:#eef2ff;color:#334155;font-size:11px;line-height:15px;max-width:100%;white-space:nowrap;">${label}</span>`
	                })
	                .join('')
	            const ratingText = item.DanhGia ? this.escapeHtml(item.DanhGia) : ''
	            const ratingHtml = ratingText
	                ? `<div style="margin-top:1px;font-size:11px;line-height:15px;color:#667085;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"><span style="font-weight:600;color:#344054;">Đánh giá:</span> ${ratingText}</div>`
	                : ''
	            const groupHtml = groupTags
	                ? `<div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:1px;line-height:15px;">${groupTags}</div>`
	                : ''
	
	            return `<div class="cursor-pointer" style="padding:1px 0;line-height:16px;"><div class="font-weight-bold text-primary back-link-hover" style="display:inline-block;line-height:16px;">${supplierName}</div>${groupHtml}${ratingHtml}</div>`
	        },
	        buildBankCell(item) {
	            const accountNumber = this.escapeHtml(item.NganHang_SoTaiKhoan || '')
	            const bankName = this.escapeHtml(item.NganHang_Ten || '')
	            const branchName = this.escapeHtml(item.NganHang_ChiNhanh || '')
	            const bankInfo = [bankName, branchName].filter(Boolean).join(' - ')
	            const accountHtml = accountNumber ? `<div style="font-weight:600;line-height:16px;">${accountNumber}</div>` : ''
	            const bankHtml = bankInfo ? `<div style="line-height:15px;color:#667085;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${bankInfo}</div>` : ''
	            return `<div style="padding:1px 0;">${accountHtml}${bankHtml}</div>`
	        },
	        buildContactCell(item) {
	            const phone = this.escapeHtml(item.DienThoai || '')
	            const address = this.escapeHtml(item.DiaChi || '')
	            const phoneHtml = phone ? `<div style="font-weight:600;line-height:16px;">${phone}</div>` : ''
	            const addressHtml = address ? `<div style="line-height:15px;color:#667085;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${address}</div>` : ''
	            return `<div style="padding:1px 0;">${phoneHtml}${addressHtml}</div>`
	        },
	        initTableHeaders() {
	            this.tableHeaders = [
	                {
	                    title: '#',
	                    formatter: 'rownum',
	                    width: 80,
	                    hozAlign: 'center',
	                },
	                {
	                    title: 'Độ ưu tiên',
	                    field: 'DoUuTien',
	                    width: 120,
	                    hozAlign: 'center',
	                    headerSort: true,
	                    headerFilter: 'input',
	                },
	                {
	                    title: 'Mã nhà cung cấp',
	                    field: 'MaNhaCungCap',
	                    headerSort: true,
	                    headerFilter: 'input',
	                    width: 180,
	                },
	                {
	                    title: 'Tên nhà cung cấp',
	                    field: 'TenNhaCungCap',
	                    headerSort: true,
	                    headerFilter: 'input',
	                    width: 300,
	                    cellClick: (e, cell) => {
	                        const item = cell.getRow().getData()
	                        this.openEditDialog(item)
	                    },
	                    formatter: (cell) => {
	                        const item = cell.getRow().getData()
	                        return this.buildSupplierNameCell(item)
	                    },
	                },
	                {
	                    title: 'Sản phẩm',
	                    field: 'TongSoSanPham',
	                    headerSort: true,
	                    headerFilter: 'input',
	                    hozAlign: 'center',
	                    width: 140,
	                },
	                {
	                    title: 'MST',
	                    field: 'MaSoThue',
	                    headerSort: true,
	                    headerFilter: 'input',
	                    width: 160,
	                },
	                {
	                    title: 'Ngân hàng',
	                    field: 'NganHang_Ten',
	                    headerSort: true,
	                    headerFilter: 'input',
	                    width: 280,
	                    formatter: (cell) => {
	                        const item = cell.getRow().getData()
	                        return this.buildBankCell(item)
	                    },
	                },
	                {
	                    title: 'SĐT / Địa chỉ',
	                    field: 'DiaChi',
	                    headerSort: true,
	                    headerFilter: 'input',
	                    width: 320,
	                    formatter: (cell) => {
	                        const item = cell.getRow().getData()
	                        return this.buildContactCell(item)
	                    },
	                },
	                {
	                    title: 'Trạng thái',
	                    field: 'TrangThai',
	                    headerSort: true,
	                    headerFilter: 'list',
	                    headerFilterParams: {
	                        values: {
	                            '': 'Tất cả',
	                            ...this.statusOptions.reduce((result, item) => {
	                                result[item.value] = item.title
	                                return result
	                            }, {}),
	                        },
	                    },
	                    hozAlign: 'center',
	                    width: 140,
	                    formatter: (cell) => {
	                        const item = cell.getRow().getData()
	                        const text = getStatusText(item.TrangThai)
	                        const color = getStatusColor(item.TrangThai)
	                        return `<div><span class="text-${color}">${text}</span></div>`
	                    },
	                },
	                {
	                    title: 'Tạm khóa',
	                    field: 'Is_TamKhoa',
	                    hozAlign: 'center',
	                    width: 120,
	                    headerFilter: 'list',
	                    headerFilterParams: {
	                        values: {
	                            '': 'Tất cả',
	                            true: 'Tạm khóa',
	                            false: 'Không khóa',
	                        },
	                    },
	                    headerSort: false,
	                    formatter: (cell) => {
	                        return cell.getValue() ? `<i class="icon-table mdi mdi-lock"></i>` : ''
	                    },
	                },
	                {
	                    title: '',
	                    width: 60,
	                    hozAlign: 'center',
	                    headerSort: false,
	                    formatter: () => {
	                        return `<i class="icon-table text-red mdi mdi-trash-can-outline"></i>`
	                    },
	                    cellClick: (e, cell) => {
	                        const item = cell.getRow().getData()
	                        this.deleteSupplier(item)
	                    },
	                },
	            ].map((header) => ({
	                vertAlign: 'middle',
	                ...header,
	            }))
	        },
	        openAddDialog() {
	            this.isAddDialogOpen = true
	        },
	        openEditDialog(item) {
	            this.selectedSuplier = { ...item, dsFilesParse: item.dsFilesParse || [] }
	            this.isEditDialogOpen = true
	        },
	        deleteSupplier(record) {
	            showConfirm(`Bạn chắc chắn muốn xóa nhà cung cấp? <br/> <b>${record.TenNhaCungCap}</b>`, () => {
	                apiCall('work/HH_NhaCungCap_Delete', { NhaCungCap_Id: record.NhaCungCap_Id }, () => {
	                    this.initData()
	                    showToast.success('Xóa nhà cung cấp thành công!')
	                })
	            })
	        },
	        exportExcel() {
	            this.$refs.refTable.exportExcel('DanhSachNhaCungCap')
	        },
	    },
	}
</script>