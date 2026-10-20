<template>
	<div v-if="loading" class="pa-4">
		<v-skeleton-loader type="card-avatar, article"></v-skeleton-loader>
	</div>
	<div class="d-flex flex-column h-100">
		<v-card v-if="!loading" style="position: sticky; top:0; z-index:50;" class="submission-stats-card"
			variant="flat">
			<v-card-text class="pa-1">
				<v-row align="center" dense class="header-row" :class="isMobile ? 'py-2' : ''">
					<v-col cols="12" md="8" class="border-e-md " :class="isMobile ? 'py-0' : ''">
						<div class="mb-1">
							<div class="d-flex align-baseline ga-2">
								<div class="text-overline text-primary">Thống kê:</div>
								<div class="text-subtitle-1 font-weight-bold text-truncate">
									{{ assignmentTitle || '--' }}
								</div>
							</div>
							<div class="d-flex align-baseline ga-2">
								<div class="text-overline text-primary">Lớp:</div>
								<div class="text-subtitle-1 font-weight-bold text-truncate">
									{{ lessonInfo?.TenLopNhom }}
								</div>
							</div>
						</div>
					</v-col>

					<!-- ======================================================= -->
					<!-- == CỘT BÊN PHẢI: THỐNG KÊ GỌN                       == -->
					<!-- ======================================================= -->
					<v-col cols="12" md="4" class="d-flex align-center justify-space-around "
						:class="isMobile ? 'py-0' : ''">
						<!-- Thống kê Tỉ lệ học bài -->
						<div class="text-center">
							<div class="text-overline mb-1">Đã hoàn thành bài học</div>
							<div class="d-flex align-baseline justify-center">
								<div class="text-h5 font-weight-bold text-primary">{{ stats?.LearnedCount || 0 }}</div>
								<div class="text-h6">/{{ stats?.TotalStudents || 0 }}</div>
							</div>
							<v-progress-linear :model-value="completionRate" :color="completionColor" height="8" rounded
								class="my-1 mx-auto" style="width: 120px;" />
							<div class="text-caption text-primary">{{ completionRate.toFixed(2) }}% Hoàn thành</div>
						</div>
					</v-col>
				</v-row>
			</v-card-text>
		</v-card>
		<!-- Bảng danh sách học sinh -->
		<v-card class="table-card mt-2 flex-1-1" v-if="!loading">
			<v-card-title
				class="table-title-sticky d-flex flex-column flex-md-row align-md-center align-start justify-md-space-between justify-start">
				<span style="color:black" v-if="!isMobile">Danh sách học sinh</span>
				<div class="d-flex flex-column flex-md-row justify-md-end w-100 ga-2">
					<v-text-field v-model="search" label="Tìm học sinh..." prepend-inner-icon="mdi-magnify" variant="outlined"
						class="text-grey-darken-1" density="compact" hide-details style="max-width: 300px;" />
				</div>
			</v-card-title>
			<v-data-table class="table-custom" :headers="headers" :items="processedSubmissions" :search="search" fixed-header
				height="calc(100vh - 220px)" :items-per-page="-1" :mobile="isMobile" :loading="loading" hide-default-footer
				density="compact"> 
				<template #item.HocSinhID="{ item }">
					<div class="text-muted">{{ item.HocSinhID }}</div>
				</template>
				<template #item.HoTen="{ item }">
					<div class="">{{ item.HoTen }}</div>
				</template>
				<template #item.SoDanhBo="{ item }">
					<div class="text-muted">{{ item.SoDanhBo ?? item.SoTT }}</div>
				</template>
				<template #item.Status="{ item }">
					<v-chip :color="statusColors[item.Status]" size="small" variant="text"
						class="font-weight-medium pa-0">
						{{ statusTexts[item.Status] }}
					</v-chip>
				</template>
			<template #item.CompletedDate="{ item }">
				<span v-if="item.CompletedDate">{{ formatDate(item.CompletedDate) }}</span>
				<span v-else class="text-medium-emphasis">—</span>
			</template>
			<template #item.CompletedBy="{ item }">
				<!-- CompletionSource mới phân biệt người hoàn thành; bản ghi cũ không có audit thì không suy đoán. -->
				<span v-if="item.CompletionSource === 'AUTO_TIME'">Học sinh: {{ item.HoTen }}</span>
				<span v-else-if="item.CompletionSource === 'TEACHER_MANUAL'">
					Giáo viên<span v-if="item.CompletedByUserID">: {{ item.CompletedByUserID }}</span>
					<span v-else>: chưa xác định</span>
				</span>
				<span v-else class="text-medium-emphasis">—</span>
			</template>
			<template #item.Actions="{ item }">
				<!-- Chỉ cho xác nhận thủ công khi học sinh đã có tiến trình IN_PROCESS; NOT_COMPLETED nghĩa là chưa bắt đầu. -->
				<v-btn v-if="item.Status === 'IN_PROCESS'" size="small" color="success" variant="text"
					prepend-icon="mdi-check-circle-outline" :loading="markingHocSinhID === item.HocSinhID"
					:disabled="markingHocSinhID !== null" @click="markStudentCompleted(item)">
					Hoàn thành
				</v-btn>
				<span v-else-if="item.Status === 'COMPLETED'" class="text-medium-emphasis">Đã hoàn thành</span>
				<span v-else class="text-medium-emphasis">Chưa bắt đầu</span>
			</template>
			<template #item.Score="{ item }">
					<span class="font-weight-bold" :class="getScoreColor(item.Score)">
						{{ item.Score != null ? item.Score : '—' }}
					</span>
					<span class="font-weight-bold text-success" v-tooltip="`Điểm tối đa`">
						/ {{ item.MaxScore != null ? item.MaxScore : '—' }}
					</span>
				</template>

				<template #no-data>
					<div class="text-center pa-4 text-medium-emphasis">
						Vui lòng chọn Lớp, Môn và Bài tập để xem dữ liệu.
					</div>
				</template>
			</v-data-table>
		</v-card>
		<!-- Fallback cho màn hình không nhận được confirmRef từ app shell; vẫn phải xác nhận trước khi ghi nhận thủ công. -->
		<v-dialog v-model="completionConfirmVisible" max-width="460" persistent>
			<v-card>
				<v-card-title class="text-warning">Xác nhận hoàn thành</v-card-title>
				<v-card-text>
					Bạn có chắc muốn đánh dấu hoàn thành bài học cho
					<strong>{{ pendingCompletionStudent?.HoTen }}</strong>?
					<div class="text-body-2 text-medium-emphasis mt-2">
						Thao tác này sẽ ghi nhận giáo viên là người xác nhận hoàn thành bài học.
					</div>
				</v-card-text>
				<v-card-actions>
					<v-spacer />
					<v-btn variant="text" :disabled="markingHocSinhID !== null" @click="cancelMarkStudentCompleted">
						Hủy
					</v-btn>
					<v-btn color="success" variant="flat" :loading="markingHocSinhID !== null"
						@click="confirmMarkStudentCompleted">
						Hoàn thành
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-baocaobaitapdanop',
		inject: ['confirmRef'],
		props: {
			assigntoclassid: Number,
			assignmentid: Number,
			khoiid: Number,
			lopid: String,
			monhocid: Number
		},
		data() {
			const { mobile } = Vuetify.useDisplay()
			return {
				vueData,
				loading: false,
				lopList: [], monHocList: [], assignmentList: [],
				lessonInfo: {}, mostIncorrect: [], studentLearning: [],
				selectedLopID: null,
				selectedMonHocID: null,
				selectedAssignToClassID: this.assigntoclassid,
				search: '',
				headers: [
					{ title: 'Mã HS', key: 'HocSinhID', sortable: true },
					{ title: 'Số danh bộ', key: 'SoDanhBo', sortable: true },
						{ title: 'Học sinh', key: 'HoTen', sortable: true },
						{ title: 'Trạng thái', key: 'Status', sortable: true },
						{ title: 'Thời gian hoàn thành', key: 'CompletedDate', sortable: true },
						{ title: 'Người hoàn thành', key: 'CompletedBy', sortable: true },
						{ title: 'Thao tác', key: 'Actions', sortable: false, align: 'center' },
					],
				statusColors: { 'COMPLETED': 'success', 'NOT_COMPLETED': 'grey', 'IN_PROCESS': 'blue' },
				statusTexts: { 'COMPLETED': 'Đã hoàn thành', 'NOT_COMPLETED': 'Chưa hoàn thành', 'IN_PROCESS': 'Đang học' },
				isOpen: false,
				url: "",
				isMobile: mobile,
				stats: {},
				markingHocSinhID: null,
				completionConfirmVisible: false,
				pendingCompletionStudent: null
			}
		},
		computed: {
			assignmentTitle() {
				return this.lessonInfo?.Title || '...';
			},
			processedSubmissions() {
				if (!this.studentLearning || !Array.isArray(this.studentLearning)) return [];
				return this.studentLearning.map(item => ({
					HocSinhID: item.HocSinhID,
					SoDanhBo: item.SoDanhBo,
					HoTen: item.HoTen || 'Lỗi dữ liệu',
					Status: item.Status || 'NOT_SUBMITTED',
						CompletedDate: item.CompletedDate,
						CompletedByUserID: item.CompletedByUserID,
						CompletionSource: item.CompletionSource,
						ProgressID: item.ProgressID,
				}));
			},
			completionRate() {
				if (!this.stats.TotalStudents || this.stats.TotalStudents === 0) return 0;
				console.log("stats", this.stats)
				return ((this.stats.LearnedCount || 0) / this.stats.TotalStudents) * 100;
			},
			completionColor() {
				const rate = this.completionRate;
				if (rate < 30) return 'error'; if (rate < 70) return 'warning'; return 'success';
			}
		},
		watch: {
			isOpen(val) {
				if (val) {
					let dom = document.getElementsByClassName("v-toolbar")[2]
					if (dom) {
						dom.style.display = 'none'
					}
				} else {
					let dom = document.getElementsByClassName("v-toolbar")[2]
					if (dom) {
						dom.style.display = 'block'
					}
				}
			}
		},
		methods: {
			clearReportData() {
				this.lessonInfo = {};
				this.mostIncorrect = [];
				this.studentLearning = [];
			},
			async initialize() {
				vueData.loading = true;
				if (!this.selectedAssignToClassID) {
					vueData.loading = false
					return
				}
				await this.GetLessontStats(this.selectedAssignToClassID)
				await this.getLessonInfo(this.selectedAssignToClassID)
				await this.fetchstudentLearning(this.selectedAssignToClassID)
				vueData.loading = false;
			},
	
	
			async getLessonInfo(assignToClassID) {
				await ajaxCALL("lms/EL_Teacher_GetLessonByAssignToClassID", { AssignToClassID: assignToClassID }, (res) => {
					this.lessonInfo = res.data[0] || {};
				});
			},
	
			async GetLessontStats(assignToClassID) {
				await ajaxCALL("lms/EL_Teacher_GetLessontStats", { AssignToClassID: assignToClassID }, (res) => {
					this.stats = res.data[0] || {};
				});
			},
	
			async fetchstudentLearning(assignToClassID) {
				vueData.loading = true;
				this.studentLearning = await ajaxCALLPromise("lms/EL_Teacher_GetLearning_ProgressByStudent", { AssignToClassID: assignToClassID })
				vueData.loading = false;
			},
			// Cho phép giáo viên xác nhận hoàn thành khi học sinh đã học xong nội dung sớm hơn mốc thời gian cấu hình.
			async markStudentCompleted(item) {
				if (!item?.HocSinhID || item.Status === 'COMPLETED') return;

				const confirmDialog = this.confirmRef?.value;
				// Ưu tiên dialog chung của FUI; một số màn hình module chạy tách shell nên cần fallback cục bộ.
				if (confirmDialog?.show) {
					const confirmed = await confirmDialog.show({
					title: `Xác nhận hoàn thành bài học cho ${item.HoTen}?`,
					text: 'Thao tác này sẽ ghi nhận giáo viên là người xác nhận hoàn thành bài học.',
					type: 'warning',
					confirmText: 'Hoàn thành',
					cancelText: 'Hủy'
					});
					if (!confirmed) return;
					await this.submitStudentCompletion(item);
					return;
				}

				this.pendingCompletionStudent = item;
				this.completionConfirmVisible = true;
			},
			// Chỉ gọi API sau khi giáo viên xác nhận trong dialog fallback.
			async confirmMarkStudentCompleted() {
				const item = this.pendingCompletionStudent;
				if (!item?.HocSinhID || item.Status === 'COMPLETED') {
					this.cancelMarkStudentCompleted();
					return;
				}

				this.completionConfirmVisible = false;
				this.pendingCompletionStudent = null;
				await this.submitStudentCompletion(item);
			},
			cancelMarkStudentCompleted() {
				if (this.markingHocSinhID !== null) return;
				this.completionConfirmVisible = false;
				this.pendingCompletionStudent = null;
			},
			async submitStudentCompletion(item) {
				this.markingHocSinhID = item.HocSinhID;
				try {
					await ajaxCALLPromise('lms/EL_Teacher_MarkLearningProgressCompleted', {
						AssignToClassID: this.selectedAssignToClassID,
						HocSinhID: item.HocSinhID
					});
					Vue.$toast.success(`Đã đánh dấu hoàn thành cho ${item.HoTen}.`, { position: 'top' });
					await this.initialize();
				} catch (error) {
					console.error('[LESSON_PROGRESS] Không thể đánh dấu hoàn thành:', error);
					Vue.$toast.error(error?.message || 'Không thể đánh dấu hoàn thành.', { position: 'top' });
				} finally {
					this.markingHocSinhID = null;
				}
			},
			getScoreColor(score) {
				if (score == null) return '';
				if (score < 5.0) return 'score-bad'; if (score < 7.0) return 'score-average'; return 'score-good';
			},
	
			ontest(item) {
				this.emitToParent()
				this.url = `https://lms.lhbs.vn/lms_tc_grade_asm?SubmissionID=${item.SubmissionID}`
				this.isOpen = true
	
			},
			async onClose() {
				this.isOpen = false
				window.parent.postMessage(
					{ type: "fromIframe", value: "show" },
					"*"
				)
				await this.initialize()
			},
			emitToParent() {
				window.parent.postMessage(
					{ type: "fromIframe", value: "hide" },
					"*"
				)
			},
			formatDate(input) {
				const formated = dayjs(input).format("HH:mm DD/MM/YYYY")
				return formated
			},
			dayjs
		},
		async mounted() {
			await this.initialize();
		},
	}
</script>

<style scoped>
.submission-lessonInfo-card .v-col {
		padding: 16px;
	}

	.text-truncate {
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
</style>