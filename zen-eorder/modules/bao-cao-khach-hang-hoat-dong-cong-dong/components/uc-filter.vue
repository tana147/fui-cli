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
			<v-select label="Loại thời gian" outlined dense v-model="HinhThucThoiGian" :items="DSHinhThucThoiGian"
				hide-details />
		</v-col>
		<!-- 1: Theo giờ -->
		<v-col cols="2" v-if="HinhThucThoiGian === 1">
			<f-date label="Ngày" outlined dense v-model="Ngay" :date-add="0" hide-details />
		</v-col>
		<!-- 2: Theo ngày -->
		<v-col cols="2" v-if="HinhThucThoiGian === 2">
			<f-date label="Từ ngày" outlined dense v-model="TuNgay" :date-add="0" hide-details />
		</v-col>
		<v-col cols="2" v-if="HinhThucThoiGian === 2">
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
				],
				DSHinhThucThoiGian: [
					{ value: 1, text: "Theo giờ" },
					{ value: 2, text: "Theo ngày" },
					{ value: 3, text: "Theo tuần" },
					{ value: 4, text: "Theo quý" },
					{ value: 5, text: "Theo tháng" },
					{ value: 6, text: "Theo năm" },
				],
			}
		},
		methods: {
			getReport: function () {
				const $this = this
				const params = {
					PhanHieuID: $this.PhanHieuID,
					KhuVucID: $this.KhuVucID,
					HinhThucThanhToan: $this.HinhThucThanhToan,
					HinhThucThoiGian: $this.HinhThucThoiGian,
					Ngay: $this.Ngay,
					TuNgay: $this.TuNgay,
					DenNgay: $this.DenNgay,
					Nam: $this.Nam,
					TuNam: $this.TuNam,
					DenNam: $this.DenNam,
					Thang: $this.Thang,
				}
				ajaxCALL("/eorder/BaoCao_KhachHang_HoatDongCongDong", params, (res) => {
					const resCuaHang = res.data[0] ?? []
					const resHeader = res.data[1] ?? []
					const resData = res.data[2] ?? []
					const dataHead = [
						{ text: "Khu vực", value: "TenKhuVuc" },
						{ text: "Cửa hàng", value: "TenCuaHang"},
					]
					const dataTable = []
					//1: Theo giờ
					if (params.HinhThucThoiGian === 1) {
						//Xử lý cột động cho table header
						resHeader.forEach((head) => {
							dataHead.push({ text: `${head.Gio}H`, value: `Gio_${head.Gio}`,  align: 'end' })
						})
						dataHead.push({ text: `Tổng`, value: `Total_Gio`,  align: 'end' })
						//Lặp từng cửa hàng
						resCuaHang.forEach((store) => {
							const dataRow = {
								CuaHangID: store.CuaHangID,
								TenKhuVuc: store.TenKhuVuc,
								TenCuaHang: store.TenCuaHang,
							}
							dataRow[`Total_Gio`] = 0
							//Lặp header
							resHeader.forEach((head) => {
								//Lấy ra row tương ứng theo giờ & cửa hàng
								const rowItem = resData.filter((row) => row.CuaHangID === store.CuaHangID && row.SoGio === head.Gio)
								//Nếu có thì lấy ra số lần truy cập tương ứng theo giờ
								if (rowItem.length > 0) {
									const numberOfAccess = rowItem[0].SoLanTruyCap
									dataRow[`Gio_${head.Gio}`] = numberOfAccess
									dataRow[`Total_Gio`] += rowItem[0].SoLanTruyCap
								} else {
									//Nếu không thì set số lần truy cập = 0
									dataRow[`Gio_${head.Gio}`] = null
								}
							})
	
							//Đẩy dữ liệu vào dataTable
							dataTable.push(dataRow)
						})
						//Push dòng tổng
						let objectTotal = {
							TenKhuVuc: 'Tổng',
							TenCuaHang: 'Tổng'
						}
						for (let j = 0; j < resHeader.length; j++) {
							objectTotal[`Gio_${j}`] = 0
							objectTotal[`Total_Gio`] = 0
							for (let i = 0; i < dataTable.length; i++) {
								objectTotal[`Gio_${j}`] += dataTable[i][`Gio_${j}`]
								objectTotal[`Total_Gio`] += dataTable[i][`Total_Gio`]
							}
						}
						if (objectTotal[`Total_Gio`] == 0) {
							objectTotal[`Total_Gio`] = null
						}
						dataTable.push(objectTotal)
					}
					//2: Theo ngày
					if (params.HinhThucThoiGian === 2) {
						//Xử lý cột động cho table header
						resHeader.forEach((head) => {
							dataHead.push({ text: moment(head.Ngay).format("DD/MM"), value: `Ngay_${head.Ngay}`,  align: 'end' })
						})
						dataHead.push({ text: `Tổng`, value: `NgayTruyCap_Total`,  align: 'end' })
						//Lặp từng cửa hàng
						resCuaHang.forEach((store) => {
							const dataRow = {
								CuaHangID: store.CuaHangID,
								TenKhuVuc: store.TenKhuVuc,
								TenCuaHang: store.TenCuaHang,
							}
							dataRow[`NgayTruyCap_Total`] = 0
							//Lặp header
							resHeader.forEach((head) => {
								//Lấy ra row tương ứng theo ngày & cửa hàng
								const rowItem = resData.filter((row) => row.CuaHangID === store.CuaHangID && row.NgayTruyCap === head.Ngay)
								//Nếu có thì lấy ra số lần truy cập tương ứng theo giờ
								if (rowItem.length > 0) {
									const numberOfAccess = rowItem[0].SoLanTruyCap
									dataRow[`Ngay_${head.Ngay}`] = numberOfAccess
									dataRow[`NgayTruyCap_Total`] += rowItem[0].SoLanTruyCap
								} else {
									//Nếu không thì set số lần truy cập = 0
									dataRow[`Ngay_${head.Ngay}`] = null
								}
							})
							//Đẩy dữ liệu vào dataTable
							dataTable.push(dataRow)
						})
						//Push dòng tổng
						let objectTotal = {
							TenKhuVuc: 'Tổng',
							TenCuaHang: 'Tổng'
						}
						for (let j = 0; j < resHeader.length; j++) {
							objectTotal[`Ngay_${resHeader[j].Ngay}`] = 0
							objectTotal[`NgayTruyCap_Total`] = 0
							for (let i = 0; i < dataTable.length; i++) {
								objectTotal[`Ngay_${resHeader[j].Ngay}`] += dataTable[i][`Ngay_${resHeader[j].Ngay}`]
								objectTotal[`NgayTruyCap_Total`] += dataTable[i][`NgayTruyCap_Total`]
							}
						}
						dataTable.push(objectTotal)
					}
					//3: Theo tuần
					if (params.HinhThucThoiGian === 3) {
						//Xử lý cột động cho table header
						resHeader.forEach((head) => {
							dataHead.push({ text: `Tuần ${head.SoTuan}`, value: `Tuan_${head.SoTuan}`,  align: 'end' })
						})
						dataHead.push({ text: `Tổng`, value: `Tuan_Total`,  align: 'end' })
						//Lặp từng cửa hàng
						resCuaHang.forEach((store) => {
							const dataRow = {
								CuaHangID: store.CuaHangID,
								TenKhuVuc: store.TenKhuVuc,
								TenCuaHang: store.TenCuaHang,
							}
							dataRow[`Tuan_Total`] = 0
							//Lặp header
							resHeader.forEach((head) => {
								//Lấy ra row tương ứng theo ngày & cửa hàng
								const rowItem = resData.filter((row) => row.CuaHangID === store.CuaHangID && row.Tuan === head.SoTuan)
								//Nếu có thì lấy ra số lần truy cập tương ứng theo giờ
								if (rowItem.length > 0) {
									const numberOfAccess = rowItem[0].SoLanTruyCap
									dataRow[`Tuan_${head.SoTuan}`] = numberOfAccess
									dataRow[`Tuan_Total`] += rowItem[0].SoLanTruyCap
								} else {
									//Nếu không thì set số lần truy cập = 0
									dataRow[`Tuan_${head.SoTuan}`] = null
								}
							})
							//Đẩy dữ liệu vào dataTable
							dataTable.push(dataRow)
						})
						//Push dòng tổng
						let objectTotal = {
							TenKhuVuc: 'Tổng',
							TenCuaHang: 'Tổng'
						}
						for (let j = 0; j < resHeader.length; j++) {
							objectTotal[`Tuan_${resHeader[j].SoTuan}`] = 0
							objectTotal[`Tuan_Total`] = 0
							for (let i = 0; i < dataTable.length; i++) {
								objectTotal[`Tuan_${resHeader[j].SoTuan}`] += dataTable[i][`Tuan_${resHeader[j].SoTuan}`]
								objectTotal[`Tuan_Total`] += dataTable[i][`Tuan_Total`]
							}
						}
						dataTable.push(objectTotal)
					}
					//4: Theo quý
					if (params.HinhThucThoiGian === 4) {
						//Xử lý cột động cho table header
						resHeader.forEach((head) => {
							dataHead.push({ text: `Quý ${head.QuyTrongNam}`, value: `Quy_${head.QuyTrongNam}`,  align: 'end' })
						})
						dataHead.push({ text: `Tổng`, value: `Quy_Total`,  align: 'end' })
						//Lặp từng cửa hàng
						resCuaHang.forEach((store) => {
							const dataRow = {
								CuaHangID: store.CuaHangID,
								TenKhuVuc: store.TenKhuVuc,
								TenCuaHang: store.TenCuaHang,
							}
							dataRow[`Quy_Total`] = 0
							//Lặp header
							resHeader.forEach((head) => {
								//Lấy ra row tương ứng theo ngày & cửa hàng
								const rowItem = resData.filter((row) => row.CuaHangID === store.CuaHangID && row.Quy === head.QuyTrongNam)
								//Nếu có thì lấy ra số lần truy cập tương ứng theo giờ
								if (rowItem.length > 0) {
									const numberOfAccess = rowItem[0].SoLanTruyCap
									dataRow[`Quy_${head.QuyTrongNam}`] = numberOfAccess
									dataRow[`Quy_Total`] += rowItem[0].SoLanTruyCap
								} else {
									//Nếu không thì set số lần truy cập = 0
									dataRow[`Quy_${head.QuyTrongNam}`] = null
								}
							})
							//Đẩy dữ liệu vào dataTable
							dataTable.push(dataRow)
						})
						//Push dòng tổng
						let objectTotal = {
							TenKhuVuc: 'Tổng',
							TenCuaHang: 'Tổng'
						}
						for (let j = 0; j < resHeader.length; j++) {
							objectTotal[`Quy_${resHeader[j].QuyTrongNam}`] = 0
							objectTotal[`Quy_Total`] = 0
							for (let i = 0; i < dataTable.length; i++) {
								objectTotal[`Quy_${resHeader[j].QuyTrongNam}`] += dataTable[i][`Quy_${resHeader[j].QuyTrongNam}`]
								objectTotal[`Quy_Total`] += dataTable[i][`Quy_Total`]
							}
						}
						dataTable.push(objectTotal)
					}
					//5: Theo tháng
					if (params.HinhThucThoiGian === 5) {
						//Xử lý cột động cho table header
						resHeader.forEach((head) => {
							dataHead.push({ text: `Tháng ${head.ThangTrongNam}`, value: `Thang_${head.ThangTrongNam}`,  align: 'end' })
						})
						dataHead.push({ text: `Tổng`, value: `Thang_Total`,  align: 'end' })
						//Lặp từng cửa hàng
						resCuaHang.forEach((store) => {
							const dataRow = {
								CuaHangID: store.CuaHangID,
								TenKhuVuc: store.TenKhuVuc,
								TenCuaHang: store.TenCuaHang,
							}
							dataRow[`Thang_Total`] = 0
							//Lặp header
							resHeader.forEach((head) => {
								//Lấy ra row tương ứng theo ngày & cửa hàng
								const rowItem = resData.filter((row) => row.CuaHangID === store.CuaHangID && row.Thang === head.ThangTrongNam)
								//Nếu có thì lấy ra số lần truy cập tương ứng theo giờ
								if (rowItem.length > 0) {
									const numberOfAccess = rowItem[0].SoLanTruyCap
									dataRow[`Thang_${head.ThangTrongNam}`] = numberOfAccess
									dataRow[`Thang_Total`] += rowItem[0].SoLanTruyCap
								} else {
									//Nếu không thì set số lần truy cập = 0
									dataRow[`Thang_${head.ThangTrongNam}`] = null
								}
							})
							//Đẩy dữ liệu vào dataTable
							dataTable.push(dataRow)
						})
						//Push dòng tổng
						let objectTotal = {
							TenKhuVuc: 'Tổng',
							TenCuaHang: 'Tổng'
						}
						for (let j = 0; j < resHeader.length; j++) {
							objectTotal[`Thang_${resHeader[j].ThangTrongNam}`] = 0
							objectTotal[`Thang_Total`] = 0
							for (let i = 0; i < dataTable.length; i++) {
								objectTotal[`Thang_${resHeader[j].ThangTrongNam}`] += dataTable[i][`Thang_${resHeader[j].ThangTrongNam}`]
								objectTotal[`Thang_Total`] += dataTable[i][`Thang_Total`]
							}
						}
						dataTable.push(objectTotal)
					}
					//6: Theo năm
					if (params.HinhThucThoiGian === 6) {
						//Xử lý cột động cho table header
						resHeader.forEach((head) => {
							dataHead.push({ text: `Năm ${head.Nam}`, value: `Nam_${head.Nam}`,  align: 'end' })
						})
						dataHead.push({ text: `Tổng`, value: `Nam_Total`,  align: 'end' })
						//Lặp từng cửa hàng
						resCuaHang.forEach((store) => {
							const dataRow = {
								CuaHangID: store.CuaHangID,
								TenKhuVuc: store.TenKhuVuc,
								TenCuaHang: store.TenCuaHang,
							}
							dataRow[`Nam_Total`] = 0
							//Lặp header
							resHeader.forEach((head) => {
								//Lấy ra row tương ứng theo ngày & cửa hàng
								const rowItem = resData.filter((row) => row.CuaHangID === store.CuaHangID && row.Nam === head.Nam)
								//Nếu có thì lấy ra số lần truy cập tương ứng theo giờ
								if (rowItem.length > 0) {
									const numberOfAccess = rowItem[0].SoLanTruyCap
									dataRow[`Nam_${head.Nam}`] = numberOfAccess
									dataRow[`Nam_Total`] += rowItem[0].SoLanTruyCap
								} else {
									//Nếu không thì set số lần truy cập = 0
									dataRow[`Nam_${head.Nam}`] = null
								}
							})
							//Đẩy dữ liệu vào dataTable
							dataTable.push(dataRow)
						})
						//Push dòng tổng
						let objectTotal = {
							TenKhuVuc: 'Tổng',
							TenCuaHang: 'Tổng'
						}
						for (let j = 0; j < resHeader.length; j++) {
							objectTotal[`Nam_${resHeader[j].Nam}`] = 0
							objectTotal[`Nam_Total`] = 0
							for (let i = 0; i < dataTable.length; i++) {
								objectTotal[`Nam_${resHeader[j].Nam}`] += dataTable[i][`Nam_${resHeader[j].Nam}`]
								objectTotal[`Nam_Total`] += dataTable[i][`Nam_Total`]
							}
						}
						dataTable.push(objectTotal)
					}
					//Đẩy dữ liệu ra bảng
					vueData.TableHeader = dataHead
					vueData.DSBaoCao = dataTable
				})
			},
		},
	}
</script>