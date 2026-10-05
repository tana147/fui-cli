<template>
	<v-container fluid class="bg-grey-lighten-4 fill-height align-start">
		<div id="report-content" class="bg-grey-lighten-4">
			<v-row class="mb-2">
				<v-col cols="12" md="4">
					<v-card color="red-lighten-5" class="pa-3" elevation="1" style="border-left: 5px solid #F44336">
						<div class="d-flex align-center">
							<v-avatar color="red" size="large" class="mr-3">
								<v-icon color="white">mdi-alert-circle-outline</v-icon>
							</v-avatar>
							<div>
								<div class="text-caption text-grey-darken-1 font-weight-bold">GIÁ TRỊ MẤT MÁT</div>
								<div class="text-h6 font-weight-bold text-red">{{ formatCurrency(kpiStats.tienMat) }}
								</div>
								<div class="text-caption text-red-lighten-1">{{ kpiStats.slMat }} tài sản</div>
							</div>
						</div>
					</v-card>
				</v-col>
				<v-col cols="12" md="4">
					<v-card color="orange-lighten-5" class="pa-3" elevation="1" style="border-left: 5px solid #FF9800">
						<div class="d-flex align-center">
							<v-avatar color="orange" size="large" class="mr-3">
								<v-icon color="white">mdi-wrench-clock</v-icon>
							</v-avatar>
							<div>
								<div class="text-caption text-grey-darken-1 font-weight-bold">GIÁ TRỊ HƯ HỎNG</div>
								<div class="text-h6 font-weight-bold text-orange-darken-4">{{
									formatCurrency(kpiStats.tienHu) }}
								</div>
								<div class="text-caption text-orange-darken-2">{{ kpiStats.slHu }} tài sản</div>
							</div>
						</div>
					</v-card>
				</v-col>
				<v-col cols="12" md="4">
					<v-card color="green-lighten-5" class="pa-3" elevation="1" style="border-left: 5px solid #4CAF50">
						<div class="d-flex align-center">
							<v-avatar color="green" size="large" class="mr-3">
								<v-icon color="white">mdi-check-decagram</v-icon>
							</v-avatar>
							<div>
								<div class="text-caption text-grey-darken-1 font-weight-bold">GIÁ TRỊ ĐÃ KIỂM (TỐT)
								</div>
								<div class="text-h6 font-weight-bold text-green-darken-4">{{
									formatCurrency(kpiStats.tienTot) }}
								</div>
								<div class="text-caption text-green-darken-2">{{ kpiStats.slTot }} tài sản</div>
							</div>
						</div>
					</v-card>
				</v-col>
			</v-row>

			<v-card class="mb-3 w-100" elevation="1">
				<v-card-text class="py-2">

					<v-row dense class="mb-1">
						<v-col cols="12">
							<v-radio-group v-model="filterMode" inline hide-details density="compact" color="primary">
								<template v-slot:label>
									<span class="text-caption font-weight-bold mr-3 text-grey-darken-2">CHẾ ĐỘ
										XEM:</span>
								</template>
								<v-radio value="date" label="Lọc phiếu theo thời gian"></v-radio>
								<v-radio value="sheet"
									label="So sánh phiếu cụ thể theo khoảng thời gian chọn"></v-radio>
							</v-radio-group>
						</v-col>
					</v-row>

					<v-divider class="mb-3 border-dashed"></v-divider>

					<v-row dense align="center">

						<v-col cols="12" md="3">
							<uc-date-picker v-model="tuNgay" label="Từ ngày" :max="denNgay" density="compact"
								variant="outlined" hide-details :rules="[]" clearable />
						</v-col>
						<v-col cols="12" md="3">
							<uc-date-picker v-model="denNgay" label="Đến ngày" :min="tuNgay" density="compact"
								variant="outlined" hide-details :rules="[]" clearable />
						</v-col>

						<v-col cols="12" md="3">
							<v-combobox
								:label="filterMode === 'date' ? 'Đang chế độ tổng hợp (đã khóa)' : 'Chọn phiếu (Đã lọc theo ngày)'"
								:placeholder="dsPhieuCombobox.length === 0 ? 'Vui lòng chọn ngày trước...' : 'Chọn phiếu...'"
								:items="dsPhieuCombobox" item-title="TenPhieu" item-value="MaPhieuKiemKe"
								density="compact" variant="outlined" hide-details :return-object="true"
								v-model="phieuKiemFilter" clearable multiple chips closable-chips
								prepend-inner-icon="mdi-file-compare" :disabled="filterMode === 'date'"
								:bg-color="filterMode === 'date' ? 'grey-lighten-4' : 'white'">
							</v-combobox>
						</v-col>

						<v-col cols="12" md="3" class="d-flex ga-2">
							<v-btn color="primary" class="flex-grow-1" @click="handleFilterClick" elevation="0"
								data-html2canvas-ignore="true">
								<v-icon start>mdi-filter-check</v-icon> Lọc
							</v-btn>
							<v-btn color="grey-lighten-1" variant="tonal" @click="resetFilters" elevation="0"
								title="Đặt lại" data-html2canvas-ignore="true">
								<v-icon>mdi-refresh</v-icon>
							</v-btn>
							<v-btn color="red-darken-1" height="40" prepend-icon="mdi-file-pdf-box" @click="exportToPDF"
								:loading="pdfLoading" data-html2canvas-ignore="true">
								Xuất PDF
							</v-btn>
						</v-col>
					</v-row>

					<div class="mt-3">
						<div class="d-flex justify-space-between text-caption mb-1">
							<span>Tiến độ hoàn thành kiểm kê</span>
							<span class="font-weight-bold">{{ kpiStats.progress }}%</span>
						</div>
						<v-progress-linear :model-value="kpiStats.progress" color="primary" height="6" rounded striped>
						</v-progress-linear>
					</div>

				</v-card-text>
			</v-card>

			<v-row class="w-100 mb-1">
				<v-col cols="12" md="8">
					<v-card class="fill-height pa-2" elevation="1">
						<v-card-title class="text-subtitle-2 font-weight-bold text-uppercase text-grey-darken-1">
							So sánh kết quả kiểm kê
						</v-card-title>
						<div style="height: 350px; width: 100%;">
							<canvas ref="barChartRef"></canvas>
						</div>
					</v-card>
				</v-col>

				<v-col cols="12" md="4">
					<v-card class="fill-height pa-2" elevation="1">
						<v-card-title class="text-subtitle-2 font-weight-bold text-uppercase text-grey-darken-1">
							Tỷ lệ tổng hợp ({{ chartStats.total }} Tài sản)
						</v-card-title>
						<uc-chart v-if="chartStats.total > 0" :lost="chartStats.lost" :broken="chartStats.broken"
							:good="chartStats.good" :notChecked="chartStats.notChecked" />
						<div v-else class="d-flex flex-column align-center justify-center h-100 text-grey">
							<v-icon size="40" class="mb-2">mdi-chart-bar-stacked</v-icon>
							<span>Vui lòng nhấn "Lọc" để xem dữ liệu</span>
						</div>
					</v-card>
				</v-col>
			</v-row>

			<v-row class="w-100">
				<v-col cols="12" md="4" class="d-flex flex-column ga-3">

					<v-card elevation="1" style="max-height: 300px; overflow-y: auto;">
						<v-toolbar density="compact" color="white"
							style="border-bottom: 1px solid #e0e0e0; position: sticky; top:0; z-index: 2;">
							<v-toolbar-title class="text-subtitle-2 font-weight-bold text-red">
								<v-icon start color="red">mdi-fire</v-icon> Top Đơn vị mất nhiều
							</v-toolbar-title>
						</v-toolbar>
						<v-list density="compact" lines="two">
							<v-list-item v-for="(item, index) in dsTopMat" :key="index">
								<template v-slot:prepend>
									<v-avatar color="red-lighten-4" size="small"
										class="text-red font-weight-bold mr-2">{{
											index + 1 }}</v-avatar>
								</template>
								<v-list-item-title class="font-weight-medium text-caption">
									{{ item.TenPhongBan || 'Không xác định' }}
								</v-list-item-title>
								<v-list-item-subtitle class="text-caption mt-1" style="opacity: 1;">
									<span class="text-grey-darken-3 font-weight-medium">Thiệt hại:</span>
									<b class="text-red font-weight-bold ml-1" style="font-size: 13px;">
										{{ formatCurrency(item.GiaTriMat) }}
									</b>
								</v-list-item-subtitle>
								<template v-slot:append>
									<v-chip size="x-small" color="red" variant="flat">{{ item.SoLuongMat }}</v-chip>
								</template>
							</v-list-item>
							<div v-if="dsTopMat.length === 0" class="text-center pa-2 text-grey text-caption">Chưa có dữ
								liệu mất mát</div>
						</v-list>
					</v-card>

					<v-card elevation="1" class="flex-grow-1">
						<v-toolbar density="compact" color="white" style="border-bottom: 1px solid #e0e0e0;">
							<v-toolbar-title class="text-subtitle-2 font-weight-bold">Danh sách Phiếu</v-toolbar-title>
						</v-toolbar>
						<v-data-table :headers="headerPhieu" :items="dsPhieuTable" :fixed-header="!pdfLoading"
							:height="pdfLoading ? undefined : 470" density="compact" class="flex-grow-1"
							item-value="MaPhieuKiemKe" hover :row-props="() => ({ style: 'cursor: pointer;' })"
							@click:row="onSelectPhieuFromTable">
							<template v-slot:item.TenPhieu="{ item }">
								<div class="d-flex flex-column py-2 align-start">
									<span class="font-weight-bold text-body-2 text-wrap"
										:class="item.MaPhieuKiemKe === maPhieuDangChon ? 'text-primary' : 'text-blue-grey-darken-3'"
										style="line-height: 1.4;">
										{{ item.TenPhieu }}
									</span>

									<span class="text-caption text-grey mt-1 d-flex align-center">
										<v-icon size="12" class="mr-1">mdi-clock-time-four-outline</v-icon>
										{{ formatDate(item.CreateTime) }}
									</span>
								</div>
							</template>
							<template v-slot:item.SoLuongMat="{ item }">
								<span v-if="item.SoLuongMat > 0" class="text-red font-weight-bold">{{ item.SoLuongMat
								}}</span><span v-else class="text-grey">-</span>
							</template>
							<template v-slot:item.SoLuongHu="{ item }">
								<span v-if="item.SoLuongHu > 0" class="text-orange font-weight-bold">{{ item.SoLuongHu
								}}</span><span v-else class="text-grey">-</span>
							</template>
						</v-data-table>
					</v-card>
				</v-col>

				<v-col cols="12" md="8">
					<v-card class="fill-height d-flex flex-column border-thin" elevation="0" rounded="lg">

						<v-toolbar color="white" density="compact" class="px-2 border-bottom">
							<v-icon color="primary" class="mr-2">mdi-file-document-outline</v-icon>
							<div class="d-flex flex-column justify-center">
								<span class="text-subtitle-2 font-weight-bold text-blue-grey-darken-3">CHI TIẾT
									PHIẾU</span>
								<span class="text-caption text-grey"
									style="max-width: 250px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
									{{ tenPhieuDangChon }}
								</span>
							</div>
							<v-spacer></v-spacer>
							<v-combobox v-model="phongBanDangChon" :items="dsPhongBan" item-title="TenPhongBan"
								item-value="PhongBanID" placeholder="Phòng ban" density="compact" variant="outlined"
								hide-details :return-object="true" :disabled="!maPhieuDangChon"
								bg-color="grey-lighten-5" style="width: 140px; font-size: 13px;" class="mr-2" />

							<v-combobox v-model="tinhTrangFilter" :items="dsTinhTrangKiemKe" item-title="TrangThaiMoTa"
								item-value="TrangThaiThucTe" placeholder="Tình trạng" density="compact"
								variant="outlined" hide-details multiple :return-object="true"
								:disabled="!maPhieuDangChon" bg-color="grey-lighten-5"
								style="width: 250px; font-size: 13px;" class="mr-2">
								<template v-slot:selection="{ item, index }">
									<v-chip v-if="index < 2" size="x-small" class="mr-1" label>
										{{ item.title }}
									</v-chip>

									<span v-if="index === 2" class="text-caption text-grey ml-1">
										(+{{ tinhTrangFilter.length - 2 }})
									</span>
								</template>
							</v-combobox>

							<v-btn color="green-darken-1" variant="tonal" height="40" @click="xuatExcel"
								:disabled="!maPhieuDangChon">
								<v-icon>mdi-microsoft-excel</v-icon>
							</v-btn>
						</v-toolbar>

						<v-data-table :headers="headerTaiSan" :items="dsTaiSanDisplay" :fixed-header="!pdfLoading"
							:height="pdfLoading ? undefined : 600" density="default" class="flex-grow-1 modern-table"
							no-data-text="Chọn phiếu bên trái để xem chi tiết" hover>
							<template v-slot:item.TenTaiSan="{ item }">
								<div class="d-flex align-center py-2">

									<div class="d-flex flex-column align-start">
										<uc-asset-info
											classforname="text-subtitle-2 font-weight-bold text-high-emphasis"
											:tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet"
											:mataisan="item.MaTS"></uc-asset-info>

										<div class="mt-1">
											<span
												class="text-caption bg-grey-lighten-4 px-1 rounded text-grey-darken-3 font-weight-medium border">
												{{ item.MaVach }}
											</span>
										</div>
									</div>
								</div>
							</template>

							<template v-slot:item.TenTrangThai="{ item }">
								<v-chip size="small" :color="getColorByTrangThai(item.TenTrangThai)" variant="tonal"
									class="font-weight-bold">
									{{ item.TenTrangThai }}
								</v-chip>
							</template>

							<template v-slot:item.ViTriDangLuu="{ item }">
								<div class="d-flex align-center text-caption text-grey-darken-1">
									<v-icon size="14" class="mr-1" color="grey">mdi-database-outline</v-icon>
									{{ item.ViTriDangLuu || '-' }}
								</div>
							</template>

							<template v-slot:item.ViTriThucTe="{ item }">
								<div class="d-flex align-center text-body-2 text-blue-grey-darken-3 font-weight-medium">
									<v-icon size="14" class="mr-1"
										:color="item.ViTriDangLuu == item.ViTriThucTe ? 'green' : 'orange'">
										mdi-map-marker</v-icon>
									{{ item.ViTriThucTe || '-' }}
								</div>
							</template>

							<template v-slot:item.HoTenNguoiSuDung="{ item }">
								<div class="d-flex align-center" v-if="item.HoTenNguoiSuDung">

									<span class="text-caption font-weight-medium">{{ item.HoTenNguoiSuDung }}</span>
								</div>
							</template>

							<template v-slot:item.NgayThucHien="{ item }">
								<div class="d-flex align-center">
									<v-icon size="small" color="blue" class="mr-1"
										v-if="item.NgayThucHien">mdi-calendar-check</v-icon>
									<span class="text-caption font-weight-bold text-blue-grey-darken-3">
										{{ formatDate(item.NgayThucHien) }}
									</span>
								</div>
							</template>

							<template v-slot:item.NgayHeThong="{ item }">
								<div class="d-flex flex-column" v-if="item.NgayHeThong">
									<span class="text-caption text-grey-darken-3">
										{{ formatDate(item.NgayHeThong) }}
									</span>
									<span class="text-caption text-grey" style="font-size: 11px !important;">
										{{ new Date(item.NgayHeThong).toLocaleTimeString('vi-VN', {
											hour: '2-digit',
											minute: '2-digit'
										}) }}
									</span>
								</div>
								<span v-else class="text-caption text-grey">-</span>
							</template>

						</v-data-table>
					</v-card>
				</v-col>
			</v-row>
		</div>
		<uc-confirm ref="confirm" />
	</v-container>
</template>

<script>
export default {

	data() {
		return {
			pdfLoading: false,
			filterMode: 'date',
			tuNgay: null, denNgay: null, phieuKiemFilter: [], dsPhieuCombobox: [],
			chartInstance: null,
			chartStats: { total: 0, lost: 0, broken: 0, good: 0, notChecked: 0 },
			kpiStats: { tienMat: 0, tienHu: 0, tienTot: 0, slMat: 0, slHu: 0, slTot: 0, progress: 0 },
			dsPhieuTable: [], dsTopMat: [],
			headerPhieu: [
				{ title: 'Tên phiếu', key: 'TenPhieu' },
				{ title: 'Tổng', key: 'TongTaiSan', align: 'end', width: '60px' },
				{ title: 'Mất', key: 'SoLuongMat', align: 'center', width: '50px' },
				{ title: 'Hư', key: 'SoLuongHu', align: 'center', width: '50px' },
				{ title: 'Chưa kiểm', key: 'SoLuongChuaKiem', align: 'center', width: '50px' },
			],
			maPhieuDangChon: null, tenPhieuDangChon: null,
			dsTaiSanGoc: [], dsTaiSanDisplay: [],
			headerTaiSan: [
				{ title: 'STT', key: 'STT', width: '50px', align: 'center' },
				{ title: 'Tài sản', key: 'TenTaiSan', width: '250px' },
				{ title: 'Tình trạng', key: 'TenTrangThai', width: '130px' },
				{ title: 'Vị trí lưu ', key: 'ViTriDangLuu', width: '150px' },
				{ title: 'Vị trí thực', key: 'ViTriThucTe', width: '150px' },
				{ title: 'Người giữ', key: 'HoTenNguoiSuDung', width: '150px' },
				// --- CẬP NHẬT HEADER MỚI ---
				{ title: 'Ngày thực hiện', key: 'NgayThucHien', width: '130px' }, // Ngày chọn
				{ title: 'Ngày nhập máy', key: 'NgayHeThong', width: '150px' }, // Ngày hệ thống (có giờ phút)
				// ---------------------------
			],
			phongBanDangChon: { "TenPhongBan": "Tất cả", "PhongBanID": 0 },
			dsPhongBan: [], tinhTrangFilter: [], dsTinhTrangKiemKe: [],
		};
	},
	computed: {

	},
	watch: {
		filterMode(newVal) {
			if (newVal === 'date') {
				this.phieuKiemFilter = []; // Xóa chọn
				this.dsPhieuCombobox = []; // Xóa list cho gọn
			} else {
				// Nếu chuyển sang chế độ So sánh mà đã có ngày -> Gọi API lấy phiếu ngay
				if (this.tuNgay && this.denNgay) {
					this.getPhieuTheoNgay();
				}
			}
		},

		// KHI ĐỔI NGÀY -> GỌI API LẤY LIST PHIẾU MỚI
		tuNgay() { this.onDateChange(); },
		denNgay() { this.onDateChange(); },
		phongBanDangChon: 'filterLocalAssets',
		tinhTrangFilter: { handler: 'filterLocalAssets', deep: true }
	},
	mounted() { this.loadMetaData(); },
	methods: {
		async exportToPDF() {
			// 1. Kiểm tra thư viện
			if (typeof window.html2pdf === 'undefined') {
				alert("Đang tải thư viện xuất PDF, vui lòng đợi 5s...");
				return;
			}

			this.pdfLoading = true;

			// Mẹo: Đợi Vue vẽ lại giao diện (để bung bảng ra hết cỡ nếu có scroll)
			await this.$nextTick();

			try {
				// Lấy phần tử cần in theo ID đã đặt ở Template
				const element = document.getElementById('report-content');

				if (!element) {
					alert("Lỗi: Không tìm thấy nội dung báo cáo (id='report-content').");
					this.pdfLoading = false;
					return;
				}

				// 2. Tính toán kích thước thực tế để không bị cắt trang
				const width = element.offsetWidth;
				const height = element.scrollHeight;

				// Chuyển đổi px sang pt (1px ~ 0.75pt) + lề an toàn
				const pdfWidth = (width * 0.75) + 40;
				const pdfHeight = (height * 0.75) + 40;

				// --- SỬA LỖI TẠI ĐÂY ---
				// Tự tạo tên file theo ngày hiện tại thay vì dùng this.filter.year (biến không tồn tại)
				const today = new Date();
				const dateStr = today.toLocaleDateString('vi-VN').replace(/\//g, '-'); // VD: 19-12-2025
				const fileName = `BaoCao_KiemKe_${dateStr}.pdf`;
				// -----------------------

				// 3. Cấu hình PDF
				const opt = {
					margin: [20, 20, 20, 20], // Lề: Trên, Trái, Dưới, Phải
					filename: fileName,
					image: { type: 'jpeg', quality: 0.98 },
					html2canvas: {
						scale: 2,       // Độ nét cao
						useCORS: true,  // Cho phép tải ảnh từ server khác
						scrollY: 0      // Quan trọng: sửa lỗi lệch hình khi cuộn trang
					},
					jsPDF: {
						unit: 'pt',
						format: [pdfWidth, pdfHeight], // Khổ giấy động theo nội dung
						orientation: 'portrait'
					}
				};

				// 4. Thực hiện xuất
				await window.html2pdf().set(opt).from(element).save();

			} catch (error) {
				console.error("Lỗi xuất PDF:", error);
				alert("Có lỗi: " + (error.message || error));
			} finally {
				this.pdfLoading = false;
			}
		},
		// Hàm xử lý khi đổi ngày
		onDateChange() {
			// Chỉ chạy nếu đang ở chế độ So sánh và đã chọn đủ 2 ngày
			if (this.filterMode === 'sheet' && this.tuNgay && this.denNgay) {
				this.getPhieuTheoNgay();
			}
		},

		// GỌI API MỚI (Thủ tục vừa viết)
		async getPhieuTheoNgay() {
			this.dsPhieuCombobox = []; // Reset list cũ
			try {
				const res = await axios.post("TS_PhieuKiemKe_SelectByDate", { // Tên API ứng với SP mới
					TuNgay: this.tuNgay,
					DenNgay: this.denNgay
				});
				this.dsPhieuCombobox = res.data.data || [];
			} catch (e) {
				console.error("Lỗi lấy danh sách phiếu:", e);
			}
		},

		formatDate(dateString) {
			if (!dateString) return '-';

			// Kiểm tra xem có phải định dạng Việt Nam sẵn rồi không (dd/mm/yyyy)
			// Regex này kiểm tra: 2 số / 2 số / 4 số
			if (/^\d{2}\/\d{2}\/\d{4}/.test(dateString)) {
				return dateString; // Nếu đúng là "18/12/2025" rồi thì trả về luôn
			}

			// Nếu không phải (là dạng ISO yyyy-mm-dd...), thì mới Parse
			const date = new Date(dateString);
			if (isNaN(date.getTime())) return dateString; // Nếu lỗi nữa thì trả về nguyên gốc

			return date.toLocaleDateString('vi-VN', {
				day: '2-digit',
				month: '2-digit',
				year: 'numeric'
			});
		},
		formatCurrency(value) { return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value || 0); },
		async loadMetaData() {
			try {
				const [resPB, resTT, resPhieu] = await Promise.all([
					axios.post("TS_PhongBan_Select"),
					axios.post("TS_TrangThaiThucTe_Select"),
					axios.post("TS_PhieuKiemKe_Select")
				]);

				// Xử lý Phòng ban
				this.dsPhongBan = resPB.data.data || [];
				this.dsPhongBan.unshift({ "TenPhongBan": "Tất cả", "PhongBanID": 0 });
				this.dsTinhTrangKiemKe = resTT.data?.data || [];

				// Xử lý Phiếu
				this.dsPhieuCombobox = resPhieu.data.data || [];
			} catch (e) { console.error(e); }
		},

		resetFilters() {
			this.tuNgay = null; this.denNgay = null; this.phieuKiemFilter = [];
			this.maPhieuDangChon = null; this.tenPhieuDangChon = null;
			this.dsPhieuTable = []; this.dsTaiSanDisplay = []; this.dsTopMat = [];
			this.kpiStats = { tienMat: 0, tienHu: 0, tienTot: 0, slMat: 0, slHu: 0, slTot: 0, progress: 0 };
			this.chartStats = { total: 0, lost: 0, broken: 0, good: 0, notChecked: 0 };
			if (this.chartInstance) this.chartInstance.destroy();
		},

		handleFilterClick() { this.fetchDashboardData(); },

		async fetchDashboardData() {
			this.dsPhieuTable = []; this.dsTaiSanDisplay = []; this.maPhieuDangChon = null;
			this.kpiStats = { tienMat: 0, tienHu: 0, tienTot: 0, slMat: 0, slHu: 0, slTot: 0, progress: 0 };

			try {
				let rawData = [];
				let listIDs = "";

				// === OPTION 2: SO SÁNH PHIẾU CỤ THỂ ===
				if (this.filterMode === 'sheet') {
					if (!this.phieuKiemFilter || this.phieuKiemFilter.length === 0) {
						// Cảnh báo nhẹ nếu chưa chọn phiếu
						// alert("Vui lòng chọn ít nhất 1 phiếu trong danh sách!");
						return;
					}

					listIDs = this.phieuKiemFilter.map(x => x.MaPhieuKiemKe).join(',');
					const promises = this.phieuKiemFilter.map(item =>
						axios.post("TS_ThongKePhieuKiemKe_TaiSanMat_Hu_byMaPhieu", { MaPhieuKiemKe: item.MaPhieuKiemKe })
					);
					const results = await Promise.all(promises);
					rawData = results.map(r => (r.data.data && r.data.data.length > 0) ? r.data.data[0] : null).filter(x => x);

				}
				// === OPTION 1: TỔNG HỢP THEO THỜI GIAN ===
				else {
					if (!this.tuNgay || !this.denNgay) {
						// alert("Vui lòng chọn từ ngày - đến ngày!");
						return;
					}
					listIDs = ""; // Để trống -> SQL tự lọc theo ngày

					const res = await axios.post("TS_ThongKePhieuKiemKe_TaiSanMat_Hu", {
						TuNgay: this.tuNgay,
						DenNgay: this.denNgay
					});
					rawData = res.data.data || [];
				}

				// Gọi Top điểm nóng (Logic cũ vẫn đúng)
				const payloadTop = { ListMaPhieu: listIDs };
				if (this.filterMode === 'date') { // Chỉ gửi ngày nếu là chế độ tổng hợp
					payloadTop.TuNgay = this.tuNgay;
					payloadTop.DenNgay = this.denNgay;
				}
				const resTop = await axios.post("TS_ThongKe_TopPhongBanMatMat", payloadTop);
				this.dsTopMat = resTop.data.data || [];

				this.processDataForCharts(rawData);

			} catch (error) { console.error(error); }
		},

		processDataForCharts(data) {
			let totalTienMat = 0, totalTienHu = 0, totalTienTot = 0;
			let totalMat = 0, totalHu = 0, totalTot = 0, totalChuaKiem = 0, grandTotal = 0;

			this.dsPhieuTable = data.map(item => {
				const mat = Number(item.SoLuongMat) || 0; const hu = Number(item.SoLuongHu) || 0;
				const tot = Number(item.SoLuongTot) || 0; const chuaKiem = Number(item.SoLuongChuaKiem) || 0;
				const tMat = Number(item.TienMat) || 0; const tHu = Number(item.TienHu) || 0; const tTot = Number(item.TienTot) || 0;

				totalTienMat += tMat; totalTienHu += tHu; totalTienTot += tTot;
				totalMat += mat; totalHu += hu; totalTot += tot; totalChuaKiem += chuaKiem;
				grandTotal += (mat + hu + tot + chuaKiem);

				return { ...item, SoLuongMat: mat, SoLuongHu: hu, SoLuongTot: tot, SoLuongChuaKiem: chuaKiem };
			});

			this.kpiStats = {
				tienMat: totalTienMat, tienHu: totalTienHu, tienTot: totalTienTot,
				slMat: totalMat, slHu: totalHu, slTot: totalTot,
				progress: grandTotal > 0 ? ((grandTotal - totalChuaKiem) / grandTotal * 100).toFixed(1) : 0
			};
			this.chartStats = { total: grandTotal, lost: totalMat, broken: totalHu, good: totalTot, notChecked: totalChuaKiem };
			this.updateBarChart(this.dsPhieuTable);
		},

		updateBarChart(data) {
			if (this.chartInstance) this.chartInstance.destroy();

			// Kiểm tra thư viện
			if (typeof window.Chart === 'undefined') return;

			const ctx = this.$refs.barChartRef.getContext('2d');

			this.chartInstance = new window.Chart(ctx, {
				type: 'bar',
				data: {
					labels: data.map(d => d.TenPhieu),
					datasets: [
						{
							label: 'Mất',
							data: data.map(d => d.SoLuongMat),
							backgroundColor: '#F44336',
							stack: 'combined' // Cùng tên stack để chồng lên nhau
						},
						{
							label: 'Hư',
							data: data.map(d => d.SoLuongHu),
							backgroundColor: '#FF9800',
							stack: 'combined'
						},
						{
							label: 'Tốt',
							data: data.map(d => d.SoLuongTot),
							backgroundColor: '#4CAF50',
							stack: 'combined'
						},
						{
							label: 'Chưa kiểm',
							data: data.map(d => d.SoLuongChuaKiem),
							backgroundColor: '#9E9E9E',
							stack: 'combined'
						}
					]
				},
				options: {
					responsive: true,
					maintainAspectRatio: false,

					// --- CẤU HÌNH QUAN TRỌNG ĐỂ HIỆN HẾT TOOLTIP ---
					interaction: {
						mode: 'index', // Hiển thị tất cả dataset tại vị trí cột (index) này
						intersect: false, // Rê chuột vào khoảng trống của cột cũng hiện
					},

					scales: {
						x: {
							stacked: true,
							grid: { display: false },
							ticks: {
								maxRotation: 45, // Xoay chữ nếu tên phiếu dài
								minRotation: 0
							}
						},
						y: {
							stacked: true,
							beginAtZero: true
						}
					},
					plugins: {
						legend: { position: 'top' },
						tooltip: {
							mode: 'index', // Chế độ gom nhóm
							intersect: false,
							callbacks: {
								// (Tùy chọn) Thêm dòng Tổng cộng ở dưới cùng tooltip cho dễ nhìn
								footer: (tooltipItems) => {
									let sum = 0;
									tooltipItems.forEach(function (tooltipItem) {
										sum += tooltipItem.parsed.y;
									});
									return 'Tổng cộng: ' + sum;
								}
							}
						}
					},
					// Sự kiện Click
					onClick: (e, elements) => {
						if (elements.length > 0) {
							const index = elements[0].index;
							this.onSelectPhieuFromTable(null, { item: this.dsPhieuTable[index] });
						}
					}
				}
			});
		},
		async onSelectPhieuFromTable(event, { item }) {
			this.maPhieuDangChon = item.MaPhieuKiemKe;
			this.tenPhieuDangChon = item.TenPhieu;
			try {
				const res = await axios.post("TS_ThongKeChiTietTaiSanKiemKe_SelectByLoaiMaPhieuKiem", { MaPhieuKiemKe: item.MaPhieuKiemKe });
				this.dsTaiSanGoc = (res.data?.data || []).map((x, i) => ({ ...x, STT: i + 1 }));
				this.filterLocalAssets();
			} catch (e) { }
		},
		filterLocalAssets() {
			let result = [...this.dsTaiSanGoc];

			// Lọc Phòng ban
			if (this.phongBanDangChon?.PhongBanID !== 0) {
				result = result.filter(x => x.PhongBanID === this.phongBanDangChon.PhongBanID);
			}

			// Lọc Tình trạng
			if (this.tinhTrangFilter.length > 0) {
				const selectedIds = this.tinhTrangFilter.map(t => t.TrangThaiThucTe);

				result = result.filter(x => {
					const statusThucTe = (x.TrangThaiThucTe === null || x.TrangThaiThucTe === undefined) ? 0 : x.TrangThaiThucTe;

					return selectedIds.includes(statusThucTe);
				});
			}

			this.dsTaiSanDisplay = result;
		},
		getColorByTrangThai(s) {
			if (!s) return 'grey'; const str = s.toLowerCase();
			return str.includes('mất') ? 'red' : str.includes('hư') ? 'orange' : str.includes('tốt') || str.includes('còn') ? 'green' : 'grey';
		},
		xuatExcel() {
			// 1. Kiểm tra dữ liệu
			if (!this.dsTaiSanDisplay || this.dsTaiSanDisplay.length === 0) {
				alert("Không có dữ liệu để xuất!");
				return;
			}

			const XLSX = window.XLSX;
			if (!XLSX) {
				alert("Lỗi: Thư viện XLSX chưa tải.");
				return;
			}

			// 2. Chuẩn bị tên file và ngày tháng
			let fileName = "";
			const today = new Date();
			const dateStr = today.toLocaleDateString('vi-VN');
			const todayFile = dateStr.replace(/\//g, '-');

			let titleBaoCao = "BÁO CÁO THỐNG KÊ KIỂM KÊ";
			let subTitle = "";

			if (this.maPhieuDangChon && this.tenPhieuDangChon) {
				// Chế độ xem 1 phiếu
				const safeName = this.tenPhieuDangChon
					.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
					.replace(/[^a-zA-Z0-9 ]/g, "").replace(/\s+/g, "_");
				fileName = `ChiTiet_${safeName}_${todayFile}.xlsx`;
				titleBaoCao = "CHI TIẾT PHIẾU KIỂM KÊ";
				subTitle = `Phiếu: ${this.tenPhieuDangChon}`;
			} else {
				// Chế độ tổng hợp
				fileName = `TongHopKiemKe_${todayFile}.xlsx`;
				titleBaoCao = "BÁO CÁO TỔNG HỢP KIỂM KÊ TÀI SẢN";
				subTitle = `Thời gian xuất: ${dateStr}`;
			}

			// 3. Chuẩn bị dữ liệu bảng (Data Table)
			const data = this.dsTaiSanDisplay.map((x, index) => ({
				'STT': index + 1,
				'Mã TS': x.MaVach || '',
				'Tên tài sản': x.TenTaiSan || '',
				'Tình trạng': x.TenTrangThai || '',
				'Vị trí lưu (PM)': x.ViTriDangLuu || '',
				'Vị trí thực tế': x.ViTriThucTe || '',
				'Ngày thực hiện': this.formatDate(x.NgayThucHien),
				'Ngày nhập máy': x.NgayHeThong ?
					(this.formatDate(x.NgayHeThong) + ' ' + new Date(x.NgayHeThong).toLocaleTimeString('vi-VN')) : ''
			}));

			// 4. Tạo Worksheet
			// origin: 'A6' nghĩa là dữ liệu bảng sẽ bắt đầu từ dòng số 6 (để dành 5 dòng đầu cho Tiêu đề)
			const ws = XLSX.utils.json_to_sheet(data, { origin: 'A6' });

			// 5. Thêm Tiêu đề (Header) vào các dòng đầu (A1 -> A5)
			// Dùng mảng 2 chiều (Array of Arrays) để chèn dữ liệu
			const headerInfo = [
				["TRƯỜNG SONG NGỮ LẠC HỒNG"], // A1: Tên đơn vị (Thay thế Logo)
				["HỆ THỐNG QUẢN LÝ TÀI SẢN"], // A2: Bộ phận
				[""], // A3: Dòng trống
				[titleBaoCao], // A4: Tên báo cáo (IN HOA)
				[subTitle], // A5: Tên phiếu hoặc ngày tháng
			];

			XLSX.utils.sheet_add_aoa(ws, headerInfo, { origin: 'A1' });

			// 6. Gộp ô (Merge Cells) để căn giữa tiêu đề
			if (!ws['!merges']) ws['!merges'] = [];

			// Gộp dòng 1 (Tên trường): Từ cột A đến cột E
			ws['!merges'].push({ s: { r: 0, c: 0 }, e: { r: 0, c: 4 } });
			// Gộp dòng 4 (Tên báo cáo): Từ cột A đến cột H (cho rộng ra giữa bảng)
			ws['!merges'].push({ s: { r: 3, c: 0 }, e: { r: 3, c: 7 } });
			// Gộp dòng 5 (Sub title): Từ cột A đến cột H
			ws['!merges'].push({ s: { r: 4, c: 0 }, e: { r: 4, c: 7 } });

			// 7. Chỉnh độ rộng cột (Widths)
			const wscols = [
				{ wch: 5 }, // STT
				{ wch: 15 }, // Mã
				{ wch: 30 }, // Tên
				{ wch: 15 }, // Tình trạng
				{ wch: 25 }, // Vị trí PM
				{ wch: 25 }, // Vị trí Thực
				{ wch: 15 }, // Ngày thực hiện
				{ wch: 20 } // Ngày nhập máy
			];
			ws['!cols'] = wscols;

			// 8. Xuất file
			const wb = XLSX.utils.book_new();
			XLSX.utils.book_append_sheet(wb, ws, "BaoCao");
			XLSX.writeFile(wb, fileName);
		},
	}
}
</script>