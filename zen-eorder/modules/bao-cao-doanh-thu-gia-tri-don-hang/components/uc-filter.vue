<template>
	<v-row>
		<v-col cols="4">
			<v-select label="Phân hiệu" outlined dense v-model="PhanHieuID" :items="vueData.DSPhanHieu"
				item-value="PhanHieuID" item-text="TenPhanHieu" hide-details />
		</v-col>
		<v-col cols="4">
			<v-select label="Khu vực" outlined dense v-model="KhuVucID" :items="vueData.DSKhuVuc" item-value="KhuVucID"
				item-text="TenKhuVuc" hide-details />
		</v-col>
		<v-col cols="4">
			<v-select label="Cửa hàng" outlined dense v-model="CuaHangID" :items="vueData.DSCuaHang"
				item-value="CuaHangID" item-text="TenCuaHang" hide-details />
		</v-col>
		<v-col cols="4">
			<v-select label="Hình thức thanh toán" outlined dense v-model="HinhThucThanhToan" :items="DSHinhThucThanhToan"
				 hide-details />
		</v-col>
		<v-col cols="2">
			<v-text-field label="Bước giá trị" v-model="FormatPrice" outlined dense hide-details />
		</v-col>
		<v-col cols="2">
			<v-select label="Loại thời gian" outlined dense v-model="HinhThucThoiGian" :items="DSHinhThucThoiGian"
				hide-details />
		</v-col>
		<!-- 1: Theo giờ -->
		<!-- <v-col cols="2" v-if="HinhThucThoiGian === 1">
			<f-date label="Ngày" outlined dense v-model="Ngay" :date-add="0" hide-details />
		</v-col> -->
		<!-- 2: Theo ngày -->
		<v-col cols="2" v-if="HinhThucThoiGian === 2 || HinhThucThoiGian === 1">
			<f-date label="Từ ngày" outlined dense v-model="TuNgay" :date-add="0" hide-details />
		</v-col>
		<v-col cols="2" v-if="HinhThucThoiGian === 2 || HinhThucThoiGian === 1">
			<f-date label="Đến ngày" outlined dense v-model="DenNgay" :date-add="0" hide-details />
		</v-col>
		<!-- 3: Theo tuần -->
		<v-col cols="2" v-if="HinhThucThoiGian === 3">
			<v-select label="Năm" outlined dense v-model="Nam" :items="DSNam" hide-details />
		</v-col>
		<v-col cols="2" v-if="HinhThucThoiGian === 3">
			<v-select label="Tháng" outlined dense v-model="Thang" :items="DSThang" hide-details />
		</v-col>
		<!-- 4: Theo quý || 5: Theo tháng -->
		<v-col cols="2" v-if="HinhThucThoiGian === 4 || HinhThucThoiGian === 5">
			<v-select label="Năm" outlined dense v-model="Nam" :items="DSNam" hide-details />
		</v-col>
		<!-- 6: Theo năm -->
		<v-col cols="2" v-if="HinhThucThoiGian === 6">
			<v-select label="Từ năm" outlined dense v-model="TuNam" :items="DSNam" hide-details />
		</v-col>
		<v-col cols="2" v-if="HinhThucThoiGian === 6">
			<v-select label="Đến năm" outlined dense v-model="DenNam" :items="DSNam" hide-details />
		</v-col>
		<v-col cols="2">
			<v-select label="Báo cáo" outlined dense v-model="isReportGiaTriBaoCao"
				:items="[{ value: 0, text: 'Doanh Thu' }, { value: 1, text: 'Số Lượng' }]" hide-details />
		</v-col>
		<v-col cols="2">
			<v-btn color="primary" elevation="0" @click="getReport"><v-icon left>mdi-filter</v-icon>Tìm</v-btn>
		</v-col>
	</v-row>
</template>

<script>
export default {
	props: [],
	data: function () {
		//Lấy danh sách năm
		const yearNow = moment().year()
		let dsYear = []
		for (let y = yearNow; y >= 2024; y--) {
			dsYear.push(y)
		}
		return {
			isReportGiaTriBaoCao: 0,
			GiaTri_BuocNhay: 50_000,
			CuaHangID: 0,
			PhanHieuID: 0,
			KhuVucID: 0,
			HinhThucThanhToan: 0,
			HinhThucThoiGian: 1, //Mặc định theo giờ
			Ngay: moment().format("YYYY-MM-DD"),
			TuNgay: moment().format("YYYY-MM-DD"),
			DenNgay: moment().format("YYYY-MM-DD"),
			Nam: yearNow,
			TuNam: yearNow,
			DenNam: yearNow,
			Thang: moment().month() + 1,
			DSNam: dsYear,
			DSThang: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
				DSHinhThucThanhToan: [
				{ value: 0, text: "Tất cả" },
				{ value: 1, text: "Tiền mặt" },
				{ value: 2, text: "Chuyển khoản" },
				{ value: 4, text: "Quẹt thẻ" },
				{ value: 3, text: "Shopee Food" },
				{ value: 6, text: "Grab" },
				{ value: 5, text: "ZEN" },
				{ value: 7, text: "XSM" },
			],
			DSHinhThucThoiGian: [
				{ value: 1, text: "Theo giờ" },
				{ value: 2, text: "Theo ngày" },
				{ value: 3, text: "Theo tuần" },
				{ value: 4, text: "Theo quý" },
				{ value: 5, text: "Theo tháng" },
				{ value: 6, text: "Theo năm" },
			],
			headerDefault: [
				{
					text: 'Khoảng tiền',
					value: 'KhoangTien',
					width: '250px'
				},
				{
					text: 'Thương hiệu',
					value: 'TenPhanHieu',
					width: '250px'
				},
				{
					text: 'Tổng',
					value: 'sumRevenueFormatted',
					width: '100px',
					align: 'right',
					cellClass: "highlight-total"
				}
			]
		}
	},
	mounted() {
		
	},
	computed: {
		FormatPrice: {
            get: function () {
                return this.formatAsCurrency(parseInt(this.GiaTri_BuocNhay), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                this.GiaTri_BuocNhay = Number(_newVal.replace(/[^0-9\.]/g, ""))
            },
        }
	},
	watch: {
		'isReportGiaTriBaoCao': {
			handler() {
				this.getReport()
			},
			deep: true,
		}
	},
	methods: {
		 formatAsCurrency(value, dec) {
            dec = dec || 0
            if (value === null) {
                return 0
            }
            return "" + value.toFixed(dec).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")
        },
		getReport() {
			const params = {
				CuaHangID: this.CuaHangID,
				PhanHieuID: this.PhanHieuID,
				KhuVucID: this.KhuVucID,
				HinhThucThanhToan: this.HinhThucThanhToan,
				HinhThucThoiGian: this.HinhThucThoiGian,
				Ngay: this.Ngay,
				TuNgay: this.TuNgay,
				DenNgay: this.DenNgay,
				Nam: this.Nam,
				TuNam: this.TuNam,
				DenNam: this.DenNam,
				Thang: this.Thang,
				GiaTri_BuocNhay: this.GiaTri_BuocNhay,
				IsSoLuong: this.isReportGiaTriBaoCao
			}

			ajaxCALL('/eorder/BaoCao_DoanhThu_GiaTriDonHang', params, (res) => {
				this.sanitizeReponse(res.data)
			})
		},

		sanitizeReponse([rowForm, dynamicVar, data]) {
			if (!rowForm || rowForm.length === 0) {
				vueData.TableHeader = []
				vueData.DataReport = []
				return
			}

			// alias hình thức thời gian
			const [aliasKey] = Object.keys(dynamicVar[0])
			const isDaily = aliasKey === 'Ngay'

			 const dataRefactor = data.map(e => ({
                ...e,
                [aliasKey]: e.HinhThucThoiGian
            })) || []

			const headerTemp = this.generateHeader(dynamicVar, aliasKey, isDaily)

			const dataMap =  this.buildDataMap(dataRefactor, aliasKey)
			const dataTable =  this.generateDataTable(rowForm, headerTemp, dataMap, aliasKey)

			const rowTotal = this.generateTotalRow(dataTable, headerTemp)
			dataTable.push(rowTotal)

			vueData.TableHeader = [...this.headerDefault, ...headerTemp]
			vueData.DataReport = [...dataTable]
		},

		buildDataMap(data, aliasKey) {
			const map = new Map()
			data.forEach(item => {
				const key = `phID${item.PhanHieuID}_${item.TuTien}_${item.DenTien}_${aliasKey}${item[aliasKey]}`
				map.set(key, item)
			})
			return map
		},

		generateHeader(variables, key, isDaily) {
			const suffix = this.suffixColumn(key)
			const prefix = this.preflixColumn(key)

			return variables.map(variable => {
				const value = variable[key]
				const columnTitle = isDaily ? this.formatDaily(value) : `${prefix} ${value}${suffix}`
				const columnValue = `${key}_${value}`
				return {
					...variable,
					text: columnTitle,
					value: columnValue,
					align: 'right'
				}
			})
		},

		generateDataTable(rowForm, headers, dataMap, aliasKey) {
			return rowForm.map(row => {
				const tempRow = { ...row, sumRevenueCol: 0 }
				headers.forEach(head => {
					const key = `phID${tempRow.PhanHieuID}_${tempRow.TuTien}_${tempRow.DenTien}_${aliasKey}${head[aliasKey]}`
					
					const data = dataMap.get(key)

					const price = data ? data.GiaTriBaoCao : 0
					tempRow[head.value] = price.toLocaleString("vi-vn") //formatPrice(price) 
					tempRow[head.value + '_value'] = price
					tempRow.sumRevenueCol += price
				})

				tempRow.sumRevenueFormatted = tempRow.sumRevenueCol.toLocaleString("vi-vn") //formatPrice(tempRow.sumRevenueCol)
				return tempRow
			})
		},

		generateTotalRow(dataTable, headers) {
			const totalRow = { KhoangTien: 'Tổng', sumRevenueCol: 0 }

			totalRow.sumRevenueCol = dataTable.reduce((sum, row) => sum + (row.sumRevenueCol || 0), 0)
			totalRow.sumRevenueFormatted = totalRow.sumRevenueCol.toLocaleString("vi-vn") //formatPrice(totalRow.sumRevenueCol)

			headers.forEach(head => {
				const total = dataTable.reduce((sum, row) => sum + (row[head.value + '_value'] || 0), 0)
				totalRow[head.value + '_value'] = total
				totalRow[head.value] = total.toLocaleString("vi-vn")//  formatPrice(total)
			})

			return totalRow
		},

		suffixColumn(col) {
			if (col === 'Gio') return 'H'
			return ''
		},

		preflixColumn(col) {
			switch (col) {
				case 'Tuan': return 'Tuần'
				case 'Thang': return 'Tháng'
				case 'Quy': return 'Quý'
				default: return ''
			}
		},

		formatDaily(str) {
			return moment(str).format("D/M")
		},

		 
	}
}
</script>