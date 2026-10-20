<template>
	<div>
		<!-- Loading State -->
		<!-- Khi làm lại, ẩn snapshot cũ trong lúc tạo/tải lượt mới để không nháy câu cũ. -->
		<div v-if="!dataReady || isReloadingAttempt" class="page-loading">
			<div class="loader-ring">
				<v-progress-circular indeterminate size="52" width="3" color="primary" />
			</div>
			<p class="loading-label">Đang tải dữ liệu học sinh...</p>
		</div>

		<!-- Main Content -->
		<v-container v-else-if="loadError" fluid class="pa-4">
			<v-alert type="error" variant="tonal" prominent>
				<template #title>Không thể tải bài tập</template>
				{{ loadError }}
			</v-alert>
		</v-container>

		<v-container v-else fluid class="pa-0">
			<v-row :no-gutters="true">
				<v-col cols="12">
					<!-- Assignment Taker Component -->
					<uc-assignment-taker-2 v-if="dataReady === true" :key="keyComp" ref="assignmentTaker" class="pa-0"
						v-model:assignment-data="assignmentData" v-model:puseranswers="puseranswers"
						:user-answers-submitted="userAnswersSubmitted"
						:hocSinhDetail="HocSinhDetail" :mon-hoc-name="monHocName" :on-save-draft="saveDraft"
						:on-save-flags-post-submit="saveFlagsPostSubmit" :on-open-submit-dialog="openSubmitDialog" />
					<v-dialog v-model="confirmSubmitDialog" max-width="420">
						<v-card>
							<v-alert type="warning" variant="tonal" rounded="0" class="mb-0"
								icon="mdi-send-check-outline" title="Xác nhận nộp bài">
								Bạn có chắc chắn muốn nộp bài không? Sau khi nộp, bạn sẽ
								<strong>không thể chỉnh sửa</strong> bài làm của mình.
							</v-alert>

							<v-alert v-if="isFullQuizAutoGrade && !isIntegrated" type="info" variant="tonal" rounded="0"
								class="mb-0" icon="mdi-lightning-bolt-outline">
								Tất cả các câu đều là dạng trắc nghiệm nên hệ thống sẽ
								<strong>tự động chấm và công bố điểm ngay sau khi nộp</strong>.
							</v-alert>

							<v-alert v-if="isIntegrated" type="info" variant="tonal" rounded="0" class="mb-0"
								icon="mdi-information-outline">
								Bạn đang nộp bài làm được hoàn thành từ trang liên kết. Vui lòng đảm bảo bạn đã lưu/nộp
								bài bên trang nguồn trước khi nhấn xác nhận.
							</v-alert>

							<v-alert v-if="renderQuestionNotSubmit().length > 0" type="error" variant="tonal"
								rounded="0" class="mb-0" icon="mdi-alert-circle-outline">
								Còn những câu
								<strong>{{ renderQuestionNotSubmit() }}</strong>
								chưa làm.
							</v-alert>

							<v-card-actions class="pa-3">
								<v-spacer />
								<v-btn variant="text" color="grey" @click="confirmSubmitDialog = false">
									<v-icon start>mdi-close</v-icon>Hủy
								</v-btn>
								<v-btn color="success" variant="flat" @click="submitAssignmentFinal()">
									<v-icon start>mdi-check-all</v-icon>Xác nhận Nộp
								</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
				</v-col>
			</v-row>
		</v-container>
	</div>
</template>

<script>
	export default {
		name: 'AssignmentTakerPage',

    data() {
        const urlParams = new URLSearchParams(window.location.search);

        // Parse boolean ngay từ đầu, tránh so sánh string rải rác trong code
        // Is_SendToClass=0 hoặc Is_SendToClass=false → false; còn lại → true
        // Nếu Is_SendToClass không có trong URL, tự suy từ sự hiện diện của AssignToStudentID
        const _isSTC = urlParams.get('Is_SendToClass');
        const isSendToClass = _isSTC === null
            ? !urlParams.get('AssignToStudentID')
            : _isSTC !== '0' && _isSTC !== 'false';

        return {
            urlParams,
            SUBMISSION_STATUS: { DRAFT: 1, SUBMITTED: 2, IN_REVIEW: 3, GRADED: 4 },
            QUIZ_TYPES: {
                SINGLE_CHOICE: 'QUIZ_SINGLE_CHOICE',
                MULTIPLE_CHOICE: 'QUIZ_MULTIPLE_CHOICE',
                TRUE_FALSE: 'QUIZ_TRUE_FALSE',
                MULTIPLE_TRUE_FALSE: 'QUIZ_MULTIPLE_TRUE_FALSE',
                FILL_IN_BLANK: 'QUIZ_FILL_IN_BLANK',
                MATCHING: 'QUIZ_MATCHING'
            },
            HocSinhID: parseInt(urlParams.get('HocSinhID') || '0'),

            // Boolean thay vì string — dùng trực tiếp trong toàn bộ code
            isSendToClass,

            dataReady: false,
            loadError: '',
            assignmentData: [],
            monHocName: '',
            confirmSubmitDialog: false,
            puseranswers: {},
            NienKhoa: null,
            assignmentInfo: {},
            userAnswersSubmitted: {},
            submitionInfo: {},
            isRendered: false,
            keyComp: 0,
            Is_Resubmit: 0,
            LanNop: 1,
            HocSinhDetail: null,
            DSNienKhoa: [],
            AssignmentConfigAfterShuffle: null,
            // Chỉ dùng cho bài có nhóm RANDOM: giữ snapshot ở local trong lúc auto-save
            // để response trả về ngân hàng gốc không làm đổi bộ câu của lượt hiện tại.
            attemptConfigPersisted: false,

            // Guard flag — chặn loadAssignmentData chạy đồng thời
            isLoadingAssignment: false,

            // Không cho auto-grade recovery ghi trạng thái GRADED xen giữa phase 1 và phase 2.
            isSubmittingAssignment: false,

            // Giữ màn hình loading trong toàn bộ khoảng tạo submission mới và tải
            // snapshot mới; nếu không, snapshot của lượt trước sẽ hiện thoáng qua.
            isReloadingAttempt: false,

            // Guard cho beforeunload
            beforeunloadHandler: null,

            // Chi tiết lỗi gần nhất để alert/toast không chỉ hiện thông báo chung chung
            lastAssignmentError: null,
        };
    },

    computed: {
        // true khi bài đang trong trạng thái chưa nộp (0=chưa làm, 1=DRAFT)
        isActiveDirty() {
            if (!this.dataReady) return false;
            return (this.submitionInfo?.SubmissionStatus ?? 0) < 2;
        },

        isFullQuizAutoGrade() {
            return this.toBoolean(this.assignmentData?.[0]?.[0]?.Is_Full_Quiz);
        },

        isIntegrated() {
            const config = this.assignmentData?.[0]?.[0];
            if (!config) return false;
            // Nếu nguồn là LMS thì không phải là Integrated External
            if (config.IntegrationSource === 'LMS') return false;

            if (config.IntegrationSource) return true;
            try {
                const parsed = JSON.parse(config.AssignmentConfig);
                return parsed.type === 'INTEGRATED';
            } catch (e) {
                return false;
            }
        },
    },

    watch: {
        // Thông báo cho parent (iframe wrapper) mỗi khi trạng thái dirty thay đổi
        isActiveDirty(val) {
            window.parent.postMessage({ type: 'lms:assignment:dirty', isDirty: val }, '*');
        },
    },

    mounted() {
        this.callNienKhoa_Get();
        // Chặn đóng tab browser khi bài đang làm chưa nộp
        this.beforeunloadHandler = (e) => {
            if (this.isActiveDirty) {
                e.preventDefault();
                e.returnValue = '';
            }
        };
        window.addEventListener('beforeunload', this.beforeunloadHandler);
    },

    beforeUnmount() {
        if (this.beforeunloadHandler) {
            window.removeEventListener('beforeunload', this.beforeunloadHandler);
        }
        // Khi trang làm bài bị huỷ mount (đóng iframe), reset dirty để parent biết
        window.parent.postMessage({ type: 'lms:assignment:dirty', isDirty: false }, '*');
    },

    methods: {

        // ===========================
        // SUBMIT DIALOG
        // ===========================

        openSubmitDialog() {
            this.confirmSubmitDialog = true;
        },

        // ===========================
        // INITIALIZATION
        // ===========================

        async callNienKhoa_Get() {
            try {
                const data = await fetchPromise('/lms/NienKhoa_Get', {});
                this.DSNienKhoa = data || [];
                const activeNK = this.DSNienKhoa.find(item => item.IsActive);
                this.NienKhoa = activeNK?.NienKhoa ?? null;
                await this.callHocSinh_Detail_GetBy_HocSinhID();
            } catch (err) {
                console.error('Lỗi NienKhoa_Get:', err);
            }
        },

        async callHocSinh_Detail_GetBy_HocSinhID() {
            try {
                const data = await fetchPromise('/lms/HocSinh_Detail_GetBy_HocSinhID', {
                    HocSinhID: this.HocSinhID,
                    NienKhoa: this.NienKhoa,
                });
                this.HocSinhDetail = data || null;
                this.dataReady = true;
                this.initPage();
            } catch (err) {
                console.error('Lỗi HocSinh_Detail_GetBy_HocSinhID:', err);
                this.dataReady = true;
            }
        },

        initPage() {
            this.initializeParams();
            const { AssignToClassID, AssignToStudentID } = this.getAssignmentIDs();
            if (!this.validateAssignmentIDs(AssignToClassID, AssignToStudentID)) return;
            this.loadAssignmentData(AssignToClassID, AssignToStudentID);
        },

        initializeParams() {
            this.LanNop = this.urlParams.get('LanNop')
                ? parseInt(this.urlParams.get('LanNop'))
                : 1;
            this.Is_Resubmit = this.urlParams.get('Is_Resubmit') === '1' ? 1 : 0;
        },

        getAssignmentIDs() {
            return {
                AssignToClassID: this.urlParams.get('AssignToClassID'),
                AssignToStudentID: this.urlParams.get('AssignToStudentID'),
            };
        },

        validateAssignmentIDs(classID, studentID) {
            if (!classID && !studentID) {
                Vue.$toast.error('Không tìm thấy ID bài tập trên URL.', { position: 'top' });
                this.dataReady = true;
                return false;
            }
            return true;
        },

        // ===========================
        // DATA LOADING
        // ===========================

        async loadAssignmentData(AssignToClassID, AssignToStudentID) {
            // Guard: chặn gọi đồng thời, tránh race condition
            if (this.isLoadingAssignment) return;
            this.isLoadingAssignment = true;
            this.loadError = '';

            let endpoint = '';
            let params = {};

            try {
                const isSendToStudent = !this.isSendToClass;

                if (!isSendToStudent && !AssignToClassID) {
                    Vue.$toast.error('Không tìm thấy AssignToClassID bài tập trên URL.', { position: 'top' });
                    return;
                }
                if (isSendToStudent && !AssignToStudentID) {
                    Vue.$toast.error('Không tìm thấy AssignToStudentID bài tập trên URL.', { position: 'top' });
                    return;
                }

                endpoint = isSendToStudent
                    ? 'lms/EL_Student_GetAssignmentDetail_AssignToStudent'
                    : 'lms/EL_Student_GetAssignmentDetail';

                // Khi mở lượt làm lại, API InsertSubmission tạo submission mới trong
                // lúc request detail hiện tại vẫn đang chạy. Phải tải lại detail ngay
                // trong cùng chuỗi async sau khi có LanNop mới; gọi initPage() lồng vào
                // đây sẽ bị guard isLoadingAssignment chặn và giữ lại bộ câu cũ.
                let shouldReloadForNewAttempt = true;
                while (shouldReloadForNewAttempt) {
                    shouldReloadForNewAttempt = false;
                    params = isSendToStudent
                        ? {
                            AssignToStudentID: parseInt(AssignToStudentID),
                            HocSinhID: this.HocSinhDetail.HocSinhID,
                            LanNop: this.LanNop ?? 1,
                        }
                        : {
                            AssignToClassID: parseInt(AssignToClassID),
                            HocSinhID: this.HocSinhDetail.HocSinhID,
                            LanNop: this.LanNop ?? 1,
                        };

                    console.debug('[Assignment] loadAssignmentData request', {
                        endpoint,
                        params,
                        isSendToStudent,
                    });
                    const data = await fetchPromise(endpoint, params, { cache: false, suppressError: true });
                    console.debug('[Assignment] loadAssignmentData response', {
                        endpoint,
                        responseType: Array.isArray(data) ? 'array' : typeof data,
                        responseKeys: data && typeof data === 'object' ? Object.keys(data) : [],
                        arrayLengths: Array.isArray(data) ? data.map(item => Array.isArray(item) ? item.length : null) : undefined,
                    });
                    const result = await this.processAssignmentResponse({ data });
                    if (result?.reloadForNewAttempt) {
                        // processAssignmentResponse đã cập nhật LanNop và Is_Resubmit.
                        // Vòng lặp này dùng đúng LanNop mới để lấy config rồi bốc lại câu.
                        shouldReloadForNewAttempt = true;
                    } else if (!this.loadError) {
                        this.keyComp++;
                    }
                }
            } catch (err) {
                this.isReloadingAttempt = false;
                console.error('Lỗi loadAssignmentData:', err);
                const errorDetails = this.describeAssignmentApiError(err, {
                    endpoint,
                    params,
                    reason: 'fetchPromise hoặc processAssignmentResponse ném lỗi.',
                });
                console.error('[Assignment] loadAssignmentData failed', errorDetails);
                this.lastAssignmentError = errorDetails;
                this.handleInvalidResponse(err, errorDetails);
            } finally {
                // Luôn release guard dù thành công hay lỗi
                this.isLoadingAssignment = false;
            }
        },

        async processAssignmentResponse(response) {
            const isResubmitResponse = this.Is_Resubmit === 1;
            if (isResubmitResponse) {
                // Response đầu tiên khi bấm "Làm lại" vẫn chứa dữ liệu lượt cũ.
                // Ẩn UI ngay từ đây, chỉ mở lại sau khi vòng tải LanNop mới hoàn tất.
                this.isReloadingAttempt = true;
                // Lượt mới phải bắt đầu với state đáp án riêng; không để autosave cũ
                // hoặc payload nộp tiếp theo mang question-id của lượt trước sang.
                this.puseranswers = {};
                this.userAnswersSubmitted = {};
            }
            if (!this.isValidResponse(response)) {
                this.isReloadingAttempt = false;
                this.handleInvalidResponse(response?.data);
                return;
            }
            // Mỗi response detail là một lần bắt đầu/đọc lại attempt; không để snapshot
            // của lần làm trước rò sang lần làm hiện tại.
            this.AssignmentConfigAfterShuffle = null;
            this.attemptConfigPersisted = false;
            this.setAssignmentData(response);

            // Khi làm lại, không được xử lý cấu hình của lần 1 trước.
            // Submission mới phải được tạo trước, sau đó lần tải lại mới bốc bộ câu mới.
            if (this.Is_Resubmit === 1) {
                const inserted = await this.insertSubmissionForResubmit();
                if (inserted) {
                    this.initializeParams();
                    return { reloadForNewAttempt: true };
                }
                this.isReloadingAttempt = false;
                return { reloadForNewAttempt: false };
            }

            const config = this.assignmentData[0][0];
            // Is_Shuffle chỉ phản ánh submission đã có AssignmentConfig snapshot ở backend;
            // loại bài RANDOM được nhận diện từ AssignmentConfig.questionSelection bên dưới.
            this.attemptConfigPersisted = this.toBoolean(config.Is_Shuffle);
            // Store đã bảo vệ JSON, nhưng client vẫn phải chặn payload lỗi để không làm văng
            // toàn bộ màn hình khi dữ liệu cũ hoặc proxy trả về chuỗi không hợp lệ.
            const parsedAssignmentConfig = this.parseAssignmentJson(config.AssignmentConfig, 'AssignmentConfig');
            if (!parsedAssignmentConfig) {
                this.isReloadingAttempt = false;
                this.handleInvalidResponse({ Message: 'Dữ liệu cấu hình bài tập không hợp lệ.' });
                return { reloadForNewAttempt: false };
            }
            config.groups = Array.isArray(parsedAssignmentConfig.groups)
                ? parsedAssignmentConfig.groups
                : [];
            await this.processAssignmentConfig(config);
            this.loadSubmittedAnswers(response);
            this.isReloadingAttempt = false;
            return { reloadForNewAttempt: false };
        },

        isValidResponse(response) {
            return response?.data?.length > 0 && response.data[0]?.length > 0;
        },

        parseAssignmentJson(value, fieldName = 'AssignmentConfig') {
            if (value && typeof value === 'object') return value;
            try {
                const parsed = JSON.parse(value);
                return parsed && typeof parsed === 'object' ? parsed : null;
            } catch (error) {
                console.error(`[Assignment] Không parse được ${fieldName}:`, error);
                return null;
            }
        },

        handleInvalidResponse(errorResponse = null, errorDetails = null) {
            console.error('API getAssignmentDetail không trả về dữ liệu hợp lệ.', errorResponse);
            const baseMessage = errorResponse?.Message
                || errorResponse?.message
                || errorResponse?.response?.data?.Message
                || 'Không thể tải được dữ liệu bài tập.';
            const message = errorDetails
                ? this.formatAssignmentErrorForAlert('Không thể tải dữ liệu bài tập', errorDetails, baseMessage)
                : baseMessage;
            this.loadError = message;
            Vue.$toast.error(message, { position: 'top' });
        },

        setAssignmentData(response) {
            this.assignmentData = response.data;
            if (this.Is_Resubmit === 1) {
                this.assignmentData[1] = [];
            }
            this.monHocName = response.data[0]?.[0]?.MonHocName || '';
            this.assignmentInfo = response.data[0] ?? {};
            this.submitionInfo = response.data[1][0] ?? {};
            this.ensureAutoGradeScoresInSubmissionContent();
        },

        ensureAutoGradeScoresInSubmissionContent() {
            // Submit có luồng save GRADED riêng; recovery chỉ chạy khi tải lại một submission cũ.
            if (this.isSubmittingAssignment) return;
            if (!this.isFullQuizAutoGrade) return;
            if (![this.SUBMISSION_STATUS.SUBMITTED, this.SUBMISSION_STATUS.GRADED].includes(this.submitionInfo?.SubmissionStatus)) return;

            const raw = this.submitionInfo?.SubmissionContent;
            if (!raw) return;

            let parsed = null;
            try {
                parsed = JSON.parse(raw);
            } catch (e) {
                console.error('Không parse được SubmissionContent để backfill điểm tự động:', e);
                return;
            }

            const answers = parsed?.answers || {};
            const hasMissingScore = Object.values(answers).some(answerItem => {
                const grading = answerItem?.grading || {};
                const hasManual = typeof grading.manualScore === 'number';
                const hasAuto = typeof grading.autoScore === 'number';
                return !hasManual && !hasAuto;
            });
            // Phase 1 lưu trạng thái SUBMITTED và chưa có tổng Score.
            // Khi đó phải chấm lại từ SubmissionContent hiện tại để công bố điểm.
            const hasMissingTotalScore = this.submitionInfo?.Score === null
                || this.submitionInfo?.Score === undefined
                || this.submitionInfo?.Score === '';

            if (!hasMissingScore && !hasMissingTotalScore && this.submitionInfo?.SubmissionStatus === this.SUBMISSION_STATUS.GRADED) return;

            const groups = this.getGroupsForAutoGrading();
            if (!groups.length) return;

            const graded = this.fn_AutoGradeSubmission({ answers: _.cloneDeep(answers) }, groups);
            this.submitionInfo = {
                ...this.submitionInfo,
                SubmissionStatus: this.SUBMISSION_STATUS.GRADED,
                SubmissionContent: graded.SubmissionContent,
                // Nếu SubmissionContent cũ thiếu điểm, Score cũ (thường là 0)
                // không còn đáng tin; dùng lại tổng điểm vừa tự chấm.
                Score: graded.Score,
            };

            if (this.assignmentData?.[1]?.[0]) {
                this.assignmentData[1][0] = {
                    ...this.assignmentData[1][0],
                    SubmissionStatus: this.SUBMISSION_STATUS.GRADED,
                    SubmissionContent: graded.SubmissionContent,
                    Score: graded.Score,
                };
            }

            // Tự động đồng bộ điểm thật và chi tiết chấm về DB nếu trước đó bị gián đoạn Phase 2 dẫn đến điểm = 0
            this.syncAutoGradeBackfillToDb(graded.SubmissionContent, graded.Score);
        },

        // ===========================
        // QUESTION SHUFFLING
        // ===========================

        async processAssignmentConfig(config) {
            const isRandomQuestionPool = this.hasGroupedRandomQuestionSelection(config);
            // Bài thường giữ nguyên điều kiện cũ. Với nhóm RANDOM, Is_Shuffle chỉ là
            // dấu hiệu backend đã có snapshot; không dùng nó để nhận diện loại bài.
            const shouldShuffle = isRandomQuestionPool
                ? Number(config.Is_Shuffle) === 0 || !this.hasSubmission()
                : config.Is_Shuffle === 0 || !this.hasSubmission();
            if (shouldShuffle) {
                this.prepareQuestionsForAttempt(config);
            }
            if (this.isGradedSubmission()) {
                await this.mapAnswersForGradedAssignment(config);
            }
        },

        hasSubmission() {
            return !this.isSendToClass
                ? this.submitionInfo?.SubmissionID
                : this.submitionInfo?.SubmissionContent;
        },

        prepareQuestionsForAttempt(config) {
            const sourceConfig = typeof config.AssignmentConfig === 'string'
                ? JSON.parse(config.AssignmentConfig)
                : _.cloneDeep(config.AssignmentConfig || {});
            const groups = _.cloneDeep(sourceConfig.groups || []);
            let assignmentHistory = [];
            try {
                assignmentHistory = config.AssignmentConfigHistory
                    ? (typeof config.AssignmentConfigHistory === 'string'
                        ? JSON.parse(config.AssignmentConfigHistory)
                        : config.AssignmentConfigHistory)
                    : [];
            } catch (error) {
                console.warn('Không parse được lịch sử snapshot, tiếp tục bốc ngẫu nhiên:', error);
            }

            // Thuật toán Seeded PRNG (Mulberry32) kết hợp Hash theo HocSinhID + AssignmentID
            // Giúp mỗi học sinh có 1 chuỗi xáo trộn giả ngẫu nhiên độc lập, phân tán tối đa, chống đoán quy luật / bắt bài.
            const createSeededRandom = (seedStr) => {
                let h = 1779033703 ^ seedStr.length;
                for (let i = 0; i < seedStr.length; i++) {
                    h = Math.imul(h ^ seedStr.charCodeAt(i), 3432918353);
                    h = h << 13 | h >>> 19;
                }
                return function() {
                    h = Math.imul(h ^ (h >>> 16), 2246822507);
                    h = Math.imul(h ^ (h >>> 13), 3266489909);
                    return ((h ^= h >>> 16) >>> 0) / 4294967296;
                };
            };
            const seededShuffle = (array, seedStr) => {
                const rng = createSeededRandom(seedStr);
                const arr = [...array];
                for (let i = arr.length - 1; i > 0; i--) {
                    const j = Math.floor(rng() * (i + 1));
                    const temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
                return arr;
            };

            const attemptNumber = Number(this.LanNop || 1);
            const limitAssigned = Number(config.LimitAssigned ?? this.assignmentData?.[0]?.[0]?.LimitAssigned ?? 1);
            const studentId = this.HocSinhDetail?.HocSinhID || this.HocSinhID || 'default';
            const assignmentId = config.AssignmentID || this.assignmentData?.[0]?.[0]?.AssignmentID || '';

            // Trường hợp 1: limitAssigned = 1 (Thi kiểm tra 1 lần) -> Seed dựa theo từng HocSinhID để phân tán tối đa, tránh trùng giữa các học sinh trong lớp
            // Trường hợp 2: limitAssigned > 1 (Luyện tập nhiều lần) -> Seed và exposure dựa theo từng lần làm (attemptNumber) của đúng học sinh đó để tránh lặp lại câu đã làm các lần trước
            const studentSeedPrefix = limitAssigned <= 1
                ? `${studentId}_${assignmentId}`
                : `${studentId}_${assignmentId}_attempt_${attemptNumber}`;

            const parseHistoryJson = value => {
                if (!value) return null;
                try {
                    return typeof value === 'string' ? JSON.parse(value) : value;
                } catch (_) {
                    return null;
                }
            };
            const getQuestionId = question => String(
                question?.sourceTracking?.questionId
                ?? question?.sourceTracking?.sourceQuestionId
                ?? question?.id
            );

            // Lịch sử cũ chỉ có AssignmentConfig; lịch sử mới có thêm SubmissionContent
            // để biết câu nào học sinh đã làm sai. Không có dữ liệu chấm thì không tự đoán
            // là sai, tránh ưu tiên lại các câu chỉ mới được lưu nháp.
            const isWrongHistoricalAnswer = (question, answerItem) => {
                const grading = answerItem?.grading || {};
                if (typeof grading.isCorrect === 'boolean') return !grading.isCorrect;

                const scoreValue = grading.manualScore ?? grading.autoScore;
                const score = Number(scoreValue);
                if (!Number.isFinite(score)) return false;

                const points = Number(question?.points);
                return Number.isFinite(points) && points > 0
                    ? score < points
                    : score <= 0;
            };

            const getWrongQuestionRepeatRate = selection => {
                const rawRate = selection?.wrongQuestionRepeatRate
                    ?? selection?.wrongAnswerRepeatRate
                    ?? 0.2;
                const rate = Number(rawRate);
                return Number.isFinite(rate) ? Math.min(Math.max(rate, 0), 1) : 0.2;
            };

            const buildSelectionState = group => {
                const exposure = new Map();
                const wrongQuestionIds = new Set();
                if (limitAssigned <= 1) return { exposure, wrongQuestionIds };

                assignmentHistory.forEach(entry => {
                    const snapshot = parseHistoryJson(entry?.AssignmentConfig ?? entry);
                    if (!snapshot) return;

                    const historyGroup = snapshot?.groups?.find(item => item.id === group.id);
                    const historyQuestions = historyGroup?.questions || [];
                    const submissionContent = parseHistoryJson(entry?.SubmissionContent);
                    const answers = submissionContent?.answers || {};

                    historyQuestions.forEach(question => {
                        const id = getQuestionId(question);
                        exposure.set(id, (exposure.get(id) || 0) + 1);

                        const answerItem = answers?.[question?.id] || answers?.[id];
                        if (isWrongHistoricalAnswer(question, answerItem)) {
                            wrongQuestionIds.add(id);
                        }
                    });
                });

                return { exposure, wrongQuestionIds };
            };

            const selectFromRandomPool = (pool, requestedCount, seedSuffix, selection, state) => {
                const count = Math.min(
                    Math.max(Math.floor(Number(requestedCount) || 0), 0),
                    pool.length
                );
                if (!count) return [];
                if (count >= pool.length) return [...pool];

                const seed = `${studentSeedPrefix}_${seedSuffix}`;
                const seededPool = seededShuffle(pool, seed);
                const { exposure, wrongQuestionIds } = state;
                const selectedIds = new Set();
                const wrongCandidates = seededPool
                    .filter(question => {
                        const id = getQuestionId(question);
                        return wrongQuestionIds.has(id) && (exposure.get(id) || 0) > 0;
                    })
                    .sort((left, right) => (
                        (exposure.get(getQuestionId(left)) || 0)
                        - (exposure.get(getQuestionId(right)) || 0)
                    ));

                // Mặc định dành khoảng 20% số câu cho câu đã làm sai. Phần lẻ được
                // quyết định bằng seed để tỷ lệ vẫn ngẫu nhiên nhưng ổn định khi reload.
                const repeatRate = getWrongQuestionRepeatRate(selection);
                const expectedWrongCount = count * repeatRate;
                const baseWrongCount = Math.floor(expectedWrongCount);
                const fractionalPart = expectedWrongCount - baseWrongCount;
                const quotaRandom = createSeededRandom(`${seed}_wrong_quota`)();
                const wrongCount = Math.min(
                    wrongCandidates.length,
                    baseWrongCount + (quotaRandom < fractionalPart ? 1 : 0)
                );
                const selectedWrong = wrongCandidates.slice(0, wrongCount);
                selectedWrong.forEach(question => selectedIds.add(getQuestionId(question)));

                // Sau khi dành quota cho câu sai, phần còn lại vẫn ưu tiên câu chưa
                // từng xuất hiện (exposure = 0), rồi mới đến câu đã xuất hiện ít nhất.
                const remaining = seededPool
                    .filter(question => !selectedIds.has(getQuestionId(question)))
                    .sort((left, right) => (
                        (exposure.get(getQuestionId(left)) || 0)
                        - (exposure.get(getQuestionId(right)) || 0)
                    ));

                return selectedWrong.concat(remaining.slice(0, count - selectedWrong.length));
            };

            groups.forEach(group => {
                // Random selection happens once per attempt. The resulting config is
                // persisted in tblEL_Submissions, so reload/resume never reselects questions.
                const selection = group.questionSelection || {};
                if (selection.mode === 'RANDOM') {
                    const matrixConfigs = selection.matrixMode && Array.isArray(group.questionSource?.matrixConfigs)
                        ? group.questionSource.matrixConfigs
                        : [];
                    if (matrixConfigs.length) {
                        // Ma trận bốc độc lập theo từng nguồn nhóm, nhờ đó 2-3 nhóm có thể đóng góp
                        // số câu khác nhau cho cùng một mức độ mà không bị gộp thành một quota chung.
                        const allQuestions = Array.isArray(group.questions) ? group.questions : [];
                        const selectionState = buildSelectionState(group);

                        const pickFromPool = (pool, requestedCount, levelKey = '') => {
                            return selectFromRandomPool(
                                pool,
                                requestedCount,
                                `${group.id || ''}_${levelKey}`,
                                selection,
                                selectionState
                            );
                        };
                        const selectedIds = new Set();
                        matrixConfigs.forEach(mCfg => {
                            const sourceConfigs = Array.isArray(mCfg.sources) && mCfg.sources.length ? mCfg.sources : [mCfg];
                            sourceConfigs.forEach((source, sIdx) => {
                                const sourceIds = new Set((source.questionIds || []).map(String));
                                const sourcePool = allQuestions.filter(question => sourceIds.has(getQuestionId(question)));
                                pickFromPool(sourcePool, source.randomCount, `${mCfg.cognitiveLevel || ''}_${sIdx}`).forEach(question => selectedIds.add(getQuestionId(question)));
                            });
                        });
                        group.questions = allQuestions.filter(question => selectedIds.has(getQuestionId(question)));
                    } else {
                    // Group RANDOM tiêu chuẩn bốc trên toàn bộ câu trong group.
                    // questionSource.questionIds chỉ mô tả nguồn import; chỉ flow ma trận ở trên
                    // mới dùng questionIds để tách pool theo từng cấu hình nguồn/mức độ.
                    const allQuestions = Array.isArray(group.questions) ? group.questions : [];
                    const pool = allQuestions;
                    const requestedCount = Number(selection.questionsPerAttempt);
                    const count = Math.min(
                        Math.max(Number.isFinite(requestedCount) ? Math.floor(requestedCount) : pool.length, 1),
                        pool.length
                    );
                    const selectionState = buildSelectionState(group);
                    group.questions = selectFromRandomPool(
                        pool,
                        count,
                        `${group.id || ''}_standard_pool`,
                        selection,
                        selectionState
                    );
                    }
                }

                if (group.advancedFeatures?.isShuffleQuestions) {
                    group.questions = seededShuffle(group.questions, `${studentSeedPrefix}_${group.id || ''}_shuffle_q`);
                }
                if (group.advancedFeatures?.isShuffleAnswers) {
                    this.shuffleQuizAnswers(group.questions, `${studentSeedPrefix}_${group.id || ''}`);
                }
            });
            this.AssignmentConfigAfterShuffle = { ...sourceConfig, groups };
            config.groups = groups;
            config._cachedGroups = groups;
            config.AssignmentConfig = JSON.stringify(this.AssignmentConfigAfterShuffle);
        },

        hasGroupedRandomQuestionSelection(config = null) {
            let groups = config?.groups;
            if (!Array.isArray(groups)) {
                let parsedConfig = config?.AssignmentConfig;
                try {
                    if (typeof parsedConfig === 'string') parsedConfig = JSON.parse(parsedConfig);
                } catch (error) {
                    return false;
                }
                groups = parsedConfig?.groups;
            }

            // Đây là marker do Soạn bài tập lưu cho flow bốc câu theo nhóm
            // (Content Hub hoặc nguồn pool tương đương); bài soạn câu hỏi thường
            // không có questionSelection nên không đi vào nhánh snapshot này.
            return Array.isArray(groups)
                && groups.some(group => group?.questionSelection?.mode === 'RANDOM');
        },

        getCurrentAttemptConfigSnapshot() {
            if (this.AssignmentConfigAfterShuffle) {
                return _.cloneDeep(this.AssignmentConfigAfterShuffle);
            }

            const currentConfig = this.assignmentData?.[0]?.[0];
            if (!currentConfig?.AssignmentConfig) return null;

            try {
                return JSON.parse(currentConfig.AssignmentConfig);
            } catch (error) {
                console.warn('Không parse được AssignmentConfig hiện tại:', error);
                return null;
            }
        },

        preserveCurrentAttemptConfig(responseData) {
            const responseConfig = responseData?.[0]?.[0];
            const snapshot = this.getCurrentAttemptConfigSnapshot();
            if (!responseConfig || !snapshot || !Array.isArray(snapshot.groups)) return false;

            // SaveSubmission có thể trả lại AssignmentConfig của bài gốc (toàn bộ ngân hàng).
            // Giữ snapshot hiện tại trong response để reactive state không nhảy sang pool gốc
            // và không làm lệch question-id với puseranswers của học sinh.
            responseConfig.AssignmentConfig = JSON.stringify(snapshot);
            responseConfig.groups = _.cloneDeep(snapshot.groups);
            this.AssignmentConfigAfterShuffle = snapshot;
            return true;
        },

        shuffleQuizAnswers(questions, seedPrefix = '') {
            const createSeededRandom = (seedStr) => {
                let h = 1779033703 ^ seedStr.length;
                for (let i = 0; i < seedStr.length; i++) {
                    h = Math.imul(h ^ seedStr.charCodeAt(i), 3432918353);
                    h = h << 13 | h >>> 19;
                }
                return function() {
                    h = Math.imul(h ^ (h >>> 16), 2246822507);
                    h = Math.imul(h ^ (h >>> 13), 3266489909);
                    return ((h ^= h >>> 16) >>> 0) / 4294967296;
                };
            };
            const seededShuffle = (array, seedStr) => {
                if (!seedStr) return _.shuffle(array);
                const rng = createSeededRandom(seedStr);
                const arr = [...array];
                for (let i = arr.length - 1; i > 0; i--) {
                    const j = Math.floor(rng() * (i + 1));
                    const temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
                return arr;
            };

            questions
                .filter(q => q.type.includes('QUIZ_'))
                .forEach((question, qIdx) => {
                    const { type, config } = question;
                    const qSeed = seedPrefix ? `${seedPrefix}_q_${question.id || qIdx}` : '';
                    switch (type) {
                        case this.QUIZ_TYPES.SINGLE_CHOICE:
                        case this.QUIZ_TYPES.MULTIPLE_CHOICE:
                        case this.QUIZ_TYPES.MULTIPLE_TRUE_FALSE:
                            config.options = seededShuffle(config.options, qSeed ? `${qSeed}_opts` : '');
                            break;
                        case this.QUIZ_TYPES.MATCHING:
                            config.columnA = seededShuffle(config.columnA, qSeed ? `${qSeed}_colA` : '');
                            config.columnB = seededShuffle(config.columnB, qSeed ? `${qSeed}_colB` : '');
                            break;
                    }
                });
        },

        // ===========================
        // ANSWER MAPPING
        // ===========================

        isGradedSubmission() {
            return (
                this.submitionInfo?.SubmissionID &&
                this.submitionInfo?.SubmissionStatus === this.SUBMISSION_STATUS.GRADED
            );
        },

        async mapAnswersForGradedAssignment(config) {
            // Không để payload chấm bài lỗi làm crash component; caller sẽ hiển thị lỗi có kiểm soát.
            const configWithAnswers = this.parseAssignmentJson(
                config.AssignmentConfig_HadAnswer,
                'AssignmentConfig_HadAnswer'
            );
            const configNoAnswers = this.parseAssignmentJson(config.AssignmentConfig, 'AssignmentConfig');
            if (!configWithAnswers || !configNoAnswers) {
                throw new Error('Dữ liệu cấu hình đáp án bài tập không hợp lệ.');
            }
            const mappedGroups = await this.handleMapingAnswer_For_Graded(configWithAnswers, configNoAnswers);
            config.groups = mappedGroups;
        },

		handleMapingAnswer_For_Graded(asmConfig, asmConfigNoAnswer) {
			const flatQuestionsWithAnswers = asmConfig.groups.flatMap(g => g.questions);
			const groupsNoAnswer = _.cloneDeep(asmConfigNoAnswer.groups);
			const flatQuestionsNoAnswer = groupsNoAnswer.flatMap(g => g.questions);

			const answeredQuestions = flatQuestionsWithAnswers.map(questionWithAnswer => {
				// JSON từ SQL có thể trả id số/string khác kiểu; ID là khóa nghiệp vụ
				// nên phải normalize trước khi ghép answer key với snapshot.
				const questionNoAnswer = flatQuestionsNoAnswer.find(q => String(q.id) === String(questionWithAnswer.id));
                if (!questionNoAnswer) return null;
                this.copyCorrectAnswers(questionWithAnswer, questionNoAnswer);
                return questionNoAnswer;
            }).filter(Boolean);

            groupsNoAnswer.forEach(group => {
                group.questions = group.questions.map(question => {
					const answered = answeredQuestions.find(q => String(q.id) === String(question.id));
                    return answered || question;
                });
            });
            return groupsNoAnswer;
        },

        copyCorrectAnswers(source, target) {
            const { type, config: sourceConfig } = source;
            const targetConfig = target.config;
            switch (type) {
                case this.QUIZ_TYPES.SINGLE_CHOICE:
                case this.QUIZ_TYPES.TRUE_FALSE:
                    targetConfig.correctAnswer = _.cloneDeep(sourceConfig.correctAnswer);
                    break;
                case this.QUIZ_TYPES.MULTIPLE_CHOICE:
                    targetConfig.correctAnswers = _.cloneDeep(sourceConfig.correctAnswers);
                    break;
                case this.QUIZ_TYPES.MULTIPLE_TRUE_FALSE:
                    targetConfig.options = _.cloneDeep(sourceConfig.options);
                    break;
                case this.QUIZ_TYPES.FILL_IN_BLANK:
                    targetConfig.parts = _.cloneDeep(sourceConfig.parts);
                    break;
                case this.QUIZ_TYPES.MATCHING:
                    targetConfig.columnA = _.cloneDeep(sourceConfig.columnA);
                    targetConfig.columnB = _.cloneDeep(sourceConfig.columnB);
                    targetConfig.correctPairs = _.cloneDeep(sourceConfig.correctPairs);
                    break;
            }
        },

        loadSubmittedAnswers(response) {
            if (response.data[1][0]?.SubmissionStatus === this.SUBMISSION_STATUS.GRADED) {
                const submissionContent = JSON.parse(response.data[1][0]?.SubmissionContent || '{}');
                this.userAnswersSubmitted = submissionContent.answers || {};
            }
        },

        // ===========================
        // SUBMISSION HANDLING
        // ===========================

        async saveDraft(payload) {
            if (this.Is_Resubmit === 1 || this.isReloadingAttempt) return null;

            const isSendToStudent = !this.isSendToClass;
            const endpoint = isSendToStudent
                ? 'lms/EL_Student_SaveSubmission_AssignToStudent'
                : 'lms/EL_Student_SaveSubmission';
            const requestLanNop = this.LanNop;
            const safePayload = this.filterSubmissionContentToCurrentAttempt(payload);

            const params = isSendToStudent
                ? {
                    ...safePayload,
                    Is_Full_Quiz: this.isFullQuizAutoGrade,
                    Is_Resubmit: this.Is_Resubmit ?? 0,
                    Score: payload?.Score ?? null,
                    SubmitToken: null,
                    // Khóa request vào đúng lượt đang mở; nếu học sinh mở lại lượt cũ
                    // trong khi đã có lượt mới hơn, SP không được ghi nhầm sang lượt mới nhất.
                    LanNop: this.LanNop ?? 1,
                    AssignToStudentID: parseInt(this.urlParams.get('AssignToStudentID')),
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                }
                : {
                    ...safePayload,
                    Is_Full_Quiz: this.isFullQuizAutoGrade,
                    Is_Resubmit: this.Is_Resubmit ?? 0,
                    Score: payload?.Score ?? null,
                    SubmitToken: null,
                    // Gửi cùng khóa lượt cho nhánh giao theo lớp để class/student dùng
                    // chung contract lưu bài mà không làm thay đổi payload cũ khác.
                    LanNop: this.LanNop ?? 1,
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                };

            const data = await fetchPromise(endpoint, params, { cache: false });
            // Bỏ qua response autosave cũ nếu trong lúc request đang chạy trang đã
            // chuyển sang snapshot/lượt khác; response đó không được ghi đè state mới.
            if (this.isReloadingAttempt || this.Is_Resubmit === 1 || requestLanNop !== this.LanNop) return null;
            await this.handleSaveResponse({ data });
            return data;
        },

        getQuestionIdsFromGroups(groups) {
            const ids = new Set();
            (groups || []).forEach(group => {
                (group?.questions || []).forEach(question => {
                    if (question?.id !== null && question?.id !== undefined && question?.id !== '') {
                        ids.add(String(question.id));
                    }
                });
            });
            return ids;
        },

        filterAnswersToQuestionGroups(answers, groups) {
            const source = answers && typeof answers === 'object' && !Array.isArray(answers) ? answers : {};
            const ids = this.getQuestionIdsFromGroups(groups);
            // Chưa có snapshot thì giữ payload để không làm mất dữ liệu ở các trạng thái
            // tải dở; khi đã có danh sách câu, chỉ giữ đáp án thuộc đúng lượt hiện tại.
            if (!ids.size) return source;
            return Object.fromEntries(Object.entries(source).filter(([questionId]) => ids.has(String(questionId))));
        },

        filterSubmissionContentToCurrentAttempt(payload) {
            if (!payload || typeof payload !== 'object' || !payload.SubmissionContent) return payload;
            try {
                const content = typeof payload.SubmissionContent === 'string'
                    ? JSON.parse(payload.SubmissionContent)
                    : payload.SubmissionContent;
                if (!content || typeof content !== 'object' || !content.answers || typeof content.answers !== 'object') return payload;
                const groups = this.AssignmentConfigAfterShuffle?.groups || this.assignmentData?.[0]?.[0]?.groups || [];
                const answers = this.filterAnswersToQuestionGroups(content.answers, groups);
                return { ...payload, SubmissionContent: JSON.stringify({ ...content, answers }) };
            } catch (error) {
                console.error('[Assignment] Không lọc được đáp án theo snapshot hiện tại:', error);
                return payload;
            }
        },

        async handleSaveResponse(response) {
            const responseData = response?.data;
            const responseConfig = responseData?.[0]?.[0];

            const isRandomQuestionPool = this.hasGroupedRandomQuestionSelection(
                this.AssignmentConfigAfterShuffle || this.assignmentData?.[0]?.[0]
            );

            if (!isRandomQuestionPool) {
                // Cập nhật metadata của submission nhưng không gọi initPage() sau mỗi
                // auto-save. Reload toàn bộ bài ở đây có thể lấy snapshot cũ từ server
                // và ghi đè các câu học sinh vừa làm trong lúc request trước hoàn tất.
                this.assignmentData = responseData;
                this.loadSubmittedAnswers(response);
                if (responseConfig?.Is_Shuffle !== 1) {
                    await this.saveAssignmentConfig(responseData?.[1]?.[0]?.SubmissionID);
                }
                return;
            }

            const hasCurrentSnapshot = this.preserveCurrentAttemptConfig(responseData);

            this.assignmentData = responseData;
            this.assignmentInfo = responseData?.[0] ?? {};
            this.submitionInfo = responseData?.[1]?.[0] ?? {};
            this.loadSubmittedAnswers(response);

            if (this.toBoolean(responseConfig?.Is_Shuffle)) {
                this.attemptConfigPersisted = true;
            }

            if (hasCurrentSnapshot && !this.attemptConfigPersisted) {
                // Chỉ lưu snapshot lần đầu. Response đã được merge ở trên nên không cần
                // gọi initPage(), tránh reload lại cả ngân hàng câu hỏi sau mỗi auto-save.
                const submissionID = responseData?.[1]?.[0]?.SubmissionID;
                if (submissionID) {
                    await this.saveAssignmentConfig(submissionID);
                    this.attemptConfigPersisted = true;
                }
            }
        },

        async saveAssignmentConfig(submissionID, options = {}) {
            const snapshot = this.AssignmentConfigAfterShuffle || this.getCurrentAttemptConfigSnapshot();
            if (!submissionID || !snapshot) return;

            await fetchPromise(
                '/lms/EL_Student_Save_AssignmentConfig',
                {
                    SubmissionID: submissionID,
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                    AssignmentConfig: JSON.stringify(snapshot),
                },
                { cache: false, ...options }
            );
            // Không gọi initPage() ở đây — caller tự quyết định
        },

        async submitAssignment(payload) {
            if (this.isSubmittingAssignment) return;
            payload = this.filterSubmissionContentToCurrentAttempt(payload);
            this.isSubmittingAssignment = true;

            const isSendToStudent = !this.isSendToClass;
            const endpoint = isSendToStudent
                ? 'lms/EL_Student_SaveSubmission_AssignToStudent'
                : 'lms/EL_Student_SaveSubmission';
            let submitPhase = 'start';
            const submitDebugContext = {
                endpoint,
                isSendToStudent,
                isFullQuizAutoGrade: this.isFullQuizAutoGrade,
                isResubmit: this.Is_Resubmit,
                payloadStatus: payload?.SubmissionStatus,
                payloadKeys: payload && typeof payload === 'object' ? Object.keys(payload) : [],
                assignmentId: this.assignmentData?.[0]?.[0]?.AssignmentID,
                assignToClassId: this.assignmentData?.[0]?.[0]?.AssignToClassID,
                assignToStudentId: this.urlParams.get('AssignToStudentID'),
                hocSinhId: this.HocSinhDetail?.HocSinhID,
                submissionId: this.submitionInfo?.SubmissionID,
            };
            console.debug('[Assignment] submitAssignment start', submitDebugContext);

            const buildParams = (payloadInput, submitToken) => (isSendToStudent
                ? {
                    ...payloadInput,
                    Is_Full_Quiz: this.isFullQuizAutoGrade,
                    SubmitToken: submitToken,
                    Is_Resubmit: this.Is_Resubmit,
                    // Submit cũng phải giữ đúng lượt hiện tại, nhất là sau phase 1
                    // và phase 2 của bài trắc nghiệm tự động chấm.
                    LanNop: this.LanNop ?? 1,
                    AssignToStudentID: parseInt(this.urlParams.get('AssignToStudentID')),
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                }
                : {
                    ...payloadInput,
                    Is_Full_Quiz: this.isFullQuizAutoGrade,
                    SubmitToken: submitToken,
                    Is_Resubmit: this.Is_Resubmit,
                    // Dùng đúng LanNop của URL thay vì để SP tự chọn submission mới nhất.
                    LanNop: this.LanNop ?? 1,
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                });

            try {
                // Snapshot phải được ghi trước lần nộp đầu tiên, kể cả khi học sinh
                // không bấm "Lưu nháp". Nếu để SaveSubmission chạy trước, RANDOM
                // pool có thể bị chấm/báo cáo theo cấu hình nguồn thay vì đúng tập
                // câu mà học sinh vừa nhận. Is_Shuffle = 1 nghĩa là snapshot đã có.
                const currentAssignment = this.assignmentData?.[0]?.[0] || {};
                if (currentAssignment.Is_Shuffle !== 1) {
                    submitPhase = 'save-assignment-config';
                    const submissionID = this.submitionInfo?.SubmissionID;
                    if (!submissionID || !this.AssignmentConfigAfterShuffle) {
                        throw new Error('Không thể xác định snapshot câu hỏi của lượt làm hiện tại.');
                    }
                    await this.saveAssignmentConfig(submissionID, { suppressError: true });
                    console.debug('[Assignment] assignment snapshot saved', { submissionID });
                    currentAssignment.Is_Shuffle = 1;
                }

                if (this.isFullQuizAutoGrade) {
                    submitPhase = 'phase1-request-token';
                    // Phase 1: lưu bài nộp với trạng thái SUBMITTED (2).
                    // Vì là Full Quiz, backend sẽ trả config có đáp án (AssignmentConfig_HadAnswer) khi gọi reload.
                    const phase1Payload = {
                        ...payload,
                        SubmissionStatus: this.SUBMISSION_STATUS.SUBMITTED,
                    };

                    let tokenPhase1 = await this.requestSubmitToken(isSendToStudent);
                    console.debug('[Assignment] phase1 token result', { hasToken: Boolean(tokenPhase1) });
                    if (!tokenPhase1) {
                        console.error('[Assignment] submit blocked: phase1 token missing', {
                            phase: 'phase1-request-token',
                            endpoint,
                            assignToClassId: this.assignmentData?.[0]?.[0]?.AssignToClassID,
                            assignToStudentId: this.urlParams.get('AssignToStudentID'),
                            hocSinhId: this.HocSinhDetail?.HocSinhID,
                            submissionId: this.submitionInfo?.SubmissionID,
                            reason: 'EL_Student_SubmitToken_Begin không trả về SubmitToken hoặc request bị lỗi; xem log requestSubmitToken rejected/failed ngay phía trên.',
                        });
                        Vue.$toast.error(this.formatAssignmentErrorForAlert(
                            'Không lấy được one-time token nộp bài',
                            this.lastAssignmentError,
                            'Vui lòng thử lại.'
                        ), { position: 'top' });
                        return;
                    }

                    submitPhase = 'phase1-save-submission';
                    const phase1Response = await fetchPromise(endpoint, buildParams(phase1Payload, tokenPhase1), { cache: false, suppressError: true });
                    console.debug('[Assignment] phase1 save response', {
                        responseType: Array.isArray(phase1Response) ? 'array' : typeof phase1Response,
                        responseKeys: phase1Response && typeof phase1Response === 'object' ? Object.keys(phase1Response) : [],
                    });

                    submitPhase = 'reload-after-phase1';
                    const { AssignToClassID, AssignToStudentID } = this.getAssignmentIDs();
                    await this.loadAssignmentData(AssignToClassID, AssignToStudentID);

                    const phase2Payload = this.buildAutoGradedPayload({
                        ...payload,
                        SubmissionStatus: this.SUBMISSION_STATUS.GRADED,
                    });

                    const canPublishScore =
                        phase2Payload?.SubmissionStatus === this.SUBMISSION_STATUS.GRADED
                        && typeof phase2Payload?.Score === 'number';
                    console.debug('[Assignment] phase2 decision', {
                        canPublishScore,
                        status: phase2Payload?.SubmissionStatus,
                        hasScore: typeof phase2Payload?.Score === 'number',
                    });

                    if (canPublishScore) {
                        submitPhase = 'phase2-request-token';
                        const tokenPhase2 = await this.requestSubmitToken(isSendToStudent);
                        console.debug('[Assignment] phase2 token result', { hasToken: Boolean(tokenPhase2) });
                        if (!tokenPhase2) {
                            console.error('[Assignment] submit blocked: phase2 token missing', {
                                phase: 'phase2-request-token',
                                endpoint,
                                assignToClassId: this.assignmentData?.[0]?.[0]?.AssignToClassID,
                                assignToStudentId: this.urlParams.get('AssignToStudentID'),
                                hocSinhId: this.HocSinhDetail?.HocSinhID,
                                submissionId: this.submitionInfo?.SubmissionID,
                                reason: 'Đã lưu phase 1 nhưng không lấy được token phase 2 để cập nhật điểm.',
                            });
                            Vue.$toast.error(this.formatAssignmentErrorForAlert(
                                'Đã nộp bài nhưng chưa lấy được token để cập nhật điểm',
                                this.lastAssignmentError,
                                'Vui lòng thử lại.'
                            ), { position: 'top' });
                            // Phase 1 đã lưu bài; không reload ở lỗi phase 2 vì reload
                            // có thể thay state đang hiển thị bằng snapshot cũ và làm
                            // học sinh tưởng rằng các câu vừa làm đã bị mất.
                            return;
                        }
                        submitPhase = 'phase2-save-submission';
                        const phase2Response = await fetchPromise(endpoint, buildParams(phase2Payload, tokenPhase2), { cache: false, suppressError: true });
                        console.debug('[Assignment] phase2 save response', {
                            responseType: Array.isArray(phase2Response) ? 'array' : typeof phase2Response,
                            responseKeys: phase2Response && typeof phase2Response === 'object' ? Object.keys(phase2Response) : [],
                        });
                        Vue.$toast.success('Nộp bài thành công! Hệ thống đã tự động chấm và công bố điểm.', { position: 'top' });
                    } else {
                        Vue.$toast.success('Nộp bài thành công!', { position: 'top' });
                    }
                } else {
                    const payloadForSubmit = payload;
                    let submitToken = null;
                    if ((payloadForSubmit?.SubmissionStatus ?? 0) >= this.SUBMISSION_STATUS.SUBMITTED) {
                        submitPhase = 'request-token';
                        submitToken = await this.requestSubmitToken(isSendToStudent);
                        console.debug('[Assignment] normal token result', { hasToken: Boolean(submitToken) });
                        if (!submitToken) {
                            console.error('[Assignment] submit blocked: normal token missing', {
                                phase: 'request-token',
                                endpoint,
                                assignToClassId: this.assignmentData?.[0]?.[0]?.AssignToClassID,
                                assignToStudentId: this.urlParams.get('AssignToStudentID'),
                                hocSinhId: this.HocSinhDetail?.HocSinhID,
                                submissionId: this.submitionInfo?.SubmissionID,
                                reason: 'EL_Student_SubmitToken_Begin không trả về SubmitToken hoặc request bị lỗi.',
                            });
                            Vue.$toast.error(this.formatAssignmentErrorForAlert(
                                'Không lấy được one-time token nộp bài',
                                this.lastAssignmentError,
                                'Vui lòng thử lại.'
                            ), { position: 'top' });
                            return;
                        }
                    }
                    submitPhase = 'save-submission';
                    const saveResponse = await fetchPromise(endpoint, buildParams(payloadForSubmit, submitToken), { cache: false, suppressError: true });
                    console.debug('[Assignment] save response', {
                        responseType: Array.isArray(saveResponse) ? 'array' : typeof saveResponse,
                        responseKeys: saveResponse && typeof saveResponse === 'object' ? Object.keys(saveResponse) : [],
                    });
                    Vue.$toast.success('Nộp bài thành công!', { position: 'top' });
                }

                this.initPage();
            } catch (err) {
                const errorDetails = this.describeAssignmentApiError(err, {
                    phase: submitPhase,
                    ...submitDebugContext,
                    reason: 'Lỗi xảy ra trong một bước submit; phase cho biết bước lỗi.',
                });
                console.error('[Assignment] submitAssignment failed', errorDetails);
                this.lastAssignmentError = errorDetails;
                Vue.$toast.error(this.formatAssignmentErrorForAlert(
                    'Nộp bài thất bại',
                    errorDetails,
                    'Vui lòng thử lại.'
                ), { position: 'top' });
            } finally {
                this.isSubmittingAssignment = false;
            }
        },

        async requestSubmitToken(isSendToStudent) {
            const endpoint = 'lms/EL_Student_SubmitToken_Begin';
            this.lastAssignmentError = null;
            const params = {
                HocSinhID: this.HocSinhDetail?.HocSinhID,
            };

            if (isSendToStudent) {
                params.AssignToStudentID = parseInt(this.urlParams.get('AssignToStudentID'));
            } else {
                params.AssignToClassID = this.assignmentData?.[0]?.[0]?.AssignToClassID;
            }

            try {
                console.debug('[Assignment] requestSubmitToken request', { endpoint, params, isSendToStudent });
                const res = await fetchPromise(endpoint, params, { cache: false, suppressError: true });
                const token = res?.SubmitToken || res?.[0]?.SubmitToken || null;
                const responseSummary = this.summarizeAssignmentApiResponse(res);
                console.debug('[Assignment] requestSubmitToken response', { ...responseSummary, hasSubmitToken: Boolean(token) });
                if (!token) {
                    this.lastAssignmentError = {
                        endpoint,
                        params,
                        reason: 'Response không có SubmitToken theo các format được hỗ trợ (res.SubmitToken hoặc res[0].SubmitToken).',
                        response: responseSummary,
                    };
                    console.error('[Assignment] requestSubmitToken rejected', this.lastAssignmentError);
                }
                return token;
            } catch (error) {
                console.error('Lỗi requestSubmitToken:', error);
                this.lastAssignmentError = this.describeAssignmentApiError(error, {
                    endpoint,
                    params,
                    reason: 'fetchPromise ném lỗi khi gọi EL_Student_SubmitToken_Begin.',
                });
                console.error('[Assignment] requestSubmitToken failed', this.lastAssignmentError);
                return null;
            }
        },

        summarizeAssignmentApiResponse(response) {
            if (response == null) return { responseType: String(response), responseKeys: [] };
            if (Array.isArray(response)) {
                return {
                    responseType: 'array',
                    arrayLength: response.length,
                    itemTypes: response.slice(0, 3).map(item => Array.isArray(item) ? 'array' : typeof item),
                    itemKeys: response.slice(0, 3).map(item => item && typeof item === 'object' && !Array.isArray(item) ? Object.keys(item) : []),
                };
            }
            if (typeof response === 'object') {
                return {
                    responseType: 'object',
                    responseKeys: Object.keys(response),
                    success: response.success,
                    code: response.code ?? response.Code,
                    status: response.status ?? response.Status,
                    message: response.message ?? response.Message,
                    dataType: response.data == null ? String(response.data) : (Array.isArray(response.data) ? 'array' : typeof response.data),
                    dataKeys: response.data && typeof response.data === 'object' && !Array.isArray(response.data) ? Object.keys(response.data) : [],
                };
            }
            return { responseType: typeof response, responsePreview: String(response).slice(0, 200) };
        },

        describeAssignmentApiError(error, context = {}) {
            return {
                ...context,
                errorName: error?.name,
                message: error?.message || 'Không có error.message',
                code: error?.code,
                status: error?.status || error?.response?.status,
                response: error?.responseJSON ? this.summarizeAssignmentApiResponse(error.responseJSON) : undefined,
                stack: error?.stack ? error.stack.split('\n').slice(0, 3).join(' | ') : undefined,
            };
        },

        formatAssignmentErrorForAlert(prefix, details = null, fallback = 'Vui lòng thử lại.') {
            const detail = details || {};
            let message = detail.message
                || detail.response?.message
                || '';
            if (!message && detail.reason && detail.reason.includes('SubmitToken')) {
                message = 'Hệ thống không trả về one-time token.';
            }
            if (!message && detail.response) {
                message = 'Hệ thống trả về dữ liệu lỗi hoặc không đúng định dạng.';
            }
            if (!message) message = fallback;
            const status = detail.status || detail.code;
            const statusText = status ? 'Mã lỗi ' + status : '';
            return [prefix, message, statusText]
                .filter(Boolean)
                .join(' — ');
        },

        submitAssignmentFinal() {
            this.confirmSubmitDialog = false;

            // Chỉ xin one-time token sau khi request auto-save cuối cùng đã hoàn tất;
            // nếu auto-save lỗi (đặc biệt 401 do session hết hạn), giữ bài trên màn hình.
            const assignmentTaker = this.$refs.assignmentTaker;
            const flushPromise = assignmentTaker?.flushPendingSave?.();
            if (!flushPromise || typeof flushPromise.then !== 'function') {
                Vue.$toast.error('Chưa thể nộp bài vì đáp án chưa được lưu thành công. Vui lòng đăng nhập lại rồi thử lại.', { position: 'top' });
                return;
            }

            flushPromise.then(saved => {
                if (!saved) {
                    Vue.$toast.error('Chưa thể nộp bài vì đáp án chưa được lưu thành công. Vui lòng đăng nhập lại rồi thử lại.', { position: 'top' });
                    return;
                }

                const payload = {
                    AssignToClassID: this.assignmentData[0][0].AssignToClassID,
                    SubmissionContent: JSON.stringify({ answers: this.puseranswers }),
                    SubmissionStatus: this.SUBMISSION_STATUS.SUBMITTED,
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                };
                this.submitAssignment(payload);
            }).catch(error => {
                console.error('[Assignment] final save flush failed', error);
                Vue.$toast.error('Chưa thể nộp bài vì không thể xác nhận trạng thái lưu. Vui lòng thử lại.', { position: 'top' });
            });
        },

        toBoolean(value) {
            if (typeof value === 'boolean') return value;
            if (typeof value === 'number') return value === 1;
            if (typeof value === 'string') {
                const normalized = value.trim().toLowerCase();
                return normalized === '1' || normalized === 'true';
            }
            return false;
        },

        buildAutoGradedPayload(payload) {
            const groups = this.getGroupsForAutoGrading();
            if (!groups.length) {
                console.warn('Auto-grade fallback: thiếu cấu hình câu hỏi có đáp án, chuyển về trạng thái đã nộp.');
                return {
                    ...payload,
                    SubmissionStatus: this.SUBMISSION_STATUS.SUBMITTED,
                };
            }

            const hasAnyAnswerKey = this.countScorableQuizQuestions(groups) > 0;
            if (!hasAnyAnswerKey) {
                console.warn('Auto-grade fallback: không tìm thấy answer key để chấm tự động, chuyển về trạng thái đã nộp.');
                return {
                    ...payload,
                    SubmissionStatus: this.SUBMISSION_STATUS.SUBMITTED,
                };
            }

            // Sau phase 1, SubmissionContent trong DB là nguồn chuẩn của lượt nộp.
            // Ưu tiên dữ liệu này để không chấm nhầm state UI cũ khi học sinh vừa nộp.
            const answers = this.filterAnswersToQuestionGroups(this.getLatestSubmissionAnswers(), groups);
            const graded = this.fn_AutoGradeSubmission({ answers: _.cloneDeep(answers) }, groups);
            if (typeof graded?.Score !== 'number' || Number.isNaN(graded.Score)) {
                console.warn('Auto-grade fallback: tính điểm thất bại, chuyển về trạng thái đã nộp.');
                return {
                    ...payload,
                    SubmissionStatus: this.SUBMISSION_STATUS.SUBMITTED,
                };
            }

            return {
                ...payload,
                SubmissionStatus: this.SUBMISSION_STATUS.GRADED,
                SubmissionContent: graded.SubmissionContent,
                Score: graded.Score,
            };
        },

        getLatestSubmissionAnswers() {
            const raw = this.submitionInfo?.SubmissionContent;
            if (raw) {
                try {
                    const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
                    if (parsed?.answers && typeof parsed.answers === 'object') {
                        return parsed.answers;
                    }
                } catch (error) {
                    console.warn('Không parse được SubmissionContent hiện tại, dùng state UI:', error);
                }
            }
            return this.puseranswers || {};
        },

        getGroupsForAutoGrading() {
            const detail = this.assignmentData?.[0]?.[0] || {};
            const rawConfigs = [
                detail.AssignmentConfig_HadAnswer,
                detail.AssignmentConfig,
            ].filter(Boolean);

            let bestGroups = [];
            let bestScore = -1;

            for (const rawConfig of rawConfigs) {
                try {
                    const parsed = JSON.parse(rawConfig);
                    const groups = parsed?.groups || [];
                    const score = this.countScorableQuizQuestions(groups);
                    if (score > bestScore) {
                        bestScore = score;
                        bestGroups = groups;
                    }
                } catch (e) {
                    console.error('Không parse được AssignmentConfig để tự động chấm:', e);
                }
            }

            return bestGroups;
        },

        async syncAutoGradeBackfillToDb(submissionContent, score) {
            try {
                const isSendToStudent = !this.isSendToClass;
                const token = await this.requestSubmitToken(isSendToStudent);
                if (!token) return;
                const endpoint = isSendToStudent
                    ? 'lms/EL_Student_SaveSubmission_AssignToStudent'
                    : 'lms/EL_Student_SaveSubmission';
                const params = isSendToStudent
                    ? {
                        AssignToStudentID: parseInt(this.urlParams.get('AssignToStudentID')),
                        HocSinhID: this.HocSinhDetail?.HocSinhID,
                        SubmissionContent: submissionContent,
                        SubmissionStatus: this.SUBMISSION_STATUS.GRADED,
                        Score: score,
                        Is_Full_Quiz: this.isFullQuizAutoGrade,
                        SubmitToken: token,
                        Is_Resubmit: 0,
                        // Backfill điểm tự động vẫn thuộc lượt đang mở, không phải lượt cao nhất.
                        LanNop: this.LanNop ?? 1,
                    }
                    : {
                        AssignToClassID: this.assignmentData?.[0]?.[0]?.AssignToClassID,
                        HocSinhID: this.HocSinhDetail?.HocSinhID,
                        SubmissionContent: submissionContent,
                        SubmissionStatus: this.SUBMISSION_STATUS.GRADED,
                        Score: score,
                        Is_Full_Quiz: this.isFullQuizAutoGrade,
                        SubmitToken: token,
                        Is_Resubmit: 0,
                        // Backfill điểm tự động vẫn thuộc lượt đang mở, không phải lượt cao nhất.
                        LanNop: this.LanNop ?? 1,
                    };
                await fetchPromise(endpoint, params, { cache: false, suppressError: true });
                console.debug('[Assignment] auto-grade backfilled score synced to DB successfully', { score });
            } catch (err) {
                console.warn('[Assignment] failed to sync backfilled score to DB:', err);
            }
        },

        countScorableQuizQuestions(groups) {
            let count = 0;
            for (const group of (groups || [])) {
                for (const question of (group?.questions || [])) {
                    if (this.hasAnswerKey(question)) count += 1;
                }
            }
            return count;
        },

        hasAnswerKey(question) {
            if (!question || !question.type) return false;
            const config = question.config || {};

            if (question.type === this.QUIZ_TYPES.SINGLE_CHOICE || question.type === this.QUIZ_TYPES.TRUE_FALSE) {
                return config.correctAnswer !== null && config.correctAnswer !== undefined && config.correctAnswer !== '';
            }
            if (question.type === this.QUIZ_TYPES.MULTIPLE_CHOICE) {
                return Array.isArray(config.correctAnswers) && config.correctAnswers.length > 0;
            }
            if (question.type === this.QUIZ_TYPES.MULTIPLE_TRUE_FALSE) {
                return Array.isArray(config.options) && config.options.some(opt => opt?.correctAnswer !== null && opt?.correctAnswer !== undefined);
            }
            if (question.type === this.QUIZ_TYPES.MATCHING) {
                return Array.isArray(config.correctPairs) && config.correctPairs.length > 0;
            }
            if (question.type === this.QUIZ_TYPES.FILL_IN_BLANK) {
                const blanks = (config.parts || []).filter(p => p.type === 'blank');
                return blanks.some(blank => Array.isArray(blank.acceptedAnswers) && blank.acceptedAnswers.length > 0);
            }

            return false;
        },

        isSameValue(left, right) {
            if (left === right) return true;
            if (left == null || right == null) return false;
            return String(left) === String(right);
        },

        fn_AutoGradeSubmission(submissionContentObj, asmGroups) {
            // Tính điểm và lưu payload theo đúng câu trong snapshot của lượt hiện tại;
            // bỏ các key còn sót từ draft/lượt làm trước.
            let answers = this.filterAnswersToQuestionGroups(submissionContentObj?.answers ?? {}, asmGroups);
            let score = 0;

            for (const group of asmGroups) {
                for (const question of (group?.questions || [])) {
                    let autoScore = 0;
                    const answerData = answers?.[question.id]?.answerData;
                    const questionPoints = Number(question?.points ?? 0);

                    if (answerData == null) continue;

                    if (question.type === this.QUIZ_TYPES.SINGLE_CHOICE) {
                        if (this.isSameValue(question?.config?.correctAnswer, answerData)) {
                            autoScore = questionPoints;
                        }
                    }
                    else if (question.type === this.QUIZ_TYPES.MULTIPLE_CHOICE) {
                        const arr1 = question?.config?.correctAnswers || [];
                        const mode = question?.config?.scoringMode || 'equal';
                        let correctIndex = 0;

                        arr1.forEach(opt => {
                            if (Array.isArray(answerData) && answerData.some(item => this.isSameValue(item, opt))) correctIndex++;
                        });

                        if (mode === 'partial') {
                            const partialMap = { 1: 0.1, 2: 0.25, 3: 0.5, 4: 1.0 };
                            autoScore = (partialMap[correctIndex] ?? 0) * questionPoints;
                        } else {
                            autoScore = arr1.length
                                ? Math.round((correctIndex / arr1.length) * questionPoints * 100) / 100
                                : 0;
                        }
                    }
                    else if (question.type === this.QUIZ_TYPES.TRUE_FALSE) {
                        if (this.isSameValue(question?.config?.correctAnswer, answerData)) {
                            autoScore = questionPoints;
                        }
                    }
                    else if (question.type === this.QUIZ_TYPES.MULTIPLE_TRUE_FALSE) {
                        const mode = question?.config?.scoringMode || 'equal';
                        const options = question?.config?.options || [];
                        let correctCount = 0;

                        options.forEach(opt => {
                            if (this.isSameValue(opt?.correctAnswer, answerData?.[opt.id])) correctCount++;
                        });

                        if (mode === 'partial') {
                            const partialMap = { 1: 0.1, 2: 0.25, 3: 0.5, 4: 1.0 };
                            autoScore = (partialMap[correctCount] ?? 0) * questionPoints;
                        } else {
                            const total = options.length;
                            autoScore = total
                                ? Math.round((correctCount / total) * questionPoints * 100) / 100
                                : 0;
                        }
                    }
                    else if (question.type === this.QUIZ_TYPES.MATCHING) {
                        let numberOfCorrect = 0;
                        const correctPairs = question?.config?.correctPairs || [];

                        correctPairs.forEach(item => {
                            const findAnswer = Array.isArray(answerData)
                                ? answerData.find(a => this.isSameValue(a.from, item.from))
                                : null;
                            if (findAnswer && this.isSameValue(findAnswer.to, item.to)) numberOfCorrect += 1;
                        });

                        autoScore = correctPairs.length
                            ? (numberOfCorrect / correctPairs.length) * questionPoints
                            : 0;
                    }
                    else if (question.type === this.QUIZ_TYPES.FILL_IN_BLANK) {
                        const parts = question?.config?.parts || [];
                        const blanks = parts.filter(p => p.type === 'blank');

                        if (blanks.length === 0) {
                            autoScore = questionPoints;
                        } else {
                            let correctAnswersCount = 0;
                            const normalizeBlankValue = (val) => String(val ?? '')
                                .normalize('NFKC')
                                .replace(/[’‘ʼ`´ʻʽʹ]/g, "'")
                                .replace(/[“”„‟]/g, '"')
                                .replace(/[−–—﹣－]/g, '-')
                                .replace(/\s+/g, '')
                                .trim()
                                .toLowerCase();

                            blanks.forEach(blank => {
                                const studentAnswer = normalizeBlankValue(answerData?.[blank.id]);
                                const acceptedAnswers = (blank.acceptedAnswers || []).map(normalizeBlankValue);
                                if (acceptedAnswers.includes(studentAnswer)) {
                                    correctAnswersCount += 1;
                                } else {
                                    const numericPattern = /^[+-]?(?:(?:\d+(?:[.,]\d+)?)|(?:[.,]\d+))$/;
                                    const studentNum = numericPattern.test(studentAnswer)
                                        ? Number(studentAnswer.replace(',', '.'))
                                        : null;
                                    if (Number.isFinite(studentNum)) {
                                        const numMatch = acceptedAnswers.some(ans => {
                                            const ansNum = numericPattern.test(ans) ? Number(ans.replace(',', '.')) : null;
                                            return Number.isFinite(ansNum) && Math.abs(studentNum - ansNum) < 1e-9;
                                        });
                                        if (numMatch) correctAnswersCount += 1;
                                    }
                                }
                            });

                            autoScore = (correctAnswersCount / blanks.length) * questionPoints;
                        }
                    }

                    score += autoScore;
                    answers = {
                        ...answers,
                        [question.id]: {
                            ...answers[question.id],
                            grading: {
                                ...answers?.[question.id]?.grading,
                                autoScore,
                                manualScore: answers?.[question.id]?.grading?.manualScore !== null && answers?.[question.id]?.grading?.manualScore !== undefined && answers?.[question.id]?.grading?.manualScore !== 0
                                    ? answers[question.id].grading.manualScore
                                    : autoScore,
                            },
                        },
                    };
                }
            }

            return {
                SubmissionContent: JSON.stringify({ answers }),
                Score: Math.round(score * 100) / 100,
            };
        },

        // ===========================
        // RESUBMISSION
        // ===========================

        async insertSubmissionForResubmit() {
            const isSendToStudent = !this.isSendToClass;
            const payload = isSendToStudent
                ? {
                    AssignToStudentID: parseInt(this.urlParams.get('AssignToStudentID')),
                    SubmissionContent: JSON.stringify({ answers: {} }),
                    SubmissionStatus: this.SUBMISSION_STATUS.DRAFT,
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                }
                : {
                    AssignToClassID: this.assignmentData[0][0].AssignToClassID,
                    SubmissionContent: JSON.stringify({ answers: {} }),
                    SubmissionStatus: this.SUBMISSION_STATUS.DRAFT,
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                };
            const endpoint = isSendToStudent
                ? 'lms/EL_Student_InsertSubmission_AssignToStudent'
                : 'lms/EL_Student_InsertSubmission';

            try {
                const data = await fetchPromise(endpoint, payload, { cache: false });
                this.urlParams.delete('Is_Resubmit');
                this.urlParams.set('LanNop', data[1][0].LanNop.toString());
                // Không gọi initPage() ở đây: request detail hiện tại vẫn giữ
                // isLoadingAssignment. Caller sẽ tải lại tuần tự bằng LanNop mới.
                return true;
            } catch (err) {
                console.error('Lỗi insertSubmissionForResubmit:', err);
                return false;
            }
        },

        // ===========================
        // FLAG POST-SUBMIT
        // ===========================

        async saveFlagsPostSubmit(payload) {
            const isSendToStudent = !this.isSendToClass;
            if (isSendToStudent) {
                await fetchPromise('lms/EL_Student_SaveSubmission_AssignToStudent_WithFlag', {
                    AssignToStudentID: parseInt(this.urlParams.get('AssignToStudentID')),
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                    SubmissionContent: payload.SubmissionContent,
                }, { cache: false });
            } else {
                await fetchPromise('lms/EL_Student_SaveSubmissionWithFlag', {
                    AssignToClassID: payload.AssignToClassID,
                    HocSinhID: this.HocSinhDetail.HocSinhID,
                    SubmissionContent: payload.SubmissionContent,
                }, { cache: false });
            }
        },

        // ===========================
        // QUESTION TRACKING
        // ===========================

        renderQuestionNotSubmit() {
            const currentConfig = this.assignmentData[0]?.[0];
            if (!currentConfig) return '';

            let groups = currentConfig.groups;
            if (!Array.isArray(groups)) {
                try {
                    groups = JSON.parse(currentConfig.AssignmentConfig || '{}').groups || [];
                } catch (error) {
                    return '';
                }
            }

            const allQuestions = groups.flatMap(g => g.questions || []);
            const unanswered = allQuestions
                .map((question, index) => ({ question, index: index + 1 }))
                .filter(({ question }) => {
                    const answerData = this.puseranswers[question.id]?.answerData;
                    return answerData === null || answerData === undefined;
                })
                .map(({ index }) => `Câu ${index}`);
            return unanswered.join(', ');
        },
    },
	}
</script>