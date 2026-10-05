<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Quản lý nguyên liệu">
			<template v-slot:append>
				<v-btn color="primary" prepend-icon="mdi-plus" variant="flat"
					@click="vueData.isShowModalAddNguyenLieu = true">Thêm mới</v-btn>
				<v-btn color="primary" prepend-icon="mdi-file-excel-outline" variant="flat"
					@click="isOpenImport = true">Nhập excel</v-btn>
				<v-btn color="primary" prepend-icon="mdi-file-export-outline" variant="flat" @click="exportExcel">Xuất
					excel</v-btn>
			</template>
		</v-app-bar>

		<z-table v-if="isTableReady" ref="refTable" :headers="tableHeaders" :items="tableRows"
			height="calc(100vh - 48px)" @onMove="onMove" :options="tableOptions" />

		<uc-modal-add-nguyen-lieu @onReload="initData" @onContinue="handleContinueAfterAdd"
			:onLoadNhomTinhChat="onLoadNhomTinhChat" :DsTrangThai="statusOptions" :onLoadNhomVatTu="onLoadNhomVatTu"
			:onLoadNhomTenSanPham="onLoadNhomTenSanPham" :LoaiThanhPhanList="loaiThanhPhanOptions" />

		<uc-modal-update-nguyen-lieu v-model="isShowModalUpdateNguyenLieu" @onReload="initData" :record="selectedRecord"
			:initialTab="initialUpdateTab" :DsTrangThai="statusOptions" :onLoadNhomTinhChat="onLoadNhomTinhChat"
			:onLoadNhomVatTu="onLoadNhomVatTu" :onLoadNhomTenSanPham="onLoadNhomTenSanPham"
			:LoaiThanhPhanList="loaiThanhPhanOptions" />
		<uc-modal-import-excel v-model="isOpenImport" :onLoadNhomTinhChat="onLoadNhomTinhChat"
			:onLoadNhomVatTu="onLoadNhomVatTu" :onLoadNhomTenSanPham="onLoadNhomTenSanPham"
			:LoaiThanhPhanList="loaiThanhPhanOptions" :DsTrangThai="statusOptions" @onReload="initData" />
	</z-layout>
</template>

<script>
	export default {
		data() {
			return {
				vueData,
				isTableReady: false,
				tableHeaders: [],
				tableRows: [],
				tableOptions: {
					pagination: true,
					layout: 'fitDataStretch',
					// movableRows: true,
					// rowHeader: { minWidth: 35, width: 35, rowHandle: true, formatter: "handle" },
				},
				selectedRecord: null,
				initialUpdateTab: 'info',
				isShowModalUpdateNguyenLieu: false,
				isOpenImport: false,
				statusOptions: [
					{ title: 'ĐANG SỬ DỤNG', value: 'DANG_SU_DUNG' },
					{ title: 'NGỪNG SỬ DỤNG', value: 'NGUNG_SU_DUNG' },
					{ title: 'ĐANG TEST', value: 'TEST' },
				],
				loaiThanhPhanOptions: [
					{ text: 'Thành phẩm', value: 'TP' },
					{ text: 'Bán thành phẩm', value: 'BTP' },
					{ text: 'Nguyên liệu', value: 'NL' },
				],
			}
		},
		mounted() {
			this.initData()
		},
		methods: {
			async initData() {
				try {
					this.isTableReady = false
					const response = await apiCallPromise('/work/MT_NguyenLieu_Select')
					const rawRows = Array.isArray(response) ? response : Array.isArray(response?.data) ? response.data : []
					this.tableRows = rawRows.map((item) => ({
						...item,
						DonGiaNhapDisplay: item.DonGia_ApDung ? Number(item.DonGia_ApDung).toLocaleString('vi-VN') : '',
						DonGiaBanDisplay: item.GiaBan ? Number(item.GiaBan).toLocaleString('vi-VN') : '',
					}))
					this.initTableHeaders()
				} finally {
					this.isTableReady = true
				}
			},
			initTableHeaders() {
				const numberCompareFilterEditor = (cell, onRendered, success, cancel) => {
					const outer = document.createElement('div')
	
					const container = document.createElement('div')
					container.style.display = 'flex'
					container.style.flexDirection = 'column'
					container.style.gap = '4px'
					container.style.width = '100%'
	
					// Select
					const select = document.createElement('select')
					select.classList.add('tabulator-select')
	
					const operators = ['=', '>', '<', '>=', '<=', '<>']
	
					operators.forEach((op) => {
						const option = document.createElement('option')
						option.value = op
						option.text = op || 'Tất cả'
						select.appendChild(option)
					})
	
					// Input
					const input = document.createElement('input')
					input.type = 'text'
					input.inputMode = 'numeric'
					input.placeholder = 'Giá...'
					input.classList.add('tabulator-edit-input')
	
					input.addEventListener('input', (e) => {
						// Xóa dấu , cũ
						let raw = e.target.value.replace(/,/g, '')
	
						// Chặn ký tự không phải số
						if (!/^\d*$/.test(raw)) return
	
						// Format dấu ,
						e.target.value = raw ? Number(raw).toLocaleString('en-US') : ''
					})
	
					function parseNumber(value) {
						if (!value) return null
						return Number(value.replace(/,/g, ''))
					}
	
					function buildValue() {
						const parsed = parseNumber(input.value)
	
						success({
							op: select.value,
							value: parsed,
						})
					}
	
					select.addEventListener('change', buildValue)
					input.addEventListener('change', buildValue)
	
					container.appendChild(input)
					container.appendChild(select)
	
					outer.appendChild(container)
	
					return outer
				}
	
				function numberCompareFilterFunction(headerValue, rowValue) {
					// nếu chưa chọn gì thì show hết
					if (!headerValue || !headerValue.op || headerValue.value == null) return true
	
					const val = Number(rowValue)
					const compare = Number(headerValue.value)
	
					switch (headerValue.op) {
						case '=':
							return val === compare
						case '>':
							return val > compare
						case '<':
							return val < compare
						case '>=':
							return val >= compare
						case '<=':
							return val <= compare
						case '<>':
							return val !== compare
						default:
							return true
					}
				}
	
				const minMaxFilterEditor = (cell, onRendered, success, cancel) => {
					let end
					const container = document.createElement('span')
					const start = document.createElement('input')
	
					container.className = 'tabulator-min-max-filter'
					container.style.display = 'flex'
					container.style.flexDirection = 'column'
					container.style.gap = '4px'
	
					start.setAttribute('type', 'number')
					start.setAttribute('placeholder', 'Từ')
					start.setAttribute('min', '0')
					start.style.padding = '4px'
					start.style.width = '100%'
					start.style.boxSizing = 'border-box'
	
					const buildValues = () => {
						success({
							start: start.value,
							end: end.value,
						})
					}
	
					const keypress = (event) => {
						if (event.keyCode === 13) {
							buildValues()
						}
	
						if (event.keyCode === 27) {
							cancel()
						}
					}
	
					end = start.cloneNode()
					end.setAttribute('placeholder', 'Đến')
	
					start.addEventListener('change', buildValues)
					start.addEventListener('blur', buildValues)
					start.addEventListener('keydown', keypress)
	
					end.addEventListener('change', buildValues)
					end.addEventListener('blur', buildValues)
					end.addEventListener('keydown', keypress)
	
					container.appendChild(start)
					container.appendChild(end)
	
					return container
				}
	
				const minMaxFilterFunction = (headerValue, rowValue) => {
					const numericValue = Number(rowValue)
	
					if (!headerValue || Number.isNaN(numericValue)) {
						return true
					}
	
					if (headerValue.start !== '') {
						if (headerValue.end !== '') {
							return numericValue >= Number(headerValue.start) && numericValue <= Number(headerValue.end)
						}
	
						return numericValue >= Number(headerValue.start)
					}
	
					if (headerValue.end !== '') {
						return numericValue <= Number(headerValue.end)
					}
	
					return true
				}
	
				this.tableHeaders = [
					{ title: '#', formatter: 'rownum', width: 80, hozAlign: 'center' },
					{ title: 'Độ ưu tiên', field: 'DoUuTien', headerSort: true, headerFilter: 'input', width: 120, hozAlign: 'center' },
					{ title: 'Mã nội bộ', field: 'MaNoiBo', headerSort: true, headerFilter: 'input', width: 120 },
					{
						title: 'Nguyên liệu',
						field: 'TenHangHoa',
						headerSort: true,
						headerFilter: 'input',
						minWidth: 280,
						cellClick: (e, cell) => {
							const item = cell.getRow().getData()
							this.openUpdateModal(item)
						},
						formatter: (cell) => `<div class="font-weight-bold text-primary cursor-pointer back-link-hover">${cell.getValue() || ''}</div>`,
					},
					{
						title: 'Loại NL',
						field: 'LoaiNguyenLieu',
						headerSort: true,
						headerFilter: 'list',
						headerFilterParams: {
							values: {
								'': 'Tất cả',
								NL: 'NL',
								TP: 'TP',
								BTP: 'BTP',
							},
						},
						width: 110,
						hozAlign: 'center',
					},
					{ title: 'Nhóm tính chất', field: 'TenTinhChat', headerSort: true, headerFilter: 'input', minWidth: 180 },
					{ title: 'Nhóm vật tư', field: 'TenNhomVatTu', headerSort: true, headerFilter: 'input', minWidth: 180 },
					{ title: 'Nhóm sản phẩm', field: 'TenNhomSanPham', headerSort: true, headerFilter: 'input', minWidth: 180 },
					{
						title: 'Đơn giá nhập',
						field: 'DonGia_ApDung',
						headerSort: true,
						width: 150,
						hozAlign: 'right',
						formatter: (cell) => {
							const value = cell.getValue()
							return value ? Number(value).toLocaleString('vi-VN') : ''
						},
						headerFilter: numberCompareFilterEditor,
						headerFilterFunc: numberCompareFilterFunction,
						headerFilterLiveFilter: false,
					},
					{
						title: 'Đơn giá bán',
						field: 'GiaBan',
						headerSort: true,
						width: 150,
						hozAlign: 'right',
						formatter: (cell) => {
							const value = cell.getValue()
							return value ? Number(value).toLocaleString('vi-VN') : ''
						},
						headerFilter: numberCompareFilterEditor,
						headerFilterFunc: numberCompareFilterFunction,
						headerFilterLiveFilter: false,
					},
					{ title: 'ĐV nhập', field: 'TenDonVi', headerSort: true, headerFilter: 'input', width: 120, hozAlign: 'center' },
					{
						title: 'Tổng ĐV quy đổi',
						field: 'TongDonViQuyDoi',
						headerSort: true,
						headerFilter: 'input',
						width: 180,
						hozAlign: 'center',
						formatter: (cell) => `${cell.getValue() ?? 0}`,
					},
					{
						title: 'Tổng địa điểm áp dụng',
						field: 'TongDiaDiemApDung',
						headerSort: true,
						headerFilter: 'input',
						width: 180,
						hozAlign: 'center',
						formatter: (cell) => `${cell.getValue() ?? 0}`,
					},
					{
						title: 'Trạng thái',
						field: 'TrangThai',
						headerSort: true,
						headerFilter: 'input',
						width: 170,
						formatter: (cell) => {
							const value = cell.getValue() || ''
							// Tabulator chỉ render HTML string, không parse directive Vue như v-if
							if (!value) return ''
							const text = getStatusText(value)
							const color = getStatusColor(value)
							return `
								<div class="chip chip-${color}">
									<span>${text}</span>
								</div>
								`
						},
					},
					{
						title: 'Tạm khóa',
						field: 'Is_TamKhoa',
						headerSort: false,
						width: 100,
						hozAlign: 'center',
						headerFilter: 'list',
						headerFilterParams: {
							values: {
								'': 'Tất cả',
								true: 'Tạm khóa',
								false: 'Không khóa',
							},
						},
						formatter: (cell) => {
							if (!cell.getValue()) return ''
							return '<i class="icon-table text-primary mdi mdi-lock-outline"></i>'
						},
					},
					{
						title: '',
						width: 60,
						hozAlign: 'center',
						headerSort: false,
						formatter: () => '<i class="icon-table text-red mdi mdi-trash-can-outline"></i>',
						cellClick: (e, cell) => {
							const item = cell.getRow().getData()
							this.deleteItem(item)
						},
					},
				]
			},
			openUpdateModal(item, tab = 'info') {
				this.selectedRecord = { ...item }
				this.initialUpdateTab = tab
				this.isShowModalUpdateNguyenLieu = true
			},
			async handleContinueAfterAdd(payload) {
				await this.initData()
				const foundRecord = this.tableRows.find((item) => item.MaNoiBo === payload?.MaNoiBo) || this.tableRows.find((item) => item.TenHangHoa === payload?.TenHangHoa)
				if (foundRecord) {
					this.openUpdateModal(foundRecord)
				}
			},
			deleteItem(item) {
				showConfirm(`Bạn chắc chắn muốn xóa nguyên liệu? <br/> <b>${item.TenHangHoa}</b>`, () => {
					apiCall('/work/MT_NguyenLieu_Delete', { HangHoa_Id: item.HangHoa_Id }, () => {
						showToast.success('Xóa nguyên liệu thành công!')
						this.initData()
					})
				})
			},
			exportExcel() {
				this.$refs.refTable?.exportExcel('DanhSachNguyenLieu')
			},
			onLoadNhomTinhChat() {
				return apiCallPromise('/work/HH_PhanLoai_TinhChat_Select_Dropdown')
			},
			onLoadNhomVatTu(tinhChatId) {
				return apiCallPromise('/work/HH_PhanLoai_NhomVatTu_Select_Dropdown', {
					PhanLoai_TinhChat_Id: tinhChatId,
				})
			},
			onLoadNhomTenSanPham() {
				return apiCallPromise('/work/HH_PhanLoai_NhomSanPham_Select_Dropdown')
			},
			onMove(row) {
				console.log('xxxxxx', row.getData())
				console.log("Vị trí mới:", row.getPosition());
			}
		},
	}
</script>