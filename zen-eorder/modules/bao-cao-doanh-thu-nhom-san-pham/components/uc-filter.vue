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
		<v-col cols="2">
			<v-select label="Báo cáo" outlined dense v-model="isReportDoanhThu"
				:items="[{ value: 0, text: 'Doanh Thu' }, { value: 1, text: 'Số Lượng' }]" hide-details />
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
				isReportDoanhThu: 0,
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
						text: 'Nhóm sản phẩm',
						value: 'NhomSanPhamBaoCao',
						width: '250px'
					},
					{
						text: 'Thương hiệu',
						value: 'ThuongHieu',
						width: '200px'
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
		watch: {
			'isReportDoanhThu': {
				handler() {
					this.getReport()
				},
				deep: true,
			}
		},
		methods: {
			getReport() {
				const params = {
					CuaHangID: this.CuaHangID,
					PhanHieuID: this.PhanHieuID,
					KhuVucID: this.KhuVucID,
					HinhThucThanhToan: this.HinhThucThanhToan,
					HinhThucThoiGian: this.HinhThucThoiGian,
					IsSoLuong: this.isReportDoanhThu,
					Ngay: this.Ngay,
					TuNgay: this.TuNgay,
					DenNgay: this.DenNgay,
					Nam: this.Nam,
					TuNam: this.TuNam,
					DenNam: this.DenNam,
					Thang: this.Thang
				}
	
				ajaxCALL('/eorder/BaoCao_DoanhThu_NhomSanPham', params, (res) => {
					this.sanitizeResponse(res.data)
				})
			},
			sanitizeResponse([dynamicVariables, dataRaw]) {
				if (!dynamicVariables?.length || !dataRaw?.length) {
					vueData.TableHeader = []
					vueData.DataReport = []
					return
				}
	
				const [aliasKey] = Object.keys(dynamicVariables[0])
				const isDaily = aliasKey === 'Ngay'
	
				// 1. Header động
				const headerTemp = this.generateHeader(dynamicVariables, aliasKey, isDaily)
	
				// 2. Gom dữ liệu vào Map (group by NhomSanPham_BaoCaoID + ThuongHieu + aliasKey)
				const aggMap = new Map()
				dataRaw.forEach(item => {
					const sub = this.formatString(item.ThuongHieu)
					const key = `nsp${item.NhomSanPham_BaoCaoID}_${sub}_${item[aliasKey]}`
					if (!aggMap.has(key)) {
						aggMap.set(key, { ...item, GiaTriBaoCao: Number(item.GiaTriBaoCao) || 0 })
					} else {
						aggMap.get(key).GiaTriBaoCao += Number(item.GiaTriBaoCao) || 0
					}
				})
	
				// 3. Build danh sách brand unique (row gốc)
				const uniqueBrands = []
				const seen = new Set()
				dataRaw.forEach(item => {
					const key = `${item.NhomSanPham_BaoCaoID}_${item.ThuongHieu}`
					if (!seen.has(key)) {
						seen.add(key)
						uniqueBrands.push({
							NhomSanPham_BaoCaoID: item.NhomSanPham_BaoCaoID,
							NhomSanPhamBaoCao: item.NhomSanPhamBaoCao,
							ThuongHieu: item.ThuongHieu
						})
					}
				})
	
				// 4. Sinh bảng dữ liệu
				const dataTable = uniqueBrands.map(brand => {
					const row = { ...brand, sumRevenueCol: 0 }
	
					headerTemp.forEach(head => {
						const sub = this.formatString(brand.ThuongHieu)
						const key = `nsp${brand.NhomSanPham_BaoCaoID}_${sub}_${head[aliasKey]}`
						const data = aggMap.get(key)
						const price = data ? data.GiaTriBaoCao : 0
	
						row[head.value] = price.toLocaleString("vi-vn") //formatPrice(price)
						row[head.value + '_value'] = price
						row.sumRevenueCol += price
					})
	
					row.sumRevenueFormatted = row.sumRevenueCol.toLocaleString("vi-vn") //formatPrice(row.sumRevenueCol)
					return row
				})
	
				// 5. Dòng tổng
				const totalRow = { NhomSanPhamBaoCao: 'Tổng', sumRevenueCol: 0 }
				totalRow.sumRevenueCol = dataTable.reduce((s, r) => s + r.sumRevenueCol, 0)
				totalRow.sumRevenueFormatted = totalRow.sumRevenueCol.toLocaleString("vi-vn") //formatPrice(totalRow.sumRevenueCol)
	
				headerTemp.forEach(head => {
					const total = dataTable.reduce((s, r) => s + (r[head.value + '_value'] || 0), 0)
					totalRow[head.value + '_value'] = total
					totalRow[head.value] = total.toLocaleString("vi-vn")// formatPrice(total)R
				})
				dataTable.push(totalRow)
	
				// 6. Kết quả
				vueData.TableHeader = [...this.headerDefault, ...headerTemp]
				vueData.DataReport = dataTable
			},
	
			buildUniqueBrands(dataRaw) {
				const seen = new Map()
				dataRaw.forEach(item => {
					const key = `${item.NhomSanPham_BaoCaoID}_${item.ThuongHieu}`
					if (!seen.has(key)) {
						seen.set(key, {
							NhomSanPham_BaoCaoID: item.NhomSanPham_BaoCaoID,
							NhomSanPhamBaoCao: item.NhomSanPhamBaoCao,
							ThuongHieu: item.ThuongHieu
						})
					}
				})
				return Array.from(seen.values())
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
			formatString(str) {
				if (!str) return
	
				return str
					.normalize("NFD")                     // Tách dấu khỏi ký tự gốc
					.replace(/[\u0300-\u036f]/g, "")      // Xoá dấu
					.replace(/[^a-zA-Z0-9 ]/g, "")        // Bỏ ký tự đặc biệt, giữ chữ/số/khoảng trắng
					.trim()                               // Bỏ khoảng trắng đầu/cuối
					.replace(/\s+/g, "_");                // Thay khoảng trắng bằng _
			}
	
		}
	}
</script>