<template>
	<v-card class="assignment-properties-card" :sticky="inDrawer ? undefined : true" top="80px">
		<div v-if="inDrawer" class="d-flex align-center pa-3 border-b">
			<span class="text-subtitle-2 font-weight-medium flex-grow-1">{{ IsEngLish ? 'Properties' : 'Thuộc tính' }}</span>
			<v-btn icon size="small" variant="text" @click="$emit('close')">
				<v-icon>mdi-close</v-icon>
			</v-btn>
		</div>
		<div class="properties-context-header d-flex align-center text-subtitle-1 font-weight-medium flex-wrap ga-2 px-3 pt-2">
			<span v-if="!inDrawer">{{ $t('message.Attribute') }}</span>
			<div class="ml-2" v-if="item?.type === 'question' && globalQuestionNumber !== 0">
				<v-chip v-if="isQuestionTextField === false" label variant="outlined" color="primary"
					@click="isQuestionTextField = true; $nextTick(() => { $refs.questionInput.focus() });">
					{{ $t('message.Question') }} {{ selectedQuestionData.ordinalNumber }} <v-icon end>mdi-pencil-circle
					</v-icon>
				</v-chip>
				<v-text-field v-else ref="questionInput" v-model="selectedQuestionData.ordinalNumber"
					hide-details="auto" @blur="isQuestionTextField = false" />
			</div>
			<v-chip v-else-if="item?.type === 'group'" class="ml-2" label color="primary">
				{{ selectedGroupData.title }}
			</v-chip>
			<v-spacer></v-spacer>
			<div v-if="item?.type === 'question'" class="ms-auto">
				<v-btn icon variant="text" @click="onOpenModalKiNang()">
					<v-icon>mdi-cog-outline</v-icon>
				</v-btn>
			</div>
		</div>
		<!-- Chip chỉ hiển thị trạng thái; nút primary bên cạnh mới là thao tác đẩy/cập nhật câu hỏi. -->
		<div v-if="item?.type === 'question' && selectedQuestionData" class="d-flex align-center flex-wrap ga-2 px-3 pt-1">
			<span class="text-caption font-weight-medium text-medium-emphasis">{{ IsEngLish ? 'Content Hub:' : 'Kho soạn nội dung:' }}</span>
			<v-chip v-if="contentHubStatus.kind !== 'idle'" size="small" variant="tonal"
				:color="contentHubStatusColor" :prepend-icon="contentHubStatusIcon">
				{{ contentHubStatusLabel }}
			</v-chip>
			<v-btn v-if="contentHubCanPublish" size="small" variant="elevated"
				:color="contentHubStatus.kind === 'changed' ? 'warning' : 'primary'"
				:loading="contentHubPublishLoading" :aria-label="contentHubPublishButtonLabel"
				@click="openContentHubPublishDialog">
				<v-icon start>mdi-arrow-up-bold-box-outline</v-icon>
				{{ contentHubPublishButtonLabel }}
			</v-btn>
			<v-btn v-if="contentHubStatus.kind === 'error'" size="small" variant="text" color="primary"
				@click="scheduleContentHubStatusCheck(true)">
				<v-icon start>mdi-refresh</v-icon>{{ IsEngLish ? 'Retry' : 'Kiểm tra lại' }}
			</v-btn>
		</div>
		<v-divider class="my-2" />
		<div v-if="!item" class="text-center pa-8 text-grey">
			<v-icon size="48" class="mb-2">mdi-cursor-default-click-outline</v-icon>
			<div>{{ $t('message.SelectSectionOrQuestionToEdit') }}</div>
		</div>

		<div v-else class="px-3 pb-3">
			<div v-if="item?.type === 'group'" class="d-flex flex-column ga-2">
				<v-text-field class="mt-2" :model-value="selectedGroupData.title"
					@update:model-value="updateItem('title', $event)" :label="$t('message.SectionGroupName')"
					variant="outlined" density="compact" />
				<v-checkbox v-model="selectedGroupData.isCheckShowAllQuestion"
					:label="$t('message.ShowAllQuestionsInGroup')" density="compact" hide-details />
				<div class="d-flex align-center ga-2 w-100">
					<v-checkbox :model-value="selectedGroupData.advancedFeatures.isShuffleQuestions"
						@update:model-value="(value) => { updateShuffleQuestions(selectedGroupData.id, value) }"
						:label="$t('message.ShuffleQuestions')"></v-checkbox>
					<v-checkbox :model-value="selectedGroupData.advancedFeatures.isShuffleAnswers"
						@update:model-value="(value) => { updateShuffleAnswers(selectedGroupData.id, value) }"
						:label="$t('message.ShuffleAnswers')"></v-checkbox>
				</div>
				<v-divider class="my-1" />
				<v-switch
					:model-value="isRandomQuestionPool"
					@update:model-value="updateRandomQuestionPool"
					label="Lấy ngẫu nhiên từ nhóm câu hỏi"
					color="primary"
					density="compact"
					hide-details
				/>
				<div v-if="isRandomQuestionPool" class="rounded border pa-3 bg-blue-lighten-5">
					<!-- Nếu là Ma trận đề: Hiển thị tóm tắt mức độ và nút sửa ma trận thay vì ô nhập số câu đơn lẻ -->
					<div v-if="selectedGroupData.questionSource?.sourceKind === 'QUESTION_BANK_SKILL_MATRIX' || selectedGroupData.questionSource?.matrixMode" class="d-flex flex-column ga-2">
						<div class="d-flex align-center justify-space-between">
							<div class="d-flex align-center ga-1">
								<v-icon color="indigo" size="18">mdi-matrix</v-icon>
								<span class="text-caption font-weight-bold text-indigo-darken-2">Cấu hình Ma trận đề</span>
							</div>
							<v-chip size="x-small" color="indigo" variant="flat">
								Tổng {{ selectedGroupData.questionSelection?.questionsPerAttempt || 0 }} câu bốc
							</v-chip>
						</div>
						<div class="text-caption text-medium-emphasis">
							Đề được bốc ngẫu nhiên từ kho <strong>{{ selectedGroupData.questions?.length || 0 }} câu</strong> theo 4 mức độ nhận thức đã thiết lập.
						</div>
						<v-btn size="small" variant="tonal" color="indigo" block @click="$emit('open-import', 'bank')">
							<v-icon start size="14">mdi-cog-outline</v-icon>Chỉnh sửa Ma trận đề
						</v-btn>
					</div>
					<!-- Nếu là Pool kỹ năng hoặc Pool file thông thường: Cho phép chỉnh số câu mỗi lượt -->
					<div v-else>
						<div v-if="selectedGroupData.questionSource?.sourceKind === 'QUESTION_BANK_SKILL'" class="d-flex align-center ga-1 mb-2">
							<v-chip size="x-small" color="indigo" variant="flat">
								<v-icon start size="12">mdi-star-outline</v-icon>
								Pool Kỹ năng: {{ selectedGroupData.questionSource.skillName || 'Kỹ năng' }}
							</v-chip>
						</div>
						<v-text-field
							:model-value="randomQuestionsPerAttempt"
							@update:model-value="updateRandomQuestionsPerAttempt"
							:label="'Số câu mỗi lượt (kho ngẫu nhiên: ' + randomPoolSize + ' câu)'"
							type="number"
							:min="1"
							:max="randomPoolSize || 1"
							variant="outlined"
							density="compact"
							hide-details="auto"
							persistent-hint
							hint="Mỗi học sinh chỉ nhận số câu này; điểm tối đa được lưu riêng theo đúng câu đã bốc."
						/>
					</div>
				</div>

				<v-divider />
				<!-- Thêm các YT, IMG, RECOURD_AUDIO source -->
				<uc-media :key="item.groupIndex" :selectedData="selectedGroupData" :item="item"
					v-model:loadingPage="loadingPage" @update:selectedData="handleGroupMediaUpdate" />
				<!-- END -->
				<v-divider />
				<v-textarea :model-value="selectedGroupData.description"
					@update:model-value="updateItem('description', $event)" :label="$t('message.SectionDescription')"
					variant="outlined" density="compact" rows="3" />
				<!-- Nội dung của Phần dùng chung editor câu hỏi để hỗ trợ định dạng, công thức và ảnh nhúng khi cần. -->
				<div class="d-flex flex-column ga-1">
					<label class="text-body-2 font-weight-medium">Nội dung Phần này</label>
					<uc-rich-text-editor :model-value="selectedGroupData.content || ''"
						@update:model-value="updateItem('content', $event)"
						placeholder="Nhập văn bản/nội dung cho Phần này..." :imageapi="vueData.v_Set.apiFile"
						variant="outlined" rows="6" auto-grow />
				</div>
			</div>

			<div v-else-if="item?.type === 'question' && selectedQuestionData">
				<p class="mb-2 text-subtitle-1 font-weight-medium">{{ $t('message.QuestionContent') }}:</p>
				<div :key="selectedQuestionData.id">
					<uc-rich-text-editor :model-value="selectedQuestionData.config.questionText"
						:placeholder="$t('message.EnterQuestion')"
						@update:model-value="updateQuestionConfig('questionText', $event)"
						:imageapi="vueData.v_Set.apiFile" />
				</div>
				<div class="question-settings-grid mt-3">
					<!-- Giữ chip Mức độ chuẩn; bỏ chip kỹ năng có nút x vì đang lặp lại cùng thông tin trong drawer. -->
					<div v-if="questionCognitiveLevel" class="d-flex align-center flex-wrap ga-2 mb-2">
						<span class="text-caption font-weight-bold text-medium-emphasis">{{ IsEngLish ? 'Cognitive Level:' : 'Mức độ:' }}</span>
						<v-chip size="small" variant="tonal" :color="questionCognitiveLevel.color" class="font-weight-medium">
							<v-icon start size="14">mdi-chart-timeline-variant</v-icon>
							{{ questionCognitiveLevel.title }}
						</v-chip>
					</div>
					<v-row dense>
						<v-col cols="6"><v-text-field :model-value="selectedQuestionData.points" @update:model-value="onPointInput"
							:label="$t('message.Score')" type="text" variant="outlined" density="compact"
							:clearable="false" :disabled="isPartialScoring" /></v-col>
						<v-col cols="6"><v-select :model-value="selectedQuestionData.gradingType || 'auto'"
							@update:model-value="updateQuestion('gradingType', $event)" :label="$t('message.GradingMethod')"
							:items="[{ value: 'auto', title: IsEngLish ? 'Auto' : 'Tự động' }, { value: 'manual', title: IsEngLish ? 'Manual' : 'Chấm tay' }]"
							variant="outlined" density="compact" :disabled="!isAutoGradable(selectedQuestionData.type) || selectedQuestionData.type === 'QUIZ_ORDERING'" :clearable="false" /></v-col>
					</v-row>
				</div>
				<v-divider class="my-2" />
				<!-- END -->
				<div class="question-answer-section d-flex justify-space-between align-center"
					v-if="!['QUIZ_TRUE_FALSE', 'ESSAY', 'AUDIO_RESPONSE', 'FILE_UPLOAD', 'SHORT_ANSWER'].includes(selectedQuestionData.type)">
					<p class="font-weight-medium">{{ $t('message.Answer') }}:</p>
					<v-checkbox v-model="selectedQuestionData.config.isAdvanced" :label="$t('message.Advanced')" />
				</div>
				<!-- QUIZ_SINGLE_CHOICE -->
				<div v-if="selectedQuestionData.type === 'QUIZ_SINGLE_CHOICE'">
					<v-row dense class="question-answer-row" v-for="(option, index) in selectedQuestionData.config.options" :key="option.id">
						<v-col cols="1" class="d-flex justify-center align-center">
							<v-radio-group :model-value="selectedQuestionData.config.correctAnswer"
								@update:model-value="updateQuestionConfig('correctAnswer', $event)"
								class="flex-shrink-0">
								<v-radio :value="option.id" hide-details />
							</v-radio-group>
						</v-col>
						<v-col cols="10" class="d-flex justify-center align-center">
							<v-textarea v-if="!selectedQuestionData.config.isAdvanced" :model-value="option.text"
								@update:model-value="updateOptionText(index, $event)" variant="outlined" density="compact"
								hide-details :clearable="false" rows="2" :auto-grow="false"
								:placeholder="IsEngLish ? 'Enter answer text...' : 'Nhập nội dung đáp án...'" />
							<uc-latex-edit class="w-100" v-else v-model:content="option.text" />
						</v-col>
						<v-col cols="1" class="d-flex justify-center align-center">
							<v-btn class="answer-remove-btn" size="x-small" variant="text"
								@click="removeOption(index)" :aria-label="IsEngLish ? 'Delete answer' : 'Xóa đáp án'">
								<v-icon size="17">mdi-close</v-icon>
							</v-btn>
						</v-col>
					</v-row>
					<v-btn block size="small" @click="addOption" variant="tonal" class="mt-2">
						<v-icon start>mdi-plus</v-icon>{{ $t('message.MoreAnswer') }}
					</v-btn>
				</div>
				<!-- QUIZ_MULTIPLE_CHOICE -->
				<div v-else-if="selectedQuestionData.type === 'QUIZ_MULTIPLE_CHOICE'">
					<div class="mb-3">
						<v-select density="compact" variant="outlined" hide-details
							:model-value="selectedQuestionData.config.scoringMode || 'equal'"
							@update:model-value="onScoringModeChange($event)" :items="[
								{ value: 'equal', title: IsEngLish ? 'Equal scoring' : 'Tính điểm chia đều' },
								{ value: 'partial', title: IsEngLish ? 'Partial scoring' : 'Tính điểm theo từng ý' }
							]" :label="IsEngLish ? 'Scoring method' : 'Cách tính điểm'" />
						<v-alert v-if="(selectedQuestionData.config.scoringMode || 'equal') === 'partial'" class="mt-2"
							density="compact" variant="tonal" color="info" type="info">
							<div class="text-caption">
								<b>{{ IsEngLish ? 'Partial scoring:' : 'Tính điểm theo từng ý :' }}</b><br>
								{{ IsEngLish ? '1 correct: 0.1 pt' : 'Đúng 1 ý: 0,1đ' }} &nbsp;·&nbsp; {{ IsEngLish ? '2 correct: 0.25 pt' : 'Đúng 2 ý: 0,25đ' }} &nbsp;·&nbsp; {{ IsEngLish ? '3 correct: 0.5 pt' : 'Đúng 3 ý: 0,5đ' }} &nbsp;·&nbsp; {{ IsEngLish ? 'All 4 correct: 1.0 pt' : 'Đúng cả 4 ý: 1,0đ' }}<br>
								<span class="font-weight-medium">{{ IsEngLish ? 'Required: 4 options, max score 1.0 pt.' : 'Bắt buộc: 4 đáp án, điểm tối đa 1,0đ.' }}</span>
							</div>
						</v-alert>
					</div>
					<v-row dense class="question-answer-row" v-for="(option, index) in selectedQuestionData.config.options" :key="option.id"
						align="center">
						<v-col cols="1" class="d-flex justify-center">
							<v-checkbox :model-value="selectedQuestionData.config.correctAnswers" :value="option.id"
								@update:model-value="updateQuestionConfig('correctAnswers', $event)" hide-details
								class="flex-shrink-0">
							</v-checkbox>
						</v-col>
						<v-col cols="10">
							<v-textarea v-if="!selectedQuestionData.config.isAdvanced" :model-value="option.text"
								@update:model-value="updateOptionText(index, $event)" variant="outlined" density="compact" hide-details
								:clearable="false" rows="2" :auto-grow="false" :placeholder="IsEngLish ? 'Enter answer text...' : 'Nhập nội dung đáp án...'" />
							<uc-latex-edit v-else v-model:content="option.text" />
						</v-col>
						<v-col cols="1" class="d-flex justify-center align-center">
							<v-btn v-if="(selectedQuestionData.config.scoringMode || 'equal') !== 'partial'"
								class="answer-remove-btn" size="x-small" variant="text"
								@click="removeOption(index)" :aria-label="IsEngLish ? 'Delete answer' : 'Xóa đáp án'">
								<v-icon size="17">mdi-close</v-icon>
							</v-btn>
						</v-col>
					</v-row>
					<v-btn v-if="(selectedQuestionData.config.scoringMode || 'equal') !== 'partial'" block size="small"
						@click="addOption" variant="tonal" class="mt-2">
						<v-icon start>mdi-plus</v-icon>{{ $t('message.MoreAnswer') }}
					</v-btn>
				</div>
				<!-- QUIZ_TRUE_FALSE -->
				<div v-else-if="selectedQuestionData.type === 'QUIZ_TRUE_FALSE'">
					<v-radio-group :model-value="selectedQuestionData.config.correctAnswer"
						@update:model-value="updateQuestionConfig('correctAnswer', $event)">
						<v-radio :value="true" :label="$t('message.Correct')" />
						<v-radio :value="false" :label="$t('message.Incorrect')" />
					</v-radio-group>
				</div>
				<!-- QUIZ_MULTIPLE_TRUE_FALSE -->
				<div v-else-if="selectedQuestionData.type === 'QUIZ_MULTIPLE_TRUE_FALSE'">
					<div class="mb-3">
						<v-select density="compact" variant="outlined" hide-details
							:model-value="selectedQuestionData.config.scoringMode || 'equal'"
							@update:model-value="onScoringModeChange($event)" :items="[
								{ value: 'equal', title: IsEngLish ? 'Equal scoring' : 'Tính điểm chia đều' },
								{ value: 'partial', title: IsEngLish ? 'Partial scoring' : 'Tính điểm theo từng ý' }
							]" :label="IsEngLish ? 'Scoring method' : 'Cách tính điểm'" />
						<v-alert v-if="(selectedQuestionData.config.scoringMode || 'equal') === 'partial'" class="mt-2"
							density="compact" variant="tonal" color="info" type="info">
							<div class="text-caption">
								<b>{{ IsEngLish ? 'Partial scoring:' : 'Tính điểm theo từng ý :' }}</b><br>
								{{ IsEngLish ? '1 correct: 0.1 pt' : 'Đúng 1 ý: 0,1đ' }} &nbsp;·&nbsp; {{ IsEngLish ? '2 correct: 0.25 pt' : 'Đúng 2 ý: 0,25đ' }} &nbsp;·&nbsp; {{ IsEngLish ? '3 correct: 0.5 pt' : 'Đúng 3 ý: 0,5đ' }} &nbsp;·&nbsp; {{ IsEngLish ? 'All 4 correct: 1.0 pt' : 'Đúng cả 4 ý: 1,0đ' }}<br>
								<span class="font-weight-medium">{{ IsEngLish ? 'Required: 4 options, max score 1.0 pt.' : 'Bắt buộc: 4 đáp án, điểm tối đa 1,0đ.' }}</span>
							</div>
						</v-alert>
					</div>
					<!-- Dùng flex theo đúng nội dung: hai ô chọn cố định, ô nhập chiếm phần còn lại, nút xóa tự co. Cách này bỏ phần 2 cột trống bên phải của lưới cũ. -->
					<div v-for="(option, index) in selectedQuestionData.config.options" :key="index"
						class="question-answer-row question-answer-statement-row d-flex align-center">
						<div class="statement-answer-controls d-flex justify-space-evenly align-center flex-shrink-0">
							<v-checkbox v-model="option.correctAnswer" color="primary" hide-details
								@update:modelValue="(val) => { if (val) option.inCorrectAnswer = false }" />
							<v-checkbox v-model="option.inCorrectAnswer" color="red" hide-details
								@update:modelValue="(val) => { if (val) option.correctAnswer = false }" />
						</div>
						<div class="statement-answer-input flex-grow-1">
							<v-textarea :model-value="option.text" @update:model-value="updateOptionText(index, $event)"
								variant="outlined" density="compact" hide-details :clearable="false"
								:placeholder="IsEngLish ? 'Enter answer text...' : 'Nhập nội dung đáp án...'" auto-grow :rows="2" />
						</div>
						<div class="flex-shrink-0">
							<v-btn
								v-if="selectedQuestionData.config.options.length > 2 && (selectedQuestionData.config.scoringMode || 'equal') !== 'partial'"
								class="answer-remove-btn" icon="mdi-delete-outline" variant="text" size="small" color="red"
								@click="removeOption(index)" />
						</div>
					</div>
					<v-btn v-if="(selectedQuestionData.config.scoringMode || 'equal') !== 'partial'"
						prepend-icon="mdi-plus" variant="text" color="primary" @click="addOption('options')">
						{{ $t('message.MoreAnswer') }}
					</v-btn>
				</div>

				<!-- QUIZ_FILL_IN_BLANK -->
				<div v-else-if="selectedQuestionData.type === 'QUIZ_FILL_IN_BLANK'">
					<p class="text-caption mb-2">{{ $t('message.Structure') }}</p>

					<div v-for="(part, index) in selectedQuestionData.config.parts" :key="getPartKey(part, index)"
						class="d-flex align-start mb-2 ga-2">

						<!-- Type badge -->
						<v-chip size="x-small" variant="tonal" :color="part.type === 'blank' ? 'indigo' : 'default'"
							class="mt-2 flex-shrink-0">{{ part.type === 'blank' ? (IsEngLish ? 'Blank' : 'Trống') : (IsEngLish ? 'Text' : 'Văn bản') }}</v-chip>

						<!-- Text part -->
						<v-text-field v-if="part.type === 'text'" :model-value="part.value"
							@update:model-value="updatePart(index, 'value', $event)"
							:placeholder="$t('message.TextContent')" variant="outlined" density="compact" hide-details
							:clearable="false" class="flex-grow-1" />

						<!-- Blank part -->
						<div v-else-if="part.type === 'blank'" class="flex-grow-1 rounded pa-2"
							style="border: 1.5px dashed #9E9E9E;">
							<!-- Danh sách đáp án đúng -->
							<div v-if="getAnswersWithId(part.id, part).length > 0" class="d-flex flex-wrap ga-1 mb-2">
								<v-chip v-for="ans in getAnswersWithId(part.id, part)" :key="ans.id" size="small"
									:color="editingBlankState[part.id] && editingBlankState[part.id].editingId === ans.id ? 'primary' : 'success'"
									variant="tonal"
									:prepend-icon="editingBlankState[part.id] && editingBlankState[part.id].editingId === ans.id ? 'mdi-pencil' : 'mdi-check'"
									closable @click="selectAnswerForEdit(part.id, ans.id)"
									@click:close.stop="removeAcceptedAnswer(part.id, index, ans.id)">{{ ans.value
									}}</v-chip>
							</div>
							<p v-else class="text-caption text-medium-emphasis mb-2">{{ IsEngLish ? 'No correct answer yet' : 'Chưa có đáp án đúng' }}</p>

							<!-- Enter đã được bắt để lưu ngay; hint cố định nhắc người dùng hoàn tất thao tác sau khi nhập. -->
							<v-text-field
								:model-value="editingBlankState[part.id] ? editingBlankState[part.id].inputValue : ''"
								@update:model-value="setBlankInput(part.id, $event)"
								@keydown.enter.prevent="commitBlankAnswer(part.id, index, part)" variant="outlined"
								density="compact" hide-details="auto" persistent-hint :hint="IsEngLish ? 'Press Enter after typing to save answer' : 'Nhập xong nhấn Enter để lưu đáp án'"
								:clearable="false"
								:placeholder="editingBlankState[part.id] && editingBlankState[part.id].editingId !== null ? (IsEngLish ? 'Edit answer then press Enter...' : 'Sửa đáp án rồi nhấn Enter...') : (IsEngLish ? 'Enter answer then press Enter...' : 'Nhập đáp án rồi nhấn Enter...')"
								append-inner-icon="mdi-keyboard-return" />
						</div>

						<v-btn icon size="small" variant="text" color="default" @click="removePart(index)" class="mt-1">
							<v-icon>mdi-close</v-icon>
						</v-btn>
					</div>

					<div class="d-flex ga-2 mt-1">
						<v-btn size="small" @click="addPart('text')" variant="tonal" prepend-icon="mdi-format-text">{{
							$t('message.AddText') }}</v-btn>
						<v-btn size="small" @click="addPart('blank')" variant="tonal" color="indigo"
							prepend-icon="mdi-form-textbox">{{ $t('message.AddBlank') }}</v-btn>
					</div>
				</div>
				<!-- QUIZ_MATCHING (QUIZ_MATCHING_V2 kept for backward compat with existing data) -->
				<div v-else-if="['QUIZ_MATCHING', 'QUIZ_MATCHING_V2'].includes(selectedQuestionData.type)">
					<v-row dense class="mb-1">
						<v-col>
							<p class="text-caption font-weight-medium mb-0">{{ $t('message.Column') }} A</p>
						</v-col>
						<v-col>
							<p class="text-caption font-weight-medium mb-0">{{ $t('message.Column') }} B ({{
								$t('message.Similar') }})</p>
						</v-col>
						<v-col cols="2"></v-col>
					</v-row>
					<v-row v-for="(pair, index) in selectedQuestionData.config.columnA" :key="index" dense class="mb-1">
						<v-col cols="5">
							<v-text-field v-if="!selectedQuestionData.config.isAdvanced" v-model="pair.text"
								density="compact" variant="outlined" hide-details :clearable="false"
								:placeholder="$t('message.Column') + ' A...'" />
							<uc-latex-edit v-else v-model:content="pair.text" class="w-100" />
						</v-col>
						<v-col cols="5">
							<v-text-field v-if="!selectedQuestionData.config.isAdvanced"
								v-model="selectedQuestionData.config.columnB[index].text" density="compact"
								variant="outlined" hide-details :clearable="false"
								:placeholder="$t('message.Column') + ' B...'" />
							<uc-latex-edit v-else v-model:content="selectedQuestionData.config.columnB[index].text"
								class="w-100" />
						</v-col>
						<v-col cols="2" class="d-flex align-center">
							<v-btn icon="mdi-delete-outline" variant="text" size="small" color="red"
								@click="removePair(index)" />
						</v-col>
					</v-row>
					<v-btn prepend-icon="mdi-plus" variant="tonal" color="primary" @click="addPair" class="mt-4 mb-4">
						{{ $t('message.AddPair') }}
					</v-btn>
				</div>
				<!-- QUIZ_ORDERING: danh sách đang hiển thị chính là thứ tự đúng; học sinh sẽ nhận các ý này để sắp xếp lại ở màn hình làm bài. -->
				<div v-else-if="selectedQuestionData.type === 'QUIZ_ORDERING'">
					<p class="text-caption mb-2">{{ IsEngLish ? 'Arrange the items in the correct order.' : 'Nhập các ý theo thứ tự đúng.' }}</p>
					<div v-for="(entry, index) in (selectedQuestionData.config.items || [])" :key="entry.id || index" class="d-flex align-start ga-2 mb-2">
						<v-chip size="small" color="primary" variant="tonal" class="mt-2 flex-shrink-0">{{ index + 1 }}</v-chip>
						<v-textarea v-if="!selectedQuestionData.config.isAdvanced" :model-value="entry.text"
							@update:model-value="updateOrderingItemText(index, $event)" variant="outlined" density="compact"
							hide-details :clearable="false" rows="2" auto-grow class="flex-grow-1"
							:placeholder="IsEngLish ? 'Enter item...' : 'Nhập ý cần sắp xếp...'" />
						<uc-latex-edit v-else v-model:content="entry.text" class="flex-grow-1" />
						<div class="d-flex align-center mt-1">
							<v-btn icon="mdi-arrow-up" size="small" variant="text" :disabled="index === 0" @click="moveOrderingItem(index, -1)" />
							<v-btn icon="mdi-arrow-down" size="small" variant="text" :disabled="index === (selectedQuestionData.config.items || []).length - 1" @click="moveOrderingItem(index, 1)" />
							<v-btn v-if="(selectedQuestionData.config.items || []).length > 2" icon="mdi-delete-outline" size="small" variant="text" color="red" @click="removeOrderingItem(index)" />
						</div>
					</div>
					<v-btn prepend-icon="mdi-plus" variant="tonal" color="primary" @click="addOrderingItem" class="mt-1">
						{{ IsEngLish ? 'Add item' : 'Thêm ý' }}
					</v-btn>
					<p class="text-caption text-medium-emphasis mt-2 mb-0">
						{{ orderingItemScoreLabel }}
					</p>
				</div>
				<!-- FILE_UPLOAD -->
				<div v-else-if="selectedQuestionData.type === 'FILE_UPLOAD'">
					<div v-if="selectedQuestionData.config.media.type === 'VIDEO'">
						<video :src="selectedQuestionData.config.media.source" controls />
					</div>
				</div>

				<div v-else-if="selectedQuestionData.type === 'ESSAY'">
					<!-- Đáp án tham khảo chỉ hỗ trợ giáo viên khi chấm tay; không phải đáp án để hệ thống tự chấm. -->
					<uc-rich-text-editor :model-value="selectedQuestionData.config.referenceAnswer || ''"
						label="Đáp án tham khảo (chỉ giáo viên xem)"
						placeholder="Nhập ý chính hoặc đáp án tham khảo để đối chiếu khi chấm..."
						@update:model-value="updateQuestionConfig('referenceAnswer', $event)"
						:imageapi="vueData.v_Set.apiFile" variant="outlined" rows="4" auto-grow />
					<v-number-input v-model="selectedQuestionData.config.maxLength" :label="$t('message.MaxCharacters')"
						variant="outlined" density="compact" />
				</div>

				<div v-else-if="selectedQuestionData.type === 'SHORT_ANSWER'">
					<!-- Câu trả lời ngắn cũng lưu cùng key referenceAnswer để Content Hub và trang chấm bài dùng chung schema. -->
					<uc-rich-text-editor :model-value="selectedQuestionData.config.referenceAnswer || ''"
						label="Đáp án tham khảo (chỉ giáo viên xem)"
						placeholder="Nhập câu trả lời hoặc các ý chính tham khảo..."
						@update:model-value="updateQuestionConfig('referenceAnswer', $event)"
						:imageapi="vueData.v_Set.apiFile" variant="outlined" rows="4" auto-grow />
				</div>

				<div v-else-if="selectedQuestionData.type === 'AUDIO_RESPONSE'">
					<p class="text-caption text-grey">
						{{ $t('message.NoAnswerConfig') }}.
					</p>
				</div>

				<v-divider class="my-3" />
				<uc-media :selectedData="selectedQuestionData.config" :item="{ ...item, sourceTracking: selectedQuestionData.sourceTracking }" v-model:loadingPage="loadingPage"
					@update:selectedData="handleQuestionMediaUpdate" />
			</div>
		</div>
	</v-card>

	<!-- Câu hỏi mới phải chọn nhóm đích trước khi ghi vào kho dùng chung. -->
	<v-dialog v-model="contentHubPushDialog" max-width="560" persistent>
		<v-card>
			<v-card-title class="d-flex align-center">
				<span class="text-subtitle-1 font-weight-bold">
					{{ contentHubStatus.kind === 'changed' ? (IsEngLish ? 'Update question in Content Hub' : 'Cập nhật câu hỏi trong Kho soạn nội dung') : (IsEngLish ? 'Push question to Content Hub' : 'Đẩy câu hỏi vào Kho soạn nội dung') }}
				</span>
				<v-spacer />
				<v-btn icon variant="text" :disabled="contentHubPublishLoading" @click="contentHubPushDialog = false">
					<v-icon>mdi-close</v-icon>
				</v-btn>
		</v-card-title>
		<v-card-text>
			<!-- Giữ toàn bộ ngữ cảnh câu hỏi trong dialog để người dùng xác nhận đúng nội dung trước khi đẩy vào kho. -->
			<div class="rounded border pa-3 mb-3 bg-grey-lighten-5" style="max-height: 230px; overflow-y: auto;">
				<div class="d-flex align-center ga-2 mb-2">
					<v-icon size="18" color="primary">mdi-text-box-search-outline</v-icon>
					<span class="text-subtitle-2 font-weight-bold">{{ IsEngLish ? 'Question content' : 'Nội dung câu hỏi' }}</span>
					<v-spacer />
					<v-chip size="x-small" color="primary" variant="tonal">{{ contentHubQuestionTypeLabel }}</v-chip>
				</div>
				<div v-if="contentHubQuestionPreviewText" class="text-body-2" v-html="contentHubQuestionPreviewText"></div>
				<div v-else class="text-caption text-medium-emphasis">{{ IsEngLish ? 'No question content.' : 'Chưa có nội dung câu hỏi.' }}</div>
				<template v-if="contentHubPreviewAnswers.length">
					<v-divider class="my-2" />
					<div class="text-caption font-weight-bold text-medium-emphasis mb-1">{{ IsEngLish ? 'Options / Answers' : 'Phương án / đáp án' }}</div>
					<div v-for="answer in contentHubPreviewAnswers" :key="answer.key"
						class="d-flex align-start ga-2 text-body-2 mb-1">
						<span class="font-weight-bold flex-shrink-0">{{ answer.label }}</span>
						<span class="flex-grow-1" v-html="answer.text"></span>
						<v-chip v-if="answer.badge" size="x-small" :color="answer.badgeColor || 'success'" variant="tonal">
							{{ answer.badge }}
						</v-chip>
					</div>
				</template>
				<div v-else class="text-caption text-medium-emphasis mt-2">{{ IsEngLish ? 'This question type has no preset answers.' : 'Dạng câu hỏi này không có đáp án cài sẵn.' }}</div>
			</div>
			<!-- Hiển thị phạm vi ngay tại nơi chọn nhóm để tránh chọn nhầm kho của môn/khối khác. -->
			<div class="d-flex align-center flex-wrap ga-2 mb-3">
				<span class="text-caption font-weight-medium text-medium-emphasis">{{ IsEngLish ? 'Content Hub scope:' : 'Phạm vi kho:' }}</span>
				<v-chip size="small" color="indigo" variant="tonal" prepend-icon="mdi-book-open-variant">
					{{ IsEngLish ? 'Subject' : 'Môn' }}: {{ contentHubScope.subject }}
				</v-chip>
				<v-chip size="small" color="teal" variant="tonal" prepend-icon="mdi-school-outline">
					{{ IsEngLish ? 'Grade' : 'Khối' }}: {{ contentHubScope.grade }}
				</v-chip>
			</div>
			<div v-if="contentHubStatus.kind !== 'changed'" class="d-flex align-end ga-2">
				<v-select v-model="contentHubTargetGroup" class="flex-grow-1" :items="contentHubGroups"
					item-title="Title" item-value="Id" return-object :label="IsEngLish ? 'Question group in hub' : 'Nhóm câu hỏi trong kho'"
					variant="outlined" density="compact" :loading="contentHubGroupsLoading"
					:disabled="contentHubPublishLoading" :no-data-text="IsEngLish ? 'No question groups found for this subject/grade.' : 'Chưa có nhóm câu hỏi cho môn/khối này.'" />
				<v-btn color="success" variant="tonal" size="small" prepend-icon="mdi-plus"
					:disabled="contentHubPublishLoading" @click="openContentHubCreateGroupDialog">
					{{ IsEngLish ? 'Create new group' : 'Tạo nhóm mới' }}
				</v-btn>
			</div>
			<v-chip v-else size="small" color="warning" variant="tonal">
					<v-icon start>mdi-pencil-alert-outline</v-icon>
					{{ IsEngLish ? 'Content has changed; the linked question in the hub will be updated.' : 'Nội dung đã thay đổi; hệ thống sẽ cập nhật câu hỏi đã liên kết trong kho.' }}
				</v-chip>
				<v-alert v-if="contentHubPublishError" density="compact" variant="tonal" color="error" class="mt-3">
					{{ contentHubPublishError }}
				</v-alert>
			</v-card-text>
			<v-card-actions class="pa-4">
				<v-spacer />
				<v-btn variant="text" :disabled="contentHubPublishLoading" @click="contentHubPushDialog = false">{{ IsEngLish ? 'Cancel' : 'Hủy' }}</v-btn>
				<v-btn color="primary" variant="elevated" :loading="contentHubPublishLoading"
					:disabled="contentHubStatus.kind !== 'changed' && (!contentHubTargetGroup || contentHubGroupsLoading)"
					@click="publishQuestionToContentHub">
					{{ contentHubStatus.kind === 'changed' ? (IsEngLish ? 'Update' : 'Cập nhật') : (IsEngLish ? 'Push to hub' : 'Đẩy vào kho') }}
				</v-btn>
			</v-card-actions>
		</v-card>
		</v-dialog>

		<v-dialog v-model="contentHubCreateGroupDialog" max-width="460" persistent>
			<v-card>
				<v-card-title class="d-flex align-center">
					<span class="text-subtitle-1 font-weight-bold">{{ IsEngLish ? 'Create new question group' : 'Tạo nhóm câu hỏi mới' }}</span>
					<v-spacer />
					<v-btn icon variant="text" :disabled="contentHubCreateGroupLoading"
						@click="contentHubCreateGroupDialog = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text>
					<div class="d-flex flex-wrap ga-2 mb-3">
						<v-chip size="small" color="indigo" variant="tonal">{{ IsEngLish ? 'Subject' : 'Môn' }}: {{ contentHubScope.subject }}</v-chip>
						<v-chip size="small" color="teal" variant="tonal">{{ IsEngLish ? 'Grade' : 'Khối' }}: {{ contentHubScope.grade }}</v-chip>
					</div>
					<v-text-field v-model="contentHubCreateGroupName" :label="IsEngLish ? 'Question group name *' : 'Tên nhóm câu hỏi *'"
						variant="outlined" density="compact" autofocus :disabled="contentHubCreateGroupLoading"
						@keydown.enter.prevent="createContentHubGroup" />
					<v-alert v-if="contentHubCreateGroupError" density="compact" variant="tonal" color="error">
						{{ contentHubCreateGroupError }}
					</v-alert>
				</v-card-text>
				<v-card-actions class="pa-4">
					<v-spacer />
					<v-btn variant="text" :disabled="contentHubCreateGroupLoading"
						@click="contentHubCreateGroupDialog = false">{{ IsEngLish ? 'Cancel' : 'Hủy' }}</v-btn>
					<v-btn color="success" variant="elevated" prepend-icon="mdi-content-save"
						:loading="contentHubCreateGroupLoading" :disabled="!contentHubCreateGroupName.trim()"
						@click="createContentHubGroup">{{ IsEngLish ? 'Create group' : 'Tạo nhóm' }}</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<uc-loading-page v-model="loadingPage.isLoading" v-model:text="loadingPage.text" />
	<uc-question-from-hoc-lieu v-if="isShowModalImportFromHocLieu" v-model:isOpen="isShowModalImportFromHocLieu"
		:assignmentDetail="assignment" :linked-hoc-lieu-i-d="linkedHocLieuID" @importJson="bindingImport" />
	<uc-question-from-bank v-if="isShowModalImportFromBank" v-model:isOpen="isShowModalImportFromBank"
		:assignmentDetail="assignment" @importJson="bindingImport" />
	<uc-chon-ki-nang v-model:dialog="isShowModalSkill" @skillApplied="handleSubmitSkill"></uc-chon-ki-nang>
</template>

<script>
	export default {
		name: 'uc-assignment-properties', 
		inject: ['snackbarRef'],
		props: { groups: { type: Array, default: () => [] }, item: Object, assignment: Object, inDrawer: { type: Boolean, default: false }, openImportType: { type: String, default: '' }, linkedHocLieuID: { type: Number, default: 0 } },
		emits: ['update:groups', 'update:item', 'update:assignment', 'close'],
		data() {
			this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
			return {
				vueData,
				window,
				fileRecordAudio: null,
				loadingPage: {
					isLoading: false,
					text: "Đang tải dữ liệu..."
				},
				isSaveFile: false,
				isQuestionTextField: false,
				isShowModalImportFromHocLieu: false,
				isShowModalImportFromBank: false,
				isShowModalSkill: false,
					skills: new Map(),
					editingBlankState: {},
					contentHubPushDialog: false,
					contentHubGroups: [],
					contentHubTargetGroup: null,
					contentHubGroupsLoading: false,
					contentHubPublishLoading: false,
					contentHubPublishError: '',
					contentHubCreateGroupDialog: false,
					contentHubCreateGroupName: '',
					contentHubCreateGroupLoading: false,
					contentHubCreateGroupError: '',
					contentHubStatusTimer: null,
					contentHubStatusRequest: 0,
					contentHubStatus: { kind: 'idle', fingerprint: '', questionId: null, groupId: null, groupTitle: '', message: '' }
				}
			},
			beforeUnmount() {
				clearTimeout(this.contentHubStatusTimer)
			},
			watch: {
			openImportType(value) {
				if (value === 'hocLieu') this.onOpenModalImportFromHocLieu()
				if (value === 'bank') this.onOpenModalImportFromBank()
			},
			item() {
				this.editingBlankState = {}
				this.isQuestionTextField = false
					this.isShowModalImportFromHocLieu = false
					this.isShowModalImportFromBank = false
					this.isShowModalSkill = false
					this.contentHubPushDialog = false
					this.contentHubCreateGroupDialog = false
					this.contentHubCreateGroupError = ''
					this.contentHubStatus = { kind: 'idle', fingerprint: '', questionId: null, groupId: null, groupTitle: '', message: '' }
					this.scheduleContentHubStatusCheck()
				},
			selectedQuestionData: {
				deep: true,
				handler(value) {
					// Dữ liệu cũ có thể từng lưu ordering là chấm tay; chuẩn hóa lại để câu có đáp án luôn đi qua quiz auto-grading.
					if (value?.type === 'QUIZ_ORDERING' && value.gradingType !== 'auto') value.gradingType = 'auto'
					this.scheduleContentHubStatusCheck()
				}
			}
			},
			computed: {
			selectedGroupData() {
				if (!this.item || this.item.type !== 'group') return null;
				let mapGroup = this.groups[this.item.groupIndex]
				if (!mapGroup.advancedFeatures) {
					this.groups[this.item.groupIndex].advancedFeatures = {
						isShuffleQuestions: false,
						isShuffleAnswers: false
					}
				}
				return mapGroup;
			},
			selectedQuestionData() {
				if (!this.item || this.item.type !== 'question') return null;
				return this.groups[this.item.groupIndex]?.questions?.[this.item.qIndex];
			},
			isRandomQuestionPool() {
				return this.selectedGroupData?.questionSelection?.mode === 'RANDOM';
			},
			randomPoolSize() {
				return this.getRandomPoolSize(this.selectedGroupData)
			},
			randomQuestionsPerAttempt() {
				return this.selectedGroupData?.questionSelection?.questionsPerAttempt || '';
			},
			globalQuestionNumber() {
				if (!this.item || this.item.type !== 'question') return 0;
				let n = 1;
				for (let i = 0; i < this.item.groupIndex; i++) {
					n += this.groups[i].questions.length;
				}
				return n + this.item.qIndex;
			},
			IsEngLish: function () {
				if (this.$i18n?.locale === 'en') return true
				try {
					const isLang = JSON.parse(localStorage.getItem('IsLanguage'))
					return isLang === true || isLang === 'true'
				} catch (e) {
					return localStorage.getItem('IsLanguage') === 'true'
				}
			},
			isPartialScoring() {
				if (!this.selectedQuestionData) return false;
				const type = this.selectedQuestionData.type;
				if (!['QUIZ_MULTIPLE_CHOICE', 'QUIZ_MULTIPLE_TRUE_FALSE'].includes(type)) return false;
				return (this.selectedQuestionData.config.scoringMode || 'equal') === 'partial';
			},
			orderingItemScoreLabel() {
				const question = this.selectedQuestionData
				if (!question || question.type !== 'QUIZ_ORDERING') return ''
				const items = Array.isArray(question.config?.items) ? question.config.items : []
				const totalPoints = Number(question.points) || 0
				const pointsPerItem = items.length ? totalPoints / items.length : 0
				const formatted = pointsPerItem.toFixed(2).replace(/\.00$/, '').replace(/(\.\d)0$/, '$1')
				return this.IsEngLish
					? 'Equal scoring: each correctly placed item = ' + formatted + ' pt.'
					: 'Chấm đều: mỗi ý đúng vị trí = ' + formatted + ' điểm.'
			},
			cognitiveLevelsDefinition() {
				return [
					{ key: 'cog_van_dung_cao', title: this.IsEngLish ? 'High Application' : 'Vận dụng cao', color: 'deep-purple', aliases: ['vận dụng cao', 'van dung cao', 'van_dung_cao', 'VAN_DUNG_CAO', 'nâng cao', 'high application'] },
					{ key: 'cog_van_dung', title: this.IsEngLish ? 'Application' : 'Vận dụng', color: 'orange', aliases: ['vận dụng', 'van dung', 'van_dung', 'VAN_DUNG', 'application'] },
					{ key: 'cog_thong_hieu', title: this.IsEngLish ? 'Comprehension' : 'Thông hiểu', color: 'teal', aliases: ['thông hiểu', 'thong hieu', 'thong_hieu', 'THONG_HIEU', 'hiểu biết', 'comprehension'] },
					{ key: 'cog_nhan_biet', title: this.IsEngLish ? 'Recognition' : 'Nhận biết', color: 'info', aliases: ['nhận biết', 'nhan biet', 'nhan_biet', 'NHAN_BIET', 'recognition'] }
				]
			},
			questionCognitiveLevel() {
				return this.getQuestionCognitiveLevel(this.selectedQuestionData)
			},
			contentHubStatusColor() {
				return { exists: 'success', changed: 'warning', new: 'grey', checking: 'info', invalid: 'error', unsupported: 'grey', error: 'error' }[this.contentHubStatus.kind] || 'grey'
			},
			contentHubStatusIcon() {
				return { exists: 'mdi-check-circle-outline', changed: 'mdi-alert-circle-outline', new: 'mdi-information-outline', checking: 'mdi-loading', invalid: 'mdi-alert-outline', unsupported: 'mdi-information-outline', error: 'mdi-alert-circle-outline' }[this.contentHubStatus.kind] || 'mdi-database-outline'
			},
			contentHubStatusLabel() {
				if (this.contentHubStatus.message) return this.contentHubStatus.message
				return {
					exists: this.IsEngLish ? 'Already in Content Hub' : 'Đã có trong Kho soạn nội dung',
					changed: this.IsEngLish ? 'In hub, but content modified' : 'Đã có trong kho nhưng nội dung đã thay đổi',
					new: this.IsEngLish ? 'Not in Content Hub' : 'Chưa có trong Kho soạn nội dung',
					checking: this.IsEngLish ? 'Checking Content Hub...' : 'Đang kiểm tra Content Hub...',
					invalid: this.IsEngLish ? 'Question not eligible for hub' : 'Câu hỏi chưa đủ điều kiện đưa vào kho',
					unsupported: this.IsEngLish ? 'Question type not supported by Content Hub' : 'Loại câu hỏi chưa được Content Hub hỗ trợ',
					error: this.IsEngLish ? 'Unable to determine Content Hub status' : 'Chưa xác định được trạng thái Content Hub'
				}[this.contentHubStatus.kind] || ''
			},
			contentHubCanPublish() {
				return ['new', 'changed'].includes(this.contentHubStatus.kind)
					&& !this.contentHubPublishLoading
					&& Boolean(this.selectedQuestionData)
					&& Boolean(this.assignment?.MonHocID)
					&& Boolean(this.assignment?.KhoiID)
					&& !this.contentHubStatus.validationError
			},
			contentHubPublishButtonLabel() {
				return this.contentHubStatus.kind === 'changed'
					? (this.IsEngLish ? 'Update question' : 'Cập nhật câu hỏi')
					: (this.IsEngLish ? 'Push question to hub' : 'Đẩy câu hỏi vào kho')
			},
			contentHubQuestionPreviewText() {
				return this.contentHubText(this.selectedQuestionData?.config?.questionText || '')
			},
			contentHubQuestionTypeLabel() {
				if (this.IsEngLish) {
					return {
						QUIZ_SINGLE_CHOICE: 'Single Choice',
						QUIZ_MULTIPLE_CHOICE: 'Multiple Choice',
						QUIZ_TRUE_FALSE: 'True / False',
						QUIZ_MULTIPLE_TRUE_FALSE: 'Multiple True / False',
						QUIZ_FILL_IN_BLANK: 'Fill in the Blank',
						QUIZ_MATCHING: 'Matching',
						QUIZ_ORDERING: 'Ordering',
						ESSAY: 'Essay',
						SHORT_ANSWER: 'Short Answer',
						AUDIO_RESPONSE: 'Audio Response',
						FILE_UPLOAD: 'File Upload',
					}[this.selectedQuestionData?.type] || this.selectedQuestionData?.type || 'Question'
				}
				return {
					QUIZ_SINGLE_CHOICE: 'Trắc nghiệm 1 đáp án',
					QUIZ_MULTIPLE_CHOICE: 'Trắc nghiệm nhiều đáp án',
					QUIZ_TRUE_FALSE: 'Đúng / Sai',
					QUIZ_MULTIPLE_TRUE_FALSE: 'Nhiều Đúng / Sai',
					QUIZ_FILL_IN_BLANK: 'Điền vào chỗ trống',
					QUIZ_MATCHING: 'Ghép nối',
					QUIZ_ORDERING: 'Sắp xếp thứ tự',
					ESSAY: 'Tự luận',
					SHORT_ANSWER: 'Trả lời ngắn',
					AUDIO_RESPONSE: 'Ghi âm trả lời',
					FILE_UPLOAD: 'Nộp file',
				}[this.selectedQuestionData?.type] || this.selectedQuestionData?.type || 'Câu hỏi'
			},
			contentHubPreviewAnswers() {
				const question = this.selectedQuestionData
				const config = question?.config || {}
				const type = question?.type
				const optionLabel = index => String.fromCharCode(65 + index)
				const optionText = option => this.contentHubText(option?.text ?? option?.label ?? option?.value ?? '')
				if (['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE'].includes(type)) {
					const options = Array.isArray(config.options) ? config.options : []
					const correctSingle = this.contentHubNormalizeOptionId(config.correctAnswer, options)
					const correctMultiple = new Set((Array.isArray(config.correctAnswers) ? config.correctAnswers : [])
						.map(value => this.contentHubNormalizeOptionId(value, options)).filter(Boolean).map(String))
					return options.map((option, index) => ({
						key: String(option?.id ?? index),
						label: optionLabel(index) + '.',
						text: optionText(option),
						badge: type === 'QUIZ_SINGLE_CHOICE'
							? String(option?.id) === String(correctSingle) ? (this.IsEngLish ? 'Correct answer' : 'Đáp án đúng') : ''
							: correctMultiple.has(String(option?.id)) ? (this.IsEngLish ? 'Correct answer' : 'Đáp án đúng') : '',
						badgeColor: 'success',
					}))
				}
				if (type === 'QUIZ_TRUE_FALSE') {
					return [
						{ key: 'true', label: 'A.', text: this.IsEngLish ? 'True' : 'Đúng', badge: config.correctAnswer === true ? (this.IsEngLish ? 'Correct answer' : 'Đáp án đúng') : '', badgeColor: 'success' },
						{ key: 'false', label: 'B.', text: this.IsEngLish ? 'False' : 'Sai', badge: config.correctAnswer === false ? (this.IsEngLish ? 'Correct answer' : 'Đáp án đúng') : '', badgeColor: 'success' },
					]
				}
				if (type === 'QUIZ_MULTIPLE_TRUE_FALSE') {
					return (Array.isArray(config.options) ? config.options : []).map((option, index) => ({
						key: String(option?.id ?? index),
						label: optionLabel(index) + '.',
						text: optionText(option),
						badge: option?.correctAnswer === true ? (this.IsEngLish ? 'True' : 'Đúng') : option?.inCorrectAnswer === true ? (this.IsEngLish ? 'False' : 'Sai') : '',
						badgeColor: option?.correctAnswer === true ? 'success' : 'error',
					}))
				}
				if (type === 'QUIZ_FILL_IN_BLANK') {
					return (Array.isArray(config.parts) ? config.parts : []).filter(part => part?.type === 'blank').map((part, index) => ({
						key: String(part?.id ?? index),
						label: `${this.IsEngLish ? 'Blank' : 'Ô trống'} ${index + 1}:`,
						text: (Array.isArray(part?.acceptedAnswers) ? part.acceptedAnswers : []).map(value => this.contentHubText(value)).filter(Boolean).join(', ') || (this.IsEngLish ? 'No accepted answer' : 'Chưa có đáp án chấp nhận'),
						badge: '',
						badgeColor: 'success',
					}))
				}
				if (['QUIZ_MATCHING', 'QUIZ_MATCHING_V2'].includes(type)) {
					const columnA = Array.isArray(config.columnA) ? config.columnA : []
					const columnB = Array.isArray(config.columnB) ? config.columnB : []
					return (Array.isArray(config.correctPairs) ? config.correctPairs : []).map((pair, index) => {
						const left = columnA.find(item => String(item?.id) === String(pair?.from ?? pair?.aId ?? pair?.leftId))
						const right = columnB.find(item => String(item?.id) === String(pair?.to ?? pair?.bId ?? pair?.rightId))
						return { key: 'pair_' + index, label: `${this.IsEngLish ? 'Pair' : 'Cặp'} ${index + 1}:`, text: `${optionText(left)} → ${optionText(right)}`, badge: '', badgeColor: 'success' }
					})
				}
				if (type === 'QUIZ_ORDERING') {
					const items = Array.isArray(config.items) ? config.items : []
					const itemById = new Map(items.map(item => [String(item?.id), item]))
					const order = Array.isArray(config.correctOrder) && config.correctOrder.length
						? config.correctOrder
						: items.map(item => item?.id)
					return order.map((id, index) => ({
						key: 'ordering_' + index,
						label: (index + 1) + '.',
						text: this.contentHubText(itemById.get(String(id))?.text),
						badge: '',
						badgeColor: 'success',
					})).filter(item => item.text)
				}
				return []
			},
			contentHubScope() {
				const assignment = this.assignment || {}
				const firstText = (values, fallback) => {
					const value = values.map(item => this.contentHubText(item)).find(item => item.trim())
					return value || fallback
				}
				return {
					subject: firstText([
						assignment.MonHocName,
						assignment.TenMonHoc_HienThi,
						assignment.TenMonHoc,
						assignment.MonHocTitle,
						assignment.MonHoc?.TenMonHoc_HienThi,
						assignment.MonHoc?.TenMonHoc,
						assignment.MonHocID ? `ID ${assignment.MonHocID}` : '',
					], this.IsEngLish ? 'Unspecified' : 'Chưa xác định'),
					grade: firstText([
						assignment.KhoiName,
						assignment.TenKhoi_HienThi,
						assignment.TenKhoi,
						assignment.KhoiTitle,
						assignment.Khoi?.TenKhoi_HienThi,
						assignment.Khoi?.TenKhoi,
						assignment.KhoiID ? assignment.KhoiID : '',
					], this.IsEngLish ? 'Unspecified' : 'Chưa xác định'),
				}
			}
			},
			methods: {
			contentHubSupportedTypes() {
				// Các dạng tự luận/trả lời ngắn/audio chỉ cần lưu nội dung câu hỏi
				// và media (nếu có), không yêu cầu cấu hình đáp án đúng trong Kho soạn nội dung.
				return ['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_TRUE_FALSE', 'QUIZ_MULTIPLE_TRUE_FALSE', 'QUIZ_FILL_IN_BLANK', 'QUIZ_MATCHING', 'QUIZ_ORDERING', 'ESSAY', 'SHORT_ANSWER', 'AUDIO_RESPONSE']
			},
			contentHubNormalizeType(type) {
				return type === 'QUIZ_MATCHING_V2' ? 'QUIZ_MATCHING' : String(type || '').trim()
			},
			contentHubDeepClone(value, fallback = {}) {
				try { return JSON.parse(JSON.stringify(value)) } catch (error) { return fallback }
			},
			// Mọi dữ liệu đi vào ConfigJson phải qua đây để không biến object thành chuỗi "[object Object]".
			contentHubText(value) {
				if (value === null || value === undefined) return ''
				if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') return String(value)
				if (Array.isArray(value)) return value.map(item => this.contentHubText(item)).filter(Boolean).join(' ')
				if (typeof value === 'object') return this.contentHubText(value.html ?? value.content ?? value.text ?? value.value ?? value.label ?? '')
				return ''
			},
			contentHubNormalizeText(value) {
				return this.contentHubText(value)
					.replace(/&nbsp;/gi, ' ')
					.replace(/<\/?(?:p|div)(?:\s[^>]*)?>/gi, ' ')
					.replace(/\s+/g, ' ')
					.trim()
					.toLowerCase()
			},
			contentHubNormalizeBoolean(value) {
				if (value === true || value === 1 || String(value).toLowerCase() === 'true') return true
				if (value === false || value === 0 || String(value).toLowerCase() === 'false') return false
				return null
			},
			contentHubParseJson(value, fallback = {}) {
				if (value && typeof value === 'object') return this.contentHubDeepClone(value, fallback)
				try { return typeof value === 'string' && value.trim() ? JSON.parse(value) : fallback } catch (error) { return fallback }
			},
			contentHubNormalizeMedia(media) {
				const source = media && typeof media === 'object' ? media : {}
				const sourceItem = item => ({
					id: this.contentHubText(item?.id),
					name: this.contentHubText(item?.name),
					source: this.contentHubText(item?.source ?? item?.url ?? item?.externalSource),
					...(item?.mediaSource ? { mediaSource: this.contentHubText(item.mediaSource) } : {}),
				})
				const sourceList = value => (Array.isArray(value) ? value : []).map(sourceItem).filter(item => item.source || item.name || item.id)
				return {
					type: this.contentHubText(source.type || 'YOUTUBE'),
					sourceYT: sourceItem(source.sourceYT),
					sourceRecord: sourceItem(source.sourceRecord),
					sourceFiles: { file: sourceList(source.sourceFiles?.file), image: sourceList(source.sourceFiles?.image) },
				}
			},
			contentHubNormalizeOptionId(value, options) {
				const raw = value && typeof value === 'object' ? (value.id ?? value.value ?? value.key ?? value.text) : value
				const direct = (options || []).find(option => String(option.id) === String(raw))
				if (direct) return direct.id
				const textKey = this.contentHubNormalizeText(raw)
				const byText = (options || []).find(option => this.contentHubNormalizeText(option.text) === textKey)
				return byText ? byText.id : null
			},
			contentHubNormalizeSkills(skills) {
				return (Array.isArray(skills) ? skills : []).map(skill => {
					if (skill && typeof skill === 'object') {
						const id = skill.KyNang_MonHoc_ChiTietID ?? skill.SkillID ?? skill.SkillId ?? skill.id ?? skill.ID
						const name = skill.TenKyNang ?? skill.SkillName ?? skill.name ?? skill.title ?? ''
						return {
							...(id !== undefined && id !== null ? { KyNang_MonHoc_ChiTietID: id, id } : {}),
							TenKyNang: this.contentHubText(name),
							NhomKyNang: this.contentHubText(skill.NhomKyNang ?? skill.group ?? ''),
							SkillCode: this.contentHubText(skill.SkillCode ?? skill.code ?? ''),
							MucDoCode: this.contentHubText(skill.MucDoCode ?? skill.levelCode ?? ''),
							name: this.contentHubText(name),
						}
					}
					const value = this.contentHubText(skill)
					return value ? { id: value, name: value, TenKyNang: value } : null
				}).filter(Boolean)
			},
			// Chuyển schema nội bộ của Soạn bài tập sang schema mà EL_Question_* lưu trong Content Hub.
			contentHubNormalizeConfig(question) {
				const source = this.contentHubDeepClone(question?.config || {}, {})
				const type = this.contentHubNormalizeType(question?.type)
				const config = {
					questionText: this.contentHubText(source.questionText ?? source.prompt ?? question?.questionText ?? ''),
					isAdvanced: Boolean(source.isAdvanced),
					media: this.contentHubNormalizeMedia(source.media),
				}
				if (['SHORT_ANSWER', 'ESSAY'].includes(type)) {
					// Chỉ giữ đáp án tham khảo cho hai dạng chấm tay; làm sạch object/rich-text để không lưu "[object Object]".
					config.referenceAnswer = this.contentHubText(source.referenceAnswer)
				}
				if (type === 'QUIZ_SINGLE_CHOICE' || type === 'QUIZ_MULTIPLE_CHOICE') {
					const options = (Array.isArray(source.options) ? source.options : []).map((option, index) => ({
						id: this.contentHubText(option?.id ?? option?.value ?? String.fromCharCode(97 + index)),
						text: this.contentHubText(option?.text ?? option?.label ?? option?.content ?? option?.value ?? ''),
					}))
					config.options = options
					if (type === 'QUIZ_SINGLE_CHOICE') config.correctAnswer = this.contentHubNormalizeOptionId(source.correctAnswer, options)
					else config.correctAnswers = (Array.isArray(source.correctAnswers) ? source.correctAnswers : [])
						.map(value => this.contentHubNormalizeOptionId(value, options)).filter(value => value !== null)
					if (source.scoringMode) config.scoringMode = this.contentHubText(source.scoringMode)
				}
				if (type === 'QUIZ_TRUE_FALSE') {
					if (Array.isArray(source.options) && source.options.length) {
						config.options = source.options.map((option, index) => ({
							id: this.contentHubText(option?.id ?? String.fromCharCode(97 + index)),
							text: this.contentHubText(option?.text ?? option?.label ?? ''),
							correctAnswer: this.contentHubNormalizeBoolean(option?.correctAnswer) === true,
							inCorrectAnswer: this.contentHubNormalizeBoolean(option?.inCorrectAnswer) === true,
						}))
					} else config.correctAnswer = this.contentHubNormalizeBoolean(source.correctAnswer)
				}
				if (type === 'QUIZ_MULTIPLE_TRUE_FALSE') {
					config.options = (Array.isArray(source.options) ? source.options : []).map((option, index) => ({
						id: this.contentHubText(option?.id ?? String.fromCharCode(97 + index)),
						text: this.contentHubText(option?.text ?? option?.label ?? ''),
						correctAnswer: this.contentHubNormalizeBoolean(option?.correctAnswer) === true,
						inCorrectAnswer: this.contentHubNormalizeBoolean(option?.inCorrectAnswer) === true,
					}))
					config.scoringMode = this.contentHubText(source.scoringMode || 'equal')
				}
				if (type === 'QUIZ_FILL_IN_BLANK') {
					config.parts = (Array.isArray(source.parts) ? source.parts : []).map((part, index) => {
						if (part?.type !== 'blank') return { type: 'text', value: this.contentHubText(part?.value ?? part?.text ?? '') }
						const rawAnswers = Array.isArray(part.acceptedAnswers) ? part.acceptedAnswers : [part.acceptedAnswers ?? part.correctAnswer ?? part.answer]
						const acceptedAnswers = [...new Set(rawAnswers.map(value => this.contentHubText(value).trim()).filter(Boolean))]
						return { type: 'blank', id: this.contentHubText(part.id || ('blank_' + (index + 1))), correctAnswer: acceptedAnswers[0] || '', acceptedAnswers }
					})
				}
				if (type === 'QUIZ_MATCHING') {
					const sourceA = Array.isArray(source.columnA) ? source.columnA : []
					const sourceB = Array.isArray(source.columnB) ? source.columnB : []
					const columnA = sourceA.map((item, index) => ({ id: 'a_' + index, text: this.contentHubText(item?.text ?? item?.label ?? item?.value ?? '') }))
					const columnB = sourceB.map((item, index) => ({ id: 'b_' + index, text: this.contentHubText(item?.text ?? item?.label ?? item?.value ?? '') }))
					const findIndex = (items, value) => {
						const raw = value && typeof value === 'object' ? (value.id ?? value.value ?? value.text) : value
						const direct = items.findIndex(item => String(item?.id) === String(raw))
						if (direct >= 0) return direct
						return items.findIndex(item => this.contentHubNormalizeText(item?.text) === this.contentHubNormalizeText(raw))
					}
					config.columnA = columnA
					config.columnB = columnB
					config.correctPairs = (Array.isArray(source.correctPairs) ? source.correctPairs : []).map(pair => {
						const left = findIndex(sourceA, pair?.aId ?? pair?.leftId ?? pair?.sourceId ?? pair?.from)
						const right = findIndex(sourceB, pair?.bId ?? pair?.rightId ?? pair?.targetId ?? pair?.to)
						return left >= 0 && right >= 0 ? { from: 'a_' + left, to: 'b_' + right } : null
					}).filter(Boolean)
				}
				if (type === 'QUIZ_ORDERING') {
					// Chuẩn hóa cả schema mới (`items`) và dữ liệu thử nghiệm cũ dùng `options`.
					// `correctOrder` chỉ tham chiếu ID, giúp đổi vị trí mà không phụ thuộc text của ý.
					const sourceItems = Array.isArray(source.items) ? source.items : (Array.isArray(source.options) ? source.options : [])
					const items = sourceItems.map((item, index) => ({
						id: this.contentHubText(item?.id ?? item?.value ?? ('ordering_' + (index + 1))),
						text: this.contentHubText(item?.text ?? item?.label ?? item?.content ?? item?.value ?? ''),
					}))
					const orderValues = Array.isArray(source.correctOrder) && source.correctOrder.length
						? source.correctOrder
						: items.map(item => item.id)
					const resolveId = value => {
						const direct = items.find(item => String(item.id) === String(value))
						if (direct) return direct.id
						const index = Number(value)
						return Number.isInteger(index) && items[index] ? items[index].id : null
					}
					config.items = items
					config.correctOrder = orderValues.map(resolveId).filter(Boolean)
					// Ordering luôn là quiz tự chấm; điểm của mỗi vị trí được suy ra từ tổng điểm / số item.
					config.scoringMode = 'equal'
				}
				return config
			},
			contentHubStableValue(value) {
				if (Array.isArray(value)) return value.map(item => this.contentHubStableValue(item))
				if (value && typeof value === 'object') return Object.keys(value).sort().reduce((result, key) => {
					result[key] = this.contentHubStableValue(value[key])
					return result
				}, {})
				return value
			},
			contentHubHash(value) {
				let first = 2166136261
				let second = 2246822519
				for (let index = 0; index < value.length; index += 1) {
					const code = value.charCodeAt(index)
					first = Math.imul(first ^ code, 16777619)
					second = Math.imul(second ^ code, 3266489917)
				}
				return (first >>> 0).toString(16).padStart(8, '0') + (second >>> 0).toString(16).padStart(8, '0')
			},
			contentHubSemanticConfig(type, config) {
				const media = config.media || {}
				const semantic = {
					isAdvanced: Boolean(config.isAdvanced),
					media: {
						type: this.contentHubNormalizeText(media.type),
						youtube: this.contentHubNormalizeText(media.sourceYT?.source),
						audio: this.contentHubNormalizeText(media.sourceRecord?.source),
						files: [...(media.sourceFiles?.file || []), ...(media.sourceFiles?.image || [])].map(file => ({ name: this.contentHubNormalizeText(file?.name), source: this.contentHubNormalizeText(file?.source) })),
					},
				}
				if (type === 'QUIZ_SINGLE_CHOICE' || type === 'QUIZ_MULTIPLE_CHOICE') {
					const options = (config.options || []).map(option => ({ text: this.contentHubNormalizeText(option?.text) }))
					const indexOf = value => (config.options || []).findIndex(option => String(option?.id) === String(value))
					semantic.options = options
					semantic.correct = type === 'QUIZ_SINGLE_CHOICE'
						? indexOf(config.correctAnswer)
						: (config.correctAnswers || []).map(indexOf).filter(index => index >= 0).sort((a, b) => a - b)
				}
				if (type === 'QUIZ_TRUE_FALSE') semantic.answer = Array.isArray(config.options)
					? config.options.map(option => ({ text: this.contentHubNormalizeText(option?.text), correct: option.correctAnswer === true, incorrect: option.inCorrectAnswer === true }))
					: config.correctAnswer
				if (type === 'QUIZ_MULTIPLE_TRUE_FALSE') semantic.options = (config.options || []).map(option => ({ text: this.contentHubNormalizeText(option?.text), correct: option.correctAnswer === true, incorrect: option.inCorrectAnswer === true }))
				if (type === 'QUIZ_FILL_IN_BLANK') semantic.parts = (config.parts || []).map(part => part.type === 'blank'
					? { type: 'blank', acceptedAnswers: (part.acceptedAnswers || []).map(value => this.contentHubNormalizeText(value)).sort() }
					: { type: 'text', value: this.contentHubNormalizeText(part.value) })
				if (type === 'QUIZ_MATCHING') {
					semantic.columnA = (config.columnA || []).map(item => this.contentHubNormalizeText(item?.text))
					semantic.columnB = (config.columnB || []).map(item => this.contentHubNormalizeText(item?.text))
					semantic.pairs = (config.correctPairs || []).map(pair => ({
						from: (config.columnA || []).findIndex(item => String(item?.id) === String(pair?.from)),
						to: (config.columnB || []).findIndex(item => String(item?.id) === String(pair?.to)),
					})).sort((a, b) => a.from - b.from)
				}
				if (type === 'QUIZ_ORDERING') {
					const items = Array.isArray(config.items) ? config.items : []
					const itemIndex = new Map(items.map((item, index) => [String(item?.id), index]))
					semantic.items = items.map(item => this.contentHubNormalizeText(item?.text))
					semantic.correctOrder = (Array.isArray(config.correctOrder) ? config.correctOrder : [])
						.map(id => itemIndex.get(String(id)))
						.filter(index => index !== undefined)
					semantic.scoringMode = 'equal'
				}
				if (type === 'SHORT_ANSWER' || type === 'ESSAY') {
					// Đáp án tham khảo là một phần nội dung cần theo dõi khi xác định câu hỏi đã thay đổi trong Content Hub.
					semantic.referenceAnswer = this.contentHubNormalizeText(config.referenceAnswer)
				}
				return semantic
			},
			contentHubBuildPayload(question) {
				const type = this.contentHubNormalizeType(question?.type)
				const config = this.contentHubNormalizeConfig(question)
				const questionText = config.questionText
				const semantic = this.contentHubStableValue({
					type,
					questionText: this.contentHubNormalizeText(questionText),
					config: this.contentHubSemanticConfig(type, config),
				})
				const fingerprint = this.contentHubHash(JSON.stringify(semantic))
				return {
					type,
					config,
					questionText,
					points: Number(question?.points ?? 1) || 1,
					// Ordering có đáp án chuẩn và luôn đi theo luồng quiz tự chấm.
					gradingType: type === 'QUIZ_ORDERING' ? 'auto' : (question?.gradingType || (type.startsWith('QUIZ_') ? 'auto' : 'manual')),
					isAdvanced: config.isAdvanced ? 1 : 0,
					skills: this.contentHubNormalizeSkills(question?.skills),
					fingerprint,
					sourceId: 'ASSIGNMENT_FP_' + fingerprint,
				}
			},
			contentHubValidatePayload(payload) {
				const errors = []
				const plainQuestionText = this.contentHubNormalizeText(payload?.questionText).replace(/<[^>]*>/g, ' ').trim()
				if (!plainQuestionText) errors.push(this.IsEngLish ? 'Question content is empty.' : 'Nội dung câu hỏi đang trống.')
				if (!this.contentHubSupportedTypes().includes(payload?.type)) errors.push(this.IsEngLish ? 'This question type is not supported by Content Hub.' : 'Loại câu hỏi này chưa được Content Hub hỗ trợ.')
				const config = payload?.config || {}
				if (['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE'].includes(payload?.type)) {
					const options = Array.isArray(config.options) ? config.options : []
					if (options.length < 2 || options.some(option => !this.contentHubNormalizeText(option?.text))) errors.push(this.IsEngLish ? 'Options must have at least 2 choices and cannot be empty.' : 'Các lựa chọn phải có ít nhất 2 đáp án và không được để trống.')
					if (payload.type === 'QUIZ_SINGLE_CHOICE' && !config.correctAnswer) errors.push(this.IsEngLish ? 'Question does not have a correct answer.' : 'Câu hỏi chưa có đáp án đúng.')
					if (payload.type === 'QUIZ_MULTIPLE_CHOICE' && (!Array.isArray(config.correctAnswers) || !config.correctAnswers.length)) errors.push(this.IsEngLish ? 'Question does not have a correct answer.' : 'Câu hỏi chưa có đáp án đúng.')
				}
				if (payload?.type === 'QUIZ_TRUE_FALSE' && Array.isArray(config.options)) {
					if (!config.options.length || config.options.some(option => !this.contentHubNormalizeText(option?.text))) errors.push(this.IsEngLish ? 'True/False statements cannot be empty.' : 'Các mệnh đề Đúng/Sai không được để trống.')
					if (!config.options.some(option => option.correctAnswer === true || option.inCorrectAnswer === true)) errors.push(this.IsEngLish ? 'Question has no True/False answer set.' : 'Câu hỏi chưa có đáp án Đúng/Sai.')
				} else if (payload?.type === 'QUIZ_TRUE_FALSE' && typeof config.correctAnswer !== 'boolean') errors.push(this.IsEngLish ? 'Question has not specified True/False answer.' : 'Câu hỏi chưa xác định đáp án Đúng/Sai.')
				if (payload?.type === 'QUIZ_MULTIPLE_TRUE_FALSE') {
					const options = Array.isArray(config.options) ? config.options : []
					if (!options.length || options.some(option => !this.contentHubNormalizeText(option?.text) || (option.correctAnswer !== true && option.inCorrectAnswer !== true))) errors.push(this.IsEngLish ? 'Each True/False statement must have content and an answer.' : 'Mỗi mệnh đề Đúng/Sai phải có nội dung và đáp án.')
				}
				if (payload?.type === 'QUIZ_FILL_IN_BLANK') {
					const parts = Array.isArray(config.parts) ? config.parts : []
					if (!parts.some(part => part.type === 'blank')) errors.push(this.IsEngLish ? 'Fill in blank question must have at least one blank.' : 'Câu điền khuyết phải có ít nhất một ô trống.')
					if (parts.some(part => part.type === 'blank' && !(part.acceptedAnswers || []).length)) errors.push(this.IsEngLish ? 'Each blank must have at least one accepted answer.' : 'Mỗi ô trống phải có ít nhất một đáp án chấp nhận.')
				}
				if (payload?.type === 'QUIZ_MATCHING') {
					const columnA = Array.isArray(config.columnA) ? config.columnA : []
					const columnB = Array.isArray(config.columnB) ? config.columnB : []
					if (!columnA.length || columnA.length !== columnB.length || columnA.some(item => !this.contentHubNormalizeText(item?.text)) || columnB.some(item => !this.contentHubNormalizeText(item?.text))) errors.push(this.IsEngLish ? 'Matching question must have both columns and cannot be empty.' : 'Câu nối đáp án phải có đủ hai cột và không được để trống.')
					if (!Array.isArray(config.correctPairs) || config.correctPairs.length !== columnA.length) errors.push(this.IsEngLish ? 'Matching question does not have enough correct pairs.' : 'Câu nối đáp án chưa có đủ cặp đúng.')
				}
				if (payload?.type === 'QUIZ_ORDERING') {
					const items = Array.isArray(config.items) ? config.items : []
					const itemIds = items.map(item => String(item?.id ?? ''))
					const correctOrder = Array.isArray(config.correctOrder) ? config.correctOrder.map(id => String(id)) : []
					const uniqueItemIds = new Set(itemIds)
					if (items.length < 2 || itemIds.some(id => !id) || uniqueItemIds.size !== items.length || items.some(item => !this.contentHubNormalizeText(item?.text))) {
						errors.push(this.IsEngLish ? 'Ordering question needs at least 2 non-empty items.' : 'Câu sắp xếp phải có ít nhất 2 ý và không được để trống.')
					}
					if (correctOrder.length !== items.length || new Set(correctOrder).size !== items.length || correctOrder.some(id => !uniqueItemIds.has(id))) {
						errors.push(this.IsEngLish ? 'Ordering question has an invalid correct order.' : 'Thứ tự đúng của câu sắp xếp chưa hợp lệ.')
					}
				}
				return { valid: errors.length === 0, errors }
			},
			contentHubRows(result) {
				const value = result?.data ?? result
				if (Array.isArray(value?.[0])) return value[0]
				return Array.isArray(value) ? value : []
			},
			contentHubFirstRow(result) {
				return this.contentHubRows(result).find(item => item && (item.Id || item.ID || item.QuestionId)) || null
			},
			contentHubCandidatePayload(row) {
				const config = this.contentHubParseJson(row?.ConfigJson, {})
				return this.contentHubBuildPayload({ type: row?.Type, points: row?.Points, gradingType: row?.GradingType, config: { ...config, questionText: config.questionText ?? config.prompt ?? row?.QuestionText }, skills: this.contentHubParseJson(row?.SkillsJson, []) })
			},
			contentHubCandidateMatches(payload, row) {
			if (!row) return false
			if (String(row.SourceId || '') === String(payload.sourceId)) return true
			try { return this.contentHubCandidatePayload(row).fingerprint === payload.fingerprint } catch (error) { return false }
			},
			async contentHubFetchCandidates(payload) {
				const result = await fetchPromise('lms/EL_Question_ContentHub_Check', {
					MonHocID: Number(this.assignment?.MonHocID),
					KhoiID: Number(this.assignment?.KhoiID),
					Type: payload.type,
					QuestionText: payload.questionText,
					SourceId: payload.sourceId,
				}, { forceRefresh: true, useStaleCacheOnError: false })
				return this.contentHubRows(result)
			},
			contentHubSetSourceTracking(questionId, groupId, groupTitle, fingerprint) {
				const current = this.selectedQuestionData
				if (!current || !questionId) return
				const old = current.sourceTracking || {}
				if (String(old.questionId || '') === String(questionId) && String(old.fingerprint || '') === String(fingerprint) && String(old.groupId || '') === String(groupId || '')) return
				const groups = this.contentHubDeepClone(this.groups, [])
				const question = groups[this.item.groupIndex]?.questions?.[this.item.qIndex]
				if (!question) return
				question.sourceTracking = {
					...old,
					sourceType: 'CONTENT_HUB',
					sourceKind: 'QUESTION_BANK',
					questionId,
					groupId: groupId || old.groupId || null,
					groupTitle: groupTitle || old.groupTitle || '',
					fingerprint,
					linkedAt: old.linkedAt || new Date().toISOString(),
				}
				this.updateGroups(groups)
			},
			contentHubApplyExisting(row, payload, changed = false) {
				const questionId = row?.Id ?? row?.ID ?? row?.QuestionId
				const groupId = row?.GroupId ?? row?.groupId
				this.contentHubSetSourceTracking(questionId, groupId, row?.GroupTitle || '', payload.fingerprint)
				this.contentHubStatus = {
					kind: changed ? 'changed' : 'exists',
					fingerprint: payload.fingerprint,
					questionId,
					groupId,
					groupTitle: row?.GroupTitle || '',
					message: changed ? 'Đã có trong kho nhưng nội dung đã thay đổi' : `Đã có trong Kho soạn nội dung${row?.GroupTitle ? ' · ' + row.GroupTitle : ''}`,
				}
			},
			async checkContentHubQuestionStatus(payload, requestId) {
				try {
					const rows = await this.contentHubFetchCandidates(payload)
					if (requestId !== this.contentHubStatusRequest) return
					const match = rows.find(row => this.contentHubCandidateMatches(payload, row))
					if (match) this.contentHubApplyExisting(match, payload)
					else this.contentHubStatus = { kind: 'new', fingerprint: payload.fingerprint, questionId: null, groupId: null, groupTitle: '', message: '' }
				} catch (error) {
					if (requestId !== this.contentHubStatusRequest) return
					this.contentHubStatus = { kind: 'error', fingerprint: payload.fingerprint, questionId: null, groupId: null, groupTitle: '', message: 'Không kiểm tra được Content Hub' }
				}
			},
			scheduleContentHubStatusCheck(force = false) {
				clearTimeout(this.contentHubStatusTimer)
				const question = this.selectedQuestionData
				if (!question) {
					this.contentHubStatus = { kind: 'idle', fingerprint: '', questionId: null, groupId: null, groupTitle: '', message: '' }
					return
				}
				let payload
				try { payload = this.contentHubBuildPayload(question) } catch (error) {
					this.contentHubStatus = { kind: 'invalid', fingerprint: '', questionId: null, groupId: null, groupTitle: '', message: 'Không đọc được cấu trúc JSON câu hỏi' }
					return
				}
				const validation = this.contentHubValidatePayload(payload)
				if (!validation.valid) {
					this.contentHubStatus = { kind: 'invalid', fingerprint: payload.fingerprint, questionId: null, groupId: null, groupTitle: '', validationError: validation.errors.join(' '), message: validation.errors[0] }
					return
				}
				const tracking = question.sourceTracking || {}
				if (tracking.questionId) {
					if (!tracking.fingerprint) this.contentHubSetSourceTracking(tracking.questionId, tracking.groupId, tracking.groupTitle, payload.fingerprint)
					this.contentHubStatus = {
						kind: tracking.fingerprint && tracking.fingerprint !== payload.fingerprint ? 'changed' : 'exists',
						fingerprint: payload.fingerprint,
						questionId: tracking.questionId,
						groupId: tracking.groupId || null,
						groupTitle: tracking.groupTitle || '',
						message: tracking.fingerprint && tracking.fingerprint !== payload.fingerprint ? 'Đã có trong kho nhưng nội dung đã thay đổi' : 'Đã có trong Kho soạn nội dung',
					}
					return
				}
				this.contentHubStatus = { kind: 'checking', fingerprint: payload.fingerprint, questionId: null, groupId: null, groupTitle: '', message: '' }
				const requestId = ++this.contentHubStatusRequest
				this.contentHubStatusTimer = setTimeout(() => this.checkContentHubQuestionStatus(payload, requestId), force ? 0 : 450)
			},
			async loadContentHubGroups() {
				if (!this.assignment?.MonHocID || !this.assignment?.KhoiID) return
				this.contentHubGroupsLoading = true
				try {
					const result = await fetchPromise('lms/EL_QuestionGroup_List', {
						MonHocID: Number(this.assignment.MonHocID),
						KhoiID: Number(this.assignment.KhoiID),
						IncludeDeleted: false,
						PageNumber: 1,
						PageSize: 100,
					}, { forceRefresh: true, useStaleCacheOnError: false })
					this.contentHubGroups = this.contentHubRows(result).filter(group => !group.IsDeleted)
					const existingGroupId = this.contentHubStatus.groupId
					this.contentHubTargetGroup = this.contentHubGroups.find(group => String(group.Id) === String(existingGroupId)) || this.contentHubGroups[0] || null
				} catch (error) {
					this.contentHubGroups = []
					this.contentHubPublishError = 'Không tải được nhóm câu hỏi trong Content Hub.'
				} finally { this.contentHubGroupsLoading = false }
			},
			openContentHubCreateGroupDialog() {
				this.contentHubCreateGroupName = ''
				this.contentHubCreateGroupError = ''
				this.contentHubCreateGroupDialog = true
			},
			async createContentHubGroup() {
				const title = String(this.contentHubCreateGroupName || '').trim()
				if (!title) {
					this.contentHubCreateGroupError = 'Vui lòng nhập tên nhóm câu hỏi.'
					return
				}
				if (!this.assignment?.MonHocID || !this.assignment?.KhoiID) {
					this.contentHubCreateGroupError = 'Bài tập chưa có đủ Môn và Khối để tạo nhóm.'
					return
				}
				this.contentHubCreateGroupLoading = true
				this.contentHubCreateGroupError = ''
				try {
					const result = await fetchPromise('lms/EL_QuestionGroup_Create', {
						SourceId: crypto.randomUUID(),
						MonHocID: Number(this.assignment.MonHocID),
						KhoiID: Number(this.assignment.KhoiID),
						Title: title,
						Description: '',
						OrdinalNumber: 0,
						MediaJson: JSON.stringify({
							type: 'YOUTUBE',
							sourceYT: { id: '', source: '', name: '' },
							sourceRecord: { id: '', source: '', name: '' },
							sourceFiles: { image: [], file: [] },
						}),
						User: this.vueData?.user?.UserID,
					}, { cache: false })
					const created = this.contentHubFirstRow(result) || (result && !Array.isArray(result) && (result.Id || result.ID) ? result : null)
					const resultValue = Array.isArray(result) ? result[0] : result
					if (!created && resultValue?.status !== 'success' && resultValue?.Action !== 'Created') throw new Error('create-group-failed')
					await this.loadContentHubGroups()
					const createdId = created?.Id ?? created?.ID
					this.contentHubTargetGroup = this.contentHubGroups.find(group =>
						(createdId && String(group.Id) === String(createdId)) || String(group.Title || '').trim() === title
					) || this.contentHubTargetGroup
					this.contentHubCreateGroupDialog = false
					this.contentHubNotify(`Đã tạo nhóm "${title}".`, 'success')
				} catch (error) {
					this.contentHubCreateGroupError = error?.Message || error?.message || 'Không thể tạo nhóm câu hỏi.'
				} finally { this.contentHubCreateGroupLoading = false }
			},
			async openContentHubPublishDialog() {
				if (!this.contentHubCanPublish) return
				this.contentHubPublishError = ''
				this.contentHubPushDialog = true
				if (this.contentHubStatus.kind !== 'changed') await this.loadContentHubGroups()
			},
			contentHubBuildStoragePayload(payload, groupId, existingId = null) {
				const question = this.selectedQuestionData
				const tracking = {
					...(question?.sourceTracking || {}),
					sourceType: 'CONTENT_HUB',
					sourceKind: 'QUESTION_BANK',
					fingerprint: payload.fingerprint,
					groupId,
					assignmentId: this.assignment?.AssignmentID || vueData.AssignmentID || null,
					assignmentQuestionId: question?.id || null,
				}
				const config = { ...payload.config, sourceTracking: tracking }
				return {
					...(existingId ? { Id: existingId } : {}),
					GroupId: groupId,
					SourceId: payload.sourceId,
					Type: payload.type,
					QuestionText: payload.questionText,
					OrdinalNumber: question?.ordinalNumber ?? null,
					Points: payload.points,
					GradingType: payload.gradingType,
					IsAdvanced: payload.isAdvanced,
					ConfigJson: JSON.stringify(config),
					SkillsJson: JSON.stringify(payload.skills),
					RawJson: JSON.stringify({ sourceType: 'ASSIGNMENT_BUILDER', assignmentId: this.assignment?.AssignmentID || vueData.AssignmentID || null, assignmentQuestionId: question?.id || null, fingerprint: payload.fingerprint }),
					User: this.vueData.user?.UserID,
				}
			},
			async publishQuestionToContentHub() {
				if (!this.selectedQuestionData) return
				this.contentHubPublishError = ''
				let payload
				try { payload = this.contentHubBuildPayload(this.selectedQuestionData) } catch (error) { this.contentHubPublishError = 'Không đọc được cấu trúc JSON câu hỏi.'; return }
				const validation = this.contentHubValidatePayload(payload)
				if (!validation.valid) { this.contentHubPublishError = validation.errors.join(' '); return }
				this.contentHubPublishLoading = true
				try {
					// Kiểm tra lại ngay trước khi ghi để tránh dữ liệu bị tạo trùng khi có người khác vừa publish.
					const rows = await this.contentHubFetchCandidates(payload)
					const trackedId = this.selectedQuestionData.sourceTracking?.questionId
					const duplicate = rows.find(row => this.contentHubCandidateMatches(payload, row))
					if (duplicate && String(duplicate.Id) !== String(trackedId || '')) {
						this.contentHubApplyExisting(duplicate, payload)
						this.contentHubPushDialog = false
						this.contentHubNotify('Câu hỏi đã tồn tại trong Kho soạn nội dung, không tạo bản ghi mới.', 'info')
						return
					}
					const existingId = trackedId || null
					const groupId = existingId ? (this.selectedQuestionData.sourceTracking?.groupId || this.contentHubStatus.groupId) : this.contentHubTargetGroup?.Id
					if (!groupId) { this.contentHubPublishError = 'Vui lòng tạo và chọn nhóm câu hỏi trong Content Hub trước.'; return }
					const endpoint = existingId ? 'lms/EL_Question_Update' : 'lms/EL_Question_PublishFromAssignment'
					const result = await fetchPromise(endpoint, this.contentHubBuildStoragePayload(payload, groupId, existingId), { cache: false })
					const saved = this.contentHubFirstRow(result)
					if (!saved) throw new Error('publish-failed')
					this.contentHubSetSourceTracking(saved.Id || existingId, saved.GroupId || groupId, this.contentHubTargetGroup?.Title || this.contentHubStatus.groupTitle || '', payload.fingerprint)
					this.contentHubStatus = { kind: 'exists', fingerprint: payload.fingerprint, questionId: saved.Id || existingId, groupId: saved.GroupId || groupId, groupTitle: this.contentHubTargetGroup?.Title || '', message: 'Đã có trong Kho soạn nội dung' }
					this.contentHubPushDialog = false
					this.contentHubNotify(existingId ? 'Đã cập nhật câu hỏi trong Kho soạn nội dung.' : 'Đã đẩy câu hỏi vào Kho soạn nội dung.', 'success')
				} catch (error) {
					this.contentHubPublishError = error?.Message || error?.message || 'Không thể lưu câu hỏi vào Kho soạn nội dung.'
				} finally { this.contentHubPublishLoading = false }
			},
			contentHubNotify(message, color = 'success') {
				if (this.snackbarRef?.value?.showSnackbar) this.snackbarRef.value.showSnackbar({ message, color })
				else if (typeof showMessage === 'function') showMessage({ title: message, type: color })
				else if (typeof Vue !== 'undefined' && Vue.$toast?.[color]) Vue.$toast[color](message)
			},
			// Group RANDOM tiêu chuẩn lấy toàn bộ câu đang có trong group.
			// questionSource.questionIds chỉ phục vụ metadata nguồn/ma trận, không giới hạn pool này.
			getRandomPoolSize(group) {
				return Array.isArray(group?.questions) ? group.questions.length : 0
			},
			normalizeCognitiveText(value) {
				return String(value ?? '')
					.normalize('NFD')
					.replace(/[\u0300-\u036f]/g, '')
					.trim()
					.toLowerCase()
			},
			getQuestionCognitiveLevel(question) {
				if (!question) return null
				const config = question.config || {}
				const skills = Array.isArray(question.skills) ? question.skills : []
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
				].map(value => this.normalizeCognitiveText(value)).filter(Boolean)
				const searchable = values.join(' | ')
				return this.cognitiveLevelsDefinition.find(level => {
					return level.aliases.some(alias => searchable.includes(this.normalizeCognitiveText(alias)))
				}) || null
			},
			getPartKey(part, index) {
				return part.type === 'blank' ? part.id : ('text_' + index)
			},
			onPointInput(value) {
				const normalized = vueData.normalizeNumberInput(value);
				// Clamp to 0 minimum — negative points not allowed
				this.updateQuestion('points', (isNaN(normalized) || normalized < 0) ? 0 : normalized);
			},
			onScoringModeChange(value) {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const q = ng[this.item.groupIndex].questions[this.item.qIndex];
				q.config.scoringMode = value;
				if (value === 'partial') {
					q.points = 1.0;
					// Ensure exactly 4 options
					while (q.config.options.length < 4) {
						const ts = Date.now() + q.config.options.length;
						if (q.type === 'QUIZ_MULTIPLE_TRUE_FALSE') {
							q.config.options.push({ id: `opt_${ts}`, text: '', correctAnswer: null, inCorrectAnswer: null });
						} else {
							q.config.options.push({ id: `opt_${ts}`, text: '' });
						}
					}
					if (q.config.options.length > 4) q.config.options = q.config.options.slice(0, 4);
				}
				this.updateGroups(ng);
			},
	
			isAutoGradable(type) { return vueData.isAutoGradable(type) },
			// Handle emit từ uc-media cho group
			handleGroupMediaUpdate(updatedData) {
				if (!this.item || this.item.type !== 'group') return;
				const ng = this.groups;
				const media = updatedData.media
	
				ng[this.item.groupIndex] = {
					...ng[this.item.groupIndex],
					media: {
						...ng[this.item.groupIndex].media,
						type: media.type,
						sourceYT: media.sourceYT,
						sourceRecord: media.sourceRecord,
						sourceFiles: {
							file: media.sourceFiles?.file ?? [],
							image: media.sourceFiles?.image ?? [],
						}
					}
				};
				this.updateGroups(ng);
			},
			// Handle emit từ uc-media cho question
			handleQuestionMediaUpdate(updatedData) {
				if (!this.item || this.item.type !== 'question') return;
				const ng = this.groups;
				const media = updatedData.media
	
				ng[this.item.groupIndex].questions[this.item.qIndex] = {
					...ng[this.item.groupIndex].questions[this.item.qIndex],
					config: {
						...ng[this.item.groupIndex].questions[this.item.qIndex].config,
						media: {
							...ng[this.item.groupIndex].questions[this.item.qIndex].config.media,
							type: media.type,
							sourceYT: media.sourceYT,
							sourceRecord: media.sourceRecord,
							sourceFiles: {
								file: media.sourceFiles?.file ?? [],
								image: media.sourceFiles?.image ?? [],
							}
						}
					}
				};
				this.updateGroups(ng);
			},
	
			updateGroups(newGroups) {
				this.$emit('update:groups', newGroups);
			},
			updateRandomQuestionPool(enabled) {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const group = ng[this.item.groupIndex];
				if (enabled) {
					const sourceCount = this.getRandomPoolSize(group);
					group.questionSource = group.questionSource || { type: 'QUESTION_POOL' };
					group.questionSelection = {
						mode: 'RANDOM',
						questionsPerAttempt: Math.min(Math.max(1, Number(group.questionSelection?.questionsPerAttempt) || sourceCount), sourceCount || 1)
					};
				} else {
					delete group.questionSelection;
					delete group.questionSource;
				}
				this.updateGroups(ng);
			},
			updateRandomQuestionsPerAttempt(value) {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const group = ng[this.item.groupIndex];
				const sourceCount = this.getRandomPoolSize(group);
				const count = Math.trunc(Number(value));
				group.questionSelection = {
					mode: 'RANDOM',
					questionsPerAttempt: Number.isFinite(count) ? count : 0
				};
				if (sourceCount > 0 && group.questionSelection.questionsPerAttempt > sourceCount) {
					group.questionSelection.questionsPerAttempt = sourceCount;
				}
				this.updateGroups(ng);
			},
			updateItem(key, value) {
				const ng = JSON.parse(JSON.stringify(this.groups));
				if (this.item.type === 'group') {
					ng[this.item.groupIndex][key] = value;
				}
				this.updateGroups(ng);
			},
			updateQuestion(key, value) { const ng = JSON.parse(JSON.stringify(this.groups)); ng[this.item.groupIndex].questions[this.item.qIndex][key] = value; this.updateGroups(ng); },
			updateQuestionConfig(key, value) { const ng = JSON.parse(JSON.stringify(this.groups)); ng[this.item.groupIndex].questions[this.item.qIndex].config[key] = value; this.updateGroups(ng); },
			updateOptionText(optionIndex, text) { const ng = JSON.parse(JSON.stringify(this.groups)); ng[this.item.groupIndex].questions[this.item.qIndex].config.options[optionIndex].text = text; this.updateGroups(ng); },
			updateOrderingItemText(itemIndex, text) {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const q = ng[this.item.groupIndex].questions[this.item.qIndex];
				if (!Array.isArray(q.config.items)) q.config.items = [];
				if (q.config.items[itemIndex]) q.config.items[itemIndex].text = text;
				q.config.correctOrder = q.config.items.map(entry => entry.id);
				this.updateGroups(ng);
			},
			addOrderingItem() {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const q = ng[this.item.groupIndex].questions[this.item.qIndex];
				if (!Array.isArray(q.config.items)) q.config.items = [];
				q.config.items.push({ id: 'ordering_' + Date.now() + '_' + q.config.items.length, text: '' });
				q.config.correctOrder = q.config.items.map(entry => entry.id);
				this.updateGroups(ng);
			},
			moveOrderingItem(itemIndex, direction) {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const q = ng[this.item.groupIndex].questions[this.item.qIndex];
				const items = Array.isArray(q.config.items) ? q.config.items : [];
				const targetIndex = itemIndex + direction;
				if (targetIndex < 0 || targetIndex >= items.length) return;
				const moved = items.splice(itemIndex, 1)[0];
				items.splice(targetIndex, 0, moved);
				q.config.correctOrder = items.map(entry => entry.id);
				this.updateGroups(ng);
			},
			removeOrderingItem(itemIndex) {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const q = ng[this.item.groupIndex].questions[this.item.qIndex];
				if (!Array.isArray(q.config.items) || q.config.items.length <= 2) return;
				q.config.items.splice(itemIndex, 1);
				q.config.correctOrder = q.config.items.map(entry => entry.id);
				this.updateGroups(ng);
			},
			addOption() {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const q = ng[this.item.groupIndex].questions[this.item.qIndex];
				const isMTF = q.type === 'QUIZ_MULTIPLE_TRUE_FALSE';
				const newOption = isMTF
					? { id: `opt_${Date.now()}`, text: 'Lựa chọn mới', correctAnswer: null, inCorrectAnswer: null }
					: { id: `opt_${Date.now()}`, text: 'Lựa chọn mới' };
				q.config.options.push(newOption);
				this.updateGroups(ng);
			},
			removeOption(optionIndex) {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const q = ng[this.item.groupIndex].questions[this.item.qIndex];
				const removedId = q.config.options[optionIndex]?.id;
				q.config.options.splice(optionIndex, 1);
				if (removedId) {
					if (q.config.correctAnswer === removedId) q.config.correctAnswer = null;
					if (Array.isArray(q.config.correctAnswers)) {
						q.config.correctAnswers = q.config.correctAnswers.filter(id => id !== removedId);
					}
				}
				this.updateGroups(ng);
			},
			getAcceptedAnswers(part) {
				if (!part) return [];
				const raw = Array.isArray(part.acceptedAnswers)
					? part.acceptedAnswers
					: (part.acceptedAnswers != null ? [part.acceptedAnswers] : []);
				return this.normalizeAcceptedAnswers(raw);
			},
			normalizeAnswerKey(value) {
				return String(value ?? '')
					.trim()
					.replace(/\s+/g, '')
					.toLowerCase();
			},
			normalizeAcceptedAnswers(values) {
				if (!Array.isArray(values)) return [];
				const out = [];
				const seen = new Set();
				for (const item of values) {
					const txt = String(item ?? '').trim();
					if (!txt) continue;
					const key = this.normalizeAnswerKey(txt);
					if (!key || seen.has(key)) continue;
					seen.add(key);
					out.push(txt);
				}
				return out;
			},
			getAnswersWithId(partId, part) {
				if (!this.editingBlankState[partId]) {
					const answers = this.getAcceptedAnswers(part)
					this.editingBlankState[partId] = {
						inputValue: '',
						editingId: null,
						answersWithId: answers.map(v => ({ id: 'a' + Date.now() + '_' + Math.floor(Math.random() * 99999), value: v }))
					}
				}
				return this.editingBlankState[partId].answersWithId
			},
			setBlankInput(partId, value) {
				if (!this.editingBlankState[partId]) {
					this.editingBlankState[partId] = { inputValue: '', editingId: null, answersWithId: [] }
				}
				this.editingBlankState[partId].inputValue = value
			},
			selectAnswerForEdit(partId, answerId) {
				const state = this.editingBlankState[partId]
				if (!state) return
				const ans = state.answersWithId.find(a => a.id === answerId)
				if (!ans) return
				state.inputValue = ans.value
				state.editingId = answerId
			},
			commitBlankAnswer(partId, partIndex, part) {
				const state = this.editingBlankState[partId]
				const inputVal = String(state?.inputValue ?? '').trim()
				if (!inputVal) return
				if (state.editingId !== null) {
					const entry = state.answersWithId.find(a => a.id === state.editingId)
					if (entry) entry.value = inputVal
				} else {
					const isDupe = state.answersWithId.some(a => this.normalizeAnswerKey(a.value) === this.normalizeAnswerKey(inputVal))
					if (!isDupe) state.answersWithId.push({ id: 'a' + Date.now(), value: inputVal })
				}
				state.inputValue = ''
				state.editingId = null
				this.updatePart(partIndex, 'acceptedAnswers', state.answersWithId.map(a => a.value))
			},
			removeAcceptedAnswer(partId, partIndex, answerId) {
				const state = this.editingBlankState[partId]
				if (!state) return
				state.answersWithId = state.answersWithId.filter(a => a.id !== answerId)
				if (state.editingId === answerId) {
					state.inputValue = ''
					state.editingId = null
				}
				this.updatePart(partIndex, 'acceptedAnswers', state.answersWithId.map(a => a.value))
			},
			updatePart(partIndex, key, value) { const ng = JSON.parse(JSON.stringify(this.groups)); ng[this.item.groupIndex].questions[this.item.qIndex].config.parts[partIndex][key] = value; this.updateGroups(ng); },
			addPart(type) { const ng = JSON.parse(JSON.stringify(this.groups)); const parts = ng[this.item.groupIndex].questions[this.item.qIndex].config.parts; if (type === 'text') { parts.push({ type: 'text', value: ' ' }); } else { parts.push({ type: 'blank', id: `blank_${crypto.randomUUID()}`, acceptedAnswers: [] }); } this.updateGroups(ng); },
			removePart(partIndex) {
				const ng = JSON.parse(JSON.stringify(this.groups));
				const parts = ng[this.item.groupIndex].questions[this.item.qIndex].config.parts;
				const blankCount = parts.filter(p => p.type === 'blank').length;
				if (parts[partIndex].type === 'blank' && blankCount <= 1) return; // prevent removing last blank
				parts.splice(partIndex, 1);
				this.updateGroups(ng);
			},
			addPair() {
				const aId = crypto.randomUUID(); const bId = crypto.randomUUID();
				const newA = [...this.selectedQuestionData.config.columnA, { id: aId, text: '' }];
				const newB = [...this.selectedQuestionData.config.columnB, { id: bId, text: '' }];
				const newPairs = [...this.selectedQuestionData.config.correctPairs, { from: aId, to: bId }];
				this.selectedQuestionData.config = { ...this.selectedQuestionData.config, columnA: newA, columnB: newB, correctPairs: newPairs };
			},
			removePair(index) {
				if (this.selectedQuestionData.config.columnA.length > 1) {
					const removedAId = this.selectedQuestionData.config.columnA[index].id;
					const newA = [...this.selectedQuestionData.config.columnA]; newA.splice(index, 1);
					const newB = [...this.selectedQuestionData.config.columnB]; newB.splice(index, 1);
					const newPairs = this.selectedQuestionData.config.correctPairs.filter(p => p.from !== removedAId);
					this.selectedQuestionData.config = { ...this.selectedQuestionData.config, columnA: newA, columnB: newB, correctPairs: newPairs };
				}
			},
			updateShuffleQuestions(id, val) {
				this.groups[this.item.groupIndex].advancedFeatures.isShuffleQuestions = val
				this.$emit('update:groups', this.groups);
			},
			updateShuffleAnswers(id, val) {
				this.groups[this.item.groupIndex].advancedFeatures.isShuffleAnswers = val
				this.$emit('update:groups', this.groups);
			},
			onOpenModalImportFromHocLieu() {
				this.isShowModalImportFromHocLieu = true
			},
			onOpenModalImportFromBank() {
				this.isShowModalImportFromBank = true
			},
			bindingImport(val) {
				const cloned = JSON.parse(JSON.stringify(val))
				cloned.id = `q_${crypto.randomUUID()}`
				// Correct ordinalNumber based on actual total question count across all groups
				const totalQuestions = this.groups.reduce((sum, g) => sum + (g.questions?.length || 0), 0)
				cloned.ordinalNumber = totalQuestions + 1
				this.groups[this.item.groupIndex].questions = [...this.groups[this.item.groupIndex].questions, cloned]
			},
			onOpenModalKiNang() {
				this.isShowModalSkill = true
			},
			handleSubmitSkill(val) {
				let SkillsNotDuplicate = val.filter(i => !this.selectedQuestionData.skills.map(e => e.KyNang_MonHoc_ChiTietID).includes(i.KyNang_MonHoc_ChiTietID))
				this.selectedQuestionData.skills = [...this.selectedQuestionData.skills, ...SkillsNotDuplicate]
				val.forEach(i => {
					this.skills.set(i.KyNang_MonHoc_ChiTietID, i.TenKyNang)
				})
			},
			removeChip(index) {
				this.groups[this.item.groupIndex]?.questions[this.item.qIndex].skills.splice(index, 1)
				this.$emit('update:groups', this.groups);
			},
			getSkillLabel(skill) {
				return this.skills.get(skill.KyNang_MonHoc_ChiTietID) || skill.TenKyNang;
			}
		}
	}
</script>