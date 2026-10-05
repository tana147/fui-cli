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
		const defaultHeaders = [
			{ text: 'Mục', value: 'Muc', width: '250px' },
			{ text: 'Tổng', value: 'sumFormatted', width: '100px', align: 'right', cellClass: "highlight-total" }
		];
		return {
			// total
			TongSoLyThoaDK: 0,

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
				all: [...defaultHeaders],
				sub: [{ text: 'Muc', value: 'Muc', width: '304px', align: 'end' }, ...defaultHeaders.slice(1)],
			},
			rowDefault: ["Tổng số ly thỏa điều kiện", "Tỉ lệ Tổng CPSD/ Tổng CP nhận", "Tỉ lệ Tổng SL nhận/ Tổng số ly thoã ĐK", "Tỉ lệ SL quét/ SL nhận", "Tỉ lệ SL đổi/ SL nhận"],
			dataRawTongQuan: [],
			dataRawVoucher: [],
			dataRawCuaHang: []
		}
	},
	mounted() {

	},
	methods: {
		ajaxCALLPromise(url, data) {
			return new Promise((resolve, reject) => {
				ajaxCALL(url, data, (res) => {
					if (res && res.data !== undefined) {
						resolve(res.data);
					} else {
						reject(new Error(`Empty or invalid response from ${url}`));
					}
				});
			});
		},
		reportGET() {
			vueData.FilterObject = this.buildFilter();
			const arrCALL = [
				this.ajaxCALLPromise('/eorder/BaoCao_ChuongTrinhQuaySo_TongLy', vueData.FilterObject),
				this.ajaxCALLPromise('/eorder/BaoCao_ChuongTrinhQuaySo_Voucher', vueData.FilterObject),
				this.ajaxCALLPromise('/eorder/BaoCao_ChuongTrinhQuaySo_TyLeQuetNhan', vueData.FilterObject),
				this.ajaxCALLPromise('/eorder/BaoCao_ChuongTrinhQuaySo_TyLeDoiNhan', vueData.FilterObject),
			];

			Promise.all(arrCALL).then(([tongQuan, voucher, TyLeQuetNhan, TyLeDoiNhan]) => {
				const columnsDynamic = tongQuan[0]
				const { headers, subHeaders, data } = this.processReportData([columnsDynamic, tongQuan.splice(1), voucher.splice(1), TyLeQuetNhan.splice(1), TyLeDoiNhan.splice(1)])

				vueData.dataTable = data
				vueData.headers = headers
				vueData.subHeaders = subHeaders
			})

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
					{ ...col, text: isDaily ? this.formatDaily(value) : `${prefix} ${value}${suffix}`, value: `${typeTime}_${value}`, align: 'right' }
				];
			});
		},
		processReportData([columsFlex, ...tableData]) {
			const typeTime = Object.keys(columsFlex[0])[0];

			const isDaily = typeTime === 'Ngay';

			// xử lí cột động 
			const dynamicCols = this.buildDynamicColumns(columsFlex, typeTime, isDaily);
			const headers = [...this.headersDefault.all, ...dynamicCols];
			const subHeaders = [...this.headersDefault.sub, ...dynamicCols];

			// "Tổng số ly thỏa điều kiện"	
			const rows = this.rowDefault.map((rowGroup, idx) => this.buildRows(tableData, idx, headers, typeTime));
			return { headers, subHeaders, data: rows };
		},
		buildRows(data = [], index, columns = [], typeTime) {
			// 1. Lọc ra các cột động theo typeTime
			const dynamicCols = columns.filter(c => c?.value?.startsWith(`${typeTime}_`));

			// 2. Khởi tạo dòng tổng (numeric và formatted)
			const summaryRow = this._initRow(this.rowDefault[index], dynamicCols);

			// Xử lý và kiểm tra dữ liệu đầu vào
			const [tongQuanData = [], voucherData = [], tyLeQuetNhan = [], tyLeDoiNhan = []] = data;
			const tongQuanRaw = tongQuanData[0] || [];
			const voucherNhanRaw = voucherData[1] || [];
			const voucherQuetRaw = voucherData[2] || [];
			const voucherSuDungRaw = voucherData[2] || [];
			const TyLeQuetNhanRaw = tyLeQuetNhan || [];
			const TyLeDoiNhanRaw = tyLeDoiNhan || [];

			// Nếu không có voucher -> trả về 1 dòng tổng toàn 0
			if (!Array.isArray(tongQuanRaw) || tongQuanRaw.length === 0) {
				this._finalizeRow(summaryRow, dynamicCols);
				return summaryRow;
			}

			const self = this;
			const actions = {
				// xử lí nhóm tổng ly thỏa điều kiện theo từng cửa hàng
				0: () => {
					// Map dữ liệu
					const dataMap = new Map(
						tongQuanRaw.map(item => {
							const timeKey = item?.[typeTime] ?? item?.HinhThucThoiGian ?? '';
							return [`${index}_ch${item.CuaHangNhanID}_${timeKey}`, item];
						})
					);

					// Lấy danh sách mã voucher
					const CuaHangUnique = [...new Set(tongQuanRaw.map(v => v.CuaHangNhanID).filter(Boolean))];
					const childRows = [];

					// xử lí từng dòng dữ liệu
					CuaHangUnique.forEach(chID => {
						const getName = tongQuanRaw.find(e => e.CuaHangNhanID === chID)?.TenCuaHangNhan || `Cửa hàng ${chID}`;
						const row = self._initRow(getName, dynamicCols);

						dynamicCols.forEach(col => {
							const timeValue = col.value.split('_').pop();
							const key = `${index}_ch${chID}_${timeValue}`;
							const rawVal = Number(dataMap.get(key)?.SoLuong ?? 0);

							// Gán giá trị formatted cho cell
							row[col.value] = formatPrice(rawVal);
							row[`${col.value}_value`] = rawVal;

							// Cộng dồn totals cho row
							row['sumFormatted_value'] += rawVal;

							// Cộng dồn totals cho summary
							summaryRow['sumFormatted_value'] += rawVal;
							summaryRow[`${col.value}_value`] += rawVal;
						});

						dynamicCols.forEach((col, index, arr) => {
							if (index === 0) {
								row[col.value + '_isGrowth'] = 0
							} else {
								const current = row[col.value + '_value']
								const prev = row[arr[index - 1].value + '_value']
								row[col.value + '_isGrowth'] = this.getGrowth(current, prev)

							}
						})

						this._finalizeRow(row, dynamicCols);

						childRows.push(row);
					});


					this._finalizeRow(summaryRow, dynamicCols);
					this.TongSoLyThoaDK = summaryRow.sumFormatted_value;
					summaryRow.childRows = [...childRows]
				},
				// Tỉ lệ Tổng CPSD/ Tổng CP nhận = tổng thành tiền voucher / tổng thành tiền nhận voucher 
				1: () => {
					//mapping data
					const dataMapSuDung = new Map(
						voucherSuDungRaw.map(item => {
							const timeKey = item?.[typeTime] ?? item?.HinhThucThoiGian ?? '';
							return [`${index}_code${item.QrCode_TrungThuong}_${timeKey}`, item];
						})
					);

					// rows nhận voucher
					const voucherUnique = [...new Set(voucherSuDungRaw.map(v => v.QrCode_TrungThuong).filter(Boolean))];
					let childRows = [];
					//xử lý từng dòng dữ liệu
					voucherUnique.forEach(voucherCode => {
						const row = self._initRow(voucherCode, dynamicCols);

						// giá trị từng cột động
						dynamicCols.forEach(col => {
							const timeValue = col.value.split('_').pop();
							const key = `${index}_code${voucherCode}_${timeValue}`;
							const rawVal = Number(dataMapSuDung.get(key)?.TongTien ?? 0);

							// Gán giá trị formatted cho cell
							row[col.value] = formatPrice(rawVal);
							row[`${col.value}_value`] = rawVal;

							// Cộng dồn totals cho row
							row['sumFormatted_value'] += rawVal;

							// Cộng dồn totals cho summary
							summaryRow['sumFormatted_value'] += rawVal;
							summaryRow[`${col.value}_value`] += rawVal;
						});

						dynamicCols.forEach((col, index, arr) => {
							if (index === 0) {
								row[col.value + '_isGrowth'] = 0
							} else {
								const current = row[col.value + '_value']
								const prev = row[arr[index - 1].value + '_value']
								row[col.value + '_isGrowth'] = this.getGrowth(current, prev)
							}
						})

						this._finalizeRow(row, dynamicCols);
						childRows.push(row);
					})

					// dòng tổng tính tỉ lệ
					// tổng thành tiền nhận voucher
					const totalsPriceVoucher = voucherNhanRaw.reduce((acc, item) => acc + Number(item.TongTien || 0), 0);
					this._finalizeRowPercent(summaryRow, dynamicCols, totalsPriceVoucher);
					summaryRow.childRows = [...childRows]
				},
				// Tỉ lệ Tổng SL nhận/ Tổng số ly thoã ĐK
				2: () => {
					//mapping data
					const dataMapNhan = new Map(
						voucherNhanRaw.map(item => {
							const timeKey = item?.[typeTime] ?? item?.HinhThucThoiGian ?? '';
							return [`${index}_code${item.QrCode_TrungThuong}_${timeKey}`, item];
						})
					);

					// rows nhận voucher
					const voucherUnique = [...new Set(voucherNhanRaw.map(v => v.QrCode_TrungThuong).filter(Boolean))];
					let childRows = [];
					//xử lý từng dòng dữ liệu
					voucherUnique.forEach(voucherCode => {
						const row = self._initRow(voucherCode, dynamicCols);

						// giá trị từng cột động
						dynamicCols.forEach(col => {
							const timeValue = col.value.split('_').pop();
							const key = `${index}_code${voucherCode}_${timeValue}`;
							const rawVal = Number(dataMapNhan.get(key)?.SoLuong ?? 0);

							// Gán giá trị formatted cho cell
							row[col.value] = formatPrice(rawVal);
							row[`${col.value}_value`] = rawVal;

							// Cộng dồn totals cho row
							row['sumFormatted_value'] += rawVal;

							// Cộng dồn totals cho summary
							summaryRow['sumFormatted_value'] += rawVal;
							summaryRow[`${col.value}_value`] += rawVal;
						});

						dynamicCols.forEach((col, index, arr) => {
							if (index === 0) {
								row[col.value + '_isGrowth'] = 0
							} else {
								const current = row[col.value + '_value']
								const prev = row[arr[index - 1].value + '_value']
								row[col.value + '_isGrowth'] = this.getGrowth(current, prev)
							}
						})

						this._finalizeRow(row, dynamicCols);
						childRows.push(row);
					})

					// dòng tổng tính tỉ lệ
					// tổng thành tiền nhận voucher
					this._finalizeRowPercent(summaryRow, dynamicCols, this.TongSoLyThoaDK);
					summaryRow.childRows = [...childRows]
				},
				// Tỉ lệ SL quét/ SL nhận (CHỈ SHOW – KHÔNG TÍNH)
				3: () => {
					const dataMap = new Map(
						TyLeQuetNhanRaw.map(item => {
							const timeKey = item?.[typeTime] ?? item?.HinhThucThoiGian ?? '';
							return [`code${item.Voucher}_${timeKey}`, Number(item.TiLe || 0)];
						})
					);

					const voucherUnique = [...new Set(TyLeQuetNhanRaw.map(v => v.Voucher).filter(Boolean))];
					let childRows = [];

					voucherUnique.forEach(voucherCode => {
						const row = self._initRow(voucherCode, dynamicCols);

						dynamicCols.forEach(col => {
							const timeValue = col.value.split('_').pop();
							const key = `code${voucherCode}_${timeValue}`;
							const tiLe = dataMap.get(key) || 0;

							row[col.value] = tiLe + '%';
							row[`${col.value}_value`] = tiLe;

							summaryRow[`${col.value}_value`] += tiLe;
						});

						childRows.push(row);
					});


					summaryRow.sumFormatted = '';
					summaryRow.childRows = childRows;
				},

				// Tỉ lệ SL đổi/ SL nhận (CHỈ SHOW – KHÔNG TÍNH)
				4: () => {
					const dataMap = new Map(
						TyLeDoiNhanRaw.map(item => {
							const timeKey = item?.[typeTime] ?? item?.HinhThucThoiGian ?? '';
							return [`code${item.Voucher}_${timeKey}`, Number(item.TiLe || 0)];
						})
					);

					const voucherUnique = [...new Set(TyLeDoiNhanRaw.map(v => v.Voucher).filter(Boolean))];
					let childRows = [];

					voucherUnique.forEach(voucherCode => {
						const row = self._initRow(voucherCode, dynamicCols);

						dynamicCols.forEach(col => {
							const timeValue = col.value.split('_').pop();
							const key = `code${voucherCode}_${timeValue}`;
							const tiLe = dataMap.get(key) || 0;

							row[col.value] = tiLe + '%';
							row[`${col.value}_value`] = tiLe;

							summaryRow[`${col.value}_value`] += tiLe;
						});

						childRows.push(row);
					});


					summaryRow.sumFormatted = '';
					summaryRow.childRows = childRows;
				},

			}[index]

			actions && actions();


			return summaryRow;
		},

		// Hàm init row (numeric totals + numeric per-column)
		_initRow(label, dynamicCols) {
			const row = {
				Muc: label,
				sumFormatted_value: 0
			};
			dynamicCols.forEach(col => row[`${col.value}_value`] = 0);
			return row;
		},

		// Hàm finalize row: convert numeric -> formatted, xóa key tạm
		_finalizeRow(row = [], dynamicCols = []) {
			dynamicCols.forEach(col => {
				row[col.value] = formatPrice(row[`${col.value}_value`]);
				delete row[`${col.value}_value`];
			});
			row.sumFormatted = formatPrice(row.sumFormatted_value);
		},

		_finalizeRowPercent(row = [], dynamicCols = [], totals) {
			// tổng thành tiền nhận voucher
			dynamicCols.forEach(col => {
				totals > 0 ? row[col.value] = Math.round((row[`${col.value}_value`] / totals) * 100, 2) + '%' : null
				delete row[`${col.value}_value`];
			});
			row.sumFormatted = totals > 0 ? Math.round((row.sumFormatted_value / totals) * 100, 2) + '%' : '0%';
		},

		//  get alias
		suffixColumn(col) { return col === 'Gio' ? 'H' : '' },
		preflixColumn(col) { return { Tuan: 'Tuần', Thang: 'Tháng', Quy: 'Quý' }[col] || '' },
		formatDaily(str) { return moment(str).format("D/M") },
		getGrowth(current, prev) { return Math.sign(current - prev) }
	}
}
</script>