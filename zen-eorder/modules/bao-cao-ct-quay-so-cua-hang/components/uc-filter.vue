<template>
	<div>
		<v-row class="mt-1">
			<v-col cols="4">
				<v-select label="Chương trình" outlined dense v-model="ChuongTrinhID" :items="vueData.DSChuongTrinh"
					item-value="ChuongTrinhID" hide-details>
					<template v-slot:item="{ item }">
						<span v-if="item.ChuongTrinhID == 0">Tất cả</span>
						<span v-else>{{ item.MaChuongTrinh }} - {{ item.TenChuongTrinh }}</span>
					</template>

					<template v-slot:selection="{ item }">
						<span v-if="item.ChuongTrinhID == 0">Tất cả</span>
						<span v-else>{{ item.MaChuongTrinh }} - {{ item.TenChuongTrinh }}</span>
					</template>
				</v-select>
			</v-col>
			<v-col cols="4">
				<v-select label="Cửa hàng nhận" outlined dense v-model="CuaHangNhanID" :items="vueData.DSCuaHang"
					item-value="CuaHangID" item-text="TenCuaHang" hide-details />
			</v-col>
			<v-col cols="4">
				<v-select label="Cửa hàng đổi thưởng" outlined dense v-model="CuaHangDoiThuongID"
					:items="vueData.DSCuaHang" item-value="CuaHangID" item-text="TenCuaHang" hide-details />
			</v-col>
			<v-col cols="4">
				<v-text-field label="Voucher" v-model="Voucher" hide-details outlined dense></v-text-field>
			</v-col>
			<v-col cols="2">
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
				<v-btn color="primary" elevation="0" @click="reportGET()"><v-icon left>mdi-filter</v-icon>Tìm</v-btn>
			</v-col>
		</v-row>

	</div>
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
		const defaultHeaders = {
			SL: [

				{ text: 'Voucher', value: 'MaChuongTrinh', width: '550px', align: 'center' },
				{ text: 'Tổng SL', value: 'sumSoLuongFormatted', width: '100px', align: 'right', cellClass: "highlight-total" }
			],
			TT: [
				{ text: 'Voucher', value: 'MaChuongTrinh', width: '550px', align: 'center' },
				{ text: 'Tổng TT', value: 'sumThanhTienFormatted', width: '100px', align: 'right', cellClass: "highlight-total" }
			]
		};
		return {
			CuaHangNhanID: 0,
			CuaHangDoiThuongID: 0,
			PhanHieuID: 0,
			KhuVucID: 0,
			HinhThucThanhToan: 0,
			ChuongTrinhID: 0,
			Voucher: '',
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
			headersDefault: {
				SL: defaultHeaders.SL,
				TT: defaultHeaders.TT,
				all: [...defaultHeaders.SL, ...defaultHeaders.TT.slice(1)],
				sub: [{ text: 'Cửa hàng nhận', value: 'TenCuaHangNhan', width: '302px', align: 'end' }, { text: 'Cửa hàng đổi thưởng', value: 'TenCuaHangDoiThuong', width: '302px', align: 'end' }, ...defaultHeaders.SL.slice(1), ...defaultHeaders.TT.slice(1)],
			},
			tableDefault: ["VouchersNhan", "VouchersQuet", "VouchersDoi"]
		}
	},
	mounted() {

	},
	methods: {
		reportGET() {
			vueData.FilterObject = this.buildFilter();
			ajaxCALL('/eorder/BaoCao_ChuongTrinhQuaySo_CuaHang', vueData.FilterObject, (res) => {
				const { headers, subHeaders, VouchersNhan, VouchersQuet, VouchersDoi } = this.processReportData(res.data);
				vueData.dataTable = [VouchersNhan, VouchersQuet, VouchersDoi];
				vueData.headers = headers
				vueData.subHeaders = subHeaders
			});
		},
		buildFilter() {
			return {
				CuaHangNhanID: this.CuaHangNhanID,
				CuaHangDoiThuongID: this.CuaHangDoiThuongID,
				HinhThucThoiGian: this.HinhThucThoiGian,
				Voucher: this.Voucher,
				ChuongTrinhID: this.ChuongTrinhID,
				Ngay: this.Ngay,
				TuNgay: this.TuNgay,
				DenNgay: this.DenNgay,
				Nam: this.Nam,
				TuNam: this.TuNam,
				DenNam: this.DenNam,
				Thang: this.Thang
			};
		},

		// hàm xử lí column động
		buildDynamicColumns(columsFlex, typeTime, isDaily) {
			const suffix = this.suffixColumn(typeTime);
			const prefix = this.preflixColumn(typeTime);

			return columsFlex.flatMap(col => {
				const value = col[typeTime];
				return [
					{ ...col, text: isDaily ? this.formatDaily(value) + " SL"  : `${prefix} ${value}${suffix} SL`, value: `${typeTime}_SL_${value}`, align: 'right' },
					{ ...col, text: isDaily ? this.formatDaily(value) + " TT" : `${prefix} ${value}${suffix} TT`, value: `${typeTime}_TT_${value}`, align: 'right' }
				];
			});
		},
		processReportData([columsFlex, ...voucherGroups]) {
			const typeTime = Object.keys(columsFlex[0])[0];
			const isDaily = typeTime === 'Ngay';

			const dynamicCols = this.buildDynamicColumns(columsFlex, typeTime, isDaily);

			const headers = [...this.headersDefault.all, ...dynamicCols]
			const subHeaders = [...this.headersDefault.sub, ...dynamicCols];

			const dataTableRaw = {}
			const vouchersMap = new Map()
			this.tableDefault.forEach((element, idx) => {
				vouchersMap.set(element, [...new Set(voucherGroups[idx].map(v => v.MaChuongTrinh).filter(Boolean))])
				dataTableRaw[element] = voucherGroups[idx].map(e => ({ ...e, TenCuaHangDoiThuong: e.TenCuaHangDoiThuong ? e.TenCuaHangDoiThuong : 'Không có đổi ở cửa hàng' }))
			});

			const handledData = this.tableDefault.map((group) =>
				this.buildTable(dataTableRaw[group], [...this.headersDefault.all, ...dynamicCols], typeTime, vouchersMap.get(group))
			)

			const dataTable = this.tableDefault.reduce((acc, nameTable, index) => {
				acc[nameTable] = handledData[index];
				return acc;
			}, {});

			return { headers, subHeaders, ...dataTable };
		},
		buildTable(vouchers = [], columns = [], typeTime, vouchers_key) {
			const dynamicCols = columns.filter(c => c?.value?.startsWith(`${typeTime}_`));

			// Group dữ liệu theo voucherKey + (CuaHangNhanID, CuaHangDoiThuongID, timeValue)
			const groupedData = new Map();
			vouchers.forEach(v => {
				const timeValue = v?.[typeTime] ?? v?.HinhThucThoiGian ?? '';
				const keyVoucher = v.MaChuongTrinh;
				const key = `${v.CuaHangNhanID}_${v.CuaHangDoiThuongID}_${timeValue}`;
				if (!groupedData.has(keyVoucher)) groupedData.set(keyVoucher, new Map());
				groupedData.get(keyVoucher).set(key, v);
			});

			return vouchers_key.map(voucherKey => {
				const mainRow = this._initRow(voucherKey, dynamicCols);
				mainRow.childRows = [];

				const rowsMap = groupedData.get(voucherKey) || new Map();

				// Gom nhóm theo cặp CuaHangNhanID + CuaHangDoiThuongID
				const groupedRows = new Map();

				rowsMap.forEach(rowData => {
					const pairKey = `${rowData.CuaHangNhanID}_${rowData.CuaHangDoiThuongID}`;
					if (!groupedRows.has(pairKey)) {
						groupedRows.set(pairKey, this._initRow(rowData, dynamicCols));
					}

					const row = groupedRows.get(pairKey);


					// Cộng dồn vào row hiện tại
					dynamicCols.forEach(col => {
						const isSL = col.value.includes('_SL_');
						const timeValue = col.value.split('_').pop();
						const key = `${rowData.CuaHangNhanID}_${rowData.CuaHangDoiThuongID}_${timeValue}`;
						const val = Number(rowsMap.get(key)?.[isSL ? 'SoLuong' : 'TongTien'] || 0);

						// flag để render màu sau này
						row[`${col.value}_highlight`] = val > 0;

						row[`${col.value}_value`] += val;
						row[isSL ? 'sumSoLuongFormatted_value' : 'sumThanhTienFormatted_value'] += val;

						mainRow[`${col.value}_value`] += val;
						mainRow[isSL ? 'sumSoLuongFormatted_value' : 'sumThanhTienFormatted_value'] += val;
					});
				});

				// Hoàn thiện và push childRows
				groupedRows.forEach(row => {
					this._finalizeRow(row, dynamicCols);
					mainRow.childRows.push(row);
				});

				this._finalizeRow(mainRow, dynamicCols);
				return mainRow;
			});
		},


		// Hàm init row (numeric totals + numeric per-column)
		_initRow(voucher, dynamicCols) {
			const isString = typeof voucher == 'string'
			const row = isString ?
				{ MaChuongTrinh: voucher, sumSoLuongFormatted_value: 0, sumThanhTienFormatted_value: 0 } :
				{ ...voucher, sumSoLuongFormatted_value: 0, sumThanhTienFormatted_value: 0 }

			dynamicCols.forEach(col => row[`${col.value}_value`] = 0);
			return row;
		},

		// Hàm finalize row: convert numeric -> formatted, xóa key tạm
		_finalizeRow(row, dynamicCols) {
			dynamicCols.forEach(col => {
				row[col.value] = row[`${col.value}_value`].toLocaleString("vi-vn") // formatPrice(row[`${col.value}_value`]);
				delete row[`${col.value}_value`];
			});
			row.sumSoLuongFormatted = row.sumSoLuongFormatted_value.toLocaleString("vi-vn") // formatPrice(row.sumSoLuongFormatted_value);
			row.sumThanhTienFormatted = row.sumThanhTienFormatted_value.toLocaleString("vi-vn") //formatPrice(row.sumThanhTienFormatted_value);
		},

		//  get alias
		suffixColumn(col) { return col === 'Gio' ? 'H' : '' },
		preflixColumn(col) { return { Tuan: 'Tuần', Thang: 'Tháng', Quy: 'Quý' }[col] || '' },
		formatDaily(str) { return moment(str).format("D/M") },

	}
}
</script>