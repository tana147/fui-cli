<template>
	<!-- ── LOADING ── -->
	<div v-if="!assignment" class="uat__loading text-center pa-10">
		<v-progress-circular indeterminate size="64" />
		<p class="mt-4 text-medium-emphasis">Đang tải đề bài...</p>
	</div>

	<!-- ── MAIN ── -->
	<div v-else style="height: 100dvh; display: flex; flex-direction: column; overflow: hidden;">

		<!-- Header thông tin bài tập -->
		<AssignmentHeader :assignment="assignment" :mon-hoc-name="monHocName" :student="hocSinhDetail" :draft="draft" />

		<!-- Nhận xét giáo viên (chỉ hiện khi đã chấm và có nhận xét) -->
		<v-card v-if="isGraded && draft?.TeacherComment?.trim()" class="mx-2 mb-2" flat border>
			<v-card-text class="py-1">
				<v-btn size="small" variant="text" @click="toggleTC = !toggleTC">
					<v-icon start size="16">mdi-comment-quote-outline</v-icon>
					{{ toggleTC ? 'Ẩn nhận xét GV' : 'Xem nhận xét GV' }}
				</v-btn>
				<v-expand-transition>
					<div v-show="toggleTC" class="mt-1 text-body-2" v-html="draft?.TeacherComment" />
				</v-expand-transition>
			</v-card-text>
		</v-card>

		<!-- Layout chính -->
		<v-row dense style="flex: 1 1 0; min-height: 0; overflow: hidden; margin: 0;">

			<v-col v-if="isIntegrated" cols="12"
				style="height: 100%; display: flex; flex-direction: column; overflow: hidden; padding: 0;">
				<v-card flat class="rounded-0 border-b">
					<v-card-text class="py-2 px-4 d-flex align-center justify-space-between ga-2">
						<div class="d-flex align-center ga-2">
							<v-icon color="info">mdi-information-outline</v-icon>
							<span class="text-body-2 text-medium-emphasis">Làm bài tại trang liên kết bên dưới.</span>
						</div>
						<div>
							<v-btn v-if="!isSubmitted" color="success" variant="flat" size="small"
								@click="handleSubmit">
								<v-icon start>mdi-check-all</v-icon>Nộp bài
							</v-btn>
							<v-chip v-else color="success" size="small" label>
								<v-icon start size="14">mdi-check-decagram</v-icon>
								{{ isGraded ? 'Đã chấm điểm' : 'Đã nộp bài' }}
							</v-chip>
						</div>
					</v-card-text>
				</v-card>
				<div style="flex: 1; min-height: 0;">
					<iframe :src="assignment.IntegrationLink || assignment.Instructions" width="100%" height="100%"
						frameborder="0"></iframe>
				</div>
			</v-col>

			<!-- Sidebar điều hướng (ẩn trên mobile) -->
			<v-col v-if="!isMobile && !isIntegrated" cols="12" sm="12" md="2"
				style="height: 100%; overflow: hidden; border-inline-end: 0.5px dashed #a7a2a2; padding: 0;">
				<QuestionNavigation :groups="assignment.groups" :user-answers="userAnswers"
					:current-group-index="currentGroupIndex" :current-question-index="currentQuestionIndexInGroup"
					:draft="draft" :assignment="assignment" :get-icon-color="getIconColor"
					:get-status-icon="getQuestionStatusIcon" :get-question-number="getGlobalQuestionNumber"
					:unlocked-question-ids="unlockedQuestionIds"
					v-model:view-mode="viewMode" @navigate="navigateToQuestion" />
			</v-col>

			<!-- Nội dung câu hỏi -->
			<v-col v-if="!isIntegrated" cols="12" md="10"
				style="height: 100%; display: flex; flex-direction: column; overflow: hidden; padding: 0;">

				<!-- ── CHẾ ĐỘ 1 CÂU ── -->
				<template v-if="viewMode === 'single'">

					<AssignmentProgress v-show="shouldShowProgress" style="flex: 0 0 auto;" :answered-count="answeredCount"
						:total-questions="totalQuestions" :progress-percent="progressPercent" :save-status="saveStatus"
						:save-status-color="saveStatusColor" :save-status-icon="saveStatusIcon"
						:is-submitted="isSubmitted" :is-graded="isGraded" @submit="handleSubmit" />

					<v-card v-if="currentQuestion?.config" class="uat__question-card mx-2 mb-2" flat border
						style="flex: 1 1 0; min-height: 0; display: flex; flex-direction: column; overflow: hidden;">
						
						<!-- Phần nội dung cuộn (GroupHeader + QuestionCard) -->
						<div style="flex: 1 1 0; min-height: 0; overflow-y: auto;">
							<div class="px-2">
								<GroupHeader :group="currentGroup" :answered-count="getGroupAnsweredCount(currentGroup)"
									:user-answers="userAnswers" :active-question-id="currentQuestion?.id"
									:group-index="currentGroupIndex"
									:unlocked-ids="unlockedQuestionIds"
									:literal-html-tags="isTinHoc"
									@select-question="handleSelectInteractiveQuestion"
									@marker-reached="handleInteractiveMarkerReached"
									@question-unlocked="handleQuestionUnlocked" />
							</div>

							<v-divider />

							<!-- Hiện tất cả câu trong nhóm -->
							<div v-if="currentGroup.isCheckShowAllQuestion">
								<!-- Chỉ hiển thị câu hỏi khi đã đến mốc video hoặc không bị khóa (ẩn hoàn toàn câu chưa đến mốc) -->
								<template v-for="question in currentGroup.questions" :key="question.id">
									<QuestionCard v-if="!isQuestionLocked(question, currentGroup)"
										:question="question" :question-number="getGlobalQuestionNumberByQuestionId(question.id)"
										:answer="getAnswerForChild(question)" :grading="userAnswers[question.id]?.grading"
										:readonly="isSubmitted" :submission-status="draft?.SubmissionStatus"
										:is-block-copy-paste="isBlockCopyPaste" :is-flagged="userAnswers[question.id]?.flag"
										:literal-html-tags="isTinHoc"
										:status="questionStatus(question.id, question.points)"
										:status-icon="getQuestionStatusIcon(question.id)"
										:icon-color="getIconColor(question.id)" class="px-2 pt-2 pb-0"
										@update:answer="updateAnswer(question.id, $event)" @flag="handleFlag(question.id)" />
								</template>
							</div>

							<!-- Hiện 1 câu -->
							<div v-else>
								<v-card-text class="px-2 pt-2 pb-0">
									<!-- Card thông báo khóa khi video chưa phát tới mốc thời gian của câu hỏi -->
									<v-card v-if="isQuestionLocked(currentQuestion, currentGroup)" variant="outlined"
										class="pa-6 text-center my-3 rounded-lg" style="background: #f8fafc; border: 1px dashed #cfd8dc;">
										<div class="d-flex align-center justify-center ga-2 text-deep-purple font-weight-bold mb-2">
											<v-icon size="28" color="deep-purple-accent-4">mdi-lock-clock</v-icon>
											<span class="text-subtitle-1">Câu {{ getGlobalQuestionNumberByQuestionId(currentQuestion.id) }} đang khóa</span>
										</div>
										<div class="text-body-2 text-medium-emphasis">
											Câu hỏi này sẽ tự động xuất hiện khi video phát đến thời điểm <b>{{ formatTimeMarker(currentQuestion.timeMarker) }}</b>.
										</div>
										<div class="text-caption text-grey mt-2">
											Vui lòng bấm Play video ở phía trên để tiếp tục bài học.
										</div>
									</v-card>
									<QuestionCard v-else :key="currentQuestion.id" :question="currentQuestion"
										:question-number="getGlobalQuestionNumberByQuestionId(currentQuestion.id)"
										:answer="getAnswerForChild(currentQuestion)"
										:grading="userAnswers[currentQuestion.id]?.grading" :readonly="isSubmitted"
										:submission-status="draft?.SubmissionStatus" :is-block-copy-paste="isBlockCopyPaste"
										:is-flagged="userAnswers[currentQuestion.id]?.flag"
										:literal-html-tags="isTinHoc"
										:status="questionStatus(currentQuestion.id, currentQuestion.points)"
										:status-icon="getQuestionStatusIcon(currentQuestion.id)"
										:icon-color="getIconColor(currentQuestion.id)"
										@update:answer="updateAnswer(currentQuestion.id, $event)"
										@flag="handleFlag(currentQuestion.id)" />
								</v-card-text>
							</div>
						</div>

						<v-divider />

						<!-- Thanh điều hướng câu trước / câu sau cố định ở đáy thẻ -->
						<v-card-actions class="pa-2 px-4 d-flex justify-space-between align-center uat__action-bar"
							style="flex: 0 0 auto;">
							<v-btn variant="outlined" color="primary" size="small" :disabled="isFirstQuestion" @click="prevQuestion">
								<v-icon start>mdi-chevron-left</v-icon>Câu trước
							</v-btn>

							<span class="text-caption text-medium-emphasis font-weight-medium">
								Câu {{ globalQuestionNumber }} / {{ totalQuestions }}
							</span>

							<v-btn variant="flat" color="primary" size="small" :disabled="isLastQuestion" @click="nextQuestion">
								Câu sau<v-icon end>mdi-chevron-right</v-icon>
							</v-btn>
						</v-card-actions>
					</v-card>
				</template>

				<!-- ── CHẾ ĐỘ TẤT CẢ CÂU ── -->
				<div v-else class="uat__all-mode" style="flex: 1 1 0; min-height: 0; overflow-y: auto;">
						<AssignmentProgress v-show="shouldShowProgress" class="my-2 mx-2" :answered-count="answeredCount"
							:total-questions="totalQuestions" :progress-percent="progressPercent" :save-status="saveStatus"
							:save-status-color="saveStatusColor" :save-status-icon="saveStatusIcon"
							:is-submitted="isSubmitted" :is-graded="isGraded" @submit="handleSubmit" />

						<div class="uat__questions-container">
							<div v-for="(group, groupIndex) in assignment.groups" :key="group.id"
								class="uat__group-section mb-6">
								<GroupHeader :group="group" :answered-count="getGroupAnsweredCount(group)"
									:user-answers="userAnswers" :active-question-id="currentQuestion?.id"
										:group-index="groupIndex"
										:unlocked-ids="unlockedQuestionIds"
										:literal-html-tags="isTinHoc"
										@select-question="handleSelectInteractiveQuestion"
									@marker-reached="handleInteractiveMarkerReached"
									@question-unlocked="handleQuestionUnlocked" />

								<div class="uat__questions-in-group">
									<!-- Chỉ hiển thị câu hỏi khi đã đến mốc video hoặc không bị khóa (ẩn hoàn toàn câu chưa đến mốc) -->
									<template v-for="(question, questionIndexInGroup) in group.questions" :key="question.id">
										<QuestionCard v-if="!isQuestionLocked(question, group)"
											:question="question"
											:question-number="getGlobalQuestionNumber(groupIndex, questionIndexInGroup)"
											:answer="getAnswerForChild(question)" :grading="userAnswers[question.id]?.grading"
											:readonly="isSubmitted" :submission-status="draft?.SubmissionStatus"
										:is-block-copy-paste="isBlockCopyPaste" :is-flagged="userAnswers[question.id]?.flag"
										:literal-html-tags="isTinHoc"
										:status="questionStatus(question.id, question.points)"
											:status-icon="getQuestionStatusIcon(question.id)"
											:icon-color="getIconColor(question.id)"
											@update:answer="updateAnswer(question.id, $event)"
											@flag="handleFlag(question.id)" />
									</template>
								</div>
							</div>
						</div>
					</div>

				</v-col>
			</v-row>
		</div>
</template>

<script>
	export default {
		name: 'uc-assignment-taker',
	
		// Mixins từ script.js
		mixins: [
			useQuestionNavigation(),
			useAnswerTracking(),
			useAutoSave(),
			useQuestionStatus(),
			useCopyPasteBlocker(),
			useTimeTracking(),
		],
	
		// ── PROPS ──────────────────────────────────────────────────
		props: {
			/** Bài làm hiện tại của học sinh { [questionId]: { answerData, flag, grading } } */
			puseranswers: { type: Object, default: () => ({}) },
			/** Response từ API: [[assignmentInfo], [submissionInfo]] */
			assignmentData: { type: Array, default: () => [] },
			/** Tên môn học */
			monHocName: { type: String, default: '' },
			/** Thông tin học sinh (từ AssignmentTakerPage) */
			hocSinhDetail: { type: Object, default: () => ({}) },
			/** Câu trả lời đã nộp — dùng khi xem lại bài đã chấm */
			userAnswersSubmitted: { type: Object, default: () => ({}) },
			/** Callback lưu nháp — trả về Promise */
			onSaveDraft: { type: Function, default: () => Promise.resolve() },
			/** Callback lưu flag sau khi đã nộp bài (status > 2) — API TBD */
			onSaveFlagsPostSubmit: { type: Function, default: () => Promise.resolve() },
			/** Callback mở dialog xác nhận nộp bài */
			onOpenSubmitDialog: { type: Function, default: () => { } },
		},
	
		emits: ['update:puseranswers'],
	
		// ── DATA ───────────────────────────────────────────────────
		data() {
			return {
				// View state
				viewMode: 'all',   // 'single' | 'all'
				groupCollapsed: {},
				currentGroupIndex: 0,
				currentQuestionIndexInGroup: 0,
				toggleTC: false,
	
				// Responsive
				isMobile: false,
				isTablet: false,
	
				// Time tracking
				intervalDurationTime: null,
				resizeHandler: null,
	
				// Lodash ref (dùng trong template nếu cần)
				_,

				// Video tương tác: danh sách ID câu hỏi đã mở khóa theo mốc thời gian video
				unlockedQuestionIds: [],

				// Cache nội bộ
				_questionComponentCache: new Map(),
				_answerCache: new Map(),
			};
		},
	
		// ── COMPUTED ───────────────────────────────────────────────
		computed: {
			/** Alias để mixins dùng thống nhất qua this.userAnswers */
				userAnswers() {
					return this.puseranswers || {};
				},

				/**
				 * Chỉ môn Tin học cần hiển thị nguyên văn các thẻ HTML trong câu hỏi/đáp án.
				 * Chuẩn hóa dấu tiếng Việt và khoảng trắng để chịu được tên môn như "Tin học 12".
				 */
				isTinHoc() {
					const subject = String(this.monHocName || '')
						.normalize('NFD')
						.replace(/[\u0300-\u036f]/g, '')
						.replace(/đ/gi, 'd')
						.toLowerCase()
						.trim();
					return /\btin hoc\b/.test(subject);
				},
	
			/**
			 * Parse AssignmentConfig — có cache để tránh parse lại mỗi render.
			 * Khi đã graded → dùng AssignmentConfig_HadAnswer (có đáp án đúng).
			 */
			assignment() {
				const config = this.assignmentData?.[0]?.[0];
				if (!config) return null;
	
				const submissionStatus = this.assignmentData[1]?.[0]?.SubmissionStatus;
				const isGraded = submissionStatus === 4;
	
				// Xóa cache nếu vừa chuyển sang graded nhưng cache chưa có đáp án
				if (isGraded && config._cachedGroups?.[0]?.questions?.[0]?.config?.correctAnswer === null) {
					delete config._cachedGroups;
				}
	
				if (!config._cachedGroups) {
					try {
						const raw = (isGraded && config.AssignmentConfig_HadAnswer)
							? config.AssignmentConfig_HadAnswer
							: config.AssignmentConfig;
						const parsed = JSON.parse(raw);
						config._cachedGroups = parsed.groups || [];
						config.groups = config._cachedGroups;
	
						// Hỗ trợ bài tập tích hợp (Integration) - Chỉ xử lý khi source không phải là 'LMS'
						if (parsed.type === 'INTEGRATED' || (config.IntegrationSource && config.IntegrationSource !== 'LMS')) {
							config.Type = 'INTEGRATED';
							config.IntegrationLink = parsed.link || config.Instructions;
						}
					} catch (e) {
						console.error('[uc-assignment-taker] Lỗi parse AssignmentConfig:', e);
						config._cachedGroups = [];
						config.groups = [];
					}
				} else {
					config.groups = config._cachedGroups;
				}
	
				return config;
			},
	
			isIntegrated() {
				return this.assignment?.Type === 'INTEGRATED' || (!!this.assignment?.IntegrationSource && this.assignment?.IntegrationSource !== 'LMS');
			},
	
			/** Thông tin bài nộp hiện tại */
			draft() {
				return this.assignmentData?.[1]?.[0] || null;
			},
	
			isSubmitted() {
				return (this.draft?.SubmissionStatus ?? 0) >= 2;
			},
	
			isGraded() {
				return this.isSubmitted && this.draft?.SubmissionStatus === 4;
			},
	
			isBlockCopyPaste() {
				return this.assignment?.IsBlockCopy_Paste === true;
			},
	
			contentCardStyle() {
				return { height: '100%', overflow: 'auto' };
			},
	
			shouldShowProgress() {
				const s = this.draft?.SubmissionStatus;
				return s !== 4 && s !== 3 && !this.isIntegrated;
			},
	
			isFirstQuestion() {
				return this.globalQuestionNumber === 1;
			},
	
			isLastQuestion() {
				return this.globalQuestionNumber === this.totalQuestions;
			},
		},
	
		// ── WATCHERS ───────────────────────────────────────────────
		watch: {
			assignmentData: {
				handler(val) {
					if (val) {
						this._questionComponentCache.clear();
						this._answerCache.clear();
					}
				},
				deep: false,
			},
	
			isMobile(val) {
				if (val) this.viewMode = 'all';
			},
		},
	
		// ── LIFECYCLE ──────────────────────────────────────────────
		created() {
			this.resizeHandler = _.throttle(this._onResize, 200);
		},
	
		mounted() {
			window.addEventListener('resize', this.resizeHandler, { passive: true });
			this._onResize();
			this._initializeAnswers();
			this._startTimeTracking();
	
			if (this.isBlockCopyPaste) this.addCopyPasteBlocker();
		},
	
		beforeUnmount() {
			window.removeEventListener('resize', this.resizeHandler);
			this.resizeHandler = null;
	
			this._stopTimeTracking();
	
			if (this.autoSaveTimer) clearTimeout(this.autoSaveTimer);
			if (this.isBlockCopyPaste) this.removeCopyPasteBlocker();
	
			this._questionComponentCache.clear();
			this._answerCache.clear();
		},
	
		// ── METHODS ────────────────────────────────────────────────
		methods: {
	
			// ══════════════════════════════════════════════════════
			// RESPONSIVE
			// ══════════════════════════════════════════════════════
	
			_onResize() {
				this.isMobile = window.innerWidth < 960;
				this.isTablet = window.innerWidth <= 1240;
			},
	
			// ══════════════════════════════════════════════════════
			// ANSWER — lấy dữ liệu trả lời để truyền xuống QuestionCard
			// ══════════════════════════════════════════════════════
	
			getAnswerForChild(question) {
				if (!question) return null;
	
				const cached = this._answerCache.get(question.id);
				const current = this.userAnswers[question.id];
	
				if (cached && cached.answer === current?.answerData) {
					return cached.result;
				}
	
				let result;
				if (question.type === 'FILE_UPLOAD') {
					result = (!current || current.answerData === undefined) ? [] : current.answerData;
				} else {
					result = current?.answerData;
				}
	
				this._answerCache.set(question.id, { answer: current?.answerData, result });
				return result;
			},
	
			// ══════════════════════════════════════════════════════
			// ANSWER — cập nhật khi học sinh trả lời
			// ══════════════════════════════════════════════════════
	
			updateAnswer(questionId, newAnswer) {
				if (this.isSubmitted) return;
	
				const question = this.allQuestions.find(q => q.id === questionId);
				if (!question) {
					console.error(`[uc-assignment-taker] Không tìm thấy câu hỏi ID: ${questionId}`);
					return;
				}
	
				const newAnswers = { ...this.userAnswers };
				const currentAnswerObj = newAnswers[questionId] || {};
				const fileTypes = ['FILE_UPLOAD', 'AUDIO_RESPONSE'];
				const manualTypes = ['SHORT_ANSWER', 'ESSAY', 'FILE_UPLOAD', 'AUDIO_RESPONSE'];
	
				const answerData = fileTypes.includes(question.type)
					? (Array.isArray(newAnswer) ? newAnswer : [newAnswer])
					: newAnswer;
	
				newAnswers[questionId] = {
					...currentAnswerObj,
					answerData,
					grading: {
						teacherComment: currentAnswerObj.grading?.teacherComment ?? '',
						comment: currentAnswerObj.grading?.comment ?? '',
						...(manualTypes.includes(question.type) ? { manualScore: null } : {}),
					},
				};
	
				this._answerCache.delete(questionId);
				this.$emit('update:puseranswers', newAnswers);
				this.triggerAutoSave();
			},
	
			// ══════════════════════════════════════════════════════
			// ANSWER — khởi tạo structure bài làm từ SubmissionContent
			// ══════════════════════════════════════════════════════
	
			_initializeAnswers() {
				if (this.draft?.SubmissionContent) {
					try {
						const asmConfigStr = this.assignmentData?.[0]?.[0]?.AssignmentConfig;
						if (!asmConfigStr) {
							this.$emit('update:puseranswers', {});
							return;
						}
	
						const asmData = JSON.parse(asmConfigStr);
						if (!Array.isArray(asmData?.groups)) {
							this.$emit('update:puseranswers', {});
							return;
						}
	
						let saved = { answers: {} };
						try { saved = JSON.parse(this.draft.SubmissionContent); } catch { /* giữ default */ }
	
						const answers = saved?.answers || {};
	
						// Chuẩn hóa kiểu dữ liệu điểm để UI không hiển thị 0 khi backend trả về string.
						Object.keys(answers).forEach(questionId => {
							const answerObj = answers[questionId] || {};
							const grading = answerObj.grading || {};
							answers[questionId] = {
								...answerObj,
								grading: {
									...grading,
									manualScore: this._normalizeScoreValue(grading.manualScore),
									autoScore: this._normalizeScoreValue(grading.autoScore),
								},
							};
						});
	
						// Đảm bảo mỗi câu hỏi đều có structure đủ
						asmData.groups.forEach(group => {
							(group.questions || []).forEach(question => {
								if (!question.id) return;
								if (!answers[question.id]) {
									answers[question.id] = {
										answerData: null,
										flag: false,
										grading: { comment: null, teacherComment: null, manualScore: null },
									};
								} else if (answers[question.id].flag === undefined) {
									answers[question.id].flag = false;
								}
							});
						});
	
						this.$emit('update:puseranswers', answers);
					} catch (e) {
						console.error('[uc-assignment-taker] Lỗi _initializeAnswers:', e);
						this.$emit('update:puseranswers', {});
					}
				} else {
					// Chưa có bài nộp → tạo draft mới + khởi tạo groupCollapsed
					this.saveDraft();
					if (this.assignment?.groups) {
						const collapsed = {};
						this.assignment.groups.forEach((_, i) => { collapsed[i] = false; });
						this.groupCollapsed = collapsed;
					}
				}
			},
	
			_normalizeScoreValue(value) {
				if (value === null || value === undefined || value === '') return value ?? null;
				const num = Number(value);
				return Number.isFinite(num) ? num : value;
			},
	
			// ══════════════════════════════════════════════════════
			// FLAG (đánh dấu câu để xem lại)
			// ══════════════════════════════════════════════════════
	
			handleFlag(qid) {
				const newAnswers = { ...this.userAnswers };
				if (!newAnswers[qid]) {
					newAnswers[qid] = {
						answerData: null,
						flag: true,
						grading: { comment: null, teacherComment: null, manualScore: null },
					};
				} else {
					const currentFlag = newAnswers[qid].flag ?? false;
					newAnswers[qid] = { ...newAnswers[qid], flag: !currentFlag };
				}
				this.$emit('update:puseranswers', newAnswers);
				if (this.isSubmitted) {
					this.saveFlagsOnly(newAnswers);
				} else {
					this.triggerAutoSave();
				}
			},
	
			// ══════════════════════════════════════════════════════
			// GROUP COLLAPSE
			// ══════════════════════════════════════════════════════
	
			toggleGroupCollapse(groupIndex) {
				this.groupCollapsed = {
					...this.groupCollapsed,
					[groupIndex]: !this.groupCollapsed[groupIndex],
				};
			},
	
			// ══════════════════════════════════════════════════════
			// TIME TRACKING
			// ══════════════════════════════════════════════════════
	
			_startTimeTracking() {
				const submitionInfo = this.assignmentData?.[1]?.[0];
				if (!submitionInfo) return;
				if ([2, 3, 4].includes(submitionInfo.SubmissionStatus)) return;
	
				this.intervalDurationTime = setInterval(() => {
					this.insertDurationTime(submitionInfo);
				}, 5000);
	
				this.insertAccessTime(submitionInfo);
			},
	
			_stopTimeTracking() {
				if (this.intervalDurationTime) {
					clearInterval(this.intervalDurationTime);
					this.intervalDurationTime = null;
				}
			},
	
			// ══════════════════════════════════════════════════════
			// SUBMIT
			// ══════════════════════════════════════════════════════
	
			handleSubmit() {
				this._stopTimeTracking();
				this.onOpenSubmitDialog();
			},

			// ══════════════════════════════════════════════════════
			// VIDEO TƯƠNG TÁC (INTERACTIVE VIDEO)
			// ══════════════════════════════════════════════════════

			handleSelectInteractiveQuestion({ group, question, groupIndex }) {
				if (!question) return;
				const questions = group?.questions || this.assignment?.groups?.[groupIndex]?.questions || [];
				const qIndex = questions.findIndex(q => q.id === question.id);
				if (qIndex !== -1) {
					this.navigateToQuestion(groupIndex, qIndex, question.id);
				}
			},

			handleInteractiveMarkerReached({ group, question, questions: markerQuestionsPayload, groupIndex }) {
				if (!question && !Array.isArray(markerQuestionsPayload)) return;
				// Một marker có thể mở nhiều câu; mở khóa toàn bộ trước khi điều hướng
				// tới câu chưa trả lời đầu tiên để chế độ Từng câu/Tất cả nhất quán.
				const markerQuestions = Array.isArray(markerQuestionsPayload) && markerQuestionsPayload.length ? markerQuestionsPayload : [question];
				markerQuestions.filter(Boolean).forEach(markerQuestion => {
					if (!this.unlockedQuestionIds.includes(markerQuestion.id)) {
						this.unlockedQuestionIds.push(markerQuestion.id);
					}
				});
				const targetQuestion = markerQuestions.find(markerQuestion => markerQuestion && !this.hasUsableAnswer(this.userAnswers?.[markerQuestion.id]?.answerData)) || question;
				if (!targetQuestion) return;
				const groupQuestions = group?.questions || this.assignment?.groups?.[groupIndex]?.questions || [];
				const qIndex = groupQuestions.findIndex(q => q.id === targetQuestion.id);
				if (qIndex !== -1) {
					this.navigateToQuestion(groupIndex, qIndex, targetQuestion.id);
				}
			},

			handleQuestionUnlocked({ questionId }) {
				if (questionId && !this.unlockedQuestionIds.includes(questionId)) {
					this.unlockedQuestionIds.push(questionId);
				}
			},

			/** Kiểm tra câu hỏi có đang bị khóa do chưa xem video tới mốc đó không */
			hasUsableAnswer(answer) {
				if (answer === null || answer === undefined) return false;
				if (typeof answer === 'string' && answer.trim() === '') return false;
				if (Array.isArray(answer) && answer.length === 0) return false;
				if (typeof answer === 'object' && !Array.isArray(answer) && Object.keys(answer).length === 0) return false;
				return true;
			},

			isQuestionLocked(question, group) {
				if (!question) return false;
				const isInteractive = Boolean(group?.isInteractiveVideo || group?.media?.type === 'INTERACTIVE_VIDEO' || group?.media?.interactiveVideo);
				if (!isInteractive) return false;
				if (question.timeMarker === undefined || question.timeMarker === null || question.timeMarker === '') return false;
				// Nếu học sinh đã có đáp án trước đó thì không khóa
				const ans = this.userAnswers?.[question.id]?.answerData;
				if (this.hasUsableAnswer(ans)) return false;
				return !this.unlockedQuestionIds.includes(question.id);
			},

			formatTimeMarker(seconds) {
				if (seconds === undefined || seconds === null || isNaN(Number(seconds))) return '00:00';
				const total = Math.max(0, Math.floor(Number(seconds)));
				const hours = Math.floor(total / 3600);
				const minutes = Math.floor((total % 3600) / 60);
				const secs = total % 60;
				const result = (minutes < 10 ? '0' : '') + minutes + ':' + (secs < 10 ? '0' : '') + secs;
				return hours ? (hours < 10 ? '0' : '') + hours + ':' + result : result;
			},
		},
	}
</script>