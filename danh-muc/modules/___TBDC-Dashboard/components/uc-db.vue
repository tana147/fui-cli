<template>
	<z-layout>
		<v-container fluid class="bg-grey-lighten-5 fill-height align-start pa-6">
			<div id="dashboard-content" class="w-100">
				<v-row class="mb-4" align="center">
					<v-col cols="12" lg="6" md="12">
						<div class="d-flex align-center">
							<v-avatar color="white" size="48" class="mr-3 rounded-lg elevation-1">
								<v-icon color="blue-grey-darken-3" size="28">mdi-view-dashboard-variant</v-icon>
							</v-avatar>
							<div>
								<h1 class="text-h5 font-weight-bold text-blue-grey-darken-3">
									Dashboard Quản Lý Tài Sản
								</h1>
								<div class="text-caption text-grey-darken-1 mt-1">
									Giám sát toàn diện: Giá trị, Vận hành & Hiệu suất.
								</div>
							</div>
						</div>
					</v-col>

					<v-col cols="12" lg="6" md="12" data-html2canvas-ignore="true">
						<div class="d-flex align-center justify-lg-end justify-start flex-wrap" style="gap: 10px;">

							<v-select v-model="filter.year" :items="listYears" label="Năm" item-title="title"
								item-value="value" density="compact" variant="outlined" bg-color="white" hide-details
								prepend-inner-icon="mdi-calendar-range" style="width: 110px; flex: none;"
								class="rounded-lg" @update:model-value="initData">
							</v-select>

							<v-select v-model="filter.month" :items="listMonths" item-title="title" item-value="value"
								:return-object="false" label="Tháng" density="compact" variant="outlined"
								bg-color="white" hide-details prepend-inner-icon="mdi-calendar-month"
								style="width: 130px; flex: none;" class="rounded-lg" @update:model-value="initData">
							</v-select>

							<v-btn icon variant="tonal" color="blue-grey" size="small" class="rounded-circle"
								@click="layDuLieuDashboard" :loading="isLoading" v-tooltip:bottom="'Làm mới'">
								<v-icon>mdi-refresh</v-icon>
							</v-btn>

							<v-divider vertical class="mx-1 hidden-sm-and-down" style="height: 24px"></v-divider>

							<v-btn prepend-icon="mdi-qrcode-scan" color="primary" variant="flat"
								class="text-none font-weight-bold" rounded="lg" height="40"
								@click="showQrDialog = true">
								Quét QR
							</v-btn>

							<v-btn prepend-icon="mdi-file-pdf-box" color="red-darken-1" variant="tonal"
								class="text-none font-weight-bold" rounded="lg" height="40" @click="exportToPDF"
								:loading="pdfLoading">
								Xuất PDF
							</v-btn>
						</div>
					</v-col>
				</v-row>

				<v-row>
					<v-col cols="12" md="9">
						<v-card elevation="2" rounded="lg"
							class="bg-indigo-darken-3 text-white overflow-hidden position-relative h-100">
							<div class="position-absolute right-0 top-0 h-100 w-50 bg-white"
								style="opacity: 0.05; transform: skewX(-20deg);"></div>
							<v-card-text class="pa-6">
								<v-row align="center">
									<v-col cols="12" sm="5">
										<div class="text-overline text-indigo-lighten-3 mb-1">TỔNG GIÁ TRỊ TÀI SẢN</div>
										<div class="text-h3 font-weight-black">
											{{ formatCurrency(thongKeKPI.TongGiaTri) }}
										</div>
										<div class="d-flex align-center mt-2">
											<v-chip color="green-accent-3" size="small" label
												class="mr-2 font-weight-bold">
												<v-icon start icon="mdi-trending-up" size="small"></v-icon> Ổn định
											</v-chip>
											<span class="text-caption text-indigo-lighten-4">Dữ liệu cập nhật thời gian
												thực</span>
										</div>
									</v-col>
									<v-col cols="12" sm="7">
										<div v-for="(group, idx) in assetGroups.slice(0, 3)" :key="idx" class="mb-3">
											<div class="d-flex justify-space-between text-caption mb-1">
												<span>{{ group.TenNhomDanhMuc }}</span>

												<span>{{ formatCurrency(group.TongGiaTri) }}</span>
											</div>

											<v-progress-linear
												:model-value="thongKeKPI.TongGiaTri > 0 ? (group.TongGiaTri / thongKeKPI.TongGiaTri) * 100 : 0"
												:color="getColorByIndex(idx)" height="6" rounded>
											</v-progress-linear>
										</div>

										<div v-if="assetGroups.length === 0" class="text-caption text-center text-grey">
											Chưa có dữ liệu nhóm
										</div>
									</v-col>
								</v-row>
							</v-card-text>
						</v-card>
					</v-col>

					<v-col cols="12" md="3">
						<v-card elevation="2" rounded="lg"
							class="h-100 pa-4 d-flex flex-column justify-center align-center bg-white position-relative">

							<div class="position-absolute top-0 right-0 pa-2" style="z-index: 10;">
								<v-tooltip location="start" max-width="300" open-on-click>
									<template v-slot:activator="{ props }">
										<v-btn icon variant="text" size="small" color="grey-lighten-1" v-bind="props">
											<v-icon>mdi-information-outline</v-icon>
										</v-btn>
									</template>
									<div class="text-caption">
										<b>Tỷ lệ tài sản sẵn sàng sử dụng:</b><br>
										Thể hiện % tài sản đang hoạt động tốt trên tổng số tài sản.<br>
										<hr class="my-1 border-white">
										<i>Công thức: (Tổng TS - Đang sửa) / Tổng TS</i><br>
										<span class="text-green-accent-2">• > 90%: Hệ thống ổn định</span><br>
										<span class="text-red-accent-2">• < 60%: Cần xem lại quy trình bảo trì</span>
									</div>
								</v-tooltip>
							</div>
							<v-progress-circular :model-value="tinhHieuSuatSuDung" :size="140" :width="15" color="teal">
								<div class="text-center">
									<div class="text-h4 font-weight-bold">{{ tinhHieuSuatSuDung }}%</div>
									<div class="text-caption text-grey">Hiệu suất</div>
								</div>
							</v-progress-circular>

							<div class="mt-4 text-center text-caption text-grey-darken-1">
								<v-icon icon="mdi-circle-small" color="teal"></v-icon> Tổng: {{
									formatNumber(thongKeKPI.TongTaiSan) }}
								<span class="mx-1">|</span>
								<v-icon icon="mdi-circle-small" color="grey"></v-icon> Mới: {{
									formatNumber(thongKeKPI.TaiSanMoi) }}
							</div>
						</v-card>
					</v-col>
				</v-row>

				<v-row class="mt-4">
					<v-col cols="12" sm="6" md="2" style="flex: 0 0 20%; max-width: 20%;">
						<v-card elevation="2" rounded="lg" class="pa-4 bg-indigo-lighten-5 h-100">
							<div class="d-flex justify-space-between align-center h-100">
								<div>
									<div class="text-caption text-indigo-darken-3 font-weight-bold text-uppercase">Tổng
										tài
										sản
									</div>
									<div class="text-h5 font-weight-black text-indigo-darken-4 mt-1">
										{{ formatNumber(thongKeKPI.TongTaiSan) }}
									</div>
								</div>
								<v-avatar color="white" size="40" class="elevation-1">
									<v-icon color="indigo-darken-2" size="24">mdi-cube-outline</v-icon>
								</v-avatar>
							</div>
						</v-card>
					</v-col>

					<v-col cols="12" sm="6" md="2" style="flex: 0 0 20%; max-width: 20%;">
						<v-card elevation="2" rounded="lg"
							class="pa-4 bg-blue-lighten-5 h-100 cursor-pointer hover-card" @click="showTaiSanCho">
							<div class="d-flex justify-space-between align-center h-100">
								<div>
									<div class="text-caption text-blue-darken-3 font-weight-bold text-uppercase">Chờ ĐV
										xác
										nhận
									</div>
									<div class="text-h5 font-weight-black text-blue-darken-4 mt-1">
										{{ slTaiSan.TongTaiSan || 0 }}
									</div>
								</div>
								<v-avatar color="white" size="40" class="elevation-1">
									<v-icon color="blue-darken-2" size="24">mdi-package-variant-closed-plus</v-icon>
								</v-avatar>
							</div>
						</v-card>
					</v-col>

					<v-col cols="12" sm="6" md="2" style="flex: 0 0 20%; max-width: 20%;">
						<v-card elevation="2" rounded="lg"
							class="pa-4 bg-green-lighten-5 h-100 cursor-pointer hover-card" @click="showBaoTri">
							<div class="d-flex justify-space-between align-center h-100">
								<div>
									<div class="text-caption text-green-darken-3 font-weight-bold text-uppercase">Bảo
										trì
										tài
										sản</div>
									<div class="text-h5 font-weight-black text-green-darken-4 mt-1">
										{{ slTaiSan.SoLuongChuaXacNhan || 0 }}
									</div>
								</div>
								<v-avatar color="white" size="40" class="elevation-1">
									<v-icon color="green-darken-2" size="24">mdi-rotate-3d-variant</v-icon>
								</v-avatar>
							</div>
						</v-card>
					</v-col>

					<v-col cols="12" sm="6" md="2" style="flex: 0 0 20%; max-width: 20%;">
						<v-card elevation="2" rounded="lg"
							class="pa-4 bg-orange-lighten-5 h-100 cursor-pointer hover-card" @click="showSuaTaiSan">
							<div class="d-flex justify-space-between align-center h-100">
								<div>
									<div class="text-caption text-orange-darken-3 font-weight-bold text-uppercase">Kỹ
										thuật
										xử
										lý</div>
									<div class="text-h5 font-weight-black text-orange-darken-4 mt-1">
										{{ slTaiSan.DangSua || 0 }}
									</div>
								</div>
								<v-avatar color="white" size="40" class="elevation-1">
									<v-icon color="orange-darken-2" size="24">mdi-tools</v-icon>
								</v-avatar>
							</div>
						</v-card>
					</v-col>

					<v-col cols="12" sm="6" md="2" style="flex: 0 0 20%; max-width: 20%;">
						<v-card elevation="2" rounded="lg" class="pa-4 bg-red-lighten-5 h-100 cursor-pointer hover-card"
							@click="showTaiSanCaNhanChoXacNhan">
							<div class="d-flex justify-space-between align-center h-100">
								<div>
									<div class="text-caption text-red-darken-3 font-weight-bold text-uppercase">Cá nhân
										xác
										nhận
									</div>
									<div class="text-h5 font-weight-black text-red-darken-4 mt-1">
										{{ slTaiSan.TaiSanCaNhanChoXacNhan || 0 }}
									</div>
								</div>
								<v-avatar color="white" size="40" class="elevation-1">
									<v-icon color="red-darken-2" size="24">mdi-account-alert</v-icon>
								</v-avatar>
							</div>
						</v-card>
					</v-col>
				</v-row>

				<v-row class="mt-4">
					<v-col cols="12">
						<h3 class="text-h6 font-weight-bold text-blue-grey mb-1">
							<v-icon start color="primary">mdi-chart-timeline-variant</v-icon> Phân Tích & Cảnh Báo
						</h3>
					</v-col>

					<v-col cols="12" md="4">
						<v-card elevation="2" rounded="lg" class="h-100 border-t-lg border-warning position-relative">

							<div class="position-absolute top-0 right-0 pa-2" style="z-index: 10;">
								<v-tooltip location="bottom" max-width="300" open-on-click>
									<template v-slot:activator="{ props }">
										<v-btn icon variant="text" size="small" color="grey-lighten-1" v-bind="props">
											<v-icon>mdi-information-outline</v-icon>
										</v-btn>
									</template>
									<div class="text-caption">
										<b>Cảnh báo hết hạn bảo hành:</b><br>
										Hiển thị các tài sản sẽ hết hạn bảo hành trong vòng <b class="text-warning">30
											ngày
											tới</b>.<br>
										<hr class="my-1 border-white">
										<i>Logic:</i> Dựa trên ngày hiện tại so với "Ngày hết hạn" trong hồ sơ.<br>
										<span class="text-green-accent-2">• Áp dụng cho:</span> Tất cả tài sản đang hoạt
										động (trong kho, đang dùng, chờ xác nhận...).<br>
										<span class="text-red-accent-2">• Hành động:</span> Cần kiểm tra kỹ thuật trước
										khi
										hết hạn hoặc lập kế hoạch gia hạn.
									</div>
								</v-tooltip>
							</div>
							<v-card-item>
								<template v-slot:prepend>
									<v-icon color="amber-darken-2" icon="mdi-shield-alert-outline"></v-icon>
								</template>
								<v-card-title class="text-subtitle-1 font-weight-bold">Sắp hết bảo hành (30
									ngày)</v-card-title>
							</v-card-item>
							<v-divider></v-divider>
							<v-list density="compact" lines="two" class="pa-0">
								<v-list-item v-for="(item, i) in canhBaoBaoHanh" :key="i">
									<template v-slot:prepend>
										<v-avatar color="amber-lighten-5" size="32"
											class="font-weight-bold text-amber-darken-3 text-caption">{{
												item.SoNgayConLai
											}}
										</v-avatar>
									</template>
									<v-list-item-title class="font-weight-medium text-caption">{{ item.TenTaiSan }}
									</v-list-item-title>
									<v-list-item-subtitle class="text-caption" style="font-size: 0.7rem !important;">
										{{ item.ViTri }} • Hết: {{ formatDate(item.NgayHetHanBaoHanh) }}
									</v-list-item-subtitle>
								</v-list-item>
								<div v-if="!canhBaoBaoHanh.length" class="text-center pa-4 text-grey text-caption">
									Không có dữ liệu
								</div>
							</v-list>
						</v-card>
					</v-col>

					<v-col cols="12" md="4">
						<v-card elevation="2" rounded="lg" class="h-100 border-t-lg border-info">
							<v-card-item>
								<template v-slot:prepend>
									<v-icon color="blue" icon="mdi-calendar-clock"></v-icon>
								</template>
								<v-card-title class="text-subtitle-1 font-weight-bold">Lịch bảo trì theo
									tháng</v-card-title>
							</v-card-item>
							<v-card-text class="pa-1 pr-2 overflow-y-auto" style="max-height: 360px;">
								<v-timeline density="compact" side="end" truncate-line="start" class="pt-2">
									<v-timeline-item v-for="(task, i) in lichBaoTri" :key="i"
										:dot-color="layMauLichBaoTri(task.LoaiTrangThai)" size="x-small">
										<div class="d-flex flex-column">
											<span class="text-caption font-weight-bold"
												:class="'text-' + layMauLichBaoTri(task.LoaiTrangThai)">
												{{ formatDate(task.NgayDuKien) }}

												<span v-if="task.LoaiTrangThai === 'Quá hạn'">(Trễ)</span>
												<span v-else-if="task.LoaiTrangThai === 'Đã xong'">(Đã và đang)</span>
												<span v-else-if="task.LoaiTrangThai === 'Sắp tới'">(Sắp tới)</span>
											</span>
											<span class="text-caption font-weight-medium">{{ task.TenLichBaoTri
											}}</span>
											<span class="text-caption text-grey" style="font-size: 0.7rem;">{{
												task.TenDoiTac
											}}</span>
										</div>
									</v-timeline-item>
								</v-timeline>
								<div v-if="!lichBaoTri.length" class="text-center pa-4 text-grey text-caption">Chưa có
									lịch
									bảo
									trì</div>
							</v-card-text>
						</v-card>
					</v-col>

					<v-col cols="12" md="4">
						<v-card elevation="2" rounded="lg" class="h-100 border-t-lg border-success">
							<v-card-item>
								<template v-slot:prepend>
									<v-icon color="green" icon="mdi-account-hard-hat"></v-icon>
								</template>
								<v-card-title class="text-subtitle-1 font-weight-bold">Top Kỹ Thuật Viên</v-card-title>
							</v-card-item>
							<v-table density="compact" class="bg-transparent">
								<tbody>
									<tr v-for="(nv, i) in hieuSuatDoiNgu" :key="i">
										<td>
											<div class="text-caption font-weight-bold">{{ nv.HoTen }}</div>
											<div class="text-caption text-grey" style="font-size: 10px;">
												{{ nv.TenPhongBan }}
											</div>
										</td>
										<td class="text-right">
											<div class="font-weight-bold text-caption">{{ nv.SoPhieuDaXuLy }}</div>
										</td>
										<td style="width: 60px">
											<v-progress-linear :model-value="nv.DiemKPI" color="success" height="4"
												rounded max="100"></v-progress-linear>
										</td>
									</tr>
									<tr v-if="!hieuSuatDoiNgu.length">
										<td colspan="3" class="text-center text-caption text-grey">Chưa có dữ liệu</td>
									</tr>
								</tbody>
							</v-table>
						</v-card>
					</v-col>
				</v-row>

				<v-row class="mt-4">

					<v-col cols="12" md="6">
						<v-card elevation="2" rounded="lg" class="h-100 d-flex flex-column">
							<v-card-item class="flex-shrink-0">
								<v-card-title class="text-subtitle-1 font-weight-bold">
									<v-icon start color="primary">mdi-chart-pie</v-icon> Phân bổ theo Loại tài sản
								</v-card-title>
							</v-card-item>

							<v-table density="compact" fixed-header height="400px" class="flex-grow-1">
								<thead>
									<tr>
										<th class="bg-grey-lighten-4">Loại danh mục</th>
										<th class="text-right bg-grey-lighten-4">Số lượng</th>
										<th class="text-right bg-grey-lighten-4">Giá trị</th>
									</tr>
								</thead>
								<tbody>
									<tr v-for="(cat, i) in categories" :key="i">
										<td>
											<v-avatar :color="layGiaoDienDanhMuc(cat.TenDanhMuc).mauNen" size="28"
												class="mr-2" rounded>
												<v-icon size="16" :color="layGiaoDienDanhMuc(cat.TenDanhMuc).mauSac">
													{{ layGiaoDienDanhMuc(cat.TenDanhMuc).bieuTuong }}
												</v-icon>
											</v-avatar>
											<span class="text-caption font-weight-medium">{{ cat.TenDanhMuc }}</span>
										</td>
										<td class="text-right text-caption font-weight-bold">{{ cat.SoLuong }}</td>
										<td class="text-right text-caption">{{ formatCurrency(cat.TongGiaTri) }}</td>
									</tr>
									<tr v-if="categories.length === 0">
										<td colspan="3" class="text-center text-caption text-grey pa-4">Không có dữ liệu
										</td>
									</tr>
								</tbody>
							</v-table>
						</v-card>
					</v-col>

					<v-col cols="12" md="6">
						<v-row>
							<v-col cols="12">
								<v-card elevation="2" rounded="lg" class="h-100">
									<v-card-item>
										<v-card-title class="text-subtitle-1 font-weight-bold">
											<v-icon start color="blue-grey">mdi-history</v-icon> Nhật ký hoạt động gần
											đây
										</v-card-title>
									</v-card-item>
									<v-list lines="two" density="compact" class="pa-0">
										<v-list-item v-for="(log, i) in nhatKyHoatDong.slice(0, 4)" :key="i">
											<template v-slot:prepend>
												<v-avatar size="32" :color="layGiaoDienNhatKy(log.LoaiHoatDong).mauSac"
													variant="tonal">
													<v-icon size="16">{{ layGiaoDienNhatKy(log.LoaiHoatDong).bieuTuong
													}}
													</v-icon>
												</v-avatar>
											</template>
											<v-list-item-title class="text-caption font-weight-bold">{{ log.LoaiHoatDong
											}}
											</v-list-item-title>
											<v-list-item-subtitle class="text-caption">{{ log.TenTaiSan }} • {{
												log.NguoiThucHien }}</v-list-item-subtitle>
											<template v-slot:append>
												<span class="text-caption text-grey">{{ dinhDangNgay(log.ThoiGian)
												}}</span>
											</template>
										</v-list-item>
									</v-list>
								</v-card>
							</v-col>

							<v-col cols="12">
								<v-card elevation="2" rounded="lg">
									<v-card-item>
										<v-card-title class="text-subtitle-1 font-weight-bold text-deep-purple">
											<v-icon start>mdi-store-alert</v-icon> Tỷ lệ lỗi theo Nhà Cung Cấp
										</v-card-title>
									</v-card-item>
									<v-card-text class="pb-2">
										<div v-for="(ncc, i) in hieuSuatNCC" :key="i" class="mb-3">
											<div class="d-flex justify-space-between mb-1">
												<span class="text-caption font-weight-medium">{{ ncc.TenNCC }}</span>
												<span class="text-caption font-weight-bold"
													:class="'text-' + layMauHieuSuatNCC(ncc.TyLeHong)">
													{{ ncc.TyLeHong }}%
												</span>
											</div>
											<v-progress-linear :model-value="ncc.TyLeHong"
												:color="layMauHieuSuatNCC(ncc.TyLeHong)" height="6" rounded striped>
											</v-progress-linear>
										</div>
										<div v-if="!hieuSuatNCC.length" class="text-center text-caption text-grey">Không
											có
											dữ
											liệu NCC</div>
									</v-card-text>
								</v-card>
							</v-col>
						</v-row>
					</v-col>
				</v-row>

				<v-row class="mt-4">
					<v-col cols="12">
						<div class="d-flex justify-space-between align-start mb-2">
							<div>
								<h3 class="text-h6 font-weight-bold text-blue-grey d-flex align-center">
									Tình trạng theo Cơ sở & Tòa nhà
									<v-tooltip location="bottom" max-width="300">
										<template v-slot:activator="{ props }">
											<v-icon v-bind="props" size="small" color="grey"
												class="ml-2">mdi-information-outline
											</v-icon>
										</template>
										<span>
											<b>Ý nghĩa quản trị:</b><br>
											- Giúp phát hiện các tài sản hư hỏng, sự cố tại các tòa nhà.<br>
											- Thanh màu đỏ càng dài nghĩa là tỷ lệ thiết bị hư hỏng đang chờ sửa chữa
											càng
											cao.
										</span>
									</v-tooltip>
								</h3>
								<div class="text-caption text-grey-darken-1">
									Thống kê quy mô tài sản và tỷ lệ hư hỏng/báo sửa tại từng khu vực.
								</div>
							</div>

						</div>
					</v-col>

					<v-col cols="12" md="4" v-for="(base, index) in facilities" :key="index">
						<v-card elevation="2" rounded="lg" border>
							<v-card-item>
								<template v-slot:prepend>
									<v-avatar color="grey-lighten-4" rounded>
										<v-icon color="primary">mdi-office-building-marker</v-icon>
									</v-avatar>
								</template>
								<v-card-title class="text-subtitle-1 font-weight-bold">{{ base.name }}</v-card-title>
								<v-card-subtitle>{{ base.address || 'Đang cập nhật' }}</v-card-subtitle>
							</v-card-item>

							<v-divider></v-divider>

							<v-card-text class="bg-grey-lighten-5 pt-3">
								<div v-for="b in base.buildings" :key="b.id" class="mb-4">
									<div class="d-flex justify-space-between align-center mb-1">
										<span class="text-caption font-weight-bold d-flex align-center">
											<v-icon :color="getHealthColor(b.healthScore)" size="10" icon="mdi-circle"
												class="mr-2">
											</v-icon>
											{{ b.name }}
										</span>
										<span class="text-caption text-grey-darken-1 font-weight-medium">{{
											formatCurrency(b.totalValue)
										}}</span>
									</div>

									<v-progress-linear :model-value="100" height="6" rounded class="mb-1">
										<template v-slot:default>
											<div class="bg-success h-100" :style="{ width: b.good + '%' }"></div>
											<div class="bg-error h-100" :style="{ width: b.error + '%' }"></div>
										</template>
									</v-progress-linear>

									<div class="d-flex justify-space-between text-caption">
										<span class="text-grey">Tổng: <b>{{ formatNumber(b.assetCount) }}</b> TS</span>
										<span v-if="b.errorCount > 0" class="text-red font-weight-bold">

											{{ b.errorCount }} cần sửa ({{ b.error }}%)
										</span>
										<span v-else class="text-success">
											<v-icon icon="mdi-check-circle-outline" size="12" start></v-icon>Hoạt động
											tốt
										</span>
									</div>
								</div>

								<div v-if="!base.buildings.length"
									class="text-center pa-4 text-grey text-caption font-italic">
									Chưa có dữ liệu tòa nhà
								</div>
							</v-card-text>
						</v-card>
					</v-col>
				</v-row>
			</div>

			<v-dialog v-model="dialog" max-width="900px">
				<v-card class="rounded-lg">
					<v-toolbar color="blue-lighten-5" density="compact">
						<v-toolbar-title class="text-blue-darken-3 font-weight-bold text-subtitle-1">Danh sách tài sản
							chờ
							xác nhận</v-toolbar-title>
						<v-btn icon="mdi-close" variant="text" @click="dialog = false"></v-btn>
					</v-toolbar>
					<v-card-text class="pa-0">
						<v-expansion-panels variant="accordion">
							<v-expansion-panel v-for="(group, phongBan) in groupedTaiSanChoXacNhan" :key="phongBan">
								<v-expansion-panel-title class="text-caption font-weight-bold bg-grey-lighten-4">
									{{ phongBan }} <v-chip size="x-small" color="blue" class="ml-2">{{
										group.length }}</v-chip>
								</v-expansion-panel-title>
								<v-expansion-panel-text class="pa-0">
									<v-data-table-virtual :items="group" :headers="headerDialog" density="compact"
										hide-default-footer height="300" item-value="MaCaBiet">
										<template v-slot:item.TenTaiSan="{ item }">
											<uc-asset-info classforname="text-subtitle-2" :tentaisan="item.TenTaiSan"
												:macabiet="item.MaCaBiet" :mataisan="item.MaTS"></uc-asset-info>
										</template>
									</v-data-table-virtual>
								</v-expansion-panel-text>
							</v-expansion-panel>
						</v-expansion-panels>
					</v-card-text>
				</v-card>
			</v-dialog>

			<v-dialog v-model="dialogSuaChuaTaiSan" max-width="900px">
				<v-card class="rounded-lg">
					<v-toolbar color="orange-lighten-5" density="compact">
						<v-toolbar-title class="text-orange-darken-3 font-weight-bold text-subtitle-1">Danh sách tài sản
							đang sửa chữa</v-toolbar-title>
						<v-btn icon="mdi-close" variant="text" @click="dialogSuaChuaTaiSan = false"></v-btn>
					</v-toolbar>
					<v-card-text class="pa-0">
						<v-expansion-panels variant="accordion">
							<v-expansion-panel v-for="(group, phongBan) in groupedSuaChuaTaiSan" :key="phongBan">
								<v-expansion-panel-title class="text-caption font-weight-bold bg-grey-lighten-4">
									{{ phongBan }} <v-chip size="x-small" color="orange" class="ml-2">{{
										group.length }}</v-chip>
								</v-expansion-panel-title>
								<v-expansion-panel-text class="pa-0">
									<v-data-table-virtual :items="group" :headers="headerSuaChuaTaiSan"
										density="compact" hide-default-footer height="300" item-value="MaCaBiet">
										<template v-slot:item.TenTaiSan="{ item }">
											<uc-asset-info classforname="text-subtitle-2" :tentaisan="item.TenTaiSan"
												:macabiet="item.MaCaBiet" :mataisan="item.MaTS"></uc-asset-info>
										</template>
									</v-data-table-virtual>
								</v-expansion-panel-text>
							</v-expansion-panel>
						</v-expansion-panels>
					</v-card-text>
				</v-card>
			</v-dialog>

			<v-dialog v-model="dialogCaNhanChoXacNhan" max-width="900px">
				<v-card class="rounded-lg">
					<v-toolbar color="red-lighten-5" density="compact">
						<v-toolbar-title class="text-red-darken-3 font-weight-bold text-subtitle-1">Tài sản cá nhân chờ
							xác nhận</v-toolbar-title>
						<v-btn icon="mdi-close" variant="text" @click="dialogCaNhanChoXacNhan = false"></v-btn>
					</v-toolbar>
					<v-card-text class="pa-0">
						<v-expansion-panels variant="accordion">
							<v-expansion-panel v-for="(group, nhomKey) in groupedTaiSanTheoNhanVien" :key="nhomKey">
								<v-expansion-panel-title class="text-caption font-weight-bold bg-grey-lighten-4">
									{{ nhomKey }} <v-chip size="x-small" color="red" class="ml-2">{{
										group.length }}</v-chip>
								</v-expansion-panel-title>
								<v-expansion-panel-text class="pa-0">
									<v-data-table-virtual :items="group" :headers="headersTaiSanTheoNhanVien"
										density="compact" hide-default-footer height="300" item-value="MaCaBiet">
										<template v-slot:item.TenTaiSan="{ item }">
											<uc-asset-info classforname="text-subtitle-2" :tentaisan="item.TenTaiSan"
												:macabiet="item.MaCaBiet" :mataisan="item.MaTS"></uc-asset-info>
										</template>
									</v-data-table-virtual>
								</v-expansion-panel-text>
							</v-expansion-panel>
						</v-expansion-panels>
					</v-card-text>
				</v-card>
			</v-dialog>

			<v-dialog v-model="showQrDialog" max-width="500px">
				<v-card rounded="lg">
					<v-toolbar color="bg-blue-grey-lighten-5" density="compact">
						<v-toolbar-title class="text-blue-darken-3 font-weight-bold text-subtitle-1">Quét mã tài sản
						</v-toolbar-title>
						<v-btn icon="mdi-close" variant="text" @click="showQrDialog = false"></v-btn>
					</v-toolbar>

					<v-card-text class="pa-0">
						<div style="width: 100%; aspect-ratio: 1; position: relative; background: #000;">
							<uc-qr v-model="maCaBietQuet" @scan-success="onScanSuccess" ref="qrScanner">
								<template #default>
									<div class="position-absolute bottom-0 w-100 d-flex justify-center pb-4"
										style="z-index: 2;">
										<div class="d-flex flex-column align-center">
											<v-btn icon variant="flat" color="white" class="mb-1"
												@click="$refs.qrScanner?.triggerFileInput()">
												<v-icon color="primary">mdi-image</v-icon>
											</v-btn>
											<span class="text-caption text-white font-weight-bold"
												style="text-shadow: 0 1px 2px rgba(0,0,0,0.8);">Thư viện ảnh</span>
										</div>
									</div>
								</template>
							</uc-qr>
						</div>

						<div class="pa-4 bg-white">
							<div class="text-caption text-grey mb-1">Không quét được? Nhập mã thủ công:</div>
							<div class="d-flex align-center">
								<v-text-field v-model="maCaBietQuet" variant="outlined" density="compact"
									prepend-inner-icon="mdi-keyboard" hide-details placeholder="Ví dụ: 2019..."
									class="mr-2" @keydown.enter="onScanSuccess"></v-text-field>

								<v-btn color="primary" variant="elevated" height="40" @click="onScanSuccess">
									<v-icon start>mdi-magnify</v-icon> Tìm
								</v-btn>
							</div>
						</div>
					</v-card-text>
				</v-card>
			</v-dialog>
			<uc-asset-info ref="assetInfoRef"></uc-asset-info>
		</v-container>
	</z-layout>
</template>

<script>
export default {
	name: "TrungTamDieuHanhTaiSan",
	data() {
		const schoolYears = taoNamHoc(3, 3);
		return {
			// --- BỘ LỌC MỚI ---
			filter: { year: schoolYears.currentSchoolYear, month: 0, maCoSo: 0 },
			listYears: schoolYears.list,
			listMonthsFull: [
				{ title: 'Cả năm', value: 0 },
				{ title: 'Tháng 1', value: 1 }, { title: 'Tháng 2', value: 2 }, { title: 'Tháng 3', value: 3 },
				{ title: 'Tháng 4', value: 4 }, { title: 'Tháng 5', value: 5 }, { title: 'Tháng 6', value: 6 },
				{ title: 'Tháng 7', value: 7 }, { title: 'Tháng 8', value: 8 }, { title: 'Tháng 9', value: 9 },
				{ title: 'Tháng 10', value: 10 }, { title: 'Tháng 11', value: 11 }, { title: 'Tháng 12', value: 12 }
			],
			pdfLoading: false,
			slTaiSan: {
				TongTaiSan: 0, // Chờ đơn vị xác nhận
				SoLuongChuaXacNhan: 0, // Bảo trì tài sản
				DangSua: 0, // Đang sửa chữa
				TaiSanCaNhanChoXacNhan: 0 // Cá nhân chờ
			},
			assetGroups: [],
			isLoading: false,
			tabHienTai: 'all', // Tabs điều khiển view danh sách
			timKiem: '', // Ô tìm kiếm nhanh

			// --- 1. Dữ liệu Tổng quan (KPI) ---
			thongKeKPI: {
				TongTaiSan: 0,
				ThieuMaQR: 0,
				TaiSanMoi: 0,
				DangLuanChuyen: 0,
				DangBaoSua: 0,
				TongGiaTri: 0
			},

			// --- 2. Dữ liệu Danh sách & Biểu đồ ---
			danhSachTaiSan: [], // Danh sách kho
			categories: [],     // Biểu đồ phân bổ
			facilities: [],     // Tình trạng cơ sở

			// --- 3. Dữ liệu Phân tích Nâng cao ---
			nhatKyHoatDong: [], // Timeline
			canhBaoBaoHanh: [], // Widget Bảo hành
			lichBaoTri: [],     // Widget Bảo trì
			hieuSuatNCC: [],    // Biểu đồ NCC
			hieuSuatDoiNgu: [], // Biểu đồ Nhân viên

			// --- 4. Controls UI ---
			dialogAdd: false,
			showQrDialog: false,
			maCaBietQuet: '',


			// Dữ liệu chi tiết cho Dialog
			dsTaiSanChoXacNhan: [],
			dsSuaChuaTaiSan: [],
			dsChoCaNhanXacNhan: [],

			// Dialog Controls
			dialog: false,
			dialogSuaChuaTaiSan: false,
			dialogCaNhanChoXacNhan: false,

			// Headers cho các bảng trong Dialog
			headerDialog: [
				{ title: "Mã tài sản", key: "MaVach" },
				{ title: "Tên tài sản", key: "TenTaiSan" },
				{ title: "Ngày chuyển", key: "NgayChuyen" },
			],
			headerSuaChuaTaiSan: [
				{ title: "Tên tài sản", key: "TenTaiSan" },
				{ title: "Vị trí", key: "TenViTriPhong" },
				{ title: "Mô tả", key: "GhiChu" },
				{ title: "Ngày báo", key: "NgayBaoSua" },
			],
			headersTaiSanTheoNhanVien: [
				{ title: 'Mã vạch', key: 'MaVach' },
				{ title: 'Tên tài sản', key: 'TenTaiSan' },
				{ title: 'Vị trí', key: 'TenViTriPhong' },
			],


		};
	},

	computed: {
		// --- LOGIC LẤY THÁNG THEO NĂM ---
		listMonths() {
			const selectedYear = this.filter.year;
			if (!selectedYear) return this.listMonthsFull;

			// Logic năm học: Tháng 6 -> 12 (Năm chọn), Tháng 1 -> 5 (Năm chọn + 1)
			// Hoặc nếu bạn muốn lịch dương lịch bình thường thì cứ trả listMonthsFull
			// Ở đây tôi giữ logic cũ của bạn (Năm học)
			const part1 = this.listMonthsFull.filter(m => m.value >= 6);
			const part2 = this.listMonthsFull.filter(m => m.value > 0 && m.value <= 5); return [this.listMonthsFull[0], // Cả năm
			...part1.map(m => ({ title: `${m.value}-${selectedYear}`, value: m.value })),
			...part2.map(m => ({ title: `${m.value}-${selectedYear + 1}`, value: m.value }))
			];
		},
		// --- Computed tích hợp từ trang cũ ---
		groupedTaiSanChoXacNhan() {
			const grouped = {};
			this.dsTaiSanChoXacNhan.forEach((item) => {
				const phongBan = item.TenPhongBan || 'Chưa xác định';
				if (!grouped[phongBan]) grouped[phongBan] = [];
				grouped[phongBan].push(item);
			});
			return grouped;
		},
		groupedSuaChuaTaiSan() {
			const grouped = {};
			this.dsSuaChuaTaiSan.forEach((item) => {
				const phongBan = item.TenPhongBan || 'Chưa xác định';
				if (!grouped[phongBan]) grouped[phongBan] = [];
				grouped[phongBan].push(item);
			});
			return grouped;
		},
		groupedTaiSanTheoNhanVien() {
			const grouped = {};
			this.dsChoCaNhanXacNhan.forEach((item) => {
				const key = `${item.HoTenNhanVien || 'Không rõ'} - ${item.TenViTriPhong || ''}`;
				if (!grouped[key]) grouped[key] = [];
				grouped[key].push(item);
			});
			return grouped;
		},

		tinhHieuSuatSuDung() {
			if (this.thongKeKPI.TongTaiSan === 0) return 0;
			const dangSuDung = this.thongKeKPI.TongTaiSan - this.thongKeKPI.DangBaoSua;
			return Math.round((dangSuDung / this.thongKeKPI.TongTaiSan) * 100);
		},

		danhSachLoc() {
			let data = this.danhSachTaiSan || [];

			if (this.tabHienTai === 'missingQr') {
				data = data.filter(i => !i.MaVach || i.MaVach === '');
			} else if (this.tabHienTai === 'new') {
				data = data.filter(i => i.TinhTrang == 8);
			}

			if (this.timKiem) {
				const k = this.timKiem.toLowerCase();
				data = data.filter(i =>
					(i.TenTaiSan && i.TenTaiSan.toLowerCase().includes(k)) ||
					(i.MaCaBiet && i.MaCaBiet.toString().includes(k)) ||
					(i.TenModel && i.TenModel.toLowerCase().includes(k))
				);
			}
			return data;
		}
	},
	mounted() {
		this.layDuLieuDashboard();
		this.initData();
	},

	methods: {
		// --- 1. LOGIC QUÉT QR (MỚI) ---
		async onScanSuccess() {
			// Kiểm tra xem có mã nào được nhập hoặc quét không
			if (this.maCaBietQuet) {
				// Đóng hộp thoại quét
				this.showQrDialog = false;

				// Gọi hàm open() của component uc-asset-info
				// Logic này lấy y chang từ TimKiem.vue
				if (this.$refs.assetInfoRef) {
					await this.$refs.assetInfoRef.open(this.maCaBietQuet);

					// Reset mã sau khi tìm để lần sau quét tiếp
					this.maCaBietQuet = '';
				} else {
					console.error("Không tìm thấy component uc-asset-info (ref='assetInfoRef')");
				}
			}
		},
		async exportToPDF() {
			// 1. Kiểm tra thư viện
			if (typeof window.html2pdf === 'undefined') {
				alert("Đang tải thư viện xuất PDF, vui lòng thử lại sau 5 giây!");
				return;
			}

			this.pdfLoading = true;

			// Đợi Vue vẽ lại giao diện (đề phòng có animation chưa xong)
			await this.$nextTick();

			try {
				// Lấy phần tử cần in theo ID đã đặt ở Template
				const element = document.getElementById('dashboard-content');
				if (!element) {
					alert("Lỗi: Không tìm thấy nội dung dashboard (id='dashboard-content').");
					this.pdfLoading = false;
					return;
				}

				// 2. Tính toán kích thước thực tế
				// Dashboard thường dài, nên ta đo chiều cao thật để tạo khổ giấy dài tương ứng
				const width = element.offsetWidth;
				const height = element.scrollHeight;

				// Chuyển đổi px sang pt (1px ~ 0.75pt) + lề an toàn (40pt)
				const pdfWidth = (width * 0.75) + 40;
				const pdfHeight = (height * 0.75) + 40;

				// 3. Tạo tên file có ngày giờ
				const today = new Date();
				const timeStr = today.toLocaleDateString('vi-VN').replace(/\//g, '-') + '_' + today.getHours() + 'h' +
					today.getMinutes();
				const fileName = `Dashboard_TaiSan_${timeStr}.pdf`;

				// 4. Cấu hình PDF
				const opt = {
					margin: [20, 20, 20, 20], // Lề: Trên, Trái, Dưới, Phải
					filename: fileName,
					image: { type: 'jpeg', quality: 0.98 }, // Chất lượng ảnh cao nhất
					html2canvas: {
						scale: 2, // Tăng độ nét (scale 2 là chuẩn)
						useCORS: true, // Cho phép tải ảnh từ server khác (avatar nhân viên...)
						scrollY: 0 // Khắc phục lỗi lệch hình khi cuộn chuột
					},
					jsPDF: {
						unit: 'pt', // Đơn vị point
						format: [pdfWidth, pdfHeight], // Khổ giấy tự động co giãn theo nội dung
						orientation: 'portrait'
					}
				};

				// 5. Thực hiện xuất
				await window.html2pdf().set(opt).from(element).save();

			} catch (error) {
				console.error("Lỗi xuất PDF:", error);
				alert("Có lỗi khi tạo file PDF: " + (error.message || error));
			} finally {
				this.pdfLoading = false;
			}
		},
		async initData() {
			this.isLoading = true;
			try {
				// CHUẨN BỊ PAYLOAD LỌC (QUAN TRỌNG)
				// Các API cũ của bạn có thể chưa nhận tham số này, nhưng cứ gửi đi để sau này sửa API backend sau.
				const payload = {
					Nam: Number(this.filter.year),
					Thang: Number(this.filter.month || 0),
				};

				// Gọi API Dashboard Mới (Truyền payload)
				await this.layDuLieuDashboard(payload);

				// Gọi API Nghiệp vụ Cũ (Chạy song song)
				await Promise.all([this.getSoLuongNghiepVu(payload), this.getThongKeBaoSua(payload)]);
			} catch (e) { console.error(e); } finally { this.isLoading = false; }
		},

		async getSoLuongNghiepVu() {
			try {
				// 1. Chờ đơn vị xác nhận
				// Cũ: const resCho = await axios.post("obj/ThongKe_DashBoard");
				const resCho = await axios.post("https://api.zentea.vn/work/obj/TS_ThongKe_DashBoard"); // Mới: Bỏ obj/

				// Xử lý dữ liệu trả về (Lấy phần tử đầu tiên nếu là mảng)
				if (resCho.data?.data) {
					const data = Array.isArray(resCho.data.data) ? resCho.data.data[0] : resCho.data.data;
					this.slTaiSan.TongTaiSan = data?.TongTaiSan || 0;
				}

				// 2. Bảo trì (Chờ xác nhận)
				// Cũ: const resBaoTri = await axios.post("obj/DotBaoTri_SelectByTrangThaiChuaXacNhan");
				const resBaoTri = await axios.post("https://api.zentea.vn/work/obj/TS_DotBaoTri_SelectByTrangThaiChuaXacNhan"); // Mới: Bỏ obj/

				if (resBaoTri.data?.data) {
					const data = Array.isArray(resBaoTri.data.data) ? resBaoTri.data.data[0] : resBaoTri.data.data;
					this.slTaiSan.SoLuongChuaXacNhan = data?.SoLuongChuaXacNhan || 0;
				}

				// 3. Cá nhân chờ xác nhận (Giữ nguyên vì đã dùng đúng API danh sách)
				const resCaNhan = await axios.post("TaiSan_Select_CaNhanChoXacNhan", {});
				const listCaNhan = this.safeArray(resCaNhan.data?.data);
				this.slTaiSan.TaiSanCaNhanChoXacNhan = listCaNhan.length;
				this.dsChoCaNhanXacNhan = listCaNhan;

			} catch (e) {
				console.error("Lỗi lấy số liệu nghiệp vụ:", e);
			}
		},

		async getThongKeBaoSua() {
			try {
				// Cũ: const res = await axios.post("obj/BaoSua_ThongKe");
				const res = await axios.post("https://api.zentea.vn/work/obj/TS_BaoSua_ThongKe"); // Mới: Bỏ obj/

				if (res.data?.data) {
					// Kiểm tra mảng và lấy phần tử [0]
					const data = Array.isArray(res.data.data) ? res.data.data[0] : res.data.data;
					this.slTaiSan.DangSua = data?.DangSua || 0;
				}
			} catch (e) {
				console.error("Lỗi thống kê báo sửa:", e);
			}
		},
		async getSoLuongNghiepVu() {
			try {
				// 1. Chờ đơn vị xác nhận
				const resCho = await axios.post("https://api.zentea.vn/work/obj/TS_ThongKe_DashBoard");
				if (resCho.data?.data) this.slTaiSan.TongTaiSan = resCho.data.data.TongTaiSan;

				// 2. Bảo trì (Chờ xác nhận)
				const resBaoTri = await axios.post("https://api.zentea.vn/work/obj/TS_DotBaoTri_SelectByTrangThaiChuaXacNhan");
				if (resBaoTri.data?.data) this.slTaiSan.SoLuongChuaXacNhan = resBaoTri.data.data.SoLuongChuaXacNhan;

				// 3. Cá nhân chờ xác nhận (Cần gọi list để đếm)
				const resCaNhan = await axios.post("TaiSan_Select_CaNhanChoXacNhan", {});
				const listCaNhan = this.safeArray(resCaNhan.data?.data);
				this.slTaiSan.TaiSanCaNhanChoXacNhan = listCaNhan.length;
				this.dsChoCaNhanXacNhan = listCaNhan; // Lưu luôn để dùng cho Dialog

			} catch (e) { console.error("Lỗi lấy số liệu nghiệp vụ:", e); }
		},

		async getThongKeBaoSua() {
			try {
				const res = await axios.post("https://api.zentea.vn/work/obj/TS_BaoSua_ThongKe");
				if (res.data?.data) this.slTaiSan.DangSua = res.data.data.DangSua;
			} catch (e) { console.error(e); }
		},

		// --- 4. Logic Click vào Card -> Hiện Dialog ---
		async showTaiSanCho() {
			this.dialog = true;
			if (this.dsTaiSanChoXacNhan.length === 0) {
				const res = await axios.post("CaBietTaiSan_Select_ChoXacNhan", {});
				this.dsTaiSanChoXacNhan = this.safeArray(res.data?.data);
			}
		},
		async showSuaTaiSan() {
			this.dialogSuaChuaTaiSan = true;
			if (this.dsSuaChuaTaiSan.length === 0) {
				const res = await axios.post("BaoSua_SelectByTinhTrangXuLy", { TinhTrang: 3 });
				this.dsSuaChuaTaiSan = this.safeArray(res.data?.data);
			}
		},
		async showTaiSanCaNhanChoXacNhan() {
			this.dialogCaNhanChoXacNhan = true;
			// Dữ liệu đã lấy ở bước initData rồi
		},
		showBaoTri() {
			// Chuyển trang theo logic cũ
			window.location.href = "https://danhmuc.zentea.vn/TBDC-DatLichBaoTri";
		},
		getColorByIndex(index) {
			const colors = ['blue-accent-2', 'orange-accent-2', 'purple-accent-2', 'teal-accent-2', 'red-accent-2'];
			return colors[index % colors.length];
		},
		formatNumber(val) {
			// Kiểm tra nếu null hoặc undefined thì trả về 0
			if (val === null || val === undefined || val === '') return '0';

			// Ép kiểu sang số (Number) trước khi format
			const num = Number(val);

			// Kiểm tra nếu không phải số hợp lệ (NaN)
			if (isNaN(num)) return '0';

			return num.toLocaleString('vi-VN');
		},
		// --- 1. KHAI BÁO HÀM safeArray (SỬA LỖI Ở ĐÂY) ---
		safeArray(arr) {
			if (!arr) return [];
			return Array.isArray(arr) ? arr : [];
		},

		// --- 2. HÀM XỬ LÝ DỮ LIỆU CƠ SỞ (ĐÃ UPDATE CHO KHỚP VỚI HÌNH NETWORK) ---
		async getTinhTrangCoSo() {
			try {
				// Gọi API
				const res = await axios.post('Dashboard_TinhTrangCoSo');

				// Lấy dữ liệu thô: Dựa vào hình Network, data nằm trong res.data.data
				const rawData = this.safeArray(res.data?.data || res.data);

				// Biến đổi từ dạng Bảng (SQL) sang dạng Cây (Vue)
				const facilitiesMap = {};

				rawData.forEach(row => {
					// Nếu Cơ sở chưa tồn tại trong map, tạo mới
					if (!facilitiesMap[row.MaCoSo]) {
						facilitiesMap[row.MaCoSo] = {
							name: row.TenCoSo, // Khớp với cột SQL: TenCoSo
							address: '',
							buildings: []
						};
					}

					// Tính toán chỉ số cho từng tòa nhà
					const total = row.SoLuongTaiSan || 0; // Khớp cột SQL: SoLuongTaiSan
					const error = row.SoLuongHong || 0; // Khớp cột SQL: SoLuongHong

					// Tính % lỗi (Tránh chia cho 0)
					const percentError = total > 0 ? Math.round((error / total) * 100) : 0;

					// Tính % tốt (Good = 100 - Error)
					const percentGood = 100 - percentError;

					// Điểm sức khỏe (Dùng để tô màu icon tròn)
					const healthScore = total > 0 ? Math.round(((total - error) / total) * 100) : 100;

					// Thêm tòa nhà vào danh sách con của Cơ sở
					facilitiesMap[row.MaCoSo].buildings.push({
						id: row.MaToaNha, // Khớp cột SQL: MaToaNha
						name: row.TenToaNha, // Khớp cột SQL: TenToaNha
						totalValue: row.TongGiaTri,// Khớp cột SQL: TongGiaTri
						assetCount: total,
						errorCount: error,
						error: percentError,
						good: percentGood,
						warning: 0,
						healthScore: healthScore
					});
				});

				// Chuyển Map thành Mảng và gán vào biến data
				this.facilities = Object.values(facilitiesMap);

			} catch (e) {
				console.error("Lỗi xử lý Tình trạng Cơ sở:", e);
				this.facilities = [];
			}
		},

		// --- 3. HÀM TỔNG HỢP GỌI API ---
		async layDuLieuDashboard() {
			this.isLoading = true;
			try {
				// Gọi song song các API chính
				const [
					resKPI,
					resKho,
					resDanhMuc,
					resTimeline,
					resBaoHanh,
					resBaoTri,
					resNCC,
					resTeam,
					resNhom
				] = await Promise.all([
					axios.post('Dashboard_ChiSoTongQuan'),
					axios.post('TaiSan_Select_TrongKho'),
					axios.post('Dashboard_LayThongKeDanhMuc'),
					axios.post('Dashboard_GetTimeline'),
					axios.post('Dashboard_CanhBaoBaoHanh'),
					axios.post('Dashboard_LichBaoTri'),
					axios.post('Dashboard_HieuSuatNhaCungCap'),
					axios.post('Dashboard_HieuSuatDoiKyThuat'),
					axios.post('Dashboard_LayThongKeNhomDanhMuc')
				]);

				// Xử lý dữ liệu trả về
				const kpiData = this.safeArray(resKPI.data?.data || resKPI.data);
				if (kpiData.length > 0) this.thongKeKPI = kpiData[0];

				this.danhSachTaiSan = this.safeArray(resKho.data?.data || resKho.data);
				this.categories = this.safeArray(resDanhMuc.data?.data || resDanhMuc.data);
				this.nhatKyHoatDong = this.safeArray(resTimeline.data?.data || resTimeline.data);
				this.canhBaoBaoHanh = this.safeArray(resBaoHanh.data?.data || resBaoHanh.data);
				this.lichBaoTri = this.safeArray(resBaoTri.data?.data || resBaoTri.data);
				this.hieuSuatNCC = this.safeArray(resNCC.data?.data || resNCC.data);
				this.hieuSuatDoiNgu = this.safeArray(resTeam.data?.data || resTeam.data);
				this.assetGroups = this.safeArray(resNhom.data?.data || resNhom.data);

				// QUAN TRỌNG: Gọi hàm lấy Tình trạng cơ sở riêng
				await this.getTinhTrangCoSo();

			} catch (error) {
				console.error("Lỗi tải dữ liệu Dashboard:", error);
			} finally {
				this.isLoading = false;
			}
		},

		// --- CÁC HÀM FORMAT GIAO DIỆN (GIỮ NGUYÊN) ---
		formatCurrency(value) {
			if (!value) return '0 ₫';
			return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value);
		},
		formatDate(dateStr) {
			if (!dateStr) return '';
			const d = new Date(dateStr);
			if (isNaN(d.getTime())) return dateStr;
			return d.toLocaleDateString('vi-VN');
		},
		dinhDangNgay(dateStr) { // Thêm hàm này vì template có dùng
			if (!dateStr) return '';
			const d = new Date(dateStr);
			if (isNaN(d.getTime())) return dateStr;
			return d.toLocaleDateString('vi-VN') + ' ' + d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
		},
		getHealthColor(score) {
			if (score >= 90) return 'success';
			if (score >= 70) return 'warning';
			return 'error';
		},
		layMauLichBaoTri(trangThai) {
			if (trangThai === 'Quá hạn') return 'red';
			if (trangThai === 'Đã xong') return 'green'; // Thêm dòng này
			return 'blue'; // Sắp tới
		},
		layMauHieuSuatNCC(tyLeHong) {
			if (tyLeHong > 10) return 'red';
			if (tyLeHong > 5) return 'orange';
			return 'green';
		},
		layGiaoDienNhatKy(loai) {
			if (loai === 'Nhập mới') return { bieuTuong: 'mdi-plus-circle', mauSac: 'green' };
			if (loai === 'Báo sửa') return { bieuTuong: 'mdi-wrench', mauSac: 'red' };
			if (loai === 'Luân chuyển') return { bieuTuong: 'mdi-truck-fast', mauSac: 'orange' };
			return { bieuTuong: 'mdi-information', mauSac: 'grey' };
		},
		layGiaoDienDanhMuc(tenDanhMuc) {
			const ten = tenDanhMuc ? tenDanhMuc.toLowerCase() : '';
			if (ten.includes('máy tính') || ten.includes('laptop') || ten.includes('pc')) return {
				bieuTuong: 'mdi-laptop', mauSac:
					'blue', mauNen: 'blue-lighten-5'
			};
			if (ten.includes('máy in') || ten.includes('photo')) return {
				bieuTuong: 'mdi-printer', mauSac: 'teal', mauNen:
					'teal-lighten-5'
			};
			if (ten.includes('nội thất') || ten.includes('bàn') || ten.includes('ghế')) return {
				bieuTuong: 'mdi-chair-rolling',
				mauSac: 'orange', mauNen: 'orange-lighten-5'
			};
			if (ten.includes('xe') || ten.includes('ô tô')) return { bieuTuong: 'mdi-car', mauSac: 'red', mauNen: 'red-lighten-5' };
			if (ten.includes('điện') || ten.includes('lạnh')) return {
				bieuTuong: 'mdi-lightning-bolt', mauSac: 'deep-purple',
				mauNen: 'deep-purple-lighten-5'
			};
			return { bieuTuong: 'mdi-package-variant', mauSac: 'grey', mauNen: 'grey-lighten-4' };
		},
		dialogAction(type) { if (type === 'QR') this.showQrDialog = true; },
		moDialogCapNhatQR(item) { console.log("Cập nhật QR:", item.TenTaiSan); }
	}
}
</script>