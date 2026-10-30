<template>
	<v-sheet class="pa-4">

		<!-- KPI dùng nền tonal và không đổ bóng để giảm cảm giác nặng ở phần đầu báo cáo. -->
		<v-row dense class="mb-4">
			<v-col cols="12" sm="3">
				<v-card color="primary" variant="tonal" rounded="lg" elevation="0">
					<v-card-text class="d-flex align-center ga-3 py-3">
						<v-avatar color="primary" size="42" rounded="md">
							<v-icon color="white" size="22">mdi-book-education-outline</v-icon>
						</v-avatar>
						<div>
							<!-- KPI bám theo tab đang xem để không so số môn tổng hợp với số dòng của bảng chi tiết. -->
							<div class="text-caption text-primary">{{ subjectKpiLabel }}</div>
							<div class="text-h5 font-weight-bold text-primary">{{ subjectKpiValue }}</div>
						</div>
					</v-card-text>
				</v-card>
			</v-col>
			<!-- KPI nội dung được đổi theo tab để không gộp "đã tạo" với "đã giao". -->
			<v-col cols="12" sm="3">
				<v-card color="success" variant="tonal" rounded="lg" elevation="0">
					<v-card-text class="d-flex align-center ga-3 py-3">
						<v-avatar color="success" size="42" rounded="md">
							<v-icon color="white" size="22">mdi-file-plus-outline</v-icon>
						</v-avatar>
						<div>
							<div class="text-caption text-success">{{ resourceCreatedKpiLabel }}</div>
							<div class="text-h5 font-weight-bold text-success">{{ resourceCreatedKpiValue }}</div>
						</div>
					</v-card-text>
				</v-card>
			</v-col>
			<v-col cols="12" sm="3">
				<v-card color="info" variant="tonal" rounded="lg" elevation="0">
					<v-card-text class="d-flex align-center ga-3 py-3">
						<v-avatar color="info" size="42" rounded="md">
							<v-icon color="white" size="22">mdi-clipboard-text-outline</v-icon>
						</v-avatar>
						<div>
							<div class="text-caption text-info">{{ resourceAssignedKpiLabel }}</div>
							<div class="text-h5 font-weight-bold text-info">{{ resourceAssignedKpiValue }}</div>
						</div>
					</v-card-text>
				</v-card>
			</v-col>
			<v-col cols="12" sm="3">
				<v-card color="warning" variant="tonal" rounded="lg" elevation="0">
					<v-card-text class="d-flex align-center ga-3 py-3">
						<v-avatar color="warning" size="42" rounded="md">
							<v-icon color="white" size="22">mdi-clipboard-alert-outline</v-icon>
						</v-avatar>
						<div>
							<div class="text-caption text-warning">{{ resourceUnassignedKpiLabel }}</div>
							<div class="text-h5 font-weight-bold text-warning">{{ resourceUnassignedKpiValue }}</div>
						</div>
					</v-card-text>
				</v-card>
			</v-col>
		</v-row>

		<!-- Tabs + Legend cùng hàng -->
		<div class="d-flex align-center justify-space-between mb-3 flex-wrap ga-2">
			<v-tabs v-model="tabChiTiet" color="primary" density="compact">
				<v-tab :value="0">
					<v-icon start size="16">mdi-play-circle-outline</v-icon>Bài học
				</v-tab>
				<v-tab :value="1">
					<v-icon start size="16">mdi-clipboard-text-outline</v-icon>Bài tập
				</v-tab>
			</v-tabs>

			<!-- Legend 3 chip -->
			<div class="d-flex align-center ga-2">
				<span class="text-caption text-medium-emphasis">Mức độ:</span>
				<v-chip size="x-small" color="success" variant="tonal" label>
					<v-icon start size="10">mdi-circle</v-icon>
					Tốt ≥ 80%
				</v-chip>
				<v-chip size="x-small" color="warning" variant="tonal" label>
					<v-icon start size="10">mdi-circle</v-icon>
					Trung bình ≥ 50%
				</v-chip>
				<v-chip size="x-small" color="error" variant="tonal" label>
					<v-icon start size="10">mdi-circle</v-icon>
					Thấp &lt; 50%
				</v-chip>
			</div>
		</div>

		<!-- Bộ chọn và mô tả phạm vi là một nhóm; nút xuất đứng riêng để tránh khoảng trống lớn giữa các tác vụ trên màn rộng. -->
		<v-row dense align="center" class="mb-2">
			<v-col cols="12" md="9">
				<div class="d-flex align-center flex-wrap ga-3">
					<v-btn-toggle v-model="reportPeriodMode" mandatory color="primary" density="compact" variant="outlined">
						<v-btn value="range">Toàn khoảng ngày</v-btn>
						<v-btn value="weekly">Theo tháng / tuần</v-btn>
					</v-btn-toggle>
					<div class="text-caption text-medium-emphasis">
						<div class="text-body-2 font-weight-bold">Bộ lọc thời gian báo cáo</div>
						<div v-if="weeklyReportLoading">Đang tổng hợp các tuần...</div>
						<div v-else-if="weeklyReportError" class="text-error">Không tải được dữ liệu tuần</div>
						<div v-else-if="reportPeriodMode === 'weekly' && activeWeeklyWeek">
							{{ activeWeeklyWeek.title }} · {{ activeWeeklyWeek.rows.length }} lượt lớp–môn–giáo viên chưa giao
						</div>
						<div v-else-if="reportPeriodMode === 'weekly'">
							{{ dashboardDateRange.label }} · Không có lượt lớp–môn–giáo viên chưa giao
						</div>
						<div v-else>
							Toàn khoảng ngày · {{ dashboardDateRange.label }} · {{ weeklyMissingAssignments.length }} lượt lớp–môn–giáo viên chưa giao
						</div>
					</div>
				</div>
			</v-col>
			<v-col cols="12" md="3" class="d-flex justify-end">
				<v-btn color="success" variant="tonal" prepend-icon="mdi-microsoft-excel"
					:loading="weeklyReportLoading" :disabled="!CapID || !NgayBatDau || !NgayKetThuc"
					@click="exportWeeklyMissingHomework">
					{{ weeklyReportError ? 'Tải lại' : 'Xuất Excel' }}
				</v-btn>
			</v-col>
		</v-row>
		<template v-if="reportPeriodMode === 'weekly'">
			<v-tabs v-if="weeklyMissingGroups.length" v-model="weeklySelectedMonth" color="primary"
				density="compact" show-arrows center-active align-tabs="start">
				<v-tab v-for="month in weeklyMissingGroups" :key="month.key" :value="month.key"
					:class="weeklySelectedMonth === month.key ? 'bg-green-lighten-5' : ''">
					{{ month.title }}
					<v-chip size="x-small" color="warning" variant="tonal" label class="ml-2">{{ month.count }}</v-chip>
				</v-tab>
			</v-tabs>
			<v-divider v-if="activeWeeklyMonth" />
			<v-tabs v-if="activeWeeklyMonth" v-model="weeklySelectedWeek" color="primary"
				density="compact" show-arrows center-active align-tabs="start">
				<v-tab v-for="week in activeWeeklyMonth.weeks" :key="week.key" :value="week.key"
					:class="weeklySelectedWeek === week.key ? 'bg-green-lighten-5' : ''">
					<div class="d-flex flex-column align-start text-left">
						<span>{{ week.tabTitle }}</span>
						<span v-if="week.dateRangeLabel" class="text-caption text-medium-emphasis">{{ week.dateRangeLabel }}</span>
					</div>
					<v-chip size="x-small" variant="tonal" label class="ml-2">{{ week.rows.length }}</v-chip>
				</v-tab>
			</v-tabs>
			<div v-if="!weeklyReportLoading && !weeklyReportError && !weeklyMissingGroups.length"
				class="text-caption text-medium-emphasis mb-2">
				Không có lượt chưa giao để tạo tab tháng/tuần; báo cáo đang hiển thị toàn khoảng ngày đã chọn.
			</div>
		</template>
		<!-- Bộ đếm tab tuần lấy từ danh sách chưa giao; bảng và biểu đồ dùng API tổng hợp riêng theo ngày đã chọn. -->
		<v-alert v-if="reportPeriodMode === 'weekly' && activeWeeklyWeek && !loading && summaryError"
			 type="error" variant="tonal" density="compact" class="mb-3">
			Không tải được dữ liệu tổng hợp {{ tabChiTiet === 0 ? 'bài học' : 'bài tập' }} cho {{ dashboardDateRange.label }}.
		</v-alert>
		<v-alert v-else-if="reportPeriodMode === 'weekly' && activeWeeklyWeek && !loading && !summaryError && subjectKpiValue === 0"
			 type="info" variant="tonal" density="compact" class="mb-3">
			Bộ đếm tuần là {{ activeWeeklyWeek.rows.length }} lượt lớp–môn–giáo viên chưa giao bài tập. Báo cáo
			{{ tabChiTiet === 0 ? 'bài học' : 'bài tập' }} chưa có dữ liệu trong khoảng {{ dashboardDateRange.label }}.
		</v-alert>

		<v-tabs-window v-model="tabChiTiet">

			<!-- ===== TAB BÀI HỌC ===== -->
			<v-tabs-window-item :value="0">
				<v-row dense>

					<!-- Chart bài học -->
					<v-col cols="12" md="5">
						<v-card rounded="lg" elevation="0" border height="100%">
							<v-card-title class="text-body-2 font-weight-medium text-medium-emphasis pa-3 pb-2">
								<v-icon size="16" color="success" class="mr-1">mdi-chart-bar</v-icon>
								Tỉ lệ hoàn thành bài học
							</v-card-title>
							<v-divider />
							<v-card-text class="pa-3">
								<uc-chart-apex :options="chartBaiHoc" />
							</v-card-text>
						</v-card>
					</v-col>

					<!-- Bảng bài học -->
					<v-col cols="12" md="7">
						<v-card rounded="lg" elevation="0" border>
							<!-- Nhóm đầu là số lượng nội dung; nhóm sau chỉ phản ánh kết quả của bài đã giao. -->
							<div class="d-flex align-center justify-space-between flex-wrap ga-2 px-4 py-2 bg-grey-lighten-5 text-caption">
								<span class="font-weight-bold text-primary">Tổng bài học: đã tạo · chưa giao · đã giao</span>
								<span class="text-medium-emphasis">Kết quả bài đã giao: lượt học · HS hoàn thành · tỉ lệ</span>
							</div>
							<v-data-table :headers="headersBaiHoc" :items="dataBaiHoc" :loading="loading"
								item-value="MonHocID" density="comfortable" hover no-data-text="Không có dữ liệu"
								loading-text="Đang tải...">
								<template #loading>
									<v-skeleton-loader type="table-row@5" />
								</template>

								<template #item.stt="{ index }">
									<v-chip size="x-small" color="primary" variant="tonal" label>{{ index + 1
									}}</v-chip>
								</template>

								<template #item.TenMonHoc_HienThi="{ item }">
									{{ item.TenMonHoc_HienThi }}
								</template>

								<template #item.TotalLessons="{ item }">
									<v-chip color="primary" size="small" variant="tonal" label>{{ item.TotalLessons
									}}</v-chip>
								</template>

								<!-- Tiến độ chỉ tính trên bài đã giao; bài chưa giao vẫn được hiển thị để kiểm soát nội dung. -->
								<template #item.AssignedLessons="{ item }">
									<v-chip color="success" size="small" variant="tonal" label>{{ item.AssignedLessons
									}}</v-chip>
								</template>

								<template #item.UnassignedLessons="{ item }">
									<v-chip color="warning" size="small" variant="tonal" label>{{ item.UnassignedLessons
									}}</v-chip>
								</template>

								<template #item.TotalProgress="{ item }">
									<div class="d-flex align-center ga-1">
										<v-icon size="13" color="blue-grey">mdi-account-outline</v-icon>
										<span class="text-body-2">{{ item.TotalProgress }}</span>
										<span class="text-caption text-medium-emphasis">lượt</span>
									</div>
								</template>

								<template #item.TotalCompleted="{ item }">
									<div class="d-flex align-center ga-1">
										<v-icon size="13" color="success">mdi-account-check-outline</v-icon>
										<span class="text-body-2 font-weight-medium text-success">{{ item.TotalCompleted
										}}</span>
										<span class="text-caption text-medium-emphasis">/ {{ item.TotalProgress }}
											HS</span>
									</div>
								</template>

								<template #item.CompletionRate_Lessons="{ item }">
									<div class="d-flex align-center ga-2" style="min-width:140px">
										<v-progress-linear :model-value="item.CompletionRate_Lessons"
											:color="getRateColor(item.CompletionRate_Lessons)" bg-color="grey-lighten-3"
											rounded height="7" style="width:80px" />
										<v-chip size="x-small" :color="getRateColor(item.CompletionRate_Lessons)"
											variant="tonal" label style="min-width:52px; justify-content:center">
											{{ item.CompletionRate_Lessons }}%
										</v-chip>
									</div>
								</template>

								<template #bottom>
									<v-divider />
									<div class="d-flex align-center px-4 py-2 ga-3 flex-wrap bg-primary-lighten-5">
										<span class="text-caption font-weight-bold text-primary text-uppercase">Tổng
											cộng</span>
										<v-spacer />
										<div class="d-flex align-center ga-1">
											<v-icon size="13" color="primary">mdi-book-open-variant</v-icon>
										<span class="text-body-2 font-weight-bold text-primary">{{ tongBaiHoc }} bài
											học</span>
									</div>
									<v-divider vertical class="mx-1" />
									<div class="d-flex align-center ga-1">
										<v-icon size="13" color="success">mdi-clipboard-check-outline</v-icon>
										<span class="text-body-2 font-weight-bold text-success">{{ tongBaiHocDaGiao }} đã giao</span>
									</div>
									<v-divider vertical class="mx-1" />
									<div class="d-flex align-center ga-1">
										<v-icon size="13" color="warning">mdi-clipboard-outline</v-icon>
										<span class="text-body-2 font-weight-bold text-warning">{{ tongBaiHocChuaGiao }} chưa giao</span>
									</div>
									<v-divider vertical class="mx-1" />
									<div class="d-flex align-center ga-1">
											<v-icon size="13" color="blue-grey">mdi-account-outline</v-icon>
											<span class="text-body-2 font-weight-bold text-blue-grey">{{
												tongProgress_BaiHoc }} lượt học</span>
										</div>
										<v-divider vertical class="mx-1" />
										<div class="d-flex align-center ga-1">
											<v-icon size="13" color="success">mdi-account-check-outline</v-icon>
											<span class="text-body-2 font-weight-bold text-success">{{
												tongHoanThanh_BaiHoc }} HS hoàn thành</span>
										</div>
										<v-divider vertical class="mx-1" />
										<div class="d-flex align-center ga-1">
											<v-icon size="13"
												:color="getRateColor(+tyLeHoanThanh_BaiHoc)">mdi-percent</v-icon>
											<span class="text-body-2 font-weight-bold"
												:class="'text-' + getRateColor(+tyLeHoanThanh_BaiHoc)">
												{{ tyLeHoanThanh_BaiHoc }}% TB
											</span>
										</div>
									</div>
								</template>
							</v-data-table>
						</v-card>
					</v-col>
				</v-row>
			</v-tabs-window-item>

			<!-- ===== TAB BÀI TẬP ===== -->
			<v-tabs-window-item :value="1">
				<v-row dense>
					<!-- Chart bài tập -->
					<v-col cols="12" md="6">
						<v-card rounded="lg" elevation="0" border height="100%">
							<v-card-title class="text-body-2 font-weight-medium text-medium-emphasis pa-3 pb-2">
								<v-icon size="16" color="warning" class="mr-1">mdi-chart-bar-stacked</v-icon>
								Trạng thái nộp bài theo môn
							</v-card-title>
							<v-divider />
							<v-card-text class="pa-3 pb-1">
								<uc-chart-apex :options="chartBaiTap" />
							</v-card-text>
						</v-card>
					</v-col>
					<v-col cols="12" md="6">
						<v-card rounded="lg" elevation="0" border height="100%">
							<v-card-title class="text-body-2 font-weight-medium text-medium-emphasis pa-3 pb-2">
								<v-icon size="16" color="pink" class="mr-1">mdi-chart-bar</v-icon>
								Tỉ lệ nộp &amp; chấm bài (%)
							</v-card-title>
							<v-divider />
							<v-card-text class="pa-3">
								<uc-chart-apex :options="chartTiLe" />
							</v-card-text>
						</v-card>
					</v-col>

					<!-- Bảng bài tập -->
					<v-col cols="12" md="12">
						<v-card rounded="lg" elevation="0" border>
							<!-- Trạng thái nộp/chấm và các tỷ lệ bên phải chỉ tính trên bài tập đã giao. -->
							<div class="d-flex align-center justify-space-between flex-wrap ga-2 px-4 py-2 bg-grey-lighten-5 text-caption">
								<span class="font-weight-bold text-primary">Tổng bài tập: đã tạo · chưa giao · đã giao</span>
								<span class="text-medium-emphasis">Kết quả bài đã giao: HS · trạng thái · tỉ lệ nộp/chấm</span>
							</div>
							<v-data-table :headers="headersBaiTap" :items="dataBaiTap" :loading="loading"
								item-value="MonHocID" density="comfortable" hover no-data-text="Không có dữ liệu"
								loading-text="Đang tải...">
								<template #loading>
									<v-skeleton-loader type="table-row@5" />
								</template>

								<template #item.stt="{ index }">
									<v-chip size="x-small" color="primary" variant="tonal" label>{{ index + 1
									}}</v-chip>
								</template>

								<template #item.TenMonHoc_HienThi="{ item }">
									{{ item.TenMonHoc_HienThi }}
								</template>

								<template #item.TotalAssignments="{ item }">
									<v-chip color="primary" size="small" variant="tonal" label>{{ item.TotalAssignments
									}}</v-chip>
								</template>

								<!-- Trạng thái nộp/chấm chỉ được tính trên các bài đã giao. -->
								<template #item.AssignedAssignments="{ item }">
									<v-chip color="success" size="small" variant="tonal" label>{{ item.AssignedAssignments
									}}</v-chip>
								</template>

								<template #item.UnassignedAssignments="{ item }">
									<v-chip color="warning" size="small" variant="tonal" label>{{ item.UnassignedAssignments
									}}</v-chip>
								</template>

								<template #item.TotalAssigned="{ item }">
									<div class="d-flex align-center ga-1">
										<v-icon size="13" color="blue-grey">mdi-account-multiple-outline</v-icon>
										<span class="text-body-2">{{ item.TotalAssigned }}</span>
										<span class="text-caption text-medium-emphasis">HS</span>
									</div>
								</template>

								<template #item.trangThai="{ item }">
									<div class="d-flex align-center ga-1 flex-wrap">
										<v-tooltip text="Chưa làm" location="top">
											<template #activator="{ props }">
												<v-chip v-bind="props" size="x-small" color="grey" variant="tonal"
													label>
													<v-icon start size="10">mdi-minus-circle-outline</v-icon>{{
														item.Total_ChuaLam }}
												</v-chip>
											</template>
										</v-tooltip>
										<v-tooltip text="Đang làm" location="top">
											<template #activator="{ props }">
												<v-chip v-bind="props" size="x-small" color="blue" variant="tonal"
													label>
													<v-icon start size="10">mdi-pencil-outline</v-icon>{{
														item.Total_DangLam }}
												</v-chip>
											</template>
										</v-tooltip>
						<v-tooltip text="Đã nộp / chấm nháp" location="top">
											<template #activator="{ props }">
												<v-chip v-bind="props" size="x-small" color="warning" variant="tonal"
													label>
													<v-icon start size="10">mdi-upload-outline</v-icon>{{
														item.Total_DaNop }}
												</v-chip>
											</template>
										</v-tooltip>
										<v-tooltip text="Đã chấm" location="top">
											<template #activator="{ props }">
												<v-chip v-bind="props" size="x-small" color="success" variant="tonal"
													label>
													<v-icon start size="10">mdi-check-circle-outline</v-icon>{{
														item.Total_DaCham }}
												</v-chip>
											</template>
										</v-tooltip>
									</div>
								</template>

								<template #item.CompletionRate_Assignments="{ item }">
									<div class="d-flex align-center ga-2" style="min-width:140px">
										<v-progress-linear :model-value="item.CompletionRate_Assignments"
											:color="getRateColor(item.CompletionRate_Assignments)"
											bg-color="grey-lighten-3" rounded height="7" style="width:80px" />
										<v-chip size="x-small" :color="getRateColor(item.CompletionRate_Assignments)"
											variant="tonal" label style="min-width:52px; justify-content:center">
											{{ item.CompletionRate_Assignments }}%
										</v-chip>
									</div>
								</template>

								<template #item.CompletionRate_Graded="{ item }">
									<div class="d-flex align-center ga-2" style="min-width:130px">
										<v-progress-linear :model-value="item.CompletionRate_Graded"
											:color="getRateColor(item.CompletionRate_Graded)" bg-color="grey-lighten-3"
											rounded height="7" style="width:80px" />
										<v-chip size="x-small" :color="getRateColor(item.CompletionRate_Graded)"
											variant="tonal" label style="min-width:52px; justify-content:center">
											{{ item.CompletionRate_Graded }}%
										</v-chip>
									</div>
								</template>

								<template #bottom>
									<v-divider />
									<div class="d-flex align-center px-4 py-2 ga-3 flex-wrap bg-warning-lighten-5">
										<span class="text-caption font-weight-bold text-warning text-uppercase">Tổng
											cộng</span>
									<v-spacer />
									<div class="d-flex align-center ga-1">
										<v-icon size="13" color="primary">mdi-clipboard-text-outline</v-icon>
										<span class="text-body-2 font-weight-bold text-primary">{{ tongBaiTap }} đã tạo</span>
									</div>
									<v-divider vertical class="mx-1" />
									<div class="d-flex align-center ga-1">
										<v-icon size="13" color="success">mdi-clipboard-check-outline</v-icon>
										<span class="text-body-2 font-weight-bold text-success">{{ tongBaiTapDaGiao }} đã giao</span>
									</div>
									<v-divider vertical class="mx-1" />
									<div class="d-flex align-center ga-1">
										<v-icon size="13" color="warning">mdi-clipboard-outline</v-icon>
										<span class="text-body-2 font-weight-bold text-warning">{{ tongBaiTapChuaGiao }} chưa giao</span>
									</div>
									<v-divider vertical class="mx-1" />
									<div class="d-flex align-center ga-1">
										<v-icon size="13" color="blue-grey">mdi-account-multiple-outline</v-icon>
										<span class="text-body-2 font-weight-bold text-blue-grey">{{
											tongHocSinhDuocGiao_BaiTap }} HS được giao</span>
										</div>
										<v-divider vertical class="mx-1" />
										<v-chip size="x-small" color="grey" variant="tonal" label>Chưa làm: {{
											tongChuaLam }}</v-chip>
										<v-chip size="x-small" color="blue" variant="tonal" label>Đang làm: {{
											tongDangLam }}</v-chip>
						<v-chip size="x-small" color="warning" variant="tonal" label>Đã nộp / chấm nháp: {{
											tongDaNop }}</v-chip>
										<v-chip size="x-small" color="success" variant="tonal" label>Đã chấm: {{
											tongDaCham }}</v-chip>
										<v-divider vertical class="mx-1" />
										<div class="d-flex align-center ga-1">
											<v-icon size="13"
												:color="getRateColor(+tyLeHoanThanh_BaiTap)">mdi-percent</v-icon>
											<span class="text-body-2 font-weight-bold"
												:class="'text-' + getRateColor(+tyLeHoanThanh_BaiTap)">
												{{ tyLeHoanThanh_BaiTap }}% nộp TB
											</span>
										</div>
										<v-divider vertical class="mx-1" />
										<div class="d-flex align-center ga-1">
											<v-icon size="13"
												:color="getRateColor(+tyLeCham_BaiTap)">mdi-check-decagram-outline</v-icon>
											<span class="text-body-2 font-weight-bold"
												:class="'text-' + getRateColor(+tyLeCham_BaiTap)">
												{{ tyLeCham_BaiTap }}% chấm TB
											</span>
										</div>
									</div>
								</template>
							</v-data-table>
						</v-card>
					</v-col>
				</v-row>
			</v-tabs-window-item>

		</v-tabs-window>
	</v-sheet>
</template>

<script>
	export default {
		props: {
		CapID: { default: null },
		NienKhoa: { default: null },
		NgayBatDau: { default: null },
		NgayKetThuc: { default: null },
	},
	data() {
		return {
			loading: false,
			summaryError: false,
			tabChiTiet: 0,
			SUBJECT_COLORS: [
				'primary', 'teal', 'deep-purple', 'indigo', 'cyan',
				'pink', 'blue', 'green', 'orange', 'red',
			],
			dataTong: [],
			dataBaiHoc: [],
			dataBaiTap: [],
			weeklyMissingAssignments: [],
			weeklyReportLoading: false,
			weeklyReportError: false,
			weeklyReportRequestId: 0,
			summaryRequestId: 0,
			loadedSummaryQueryKey: '',
			reportPeriodMode: 'range',
			weeklySelectedMonth: '',
			weeklySelectedWeek: '',
			headersBaiHoc: [
				{ title: 'STT', key: 'stt', sortable: false, width: '60px' },
				{ title: 'Môn học', key: 'TenMonHoc_HienThi', sortable: true },
				{ title: 'Tổng bài học', key: 'TotalLessons', sortable: true, width: '105px' },
				{ title: 'Chưa giao', key: 'UnassignedLessons', sortable: true, width: '90px' },
				{ title: 'Đã giao', key: 'AssignedLessons', sortable: true, width: '85px' },
				{ title: 'Lượt học', key: 'TotalProgress', sortable: true, width: '110px' },
				{ title: 'HS hoàn thành', key: 'TotalCompleted', sortable: true, width: '150px' },
				{ title: 'Tỉ lệ hoàn thành', key: 'CompletionRate_Lessons', sortable: true, width: '170px' },
			],
			headersBaiTap: [
				{ title: 'STT', key: 'stt', sortable: false, width: '60px' },
				{ title: 'Môn học', key: 'TenMonHoc_HienThi', sortable: true },
				{ title: 'Tổng bài tập', key: 'TotalAssignments', sortable: true, width: '105px' },
				{ title: 'Chưa giao', key: 'UnassignedAssignments', sortable: true, width: '90px' },
				{ title: 'Đã giao', key: 'AssignedAssignments', sortable: true, width: '85px' },
				{ title: 'HS được giao', key: 'TotalAssigned', sortable: true, width: '120px' },
				{ title: 'Trạng thái', key: 'trangThai', sortable: false, width: '215px' },
				{ title: 'Tỉ lệ nộp', key: 'CompletionRate_Assignments', sortable: true, width: '160px' },
				{ title: 'Tỉ lệ chấm', key: 'CompletionRate_Graded', sortable: true, width: '160px' },
			],
		}
	},
		computed: {
		subjectKpiLabel() {
			return this.tabChiTiet === 0 ? 'Môn có bài học' : 'Môn có bài tập'
		},
		 subjectKpiValue() {
			return this.tabChiTiet === 0 ? this.dataBaiHoc.length : this.dataBaiTap.length
		},
		activeWeeklyMonth() {
			return this.weeklyMissingGroups.find(month => month.key === this.weeklySelectedMonth)
				|| this.weeklyMissingGroups[0]
				|| null
		},
		activeWeeklyWeek() {
			const month = this.activeWeeklyMonth
			if (!month) return null
			return month.weeks.find(week => week.key === this.weeklySelectedWeek) || month.weeks[0] || null
		},
		// Chọn tuần thì giới hạn cả biểu đồ và bảng hiện tại vào đúng ngày của tuần đó.
		dashboardDateRange() {
			const globalFrom = this.NgayBatDau ? String(this.NgayBatDau).slice(0, 10) : ''
			const globalTo = this.NgayKetThuc ? String(this.NgayKetThuc).slice(0, 10) : ''
			const week = this.reportPeriodMode === 'weekly' ? this.activeWeeklyWeek : null
			if (!week || !week.from || !week.to) {
				return {
					from: globalFrom,
					to: globalTo,
					isWeekly: false,
					label: globalFrom && globalTo
						? this.formatReportDate(globalFrom) + ' - ' + this.formatReportDate(globalTo)
						: '',
				}
			}

			// Tuần nằm sát biên khoảng lọc chỉ lấy phần giao nhau, tránh báo cáo ăn ra ngoài date range.
			const from = globalFrom && globalFrom > week.from ? globalFrom : week.from
			const to = globalTo && globalTo < week.to ? globalTo : week.to
			return {
				from,
				to,
				isWeekly: true,
				label: this.formatReportDate(from) + ' - ' + this.formatReportDate(to),
			}
		},
		// Dùng giá trị nguyên thủy để đổi tab trong cùng một tuần không gọi lại báo cáo dư thừa.
		dashboardDateRangeKey() {
			const range = this.dashboardDateRange
			return range.from + '|' + range.to
		},
		// Theo dõi cấp/năm học/khoảng ngày đã gửi để biết có cần nạp bù sau khi danh sách tuần hoàn tất.
		summaryQueryKey() {
			return [this.CapID ?? '', this.NienKhoa ?? '', this.dashboardDateRangeKey].join('|')
		},
		// Nhóm kết quả thiếu theo lịch tháng/tuần do LMS trả về để dùng làm bộ lọc cho báo cáo hiện tại.
		weeklyMissingGroups() {
			const months = new Map()
			const dateKey = value => {
				if (!value) return ''
				if (value instanceof Date) {
					return [value.getFullYear(), String(value.getMonth() + 1).padStart(2, '0'), String(value.getDate()).padStart(2, '0')].join('-')
				}
				return String(value).slice(0, 10)
			}
			this.weeklyMissingAssignments.forEach(row => {
				const year = Number(row.Nam) || 0
				const monthNumber = Number(row.ThangHoc) || 0
				const monthKey = year + '-' + String(monthNumber).padStart(2, '0')
				let month = months.get(monthKey)
				if (!month) {
					month = { key: monthKey, sortKey: year * 100 + monthNumber, title: 'Tháng ' + monthNumber + '/' + year, count: 0, weeks: new Map() }
					months.set(monthKey, month)
				}

				const weekKey = String(row.TuanHocID ?? (monthKey + '-' + row.Tuan))
				let week = month.weeks.get(weekKey)
				if (!week) {
					week = {
						key: weekKey,
						sortKey: Number(row.Tuan) || 0,
						tabTitle: 'Tuần ' + this.cleanSheetValue(row.Tuan),
						from: '',
						to: '',
						rows: [],
					}
					month.weeks.set(weekKey, week)
				}
				// Các dòng cùng tuần có thể khác phạm vi ngày; gộp min/max để tab và báo cáo dùng trọn khoảng tuần.
				const rowFrom = dateKey(row.NgayBatDau)
				const rowTo = dateKey(row.NgayKetThuc)
				if (rowFrom && (!week.from || rowFrom < week.from)) week.from = rowFrom
				if (rowTo && (!week.to || rowTo > week.to)) week.to = rowTo
				month.count += 1
				week.rows.push(row)
			})

			return Array.from(months.values())
				.sort((a, b) => a.sortKey - b.sortKey)
				.map(month => ({
					...month,
					weeks: Array.from(month.weeks.values())
						.sort((a, b) => a.sortKey - b.sortKey)
						.map(week => {
							const dateRangeLabel = week.from && week.to
								? this.formatReportDate(week.from) + ' – ' + this.formatReportDate(week.to)
								: ''
							return {
								...week,
								dateRangeLabel,
								title: week.tabTitle + (dateRangeLabel ? ' · ' + dateRangeLabel : ''),
								rows: week.rows.sort((a, b) =>
									this.cleanSheetValue(a.TenLop).localeCompare(this.cleanSheetValue(b.TenLop), 'vi')
									|| this.cleanSheetValue(a.TenMonHoc_HienThi).localeCompare(this.cleanSheetValue(b.TenMonHoc_HienThi), 'vi')
									|| this.cleanSheetValue(a.TenGiaoVien).localeCompare(this.cleanSheetValue(b.TenGiaoVien), 'vi')
								),
							}
						}),
				}))
		},
		// Ba KPI này dùng cùng một quy tắc với bảng chi tiết: tổng = đã giao + chưa giao.
		// Khi chuyển tab, nhãn và số liệu đổi theo loại nội dung đang được xem.
		resourceCreatedKpiLabel() {
			return this.tabChiTiet === 0 ? 'Bài học đã tạo' : 'Bài tập đã tạo'
		},
		resourceCreatedKpiValue() {
			return this.tabChiTiet === 0 ? this.tongBaiHoc : this.tongBaiTap
		},
		resourceAssignedKpiLabel() {
			return this.tabChiTiet === 0 ? 'Bài học đã giao' : 'Bài tập đã giao'
		},
		resourceAssignedKpiValue() {
			return this.tabChiTiet === 0 ? this.tongBaiHocDaGiao : this.tongBaiTapDaGiao
		},
		resourceUnassignedKpiLabel() {
			return this.tabChiTiet === 0 ? 'Bài học chưa giao' : 'Bài tập chưa giao'
		},
		resourceUnassignedKpiValue() {
			return this.tabChiTiet === 0 ? this.tongBaiHocChuaGiao : this.tongBaiTapChuaGiao
		},
		tyLeCham_BaiTap() {
			if (!this.tongHocSinhDuocGiao_BaiTap) return 0
			return (this.tongDaCham / this.tongHocSinhDuocGiao_BaiTap * 100).toFixed(1)
		},
		tongBaiHoc() { return this.dataTong.reduce((s, r) => s + (r.TotalLessons ?? 0), 0) },
		tongBaiTap() { return this.dataTong.reduce((s, r) => s + (r.TotalAssignments ?? 0), 0) },
		tongBaiHocDaGiao() { return this.dataBaiHoc.reduce((s, r) => s + (r.AssignedLessons ?? 0), 0) },
		tongBaiHocChuaGiao() { return this.dataBaiHoc.reduce((s, r) => s + (r.UnassignedLessons ?? 0), 0) },
		tongProgress_BaiHoc() { return this.dataBaiHoc.reduce((s, r) => s + (r.TotalProgress ?? 0), 0) },
		tongHoanThanh_BaiHoc() { return this.dataBaiHoc.reduce((s, r) => s + (r.TotalCompleted ?? 0), 0) },
		tyLeHoanThanh_BaiHoc() {
			if (!this.tongProgress_BaiHoc) return 0
			return (this.tongHoanThanh_BaiHoc / this.tongProgress_BaiHoc * 100).toFixed(1)
		},
		tongBaiTapDaGiao() { return this.dataBaiTap.reduce((s, r) => s + (r.AssignedAssignments ?? 0), 0) },
		tongBaiTapChuaGiao() { return this.dataBaiTap.reduce((s, r) => s + (r.UnassignedAssignments ?? 0), 0) },
		tongHocSinhDuocGiao_BaiTap() { return this.dataBaiTap.reduce((s, r) => s + (r.TotalAssigned ?? 0), 0) },
		tongChuaLam() { return this.dataBaiTap.reduce((s, r) => s + (r.Total_ChuaLam ?? 0), 0) },
		tongDangLam() { return this.dataBaiTap.reduce((s, r) => s + (r.Total_DangLam ?? 0), 0) },
		tongDaNop() { return this.dataBaiTap.reduce((s, r) => s + (r.Total_DaNop ?? 0), 0) },
		tongDaCham() { return this.dataBaiTap.reduce((s, r) => s + (r.Total_DaCham ?? 0), 0) },
		tyLeHoanThanh_BaiTap() {
			if (!this.tongHocSinhDuocGiao_BaiTap) return 0
			return ((this.tongDaNop + this.tongDaCham) / this.tongHocSinhDuocGiao_BaiTap * 100).toFixed(1)
		},
		chartBaiHoc() {
			const labels = this.dataBaiHoc.map(r => r.TenMonHoc_HienThi)
			const rates = this.dataBaiHoc.map(r => r.CompletionRate_Lessons)
			return {
				series: [{ name: 'Tỉ lệ hoàn thành (%)', data: rates }],
				chart: { type: 'bar', height: 360, toolbar: { show: false }, fontFamily: 'inherit' },
				plotOptions: {
					bar: {
						horizontal: true, borderRadius: 4, borderRadiusApplication: 'end', barHeight: '60%',
						distributed: true
					},
				},
				colors: rates.map(r => r >= 80 ? '#4CAF50' : r >= 50 ? '#FF9800' : '#F44336'),
				dataLabels: {
					enabled: true,
					formatter: val => val + '%',
					style: { fontSize: '11px', colors: ['#fff'] },
				},
				xaxis: {
					categories: labels,
					max: 100,
					labels: { formatter: val => val + '%', style: { fontSize: '11px' } },
				},
				yaxis: { labels: { style: { fontSize: '11px' } } },
				legend: { show: false },
				tooltip: { y: { formatter: val => val + '%' } },
				grid: { borderColor: 'rgba(128,128,128,0.15)', strokeDashArray: 4 },
				annotations: {
					xaxis: [
						{
							x: 80, borderColor: '#4CAF50', strokeDashArray: 4,
							label: {
								text: '≥80% Tốt', position: 'top',
								style: { color: '#4CAF50', fontSize: '10px', background: 'transparent' }
							}
						},
						{
							x: 50, borderColor: '#FF9800', strokeDashArray: 4,
							label: {
								text: '≥50% TB', position: 'top',
								style: { color: '#FF9800', fontSize: '10px', background: 'transparent' }
							}
						},
					],
				},
			}
		},
		chartBaiTap() {
			const labels = this.dataBaiTap.map(r => r.TenMonHoc_HienThi)
			return {
				series: [
					{ name: 'Chưa làm', data: this.dataBaiTap.map(r => r.Total_ChuaLam) },
					{ name: 'Đang làm', data: this.dataBaiTap.map(r => r.Total_DangLam) },
					{ name: 'Đã nộp / chấm nháp', data: this.dataBaiTap.map(r => r.Total_DaNop) },
					{ name: 'Đã chấm', data: this.dataBaiTap.map(r => r.Total_DaCham) },
				],
				chart: { type: 'bar', height: 280, stacked: true, toolbar: { show: false }, fontFamily: 'inherit' },
				plotOptions: {
					bar: { horizontal: true, borderRadius: 2, borderRadiusApplication: 'end', barHeight: '60%' },
				},
				colors: ['#9E9E9E', '#42A5F5', '#FFA726', '#66BB6A'],
				dataLabels: {
					enabled: true,
					formatter: val => val > 0 ? val : '',
					style: { fontSize: '10px', colors: ['#fff'] },
				},
				xaxis: { categories: labels, labels: { style: { fontSize: '11px' } } },
				yaxis: { labels: { style: { fontSize: '11px' } } },
				legend: {
					position: 'top', horizontalAlign: 'left', fontSize: '11px',
					markers: { size: 8, shape: 'square' }
				},
				tooltip: { y: { formatter: val => val + ' HS' } },
				grid: { borderColor: 'rgba(128,128,128,0.15)', strokeDashArray: 4 },
			}
		},
		chartTiLe() {
			const labels = this.dataBaiTap.map(r => r.TenMonHoc_HienThi)
			return {
				series: [
					{ name: 'Tỉ lệ nộp (%)', data: this.dataBaiTap.map(r => r.CompletionRate_Assignments) },
					{ name: 'Tỉ lệ chấm (%)', data: this.dataBaiTap.map(r => r.CompletionRate_Graded) },
				],
				chart: { type: 'bar', height: 280, toolbar: { show: false }, fontFamily: 'inherit' },
				plotOptions: {
					bar: { horizontal: true, borderRadius: 3, borderRadiusApplication: 'end', barHeight: '55%' },
				},
				colors: ['#E91E63', '#4CAF50'],
				dataLabels: {
					enabled: true,
					formatter: val => val + '%',
					style: { fontSize: '10px', colors: ['#fff'] },
				},
				xaxis: {
					categories: labels, max: 100,
					labels: { formatter: val => val + '%', style: { fontSize: '11px' } },
				},
				yaxis: { labels: { style: { fontSize: '11px' } } },
				legend: {
					position: 'top', horizontalAlign: 'left', fontSize: '11px',
					markers: { size: 8, shape: 'square' }
				},
				tooltip: { y: { formatter: val => val + '%' } },
				grid: { borderColor: 'rgba(128,128,128,0.15)', strokeDashArray: 4 },
				annotations: {
					xaxis: [
						{
							x: 80, borderColor: '#4CAF50', strokeDashArray: 4,
							label: {
								text: '≥80% Tốt', position: 'top',
								style: { color: '#4CAF50', fontSize: '10px', background: 'transparent' }
							}
						},
						{
							x: 50, borderColor: '#FF9800', strokeDashArray: 4,
							label: {
								text: '≥50% TB', position: 'top',
								style: { color: '#FF9800', fontSize: '10px', background: 'transparent' }
							}
						},
					],
				},
			}
		},
	},
	watch: {
		weeklyMissingGroups(groups) {
			const month = groups.find(item => item.key === this.weeklySelectedMonth) || groups[0]
			this.weeklySelectedMonth = month?.key ?? ''
			const week = month?.weeks.find(item => item.key === this.weeklySelectedWeek) || month?.weeks[0]
			this.weeklySelectedWeek = week?.key ?? ''
		},
		weeklySelectedMonth(monthKey) {
			const month = this.weeklyMissingGroups.find(item => item.key === monthKey)
			if (!month) {
				this.weeklySelectedWeek = ''
				return
			}
			if (!month.weeks.some(item => item.key === this.weeklySelectedWeek)) {
				this.weeklySelectedWeek = month.weeks[0]?.key ?? ''
			}
		},
		dashboardDateRangeKey() {
			if (this.CapID && !this.weeklyReportLoading) this.loadSummaryData()
		},
		// Nếu tuần được xác định sau khi tải danh sách thiếu, nạp lại báo cáo theo khoảng tuần vừa chọn.
		weeklyReportLoading(isLoading, wasLoading) {
			if (!isLoading && wasLoading && this.CapID && this.reportPeriodMode === 'weekly'
				&& this.loadedSummaryQueryKey !== this.summaryQueryKey) {
				this.loadSummaryData()
			}
		},
		CapID() { this.loadData() },
		NienKhoa() { this.loadData() },
		NgayBatDau() { this.loadData() },
		NgayKetThuc() { this.loadData() },
	},
	mounted() {
		if (this.CapID) this.loadData()
	},
	methods: {
		// Chuẩn hóa ô Excel để API trả null/object không biến thành chữ [object Object].
		cleanSheetValue(value) {
			if (value === null || value === undefined) return ''
			if (value instanceof Date) return this.formatReportDate(value)
			if (typeof value === 'object') {
				try { return JSON.stringify(value) } catch (e) { return '' }
			}
			return String(value).trim()
		},
		formatReportDate(value) {
			if (!value) return ''
			const dateText = value instanceof Date
				? [value.getFullYear(), String(value.getMonth() + 1).padStart(2, '0'), String(value.getDate()).padStart(2, '0')].join('-')
				: String(value).slice(0, 10)
			const parts = dateText.split('-')
			return parts.length === 3 ? parts[2] + '/' + parts[1] + '/' + parts[0] : dateText
		},
		loadWeeklyMissingHomework() {
			const requestId = ++this.weeklyReportRequestId
			if (!this.CapID || !this.NgayBatDau || !this.NgayKetThuc) {
				this.weeklyMissingAssignments = []
				this.weeklyReportLoading = false
				this.weeklyReportError = false
				return Promise.resolve([])
			}
			const self = this
			this.weeklyReportLoading = true
			this.weeklyReportError = false
			this.weeklyMissingAssignments = []
			return fetchPromise(
					'lms/BaoCaoLMS_ChuaGiaoBaiTap_ByKhoangNgay',
					{
						CapID: this.CapID,
						NienKhoa: this.NienKhoa ?? null,
						NgayBatDau: this.NgayBatDau,
						NgayKetThuc: this.NgayKetThuc,
					},
					{ forceRefresh: true }
				).then(function(result) {
					if (requestId !== self.weeklyReportRequestId) return
					// tAPI một resultset có thể trả mảng dòng trực tiếp; API nhiều resultset trả mảng lồng.
					const rows = Array.isArray(result)
						? (Array.isArray(result[0]) ? result[0] : result)
						: (result?.data ?? result?.items ?? [])
					self.weeklyMissingAssignments = Array.isArray(rows) ? rows : []
				}).catch(function(e) {
					if (requestId === self.weeklyReportRequestId) {
						console.error(e)
						self.weeklyMissingAssignments = []
						self.weeklyReportError = true
					}
				}).then(function() {
					if (requestId === self.weeklyReportRequestId) self.weeklyReportLoading = false
				})
		},
		exportWeeklyMissingHomework() {
			if (this.weeklyReportLoading) return
			if (this.weeklyReportError) {
				this.loadWeeklyMissingHomework()
				return
			}

			// Sắp theo lịch tuần chuẩn của LMS: tháng/năm học trước, rồi đến tuần và lớp.
			const sourceRows = this.reportPeriodMode === 'weekly' && this.activeWeeklyWeek
				? this.activeWeeklyWeek.rows
				: this.weeklyMissingAssignments
			const rows = sourceRows.slice().sort((a, b) => {
				const monthA = Number(a.Nam) * 100 + Number(a.ThangHoc)
				const monthB = Number(b.Nam) * 100 + Number(b.ThangHoc)
				return monthA - monthB
					|| Number(a.Tuan) - Number(b.Tuan)
					|| this.cleanSheetValue(a.TenLop).localeCompare(this.cleanSheetValue(b.TenLop), 'vi')
					|| this.cleanSheetValue(a.TenMonHoc_HienThi).localeCompare(this.cleanSheetValue(b.TenMonHoc_HienThi), 'vi')
					|| this.cleanSheetValue(a.TenGiaoVien).localeCompare(this.cleanSheetValue(b.TenGiaoVien), 'vi')
			})
			const capLabel = this.CapID === 1 ? 'Cấp 1' : this.CapID === 2 ? 'Cấp 2' : this.CapID === 3 ? 'Cấp 3' : ''
			const range = this.dashboardDateRange
			const rangeLabel = range.label || (this.formatReportDate(this.NgayBatDau) + ' - ' + this.formatReportDate(this.NgayKetThuc))
			const sheetRows = [
				['BÁO CÁO LỚP/GIÁO VIÊN CHƯA GIAO BÀI TẬP THEO TUẦN' + (range.isWeekly && this.activeWeeklyWeek ? ' · ' + this.activeWeeklyWeek.title : '')],
				['Cấp học:', capLabel, 'Năm học:', this.cleanSheetValue(this.NienKhoa)],
				['Khoảng ngày:', rangeLabel],
				[],
				['Tháng', 'Tuần', 'Thời gian tuần', 'Lớp', 'Môn học', 'Giáo viên'],
			]
			if (rows.length) {
				// Tạo dòng tiêu đề tháng rồi lồng từng tuần và các lớp bên dưới để range dài dễ rà soát.
				let currentMonth = ''
				let currentWeek = ''
				rows.forEach(row => {
					const monthKey = String(row.Nam) + '-' + String(row.ThangHoc)
					const weekKey = String(row.TuanHocID)
					if (monthKey !== currentMonth) {
						sheetRows.push(['Tháng ' + this.cleanSheetValue(row.ThangHoc) + '/' + this.cleanSheetValue(row.Nam), '', '', '', '', ''])
						currentMonth = monthKey
						currentWeek = ''
					}
					if (weekKey !== currentWeek) {
						sheetRows.push([
							'',
							'Tuần ' + this.cleanSheetValue(row.Tuan),
							this.formatReportDate(row.NgayBatDau) + ' - ' + this.formatReportDate(row.NgayKetThuc),
							'', '', '',
						])
						currentWeek = weekKey
					}
					sheetRows.push([
						'', '', '',
						this.cleanSheetValue(row.TenLop),
						this.cleanSheetValue(row.TenMonHoc_HienThi),
						this.cleanSheetValue(row.TenGiaoVien),
					])
				})
			} else {
				sheetRows.push(['', '', '', 'Không có lớp/giáo viên thiếu bài tập trong khoảng ngày này.', '', ''])
			}

			const workbook = XLSX.utils.book_new()
			const worksheet = XLSX.utils.aoa_to_sheet(sheetRows)
			worksheet['!cols'] = [18, 14, 25, 18, 30, 30].map(wch => ({ wch }))
			XLSX.utils.book_append_sheet(workbook, worksheet, 'Chua giao theo tuan')
			const startFile = String(range.from || this.NgayBatDau).slice(0, 10).replace(/-/g, '')
			const endFile = String(range.to || this.NgayKetThuc).slice(0, 10).replace(/-/g, '')
			XLSX.writeFile(workbook, 'BaoCao_ChuaGiaoBaiTap_Cap' + this.CapID + '_' + startFile + '_' + endFile + '.xlsx')
		},
		loadData() {
			this.weeklySelectedMonth = ''
			this.weeklySelectedWeek = ''
			this.loadWeeklyMissingHomework()
			this.loadSummaryData()
		},
		loadSummaryData() {
			const requestId = ++this.summaryRequestId
			const self = this
			const range = this.dashboardDateRange
			if (!this.CapID) {
				this.dataTong = this.dataBaiHoc = this.dataBaiTap = []
				this.loading = false
				this.summaryError = false
				this.loadedSummaryQueryKey = ''
				return Promise.resolve([])
			}
			this.loading = true
			this.summaryError = false
			this.loadedSummaryQueryKey = this.summaryQueryKey
			return fetchPromise(
					'lms/BaoCao_2_ThongKe_BaiTap_BaiHoc_LMS_ByCapID',
					{
						CapID: this.CapID,
						NienKhoa: this.NienKhoa ?? null,
						NgayBatDau: range.from || null,
						NgayKetThuc: range.to || null,
					},
					{ forceRefresh: true }
				).then(function(result) {
					if (requestId !== self.summaryRequestId) return
					const resultSets = Array.isArray(result) ? result : (result?.data ?? [])
					self.dataTong = Array.isArray(resultSets[0]) ? resultSets[0] : []
					self.dataBaiHoc = Array.isArray(resultSets[1]) ? resultSets[1] : []
					self.dataBaiTap = Array.isArray(resultSets[2]) ? resultSets[2] : []
					self.summaryError = false
				}).catch(function(e) {
					if (requestId === self.summaryRequestId) {
						console.error(e)
						self.dataTong = self.dataBaiHoc = self.dataBaiTap = []
						self.summaryError = true
					}
				}).then(function() {
					if (requestId === self.summaryRequestId) self.loading = false
				})
		},
		getSubjectColor(MonHocID) {
			return this.SUBJECT_COLORS[MonHocID % this.SUBJECT_COLORS.length]
		},
		getRateColor(rate) {
			if (rate >= 80) return 'success'
			if (rate >= 50) return 'warning'
			return 'error'
		},
	},
	}
</script>