<template>
	<v-dialog v-model="isShowDialogExport" max-width="500px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<v-toolbar-title>
					Xuất excel
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="closeDialog">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-card-title>
			<v-card-text>
				<v-row dense>
					<v-col cols="6">
						<f-date label="Từ ngày" outlined dense v-model="TuNgayDoiSoat" :date-add="0" hide-details />
					</v-col>
					<v-col cols="6">
						<f-date label="Đến ngày" outlined dense v-model="DenNgayDoiSoat" :date-add="0" hide-details />
					</v-col>
				</v-row>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" text @click="onSubmit">
					Xuất
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShowDialogExport: Boolean,
		},
		data() {
			return {
				vueData,
				TuNgayDoiSoat: null,
				DenNgayDoiSoat: null,
				DSCuaHang: null,
				DSNgay: null,
				DataExport: null,
				DSNganHangChietKhau: null,
				DataExportDetail: null,
				caMap: {
					'1': 'Sáng',
					'2': 'Tối',
					'3': 'Đêm'
				},
			}
		},
		mounted() {
			const now = moment();
			this.TuNgayDoiSoat = now.subtract(1, "days").format("YYYY-MM-DD")
			this.DenNgayDoiSoat = this.TuNgayDoiSoat
		},
		computed: {
		},
		watch: {},
		methods: {
			closeDialog() {
				this.$emit('update:isShowDialogExport', false)
			},
	
			async onSubmit() {
				if (this.selectedMonth === null) {
					Vue.$toast.warning("Bạn chưa chọn tháng", { position: "top" });
					return
				}
				if (this.selectedYear === null) {
					Vue.$toast.warning("Bạn chưa chọn năm", { position: "top" });
					return
				}
				const params = {
					TuNgayDoiSoat: this.TuNgayDoiSoat,
					DenNgayDoiSoat: this.DenNgayDoiSoat
				}
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatDoanhThu_Select_BaoCao', params)
				if (data) {
					this.DSCuaHang = data[0]
					this.DSNgay = data[1]
					this.DataExport = data[2]
					let DataCuaHang = [...data[0].filter(CuaHang => CuaHang.CuaHangID !== 39 && CuaHang.CuaHangID !== 40)]
					let DataDoanhThu = [...data[3]]
	
					DataCuaHang.map((CuaHang) => {
						CuaHang.Ca = []
	
						DataDoanhThu.map((data) => {
							if (data.CuaHangID === CuaHang.CuaHangID) CuaHang.Ca.push({ ...data })
						})
						// 35, 37 có 3 ca (Sáng, tối, đêm)
						// Còn lại 2 ca (Sáng, tối)
						// 30 ca tối
						// 1 sáng, 2 tối, 3 đêm
						// const baseCaSet = new Set(CuaHang.Ca.map(ca => ca.Ca))
						// const baseCaArray = [...baseCaSet].sort((a, b) => Number(a) - Number(b))
						const base1Ca = ['2']
						const base2Ca = ['1', '2']
						const base3Ca = ['1', '2', '3']
	
						CuaHang.baseCaArray =
							CuaHang.CuaHangID === 30
								? base1Ca
								: [35, 37].includes(CuaHang.CuaHangID)
									? base3Ca
									: base2Ca
					})
					this.DataExportDetail = DataCuaHang
					this.onExport()
				} else
					Vue.$toast.error("Có lỗi xảy ra, vui lòng thử lại sau", { position: "top" });
			},
	
			getTotalByCuaHangID(CuaHangID) {
				let res = 0
				this.DataExport.map((item) => {
					if (item.CuaHangID === CuaHangID) res += item.TongDoanhThu
				})
				return res
			},
	
			getTotalTMByCuaHangIDAndCa(CuaHangID, Ca) {
				const CuaHang = this.DataExportDetail.find((CuaHang) => CuaHang.CuaHangID === CuaHangID)
				const DSCa = CuaHang.Ca ?? []
				let res = 0
				DSCa.filter((c) => c.Ca === Ca).forEach((c) => res += Number(c.DoiSoat_TM))
				return res
			},
	
			getTotalByCuaHangIDAndPrefix(CuaHangID, prefix) {
				const CuaHang = this.DataExportDetail.find((CuaHang) => CuaHang.CuaHangID === CuaHangID)
				const DSCa = CuaHang.Ca ?? []
				let res = 0
				DSCa.forEach((c) => res += Number(c[prefix]))
				return res
			},
	
			intToExcelColumn(n) {
				let result = '';
				while (n > 0) {
					n--;
					result = String.fromCharCode(65 + (n % 26)) + result;
					n = Math.floor(n / 26);
				}
				return result;
			},
	
			autoWidth(worksheet, minimalWidth = 10) {
				worksheet.columns.forEach(column => {
					let maxLength = 0;
	
					column.eachCell({ includeEmpty: true }, cell => {
						let value = cell.value;
						if (!value) value = "";
						if (typeof value !== "string") value = value.toString();
						maxLength = Math.max(maxLength, value.length);
					});
	
					column.width = Math.max(maxLength + 5, minimalWidth);
				});
			},
	
			findItem(CuaHangID, NgaySo) {
				return this.DataExport.find((item) => item.CuaHangID === CuaHangID && item.Ngay_So === NgaySo)
			},
	
			findItemSheetDetail(CuaHangID, NgaySo, Ca) {
				const CuaHang = this.DataExportDetail.find((ch) => ch.CuaHangID === CuaHangID)
				const DSCa = CuaHang.Ca ?? []
				const res = DSCa.find((c) => c.Ngay_So === NgaySo && c.Ca === Ca)
				return res ?? {}
			},
	
			async onExport() {
				const workbook = new ExcelJS.Workbook();
				const sheet_Tong = workbook.addWorksheet("Tổng");
				const sheet_TM = workbook.addWorksheet("TM");
				const sheet_QT = workbook.addWorksheet("Quẹt thẻ");
				const sheet_FOODY = workbook.addWorksheet("FOODY");
				const sheet_GRAB = workbook.addWorksheet("GRAB");
				const sheet_XSM = workbook.addWorksheet("XSM");
	
				const styleHeaderCenter = {
					font: { bold: true, size: 12 },
					alignment: { horizontal: "center", vertical: "middle" },
					border: {
						top: { style: "thin" },
						left: { style: "thin" },
						bottom: { style: "thin" },
						right: { style: "thin" },
					},
				};
	
				const styleHeaderLeft = {
					font: { bold: true, size: 12 },
					alignment: { horizontal: "left", vertical: "middle" },
					border: {
						top: { style: "thin" },
						left: { style: "thin" },
						bottom: { style: "thin" },
						right: { style: "thin" },
					},
				};
	
				const styleCellRight = {
					font: { size: 12 },
					alignment: { horizontal: "right", vertical: "middle" },
					border: {
						top: { style: "thin" },
						left: { style: "thin" },
						bottom: { style: "thin" },
						right: { style: "thin" },
					},
					numFmt: '[=0]0;#,##0'
				};
	
				const styleCellLeft = {
					font: { size: 12 },
					alignment: { horizontal: "left", vertical: "middle" },
					border: {
						top: { style: "thin" },
						left: { style: "thin" },
						bottom: { style: "thin" },
						right: { style: "thin" },
					},
				};
	
				const CuaHangLength = this.DSCuaHang.length
	
				let row = 3
				// BEGIN HEADER sheet_Tong
				sheet_Tong.mergeCells(`A1:${this.intToExcelColumn(this.DSCuaHang.length + 1)}1`);
				sheet_Tong.getCell("A1").value = "DOANH THU"
				sheet_Tong.getCell("A1").style = styleHeaderCenter
	
				sheet_Tong.getCell("A2").value = "NGÀY"
				sheet_Tong.getCell("A2").style = styleHeaderCenter
	
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 2)}2`).value = "KHÁCH CK"
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 2)}2`).style = styleHeaderCenter
	
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 3)}2`).value = "TỔNG"
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 3)}2`).style = styleHeaderCenter
	
				sheet_Tong.mergeCells(`${this.intToExcelColumn(CuaHangLength + 4)}1:${this.intToExcelColumn(this.DSCuaHang.length + 4 + 2)}1`);
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 4)}1`).value = 'QUẸT THẺ'
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 4)}1`).style = styleHeaderCenter
				// QT1
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 4)}2`).value = "BIDV"
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 4)}2`).style = styleHeaderCenter
				//QT2
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 5)}2`).value = "TECH"
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 5)}2`).style = styleHeaderCenter
				//QT3
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 6)}2`).value = "VP"
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 6)}2`).style = styleHeaderCenter
	
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 7)}2`).value = "DỰ TRÙ DOANH THU"
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 7)}2`).style = styleHeaderCenter
	
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 8)}2`).value = "DOANH THU THÁNG TRƯỚC"
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 8)}2`).style = styleHeaderCenter
	
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 10)}2`).value = "Ngày"
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 10)}2`).style = styleHeaderCenter
	
				sheet_Tong.mergeCells(`${this.intToExcelColumn(CuaHangLength + 9)}1:${this.intToExcelColumn(this.DSCuaHang.length + 9 + 2)}1`);
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 9)}1`).value = 'CHÊNH LỆCH '
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 9)}1`).style = styleHeaderCenter
				// END HEADER sheet_Tong
				// Tên cửa hàng sheet_Tong
				this.DSCuaHang.forEach((CuaHang, index) => {
					sheet_Tong.getCell(`${this.intToExcelColumn(index + 2)}2`).value = CuaHang.TenCuaHang
					sheet_Tong.getCell(`${this.intToExcelColumn(index + 2)}2`).style = styleHeaderCenter
				})
	
				let totalDoanhThuRow = 0
				let totalDoanhThuThangTruocRow = 0
				let totalChuyenKhoan = 0
				// QT
				let totalQT_BIDV = 0
				let totalQT_TECH = 0
				let totalQT_VP = 0
				// main process sheet_Tong
				this.DSNgay.forEach((Ngay, index) => {
					sheet_Tong.getCell(`A${row}`).value = Ngay.Ngay_So
					sheet_Tong.getCell(`A${row}`).style = styleHeaderCenter
	
					let sumDoanhThuRow = 0
					let sumDoanhThuThangTruocRow = 0
	
					this.DSCuaHang.forEach((CuaHang, i) => {
						const item = this.findItem(CuaHang.CuaHangID, Ngay.Ngay_So)
						sheet_Tong.getCell(`${this.intToExcelColumn(i + 2)}${row}`).value = item?.TongDoanhThu ?? 0
						sheet_Tong.getCell(`${this.intToExcelColumn(i + 2)}${row}`).style = styleCellRight
						// sum row
						sumDoanhThuRow += Number(item?.TongDoanhThu ?? 0)
						sumDoanhThuThangTruocRow += Number(item?.TongDoanhThu_ThangTruoc ?? 0)
					})
					// KHACH CK
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 2)}${row}`).value = Ngay.TongCK ?? 0
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 2)}${row}`).style = styleCellRight
					// TONG
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 3)}${row}`).value = (sumDoanhThuRow + Ngay.TongCK) ?? 0
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 3)}${row}`).style = styleCellRight
					// QT BIDV
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 4)}${row}`).value = Ngay.QT_BIDV ?? 0
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 4)}${row}`).style = styleCellRight
					// QT TECH
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 5)}${row}`).value = Ngay.QT_TECH ?? 0
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 5)}${row}`).style = styleCellRight
					// QT VP
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 6)}${row}`).value = Ngay.QT_VP ?? 0
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 6)}${row}`).style = styleCellRight
					// DU TRU DOANH THU
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 7)}${row}`).value = ''
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 7)}${row}`).style = styleCellRight
					// DOANH THU THANG TRUOC
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 8)}${row}`).value = sumDoanhThuThangTruocRow ?? 0
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 8)}${row}`).style = styleCellRight
					// 
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 9)}${row}`).value = ''
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 9)}${row}`).style = styleCellRight
					// CHENH LECH
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 10)}${row}`).value = Number(sumDoanhThuRow - sumDoanhThuThangTruocRow)
					sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 10)}${row}`).style = styleCellRight
	
					totalDoanhThuRow += Number((sumDoanhThuRow + Ngay.TongCK) ?? 0)
					totalDoanhThuThangTruocRow += Number(sumDoanhThuThangTruocRow ?? 0)
					totalChuyenKhoan += Number(Ngay.TongCK ?? 0)
					totalQT_BIDV += Number(Ngay.QT_BIDV ?? 0)
					totalQT_TECH += Number(Ngay.QT_TECH ?? 0)
					totalQT_VP += Number(Ngay.QT_VP ?? 0)
					row += 1
				})
				// row TONG
				sheet_Tong.getCell(`A${row}`).value = "TỔNG"
				sheet_Tong.getCell(`A${row}`).style = styleHeaderCenter
				this.DSCuaHang.forEach((CuaHang, index) => {
					const value = this.getTotalByCuaHangID(CuaHang.CuaHangID)
					sheet_Tong.getCell(`${this.intToExcelColumn(index + 2)}${row}`).value = value
					sheet_Tong.getCell(`${this.intToExcelColumn(index + 2)}${row}`).style = styleCellRight
				})
				// KHACH CK
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 2)}${row}`).value = totalChuyenKhoan
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 2)}${row}`).style = styleCellRight
				// TONG
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 3)}${row}`).value = totalDoanhThuRow ?? 0
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 3)}${row}`).style = styleCellRight
				// QT BIDV
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 4)}${row}`).value = totalQT_BIDV
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 4)}${row}`).style = styleCellRight
				// QT TECH
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 5)}${row}`).value = totalQT_TECH
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 5)}${row}`).style = styleCellRight
				// QT VP
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 6)}${row}`).value = totalQT_VP
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 6)}${row}`).style = styleCellRight
				// DU TRU DOANH THU
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 7)}${row}`).value = ''
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 7)}${row}`).style = styleCellRight
				// DOANH THU THANG TRUOC
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 8)}${row}`).value = totalDoanhThuThangTruocRow ?? 0
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 8)}${row}`).style = styleCellRight
				//
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 9)}${row}`).value = ''
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 9)}${row}`).style = styleCellRight
				// CHENH LECH
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 10)}${row}`).value = Number(totalDoanhThuRow - totalDoanhThuThangTruocRow)
				sheet_Tong.getCell(`${this.intToExcelColumn(CuaHangLength + 10)}${row}`).style = styleCellRight
	
				// BEIGN PROCESS SHEET DETAIL TM
				sheet_TM.mergeCells(`A1:A2`);
				sheet_TM.getCell("A1").value = "NGÀY"
				sheet_TM.getCell("A1").style = styleHeaderCenter
	
				let beginColNum = 2
				let endColNum = 0
				// HEADER
				this.DataExportDetail.forEach((CuaHang, index) => {
					const baseCaArray = CuaHang.baseCaArray
					const CaLength = baseCaArray.length
					endColNum = beginColNum + CaLength - 1
					// Tên cửa hàng
					sheet_TM.mergeCells(`${this.intToExcelColumn(beginColNum)}1:${this.intToExcelColumn(endColNum)}1`);
					sheet_TM.getCell(`${this.intToExcelColumn(beginColNum)}1`).value = CuaHang.TenCuaHang
					sheet_TM.getCell(`${this.intToExcelColumn(beginColNum)}1`).style = styleHeaderCenter
					// Ca
					baseCaArray.forEach((Ca, index) => {
						sheet_TM.getCell(`${this.intToExcelColumn(beginColNum + index)}2`).value = this.caMap[Ca]
						sheet_TM.getCell(`${this.intToExcelColumn(beginColNum + index)}2`).style = styleHeaderCenter
					})
					beginColNum += CaLength
					// Tổng
					sheet_TM.mergeCells(`${this.intToExcelColumn(beginColNum)}1:${this.intToExcelColumn(beginColNum)}2`);
					sheet_TM.getCell(`${this.intToExcelColumn(beginColNum)}1`).value = 'Tổng'
					sheet_TM.getCell(`${this.intToExcelColumn(beginColNum)}1`).style = styleHeaderCenter
					beginColNum += 1
				})
				sheet_TM.mergeCells(`${this.intToExcelColumn(beginColNum)}1:${this.intToExcelColumn(beginColNum)}2`);
				sheet_TM.getCell(`${this.intToExcelColumn(beginColNum)}1`).value = 'TỔNG'
				sheet_TM.getCell(`${this.intToExcelColumn(beginColNum)}1`).style = styleHeaderCenter
				// MAIN DETAIL
				row = 3
				this.DSNgay.forEach((Ngay, index) => {
					let col = 2
					sheet_TM.getCell(`A${row}`).value = Ngay.Ngay_So
					sheet_TM.getCell(`A${row}`).style = styleHeaderCenter
					let sumRow = 0
					this.DataExportDetail.forEach((CuaHang, i) => {
						let sumCuaHang = 0
						const baseCaArray = CuaHang.baseCaArray
						baseCaArray.forEach((Ca, j) => {
							const item = this.findItemSheetDetail(CuaHang.CuaHangID, Ngay.Ngay_So, Ca)
							sheet_TM.getCell(`${this.intToExcelColumn(col + j)}${row}`).value = item?.DoiSoat_TM ?? 0
							sheet_TM.getCell(`${this.intToExcelColumn(col + j)}${row}`).style = styleCellRight
							sumCuaHang += Number(item?.DoiSoat_TM ?? 0)
						})
						col += baseCaArray.length
						sheet_TM.getCell(`${this.intToExcelColumn(col)}${row}`).value = sumCuaHang ?? 0
						sheet_TM.getCell(`${this.intToExcelColumn(col)}${row}`).style = styleCellRight
						sumRow += sumCuaHang
						col += 1
					})
					sheet_TM.getCell(`${this.intToExcelColumn(col)}${row}`).value = sumRow ?? 0
					sheet_TM.getCell(`${this.intToExcelColumn(col)}${row}`).style = styleCellRight
					row += 1
				})
				// row TONG
				sheet_TM.getCell(`A${row}`).value = "TỔNG"
				sheet_TM.getCell(`A${row}`).style = styleHeaderCenter
				let col = 2
				let sumRow = 0
				this.DataExportDetail.forEach((CuaHang, i) => {
					let sumCuaHang = 0
					const baseCaArray = CuaHang.baseCaArray
					baseCaArray.forEach((Ca, j) => {
						const value = this.getTotalTMByCuaHangIDAndCa(CuaHang.CuaHangID, Ca, 'DoiSoat_TM')
						sheet_TM.getCell(`${this.intToExcelColumn(col + j)}${row}`).value = value ?? 0
						sheet_TM.getCell(`${this.intToExcelColumn(col + j)}${row}`).style = styleCellRight
						sumCuaHang += Number(value ?? 0)
					})
					col += baseCaArray.length
					sheet_TM.getCell(`${this.intToExcelColumn(col)}${row}`).value = sumCuaHang ?? 0
					sheet_TM.getCell(`${this.intToExcelColumn(col)}${row}`).style = styleCellRight
					sumRow += sumCuaHang
					col += 1
				})
				sheet_TM.getCell(`${this.intToExcelColumn(col)}${row}`).value = sumRow ?? 0
				sheet_TM.getCell(`${this.intToExcelColumn(col)}${row}`).style = styleCellRight
				// END PROCESS SHEET DETAIL
	
				// BEIGN PROCESS SHEET DETAIL QT, FOODY, GRAB, XSM
				sheet_QT.code = 'QT';
				sheet_QT.sum = 0
				sheet_FOODY.code = 'SPF';
				sheet_FOODY.sum = 0
				sheet_GRAB.code = 'GRAB';
				sheet_GRAB.sum = 0
				sheet_XSM.code = 'XSM';
				sheet_XSM.sum = 0
				const sheets = [sheet_QT, sheet_FOODY, sheet_GRAB, sheet_XSM];
	
				sheets.forEach((sheet) => {
					sheet.mergeCells('A1:A2');
					sheet.getCell('A1').value = 'NGÀY';
					sheet.getCell('A1').style = styleHeaderCenter;
				});
				beginColNum = 2
				endColNum = 0
				// HEADER
				this.DataExportDetail.forEach((CuaHang, index) => {
					endColNum = beginColNum + 1
					sheets.forEach((sheet) => {
						sheet.mergeCells(`${this.intToExcelColumn(beginColNum)}1:${this.intToExcelColumn(endColNum)}1`);
						sheet.getCell(`${this.intToExcelColumn(beginColNum)}1`).value = CuaHang.TenCuaHang
						sheet.getCell(`${this.intToExcelColumn(beginColNum)}1`).style = styleHeaderCenter
	
						sheet.getCell(`${this.intToExcelColumn(beginColNum)}2`).value = 'TỔNG'
						sheet.getCell(`${this.intToExcelColumn(beginColNum)}2`).style = styleHeaderCenter
	
						sheet.getCell(`${this.intToExcelColumn(beginColNum + 1)}2`).value = 'TỔNG ĐÃ CHIẾT KHẤU'
						sheet.getCell(`${this.intToExcelColumn(beginColNum + 1)}2`).style = styleHeaderCenter
					})
					beginColNum += 2
				})
	
				sheets.forEach((sheet) => {
					sheet.mergeCells(`${this.intToExcelColumn(beginColNum)}1:${this.intToExcelColumn(beginColNum)}2`);
					sheet.getCell(`${this.intToExcelColumn(beginColNum)}1`).value = 'TỔNG'
					sheet.getCell(`${this.intToExcelColumn(beginColNum)}1`).style = styleHeaderCenter
				});
	
				// MAIN DETAIL
				row = 3
				this.DSNgay.forEach((Ngay, index) => {
					let col = 2
					sheets.forEach((sheet) => {
						sheet.getCell(`A${row}`).value = Ngay.Ngay_So
						sheet.getCell(`A${row}`).style = styleHeaderCenter
					});
					this.DataExportDetail.forEach((CuaHang, i) => {
						const baseCaArray = CuaHang.baseCaArray
						sheets.forEach((sheet) => {
							let Tong = 0
							let TongDaChietKhau = 0
							const prefix = sheet.code
							baseCaArray.forEach((Ca, j) => {
								const item = this.findItemSheetDetail(CuaHang.CuaHangID, Ngay.Ngay_So, Ca)
								Tong += Number(item[`DoiSoat_${prefix}`] ?? 0)
								TongDaChietKhau += Number(item[`DoiSoat_${prefix}_ChietKhau`] ?? 0)
							})
							// TONG
							sheet.getCell(`${this.intToExcelColumn(col)}${row}`).value = Tong ?? 0
							sheet.getCell(`${this.intToExcelColumn(col)}${row}`).style = styleCellRight
							// TONG DA CHIET KHAU
							sheet.getCell(`${this.intToExcelColumn(col + 1)}${row}`).value = TongDaChietKhau ?? 0
							sheet.getCell(`${this.intToExcelColumn(col + 1)}${row}`).style = styleCellRight
							sheet.sum += TongDaChietKhau
						});
						col += 2
					})
					sheets.forEach((sheet) => {
						sheet.getCell(`${this.intToExcelColumn(col)}${row}`).value = Number(sheet.sum) ?? 0
						sheet.getCell(`${this.intToExcelColumn(col)}${row}`).style = styleCellRight
						sheet.sum = 0
					});
					row += 1
				})
				// row TONG
				sheets.forEach((sheet) => {
					sheet.getCell(`A${row}`).value = "TỔNG"
					sheet.getCell(`A${row}`).style = styleHeaderCenter
					let col = 2
					let sumRow = 0
					this.DataExportDetail.forEach((CuaHang, i) => {
						const Tong = this.getTotalByCuaHangIDAndPrefix(CuaHang.CuaHangID, `DoiSoat_${sheet.code}`)
						const TongDaChietKhau = this.getTotalByCuaHangIDAndPrefix(CuaHang.CuaHangID, `DoiSoat_${sheet.code}_ChietKhau`)
						// TONG
						sheet.getCell(`${this.intToExcelColumn(col)}${row}`).value = Tong ?? 0
						sheet.getCell(`${this.intToExcelColumn(col)}${row}`).style = styleCellRight
						// TongDaChietKhau
						sheet.getCell(`${this.intToExcelColumn(col + 1)}${row}`).value = TongDaChietKhau ?? 0
						sheet.getCell(`${this.intToExcelColumn(col + 1)}${row}`).style = styleCellRight
						sumRow += TongDaChietKhau
						col += 2
					})
					sheet.getCell(`${this.intToExcelColumn(col)}${row}`).value = sumRow ?? 0
					sheet.getCell(`${this.intToExcelColumn(col)}${row}`).style = styleCellRight
				});
	
				// END PROCESS SHEET DETAIL QT, FOODY, GRAB, XSM
				// Export excel
				this.autoWidth(sheet_Tong);
				this.autoWidth(sheet_TM);
				this.autoWidth(sheet_QT);
				this.autoWidth(sheet_FOODY);
				this.autoWidth(sheet_GRAB);
				this.autoWidth(sheet_XSM);
				const buffer = await workbook.xlsx.writeBuffer();
				saveAs(new Blob([buffer]), "Excel đối soát.xlsx");
			}
	
		},
	}
</script>