<template>
	<div class="table-host">
		<v-progress-linear v-if="isLoading" indeterminate color="primary"
			style="position:absolute;top:0;left:0;right:0;z-index:10" />

		<z-table v-if="isInitTable" ref="refTable" :headers="tableHeader" :items="data" height="calc(100vh - 138px)"
			:options="tableConfig" />

		<div v-if="!hasSearched && data.length === 0 && !isLoading" class="empty-overlay">
			<uc-empty text="Chọn bộ lọc và nhấn Tìm để xem tồn kho" />
		</div>

		<div v-if="hasSearched && data.length === 0 && !isLoading" class="empty-overlay">
			<uc-empty text="Không có dữ liệu cho bộ lọc đã chọn" />
		</div>
	</div>
</template>

<script>
	export default {
		props: {
			data: Array,
			isLoading: Boolean,
			hasSearched: Boolean,
		},
		data() {
			return {
				isInitTable: false,
				tableHeader: [],
				tableConfig: {
					pagination: false,
					reactiveData: false,
				},
	
				DSTinhTrangChenhLech: [
					{ title: 'Tất cả', value: 'TAT_CA' },
					{ title: 'Khớp', value: 'KHOP' },
					{ title: 'Thừa', value: 'THUA' },
					{ title: 'Thiếu', value: 'THIEU' },
					{ title: 'Chưa có', value: 'CHUA_CO' },
				],
	
				DSTinhTrang: [
					{ title: 'Tất cả', value: 'TAT_CA' },
					{ title: 'Đã chốt', value: 'DA_CHOT' },
					{ title: 'Chưa chốt', value: 'CHUA_CHOT' },
					{ title: 'Chưa rõ', value: 'CHUA_CO_DU_LIEU' },
				],
	
				mapTinhTrang: {
					'CHUA_CHOT': { text: 'Chưa chốt', color: 'blue-grey' },
					'DA_CHOT': { text: 'Đã chốt', color: 'success' },
					'CHUA_CO_DU_LIEU': { text: 'Chưa có dữ liệu', color: 'grey' },
				},
			}
		},
		mounted() {
			this.initHeader()
			this.isInitTable = true
		},
		watch: {
			data() {
				this.renderTableData()
			},
			isInitTable(val) {
				if (val) this.renderTableData()
			},
		},
		methods: {
			renderTableData() {
				if (!this.isInitTable) return
				const table = this.$refs.refTable?.table
				if (!table) return
				table.replaceData(this.data || [])
			},
	
			exportExcel() {
				const table = this.$refs.refTable?.table
				if (!table) return
				table.download('xlsx', 'BangTonKho.xlsx', { sheetName: 'Bảng tồn kho' })
			},
	
			getTonStatus(TonHienTai, TonKiemKe) {
				if (
					TonHienTai === null || TonHienTai === undefined ||
					TonKiemKe === null || TonKiemKe === undefined ||
					isNaN(Number(TonHienTai)) || isNaN(Number(TonKiemKe))
				) {
					return { color: 'grey', text: 'Chưa có', status: 'CHUA_CO' }
				}
				const chenhLech = TonHienTai - TonKiemKe
				if (chenhLech > 0) {
					return { color: 'success', text: 'Thừa ' + chenhLech.toLocaleString('vi-VN'), status: 'THUA' }
				}
				if (chenhLech < 0) {
					return { color: 'error', text: 'Thiếu ' + Math.abs(chenhLech).toLocaleString('vi-VN'), status: 'THIEU' }
				}
				return { color: 'grey', text: 'Khớp', status: 'KHOP' }
			},
	
			createNumberFilterEditor(cell, onRendered, success, cancel) {
				const outer = document.createElement('div')
				const container = document.createElement('div')
				container.style.display = 'flex'
				container.style.flexDirection = 'column'
				container.style.gap = '4px'
				container.style.width = '100%'
	
				const select = document.createElement('select')
				select.classList.add('tabulator-select')
					;['=', '>', '<', '>=', '<=', '<>'].forEach(function (op) {
						const option = document.createElement('option')
						option.value = op
						option.text = op
						select.appendChild(option)
					})
	
				const input = document.createElement('input')
				input.type = 'text'
				input.inputMode = 'numeric'
				input.placeholder = 'Nhập...'
				input.classList.add('tabulator-edit-input')
	
				input.addEventListener('input', function (e) {
					let value = String(e.target.value || '')
					value = value.replace(/[^\d.,]/g, '')
					value = value.replace(/\./g, '')
					const firstComma = value.indexOf(',')
					if (firstComma !== -1) {
						value = value.slice(0, firstComma + 1) + value.slice(firstComma + 1).replace(/,/g, '')
					}
					const parts = value.split(',')
					const integerPart = (parts[0] || '').replace(/\D/g, '')
					const decimalPart = parts[1] !== undefined ? parts[1].replace(/\D/g, '') : undefined
					const formattedInteger = integerPart ? Number(integerPart).toLocaleString('vi-VN') : ''
					e.target.value = decimalPart !== undefined
						? formattedInteger + ',' + decimalPart
						: formattedInteger
				})
	
				function parseNumber(value) {
					if (!value) return null
					const normalized = String(value).replace(/\./g, '').replace(',', '.')
					const parsed = Number(normalized)
					return Number.isFinite(parsed) ? parsed : null
				}
	
				function buildValue() {
					success({ op: select.value, value: parseNumber(input.value) })
				}
	
				select.addEventListener('change', buildValue)
				input.addEventListener('change', buildValue)
	
				container.appendChild(input)
				container.appendChild(select)
				outer.appendChild(container)
				return outer
			},
	
			numberFilterFunc(headerValue, rowValue) {
				if (!headerValue || !headerValue.op || headerValue.value == null) return true
				const val = Number(rowValue)
				const compare = Number(headerValue.value)
				switch (headerValue.op) {
					case '=': return val === compare
					case '>': return val > compare
					case '<': return val < compare
					case '>=': return val >= compare
					case '<=': return val <= compare
					case '<>': return val !== compare
					default: return true
				}
			},
	
			makeNumCol(title, field, width) {
				return {
					title: title,
					field: field,
					hozAlign: 'end',
					width: width || 110,
					headerFilter: this.createNumberFilterEditor,
					headerFilterFunc: this.numberFilterFunc,
					headerFilterLiveFilter: false,
				}
			},
	
			makeMoneyCol(title, field, width) {
				return {
					title: title,
					field: field,
					hozAlign: 'end',
					width: width || 100,
					formatter: 'money',
					formatterParams: {
						decimal: ',',
						thousand: '.',
						symbol: '',
						symbolAfter: false,
						precision: 2,
					},
					headerFilter: this.createNumberFilterEditor,
					headerFilterFunc: this.numberFilterFunc,
					headerFilterLiveFilter: false,
				}
			},
	
			initHeader() {
				const self = this
	
				this.tableHeader = [
					{
						title: 'Thông tin sản phẩm',
						columns: [
							{ title: 'Mã hàng', field: 'MaNoiBo', width: 120, headerFilter: 'input' },
							{ title: 'Tên hàng', field: 'TenHangHoa', width: 230, headerFilter: 'input' },
							{ title: 'Nhóm SP', field: 'TenNhomSanPham', width: 160, headerFilter: 'input' },
							{ title: 'ĐVT', field: 'TenDonVi', width: 80, headerFilter: 'input' },
						],
					},
					{
						title: 'Tồn đầu',
						columns: [
							this.makeNumCol('Số lượng', 'TonDau_SoLuong'),
							this.makeMoneyCol('Giá trị', 'TonDau_GiaTri'),
						],
					},
					{
						title: 'Nhập',
						columns: [
							this.makeNumCol('Số lượng', 'Nhap_SoLuong'),
							this.makeMoneyCol('Giá trị', 'Nhap_GiaTri'),
						],
					},
					{
						title: 'Xuất',
						columns: [
							this.makeNumCol('Số lượng', 'Xuat_SoLuong'),
							this.makeMoneyCol('Giá trị', 'Xuat_GiaTri'),
						],
					},
					{
						title: 'Tồn',
						columns: [
							this.makeNumCol('Số lượng', 'Ton_SoLuong'),
							this.makeMoneyCol('Giá trị', 'Ton_GiaTri'),
						],
					},
					{
						title: 'Chênh lệch',
						field: 'ChenhLech',
						hozAlign: 'center',
						width: 120,
						formatter: function (cell) {
							const item = cell.getRow().getData()
							const status = self.getTonStatus(item.Ton_KiemKe, item.Ton_SoLuong)
							return '<div class="chip chip-' + status.color + '"><span>' + status.text + '</span></div>'
						},
						headerFilter: 'list',
						headerFilterParams: {
							values: this.DSTinhTrangChenhLech.reduce(function (acc, item) {
								acc[item.value] = item.title
								return acc
							}, {}),
							clearable: true,
						},
						headerFilterFunc: function (headerValue, _, rowData) {
							if (!headerValue || headerValue === 'TAT_CA') return true
							return self.getTonStatus(rowData.Ton_KiemKe, rowData.Ton_SoLuong).status === headerValue
						},
					},
					{
						title: 'Trạng thái',
						field: 'TinhTrang',
						hozAlign: 'center',
						width: 120,
						formatter: function (cell) {
							const item = cell.getRow().getData()
							if (item.TinhTrang === 'CHUA_RO') return ''
							const config = self.mapTinhTrang[item.TinhTrang] || {}
							return '<div class="chip chip-' + (config.color || 'default') + '"><span>' + (config.text || '') + '</span></div>'
						},
						headerFilter: 'list',
						headerFilterParams: {
							values: this.DSTinhTrang.reduce(function (acc, item) {
								acc[item.value] = item.title
								return acc
							}, {}),
							clearable: true,
						},
						headerFilterFunc: function (headerValue, rowValue) {
							if (!headerValue || headerValue === 'TAT_CA') return true
							return rowValue === headerValue
						},
					},
				]
			},
		},
	}
</script>