<template>
	<div class="assignment-canvas">
		<div v-if="!groups || groups.length === 0" class="text-center pa-6 text-grey">
			<v-icon size="48" class="mb-2">mdi-paperclip</v-icon>
			<div>{{ $t('message.DragOrSelectAComponentFromTheLibraryToGetStarted') }}.</div>
		</div>

		<!-- Vòng lặp qua các Nhóm (Groups) -->
		<div v-for="(group, groupIndex) in groups" :key="group.id" class="group-wrapper">
			<v-card class="group-card" variant="outlined">
				<div class="group-header" @click="selectItem('group', groupIndex)">
					<v-icon class="drag-handle">mdi-drag-vertical</v-icon>
					<div class="group-title">{{ group.title }}</div>
					<div class="ml-2 d-flex ga-2">
						<v-chip size="small" v-if="group.media?.sourceYT?.source?.length > 0" color="red">
							<v-icon>mdi-video-outline</v-icon>
						</v-chip>
						<v-chip size="small" v-if="group.media?.sourceRecord?.source?.length > 0" color="teal">
							<v-icon>mdi-multimedia</v-icon>
						</v-chip>
						<v-chip size="small"
							v-if="group.media?.sourceFiles?.file?.length > 0 || group.media?.sourceFiles?.image?.length > 0"
							color="blue">
							<v-icon>mdi-file</v-icon>
						</v-chip>
					</div>
					<v-chip variant="text" color="primary" class="ml-1 font-weight-medium"
						v-if="renderPointInGroup(group) > 0" size="small">
						{{ $t('message.Total') }} {{ $t('message.Score') }}: {{ renderPointInGroup(group) }}
						<!-- Điểm của group RANDOM là điểm của số câu bốc mỗi lượt, nên hiển thị rõ mẫu số nghiệp vụ. -->
						<span v-if="getRandomScoreHint(group)" class="text-caption font-weight-regular ms-1">
							({{ getRandomScoreHint(group) }})
						</span>
					</v-chip>
					<v-spacer />
					<v-chip v-if="!isMatrixGroup(group)" class="ml-2 font-weight-medium" size="small" color="primary" variant="text">
						{{ group.questions.length }} {{ $t('message.Question') }}
					</v-chip>
					<v-chip v-if="isMatrixGroup(group)" class="ml-2 font-weight-medium" size="small" color="indigo" variant="tonal">
						<v-icon start size="14">mdi-matrix</v-icon>{{ IsEngLish ? `Matrix: ${getMatrixConfiguredCount(group)} selected (Pool: ${group.questions.length})` : `Ma trận: ${getMatrixConfiguredCount(group)} câu bốc (Kho: ${group.questions.length} câu)` }}
					</v-chip>
					<v-chip v-else-if="group.questionSelection?.mode === 'RANDOM'" class="ml-1" size="small" color="deep-purple" variant="tonal">
						{{ IsEngLish ? `Random ${group.questionSelection.questionsPerAttempt}/${getRandomPoolSize(group)}` : `Ngẫu nhiên ${group.questionSelection.questionsPerAttempt}/${getRandomPoolSize(group)}` }}
					</v-chip>
					<v-btn icon size="small" variant="text" @click.stop="removeGroup(groupIndex)">
						<v-icon>mdi-delete-outline</v-icon>
					</v-btn>
				</div>

				<div v-if="!isMatrixGroup(group)" class="group-import-actions" @click.stop>
					<span class="text-caption text-medium-emphasis">{{ IsEngLish ? 'Add content from:' : 'Thêm nội dung từ:' }}</span>
					<!-- Content Hub là cửa ngõ dùng chung để lấy câu hỏi và tài liệu theo Khối/Môn của bài tập. -->
					<v-btn size="x-small" variant="tonal" color="teal" @click="$emit('open-group-import', { groupIndex, source: 'contentHub' })">
						<v-icon start size="14">mdi-folder-download-outline</v-icon>Content Hub
					</v-btn>
				</div>

				<div v-if="hasMedia(group.media)" class="assignment-canvas-media" @click.stop>
					<iframe v-if="group.media.sourceYT?.source" :src="renderUrlYoutube(group.media.sourceYT.source)" :title="IsEngLish ? 'Section video' : 'Video nhóm'" />
					<div v-if="group.media.sourceRecord?.source" class="assignment-canvas-audio">
						<uc-wave-audio-player :audioUrl="group.media.sourceRecord.source" />
					</div>
					<div v-if="group.media.sourceFiles?.image?.length || group.media.sourceFiles?.file?.length"
						class="assignment-canvas-media-grid">
						<v-img v-for="(file, index) in (group.media.sourceFiles?.image || [])" :key="file.id || index" :src="imageSource(file)" />
						<div v-for="(file, index) in (group.media.sourceFiles?.file || [])"
							:key="file.id || index" class="assignment-canvas-file-card">
							<div class="assignment-canvas-file-link">
								<v-icon color="primary">mdi-file-document-outline</v-icon>
								<div class="assignment-canvas-file-info">
									<a :href="fileSource(file)" target="_blank" rel="noopener" :title="file.name">
										{{ file.name || (IsEngLish ? 'Attachment' : 'Tệp đính kèm') }}
									</a>
									<span v-if="file.fileSize" class="assignment-canvas-file-size">{{ formatFileSize(file.fileSize) }}</span>
								</div>
								<v-btn :href="fileSource(file)" target="_blank" rel="noopener" icon="mdi-open-in-new"
									variant="tonal" size="x-small" color="primary" :title="IsEngLish ? 'Open file' : 'Mở file'" />
							</div>
						</div>
					</div>
				</div>

				<!-- Hiển thị trước nội dung rich text của Phần ngay trên canvas để giáo viên thấy phần dẫn nhập khi soạn bài. -->
				<div v-if="group.content" class="assignment-canvas-section-content mt-2 px-3 py-2" @click.stop>
					<uc-latex-view :content="group.content" />
				</div>

				<!-- Container cho câu hỏi với drop zone hoặc Block Ma trận đề trực tiếp -->
				<div class="questions-container">
					<!-- Nếu nhóm được cấu hình theo Ma trận đề: Hiển thị Bảng cấu hình Ma trận TRỰC TIẾP trên Canvas -->
					<div v-if="isMatrixGroup(group)" class="matrix-canvas-block pa-3 ma-2 rounded border bg-grey-lighten-5">
						<!-- Dùng v-row/v-col cho header ma trận để các control tự co giãn -->
						<v-row dense align="center" class="mb-2">
							<v-col cols="12" md="5" class="d-flex align-center ga-2">
								<v-icon color="indigo">mdi-format-list-checks</v-icon>
								<div>
									<span class="text-subtitle-2 font-weight-bold">{{ IsEngLish ? 'Question matrix configuration:' : 'Bảng cấu hình Ma trận số câu hỏi:' }}</span>
									<div class="text-caption text-medium-emphasis">{{ IsEngLish ? 'Configure number of random questions across 4 cognitive levels' : 'Cấu hình số câu bốc ngẫu nhiên theo 4 mức độ nhận thức' }}</div>
								</div>
							</v-col>
							<v-col cols="12" md="7">
								<v-row dense align="center" justify="end">
									<!-- Hiển thị Tổng số câu tự động tính từ 4 mức độ -->
									<v-col cols="auto" class="d-flex align-center ga-2">
										<span class="text-caption font-weight-medium text-no-wrap">{{ IsEngLish ? 'Total questions:' : 'Tổng số câu:' }}</span>
										<v-chip color="indigo" variant="flat" size="default" class="font-weight-bold px-3">
											{{ getMatrixConfiguredTotal(groupIndex) }} {{ IsEngLish ? 'questions' : 'câu' }}
										</v-chip>
									</v-col>
									<v-col cols="auto">
										<v-chip :color="getMatrixTotalStatus(groupIndex).color" variant="tonal" size="small" class="font-weight-medium">
											{{ getMatrixTotalStatus(groupIndex).text }}
										</v-chip>
									</v-col>
									<v-col cols="auto">
										<v-btn size="x-small" variant="text" color="indigo" :loading="isReloadingMatrixGroups" @click="loadQuestionGroups(true)">
											<v-icon start size="14">mdi-sync</v-icon>{{ IsEngLish ? 'Reload data' : 'Tải lại dữ liệu' }}
										</v-btn>
										<v-btn size="x-small" variant="text" color="grey-darken-1" @click="resetMatrixForGroup(groupIndex)">
											<v-icon start size="14">mdi-refresh</v-icon>{{ IsEngLish ? 'Reset' : 'Đặt lại' }}
										</v-btn>
										<v-btn size="x-small" variant="text" color="primary" @click="toggleMatrixDetails(groupIndex)">
											<v-icon start size="14">{{ isMatrixDetailsExpanded(groupIndex) ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
											{{ isMatrixDetailsExpanded(groupIndex) ? (IsEngLish ? 'Collapse pool' : 'Thu gọn kho') : (IsEngLish ? `View pool (${group.questions.length} questions)` : `Xem kho (${group.questions.length} câu)`) }}
										</v-btn>
									</v-col>
								</v-row>
							</v-col>
						</v-row>

						<!-- Danh sách 4 Card Mức độ nhận thức trực tiếp trên Canvas -->
						<div class="skill-matrix-cards">
							<v-card v-for="item in getMatrixSkillItemsForGroup(groupIndex)" :key="item.key" variant="outlined" class="skill-matrix-card bg-white mb-2">
								<v-card-text class="pa-3">
									<v-row dense align="center" class="skill-matrix-card__header">
										<v-col cols="12" md="4">
											<v-chip size="small" :color="getCognitiveChipColor(item.title)" variant="tonal" class="font-weight-bold text-no-wrap matrix-skill-chip">
												{{ item.title }} ({{ getSkillPercent(groupIndex, item) }}%)
											</v-chip>
										</v-col>
										<v-col cols="12" sm="6" md="3">
											<div class="text-caption text-medium-emphasis">{{ IsEngLish ? 'Available questions' : 'Số câu có sẵn' }}</div>
											<v-chip size="x-small" :color="item.taggedCount > 0 ? 'success' : 'grey-darken-1'" variant="tonal">
												<template v-if="item.taggedCount > 0">
													{{ item.taggedCount }} {{ IsEngLish ? 'questions at level' : 'câu đúng mức độ' }}
												</template>
												<template v-else>
													{{ IsEngLish ? `0 questions at level (${item.availableCount} questions in group)` : `0 câu đúng mức độ (${item.availableCount} câu trong nhóm)` }}
												</template>
											</v-chip>
										</v-col>
										<v-col cols="6" sm="3" md="2">
											<div class="text-caption text-medium-emphasis">{{ IsEngLish ? 'Configured' : 'Đã cấu hình' }}</div>
											<span class="matrix-configured-count">{{ getSkillConfiguredCount(groupIndex, item.key) }}</span>
											<span class="text-caption text-medium-emphasis">{{ IsEngLish ? ' questions' : ' câu' }}</span>
										</v-col>
										<v-col v-if="item.availableCount > 0" cols="12" md="3" class="skill-matrix-card__actions text-end">
											<v-btn size="x-small" variant="text" color="primary" @click="fillSkillMatrixSources(groupIndex, item.key)">
												<v-icon start size="13">mdi-check-all</v-icon>{{ IsEngLish ? 'Pick all matching level' : 'Lấy hết câu đúng mức độ' }}
											</v-btn>
										</v-col>
									</v-row>
									<v-divider class="my-2" />
									<div class="matrix-source-section">
										<div class="text-caption font-weight-medium text-medium-emphasis mb-1">{{ IsEngLish ? 'Question group sources' : 'Nguồn nhóm câu hỏi' }}</div>
										<div class="matrix-source-list">
											<div v-for="source in getSkillMatrixSources(groupIndex, item.key)" :key="source.id" class="matrix-source-row">
												<v-select :model-value="source.groupId" :items="questionGroups" item-title="Title" item-value="Id"
													:label="IsEngLish ? 'Group source' : 'Nguồn nhóm'" density="compact" variant="outlined" hide-details
													:placeholder="IsEngLish ? 'Select question group' : 'Chọn nhóm câu hỏi'" class="matrix-source-select"
													@update:model-value="onMatrixSourceGroupChange(groupIndex, item.key, source.id, $event)" />
												<v-chip size="x-small" variant="tonal" :color="getMatrixSourceAvailableCount(groupIndex, item.key, source.id) > 0 ? 'success' : 'default'">
													{{ getMatrixSourceAvailableCount(groupIndex, item.key, source.id) }} {{ IsEngLish ? 'questions' : 'câu' }}
												</v-chip>
												<v-text-field :model-value="source.count" type="number" min="0"
													:max="getMatrixSourceAvailableCount(groupIndex, item.key, source.id) || 999" density="compact" variant="outlined"
													hide-details :placeholder="IsEngLish ? 'Questions count' : 'Số câu bốc'" class="matrix-source-count"
													:disabled="getMatrixSourceAvailableCount(groupIndex, item.key, source.id) === 0"
													@update:model-value="onMatrixSourceCountChange(groupIndex, item.key, source.id, $event)" />
												<v-btn v-if="getSkillMatrixSources(groupIndex, item.key).length > 1" icon="mdi-close" size="x-small" variant="text" color="grey" @click="removeMatrixSource(groupIndex, item.key, source.id)" />
											</div>
											<v-btn size="x-small" variant="text" color="primary" class="matrix-add-source-btn" @click="addMatrixSource(groupIndex, item.key)">
												<v-icon start size="14">mdi-plus</v-icon>{{ IsEngLish ? 'Add group' : 'Thêm nhóm' }}
											</v-btn>
										</div>
									</div>
								</v-card-text>
							</v-card>
						</div>

						<!-- Khi giáo viên muốn mở rộng xem toàn bộ câu hỏi trong pool của Ma trận -->
						<div v-if="isMatrixDetailsExpanded(groupIndex)" class="mt-3 pt-2 border-t">
							<div class="text-caption font-weight-bold text-medium-emphasis mb-2">{{ IsEngLish ? `Questions in Matrix pool (${group.questions.length}):` : `Danh sách câu hỏi trong ngân hàng nguồn của Ma trận (${group.questions.length} câu):` }}</div>
							<v-list v-if="group.questions.length" class="pa-0 bg-transparent">
								<v-list-item v-for="(question, qIndex) in group.questions" :key="question.id" class="question-preview bg-white rounded mb-1 border"
									:class="{ 'selected': isSelectedQuestion(groupIndex, qIndex) }"
									@click="selectItem('question', groupIndex, qIndex)">
									<template #prepend>
										<v-chip size="x-small" color="indigo" variant="tonal" class="mr-2">{{ IsEngLish ? 'Question' : 'Câu' }} {{ qIndex + 1 }}</v-chip>
									</template>
									<template #append>
										<v-chip size="x-small" class="mr-1">{{ question.type }}</v-chip>
									</template>
									<v-list-item-title class="text-body-2">
										<uc-latex-view v-model:content="question.config.questionText" :escapeHtml="false" />
									</v-list-item-title>
								</v-list-item>
							</v-list>
							<div v-else class="text-caption text-medium-emphasis text-center py-2">{{ IsEngLish ? 'No questions in the matrix source pool yet. Please select source groups above.' : 'Chưa có câu hỏi nào trong kho nguồn của Ma trận. Vui lòng chọn nhóm nguồn ở trên.' }}</div>
						</div>
					</div>

					<!-- Vòng lặp qua các Câu hỏi (Questions) trong nhóm bình thường (không phải Ma trận) -->
					<v-list v-else-if="group.questions.length > 0" class="pa-0">
						<div v-for="(question, qIndex) in group.questions" :key="question.id"
							class="question-item-wrapper"
							@dragover.prevent="handleQuestionDragOver($event, groupIndex, qIndex)"
							@dragenter.prevent="handleQuestionDragEnter($event, groupIndex, qIndex)"
							@dragleave="handleQuestionDragLeave($event)"
							@drop.prevent="handleQuestionDrop($event, groupIndex, qIndex)">
							<!-- Drop indicator phía trên -->
							<div v-if="showDropIndicator(groupIndex, qIndex, 'before')" class="drop-indicator"></div>

							<v-list-item class="question-preview" :class="{
								'selected': isSelectedQuestion(groupIndex, qIndex),
								'dragging': isDragging(groupIndex, qIndex)
							}" @click="selectItem('question', groupIndex, qIndex)" draggable="true"
								@dragstart="handleQuestionDragStart($event, groupIndex, qIndex)"
								@dragend="handleDragEnd">
								<template #prepend>
									<v-icon class="drag-handle">mdi-drag</v-icon>
								</template>
								<template #append>
									<v-chip size="x-small" class="mr-1">{{ question.type }}</v-chip>
									<div class="d-flex align-center">
										<v-btn icon size="x-small" variant="text"
											@click.stop="removeQuestion(groupIndex, qIndex)">
											<v-icon>mdi-close</v-icon>
										</v-btn>
									</div>
								</template>

								<v-list-item-title class="font-weight-bold d-flex align-center">
									{{ $t('message.Question') }} {{ question.ordinalNumber }}:
									<!-- Hiển thị mức độ ngay trên canvas để giáo viên quét nhanh toàn bộ đề mà không cần mở panel thuộc tính từng câu. -->
									<v-chip v-if="getQuestionCognitiveLevel(question)" size="x-small" variant="tonal"
										:color="getQuestionCognitiveLevel(question).color" class="ml-2 font-weight-medium">
										<v-icon start size="12">mdi-chart-timeline-variant</v-icon>
										{{ getQuestionCognitiveLevel(question).title }}
									</v-chip>
									<span class="ml-2" v-if="question.type?.includes('QUIZ')">
										<v-chip size="x-small" color="red"
											v-if="vueData.isCheckAnswerQuestionNotChoose(question)">
											{{ $t('message.NoAnswer') }}
										</v-chip>
									</span>
									<span class="ml-2 d-flex ga-2">
										<v-chip size="small" v-if="question.config.media.sourceYT.source?.length > 0"
											color="red">
											<v-icon>mdi-video-outline</v-icon>
										</v-chip>
										<v-chip size="small"
											v-if="question.config.media.sourceRecord.source?.length > 0" color="teal">
											<v-icon>mdi-multimedia</v-icon>
										</v-chip>
										<v-chip size="small"
											v-if="question.config.media.sourceFiles.file?.length > 0 || question.config.media.sourceFiles.image?.length > 0"
											color="blue">
											<v-icon>mdi-file</v-icon>
										</v-chip>
									</span>
								</v-list-item-title>
								<v-list-item-subtitle>
									<uc-latex-view v-model:content="question.config.questionText" class="flex-column"
										:escapeHtml="false"
										style="-webkit-box-orient: unset; word-break: break-word; line-height: 1.25rem !important; align-items: unset !important; display: table !important;" />
								</v-list-item-subtitle>
								<div v-if="hasMedia(question.config.media)" class="assignment-canvas-media mt-2" @click.stop>
									<iframe v-if="question.config.media.sourceYT?.source" :src="renderUrlYoutube(question.config.media.sourceYT.source)" :title="IsEngLish ? 'Question video' : 'Video câu hỏi'" />
									<div v-if="question.config.media.sourceRecord?.source" class="assignment-canvas-audio">
										<uc-wave-audio-player :audioUrl="question.config.media.sourceRecord.source" />
									</div>
									<div v-if="question.config.media.sourceFiles?.image?.length || question.config.media.sourceFiles?.file?.length"
										class="assignment-canvas-media-grid">
										<v-img v-for="(file, index) in (question.config.media.sourceFiles?.image || [])" :key="file.id || index" :src="imageSource(file)" />
										<div v-for="(file, index) in (question.config.media.sourceFiles?.file || [])"
											:key="file.id || index" class="assignment-canvas-file-card">
											<div class="assignment-canvas-file-link">
												<v-icon color="primary">mdi-file-document-outline</v-icon>
												<div class="assignment-canvas-file-info">
													<a :href="fileSource(file)" target="_blank" rel="noopener" :title="file.name">
														{{ file.name || (IsEngLish ? 'Attachment' : 'Tệp đính kèm') }}
													</a>
													<span v-if="file.fileSize" class="assignment-canvas-file-size">{{ formatFileSize(file.fileSize) }}</span>
												</div>
												<v-btn :href="fileSource(file)" target="_blank" rel="noopener" icon="mdi-open-in-new"
													variant="tonal" size="x-small" color="primary" :title="IsEngLish ? 'Open file' : 'Mở file'" />
											</div>
										</div>
									</div>
								</div>
							</v-list-item>

							<!-- Drop indicator phía dưới (chỉ hiện ở item cuối) -->
							<div v-if="showDropIndicator(groupIndex, qIndex, 'after')" class="drop-indicator"></div>
						</div>
					</v-list>

					<!-- Empty state với drop zone -->
					<div v-else class="empty-group-placeholder"
						:class="{ 'drag-over': dragOverGroupIndex === groupIndex }"
						@dragover.prevent="handleEmptyGroupDragOver"
						@dragenter.prevent="handleEmptyGroupDragEnter($event, groupIndex)"
						@dragleave="handleEmptyGroupDragLeave" @drop.prevent="handleEmptyGroupDrop($event, groupIndex)">
						<v-icon class="mb-2" color="grey-lighten-1">mdi-inbox-arrow-down</v-icon>
						<div class="text-grey">{{ $t('message.DropQuestionHere') }}</div>
					</div>
				</div>
			</v-card>
		</div>

		<v-btn v-if="!hasMatrixGroup" block variant="elevated" color="primary" class="mt-4" @click="addGroup"
			style="position: sticky;bottom: -4px;">
			<v-icon start>mdi-plus-box-outline</v-icon>
			{{ $t('message.AddNewSection') }}
		</v-btn>

	</div>
</template>

<script>
	export default {
		inject: ['confirmRef'],
	props: {
		groups: { type: Array, default: () => [] },
		selectedItem: Object, // { type, groupIndex, qIndex }
		canImportFromHocLieu: { type: Boolean, default: false },
		assignment: { type: Object, default: () => ({}) }
	},
	emits: ['update:groups', 'update:selectedItem', 'open-group-import'],
	data() {
		return {
			draggedQuestion: null, // { groupIndex, qIndex, question }
			dragOverGroupIndex: null,
			dragOverPosition: null, // { groupIndex, qIndex, position }
			expandedMatrixGroups: {},
			questionGroups: [],
			groupQuestionsCache: {},
			isReloadingMatrixGroups: false,
			skillMatrixSourcesByGroup: {},
			vueData
		}
	},
	computed: {
		IsEngLish() {
			if (this.$i18n?.locale === 'en') return true
			try {
				const isLang = JSON.parse(localStorage.getItem('IsLanguage'))
				return isLang === true || isLang === 'true'
			} catch (e) {
				return localStorage.getItem('IsLanguage') === 'true'
			}
		},
		questionHeaders() {
			return [
				{ title: this.IsEngLish ? 'Question Content' : 'Nội dung câu hỏi', key: 'QuestionText', sortable: false, width: 420 },
				{ title: this.IsEngLish ? 'Correct Answer' : 'Đáp án đúng', key: 'AnswerPreview', sortable: false, width: 340 },
				{ title: this.IsEngLish ? 'Type' : 'Loại', key: 'Type', width: 190, sortable: false },
				{ title: this.IsEngLish ? 'Score' : 'Điểm', key: 'Points', width: 80, align: 'center' },
			]
		},
		khoiId() {
			return Number(this.assignment?.KhoiID || this.vueData?.KhoiID || this.vueData?.assignment?.KhoiID || 0)
		},
		monHocId() {
			return Number(this.assignment?.MonHocID || this.vueData?.MonHocID || this.vueData?.assignment?.MonHocID || 0)
		},
		hasMatrixGroup() {
			return (this.groups || []).some(g => this.isMatrixGroup(g))
		},
		getTotalQuestion() {
			let number = 0
			for (let i = 0; i < this.groups.length; i++) {
				number += this.groups[i].questions.length
			}
			return number
		},
		cognitiveLevelsDefinition() {
			return [
				{
					key: 'cog_nhan_biet',
					title: this.IsEngLish ? 'Recognition' : 'Nhận biết',
					description: this.IsEngLish ? 'Recall, recognize or repeat learned knowledge, definitions, facts' : 'Nhớ lại, nhận ra hoặc nhắc lại các kiến thức, định nghĩa, sự kiện đã học',
					matchedNames: ['nhận biết', 'nhan biet', 'nhận biết (nhớ lại)', 'recognition']
				},
				{
					key: 'cog_thong_hieu',
					title: this.IsEngLish ? 'Comprehension' : 'Thông hiểu',
					description: this.IsEngLish ? 'Interpret, explain, compare or summarize knowledge in one\'s own words' : 'Diễn giải, giải thích, so sánh hoặc tóm tắt lại kiến thức bằng ngôn ngữ/cách hiểu của riêng mình',
					matchedNames: ['thông hiểu', 'thong hieu', 'hiểu biết', 'thông hiểu (hiểu biết)', 'comprehension']
				},
				{
					key: 'cog_van_dung',
					title: this.IsEngLish ? 'Application' : 'Vận dụng',
					description: this.IsEngLish ? 'Use learned knowledge and skills to solve familiar problems or similar situations' : 'Dùng kiến thức, kỹ năng đã học để giải quyết các vấn đề, bài tập quen thuộc hoặc tình huống tương tự',
					matchedNames: ['vận dụng', 'van dung', 'vận dụng thấp', 'application']
				},
				{
					key: 'cog_van_dung_cao',
					title: this.IsEngLish ? 'High Application' : 'Vận dụng cao',
					description: this.IsEngLish ? 'Synthesize knowledge and skills to solve complex problems, creative thinking, logical deduction' : 'Dùng tổng hợp kiến thức, kỹ năng để giải quyết các vấn đề phức tạp, tư duy sáng tạo, suy luận logic',
					matchedNames: ['vận dụng cao', 'van dung cao', 'nâng cao', 'high application']
				}
			]
		}
	},
	watch: {
		'groups': {
			handler() {
				this.initMatrixDataFromGroups()
			},
			immediate: true,
			deep: true
		}
	},
	mounted() {
		this.loadQuestionGroups()
		window.addEventListener('focus', this.onWindowFocus)
	},
	beforeUnmount() {
		window.removeEventListener('focus', this.onWindowFocus)
	},
	methods: {
		onWindowFocus() {
			if (this.hasMatrixGroup) {
				this.loadQuestionGroups(true)
			}
		},
		rows(result) {
			const value = result?.value ?? result?.data ?? result?.rows ?? result
			return Array.isArray(value) ? value.flat() : [value]
		},
		parseJson(raw, fallback = null) {
			if (!raw) return fallback
			if (typeof raw === 'object') return raw
			try {
				return JSON.parse(raw)
			} catch (e) {
				return fallback
			}
		},
		questionKey(item) {
			return String(item?.Id ?? item?.ID ?? item?.QuestionId ?? '')
		},
		getQuestionText(item) {
			const config = item?.ParsedConfig || this.parseJson(item?.ConfigJson, {})
			return String(item?.QuestionText || item?.Content || item?.TenCauHoi || config?.questionText || '').trim()
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
					// Content Hub dùng from/to; dữ liệu cũ của Question Bank dùng aId/bId.
					// Chuẩn hóa lúc đọc để phần xem đáp án không bị rỗng dù cặp nối vẫn tồn tại.
					const left = itemById.get(String(pair?.aId ?? pair?.leftId ?? pair?.sourceId ?? pair?.from ?? ''))
					const right = itemById.get(String(pair?.bId ?? pair?.rightId ?? pair?.targetId ?? pair?.to ?? ''))
					if (!left || !right) return null
					return { id: pair.id || index, label: `${index + 1}.`, text: `${this.getAnswerText(left)} → ${this.getAnswerText(right)}`, correct: true }
				}).filter(Boolean)
			}
			const options = Array.isArray(config.options) ? config.options : []
			if (options.length) {
				if (item?.Type === 'QUIZ_MULTIPLE_TRUE_FALSE') {
					return options.map((option, index) => ({
						id: option.id || index,
						label: `${String.fromCharCode(65 + index)}.`,
						text: option.correctAnswer === true ? 'Đ' : (option.inCorrectAnswer === true ? 'S' : '—'),
						correct: false,
					}))
				}
				return options.reduce((answers, option, index) => {
					if (option.correctAnswer === true || option.isTrue === true) {
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
			return []
		},
		getAnswerText(option) {
			if (typeof option === 'string' || typeof option === 'number') return String(option)
			const value = option?.text ?? option?.label ?? option?.value ?? option?.content ?? ''
			if (typeof value === 'string') return value
			return value?.html || value?.content || value?.text || ''
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
					// Giữ nguyên from/to để tương thích dữ liệu Content Hub, đồng thời bổ sung alias chuẩn của Soạn bài tập.
					aId: pair?.aId ?? pair?.leftId ?? pair?.sourceId ?? pair?.from,
					bId: pair?.bId ?? pair?.rightId ?? pair?.targetId ?? pair?.to,
				}))
			}
			return normalized
		},
		parseQuestion(item) {
			const config = this.normalizeImportedConfig(item?.Type, this.parseJson(item?.ConfigJson, {}))
			const skills = this.parseJson(item?.SkillsJson, [])
			const type = item.Type
			const sourceTracking = {
				...(config.sourceTracking || {}),
				sourceType: 'CONTENT_HUB',
				sourceKind: 'QUESTION_BANK',
				questionId: item.Id,
				groupId: item.GroupId,
				importedAt: new Date().toISOString()
			}
			return {
				id: `q_${crypto.randomUUID()}`,
				type,
				label: type,
				points: Number(item.Points || 1),
				gradingType: item.GradingType || (type?.startsWith('QUIZ_') ? 'auto' : 'manual'),
				skills: Array.isArray(skills) ? skills : [],
				config: {
					...config,
					questionText: this.getQuestionText(item),
					isAdvanced: Boolean(item.IsAdvanced || config.isAdvanced),
					media: config.media || {
						type: 'YOUTUBE',
						sourceYT: { id: '', name: '', source: '' },
						sourceRecord: { id: '', name: '', source: '' },
						sourceFiles: { file: [], image: [] }
					}
				},
				sourceTracking,
			}
		},
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
		getCognitiveChipColor(title) {
			const map = {
				'Nhận biết': 'info',
				'Recognition': 'info',
				'Thông hiểu': 'teal',
				'Comprehension': 'teal',
				'Vận dụng': 'orange',
				'Application': 'orange',
				'Vận dụng cao': 'deep-purple',
				'High Application': 'deep-purple'
			}
			return map[title] || 'indigo'
		},
		getQuestionCognitiveLevel(question) {
			// Câu hỏi trong bài tập có thể đến từ ngân hàng cũ hoặc Content Hub, nên đọc cả config và các biến thể của skills.
			if (!question) return null
			const config = question.config || {}
			const skills = Array.isArray(question.skills) ? question.skills : []
			const normalize = value => String(value ?? '')
				.normalize('NFD')
				.replace(/[\u0300-\u036f]/g, '')
				.trim()
				.toLowerCase()
			const values = [
				config.questionLevel,
				config.QuestionLevel,
				config.MucDo,
				config.MucDoCode,
				config.Level,
				config.LevelCode,
				...skills.flatMap(skill => typeof skill === 'object' && skill !== null
					? [skill.TenKyNang, skill.name, skill.title, skill.MucDo, skill.MucDoCode, skill.SkillCode, skill.NhomKyNang, skill.group]
					: [skill])
			].map(normalize).filter(Boolean)
			const searchable = values.join(' | ')
			const aliases = {
				cog_van_dung_cao: ['van dung cao', 'van_dung_cao', 'nang cao', 'high application'],
				cog_van_dung: ['van dung', 'van_dung', 'application'],
				cog_thong_hieu: ['thong hieu', 'thong_hieu', 'hieu biet', 'comprehension'],
				cog_nhan_biet: ['nhan biet', 'nhan_biet', 'recognition']
			}
			// Ưu tiên mức cụ thể hơn trước; nếu không, “Vận dụng cao” sẽ bị khớp sớm vào từ “Vận dụng”.
			const order = ['cog_van_dung_cao', 'cog_van_dung', 'cog_thong_hieu', 'cog_nhan_biet']
			for (const key of order) {
				if (aliases[key].some(alias => searchable.includes(alias))) {
					const def = this.cognitiveLevelsDefinition.find(level => level.key === key)
					if (def) {
						return {
							...def,
							color: this.getCognitiveChipColor(def.title)
						}
					}
				}
			}
			return null
		},
		async loadQuestionGroups(force = false) {
			if (!this.khoiId && !this.monHocId) return
			if (force) {
				this.isReloadingMatrixGroups = true
				this.groupQuestionsCache = {}
			}
			try {
				const result = await fetchPromise('lms/EL_QuestionGroup_List', {
					KhoiID: this.khoiId,
					MonHocID: this.monHocId,
					IncludeDeleted: false,
					PageNumber: 1,
					PageSize: 100
				}, { forceRefresh: true, cache: false })
				this.questionGroups = this.rows(result).filter(item => item?.Id)
				const fetchPromises = []
				this.groups.forEach((g, idx) => {
					if (this.isMatrixGroup(g)) {
						if (force) {
							delete this.skillMatrixSourcesByGroup[idx]
						}
						this.initMatrixDataForGroupIndex(idx)
						const groupSources = this.skillMatrixSourcesByGroup[idx] || {}
						Object.values(groupSources).forEach(sources => {
							(sources || []).forEach(s => {
								if (s.groupId) {
									fetchPromises.push(this.fetchQuestionsForGroup(s.groupId, true))
								}
							})
						})
					}
				})
				if (fetchPromises.length) {
					await Promise.allSettled(fetchPromises)
				}
			} catch (error) {
				console.error('Không thể tải nhóm câu hỏi cho ma trận:', error)
			} finally {
				this.isReloadingMatrixGroups = false
			}
		},
		initMatrixDataFromGroups() {
			(this.groups || []).forEach((group, groupIndex) => {
				if (this.isMatrixGroup(group)) {
					this.initMatrixDataForGroupIndex(groupIndex)
				}
			})
		},
		initMatrixDataForGroupIndex(groupIndex) {
			const group = this.groups[groupIndex]
			if (!group) return
			const matrixConfigs = group?.questionSource?.matrixConfigs || []
			if (!this.skillMatrixSourcesByGroup[groupIndex]) {
				const sourcesMap = {}
				this.cognitiveLevelsDefinition.forEach(level => {
					const config = matrixConfigs.find(c => c.skillId === level.key)
					if (config && Array.isArray(config.sources) && config.sources.length) {
						sourcesMap[level.key] = config.sources.map(s => ({
							id: s.sourceId || `${level.key}_source_${Date.now()}_${Math.random()}`,
							groupId: s.groupId,
							count: s.randomCount || 0,
							selectedQuestionIds: s.questionIds || []
						}))
						// Pre-fetch questions for groups in config
						config.sources.forEach(s => {
							if (s.groupId) this.fetchQuestionsForGroup(s.groupId)
						})
					} else {
						const defaultGroupId = this.questionGroups[0]?.Id || null
						sourcesMap[level.key] = [{ id: `${level.key}_source_0`, groupId: defaultGroupId, count: 0 }]
						if (defaultGroupId) this.fetchQuestionsForGroup(defaultGroupId)
					}
				})
				this.skillMatrixSourcesByGroup[groupIndex] = sourcesMap
			}
		},
		async fetchQuestionsForGroup(groupId, force = false) {
			if (!groupId || (!force && this.groupQuestionsCache[groupId])) return
			try {
				const result = await fetchPromise('lms/EL_Question_List', {
					GroupId: groupId,
					Type: '',
					Search: '',
					IncludeDeleted: false,
					PageNumber: 1,
					PageSize: 200
				}, { forceRefresh: true, cache: false })
				const loaded = this.rows(result).map(item => ({
					...item,
					_contentHubGroupId: item.GroupId ?? item.GroupID ?? groupId,
					ParsedConfig: this.normalizeImportedConfig(item.Type, this.parseJson(item.ConfigJson, {})),
				}))
				this.groupQuestionsCache = { ...this.groupQuestionsCache, [groupId]: loaded }
			} catch (e) {
				console.error('Không thể tải câu hỏi nhóm:', groupId, e)
			}
		},
		getQuestionsForGroup(groupId) {
			if (!groupId) return []
			return this.groupQuestionsCache[groupId] || []
		},
		getSkillMatrixSources(groupIndex, skillKey) {
			const groupSources = this.skillMatrixSourcesByGroup[groupIndex]
			if (groupSources && Array.isArray(groupSources[skillKey]) && groupSources[skillKey].length) {
				return groupSources[skillKey]
			}
			const defaultGroupId = this.questionGroups[0]?.Id || null
			return [{ id: `${skillKey}_source_0`, groupId: defaultGroupId, count: 0 }]
		},
		updateSkillMatrixSources(groupIndex, skillKey, sources) {
			const groupSources = { ...(this.skillMatrixSourcesByGroup[groupIndex] || {}) }
			groupSources[skillKey] = sources
			this.skillMatrixSourcesByGroup = {
				...this.skillMatrixSourcesByGroup,
				[groupIndex]: groupSources
			}
			this.syncMatrixToGroup(groupIndex)
		},
		addMatrixSource(groupIndex, skillKey) {
			const sources = [...this.getSkillMatrixSources(groupIndex, skillKey)]
			const defaultGroupId = this.questionGroups[0]?.Id || null
			sources.push({
				id: `${skillKey}_source_${Date.now()}_${sources.length}`,
				groupId: defaultGroupId,
				count: 0
			})
			this.updateSkillMatrixSources(groupIndex, skillKey, sources)
		},
		removeMatrixSource(groupIndex, skillKey, sourceId) {
			const sources = this.getSkillMatrixSources(groupIndex, skillKey).filter(s => s.id !== sourceId)
			const defaultGroupId = this.questionGroups[0]?.Id || null
			this.updateSkillMatrixSources(groupIndex, skillKey, sources.length ? sources : [{ id: `${skillKey}_source_0`, groupId: defaultGroupId, count: 0 }])
		},
		onMatrixSourceCountChange(groupIndex, skillKey, sourceId, value) {
			const sources = this.getSkillMatrixSources(groupIndex, skillKey).map(source => {
				if (source.id !== sourceId) return source
				const available = this.getMatrixSourceAvailableCount(groupIndex, skillKey, sourceId)
				return { ...source, count: Math.min(Math.max(Number(value) || 0, 0), available) }
			})
			this.updateSkillMatrixSources(groupIndex, skillKey, sources)
		},
		async onMatrixSourceGroupChange(groupIndex, skillKey, sourceId, groupId) {
			const sources = this.getSkillMatrixSources(groupIndex, skillKey).map(source => {
				if (source.id !== sourceId) return source
				return { ...source, groupId, count: 0, selectedQuestionIds: [] }
			})
			this.updateSkillMatrixSources(groupIndex, skillKey, sources)
			if (groupId) {
				await this.fetchQuestionsForGroup(groupId)
				this.syncMatrixToGroup(groupIndex)
			}
		},
		fillSkillMatrixSources(groupIndex, skillKey) {
			const skill = this.getMatrixSkillItemsForGroup(groupIndex).find(item => item.key === skillKey)
			const sources = this.getSkillMatrixSources(groupIndex, skillKey).map(source => {
				const detail = skill?.sources?.find(s => s.id === source.id)
				return { ...source, count: detail?.availableCount || 0 }
			})
			this.updateSkillMatrixSources(groupIndex, skillKey, sources)
		},
		getMatrixSkillItemsForGroup(groupIndex) {
			return this.cognitiveLevelsDefinition.map(level => {
				const configuredSources = this.getSkillMatrixSources(groupIndex, level.key)
				const sourceDetails = configuredSources.map(source => {
					const groupQuestions = this.getQuestionsForGroup(source.groupId)
					const taggedQuestions = groupQuestions
						.filter(item => this.matchesCognitiveLevel(item, level))
						.map(item => ({ ...item, _matrixSourceId: source.id, _isMatchedCognitive: true }))
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
		getSkillConfiguredCount(groupIndex, skillKey) {
			return this.getSkillMatrixSources(groupIndex, skillKey).reduce((sum, source) => sum + Math.max(Number(source.count) || 0, 0), 0)
		},
		getMatrixSourceAvailableCount(groupIndex, skillKey, sourceId) {
			const skill = this.getMatrixSkillItemsForGroup(groupIndex).find(item => item.key === skillKey)
			return skill?.sources?.find(source => source.id === sourceId)?.availableCount || 0
		},
		getMatrixConfiguredTotal(groupIndex) {
			return this.cognitiveLevelsDefinition.reduce((sum, lvl) => sum + this.getSkillConfiguredCount(groupIndex, lvl.key), 0)
		},
		getSkillPercent(groupIndex, item) {
			const count = this.getSkillConfiguredCount(groupIndex, item.key)
			const totalPicked = this.getMatrixConfiguredTotal(groupIndex)
			if (totalPicked > 0) return Math.round((count / totalPicked) * 100)
			return 0
		},
		getMatrixTotalStatus(groupIndex) {
			const current = this.getMatrixConfiguredTotal(groupIndex)
			const activeSkillsCount = this.cognitiveLevelsDefinition.filter(lvl => this.getSkillConfiguredCount(groupIndex, lvl.key) > 0).length
			if (current === 0) {
				return { color: 'grey', text: this.IsEngLish ? 'No questions configured' : 'Chưa cấu hình câu hỏi' }
			}
			return { color: 'teal', text: this.IsEngLish ? `Allocated: ${activeSkillsCount}/4 levels` : `Đã phân bổ: ${activeSkillsCount}/4 mức độ` }
		},
		resetMatrixForGroup(groupIndex) {
			const defaultGroupId = this.questionGroups[0]?.Id || null
			const sourcesMap = {}
			this.cognitiveLevelsDefinition.forEach(lvl => {
				sourcesMap[lvl.key] = [{ id: `${lvl.key}_source_0`, groupId: defaultGroupId, count: 0 }]
			})
			this.skillMatrixSourcesByGroup[groupIndex] = sourcesMap
			this.syncMatrixToGroup(groupIndex)
		},
		syncMatrixToGroup(groupIndex) {
			const group = this.groups[groupIndex]
			if (!group || !this.isMatrixGroup(group)) return

			const matrixConfigs = []
			const allGroupQuestions = []
			const seenQuestionKeys = new Set()
			const skillItems = this.getMatrixSkillItemsForGroup(groupIndex)

			skillItems.forEach(skill => {
				const sourceConfigs = skill.sources.map(source => {
					const pool = source.taggedQuestions || []
					const configuredCount = Math.max(Number(source.count) || 0, 0)
					const questionIds = pool.map(item => item.Id).filter(id => id !== undefined && id !== null).map(String)

					return {
						sourceId: source.id,
						groupId: source.groupId,
						groupTitle: this.questionGroups.find(g => String(g.Id) === String(source.groupId))?.Title || '',
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
					const sourceQuestions = sourceDetail?.taggedQuestions || []
					sourceQuestions.forEach(item => {
						const id = String(item.Id ?? this.questionKey(item))
						if (!seenIds.has(id)) {
							seenIds.add(id)
							uniqueQuestions.push(item)
						}
					})
				})

				uniqueQuestions.forEach(item => {
					const key = this.questionKey(item)
					if (!seenQuestionKeys.has(key)) {
						seenQuestionKeys.add(key)
						allGroupQuestions.push(this.parseQuestion(item))
					}
				})

				matrixConfigs.push({
					skillId: skill.key,
					skillName: skill.title,
					skillGroup: skill.group,
					randomCount: sourceConfigs.reduce((sum, source) => sum + source.randomCount, 0),
					availableCount: uniqueQuestions.length,
					questions: uniqueQuestions.map(item => this.parseQuestion(item)),
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

			const totalConfiguredQuestions = matrixConfigs.reduce((sum, config) => sum + (Number(config.randomCount) || 0), 0)
			const newGroups = JSON.parse(JSON.stringify(this.groups))
			newGroups[groupIndex] = {
				...newGroups[groupIndex],
				questions: allGroupQuestions,
				questionSource: {
					sourceType: 'CONTENT_HUB',
					sourceKind: 'QUESTION_BANK_SKILL_MATRIX',
					matrixMode: true,
					matrixConfigs,
					questionIds: allGroupQuestions.map(q => q.sourceTracking?.questionId || q.id),
					poolSize: allGroupQuestions.length,
				},
				questionSelection: {
					mode: 'RANDOM',
					matrixMode: true,
					questionsPerAttempt: totalConfiguredQuestions,
				}
			}

			this._reorderOrdinalNumbers(newGroups)
			this.$emit('update:groups', newGroups)
		},
		hasMedia(media) {
			return !!(media?.sourceYT?.source || media?.sourceRecord?.source || media?.sourceFiles?.image?.length || media?.sourceFiles?.file?.length)
		},
		imageSource(file) {
			const source = file?.externalSource || file?.source
			if (!source) return ''
			if (!source.includes('drive.google.com')) return this.fileSource(file)
			return `https://drive.google.com/thumbnail?id=${file.externalId || file.id || this.getDriveFileId(source)}&sz=w1000`
		},
		fileSource(file) {
			const source = file?.externalSource || file?.source || ''
			if (!source) return source
			if (/^https?:\/\/lms\.lhbs\.vn\/FileData\//i.test(source)) {
				return source.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/')
			}
			if (/^https?:\/\//i.test(source)) return source
			if (file?.mediaSource !== 'db') return source

			const base = vueData?.v_Set?.urlReadFile || ''
			if (!base) return source
			return `${base.replace(/\/+$/, '')}/${source.replace(/^\/+/, '')}`
		},
		getDriveFileId(url) {
			const match = url?.match(/\/d\/([^/]+)/)
			return match ? match[1] : null
		},
		formatFileSize(size) {
			const value = Number(size || 0)
			if (!value) return ''
			if (value < 1024) return `${value} B`
			if (value < 1024 * 1024) return `${(value / 1024).toFixed(1)} KB`
			return `${(value / (1024 * 1024)).toFixed(1)} MB`
		},
		renderUrlYoutube,
		stripHtml(html) {
			if (!html) return this.IsEngLish ? 'No content' : 'Chưa có nội dung';
			let doc = new DOMParser().parseFromString(html, 'text/html');
			return doc.body.textContent || "";
		},
		isMatrixGroup(group) {
			return group?.questionSource?.sourceKind === 'QUESTION_BANK_SKILL_MATRIX' ||
				group?.questionSource?.matrixMode === true ||
				group?.questionSelection?.matrixMode === true;
		},
		// Group RANDOM tiêu chuẩn bốc trên toàn bộ câu trong group.
		// questionSource.questionIds chỉ là metadata nguồn, không phải giới hạn pool của group.
		getRandomPoolSize(group) {
			return Array.isArray(group?.questions) ? group.questions.length : 0
		},
		getRandomScoreHint(group) {
			if (group?.questionSelection?.mode !== 'RANDOM') return ''
			const count = this.isMatrixGroup(group)
				? this.getMatrixConfiguredCount(group)
				: Number(group.questionSelection?.questionsPerAttempt)
			return Number.isFinite(count) && count > 0 ? (this.IsEngLish ? `${count} random questions` : `${count} câu bốc ngẫu nhiên`) : ''
		},
		// Điểm hiển thị của group random phải phản ánh số câu thực tế mỗi lượt.
		getEffectiveGroupScore(group) {
			const questions = Array.isArray(group?.questions) ? group.questions : []
			const poolScore = questions.reduce((sum, question) => {
				const points = Number(question?.points ?? 0)
				return sum + (Number.isFinite(points) && points > 0 ? points : 0)
			}, 0)
			if (group?.questionSelection?.mode !== 'RANDOM') return poolScore

			const requested = Math.floor(Number(group.questionSelection?.questionsPerAttempt))
			const count = Math.min(
				Math.max(Number.isFinite(requested) ? requested : 0, 0),
				questions.length
			)
			return questions.length ? poolScore * (count / questions.length) : 0
		},
		getMatrixConfiguredCount(group) {
			const configs = group?.questionSource?.matrixConfigs || [];
			if (configs.length) {
				return configs.reduce((sum, item) => sum + (Number(item.randomCount) || 0), 0);
			}
			return Number(group?.questionSelection?.questionsPerAttempt) || group?.questions?.length || 0;
		},
		getMatrixLevels(group) {
			const configs = group?.questionSource?.matrixConfigs || [];
			const colorMap = {
				cog_nhan_biet: 'info',
				cog_thong_hieu: 'teal',
				cog_van_dung: 'orange',
				cog_van_dung_cao: 'deep-purple',
			};
			if (configs.length) {
				return configs.map(config => ({
					key: config.skillId,
					title: config.skillName,
					color: colorMap[config.skillId] || 'indigo',
					randomCount: Number(config.randomCount) || 0,
					availableCount: Number(config.availableCount) || (config.questionIds || []).length || 0,
					sources: config.sources || [],
				}));
			}
			return [
				{ key: 'cog_nhan_biet', title: this.IsEngLish ? 'Recognition' : 'Nhận biết', color: 'info', randomCount: 0, availableCount: 0, sources: [] },
				{ key: 'cog_thong_hieu', title: this.IsEngLish ? 'Comprehension' : 'Thông hiểu', color: 'teal', randomCount: 0, availableCount: 0, sources: [] },
				{ key: 'cog_van_dung', title: this.IsEngLish ? 'Application' : 'Vận dụng', color: 'orange', randomCount: 0, availableCount: 0, sources: [] },
				{ key: 'cog_van_dung_cao', title: this.IsEngLish ? 'High Application' : 'Vận dụng cao', color: 'deep-purple', randomCount: 0, availableCount: 0, sources: [] },
			];
		},
		isMatrixDetailsExpanded(groupIndex) {
			return Boolean(this.expandedMatrixGroups[groupIndex]);
		},
		toggleMatrixDetails(groupIndex) {
			this.expandedMatrixGroups = {
				...this.expandedMatrixGroups,
				[groupIndex]: !this.expandedMatrixGroups[groupIndex]
			};
		},
		getGlobalQuestionNumber(groupIndex, qIndex) {
			let number = 1;
			for (let i = 0; i < groupIndex; i++) {
				number += this.groups[i].questions.length;
			}
			return number + qIndex;
		},
		selectItem(type, groupIndex, qIndex = null) {
			if (type === 'group') {
				const group = this.groups?.[groupIndex]
				if (this.isMatrixGroup(group)) {
					return
				}
			}
			this.$emit('update:selectedItem', { type, groupIndex, qIndex });
		},
		isSelectedQuestion(groupIndex, qIndex) {
			return this.selectedItem?.type === 'question' &&
				this.selectedItem?.groupIndex === groupIndex &&
				this.selectedItem?.qIndex === qIndex;
		},
		isDragging(groupIndex, qIndex) {
			return this.draggedQuestion?.groupIndex === groupIndex &&
				this.draggedQuestion?.qIndex === qIndex;
		},
		showDropIndicator(groupIndex, qIndex, position) {
			if (!this.dragOverPosition) return false;

			const isSameGroup = this.dragOverPosition.groupIndex === groupIndex;
			const isSameIndex = this.dragOverPosition.qIndex === qIndex;
			const isSamePosition = this.dragOverPosition.position === position;

			if (this.draggedQuestion &&
				this.draggedQuestion.groupIndex === groupIndex &&
				this.draggedQuestion.qIndex === qIndex) {
				return false;
			}

			if (position === 'after') {
				const isLastItem = qIndex === this.groups[groupIndex].questions.length - 1;
				return isLastItem && isSameGroup && isSameIndex && isSamePosition;
			}

			return isSameGroup && isSameIndex && isSamePosition;
		},
		addGroup() {
			const newGroups = [...this.groups];
			newGroups.push({
				id: `group_${crypto.randomUUID()}`,
				title: `${this.$i18n.locale == 'en' ? 'Section' : 'Phần'} ${newGroups.length + 1}`,
				description: '',
				content: '',
				media: {
					type: "YOUTUBE",
					sourceYT: { id: "", source: "", name: "" },
					sourceIMGs: [],
					sourceRecord: { id: "", source: "", name: "" },
					sourceFiles: {
						file: [],
						image: []
					}
				},
				questions: []
			});
			this.$emit('update:groups', newGroups);
		},
		async removeGroup(groupIndex) {
			const group = this.groups[groupIndex];
			if (!group) return;
			if ((group.questions || []).length === 0) {
				const newGroups = this.groups.filter((_, index) => index !== groupIndex);
				this.$emit('update:groups', newGroups);
				this.$emit('update:selectedItem', null);
				return;
			}
			if (this.confirmRef?.value?.show) {
				const ok = await this.confirmRef.value.show({
					title: this.IsEngLish ? "Confirm section deletion" : "Xác nhận xóa phần",
					text: this.IsEngLish ? `Are you sure you want to delete "${group.title || 'this section'}" with ${group.questions.length} questions?` : `Bạn có chắc chắn muốn xóa toàn bộ "${group.title || 'Phần này'}" gồm ${group.questions.length} câu hỏi không?`
				});
				if (!ok) return;
			} else if (typeof window !== 'undefined' && typeof window.confirm === 'function') {
				const ok = window.confirm(this.IsEngLish ? `Are you sure you want to delete "${group.title || 'this section'}"?` : `Bạn có chắc muốn xóa toàn bộ "${group.title || 'Phần này'}" không?`);
				if (!ok) return;
			}
			const newGroups = this.groups.filter((_, index) => index !== groupIndex);
			this.$emit('update:groups', newGroups);
			this.$emit('update:selectedItem', null);
		},
		removeQuestion(groupIndex, qIndex) {
			const newGroups = JSON.parse(JSON.stringify(this.groups));
			newGroups[groupIndex].questions.splice(qIndex, 1);
			this.$emit('update:groups', newGroups);
			this.$emit('update:selectedItem', null);
		},
		renderPointInGroup(group) {
			return this.formatNumber(this.getEffectiveGroupScore(group), 2)
		},

		formatNumber(value, decimals = 2) {
			if (isNaN(value)) return (0).toFixed(decimals)
			return Number(value).toFixed(decimals)
		},
		moveQuestion(groupIndex, qIndex, direction) {
			const newGroups = JSON.parse(JSON.stringify(this.groups))
			const questions = newGroups[groupIndex].questions
			const targetIndex = direction === 'up' ? qIndex - 1 : qIndex + 1
			if (targetIndex < 0 || targetIndex >= questions.length) return
			const temp = questions[qIndex]
			questions[qIndex] = questions[targetIndex]
			questions[targetIndex] = temp
			this.$emit('update:groups', newGroups)
			this.$emit('update:selectedItem', { type: 'question', groupIndex, qIndex: targetIndex })
		},
		// Drag & Drop handlers for questions
		handleQuestionDragStart(event, groupIndex, qIndex) {
			this.draggedQuestion = {
				groupIndex,
				qIndex,
				question: JSON.parse(JSON.stringify(this.groups[groupIndex].questions[qIndex]))
			};

			event.dataTransfer.effectAllowed = 'move';
			event.target.classList.add('dragging');
		},

		handleDragEnd(event) {
			event.target.classList.remove('dragging');
			this.draggedQuestion = null;
			this.dragOverGroupIndex = null;
			this.dragOverPosition = null;
		},

		handleQuestionDragEnter(event, groupIndex, qIndex) {
			if (!this.draggedQuestion) return;

			if (this.draggedQuestion.groupIndex === groupIndex &&
				this.draggedQuestion.qIndex === qIndex) {
				return;
			}
		},

		handleQuestionDragLeave(event) {
			if (!event.currentTarget.contains(event.relatedTarget)) {
				this.dragOverPosition = null;
			}
		},

		handleQuestionDragOver(event, groupIndex, qIndex) {
			if (!this.draggedQuestion) return;

			if (this.draggedQuestion.groupIndex === groupIndex &&
				this.draggedQuestion.qIndex === qIndex) {
				return;
			}

			const rect = event.currentTarget.getBoundingClientRect();
			const mouseY = event.clientY;
			const itemCenterY = rect.top + rect.height / 2;

			const position = mouseY < itemCenterY ? 'before' : 'after';

			this.dragOverPosition = {
				groupIndex,
				qIndex,
				position
			};
		},

		handleQuestionDrop(event, targetGroupIndex, targetQIndex) {
			if (!this.draggedQuestion || !this.dragOverPosition) return;

			const { groupIndex: sourceGroupIndex, qIndex: sourceQIndex, question } = this.draggedQuestion;
			const { position } = this.dragOverPosition;

			const newGroups = JSON.parse(JSON.stringify(this.groups));

			let insertIndex = targetQIndex;
			if (position === 'after') {
				insertIndex += 1;
			}

			if (sourceGroupIndex === targetGroupIndex) {
				if (sourceQIndex < insertIndex) {
					insertIndex -= 1;
				}

				if (sourceQIndex === insertIndex) {
					return;
				}

				newGroups[sourceGroupIndex].questions.splice(sourceQIndex, 1);
				newGroups[targetGroupIndex].questions.splice(insertIndex, 0, question);
			} else {
				newGroups[sourceGroupIndex].questions.splice(sourceQIndex, 1);
				newGroups[targetGroupIndex].questions.splice(insertIndex, 0, question);
			}

			this._reorderOrdinalNumbers(newGroups)
			this.$emit('update:groups', newGroups);
			this.$emit('update:selectedItem', {
				type: 'question',
				groupIndex: targetGroupIndex,
				qIndex: insertIndex
			});

			this.draggedQuestion = null;
			this.dragOverPosition = null;
		},

		_reorderOrdinalNumbers(groups) {
			let number = 0
			groups.forEach(group => {
				group.questions.forEach(q => {
					q.ordinalNumber = ++number
				})
			})
		},

		// Handlers for empty groups
		handleEmptyGroupDragOver(event) {
			event.dataTransfer.dropEffect = 'move';
		},

		handleEmptyGroupDragEnter(event, groupIndex) {
			this.dragOverGroupIndex = groupIndex;
		},

		handleEmptyGroupDragLeave(event) {
			if (!event.currentTarget.contains(event.relatedTarget)) {
				this.dragOverGroupIndex = null;
			}
		},

		handleEmptyGroupDrop(event, targetGroupIndex) {
			if (!this.draggedQuestion) return;

			const { groupIndex: sourceGroupIndex, qIndex: sourceQIndex, question } = this.draggedQuestion;

			if (sourceGroupIndex === targetGroupIndex) {
				return;
			}

			const newGroups = JSON.parse(JSON.stringify(this.groups));

			newGroups[sourceGroupIndex].questions.splice(sourceQIndex, 1);
			newGroups[targetGroupIndex].questions.push(question);

			this._reorderOrdinalNumbers(newGroups)
			this.$emit('update:groups', newGroups);
			this.$emit('update:selectedItem', {
				type: 'question',
				groupIndex: targetGroupIndex,
				qIndex: 0
			});

			this.draggedQuestion = null;
			this.dragOverGroupIndex = null;
		}
	}
	}
</script>