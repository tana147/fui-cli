<template>
	<v-dialog :model-value="modelValue" max-width="1100" @update:model-value="onDialogModelUpdate">
		<!-- Chế độ chỉ tài liệu không cần vùng fill-height của tab câu hỏi, nên dialog co theo bảng. -->
		<v-card class="content-hub-import-dialog" :class="{ 'content-hub-import-dialog--documents': documentsOnly || interactiveVideosOnly }">
            <v-card-title class="content-hub-import-dialog__header d-flex align-center ga-2">
                <v-icon class="content-hub-import-dialog__title-icon">mdi-database-import-outline</v-icon>
                <span class="content-hub-import-dialog__title">Import từ Content Hub</span>
                <v-spacer />
                <v-btn icon="mdi-close" variant="text" color="white" @click="close" />
            </v-card-title>
			<v-card-text class="content-hub-import-dialog__body px-4 pt-4 pb-3">
                <v-alert v-if="!hasContext" type="warning" variant="tonal" density="compact" class="mb-3">
                    {{ documentsOnly ? 'Bài học' : 'Bài tập' }} chưa có Khối/Môn nên chưa thể tải dữ liệu từ Content Hub.
                </v-alert>
                <!-- Ẩn tabs khi chỉ định đơn tab (questionsOnly hoặc documentsOnly) để giao diện gọn gàng -->
                <v-tabs v-if="!documentsOnly && !questionsOnly" v-model="activeTab" color="primary" class="mb-3">
                    <!-- Bài tập có thêm tab Tài liệu nhưng chỉ nhận video tương tác; bài học dùng lại tab này cho mọi tài liệu hợp lệ. -->
                    <v-tab value="documents"><v-icon start>mdi-file-document-multiple-outline</v-icon>Tài liệu</v-tab>
                    <v-tab value="questions"><v-icon start>mdi-help-box-multiple-outline</v-icon>Câu hỏi</v-tab>
                </v-tabs>
                <v-window v-model="activeTab" class="content-hub-import-dialog__window">
                    <v-window-item v-if="!questionsOnly" value="documents" class="content-hub-import-dialog__window-item">
                        <div class="content-hub-import-dialog__panel content-hub-document-panel">
                        <v-row dense class="mb-2 flex-grow-0 align-start pt-1">
                            <v-col cols="12" :md="showDocumentTypeFilter ? 5 : 6">
                                <v-select v-model="selectedLibraryId" :items="libraries" item-title="TenHocLieu" item-value="HocLieuID"
                                    :label="interactiveVideosOnly ? 'Video tương tác trong Content Hub' : 'Kho tài liệu Content Hub'"
                                    variant="outlined" density="compact" :loading="loadingLibraries" clearable hide-details class="content-hub-filter-select" />
                            </v-col>
                            <!-- Bộ lọc loại tài liệu theo danh sách được phép của từng module (Video, Audio, Image, Slide/Office, HTML, iSpring) -->
                            <v-col v-if="showDocumentTypeFilter" cols="12" md="4">
                                <v-select v-model="selectedDocumentTypeFilter" :items="documentTypeOptions" item-title="title" item-value="value"
                                    label="Loại tài liệu" variant="outlined" density="compact" hide-details class="content-hub-filter-select" />
                            </v-col>
                            <v-col cols="12" :md="showDocumentTypeFilter ? 3 : 6" class="d-flex align-start justify-end pt-1">
                                <v-chip color="secondary" variant="tonal">{{ selectedDocuments.length }} {{ interactiveVideosOnly ? 'video tương tác' : 'tài liệu' }} đã chọn</v-chip>
                            </v-col>
                        </v-row>
                        <v-data-table v-model="selectedDocuments" :headers="documentHeaders" :items="documentItems" item-value="NoiDungID"
                            show-select return-object :loading="loadingDocuments" :items-per-page="10" density="compact" class="border rounded content-hub-import-dialog__table content-hub-document-table">
                            <template #item.TenNoiDung="{ item }">
                                <div class="d-flex align-center ga-2"><v-icon :color="getDocumentColor(item)">{{ getDocumentIcon(item) }}</v-icon><span class="text-truncate content-hub-document-name">{{ getDocumentName(item) }}</span><v-chip v-if="isInteractiveVideo(item)" size="x-small" color="deep-purple" variant="tonal">{{ getInteractiveQuestionCount(item) }} câu hỏi</v-chip></div>
                            </template>
                            <template #item.NguoiUploadName="{ item }"><span class="d-block text-truncate content-hub-document-creator">{{ getDocumentCreator(item) }}</span></template>
                            <template #item.LoaiNoiDung="{ item }"><v-chip size="x-small" variant="tonal">{{ getDocumentType(item) }}</v-chip></template>
                            <!-- Ảnh ưu tiên binary LMS FileData; chỉ fallback thumbnail Drive để tránh URL googleusercontent trả 403. -->
                            <template #item.actions="{ item }"><v-btn v-if="getDocumentOpenSource(item)" :icon="isImageDocument(item) ? 'mdi-eye-outline' : 'mdi-open-in-new'" size="small" variant="text"
                                :href="isImageDocument(item) ? undefined : getDocumentOpenSource(item)" :target="isImageDocument(item) ? undefined : '_blank'" rel="noopener" @click="handleDocumentOpen(item, $event)" /></template>
                            <template #item.CreateUser="{ item }"><span class="d-block text-truncate content-hub-document-creator-code">{{ getDocumentEmployeeCode(item) }}</span></template>
                            <template #item.CreateTime="{ item }"><span class="d-block text-truncate content-hub-document-created-time">{{ getDocumentCreatedTime(item) }}</span></template>
                            <template #no-data><div class="pa-6 text-center text-medium-emphasis">{{ interactiveVideosOnly ? 'Chưa có video tương tác trong Khối/Môn này.' : 'Chưa có tài liệu trong kho này.' }}</div></template>
                        </v-data-table>
                        </div>
                    </v-window-item>
                    <v-window-item v-if="!documentsOnly" value="questions" class="content-hub-import-dialog__window-item">
                        <div class="content-hub-import-dialog__panel content-hub-question-panel">
                        <!-- Tách control khỏi bảng để stylesheet global chỉ cần chia hai vùng bằng Grid. -->
                        <div class="content-hub-question-controls">
                        <!-- Import từ Content Hub: Tiêu chuẩn theo Nhóm / File câu hỏi -->
                        <v-row dense class="mb-2 flex-grow-0 align-start">
                            <!-- Ma trận chọn nguồn riêng ở từng dòng; bộ chọn nhóm chung chỉ dùng cho chế độ Tiêu chuẩn. -->
                            <v-col cols="12" md="5">
                                <v-select v-model="selectedGroupId" :items="questionGroups" item-title="Title" item-value="Id"
                                    label="Nhóm câu hỏi" variant="outlined" density="compact" :loading="loadingGroups" hide-details class="content-hub-filter-select" />
                            </v-col>
                            <!-- Chế độ Tiêu chuẩn: Hiển thị lọc theo nguồn file -->
                            <v-col cols="12" md="5">
                                <v-select v-model="selectedQuestionSourceFile" :items="questionSourceFiles" item-title="title" item-value="value"
                                    label="Nguồn file (không bắt buộc)" variant="outlined" density="compact" :disabled="!questionSourceFiles.length"
                                    placeholder="Tất cả nguồn" clearable hide-details class="content-hub-filter-select" />
                            </v-col>
                            <v-col cols="12" md="2" class="d-flex align-start justify-end pt-1">
                                <v-chip color="primary" variant="tonal">
                                    Đã chọn {{ currentGroupSelectedCount }}/{{ questionPoolCount }} câu
                                </v-chip>
                            </v-col>
                        </v-row>
                        <!-- Lựa chọn được giữ xuyên suốt các nhóm; dòng này cho biết tổng câu đã chọn ở từng nhóm. -->
                        <div v-if="selectedQuestions.length" class="question-selection-summary mb-2">
                            <span class="text-caption text-medium-emphasis">Theo nhóm:</span>
                            <v-chip v-for="summary in selectedQuestionGroupSummaries" :key="summary.id" size="x-small" color="secondary" variant="tonal">
                                {{ summary.title }}: {{ summary.count }} câu
                            </v-chip>
                            <v-chip size="x-small" color="primary" variant="outlined">Tổng {{ selectedQuestions.length }} câu</v-chip>
                        </div>
                        </div>

                        <!-- Chế độ Tiêu chuẩn: Virtual table danh sách chi tiết câu hỏi -->
                        <div class="d-flex flex-column flex-grow-1 overflow-hidden content-hub-question-list">
                            <!-- Nêu rõ phạm vi pool hiện tại để người dùng biết có thể trộn câu tự tạo và câu từ file. -->
                            <!-- Chỉ module có nghiệp vụ bốc ngẫu nhiên (Soạn bài tập) mới cần giải thích và dùng thao tác lấy cả pool. -->
                            <!-- Alert chỉ cao theo nội dung; nếu để flex/grid tự kéo chiều cao, thông báo sẽ chiếm luôn vùng bảng. -->
                            <v-alert v-if="allowQuestionPool && canImportQuestionPool" type="info" variant="tonal" density="compact" class="mb-2 flex-shrink-0 content-hub-question-pool-alert" style="height: auto !important; min-height: 42px !important; max-height: none !important; flex: 0 0 auto !important; align-self: stretch !important;">
                                <template v-if="isAllQuestionSources">
                                    Đang hiển thị toàn bộ <strong>{{ questionPoolCount }} câu</strong> trong nhóm, gồm câu tự tạo và câu từ các file.
                                </template>
                                <template v-else>
                                    File <strong>“{{ selectedQuestionSourceFile }}”</strong> có <strong>{{ questionPoolCount }} câu</strong>.
                                </template>
                                Chọn các câu cần dùng, hoặc lấy toàn bộ phạm vi đang hiển thị.
                            </v-alert>

                            <!-- Virtual table vẫn giữ cơ chế chọn của data table nhưng bỏ phân trang; người dùng cuộn để xem toàn bộ câu hỏi. -->
                            <v-data-table-virtual :model-value="visibleSelectedQuestions" @update:model-value="onVisibleQuestionSelectionUpdate"
                                :headers="questionHeaders" :items="filteredQuestions" item-value="Id"
                                show-select return-object :loading="loadingQuestions" height="100%" item-height="58"
                                density="compact" class="border rounded content-hub-import-dialog__table content-hub-standard-question-table">
                                <template #item.QuestionText="{ item }">
                                    <div class="content-hub-question-preview py-1">
                                        <!-- Cảnh báo nếu câu hỏi đã được chọn ở bộ lọc kỹ năng/nhóm khác hoặc đã có sẵn trong bài tập -->
                                        <div v-if="getQuestionDuplicateStatus(item)" class="d-flex align-center ga-1 mb-1">
                                            <v-chip size="x-small" :color="getQuestionDuplicateStatus(item).color" variant="flat" class="font-weight-medium">
                                                <v-icon start size="12">{{ getQuestionDuplicateStatus(item).icon }}</v-icon>
                                                {{ getQuestionDuplicateStatus(item).text }}
                                            </v-chip>
                                        </div>
                                        <!-- uc-latex-view xử lý cả HTML, công thức và ảnh được nhúng trong QuestionText. -->
                                        <uc-latex-view v-if="getQuestionText(item)" :content="getQuestionText(item)"
                                            :escape-html="false" class="question-preview__text" />
                                        <span v-else class="text-medium-emphasis">Chưa có nội dung</span>
                                        <!-- Hiển thị các chip Kỹ năng của câu hỏi (hỗ trợ 1 câu có nhiều kỹ năng) -->
                                        <div v-if="getQuestionSkills(item).length" class="d-flex flex-wrap align-center ga-1 mt-1">
                                            <v-chip v-for="skill in getQuestionSkills(item)" :key="skill.id || skill.KyNang_MonHoc_ChiTietID || skill.name || skill.TenKyNang"
                                                size="x-small" color="indigo" variant="tonal">
                                                {{ skill.name || skill.TenKyNang || 'Kỹ năng' }}
                                            </v-chip>
                                        </div>
                                        <!-- Một số câu hỏi lưu ảnh ở media thay vì nhúng trực tiếp vào QuestionText. -->
                                        <div v-if="getQuestionImages(item).length" class="question-preview__images">
                                            <v-img v-for="(image, index) in getQuestionImages(item)" :key="image.id || index"
                                                :src="imageSource(image)" class="question-preview__image" cover />
                                        </div>
                                    </div>
                                </template>
                                <template #item.AnswerPreview="{ item }">
                                    <div v-if="getQuestionAnswers(item).length" class="answer-preview py-1">
                                        <div v-for="(answer, index) in getQuestionAnswers(item)" :key="answer.id || index"
                                            class="answer-preview__item" :class="{ 'answer-preview__item--correct': answer.correct, 'answer-preview__item--compact': answer.compact, 'answer-preview__item--true': answer.compactStatus === 'true', 'answer-preview__item--false': answer.compactStatus === 'false' }">
                                            <span class="answer-preview__label">{{ answer.label || `${index + 1}.` }}</span>
                                            <uc-latex-view :content="answer.text || '—'" :escape-html="false" class="answer-preview__text" />
                                            <v-icon v-if="answer.correct" size="14" color="success" title="Đáp án đúng">mdi-check-circle</v-icon>
                                        </div>
                                    </div>
                                    <span v-else class="text-medium-emphasis">—</span>
                                </template>
                                <template #item.Type="{ item }"><v-chip size="x-small" variant="tonal">{{ item.Type }}</v-chip></template>
								<template #no-data>
									<div class="pa-6 text-center text-medium-emphasis d-flex align-center justify-center ga-2">
										<v-progress-circular v-if="loadingQuestions" indeterminate size="20" width="2" />
										<span>{{ loadingQuestions ? 'Đang tải câu hỏi...' : 'Nhóm "' + selectedQuestionGroupTitle + '" chưa có câu hỏi phù hợp.' }}</span>
									</div>
								</template>
                            </v-data-table-virtual>
                        </div>
                        </div>
                    </v-window-item>
                </v-window>
            </v-card-text>
            <v-card-actions class="content-hub-import-dialog__actions">
                <v-spacer /><v-btn variant="text" @click="close">Hủy</v-btn>
                <!-- Tên nút mô tả nghiệp vụ thay vì dùng riêng thuật ngữ pool để giáo viên dễ phân biệt hai cách import. -->
                <!-- Soạn học liệu chỉ chọn từng câu; Soạn bài tập mới được lấy cả nhóm để bốc ngẫu nhiên. -->
                <v-btn v-if="allowQuestionPool && !documentsOnly && canImportQuestionPool" color="secondary" variant="tonal" @click="importQuestionPool">
                    {{ getImportPoolButtonText() }}
                </v-btn>
                <!-- Ma trận dùng nút tạo bài tập riêng; không hiển thị nút import câu tiêu chuẩn với số 0 gây hiểu nhầm. -->
                <v-btn v-if="activeTab !== 'questions' || importMode !== 'SKILL_MATRIX'" color="primary" variant="flat"
                    :disabled="!selectedImportCount" @click="importSelected">
                    Import {{ selectedImportCount }} {{ activeTab === 'questions' ? 'câu đang chọn' : (interactiveVideosOnly ? 'video tương tác' : 'tài liệu') }}
                </v-btn>
            </v-card-actions>
        </v-card>

        <!-- Subdialog: Chọn từng câu hỏi cụ thể cho Nguồn nhóm / Mức độ nhận thức trong Ma trận -->
        <v-dialog v-model="isMatrixDetailDialogOpen" max-width="1100" scrollable>
            <v-card class="matrix-detail-dialog-card">
                <v-card-title class="d-flex align-center justify-space-between bg-primary text-white pa-3">
                    <div class="d-flex align-center ga-2">
                        <v-icon color="white">mdi-checkbox-multiple-marked-outline</v-icon>
                        <span class="font-weight-bold">
                            Chọn câu hỏi: {{ currentMatrixDetailSkill?.title }}
                            <span v-if="currentMatrixDetailSource?.groupTitle" class="text-caption font-weight-regular ml-1">({{ currentMatrixDetailSource.groupTitle }})</span>
                        </span>
                    </div>
                    <v-btn icon="mdi-close" variant="text" density="compact" color="white" @click="isMatrixDetailDialogOpen = false" />
                </v-card-title>
                <v-card-text class="pa-3 d-flex flex-column flex-grow-1 overflow-hidden matrix-detail-dialog-body">
                    <div class="d-flex align-center justify-space-between mb-2">
                        <span class="text-caption text-medium-emphasis">
                            <template v-if="currentMatrixDetailSource">
                                Đang hiển thị {{ (currentMatrixDetailSource.questions || []).length }} câu hỏi có sẵn từ nhóm <strong>{{ currentMatrixDetailSource.groupTitle || 'đã chọn' }}</strong> cho mức độ {{ currentMatrixDetailSkill?.title }}.
                            </template>
                            <template v-else>
                                Đang hiển thị {{ currentMatrixDetailSkill?.questions?.length || 0 }} câu hỏi có sẵn từ các nguồn nhóm đã chọn.
                            </template>
                        </span>
                        <div class="d-flex align-center ga-2">
                            <v-btn size="x-small" variant="text" color="success" @click="matrixDetailQuestions = (currentMatrixDetailSource ? (currentMatrixDetailSource.questions || []) : (currentMatrixDetailSkill?.questions || [])).filter(q => q._isMatchedCognitive)">
                                <v-icon start size="13">mdi-check-all</v-icon>Chọn câu đúng mức độ
                            </v-btn>
                            <v-btn size="x-small" variant="text" color="primary" @click="matrixDetailQuestions = [...(currentMatrixDetailSource ? (currentMatrixDetailSource.questions || []) : (currentMatrixDetailSkill?.questions || []))]">
                                Chọn tất cả
                            </v-btn>
                            <v-btn size="x-small" variant="text" color="grey" @click="matrixDetailQuestions = []">
                                Bỏ chọn hết
                            </v-btn>
                        </div>
                    </div>
                    <v-data-table-virtual :model-value="matrixDetailQuestions" @update:model-value="matrixDetailQuestions = $event"
                        :headers="questionHeaders" :items="currentMatrixDetailSource ? (currentMatrixDetailSource.questions || []) : (currentMatrixDetailSkill?.questions || [])" item-value="Id"
                        show-select return-object height="100%" item-height="58"
                        density="compact" class="border rounded content-hub-import-dialog__table">
                        <template #item.QuestionText="{ item }">
                            <div class="content-hub-question-preview py-1">
                                <div class="d-flex align-center ga-1 mb-1">
                                    <v-chip size="x-small" :color="item._isMatchedCognitive ? 'success' : 'grey'" variant="tonal" class="font-weight-medium">
                                        <v-icon start size="12">{{ item._isMatchedCognitive ? 'mdi-check-circle' : 'mdi-information-outline' }}</v-icon>
                                        {{ item._isMatchedCognitive ? `Đúng mức độ ${currentMatrixDetailSkill?.title || ''}` : 'Câu hỏi từ nhóm (chưa gắn đúng mức độ)' }}
                                    </v-chip>
                                </div>
                                <uc-latex-view v-if="getQuestionText(item)" :content="getQuestionText(item)" :escape-html="false" class="question-preview__text" />
                                <span v-else class="text-medium-emphasis">Chưa có nội dung</span>
                                <div v-if="getQuestionSkills(item).length" class="d-flex flex-wrap align-center ga-1 mt-1">
                                    <v-chip v-for="skill in getQuestionSkills(item)" :key="skill.id || skill.KyNang_MonHoc_ChiTietID || skill.name || skill.TenKyNang"
                                        size="x-small" color="indigo" variant="tonal">
                                        {{ skill.name || skill.TenKyNang || 'Kỹ năng' }}
                                    </v-chip>
                                </div>
                            </div>
                        </template>
                        <template #item.AnswerPreview="{ item }">
                            <div v-if="getQuestionAnswers(item).length" class="answer-preview py-1">
                                <div v-for="(answer, index) in getQuestionAnswers(item)" :key="answer.id || index" class="answer-preview__item">
                                    <span class="answer-preview__label">{{ answer.label || `${index + 1}.` }}</span>
                                    <uc-latex-view :content="answer.text || '—'" :escape-html="false" class="answer-preview__text" />
                                </div>
                            </div>
                            <span v-else class="text-medium-emphasis">—</span>
                        </template>
                        <template #item.Type="{ item }"><v-chip size="x-small" variant="tonal">{{ item.Type }}</v-chip></template>
                    </v-data-table-virtual>
                </v-card-text>
                <v-card-actions class="pa-3 border-t">
                    <span class="text-caption text-medium-emphasis">
                        Đã chọn <strong>{{ matrixDetailQuestions.length }}</strong> câu
                        <span v-if="currentMatrixDetailSource">cho nhóm {{ currentMatrixDetailSource.groupTitle }} (mức độ {{ currentMatrixDetailSkill?.title }})</span>
                        <span v-else>cho mức độ {{ currentMatrixDetailSkill?.title }}</span>
                    </span>
                    <v-spacer />
                    <v-btn variant="text" @click="isMatrixDetailDialogOpen = false">Đóng</v-btn>
                    <v-btn color="primary" variant="flat" @click="saveMatrixDetailSelection">
                        Xác nhận ({{ matrixDetailQuestions.length }} câu)
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <!-- Preview ảnh dùng URL binary FileData của LMS, không phụ thuộc URL googleusercontent đã hết hạn/quyền truy cập. -->
        <v-dialog v-model="imagePreviewDialog" max-width="1000" @update:model-value="onImagePreviewModelUpdate">
            <v-card class="content-hub-image-preview-dialog">
                <v-card-title class="d-flex align-center ga-2">
                    <span class="text-truncate">{{ imagePreviewTitle }}</span>
                    <v-spacer />
                    <v-btn icon="mdi-close" variant="text" @click="closeImagePreview" />
                </v-card-title>
                <v-card-text class="d-flex align-center justify-center pa-3">
                    <v-progress-circular v-if="imagePreviewLoading" indeterminate color="primary" />
                    <v-img v-else-if="imagePreviewUrl" :src="imagePreviewUrl" :alt="imagePreviewTitle" max-height="680" contain />
                    <div v-else class="text-medium-emphasis">Không có dữ liệu ảnh để hiển thị.</div>
                </v-card-text>
            </v-card>
        </v-dialog>
    </v-dialog>
</template>

<script>
	export default {
		name: 'uc-content-hub-import-dialog',
    inject: ['snackbarRef'],
    props: {
        modelValue: { type: Boolean, default: false },
        assignment: { type: Object, default: () => ({}) },
        // Cho phép module soạn bài học dùng lại dialog nhưng chỉ lấy tài liệu, không hiển thị ngân hàng câu hỏi.
        resource: { type: Object, default: null },
        documentsOnly: { type: Boolean, default: false },
        // Chỉ hiển thị tab Câu hỏi, ẩn hoàn toàn tab Tài liệu (ví dụ dành cho Soạn bài tập)
        questionsOnly: { type: Boolean, default: false },
        // Soạn bài tập chỉ cho phép gắn video có dữ liệu mốc/câu hỏi để không biến tài liệu thường thành phần có điểm.
        interactiveVideosOnly: { type: Boolean, default: false },
        // Pool là nghiệp vụ riêng của Soạn bài tập; mặc định tắt để Soạn học liệu chỉ import các câu được tick.
        allowQuestionPool: { type: Boolean, default: false },
        // Chế độ mở ban đầu hoặc cố định: 'STANDARD' (Tiêu chuẩn) hoặc 'SKILL_MATRIX' (Ma trận đề)
        initialImportMode: { type: String, default: 'STANDARD' },
        lockImportMode: { type: Boolean, default: false },
        // Danh sách các loại tài liệu cho phép nhận vào (VIDEO, DOCUMENT, AUDIO, IMAGE, HTML, ISPRING, INTERACTIVE_VIDEO)
        allowedDocumentTypes: {
            type: Array,
            default: () => ['VIDEO', 'DOCUMENT', 'AUDIO', 'IMAGE', 'HTML', 'ISPRING']
        },
    },
    emits: ['update:modelValue', 'import-question', 'import-question-pool', 'import-skill-matrix', 'import-document'],
    data() {
        return {
            // Xác định tab active ban đầu dựa trên prop cấu hình của từng module
            activeTab: this.questionsOnly ? 'questions' : (this.documentsOnly || this.interactiveVideosOnly ? 'documents' : 'documents'),
            // Chế độ import cho Soạn bài tập: STANDARD (Tiêu chuẩn theo Nhóm/File) hoặc SKILL_MATRIX (Ma trận Kỹ năng)
            importMode: 'STANDARD',
            questionGroups: [], questions: [], selectedQuestions: [], selectedGroupId: null,
            // Giá trị mặc định để hiển thị toàn bộ câu hỏi trong nhóm; bộ lọc file chỉ thu hẹp phạm vi khi người dùng chủ động chọn.
            selectedQuestionSourceFile: '__ALL_QUESTION_SOURCES__',
            // Giá trị lọc kỹ năng câu hỏi
            selectedQuestionSkill: '__ALL_SKILLS__',
            // Giá trị lọc loại tài liệu trong tab Tài liệu
            selectedDocumentTypeFilter: 'ALL',
            // Danh mục kỹ năng chính thức của Môn học lấy từ DB API
            subjectSkills: [],
            libraries: [], documents: [], sourceDocuments: [], selectedDocuments: [], selectedLibraryId: null,
            loadingGroups: false, loadingQuestions: false, loadingLibraries: false, loadingDocuments: false, loadingSkills: false,
            imagePreviewDialog: false, imagePreviewTitle: '', imagePreviewUrl: '', imagePreviewLoading: false,
            questionHeaders: [
                { title: 'Nội dung câu hỏi', key: 'QuestionText', sortable: false, width: 420 },
                { title: 'Đáp án đúng', key: 'AnswerPreview', sortable: false, width: 340 },
                { title: 'Loại', key: 'Type', width: 190, sortable: false },
                { title: 'Điểm', key: 'Points', width: 80, align: 'center' },
            ],
            // Mỗi mức độ có thể ghép nhiều nhóm; mỗi nguồn giữ số câu riêng để không làm mất quota theo nhóm.
            skillMatrixSources: {},
            matrixSelectedQuestionsMap: {},
            isMatrixDetailDialogOpen: false,
            currentMatrixDetailSkill: null,
            currentMatrixDetailSource: null,
            matrixDetailQuestions: [],
            targetTotalMatrixQuestions: null,
            groupQuestionsCache: {},
            documentHeaders: [
                { title: 'Tên tài liệu', key: 'TenNoiDung', sortable: false },
                { title: 'Người tạo', key: 'NguoiUploadName', width: 180, sortable: false },
                { title: 'Mã nhân viên', key: 'CreateUser', width: 120, sortable: false },
                { title: 'Thời gian tạo', key: 'CreateTime', width: 150, sortable: false },
                { title: 'Loại', key: 'LoaiNoiDung', width: 150, sortable: false },
                { title: '', key: 'actions', width: 60, sortable: false },
            ],
        }
    },
    computed: {
        contentContext() { return this.resource || this.assignment || {} },
        khoiId() { return Number(this.contentContext?.KhoiID || 0) },
        monHocId() { return Number(this.contentContext?.MonHocID || 0) },
        hasContext() { return this.khoiId > 0 && this.monHocId > 0 },
        selectedImportCount() { return this.activeTab === 'questions' ? this.selectedQuestions.length : this.selectedDocuments.length },
        selectedQuestionGroupTitle() {
            const group = this.questionGroups.find(item => String(item?.Id) === String(this.selectedGroupId))
            return group?.Title || 'đã chọn'
        },
        // Tập các ID câu hỏi đã có sẵn trong bài tập đang soạn (để cảnh báo trùng khi giáo viên chọn)
        existingAssignmentQuestionIds() {
            const groups = this.assignment?.AssignmentConfig?.groups || []
            const ids = new Set()
            groups.forEach(group => {
                (group.questions || []).forEach(q => {
                    const id = q?.sourceTracking?.questionId ?? q?.sourceTracking?.sourceQuestionId ?? q?.id
                    if (id !== undefined && id !== null) ids.add(String(id))
                })
            })
            return ids
        },
        questionSourceFiles() {
            if (!this.questions.length) return []
            const counts = this.questions.reduce((result, item) => {
                const name = this.getQuestionSourceFile(item)
                result[name] = (result[name] || 0) + 1
                return result
            }, {})
            const sourceItems = Object.keys(counts).sort((left, right) => left.localeCompare(right, 'vi')).map(value => ({
                value,
                title: value + ' (' + counts[value] + ' câu)',
            }))
            return [{ value: '__ALL_QUESTION_SOURCES__', title: 'Tất cả nguồn trong nhóm (' + this.questions.length + ' câu)' }, ...sourceItems]
        },
        // Trích xuất toàn bộ Kỹ năng: Gộp từ danh mục chuẩn của môn học và SkillsJson trên câu hỏi (Deduplicate theo tên chuẩn)
        questionSkillOptions() {
            const skillMap = new Map()

            // 1. Thêm từ danh mục chuẩn của môn học (Deduplicate theo Tên kỹ năng để tránh trùng giữa các nhóm kỹ năng)
            this.subjectSkills.forEach(skill => {
                const title = String(skill.TenKyNang || skill.name || '').trim()
                const key = String(skill.KyNang_MonHoc_ChiTietID || skill.id || title)
                if (title) {
                    const normTitle = title.toLowerCase()
                    if (!skillMap.has(normTitle)) {
                        skillMap.set(normTitle, { key, title, group: skill.NhomKyNang || '', count: 0, matchedKeys: new Set([key, title]) })
                    } else {
                        skillMap.get(normTitle).matchedKeys.add(key)
                        skillMap.get(normTitle).matchedKeys.add(title)
                    }
                }
            })

            // 2. Đếm số câu hỏi thực tế trong nhóm có gắn kỹ năng này
            this.questions.forEach(item => {
                const skills = this.getQuestionSkills(item)
                skills.forEach(skill => {
                    const title = String(skill.name || skill.TenKyNang || '').trim()
                    const key = String(skill.id || skill.KyNang_MonHoc_ChiTietID || title)
                    if (title) {
                        const normTitle = title.toLowerCase()
                        const existing = skillMap.get(normTitle) || { key, title, group: '', count: 0, matchedKeys: new Set([key, title]) }
                        existing.count += 1
                        existing.matchedKeys.add(key)
                        existing.matchedKeys.add(title)
                        skillMap.set(normTitle, existing)
                    }
                })
            })

            const sorted = Array.from(skillMap.values()).sort((a, b) => a.title.localeCompare(b.title, 'vi'))
            return [
                { value: '__ALL_SKILLS__', title: 'Tất cả kỹ năng (' + this.questions.length + ' câu)' },
                ...sorted.map(s => ({
                    value: s.key,
                    title: s.count > 0 ? `${s.title} (${s.count} câu)` : `${s.title} (0 câu)`,
                    rawTitle: s.title,
                    count: s.count,
                    matchedKeys: Array.from(s.matchedKeys)
                }))
            ]
        },
        isAllQuestionSources() {
            return !this.selectedQuestionSourceFile || this.selectedQuestionSourceFile === '__ALL_QUESTION_SOURCES__'
        },
        isAllQuestionSkills() {
            return !this.selectedQuestionSkill || this.selectedQuestionSkill === '__ALL_SKILLS__'
        },
        filteredQuestions() {
            let result = this.questions
            // Ở chế độ STANDARD: Lọc theo Nguồn file (mặc định lấy tất cả nguồn trong nhóm)
            if (this.importMode === 'STANDARD') {
                if (!this.isAllQuestionSources) {
                    result = result.filter(item => this.getQuestionSourceFile(item) === this.selectedQuestionSourceFile)
                }
            } else if (this.importMode === 'SKILL_MATRIX') {
                // Ở chế độ SKILL_MATRIX: Lọc theo Kỹ năng câu hỏi
                if (!this.isAllQuestionSkills) {
                    const selectedSkillOption = this.questionSkillOptions.find(opt => String(opt.value) === String(this.selectedQuestionSkill))
                    const validKeys = new Set(selectedSkillOption?.matchedKeys || [String(this.selectedQuestionSkill)])
                    result = result.filter(item => {
                        const skills = this.getQuestionSkills(item)
                        return skills.some(s => {
                            const key = String(s.id || s.KyNang_MonHoc_ChiTietID || '')
                            const name = String(s.name || s.TenKyNang || '').trim()
                            return validKeys.has(key) || validKeys.has(name)
                        })
                    })
                }
            }
            return result
        },
        questionPoolCount() { return this.filteredQuestions.length },
        // Đếm số câu hỏi trong pool đang hiển thị đã được tick chọn hoặc đã có trong bài tập
        duplicateQuestionCountInPool() {
            const selectedKeys = new Set(this.selectedQuestions.map(item => this.questionKey(item)))
            return this.filteredQuestions.filter(item => {
                const key = this.questionKey(item)
                return selectedKeys.has(key) || this.existingAssignmentQuestionIds.has(key)
            }).length
        },
        // Data table chỉ nhận các câu của nhóm/nguồn hiện tại; các câu ở nhóm khác vẫn được giữ trong selectedQuestions.
        visibleSelectedQuestions() {
            const selectedKeys = new Set(this.selectedQuestions.map(item => this.questionKey(item)))
            return this.filteredQuestions.filter(item => selectedKeys.has(this.questionKey(item)))
        },
        currentGroupSelectedCount() { return this.visibleSelectedQuestions.length },
        selectedQuestionGroupSummaries() {
            const summaries = new Map()
            this.selectedQuestions.forEach(item => {
                const id = this.questionGroupKey(item)
                const group = this.questionGroups.find(candidate => String(candidate?.Id) === id)
                const summary = summaries.get(id) || { id, title: group?.Title || `Nhóm ${id}`, count: 0 }
                summary.count += 1
                summaries.set(id, summary)
            })
            return Array.from(summaries.values())
        },
        // Danh sách 4 mức độ nhận thức quy chuẩn cho toàn bộ môn học phục vụ Ma trận đề
        availableMatrixSkills() {
            const cognitiveLevels = [
                {
                    key: 'cog_nhan_biet',
                    title: 'Nhận biết',
                    description: 'Nhớ lại, nhận ra hoặc nhắc lại các kiến thức, định nghĩa, sự kiện đã học',
                    matchedNames: ['nhận biết', 'nhan biet', 'nhận biết (nhớ lại)']
                },
                {
                    key: 'cog_thong_hieu',
                    title: 'Thông hiểu',
                    description: 'Diễn giải, giải thích, so sánh hoặc tóm tắt lại kiến thức bằng ngôn ngữ/cách hiểu của riêng mình',
                    matchedNames: ['thông hiểu', 'thong hieu', 'hiểu biết', 'thông hiểu (hiểu biết)']
                },
                {
                    key: 'cog_van_dung',
                    title: 'Vận dụng',
                    description: 'Dùng kiến thức, kỹ năng đã học để giải quyết các vấn đề, bài tập quen thuộc hoặc tình huống tương tự',
                    matchedNames: ['vận dụng', 'van dung', 'vận dụng thấp']
                },
                {
                    key: 'cog_van_dung_cao',
                    title: 'Vận dụng cao',
                    description: 'Dùng tổng hợp kiến thức, kỹ năng để giải quyết các vấn đề phức tạp, tư duy sáng tạo, suy luận logic',
                    matchedNames: ['vận dụng cao', 'van dung cao', 'nâng cao']
                }
            ]

            return cognitiveLevels.map(level => {
                const configuredSources = this.getSkillMatrixSources(level.key)
                const sourceDetails = configuredSources.map(source => {
                    const groupQuestions = this.getQuestionsForGroup(source.groupId)
                    const taggedQuestions = groupQuestions
                        .filter(item => this.matchesCognitiveLevel(item, level))
                        .map(item => ({ ...item, _matrixSourceId: source.id, _isMatchedCognitive: true }))
                    const untaggedQuestions = groupQuestions
                        .filter(item => !this.matchesCognitiveLevel(item, level))
                        .map(item => ({ ...item, _matrixSourceId: source.id, _isMatchedCognitive: false }))

                    // Tổng câu có sẵn trong nhóm nguồn để giáo viên có thể bốc ngẫu nhiên hoặc chọn đích danh bất kỳ câu nào
                    const availableQuestions = groupQuestions.map(item => ({
                        ...item,
                        _matrixSourceId: source.id,
                        _isMatchedCognitive: this.matchesCognitiveLevel(item, level)
                    }))

                    return {
                        ...source,
                        taggedCount: taggedQuestions.length,
                        taggedQuestions,
                        availableCount: groupQuestions.length,
                        totalQuestionsInGroup: groupQuestions.length,
                        questions: availableQuestions,
                    }
                })
                const seenQuestionIds = new Set()
                const allAvailableQuestions = sourceDetails.flatMap(source => source.questions.filter(item => {
                    const key = this.questionKey(item)
                    if (seenQuestionIds.has(key)) return false
                    seenQuestionIds.add(key)
                    return true
                }))
                const totalTaggedCount = sourceDetails.reduce((sum, s) => sum + s.taggedCount, 0)
                const totalAvailableCount = allAvailableQuestions.length

                return {
                    key: level.key,
                    title: level.title,
                    description: level.description,
                    group: 'Mức độ nhận thức',
                    taggedCount: totalTaggedCount,
                    sourceCount: sourceDetails.length,
                    totalQuestionsInGroup: sourceDetails.reduce((sum, source) => sum + source.totalQuestionsInGroup, 0),
                    availableCount: totalAvailableCount,
                    questions: allAvailableQuestions,
                    sources: sourceDetails,
                }
            })
        },
        // Tổng số câu hỏi được cấu hình bốc trong Ma trận kỹ năng
        totalMatrixConfigQuestions() {
            return this.availableMatrixSkills.reduce((sum, skill) => sum + this.getSkillConfiguredCount(skill.key), 0)
        },
        // Số lượng kỹ năng đã cấu hình bốc ít nhất 1 câu
        activeMatrixSkillsCount() {
            return this.availableMatrixSkills.filter(skill => this.getSkillConfiguredCount(skill.key) > 0).length
        },
        matrixTotalMatchColor() {
            const target = Number(this.targetTotalMatrixQuestions)
            const current = this.totalMatrixConfigQuestions
            if (!target || target <= 0) return 'indigo'
            if (current === target) return 'success'
            if (current < target) return 'warning'
            return 'error'
        },
        matrixTotalStatusText() {
            const target = Number(this.targetTotalMatrixQuestions)
            const current = this.totalMatrixConfigQuestions
            if (!target || target <= 0) {
                return `Tổng bốc: ${current} câu (${this.activeMatrixSkillsCount}/4 mức độ)`
            }
            if (current === target) {
                return `Đạt chuẩn: ${current}/${target} câu (100%)`
            }
            if (current < target) {
                return `Đang chọn: ${current}/${target} câu (còn thiếu ${target - current} câu)`
            }
            return `Vượt quá: ${current}/${target} câu (thừa ${current - target} câu)`
        },
        // Chặn cả giao diện lẫn event pool ở các module chỉ có nhu cầu chọn từng câu hỏi.
        canImportQuestionPool() {
            if (!this.allowQuestionPool || this.activeTab !== 'questions') return false
            if (this.importMode === 'SKILL_MATRIX') return this.totalMatrixConfigQuestions > 0
            return this.questionPoolCount > 0
        },
        // =========================================================================================
        // LOGIC PHÂN LOẠI & LỌC TÀI LIỆU CONTENT HUB THEO NGHIỆP VỤ TỪNG MODULE
        // =========================================================================================

        // Danh sách các loại tài liệu thực tế được phép nhận dựa theo cấu hình của module đang nhúng dialog:
        // - Soạn học liệu (soan-hoc-lieu-v2): ['DOCUMENT', 'VIDEO', 'AUDIO', 'HTML', 'ISPRING'] (loại bỏ IMAGE lẻ)
        // - Soạn bài học (lms_tc_lesson_builder): ['DOCUMENT', 'VIDEO', 'AUDIO', 'IMAGE', 'HTML', 'ISPRING']
        // - Soạn bài tập (lms_tc_asm_builder): ['INTERACTIVE_VIDEO'] nếu mở tài liệu hoặc questionsOnly = true
        effectiveAllowedDocumentTypes() {
            if (this.interactiveVideosOnly) return ['INTERACTIVE_VIDEO']
            if (Array.isArray(this.allowedDocumentTypes) && this.allowedDocumentTypes.length > 0) {
                return this.allowedDocumentTypes.map(t => String(t).toUpperCase())
            }
            return ['VIDEO', 'DOCUMENT', 'AUDIO', 'IMAGE', 'HTML', 'ISPRING']
        },

        // Danh sách tùy chọn cho dropdown lọc loại tài liệu:
        // Chỉ hiển thị các mục nằm trong danh sách được phép của module (effectiveAllowedDocumentTypes)
        documentTypeOptions() {
            const typeLabels = {
                ALL: 'Tất cả loại tài liệu',
                VIDEO: 'Video & Video tương tác',
                INTERACTIVE_VIDEO: 'Video tương tác',
                DOCUMENT: 'Tài liệu (PDF, Word, PPT, Excel)',
                AUDIO: 'Audio (Âm thanh)',
                IMAGE: 'Hình ảnh',
                HTML: 'HTML / Bài đọc',
                ISPRING: 'iSpring'
            }
            const allowed = new Set(this.effectiveAllowedDocumentTypes)
            const options = [{ value: 'ALL', title: typeLabels.ALL }]
            ;['DOCUMENT', 'VIDEO', 'AUDIO', 'IMAGE', 'HTML', 'ISPRING'].forEach(key => {
                if (allowed.has(key) || (key === 'VIDEO' && allowed.has('INTERACTIVE_VIDEO'))) {
                    options.push({ value: key, title: typeLabels[key] })
                }
            })
            return options
        },

        // Chỉ hiển thị dropdown bộ lọc loại tài liệu khi có từ 2 loại tài liệu trở lên được phép nhận
        showDocumentTypeFilter() {
            return !this.interactiveVideosOnly && this.documentTypeOptions.length > 2
        },

        // Lọc danh sách tài liệu hiển thị trong bảng:
        // 1. Chỉ loại bản ghi trùng cùng node/cùng lần sử dụng; không deduplicate chỉ theo FileID vì một file có thể được nhiều giáo viên dùng.
        // 2. Lọc cứng theo allowedDocumentTypes của module (ví dụ: loại bỏ hoàn toàn các file ảnh cắt lẻ .png, .jpg)
        // 3. Lọc động theo lựa chọn của người dùng trên dropdown selectedDocumentTypeFilter
        documentItems() {
            const items = [...(this.selectedLibraryId ? this.documents : []), ...this.sourceDocuments]
            const seen = new Set()
            const allowedSet = new Set(this.effectiveAllowedDocumentTypes)

            return items.filter(item => {
                const meta = this.getDocumentMeta(item)
                const fileKey = String(meta.fileId || meta.FILE_ID || item?.FileID || this.getRawDocumentSource(item) || this.getDocumentName(item))
                const nodeId = item?.NoiDungID
                const resourceId = item?.ResourceID
                // SourceFile_GetAll trả ResourceID theo Lesson/Assignment; giữ các dòng khác resource hoặc khác người tạo dù dùng cùng FileID.
                const key = nodeId
                    ? `node:${nodeId}`
                    : resourceId
                        ? `resource:${item?.ResourceType || ''}:${resourceId}:${fileKey}:${item?.ElementType || ''}:${item?.ElementSortOrder ?? ''}`
                        : `file:${fileKey}`
                if (seen.has(key)) return false
                seen.add(key)

                const typeCode = this.getDocumentTypeCode(item)

                // Bước 1: Kiểm tra loại tài nguyên có thuộc danh sách module hỗ trợ không
                if (allowedSet.size > 0) {
                    const isAllowed = allowedSet.has(typeCode) || (typeCode === 'INTERACTIVE_VIDEO' && (allowedSet.has('VIDEO') || allowedSet.has('INTERACTIVE_VIDEO')))
                    if (!isAllowed) return false
                }

                // Bước 2: Kiểm tra theo bộ lọc người dùng đang chọn trên giao diện
                if (this.selectedDocumentTypeFilter && this.selectedDocumentTypeFilter !== 'ALL') {
                    if (this.selectedDocumentTypeFilter === 'VIDEO') {
                        if (typeCode !== 'VIDEO' && typeCode !== 'INTERACTIVE_VIDEO') return false
                    } else if (typeCode !== this.selectedDocumentTypeFilter) {
                        return false
                    }
                }
                return true
            })
        },
    },
    watch: {
        modelValue(value) {
            if (value) {
                if (this.initialImportMode) this.importMode = this.initialImportMode
                this.loadContentHub()
            }
        },
        initialImportMode(value) {
            if (value) this.importMode = value
        },
        selectedGroupId() { this.selectedQuestionSourceFile = '__ALL_QUESTION_SOURCES__'; this.selectedQuestionSkill = '__ALL_SKILLS__'; this.loadQuestions() },
        selectedLibraryId() { this.loadDocuments() },
        documentsOnly(value) {
            if (value) this.activeTab = 'documents'
            if (this.modelValue) this.loadContentHub()
        },
        questionsOnly(value) {
            if (value) this.activeTab = 'questions'
            if (this.modelValue) this.loadContentHub()
        },
        imagePreviewDialog(value) {
            if (!value) this.clearImagePreview()
        },
    },
    methods: {
        rows(response) {
            const value = response?.data ?? response ?? []
            if (Array.isArray(value?.[0]) && value.length === 1) return value[0]
            return Array.isArray(value) ? value.flat() : [value]
        },
        questionKey(item) {
            return String(item?.Id ?? item?.ID ?? item?.QuestionId ?? '')
        },
        questionGroupKey(item) {
            return String(item?._contentHubGroupId ?? item?.GroupId ?? item?.GroupID ?? 'unknown')
        },
        // Merge lựa chọn của bảng hiện tại vào danh sách tổng thay vì để data table thay thế các câu ở nhóm trước.
        onVisibleQuestionSelectionUpdate(value) {
            const visibleKeys = new Set(this.filteredQuestions.map(item => this.questionKey(item)))
            const retained = this.selectedQuestions.filter(item => !visibleKeys.has(this.questionKey(item)))
            const itemByKey = new Map(this.filteredQuestions.map(item => [this.questionKey(item), item]))
            const nextVisible = []
            const seen = new Set(retained.map(item => this.questionKey(item)))
            ;(Array.isArray(value) ? value : []).forEach(valueItem => {
                const key = this.questionKey(valueItem)
                const item = itemByKey.get(key) || (typeof valueItem === 'object' ? valueItem : null)
                if (item && !seen.has(key)) {
                    nextVisible.push(item)
                    seen.add(key)
                }
            })
            this.selectedQuestions = [...retained, ...nextVisible]
        },
        async loadContentHub() {
            this.selectedQuestions = []; this.selectedDocuments = []; this.sourceDocuments = []; this.selectedQuestionSourceFile = '__ALL_QUESTION_SOURCES__'
            this.selectedDocumentTypeFilter = 'ALL'
            if (!this.hasContext) return
            // Bài tập cần tải cả ngân hàng câu hỏi và video tương tác; tất cả loader đều dùng Khối/Môn của bài đang soạn.
            const loaders = []
            if (!this.questionsOnly) loaders.push(this.loadLibraries())
            if (!this.documentsOnly) {
                loaders.push(this.loadGroups())
                loaders.push(this.loadSubjectSkills())
            }
            await Promise.all(loaders)
            this.ensureQuestionSourceSelection()
        },
        async loadSubjectSkills() {
            if (!this.monHocId) { this.subjectSkills = []; return }
            this.loadingSkills = true
            try {
                const groupResult = await fetchPromise('lms/EL_KyNang_MonHoc_Get', { MonHocID: this.monHocId }, { forceRefresh: true, useStaleCacheOnError: false })
                const groups = Array.isArray(groupResult?.[0]) ? groupResult[0] : (Array.isArray(groupResult) ? groupResult : [])
                const detailResults = await Promise.all(groups.map(group => fetchPromise('lms/EL_KyNang_MonHoc_ChiTiet_Get', { KyNang_MonHocID: group.KyNang_MonHocID }, { forceRefresh: true, useStaleCacheOnError: false })))
                this.subjectSkills = detailResults.flatMap((result, index) => {
                    const details = Array.isArray(result?.[0]) ? result[0] : (Array.isArray(result) ? result : [])
                    return details.map(skill => ({ ...skill, NhomKyNang: skill.NhomKyNang || groups[index]?.NhomKyNang || '' }))
                })
            } catch (error) {
                this.subjectSkills = []
            } finally { this.loadingSkills = false }
        },
        async loadGroups() {
            this.loadingGroups = true
            try {
                const result = await fetchPromise('lms/EL_QuestionGroup_List', { KhoiID: this.khoiId, MonHocID: this.monHocId, IncludeDeleted: false, PageNumber: 1, PageSize: 100 }, { forceRefresh: true })
                this.questionGroups = this.rows(result).filter(item => item?.Id)
                this.selectedGroupId = this.questionGroups[0]?.Id || null
                await this.loadQuestions()
            } catch (error) {
                this.questionGroups = []
                this.notify(error?.Message || error?.message || 'Không thể tải nhóm câu hỏi Content Hub.', 'error')
            } finally { this.loadingGroups = false }
        },
        async loadQuestions() {
            if (!this.selectedGroupId) { this.questions = []; this.selectedQuestionSourceFile = '__ALL_QUESTION_SOURCES__'; return }
            this.loadingQuestions = true
            try {
                const groupId = this.selectedGroupId
                const result = await fetchPromise('lms/EL_Question_List', { GroupId: this.selectedGroupId, Type: '', Search: '', IncludeDeleted: false, PageNumber: 1, PageSize: 200 }, { forceRefresh: true })
                // Gắn group id nội bộ để thống kê vẫn đúng khi câu đã chọn được giữ lại sau khi chuyển nhóm.
                const loaded = this.rows(result).map(item => ({
                    ...item,
                    _contentHubGroupId: item.GroupId ?? item.GroupID ?? groupId,
                    ParsedConfig: this.normalizeImportedConfig(item.Type, this.parseJson(item.ConfigJson, {})),
                }))
                this.questions = loaded
                this.groupQuestionsCache[groupId] = loaded
                this.ensureQuestionSourceSelection()
            } catch (error) {
                this.questions = []
                this.selectedQuestionSourceFile = null
                this.notify(error?.Message || error?.message || 'Không thể tải câu hỏi Content Hub.', 'error')
            } finally { this.loadingQuestions = false }
        },
        getQuestionsForGroup(groupId) {
            if (!groupId) return []
            if (groupId === this.selectedGroupId) return this.questions
            return this.groupQuestionsCache[groupId] || []
        },
        getSkillMatrixSources(skillKey) {
            const configured = this.skillMatrixSources?.[skillKey]
            if (Array.isArray(configured) && configured.length) return configured
            return [{ id: `${skillKey}_source_0`, groupId: this.selectedGroupId, count: 0 }]
        },
        getSkillConfiguredCount(skillKey) {
            return this.getSkillMatrixSources(skillKey).reduce((sum, source) => sum + Math.max(Number(source.count) || 0, 0), 0)
        },
        getMatrixSourceAvailableCount(skillKey, sourceId) {
            const skill = this.availableMatrixSkills.find(item => item.key === skillKey)
            return skill?.sources?.find(source => source.id === sourceId)?.availableCount || 0
        },
        updateSkillMatrixSources(skillKey, sources) {
            this.skillMatrixSources = { ...this.skillMatrixSources, [skillKey]: sources }
            this.matrixSelectedQuestionsMap = { ...this.matrixSelectedQuestionsMap, [skillKey]: [] }
        },
        createMatrixSource(skillKey, index = 0) {
            return { id: `${skillKey}_source_${Date.now()}_${index}`, groupId: null, count: 0 }
        },
        addMatrixSource(skillKey) {
            const sources = [...this.getSkillMatrixSources(skillKey)]
            sources.push(this.createMatrixSource(skillKey, sources.length))
            this.updateSkillMatrixSources(skillKey, sources)
        },
        removeMatrixSource(skillKey, sourceId) {
            const sources = this.getSkillMatrixSources(skillKey).filter(source => source.id !== sourceId)
            this.updateSkillMatrixSources(skillKey, sources.length ? sources : [this.createMatrixSource(skillKey)])
        },
        onMatrixSourceCountChange(skillKey, sourceId, value) {
            const sources = this.getSkillMatrixSources(skillKey).map(source => {
                if (source.id !== sourceId) return source
                const available = this.getMatrixSourceAvailableCount(skillKey, sourceId)
                return { ...source, count: Math.min(Math.max(Number(value) || 0, 0), available) }
            })
            this.skillMatrixSources = { ...this.skillMatrixSources, [skillKey]: sources }
        },
        async onMatrixSourceGroupChange(skillKey, sourceId, groupId) {
            const sources = this.getSkillMatrixSources(skillKey).map(source => source.id === sourceId
                ? { ...source, groupId, count: 0 }
                : source)
            this.updateSkillMatrixSources(skillKey, sources)
            if (groupId && !this.groupQuestionsCache[groupId]) {
                try {
                    const result = await fetchPromise('lms/EL_Question_List', { GroupId: groupId, Type: '', Search: '', IncludeDeleted: false, PageNumber: 1, PageSize: 200 }, { forceRefresh: true })
                    const loaded = this.rows(result).map(item => ({
                        ...item,
                        _contentHubGroupId: item.GroupId ?? item.GroupID ?? groupId,
                        ParsedConfig: this.normalizeImportedConfig(item.Type, this.parseJson(item.ConfigJson, {})),
                    }))
                    this.groupQuestionsCache = { ...this.groupQuestionsCache, [groupId]: loaded }
                } catch (error) {
                    this.notify(error?.Message || error?.message || 'Không thể tải câu hỏi cho nhóm đã chọn.', 'error')
                }
            }
        },
        fillSkillMatrixSources(skillKey) {
            const skill = this.availableMatrixSkills.find(item => item.key === skillKey)
            const sources = this.getSkillMatrixSources(skillKey).map(source => {
                const detail = skill?.sources?.find(item => item.id === source.id)
                return { ...source, count: detail?.availableCount || 0 }
            })
            this.skillMatrixSources = { ...this.skillMatrixSources, [skillKey]: sources }
        },
        async loadLibraries() {
            this.loadingLibraries = true
            try {
                // GetAll/GetTree lấy kho Content Hub; SourceFile_GetAll lấy thêm các file lịch sử cùng Khối/Môn.
                const [libraryResult, sourceFileResult] = await Promise.all([
                    fetchPromise('lms/FP_TaiNguyen_GetAll', { KhoiID: this.khoiId, MonHocID: this.monHocId, TaiNguyenLoaiID: 0, TaiNguyenMucID: 0 }, { forceRefresh: true }),
                    fetchPromise('lms/FP_TaiNguyen_SourceFile_GetAll', { KhoiID: this.khoiId, MonHocID: this.monHocId }, { forceRefresh: true, useStaleCacheOnError: false }),
                ])
                const all = this.rows(libraryResult)
                // HTML được lưu inline trong DataJson.htmlContent nên không có URL; vẫn phải đưa vào danh sách import.
                this.sourceDocuments = this.rows(sourceFileResult).filter(item => this.hasDocumentContent(item))
                // Không fallback sang kho bất kỳ khi context rỗng: người soạn chỉ được import đúng tài nguyên thuộc Khối/Môn của bài.
                const contextual = all.filter(item => Number(item.KhoiID) === this.khoiId && Number(item.MonHocID) === this.monHocId)
                this.libraries = contextual.filter(item => {
                    const type = String(item.TaiNguyenLoaiCode || '').toUpperCase()
                    return !type || ['TAI_LIEU_THAM_KHAO', 'SANG_KIEN'].includes(type)
                })
                this.selectedLibraryId = this.libraries[0]?.HocLieuID || null
                await this.loadDocuments()
            } catch (error) {
                this.libraries = []; this.documents = []; this.sourceDocuments = []
                this.notify(error?.Message || error?.message || 'Không thể tải kho tài liệu Content Hub.', 'error')
            } finally { this.loadingLibraries = false }
        },
        async loadDocuments() {
            if (!this.selectedLibraryId) { this.documents = []; return }
            this.loadingDocuments = true
            try {
                const result = await fetchPromise('lms/FP_TaiNguyen_GetTree', { HocLieuID: this.selectedLibraryId }, { forceRefresh: true })
                // Không dùng URL làm điều kiện duy nhất: tài liệu HTML hợp lệ có thể chỉ tồn tại dưới dạng htmlContent.
                this.documents = this.rows(result).filter(item => item?.LoaiNoiDung && item.LoaiNoiDung !== 'THU_MUC' && this.hasDocumentContent(item))
            } catch (error) {
                this.documents = []
                this.notify(error?.Message || error?.message || 'Không thể tải tài liệu Content Hub.', 'error')
            } finally { this.loadingDocuments = false }
        },
        parseJson(value, fallback = {}) {
            if (value && typeof value === 'object') return value
            try { return typeof value === 'string' && value.trim() ? JSON.parse(value) : fallback } catch { return fallback }
        },
        getQuestionText(item) {
            const config = item?.ParsedConfig || this.parseJson(item?.ConfigJson, {})
            const value = item?.QuestionText || config.questionText || config.prompt || ''
            if (typeof value === 'string') return value
            return value?.html || value?.content || value?.text || ''
        },
        getQuestionSourceFile(item) {
            const config = item?.ParsedConfig || this.parseJson(item?.ConfigJson, {})
            const raw = this.parseJson(item?.RawJson, {})
            const tracking = config?.sourceTracking || {}
            const directCandidates = [
                item?.SourceFileName,
                item?.FileName,
                item?.TenFile,
                item?._sourceFileName,
                tracking.sourceFileName,
                tracking.fileName,
                config.sourceFileName,
                raw?.sourceFileName,
                raw?.fileName,
                raw?.FileName,
            ]
            const directName = directCandidates.find(value => String(value || '').trim())
            if (directName) return String(directName).trim()

            // Dữ liệu cũ đôi khi chỉ lưu ID node trong sourceTracking/SourceId; dò ngược sang danh sách file đã tải để lấy đúng tên.
            const sourceIdMatch = String(item?.SourceId || '').match(/^HOC_LIEU_SO_\d+_(\d+)/i)
            const sourceNodeId = tracking.NoiDungID || tracking.nodeId || item?.SourceNoiDungID || sourceIdMatch?.[1]
            const sourceDocument = this.sourceDocuments.find(document => String(document?.NoiDungID || document?.FileID || '') === String(sourceNodeId || ''))
            return sourceDocument ? this.getDocumentName(sourceDocument) : 'Chưa xác định'
        },
        ensureQuestionSourceSelection() {
            const availableValues = this.questionSourceFiles.map(item => item.value)
            if (!availableValues.length) {
                this.selectedQuestionSourceFile = null
                return
            }
            if (!availableValues.includes(this.selectedQuestionSourceFile)) this.selectedQuestionSourceFile = '__ALL_QUESTION_SOURCES__'
        },
        getQuestionImages(item) {
            const config = item?.ParsedConfig || this.parseJson(item?.ConfigJson, {})
            const images = config?.media?.sourceFiles?.image || config?.media?.images || config?.images || []
            return Array.isArray(images) ? images.filter(image => this.imageSource(image)) : []
        },
        imageSource(image) {
            const source = image?.externalSource || image?.source || image?.url || ''
            if (!source) return ''
            if (!source.includes('drive.google.com')) return this.fileSource(image)
            const driveId = image.externalId || image.id || this.getDriveFileId(source)
            return driveId ? `https://drive.google.com/thumbnail?id=${driveId}&sz=w1000` : source
        },
        fileSource(file) {
            const source = file?.externalSource || file?.source || file?.url || ''
            if (!source) return ''
            if (/^https?:\/\/lms\.lhbs\.vn\/FileData\//i.test(source)) {
                return source.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/')
            }
            if (/^https?:\/\//i.test(source) || file?.mediaSource !== 'db') return source
            const base = vueData?.v_Set?.urlReadFile || ''
            return base ? `${base.replace(/\/+$/, '')}/${source.replace(/^\/+/, '')}` : source
        },
        getDriveFileId(url) {
            // Hỗ trợ cả hai dạng URL Drive thường gặp: /file/d/{id}/preview và ?id={id}.
            const match = String(url || '').match(/(?:\/d\/|[?&]id=)([^/?&#]+)/i)
            return match ? match[1] : ''
        },
        getQuestionAnswers(item) {
            const config = item?.ParsedConfig || this.parseJson(item?.ConfigJson, {})
            const type = item?.Type
            if (type === 'QUIZ_TRUE_FALSE') {
                if (config.correctAnswer !== true && config.correctAnswer !== false) return []
                return [{ id: 'true-false', text: config.correctAnswer ? 'Đúng' : 'Sai', correct: true }]
            }
            if (type === 'QUIZ_MATCHING' || type === 'QUIZ_MATCHING_V2') {
                const columnA = Array.isArray(config.columnA) ? config.columnA : []
                const columnB = Array.isArray(config.columnB) ? config.columnB : []
                const itemById = new Map([...columnA, ...columnB].map(entry => [String(entry?.id), entry]))
                return (Array.isArray(config.correctPairs) ? config.correctPairs : []).map((pair, index) => {
                    // Content Hub lưu cặp nối theo from/to; vẫn hỗ trợ aId/bId của schema cũ.
                    const left = itemById.get(String(pair?.aId ?? pair?.leftId ?? pair?.sourceId ?? pair?.from ?? ''))
                    const right = itemById.get(String(pair?.bId ?? pair?.rightId ?? pair?.targetId ?? pair?.to ?? ''))
                    if (!left || !right) return null
                    return { id: pair.id || index, label: `${index + 1}.`, text: `${this.getAnswerText(left)} → ${this.getAnswerText(right)}`, correct: true }
                }).filter(Boolean)
            }
            const options = Array.isArray(config.options) ? config.options : []
            if (options.length) {
                // Dạng Đúng/Sai nhiều chỉ cần xem key theo từng ý, không render lại nội dung mệnh đề dài trong cột đáp án.
                if (item?.Type === 'QUIZ_MULTIPLE_TRUE_FALSE') {
                    return options.map((option, index) => ({
                        id: option.id || index,
                        label: `${String.fromCharCode(65 + index)}.`,
                        text: option.correctAnswer === true ? 'Đ' : (option.inCorrectAnswer === true ? 'S' : '—'),
                        correct: false,
                        compact: true,
                        compactStatus: option.correctAnswer === true ? 'true' : (option.inCorrectAnswer === true ? 'false' : 'unset'),
                    }))
                }

                // Chỉ preview đáp án đúng; toàn bộ options vẫn được giữ nguyên trong payload khi import.
                return options.reduce((answers, option, index) => {
                    if (this.isCorrectAnswer(item, option)) {
                        answers.push({
                            id: option.id || index,
                            label: `${String.fromCharCode(65 + index)}.`,
                            text: this.getAnswerText(option),
                            correct: true,
                        })
                    }
                    return answers
                }, [])
            }

            // Câu điền khuyết có cả schema mới (acceptedAnswers) và dữ liệu Content Hub cũ
            // (correctAnswer/answer). Đọc cả hai để preview khớp với dữ liệu sẽ import.
            const parts = Array.isArray(config.parts) ? config.parts : []
            const acceptedAnswers = parts.flatMap(part => this.getBlankAcceptedAnswers(part))
            if (acceptedAnswers.length) return acceptedAnswers.map((answer, index) => ({ id: index, text: String(answer), correct: true }))

            const correctAnswers = Array.isArray(config.correctAnswers)
                ? config.correctAnswers
                : (config.correctAnswer !== undefined && config.correctAnswer !== null ? [config.correctAnswer] : [])
            return correctAnswers.map((answer, index) => ({ id: index, text: String(answer), correct: true }))
        },
        getBlankAcceptedAnswers(part) {
            const values = Array.isArray(part?.acceptedAnswers)
                ? part.acceptedAnswers
                : (part?.acceptedAnswers != null
                    ? [part.acceptedAnswers]
                    : [part?.correctAnswer, part?.answer, part?.value])
            return values
                .map(answer => this.getAnswerText(answer).trim())
                .filter(Boolean)
        },
        normalizeImportedConfig(type, config) {
            const normalized = { ...(config || {}) }
            if (type === 'QUIZ_SINGLE_CHOICE' && normalized.correctAnswer && typeof normalized.correctAnswer === 'object') {
                normalized.correctAnswer = normalized.correctAnswer.id ?? normalized.correctAnswer.value
            }
            if (type === 'QUIZ_MULTIPLE_CHOICE' && Array.isArray(normalized.correctAnswers)) {
                normalized.correctAnswers = normalized.correctAnswers.map(answer => typeof answer === 'object' ? (answer.id ?? answer.value) : answer).filter(answer => answer !== undefined && answer !== null)
            }
            if (type === 'QUIZ_MATCHING' || type === 'QUIZ_MATCHING_V2') {
                normalized.correctPairs = (Array.isArray(normalized.correctPairs) ? normalized.correctPairs : []).map(pair => ({
                    ...pair,
                    // Chuẩn hóa alias để bảng preview và payload import đọc cùng một cấu trúc.
                    aId: pair?.aId ?? pair?.leftId ?? pair?.sourceId ?? pair?.from,
                    bId: pair?.bId ?? pair?.rightId ?? pair?.targetId ?? pair?.to,
                }))
            }
            if (type !== 'QUIZ_FILL_IN_BLANK' || !Array.isArray(normalized.parts)) return normalized
            normalized.parts = normalized.parts.map((part, index) => {
                if (!part || typeof part !== 'object') return part
                const isBlank = String(part.type || '').toLowerCase() === 'blank' || part.isBlank === true || part.kind === 'blank'
                if (!isBlank) return part
                const acceptedAnswers = this.getBlankAcceptedAnswers(part)
                return {
                    ...part,
                    type: 'blank',
                    id: part.id || `blank_${index + 1}`,
                    acceptedAnswers,
                    // Giữ trường cũ để các viewer cũ vẫn đọc được, đồng thời đảm bảo
                    // component chấm bài dùng được acceptedAnswers.
                    correctAnswer: this.getAnswerText(part.correctAnswer ?? part.answer ?? acceptedAnswers[0]).trim(),
                }
            })
            return normalized
        },
        getAnswerText(option) {
            if (typeof option === 'string' || typeof option === 'number') return String(option)
            const value = option?.text ?? option?.label ?? option?.value ?? option?.content ?? ''
            if (typeof value === 'string') return value
            return value?.html || value?.content || value?.text || ''
        },
        isCorrectAnswer(item, option) {
            const config = item?.ParsedConfig || this.parseJson(item?.ConfigJson, {})
            const sameId = (left, right) => String(left) === String(right)
            if (item?.Type === 'QUIZ_MULTIPLE_TRUE_FALSE' || item?.Type === 'QUIZ_TRUE_FALSE') {
                if (option.correctAnswer !== undefined || option.isTrue !== undefined) return option.correctAnswer === true || option.isTrue === true
            }
            if (Array.isArray(config.correctAnswers)) return config.correctAnswers.some(answer => sameId(answer, option.id))
            if (config.correctAnswer !== undefined && config.correctAnswer !== null) return sameId(config.correctAnswer, option.id)
            return option.correctAnswer === true || option.isTrue === true
        },
        parseQuestion(item) {
            const config = this.normalizeImportedConfig(item?.Type, this.parseJson(item?.ConfigJson, {}))
            const skills = this.parseJson(item?.SkillsJson, [])
            const type = item.Type
            const sourceFileName = this.getQuestionSourceFile(item)
            const sourceTracking = { ...(config.sourceTracking || {}), sourceType: 'CONTENT_HUB', sourceKind: 'QUESTION_BANK', questionId: item.Id, groupId: item.GroupId, importedAt: new Date().toISOString() }
            if (sourceFileName !== 'Chưa xác định') sourceTracking.sourceFileName = sourceFileName
            return {
                id: `q_${crypto.randomUUID()}`, type, label: type, points: Number(item.Points || 1),
                gradingType: item.GradingType || (type?.startsWith('QUIZ_') ? 'auto' : 'manual'), skills: Array.isArray(skills) ? skills : [],
                config: { ...config, questionText: this.getQuestionText(item), isAdvanced: Boolean(item.IsAdvanced || config.isAdvanced), media: config.media || { type: 'YOUTUBE', sourceYT: { id: '', name: '', source: '' }, sourceRecord: { id: '', name: '', source: '' }, sourceFiles: { file: [], image: [] } } },
                sourceTracking,
            }
        },
        getQuestionSkills(item) {
            const skills = this.parseJson(item?.SkillsJson, [])
            if (Array.isArray(skills)) {
                return skills.map(skill => {
                    if (typeof skill === 'object' && skill !== null) return skill
                    return { id: skill, name: String(skill) }
                }).filter(Boolean)
            }
            return []
        },
        // Kiểm tra câu hỏi có bị trùng lặp (đã được tick chọn ở nhóm/kỹ năng khác, hoặc đã có sẵn trong bài tập)
        getQuestionDuplicateStatus(item) {
            const key = this.questionKey(item)
            const isAlreadyInAssignment = this.existingAssignmentQuestionIds.has(key)
            if (isAlreadyInAssignment) {
                return {
                    text: 'Đã có trong bài tập',
                    color: 'warning',
                    icon: 'mdi-alert-circle-outline',
                }
            }
            // Kiểm tra xem câu này có nằm trong danh sách đã tick chọn (khi đang lọc kỹ năng khác)
            const isSelected = this.selectedQuestions.some(q => this.questionKey(q) === key)
            if (isSelected) {
                return {
                    text: 'Đã chọn',
                    color: 'success',
                    icon: 'mdi-check-circle-outline',
                }
            }
            return null
        },
        getCognitiveChipColor(title) {
            const map = {
                'Nhận biết': 'info',
                'Thông hiểu': 'teal',
                'Vận dụng': 'orange',
                'Vận dụng cao': 'deep-purple'
            }
            return map[title] || 'indigo'
        },
        getSelectedSkillTitle() {
            const option = this.questionSkillOptions.find(opt => String(opt.value) === String(this.selectedQuestionSkill))
            return option?.rawTitle || option?.title || 'Kỹ năng'
        },
        // Nhận diện mức độ theo tên kỹ năng hoặc nhóm kỹ năng; loại trừ Vận dụng cao khỏi Vận dụng vì chuỗi "vận dụng" là tiền tố chung.
        matchesCognitiveLevel(item, level) {
            const values = this.getQuestionSkills(item).flatMap(skill => [
                skill?.name,
                skill?.TenKyNang,
                skill?.NhomKyNang,
                skill?.group,
            ]).map(value => String(value || '').trim().toLowerCase())
            return values.some(value => {
                if (!value) return false
                if (level.key === 'cog_van_dung' && (value.includes('vận dụng cao') || value.includes('van dung cao'))) return false
                return level.matchedNames.some(name => value.includes(name))
            })
        },
        // Tính tỷ lệ thực tế do người dùng tự chia; tổng số câu chỉ là mẫu số để kiểm tra, không tự ghi số câu vào từng mức độ.
        getSkillPercent(item) {
            const count = this.getSkillConfiguredCount(item.key)
            const target = Number(this.targetTotalMatrixQuestions)
            const totalPicked = this.totalMatrixConfigQuestions

            // Khi đã nhập tổng đề: hiển thị tỷ lệ người dùng đã nhập trên tổng đó.
            if (target > 0) {
                return Math.round((count / target) * 100)
            }
            // Nếu chưa nhập tổng đề nhưng đã nhập số câu: hiển thị tỷ lệ trong tổng số câu đang bốc.
            if (totalPicked > 0) {
                return Math.round((count / totalPicked) * 100)
            }
            return 0
        },
        resetMatrixConfigs() {
            this.skillMatrixSources = {}
            this.matrixSelectedQuestionsMap = {}
        },
        openMatrixDetailDialog(skillItem) {
            this.currentMatrixDetailSkill = skillItem
            this.currentMatrixDetailSource = null
            const previouslySelected = this.matrixSelectedQuestionsMap[skillItem.key] || []
            const selectedIds = new Set(previouslySelected.map(q => this.questionKey(q)))
            this.matrixDetailQuestions = (skillItem.questions || []).filter(q => selectedIds.has(this.questionKey(q)))
            this.isMatrixDetailDialogOpen = true
        },
        openMatrixSourceDetailDialog(skillKey, sourceId) {
            const skill = this.availableMatrixSkills.find(item => item.key === skillKey)
            if (!skill) return
            const sourceDetail = skill.sources?.find(item => item.id === sourceId)
            if (!sourceDetail) return
            const group = this.questionGroups.find(g => String(g.Id) === String(sourceDetail.groupId))
            this.currentMatrixDetailSkill = skill
            this.currentMatrixDetailSource = {
                ...sourceDetail,
                skillKey,
                groupTitle: group?.Title || (sourceDetail.groupId ? `Nhóm ${sourceDetail.groupId}` : 'Chưa chọn nhóm')
            }
            const previouslySelectedIds = new Set((sourceDetail.selectedQuestionIds || []).map(String))
            this.matrixDetailQuestions = (sourceDetail.questions || []).filter(q => previouslySelectedIds.has(this.questionKey(q)))
            this.isMatrixDetailDialogOpen = true
        },
        saveMatrixDetailSelection() {
            if (!this.currentMatrixDetailSkill) return
            const skillKey = this.currentMatrixDetailSkill.key

            // Trường hợp 1: Chọn câu hỏi cho một nguồn nhóm cụ thể
            if (this.currentMatrixDetailSource) {
                const sourceId = this.currentMatrixDetailSource.id
                const selectedIds = this.matrixDetailQuestions.map(q => this.questionKey(q))
                const sources = this.getSkillMatrixSources(skillKey).map(source => {
                    if (source.id !== sourceId) return source
                    return {
                        ...source,
                        selectedQuestionIds: selectedIds,
                        count: selectedIds.length
                    }
                })
                this.skillMatrixSources = { ...this.skillMatrixSources, [skillKey]: sources }
                this.isMatrixDetailDialogOpen = false
                return
            }

            // Trường hợp 2: Chọn câu hỏi cấp Mức độ nhận thức (tất cả các nguồn)
            this.matrixSelectedQuestionsMap = {
                ...this.matrixSelectedQuestionsMap,
                [skillKey]: [...this.matrixDetailQuestions]
            }
            const selectedBySource = new Map()
            const selectedIdsBySource = new Map()
            this.matrixDetailQuestions.forEach(question => {
                const sourceId = question?._matrixSourceId || this.getSkillMatrixSources(skillKey)[0]?.id
                selectedBySource.set(sourceId, (selectedBySource.get(sourceId) || 0) + 1)
                if (!selectedIdsBySource.has(sourceId)) selectedIdsBySource.set(sourceId, [])
                selectedIdsBySource.get(sourceId).push(this.questionKey(question))
            })
            const sources = this.getSkillMatrixSources(skillKey).map(source => ({
                ...source,
                selectedQuestionIds: selectedIdsBySource.get(source.id) || [],
                count: selectedBySource.get(source.id) || 0,
            }))
            this.skillMatrixSources = { ...this.skillMatrixSources, [skillKey]: sources }
            this.isMatrixDetailDialogOpen = false
        },
        getImportPoolButtonText() {
            if (this.importMode === 'SKILL_MATRIX') {
                return `Tạo bài tập ma trận (${this.totalMatrixConfigQuestions} câu bốc / ${this.activeMatrixSkillsCount} mức độ)`
            }
            return `Lấy toàn bộ ${this.isAllQuestionSources ? 'câu trong nhóm' : 'câu trong file'} (${this.questionPoolCount} câu)`
        },
        getQuestionSourceDescriptor(items) {
            const questions = Array.isArray(items) ? items : []
            const first = questions[0] || {}
            const isSkillFiltered = this.importMode === 'SKILL_MATRIX' && this.selectedQuestionSkill && this.selectedQuestionSkill !== '__ALL_SKILLS__'
            const isAllSources = this.isAllQuestionSources

            let sourceKind = 'QUESTION_BANK_GROUP'
            let sourceFileName = 'Tất cả nguồn trong nhóm'
            let skillId = null
            let skillName = null

            if (isSkillFiltered) {
                sourceKind = 'QUESTION_BANK_SKILL'
                skillId = this.selectedQuestionSkill
                skillName = this.getSelectedSkillTitle()
                sourceFileName = `Kỹ năng: ${skillName}`
            } else if (!isAllSources) {
                sourceKind = 'QUESTION_BANK_FILE'
                sourceFileName = this.selectedQuestionSourceFile || this.getQuestionSourceFile(first)
            }

            return {
                sourceType: 'CONTENT_HUB',
                sourceKind,
                groupId: first.GroupId || this.selectedGroupId,
                sourceFileName,
                skillId,
                skillName,
                questionIds: questions.map(item => item.Id).filter(id => id !== undefined && id !== null).map(id => String(id)),
                poolSize: questions.length,
                importedAt: new Date().toISOString(),
            }
        },
        // Content Hub mới lưu theo timerMarker.questions[]; dữ liệu cũ vẫn là một question trên mỗi interaction.
        // Chuẩn hóa ngay tại cửa ngõ import để các module nhận được cùng một danh sách câu hỏi phẳng.
        getInteractiveTimerMarkers(item) {
            const meta = this.getDocumentMeta(item)
            let source = meta.timerMarkers || meta.interactions || []
            if (typeof source === 'string') {
                try { source = JSON.parse(source) } catch (error) { source = [] }
            }
            if (!Array.isArray(source)) return []
            const markers = []
            const byTime = new Map()
            const parseTime = value => {
                if (typeof value === 'number') return Math.max(0, Math.floor(value))
                const parts = String(value ?? 0).split(':').map(Number)
                if (parts.some(Number.isNaN)) return 0
                if (parts.length === 3) return Math.max(0, parts[0] * 3600 + parts[1] * 60 + parts[2])
                if (parts.length === 2) return Math.max(0, parts[0] * 60 + parts[1])
                return Math.max(0, Number(parts[0]) || 0)
            }
            source.forEach(item => {
                const time = parseTime(item?.time ?? item?.timerMarker ?? item?.timeMarker)
                const key = String(time)
                let marker = byTime.get(key)
                if (!marker) {
                    marker = { id: item?.id || `timer_marker_${time}_${markers.length}`, time, timerMarker: time, questions: [] }
                    byTime.set(key, marker)
                    markers.push(marker)
                }
                const questions = Array.isArray(item?.questions) ? item.questions : [item?.question || item]
                questions.forEach(question => {
                    if (question && typeof question === 'object') marker.questions.push(question)
                })
            })
            return markers.filter(marker => marker.questions.length).sort((a, b) => a.time - b.time)
        },
        getDocumentMeta(item) { return this.parseJson(item?.DataJson, {}) },
        isInteractiveVideo(item) { return this.getDocumentMeta(item)?.interactive === true },
        getInteractiveQuestionCount(item) { return this.getInteractiveTimerMarkers(item).reduce((count, marker) => count + marker.questions.length, 0) },
        getDocumentName(item) { const meta = this.getDocumentMeta(item); return item?.TenNoiDung || item?.displayName || item?.FileName || item?.TenFile || meta.fileName || meta.FILE_NAME || 'Tài liệu Content Hub' },
        // Các nguồn tài liệu cũ/mới dùng tên field khác nhau; ưu tiên tên giáo viên và chỉ fallback về mã tài khoản để không tạo ô trống.
        getDocumentCreator(item) {
            const meta = this.getDocumentMeta(item)
            const candidates = [
                item?.NguoiUploadName,
                item?.NguoiTaoName,
                item?.CreatedByName,
                item?.CreateUserName,
                meta.NguoiUploadName,
                meta.NguoiTaoName,
                meta.CreatedByName,
                item?.CreateUser,
                item?.NguoiTao,
            ]
            const value = candidates.find(candidate => (typeof candidate === 'string' || typeof candidate === 'number') && String(candidate).trim())
            return value === undefined ? 'Chưa xác định' : String(value).trim()
        },
        // CreateUser là mã tài khoản/nhân viên do API cây tài nguyên trả về; đọc thêm alias để tương thích dữ liệu cũ.
        getDocumentEmployeeCode(item) {
            const meta = this.getDocumentMeta(item)
            const candidates = [
                item?.CreateUser,
                item?.CreateUserCode,
                item?.NguoiTao,
                item?.NguoiTaoCode,
                item?.NguoiUploadCode,
                meta.CreateUser,
                meta.CreateUserCode,
                meta.NguoiTaoCode,
                meta.NguoiUploadCode,
            ]
            const value = candidates.find(candidate => (typeof candidate === 'string' || typeof candidate === 'number') && String(candidate).trim())
            return value === undefined ? '—' : String(value).trim()
        },
        // Hiển thị thời gian tạo theo cùng định dạng với màn Kho soạn nội dung, nhưng giữ nguyên chuỗi nếu server trả format đặc biệt.
        getDocumentCreatedTime(item) {
            const meta = this.getDocumentMeta(item)
            const raw = item?.CreateTime || item?.CreatedTime || item?.NguoiUploadTime || item?.UploadTime
                || meta.CreateTime || meta.CreatedTime || meta.NguoiUploadTime || meta.UploadTime || ''
            if (!raw) return '—'
            const date = new Date(String(raw).replace(' ', 'T'))
            if (Number.isNaN(date.getTime())) return String(raw)
            const parts = new Intl.DateTimeFormat('vi-VN', {
                day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false,
            }).formatToParts(date)
            const part = type => parts.find(item => item.type === type)?.value || ''
            return `${part('day')}/${part('month')}/${part('year')} ${part('hour')}:${part('minute')}`
        },
        getRawDocumentSource(item) {
            const meta = this.getDocumentMeta(item)
            return item?.FileURL || item?.FileUrl || item?.fileUrl || item?.FileDataURL || item?.Url || item?.URL || item?.Link || item?.DetailUrl || meta.url || meta.dbUrl || meta.DB_URL || meta.FILE_URL || meta.iSpringURL || ''
        },
        // Audio/image cần URL file trực tiếp; viewer FileData chỉ phù hợp để đọc tài liệu văn phòng.
        getDocumentDirectSource(item) {
            const meta = this.getDocumentMeta(item)
            const source = meta.dbUrl || meta.DB_URL || meta.FILE_URL || item?.dbUrl || item?.DB_URL
                || item?.FileURL || item?.FileUrl || item?.fileUrl || item?.FileDataURL || meta.url || meta.iSpringURL || ''
            return this.normalizeDirectFileSource(source)
        },
        // Audio/ảnh không cần lớp viewer; chuyển URL FileData viewer/download về endpoint trả file trực tiếp.
        normalizeDirectFileSource(source) {
            let value = String(source || '').trim()
            if (!value) return ''

            // FileData có thể trả về host cũ hoặc đường dẫn tương đối; chuẩn hóa về host đọc file dùng chung của LMS.
            value = value.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/')
            value = value.replace(/\/(?:viewer|download)\/FileData\//i, '/FileData/')
            if (/^https?:\/\//i.test(value) || /^(?:data|blob):/i.test(value)) return value

            const base = vueData?.v_Set?.urlReadFile || 'https://file.lhbs.vn/lms'
            return `${base.replace(/\/+$/, '')}/${value.replace(/^\/+/, '')}`
        },
        // Bê nguyên quy tắc của lms-content-hub: fileId của LMS được ưu tiên, còn Drive ID chỉ là metadata/fallback.
        getLmsStorageFileId(item, rawFileDataUrl = '') {
            const meta = this.getDocumentMeta(item)
            const driveFileId = String(meta.driveFileId || meta.DriveFileId || meta.DRIVE_FILE_ID || '').trim()
            const dataUrlFileId = String(rawFileDataUrl).match(/\/FileData\/([^/?#]+)/i)?.[1] || ''
            const candidates = [meta.fileId, meta.FILE_ID, item?.FileID, item?.fileId, dataUrlFileId]
            return candidates.map(value => String(value || '').trim()).find(value => value && value !== driveFileId) || ''
        },
        // Ảnh phải đọc qua binary FileData của LMS nếu bản ghi có bản sao trong DB; điều này tránh URL googleusercontent hết hạn/quyền 403.
        getLmsFileUrl(item) {
            const meta = this.getDocumentMeta(item)
            const rawFileDataUrl = String(meta.dbUrl || meta.DB_URL || meta.FILE_URL || meta.url || item?.FileURL || item?.FileUrl || '').trim()
            const fileId = this.getLmsStorageFileId(item, rawFileDataUrl)
            const driveFileId = String(meta.driveFileId || meta.DriveFileId || meta.DRIVE_FILE_ID || '').trim()
            const rawFileDataId = String(rawFileDataUrl).match(/\/FileData\/([^/?#]+)/i)?.[1] || ''
            const isRawLmsFileData = /(?:file\.lhbs\.vn|lms\.lhbs\.vn)\/lms\/FileData\//i.test(rawFileDataUrl)
                || /(?:^|\/)FileData\//i.test(rawFileDataUrl)
            const hasExplicitLmsStorage = /LMS_(?:DB_)?FILEDATA/i.test(String(meta.storage || ''))

            // Link ngoài chưa có metadata storage LMS thì không được tự biến Drive ID thành FileData ID.
            if (rawFileDataUrl && !isRawLmsFileData && !hasExplicitLmsStorage) return ''
            const canUseRawFileDataUrl = isRawLmsFileData && rawFileDataId !== driveFileId
            const fileDataUrl = canUseRawFileDataUrl ? rawFileDataUrl : (fileId ? `/FileData/${fileId}` : '')
            if (!fileDataUrl) return ''
            if (/^https?:\/\//i.test(fileDataUrl)) return fileDataUrl

            const base = String(vueData?.v_Set?.urlReadFile || '').replace(/\/$/, '')
            return base ? `${base}/${String(fileDataUrl).replace(/^\/+/, '')}` : this.normalizeDirectFileSource(fileDataUrl)
        },
        // Cùng fallback với lms-content-hub: LMS FileData trước, Drive thumbnail sau cùng.
        getImagePreviewUrl(item, fallbackUrl = '') {
            const lmsUrl = this.getLmsFileUrl(item)
            if (lmsUrl) return lmsUrl
            const meta = this.getDocumentMeta(item)
            const driveFileId = meta.driveFileId || meta.DriveFileId || meta.DRIVE_FILE_ID
                || this.getDriveFileId(String(fallbackUrl || this.getDocumentOpenSource(item) || ''))
            if (driveFileId) return `https://drive.google.com/thumbnail?id=${encodeURIComponent(driveFileId)}&sz=w2000`
            return fallbackUrl || this.getDocumentDirectSource(item) || this.getRawDocumentSource(item)
        },
        // Tài liệu có thể là file URL hoặc HTML inline; dùng helper này cho loader để không bỏ sót HTML không có file vật lý.
        hasDocumentContent(item) {
            const meta = this.getDocumentMeta(item)
            return Boolean(this.getRawDocumentSource(item)
                || meta.htmlContent || meta.HTMLContent
                || item?.htmlContent || item?.HTMLContent)
        },
        // Chuẩn hóa loại file Office/PDF để viewer nhận đúng cả tài liệu import từ Content Hub không có slideType.
        getDocumentSlideType(item) {
            const meta = this.getDocumentMeta(item)
            const value = `${meta.slideType || meta.fileType || ''} ${meta.contentType || ''} ${item?.FileName || item?.TenFile || item?.displayName || meta.fileName || meta.FILE_NAME || ''} ${this.getRawDocumentSource(item)}`.toLowerCase()
            if (/pdf|application\/pdf/.test(value)) return 'PDF'
            if (/pptx?|powerpoint|presentation/.test(value)) return 'PPT'
            if (/xlsx?|excel|spreadsheet/.test(value)) return 'XLSX'
            // Kiểm tra PPT/XLS trước DOC vì MIME Office có chuỗi "officedocument".
            if (/docx?|msword|wordprocessingml/.test(value)) return 'DOCX'
            return ''
        },
        // HTML Content Hub có thể chứa audio inline dù bản ghi được lưu dưới dạng HTML.
        getAudioSourceFromHtml(item) {
            const meta = this.getDocumentMeta(item)
            const html = meta.htmlContent || meta.HTMLContent || item?.htmlContent || ''
            if (typeof html !== 'string') return ''
            const match = html.match(/<(?:audio|source)\b[^>]*\bsrc\s*=\s*["']([^"']+)["']/i)
            return this.normalizeDirectFileSource(match?.[1] || '')
        },
        getDocumentViewerSource(item) {
            const meta = this.getDocumentMeta(item)
            const rawSource = String(this.getRawDocumentSource(item) || '')
            const sourceId = rawSource.match(/\/FileData\/([^/?#]+)/i)?.[1] || ''
            const fileId = meta.fileId || meta.FILE_ID || item?.FileID || item?.fileId || sourceId
            const rawFileName = this.getDocumentName(item)
            const hasLmsCopy = meta.uploadSource === 'db'
                || Boolean(meta.storage || meta.dbUrl || meta.DB_URL || meta.FILE_URL)
                || /(?:^|\/)FileData\//i.test(rawSource)
                || /file\.lhbs\.vn\/lms\/FileData\//i.test(rawSource)
            if (!hasLmsCopy || !fileId || !rawFileName) return ''
            // Chuẩn hóa tên file: loại bỏ các ký tự đặc biệt gây lỗi IIS Request Filtering (404 Not Found) như &, +, #, %, ?, :, /, \, *, ", <, >, |
            const lastDotIndex = rawFileName.lastIndexOf('.')
            const baseName = lastDotIndex !== -1 ? rawFileName.substring(0, lastDotIndex) : rawFileName
            const ext = lastDotIndex !== -1 ? rawFileName.substring(lastDotIndex) : ''
            const cleanBase = baseName.replace(/[&+%#?:/\\*"<>|]/g, '_').trim() || 'file'
            const fileName = `${cleanBase}${ext}`
            // Chỉ ưu tiên viewer khi metadata xác nhận có bản LMS; file thuần Google Drive cũng có fileId nhưng không dùng được viewer này.
            return `https://file.lhbs.vn/lms/viewer/FileData/${encodeURIComponent(fileId)}/${encodeURIComponent(fileName)}`
        },
        // =========================================================================================
        // HÀM NHẬN DIỆN & CHUẨN HÓA MÃ LOẠI TÀI LIỆU (TypeCode)
        // Quét tổng hợp từ: metadata Content Hub, tên file (name/fileName/tenFile), đuôi mở rộng,
        // link nguồn (rawSource) và URL viewer để phân loại chính xác:
        // - INTERACTIVE_VIDEO: Video có gắn mốc câu hỏi tương tác (interactive = true)
        // - ISPRING: Gói bài giảng SCORM/iSpring chạy iframe
        // - HTML: Bài đọc / tài liệu nội dung HTML inline
        // - VIDEO: File video MP4, WebM, MOV, link YouTube
        // - AUDIO: File âm thanh MP3, WAV, AAC, M4A, OGG
        // - IMAGE: File ảnh PNG, JPG, JPEG, GIF, WebP, SVG, BMP, ICO (ảnh cắt đề thi, screenshot...)
        // - DOCUMENT: Tài liệu bài giảng văn phòng (PDF, Word DOCX/DOC, PowerPoint PPTX/PPT, Excel XLSX/XLS)
        // =========================================================================================
        getDocumentTypeCode(item) {
            const meta = this.getDocumentMeta(item)
            const name = String(this.getDocumentName(item) || item?.FileName || item?.TenFile || '').toLowerCase()
            const htmlContent = meta.htmlContent || meta.HTMLContent || item?.htmlContent || item?.HTMLContent || ''
            const declaredType = `${item?.LoaiNoiDung || ''} ${meta.contentType || ''}`.toLowerCase()
            const rawSource = String(this.getRawDocumentSource(item) || '').toLowerCase()
            const value = `${declaredType} ${meta.mediaType || ''} ${name} ${rawSource} ${this.getDocumentSource(item)}`.toLowerCase()
            if (meta.interactive === true) return 'INTERACTIVE_VIDEO'
            if (/ispring|application\/x-ispring/.test(declaredType) || meta.iSpringURL) return 'ISPRING'
            if (/html/.test(declaredType) || htmlContent) return 'HTML'
            if (/video|youtube|\.mp4|\.webm|\.mov/.test(value)) return 'VIDEO'
            if (/audio|\.mp3|\.wav|\.aac|\.m4a|\.ogg/.test(value)) return 'AUDIO'
            if (/image|\.png|\.jpe?g|\.gif|\.webp|\.svg|\.bmp|\.ico/.test(value)) return 'IMAGE'
            if (this.getDocumentSlideType(item) || /pdf|docx?|pptx?|xlsx?|document|spreadsheet|presentation/.test(value)) return 'DOCUMENT'
            return 'DOCUMENT'
        },

        // Nút mở tài liệu dùng viewer LMS cho Office/PDF; ảnh mở dialog nội bộ và dùng cùng helper với lms-content-hub.
        getDocumentOpenSource(item) {
            if (this.getDocumentTypeCode(item) !== 'IMAGE') return this.getDocumentSource(item)
            return this.getImagePreviewUrl(item, this.getDocumentDirectSource(item) || this.getRawDocumentSource(item))
        },
        isImageDocument(item) { return this.getDocumentTypeCode(item) === 'IMAGE' },
        // Chặn điều hướng ngoài riêng cho ảnh để preview trong dialog, tránh rơi vào URL Google đã hết quyền.
        handleDocumentOpen(item, event) {
            if (!this.isImageDocument(item)) return
            event?.preventDefault?.()
            this.openImagePreview(item)
        },
        openImagePreview(item) {
            this.closeImagePreview()
            this.imagePreviewTitle = this.getDocumentName(item)
            this.imagePreviewUrl = this.getImagePreviewUrl(item, this.getDocumentDirectSource(item) || this.getRawDocumentSource(item))
            if (!this.imagePreviewUrl) {
                this.notify('Tài liệu chưa có URL ảnh để hiển thị.', 'error')
                return
            }
            this.imagePreviewDialog = true
            this.imagePreviewLoading = false
        },
        onImagePreviewModelUpdate(value) {
            this.imagePreviewDialog = value
            if (!value) this.clearImagePreview()
        },
        closeImagePreview() {
            this.imagePreviewDialog = false
            this.clearImagePreview()
        },
        clearImagePreview() {
            this.imagePreviewUrl = ''
            this.imagePreviewTitle = ''
            this.imagePreviewLoading = false
        },
        // Bản sao LMS có metadata DB thì phải đi qua viewer trước; chỉ dùng link ngoài khi không có bản DB.
        getDocumentSource(item) { return this.getDocumentViewerSource(item) || this.getRawDocumentSource(item) },

        // Trả về tên hiển thị loại tài liệu (Label) trên cột 'Loại' của bảng
        getDocumentType(item) {
            const meta = this.getDocumentMeta(item)
            const name = String(this.getDocumentName(item) || item?.FileName || item?.TenFile || '').toLowerCase()
            const htmlContent = meta.htmlContent || meta.HTMLContent || item?.htmlContent || item?.HTMLContent || ''
            const declaredType = `${item?.LoaiNoiDung || ''} ${meta.contentType || ''}`.toLowerCase()
            const rawSource = String(this.getRawDocumentSource(item) || '').toLowerCase()
            const value = `${declaredType} ${meta.mediaType || ''} ${name} ${rawSource} ${this.getDocumentSource(item)}`.toLowerCase()
            if (meta.interactive === true) return 'Video tương tác'
            // iSpring là gói HTML chạy trên GitHub Pages; phải nhận diện trước HTML để không rơi thành HTML thường.
            if (/ispring|application\/x-ispring/.test(declaredType) || meta.iSpringURL) return 'ISPRING_CONTENT'
            if (/html/.test(declaredType) || htmlContent) return 'HTML'
            if (/video|youtube|\.mp4|\.webm|\.mov/.test(value)) return 'Video'
            if (/audio|\.mp3|\.wav|\.aac|\.m4a|\.ogg/.test(value)) return 'Audio'
            if (/image|\.png|\.jpe?g|\.gif|\.webp|\.svg|\.bmp|\.ico/.test(value)) return 'Hình ảnh'
            if (/html|interactive/.test(value)) return 'HTML'
            return item?.LoaiNoiDung || 'Tài liệu'
        },
        getDocumentIcon(item) { return { 'Video tương tác': 'mdi-timeline-text-outline', Video: 'mdi-play-circle-outline', Audio: 'mdi-volume-high', 'Hình ảnh': 'mdi-image-outline', HTML: 'mdi-language-html5', ISPRING_CONTENT: 'mdi-play-box-multiple' }[this.getDocumentType(item)] || 'mdi-file-document-outline' },
        getDocumentColor(item) { return { 'Video tương tác': 'deep-purple', Video: 'deep-purple', Audio: 'teal', 'Hình ảnh': 'orange', HTML: 'amber', ISPRING_CONTENT: 'purple' }[this.getDocumentType(item)] || 'primary' },
        parseDocument(item) {
            const meta = this.getDocumentMeta(item)
            const rawSource = this.getRawDocumentSource(item)
            const viewerSource = this.getDocumentViewerSource(item)
            const documentType = this.getDocumentType(item)
            const typeCode = this.getDocumentTypeCode(item)
            const directSource = this.getDocumentDirectSource(item) || this.getAudioSourceFromHtml(item)
            const htmlContent = meta.htmlContent || meta.HTMLContent || item?.htmlContent || item?.HTMLContent || ''
            // Audio/image phải giữ URL trực tiếp để thẻ media tải được; viewer LMS chỉ dùng cho tài liệu văn phòng; HTML ưu tiên htmlContent nếu không có file url.
            const source = ['Audio', 'Hình ảnh'].includes(documentType)
                ? (directSource || this.normalizeDirectFileSource(rawSource))
                : (documentType === 'HTML' ? (htmlContent || viewerSource || rawSource) : (viewerSource || rawSource))
            const audioUrl = this.getAudioSourceFromHtml(item)
            return {
                id: meta.fileId || meta.FILE_ID || item.NoiDungID,
                name: this.getDocumentName(item),
                url: source,
                source,
                viewerSource,
                externalSource: rawSource,
                driveFileId: meta.driveFileId || meta.DRIVE_FILE_ID || '',
                uploadSource: meta.uploadSource || '',
                mediaSource: meta.uploadSource === 'db' || meta.storage ? 'db' : 'link',
                fileSize: Number(meta.fileSize || meta.FILE_SIZE || 0),
                contentType: meta.contentType || item.LoaiNoiDung || '',
                // Dùng mã loại ổn định để module nhận biết IMAGE/AUDIO dù label hiển thị có dấu hoặc được dịch.
                mediaType: typeCode,
                slideType: this.getDocumentSlideType(item),
                // Giữ riêng iSpringURL/GUID để module Soạn và viewer mở đúng iframe, không chỉ có URL fallback.
                iSpringURL: meta.iSpringURL || (documentType === 'ISPRING_CONTENT' ? source : ''),
                iSpringGUID: meta.iSpringGUID || meta.ISPRING_GUID || '',
                audioUrl,
                htmlContent,
                // Giữ timerMarkers để module mới hiểu đúng nhóm mốc; interactions phẳng để module cũ vẫn phát/chấm được.
                interactive: meta.interactive === true,
                timerMarkers: JSON.parse(JSON.stringify(this.getInteractiveTimerMarkers(item))),
                interactions: JSON.parse(JSON.stringify(this.getInteractiveTimerMarkers(item).flatMap(marker => marker.questions.map(question => ({
                    ...question,
                    time: marker.time,
                    timerMarker: marker.time,
                    prompt: question?.content?.prompt || question?.config?.questionText || question?.prompt || '',
                    question,
                }))))),
                sourceTracking: { sourceType: 'CONTENT_HUB', sourceKind: typeCode, resourceId: item.HocLieuID, nodeId: item.NoiDungID, importedAt: new Date().toISOString(), sourcePriority: viewerSource ? 'viewer' : 'gdrive-or-external' },
            }
        },
        importSelected() {
            if (!this.documentsOnly && this.activeTab === 'questions') this.selectedQuestions.forEach(item => this.$emit('import-question', this.parseQuestion(item)))
            else this.selectedDocuments.forEach(item => this.$emit('import-document', this.parseDocument(item)))
            this.close()
        },
        importQuestionPool() {
            if (!this.canImportQuestionPool) return
            if (this.importMode === 'SKILL_MATRIX') {
                const matrixConfigs = []
                this.availableMatrixSkills.forEach(skill => {
                    const customPickedSkill = this.matrixSelectedQuestionsMap[skill.key] || []
                    const sourceConfigs = skill.sources.map(source => {
                        const manuallyPickedFromCard = customPickedSkill.filter(item => item._matrixSourceId === source.id)
                        const manuallyPickedFromSource = (source.selectedQuestionIds || []).length
                            ? (source.questions || []).filter(item => (source.selectedQuestionIds || []).map(String).includes(this.questionKey(item)))
                            : []
                        const manuallyPicked = manuallyPickedFromSource.length
                            ? manuallyPickedFromSource
                            : (manuallyPickedFromCard.length ? manuallyPickedFromCard : [])

                        const pool = (source.selectedQuestionIds || []).length || customPickedSkill.length
                            ? manuallyPicked
                            : (source.questions || [])
                        const configuredCount = (source.selectedQuestionIds || []).length || customPickedSkill.length
                            ? manuallyPicked.length
                            : Math.max(Number(source.count) || 0, 0)
                        const questionIds = pool.map(item => item.Id).filter(id => id !== undefined && id !== null).map(String)
                        return {
                            sourceId: source.id,
                            groupId: source.groupId,
                            groupTitle: this.questionGroups.find(group => String(group.Id) === String(source.groupId))?.Title || '',
                            randomCount: Math.min(configuredCount, pool.length),
                            availableCount: pool.length,
                            questionIds,
                        }
                    }).filter(source => source.randomCount > 0 && source.questionIds.length)

                    if (!sourceConfigs.length) return
                    const uniqueQuestions = []
                    const seenIds = new Set()
                    sourceConfigs.forEach(source => {
                        const sourceDetail = skill.sources.find(item => item.id === source.sourceId)
                        const sourceQuestions = (sourceDetail?.selectedQuestionIds || []).length
                            ? (sourceDetail?.questions || []).filter(item => (sourceDetail.selectedQuestionIds || []).map(String).includes(this.questionKey(item)))
                            : (sourceDetail?.questions || [])
                        sourceQuestions.forEach(item => {
                            const id = String(item.Id ?? this.questionKey(item))
                            if (!seenIds.has(id)) {
                                seenIds.add(id)
                                uniqueQuestions.push(item)
                            }
                        })
                    })
                    const questions = customPickedSkill.length
                        ? customPickedSkill.filter(item => seenIds.has(String(item.Id ?? this.questionKey(item))))
                        : uniqueQuestions
                    matrixConfigs.push({
                        skillId: skill.key,
                        skillName: skill.title,
                        skillGroup: skill.group,
                        randomCount: sourceConfigs.reduce((sum, source) => sum + source.randomCount, 0),
                        availableCount: questions.length,
                        questions: questions.map(item => this.parseQuestion(item)),
                        sources: sourceConfigs,
                        source: {
                            sourceType: 'CONTENT_HUB',
                            sourceKind: 'QUESTION_BANK_SKILL_MATRIX',
                            groupIds: sourceConfigs.map(source => source.groupId).filter(Boolean),
                            sourceFileName: `Mức độ: ${skill.title}`,
                            skillId: skill.key,
                            skillName: skill.title,
                            questionIds: questions.map(item => item.Id).filter(id => id !== undefined && id !== null).map(String),
                            poolSize: questions.length,
                            importedAt: new Date().toISOString(),
                        }
                    })
                })
                if (!matrixConfigs.length) return
                this.$emit('import-skill-matrix', matrixConfigs)
                this.close()
                return
            }

            this.$emit('import-question-pool', {
                questions: this.filteredQuestions.map(item => this.parseQuestion(item)),
                source: this.getQuestionSourceDescriptor(this.filteredQuestions),
            })
            this.close()
        },
        onDialogModelUpdate(value) { if (!value) this.close() },
        close() { this.closeImagePreview(); this.selectedQuestions = []; this.selectedDocuments = []; this.$emit('update:modelValue', false) },
        notify(message, color = 'info') { this.snackbarRef?.value?.showSnackbar?.({ message, color }) },
    },
	}
</script>

<style scoped>
/* Chừa khoảng thở phía trên và cho phép outline/label nổi ra ngoài field; Vuetify sẽ cắt label nếu field nằm sát mép vùng cuộn. */
.content-hub-import-dialog .content-hub-filter-select {
	padding-top: 4px;
	overflow: visible;
}

.content-hub-import-dialog .content-hub-filter-select :deep(.v-field),
.content-hub-import-dialog .content-hub-filter-select :deep(.v-field__field),
.content-hub-import-dialog .content-hub-filter-select :deep(.v-field__outline) {
	overflow: visible;
}
</style>