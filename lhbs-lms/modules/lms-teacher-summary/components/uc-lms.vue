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
									<div class="d-flex align-center ga-2 py-1">
										<v-avatar size="30" :color="getSubjectColor(item.MonHocID)" rounded="md">
											<v-icon size="16" color="white">mdi-book-open-variant</v-icon>
										</v-avatar>
										<span class="text-body-2 font-weight-medium">{{ item.TenMonHoc_HienThi }}</span>
									</div>
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
									<div class="d-flex align-center ga-2 py-1">
										<v-avatar size="30" :color="getSubjectColor(item.MonHocID)" rounded="md">
											<v-icon size="16" color="white">mdi-clipboard-text-outline</v-icon>
										</v-avatar>
										<span class="text-body-2 font-weight-medium">{{ item.TenMonHoc_HienThi }}</span>
									</div>
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
		name: 'UcLms',
	props: {
		CapID: { default: null },
		NienKhoa: { default: null },
		NgayBatDau: { default: null },
		NgayKetThuc: { default: null },
	},
	data() {
		return {
			loading: false,
			tabChiTiet: 0,
			SUBJECT_COLORS: [
				'primary', 'teal', 'deep-purple', 'indigo', 'cyan',
				'pink', 'blue', 'green', 'orange', 'red',
			],
			dataTong: [],
			dataBaiHoc: [],
			dataBaiTap: [],
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
		CapID() { this.loadData() },
		NienKhoa() { this.loadData() },
		NgayBatDau() { this.loadData() },
		NgayKetThuc() { this.loadData() },
	},
	mounted() {
		if (this.CapID) this.loadData()
	},
	methods: {
		async loadData() {
			if (!this.CapID) return
			this.loading = true
			try {
				const result = await fetchPromise(
					'lms/BaoCao_2_ThongKe_BaiTap_BaiHoc_LMS_ByCapID',
					{
						CapID: this.CapID,
						NienKhoa: this.NienKhoa ?? null,
						NgayBatDau: this.NgayBatDau ?? null,
						NgayKetThuc: this.NgayKetThuc ?? null,
					}
				)
				this.dataTong = result[0] ?? []
				this.dataBaiHoc = result[1] ?? []
				this.dataBaiTap = result[2] ?? []
			} catch (e) {
				console.error(e)
				this.dataTong = this.dataBaiHoc = this.dataBaiTap = []
			} finally {
				this.loading = false
			}
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