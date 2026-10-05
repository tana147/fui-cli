<template>
	<v-sheet class="uc-hoc-lieu-so pa-4">

		<!-- KPI cộng theo các trường tổng hợp của API; không đếm số dòng vì mỗi dòng là một môn/khối. -->
		<v-row dense class="mb-4">
			<v-col cols="12" sm="4">
				<v-card color="primary" variant="tonal" rounded="lg" elevation="0">
					<v-card-text class="d-flex align-center ga-3 py-3">
						<v-avatar color="primary" size="42" rounded="md">
							<v-icon color="white" size="22">mdi-book-multiple</v-icon>
						</v-avatar>
						<div>
							<div class="text-caption text-primary">Tổng số học liệu</div>
							<div class="text-h5 font-weight-bold text-primary">{{ totalHL }}</div>
						</div>
					</v-card-text>
				</v-card>
			</v-col>
			<v-col cols="12" sm="4">
				<v-card color="success" variant="tonal" rounded="lg" elevation="0">
					<v-card-text class="d-flex align-center ga-3 py-3">
						<v-avatar color="success" size="42" rounded="md">
							<v-icon color="white" size="22">mdi-sitemap</v-icon>
						</v-avatar>
						<div>
							<div class="text-caption text-success">Tổng nội dung học liệu</div>
							<div class="text-h5 font-weight-bold text-success">{{ filteredSummary.totalContent }}</div>
						</div>
					</v-card-text>
				</v-card>
			</v-col>
			<v-col cols="12" sm="4">
				<v-card color="info" variant="tonal" rounded="lg" elevation="0">
					<v-card-text class="d-flex align-center ga-3 py-3">
						<v-avatar color="info" size="42" rounded="md">
							<v-icon color="white" size="22">mdi-calendar-range</v-icon>
						</v-avatar>
						<div>
							<div class="text-caption text-info">Nội dung tạo/cập nhật trong khoảng thời gian đang lọc</div>
							<div class="text-h5 font-weight-bold text-info">{{ filteredSummary.totalContentInRange }}</div>
						</div>
					</v-card-text>
				</v-card>
			</v-col>
		</v-row>

		<!-- Filter khối -->
		<v-card rounded="lg" elevation="0" border class="mb-4 pa-3">
			<div class="d-flex align-center ga-2 flex-wrap">
				<v-icon size="16" color="primary">mdi-filter-outline</v-icon>
				<span class="text-caption text-medium-emphasis">Lọc theo khối:</span>
				<v-btn-toggle v-model="activeKhoi" color="primary" variant="outlined" density="compact" rounded="lg" divided>
					<v-btn :value="0" size="small" class="text-caption">Tất cả</v-btn>
					<v-btn v-for="k in khoiList" :key="k" :value="k" size="small" class="text-caption">Khối {{ k }}</v-btn>
				</v-btn-toggle>
				<v-spacer />
				<v-chip size="small" color="success" variant="tonal" prepend-icon="mdi-check-circle">Có nội dung: {{ totalHasND }}</v-chip>
				<v-chip size="small" color="warning" variant="tonal" prepend-icon="mdi-book-off-outline">Chưa có nội dung: {{ totalNoND }}</v-chip>
			</div>
		</v-card>

		<!-- Chart và bảng tách thành hai hàng đầy đủ để tránh bóp cột và xuống dòng tên môn. -->
		<v-row dense>

			<!-- Chart -->
			<v-col cols="12">
				<v-card rounded="lg" elevation="0" border height="100%">
					<v-card-title class="text-body-2 font-weight-medium text-medium-emphasis pa-3 pb-2">
						<v-icon size="16" color="primary" class="mr-1">mdi-chart-line</v-icon>
						Nội dung theo môn học
						<span class="text-caption text-medium-emphasis ml-2">(trong khoảng thời gian đang lọc)</span>
						<v-chip v-if="activeKhoi" size="x-small" color="primary" variant="tonal" class="ml-2">
							Khối {{ activeKhoi }}
						</v-chip>
					</v-card-title>
					<v-divider />
					<v-card-text class="pa-3">
						<!-- Mỗi cột đã mang tên môn trên trục ngang; không dùng legend để tránh hiểu nhầm
						     thành nhiều chuỗi theo khối. Khoảng ngày và khối chỉ là bộ lọc dữ liệu. -->
						<uc-chart-apex :options="chartOptions" />
					</v-card-text>
				</v-card>
			</v-col>

			<!-- Table -->
			<v-col cols="12">
				<!-- Tách rõ bảng tổng hợp khỏi khối hoạt động giáo viên bên dưới. -->
				<v-card rounded="lg" elevation="0" border class="mb-4">
					<v-card-title class="text-body-2 font-weight-medium text-medium-emphasis pa-3 pb-2">
						<v-icon size="16" color="primary" class="mr-1">mdi-table</v-icon>
						Tổng hợp học liệu theo môn
						<v-chip v-if="activeKhoi !== 0" size="x-small" color="primary" variant="tonal" class="ml-2">
							Khối {{ activeKhoi }}
						</v-chip>
					</v-card-title>
					<v-divider />
					<v-data-table :headers="tableHeaders" :items="filteredItems" :sort-by="[{ key: 'KhoiID', order: 'asc' }]"
						density="compact" hide-default-footer fixed-header height="420" :items-per-page="-1" hover class="uc-hoc-lieu-so__summary-table">

						<!-- Mỗi dòng giữ độc lập theo cặp Khối–Môn, tránh gộp các khối làm khó đối chiếu số liệu. -->
						<template #body="{ items }">
							<tr v-for="item in items" :key="item.MonHocID + '-' + item.KhoiID"
								class="v-data-table__tr">
								<td class="text-center align-middle">
									<v-chip size="x-small" color="primary" variant="tonal" label class="font-weight-bold">
										Khối {{ item.KhoiID }}
									</v-chip>
								</td>
								<td>
									<div class="d-flex align-center ga-2 py-1">
										<!-- Màu/icon lấy từ tblMonHoc; chỉ dùng màu hash và icon mặc định khi danh mục không có dữ liệu. -->
										<v-avatar size="28" :color="getSubjectColor(item)" rounded="sm" class="flex-shrink-0">
											<v-icon color="white" size="17">{{ getSubjectIcon(item) }}</v-icon>
										</v-avatar>
										<span class="text-body-2 font-weight-medium text-primary hover:underline">
											{{ item.TenMonHoc_HienThi }}
										</span>
									</div>
								</td>
				<td>
									<div v-if="Number(item.TongNoiDung || 0) > 0" class="d-flex align-center ga-2">
										<span class="text-body-2 font-weight-bold" style="min-width:28px;text-align:right">{{ Number(item.TongNoiDung || 0) }} mục</span>
										<v-progress-linear :model-value="Number(item.TongNoiDung || 0) / maxND * 100" color="primary" rounded height="5" style="width:60px;flex-shrink:0" />
									</div>
									<span v-if="Number(item.TongNoiDung || 0) === 0" class="text-disabled">Chưa có nội dung</span>
								</td>
								<td>
									<div class="d-flex align-center ga-2">
										<span class="text-body-2 font-weight-bold text-success" style="min-width:28px;text-align:right">{{ Number(item.TongNoiDungTrongKhoang || 0) }} mục</span>
										<v-progress-linear :model-value="Number(item.TongNoiDung || 0) > 0 ? Number(item.TongNoiDungTrongKhoang || 0) / Number(item.TongNoiDung || 0) * 100 : 0" color="success" rounded height="5" style="width:60px;flex-shrink:0" />
									</div>
								</td>
								<!-- Nút rõ ràng để người dùng biết record có thể mở dialog chi tiết. -->
								<td>
									<v-btn size="x-small" variant="tonal" color="primary" prepend-icon="mdi-eye-outline"
										class="text-none" @click.stop="openDetailMonHoc(item)">
										Xem chi tiết
									</v-btn>
								</td>
							</tr>
						</template>


						<!-- Footer tổng -->
						<template #bottom>
							<v-divider />
							<div class="d-flex align-center px-4 py-2 ga-3 flex-wrap bg-primary-lighten-5">
								<span class="text-caption font-weight-bold text-primary text-uppercase">Tổng cộng</span>
								<v-spacer />
								<div class="d-flex align-center ga-1">
									<v-icon size="13" color="primary">mdi-book-multiple</v-icon>
										<span class="text-body-2 font-weight-bold text-primary">{{ filteredSummary.total }} học liệu</span>
								</div>
								<v-divider vertical class="mx-1" />
								<div class="d-flex align-center ga-1">
									<v-icon size="13" color="success">mdi-check-circle</v-icon>
									<span class="text-body-2 font-weight-bold text-success">
										{{ filteredSummary.totalContent }} nội dung
									</span>
								</div>
								<v-divider vertical class="mx-1" />
								<div class="d-flex align-center ga-1">
									<v-icon size="13" color="info">mdi-calendar-range</v-icon>
								<span class="text-body-2 font-weight-bold text-info">{{ filteredSummary.totalContentInRange }} trong khoảng thời gian đang lọc</span>
								</div>
								<v-divider vertical class="mx-1" />
								<div class="d-flex align-center ga-1">
									<v-icon size="13" color="warning">mdi-book-off-outline</v-icon>
									<span class="text-body-2 font-weight-bold text-warning">{{ filteredSummary.noContent }} chưa có</span>
								</div>
							</div>
						</template>
					</v-data-table>
				</v-card>
			</v-col>

		</v-row>

		<!-- Đặt bảng tổng hợp ở cuối phần chính để người xem đọc tổng quan môn học trước, sau đó mới xem ai thao tác nhiều nhất. -->
		<v-card rounded="lg" elevation="0" border class="mb-4">
			<v-card-title class="d-flex align-center ga-2 text-body-2 font-weight-bold text-primary pa-3">
				<v-icon size="18" color="primary">mdi-account-star-outline</v-icon>
					<div>
						<span>Giáo viên thao tác học liệu toàn khối</span>
						<div class="text-caption text-medium-emphasis">Thao tác tạo/cập nhật trong {{ activityPeriodLabel }}</div>
					</div>
					<v-spacer />
					<v-chip v-if="activeKhoi !== 0" size="x-small" color="primary" variant="tonal">
					Khối {{ activeKhoi }}
				</v-chip>
				<v-chip v-if="teacherActivityOverview.length > 0" size="x-small" color="warning" variant="tonal">
					Nhiều nhất: {{ teacherActivityOverview[0].TenGiaoVien }}
				</v-chip>
			</v-card-title>
			<v-divider />
			<v-data-table :headers="teacherActivityOverviewHeaders" :items="teacherActivityOverview"
				:loading="loadingTeacherActivity" density="compact" hide-default-footer :items-per-page="-1"
				class="text-caption" no-data-text="Chưa có giáo viên thao tác trong khoảng thời gian đang lọc"
				loading-text="Đang tổng hợp hoạt động giáo viên...">
				<template #item.TenGiaoVien="{ item }">
					<div class="d-flex align-center ga-2 py-1">
						<v-icon :color="item === teacherActivityOverview[0] ? 'warning' : 'info'" size="16">
							{{ item === teacherActivityOverview[0] ? 'mdi-star' : 'mdi-account' }}
						</v-icon>
						<span class="font-weight-bold">{{ item.TenGiaoVien }}</span>
					</div>
				</template>
				<template #item.SoMucThem="{ item }">
					<span class="font-weight-bold text-success">{{ item.SoMucThem }} mục</span>
				</template>
				<template #item.SoMucCapNhat="{ item }">
					<span class="font-weight-bold text-warning">{{ item.SoMucCapNhat }} mục</span>
				</template>
				<template #item.LoaiNoiDung="{ item }">
					<div class="d-flex flex-wrap ga-1">
						<v-chip v-if="item.SoCauTruc" size="x-small" color="amber-darken-2" variant="tonal">Tạo mục: {{ item.SoCauTruc }}</v-chip>
						<v-chip v-if="item.SoHocLieu" size="x-small" color="teal" variant="tonal">Tạo tài liệu: {{ item.SoHocLieu }}</v-chip>
						<v-chip v-if="item.SoCauHoi" size="x-small" color="deep-purple" variant="tonal">Tạo câu hỏi: {{ item.SoCauHoi }}</v-chip>
					</div>
				</template>
				<!-- Nút rõ ràng để người dùng biết có thể xem các node cụ thể của giáo viên. -->
				<template #item.actions="{ item }">
					<v-btn size="x-small" variant="tonal" color="primary" prepend-icon="mdi-eye-outline"
						class="text-none" @click="openTeacherActivityDetail(item)">
						Xem chi tiết
					</v-btn>
				</template>
			</v-data-table>
		</v-card>

		<!-- DIALOG CHI TIẾT GIÁO VIÊN TẠO VÀ CẬP NHẬT -->
		<v-dialog v-model="dialogDetail" max-width="1050px" scrollable>
			<v-card class="rounded-lg">
				<v-card-title class="d-flex align-center justify-space-between bg-light-blue-lighten-5 px-4 py-3">
					<div class="d-flex align-center ga-2">
						<v-icon color="primary">mdi-account-school</v-icon>
						<span class="text-h6 font-weight-bold text-primary">
							Chi tiết học liệu: {{ selectedMonHocItem?.TenMonHoc_HienThi }} (Khối {{ selectedMonHocItem?.KhoiID }})
						</span>
					</div>
					<v-btn icon="mdi-close" variant="text" size="small" @click="dialogDetail = false" />
				</v-card-title>

				<v-divider />

				<v-card-text class="pt-4" style="max-height: 75vh; overflow-y: auto;">
					<!-- Alert Tổng Quan -->
					<v-row dense class="mb-3">
						<!-- Môn chỉ có một học liệu không cần KPI đếm học liệu; chỉ hiện KPI này khi cần phân biệt nhiều học liệu. -->
						<v-col v-if="dialogHocLieuOptions.length > 1" cols="12" sm="4">
							<v-alert type="info" variant="tonal" :icon="false" class="py-2 mb-0 text-caption">
								<v-icon size="16" class="mr-1">mdi-book-multiple</v-icon>
								<strong>Tổng số học liệu:</strong> {{ totalBaiHocInDialog }} học liệu
							</v-alert>
						</v-col>
						<v-col cols="12" :sm="dialogHocLieuOptions.length > 1 ? 4 : 6">
							<v-alert type="success" variant="tonal" :icon="false" class="py-2 mb-0 text-caption">
								<v-icon size="16" class="mr-1">mdi-account-group</v-icon>
								<strong>Số giáo viên tham gia:</strong> {{ totalGiaoVienInDialog }} giáo viên
							</v-alert>
						</v-col>
						<v-col cols="12" :sm="dialogHocLieuOptions.length > 1 ? 4 : 6">
							<v-alert type="warning" variant="tonal" :icon="false" class="py-2 mb-0 text-caption">
								<v-icon size="16" class="mr-1">mdi-sitemap</v-icon>
								<strong>Tổng số mục nội dung:</strong> {{ totalMucNoiDungInDialog }} mục
							</v-alert>
						</v-col>
					</v-row>

					<!-- Khi có bộ lọc ngày, giữ toàn bộ cây nhưng dùng màu để phân biệt node tạo/cập nhật trong khoảng thời gian đang lọc. -->
						<v-alert v-if="NgayBatDau || NgayKetThuc || NienKhoa" type="info" variant="tonal" :icon="false" density="compact" class="mb-4 text-caption">
						<span class="mr-3"><span class="period-legend-dot period-legend-created" /> Xanh: tạo trong khoảng thời gian đang lọc</span>
						<span class="mr-3"><span class="period-legend-dot period-legend-updated" /> Vàng: cập nhật trong khoảng thời gian đang lọc</span>
						<span class="mr-3"><span class="period-legend-dot period-legend-both" /> Xanh dương: vừa tạo và cập nhật trong khoảng thời gian đang lọc</span>
						<span><span class="period-legend-dot period-legend-outside" /> Nền trắng: nội dung ngoài khoảng thời gian đang lọc</span>
					</v-alert>

					<!-- Môn có nhiều học liệu phải chọn một học liệu trước; tránh trộn nhiều cây nội dung trong cùng một chi tiết. -->
					<v-card v-if="dialogHocLieuOptions.length > 1" rounded="lg" elevation="0" border class="mb-4 pa-3">
						<v-select v-model="selectedHocLieuID" :items="dialogHocLieuOptions"
							item-title="title" item-value="value" label="Chọn học liệu để xem chi tiết"
							variant="outlined" density="compact" hide-details
							prepend-inner-icon="mdi-book-open-page-variant" />
					</v-card>

					<!-- Tổng hợp hoạt động giáo viên, không tính tài khoản hệ thống -->
					<v-card v-if="!loadingDetail && teacherActivitySummary.length > 0" rounded="lg" elevation="0" border class="mb-4">
						<v-card-title class="d-flex align-center ga-2 text-body-2 font-weight-bold text-primary pa-3">
							<v-icon size="18" color="primary">mdi-account-star-outline</v-icon>
							<span>Giáo viên thao tác học liệu</span>
							<v-spacer />
							<v-chip size="x-small" color="warning" variant="tonal">
								Nhiều nhất: {{ teacherActivitySummary[0].TenGiaoVien }}
						</v-chip>
					</v-card-title>
					<v-divider />
					<v-data-table :headers="teacherActivityHeaders" :items="teacherActivitySummary" density="compact"
							hide-default-footer :items-per-page="-1" class="text-caption">
							<template #item.TenGiaoVien="{ item }">
								<div class="d-flex align-center ga-2 py-1">
									<v-icon :color="item === teacherActivitySummary[0] ? 'warning' : 'info'" size="16">
										{{ item === teacherActivitySummary[0] ? 'mdi-star' : 'mdi-account' }}
									</v-icon>
									<span class="font-weight-bold">{{ item.TenGiaoVien }}</span>
								</div>
							</template>
							<template #item.SoMucThem="{ item }">
								<span class="font-weight-bold text-success">{{ item.SoMucThem }} mục</span>
							</template>
							<template #item.SoMucCapNhat="{ item }">
								<span class="font-weight-bold text-warning">{{ item.SoMucCapNhat }} mục</span>
							</template>
							<template #item.LoaiNoiDung="{ item }">
								<!-- Phân nhóm theo đúng ba thao tác của trang soạn học liệu để người dùng đọc ngay trong bảng. -->
								<div class="d-flex flex-wrap ga-1">
									<v-chip v-if="item.SoCauTruc" size="x-small" color="amber-darken-2" variant="tonal">Tạo mục: {{ item.SoCauTruc }}</v-chip>
									<v-chip v-if="item.SoHocLieu" size="x-small" color="teal" variant="tonal">Tạo tài liệu: {{ item.SoHocLieu }}</v-chip>
									<v-chip v-if="item.SoCauHoi" size="x-small" color="deep-purple" variant="tonal">Tạo câu hỏi: {{ item.SoCauHoi }}</v-chip>
								</div>
							</template>
						</v-data-table>
					</v-card>

					<!-- Loader khi đang tải dữ liệu -->
					<div v-if="loadingDetail" class="d-flex flex-column align-center justify-center py-12">
						<v-progress-circular indeterminate color="primary" size="48" class="mb-3" />
						<div class="text-caption text-medium-emphasis">Đang tải toàn bộ cấu trúc nội dung & thông tin tác giả...</div>
					</div>

					<!-- Một học liệu được chọn sẽ hiển thị riêng toàn bộ cây nội dung của nó. -->
					<div v-else-if="selectedDialogHocLieu" class="d-flex flex-column ga-3">
						<template v-for="bai in selectedDialogHocLieuList" :key="bai.HocLieuID">
								<div class="border rounded-lg pa-3 bg-white shadow-sm"
									:class="bai.TreeNodes && bai.TreeNodes.length > 0 ? 'border-success-lighten-2' : 'border-grey-lighten-2'">
					<!-- Tiêu đề học liệu cho phép xuống dòng; chip trạng thái không bị co mất chữ khi tên học liệu dài. -->
					<div class="d-flex align-center justify-space-between bg-primary-lighten-5 px-3 py-2 rounded border mb-2">
						<div class="d-flex align-start flex-wrap ga-2">
							<v-icon color="primary" size="20">mdi-book-open-page-variant</v-icon>
							<span class="font-weight-bold text-subtitle-1 text-primary flex-grow-1" style="min-width: 0; overflow-wrap: anywhere;">{{ bai.TenHocLieu }}</span>
							<v-chip size="x-small" class="flex-shrink-0" :color="bai.TreeNodes && bai.TreeNodes.length > 0 ? 'success' : 'grey'" variant="tonal">
								{{ bai.TreeNodes && bai.TreeNodes.length > 0 ? 'Có nội dung' : 'Chưa có nội dung' }}
							</v-chip>
							<v-chip size="x-small" class="flex-shrink-0" color="info" variant="tonal">
								{{ bai.TreeNodes?.length || 0 }} mục nội dung
							</v-chip>
							<v-chip v-if="periodNodeCount(bai) > 0" size="x-small" class="flex-shrink-0" color="warning" variant="tonal">
								{{ periodNodeCount(bai) }} mục trong khoảng thời gian đang lọc
											</v-chip>
										</div>
										<v-btn
											size="small"
											variant="text"
											color="primary"
											prepend-icon="mdi-open-in-new"
											class="text-caption text-none"
											@click="openBaiHoc(bai)"
										>
											Soạn thảo / Xem bài
										</v-btn>
									</div>

									<!-- Cây Nội Dung Lồng Nhau Dạng Cây Thư Mục Phân Cấp -->
									<div v-if="bai.TreeNodes && bai.TreeNodes.length > 0" class="my-2 d-flex flex-column ga-2">
										<div 
											v-for="node in bai.TreeNodes" 
											:key="node.NoiDungID" 
											class="position-relative border rounded pa-2 hover:bg-grey-lighten-5 transition-all shadow-sm"
											:class="getNodePeriodClass(node)"
											:style="{ marginLeft: `${(node.Level || 0) * 28}px` }"
										>
											<!-- Đường nhánh nối cây thư mục -->
											<div 
												v-if="(node.Level || 0) > 0" 
												class="position-absolute" 
												style="left: -18px; top: 50%; width: 16px; height: 2px; background-color: #CBD5E1;"
											></div>

							<v-row dense align="start" class="ma-0">
								<!-- Tên Mục & Icon Loại Nội Dung -->
								<v-col cols="7" class="d-flex align-start flex-wrap ga-1 pl-0">
															<v-icon :color="getNodeIconColor(node.LoaiNoiDung)" size="20" class="mt-1 flex-shrink-0">
																{{ getNodeIcon(node.LoaiNoiDung) }}
															</v-icon>
															
															<span 
																class="text-body-2 flex-shrink-1"
																style="min-width: 0; overflow-wrap: anywhere;"
														:class="isGroupNode(node.LoaiNoiDung) ? 'font-weight-bold text-uppercase text-grey-darken-4' : 'font-weight-medium text-grey-darken-3'"
													>
														{{ node.TenNoiDung }}
													</span>

													<v-chip 
														v-if="node.LoaiNoiDung" 
														size="x-small" 
														variant="tonal" 
														:color="getNodeIconColor(node.LoaiNoiDung)"
															class="text-caption font-weight-medium flex-shrink-0"
													>
															{{ formatLoaiNoiDungLabel(node.LoaiNoiDung) }}
															</v-chip>
															<!-- Node có cả hai mốc phải hiện hai chip riêng; tránh gộp thành chip vàng gây hiểu nhầm chỉ là cập nhật. -->
															<v-chip v-if="node.CreatedInPeriod" size="x-small" variant="flat" color="success" title="Tạo trong khoảng thời gian đang lọc" class="text-caption font-weight-medium flex-shrink-0">
																Được tạo trong khoảng thời gian đang lọc
															</v-chip>
															<v-chip v-if="node.UpdatedInPeriod" size="x-small" variant="flat" color="warning" title="Cập nhật trong khoảng thời gian đang lọc" class="text-caption font-weight-medium flex-shrink-0">
																Được cập nhật trong khoảng thời gian đang lọc
															</v-chip>
												</v-col>

								<!-- Tách riêng hai vai trò tạo/cập nhật để tên dài và thời gian không bị dính vào nhau. -->
								<v-col cols="5" class="text-caption text-medium-emphasis text-right">
									<div class="d-flex align-start justify-end ga-2 flex-wrap">
										<div v-if="!isHiddenCreator(node)" class="d-flex align-start flex-shrink-0" title="Tạo bởi">
											<div class="d-flex flex-column align-end" style="min-width: 0;">
												<span class="d-flex align-center ga-1 text-caption text-medium-emphasis">
													<v-icon size="13" color="info">mdi-account-plus</v-icon>
													Tạo bởi
												</span>
												<span class="font-weight-bold text-grey-darken-2">{{ getUserName(node, 'create') }}</span>
																						<span v-if="node.CreateTime" class="text-grey text-caption" style="font-size: 11px;">{{ formatDateTime(node.CreateTime) }}</span>
											</div>
										</div>
										<div v-if="node.UpdateUser && !isSystemUser(getUserCode(node, 'update')) && getUserName(node, 'update') !== getUserName(node, 'create')" class="d-flex align-start flex-shrink-0" title="Cập nhật gần nhất">
											<div class="d-flex flex-column align-end" style="min-width: 0;">
												<span class="d-flex align-center ga-1 text-caption text-medium-emphasis">
													<v-icon size="13" color="warning">mdi-account-edit</v-icon>
													Cập nhật
												</span>
												<span class="font-weight-bold text-grey-darken-2">{{ getUserName(node, 'update') }}</span>
																						<span v-if="node.UpdateTime" class="text-grey text-caption" style="font-size: 11px;">{{ formatDateTime(node.UpdateTime) }}</span>
											</div>
										</div>
									</div>
								</v-col>
											</v-row>
										</div>
									</div>
									<div v-else class="text-center py-5 text-medium-emphasis text-caption">
										<v-icon size="20" class="mr-1">mdi-file-document-outline</v-icon>
										Học liệu này chưa có nội dung.
									</div>
								</div>
						</template>
					</div>

					<div v-else class="text-center py-8 text-disabled">
						Chưa có học liệu cho môn học này.
					</div>
				</v-card-text>
			</v-card>
		</v-dialog>

		<!-- Dialog chi tiết hoạt động toàn khối của một giáo viên được chọn từ bảng tổng hợp. -->
		<v-dialog v-model="teacherActivityDetailDialog" max-width="1180px" scrollable>
			<v-card class="rounded-lg">
				<v-card-title class="d-flex align-center justify-space-between bg-light-blue-lighten-5 px-4 py-3">
					<div class="d-flex align-center ga-2">
						<v-icon color="primary">mdi-account-details-outline</v-icon>
						<div>
							<div class="text-h6 font-weight-bold text-primary">
								Chi tiết thao tác: {{ selectedTeacherActivity?.TenGiaoVien }}
							</div>
							<div class="text-caption text-medium-emphasis">Các mục đã tạo/cập nhật trong {{ activityPeriodLabel }}</div>
						</div>
					</div>
					<v-btn icon="mdi-close" variant="text" size="small" @click="teacherActivityDetailDialog = false" />
				</v-card-title>
				<v-divider />
				<!-- Nhóm theo khối/môn học/học liệu để đọc theo cấu trúc giống màn soạn học liệu. -->
				<v-card-text class="pa-3" style="max-height: 75vh; overflow-y: auto;">
					<div v-if="loadingTeacherActivityDetail" class="d-flex flex-column align-center justify-center py-12">
						<v-progress-circular indeterminate color="primary" size="42" class="mb-3" />
						<div class="text-caption text-medium-emphasis">Đang tải chi tiết thao tác...</div>
					</div>
					<div v-else-if="teacherActivityDetailGroups.length" class="d-flex flex-column ga-3">
						<v-card v-for="group in teacherActivityDetailGroups" :key="group.key" rounded="lg" elevation="0" border>
							<div class="d-flex align-center justify-space-between flex-wrap ga-2 bg-primary-lighten-5 px-3 py-2">
								<div class="d-flex align-center ga-2">
									<v-icon color="primary" size="20">mdi-book-open-page-variant</v-icon>
									<div>
										<div class="font-weight-bold text-primary">{{ group.TenHocLieu || 'Học liệu chưa đặt tên' }}</div>
										<div class="text-caption text-medium-emphasis">{{ group.TenMonHoc_HienThi || 'Chưa xác định môn học' }}</div>
									</div>
								</div>
								<div class="d-flex align-center ga-1">
									<v-chip size="x-small" color="primary" variant="tonal">Khối {{ group.KhoiID }}</v-chip>
									<v-chip size="x-small" color="info" variant="tonal">{{ group.rows.length }} mục</v-chip>
								</div>
							</div>
							<v-divider />
							<!-- Hiển thị theo Level của ParentID để người xem nhận ra cấu trúc cây thay vì danh sách phẳng. -->
							<div class="pa-2 d-flex flex-column ga-1">
								<div v-for="(item, index) in group.treeRows" :key="item.NoiDungID || group.key + '-' + index"
									:class="['uc-hoc-lieu-so__tree-row', 'uc-hoc-lieu-so__tree-level-' + Math.min(item.Level || 0, 6)]"
									:style="{ marginLeft: Math.min(item.Level || 0, 6) * 24 + 'px' }">
									<div class="d-flex align-center justify-space-between flex-wrap ga-2 border rounded pa-2">
										<div class="d-flex align-center ga-2" style="min-width: 0;">
											<v-icon v-if="item.Level > 0" color="grey" size="16">mdi-subdirectory-arrow-right</v-icon>
											<v-icon :color="getNodeIconColor(item.LoaiNoiDung)" size="20">
												{{ getNodeIcon(item.LoaiNoiDung) }}
											</v-icon>
											<div style="min-width: 0;">
												<div class="text-body-2 font-weight-medium" style="overflow-wrap: anywhere;">
													{{ item.TenNoiDung || 'Mục nội dung chưa đặt tên' }}
												</div>
												<div class="d-flex align-center flex-wrap ga-1 mt-1">
													<v-chip size="x-small" variant="tonal" :color="getNodeIconColor(item.LoaiNoiDung)">
														{{ formatLoaiNoiDungLabel(item.LoaiNoiDung) }}
													</v-chip>
												</div>
											</div>
										</div>
										<div class="d-flex align-center flex-wrap justify-end ga-1">
											<v-chip v-for="action in item.actions" :key="action.LoaiThaoTac + '-' + action.ThoiGianThaoTac"
												size="x-small" variant="tonal"
												:color="formatLoaiThaoTacLabel(action.LoaiThaoTac) === 'Cập nhật' ? 'warning' : 'success'">
												{{ formatLoaiThaoTacLabel(action.LoaiThaoTac) }} · {{ formatDate(action.ThoiGianThaoTac) }}
											</v-chip>
										</div>
									</div>
								</div>
							</div>
						</v-card>
					</div>
					<div v-else class="text-center py-8 text-disabled">Không có chi tiết thao tác</div>
				</v-card-text>
			</v-card>
		</v-dialog>
	</v-sheet>
</template>

<script>
	export default {
		name: 'UcHocLieuSo',
		props: {
			CapID:       { default: null },
			NienKhoa:    { default: null },  // Niên khóa dùng làm mốc mặc định khi không truyền ngày riêng
			NgayBatDau:  { default: null },  // 'YYYY-MM-DD' | null
			NgayKetThuc: { default: null },  // 'YYYY-MM-DD' | null
		},

		data() {
			return {
				items: [],
				subjectCatalog: [],
				activeKhoi: 0,
				dialogDetail: false,
				loadingDetail: false,
				selectedMonHocItem: null,
				selectedHocLieuID: null,
				dsGiaoVienBaiHoc: [],
				activityOverviewRows: [],
				loadingTeacherActivity: false,
				teacherActivityDetailDialog: false,
				loadingTeacherActivityDetail: false,
				selectedTeacherActivity: null,
				teacherActivityDetails: [],
				mapTeacherName: {},
				teacherActivityHeaders: [
					{ title: 'Giáo viên', value: 'TenGiaoVien', minWidth: '220px' },
					{ title: 'Đã thêm', value: 'SoMucThem', align: 'center', width: '100px' },
					{ title: 'Đã cập nhật', value: 'SoMucCapNhat', align: 'center', width: '115px' },
					{ title: 'Đã làm trong khoảng thời gian đang lọc', value: 'LoaiNoiDung', sortable: false },
				],
				teacherActivityOverviewHeaders: [
					{ title: 'Giáo viên', value: 'TenGiaoVien', minWidth: '220px' },
					{ title: 'Đã thêm', value: 'SoMucThem', align: 'center', width: '100px' },
					{ title: 'Đã cập nhật', value: 'SoMucCapNhat', align: 'center', width: '115px' },
					{ title: 'Đã làm trong khoảng thời gian đang lọc', value: 'LoaiNoiDung', sortable: false },
					{ title: 'Thao tác', value: 'actions', align: 'center', width: '125px', sortable: false },
				],
				teacherActivityDetailHeaders: [
					{ title: 'Khối', value: 'KhoiID', width: '70px' },
					{ title: 'Môn học', value: 'TenMonHoc_HienThi', width: '150px' },
					{ title: 'Học liệu', value: 'TenHocLieu', width: '190px' },
					{ title: 'Tên mục', value: 'TenNoiDung', minWidth: '240px' },
					{ title: 'Loại', value: 'LoaiNoiDung', width: '125px' },
					{ title: 'Thao tác', value: 'LoaiThaoTac', width: '105px' },
					{ title: 'Ngày', value: 'ThoiGianThaoTac', width: '105px' },
				],
				teacherHeaders: [
					{ title: 'Giáo viên (Tạo / Cập nhật)', value: 'TenGiaoVien', width: '220px' },
					{ title: 'Số bài', value: 'SoLuongBai', align: 'center', width: '90px' },
					{ title: 'Danh sách bài học & Thông tin chi tiết', value: 'DanhSachBai' },
				],
				SUBJECT_COLORS: [
					'primary', 'teal', 'deep-purple', 'indigo', 'cyan',
					'pink', 'blue', 'green', 'orange', 'red',
				],
				colorPalette: [
					'rgb(var(--v-theme-primary))',
					'#F59E0B', '#22C55E', '#F472B6',
					'#06B6D4', '#8B5CF6', '#EF4444',
					'#84CC16', '#F97316', '#EC4899',
					'#14B8A6', '#6366F1', '#A78BFA',
				],
				tableHeaders: [
					{ title: 'Khối',      value: 'KhoiID',             width: '8%',  sortable: true },
					{ title: 'Môn học',   value: 'TenMonHoc_HienThi', width: '29%', sortable: false },
					{ title: 'Tổng nội dung học liệu', value: 'TongNoiDung', width: '18%', sortable: false },
					{ title: 'Nội dung tạo/cập nhật trong khoảng thời gian đang lọc', value: 'TongNoiDungTrongKhoang', width: '30%', sortable: false },
					{ title: 'Thao tác',  value: 'actions',            width: '15%', sortable: false },
				],
			}
		},

		mounted() {
			this.getDSGiaoVienMap()
			if (this.CapID) this.onLoad()
		},
		watch: {
			CapID()       {
				// Đổi cấp học phải quay về "Tất cả" để không giữ bộ lọc Khối của cấp trước.
				this.activeKhoi = 0
				this.onLoad()
			},
			NienKhoa()    { this.onLoad() },
			NgayBatDau()  { this.onLoad() },
			NgayKetThuc() { this.onLoad() },
		},

		computed: {
			// API trả một dòng cho mỗi môn/khối; các KPI phải cộng số liệu trong dòng.
			summaryTotals() {
				return this.items.reduce((total, item) => {
					total.total += Number(item.TongHocLieu || 0)
					total.hasContent += Number(item.HocLieuCoNoiDung || 0)
					total.noContent += Number(item.HocLieuChuaCoNoiDung || 0)
					total.totalContent += Number(item.TongNoiDung || 0)
					total.totalContentInRange += Number(item.TongNoiDungTrongKhoang || 0)
					return total
				}, { total: 0, hasContent: 0, noContent: 0, totalContent: 0, totalContentInRange: 0 })
			},
			// Các KPI và chip trạng thái phải cùng phạm vi với bảng đang lọc theo Khối; tránh card tổng toàn cấp lệch với hai card nội dung.
			totalHL()    { return this.filteredSummary.total },
			totalHasND() { return this.filteredSummary.hasContent },
			totalNoND()  { return this.filteredSummary.noContent },
			filteredSummary() {
				return this.filteredItems.reduce((total, item) => {
					total.total += Number(item.TongHocLieu || 0)
					total.hasContent += Number(item.HocLieuCoNoiDung || 0)
					total.noContent += Number(item.HocLieuChuaCoNoiDung || 0)
					total.totalContent += Number(item.TongNoiDung || 0)
					total.totalContentInRange += Number(item.TongNoiDungTrongKhoang || 0)
					return total
				}, { total: 0, hasContent: 0, noContent: 0, totalContent: 0, totalContentInRange: 0 })
			},
			maxND()      { return Math.max(...this.items.map(i => Number(i.TongNoiDung || 0)), 1) },
			detailNodeCount() {
				// KPI nội dung bám theo học liệu đang chọn, không cộng dồn nhiều học liệu của cùng một môn.
				return this.selectedDialogHocLieu?.TreeNodes?.length || 0
			},

			khoiList() {
				return [...new Set(this.items.map(i => i.KhoiID))].sort((a, b) => a - b)
			},
			chartSubjects() {
				return [...new Set(this.items.map(i => i.TenMonHoc_HienThi))].sort()
			},
			activeKhoiList() {
				return this.activeKhoi === 0 ? this.khoiList : [this.activeKhoi]
			},
			subjectTotalMap() {
				return Object.fromEntries(
					this.chartSubjects.map(s => [
						s,
						this.items
							.filter(i => this.activeKhoiList.includes(i.KhoiID) && i.TenMonHoc_HienThi === s)
							.reduce((sum, i) => sum + Number(i.TongNoiDungTrongKhoang || 0), 0),
					])
				)
			},
			filteredItems() {
				return this.activeKhoi === 0
					? this.items
					: this.items.filter(i => i.KhoiID === this.activeKhoi)
			},
			// Chuẩn hóa danh sách học liệu từ các nhóm giáo viên để bộ chọn và phần chi tiết dùng cùng một nguồn.
			dialogHocLieuItems() {
				return this.dsGiaoVienBaiHoc.reduce((items, group) => {
					return items.concat((group.DanhSachBai || []).map(bai => ({
						...bai,
						TenGiaoVien: group.TenGiaoVien,
					})))
				}, [])
			},
			dialogHocLieuOptions() {
				return this.dialogHocLieuItems.map((bai, index) => ({
					title: bai.TenHocLieu || 'Học liệu ' + (index + 1),
					value: bai.HocLieuID,
				}))
			},
			selectedDialogHocLieu() {
				const items = this.dialogHocLieuItems
				if (!items.length) return null
				return items.find(bai => String(bai.HocLieuID) === String(this.selectedHocLieuID)) || items[0]
			},
			selectedDialogHocLieuList() {
				return this.selectedDialogHocLieu ? [this.selectedDialogHocLieu] : []
			},
			// API hoạt động dùng cùng bộ lọc ngày/niên khóa với màn hình; hiển thị phạm vi này cạnh card để tránh hiểu nhầm là số liệu toàn thời gian.
			activityPeriodLabel() {
				if (this.NgayBatDau || this.NgayKetThuc) {
					const start = this.NgayBatDau ? this.formatDate(this.NgayBatDau) : 'đầu kỳ'
					const end = this.NgayKetThuc ? this.formatDate(this.NgayKetThuc) : 'hiện tại'
					return `${start} – ${end}`
				}
				if (this.NienKhoa) {
					const schoolYear = Number(this.NienKhoa)
					return `${this.formatDate(`${this.NienKhoa}-08-01`)} – ${this.formatDate(`${schoolYear + 1}-05-31`)}`
				}
				return 'toàn bộ thời gian'
			},
			teacherActivityOverview() {
				// API trả theo từng khối; gộp lại ở UI khi xem "Tất cả" và lọc đúng khối đang chọn.
				const map = {}
				this.activityOverviewRows
					// Không đưa tài khoản kỹ thuật/test vào bảng giáo viên, chip "Nhiều nhất" hoặc file Excel.
					.filter(row => !this.isSystemUser(row.MaGV) && !this.isSystemUser(row.TenGiaoVien))
					.filter(row => this.activeKhoi === 0 || Number(row.KhoiID) === Number(this.activeKhoi))
					.forEach(row => {
						const key = row.MaGV || row.TenGiaoVien
						if (!map[key]) {
							map[key] = {
								MaGV: key,
								TenGiaoVien: row.TenGiaoVien,
								TongThaoTac: 0,
								SoMucThem: 0,
								SoMucCapNhat: 0,
								SoCauTruc: 0,
								SoHocLieu: 0,
								SoCauHoi: 0,
							}
						}
						Object.keys(map[key]).forEach(field => {
							if (field !== 'MaGV' && field !== 'TenGiaoVien') map[key][field] += Number(row[field] || 0)
						})
					})
				return Object.values(map).sort((a, b) => b.TongThaoTac - a.TongThaoTac || b.SoMucThem - a.SoMucThem || a.TenGiaoVien.localeCompare(b.TenGiaoVien))
			},
				chartSeries() {
					// Tổng hợp theo môn trong phạm vi khối/ngày đang chọn; API đã lọc ngày
					// trước khi items được đưa vào chart nên không được tách trục thành Khối.
					return [{
						name: 'Tổng nội dung',
						category: 'Tổng nội dung',
						data: this.chartSubjects.map(s => this.subjectTotalMap[s]),
						color: 'rgb(var(--v-theme-primary))',
					}]
				},
				chartOptions() {
					return {
						series: this.chartSeries,
						chart: {
							type: 'line',
							height: 380,
							toolbar: { show: false },
							fontFamily: 'inherit',
						},
						// Một chuỗi dữ liệu theo môn; line giúp so sánh liên tục khi có nhiều môn.
						colors: ['rgb(var(--v-theme-primary))'],
						stroke: { curve: 'smooth', width: 3 },
						markers: { size: 4, hover: { size: 6 } },
						legend: { show: false },
						dataLabels: {
							enabled: true,
							formatter: val => val > 0 ? val : '',
						},
						xaxis: {
							categories: this.chartSubjects,
							labels: {
								style: { fontSize: '11px' },
									rotate: -35,
							trim: true,
							maxHeight: 80,
						},
					},
					tooltip: { y: { formatter: val => val + ' nội dung' } },
					grid: { borderColor: 'rgba(128,128,128,0.15)', strokeDashArray: 4 },
				}
			},
			totalBaiHocInDialog() {
				// KPI lấy theo dòng tổng hợp để không đếm bản ghi placeholder mà API chi tiết có thể trả khi môn chưa có học liệu.
				const summaryCount = Number(this.selectedMonHocItem?.TongHocLieu)
				if (Number.isFinite(summaryCount)) return summaryCount
				return this.dsGiaoVienBaiHoc.reduce((sum, gv) => sum + (gv.DanhSachBai?.length || 0), 0)
			},
			totalGiaoVienInDialog() {
				// KPI phải dùng cùng nguồn với bảng hoạt động: chỉ đếm giáo viên thao tác node,
				// không đếm tài khoản tạo học liệu gốc như Luan hoặc tài khoản hệ thống.
				return this.teacherActivitySummary.length
			},
			teacherActivitySummary() {
				const map = {}
				const addActivity = (item, type) => {
					const code = this.getUserCode(item, type)
					if (!code || this.isSystemUser(code)) return
					const name = this.getUserName(item, type)
					if (!name || name === 'Giáo viên bộ môn' || name === '—') return

					if (!map[code]) {
						map[code] = {
							MaGV: code,
							TenGiaoVien: name,
							TongThaoTac: 0,
							SoMucThem: 0,
							SoMucCapNhat: 0,
							SoCauTruc: 0,
							SoHocLieu: 0,
							SoCauHoi: 0,
						}
					}

					const row = map[code]
					row.TongThaoTac++
					if (type === 'create') row.SoMucThem++
					if (type === 'update') row.SoMucCapNhat++

					// Đồng nhất với soan-hoc-lieu-v2: CHUONG/BAI/NHOM_KY_NANG là "Tạo mục",
					// QUIZ_* là "Tạo câu hỏi", các loại còn lại là "Tạo tài liệu".
					const loai = String(item.LoaiNoiDung || '').toUpperCase()
					if (['CHUONG', 'BAI', 'NHOM_KY_NANG'].includes(loai)) row.SoCauTruc++
					else if (loai.startsWith('QUIZ')) row.SoCauHoi++
					else row.SoHocLieu++
				}

				const selectedHocLieuID = this.selectedDialogHocLieu?.HocLieuID
				this.dsGiaoVienBaiHoc.forEach(gv => {
					(gv.DanhSachBai || [])
						.filter(bai => !selectedHocLieuID || String(bai.HocLieuID) === String(selectedHocLieuID))
						.forEach(bai => {
						;(bai.ActivityNodes || bai.FlatNodes || []).forEach(node => {
							addActivity(node, 'create')
							const creatorCode = this.getUserCode(node, 'create')
							const updaterCode = this.getUserCode(node, 'update')
							if (updaterCode && updaterCode !== creatorCode) addActivity(node, 'update')
						})
					})
				})

					return Object.values(map).sort((a, b) => b.TongThaoTac - a.TongThaoTac || b.SoMucThem - a.SoMucThem || a.TenGiaoVien.localeCompare(b.TenGiaoVien))
				},
				// Gom các dòng chi tiết theo khối/môn/học liệu, gộp các lần thao tác trên cùng node,
				// rồi duyệt theo ParentID để dialog hiển thị đúng cây nội dung.
				teacherActivityDetailGroups() {
					const groups = {}
					this.teacherActivityDetails.forEach((row, index) => {
						const key = [row.KhoiID, row.TenMonHoc_HienThi, row.TenHocLieu].map(value => String(value || '')).join('|') || String(index)
						if (!groups[key]) {
							groups[key] = {
								key,
								KhoiID: row.KhoiID,
								TenMonHoc_HienThi: row.TenMonHoc_HienThi,
								TenHocLieu: row.TenHocLieu,
								rows: [],
								nodeMap: {},
							}
						}

						// Một node có thể xuất hiện hai lần (Tạo và Cập nhật); gộp lại để mỗi node chỉ còn một dòng cây.
						const nodeKey = String(row.NoiDungID || key + '-' + index)
						if (!groups[key].nodeMap[nodeKey]) {
							groups[key].nodeMap[nodeKey] = { ...row, actions: [] }
							groups[key].rows.push(groups[key].nodeMap[nodeKey])
						}
						groups[key].nodeMap[nodeKey].actions.push({
							LoaiThaoTac: row.LoaiThaoTac,
							ThoiGianThaoTac: row.ThoiGianThaoTac,
						})
					})

					return Object.values(groups).map(group => ({
						...group,
						treeRows: this.buildTreeFromFlatNodes(group.rows),
					}))
				},
				totalMucNoiDungInDialog() {
					return this.detailNodeCount
				},
			},

		methods: {
			// Chuẩn hóa response của API học liệu: tAPI có thể trả trực tiếp một mảng,
			// nhiều result-set ([metadata, rows]) hoặc bọc qua data/rows/items.
			// Nếu không bóc đúng result-set chứa khóa định danh, dữ liệu vẫn có trong response nhưng UI sẽ render rỗng.
			normalizeApiRows(response, identityKey) {
				const parseValue = value => {
					if (typeof value !== 'string') return value
					const text = value.trim()
					if (!text) return []
					try {
						return JSON.parse(text)
					} catch {
						return value
					}
				}

				let value = parseValue(response)
				const wrapperKeys = ['data', 'rows', 'items', 'result', 'Data', 'Rows', 'Items', 'Result']
				for (let depth = 0; depth < 4 && value && !Array.isArray(value) && typeof value === 'object'; depth++) {
					const key = wrapperKeys.find(candidate => value[candidate] !== undefined && value[candidate] !== null)
					if (!key) break
					value = parseValue(value[key])
				}

				if (!Array.isArray(value)) return value && typeof value === 'object' ? [value] : []

				// Với response nhiều result-set, ưu tiên dataset có khóa định danh của loại dữ liệu đang cần.
				const nestedArrays = value.filter(Array.isArray)
				if (nestedArrays.length > 0) {
					const matchingRows = nestedArrays.find(rows => rows.some(row => row && typeof row === 'object' && row[identityKey] !== undefined && row[identityKey] !== null))
					return matchingRows || nestedArrays[1] || nestedArrays[0]
				}

				return value
			},

			buildTreeFromFlatNodes(flatNodes) {
				if (!Array.isArray(flatNodes) || flatNodes.length === 0) return []
				const map = {}
				const roots = []

				flatNodes.forEach(node => {
					if (node && node.NoiDungID !== undefined && node.NoiDungID !== null) {
						map[String(node.NoiDungID)] = { ...node, children: [], Level: 0 }
					}
				})

				flatNodes.forEach(node => {
					if (node && node.NoiDungID !== undefined && node.NoiDungID !== null) {
						const parentKey = node.ParentID ? String(node.ParentID) : null
						if (parentKey && map[parentKey]) {
							map[parentKey].children.push(map[String(node.NoiDungID)])
						} else {
							roots.push(map[String(node.NoiDungID)])
						}
					}
				})

				const result = []
				const traverse = (list, level = 0) => {
					list.forEach(item => {
						if (item) {
							item.Level = level
							result.push(item)
							if (item.children && item.children.length > 0) {
								traverse(item.children, level + 1)
							}
						}
					})
				}
				traverse(roots, 0)
				return result
			},

			getNodeIcon(loai) {
				if (!loai) return 'mdi-file-document-outline'
				const u = loai.toUpperCase()
				if (u.includes('CHUONG') || u.includes('THEME') || u.includes('TOPIC') || u.includes('CHUDU')) return 'mdi-folder-open'
				if (u.includes('BAI') || u.includes('LESSON')) return 'mdi-book-outline'
				if (u.includes('QUIZ') || u.includes('TEST') || u.includes('EXAM')) return 'mdi-help-circle-outline'
				if (u.includes('CANVA') || u.includes('SLIDE') || u.includes('PPT')) return 'mdi-presentation-play'
				if (u.includes('AUDIO') || u.includes('MP3')) return 'mdi-music-note'
				if (u.includes('VIDEO') || u.includes('MP4')) return 'mdi-video'
				return 'mdi-file-document-outline'
			},

			getNodeIconColor(loai) {
				if (!loai) return 'grey'
				const u = loai.toUpperCase()
				if (u.includes('CHUONG') || u.includes('THEME')) return 'warning'
				if (u.includes('BAI') || u.includes('LESSON')) return 'primary'
				if (u.includes('QUIZ') || u.includes('TEST')) return 'error'
				if (u.includes('SLIDE') || u.includes('CANVA')) return 'teal'
				return 'info'
			},

			formatLoaiNoiDungLabel(loai) {
				if (!loai) return 'Mục'
				const u = loai.toUpperCase()
				if (u.includes('CHUONG') || u.includes('THEME')) return 'Chủ đề / Chương'
				if (u.includes('BAI')) return 'Bài học'
				if (u.includes('QUIZ') || u.includes('TEST')) return 'Bài tập Quiz'
				return loai
			},

			// API cũ có thể trả chuỗi mất dấu như "C?p nh?t"; chuẩn hóa tại UI để không lộ lỗi mã hóa cho người dùng.
			formatLoaiThaoTacLabel(value) {
				const raw = String(value || '').trim()
				if (!raw) return 'Thêm mới'
				const compact = raw.toLowerCase().replace(/\s+/g, '')
				const withoutAccent = raw.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
				if (compact === 'c?pnh?t' || withoutAccent === 'cap nhat' || compact === 'update') return 'Cập nhật'
				// Dữ liệu lịch sử có thể đã lưu thành "T?o"; map cả chuỗi lỗi mã hóa và chuỗi không dấu về nhãn chuẩn.
				if (compact === 't?o' || withoutAccent === 'tao') return 'Tạo'
				if (withoutAccent === 'them moi' || compact === 'create' || compact === 'insert') return 'Thêm mới'
				return raw
			},

			isGroupNode(loai) {
				if (!loai) return false
				const u = loai.toUpperCase()
				return u.includes('CHUONG') || u.includes('THEME') || u.includes('BAI')
			},

			getUserCode(item, type) {
				if (!item) return ''
				const rawCode = type === 'create'
					? (item.CreateUser || item.CreatedBy || item.CreateBy || item.CreatorUser || item.CreatorID || item.TenNguoiTao || item.CreatedByName || item.NguoiTao)
					: (item.UpdateUser || item.UpdatedBy || item.UpdateBy || item.UpdaterUser || item.UpdaterID || item.TenNguoiCapNhat || item.UpdatedByName || item.NguoiCapNhat)
				if (!rawCode) return ''
				if (typeof rawCode === 'object') {
					return String(rawCode.UserCode || rawCode.UserID || rawCode.MaGV || rawCode.Code || '').trim().toUpperCase()
				}
				return String(rawCode).trim().toUpperCase()
			},

			getCreatorCode(item) {
				return this.getUserCode(item, 'create')
			},

			isSystemUser(code) {
				// Các tài khoản kỹ thuật/test không được tính là giáo viên tham gia thao tác.
				const normalized = String(code || '').trim().toUpperCase().replace(/\s+/g, '_')
				return ['NA0000022', 'LUAN', 'ANTIGRAVITY_FIX'].includes(normalized)
			},

			isHiddenCreator(item) {
				return this.isSystemUser(this.getCreatorCode(item))
			},

			async onLoad() {
				if (!this.CapID) return
				this.loadingTeacherActivity = true
				try {
					// Hai nguồn dùng cùng bộ lọc cấp/niên khóa/ngày để bảng môn và bảng giáo viên không lệch số liệu.
					const [items, activityRows, subjects] = await Promise.all([
						fetchPromise('lms/BaoCao_2_ThongKe_HocLieuSo_ByCapID', {
							CapID: this.CapID,
							NienKhoa: this.NienKhoa ?? null,
							NgayBatDau: this.NgayBatDau ?? null,
							NgayKetThuc: this.NgayKetThuc ?? null,
						}, { forceRefresh: true }),
						fetchPromise('lms/BaoCao_2_ThongKe_GiaoVienThaoTacHocLieuSo_ByCapID', {
							CapID: this.CapID,
							KhoiID: 0,
							NienKhoa: this.NienKhoa ?? null,
							NgayBatDau: this.NgayBatDau ?? null,
							NgayKetThuc: this.NgayKetThuc ?? null,
						}, { forceRefresh: true }),
						// API tổng hợp không trả Color/Icon; lấy danh mục môn theo đúng tblMonHoc để bảng dùng cấu hình gốc.
						fetchPromise('lms/MonHoc_Get_ByCapID', {
							CapID: this.CapID,
						}, { forceRefresh: true }),
					])
					this.subjectCatalog = Array.isArray(subjects) ? subjects : []
					this.items = Array.isArray(items) ? items : []
					this.activityOverviewRows = Array.isArray(activityRows) ? activityRows : []
				} catch (error) {
					console.error('Lỗi khi tải tổng hợp học liệu số:', error)
					this.items = []
					this.activityOverviewRows = []
				} finally {
					this.loadingTeacherActivity = false
				}
			},
			getSubjectMeta(item) {
				const subjectId = Number(item?.MonHocID)
				return this.subjectCatalog.find(subject => Number(subject.MonHocID) === subjectId) || {}
			},

			getSubjectColor(item) {
				const configuredColor = item?.Color || this.getSubjectMeta(item).Color
				if (configuredColor) return configuredColor
				const name = String(item?.TenMonHoc_HienThi || '')
				let hash = 0
				for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash)
				return this.SUBJECT_COLORS[Math.abs(hash) % this.SUBJECT_COLORS.length]
			},

			getSubjectIcon(item) {
				return item?.Icon || this.getSubjectMeta(item).Icon || 'mdi-book-open-variant'
			},

			async openDetailMonHoc(item) {
				this.selectedMonHocItem = item
				this.selectedHocLieuID = null
				this.dialogDetail = true
				this.loadingDetail = true
				this.dsGiaoVienBaiHoc = []

				try {
					await this.getDSGiaoVienMap()

					// Lấy toàn bộ học liệu của môn để vẫn hiển thị các học liệu chưa có nội dung;
					// khoảng ngày được áp dụng cho các node nội dung ngay bên dưới.
					const fetchedResponse = await fetchPromise('lms/FP_HocLieu_GetAll', {
						PageNumber: 1,
						PageSize: 999,
						KhoiID: item.KhoiID ?? 0,
						MonHocID: item.MonHocID ?? 0,
						BoSachID: 0,
						Loai: 'HOC_LIEU',
					}, { cache: false })
					const fetchedList = this.normalizeApiRows(fetchedResponse, 'HocLieuID')

					// Đồng bộ với bảng tổng hợp: nếu SP xác định chưa có học liệu thì bỏ bản ghi placeholder của endpoint chi tiết.
					const expectedHocLieuCount = Number(item.TongHocLieu)
					const rawList = expectedHocLieuCount === 0
						? []
						: fetchedList.filter(b => b.Loai !== 'TAI_NGUYEN' && b.TenHocLieu !== 'Tài nguyên đã tải lên')

					// 2. Lấy thông tin cây nội dung lồng nhau của từng bài học
					const updatedList = await Promise.all(rawList.map(async (bai) => {
						try {
							const treeRes = await fetchPromise('lms/FP_NoiDung_GetTreeByHocLieu', {
								HocLieuID: bai.HocLieuID,
							}, { cache: false })
							
							// Giữ toàn bộ node API để dialog luôn cho thấy đầy đủ học liệu, kể cả node nằm ngoài khoảng ngày.
							// Gắn cờ tạo/cập nhật trong khoảng thời gian đang lọc lên từng node để UI tô màu thay vì loại node khỏi cây.
							const nodes = this.normalizeApiRows(treeRes, 'NoiDungID')
							const allNodes = (nodes || []).map(node => ({
								...node,
								CreatedInPeriod: this.isDateInSelectedRange([node.CreateTime, node.CreateDate]),
																UpdatedInPeriod: this.hasRealUpdate(node) && this.isDateInSelectedRange([node.UpdateTime, node.UpdateDate]),
							}))

							// Dựng cây từ toàn bộ danh sách phẳng; không lọc mất học liệu khi kỳ lọc không có node phù hợp.
							const treeNodes = this.buildTreeFromFlatNodes(allNodes)
							const firstNode = allNodes.find(n => n && (n.CreateUser || n.UpdateUser || n.CreateBy || n.UpdateBy))

							const createUser = bai.CreateUser || bai.CreatedBy || firstNode?.CreateUser || firstNode?.CreateBy
							const updateUser = bai.UpdateUser || bai.UpdatedBy || firstNode?.UpdateUser || firstNode?.UpdateBy || createUser

							const baiDetail = {
								...bai,
								CreatedBy: createUser,
								CreateUser: createUser,
								UpdatedBy: updateUser,
								UpdateUser: updateUser
							}

							return {
								...baiDetail,
								TreeNodes: treeNodes,
								FlatNodes: allNodes,
								// Tách nguồn thống kê khỏi nguồn hiển thị: dialog giữ toàn bộ node, nhưng giáo viên chỉ được tính trong khoảng thời gian đang lọc.
								ActivityNodes: (this.NgayBatDau || this.NgayKetThuc || this.NienKhoa)
									? allNodes.filter(node => node.CreatedInPeriod || node.UpdatedInPeriod)
									: allNodes,
								CreatedDate: bai.CreatedDate || bai.CreateTime || firstNode?.CreateTime || firstNode?.CreateDate,
								UpdatedDate: bai.UpdatedDate || bai.UpdateTime || firstNode?.UpdateTime || firstNode?.UpdateDate,
								TenNguoiTao: this.getUserName(baiDetail, 'create'),
								TenNguoiCapNhat: this.getUserName(baiDetail, 'update')
							}
						} catch (e) {
							return bai
						}
					}))

					// 3. Nhóm bài học và tính Thống kê Loại Nội dung cho từng Giáo viên
					const mapGV = {}
					updatedList.forEach(bai => {
						const gvName = this.getUserName(bai, 'create')
						const gvKey = gvName
						if (!mapGV[gvKey]) {
							mapGV[gvKey] = {
								TenGiaoVien: gvName,
								MaGV: (bai.CreatedBy && bai.CreatedBy !== gvName) ? String(bai.CreatedBy).trim() : '',
								DanhSachBai: [],
								SoBaiGiang: 0,
								SoBaiTapQuiz: 0,
								TongSoMucTao: 0
							}
						}

						// Đếm số Bài giảng / Bài tập (Quiz) và Tổng số mục tạo từ FlatNodes
						let baiGiang = 0
						let baiTapQuiz = 0
						let tongMuc = (bai.FlatNodes || []).length

						;(bai.FlatNodes || []).forEach(node => {
							const loai = (node.LoaiNoiDung || '').toUpperCase()
							if (loai.includes('QUIZ') || loai.includes('TEST') || loai.includes('EXAM') || loai.includes('CHON') || loai.includes('DIEN')) {
								baiTapQuiz++
							} else {
								baiGiang++
							}
						})

						mapGV[gvKey].SoBaiGiang += baiGiang
						mapGV[gvKey].SoBaiTapQuiz += baiTapQuiz
						mapGV[gvKey].TongSoMucTao += tongMuc

						// Đảm bảo luôn hiển thị tất cả các cuốn sách trong bộ sách
						mapGV[gvKey].DanhSachBai.push({
							...bai,
							HocLieuCoNoiDung: (bai.TreeNodes && bai.TreeNodes.length > 0) || tongMuc > 0
						})
					})

					this.dsGiaoVienBaiHoc = Object.values(mapGV)
					// Môn có một hoặc nhiều học liệu đều mở từ học liệu đầu tiên; bộ chọn cho phép đổi sang học liệu khác.
					this.selectedHocLieuID = updatedList[0]?.HocLieuID ?? null
				} catch (error) {
					console.error('Lỗi khi lấy chi tiết học liệu:', error)
				} finally {
					this.loadingDetail = false
				}
			},

			async openTeacherActivityDetail(teacher) {
				this.selectedTeacherActivity = teacher
				this.teacherActivityDetailDialog = true
				this.loadingTeacherActivityDetail = true
				this.teacherActivityDetails = []

				try {
					// Chi tiết dùng cùng giáo viên, khối, niên khóa và khoảng ngày với bảng tổng hợp để số liệu có thể đối chiếu.
					const detailRows = await fetchPromise('lms/BaoCao_2_ChiTietGiaoVienThaoTacHocLieuSo_ByCapID', {
						CapID: this.CapID,
						KhoiID: this.activeKhoi || 0,
						MaGV: teacher.MaGV,
						NienKhoa: this.NienKhoa ?? null,
						NgayBatDau: this.NgayBatDau ?? null,
						NgayKetThuc: this.NgayKetThuc ?? null,
					}, { forceRefresh: true })
					this.teacherActivityDetails = Array.isArray(detailRows) ? detailRows : []
				} catch (error) {
					console.error('Lỗi khi tải chi tiết hoạt động giáo viên:', error)
					this.teacherActivityDetails = []
				} finally {
					this.loadingTeacherActivityDetail = false
				}
			},

			openBaiHoc(bai) {
				const url = `/soan-hoc-lieu-v2?HocLieuID=${bai.HocLieuID}&KhoiID=${bai.KhoiID || 0}&MonHocID=${bai.MonHocID || 0}&BoSachID=${bai.BoSachID || 0}`
				if (typeof openWindow === 'function') {
					openWindow({ title: `Soạn thảo / Xem bài: ${bai.TenHocLieu}`, url })
				} else {
					window.open(url, '_blank')
				}
			},

			formatDate(str) {
				if (!str) return ''
				try {
					const d = new Date(str)
					if (isNaN(d.getTime())) return str
					const day = String(d.getDate()).padStart(2, '0')
					const month = String(d.getMonth() + 1).padStart(2, '0')
					const year = d.getFullYear()
					return `${day}/${month}/${year}`
				} catch {
					return str
				}
			},

			formatDateTime(str) {
				if (!str) return ''
				const date = new Date(str)
				if (isNaN(date.getTime())) return this.formatDate(str)
				const dateLabel = this.formatDate(str)
				const hours = String(date.getHours()).padStart(2, '0')
				const minutes = String(date.getMinutes()).padStart(2, '0')
				return `${dateLabel} ${hours}:${minutes}`
			},

			// UpdateTime mặc định đôi khi được ghi ngay lúc tạo node. Chỉ xem là "cập nhật"
			// khi mốc cập nhật thực sự sau mốc tạo; nếu API có giờ thì vẫn phân biệt được cùng một ngày.
			hasRealUpdate(node) {
				const updateValue = node?.UpdateTime || node?.UpdateDate
				if (!updateValue) return false
				const createValue = node?.CreateTime || node?.CreateDate
				if (!createValue) return true
				const createTime = new Date(createValue).getTime()
				const updateTime = new Date(updateValue).getTime()
				if (isNaN(createTime) || isNaN(updateTime)) return true
				return updateTime > createTime
			},

			// Một node được đánh dấu nếu bất kỳ mốc ngày hợp lệ nào của cùng vai trò nằm trong khoảng thời gian đang lọc.
			isDateInSelectedRange(values) {
				// Đồng bộ với SP: nếu chỉ truyền niên khóa thì dùng 01/08 đến 31/05 làm khoảng mặc định.
				const startValue = this.NgayBatDau || (this.NienKhoa ? String(this.NienKhoa) + '-08-01' : null)
				const endValue = this.NgayKetThuc || (this.NienKhoa ? String(Number(this.NienKhoa) + 1) + '-05-31' : null)
				if (!startValue && !endValue) return false
				const startDate = startValue ? new Date(startValue + 'T00:00:00') : null
				const endDate = endValue ? new Date(endValue + 'T23:59:59') : null
				return (Array.isArray(values) ? values : [values]).some(value => {
					if (!value) return false
					const date = new Date(value)
					return !isNaN(date.getTime()) && (!startDate || date >= startDate) && (!endDate || date <= endDate)
				})
			},

			periodNodeCount(bai) {
				return (bai?.FlatNodes || []).filter(node => this.nodePeriodStatus(node)).length
			},

			nodePeriodStatus(node) {
				if (!node) return ''
				if (node.CreatedInPeriod && node.UpdatedInPeriod) return 'created-updated'
				if (node.CreatedInPeriod) return 'created'
				if (node.UpdatedInPeriod) return 'updated'
				return ''
			},

			getNodePeriodClass(node) {
				const status = this.nodePeriodStatus(node)
				if (status === 'created') return 'period-node-created'
				if (status === 'updated') return 'period-node-updated'
				if (status === 'created-updated') return 'period-node-both'
				// Chỉ tô màu khi node thực sự được tạo/cập nhật trong khoảng lọc; node còn lại giữ nền trắng.
				return 'period-node-outside'
			},

			getUserName(bai, type) {
				if (!bai) return 'Giáo viên bộ môn'
				
				// 1. Xác định mã người dùng
				let rawCode = null
				if (type === 'create') {
					// Nếu CreateUser là Luan hoặc admin, ưu tiên lấy UpdateUser để có giáo viên tạo/cập nhật thực tế
					if ((bai.CreateUser === 'Luan' || bai.CreatedBy === 'Luan' || bai.CreateUser === 'admin') && (bai.UpdateUser || bai.UpdatedBy)) {
						rawCode = bai.UpdateUser || bai.UpdatedBy
					} else {
						rawCode = bai.CreateUser || bai.CreatedBy || bai.TenNguoiTao || bai.CreatedByName || bai.NguoiTao || bai.UpdateUser || bai.UpdatedBy
					}
				} else {
					rawCode = bai.UpdateUser || bai.UpdatedBy || bai.TenNguoiCapNhat || bai.UpdatedByName || bai.NguoiCapNhat || bai.CreateUser || bai.CreatedBy
				}

				if (!rawCode || rawCode === 'N/A') return 'Giáo viên bộ môn'
				const cleanCode = String(rawCode).trim()
				const upperKey = cleanCode.toUpperCase()

				// 2. Tra cứu trực tiếp từ Bảng tên Giáo viên (NA0000022 -> Lê Chân Thiện Tâm, NV0001089 -> tên GV...)
				if (this.mapTeacherName[upperKey]) {
					return this.mapTeacherName[upperKey]
				}
				if (this.mapTeacherName[cleanCode]) {
					return this.mapTeacherName[cleanCode]
				}

				// 3. Nếu mã có khoảng trắng (đã là Họ Tên đầy đủ)
				if (cleanCode.includes(' ')) return cleanCode

				// 4. Nếu không tra thấy trong bảng GV, hiển thị trực tiếp mã định danh
				return cleanCode
			},

			async getDSGiaoVienMap() {
				if (Object.keys(this.mapTeacherName).length > 0) return
				try {
					const res = await fetchPromise('lms/GiaoVien_Get', {}, { cache: true })
					const list = Array.isArray(res) ? res : (res?.data || res?.items || [])
					if (Array.isArray(list)) {
						const newMap = {}
						list.forEach(gv => {
							const name = gv.HoTenGV || gv.TenGiaoVien || `${gv.HoGV || ''} ${gv.TenGV || ''}`.trim()
							const id = String(gv.GiaoVienID || gv.UserID || gv.UserCode || '').trim()
							if (id && name) {
								newMap[id] = name
								newMap[id.toUpperCase()] = name
							}
						})
						this.mapTeacherName = newMap
						console.log('[DEBUG] Đã tải danh sách Giáo viên:', Object.keys(newMap).length, 'thầy cô')
					}
				} catch (e) {
					console.warn('Không tải được danh sách tên GV:', e)
				}
			},

			getInitials(name) {
				if (!name) return 'GV'
				const parts = String(name).trim().split(' ')
				return parts[parts.length - 1].charAt(0).toUpperCase()
			},
		},
	}
</script>

<style scoped>
/* Khoảng thụt theo cấp cây; selector luôn có prefix component để không ảnh hưởng dialog khác trong module. */
.uc-hoc-lieu-so .uc-hoc-lieu-so__tree-level-0 { margin-left: 0; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__tree-level-1 { margin-left: 24px; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__tree-level-2 { margin-left: 48px; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__tree-level-3 { margin-left: 72px; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__tree-level-4 { margin-left: 96px; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__tree-level-5 { margin-left: 120px; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__tree-level-6 { margin-left: 144px; }
/* Chia tỷ lệ cố định để cột môn học không chiếm hết phần trống và đẩy nội dung sang quá xa. */
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table { table-layout: fixed; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table th:nth-child(1),
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table td:nth-child(1) { width: 8%; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table th:nth-child(2),
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table td:nth-child(2) { width: 29%; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table th:nth-child(3),
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table td:nth-child(3) { width: 18%; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table th:nth-child(4),
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table td:nth-child(4) { width: 30%; }
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table th:nth-child(5),
.uc-hoc-lieu-so .uc-hoc-lieu-so__summary-table .v-table__wrapper > table td:nth-child(5) { width: 15%; text-align: left; }
.period-legend-dot { display: inline-block; width: 9px; height: 9px; border-radius: 50%; margin-right: 4px; }
.period-legend-created { background: #16a34a; }
.period-legend-updated { background: #d97706; }
.period-legend-both { background: #2563eb; }
.period-legend-outside { background: #ffffff; border: 1px solid #cbd5e1; }
.period-node-created { background: #f0fdf4; border-color: #bbf7d0 !important; }
.period-node-updated { background: #fffbeb; border-color: #fde68a !important; }
.period-node-both {
	background: #eff6ff;
	border-color: #93c5fd !important;
}
.period-node-outside { background: #ffffff; border-color: #e5e7eb !important; }
</style>