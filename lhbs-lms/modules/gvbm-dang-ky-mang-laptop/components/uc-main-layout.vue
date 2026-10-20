<template>
	<Global class="uc-gvbm-dang-ky-mang-laptop">
		<template #header>
			<v-card>
				<v-card-title class="d-flex align-center flex-wrap ga-2">
					<v-icon color="primary">mdi-laptop</v-icon>
					<span>{{ isEn ? 'GVBM - Register device carry' : TitlePage }}</span>
					<v-spacer />
					<div class="d-flex flex-wrap align-center justify-end ga-3">
						<div v-for="item in scheduleLegends" :key="item.label" class="d-flex align-center ga-1">
							<span class="legend-box" :class="item.class" />
							<span class="text-caption text-medium-emphasis">{{ item.label }}</span>
						</div>
						<v-btn-toggle v-model="isEn" size="small" class="ms-2">
							<v-btn :value="false" :disabled="!isEn" :color="!isEn ? 'green' : 'white'" @click="setLanguage(false)">
								<v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="30" />
							</v-btn>
							<v-btn :value="true" :disabled="isEn" :color="isEn ? 'green' : 'white'" @click="setLanguage(true)">
								<v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="30" />
							</v-btn>
						</v-btn-toggle>
					</div>
				</v-card-title>
				<v-card-subtitle class="pb-3">
					{{ isEn ? 'Click on a class period to view info and register device carry.' : 'Bấm vào ô tiết học để xem thông tin và đăng ký mang thiết bị.' }}
				</v-card-subtitle>
			</v-card>
		</template>

		<div class="pa-4">
			<v-card class="mb-4">
				<v-card-text class="pt-5">
					<div class="d-flex align-center justify-space-between ga-2 w-100">
						<v-btn icon variant="text" :disabled="!canGoPreviousWeek || vueData.isLoadingTKB"
							@click="changeWeek(-1)"><v-icon>mdi-chevron-left</v-icon></v-btn>
						<div class="flex-grow-1 px-2" style="max-width: 460px">
							<v-select v-model="vueData.TuanXemTKB" :items="DSTuanTKB" :item-title="formatTuanHienThi"
								:return-object="true" :label="isEn ? 'Timetable' : 'Thời khóa biểu'" variant="outlined" hide-details="auto"
								prepend-inner-icon="mdi-calendar-week" :loading="vueData.isLoadingTKB" />
						</div>
						<v-btn icon variant="text" :disabled="!canGoNextWeek || vueData.isLoadingTKB"
							@click="changeWeek(1)"><v-icon>mdi-chevron-right</v-icon></v-btn>
					</div>
					<div v-if="vueData.isLoadingTKB" class="d-flex align-center ga-2 text-primary text-caption mt-2">
						<v-progress-circular indeterminate size="16" width="2" />
							<span>{{ isEn ? 'Loading timetable...' : 'Đang tải thời khóa biểu...' }}</span>
						</div>
					<div v-if="vueData.TKBQueue.length" class="schedule-selection-toolbar d-flex justify-end mt-2 mb-2">
						<v-btn color="primary" size="small" variant="tonal" prepend-icon="mdi-laptop" @click="openSelectedScheduleRegistration">
							{{ isEn ? ('Register ' + vueData.TKBQueue.length + ' periods') : ('Đăng ký ' + vueData.TKBQueue.length + ' tiết') }}
						</v-btn>
					</div>
					<div class="schedule-scroll mt-4 d-none d-sm-block">
						<v-table density="compact" class="schedule-table text-caption">
							<thead><tr><th>{{ isEn ? 'Session' : 'Buổi' }}</th><th>{{ isEn ? 'Period' : 'Tiết' }}</th><th v-for="day in mobileWeekDays" :key="day.key"><div>{{ day.label }}</div><div class="schedule-header-date">{{ day.date }}</div></th></tr></thead>
							<tbody>
								<tr v-for="row in scheduleRows" :key="row.Buoi + '_' + row.Tiet">
									<td v-if="row.BuoiRowspan" :rowspan="row.BuoiRowspan"
										:class="['font-weight-medium', 'text-no-wrap', 'text-center', periodClass(row)]">{{ isEn ? (row.Buoi === 1 ? 'MORNING' : 'AFTERNOON') : row.TenBuoi }}</td>
									<td :class="['font-weight-medium', 'text-center', periodClass(row)]">{{ row.Tiet }}</td>
									<td v-for="cell in row.Cells" :key="cell.ThuKey" :class="scheduleCellClass(row, cell)"
										@click="cell.CoTiet && toggleScheduleCell(row, cell)">
										<div class="schedule-cell-main"><v-icon v-if="cell.IsDaDangKy" size="x-small" color="teal-darken-3">mdi-check-circle</v-icon><span>{{ cell.TenLop }}{{ cell.TenMon ? ' - ' + cell.TenMon : '' }}</span></div>
										<span v-if="cell.IsDaDangKy" class="schedule-status-badge">{{ isEn ? 'Registered' : 'Đã đăng ký' }}</span>
										<v-icon v-if="cell.IsBiTrungLich" size="x-small" color="error" :title="isEn ? 'Schedule conflict detected' : 'Đã có đăng ký trùng lịch'">mdi-alert-circle</v-icon>
									</td>
								</tr>
							</tbody>
						</v-table>
					</div>
					<div class="mobile-schedule mt-4 d-sm-none">
						<div class="mobile-week-days">
							<v-btn v-for="day in mobileWeekDays" :key="day.key" class="mobile-week-day" :class="{ 'mobile-week-day-active': day.key === mobileCurrentThuKey }" variant="text" @click="mobileThuKey = day.key">
								<span class="text-caption font-weight-medium">{{ day.label }}</span>
								<span class="text-caption text-medium-emphasis">{{ day.date }}</span>
							</v-btn>
						</div>
						<div v-for="period in mobilePeriodGroups" :key="period.Buoi" class="mobile-period mt-2">
							<div :class="['mobile-period-header', periodClass(period.rows[0])]"><span class="mobile-period-dot">●</span>{{ isEn ? (period.Buoi === 1 ? 'MORNING' : 'AFTERNOON') : period.TenBuoi }}</div>
							<div v-for="row in period.rows" :key="row.Buoi + '_' + row.Tiet" class="mobile-schedule-row" :class="scheduleCellClass(row, row.Cell)" @click="row.Cell.CoTiet && toggleScheduleCell(row, row.Cell)">
								<span class="mobile-period-number">{{ row.Tiet }}</span>
									<div class="flex-grow-1 text-truncate">
										<div class="font-weight-medium text-truncate">{{ row.Cell.CoTiet ? (row.Cell.TenMon || row.Cell.TenLop) : '—' }}</div>
										<div v-if="row.Cell.CoTiet && row.Cell.TenMon && row.Cell.TenLop" class="text-caption text-medium-emphasis text-truncate">{{ row.Cell.TenLop }}</div>
										<span v-if="row.Cell.IsDaDangKy" class="schedule-status-badge">{{ isEn ? 'Registered' : 'Đã đăng ký' }}</span>
									</div>
									<v-icon v-if="row.Cell.IsDaDangKy" size="small" color="teal-darken-3">mdi-check-circle</v-icon>
								<v-icon v-if="row.Cell.IsBiTrungLich" size="small" color="error">mdi-alert-circle</v-icon>
							</div>
						</div>
					</div>
				</v-card-text>
			</v-card>

			<uc-dialog v-model="registrationDialog" :title="isEn ? 'Registration Details' : 'Thông tin đăng ký'" :width="1200" :is-show-done-btn="false">
				<template #subTitle>{{ registrationSubtitle }}<span v-if="registrationBlocked" class="text-error ml-2">{{ registrationBlockedText }}</span></template>
							<v-textarea v-model="vueData.GhiChu" :label="isEn ? 'Notes' : 'Ghi chú'" rows="2" auto-grow hide-details="auto" :readonly="registrationBlocked" />
							<v-chip v-if="vueData.canhBaoTreHan()" color="warning" size="small" prepend-icon="mdi-alert" class="mt-2">
								{{ isEn ? 'Overdue — still saved but need to notify Class Teacher / Supervisor.' : 'Trễ hạn quy định — vẫn lưu được nhưng cần báo GVCN/quản sinh.' }}
							</v-chip>

					<div v-if="vueData.LopItem" class="mt-4">
						<div class="student-picker-toolbar mb-2">
							<span class="text-subtitle-2 text-medium-emphasis">{{ isEn ? 'Students bringing devices — default all class' : 'Học sinh mang thiết bị — mặc định cả lớp' }}</span>
							<div class="student-picker-controls">
								<v-text-field v-model="vueData.TimKiemHocSinh" :label="isEn ? 'Search student' : 'Tìm học sinh'" prepend-inner-icon="mdi-magnify"
									clearable density="compact" hide-details="auto" class="student-picker-search" />
								<v-btn class="d-none d-sm-inline-flex" size="small" variant="text" color="primary"
									:prepend-icon="allStudentsSelected ? 'mdi-checkbox-multiple-blank-outline' : 'mdi-checkbox-multiple-marked'"
									:disabled="registrationBlocked" @click="toggleAllStudents(!allStudentsSelected)">
									{{ allStudentsSelected ? (isEn ? 'Deselect all' : 'Bỏ chọn tất cả') : (isEn ? 'Select all' : 'Chọn tất cả') }}
								</v-btn>
							</div>
						</div>
						<div class="d-none d-sm-block">
						<v-data-table :headers="studentHeaders" :items="filteredStudents" item-value="HocSinhID"
							items-per-page="-1" hide-default-footer density="compact"
							class="border rounded">
							<template #header.IsChon>
								<v-checkbox :model-value="allStudentsSelected" density="compact" hide-details :disabled="registrationBlocked"
									@update:model-value="toggleAllStudents" />
							</template>
							<template #item.IsChon="{ item }">
								<v-checkbox :model-value="item.IsChon" density="compact" hide-details :disabled="registrationBlocked"
									@update:model-value="vueData.toggleChonHocSinh(item)" />
							</template>
							<template #item.GhiChu="{ item }">
							<v-text-field v-model="item.GhiChu" variant="filled" density="compact" hide-details :readonly="registrationBlocked" />
							</template>
							<template v-for="device in tableDeviceTypes" :key="device.key" #[device.headerSlot]>
								<div class="d-flex align-center justify-center ga-1 text-no-wrap">
										<span>{{ device.title }}</span>
									<v-checkbox :model-value="vueData.isCotThietBiChonHet(device.title)" density="compact" hide-details :disabled="registrationBlocked"
										@update:model-value="vueData.toggleCotThietBi(device.title)" />
								</div>
							</template>
							<template v-for="device in tableDeviceTypes" :key="'item-' + device.key" #[device.itemSlot]="{ item }">
								<v-checkbox :model-value="item.IsChon && item.ThietBiChon.includes(device.title)" :disabled="registrationBlocked || !item.IsChon"
									density="compact" hide-details @update:model-value="vueData.toggleThietBi(item, device.title)" />
							</template>
							<template #no-data><div class="pa-4 text-medium-emphasis">{{ isEn ? 'Class has no students' : 'Lớp chưa có học sinh' }}</div></template>
						</v-data-table>
						</div>
						<div class="d-sm-none mobile-student-list">
							<div class="mobile-student-list-header">
								<v-checkbox :model-value="allStudentsSelected" :label="isEn ? 'Select all students' : 'Chọn tất cả học sinh'" density="compact" hide-details
									:disabled="registrationBlocked" @update:model-value="toggleAllStudents" />
							</div>
							<v-list class="pa-0 bg-transparent">
							<v-list-item v-for="student in filteredStudents" :key="student.HocSinhID" class="mobile-student-item mb-2 px-2 py-1" rounded="0" border @click="vueData.toggleChonHocSinh(student)">
								<div class="d-flex align-center ga-2">
									<v-checkbox :model-value="student.IsChon" density="compact" hide-details :disabled="registrationBlocked" @click.stop @update:model-value="vueData.toggleChonHocSinh(student)" />
									<div class="flex-grow-1 min-width-0"><div class="font-weight-medium text-truncate">{{ student.HoTen }}</div><div class="text-caption text-medium-emphasis">Mã HS: {{ student.HocSinhID }}<span v-if="student.SoDanhBo"> • SDB: {{ student.SoDanhBo }}</span></div></div>
								</div>
								<div class="d-flex flex-wrap ga-1 mt-1" @click.stop><v-checkbox v-for="device in tableDeviceTypes" :key="device.key" :label="device.title" :model-value="student.IsChon && student.ThietBiChon.includes(device.title)" density="compact" hide-details :disabled="registrationBlocked || !student.IsChon" @update:model-value="vueData.toggleThietBi(student, device.title)" /></div>
								<v-text-field v-model="student.GhiChu" :label="isEn ? 'Notes' : 'Ghi chú'" variant="outlined" density="compact" hide-details class="mt-1" :readonly="registrationBlocked" @click.stop />
							</v-list-item>
							</v-list>
							<div v-if="!filteredStudents.length" class="pa-4 text-center text-medium-emphasis">{{ isEn ? 'Class has no students' : 'Lớp chưa có học sinh' }}</div>
						</div>
					</div>
				<template #actions>
					<v-spacer />
					<v-btn variant="text" @click="registrationDialog = false">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
					<v-btn color="primary" prepend-icon="mdi-content-save" :loading="vueData.isLoadingSave"
						:disabled="!canSubmit || registrationBlocked" @click="submitRegistration()">
						{{ registrationBlocked ? (isEn ? 'Cannot register' : 'Không thể đăng ký') : (isEn ? 'Register' : 'Đăng ký') }}
					</v-btn>
				</template>
			</uc-dialog>

			<v-card>
				<v-card-title class="text-primary d-flex align-center flex-wrap ga-2">
					<v-icon>mdi-format-list-bulleted</v-icon>
					<span>{{ isEn ? 'Registered List' : 'Danh sách đã đăng ký' }}</span>
					<v-spacer />
					<v-text-field v-model="registeredSearch" :label="isEn ? 'Search' : 'Tìm kiếm'" prepend-inner-icon="mdi-magnify" clearable density="compact" hide-details="auto" style="max-width: 300px" />
				</v-card-title>
				<v-divider />
				<v-card-text>
					<div class="d-none d-sm-block">
					<v-data-table :headers="registeredHeaders" :items="currentWeekRegistrations" :search="registeredSearch"
						:items-per-page="10" fixed-header height="500" density="compact" hover
						:items-per-page-text="isEn ? 'Items per page:' : 'Dữ liệu trên mỗi trang'"
						:page-text="isEn ? '{0}-{1} of {2}' : '{0}-{1} trên {2}'">
						<template #item.SoHocSinh="{ item }">
							<v-btn size="x-small" variant="tonal" color="primary" class="font-weight-bold" :title="isEn ? 'Click to view student list' : 'Bấm để xem danh sách học sinh'" @click="openStudentListDetail(item)">
								<v-icon start size="12">mdi-account-multiple</v-icon>
								{{ item.SoHocSinh }}
							</v-btn>
						</template>
						<template #item.LoaiThietBi="{ item }">
							<v-chip v-for="device in String(item.LoaiThietBi || '').split(',').map(function(x) { return x.trim() }).filter(Boolean)"
								:key="device" size="x-small" variant="tonal" color="primary" class="me-1 mb-1">{{ device }}</v-chip>
						</template>
						<template #item.GhiChu="{ item }">
							<span v-if="item.GhiChu" class="text-body-2" :title="item.GhiChu">{{ item.GhiChu }}</span>
							<span v-else class="text-medium-emphasis">—</span>
						</template>
						<template #item.TreHanHienThi="{ item }">
							<v-chip v-if="item.TreHanHienThi" size="x-small" color="warning" variant="tonal">{{ isEn ? 'Overdue' : item.TreHanHienThi }}</v-chip>
						</template>
						<template #item.actions="{ item }">
							<div class="d-flex align-center justify-center ga-1">
								<v-btn icon size="small" variant="text" color="info" :title="isEn ? 'View student list' : 'Xem danh sách học sinh'" @click="openStudentListDetail(item)">
									<v-icon size="small">mdi-eye-outline</v-icon>
								</v-btn>
								<v-btn icon size="small" variant="text" color="warning" :title="isEn ? 'Delete registration' : 'Xóa đăng ký'" @click="removeRegistration(item)">
									<v-icon size="small">mdi-delete-outline</v-icon>
								</v-btn>
							</div>
						</template>
						<template #no-data><div class="pa-6 text-center text-medium-emphasis">{{ isEn ? 'No registrations yet' : 'Chưa có đăng ký nào' }}</div></template>
					</v-data-table>
					</div>
					<div class="d-sm-none mobile-registration-list">
						<v-card v-for="item in paginatedRegistrations" :key="item.DangKyID" variant="outlined" class="pa-3 mb-2">
							<div class="d-flex align-start justify-space-between ga-2">
								<div>
									<div class="font-weight-medium">{{ item.TenLop }}</div>
									<div class="text-caption text-medium-emphasis">{{ item.NgayApDungHienThi }} • {{ item.LichHienThi }}</div>
								</div>
								<div class="d-flex align-center ga-1">
									<v-btn icon size="small" variant="text" color="info" :title="isEn ? 'View student list' : 'Xem danh sách học sinh'" @click="openStudentListDetail(item)">
										<v-icon size="small">mdi-eye-outline</v-icon>
									</v-btn>
									<v-btn icon size="small" variant="text" color="warning" @click="removeRegistration(item)">
										<v-icon size="small">mdi-delete-outline</v-icon>
									</v-btn>
								</div>
							</div>
							<div class="d-flex align-center justify-space-between ga-2 mt-2">
								<div><v-chip v-for="device in String(item.LoaiThietBi || '').split(',').map(function(x) { return x.trim() }).filter(Boolean)" :key="device" size="x-small" variant="tonal" color="primary" class="me-1">{{ device }}</v-chip></div>
								<v-chip size="x-small" color="primary" variant="tonal" class="cursor-pointer" @click="openStudentListDetail(item)">
									<v-icon start size="12">mdi-account-multiple</v-icon>
									{{ item.SoHocSinh }} HS
								</v-chip>
							</div>
							<div v-if="item.GhiChu" class="text-caption text-medium-emphasis mt-2 font-italic"><v-icon size="x-small" class="me-1">mdi-note-text-outline</v-icon>{{ item.GhiChu }}</div>
							<v-chip v-if="item.TreHanHienThi" size="x-small" color="warning" variant="tonal" class="mt-2">{{ isEn ? 'Overdue' : item.TreHanHienThi }}</v-chip>
						</v-card>
						<div v-if="!filteredRegistrations.length" class="pa-6 text-center text-medium-emphasis">{{ isEn ? 'No registrations yet' : 'Chưa có đăng ký nào' }}</div>
						<v-pagination v-if="registeredPageCount > 1" v-model="registeredPage" :length="registeredPageCount" density="compact" total-visible="5" class="mt-2" />
					</div>
				</v-card-text>
			</v-card>

			<!-- Dialog xem chi tiết danh sách học sinh đăng ký -->
			<uc-dialog v-model="isShowStudentDetailDialog" :title="(isEn ? 'Registered student list - ' : 'Danh sách học sinh đăng ký - ') + (selectedRegistrationDetail ? selectedRegistrationDetail.TenLop : '')" :width="780" :is-show-done-btn="false">
				<template #subTitle v-if="selectedRegistrationDetail">
					{{ selectedRegistrationDetail.NgayApDungHienThi }} · {{ selectedRegistrationDetail.LichHienThi }} · {{ selectedRegistrationDetail.LoaiThietBi }}
				</template>
				<div v-if="loadingStudentDetail" class="text-center pa-6">
					<v-progress-circular indeterminate color="primary" />
				</div>
				<template v-else>
					<div v-if="studentDetailList.length" class="d-flex align-center justify-space-between mb-3 ga-2 flex-wrap">
						<div class="text-caption font-weight-medium text-medium-emphasis">
							{{ isEn ? 'Total students: ' : 'Tổng số học sinh: ' }}<strong class="text-primary">{{ studentDetailList.length }}</strong>
						</div>
						<v-text-field v-model="studentDetailSearch" :label="isEn ? 'Search student' : 'Tìm học sinh'" prepend-inner-icon="mdi-magnify"
							clearable density="compact" hide-details="auto" style="max-width: 250px" />
					</div>
					<v-table v-if="filteredStudentDetailList.length" density="compact" class="border rounded">
						<thead>
							<tr>
								<th class="text-center" style="width: 50px">STT</th>
								<th style="width: 100px">{{ isEn ? 'Student ID' : 'Mã HS' }}</th>
								<th style="width: 90px">{{ isEn ? 'Reg. No' : 'SDB' }}</th>
								<th style="min-width: 150px">{{ isEn ? 'Student Name' : 'Họ và tên' }}</th>
								<th style="min-width: 130px">{{ isEn ? 'Device' : 'Thiết bị mang theo' }}</th>
								<th style="min-width: 130px">{{ isEn ? 'Notes' : 'Ghi chú' }}</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="(hs, index) in filteredStudentDetailList" :key="hs.DangKyHocSinhID || hs.HocSinhID || index">
								<td class="text-center text-medium-emphasis">{{ index + 1 }}</td>
								<td class="font-weight-medium">{{ hs.HocSinhID }}</td>
								<td>{{ hs.SoDanhBo || '—' }}</td>
								<td>
									<span class="font-weight-medium text-primary">{{ hs.HoTen }}</span>
								</td>
								<td>
									<div v-if="hs.LoaiThietBi">
										<v-chip v-for="device in String(hs.LoaiThietBi || '').split(',').map(function(x) { return x.trim() }).filter(Boolean)" :key="device" size="x-small" variant="tonal" color="primary" class="me-1 mb-1">
											{{ device }}
										</v-chip>
									</div>
									<span v-else class="text-medium-emphasis">—</span>
								</td>
								<td>
									<span v-if="hs.GhiChu" class="text-body-2">{{ hs.GhiChu }}</span>
									<span v-else class="text-medium-emphasis">—</span>
								</td>
							</tr>
						</tbody>
					</v-table>
					<div v-else class="text-center text-medium-emphasis pa-6">
						{{ isEn ? 'No student details found' : 'Không tìm thấy học sinh nào' }}
					</div>
				</template>
				<template #actions>
					<v-spacer />
					<v-btn variant="text" @click="isShowStudentDetailDialog = false">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
				</template>
			</uc-dialog>
		</div>
	</Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'confirmRef'],
	data() {
		const isEn = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
		if (this.$i18n) {
			this.$i18n.locale = isEn ? 'en' : 'vi';
		}
		return {
			isEn,
			vueData,
			moduleInitStarted: false,
			registrationDialog: false,
			registrationBlocked: false,
			registeredSearch: '',
			registeredPage: 1,
			registeredPageSize: 10,
			mobileThuKey: '2',
			thuHeaders: ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'],
			tableDeviceTypes: [
				{ title: 'Laptop', key: 'Laptop', headerSlot: 'header.Laptop', itemSlot: 'item.Laptop' },
				{ title: 'Tablet', key: 'Tablet', headerSlot: 'header.Tablet', itemSlot: 'item.Tablet' },
				{ title: 'Thiết bị khác', key: 'ThietBiKhac', headerSlot: 'header.ThietBiKhac', itemSlot: 'item.ThietBiKhac' },
			],
			isShowStudentDetailDialog: false,
			loadingStudentDetail: false,
			selectedRegistrationDetail: null,
			studentDetailList: [],
			studentDetailSearch: '',
		}
	},
	created() {
		this.initModuleState()
	},
	mounted() {
		window.addEventListener('storage', (e) => {
			if (e.key === 'IsLanguage') {
				const isEn = JSON.parse(e.newValue) ?? false;
				this.isEn = isEn;
				if (this.$i18n) this.$i18n.locale = isEn ? 'en' : 'vi';
			}
		});
		vueData.snackbarRef = this.snackbarRef
		this.waitForModuleContext()
	},
	computed: {
		scheduleLegends() {
			var legends = [
				{ label: this.isEn ? 'Registered' : 'Đã đăng ký', class: 'schedule-cell-primary' },
				{ label: this.isEn ? 'Selecting to register' : 'Đang chọn để đăng ký', class: 'schedule-cell-info' },
				{ label: this.isEn ? 'Teaching period, not registered' : 'Có tiết dạy, chưa đăng ký', class: 'schedule-cell-success' },
			]
			// Ô trống của GVCN vẫn giữ nội dung rỗng để không nhầm là tiết dạy,
			// nhưng có màu nhẹ và có thể bấm chọn như một tiết đăng ký.
			if ((this.vueData.DSLopChuNhiem || []).length) legends.push({ label: this.isEn ? 'Blank period - click to register as homeroom' : 'Tiết trống - bấm để đăng ký GVCN', class: 'schedule-cell-gvcn' })
			return legends
		},
		studentHeaders() {
			return [
				{ title: '', key: 'IsChon', width: 56, sortable: false, align: 'center' },
				{ title: this.isEn ? 'Student ID' : 'Mã HS', key: 'HocSinhID', width: 90 },
				{ title: this.isEn ? 'Reg. No' : 'SDB', key: 'SoDanhBo', width: 90 },
				{ title: this.isEn ? 'Student' : 'Học sinh', key: 'HoTen', minWidth: 180 },
				{ title: 'Laptop', key: 'Laptop', width: 120, sortable: false, align: 'center' },
				{ title: 'Tablet', key: 'Tablet', width: 120, sortable: false, align: 'center' },
				{ title: this.isEn ? 'Other device' : 'Thiết bị khác', key: 'ThietBiKhac', width: 150, sortable: false, align: 'center' },
				{ title: this.isEn ? 'Notes' : 'Ghi chú', key: 'GhiChu', minWidth: 200, sortable: false },
			]
		},
		registeredHeaders() {
			return [
				{ title: this.isEn ? 'Class' : 'Lớp', key: 'TenLop', minWidth: 90 },
				{ title: this.isEn ? 'Device type' : 'Loại thiết bị', key: 'LoaiThietBi', minWidth: 130 },
				{ title: this.isEn ? 'Effective date' : 'Ngày áp dụng', key: 'NgayApDungHienThi', minWidth: 120 },
				{ title: this.isEn ? 'Schedule' : 'Lịch', key: 'LichHienThi', minWidth: 170 },
				{ title: this.isEn ? 'Students' : 'Số HS', key: 'SoHocSinh', width: 80, align: 'center' },
				{ title: this.isEn ? 'Notes' : 'Ghi chú', key: 'GhiChu', minWidth: 180 },
				{ title: this.isEn ? 'Overdue' : 'Trễ hạn', key: 'TreHanHienThi', width: 100, sortable: false },
				{ title: this.isEn ? 'Actions' : 'Thao tác', key: 'actions', width: 80, sortable: false, align: 'center' },
			]
		},
		DSTuanTKB() {
			var weeks = (this.vueData.DSTuan || []).slice().sort(function(a, b) {
				return new Date(a.NgayBatDau) - new Date(b.NgayBatDau)
			})
			var mondayWeeks = weeks.filter(function(item) {
				var date = new Date(item.NgayBatDau)
				return date.getDay() === 1
			})
			return mondayWeeks.length ? mondayWeeks : weeks
		},
		TitlePage() {
			return getTitlePageByURL(window.location.pathname + window.location.search)
		},
		currentWeekIndex() {
			var current = this.vueData.TuanXemTKB
			return this.DSTuanTKB.findIndex(function(item) {
				return item === current || (current && item.TuanHocID === current.TuanHocID)
			})
		},
		mobileCurrentThuKey() {
			return this.mobileThuKey || '2'
		},
		mobileWeekDays() {
			var keys = ['2', '3', '4', '5', '6', '7', '1']
			var labels = { '1': 'CN', '2': 'T2', '3': 'T3', '4': 'T4', '5': 'T5', '6': 'T6', '7': 'T7' }
			return keys.map(function(key) {
				var date = tinhNgayTuThuKey(key) || ''
				return { key: key, label: labels[key], date: date ? date.slice(8, 10) + '/' + date.slice(5, 7) : '' }
			})
		},
		mobilePeriodGroups() {
			var rows = (this.vueData.DSTKB || []).map(function(row) {
				var cell = (row.Cells || []).find(function(item) { return item.ThuKey === this.mobileCurrentThuKey }.bind(this))
				return Object.assign({}, row, { Cell: cell || { ThuKey: this.mobileCurrentThuKey, CoTiet: false, TenLop: '', TenMon: '' } })
			}.bind(this))
			return [1, 2].map(function(buoi) {
				var periodRows = rows.filter(function(row) { return row.Buoi === buoi })
				return { Buoi: buoi, TenBuoi: buoi === 1 ? 'SÁNG' : 'CHIỀU', rows: periodRows }
			}).filter(function(period) { return period.rows.length })
		},
		canGoPreviousWeek() {
			return this.currentWeekIndex > 0
		},
		canGoNextWeek() {
			return this.currentWeekIndex >= 0 && this.currentWeekIndex < this.DSTuanTKB.length - 1
		},
		registrationSubtitle() {
			var lop = this.vueData.LopItem && (this.vueData.LopItem.TenHienThi || this.vueData.LopItem.TenLop)
			var ngay = this.formatRegistrationDate(this.vueData.NgayApDung)
			var buoi = { 1: 'Sáng', 2: 'Chiều', 3: 'Tối' }[this.vueData.Buoi] || ''
			var tiet = this.vueData.TietBatDau === this.vueData.TietKetThuc
				? 'Tiết ' + this.vueData.TietBatDau
				: 'Tiết ' + this.vueData.TietBatDau + ' - ' + this.vueData.TietKetThuc
			return [lop, ngay, buoi, tiet].filter(Boolean).join(' • ')
		},
		allStudentsSelected() {
			var students = this.vueData.HocSinhThietBi || []
			return students.length > 0 && students.every(function(item) { return item.IsChon })
		},
		scheduleRows() {
			var rows = this.vueData.DSTKB || []
			if (!rows.length) {
				rows = []
				for (var buoi = 1; buoi <= 2; buoi += 1) {
					for (var tiet = 1; tiet <= 5; tiet += 1) {
						rows.push({
							Buoi: buoi,
							Tiet: tiet,
									TenBuoi: buoi === 1 ? 'Sáng' : 'Chiều',
									Cells: ['2', '3', '4', '5', '6', '7', '1'].map(function(thuKey) {
										return { ThuKey: thuKey, CoTiet: false, TenLop: '', TenMon: '', IsDaDangKy: false }
									}),
						})
					}
				}
			}
			return rows.map(function(row, index) {
				var isFirst = index === 0 || rows[index - 1].Buoi !== row.Buoi
				var rowspan = 0
				if (isFirst) {
					for (var i = index; i < rows.length && rows[i].Buoi === row.Buoi; i += 1) rowspan += 1
				}
				return Object.assign({}, row, { BuoiRowspan: rowspan })
			})
		},
		filteredStudents() {
			const keyword = String(this.vueData.TimKiemHocSinh || '').trim().toLowerCase()
			return (this.vueData.HocSinhThietBi || []).filter(x => !keyword || String(x.HoTen || '').toLowerCase().includes(keyword))
		},
		filteredStudentDetailList() {
			const keyword = String(this.studentDetailSearch || '').trim().toLowerCase()
			if (!keyword) return this.studentDetailList
			return (this.studentDetailList || []).filter(hs =>
				String(hs.HoTen || '').toLowerCase().includes(keyword) ||
				String(hs.HocSinhID || '').toLowerCase().includes(keyword) ||
				String(hs.SoDanhBo || '').toLowerCase().includes(keyword) ||
				String(hs.LoaiThietBi || '').toLowerCase().includes(keyword) ||
				String(hs.GhiChu || '').toLowerCase().includes(keyword)
			)
		},
		// Danh sách đăng ký được lọc theo đúng tuần đang chọn trên TKB
		currentWeekRegistrations() {
			var currentWeek = this.vueData.TuanXemTKB
			var list = this.vueData.DSDangKy || []
			if (!currentWeek) return list
			var currentTuanHocID = currentWeek.TuanHocID
			var tuNgay = tinhNgayTuThuKey('2') // Thứ 2: YYYY-MM-DD
			var denNgay = tinhNgayTuThuKey('1') // Chủ nhật: YYYY-MM-DD
			return list.filter(function(item) {
				// Nếu có TuanHocID trùng khớp
				if (currentTuanHocID && item.TuanHocID && Number(item.TuanHocID) === Number(currentTuanHocID)) {
					return true
				}
				// Hoặc kiểm tra khoảng ngày áp dụng trong tuần
				if (item.NgayApDung && tuNgay && denNgay) {
					var ngay = String(item.NgayApDung).slice(0, 10)
					return ngay >= tuNgay && ngay <= denNgay
				}
				return !currentTuanHocID
			})
		},
		filteredRegistrations() {
			var keyword = String(this.registeredSearch || '').trim().toLowerCase()
			return (this.currentWeekRegistrations || []).filter(function(item) { return !keyword || JSON.stringify(item).toLowerCase().includes(keyword) })
		},
		registeredPageCount() {
			return Math.max(1, Math.ceil(this.filteredRegistrations.length / this.registeredPageSize))
		},
		paginatedRegistrations() {
			var start = (this.registeredPage - 1) * this.registeredPageSize
			return this.filteredRegistrations.slice(start, start + this.registeredPageSize)
		},
		canSubmit() {
			return Boolean(this.vueData.LopItem && this.vueData.NgayApDung && this.vueData.HocSinhThietBi.some(x => x.IsChon))
		},
		registrationBlockedText() {
			return 'Tiết này đã được đăng ký hoặc đã có đăng ký trùng lịch.'
		},
	},
	watch: {
		'vueData.LopItem': { deep: true, handler() { this.loadStudents(); this.loadRegistrations() } },
		'vueData.TuanXemTKB': { deep: true, handler() { this.loadWeekData() } },
		registeredSearch() { this.registeredPage = 1 },
		registeredPageCount(value) { if (this.registeredPage > value) this.registeredPage = value },
	},
	methods: {
		formatTuanHienThi(item) {
			if (!item) return ''
			let text = item.Tuan_HienThi || item.TenTuan || ''
			if (this.isEn) {
				text = text.replace(/Tuần/gi, 'Week').replace(/Tháng/gi, 'Month')
			}
			return text
		},
		setLanguage(val) {
			this.isEn = val;
			if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi';
			localStorage.setItem('IsLanguage', JSON.stringify(val));
		},
			initModuleState() {
			var defaults = {
				DSLop: [], DSLopChuNhiem: [], DSNhomAV: [], LopItem: null, DSTuan: [], TuanXemTKB: null, TKBRaw: null, TKBTuanInfo: null, DSTKB: [], TKBQueue: [], TKBKeyDangChon: null,
				isLoadingTKB: false, NgayApDung: null, Buoi: 1, TietBatDau: 1, TietKetThuc: 1,
				DSBuoi: [{ title: 'Sáng', value: 1 }, { title: 'Chiều', value: 2 }, { title: 'Tối', value: 3 }], DSTiet: [1, 2, 3, 4, 5], DSLoaiThietBi: ['Laptop', 'Tablet', 'Điện thoại di động', 'Thiết bị khác'],
				DSHocSinhLop: [], HocSinhThietBi: [], TimKiemHocSinh: '', GhiChu: '', DSDangKy: [], isLoadingSave: false,
			}
			Object.keys(defaults).forEach(function(key) { if (typeof vueData[key] === 'undefined' || vueData[key] === null) vueData[key] = defaults[key] })
		},
		waitForModuleContext() {
			var self = this
			if (this.moduleInitStarted) return
			var timer = setInterval(function() {
				if (!vueData.NienKhoa || !vueData.user?.UserID) return
				clearInterval(timer)
				self.loadInitialData()
			}, 100)
			setTimeout(function() { clearInterval(timer) }, 8000)
		},
		async loadInitialData() {
			if (this.moduleInitStarted) return
			this.moduleInitStarted = true
			if (typeof IsCheck_NotRoleParent === 'function') IsCheck_NotRoleParent(vueData.user)
			try {
				var results = await Promise.allSettled([
					fetchPromise('lms/GiaoVienLop_Get_By_GiaoVienID', { GiaoVienID: vueData.user.UserID, NienKhoa: vueData.NienKhoa }, { cache: false }),
					fetchPromise('lms/Lop_Get_ByGVCN', { NienKhoa: vueData.NienKhoa, sys_UserID: vueData.user.UserID }, { cache: false }),
					fetchPromise('lms/TuanHocTap_Get', { NienKhoa: vueData.NienKhoa }, { cache: false }),
					// Danh mục nhóm chỉ làm nguồn tra cứu dự phòng cho lớp có trong TKB thay thế.
					fetchPromise('lms/NhomAV_Get', { NienKhoa: vueData.NienKhoa }, { cache: false }),
				])
				var valueOf = function(result) { return result.status === 'fulfilled' ? result.value : [] }
				vueData.DSLop = valueOf(results[0]); vueData.DSLopChuNhiem = valueOf(results[1]); vueData.DSTuan = valueOf(results[2]); vueData.DSNhomAV = valueOf(results[3])
				vueData.renderDSLop()
				// Chọn tuần học hiện tại trước, sau đó nạp dữ liệu TKB và danh sách đăng ký đúng theo tuần đó
				vueData.chonTuanTKBHienTai()
				await this.loadWeekData()
			} catch (error) {
				console.error('[gvbm-dang-ky-mang-laptop] Khởi tạo module thất bại', error)
				this.moduleInitStarted = false
			}
		},
		async loadSchedule() {
			if (!vueData.TuanXemTKB || !vueData.user?.UserID) return
			vueData.isLoadingTKB = true
			try {
				// Dung cung giao vien voi GiaoVienLop_Get_By_GiaoVienID de lop tu TKB tra duoc LopID dang ky.
				vueData.TKBRaw = await fetchPromise('quansinh/ThoiKhoaBieu_GiaoVien', { NgayDauTuan: vueData.tinhNgayDauTuanTKB(), GiaoVienID: vueData.user.UserID }, { cache: false })
				vueData.renderTKB()
			} finally { vueData.isLoadingTKB = false }
		},
		async loadWeekData() {
			await Promise.allSettled([this.loadSchedule(), this.loadRegistrations()])
		},
		async loadStudents() {
			var lop = vueData.LopItem
			if (!lop?.LopID) return
			vueData.DSHocSinhLop = []; vueData.HocSinhThietBi = []
			if (lop.IsLopGop) {
				var lists = await Promise.all((lop.DSLopThanhPhan || []).map(function(lopThanhPhan) {
					var isNhom = Boolean(lopThanhPhan.NhomID)
					return fetchPromise(isNhom ? 'lms/HocSinhNhom_Get_ByNhomID' : 'lms/HocSinhLop_Get_ByLopID',
						isNhom
							? { NhomID: lopThanhPhan.NhomID, NienKhoa: vueData.NienKhoa }
							: { LopID: lopThanhPhan.LopID, MonHocID: 0, HocLieuID: 0, NienKhoa: vueData.NienKhoa },
						{ cache: false })
				}))
				var hocSinhTheoID = new Map()
				lists.forEach(function(list, index) {
					;(list || []).forEach(function(hocSinh) {
						var id = String(hocSinh.HocSinhID || '')
						if (!id) return
						var lopNguon = lop.DSLopThanhPhan[index]
						var existing = hocSinhTheoID.get(id)
						if (existing) {
							existing.DSLopNguon.push(lopNguon)
							return
						}
						hocSinhTheoID.set(id, Object.assign({}, hocSinh, { DSLopNguon: [lopNguon] }))
					})
				})
				vueData.DSHocSinhLop = Array.from(hocSinhTheoID.values())
				vueData.initHocSinhThietBi()
				return
			}
			var api = lop.NhomID ? 'lms/HocSinhNhom_Get_ByNhomID' : 'lms/HocSinhLop_Get_ByLopID'
			var input = lop.NhomID
				? { NhomID: lop.NhomID, NienKhoa: vueData.NienKhoa }
				: { LopID: lop.LopID, MonHocID: 0, HocLieuID: 0, NienKhoa: vueData.NienKhoa }
			vueData.DSHocSinhLop = await fetchPromise(api, input, { cache: false }) || []
			vueData.initHocSinhThietBi()
		},
		async loadRegistrations() {
			// Guard: chỉ load khi đã có tuần đang xem và TuanHocID hợp lệ.
			// Nếu TuanHocID = 0, API trả về toàn bộ tất cả các tuần → hiển thị sai dữ liệu.
			if (!vueData.TuanXemTKB?.TuanHocID) return
			vueData.DSDangKy = await vueData.taiDSDangKyTheoTuan()
			vueData.renderDSDangKy()
		},
		submitRegistration() {
			var self = this
			this.vueData.submitDangKy().then(function(success) {
				if (success) self.registrationDialog = false
			})
		},
		toggleAllStudents(value) {
			if (value) this.vueData.chonTatCaHocSinh()
			else this.vueData.boChonTatCaHocSinh()
		},
		formatRegistrationDate(value) {
			if (!value) return ''
			var dateText = String(value).slice(0, 10)
			var parts = dateText.split('-')
			return parts.length === 3 ? parts[2] + '/' + parts[1] + '/' + parts[0] : dateText
		},
		toggleScheduleCell(row, cell) {
			var key = row.Buoi + '_' + row.Tiet + '_' + cell.ThuKey
			var selected = (this.vueData.TKBQueue || []).find(function(item) { return item.key === key })
			if (selected) {
				this.vueData.boChonTietTKB(selected)
				return
			}
			var current = this.vueData.TKBQueue || []
			var first = current[0]
			if (first && (first.ThuKey !== cell.ThuKey || Number(first.Buoi) !== Number(row.Buoi) || normalizeLookupText(first.TenLop) !== normalizeLookupText(cell.TenLop))) {
				showModuleSnackbarDKLT('Hãy chọn các tiết cùng ngày, buổi và lớp để đăng ký chung', 'warning')
				return
			}
			this.vueData.onChonTietTKB(row, cell)
		},
		openSelectedScheduleRegistration() {
			var items = (this.vueData.TKBQueue || []).slice().sort(function(a, b) { return Number(a.Tiet) - Number(b.Tiet) })
			if (!items.length) return
			for (var i = 1; i < items.length; i += 1) {
				if (Number(items[i].Tiet) !== Number(items[i - 1].Tiet) + 1) {
					showModuleSnackbarDKLT('Các tiết chọn phải liền nhau để đăng ký chung', 'warning')
					return
				}
			}
			this.vueData.dienFormTuTiet(items[0])
			this.vueData.TietBatDau = items[0].Tiet
			this.vueData.TietKetThuc = items[items.length - 1].Tiet
			this.registrationBlocked = false
			this.registrationDialog = true
		},
		openRegistrationFromSchedule(row, cell) {
			if (cell.IsDaDangKy || cell.IsBiTrungLich) {
				this.vueData.dienFormTuTiet({
					key: row.Buoi + '_' + row.Tiet + '_' + cell.ThuKey,
					Buoi: row.Buoi, Tiet: row.Tiet, TenLop: cell.TenLop, TenMon: cell.TenMon,
					IsTietGVCN: !!cell.IsTietGVCN,
					NgayApDung: tinhNgayTuThuKey(cell.ThuKey),
				})
				this.registrationBlocked = true
				this.registrationDialog = true
				return
			}
			this.registrationBlocked = false
			if (this.vueData.onChonTietTKB(row, cell) !== false) this.registrationDialog = true
		},
		openRegistrationFromQueue(item) {
			this.vueData.dienFormTuTiet(item)
			this.registrationBlocked = false
			this.registrationDialog = true
		},
		removeRegistration(item) {
			var self = this
			this.confirmRef.value.show({
				title: 'Xác nhận xóa đăng ký lớp ' + (item.TenLop || '') + '?',
				message: 'Đăng ký và danh sách học sinh mang thiết bị sẽ bị xóa.',
			}).then(function(confirmed) {
				if (!confirmed) return
				fetchPromise('lms/DangKyMangLaptop_Del', { DangKyID: item.DangKyID }, { cache: false })
					.then(function() {
						// Sau khi xóa, gọi loadRegistrations() để tải lại đúng tuần đang xem (thay vì gọi TuanHocID: 0)
						return self.loadRegistrations()
					})
					.then(function() {
						self.snackbarRef.value.showSnackbar({ message: 'Đã xóa đăng ký', color: 'success' })
					})
			})
		},
		async openStudentListDetail(item) {
			this.selectedRegistrationDetail = item
			this.studentDetailList = []
			this.studentDetailSearch = ''
			this.loadingStudentDetail = true
			this.isShowStudentDetailDialog = true
			try {
				const res = await fetchPromise('lms/DangKyMangLaptop_HocSinh_Get', { DangKyID: item.DangKyID }, { cache: false })
				this.studentDetailList = res || []
			} catch (err) {
				console.error('Error fetching student details:', err)
				this.studentDetailList = []
			} finally {
				this.loadingStudentDetail = false
			}
		},
		changeWeek(offset) {
			var nextIndex = this.currentWeekIndex + offset
			var weeks = this.DSTuanTKB
			if (nextIndex < 0 || nextIndex >= weeks.length) return
			this.vueData.TuanXemTKB = weeks[nextIndex]
		},
			scheduleCellClass(row, cell) {
				if (!cell.CoTiet) return ''
				var statusClass = cell.IsBiTrungLich
					? 'schedule-cell-error'
					: this.vueData.isTietDaChon(row, cell)
						? 'schedule-cell-info'
						: cell.IsDaDangKy ? 'schedule-cell-primary' : cell.IsTietGVCN ? 'schedule-cell-gvcn' : 'schedule-cell-success'
				return 'schedule-cell ' + statusClass
			},
		periodClass(row) {
			return row.Buoi === 1 ? 'schedule-period-primary' : row.Buoi === 2 ? 'schedule-period-warning' : 'schedule-period-tertiary'
		},
	},
	}
</script>