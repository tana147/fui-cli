<template>
	<div>
		<v-row class="page-navigation">
			<v-col cols="4">
				<v-select label="Cửa hàng" outlined dense v-model="vueData.CuaHangID" :items="vueData.DSCuaHang"
					item-value="CuaHangID" item-text="TenCuaHang" hide-details />
			</v-col>

			<v-col cols="2">
				<f-date label="Từ ngày" outlined dense v-model="TuNgay" :date-add="0" hide-details />
			</v-col>
			<v-col cols="2">
				<f-date label="Đến ngày" outlined dense v-model="DenNgay" :date-add="0" hide-details />
			</v-col>
			<v-col cols="2">
				<v-btn color="primary" elevation="0" @click="getReport"><v-icon left>mdi-filter</v-icon>Tìm</v-btn>
			</v-col>

		</v-row>

		<v-row class="row-report-summary page-navigation">
			<v-col cols="2">
				Tổng doanh thu <br /> 
				<b class="red--text">{{ formatCurrency(tongDoanhThu) }}</b>
			</v-col>
			<v-col cols="2">
				Tổng giao dịch <br /> 
				<b class="red--text">{{ vueData.DataReport.length  }}</b>
			</v-col>
			<v-col cols="2">
				Số tiền giao dịch trung bình <br /> 
				<b class="red--text">{{ formatCurrency(tienTrungBinh) }}</b>
			</v-col>
			<v-col cols="2">
				Tổng số đơn hủy<br /> 
				<b class="red--text">{{ tongSoLuongHuy }}</b>
			</v-col>
			<v-col cols="2">
				Tổng tiền hủy <br /> 
				<b class="red--text">{{ formatCurrency(tongTienHuy) }}</b>
			</v-col>
			<v-col cols="2">
				Tỉ lệ hủy đơn <br /> 
				<b class="red--text">{{ tiLeHuy }}%</b>
			</v-col>
		</v-row>

		<v-row class="page-navigation">
			<v-col cols="12">
				<v-card small elevation="0" class="pa-0">
					<v-card-text class="pa-1">
						<div>
							<uc-chart :options="options" :key="chartKey"></uc-chart>
						</div>
					</v-card-text>
				</v-card>
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
			return {
				PhanHieuID: 0,
				KhuVucID: 0,
				HinhThucThanhToan: 0,
				HinhThucThoiGian: 1, // Mặc định theo giờ
				Ngay: moment().format("YYYY-MM-DD"),
				TuNgay: moment().startOf("month").format("YYYY-MM-DD"),
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
				chartKey: 0, // Thêm key để force rerender
				options: {
					chart: {
						height: 300,
						type: 'line',
						width: '100%',
						stacked: false,
						toolbar: {
							show: false
						},
						parentHeightOffset: 0,
						sparkline: {
							enabled: false
						}
					},
					grid: {
						padding: {
							left: 20,
							right: 20
						}
					},
					series: [
						{
							name: "Doanh thu",
							type: "line",
							data: [],
							strokeWidth: 2,
							markers: { size: 4 },
							yAxisIndex: 0
						},
						{
							name: "Số lượng",
							type: "line",
							data: [],
							strokeWidth: 2,
							markers: { size: 4 },
							yAxisIndex: 1
						},
						{
							name: "Tiền hủy",
							type: "line",
							data: [],
							strokeWidth: 2,
							markers: { size: 4 },
							yAxisIndex: 0
						},
						{
							name: "Số lượng hủy",
							type: "line",
							data: [],
							strokeWidth: 2,
							markers: { size: 4 },
							yAxisIndex: 1
						}
					],
					stroke: {
						width: [2, 2],
						dashArray: [0, 3, 0, 3],
						curve: 'straight'
					},
					xaxis: {
						categories: [],
						labels: {
							rotate: -45,
							rotateAlways: true,
							offsetX: 2,
							offsetY: 5,
							style: {
								fontSize: '11px',
								fontWeight: 400,
								cssClass: 'apexcharts-xaxis-label'
							},
							trim: false,
							minHeight: 50
						},
						axisBorder: {
							show: true
						},
						axisTicks: {
							show: true,
							height: 6
						},
						tickPlacement: 'on',
						tickAmount: 10
					},
					yaxis: [
						{
							labels: {
								formatter: val => val.toLocaleString("vi-VN") + ' VNĐ'
							},
							tickAmount: 6,
							forceNiceScale: true,
							min: 0,
							decimalsInFloat: 0,
							seriesName: ['Doanh Thu', 'Tiền hủy']
						},
						{
							opposite: true,
							labels: {
								formatter: val => Math.round(val).toLocaleString("vi-VN") + ' đơn'
							},
							tickAmount: 6,
							forceNiceScale: true,
							min: 0,
							decimalsInFloat: 0,
							seriesName: ['Số Lượng', 'Số Lượng hủy']
						}
					],
					dataLabels: {
						enabled: false
					},
					colors: [
						'#2E7D32', // Doanh thu - Deep green
						'#1976D2', // Số đơn - Blue
						'#D32F2F', // Tiền hủy - Red
						'#FF6D00'  // Số đơn hủy - Orange
					],
					tooltip: {
						shared: true,
						intersect: false,
						y: [{
							formatter: function (value) {
								return value.toLocaleString('vi-VN') + ' VNĐ'
							}
						},
						{
							formatter: function (value) {
								return value.toLocaleString('vi-VN') + ' đơn'
							}
						},
						{
							formatter: function (value) {
								return value.toLocaleString('vi-VN') + ' VNĐ'
							}
						},
						{
							formatter: function (value) {
								return value.toLocaleString('vi-VN') + ' đơn hủy'
							}
						}]
					}
				},
				tongDoanhThu: 0,
				tongSoLuong: 0,
				tongSoLuongHuy: 0,
				tongTienHuy: 0,
				tienTrungBinh: 0,
				tiLeHuy: 0,
				percentDoanhThu: 0,
				percentSoLuong: 0,
				percentSoLuongHuy: 0,
				percentTienHuy: 0,
				percentTrungBinh: 0,
				percentTiLeHuy: 0,
				previousData: null,
				prevTuNgay: null,
				prevDenNgay: null
			}
		},
		computed: {
			comparisonText() {
				if (!this.prevTuNgay || !this.prevDenNgay) return '';
				const daysDiff = moment(this.TuNgay).diff(moment(this.prevTuNgay), 'days');
				return `${daysDiff} ngày trước (${moment(this.prevTuNgay).format('DD/MM')} - ${moment(this.prevDenNgay).format('DD/MM')})`;
			}
		},
		mounted() {
		},
		methods: {
			getReport() {
				// Store current dates as previous before updating
				this.prevTuNgay = this.TuNgay;
				this.prevDenNgay = this.DenNgay;

				const params = {
					CuaHangID: vueData.CuaHangID,
					TuNgay: this.TuNgay,
					DenNgay: this.DenNgay
				}
	
				ajaxCALL('/eorder/BaoCao_HoaDon_Grab_Chart_ByCuaHangId', params, (res) => {
					// Store previous values for comparison
					const prevDoanhThu = this.tongDoanhThu;
					const prevSoLuong = this.tongSoLuong;
					const prevSoLuongHuy = this.tongSoLuongHuy;
					const prevTienHuy = this.tongTienHuy;
					const prevTrungBinh = this.tienTrungBinh;
					const prevTiLeHuy = this.tiLeHuy;

					// Calculate current values
					this.tongDoanhThu = res.data.reduce((sum, item) => sum + (item.DoanhThu || 0), 0);
					this.tongSoLuong = res.data.reduce((sum, item) => sum + (item.SoLuong || 0), 0);
					this.tongSoLuongHuy = res.data.reduce((sum, item) => sum + (item.SLHuy || 0), 0);
					this.tongTienHuy = res.data.reduce((sum, item) => sum + (item.TienHuy || 0), 0);
					this.tienTrungBinh = this.tongSoLuong ? Math.round(this.tongDoanhThu / this.tongSoLuong) : 0;
					this.tiLeHuy = this.tongSoLuong ? Math.round((this.tongSoLuongHuy / (this.tongSoLuong + this.tongSoLuongHuy)) * 100) : 0;

					// Calculate percent changes
					this.percentDoanhThu = this.calculatePercentChange(this.tongDoanhThu, prevDoanhThu);
					this.percentSoLuong = this.calculatePercentChange(this.tongSoLuong, prevSoLuong);
					this.percentSoLuongHuy = this.calculatePercentChange(this.tongSoLuongHuy, prevSoLuongHuy);
					this.percentTienHuy = this.calculatePercentChange(this.tongTienHuy, prevTienHuy);
					this.percentTrungBinh = this.calculatePercentChange(this.tienTrungBinh, prevTrungBinh);
					this.percentTiLeHuy = this.calculatePercentChange(this.tiLeHuy, prevTiLeHuy);

					// Chart data processing
					const categories = res.data.map(item => {
						if (!item.Ngay) return "";
						return this.formatDaily(item.Ngay)
					})
					const doanhThu = res.data.map(item => parseFloat(item.DoanhThu) || 0)
					const tienHuy = res.data.map(item => parseFloat(item.TienHuy) || 0)
					const soLuong = res.data.map(item => parseInt(item.SoLuong) || 0)
					const soLuongHuy = res.data.map(item => parseInt(item.SLHuy) || 0)
	
					// tổng số lượng
					// tổng doanh thu
					// số tiền giao dịch trung bình
	
					const newOptions = {
						...this.options,
						xaxis: { categories },
						series: [
							{ name: "Doanh Thu", type: "line", data: doanhThu },
							{ name: "Số đơn", type: "line", data: soLuong },
							{ name: "Tiền hủy", type: "line", data: tienHuy },
							{ name: "Số đơn hủy", type: "line", data: soLuongHuy }
						]
					};
	
					this.options = newOptions
					this.chartKey++
				});

				ajaxCALL('/eorder/BaoCao_HoaDon_Grab_ByCuaHangId', params, (res) => {
					vueData.DataReport =  res.data
				});

				
			},
			formatDaily(str) {
				return moment(str).format("D/M")
			},
			formatCurrency(value) {
				return value.toLocaleString('vi-VN')
			},
			getPercentClass(value) {
				return {
					'ml-2': true,
					'green--text': value > 0,
					'red--text': value < 0
				}
			},
			
			formatPercent(value) {
				const sign = value > 0 ? '+' : '';
				return `${sign}${value.toFixed(2)}%`;
			},

			calculatePercentChange(current, previous) {
				if (!previous) return 0;
				return ((current - previous) / previous) * 100;
			},
		}
	
	}
</script>

