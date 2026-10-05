<template>
	<div class="pa-3">
		<div class="filter-bar mb-3">
			<v-row dense align="center">
				<v-col cols="12" md="2">
					<v-select v-model="Nam" density="compact" :items="DSNam" item-value="value" item-title="title"
						label="Năm" hide-details variant="outlined" />
				</v-col>
				<v-col cols="12" md="2">
					<v-select v-model="Thang" density="compact" :items="DSThang" item-value="value" item-title="title"
						label="Tháng" hide-details variant="outlined" />
				</v-col>
				<v-col cols="12" md="3">
					<v-autocomplete v-model="DiaDiem_Id" density="compact" :items="DSDiaDiemTatCa"
						item-value="DiaDiem_Id" item-title="TenDiaDiem" label="Địa điểm" hide-details
						variant="outlined" />
				</v-col>
				<v-col cols="auto">
					<v-btn prepend-icon="mdi-magnify" variant="flat" color="primary" @click="onSearch">Tìm</v-btn>
				</v-col>
				<v-col cols="auto" v-if="hasActiveFilter">
					<v-btn prepend-icon="mdi-filter-off-outline" variant="text" color="grey-darken-1" size="small"
						@click="clearFilter">Xoá lọc</v-btn>
				</v-col>
				<v-col cols="auto">
					<v-chip size="small" color="primary" variant="tonal" class="result-count-chip">
						{{ tableData.length }} kết quả
					</v-chip>
				</v-col>
			</v-row>
		</div>
		<v-row dense>
			<v-col cols="12" sm="6" md="3">
				<uc-stat-card bgclass="white" colortitle="grey-darken-3" :value="StatsInfo.TongSoPhieu"
					title="Tổng phiếu" icon="mdi-file-document-multiple-outline" coloricon="blue-darken-2"
					bgicon="blue-lighten-5" class="stat-card-hover" />
			</v-col>
			<v-col cols="12" sm="6" md="3">
				<uc-stat-card bgclass="white" colortitle="grey-darken-3" :value="tongTienThang" title="Tổng tiền tháng"
					icon="mdi-cash-multiple" coloricon="teal-darken-2" bgicon="teal-lighten-5"
					class="stat-card-hover" />
			</v-col>
			<v-col cols="12" sm="6" md="3">
				<uc-stat-card @click="onViewDetailDanhSach('CO_HOA_DON')" bgclass="white" colortitle="grey-darken-3"
					:value="StatsInfo.CoHoaDon" title="Có hoá đơn" icon="mdi-receipt-text-check"
					coloricon="green-darken-2" bgicon="green-lighten-5" class="stat-card-hover" />
			</v-col>
			<v-col cols="12" sm="6" md="3">
				<uc-stat-card @click="onViewDetailDanhSach('KHONG_CO_HOA_DON')" bgclass="white"
					colortitle="grey-darken-3" :value="StatsInfo.KhongCoHoaDon" title="Không có hoá đơn"
					icon="mdi-alert-circle-outline" coloricon="deep-orange-darken-2" bgicon="deep-orange-lighten-5"
					class="stat-card-hover" />
			</v-col>
		</v-row>
	</div>

	<z-table v-if="isInitTable" ref="refTable" :headers="tableHeader" :items="tableData" height="calc(100vh - 232px)"
		:options="tableConfig" />

</template>

<script>
	export default {
	props: {
		StatsInfo: Object,
		DSPhieuNhap: Array,
		DSDiaDiem: Array,
	},
	emits: ['edit-emit', 'view-detail-emit', 'load-data', 'view-detail-danh-sach', 'on-finish-phieu-dat-hang'],
	data() {
		return {
			isInitTable: false,
			isLoading: false,
			tableHeader: [],
			tableData: [],
			tableConfig: {
				pagination: true,
				rowDblClick: (e, row) => {
					this.onViewDetail(row.getData())
				},
			},

			mapTinhTrangPhieu,
			mapTinhTrangHoaDon: {
				'NHAN_KEM_HOA_DON': {
					text: 'Nhận kèm hoá đơn',
					color: 'success'
				},
				'KHONG_KEM_HOA_DON': {
					text: 'Không kèm hoá đơn',
					color: 'warning'
				},
				'KHONG_CO_HOA_DON': {
					text: 'Không có hoá đơn',
					color: 'grey'
				},
			},
			mapLoaiPhieu: {
				'PHIEU_NHAP': {
					text: 'Nhập',
					color: 'blue'
				},
				'PHIEU_DAT_HANG': {
					text: 'Đặt hàng',
					color: 'warning'
				},
				'LUAN_CHUYEN': {
					text: 'Luân chuyển',
					color: 'purple'
				},
			},
			DiaDiem_Id: 0,
			Nam: null,
			Thang: null,
			DSNam: [],
			DSThang: [],
		}
	},
	mounted() {
		const currentYear = new Date().getFullYear();
		const years = [];
		const count = 10;
		for (let i = 0; i < count; i++) {
			years.push({ title: currentYear - i, value: currentYear - i });
		}
		this.DSThang = this.getMonthsByYear(currentYear)
		this.DSNam = years
		this.Nam = currentYear
		this.Thang = new Date().getMonth() + 1
	},
	computed: {
		DSDiaDiemTatCa() {
			return [{ TenDiaDiem: 'Tất cả', DiaDiem_Id: 0 }, ...this.DSDiaDiem]
		},
		tongTienThang() {
			if (!this.tableData || this.tableData.length === 0) return '0'
			const total = this.tableData.reduce((sum, item) => sum + (Number(item.TongTien) || 0), 0)
			return total.toLocaleString('vi-VN')
		},
		hasActiveFilter() {
			return this.DiaDiem_Id !== 0
		}

	},
	watch: {
		Nam(newYear, oldYear) {
			if (newYear === oldYear) return
			this.DSThang = this.getMonthsByYear(newYear)

			if (!this.DSThang.some(m => m.value === this.Thang)) {
				this.Thang = null
			}
		},

		DSPhieuNhap(val) {
			this.initData(val)
		}
	},
	methods: {
		initData(data) {
			this.tableData = data ?? []
			if (this.$refs.refTable) {
				this.$refs.refTable.table.setData(this.tableData)
			}
			this.initHeader()
			this.isInitTable = true
		},
		clearFilter() {
			this.DiaDiem_Id = 0
			this.emitLoadData()
		},
		initHeader() {
			const $this = this

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

			$this.tableHeader = [
				{ title: '#', formatter: "rownum", hozAlign: "center", width: 60 },
				{
					title: 'Nhà cung cấp', field: 'TenNhaCungCap', width: 250, headerFilter: "input",
					cellClick: (e, cell) => {
						const item = cell.getRow().getData()
						this.onViewDetail(item)
					},
					formatter: (cell) => {
						return `<div class="font-weight-bold text-primary cursor-pointer back-link-hover">${cell.getValue() ?? ""}</div>`
					},
				},
				{ title: 'Địa điểm xuất', field: 'DiaDiemXuat', width: 150, headerFilter: "input", },
				{
					title: 'Loại phiếu', field: 'LoaiPhieu', width: 130, headerFilter: "input",
					headerFilterFunc: (headerValue, rowValue, rowData) => {
						const text = this.mapLoaiPhieu[rowValue]?.text || ""
						return text.toLowerCase().includes(headerValue.toLowerCase())
					},
					formatter: (cell) => {
						const item = cell.getRow().getData()

						const text = this.mapLoaiPhieu[item.LoaiPhieu]?.text
						const color = this.mapLoaiPhieu[item.LoaiPhieu]?.color

						return `
						<div class="chip chip-${color}">
						<span>${text}</span>
						</div>
						`
					}
				},
				{ title: 'Số hoá đơn', field: 'SoHoaDon', width: 130, headerFilter: "input", },
				{
					title: 'Tổng tiền', field: 'TongTien', width: 120, formatter: "money", hozAlign: 'right',
					formatterParams: {
						decimal: ",",
						thousand: ".",
						symbol: "",
						symbolAfter: false,
						precision: 0
					},
					headerFilter: numberCompareFilterEditor,
					headerFilterFunc: numberCompareFilterFunction,
					headerFilterLiveFilter: false,
				},
				{ title: 'Tên địa điểm', field: 'TenDiaDiem', width: 150, headerFilter: "input", },
				{
					title: 'Trạng thái', field: 'TinhTrang', width: 170, headerFilter: "input",
					headerFilterFunc: (headerValue, rowValue, rowData) => {
						const text = this.mapTinhTrangPhieu[rowValue]?.text || ""
						return text.toLowerCase().includes(headerValue.toLowerCase())
					},
					formatter: (cell) => {
						const item = cell.getRow().getData()

						const text = this.mapTinhTrangPhieu[item.TinhTrang]?.text
						const color = this.mapTinhTrangPhieu[item.TinhTrang]?.color

						return `<div class="chip chip-${color}"><span>${text}</span></div>`
					}
				},
				{
					title: 'Hoá đơn', field: 'TinhTrangHoaDon', width: 150, headerFilter: "input",
					headerFilterFunc: (headerValue, rowValue) => {
						const text = this.mapTinhTrangHoaDon[rowValue]?.text || "Chưa rõ"
						return text.toLowerCase().includes(headerValue.toLowerCase())
					},
					formatter: (cell) => {
						const item = cell.getRow().getData()

						const text = this.mapTinhTrangHoaDon[item.TinhTrangHoaDon]?.text ?? "Chưa rõ"
						const color = this.mapTinhTrangHoaDon[item.TinhTrangHoaDon]?.color ?? "grey"

						return `<div class="chip chip-${color}"><span>${text}</span></div>`
					}
				},
				{
					title: 'Ngày nhập', field: 'NgayNhap', width: 150, hozAlign: 'center', headerFilter: "input",
					headerFilterFunc: (headerValue, rowValue, rowData) => {
						const text = this.formatDate(rowValue) || ""
						return text.toLowerCase().includes(headerValue.toLowerCase())
					},
					formatter: (cell) => {
						const item = cell.getRow().getData()

						const isToday = this.isToday(item.NgayNhap)
						const text = this.formatDate(item.NgayNhap) ?? 'Chưa rõ'

						const chipClass = isToday ? 'chip-today' : 'chip-normal'

						return `<div class="chip ${chipClass}"><span>${text}</span></div>`
					},
				},
				{ title: 'Người mua', field: 'NguoiMua', width: 150, headerFilter: "input", },
				{
					title: "",
					width: 60,
					hozAlign: "center",
					headerSort: false,
					formatter: (cell) => {
						const item = cell.getRow().getData()

						let html = ''

						// Cập nhật phiếu
						if (item.TinhTrang === 'CHO_HOA_DON') {
							html += `
							<i class="icon-table mdi mdi-square-edit-outline" data-action="edit" title="Cập nhật phiếu"></i>
							`
						}

						// Tạo phiếu nhập hoặc In phiếu
						if (item.LoaiPhieu === 'PHIEU_DAT_HANG' && item.TinhTrang === 'DAT_HANG') {
							html += `
							<i class="icon-table mdi mdi-truck-check" data-action="finish" title="Tạo phiếu nhập"></i>
							`
						} else {
							html += `
							<i class="icon-table mdi mdi-printer-outline" data-action="print" title="In phiếu"></i>
							`
						}

						return `<div class="action-group">${html}</div>`
					},
					cellClick: (e, cell) => {
						const item = cell.getRow().getData()
						const action = e.target.getAttribute('data-action')

						if (action === 'edit') {
							this.onEdit(item)
						}

						if (action === 'finish') {
							this.onFinish(item)
						}

						if (action === 'print') {
							this.onPrint(item)
						}
					}
				},
			]
		},

		formatDate: window.formatDate,
		isToday(d) { return d?.startsWith(new Date().toISOString().substr(0, 10)) },

		getMonthsByYear(selectedYear) {
			const now = new Date();
			const currentYear = now.getFullYear();
			const currentMonth = now.getMonth() + 1;

			const maxMonth = selectedYear === currentYear ? currentMonth : 12;

			return Array.from({ length: maxMonth }, (_, i) => ({
				title: `Tháng ${i + 1}`,
				value: i + 1
			})).reverse()
		},

		onSearch() {
			this.emitLoadData()
		},

		emitLoadData() {
			this.$emit('load-data', {
				DiaDiem_Id: this.DiaDiem_Id,
				Nam: this.Nam,
				Thang: this.Thang,
			})
		},

		onDeletePhieuNhap(item) {
			showConfirm(
				"Xoá phiếu nhập này sẽ ảnh hưởng trực tiếp tới <strong>tồn kho</strong> và <strong> tài sản thực tế</strong> </br>Bạn có thực sự muốn tiếp tục?",
				() => {
					const params = {
						PhieuNhap_Id: item.PhieuNhap_Id
					}
					apiCall("work/HH_PhieuNhap_Delete", params, (res) => {
						if (res) showToast.success("Thành công");
						this.emitLoadData()
					})
				}
			)
		},

		onViewDetail(item) {
			this.$emit('view-detail-emit', item)
		},

		onEdit(item) {
			this.$emit('edit-emit', item)
		},
		onViewDetailDanhSach(TinhTrang) {
			this.$emit('view-detail-danh-sach', TinhTrang)
		},
		onFinish(item) {
			this.$emit('on-finish-phieu-dat-hang', item)
		},

		generateQRPhieuNhap(phieuNhapId) {
			const temp = document.createElement("div")

			$(temp).qrcode({
				text: String(phieuNhapId),
				render: "canvas",
				width: 256,
				height: 256,
				correctLevel: 3
			})

			const canvas = temp.querySelector("canvas")
			return canvas.toDataURL("image/png")
		},

		async convertImageUrlToBase64(url) {
			const response = await fetch(url)
			const blob = await response.blob()
			return await new Promise((resolve, reject) => {
				const reader = new FileReader()
				reader.onloadend = () => resolve(reader.result)
				reader.onerror = reject
				reader.readAsDataURL(blob)
			})
				.then((base64) => {
					return base64
				})
				.catch((err) => {
					console.log(err)
				})
		},

		async onPrint(item) {
			const data = await apiCallPromise('work/HH_PhieuNhap_Select_ById', {
				PhieuNhap_Id: item.PhieuNhap_Id
			})
			const qrBase64 = this.generateQRPhieuNhap(item.PhieuNhap_Id)

			const arrayHangHoa = [...data[0], ...data[1]]
			const dataItem = { ...item, arrayHangHoa: arrayHangHoa }
			const pictureUrl = `/_cdn/danh-muc/logo-2025.png`
			const logoBase64 = await this.convertImageUrlToBase64(pictureUrl)
			const docDefinition = {
				pageMargins: [30, 15, 30, 30],

				content: [
					{
						columns: [
							{
								width: 'auto',
								image: logoBase64,
								fit: [60, 60]
							},

							{
								width: '*',
								stack: [
									{
										text: 'CÔNG TY TNHH MỘT THÀNH VIÊN SẢN XUẤT THƯƠNG MẠI DỊCH VỤ TÔ MINH',
										style: 'companyName'
									},
									{
										text: 'Địa chỉ: Tầng 1, số 328, đường 30/4, Khu Phố Vườn Mít, Phường Trấn Biên, Tỉnh Đồng Nai, Việt Nam',
										style: 'companyInfo'
									},
									{
										text: 'SĐT: 032984786',
										style: 'companyInfo'
									}
								]
							}
						],
						columnGap: 10,
						margin: [0, 0, 0, 10]
					},

					{
						text: 'PHIẾU NHẬP HÀNG',
						style: 'header',
						alignment: 'center',
						margin: [0, 0, 0, 10]
					},

					{
						columns: [
							{
								width: '*',
								stack: [
									{ text: `Nhà cung cấp: ${dataItem.TenNhaCungCap}`, style: 'info' },
									{ text: `Số HĐ: ${dataItem.SoHoaDon}`, style: 'info' },
									{ text: `Địa điểm: ${dataItem.TenDiaDiem}`, style: 'info' },
									{ text: `Ngày nhập: ${this.formatDate(dataItem.NgayNhap)}`, style: 'info' }
								]
							},
							{
								width: 'auto',
								image: qrBase64,
								fit: [80, 80],
								alignment: 'right'
							}
						],
						columnGap: 15,
						margin: [0, 0, 0, 15]
					},

					{
						table: {
							headerRows: 1,
							widths: ['*', 80],
							body: [
								[
									{ text: 'Tên hàng', style: 'tableHeader' },
									{ text: 'Số lượng', style: 'tableHeader', alignment: 'right' }
								],
								...dataItem.arrayHangHoa.map(item => [
									{ text: item.TenHangHoa, style: 'tableCell' },
									{ text: item.SoLuongNhap, style: 'tableCell', alignment: 'right' }
								])
							]
						},
						layout: {
							fillColor: (rowIndex) => rowIndex === 0 ? '#eeeeee' : null,
							hLineWidth: () => 0.5,
							vLineWidth: () => 0.5,
							hLineColor: () => '#cccccc',
							vLineColor: () => '#cccccc',
							paddingLeft: () => 8,
							paddingRight: () => 8,
							paddingTop: () => 6,
							paddingBottom: () => 6
						}
					}
				],

				styles: {
					header: {
						fontSize: 18,
						bold: true
					},
					companyName: {
						fontSize: 12,
						bold: true
					},
					companyInfo: {
						fontSize: 10
					},
					info: {
						fontSize: 11,
						margin: [0, 2]
					},
					tableHeader: {
						bold: true,
						fontSize: 12
					},
					tableCell: {
						fontSize: 11
					}
				}
			};
			pdfMake.createPdf(docDefinition).open();
		}
	},
}
</script>