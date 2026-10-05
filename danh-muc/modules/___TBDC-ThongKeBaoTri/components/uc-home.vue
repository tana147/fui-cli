<template>
	<v-container fluid class="pa-4 bg-grey-lighten-4" style="min-height: 100vh;">
		<div id="report-content" class="bg-grey-lighten-4">
			<v-card class="rounded-lg elevation-1 mb-4">
				<div class="d-flex flex-wrap align-center px-4 py-3">
					<div>
						<div class="text-h6 font-weight-bold text-primary d-flex align-center">
							<v-icon start color="primary">mdi-calendar-check</v-icon>
							THỐNG KÊ KẾT QUẢ BẢO TRÌ ĐỊNH KỲ
						</div>
						<div class="text-caption text-grey">Theo dõi hiệu quả bảo trì theo kế hoạch</div>
					</div>

					<v-spacer></v-spacer>

					<div class="d-flex align-center gap-2" style="gap: 10px;">
						<v-select v-model="filter.year" :items="listYears" label="Năm" item-title="title"
							item-value="value" density="compact" variant="outlined" hide-details bg-color="white"
							@update:model-value="refreshAll">
						</v-select>

						<v-select v-model="filter.month" :items="listMonths" item-title="title" item-value="value"
							:return-object="false" label="Tháng" density="compact" variant="outlined" hide-details
							bg-color="white" style="width: 150px;" @update:model-value="refreshAll"></v-select>

						<v-autocomplete v-model="filter.maCoSo" :items="listCoSo" item-title="TenCoSo"
							item-value="MaCoSo" :return-object="false" label="Cơ sở" density="compact"
							variant="outlined" hide-details bg-color="white" style="width: 220px;"
							@update:model-value="refreshAll"></v-autocomplete>

						<v-btn color="primary" height="40" prepend-icon="mdi-refresh" @click="refreshAll"
							data-html2canvas-ignore="true" :loading="loading">
							Tải dữ liệu
						</v-btn>

						<v-btn color="red-darken-1" height="40" prepend-icon="mdi-file-pdf-box" @click="exportToPDF"
							data-html2canvas-ignore="true" :loading="pdfLoading">
							Xuất PDF
						</v-btn>

					</div>
				</div>
			</v-card>



			<div class="d-flex flex-wrap mx-n2 mb-4">

				<div class="pa-2 flex-grow-1" style="flex-basis: 200px; min-width: 0;">
					<v-card class="fill-height rounded-lg elevation-2 pa-4 d-flex align-center"
						style="border-left: 4px solid #1976D2;">
						<div class="mr-3">
							<v-icon color="blue-darken-2" size="36">mdi-clipboard-check</v-icon>
						</div>
						<div>
							<div class="text-caption text-grey font-weight-bold text-uppercase">TS ĐÃ KIỂM TRA</div>
							<div class="d-flex align-baseline">
								<span class="text-h5 font-weight-black text-primary mr-2">{{
									formatNumber(stats.TongTSDaKiemTra)
								}}</span>
								<span class="text-caption font-weight-bold text-blue-grey">
									({{ calculatePercent(stats.TongTSDaKiemTra, stats.TongSoDot * 100) }}%) </span>
							</div>
							<div class="text-caption text-grey">Trong {{ formatNumber(stats.TongSoDot) }} đợt</div>
						</div>
					</v-card>
				</div>

				<div class="pa-2 flex-grow-1" style="flex-basis: 200px; min-width: 0;">
					<v-card class="fill-height rounded-lg elevation-2 pa-4 d-flex align-center"
						style="border-left: 4px solid #43A047;">
						<div class="mr-3">
							<v-icon color="green-darken-2" size="36">mdi-package-variant-closed-check</v-icon>
						</div>
						<div>
							<div class="text-caption text-grey font-weight-bold text-uppercase">TỶ LỆ HOẠT ĐỘNG TỐT
							</div>
							<div class="d-flex align-baseline">
								<span class="text-h5 font-weight-black text-green-darken-2 mr-2">{{ stats.TyLeSuckhoe ||
									0
								}}%</span>
								<span class="text-caption font-weight-bold text-green">
									({{ formatNumber(stats.TongTSDaKiemTra - stats.TongSoHong) }} Tốt)
								</span>
							</div>
						</div>
					</v-card>
				</div>

				<div class="pa-2 flex-grow-1" style="flex-basis: 200px; min-width: 0;">
					<v-card class="fill-height rounded-lg elevation-2 pa-4 d-flex align-center"
						style="border-left: 4px solid #EF5350;">
						<div class="mr-3">
							<v-icon color="red-darken-2" size="36">mdi-alert-circle</v-icon>
						</div>
						<div>
							<div class="text-caption text-grey font-weight-bold text-uppercase">PHÁT HIỆN HỎNG</div>
							<div class="d-flex align-baseline">
								<span class="text-h5 font-weight-black text-red mr-2">{{ formatNumber(stats.TongSoHong)
								}}</span>
								<span class="text-caption font-weight-bold text-red-lighten-1">
									({{ calculatePercent(stats.TongSoHong, stats.TongTSDaKiemTra) }}%)
								</span>
							</div>
						</div>
					</v-card>
				</div>

				<div class="pa-2 flex-grow-1" style="flex-basis: 200px; min-width: 0;">
					<v-card class="fill-height rounded-lg elevation-2 pa-4 d-flex align-center"
						style="border-left: 4px solid #FFA000;">
						<div class="mr-3">
							<v-icon color="orange-darken-3" size="36">mdi-cash-multiple</v-icon>
						</div>
						<div>
							<div class="text-caption text-grey font-weight-bold text-uppercase">CHI PHÍ</div>
							<div class="text-h5 font-weight-black text-orange-darken-3">{{
								formatCurrencyShort(stats.TongChiPhi) }}
							</div>
						</div>
					</v-card>
				</div>

				<div class="pa-2 flex-grow-1" style="flex-basis: 200px; min-width: 0;">
					<v-card class="fill-height rounded-lg elevation-2 pa-4" style="border-left: 4px solid #9C27B0;">
						<div class="d-flex flex-column h-100 justify-center">
							<div class="text-caption text-grey font-weight-bold mb-1 text-uppercase">NGUỒN LỰC</div>
							<div class="d-flex justify-space-between mb-1"><span class="text-caption">Nội
									bộ:</span><span class="font-weight-bold text-blue">{{ stats.SoLuotNoiBo || 0
									}}</span></div>
							<div class="d-flex justify-space-between"><span class="text-caption">Thuê ngoài:</span><span
									class="font-weight-bold text-purple">{{ stats.SoLuotDoiTac || 0 }}</span></div>
						</div>
					</v-card>
				</div>
			</div>

			<v-row class="mt-2">
				<v-col cols="12" md="4">
					<v-card class="fill-height rounded-lg elevation-2 d-flex flex-column">
						<v-toolbar density="compact" color="white" class="border-b px-2">
							<v-icon color="red" class="mr-2">mdi-calendar-clock</v-icon>
							<v-toolbar-title class="text-subtitle-2 font-weight-bold text-red">LỊCH SẮP ĐẾN HẠN (30
								NGÀY)
							</v-toolbar-title>
						</v-toolbar>
						<v-list density="compact" class="pa-0 flex-grow-1" style="max-height: 300px; overflow-y: auto;">
							<template v-if="upcomingList.length > 0">
								<v-list-item v-for="(item, i) in upcomingList" :key="i" lines="two">
									<template v-slot:prepend>
										<v-avatar color="red-lighten-5" class="text-red font-weight-bold rounded"
											size="36">
											{{ item.SoNgayConLai }}
										</v-avatar>
									</template>
									<v-list-item-title class="font-weight-bold text-body-2">{{ item.TenLichBaoTri }}
									</v-list-item-title>
									<v-list-item-subtitle class="text-caption">
										Ngày: <span class="text-primary">{{ formatDate(item.NgayDuKien) }}</span> - SL:
										<b>{{ item.SoLuongTaiSan }}</b> TS
									</v-list-item-subtitle>
								</v-list-item>
							</template>
							<div v-else class="text-center pa-10 text-grey">
								<v-icon class="mb-2">mdi-calendar-check</v-icon>
								<div>Không có lịch bảo trì sắp tới</div>
							</div>
						</v-list>
					</v-card>
				</v-col>

				<v-col cols="12" md="4">
					<v-card class="fill-height rounded-lg elevation-2 d-flex flex-column">
						<v-toolbar density="compact" color="white" class="border-b px-2">
							<v-icon color="green" class="mr-2">mdi-chart-donut</v-icon>
							<v-toolbar-title class="text-subtitle-2 font-weight-bold text-green">TỶ LỆ HOÀN THÀNH
							</v-toolbar-title>
						</v-toolbar>
						<v-card-text class="pa-2 flex-grow-1 d-flex align-center justify-center">
							<uc-chart-tien-do :data="dataTienDo" style="width: 100%"></uc-chart-tien-do>
						</v-card-text>
					</v-card>
				</v-col>

				<v-col cols="12" md="4">
					<v-card class="fill-height rounded-lg elevation-2 d-flex flex-column">
						<v-toolbar density="compact" color="white" class="border-b px-2">
							<v-icon color="blue" class="mr-2">mdi-account-star</v-icon>
							<v-toolbar-title class="text-subtitle-2 font-weight-bold text-blue">TOP NHÂN VIÊN TÍCH CỰC
							</v-toolbar-title>
						</v-toolbar>
						<v-card-text class="pa-2 flex-grow-1 d-flex align-center justify-center">
							<uc-chart-nhan-vien :items="filteredNhanVien" style="width: 100%"></uc-chart-nhan-vien>
						</v-card-text>
					</v-card>
				</v-col>
			</v-row>

			<v-row class="mt-4">
				<v-col cols="12">
					<v-card class="fill-height rounded-lg elevation-2 d-flex flex-column">
						<v-toolbar density="compact" color="white" class="border-b px-2">
							<v-icon color="blue" class="mr-2">mdi-account-details</v-icon>
							<v-toolbar-title class="text-subtitle-2 font-weight-bold text-blue">BÁO CÁO CHI TIẾT HIỆU
								SUẤT
								NHÂN VIÊN KỸ THUẬT</v-toolbar-title>
							<v-spacer></v-spacer>
							<v-switch v-model="reportOptions.showTop10" hide-details inset label="Chỉ hiển thị Top 10"
								density="compact" color="primary" class="mr-2 pt-0"></v-switch>
						</v-toolbar>
						<v-card-text class="pa-2 flex-grow-1">
							<v-data-table :headers="headersNhanVien" :items="filteredNhanVien" density="compact"
								hide-default-footer :items-per-page="50" style="font-size: 13px; max-height: 400px;"
								class="elevation-1">
								<template #item.HoTen="{ item }">
									<span>{{ item.HoTen }}</span>
								</template>
								<template #item.TongSoLuong="{ item }">
									<span>{{ item.TongSoLuong }}</span>
								</template>
								<template #item.ThoiGianTrungBinhGio="{ item }">
									{{ item.ThoiGianTrungBinhGio }} giờ
								</template>
								<template #item.SoLanTreHan="{ item }">
									<span :class="item.SoLanTreHan > 0 ? 'text-red font-weight-bold' : 'text-grey'">
										{{ item.SoLanTreHan }}</span>
								</template>
								<template #item.actions="{ item }">
									<v-btn icon="mdi-eye" size="x-small" variant="text" color="primary"
										@click="showEmployeeDetail(item)"></v-btn>
								</template>
							</v-data-table>
						</v-card-text>
					</v-card>
				</v-col>
			</v-row>


			<v-divider class="my-4"></v-divider>
			<div class="text-subtitle-1 font-weight-bold text-primary mb-2 d-flex align-center mt-6">
				<v-icon start>mdi-shape</v-icon> PHÂN TÍCH THEO LOẠI DANH MỤC
			</div>
			<v-row class="mb-4">
				<v-col cols="12" md="5">
					<v-card class="fill-height rounded-lg elevation-2 d-flex flex-column">
						<v-toolbar density="compact" color="white" class="border-b px-2">
							<v-toolbar-title class="text-subtitle-2 font-weight-bold text-blue">BIỂU ĐỒ TOP LOẠI DANH
								MỤC
								HỎNG
							</v-toolbar-title>
						</v-toolbar>
						<v-card-text class="flex-grow-1 pa-2">
							<uc-chart-loai :items="dataLoai.chart" :loading="loading" />
						</v-card-text>
					</v-card>
				</v-col>
				<v-col cols="12" md="7">
					<v-card class="fill-height rounded-lg elevation-2 d-flex flex-column">
						<v-toolbar density="compact" color="white" class="border-b px-2">
							<v-toolbar-title class="text-subtitle-2 font-weight-bold">DANH SÁCH (HIỂN THỊ LOẠI)
							</v-toolbar-title>
						</v-toolbar>
						<v-data-table :headers="headersLoai" :items="dataLoai.list" density="compact"
							class="flex-grow-1" fixed-header height="350" items-per-page="50">
							<template #item.TenTaiSan="{ item }">
								<div>
									<div class="font-weight-bold text-body-2">{{ item.TenTaiSan }}</div>
									<div class="text-caption text-grey">{{ item.MaVach }}</div>
								</div>
							</template>
							<template #item.ChiPhi="{ item }"><span class="text-red font-weight-bold">{{ item.ChiPhi > 0
								?
								formatCurrency(item.ChiPhi) : '-' }}</span></template>
						</v-data-table>
					</v-card>
				</v-col>
			</v-row>

			<v-divider class="my-4"></v-divider>
			<div class="text-subtitle-1 font-weight-bold text-indigo mb-2 d-flex align-center">
				<v-icon start>mdi-tag-multiple</v-icon> PHÂN TÍCH THEO DANH MỤC CHI TIẾT
			</div>
			<v-row class="mb-4">
				<v-col cols="12" md="5">
					<v-card class="fill-height rounded-lg elevation-2 d-flex flex-column">
						<v-toolbar density="compact" color="white" class="border-b px-2">
							<v-toolbar-title class="text-subtitle-2 font-weight-bold text-orange">BIỂU ĐỒ TOP DANH MỤC
								HỎNG
							</v-toolbar-title>
						</v-toolbar>
						<v-card-text class="flex-grow-1 pa-2">
							<uc-chart-danh-muc :items="dataDanhMuc.chart" :loading="loading" />
						</v-card-text>
					</v-card>
				</v-col>
				<v-col cols="12" md="7">
					<v-card class="fill-height rounded-lg elevation-2 d-flex flex-column">
						<v-toolbar density="compact" color="white" class="border-b px-2">
							<v-toolbar-title class="text-subtitle-2 font-weight-bold">DANH SÁCH CHI
								TIẾT</v-toolbar-title>
						</v-toolbar>
						<v-data-table :headers="headersDanhMuc" :items="dataDanhMuc.list" density="compact"
							class="flex-grow-1" fixed-header height="350" items-per-page="50">
							<template #item.TenTaiSan="{ item }">
								<div>
									<div class="font-weight-bold text-body-2">{{ item.TenTaiSan }}</div>
									<div class="text-caption text-grey">{{ item.MaVach }}</div>
								</div>
							</template>
							<template #item.ChiPhi="{ item }"><span class="text-red font-weight-bold">{{ item.ChiPhi > 0
								?
								formatCurrency(item.ChiPhi) : '-' }}</span></template>
						</v-data-table>
					</v-card>
				</v-col>
			</v-row>


			<v-dialog v-model="dialogEmployeeDetail" max-width="900px">
				<v-card class="rounded-lg" style="height: 600px; display: flex; flex-direction: column;">
					<v-toolbar density="compact" class="pa-2">
						<v-toolbar-title class="text-primary text-subtitle-1 font-weight-bold" style="flex: 1;">
							Nhân viên: {{ currentEmployeeName }}
						</v-toolbar-title>

						<v-autocomplete v-model="filterLocationDetail" :items="locationListDetail"
							label="Lọc theo vị trí" density="compact" variant="solo-filled" hide-details class="mr-2"
							style="width: 250px; max-width: 40%;" clearable></v-autocomplete>

						<v-btn icon="mdi-close" variant="text" @click="dialogEmployeeDetail = false"></v-btn>
					</v-toolbar>
					<v-divider></v-divider>

					<v-card-text class="pa-0 flex-grow-1"
						style="overflow: hidden; display: flex; flex-direction: column;">
						<div class="px-4 py-2 bg-grey-lighten-4 text-caption d-flex justify-space-between align-center">
							<span>
								<b>{{ filteredDetailedAssets.length }}</b> tài sản
								<span v-if="filterLocationDetail"> tại <b>{{ filterLocationDetail }}</b></span>
							</span>
						</div>

						<v-data-table :headers="headersDetailAssets" :items="filteredDetailedAssets" density="compact"
							fixed-header class="flex-grow-1" :loading="loadingDetail" item-value="MaVach"
							style="font-size: 13px;">
							<template #loading>
								<v-skeleton-loader type="table-row@5"></v-skeleton-loader>
							</template>

							<template #item.MaVach="{ item }">
								<span>{{ item.MaVach }}</span>
							</template>

							<template #item.TenViTriPhong="{ item }">
								<span>
									{{ item.TenViTriPhong }}
								</span>
							</template>
						</v-data-table>

						<div v-if="!loadingDetail && detailedAssetList.length === 0" class="text-center pa-8 text-grey">
							Không tìm thấy tài sản chi tiết đã bảo trì trong đợt này.
						</div>
					</v-card-text>
				</v-card>
			</v-dialog>

		</div>


	</v-container>
</template>

<script>
export default {
	name: "ThongKeBaoTriPage",
	data() {
		return {
			loading: false,
			pdfLoading: false,
			search: '',
			filter: { year: 2026, month: 0, maCoSo: 0 },

			listYears: [2026, 2025, 2024],
			listMonthsFull: [
				{ title: 'Cả năm', value: 0 },
				{ title: 'Tháng 1', value: 1 },
				{ title: 'Tháng 2', value: 2 },
				{ title: 'Tháng 3', value: 3 },
				{ title: 'Tháng 4', value: 4 },
				{ title: 'Tháng 5', value: 5 },
				{ title: 'Tháng 6', value: 6 },
				{ title: 'Tháng 7', value: 7 },
				{ title: 'Tháng 8', value: 8 },
				{ title: 'Tháng 9', value: 9 },
				{ title: 'Tháng 10', value: 10 },
				{ title: 'Tháng 11', value: 11 },
				{ title: 'Tháng 12', value: 12 }
			],
			// listMonths: [
			// 	{ title: 'Cả năm', value: 0 }, { title: 'Tháng 1', value: 1 }, { title: 'Tháng 2', value: 2 }, { title: 'Tháng 3', value: 3 }, { title: 'Tháng 4', value: 4 }, { title: 'Tháng 5', value: 5 }, { title: 'Tháng 6', value: 6 }, { title: 'Tháng 7', value: 7 }, { title: 'Tháng 8', value: 8 }, { title: 'Tháng 9', value: 9 }, { title: 'Tháng 10', value: 10 }, { title: 'Tháng 11', value: 11 }, { title: 'Tháng 12', value: 12 }
			// ],
			listCoSo: [],

			stats: { TongSoDot: 0, TongTSDaKiemTra: 0, TongSoHong: 0, TyLeSuckhoe: 0, TongChiPhi: 0, SoLuotNoiBo: 0, SoLuotDoiTac: 0 },

			dataTienDo: { DungHan: 0, TreHan: 0, ChuaThucHien: 0 },
			dataNhanVien: [],
			upcomingList: [],

			dialogEmployeeDetail: false,
			currentEmployeeAssets: [],
			currentEmployeeName: '',
			loadingDetail: false,
			detailedAssetList: [],
			filterLocationDetail: null,

			dataLoai: { chart: [], list: [] },
			dataDanhMuc: { chart: [], list: [] },

			reportOptions: { showTop10: false, },

			// Headers
			headersNhanVien: [
				{ title: 'Mã/Tên NV', key: 'HoTen' },
				{ title: 'Số lượng tài sản bảo trì', key: 'TongSoLuong' },
				{ title: 'Thời gian bảo trì (Giờ)', key: 'ThoiGianTrungBinhGio' },
				{ title: 'Trễ hạn (lần)', key: 'SoLanTreHan', },
				{ title: 'Chi phí', key: 'TongGiaTri', align: 'end' },
				{ title: 'Chi tiết', key: 'actions', align: 'center', sortable: false },
			],
			headersLoai: [
				{ title: 'Tài sản', key: 'TenTaiSan' },
				{ title: 'Loại', key: 'TenLoai' },
				{ title: 'Vị trí', key: 'TenViTriPhong' },
				{ title: 'Chi phí', key: 'ChiPhi', align: 'end' },
			],
			headersDanhMuc: [
				{ title: 'Tài sản', key: 'TenTaiSan' },
				{ title: 'Danh Mục', key: 'TenDanhMuc' },
				{ title: 'Vị trí', key: 'TenViTriPhong' },
				{ title: 'Chi phí', key: 'ChiPhi', align: 'end' },
			],
			headersDetailAssets: [
				{ title: 'Mã Vạch', key: 'MaVach' },
				{ title: 'Tên Tài Sản', key: 'TenTaiSan' },
				{ title: 'Vị Trí', key: 'TenViTriPhong' },
			],
		};
	},

	computed: {
		filteredDetailedAssets() {
			if (!this.filterLocationDetail) {
				return this.detailedAssetList;
			}
			return this.detailedAssetList.filter(item =>
				item.TenViTriPhong === this.filterLocationDetail
			);
		},
		locationListDetail() {
			if (!this.detailedAssetList || this.detailedAssetList.length === 0) return [];
			// Lấy danh sách duy nhất và loại bỏ null/undefined
			const locations = [...new Set(this.detailedAssetList.map(item => item.TenViTriPhong).filter(Boolean))];
			return locations.sort(); // Sắp xếp A-Z
		},
		filteredNhanVien() {
			if (!this.dataNhanVien || this.dataNhanVien.length === 0) {
				return [];
			}

			let list = this.dataNhanVien.filter(nv =>
				nv.HoTen && nv.HoTen.length > 5 && nv.TongSoLuong > 0
			);

			if (this.reportOptions.showTop10) {
				return list.slice(0, 10);
			}

			return list;
		},
		listMonths() {
			// Lấy giá trị năm hiện tại đang được chọn (VD: 2025)
			const selectedYear = this.filter.year;

			// Nếu chưa có năm được chọn hoặc năm = 0, trả về toàn bộ danh sách tháng
			if (!selectedYear) {
				return this.listMonthsFull;
			}

			// Lọc ra các tháng từ tháng 6 đến tháng 5
			// Phần 1: Tháng 6, 7, 8, 9, 10, 11, 12 (Năm bắt đầu - selectedYear)
			const part1 = this.listMonthsFull.filter(m => m.value >= 6);

			// Phần 2: Tháng 1, 2, 3, 4, 5 (Năm kết thúc - selectedYear + 1)
			const part2 = this.listMonthsFull.filter(m => m.value > 0 && m.value <= 5); // Kết hợp lại theo thứ tự: Cả năm (value:0), Tháng 6 -> 12, Tháng 1 -> 5
			const orderedMonths = [
				this.listMonthsFull.find(m => m.value === 0), // 'Cả năm'
				...part1.map(m => ({
					title: `${m.value}-${selectedYear}`,
					value: m.value
				})),
				...part2.map(m => ({
					title: `${m.value}-${selectedYear + 1}`,
					value: m.value
				}))
			].filter(Boolean); // Lọc bỏ các giá trị null/undefined

			return orderedMonths;
		},
	},

	mounted() {
		this.getCoSo();
		this.refreshAll();
	},
	methods: {

		async exportToPDF() {
			if (typeof window.html2pdf === 'undefined') {
				alert("Đang tải thư viện, vui lòng đợi 5s...");
				return;
			}

			this.pdfLoading = true;

			try {
				const element = document.getElementById('report-content');
				if (!element) {
					alert("Lỗi: Không tìm thấy nội dung báo cáo.");
					this.pdfLoading = false;
					return;
				}

				// 1. TÍNH TOÁN KÍCH THƯỚC THỰC TẾ
				// Lấy chiều rộng và cao của nội dung HTML
				const width = element.offsetWidth;
				const height = element.scrollHeight;

				// Chuyển đổi px sang pt (point) cho chuẩn in ấn (1px ~ 0.75pt)
				// Cộng thêm một chút lề (margin) để không bị sát mép quá
				const pdfWidth = (width * 0.75) + 40;
				const pdfHeight = (height * 0.75) + 40;

				// 2. CẤU HÌNH TÊN FILE
				const yearText = this.filter.year || 'Hien_Tai';
				const fileName = `BaoCao_Full_${yearText}.pdf`;

				// 3. CẤU HÌNH PDF "KHỔ GIẤY ĐỘNG"
				const opt = {
					margin: [20, 20, 20, 20], // Lề: Trên, Trái, Dưới, Phải (đơn vị pt)
					filename: fileName,
					image: { type: 'jpeg', quality: 0.98 },
					html2canvas: {
						scale: 2,       // Giữ nguyên độ nét cao
						useCORS: true,
						scrollY: 0
					},
					jsPDF: {
						unit: 'pt', // Đơn vị là point
						// QUAN TRỌNG NHẤT: Set khổ giấy theo kích thước đã tính
						format: [pdfWidth, pdfHeight],
						orientation: 'portrait'
					}
				};

				await window.html2pdf().set(opt).from(element).save();

			} catch (error) {
				console.error("Lỗi:", error);
				alert("Có lỗi: " + error.message);
			} finally {
				this.pdfLoading = false;
			}
		},
		safeArray(arr) {
			return (arr && Array.isArray(arr)) ? arr : [];
		},


		async getCoSo() {
			try {
				const res = await axios.post("TS_CoSo_Select");
				const dbCoSo = this.safeArray(res.data.data);
				this.listCoSo = [{ TenCoSo: 'Tất cả cơ sở', MaCoSo: 0 }, ...dbCoSo];
			} catch (e) { this.listCoSo = [{ TenCoSo: 'Tất cả cơ sở', MaCoSo: 0 }]; }
		},

		async refreshAll() {
			this.loading = true;
			try {
				let coSoVal = this.filter.maCoSo?.MaCoSo ?? Number(this.filter.maCoSo) ?? 0;
				const payload = { Nam: Number(this.filter.year), Thang: Number(this.filter.month || 0), MaCoSo: coSoVal };

				const [resLoai, resDanhMuc, resNangCao] = await Promise.all([
					axios.post("TS_ThongKe_BaoTri_LoaiDanhMuc", payload),
					axios.post("TS_ThongKe_BaoTri_DanhMuc", payload),
					axios.post("TS_ThongKe_BaoTri_NangCao", payload)
				]);

				// Xử lý KPI Nâng cao
				const setsNC = resNangCao.data.data;
				if (setsNC && setsNC.length >= 3) {
					const statsNC = setsNC[0][0] || {};
					// Cập nhật stats
					this.stats = {
						TongSoDot: statsNC.TongSoDot || 0,
						TongTSDaKiemTra: statsNC.TongTSDaKiemTra || 0,
						TongSoHong: statsNC.TongSoHong || 0,
						TyLeSuckhoe: statsNC.TyLeSuckhoe || 0,
						TongChiPhi: statsNC.TongChiPhi || 0,
						SoLuotNoiBo: statsNC.SoLuotNoiBo || 0,
						SoLuotDoiTac: statsNC.SoLuotDoiTac || 0
					};
					this.dataTienDo = setsNC[0][0] || { DungHan: 0, TreHan: 0, ChuaThucHien: 0 };
					this.dataNhanVien = setsNC[1] || [];
					this.upcomingList = setsNC[2] || [];
				}

				// Xử lý Charts cũ
				if (resLoai.data.data) {
					this.dataLoai.chart = this.safeArray(resLoai.data.data[1]); this.dataLoai.list =
						this.safeArray(resLoai.data.data[2]);
				}
				if (resDanhMuc.data.data) {
					this.dataDanhMuc.chart = this.safeArray(resDanhMuc.data.data[0]); this.dataDanhMuc.list =
						this.safeArray(resDanhMuc.data.data[1]);
				}

			} catch (e) {
				console.error("Lỗi tải dữ liệu:", e);
			} finally {
				this.loading = false;
			}
		},


		showEmployeeDetail(item) {
			this.filterLocationDetail = null;
			if (!item.CacMaDotBaoTri || item.CacMaDotBaoTri.length === 0) {
				this.detailedAssetList = [];
				this.currentEmployeeName = item.HoTen || item.MaNhanVien;
				this.dialogEmployeeDetail = true;
				return;
			}

			this.currentEmployeeName = item.HoTen || item.MaNhanVien;
			this.detailedAssetList = [];
			this.dialogEmployeeDetail = true;
			this.loadingDetail = true;

			axios.post("TS_BaoTri_DanhSachChiTiet_NhanVienBaoTri", {
				MaNhanVien: item.MaNhanVien,
				MaDotBaoTriList: item.CacMaDotBaoTri,

			})
				.then(response => {
					let rawData = response.data.data;

					// Xử lý an toàn array-of-arrays
					let finalData = Array.isArray(rawData) && rawData.length > 0 && Array.isArray(rawData[0]) ? rawData[0] :
						(Array.isArray(rawData) ? rawData : []);

					this.detailedAssetList = finalData; // Gán dữ liệu vào bảng
				})
				.catch(e => {
					console.error("Lỗi tải chi tiết tài sản:", e);
					this.detailedAssetList = [];
					alert("Lỗi tải dữ liệu chi tiết! Vui lòng kiểm tra console.");
				})
				.finally(() => {
					this.loadingDetail = false;
				});
		},

		formatNumber(val) { return val ? val.toLocaleString('vi-VN') : '0'; },
		formatCurrency(val) { return val ? val.toLocaleString('vi-VN', { style: 'currency', currency: 'VND' }) : '0 ₫'; },
		formatCurrencyShort(val) {
			if (!val) return '0 ₫';
			if (val >= 1000000000) return (val / 1000000000).toFixed(1) + ' Tỷ';
			if (val >= 1000000) return (val / 1000000).toFixed(1) + ' Tr';
			return this.formatCurrency(val);
		},
		calculatePercent(part, total) { return (!total) ? 0 : ((part / total) * 100).toFixed(1); },
		formatDate(d) { return d ? new Date(d).toLocaleDateString('vi-VN') : ''; }
	}
}
</script>