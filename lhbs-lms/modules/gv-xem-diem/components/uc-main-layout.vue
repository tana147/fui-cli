<template>
	<Global>
		<template #header>
			<v-card> 
				<v-card-title class="d-flex align-center flex-wrap ga-2">
					<span>{{ pageTitle }} • {{ titleCap }}</span>
					<v-chip variant="text" color="primary" class="font-weight-medium">
						{{ isEn ? 'Total students:' : 'Tổng số học sinh:' }} {{ DSHocSinhQLD.length }}
					</v-chip>
					<v-spacer />
					<v-btn-toggle v-model="isEn" size="small" class="ml-auto">
						<v-btn :value="false" :disabled="!isEn" :color="!isEn ? 'green' : 'white'" @click="setLanguage(false)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="30" />
						</v-btn>
						<v-btn :value="true" :disabled="isEn" :color="isEn ? 'green' : 'white'" @click="setLanguage(true)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="30" />
						</v-btn>
					</v-btn-toggle>
				</v-card-title>
				<v-card-text>
					<!-- Keep scope filters compact on desktop; less-used actions stay together in one menu. -->
					<v-row align="center">
						<v-col cols="12" sm="6" md="2">
							<v-select :key="'sem_' + isEn" v-model="Semester" :label="isEn ? 'Select semester' : 'Chọn học kì'" :items="DSSemester"
								:item-title="formatSemesterTitle" item-value="value" return-object
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
								<template #selection="{ item }">
									<span>{{ formatSemesterTitle(item) }}</span>
								</template>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="formatSemesterTitle(item)"></v-list-item>
								</template>
							</v-select>
						</v-col>
						<v-col cols="12" sm="6" md="2">
							<v-select :key="'khoi_' + isEn" v-model="KhoiItem" :label="isEn ? 'Select grade' : 'Chọn khối'" :items="DSKhoi"
								:item-title="formatKhoiTitle" item-value="KhoiID" return-object
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
								<template #selection="{ item }">
									<span>{{ formatKhoiTitle(item) }}</span>
								</template>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="formatKhoiTitle(item)"></v-list-item>
								</template>
							</v-select>
						</v-col>
						<v-col cols="12" sm="6" md="2">
							<v-select :key="'lop_' + isEn" v-model="LopItem" :label="isEn ? 'Select class' : 'Chọn lớp'" :items="DSLop"
								item-title="TenLop" item-value="LopID" :disabled="!KhoiItem" return-object
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'" />
						</v-col>
						<v-col cols="12" md="6" class="d-flex align-center justify-end ga-3 flex-wrap">
							<v-btn variant="outlined" color="primary" :disabled="!LopItem || isLoading" :loading="isLoading"
								@click="getDiemTheoLopMonQLD">
								<v-icon start>mdi-refresh</v-icon>{{ isEn ? 'Refresh' : 'Làm mới' }}
							</v-btn>
							<!-- Trên màn hình rộng hiện thao tác riêng; vẫn giữ nguyên quyền, trạng thái chờ và điều kiện khả dụng. -->
							<div class="d-none d-lg-flex align-center ga-2 flex-wrap">
								<v-btn v-if="[2, 3].includes(Number(vueData.CapID))" variant="outlined" color="primary"
									:disabled="!LopItem || isLoading || IsLoadingPublicationStatus" :loading="IsLoadingPublicationStatus"
									@click="loadClassPublicationStatus">
									<v-icon start>mdi-bullhorn-outline</v-icon>{{ isEn ? 'Check publication' : 'Kiểm tra công bố' }}
								</v-btn>
								<v-btn v-if="isAdminCompare" variant="outlined" color="primary"
									:disabled="IsLoadingCompareLMS || DSHocSinhQLD.length === 0" :loading="IsLoadingCompareLMS"
									@click="onLoadBangDiemLMS">
									<v-icon start>mdi-compare</v-icon>{{ isEn ? 'Compare LMS grades' : 'So sánh điểm LMS' }}
								</v-btn>
								<v-btn v-if="isAdminCompare" variant="outlined" color="primary"
									:disabled="DSHocSinhQLD.length === 0" @click="openKeoDiemDialog">
									<v-icon start>mdi-database-import</v-icon>{{ isEn ? 'Pull grades' : 'Kéo điểm' }}
								</v-btn>
							</div>
							<!-- Trên màn hình hẹp, gom các thao tác phụ vào menu để hàng bộ lọc luôn gọn. -->
							<div class="d-flex d-lg-none">
								<v-menu location="bottom end">
									<template #activator="{ props }">
										<v-btn v-bind="props" variant="outlined" color="primary">
											<v-icon start>mdi-dots-horizontal</v-icon>{{ isEn ? 'Actions' : 'Thao tác' }}
										</v-btn>
									</template>
									<v-list density="compact">
										<v-list-item v-if="[2, 3].includes(Number(vueData.CapID))"
											:disabled="!LopItem || isLoading || IsLoadingPublicationStatus"
											:title="isEn ? 'Check publication' : 'Kiểm tra công bố'"
											prepend-icon="mdi-bullhorn-outline" @click="loadClassPublicationStatus">
											<template #append>
												<v-progress-circular v-if="IsLoadingPublicationStatus" indeterminate size="16" width="2" />
											</template>
										</v-list-item>
										<v-list-item v-if="isAdminCompare"
											:disabled="IsLoadingCompareLMS || DSHocSinhQLD.length === 0"
											:title="isEn ? 'Compare LMS grades' : 'So sánh điểm LMS'"
											prepend-icon="mdi-compare" @click="onLoadBangDiemLMS">
											<template #append>
												<v-progress-circular v-if="IsLoadingCompareLMS" indeterminate size="16" width="2" />
											</template>
										</v-list-item>
										<v-list-item v-if="isAdminCompare" :disabled="DSHocSinhQLD.length === 0"
											:title="isEn ? 'Pull grades' : 'Kéo điểm'" prepend-icon="mdi-database-import"
											@click="openKeoDiemDialog" />
									</v-list>
								</v-menu>
							</div>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card> 
		</template>

		<!-- Show publication results on demand, grouped by subject and by score column. -->
		<v-dialog v-model="IsShowPublicationStatusDialog" max-width="800" scrollable>
			<v-card class="pa-0">
				<v-toolbar density="compact" flat>
					<v-toolbar-title>
						{{ isEn ? 'Publication status:' : 'Tình trạng công bố:' }} {{ LopItem?.TenLop }} · {{ formatSemesterTitle(Semester) }}
					</v-toolbar-title>
					<v-spacer />
					<v-btn icon variant="text" @click="IsShowPublicationStatusDialog = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-toolbar>
				<v-card-text class="d-flex flex-column ga-3">
					<div class="text-caption text-medium-emphasis">
						{{ isEn
								? 'Subjects with no TX/GK/CK scores are hidden. Empty cells are shown as not entered; 0 is a valid score. Pulled centralized-exam midterm/final scores count as published. GPA is not a publication column.'
								: 'Môn chưa có điểm TX/GK/CK được ẩn. Ô trống hiển thị là chưa nhập; điểm 0 vẫn hợp lệ. GK/CK thi tập trung đã kéo được tính là đã công bố. ĐTB không phải cột công bố.' }}
					</div>
					<v-progress-linear v-if="IsLoadingPublicationStatus" indeterminate color="primary" />
					<v-alert v-if="PublicationStatusError" type="warning" variant="tonal" density="compact">
						{{ PublicationStatusError }}
					</v-alert>
					<div v-else-if="IsPublicationStatusLoaded && DSPublicationStatus.length" class="d-flex flex-column ga-3">
						<v-card v-for="item in DSPublicationStatus" :key="item.key" variant="outlined" class="pa-3">
							<div class="d-flex align-center flex-wrap ga-2">
								<span class="font-weight-medium">{{ item.subjectName }}</span>
								<v-chip size="small" :color="getPublicationStatusColor(item.status)" variant="tonal" :title="item.details">
									<v-icon start>{{ getPublicationStatusIcon(item.status) }}</v-icon>
									{{ getPublicationStatusLabel(item.status) }}
								</v-chip>
							</div>
							<div class="d-flex flex-column ga-2 mt-2">
								<div v-for="column in item.columns" :key="column.key" class="d-flex align-center flex-wrap ga-2">
									<span class="font-weight-medium">{{ column.title }}</span>
									<!-- Chỉ GK/CK thi tập trung có trạng thái công bố từ luồng kéo; ĐTB bị loại khỏi popup này. -->
									<template v-if="item.historyAvailable || column.countedViaSourcePull">
										<v-chip v-if="column.countedViaSourcePull && column.scoreCount" size="small" variant="tonal" color="success"
											:title="isEn ? 'Centralized-exam scores count as published after they are pulled.' : 'Điểm GK/CK thi tập trung được tính là đã công bố sau khi kéo về.'">
											{{ column.publishedCount }}/{{ column.scoreCount }} {{ isEn ? 'pulled · published' : 'đã kéo · tính là đã công bố' }}
										</v-chip>
										<v-chip v-else-if="column.scoreCount" size="small" variant="tonal" :color="column.publishedCount ? 'success' : 'grey'">
											{{ column.publishedCount }}/{{ column.scoreCount }} {{ isEn ? 'scores published' : 'ô đã công bố' }}
										</v-chip>
										<!-- Màu cam làm nổi số ô còn lệch; xanh dành cho ô đã khớp, đỏ dành cho lần gửi lỗi. -->
										<v-chip v-if="column.unpublishedCount" size="small" color="warning" variant="tonal" class="font-weight-medium">
											{{ column.unpublishedCount }} {{ isEn ? 'not published' : 'chưa công bố' }}
										</v-chip>
										<v-chip v-if="column.failedCount" size="small" color="error" variant="tonal">
											{{ column.failedCount }} {{ isEn ? 'failed' : 'lỗi gửi' }}
										</v-chip>
										<v-chip v-if="column.processingCount" size="small" color="info" variant="tonal">
											{{ column.processingCount }} {{ isEn ? 'processing' : 'đang xử lý' }}
										</v-chip>
									</template>
									<v-chip v-else-if="column.scoreCount" size="small" color="grey" variant="tonal">
										{{ column.scoreCount }} {{ isEn ? 'scores entered' : 'ô đã nhập' }}
									</v-chip>
									<v-chip v-if="column.unenteredCount" size="small" color="grey" variant="outlined">
										{{ column.unenteredCount }} {{ isEn ? 'not entered' : 'chưa nhập' }}
									</v-chip>
								</div>
							</div>
							<div v-if="item.historyRequired && !item.historyAvailable" class="text-caption text-medium-emphasis mt-2">
								{{ isEn ? 'Publication history could not be confirmed for this subject.' : 'Chưa xác minh được lịch sử công bố của môn này.' }}
							</div>
						</v-card>
					</div>
					<div v-else-if="IsPublicationStatusLoaded" class="text-body-2 text-medium-emphasis">
						{{ isEn ? 'No subjects have entered scores in this class.' : 'Không có môn nào đã nhập điểm trong lớp này.' }}
					</div>
				</v-card-text>
			</v-card>
		</v-dialog>

		<v-divider />

		<div v-auto-table-height>
			<template v-if="isLoading">
				<div class="d-flex flex-column align-center justify-center py-12 text-medium-emphasis">
					<v-progress-circular indeterminate color="primary" size="48" class="mb-3" />
					<p class="text-body-2">{{ isEn ? 'Loading grade data...' : 'Đang tải dữ liệu điểm...' }}</p>
				</div>
			</template>
			<template v-else-if="DSHocSinhQLD.length > 0">
				<div v-for="hocSinh in DSHocSinhQLD" :key="hocSinh.HocSinhID" class="mb-3 pa-3">
					<v-lazy :min-height="100" :options="{ threshold: 0.3 }">
						<v-card border>
							<v-card-title class="font-weight-medium text-primary d-flex align-center flex-wrap ga-2">
								<span>{{ isEn ? 'Student:' : 'Học sinh:' }} [{{ hocSinh.HocSinhID }}] {{ hocSinh.HoTen }}</span>
								<!-- <v-chip v-if="hocSinh.TenTinhTrang" size="small"
									:color="hocSinh.TenTinhTrang === 'Nghỉ học' ? 'error' : 'primary'" variant="tonal">
									{{ hocSinh.TenTinhTrang }}
								</v-chip> -->
							</v-card-title>
							<v-data-table :headers="getHeaders()" :items="getItems(hocSinh)" item-value="MonHocID"
								items-per-page="-1" hide-default-footer density="compact">
								<template #item.MonHocID="{ value }">
									{{ getDisplaySubjectName(value) }}
								</template>
								<template #item.TX1="{ item, value }">
									<div class="d-flex ga-2 align-center justify-center">
										<span>{{ value }}</span>
										<v-chip v-if="IsCompareLMS && renderItemLMS(item, 'TX1')"
											:color="renderItemLMSIsLock(item, 'TX1') ? 'success' : 'orange'"
											size="small">
											{{ renderItemLMS(item, 'TX1') }}
											<v-tooltip activator="parent" location="top">{{ getLockTooltipText(item, 'TX1') }}</v-tooltip>
										</v-chip>
									</div>
								</template>
								<template #item.TX2="{ item, value }">
									<div class="d-flex ga-2 align-center justify-center">
										<span>{{ value }}</span>
										<v-chip v-if="IsCompareLMS && renderItemLMS(item, 'TX2')"
											:color="renderItemLMSIsLock(item, 'TX2') ? 'success' : 'orange'"
											size="small">
											{{ renderItemLMS(item, 'TX2') }}
											<v-tooltip activator="parent" location="top">{{ getLockTooltipText(item, 'TX2') }}</v-tooltip>
										</v-chip>
									</div>
								</template>
								<template #item.TX3="{ item, value }">
									<div class="d-flex ga-2 align-center justify-center">
										<span>{{ value }}</span>
										<v-chip v-if="IsCompareLMS && renderItemLMS(item, 'TX3')"
											:color="renderItemLMSIsLock(item, 'TX3') ? 'success' : 'orange'"
											size="small">
											{{ renderItemLMS(item, 'TX3') }}
											<v-tooltip activator="parent" location="top">{{ getLockTooltipText(item, 'TX3') }}</v-tooltip>
										</v-chip>
									</div>
								</template>
								<template #item.TX4="{ item, value }">
									<div class="d-flex ga-2 align-center justify-center">
										<span>{{ value }}</span>
										<v-chip v-if="IsCompareLMS && renderItemLMS(item, 'TX4')"
											:color="renderItemLMSIsLock(item, 'TX4') ? 'success' : 'orange'"
											size="small">
											{{ renderItemLMS(item, 'TX4') }}
											<v-tooltip activator="parent" location="top">{{ getLockTooltipText(item, 'TX4') }}</v-tooltip>
										</v-chip>
									</div>
								</template>
								<template #item.TX5="{ item, value }">
									<div class="d-flex ga-2 align-center justify-center">
										<span>{{ value }}</span>
										<v-chip v-if="IsCompareLMS && renderItemLMS(item, 'TX5')"
											:color="renderItemLMSIsLock(item, 'TX5') ? 'success' : 'orange'"
											size="small">
											{{ renderItemLMS(item, 'TX5') }}
											<v-tooltip activator="parent" location="top">{{ getLockTooltipText(item, 'TX5') }}</v-tooltip>
										</v-chip>
									</div>
								</template>
								<template #item.GK="{ item, value }">
									<div class="d-flex ga-2 align-center justify-center">
										<span>{{ value }}</span>
										<v-chip v-if="IsCompareLMS && renderItemLMS(item, 'GK')"
											:color="renderItemLMSIsLock(item, 'GK') ? 'success' : 'orange'"
											size="small">
											{{ renderItemLMS(item, 'GK') }}
											<v-tooltip activator="parent" location="top">{{ getLockTooltipText(item, 'GK') }}</v-tooltip>
										</v-chip>
									</div>
								</template>
								<template #item.CK="{ item, value }">
									<div class="d-flex ga-2 align-center justify-center">
										<span>{{ value }}</span>
										<v-chip v-if="IsCompareLMS && renderItemLMS(item, 'CK')"
											:color="renderItemLMSIsLock(item, 'CK') ? 'success' : 'orange'"
											size="small">
											{{ renderItemLMS(item, 'CK') }}
											<v-tooltip activator="parent" location="top">{{ getLockTooltipText(item, 'CK') }}</v-tooltip>
										</v-chip>
									</div>
								</template>
								<template #item.DTB="{ item, value }">
									<div class="d-flex ga-2 align-center justify-center">
										<span>{{ value }}</span>
										<v-chip v-if="IsCompareLMS && renderItemLMS(item, 'DTB')"
											:color="renderItemLMSIsLock(item, 'DTB') ? 'success' : 'orange'"
											size="small">
											{{ renderItemLMS(item, 'DTB') }}
											<v-tooltip activator="parent" location="top">{{ getLockTooltipText(item, 'DTB') }}</v-tooltip>
										</v-chip>
									</div>
								</template>
								<template #item.DiemTB_CaNam="{ item, value }">
									<div class="d-flex ga-2 align-center justify-center">
										<span>{{ value }}</span>
										<v-chip v-if="IsCompareLMS && renderItemLMS(item, 'DiemTB_CaNam')"
											:color="renderItemLMSIsLock(item, 'DiemTB_CaNam') ? 'success' : 'orange'"
											size="small">
											{{ renderItemLMS(item, 'DiemTB_CaNam') }}
											<v-tooltip activator="parent" location="top">
												{{ getLockTooltipText(item, 'DiemTB_CaNam') }}
											</v-tooltip>
										</v-chip>
									</div>
								</template>
							</v-data-table>
						</v-card>
					</v-lazy>
				</div>
			</template>
			<template v-else-if="!LopItem">
				<div class="d-flex flex-column align-center justify-center py-12 text-medium-emphasis">
					<v-icon size="48" class="mb-3 opacity-40">mdi-table-search</v-icon>
					<p class="text-body-2">{{ isEn ? 'Select a class to view data' : 'Vui lòng chọn lớp để xem dữ liệu' }}</p>
				</div>
			</template>
			<template v-else>
				<div class="d-flex flex-column align-center justify-center py-12 text-medium-emphasis">
					<v-icon size="48" class="mb-3 opacity-60" color="warning">mdi-database-off-outline</v-icon>
					<p class="text-body-1 font-weight-medium text-warning">{{ isEn ? 'No grade data found for this class in QLD system' : 'Không tìm thấy dữ liệu điểm của lớp này trên hệ thống Quản lý điểm (QLD)' }}</p>
					<p class="text-caption text-medium-emphasis mt-1">{{ isEn ? 'Please check if this class has been synchronized with the QLD system.' : 'Vui lòng kiểm tra lớp này đã được đồng bộ với hệ thống QLD hay chưa.' }}</p>
				</div>
			</template>
		</div>

		<uc-dialog v-model="IsShowDialogKeoDiem" :title="isEn ? 'Select columns to pull grades' : 'Chọn cột kéo điểm'"
			:doneText="isEn ? 'Confirm pull' : 'Xác nhận kéo'"
			:persistent="IsPullingDiem" @onSubmit="onSubmitKeoDiem">
			<div class="d-flex ga-2 mb-3">
				<v-btn size="small" variant="outlined" color="primary" :disabled="IsPullingDiem"
					@click="selectAllKeoDiemColumns">
					{{ isEn ? 'Select all' : 'Chọn tất cả' }}
				</v-btn>
				<v-btn size="small" variant="outlined" color="secondary" :disabled="IsPullingDiem"
					@click="clearAllKeoDiemColumns">
					{{ isEn ? 'Deselect all' : 'Bỏ chọn tất cả' }}
				</v-btn>
			</div>
			<v-row>
				<v-col v-for="col in pullColumnOptions" :key="col.value" cols="12" sm="6" md="4">
					<v-checkbox v-model="SelectedKeoDiemColumns" :label="col.title" :value="col.value" hide-details
						density="compact" :disabled="IsPullingDiem" />
				</v-col>
			</v-row>
			<v-alert v-if="IsPullingDiem" type="info" variant="tonal" class="mt-2">
				{{ PullProgressText }}
			</v-alert>
			<v-progress-linear v-if="IsPullingDiem" class="mt-3" color="primary" height="8"
				:model-value="PullProgressPercent" rounded />
		</uc-dialog>
	</Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
	
	    data() {
	        const DSSemester = [
	            { title: 'Học kì 1', value: 'HK1', HocKi: 1 },
	            { title: 'Học kì 2', value: 'HK2', HocKi: 2 },
	            { title: 'Cả năm', value: 'CaNam', HocKi: 0 },
	        ]
	        // Lấy học kì từ năm học đang chọn; dùng học kì 2 làm mặc định khi dữ liệu cha chưa có giá trị khớp.
	        const currentHocKi = String(vueData?.NienKhoaItem?.HocKi ?? '').trim().toLowerCase()
	        const initialSemester = DSSemester.find(item =>
	            [item.HocKi, item.value, item.title].some(value => String(value).trim().toLowerCase() === currentHocKi)
	        ) || DSSemester[1]
	        return {
	            isEn: JSON.parse(localStorage.getItem('IsLanguage')) ?? false,
	            vueData,
	            isLoading: false,
	            DSKhoi: [],
	            DSLop: [],
	            KhoiItem: null,
	            LopItem: null,
	            DSHocSinh_API_QLD: [],
	            DSHocSinhQLD: [],
	            DSHocSinhTinhTrang: [],
	            DSHocSinh_LMS: [],
	            IsCompareLMS: false,
	            IsLoadingCompareLMS: false,
	            DSPublicationStatus: [],
	            IsShowPublicationStatusDialog: false,
	            IsLoadingPublicationStatus: false,
	            IsPublicationStatusLoaded: false,
	            PublicationStatusError: '',
	            PublicationStatusRequestId: 0,
	            IsShowDialogKeoDiem: false,
	            SelectedKeoDiemColumns: [],
	            IsPullingDiem: false,
	            PullProgressText: '',
	            PullProgressCurrent: 0,
	            PullProgressTotal: 0,
	            DSSemester,
	            Semester: initialSemester,
	        }
	    },
	
	    computed: {
	        titleCap() {
	            const capId = parseInt(vueData.CapID)
	            if (this.isEn) {
	                if (capId === 1) return 'Primary'
	                if (capId === 2) return 'Secondary'
	                if (capId === 3) return 'High School'
	                return 'Level ' + capId
	            }
	            return renderText(capId)
	        },
	        pageTitle() {
	            if (this.isEn) return 'View Grades'
	            return getTitlePageByURL(window.location.pathname + window.location.search)
	        },
	        TitleCap() { return this.titleCap },
	        TitlePage() { return this.pageTitle },
	        isAdminCompare() { return vueData?.user?.UserID === 'NA0000022' },
	        pullColumnOptions() {
	            return this.getHeaders()
	                // Tên môn và STT chỉ để hiển thị, không phải cột điểm có thể kéo.
	                .filter(x => !['MonHocID', 'STT'].includes(x.value))
	                .map(x => ({ title: x.title, value: x.value }))
	        },
	        PullProgressPercent() {
	            if (!this.PullProgressTotal) return 0
	            return Math.round((this.PullProgressCurrent / this.PullProgressTotal) * 100)
	        },
	    },
	
	    watch: {
	        // Đồng bộ bộ lọc nếu trang cha đổi học kì của năm học hiện tại.
	        'vueData.NienKhoaItem.HocKi'(hocKi) {
	            this.syncSemesterWithNienKhoa(hocKi)
	        },
	        'vueData.NienKhoa'() {
	            this.resetAllFilters()
	            this.getKhoi()
	        },
	        Semester() {
	            this.resetAfterSemesterChanged()
	            this.getKhoi()
	        },
	        KhoiItem(v) {
	            this.LopItem = null
	            this.DSLop = []
	            this.clearData()
	            if (v?.KhoiID) this.getLop()
	        },
	        LopItem(v) {
	            this.clearData()
	            if (v?.LopID) this.getDiemTheoLopMonQLD()
	        },
	    },
	
	    mounted() {
	        window.addEventListener('storage', this.handleStorageChange)
	        this.getKhoi()
	    },
	
	    beforeUnmount() {
	        window.removeEventListener('storage', this.handleStorageChange)
	    },
	
	    methods: {
	        findSemesterByHocKi(hocKi) {
	            const target = String(hocKi ?? '').trim().toLowerCase()
	            return this.DSSemester.find(item =>
	                [item.HocKi, item.value, item.title].some(value => String(value).trim().toLowerCase() === target)
	            ) || null
	        },

	        syncSemesterWithNienKhoa(hocKi) {
	            const semester = this.findSemesterByHocKi(hocKi)
	            if (semester && semester.value !== this.Semester?.value) this.Semester = semester
	        },

	        setLanguage(val) {
	            this.isEn = val
	            if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi'
	            localStorage.setItem('IsLanguage', JSON.stringify(val))
	        },
	        handleStorageChange(event) {
	            if (event.key === 'IsLanguage') {
	                this.isEn = JSON.parse(event.newValue) ?? false
	            }
	        },
	        formatSemesterTitle(item) {
	            if (!item) return ''
	            const raw = (item && item.raw) ? item.raw : item
	            if (this.isEn) {
	                if (raw.value === 'HK1') return 'Semester 1'
	                if (raw.value === 'HK2') return 'Semester 2'
	                if (raw.value === 'CaNam') return 'Full year'
	            }
	            return raw.title || ''
	        },
	        formatKhoiTitle(item) {
	            if (!item) return ''
	            const raw = (item && item.raw) ? item.raw : item
	            const name = typeof raw === 'object' ? (raw.TenKhoiHoc || raw.title) : raw
	            if (!name) return ''
	            if (!this.isEn) return name
	            return String(name).replace(/Khối/gi, 'Grade')
	        },
	        getLockTooltipText(item, key) {
	            const isLocked = this.renderItemLMSIsLock(item, key)
	            if (this.isEn) {
	                return isLocked ? 'Locked' : 'Unlocked'
	            }
	            return isLocked ? 'Đã khóa' : 'Chưa khóa'
	        },
	        extractList(res) {
	            if (Array.isArray(res)) return res
	            return res?.data ?? []
	        },
	
	        isNumber(value) {
	            if (value === null || value === undefined) return false
	            return String(value).trim() !== '' && !isNaN(value)
	        },

	        isAnnualSubjectKey(key) {
	            const normalizedKey = String(key || '').trim().toLowerCase()
	            if (!normalizedKey) return false

	            const nonSubjectKeys = new Set([
	                'stt',
	                'hocsinhid',
	                'hoten',
	                'tenlop',
	                'ngaysinh',
	                'dtb',
	                'hocluc',
	                'kqrenluyen',
	                'danhhieu',
	                'phep',
	                'khongphep',
	                'tongbuoinghi',
	                'uudiem',
	                'nhuocdiem',
	                'dexuat',
	                'hocsinhlopid',
	                'hocki',
	                'hocky',
	                'nienkhoa',
	                'lopid',
	                'khoiid',
	            ])

	            if (nonSubjectKeys.has(normalizedKey)) return false
	            if (normalizedKey.endsWith('id')) return false
	            return true
	        },
	
	        clearData() {
	            this.DSHocSinh_API_QLD = []
	            this.DSHocSinhQLD = []
	            this.DSHocSinhTinhTrang = []
	            this.DSHocSinh_LMS = []
	            this.IsCompareLMS = false
	            this.resetPublicationStatus()
	        },

	        resetPublicationStatus() {
	            // Bỏ trạng thái môn của bộ lọc cũ và khiến response đang chờ không ghi đè lớp/học kì mới.
	            this.PublicationStatusRequestId += 1
	            this.DSPublicationStatus = []
	            this.IsShowPublicationStatusDialog = false
	            this.IsLoadingPublicationStatus = false
	            this.IsPublicationStatusLoaded = false
	            this.PublicationStatusError = ''
	        },
	
	        resetAllFilters() {
	            this.KhoiItem = null
	            this.LopItem = null
	            this.DSKhoi = []
	            this.DSLop = []
	            this.clearData()
	        },
	
	        resetAfterSemesterChanged() {
	            this.KhoiItem = null
	            this.LopItem = null
	            this.DSLop = []
	            this.clearData()
	            this.SelectedKeoDiemColumns = []
	        },
	
	        openKeoDiemDialog() {
	            this.SelectedKeoDiemColumns = this.getDefaultKeoDiemColumns()
	            this.IsShowDialogKeoDiem = true
	        },
	
	        getDefaultKeoDiemColumns() {
	            const defaultColumns = this.Semester.HocKi === 0
	                ? ['DiemTB_CaNam']
	                : ['GK', 'CK', 'DTB']
	            const availableColumns = new Set(this.pullColumnOptions.map(x => x.value))
	            return defaultColumns.filter(x => availableColumns.has(x))
	        },
	
	        selectAllKeoDiemColumns() {
	            this.SelectedKeoDiemColumns = this.pullColumnOptions.map(x => x.value)
	        },
	
	        clearAllKeoDiemColumns() {
	            this.SelectedKeoDiemColumns = []
	        },
	
	        resetPullProgress() {
	            this.IsPullingDiem = false
	            this.PullProgressText = ''
	            this.PullProgressCurrent = 0
	            this.PullProgressTotal = 0
	        },
	
	        buildPayloadBySelectedColumns(data, selectedColumns) {
	            const baseKeys = ['HocSinhID', 'HoTen', 'MonHocID', 'TenLop', 'HocKi']
	            const scoreKeys = ['TX1', 'TX2', 'TX3', 'TX4', 'TX5', 'GK', 'CK', 'DTB', 'DiemTB_CaNam']
	            const allowKeys = new Set([...baseKeys, ...selectedColumns])
	
	            return data.map(item => {
	                const payloadItem = { ...item }
	
	                // Bỏ tick cột nào thì xóa key đó khỏi payload.
	                for (const scoreKey of scoreKeys) {
	                    if (!selectedColumns.includes(scoreKey) && Object.prototype.hasOwnProperty.call(payloadItem, scoreKey)) {
	                        delete payloadItem[scoreKey]
	                    }
	                }
	
	                // Giữ lại đúng các key cần gửi.
	                for (const key in payloadItem) {
	                    if (!allowKeys.has(key)) delete payloadItem[key]
	                }
	
	                return payloadItem
	            })
	        },
	
	        async onSubmitKeoDiem() {
	            if (this.IsPullingDiem) return
	            if (!this.SelectedKeoDiemColumns.length) {
	                this.snackbarRef.value.show({ message: this.isEn ? 'Please select at least 1 grade column' : 'Vui lòng chọn ít nhất 1 cột điểm', color: 'warning' })
	                return
	            }
	            await this.fnKeoDiem(this.SelectedKeoDiemColumns)
	        },
	
	        async getKhoi() {
	            const res = await fetchPromise('lms/KhoiHocByCapHoc_Get', {
	                CapID: vueData.CapID,
	                NienKhoa: vueData.NienKhoa,
	                HocKi: this.Semester.HocKi,
	            })
	            this.DSKhoi = this.extractList(res)
	        },
	
	        async getLop() {
	            if (!this.KhoiItem?.KhoiID) return
	            const res = await fetchPromise('lms/Lop_Get_ByKhoiID', {
	                NienKhoa: vueData.NienKhoa,
	                KhoiID: this.KhoiItem.KhoiID,
	                HocKi: this.Semester.HocKi,
	            })
	            this.DSLop = this.extractList(res).filter(x => this.isNumber(x.LopID))
	        },
	
	        async getDiemTheoLopMonQLD() {
	            if (!this.LopItem?.LopID) return
	            this.resetPublicationStatus()
	            this.IsCompareLMS = false
	            this.isLoading = true
	            try {
	                if (this.Semester.HocKi === 0) {
	                    await this.getDiemTBLopMon()
	                    return
	                }

	                const [res, hocSinhTinhTrang] = await Promise.all([
	                    fetchPromise(`diemc${vueData.CapID}/LMS_GetDiemTheoLop`, {
	                        LopID: this.LopItem.LopID,
	                        MonHocID: 'toan',
	                        HocKy: this.Semester.HocKi,
	                        NamHoc: vueData.NienKhoa,
	                    }, { cache: false }),
	                    this.getHocSinhTinhTrangByLopID(),
	                ])

	                const list = this.extractList(res).map(x => ({ ...x, HocKi: this.Semester.value }))
	                const dataWithTinhTrang = this.applyHocSinhTinhTrang(list, hocSinhTinhTrang)
	                this.DSHocSinh_API_QLD = dataWithTinhTrang
	                this.renderDSHocSinhQLD(dataWithTinhTrang)
	            } catch (err) {
	                console.error('getDiemTheoLopMonQLD error:', err)
	                this.DSHocSinh_API_QLD = []
	                this.DSHocSinhQLD = []
	            } finally {
	                this.isLoading = false
	            }
	        },

	        async getDiemTBLopMon() {
	            const [res, hocSinhTinhTrang] = await Promise.all([
	                fetchPromise(`diemc${vueData.CapID}/LMS_GetTongKetDTBMonHocByLop`, {
	                    LopID: this.LopItem.LopID,
	                    HocKy: this.Semester.HocKi,
	                    NienKhoa: vueData.NienKhoa,
	                }, { cache: false }),
	                this.getHocSinhTinhTrangByLopID(),
	            ])
	
	            const newData = this.extractList(res).map(x => ({ ...x, HocKi: this.Semester.value }))
	            const data = []
	            for (const item of newData) {
	                for (const key in item) {
	                    if (!this.isAnnualSubjectKey(key)) continue
	                    data.push({
	                        HocSinhID: item.HocSinhID,
	                        HoTen: item.HoTen,
	                        MonHocID: key,
	                        TenLop: item.TenLop,
	                        DiemTB_CaNam: item[key],
	                        HocKi: this.Semester.value,
	                    })
	                }
	            }
	            const dataWithTinhTrang = this.applyHocSinhTinhTrang(data, hocSinhTinhTrang)
	            this.DSHocSinh_API_QLD = dataWithTinhTrang
	            this.renderDSHocSinhQLD(dataWithTinhTrang)
	        },

	        async getHocSinhTinhTrangByLopID() {
	            if (!this.LopItem?.LopID) return []
	            const res = await fetchPromise('lms/HocSinhLop_Get_ByLopID', {
	                LopID: this.LopItem.LopID,
	                NienKhoa: vueData.NienKhoa,
	            }, { cache: false })
	            this.DSHocSinhTinhTrang = this.extractList(res)
	            return this.DSHocSinhTinhTrang
	        },

	        extractPublicationHistoryRows(response) {
	            let body = response
	            if (typeof body === 'string') {
	                try { body = JSON.parse(body) } catch (_) { body = null }
	            }
	            if (Array.isArray(body)) return body
	            for (const key of ['Result', 'Data', 'data', 'result']) {
	                if (Array.isArray(body?.[key])) return body[key]
	            }
	            throw new Error('API lịch sử công bố không trả về danh sách hợp lệ.')
	        },

	        getPublicationScoreColumns() {
	            // ĐTB là số liệu nguồn từ QLDiem, không có log công bố theo từng ô nên không được tính là đã công bố tại đây.
	            return this.getHeaders()
	                .filter(column => !['STT', 'MonHocID', 'DTB', 'DiemTB_CaNam'].includes(column.value))
	                .map(column => ({ key: column.value, title: column.title }))
	        },

	        // MonHoc_Get_ByLopID trả cả mã môn và ID số; các dòng điểm dùng mã môn trong MonHocID.
	        getPublicationScoreRows(subject) {
	            const subjectCodes = new Set([subject?.MonHocCode, subject?.MonHocID]
	                .filter(value => value !== null && value !== undefined)
	                .map(value => String(value).trim().toLowerCase())
	                .filter(Boolean))
	            return this.DSHocSinhQLD.flatMap(student => Array.isArray(student?.DSCotDiem) ? student.DSCotDiem : [])
	                .filter(row => [row?.MonHocID, row?.MonHocCode]
	                    .filter(value => value !== null && value !== undefined)
	                    .some(value => subjectCodes.has(String(value).trim().toLowerCase())))
	        },

	        // Chỉ cờ IsThiTapTrung=true xác nhận GK/CK thuộc luồng thi tập trung; thiếu cờ thì vẫn cần lịch sử công bố thông thường.
	        isCentralExamSubject(subject) {
	            const value = subject?.IsThiTapTrung
	            return value === true || value === 1 ||
	                ['true', '1'].includes(String(value ?? '').trim().toLowerCase())
	        },

	        hasEnteredScore(value) {
	            if (value === null || value === undefined || typeof value === 'boolean') return false
	            if (typeof value === 'number') return Number.isFinite(value)
	            if (typeof value !== 'string') return false
	            const normalized = value.trim().toLowerCase()
	            return normalized !== '' && !['-', '—', '–', '--', 'null', 'undefined', 'nan'].includes(normalized)
	        },

	        normalizePublicationScoreValue(value) {
	            if (!this.hasEnteredScore(value)) return null
	            const normalized = String(value).trim().replace(',', '.')
	            const numericValue = Number(normalized)
	            return Number.isFinite(numericValue)
	                ? 'number:' + numericValue
	                : 'text:' + normalized.toLowerCase()
	        },

	        // Chuẩn hóa mã cột trong log sang key đang dùng trên bảng điểm (ví dụ TX_L1_HK1 → TX1).
	        normalizePublicationColumnCode(value) {
	            const code = String(value ?? '').trim().toUpperCase().replace(/[^A-Z0-9]/g, '')
	            const txMatch = code.match(/^(?:TXL?|THEME)(\d+)/)
	            if (txMatch) return 'TX' + txMatch[1]
	            if (/^(GK|DIEMGK|DIEMCD1|S[12]MID|MID)/.test(code)) return 'GK'
	            if (/^(CK|DIEMCK|DIEMCD2|S[12]FINAL|FINAL)/.test(code)) return 'CK'
	            if (/^(DTB|DIEMTB|AVERAGE)/.test(code)) return 'DTB'
	            return code
	        },

	        normalizePublicationSemester(value) {
	            const normalized = String(value ?? '').trim().toUpperCase().replace(/\s/g, '')
	            const match = normalized.match(/^(?:HK)?([12])$/)
	            return match ? Number(match[1]) : null
	        },

	        isAutoPublishedSourceColumn(column, isCentralExam) {
	            const columnCode = this.normalizePublicationColumnCode(column?.key)
	            return isCentralExam && ['GK', 'CK'].includes(columnCode)
	        },

	        // Đối chiếu log đúng học kỳ; chỉ GK/CK thi tập trung được tính công bố theo trạng thái kéo.
	        buildPublicationColumnStatuses(scoreRows, scoreColumns, historyRows, isCentralExam = false, expectedSemester = null) {
	            const historyByCell = new Map()
	            for (const history of historyRows) {
	                const studentID = String(history?.HocSinhID ?? '').trim()
	                const columnCode = this.normalizePublicationColumnCode(history?.MaCotDiem)
	                if (!studentID || !columnCode) continue
	                // API được gọi với một học kỳ cụ thể; bỏ log khác kỳ và ưu tiên log có kỳ rõ ràng hơn log không ghi kỳ.
	                const historySemester = this.normalizePublicationSemester(history?.HocKy ?? history?.Semester)
	                if (expectedSemester !== null && historySemester !== null && historySemester !== Number(expectedSemester)) continue
	                const key = studentID + '|' + columnCode
	                const existing = historyByCell.get(key)
	                const existingSemester = this.normalizePublicationSemester(existing?.HocKy ?? existing?.Semester)
	                if (existing && existingSemester === Number(expectedSemester) && historySemester !== Number(expectedSemester)) continue
	                historyByCell.set(key, history)
	            }
	            const totalStudents = this.DSHocSinhQLD.length

	            return scoreColumns.map(column => {
	                const rowsByStudent = new Map()
	                scoreRows.forEach((row, index) => {
	                    if (!this.hasEnteredScore(row?.[column.key])) return
	                    const studentID = String(row?.HocSinhID ?? '').trim()
	                    rowsByStudent.set(studentID || `row:${index}`, row)
	                })
	                const scoredRows = [...rowsByStudent.values()]
	                const columnCode = this.normalizePublicationColumnCode(column.key)
	                const countedViaCentralExamPull = isCentralExam && ['GK', 'CK'].includes(columnCode)
	                const countedViaSourcePull = countedViaCentralExamPull
	                let publishedCount = 0
	                let failedCount = 0
	                let processingCount = 0
	                let unpublishedCount = 0

	                for (const row of scoredRows) {
	                    if (countedViaSourcePull) {
	                        publishedCount += 1
	                        continue
	                    }
	                    const studentID = String(row?.HocSinhID ?? '').trim()
	                    const currentScore = this.normalizePublicationScoreValue(row?.[column.key])
	                    const history = historyByCell.get(studentID + '|' + this.normalizePublicationColumnCode(column.key))
	                    if (!history) {
	                        unpublishedCount += 1
	                        continue
	                    }

	                    const successfulScore = this.normalizePublicationScoreValue(history.LastSuccessfulScore)
	                    if (Number(history.SuccessfulSendCount) > 0 && successfulScore === currentScore) {
	                        publishedCount += 1
	                        continue
	                    }

	                    const latestAttemptScore = this.normalizePublicationScoreValue(history.LastAttemptScore)
	                    const latestAttemptMatches = latestAttemptScore !== null && latestAttemptScore === currentScore
	                    const latestAttemptStatus = String(history.LastAttemptStatus || '')
	                    if (latestAttemptMatches && ['Failed', 'InvalidResponse'].includes(latestAttemptStatus)) {
	                        failedCount += 1
	                    } else if (latestAttemptMatches && latestAttemptStatus === 'Started') {
	                        processingCount += 1
	                    } else {
	                        unpublishedCount += 1
	                    }
	                }

	                return {
	                    key: column.key,
	                    title: column.title,
	                    scoreCount: scoredRows.length,
	                    publishedCount,
	                    unenteredCount: Math.max(0, totalStudents - scoredRows.length),
	                    unpublishedCount,
	                    failedCount,
	                    processingCount,
	                    countedViaCentralExamPull,
	                    countedViaSourcePull,
	                }
	            })
	        },

	        async loadClassPublicationStatus() {
	            if (!this.LopItem?.LopID || !this.KhoiItem?.KhoiID) return
	            const capID = Number(vueData.CapID)
	            if (![2, 3].includes(capID)) return

	            this.IsShowPublicationStatusDialog = true
	            const requestId = ++this.PublicationStatusRequestId
	            this.IsLoadingPublicationStatus = false
	            this.IsPublicationStatusLoaded = false
	            this.PublicationStatusError = ''
	            this.DSPublicationStatus = []

	            const hocKy = Number(this.Semester?.HocKi)
	            if (![1, 2].includes(hocKy)) {
	                this.PublicationStatusError = this.isEn
	                    ? 'Select Semester 1 or 2 to check publication history.'
	                    : 'Chọn học kì 1 hoặc 2 để kiểm tra lịch sử công bố.'
	                return
	            }

	            this.IsLoadingPublicationStatus = true
	            try {
	                const subjectResponse = await fetchPromise('lms/MonHoc_Get_ByLopID', {
	                    NienKhoa: vueData.NienKhoa,
	                    HocKi: hocKy,
	                    LopID: this.LopItem.LopID,
	                })
	                if (requestId !== this.PublicationStatusRequestId) return

	                const seenSubjects = new Set()
	                const subjects = this.extractList(subjectResponse).filter(subject => {
	                    const key = String(subject?.MonHocLopID ?? subject?.MonHocID ?? '')
	                    if (!key || seenSubjects.has(key)) return false
	                    seenSubjects.add(key)
	                    return true
	                })
	                const scoreColumns = this.getPublicationScoreColumns()
	                // Chỉ hiện môn có TX/GK/CK; ĐTB không đại diện cho việc giáo viên đã công bố điểm.
	                const subjectsWithScores = subjects.map(subject => {
	                    const scoreRows = this.getPublicationScoreRows(subject)
	                    const hasAnyEnteredScore = scoreColumns.some(column => scoreRows.some(row => this.hasEnteredScore(row?.[column.key])))
	                    const columns = scoreColumns.filter(column => {
	                        const hasEnteredScore = scoreRows.some(row => this.hasEnteredScore(row?.[column.key]))
	                        const code = this.normalizePublicationColumnCode(column.key)
	                        return hasEnteredScore || ['GK', 'CK'].includes(code)
	                    })
	                    return { subject, scoreRows, columns, hasAnyEnteredScore }
	                }).filter(entry => entry.hasAnyEnteredScore)

	                const statuses = await Promise.all(subjectsWithScores.map(async entry => {
	                    const { subject, scoreRows, columns } = entry
	                    const isCentralExam = this.isCentralExamSubject(subject)
	                    const historyColumns = columns.filter(column =>
	                        scoreRows.some(row => this.hasEnteredScore(row?.[column.key])) &&
	                        !this.isAutoPublishedSourceColumn(column, isCentralExam)
	                    )
	                    const subjectName = this.isEn
	                        ? (subject.TenMonHoc_EN || subject.TenMonHoc_HienThi || subject.TenMonHoc || subject.MonHocName)
	                        : (subject.TenMonHoc_HienThi || subject.TenMonHoc || subject.MonHocName)
	                    const statusItem = {
	                        key: String(subject.MonHocLopID ?? subject.MonHocID),
	                        subjectName: subjectName || (this.isEn ? 'Unnamed subject' : 'Chưa có tên môn'),
	                        status: 'unavailable',
	                        historyAvailable: false,
	                        historyRequired: historyColumns.length > 0,
	                        columns: this.buildPublicationColumnStatuses(scoreRows, columns, [], isCentralExam, hocKy),
	                        details: this.isEn
	                            ? 'Course metadata required to check publication is missing.'
	                            : 'Thiếu thông tin môn học để kiểm tra lịch sử công bố.',
	                    }
	                    const params = {
	                        CapID: capID,
	                        KhoiID: Number(this.KhoiItem.KhoiID),
	                        NienKhoa: Number(vueData.NienKhoa),
	                        LopChonID: String(this.LopItem.LopID),
	                        MonHocLopID: Number(subject.MonHocLopID),
	                        MonHocID: Number(subject.MonHocID),
	                        TemplateBangDiemID: Number(subject.TemplateBangDiemID),
	                        HocKy: hocKy,
	                    }
	                    // Bỏ qua truy vấn log khi các điểm đã nhập đều đến từ luồng thi tập trung.
	                    if (!statusItem.historyRequired) {
	                        const totals = statusItem.columns.reduce((result, column) => ({
	                            scoreCount: result.scoreCount + column.scoreCount,
	                            publishedCount: result.publishedCount + column.publishedCount,
	                        }), { scoreCount: 0, publishedCount: 0 })
	                        statusItem.status = totals.scoreCount > 0 && totals.publishedCount === totals.scoreCount
	                            ? 'published'
	                            : 'unavailable'
	                        statusItem.details = this.isEn
	                            ? `${totals.publishedCount}/${totals.scoreCount} entered score cells from centralized exams count as published.`
	                            : `${totals.publishedCount}/${totals.scoreCount} ô điểm đã nhập từ thi tập trung được tính là đã công bố.`
	                        return statusItem
	                    }
	                    const requiredIds = [params.CapID, params.KhoiID, params.NienKhoa, params.MonHocLopID,
	                        params.MonHocID, params.TemplateBangDiemID]
	                    if (!params.LopChonID || requiredIds.some(value => !Number.isFinite(value) || value <= 0)) {
	                        return statusItem
	                    }

	                    try {
	                        // Điểm có thể vừa được công bố từ màn nhập; không dùng lại cache lịch sử cũ khi mở dialog lần nữa.
	                        const historyResponse = await fetchPromise('lms/LMS_SyncDiemLog_History_Select', params, { cache: false })
	                        const historyRows = this.extractPublicationHistoryRows(historyResponse)
	                        statusItem.historyAvailable = true
	                        statusItem.columns = this.buildPublicationColumnStatuses(scoreRows, columns, historyRows, isCentralExam, hocKy)

	                        const columnTotals = statusItem.columns.reduce((total, column) => ({
	                            scoreCount: total.scoreCount + column.scoreCount,
	                            publishedCount: total.publishedCount + column.publishedCount,
	                            failedCount: total.failedCount + column.failedCount,
	                            processingCount: total.processingCount + column.processingCount,
	                        }), { scoreCount: 0, publishedCount: 0, failedCount: 0, processingCount: 0 })
	                        const latestSuccess = historyRows
	                            .filter(row => Number(row?.SuccessfulSendCount) > 0)
	                            .map(row => row.LastSuccessfulAt)
	                            .filter(Boolean)
	                            .sort((a, b) => new Date(b).getTime() - new Date(a).getTime())[0]

	                        if (columnTotals.publishedCount === columnTotals.scoreCount && !columnTotals.failedCount && !columnTotals.processingCount) {
	                            statusItem.status = 'published'
	                        } else if (columnTotals.publishedCount > 0) {
	                            statusItem.status = 'partial'
	                        } else if (columnTotals.failedCount > 0) {
	                            statusItem.status = 'failed'
	                        } else if (columnTotals.processingCount > 0) {
	                            statusItem.status = 'processing'
	                        } else {
	                            statusItem.status = 'unpublished'
	                        }

	                        statusItem.details = this.isEn
	                            ? `${columnTotals.publishedCount}/${columnTotals.scoreCount} current score cells match a successful publication.`
	                            : `${columnTotals.publishedCount}/${columnTotals.scoreCount} ô điểm hiện tại khớp với lần công bố thành công.`
	                        if (latestSuccess) statusItem.details += (this.isEn ? ' Latest success: ' : ' Gần nhất: ') + this.formatPublicationStatusTime(latestSuccess)
	                    } catch (error) {
	                        console.error('loadClassPublicationStatus subject error:', error)
	                        statusItem.status = 'error'
	                        statusItem.details = this.isEn
	                            ? 'Could not load this subject publication history.'
	                            : 'Chưa tải được lịch sử công bố của môn này.'
	                    }
	                    return statusItem
	                }))

	                if (requestId !== this.PublicationStatusRequestId) return
	                const statusPriority = { unpublished: 0, failed: 1, error: 2, unavailable: 3, partial: 4, processing: 5, published: 6 }
	                statuses.sort((a, b) => statusPriority[a.status] - statusPriority[b.status])
	                this.DSPublicationStatus = statuses
	                this.IsPublicationStatusLoaded = true
	            } catch (error) {
	                if (requestId !== this.PublicationStatusRequestId) return
	                console.error('loadClassPublicationStatus error:', error)
	                this.PublicationStatusError = this.isEn
	                    ? 'Could not load publication status. Please try again.'
	                    : 'Chưa tải được tình trạng công bố. Vui lòng thử lại.'
	            } finally {
	                if (requestId === this.PublicationStatusRequestId) this.IsLoadingPublicationStatus = false
	            }
	        },

	        formatPublicationStatusTime(value) {
	            const date = new Date(value)
	            return Number.isNaN(date.getTime()) ? String(value) : date.toLocaleString(this.isEn ? 'en-US' : 'vi-VN', {
	                day: '2-digit', month: '2-digit', year: '2-digit', hour: '2-digit', minute: '2-digit',
	            })
	        },

	        getPublicationStatusLabel(status) {
	            const labels = {
	                published: this.isEn ? 'Published' : 'Đã có công bố',
	                partial: this.isEn ? 'Partially published' : 'Công bố một phần',
	                failed: this.isEn ? 'Failed, not published' : 'Gửi lỗi, chưa công bố',
	                processing: this.isEn ? 'Processing' : 'Đang xử lý',
	                unpublished: this.isEn ? 'Not published' : 'Chưa công bố',
	                unavailable: this.isEn ? 'Missing course details' : 'Thiếu thông tin môn',
	                error: this.isEn ? 'Status unavailable' : 'Chưa tải được trạng thái',
	            }
	            return labels[status] || (this.isEn ? 'Unknown' : 'Không rõ')
	        },

	        getPublicationStatusColor(status) {
	            const colors = { published: 'success', partial: 'warning', failed: 'error', processing: 'info', unpublished: 'grey', unavailable: 'grey', error: 'error' }
	            return colors[status] || 'grey'
	        },

	        getPublicationStatusIcon(status) {
	            const icons = {
	                published: 'mdi-bullhorn-outline',
	                partial: 'mdi-bullhorn-outline',
	                failed: 'mdi-alert-circle-outline',
	                processing: 'mdi-progress-clock',
	                unpublished: 'mdi-bullhorn-outline',
	                unavailable: 'mdi-help-circle-outline',
	                error: 'mdi-alert-outline',
	            }
	            return icons[status] || 'mdi-help-circle-outline'
	        },

	        applyHocSinhTinhTrang(data, hocSinhTinhTrang) {
	            if (!Array.isArray(hocSinhTinhTrang)) return data
	            const mapTinhTrang = new Map(hocSinhTinhTrang.map(x => [x.HocSinhID, x]))
	            return data.map(item => {
	                const tinhTrang = mapTinhTrang.get(item.HocSinhID)
	                return {
	                    ...item,
	                    TenTinhTrang: tinhTrang?.TenTinhTrang ?? item.TenTinhTrang ?? 'Nghỉ học',
	                }
	            })
	        },
	
	        renderDSHocSinhQLD(data) {
	            const hocSinhIds = [...new Set(data.map(x => x.HocSinhID))]
	            const dsHocSinh = []
	            for (const hocSinhID of hocSinhIds) {
	                const hocSinh = data.find(x => x.HocSinhID === hocSinhID)
	                if (!hocSinh) continue
	                dsHocSinh.push({
	                    ...hocSinh,
	                    DSCotDiem: data.filter(x => x.HocSinhID === hocSinhID),
	                })
	            }
	            this.DSHocSinhQLD = dsHocSinh
	        },
	
	        getHeaders() {
	            // STT là cột trình bày riêng trong từng bảng học sinh, không thuộc dữ liệu điểm.
	            const headers = [{
	                title: this.isEn ? 'No.' : 'STT',
	                value: 'STT',
	                minWidth: 50,
	                align: 'center',
	            }]
	            let listMaCotDiem = [
	                { title: this.isEn ? 'Subject' : 'Tên môn học', value: 'MonHocID', minWidth: 100, align: 'left' },
	            ]
	
	            if (this.Semester.HocKi === 0) {
	                listMaCotDiem = [
	                    { title: this.isEn ? 'Subject' : 'Tên môn học', value: 'MonHocID', minWidth: 100, align: 'left' },
	                    { title: this.isEn ? 'Full Year GPA' : 'DiemTB_CaNam', value: 'DiemTB_CaNam' },
	                ]
	            } else {
	                listMaCotDiem = [
	                    { title: this.isEn ? 'Subject' : 'Tên môn học', value: 'MonHocID', minWidth: 100, align: 'left' },
	                    { title: 'TX1', value: 'TX1' },
	                    { title: 'TX2', value: 'TX2' },
	                    { title: 'TX3', value: 'TX3' },
	                    { title: 'TX4', value: 'TX4' },
	                    { title: 'GK', value: 'GK' },
	                    { title: 'CK', value: 'CK' },
	                    { title: this.isEn ? 'GPA' : 'ĐTB', value: 'DTB' },
	                ]
	            }
	
	            for (const col of listMaCotDiem) {
	                headers.push({
	                    title: col.title,
	                    value: col.value,
	                    minWidth: col.minWidth || 50,
	                    align: col.align || 'center',
	                })
	            }
	
	            if (parseInt(vueData.CapID) === 3 && this.Semester.HocKi !== 0) {
	                headers.splice(5, 0, {
	                    title: 'TX5',
	                    value: 'TX5',
	                    align: 'center',
	                    minWidth: 50,
	                })
	            }
	            return headers
	        },

	        // Chuẩn hóa mã môn chỉ ở lớp hiển thị; giữ nguyên MonHocID gốc cho truy vấn và đối chiếu điểm.
	        getDisplaySubjectName(monHocID) {
	            const code = String(monHocID ?? '').trim().toUpperCase()
	            if (code === 'TD') return 'GDTC'
	            if (Number(vueData.CapID) === 2 && code === 'HKTN') return 'KHTN'
	            return monHocID
	        },
	
	        getItems(hocSinh) {
	            // Đánh số sau khi sắp xếp để STT khớp thứ tự môn đang thấy và bắt đầu lại ở từng học sinh.
	            return [...hocSinh.DSCotDiem]
	                .sort((a, b) => String(a.MonHocID).localeCompare(String(b.MonHocID)))
	                .map((item, index) => ({ ...item, STT: index + 1 }))
	        },
	
	        renderItemLMS(itemTable, key) {
	            let diem = null
	            if (!this.DSHocSinh_LMS?.length) return diem
	            const itemHocSinhMon = this.DSHocSinh_LMS.find(x =>
	                x.MonHocCode.toLowerCase() === itemTable.MonHocID.toLowerCase()
	                && x.HocSinhID == itemTable.HocSinhID
	            )
	            if (!itemHocSinhMon) return diem
	            const monHocCode = itemHocSinhMon.MonHocCode.toLowerCase()
	            const semester = this.Semester.value
	
	            if (key === 'TX1') {
	                if (monHocCode === 'anh') {
	                    if (semester === 'HK1') diem = itemHocSinhMon?.Theme1_Total ?? null
	                    if (semester === 'HK2') diem = itemHocSinhMon?.Theme5_Total ?? null
	                } else {
	                    diem = itemHocSinhMon['TX_L1_' + semester] ?? null
	                }
	            } else if (key === 'TX2') {
	                if (monHocCode === 'anh') {
	                    if (semester === 'HK1') diem = itemHocSinhMon?.Theme2_Total ?? null
	                    if (semester === 'HK2') diem = itemHocSinhMon?.Theme6_Total ?? null
	                } else {
	                    diem = itemHocSinhMon['TX_L2_' + semester] ?? null
	                }
	            } else if (key === 'TX3') {
	                if (monHocCode === 'anh') {
	                    if (semester === 'HK1') diem = itemHocSinhMon?.Theme3_Total ?? null
	                    if (semester === 'HK2') diem = itemHocSinhMon?.Theme7_Total ?? null
	                } else {
	                    diem = itemHocSinhMon['TX_L3_' + semester] ?? null
	                }
	            } else if (key === 'TX4') {
	                if (monHocCode === 'anh') {
	                    if (semester === 'HK1') diem = itemHocSinhMon?.Theme4_Total ?? null
	                    if (semester === 'HK2') diem = itemHocSinhMon?.Theme8_Total ?? null
	                } else {
	                    diem = itemHocSinhMon['TX_L4_' + semester] ?? null
	                }
	            } else if (key === 'TX5') {
	                diem = itemHocSinhMon['TX_L5_' + semester] ?? null
	            } else if (key === 'GK') {
	                if (monHocCode === 'anh') {
	                    if (semester === 'HK1') diem = itemHocSinhMon['S1_Mid_Total_Point'] ?? null
	                    if (semester === 'HK2') diem = itemHocSinhMon['S2_Mid_Total_Point'] ?? null
	                }
	                else if (monHocCode === 'ai') {
	                    diem = itemHocSinhMon['DiemCD1_' + semester] ?? null
	                }
	                else {
	                    diem = itemHocSinhMon['DiemGK_' + semester] ?? null
	                }
	            } else if (key === 'CK') {
	                if (monHocCode === 'anh') {
	                    if (semester === 'HK1') diem = itemHocSinhMon['S1_Final_Total_Point'] ?? null
	                    if (semester === 'HK2') diem = itemHocSinhMon['S2_Final_Total_Point'] ?? null
	                }
	                else if (monHocCode === 'ai') {
	                    diem = itemHocSinhMon['DiemCD2_' + semester] ?? null
	                }
	                else {
	                    diem = itemHocSinhMon['DiemCK_' + semester] ?? null
	                }
	            } else if (key === 'DTB' || key === 'DiemTB_CaNam') {
	                diem = itemHocSinhMon['DiemTB_' + semester] ?? null
	            }
	            return diem
	        },
	
	        renderItemLMSIsLock(itemTable, key) {
	            if (!this.DSHocSinh_LMS?.length) return null
	            const itemHocSinhMon = this.DSHocSinh_LMS.find(x =>
	                x.MonHocCode.toLowerCase() === itemTable.MonHocID.toLowerCase()
	                && x.HocSinhID == itemTable.HocSinhID,
	            )
	            if (!itemHocSinhMon) return null
	            const monHocCode = itemHocSinhMon.MonHocCode.toLowerCase()
	            const semester = this.Semester.value
	            let maCotDiem = null
	
	            if (key === 'TX1') {
	                maCotDiem = monHocCode === 'anh'
	                    ? (semester === 'HK1' ? 'Theme1_Total' : 'Theme5_Total')
	                    : `TX_L1_${semester}`
	            } else if (key === 'TX2') {
	                maCotDiem = monHocCode === 'anh'
	                    ? (semester === 'HK1' ? 'Theme2_Total' : 'Theme6_Total')
	                    : `TX_L2_${semester}`
	            } else if (key === 'TX3') {
	                maCotDiem = monHocCode === 'anh'
	                    ? (semester === 'HK1' ? 'Theme3_Total' : 'Theme7_Total')
	                    : `TX_L3_${semester}`
	            } else if (key === 'TX4') {
	                maCotDiem = monHocCode === 'anh'
	                    ? (semester === 'HK1' ? 'Theme4_Total' : 'Theme8_Total')
	                    : `TX_L4_${semester}`
	            } else if (key === 'TX5') {
	                maCotDiem = `TX_L5_${semester}`
	            } else if (key === 'GK') {
	                if (monHocCode === 'anh') {
	                    maCotDiem = semester === 'HK1' ? 'S1_Mid_Total_Point' : 'S2_Mid_Total_Point'
	                } else if (monHocCode === 'ai') {
	                    maCotDiem = `DiemCD1_${semester}`
	                } else {
	                    maCotDiem = `DiemGK_${semester}`
	                }
	            } else if (key === 'CK') {
	                if (monHocCode === 'anh') {
	                    maCotDiem = semester === 'HK1' ? 'S1_Final_Total_Point' : 'S2_Final_Total_Point'
	                } else if (monHocCode === 'ai') {
	                    maCotDiem = `DiemCD2_${semester}`
	                } else {
	                    maCotDiem = `DiemCK_${semester}`
	                }
	            } else if (key === 'DTB' || key === 'DiemTB_CaNam') {
	                maCotDiem = `DiemTB_${semester}`
	            }
	
	            if (!maCotDiem) return null
	            const lockKey = `${maCotDiem}_IsLock`
	            if (!Object.prototype.hasOwnProperty.call(itemHocSinhMon, lockKey)) return null
	            return itemHocSinhMon[lockKey]
	        },
	
	        // Giữ nút ở trạng thái chờ trong suốt lần lấy dữ liệu và luôn khôi phục sau khi API hoàn tất hoặc lỗi.
	        async onLoadBangDiemLMS() {
	            if (!this.LopItem?.LopID || this.IsLoadingCompareLMS) return
	            this.IsLoadingCompareLMS = true
	            this.IsCompareLMS = false
	            this.DSHocSinh_LMS = []
	            try {
	                const res = await fetchPromise('lms/HocSinhBangDiem_Get_ByLopID_Semester', {
	                    Semester: this.Semester.value,
	                    NienKhoa: vueData.NienKhoa,
	                    LopID: this.LopItem.LopID,
	                }, { cache: false })
	
	                const hocSinhBangDiem = this.extractList(res)
	                const newData = []
	                const hocSinhIDs = [...new Set(hocSinhBangDiem.map(x => x.HocSinhID))]
	                for (const hocSinhID of hocSinhIDs) {
	                    const obj = {
	                        HocSinhID: hocSinhID,
	                        DSCotDiem: [],
	                    }
	                    const cotDiemByHocSinh = hocSinhBangDiem.filter(x => x.HocSinhID === hocSinhID)
	                    const monHocCodes = [...new Set(cotDiemByHocSinh.map(x => x.MonHocCode))]
	                    for (const monHocCode of monHocCodes) {
	                        const arrMonHoc = cotDiemByHocSinh.filter(x => x.MonHocCode.toLowerCase() === monHocCode.toLowerCase())
	                        const newObj = {
	                            HocSinhID: hocSinhID,
	                            MonHocCode: monHocCode,
	                        }
	                        for (const cd of arrMonHoc) {
	                            newObj[cd.MaCotDiem] = cd.KetQuaDanhGia_VI
	                            newObj[`${cd.MaCotDiem}_IsLock`] = cd.IsLock
	                        }
	                        obj.DSCotDiem.push(newObj)
	                    }
	                    newData.push(obj)
	                }
	
	                const arr = []
	                for (const hs of newData) {
	                    arr.push(hs.DSCotDiem)
	                }
	                this.DSHocSinh_LMS = arr.flat()
	                this.IsCompareLMS = true
	            } catch (error) {
	                console.error('onLoadBangDiemLMS error:', error)
	                this.snackbarRef.value.showSnackbar({
	                    message: this.isEn ? 'Failed to compare LMS grades' : 'So sánh điểm LMS thất bại',
	                    color: 'error',
	                })
	            } finally {
	                this.IsLoadingCompareLMS = false
	            }
	        },
	
	        async fnKeoDiem(selectedColumns = []) {
	            const ok = await this.confirmRef.value.show({ title: this.isEn ? 'Confirm pulling grades?' : 'Xác nhận kéo điểm?' })
	            if (!ok) return
	
	            const dataToPull = this.buildPayloadBySelectedColumns(this.DSHocSinh_API_QLD , selectedColumns)
	            if (!dataToPull.length) {
	                this.snackbarRef.value.showSnackbar({ message: this.isEn ? 'No data available to pull grades' : 'Không có dữ liệu để kéo điểm', color: 'warning' })
	                return
	            }
	
	            const taskMap = new Map()
	            for (const item of dataToPull) {
	                const key = `${item.HocSinhID}__${item.MonHocID}`
	                if (!taskMap.has(key)) {
	                    taskMap.set(key, {
	                        HocSinhID: item.HocSinhID,
	                        MonHocID: item.MonHocID,
	                        JsonData: [],
	                    })
	                }
	                taskMap.get(key).JsonData.push(item)
	            }
	            const tasks = [...taskMap.values()]
	            this.IsPullingDiem = true
	            this.PullProgressTotal = tasks.length
	            this.PullProgressCurrent = 0
	            this.PullProgressText = this.isEn ? 'Preparing to pull grades...' : 'Đang chuẩn bị kéo điểm...'
	
	            try {
	                for (const task of tasks) {
	                    this.PullProgressCurrent += 1
	                    this.PullProgressText = this.isEn
	                        ? `Pulling student ${task.HocSinhID} - subject ${task.MonHocID} (${this.PullProgressCurrent}/${this.PullProgressTotal})`
	                        : `Đang kéo HS ${task.HocSinhID} - môn ${task.MonHocID} (${this.PullProgressCurrent}/${this.PullProgressTotal})`
	                    await fetchPromise(`lms/fn_HocSinh_KeoDiem_C${vueData.CapID}`, {
	                        JsonData: task.JsonData,
	                    }, { cache: false, silent: true })
	                }
	
	                this.PullProgressText = this.isEn
	                    ? `Completed (${this.PullProgressTotal}/${this.PullProgressTotal})`
	                    : `Hoàn tất (${this.PullProgressTotal}/${this.PullProgressTotal})`
	                this.snackbarRef.value.showSnackbar({ message: this.isEn ? 'Grades pulled successfully' : 'Kéo điểm thành công', color: 'success' })
	                this.IsShowDialogKeoDiem = false
	                await this.onLoadBangDiemLMS()
	            } catch (error) {
	                this.snackbarRef.value.showSnackbar({ message: this.isEn ? 'Failed to pull grades' : 'Kéo điểm thất bại', color: 'error' })
	            } finally {
	                this.resetPullProgress()
	            }
	        },
	    },
	}
</script>