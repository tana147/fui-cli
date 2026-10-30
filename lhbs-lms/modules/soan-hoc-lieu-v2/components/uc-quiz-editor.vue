<template>
	<div v-if="editableData" class="quiz-editor-container v-col-12">
		<!-- ==================== 1. QUIZ_SINGLE_CHOICE ==================== -->
		<div v-if="loaiNoiDung === 'QUIZ_SINGLE_CHOICE'">
			<!-- <v-textarea label="Câu hỏi/Yêu cầu" v-model="editableData.prompt" variant="outlined" rows="2" auto-grow>
			</v-textarea> -->
			<uc-rich-text-editor label="Câu hỏi/Yêu cầu" v-model="editableData.prompt"
				:imageapi="vueData.v_Set.apiFile" variant="outlined" rows="2" auto-grow />
			<div class="d-flex align-center justify-space-between form-label mt-4">
				<label>Các lựa chọn và đáp án đúng:</label>
				<v-checkbox v-model="editableData.isAdvanced" label="Soạn đáp án nâng cao" />
			</div>
			<v-radio-group v-model="editableData.correctAnswer">
				<v-row v-for="(option, index) in editableData.options" :key="index" align="center" class="mb-1">
					<v-col cols="1" class="d-flex align-center">
						<v-radio :value="option.id" hide-details />
					</v-col>
					<v-col cols="10">
						<v-text-field v-if="!editableData.isAdvanced" v-model="option.text" density="compact"
							variant="outlined" hide-details />
						<!-- <uc-editor-dialog v-else v-model:text="option.text" /> -->
						<uc-latex-edit v-else v-model:content="option.text" :isEditable="true" />
					</v-col>
					<v-col cols="1" class="d-flex justify-center">
						<v-btn v-if="editableData.options.length > 2" icon="mdi-delete-outline" variant="text" size="small"
							color="red" @click="removeOption('options', index)" />
					</v-col>
				</v-row>
			</v-radio-group>
			<v-btn prepend-icon="mdi-plus" variant="text" color="primary" @click="addOption('options')">Thêm lựa
				chọn
			</v-btn>
			<v-textarea class="mt-6" label="Giải thích (Tùy chọn)" v-model="editableData.explanation" variant="outlined"
				rows="2" auto-grow></v-textarea>
		</div>

		<!-- ==================== 2. QUIZ_MULTIPLE_CHOICE ==================== -->
		<div v-else-if="loaiNoiDung === 'QUIZ_MULTIPLE_CHOICE'">
			<!-- <v-textarea label="Câu hỏi/Yêu cầu" v-model="editableData.prompt" variant="outlined" rows="2" auto-grow>
			</v-textarea> -->
			<uc-rich-text-editor label="Câu hỏi/Yêu cầu" v-model="editableData.prompt"
				:imageapi="vueData.v_Set.apiFile" variant="outlined" rows="2" auto-grow />

			<div class="d-flex align-center justify-space-between form-label mt-4">
				<label class="form-label mt-4">Các lựa chọn (chọn các đáp án đúng):</label>
				<v-checkbox v-model="editableData.isAdvanced" label="Soạn đáp án nâng cao" />
			</div>
			<v-row v-for="(option, index) in editableData.options" :key="index" align="center" class="mb-1">
				<v-col cols="1" class="d-flex align-center">
					<v-checkbox v-model="editableData.correctAnswers" :value="option.id" hide-details />
				</v-col>
				<v-col cols="10">
					<v-text-field v-if="!editableData.isAdvanced" v-model="option.text" density="compact" variant="outlined"
						hide-details />
					<uc-editor-dialog v-else v-model:text="option.text" />
				</v-col>
				<v-col cols="1" class="d-flex justify-center">
					<v-btn v-if="editableData.options.length > 2" icon="mdi-delete-outline" variant="text" size="small"
						color="red" @click="removeOption('options', index)" />
				</v-col>
			</v-row>
			<v-btn prepend-icon="mdi-plus" variant="text" color="primary" @click="addOption('options')">Thêm lựa chọn
			</v-btn>
			<v-textarea class="mt-6" label="Giải thích (Tùy chọn)" v-model="editableData.explanation" variant="outlined"
				rows="2" auto-grow></v-textarea>
		</div>

		<!-- ==================== 3. QUIZ_MATCHING ==================== -->
		<div v-else-if="loaiNoiDung === 'QUIZ_MATCHING'">
			<!-- <v-textarea label="Câu hỏi/Yêu cầu" v-model="editableData.prompt" variant="outlined" rows="2" auto-grow>
			</v-textarea> -->
			<uc-rich-text-editor label="Câu hỏi/Yêu cầu" v-model="editableData.prompt"
				:imageapi="vueData.v_Set.apiFile" variant="outlined" rows="2" auto-grow />
			<div>
				<v-checkbox v-model="editableData.isAdvanced" label="Soạn đáp án nâng cao" />
			</div>
			<v-row>
				<v-col><label class="form-label">Cột A</label></v-col>
				<v-col><label class="form-label">Cột B (tương ứng)</label></v-col>
			</v-row>
			<v-row v-for="(pair, index) in editableData.columnA" :key="index" class="mb-n5">
				<v-col>
					<v-text-field v-if="!editableData.isAdvanced" v-model="pair.text" density="compact"
						variant="outlined" hide-details />
					<uc-editor-dialog v-else v-model:text="pair.text" />
				</v-col>
				<v-col class="d-flex align-center">
					<v-text-field v-if="!editableData.isAdvanced" v-model="editableData.columnB[index].text"
						density="compact" variant="outlined" hide-details />
					<uc-editor-dialog v-else v-model:text="editableData.columnB[index].text" />
					<v-btn icon="mdi-delete-outline" variant="text" size="small" color="red"
						@click="removePair(index)" />
				</v-col>
			</v-row>
			<v-btn prepend-icon="mdi-plus" variant="text" color="primary" @click="addPair" class="mt-4">Thêm cặp</v-btn>
		</div>

		<!-- ==================== 4. QUIZ_ORDERING ==================== -->
		<div v-else-if="loaiNoiDung === 'QUIZ_ORDERING'">
			<!-- <v-textarea label="Câu hỏi/Yêu cầu" v-model="editableData.prompt" variant="outlined" rows="2" auto-grow>
			</v-textarea> -->
			<uc-rich-text-editor label="Câu hỏi/Yêu cầu" v-model="editableData.prompt"
				:imageapi="vueData.v_Set.apiFile" variant="outlined" rows="2" auto-grow />
			<div class="d-flex align-center justify-space-between form-label mt-4">
				<label class="form-label mt-4">Các mục (nhập theo thứ tự đúng):</label>
				<v-checkbox v-model="editableData.isAdvanced" label="Soạn đáp án nâng cao" />
			</div>

			<div v-for="(item, index) in editableData.items" :key="index" class="d-flex align-center mb-2">
				<span class="mr-2 font-weight-bold">{{ index + 1 }}.</span>
				<v-text-field v-if="!editableData.isAdvanced" v-model="item.text" density="compact" variant="outlined"
					hide-details></v-text-field>
				<uc-editor-dialog v-else v-model:text="item.text" />
				<v-btn icon="mdi-delete-outline" variant="text" size="small" color="red"
					@click="removeOption('items', index)"></v-btn>
			</div>
			<v-btn prepend-icon="mdi-plus" variant="text" color="primary" @click="addOption('items')">Thêm mục</v-btn>
		</div>

		<!-- ==================== 5. QUIZ_DRAG_DROP_CATEGORIZE ==================== -->
		<div v-else-if="loaiNoiDung === 'QUIZ_DRAG_DROP_CATEGORIZE'">
			<!-- <v-textarea label="Câu hỏi/Yêu cầu" v-model="editableData.prompt" variant="outlined" rows="2" auto-grow>
			</v-textarea> -->
			<uc-rich-text-editor label="Câu hỏi/Yêu cầu" v-model="editableData.prompt"
				:imageapi="vueData.v_Set.apiFile" variant="outlined" rows="2" auto-grow />
			<label class="form-label mt-4">Các nhóm:</label>
			<div v-for="(cat, index) in editableData.categories" :key="index" class="d-flex align-center mb-2">
				<v-text-field v-model="cat.name" density="compact" variant="outlined" hide-details
					:placeholder="'Tên nhóm ' + (index + 1)"></v-text-field>
				<v-btn icon="mdi-delete-outline" variant="text" size="small" color="red"
					@click="removeOption('categories', index)"></v-btn>
			</div>
			<v-btn prepend-icon="mdi-plus" variant="text" color="primary" @click="addOption('categories')">Thêm nhóm
			</v-btn>

			<label class="form-label mt-6">Các mục cần phân loại:</label>
			<div v-for="(item, index) in editableData.items" :key="index" class="d-flex align-center mb-2">
				<v-text-field v-model="item.text" density="compact" variant="outlined" hide-details class="mr-2"
					:placeholder="'Nội dung mục ' + (index + 1)"></v-text-field>
				<v-select v-model="item.categoryId" :items="editableData.categories" item-title="name" item-value="id"
					label="Thuộc nhóm" density="compact" variant="outlined" hide-details style="max-width: 200px;">
				</v-select>
				<v-btn icon="mdi-delete-outline" variant="text" size="small" color="red"
					@click="removeOption('items', index)"></v-btn>
			</div>
			<v-btn prepend-icon="mdi-plus" variant="text" color="primary" @click="addOption('items')">Thêm mục</v-btn>
		</div>

		<!-- ==================== 6. QUIZ_FILL_IN_BLANK ==================== -->
		<div v-else-if="loaiNoiDung === 'QUIZ_FILL_IN_BLANK'">
			<uc-rich-text-editor v-model="editableData.prompt" :imageapi="vueData.v_Set.apiFile" />
			<!-- <v-textarea label="Hướng dẫn" v-model="editableData.prompt" variant="outlined" rows="2" auto-grow>
			</v-textarea> -->
			<label class="form-label mt-4">Nội dung câu (thêm các phần text và chỗ trống):</label>
			<div v-for="(part, index) in editableData.parts" :key="index" class="d-flex align-center mb-2">
				<v-chip class="mr-2">{{ part.type === 'text' ? 'Văn bản' : 'Ô trống' }}</v-chip>
				<v-text-field v-if="part.type === 'text'" v-model="part.value" density="compact" variant="outlined"
					hide-details placeholder="Nhập văn bản..."></v-text-field>
				<v-text-field v-else v-model="part.correctAnswer" density="compact" variant="outlined" hide-details
					placeholder="Nhập đáp án đúng..."></v-text-field>
				<v-btn icon="mdi-delete-outline" variant="text" size="small" color="red"
					@click="removeOption('parts', index)"></v-btn>
			</div>
			<v-btn prepend-icon="mdi-plus" variant="text" color="blue" @click="addPart('text')">Thêm Text</v-btn>
			<v-btn prepend-icon="mdi-plus" variant="text" color="green" @click="addPart('blank')">Thêm Ô trống</v-btn>
		</div>
		<!-- ==================== 7. Soạn thảo: Nối nhóm (QUIZ_CONNECTION) ==================== -->
		<div v-else-if="loaiNoiDung === 'QUIZ_CONNECTION'">
			<uc-rich-text-editor v-model="editableData.prompt" :imageapi="vueData.v_Set.apiFile" />
			<!-- <v-textarea label="Câu hỏi/Yêu cầu" v-model="editableData.prompt" variant="outlined" rows="2" auto-grow>
			</v-textarea> -->
			<label class="form-label mt-4">Các nhóm:</label>
			<div v-for="(group, index) in editableData.groups" :key="index" class="d-flex align-center mb-2">
				<v-text-field v-model="group.text" density="compact" variant="outlined" hide-details
					:placeholder="'Tên nhóm ' + (index + 1)"></v-text-field>
				<v-btn v-if="editableData.groups.length > 1" icon="mdi-delete-outline" variant="text" size="small"
					color="red" @click="removeOption('groups', index)"></v-btn>
			</div>
			<v-btn prepend-icon="mdi-plus" variant="text" color="primary" @click="addOption('groups')">Thêm nhóm</v-btn>

			<label class="form-label mt-6">Các mục cần nối:</label>
			<div v-for="(item, index) in editableData.items" :key="index" class="d-flex align-center mb-2">
				<v-text-field v-model="item.text" density="compact" variant="outlined" hide-details class="mr-2"
					:placeholder="'Nội dung mục ' + (index + 1)"></v-text-field>
				<v-select v-model="item.groupId" :items="editableData.groups" item-title="text" item-value="id"
					label="Thuộc nhóm" density="compact" variant="outlined" hide-details style="max-width: 200px;">
				</v-select>
				<v-btn icon="mdi-delete-outline" variant="text" size="small" color="red"
					@click="removeOption('items', index)">
				</v-btn>
			</div>
			<v-btn prepend-icon="mdi-plus" variant="text" color="primary" @click="addOption('items')">Thêm mục</v-btn>
		</div>
		<!-- ==================== 8. SHORT_ANSWER / ESSAY ==================== -->
		<div v-else-if="['SHORT_ANSWER', 'ESSAY'].includes(loaiNoiDung)">
			<div class="mb-4">
				<div class="text-subtitle-2 font-weight-bold text-primary mb-1 d-flex align-center ga-1">
					<v-icon size="small" color="primary">mdi-help-circle-outline</v-icon>
					<span>Câu hỏi / Yêu cầu tự luận <span class="text-error">*</span></span>
				</div>
				<div class="text-caption text-grey-darken-1 mb-2">Nhập nội dung câu hỏi hoặc yêu cầu bài làm tự luận cho học sinh:</div>
				<uc-rich-text-editor v-model="editableData.prompt"
					:imageapi="vueData.v_Set.apiFile" variant="outlined" rows="3" auto-grow />
			</div>

			<div class="mt-4">
				<div class="text-subtitle-2 font-weight-bold text-amber-darken-3 mb-1 d-flex align-center ga-1">
					<v-icon size="small" color="amber-darken-3">mdi-lightbulb-outline</v-icon>
					<span>Đáp án tham khảo / Gợi ý chấm <span class="text-caption font-weight-regular text-grey">(Không bắt buộc)</span></span>
				</div>
				<v-alert density="compact" type="info" variant="tonal" class="mb-2 text-caption">
					Nội dung này <strong>chỉ giáo viên nhìn thấy</strong> để làm căn cứ chấm điểm, học sinh sẽ <strong>không</strong> thấy nội dung này.
				</v-alert>
				<uc-rich-text-editor
					v-model="editableData.referenceAnswer" :imageapi="vueData.v_Set.apiFile"
					variant="outlined" rows="4" auto-grow />
			</div>
		</div>
		<!-- ==================== Soạn thảo: QUIZ_COMPOSITE (Bài kiểm tra / Bài thi) ==================== -->
		<div v-else-if="loaiNoiDung === 'QUIZ_COMPOSITE'" class="quiz-composite-wrap">
			<!-- 1. THIẾT LẬP CHUNG NHÓM CÂU HỎI -->
			<v-card class="composite-section-card mb-4" variant="outlined">
				<div class="card-header-bar d-flex justify-space-between align-center px-4 py-3 flex-wrap ga-2">
					<span class="font-weight-bold text-subtitle-1 text-primary">Thiết lập chung nhóm câu hỏi</span>
					<!-- Switch chế độ nhóm đơn giản, không icon, không chip -->
					<v-switch v-model="editableData.hasGroups" @update:modelValue="onToggleGroupMode" color="primary"
						density="compact" hide-details label="Chế độ nhóm câu hỏi" />
				</div>

				<v-divider />

				<v-card-text class="pa-4">
					<v-row dense>
						<v-col cols="12">
							<v-text-field label="Tiêu đề nhóm câu hỏi" v-model="editableData.title" density="compact"
								variant="outlined" placeholder="Nhập tiêu đề nhóm câu hỏi..." hide-details="auto" />
						</v-col>
					</v-row>

					<!-- Thống kê nhóm câu hỏi thiết kế rõ ràng, dễ nhìn -->
					<div class="composite-stats-bar mt-3 px-4 py-2 rounded-lg d-flex align-center justify-space-between flex-wrap ga-3">
						<div class="text-caption font-weight-bold text-grey-darken-2">
							Thống kê nhóm câu hỏi:
						</div>
						<div class="d-flex align-center flex-wrap ga-4">
							<div class="stat-item d-flex align-center ga-1">
								<span class="text-caption text-grey-darken-1">Số câu hỏi:</span>
								<span class="font-weight-bold text-primary text-body-2">{{ totalQuestionsCount }}</span>
							</div>
							<v-divider vertical class="my-1" />
							<div class="stat-item d-flex align-center ga-1">
								<span class="text-caption text-grey-darken-1">Tổng điểm:</span>
								<span class="font-weight-bold text-amber-darken-4 text-body-2">{{ totalPointsCalculated }}</span>
							</div>
							<template v-if="editableData.hasGroups">
								<v-divider vertical class="my-1" />
								<div class="stat-item d-flex align-center ga-1">
									<span class="text-caption text-grey-darken-1">Số phần/nhóm:</span>
									<span class="font-weight-bold text-teal-darken-2 text-body-2">{{ editableData.groups?.length || 0 }}</span>
								</div>
							</template>
						</div>
					</div>
				</v-card-text>
			</v-card>

			<!-- 2. QUẢN LÝ NHÓM CÂU HỎI (KHI BẬT hasGroups) -->
			<v-card v-if="editableData.hasGroups" class="composite-section-card mb-4" variant="outlined">
				<div class="card-header-bar d-flex justify-space-between align-center px-4 py-3 flex-wrap ga-2">
					<span class="font-weight-bold text-subtitle-1 text-teal-darken-2">Quản lý nhóm câu hỏi</span>
					<v-btn color="teal" prepend-icon="mdi-plus" size="small" variant="tonal" @click="addGroup">
						Thêm nhóm
					</v-btn>
				</div>

				<v-divider />

				<v-card-text class="pa-4">
					<!-- Tabs Nhóm câu hỏi -->
					<div class="group-tabs-container mb-3" v-if="editableData.groups && editableData.groups.length > 0">
						<v-tabs v-model="activeGroupIndex" density="compact" color="teal" class="custom-group-tabs" show-arrows>
							<v-tab v-for="(group, index) in editableData.groups" :key="group.id" :value="index" class="group-pill-tab text-none">
								<span class="group-tab-title">{{ group.title || ('Phần ' + (index + 1)) }}</span>
								<v-chip size="x-small" :color="group.questions?.length > 0 ? 'teal' : 'grey'" variant="flat" class="ml-2 px-1 text-white font-weight-bold">
									{{ group.questions?.length || 0 }}
								</v-chip>
								<v-btn v-if="editableData.groups.length > 1" icon="mdi-close" size="x-small" variant="text"
									color="grey-darken-1" class="ml-1 tab-close-btn" @click.stop="removeGroup(index)">
								</v-btn>
							</v-tab>
						</v-tabs>
					</div>

					<!-- Thiết lập nhóm đang chọn (không icon trong input) -->
					<v-window v-model="activeGroupIndex" v-if="editableData.groups && editableData.groups.length > 0">
						<v-window-item v-for="(group, index) in editableData.groups" :key="group.id" :value="index">
							<div class="active-group-settings pa-3 rounded-lg">
								<v-row dense>
									<v-col cols="12" md="6">
										<v-text-field v-model="group.title" label="Tên nhóm" variant="outlined"
											density="compact" placeholder="Ví dụ: Phần 1: Đại số..." hide-details="auto" />
									</v-col>
									<v-col cols="6" md="3">
										<v-text-field v-model.number="group.timeLimit" label="Thời gian (phút)"
											type="number" variant="outlined" density="compact" clearable suffix="phút"
											placeholder="Trống = tự do" hide-details="auto" />
									</v-col>
									<v-col cols="6" md="3">
										<v-text-field :model-value="group.points || 0" label="Tổng điểm nhóm"
											variant="outlined" density="compact" readonly suffix="điểm"
											class="bg-grey-lighten-4 rounded" hide-details="auto" />
									</v-col>
									<v-col cols="12" md="6">
										<v-textarea v-model="group.description" label="Mô tả nhóm" variant="outlined"
											density="compact" rows="2" placeholder="Nhập mô tả tóm tắt cho nhóm câu hỏi này..."
											hide-details="auto" />
									</v-col>
									<v-col cols="12" md="6">
										<v-textarea v-model="group.instruction" label="Hướng dẫn làm bài" variant="outlined"
											density="compact" rows="2" placeholder="Nhập hướng dẫn làm bài cho học sinh..."
											hide-details="auto" />
									</v-col>
								</v-row>
							</div>
						</v-window-item>
					</v-window>
				</v-card-text>
			</v-card>

			<!-- 3. KHU VỰC DANH SÁCH & THÊM CÂU HỎI (GOM THÀNH 1 CỤM LIỀN MẠCH) -->
			<v-card class="composite-section-card" variant="outlined">
				<!-- Header gom tất cả thao tác: Tiêu đề + Chọn loại câu hỏi + Thêm câu hỏi + Import -->
				<div class="card-header-bar px-4 py-3">
					<div class="d-flex justify-space-between align-center flex-wrap ga-2">
						<div class="d-flex align-center ga-2">
							<span class="font-weight-bold text-subtitle-1 text-indigo-darken-2">
								{{ editableData.hasGroups ? ('Câu hỏi trong ' + (currentGroup?.title || 'nhóm')) : 'Danh sách câu hỏi' }}
							</span>
							<v-chip size="x-small" color="indigo" variant="flat" class="font-weight-bold">
								{{ currentQuestionsList.length }} câu
							</v-chip>
						</div>

						<!-- Cụm thêm & import câu hỏi gom gọn trên header -->
						<div class="d-flex align-center flex-wrap ga-2">
							<div style="min-width: 200px; max-width: 260px;">
								<v-select :items="quizTypesForComposite" item-title="title" item-value="value"
									v-model="nextQuizType" density="compact" variant="outlined" hide-details />
							</div>
							<v-btn prepend-icon="mdi-plus" color="primary" variant="flat" size="small" @click="addQuestion"
								:disabled="editableData.hasGroups && !currentGroup">
								Thêm câu hỏi
							</v-btn>
							<v-btn color="success" variant="tonal" size="small" prepend-icon="mdi-file-upload-outline"
								class="font-weight-bold text-none" :loading="isConvertingFile" @click="openQuestionFilePicker"
								:disabled="editableData.hasGroups && !currentGroup">
								Import file
							</v-btn>
							<input ref="questionFileInput" type="file" accept=".doc,.docx,.pdf,.txt,.html,.htm" class="d-none"
								@change="convertQuestionFile" />
						</div>
					</div>

					<!-- Quick Add Chips gom ngay dưới header -->
					<div class="quick-add-chips mt-2 d-flex align-center flex-wrap ga-1">
						<span class="text-caption text-grey-darken-1 mr-1">Thêm nhanh:</span>
						<v-chip v-for="qt in quickQuizShortcuts" :key="qt.value" size="x-small" variant="tonal"
							color="primary" class="cursor-pointer" @click="quickAddQuestion(qt.value)"
							:disabled="editableData.hasGroups && !currentGroup">
							+ {{ qt.title }}
						</v-chip>
					</div>
				</div>

				<v-divider />

				<v-card-text class="pa-4">
					<!-- Danh sách câu hỏi dạng Expansion Panels -->
					<v-expansion-panels v-if="currentQuestionsList && currentQuestionsList.length > 0" v-model="panel"
						class="custom-question-panels ga-2">
						<v-expansion-panel v-for="(question, index) in currentQuestionsList" :key="question.id"
							class="question-panel-item rounded-lg mb-2">
							<v-expansion-panel-title class="py-2 px-3">
								<div class="d-flex justify-space-between align-center w-100 pr-2">
									<div class="d-flex align-center ga-2 text-truncate">
										<v-chip size="small" color="primary" variant="flat" class="font-weight-bold">
											Câu {{ index + 1 }}
										</v-chip>
										<v-chip size="small" color="blue-grey-lighten-4" variant="flat"
											class="text-blue-grey-darken-3 font-weight-medium">
											{{ getQuizTypeName(question.type) }}
										</v-chip>
										<v-chip size="small" color="amber-lighten-4" variant="flat"
											class="text-amber-darken-4 font-weight-bold">
											⭐ {{ question.points || 1 }} điểm
										</v-chip>
									</div>

									<div class="d-flex align-center ga-1" @click.stop>
										<v-btn icon="mdi-arrow-up" size="x-small" variant="tonal" color="grey-darken-1"
											:disabled="index === 0" @click="moveQuestion(index, index - 1)" title="Chuyển lên" />
										<v-btn icon="mdi-arrow-down" size="x-small" variant="tonal" color="grey-darken-1"
											:disabled="index === currentQuestionsList.length - 1"
											@click="moveQuestion(index, index + 1)" title="Chuyển xuống" />
										<v-btn icon="mdi-trash-can-outline" size="x-small" variant="tonal" color="error"
											@click="removeQuestion(index)" title="Xoá câu hỏi" />
									</div>
								</div>
							</v-expansion-panel-title>

							<v-expansion-panel-text class="pa-3 border-t">
								<!-- Question Points & Type Settings Bar (không icon) -->
								<div class="question-config-bar mb-3 pa-3 rounded-lg">
									<v-row dense align="center">
										<v-col cols="12" sm="4">
											<v-text-field v-model.number="question.points" label="Điểm số câu hỏi"
												type="number" min="0.25" step="0.25" variant="outlined" density="compact"
												suffix="điểm" hide-details="auto" @update:model-value="updateGroupPoints()" />
										</v-col>
										<v-col cols="12" sm="8">
											<v-select v-model="question.type" :items="quizTypesForComposite"
												item-title="title" item-value="value" label="Loại câu hỏi"
												variant="outlined" density="compact" hide-details="auto"
												@update:model-value="question.content = ensureDataStructure(question.type, {})" />
										</v-col>
									</v-row>
								</div>

								<div class="nested-question-editor-box">
									<uc-quiz-editor :loai-noi-dung="question.type" v-model="question.content"
										class="question-editor" />
								</div>
							</v-expansion-panel-text>
						</v-expansion-panel>
					</v-expansion-panels>

					<!-- Empty State gọn nhẹ -->
					<div v-else class="empty-questions-box pa-6 text-center rounded-lg my-1">
						<div class="text-subtitle-2 font-weight-medium text-grey-darken-2 mb-1">Chưa có câu hỏi nào</div>
						<div class="text-caption text-grey-darken-1 mb-3">
							Hãy bấm nút <strong>"Thêm câu hỏi"</strong> hoặc chọn mục thêm nhanh ở trên để bắt đầu soạn bài
						</div>
					</div>
				</v-card-text>
			</v-card>
		</div>
		<!-- ====================  QUIZ_TRUE_FALSE ==================== -->
		<div v-else-if="loaiNoiDung === 'QUIZ_TRUE_FALSE'">
			<!-- <v-textarea label="Câu hỏi/Yêu cầu" v-model="editableData.prompt" variant="outlined" rows="2" auto-grow>
			</v-textarea> -->
			<uc-rich-text-editor label="Câu hỏi/Yêu cầu" v-model="editableData.prompt"
				:imageapi="vueData.v_Set.apiFile" variant="outlined" rows="2" auto-grow />
			<div class="d-flex align-center justify-space-between form-label mt-4">
				<label>Các lựa chọn và đáp án đúng:</label>
				<v-checkbox v-model="editableData.isAdvanced" label="Soạn đáp án nâng cao" />
			</div>
			<div>

				<v-row v-for="(option, index) in editableData.options" :key="index" align="center" class="mb-1">
					<v-col cols="4" class="d-flex align-center ga-2">
						<v-checkbox v-model="option.correctAnswer" color="primary" label="Đúng"
							@update:modelValue="(val) => {if(val) option.inCorrectAnswer = false}" />
						<v-checkbox v-model="option.inCorrectAnswer" color="red" label="Sai"
							@update:modelValue="(val) => {if(val) option.correctAnswer = false}" />
					</v-col>
					<!-- <v-checkbox v-model="editableData.correctAnswers" :value="option.id" hide-details class="mr-2">
									</v-checkbox> -->
					<v-col cols="7">
						<v-text-field v-if="!editableData.isAdvanced" v-model="option.text" density="compact"
							variant="outlined" hide-details :clearable="false" />
						<uc-latex-edit v-else v-model:content="option.text" :isEditable="true" />
					</v-col>
					<v-col cols="1" class="d-flex justify-center">
						<v-btn v-if="editableData.options.length > 2" icon="mdi-delete-outline" variant="text"
							size="small" color="red" @click="removeOption('options', index)" />
					</v-col>
				</v-row>
			</div>
			<v-btn prepend-icon="mdi-plus" variant="text" color="primary" @click="addOption('options')">Thêm lựa
				chọn
			</v-btn>
			<v-textarea class="mt-6" label="Giải thích (Tùy chọn)" v-model="editableData.explanation" variant="outlined"
				rows="2" auto-grow></v-textarea>
		</div>

		<!-- ... và các loại khác ... -->
		<div v-else>
			<p class="text-grey">Không có trình soạn thảo chuyên dụng cho loại <strong>{{ loaiNoiDung }}</strong>.</p>
		</div>
	</div>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
		props: {
			loaiNoiDung: {
				type: String,
			},
			modelValue: { type: Object, default: () => ({}) }
		},
		emits: ['update:modelValue'],
		data() {
			return {
				vueData,
				editableData: {},
				panel: 0,
				nextQuizType: 'QUIZ_SINGLE_CHOICE',
				quizTypesForComposite: [
					{ value: 'QUIZ_SINGLE_CHOICE', title: 'Trắc nghiệm đơn' },
					{ value: 'QUIZ_MULTIPLE_CHOICE', title: 'Trắc nghiệm đa lựa chọn' },
					{ value: 'QUIZ_MATCHING', title: 'Ghép cặp' },
					{ value: 'QUIZ_ORDERING', title: 'Sắp xếp thứ tự' },
					{ value: 'QUIZ_DRAG_DROP_CATEGORIZE', title: 'Kéo thả phân loại' },
					{ value: 'QUIZ_FILL_IN_BLANK', title: 'Điền từ' },
					{ value: 'QUIZ_CONNECTION', title: 'Nối nhóm' },
					{ value: 'QUIZ_TRUE_FALSE', title: 'Đúng sai' },
					{ value: 'SHORT_ANSWER', title: 'Trả lời ngắn' },
					{ value: 'ESSAY', title: 'Tự luận' },
				],
				quickQuizShortcuts: [
					{ value: 'QUIZ_SINGLE_CHOICE', title: 'Trắc nghiệm đơn' },
					{ value: 'QUIZ_MULTIPLE_CHOICE', title: 'Đa lựa chọn' },
					{ value: 'QUIZ_TRUE_FALSE', title: 'Đúng / Sai' },
					{ value: 'QUIZ_MATCHING', title: 'Ghép cặp' },
					{ value: 'QUIZ_FILL_IN_BLANK', title: 'Điền từ' },
					{ value: 'SHORT_ANSWER', title: 'Trả lời ngắn' },
					{ value: 'ESSAY', title: 'Tự luận' }
				],
				isAdvanced: false,
				isOpenDialogImport_QUIZ_COMPOSITE: false,
				isConvertingFile: false,

				// Thêm cho Groups mode
				activeGroupIndex: 0
			}
		},
		computed: {
			currentGroup() {
				return this.editableData.hasGroups && this.editableData.groups?.length > 0
					? this.editableData.groups[this.activeGroupIndex]
					: null;
			},

			currentQuestionsList() {
				if (this.editableData.hasGroups && this.currentGroup) {
					return this.currentGroup.questions || [];
				}
				return this.editableData.questions || [];
			},

			totalQuestionsCount() {
				if (this.editableData.hasGroups && this.editableData.groups) {
					return this.editableData.groups.reduce((sum, group) => sum + (group.questions?.length || 0), 0);
				}
				return this.editableData.questions?.length || 0;
			},

			totalPointsCalculated() {
				if (this.editableData.hasGroups && this.editableData.groups) {
					return this.editableData.groups.reduce((sum, group) => sum + (group.points || 0), 0);
				}
				return this.editableData.questions?.reduce((sum, q) => sum + (q.points || 1), 0) || 0;
			}
		},
		watch: {
			// KÊNH NHẬN DỮ LIỆU TỪ CHA
			modelValue: {
				handler(newData) {
					// Chỉ cập nhật state nội bộ nếu dữ liệu từ cha thực sự khác
					// với dữ liệu hiện tại. Điều này phá vỡ vòng lặp.
					if (JSON.stringify(newData) !== JSON.stringify(this.editableData)) {
						console.log('ensure...')
						this.editableData = this.ensureDataStructure(this.loaiNoiDung, newData);
					}
				},
				immediate: true,
				deep: true
			},
			// KÊNH GỬI DỮ LIỆU LÊN CHA
			editableData: {
				handler(newData) {
					let _editableData = newData// 
					const keys = Object.keys(newData)

					const isOnlyKeyPrompt = Object.keys(newData).length === 1 && keys.includes('prompt')
					if (isOnlyKeyPrompt) _editableData = this.ensureDataStructure(this.loaiNoiDung, {});
					// Khi state nội bộ thay đổi, emit sự kiện lên cho cha
					this.$emit('update:modelValue', _editableData);
				},
				deep: true
			},
			loaiNoiDung: {
				handler: function (newType) {
					console.log('loai noi dung...', newType)
					// if (newType) {
					this.editableData = this.ensureDataStructure(newType, {});
					// }
				},
				deep: true
			}
		},
		methods: {
			notify(message, color = 'success') {
				this.snackbarRef?.value?.showSnackbar?.({ message, color });
			},

			ensureDataStructure(type, data) {
				return window.QuizHelpers ? window.QuizHelpers.ensureDataStructure(type, data) : data;
			},

			// SỬA: Logic thêm/xóa
			addOption(key) {
				const currentArray = this.editableData[key] || [];
				const newId = key === 'options' ? String.fromCharCode(97 + currentArray.length) : `item_${Date.now()}`;
				const newArray = [...currentArray, { id: newId, text: '' }];
				// this.editableData[key] = newArray
				// console.log('before', this.editableData)
				this.$nextTick(() => {
					this.editableData = { ...this.editableData, [key]: [...newArray] };
					console.log('options', key, this.editableData, this.panel)
				})
			},
			removeOption(key, index) {
				if (this.editableData[key] && this.editableData[key].length > 1) {
					const newArray = [...this.editableData[key]];
					newArray.splice(index, 1);
					this.editableData = { ...this.editableData, [key]: newArray };
				}
			},
			addPair() {
				const newIndex = Date.now();
				const aId = `a${newIndex}`; const bId = `b${newIndex}`;
				const newA = [...this.editableData.columnA, { id: aId, text: '' }];
				const newB = [...this.editableData.columnB, { id: bId, text: '' }];
				const newPairs = [...this.editableData.correctPairs, { from: aId, to: bId }];
				this.editableData = { ...this.editableData, columnA: newA, columnB: newB, correctPairs: newPairs };
			},
			removePair(index) {
				if (this.editableData.columnA.length > 1) {
					const newA = [...this.editableData.columnA]; newA.splice(index, 1);
					const newB = [...this.editableData.columnB]; newB.splice(index, 1);
					const newPairs = [...this.editableData.correctPairs]; newPairs.splice(index, 1);
					this.editableData = { ...this.editableData, columnA: newA, columnB: newB, correctPairs: newPairs };
				}
			},
			addPart(type) {
				const newId = `blank_${Date.now()}`;
				const newPart = type === 'text' ? { type: 'text', value: '' } : { type: 'blank', id: newId, correctAnswer: '', size: 10 };
				const newParts = [...(this.editableData.parts || []), newPart];
				this.editableData = { ...this.editableData, parts: newParts };
			},

			// Thêm methods mới cho Groups
			onToggleGroupMode(hasGroups) {
				const isGroupMode = typeof hasGroups === 'boolean' ? hasGroups : Boolean(this.editableData.hasGroups);
				this.editableData.hasGroups = isGroupMode;

				if (isGroupMode) {
					// BẬT CHẾ ĐỘ NHÓM: Lấy toàn bộ câu hỏi flat hiện có (kể cả vừa import) gom vào nhóm
					const existingQuestions = Array.isArray(this.editableData.questions) ? [...this.editableData.questions] : [];

					if (this.editableData.groups && this.editableData.groups.length > 0) {
						if (existingQuestions.length > 0) {
							const targetGroup = this.editableData.groups[this.activeGroupIndex] || this.editableData.groups[0];
							targetGroup.questions = [...(targetGroup.questions || []), ...existingQuestions];
						}
					} else {
						const defaultGroup = {
							id: this.generateId(),
							title: 'Phần I',
							description: 'Nhóm câu hỏi',
							timeLimit: null,
							points: existingQuestions.reduce((sum, q) => sum + (q.points || 1), 0),
							instruction: 'Chọn đáp án đúng nhất',
							questions: existingQuestions
						};
						this.editableData.groups = [defaultGroup];
					}

					this.editableData.questions = [];
					this.activeGroupIndex = 0;
					this.updateGroupPoints();
					this.notify('Đã chuyển sang chế độ nhóm: Toàn bộ câu hỏi đã được gom vào nhóm.');
				} else {
					// TẮT CHẾ ĐỘ NHÓM: Gom toàn bộ câu hỏi từ tất cả các nhóm về danh sách phẳng chung
					const allQuestions = [];
					if (this.editableData.groups && this.editableData.groups.length > 0) {
						this.editableData.groups.forEach(group => {
							if (Array.isArray(group.questions) && group.questions.length > 0) {
								allQuestions.push(...group.questions);
							}
						});
					}

					if (Array.isArray(this.editableData.questions) && this.editableData.questions.length > 0) {
						allQuestions.push(...this.editableData.questions);
					}

					this.editableData = {
						...this.editableData,
						questions: allQuestions,
						groups: []
					};
					this.activeGroupIndex = 0;
					this.notify('Đã tắt chế độ nhóm: Toàn bộ câu hỏi đã được gom về danh sách chung.');
				}
			},

			toggleGroupMode() {
				this.onToggleGroupMode(this.editableData.hasGroups);
			},

			addGroup() {
				const newGroup = {
					id: this.generateId(),
					title: `Phần ${(this.editableData.groups?.length || 0) + 1}`,
					description: 'Mô tả nhóm câu hỏi',
					timeLimit: null,
					points: 0,
					instruction: 'Hướng dẫn làm bài',
					questions: []
				};

				const currentGroups = this.editableData.groups || [];
				this.editableData = {
					...this.editableData,
					groups: [...currentGroups, newGroup]
				};
				this.activeGroupIndex = this.editableData.groups.length - 1;
			},

			async removeGroup(groupIndex) {
				if (this.editableData.groups && this.editableData.groups.length <= 1) {
					this.notify('Phải có ít nhất 1 nhóm câu hỏi', 'warning');
					return;
				}
				const ok = await this.confirmRef.value.show({ title: 'Xóa nhóm này sẽ xóa tất cả câu hỏi bên trong. Bạn có chắc?' });
				if (ok) {
					const newGroups = [...this.editableData.groups];
					newGroups.splice(groupIndex, 1);
					this.editableData = {
						...this.editableData,
						groups: newGroups
					};
					this.activeGroupIndex = Math.min(this.activeGroupIndex, newGroups.length - 1);
				}
			},

			generateId(prefix = 'id') {
				return window.QuizHelpers ? window.QuizHelpers.generateId(prefix) : (prefix + '_' + Math.random().toString(36).substr(2, 9));
			},

			updateGroupPoints() {
				if (this.currentGroup) {
					const points = this.currentGroup.questions?.reduce((sum, q) => sum + (q.points || 1), 0) || 0;
					this.currentGroup.points = points;
					this.editableData.totalPoints = this.totalPointsCalculated;
				}
			},

			quickAddQuestion(type) {
				this.nextQuizType = type;
				this.addQuestion();
			},

			addQuestion() {
				const newQuestionContent = this.ensureDataStructure(this.nextQuizType, {});
				const newQuestion = {
					id: `q_${Date.now()}`,
					type: this.nextQuizType,
					points: 1,
					content: newQuestionContent
				};

				if (this.editableData.hasGroups) {
					if (!this.currentGroup) {
						this.addGroup();
					}

					const currentQuestions = this.currentGroup.questions || [];
					const newQuestions = [...currentQuestions, newQuestion];
					this.currentGroup.questions = newQuestions;
					this.updateGroupPoints();
				} else {
					const currentQuestions = this.editableData.questions || [];
					const newQuestions = [...currentQuestions, newQuestion];
					this.editableData = {
						...this.editableData,
						questions: newQuestions
					};
				}

				// Auto expand the new question
				this.$nextTick(() => {
					this.panel = this.currentQuestionsList.length - 1;
				});
			},

			moveQuestion(fromIndex, toIndex) {
				const questions = this.editableData.hasGroups
					? this.currentGroup?.questions
					: this.editableData.questions;

				if (!questions || toIndex < 0 || toIndex >= questions.length) return;

				const question = questions.splice(fromIndex, 1)[0];
				questions.splice(toIndex, 0, question);

				// Trigger reactivity
				if (this.editableData.hasGroups && this.currentGroup) {
					this.currentGroup.questions = [...questions];
				} else {
					this.editableData = {
						...this.editableData,
						questions: [...questions]
					};
				}
			},

			removeQuestion(index) {
				if (this.editableData.hasGroups && this.currentGroup) {
					const newQuestions = [...this.currentGroup.questions];
					newQuestions.splice(index, 1);
					this.currentGroup.questions = newQuestions;
					this.updateGroupPoints();
				} else {
					const newQuestions = [...this.editableData.questions];
					newQuestions.splice(index, 1);
					this.editableData = {
						...this.editableData,
						questions: newQuestions
					};
				}
			},
			getQuizTypeName(type) {
				const found = this.quizTypesForComposite.find(t => t.value === type);
				return found ? found.title : 'Câu hỏi';
			},

			handleImportQuestions(importData) {
				// Kiểm tra format data
				if (!importData || !importData.questions) {
					console.error('Invalid import data');
					return;
				}

				const { questions, targetGroupIndex, questionType } = importData;

				if (this.editableData.hasGroups) {
					// Import vào group cụ thể
					const targetGroup = this.editableData.groups[targetGroupIndex];
					if (!targetGroup) {
						this.notify('Không tìm thấy nhóm đích', 'error');
						return;
					}

					// Thêm questions vào group
					const currentQuestions = targetGroup.questions || [];
					const newQuestions = [...currentQuestions, ...questions];
					targetGroup.questions = newQuestions;

					// Update points
					this.updateGroupPoints();

					// Switch to target group
					this.activeGroupIndex = targetGroupIndex;

					this.notify(`Đã import ${questions.length} câu hỏi vào "${targetGroup.title}"`);
				} else {
					// Import vào danh sách flat
					const currentQuestions = this.editableData.questions || [];
					const newQuestions = [...currentQuestions, ...questions];

					this.editableData = {
						...this.editableData,
						questions: newQuestions
					};

					this.notify(`Đã import ${questions.length} câu hỏi`);
				}

				// Auto expand câu hỏi đầu tiên vừa import
				this.$nextTick(() => {
					const startIndex = this.editableData.hasGroups
						? (this.currentGroup?.questions?.length || 0) - questions.length
						: (this.editableData.questions?.length || 0) - questions.length;

					this.panel = Math.max(0, startIndex);
				});
			},

			openQuestionFilePicker() {
				this.$refs.questionFileInput?.click();
			},

			async convertQuestionFile(event) {
				const file = event?.target?.files?.[0];
				if (!file) return;

				const questionType = this.nextQuizType || 'QUIZ_SINGLE_CHOICE';
				const questionPrompt = `Bạn là bộ phận trích xuất câu hỏi cho module soan-hoc-lieu-v2.
Trước khi xử lý Content, hãy đọc PRIORITY KNOWLEDGE do hệ thống cung cấp và áp dụng đúng nghiệp vụ nhận diện câu hỏi.
Loại câu hỏi cần xử lý lần này là: ${questionType}.
Chỉ xử lý đúng loại ${questionType}, không trộn loại câu hỏi. Mỗi câu hỏi là một phần tử riêng trong mảng questions.
Giữ nguyên nội dung câu hỏi, lựa chọn, công thức, số liệu và đơn vị. Không tự tạo hoặc tự đoán đáp án nếu Content không có căn cứ.
Không trả về HTML tổng hợp, Markdown, code fence, candidates, RawResponse, thoughtSignature hoặc metadata của Gemini. Không cần gửi id. points mặc định là 1.
Công thức inline dùng $, công thức riêng dòng dùng $$...$$, không dùng MathML, sup hoặc sub.
Chỉ trả về JSON hợp lệ: {"questionType":"${questionType}","questionsCount":0,"questions":[]}. questionsCount phải bằng số phần tử questions.
Mỗi câu phải có type, points, content; mỗi option phải có id và text; đáp án phải tham chiếu đúng option id. Không gộp nhiều câu vào một phần tử.`;

				const formData = new FormData();
				formData.append('file', file);
				formData.append('prompt', questionPrompt);

				this.isConvertingFile = true;
				this.notify('Đang tải file lên và trích xuất câu hỏi qua API...', 'info');

				try {
					const fileBase64 = await this.fileToBase64(file);
					const res = await fetch('https://tapi.lhbs.vn/lms/auth/AIDocumentProcess', {
						method: 'POST',
						headers: { 'Content-Type': 'application/json' },
						body: JSON.stringify({
							Action: 'CONVERT',
							FileName: file.name,
							FileBase64: fileBase64,
							Prompt: questionPrompt,
							PromptId: 'soan-hoc-lieu-v2-import'
						})
					});

					if (!res.ok) {
						throw new Error(`Dịch vụ chuyển đổi trả về mã lỗi HTTP ${res.status}`);
					}

					const payload = await res.json().catch(() => ({}));
					const responseRow = Array.isArray(payload) ? payload[0] : (payload.data?.[0] || payload);
					if (responseRow && responseRow.Status === 'ERROR') {
						throw new Error(responseRow.ErrorMessage || 'Không thể trích xuất câu hỏi từ file');
					}

					let questions = [];
					if (responseRow && responseRow.Data) {
						let converted = responseRow.Data;
						if (typeof converted === 'string') {
							try { converted = JSON.parse(converted); } catch (e) {}
						}
						if (converted && typeof converted.data === 'string') {
							try { converted.data = JSON.parse(converted.data); } catch (e) {}
						}

						const rawQuestions = converted?.data?.questions
							|| converted?.questions
							|| converted?.result?.questions
							|| converted?.output?.questions
							|| (Array.isArray(converted) ? converted : []);

						if (Array.isArray(rawQuestions)) {
							questions = rawQuestions;
						}
					}

					if (!questions.length) {
						throw new Error('API không tìm thấy câu hỏi nào trong file hoặc định dạng file chưa đúng.');
					}

					// Format câu hỏi chuẩn
					const formattedQuestions = questions.map((q, idx) => ({
						id: `q_${Date.now()}_${idx}`,
						type: q.type || questionType,
						points: q.points || 1,
						content: this.ensureDataStructure(q.type || questionType, q.content || {})
					}));

					this.handleImportQuestions({
						questions: formattedQuestions,
						targetGroupIndex: this.activeGroupIndex,
						questionType: questionType
					});

					this.notify(`Đã import thành công ${formattedQuestions.length} câu hỏi từ file "${file.name}"!`, 'success');
				} catch (error) {
					console.error('Convert question file error:', error);
					this.notify(`Import câu hỏi thất bại: ${error.message}`, 'error');
				} finally {
					this.isConvertingFile = false;
					if (event.target) event.target.value = '';
				}
			},

			fileToBase64(file) {
				return new Promise((resolve, reject) => {
					const reader = new FileReader();
					reader.onload = () => resolve(String(reader.result || '').split(',')[1] || '');
					reader.onerror = reject;
					reader.readAsDataURL(file);
				});
			}
		}
	}
</script>