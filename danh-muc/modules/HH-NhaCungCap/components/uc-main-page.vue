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

		<uc-stats :items="statsCards" />

		<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows"
			height="calc(100vh - 160px)" :options="tableOptions" />

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
	    computed: {
	        statsCards() {
	            const totalSuppliers = this.tableRows.length
	            const activeSuppliers = this.tableRows.filter((item) => {
	                return item.TrangThai === 'DANG_SU_DUNG' && item.Is_TamKhoa !== true
	            }).length
	            const lockedSuppliers = this.tableRows.filter((item) => item.Is_TamKhoa === true).length
	            const totalProducts = this.tableRows.reduce((total, item) => {
	                return total + this.toSafeNumber(item.TongSoSanPham)
	            }, 0)
	
	            return [
	                {
	                    title: 'Tổng nhà cung cấp',
	                    value: this.formatStatValue(totalSuppliers),
	                    icon: 'mdi-domain',
	                    coloricon: 'blue-darken-2',
	                    colortitle: 'grey-darken-3',
	                    bgicon: 'blue-lighten-5',
	                    bgclass: 'white',
	                },
	                {
	                    title: 'Đang sử dụng',
	                    value: this.formatStatValue(activeSuppliers),
	                    icon: 'mdi-check-circle-outline',
	                    coloricon: 'green-darken-2',
	                    colortitle: 'grey-darken-3',
	                    bgicon: 'green-lighten-5',
	                    bgclass: 'white',
	                },
	                {
	                    title: 'Tạm khóa',
	                    value: this.formatStatValue(lockedSuppliers),
	                    icon: 'mdi-lock-outline',
	                    coloricon: 'deep-orange-darken-2',
	                    colortitle: 'grey-darken-3',
	                    bgicon: 'deep-orange-lighten-5',
	                    bgclass: 'white',
	                },
	                {
	                    title: 'Tổng sản phẩm',
	                    value: this.formatStatValue(totalProducts),
	                    icon: 'mdi-package-variant-closed',
	                    coloricon: 'teal-darken-2',
	                    colortitle: 'grey-darken-3',
	                    bgicon: 'teal-lighten-5',
	                    bgclass: 'white',
	                },
	            ]
	        },
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
	        toSafeNumber(value) {
	            const numberValue = Number(value)
	            return Number.isFinite(numberValue) ? numberValue : 0
	        },
	        formatStatValue(value) {
	            return this.toSafeNumber(value).toLocaleString('vi-VN')
	        },
	        formatDebtValue(value) {
	            if (value === null || value === undefined || value === '') return ''
	            return this.toSafeNumber(value).toLocaleString('vi-VN')
	        },
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
	                const statusText = getStatusText(item.TrangThai)
	                const lockText = item.Is_TamKhoa === true ? 'Tạm khóa' : 'Không khóa'
	                const supplierStatusFilterKey = item.Is_TamKhoa === true ? 'TAM_KHOA' : item.TrangThai
	                return {
	                    ...item,
	                    dsFilesParse: item.DanhSachFile ? JSON.parse(item.DanhSachFile) : [],
	                    SupplierFilterText: [item.TenNhaCungCap, item.MaSoThue].filter(Boolean).join(' '),
	                    SupplierStatusFilterText: [statusText, lockText].join(' '),
	                    SupplierStatusFilterKey: supplierStatusFilterKey,
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
	            const priorityValue = item.DoUuTien === null || item.DoUuTien === undefined || item.DoUuTien === ''
	                ? ''
	                : this.escapeHtml(item.DoUuTien)
	            const ratingText = item.DanhGia ? this.escapeHtml(item.DanhGia) : ''
	            const totalProducts = this.escapeHtml(item.TongSoSanPham ?? '')
	            const taxCode = this.escapeHtml(item.MaSoThue || '')
	            const metaParts = []

	            if (priorityValue) {
	                metaParts.push(`<span><span style="font-weight:600;color:#344054;">Ưu tiên:</span> ${priorityValue}</span>`)
	            }
	
	            if (ratingText) {
	                metaParts.push(`<span><span style="font-weight:600;color:#344054;">Đánh giá:</span> ${ratingText}</span>`)
	            }
	
	            if (totalProducts !== '') {
	                metaParts.push(`<span><span style="font-weight:600;color:#344054;">Sản phẩm:</span> ${totalProducts}</span>`)
	            }
	
	            if (taxCode) {
	                metaParts.push(`<span><span style="font-weight:600;color:#344054;">MST:</span> ${taxCode}</span>`)
	            }
	
	            const metaHtml = metaParts.length
	                ? `<div style="margin-top:4px;font-size:11px;line-height:15px;color:#667085;display:flex;flex-wrap:wrap;gap:8px 12px;">${metaParts.join('')}</div>`
	                : ''
	
	            return `<div class="cursor-pointer" style="padding:4px 0;line-height:16px;"><div class="font-weight-bold text-primary back-link-hover" style="display:inline-block;line-height:18px;">${supplierName}</div>${metaHtml}</div>`
	        },
	        buildSupplierCodeCell(item) {
	            const supplierCode = this.escapeHtml(item.MaNhaCungCap || '')
	            const groupTags = (item.dsNhomPhanLoaiSuplier || [])
	                .map((group) => {
	                    const label = this.escapeHtml(group)
	                    return `<span style="display:inline-flex;align-items:center;padding:0 6px;border-radius:999px;background:#eef2ff;color:#334155;font-size:11px;line-height:15px;max-width:100%;white-space:nowrap;">${label}</span>`
	                })
	                .join('')
	            const groupHtml = groupTags
	                ? `<div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:1px;line-height:15px;">${groupTags}</div>`
	                : ''

	            return `<div style="padding:1px 0;"><div style="font-weight:600;line-height:16px;">${supplierCode}</div>${groupHtml}</div>`
	        },
	        buildBankCell(item) {
	            const accountNumber = this.escapeHtml(item.NganHang_SoTaiKhoan || '')
	            const debtValue = this.formatDebtValue(item.CongNo)
	            const bankName = this.escapeHtml(item.NganHang_Ten || '')
	            const branchName = this.escapeHtml(item.NganHang_ChiNhanh || '')
	            const bankInfo = [bankName, branchName].filter(Boolean).join(' - ')
	            const accountLabel = debtValue ? `${accountNumber} (Công nợ: ${this.escapeHtml(debtValue)})` : accountNumber
	            const accountHtml = accountLabel ? `<div style="font-weight:600;line-height:16px;">${accountLabel}</div>` : ''
	            const bankHtml = bankInfo ? `<div style="line-height:15px;color:#667085;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${bankInfo}</div>` : ''
	            return `<div style="padding:1px 0;">${accountHtml}${bankHtml}</div>`
	        },
	        buildContactCell(item) {
	            const phone = this.escapeHtml(item.DienThoai || '')
	            const address = this.escapeHtml(item.DiaChi || '')
	            const phoneHtml = phone ? `<div style="font-weight:600;line-height:16px;">${phone}</div>` : ''
	            const addressHtml = address
	                ? `<div style="line-height:15px;color:#667085;white-space:normal;word-break:break-word;">${address}</div>`
	                : ''
	            return `<div style="padding:1px 0;">${phoneHtml}${addressHtml}</div>`
	        },
	        buildStatusCell(item) {
	            const statusText = this.escapeHtml(getStatusText(item.TrangThai))
	            const statusColor = getStatusColor(item.TrangThai)
	            const lockText = item.Is_TamKhoa === true ? 'Tạm khóa' : 'Không'
	            const lockColor = item.Is_TamKhoa === true ? 'deep-orange-darken-2' : 'grey-darken-1'

	            return `
	                <div style="padding:2px 0;line-height:16px;">
	                    <div><span style="font-weight:600;color:#344054;">Tình trạng:</span> <span class="text-${statusColor}">${statusText}</span></div>
	                    <div style="margin-top:2px;"><span style="font-weight:600;color:#344054;">Tạm khóa:</span> <span class="text-${lockColor}">${lockText}</span></div>
	                </div>
	            `
	        },
	        initTableHeaders() {
	            this.tableHeaders = [
	                {
	                    title: '#',
	                    formatter: 'rownum',
	                    width: 20,
	                    hozAlign: 'center',
	                },
	                {
	                    title: 'Mã NCC',
	                    field: 'MaNhaCungCap',
	                    headerSort: true,
	                    headerFilter: 'input',
	                    width: 110,
	                    formatter: (cell) => {
	                        const item = cell.getRow().getData()
	                        return this.buildSupplierCodeCell(item)
	                    },
	                },
	                {
	                    title: 'Nhà cung cấp',
	                    field: 'SupplierFilterText',
	                    headerSort: true,
	                    headerFilter: 'input',
	                    headerFilterPlaceholder: 'Tên nhà cung cấp / MST',
	                    width: 615,
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
	                    title: 'Ngân hàng',
	                    field: 'NganHang_Ten',
	                    headerSort: true,
	                    headerFilter: 'input',
	                    width: 240,
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
	                    width: 440,
	                    formatter: (cell) => {
	                        const item = cell.getRow().getData()
	                        return this.buildContactCell(item)
	                    },
	                },
	                {
	                    title: 'Trạng thái',
	                    field: 'SupplierStatusFilterKey',
	                    headerSort: true,
	                    headerFilter: 'list',
	                    headerFilterParams: {
	                        values: {
	                            '': 'Tất cả',
	                            DANG_SU_DUNG: 'Đang sử dụng',
	                            NGUNG_SU_DUNG: 'Ngừng sử dụng',
	                            TAM_KHOA: 'Tạm khóa',
	                        },
	                    },
	                    hozAlign: 'left',
	                    width: 220,
	                    formatter: (cell) => {
	                        const item = cell.getRow().getData()
	                        return this.buildStatusCell(item)
	                    },
	                },
	                {
	                    title: '',
						width: 15,
						minWidth: 15,
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