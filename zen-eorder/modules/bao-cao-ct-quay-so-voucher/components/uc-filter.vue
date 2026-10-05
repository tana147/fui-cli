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
				{ text: 'Thuộc tính', value: 'ThuocTinh', width: '250px' },
				{ text: 'Tổng SL', value: 'sumSoLuongFormatted', width: '100px', align: 'right', cellClass: "highlight-total" }
			],
			TT: [
				{ text: 'Thuộc tính', value: 'ThuocTinh', width: '250px' },
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
				ALL: [...defaultHeaders.SL, ...defaultHeaders.TT.slice(1)],
				SL: defaultHeaders.SL,
				TT: defaultHeaders.TT,

				subALL: [{ text: 'Thuộc tính', value: 'ThuocTinh', width: '304px', align: 'end' }, ...defaultHeaders.SL.slice(1), ...defaultHeaders.TT.slice(1)],
				subSL: [{ text: 'Thuộc tính', value: 'ThuocTinh', width: '304px', align: 'end' }, ...defaultHeaders.SL.slice(1)],
				subTT: [{ text: 'Thuộc tính', value: 'ThuocTinh', width: '304px', align: 'end' }, ...defaultHeaders.TT.slice(1)]
			},
			rowDefault: ["Voucher Nhận", "Voucher Quét", "Voucher Đổi", "Voucher Tặng"]
		}
	},
	mounted() {

	},
	methods: {
		reportGET() {
			vueData.FilterObject = this.buildFilter();
			ajaxCALL('/eorder/BaoCao_ChuongTrinhQuaySo_Voucher', vueData.FilterObject, (res) => {
				const { headersALL, subHeadersALL, data } = this.processReportData(res.data);

				vueData.headers = headersALL;
				vueData.subHeaders = subHeadersALL;
				vueData.dataTable = data;

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
					{ ...col, text: isDaily ? this.formatDaily(value) + " SL" : `${prefix} ${value}${suffix} SL`, value: `${typeTime}_SL_${value}`, align: 'right' },
					{ ...col, text: isDaily ? this.formatDaily(value) + " TT" : `${prefix} ${value}${suffix} TT`, value: `${typeTime}_TT_${value}`, align: 'right' }
				];
			});
		},
		processReportData([columsFlex, ...voucherGroups]) {
			const typeTime = Object.keys(columsFlex[0])[0];
			const isDaily = typeTime === 'Ngay';

			const dynamicCols = this.buildDynamicColumns(columsFlex, typeTime, isDaily);
			const colsSL = dynamicCols.filter(c => c.value.includes('_SL_'));
			const colsTT = dynamicCols.filter(c => c.value.includes('_TT_'));

			const headersALL = [...this.headersDefault.ALL, ...dynamicCols]
			const headersSL = [...this.headersDefault.SL, ...colsSL];
			const headersTT = [...this.headersDefault.TT, ...colsTT];

			const subHeadersALL = [...this.headersDefault.subALL, ...dynamicCols];
			const subHeadersSL = [...this.headersDefault.subSL, ...colsSL];
			const subHeadersTT = [...this.headersDefault.subTT, ...colsTT];

			const rows = voucherGroups.map((group, idx) => this.buildVoucherRows(group, idx, [...this.headersDefault.ALL, ...dynamicCols], typeTime));

			return { headersALL, subHeadersALL, headersSL, headersTT, subHeadersSL, subHeadersTT, data: rows };
		},
		buildVoucherRows(vouchers = [], index, columns = [], typeTime) {
			// 1. Lọc ra các cột động theo typeTime
			const dynamicCols = columns.filter(c => c?.value?.startsWith(`${typeTime}_`));

			// 2. Khởi tạo dòng tổng (numeric và formatted)
			const summaryRow = this._initRow(this.rowDefault[index] ?? 'Tổng', dynamicCols);

			// 3. Nếu không có voucher -> trả về 1 dòng tổng toàn 0
			if (!Array.isArray(vouchers) || vouchers.length === 0) {
				this._finalizeRow(summaryRow, dynamicCols);
				return summaryRow;
			}

			// 4. Map dữ liệu: key = `${index}_qr${QrCode_TrungThuong}_${time}`
			const dataMap = new Map(
				vouchers.map(item => {
					const timeKey = item?.[typeTime] ?? item?.HinhThucThoiGian ?? '';
					return [`${index}_qr${item.QrCode_TrungThuong}_${timeKey}`, item];
				})
			);

			// 5. Lấy danh sách mã voucher
			const voucherCodes = [...new Set(vouchers.map(v => v.QrCode_TrungThuong).filter(Boolean))];

			const childRows = [];

			// 6. Tạo từng dòng chi tiết và cộng vào summary
			voucherCodes.forEach(code => {
				const row = this._initRow(code, dynamicCols);

				dynamicCols.forEach(col => {
					const colType = col.value.includes('_SL_') ? 'SoLuong' : 'TongTien';
					const timeValue = col.value.split('_').pop();
					const key = `${index}_qr${code}_${timeValue}`;
					const rawVal = Number(dataMap.get(key)?.[colType] ?? 0);

					// Gán giá trị formatted cho cell
					row[col.value] = rawVal.toLocaleString("vi-vn") // formatPrice(rawVal);
					row[`${col.value}_value`] = rawVal;

					// Cộng dồn totals cho row
					const totalKey = colType === 'SoLuong' ? 'sumSoLuongFormatted_value' : 'sumThanhTienFormatted_value';
					row[totalKey] += rawVal;

					// Cộng dồn totals cho summary
					summaryRow[totalKey] += rawVal;
					summaryRow[`${col.value}_value`] += rawVal;
				});

				this._finalizeRow(row, dynamicCols);
				childRows.push(row);
			});

			// 7. Hoàn thiện summaryRow
			this._finalizeRow(summaryRow, dynamicCols);

			summaryRow.childRows = [...childRows]
			return summaryRow;
		},

		// Hàm init row (numeric totals + numeric per-column)
		_initRow(label, dynamicCols) {
			const row = {
				ThuocTinh: label,
				sumSoLuongFormatted_value: 0,
				sumThanhTienFormatted_value: 0
			};
			dynamicCols.forEach(col => row[`${col.value}_value`] = 0);
			return row;
		},

		// Hàm finalize row: convert numeric -> formatted, xóa key tạm
		_finalizeRow(row, dynamicCols) {
			dynamicCols.forEach(col => {
				row[col.value] = row[`${col.value}_value`].toLocaleString("vi-vn") // formatPrice(row[`${col.value}_value`]);
				delete row[`${col.value}_value`];
			});
			row.sumSoLuongFormatted = row.sumSoLuongFormatted_value.toLocaleString("vi-vn") //formatPrice(row.sumSoLuongFormatted_value);
			row.sumThanhTienFormatted = row.sumThanhTienFormatted_value.toLocaleString("vi-vn") // formatPrice(row.sumThanhTienFormatted_value);
		},

		//  get alias
		suffixColumn(col) { return col === 'Gio' ? 'H' : '' },
		preflixColumn(col) { return { Tuan: 'Tuần', Thang: 'Tháng', Quy: 'Quý' }[col] || '' },
		formatDaily(str) { return moment(str).format("D/M") },

	}
}
</script>