<template>
	<div class="properties-panel">
		<v-tabs v-model="tab" bg-color="white" color="primary" grow sticky>
			<v-tab value="header">{{ $t('message.GeneralInfo') }}</v-tab>
			<v-tab value="element" :disabled="!element">{{ $t('message.Content') }}</v-tab>
		</v-tabs>
		<v-window v-model="tab" class="pa-4 properties-content">
			<v-window-item value="header" eager>
				<v-text-field :label="$t('message.LessonTitle')" :model-value="lessonHeader.Title"
					@update:modelValue="$emit('update:lessonHeader', { ...lessonHeader, Title: $event })"
					variant="outlined" density="compact" />
				<v-textarea :label="$t('message.DescriptionGuide')" :model-value="lessonHeader.Description"
					@update:modelValue="$emit('update:lessonHeader', { ...lessonHeader, Description: $event })"
					variant="outlined" density="compact" rows="3" />
				<!-- Tuần và Chương/Chủ đề được quản lý ở màn thông tin bên ngoài, không lặp lại trong trình soạn bài học. -->
				<!-- Thời gian này được lưu vào EstimatedDuration theo đơn vị phút và được backend dùng để tính hoàn thành bài học. -->
				<v-text-field label="Thời gian hoàn thành (phút)" :model-value="lessonHeader.EstimatedDuration"
					@update:modelValue="updateLessonDuration" @keydown="allowOnlyDigits" type="number"
					inputmode="numeric" min="1" step="1"
					variant="outlined" density="compact" suffix="phút"
					hint="Thời gian học sinh cần tích lũy để được đánh dấu hoàn thành." persistent-hint />
			</v-window-item>

			<v-window-item value="element" eager>
				<div v-if="!element" class="text-center pa-10 text-grey">
					<v-icon size="48" class="mb-2">mdi-cursor-default-click-outline</v-icon>
					<div>{{ $t('message.SelectComponentToEdit') }}</div>
				</div>
				<div v-else>
					<v-text-field :label="$t('message.BlockTitleOptional')" :model-value="element.ElementData.title"
						@update:modelValue="updateElementData({ title: $event })" variant="outlined" density="compact"
						clearable />
					<v-divider class="my-4"></v-divider>
					<div v-if="element.ElementType === 'TEXT'">
						<label class="text-subtitle-2 mb-2 d-block">{{ $t('message.EditText') }}</label>
						<uc-latex-edit :content="element.ElementData.content"
							@update:content="updateElementData({ content: $event })"
							:style="{ 'word-break': 'auto-phrase' }" />
					</div>
					<div v-else-if="element.ElementType === 'IMAGE'">
						<v-btn color="primary" variant="outlined" @click="$refs.inputImage.click()">
							<v-icon start class="me-1">mdi-upload</v-icon>
							{{ $t('message.UploadImage') }}
						</v-btn>
						<input ref="inputImage" type="file" accept="image/*"
							@change="(e) => handleChangeFile(e, element.ElementType)"
							style="display: none" />
						<div class="d-flex ga-2">
							<div v-for="(file, index) in element.ElementData.sources" class="position-relative"
								style="width:200px">
								<v-btn class="position-absolute" @click="removeSource(index)"
									size="small" icon="mdi-close" color="red" variant="tonal"
									style="right: 4px; top: 4px; z-index: 1" />
								<v-img v-if="getImageSource(file)" :src="getImageSource(file)" :lazy-src="getImageSource(file)"
									:alt="file.name || element.ElementData.title || 'Hình ảnh'" height="180" contain>
									<template v-slot:placeholder>
										<div class="d-flex align-center justify-center fill-height">
											<v-progress-circular color="grey-lighten-4"
												indeterminate></v-progress-circular>
										</div>
									</template>
									<template v-slot:error>
										<div class="d-flex flex-column align-center justify-center fill-height text-grey">
											<v-icon>mdi-image-broken-variant</v-icon>
											<span class="text-caption">Không tải được hình ảnh</span>
										</div>
									</template>
								</v-img>
								<div v-else class="empty-element-state">
									<v-icon>mdi-image-off-outline</v-icon>
									<span>Chưa có đường dẫn hình ảnh</span>
								</div>
								<v-text-field class="mt-2" :label="$t('message.Caption')" v-model="file.caption"
									variant="outlined" density="compact" />
							</div>
						</div>
					</div>
					<div v-else-if="element.ElementType === 'YOUTUBE'">
						<div class="d-flex ga-2">
							<v-text-field v-model="element.ElementData.source"
								:placeholder="$t('message.PasteVideoLink')" />
							<v-btn color="primary" variant="outlined" @click="$refs.inputYoutube.click()">
								<v-icon start class="me-1">mdi-upload</v-icon>
								{{ $t('message.UploadVideo') }}
							</v-btn>
						</div>
						<p class="text-caption">
							{{ $t('message.VideoNote') }}
						</p>
						<input ref="inputYoutube" type="file" @change="(e) => handleChangeFile(e, element.ElementType)"
							style="display: none" />
						<iframe width="100%" height="240" :src="renderUrlYoutube(element.ElementData.source)"
							title="YouTube video player" frameborder="0"
							allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
							allowfullscreen class="rounded border"></iframe>

						<!-- Bảng hiển thị danh sách câu hỏi tương tác (Read-only) -->
						<div v-if="element.ElementData.interactive || element.ElementData.interactions?.length" class="mt-4">
							<div class="d-flex align-center justify-space-between mb-2">
								<span class="text-subtitle-2 font-weight-bold text-deep-purple">
									<v-icon color="deep-purple" start size="18">mdi-timeline-text-outline</v-icon>
									Câu hỏi tương tác ({{ (element.ElementData.interactions || []).length }})
								</span>
								<v-chip size="x-small" color="deep-purple" variant="tonal">Từ kho Content Hub</v-chip>
							</div>

							<v-expansion-panels variant="accordion" class="border rounded" density="compact">
								<v-expansion-panel v-for="(item, idx) in (element.ElementData.interactions || [])" :key="idx">
									<v-expansion-panel-title class="py-2">
										<div class="d-flex align-center ga-2 text-truncate">
											<v-chip size="x-small" color="deep-purple" variant="flat">
												{{ formatInteractionTime(item.time) }}
											</v-chip>
											<v-chip size="x-small" :color="getInteractionTypeBadge(item).color" variant="tonal">
												{{ getInteractionTypeBadge(item).label }}
											</v-chip>
											<span class="text-caption text-truncate font-weight-medium" style="max-width: 220px;">
												{{ getInteractionPromptText(item) }}
											</span>
										</div>
									</v-expansion-panel-title>
									<v-expansion-panel-text class="text-caption bg-grey-lighten-5 pa-2">
										<div class="mb-2 font-weight-bold text-body-2 text-grey-darken-3">
											<uc-latex-view :content="getInteractionPromptRaw(item)" />
										</div>
										<!-- Chi tiết các đáp án của câu hỏi -->
										<div v-if="getCorrectInteractionOptions(item).length" class="d-flex flex-column ga-1 mt-1">
											<div v-for="(opt, optIdx) in getCorrectInteractionOptions(item)" :key="opt.id || optIdx"
												class="pa-1 rounded d-flex align-center ga-2"
												:class="isCorrectOption(item, opt) ? 'bg-green-lighten-4 border border-success font-weight-bold text-success' : 'bg-white border text-grey-darken-3'">
												<v-icon size="14" :color="isCorrectOption(item, opt) ? 'success' : 'grey'">
													{{ isCorrectOption(item, opt) ? 'mdi-check-circle' : 'mdi-circle-outline' }}
												</v-icon>
												<div class="flex-grow-1">
													<uc-latex-view :content="opt.text || opt" />
												</div>
												<v-chip v-if="isCorrectOption(item, opt)" size="x-small" color="success" variant="flat">
													Đúng
												</v-chip>
											</div>
										</div>
										<div v-else-if="getInteractionDetailsText(item)" class="text-caption text-grey-darken-3 bg-white pa-2 rounded border">
											<span class="font-weight-bold text-success mr-1">Đáp án:</span>
											<uc-latex-view :content="getInteractionDetailsText(item)" style="display: inline-block;" />
										</div>
									</v-expansion-panel-text>
								</v-expansion-panel>
							</v-expansion-panels>
						</div>
					</div>
					<div v-else-if="element.ElementType === 'FILE'">
						<v-btn color="primary" variant="outlined" @click="$refs.inputFile.click()">
							<v-icon start class="me-1">mdi-upload</v-icon>
							{{ $t('message.UploadFile') }}
						</v-btn>
						<input ref="inputFile" type="file" @change="(e) => handleChangeFile(e, element.ElementType)"
							style="display: none" />
						<div class="d-flex ga-2">
								<v-chip v-for="(file, index) in element.ElementData.sources">
									{{ file.name }}
									<v-icon @click="removeSource(index)">mdi-close</v-icon>
							</v-chip>
						</div>
					</div>
					<div v-else-if="element.ElementType === 'AUDIO'" class="d-flex flex-column ga-2">
						<label class="text-subtitle-2 mb-2 d-block">{{ $t('message.RecordOrUploadAudio') }}</label>
						<div class="d-flex ga-2 mb-2">
							<v-text-field v-model="element.ElementData.source" :placeholder="$t('message.PasteAudioLink')" :clearable="false" />
							<v-btn color="primary" variant="outlined" @click="$refs.inputUploadAudio.click()">
								<v-icon start class="me-1">mdi-upload</v-icon>
								{{ $t('message.UploadAudio') }}
							</v-btn>
							<input ref="inputUploadAudio" type="file" accept="audio/*"
								@change="(e) => handleChangeFile(e, 'UPLOAD_AUDIO')" style="display:none" />
							<v-btn v-if="element.ElementData.source" color="error" variant="outlined"
								@click="removeSingleSource()">
								<v-icon start>mdi-delete-outline</v-icon>{{ $t('message.Delete') }}
							</v-btn>
						</div>
						<uc-audio-record v-model:file="fileRecordAudio" v-model:src="element.ElementData.source"
							@handleSave="handleChangeFile(fileRecordAudio, element.ElementType)" />
					</div>
					<div v-else-if="element.ElementType === 'HTML'" class="d-flex flex-column ga-2">
						<v-checkbox v-model="element.ElementData.IsHTML" label="HTML" />
						<v-textarea v-model="element.ElementData.source" :placeholder="$t('message.PasteHTML')" />
						<!-- <f-editor v-model="element.ElementData.source" /> -->
					</div>
					<!-- QUIZ -->
					<div v-else-if="element.ElementType.includes('QUIZ')">
						<div class="d-flex justify-space-between align-center">
							<p class="mb-2 font-weight-medium">{{ $t('message.AnswerConfig') }}</p>
							<v-checkbox v-model="element.ElementData.config.isAdvanced"
								:label="$t('message.AdvancedAnswerSettings')" />
						</div>
						<div class="mb-2">
							<p class="mt-4 mb-2 font-weight-medium">{{ $t('message.QuestionContentLabel') }}</p>
							<f-editor :model-value="element.ElementData.config.questionText"
								@update:model-value="updateQuestionConfig('questionText', $event)" />
						</div>

						<div v-if="element.ElementType === 'QUIZ_SINGLE_CHOICE'">
							<div v-for="(option, index) in element.ElementData.config.options" :key="option.id"
								class="d-flex align-center mb-2">
								<v-radio-group :model-value="element.ElementData.config.correctAnswer"
									@update:model-value="updateQuestionConfig('correctAnswer', $event)"
									class="flex-shrink-0">
									<v-radio :value="option.id" hide-details />
								</v-radio-group>
								<v-text-field v-if="!element.ElementData.config.isAdvanced" :model-value="option.text"
									@update:model-value="updateOptionText(index, $event)" dense variant="outlined"
									hide-details />
								<uc-latex-edit v-else v-model:content="option.text" />
								<v-btn size="small" @click="removeOption(index)" class="ml-1" icon="mdi-close" />
							</div>
							<v-btn block small @click="addOption" variant="tonal" class="mt-2">
								<v-icon start>mdi-plus</v-icon>{{ $t('message.AddOption') }}
							</v-btn>
						</div>

						<div v-else-if="element.ElementType === 'QUIZ_MULTIPLE_CHOICE'">
							<div v-for="(option, index) in element.ElementData.config.options" :key="option.id"
								class="d-flex align-center mb-2">
								<v-checkbox :model-value="element.ElementData.config.correctAnswers" :value="option.id"
									@update:model-value="updateQuestionConfig('correctAnswers', $event)" hide-details
									class="flex-shrink-0">
								</v-checkbox>
								<v-text-field v-if="!element.ElementData.config.isAdvanced" :model-value="option.text"
									@update:model-value="updateOptionText(index, $event)" dense variant="outlined"
									hide-details />
								<uc-latex-edit v-else v-model:content="option.text" />
								<v-btn icon size="small" @click="removeOption(index)" class="ml-1">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</div>
							<v-btn small @click="addOption" variant="tonal" class="mt-2">
								<v-icon left>mdi-plus</v-icon>{{ $t('message.AddOption') }}
							</v-btn>
						</div>

						<div v-else-if="element.ElementType === 'QUIZ_TRUE_FALSE'">
							<v-radio-group :model-value="element.ElementData.config.correctAnswer"
								@update:model-value="updateQuestionConfig('correctAnswer', $event)">
								<v-radio :value="true" :label="$t('message.Correct')" />
								<v-radio :value="false" :label="$t('message.Incorrect')" />
							</v-radio-group>
						</div>

						<div v-else-if="element.ElementType === 'QUIZ_FILL_IN_BLANK'">
							<p class="text-caption">{{ $t('message.Structure') }}</p>
							<div v-for="(part, index) in element.ElementData.config.parts" :key="index"
								class="d-flex flex-wrap align-center mb-2">
								<v-text-field v-if="part.type === 'text'" :model-value="part.value"
									@update:model-value="updatePart(index, 'value', $event)"
									:label="$t('message.TextContent')" variant="outlined" density="compact"
									hide-details />

								<v-text-field v-if="part.type === 'blank'" :model-value="part.acceptedAnswers[0]"
									@update:model-value="updatePart(index, 'acceptedAnswers', [$event])"
									:label="$t('message.CorrectAnswer')" variant="outlined" density="compact"
									hide-details class="ml-2" />
								<v-btn icon size="small" @click="removePart(index)" class="ml-1">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</div>
							<v-btn small @click="addPart('text')" variant="tonal" class="mr-2 mt-2">{{
								$t('message.AddText') }}</v-btn>
							<v-btn small @click="addPart('blank')" variant="tonal" class="mt-2">{{
								$t('message.AddBlank') }}</v-btn>
						</div>

						<div v-else-if="element.ElementType === 'QUIZ_MATCHING'">
							<v-row>
								<v-col><label class="form-label">{{ $t('message.ColumnA') }}</label></v-col>
								<v-col><label class="form-label">{{ $t('message.ColumnB') }}</label></v-col>
							</v-row>
							<v-row v-for="(pair, index) in element.ElementData.config.columnA" :key="index"
								class="mb-n5">
								<v-col cols="5">
									<v-text-field v-if="!element.ElementData.config.isAdvanced" v-model="pair.text"
										density="compact" variant="outlined" hide-details />
									<uc-latex-edit v-else v-model:content="pair.text" style="width: 50%" />
								</v-col>
								<v-col cols="5" class="d-flex align-center">
									<v-text-field v-if="!element.ElementData.config.isAdvanced"
										v-model="element.ElementData.config.columnB[index].text" density="compact"
										variant="outlined" hide-details style="width: 40%" />
									<uc-latex-edit v-else
										v-model:content="element.ElementData.config.columnB[index].text" />
								</v-col>
								<v-col cols="2">
									<v-btn icon="mdi-delete-outline" variant="text" size="small" color="red"
										@click="removePair(index)" />
								</v-col>
							</v-row>
							<v-btn prepend-icon="mdi-plus" variant="tonal" color="primary" @click="addPair"
								class="mt-4 mb-4">
								{{ $t('message.AddPair') }}
							</v-btn>
						</div>
					</div>
				</div>
			</v-window-item>
		</v-window>
		<uc-loading-page v-model="loadingPage.isLoading" v-model:text="loadingPage.text" />
	</div>
</template>

<script>
	export default {
		name: 'uc-lesson-properties',
		props: {
			lessonHeader: { type: Object, required: true },
			element: { type: Object, default: null },
			index: { type: Number, default: null }
		},
		emits: ['update:lessonHeader', 'update:element'],
		data() {
			this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
			return {
				tab: 'header',
				fileRecordAudio: null,
				loadingPage: {
					isLoading: false,
					text: this.$t('message.LoadingData')
				},
				vueData,
			}
		},
		mounted() {},
		watch: {
			index(newIndex, oldIndex) {
				if (newIndex !== null && newIndex !== oldIndex) this.tab = 'element';
				else if (newIndex === null) this.tab = 'header';
			},
		},
		methods: {
			// Chặn ký tự không phải số ngay khi gõ; dữ liệu dán vào sẽ tiếp tục được làm sạch ở updateLessonDuration.
			allowOnlyDigits(event) {
				const navigationKeys = ['Backspace', 'Delete', 'Tab', 'ArrowLeft', 'ArrowRight', 'Home', 'End'];
				if (navigationKeys.includes(event.key) || event.ctrlKey || event.metaKey) return;
				if (!/^\d$/.test(event.key)) event.preventDefault();
			},
			// Chuẩn hóa ngay tại form để không lưu thời lượng rỗng, số 0 hoặc số lẻ xuống bài học.
			updateLessonDuration(value) {
				const digits = String(value ?? '').replace(/\D/g, '');
				const minutes = Number.parseInt(digits, 10);
				this.$emit('update:lessonHeader', {
					...this.lessonHeader,
					EstimatedDuration: Number.isFinite(minutes) && minutes >= 1 ? minutes : 1,
				});
			},
			async saveElement() {
				const lessonID = Number(this.element?.LessonID || this.lessonHeader?.LessonID || vueData?.LessonID || 0)
				if (!lessonID) throw new Error('Vui lòng lưu bài học lần đầu trước khi tải tệp.')
				return await this.ajaxCALLPromise('lms/EL_Element_Save', {
					ElementID: this.element.ElementID,
					LessonID: lessonID,
					ElementType: this.element.ElementType,
					// Stored procedure yêu cầu ElementData là chuỗi JSON; gửi object trực tiếp có thể bị biến thành [object Object].
					ElementData: JSON.stringify(this.element.ElementData || {}),
					SortOrder: this.element.SortOrder,
				})
			},
			getUploadManager() {
				if (!window.UploadManager) throw new Error('UploadManager chưa được khởi tạo')
				return window.UploadManager
			},
			uploadWithManager(method, file, options = {}) {
				return new Promise((resolve, reject) => {
					this.getUploadManager()[method](file, {
						...options,
						onComplete: resolve,
						onError: reject,
					})
				})
			},
			async uploadToGoogleDriveViaManager(file) {
				const lessonID = Number(this.element?.LessonID || this.lessonHeader?.LessonID || vueData?.LessonID || 0)
				if (!lessonID) throw new Error('Vui lòng lưu bài học lần đầu trước khi tải tệp.')
				const uploaded = await this.uploadWithManager('uploadLmsGoogleDrive', file, {
					folderPath: `LMS_Lesson/Lesson_${lessonID}/${vueData.user.UserID}`,
				})
				return { id: uploaded.id, name: uploaded.name || file.name, source: uploaded.source }
			},
			async uploadFileYoutubeViaManager(file) {
				const lessonID = Number(this.element?.LessonID || this.lessonHeader?.LessonID || vueData?.LessonID || 0)
				if (!lessonID) throw new Error('Vui lòng lưu bài học lần đầu trước khi tải tệp.')
				const uploaded = await this.uploadWithManager('uploadLmsYoutube', file, {
					playlistName: `LMS_Lesson_${lessonID}`,
					title: file.name.replace(/\.[^/.]+$/, ''),
				})
				return { id: uploaded.id, name: uploaded.name || file.name, source: uploaded.source }
			},
			async registerResourceFile(file, resourceType) {
				const uploadManager = this.getUploadManager()
				return new Promise((resolve, reject) => {
					uploadManager.uploadLmsSharedFile(file, {
						onComplete: async response => {
							try {
								// Không dùng lại tên `response` cho Promise đăng ký tài nguyên;
								// nếu shadow biến callback, JavaScript sẽ báo TDZ và chặn ảnh được lưu dù upload đã 100%.
								const uploaded = response?.Files?.[0] || response?.files?.[0] || response?.data?.Files?.[0] || response?.data?.files?.[0]
								if (!uploaded?.FILE_ID) throw new Error('Upload tài nguyên không trả về FILE_ID')
								const metadata = {
									uploadSource: 'db',
									fileId: uploaded.FILE_ID,
									fileName: uploaded.FILE_NAME || file.name,
									contentType: uploaded.FILE_CONTENTTYPE || file.type || '',
									fileSize: Number(uploaded.FILE_SIZE || file.size || 0),
									url: this.normalizeResourceUrl(uploaded.FILE_URL, uploaded.FILE_ID),
									origin: 'SOAN_BAI_HOC',
									publishSource: resourceType,
									lessonID: Number(this.element?.LessonID || this.lessonHeader?.LessonID || vueData?.LessonID || 0),
								}
								const registerResponse = await fetchPromise('lms/FP_TaiNguyen_File_Register', {
									KhoiID: this.element.KhoiID || vueData.lesson?.KhoiID || null,
									MonHocID: this.element.MonHocID || vueData.lesson?.MonHocID || null,
									TenNoiDung: metadata.fileName,
									LoaiNoiDung: resourceType,
									NguonTaiNguyenCode: 'SOAN_BAI_HOC',
									NguonResourceType: 'LESSON',
									NguonResourceID: metadata.lessonID,
									DataJson: JSON.stringify(metadata),
								}, { cache: false })
								const registerError = registerResponse?.Message || registerResponse?.message || registerResponse?.error?.Message || registerResponse?.error?.message
								if (registerError) throw new Error(registerError)
								const registered = Array.isArray(registerResponse) ? registerResponse[0] : registerResponse
								metadata.resourceNodeId = registered?.NoiDungID || null
								resolve(metadata)
						} catch (error) { reject(error) }
						},
						onError: reject,
				})
				})
			},
				// Chuẩn hóa URL LMS để component preview không nhận đường dẫn tương đối theo route của module.
				normalizeResourceUrl(source, fileID) {
					const raw = String(source || '').trim()
					if (raw) {
						if (/^https?:\/\//i.test(raw)) {
							return raw.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/')
						}
						const base = String(vueData?.v_Set?.urlReadFile || vueData?.v_Set?.urlReturnFile || 'https://file.lhbs.vn/lms').replace(/\/+$/, '')
						return `${base}/${raw.replace(/^\/+/, '')}`
					}
					const base = String(vueData?.v_Set?.urlReadFile || vueData?.v_Set?.urlReturnFile || 'https://file.lhbs.vn/lms').replace(/\/+$/, '')
					return fileID ? `${base}/FileData/${encodeURIComponent(fileID)}` : ''
				},
				getDriveFileIdFromSource(source) {
					if (!source || typeof source !== 'string') return null
					const match = source.match(/\/d\/([^/]+)/)
					return match?.[1] || null
				},
				// Content Hub/Học liệu số là tài nguyên dùng chung; xóa trong bài học chỉ được
				// gỡ liên kết, tuyệt đối không xóa node, FileData hoặc file Drive gốc.
				isSharedContentSource(source = null) {
					const sourceType = source?.sourceTracking?.sourceType
						|| this.element?.ElementData?.sourceTracking?.sourceType
					return ['CONTENT_HUB', 'HOC_LIEU_SO'].includes(
						String(sourceType || '').trim().toUpperCase().replace(/[\s-]+/g, '_')
					)
				},
			async deleteDriveFile(source) {
				const fileId = this.getDriveFileIdFromSource(source)
				if (!fileId) throw new Error('Không tìm thấy Google Drive file id')

				const { access_token } = await this.ajaxCALLPromise('lms/FP_Youtube_Token_Get')
				const response = await fetch(`https://www.googleapis.com/drive/v3/files/${fileId}`, {
					method: 'DELETE',
					headers: { Authorization: `Bearer ${access_token}` },
				})
				if (!response.ok) throw new Error(`Xóa file Google Drive thất bại: ${response.statusText}`)
			},
			async deleteYoutubeFile(videoId) {
				if (!videoId) return
				const { access_token } = await this.ajaxCALLPromise('lms/FP_Youtube_Token_Get')
				await new Promise((resolve, reject) => this.getUploadManager().deleteFromYouTube(videoId, {
					accessToken: access_token,
					onComplete: resolve,
					onError: reject,
				}))
			},
			async clearExistingSingleMediaBeforeUpload(elementType) {
				// Ảnh là danh sách nên upload thêm được append; audio/video là media một giá trị nên phải thay thế.
				if (elementType === 'UPLOAD_AUDIO' || elementType === 'AUDIO') {
					if (this.element?.ElementData?.source) {
						const removed = await this.removeSingleSource()
						if (!removed) throw new Error('Không thể xóa audio cũ trước khi tải audio mới.')
					}
					return
				}

				if (elementType === 'YOUTUBE') {
					const data = this.element?.ElementData || {}
					// Video nhập từ Content Hub là tài nguyên dùng chung, chỉ gỡ liên kết;
					// không được xóa video gốc khỏi YouTube.
					const sourceType = String(data.sourceTracking?.sourceType || '').toUpperCase()
					if (data.resourceNodeId && !['CONTENT_HUB', 'HOC_LIEU_SO'].includes(sourceType)) {
						await fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: data.resourceNodeId }, { cache: false })
					}
					if (data.videoId && !['CONTENT_HUB', 'HOC_LIEU_SO'].includes(sourceType)) {
						await this.deleteYoutubeFile(data.videoId)
					}
					data.source = ''
					data.videoId = ''
					data.resourceNodeId = ''
					data.resourceFileId = ''
					// Tương tác gắn theo video cũ không được giữ lại khi thay video mới.
					data.interactions = []
					await this.saveElement()
				}
			},
			async clearExistingFileSourcesBeforeUpload() {
				const sources = Array.isArray(this.element?.ElementData?.sources)
					? this.element.ElementData.sources
					: []
				if (!sources.length) {
					// Element import từ Content Hub có thể còn metadata nguồn dù danh sách file đã rỗng.
					// File upload mới phải trở thành tài sản do bài học sở hữu.
					if (this.isSharedContentSource(this.element?.ElementData)) delete this.element.ElementData.sourceTracking
					return
				}

				// FILE element chỉ giữ file đang được thay thế; xóa từ cuối để không làm lệch index.
				// removeSource tự phân biệt file tự upload và nguồn Content Hub/Học liệu số.
				for (let index = sources.length - 1; index >= 0; index -= 1) {
					const removed = await this.removeSource(index)
					if (!removed) throw new Error('Không thể xóa file cũ trước khi tải file mới.')
				}
				// Không để sourceTracking của file Content Hub cũ đánh dấu nhầm file upload mới là file dùng chung.
				if (this.isSharedContentSource(this.element?.ElementData)) delete this.element.ElementData.sourceTracking
			},
			async removeSource(index) {
				const source = this.element?.ElementData?.sources?.[index]
				if (!source) return true
				try {
						this.loadingPage.isLoading = true
						this.loadingPage.text = this.$t('message.LoadingData')
						const isSharedSource = this.isSharedContentSource(source)
						if (!isSharedSource && source.resourceNodeId) {
							await fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: source.resourceNodeId }, { cache: false })
						}
						const externalSource = source.externalSource || source.source
						if (!isSharedSource && this.getDriveFileIdFromSource(externalSource)) {
							await this.deleteDriveFile(externalSource)
						}
						if (!isSharedSource && source.resourceFileId) {
							await this.getUploadManager().deleteLmsFileData(source.resourceFileId)
						}
					this.element.ElementData.sources.splice(index, 1)
				await this.saveElement()
				return true
				} catch (error) {
					console.error('Lỗi xóa file bài học:', error)
					Vue.$toast.error(error.message || 'Không thể xóa file', { position: 'top' })
					return false
				} finally {
					this.loadingPage.isLoading = false
				}
			},
			async removeSingleSource() {
				const source = this.element?.ElementData?.source
				if (!source) return true
				try {
					this.loadingPage.isLoading = true
					this.loadingPage.text = this.$t('message.LoadingData')
					const isSharedSource = this.isSharedContentSource(this.element.ElementData)
					if (!isSharedSource && this.element.ElementData.resourceNodeId) {
						await fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: this.element.ElementData.resourceNodeId }, { cache: false })
					}
					const externalSource = this.element.ElementData.externalSource || source
					if (!isSharedSource && this.getDriveFileIdFromSource(externalSource)) {
						await this.deleteDriveFile(externalSource)
					}
					if (!isSharedSource && this.element.ElementData.resourceFileId) {
						await this.getUploadManager().deleteLmsFileData(this.element.ElementData.resourceFileId)
					}
					this.element.ElementData.source = ''
					await this.saveElement()
					return true
				} catch (error) {
					console.error('Lỗi xóa file bài học:', error)
					Vue.$toast.error(error.message || 'Không thể xóa file', { position: 'top' })
					return false
				} finally {
					this.loadingPage.isLoading = false
				}
			},
			async handleChangeFile(e, ElementType) {
				let file = null
				if (ElementType === "AUDIO") file = e
				else file = e?.target?.files?.[0]
				if (!file) return
				const lessonID = Number(this.element?.LessonID || this.lessonHeader?.LessonID || vueData?.LessonID || 0)
				if (!lessonID) {
					Vue.$toast.error('Vui lòng lưu bài học lần đầu trước khi tải tệp.', { position: 'top' })
					if (e?.target) e.target.value = ''
					return
				}
				try {
					this.loadingPage.isLoading = true
					this.loadingPage.text = 'Đang tải tệp lên...'
					if (['YOUTUBE', 'UPLOAD_AUDIO', 'AUDIO'].includes(ElementType)) {
						await this.clearExistingSingleMediaBeforeUpload(ElementType)
					}
						if (ElementType === "IMAGE") {
							// Ảnh/file/audio dùng LMS FileData làm nguồn hiển thị ổn định; không phụ thuộc token Google Drive.
							const resource = await this.registerResourceFile(file, 'IMAGE')
							// Element mới có thể chưa có mảng sources; khởi tạo trước khi append để upload không bị lỗi giữa chừng.
							const sources = Array.isArray(this.element.ElementData.sources) ? this.element.ElementData.sources : []
							sources.push({
								id: resource.fileId,
							name: resource.fileName || file.name,
							source: resource.url,
							fileSize: Number(file.size || 0),
								resourceFileId: resource.fileId,
								resourceNodeId: resource.resourceNodeId,
							})
							this.element.ElementData.sources = sources
							await this.saveElement()
					}
					else if (ElementType === 'YOUTUBE') {
						const { id, source } = await this.uploadFileYoutubeViaManager(file)
						// Video dung lượng lớn chỉ lưu trên YouTube; DB LMS chỉ lưu URL/videoId qua ElementData.
						this.element.ElementData.source = source
						this.element.ElementData.videoId = id
						await this.saveElement()
					}
					else if (ElementType === 'FILE') {
						// Người dùng có thể bấm Tải file khi element vẫn còn file cũ;
						// dọn file cũ trước để không tồn tại nhiều bản vật lý ngoài ý muốn.
						await this.clearExistingFileSourcesBeforeUpload()
						const resource = await this.registerResourceFile(file, 'FILE')
							const sources = Array.isArray(this.element.ElementData.sources) ? this.element.ElementData.sources : []
							sources.push({
							id: resource.fileId,
							name: resource.fileName || file.name,
							source: resource.url,
							fileSize: Number(file.size || 0),
								resourceFileId: resource.fileId,
								resourceNodeId: resource.resourceNodeId,
							})
							this.element.ElementData.sources = sources
							await this.saveElement()
					}
					else if (ElementType === 'UPLOAD_AUDIO' || ElementType === 'AUDIO') {
						const resource = await this.registerResourceFile(file, 'AUDIO')
						this.element.ElementData.source = resource.url
						this.element.ElementData.externalSource = ''
						this.element.ElementData.externalId = ''
						this.element.ElementData.resourceFileId = resource.fileId
						this.element.ElementData.resourceNodeId = resource.resourceNodeId
						await this.saveElement()
					}
					Vue.$toast.success('Đã tải tệp và lưu nội dung bài học.', { position: 'top' })
				} catch (error) {
					console.error('Lỗi upload nội dung bài học:', error)
					Vue.$toast.error(error?.message || error?.Message || 'Không thể tải tệp hoặc lưu nội dung bài học.', { position: 'top' })
				} finally {
					this.loadingPage.isLoading = false
					if (e?.target) e.target.value = ''
				}
			},
			async uploadFileYoutube(file) {
				this.loadingPage.isLoading = true
				this.loadingPage.text = this.$t('message.LoadingData')
	
				const { access_token } = await this.ajaxCALLPromise('lms/FP_Youtube_Token_Get')
				const playLists = await this.ajaxCALLPromise('lms/FP_Youtube_PlayList_Get', { Access_Token: access_token })
	
				const namePrefix_Playlist = `LMS_Lesson_${this.element.LessonID}`
	
				const namePlaylist = namePrefix_Playlist
				console.log('namePlaylist', namePlaylist)
				let playListCurrent = playLists?.find(x => x.Title === namePlaylist)
				if (!playListCurrent) {
					const response = await this.ajaxCALLPromise('lms/FP_Youtube_PlayList_Ins', {
						TenPlayList: namePlaylist, Access_Token: access_token
					})
					playListCurrent = response[0] //khi insert xong API trả về ID mới
				}
	
				function getCleanTitle(filename) {
					if (typeof filename !== 'string') return '';
					// Danh sách phần mở rộng cần loại bỏ
					const extensions = ['mp4', 'mov', 'avi', 'mkv'];
					// Biểu thức regex để tìm và loại bỏ đuôi file nếu nó ở cuối chuỗi
					const regex = new RegExp(`\\.(${extensions.join('|')})$`, 'i');
					// Bỏ phần mở rộng nếu có
					const nameWithoutExtension = filename.replace(regex, '');
					// Cắt khoảng trắng đầu/cuối
					const cleanTitle = nameWithoutExtension.trim();
					// Giới hạn 100 ký tự theo quy định của YouTube
					return cleanTitle.length > 100 ? cleanTitle.slice(0, 100) : cleanTitle;
				}
	
				const url =
					'https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status,contentDetails';
	
				const accessToken = access_token;
				const xUploadContentLength = file.size; // ví dụ 3MB
				const xUploadContentType = file.type; // hoặc 'video/mp4'
				const body = {
					snippet: {
						title: getCleanTitle(file.name),
						description: '',
						tags: [],
						categoryId: '27'
					},
					status: {
						privacyStatus: 'unlisted',
						selfDeclaredMadeForKids: true
					}
				};
	
				this.loadingPage.text = this.$t('message.ContinuingUpload')
				//Tạo Resumable
				const response_Resumable = await fetch(url, {
					method: 'POST',
					headers: {
						'Authorization': `Bearer ${accessToken}`,
						'Content-Type': 'application/json; charset=UTF-8',
						'X-Upload-Content-Length': xUploadContentLength.toString(),
						'X-Upload-Content-Type': xUploadContentType
					},
					body: JSON.stringify(body)
				})
				if (!response_Resumable.ok) throw new Error('Upload session initiation failed');
				const uploadUrl = response_Resumable.headers.get('Location'); // URL để upload phần video
	
				this.loadingPage.text = this.$t('message.Uploading')
				//Upload Video
				const response_file = await fetch(uploadUrl, {
					method: "PUT",
					headers: {
						'Authorization': `Bearer ${accessToken}`,
						'Content-Length': xUploadContentLength,
						'Content-Type': xUploadContentType
					},
					body: file
				})
	
				if (!response_file.ok) throw new Error(`Lỗi khi upload video: ${response_file.statusText}`);
	
				const videoResult = await response_file.json();
				const youtubeUrl = `https://www.youtube.com/watch?v=${videoResult.id}`;
				console.log('🎉 Upload thành công:', youtubeUrl);
	
				this.loadingPage.text = this.$t('message.UpdatingVideoPlaylist')
				//Cập nhật lại PlayList vào video
				const response_playList = await fetch('https://www.googleapis.com/youtube/v3/playlistItems?part=snippet', {
					method: 'POST',
					headers: {
						Authorization: `Bearer ${access_token}`,
						'Content-Type': 'application/json'
					},
					body: JSON.stringify({
						snippet: {
							playlistId: playListCurrent?.PlaylistID,
							resourceId: {
								kind: 'youtube#video',
								videoId: videoResult.id
							}
						}
					})
				})
				this.loadingPage.text = this.$t('message.WaitingYoutube')
				//Sau khi xử lý xong video thì kiểm tra video đã được upload completed lên chưa
				const isCompleted = await this.waitUntilVideoReady(videoResult.id, access_token)
				if (isCompleted) {
					//Xử lý tiếp theo
					this.loadingPage.isLoading = false
					return { id: videoResult.id, name: file.name, source: youtubeUrl }
				}
			},
			async waitUntilVideoReady(videoId, accessToken, maxWaitMs = 300000) {
				const start = Date.now();
				const checkInterval = 5000; // mỗi 5 giây check 1 lần
	
				while (Date.now() - start < maxWaitMs) {
					const res = await
						fetch(`https://www.googleapis.com/youtube/v3/videos?part=processingDetails&id=${videoId}`, {
							headers: {
								Authorization: `Bearer ${accessToken}`
							}
						});
					if (!res.ok) throw new Error('Lỗi khi kiểm tra trạng thái xử lý video');
					const data = await res.json();
					const status = data.items?.[0]?.processingDetails?.processingStatus;
					console.log('🔄 Trạng thái xử lý:', status);
	
					// 👉 Nếu không có status
					if (!status) {
						Vue.$toast.error(this.$t('message.VideoTooLongWarning'), { position: 'top' })
						throw new Error('⚠️ Video có thể quá dài (chỉ upload < 15 phút)');
						return true // thoát khỏi vòng lặp
					}
	
					if (status === 'succeeded') {
						return true; // Đã xử lý xong 
					} if (status === 'failed' || status === 'rejected') {
						throw new Error(`❌ Video xử lý thất bại: ${status}`);
					}
					await new Promise(resolve => setTimeout(resolve, checkInterval)); // đợi 5 giây
				}
				throw new Error('⏳ Quá thời gian chờ xử lý video');
			},
			async ensureFolderPathExists(path, access_token) {
				const parts = path.split('/');
				let parentId = 'root';
	
				for (const part of parts) {
					parentId = await this.getOrCreateFolderId(part, parentId, access_token);
				}
	
				return parentId; // Trả về folder cuối cùng
			},
			async getOrCreateFolderId(folderName, parentId = 'root', access_token) {
				const query = `name = '${folderName}' and mimeType = 'application/vnd.google-apps.folder' and '${parentId}' in parents and trashed = false`;
	
				const res = await fetch(`https://www.googleapis.com/drive/v3/files?q=${encodeURIComponent(query)}&fields=files(id)`, {
					headers: {
						Authorization: `Bearer ${access_token}`,
					},
				});
	
				const data = await res.json();
				if (data.files.length > 0) return data.files[0].id;
	
				// ⛏️ Nếu không có, tạo thư mục
				const createRes = await fetch('https://www.googleapis.com/drive/v3/files', {
					method: 'POST',
					headers: {
						Authorization: `Bearer ${access_token}`,
						'Content-Type': 'application/json',
					},
					body: JSON.stringify({
						name: folderName,
						mimeType: 'application/vnd.google-apps.folder',
						parents: [parentId],
					}),
				});
	
				const created = await createRes.json();
				return created.id;
			},
			async uploadToGoogleDrive(file) {
				//Trường hợp vô if
				//Khi nội dung source ko có thay đổi, vẫn là file cũ thì sẽ ko có "file"
				//Nêu ghi âm thì sẽ có file mới thì sẽ bảo qua điều kiện if
				if (!file) return
	
				this.loadingPage.isLoading = true
				this.loadingPage.text = this.$t('message.LoadingData')
	
				//Lấy Token từ câu gọi Youtube
				const { access_token } = await this.ajaxCALLPromise('lms/FP_Youtube_Token_Get')
	
				this.loadingPage.text = this.$t('message.SearchingFolder')
				const pathPrefix = `LMS_Lesson/Lesson_${this.element.LessonID}/${vueData.user.UserID}`
				const folderId = await this.ensureFolderPathExists(pathPrefix, access_token);
	
				const metadata = {
					name: file.name,
					mimeType: file.type,
					parents: [folderId],
				};
	
				const form = new FormData();
				form.append('metadata', new Blob([JSON.stringify(metadata)], { type: 'application/json' }));
				form.append('file', file);
	
				this.loadingPage.text = this.$t('message.Uploading')
				const res = await fetch('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart', {
					method: 'POST',
					headers: new Headers({ Authorization: 'Bearer ' + access_token }),
					body: form,
				});
	
				const fileDrive = await res.json();
	
				this.loadingPage.text = this.$t('message.GrantingFilePermission')
				//Cấp quyền cho file được công khai
				const reponse_permision = await fetch(`https://www.googleapis.com/drive/v3/files/${fileDrive?.id}/permissions`, {
					method: 'POST',
					headers: {
						Authorization: 'Bearer ' + access_token
					},
					body: JSON.stringify({
						role: 'reader', // Quyền xem
						type: 'anyone', // Bất kỳ ai
					}),
				});
	
				//Khi cập nhật permision xong thì lưu lại vào trong json editableItem
				if (reponse_permision.ok) {
					const driveFileUrl = `https://drive.google.com/file/d/${fileDrive.id}/preview`
					this.loadingPage.isLoading = false
					return { id: fileDrive.id, name: file.name, source: driveFileUrl }
				}
			},
			// Giữ tương thích cả ảnh Google Drive cũ và ảnh Content Hub lưu trên FileData/LMS.
			getImageSource(file) {
				const source = String(file?.source || file?.url || file?.externalSource || '').trim()
				if (!source) return ''
				if (/drive\.google\.com/i.test(source)) {
					const driveId = file?.externalId || file?.id || this.getDriveFileId(source)
					return driveId ? `https://drive.google.com/thumbnail?id=${driveId}&sz=w1000` : source
				}
				if (/^https?:\/\/lms\.lhbs\.vn\/FileData\//i.test(source)) {
					return source.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/')
				}
				if (/^https?:\/\//i.test(source) || /^(?:data|blob):/i.test(source)) return source
				const base = vueData?.v_Set?.urlReadFile || 'https://file.lhbs.vn/lms'
				return `${base.replace(/\/+$/, '')}/${source.replace(/^\/+/, '')}`
			},
			getDriveFileId(url) {
				const match = String(url || '').match(/\/d\/([^/]+)/)
				return match?.[1] || null
			},
			ajaxCALLPromise(url, params = null) {
				return new Promise((resolve, reject) => {
					ajaxCALL(url, params, res => {
						const data = res?.data ?? res
						const errorMessage = res?.Message || res?.message || res?.error?.Message || res?.error?.message
							|| data?.Message || data?.message || data?.error?.Message || data?.error?.message
						if (errorMessage && !Array.isArray(data)) {
							reject(new Error(errorMessage))
							return
						}
						resolve(data)
					})
				})
			},
			updateQuestionConfig(key, value) {
				this.element.ElementData.config[key] = value
			},
			updateOptionText(optionIndex, event) {
				this.element.ElementData.config.options[optionIndex].text = event
			},
			addOption() {
				const opts = this.element.ElementData.config.options
				opts.push({ id: `opt_${Date.now()}`, text: this.$t('message.NewOption') });
				this.element.ElementData.config.options = opts
			},
			removeOption(optionIndex) {
				this.element.ElementData.config.options.splice(optionIndex, 1);
			},
			updatePart(partIndex, key, value) {
				this.element.ElementData.config.parts[partIndex][key] = value
			},
			addPart(type) {
				const parts = this.element.ElementData.config.parts;
				if (type === 'text') parts.push({ type: 'text', value: ' ' });
				else parts.push({ type: 'blank', id: `blank_${Date.now()}`, acceptedAnswers: [] });
				this.element.ElementData.config.parts = parts
			},
			removePart(partIndex) {
				this.element.ElementData.config.parts.splice(partIndex, 1);
			},
			addPair() {
				const newIndex = Date.now();
				const aId = `a${newIndex}`;
				const bId = `b${newIndex}`;
				const newA = [...this.element.ElementData.config.columnA, { id: aId, text: '' }];
				const newB = [...this.element.ElementData.config.columnB, { id: bId, text: '' }];
				const newPairs = [...this.element.ElementData.config.correctPairs, { from: aId, to: bId }];
				this.element.ElementData.config = { ...this.element.ElementData.config, columnA: newA, columnB: newB, correctPairs: newPairs };
			},
			removePair(index) {
				if (this.element.ElementData.config.columnA.length > 1) {
					const newA = [...this.element.ElementData.config.columnA]; newA.splice(index, 1);
					const newB = [...this.element.ElementData.config.columnB]; newB.splice(index, 1);
					const newPairs = [...this.element.ElementData.config.correctPairs]; newPairs.splice(index, 1);
					this.element.ElementData.config = { ...this.element.ElementData.config, columnA: newA, columnB: newB, correctPairs: newPairs };
				}
			},
			updateElementData(newData) {
				const updatedElement = JSON.parse(JSON.stringify(this.element));
				updatedElement.ElementData = { ...updatedElement.ElementData, ...newData };
				this.$emit('update:element', { index: this.index, element: updatedElement });
			},
			formatInteractionTime(seconds) {
				const s = Math.floor(Number(seconds) || 0);
				const mins = Math.floor(s / 60);
				const secs = s % 60;
				return `${mins}:${String(secs).padStart(2, '0')}`;
			},
			getInteractionTypeBadge(item) {
				const rawType = item?.question?.type || item?.type || 'QUIZ_SINGLE_CHOICE';
				const map = {
					QUIZ_SINGLE_CHOICE: { label: 'Trắc nghiệm đơn', color: 'success' },
					QUIZ_MULTIPLE_CHOICE: { label: 'Chọn nhiều', color: 'info' },
					QUIZ_TRUE_FALSE: { label: 'Đúng / Sai', color: 'purple' },
					QUIZ_FILL_IN_BLANK: { label: 'Điền từ', color: 'indigo' },
					QUIZ_MATCHING: { label: 'Nối cặp', color: 'deep-orange' },
					QUIZ_ORDERING: { label: 'Sắp xếp', color: 'teal' }
				};
				return map[rawType] || { label: 'Câu hỏi', color: 'grey' };
			},
			getInteractionPromptRaw(item) {
				if (!item) return 'Câu hỏi tương tác';
				const content = this.getInteractionContent(item);
				const raw = content?.prompt ?? content?.questionText ?? item?.prompt ?? item?.question ?? 'Câu hỏi tương tác';
				return raw || 'Câu hỏi tương tác';
			},
			getInteractionPromptText(item) {
				if (!item) return 'Câu hỏi tương tác';
				const content = this.getInteractionContent(item);
				const raw = content?.prompt ?? content?.questionText ?? item?.prompt ?? item?.question ?? 'Câu hỏi tương tác';
				if (!raw) return 'Câu hỏi tương tác';
				return String(raw).replace(/<[^>]*>?/gm, '').replace(/&[^;]+;/g, ' ').trim() || 'Câu hỏi tương tác';
			},
			getInteractionContent(item) {
				return {
					...(item || {}),
					...(item?.content || {}),
					...(item?.question?.content || {}),
					...(item?.config || {}),
					...(item?.question?.config || {})
				};
			},
			getInteractionOptions(item) {
				const content = this.getInteractionContent(item);
				if (Array.isArray(content.options)) return content.options;
				if (Array.isArray(item?.options)) return item.options;
				return [];
			},
			getCorrectInteractionOptions(item) {
				return this.getInteractionOptions(item).filter(option => this.isCorrectOption(item, option));
			},
			isCorrectOption(item, opt) {
				const content = this.getInteractionContent(item);
				const correctAns = content.correctAnswer ?? item?.correctAnswer;
				const correctAnsArr = content.correctAnswers ?? item?.correctAnswers;
				const optId = opt?.id ?? opt;
				const optIndex = this.getInteractionOptions(item).indexOf(opt);
				if (typeof correctAns === 'number' && !opt?.id) {
					return correctAns === optIndex;
				}
				if (correctAns !== undefined && correctAns !== null) {
					return String(correctAns) === String(optId);
				}
				if (Array.isArray(correctAnsArr)) {
					return correctAnsArr.map(String).includes(String(optId));
				}
				return false;
			},
			getInteractionDetailsText(item) {
				const content = this.getInteractionContent(item);
				if (content.parts && Array.isArray(content.parts)) {
					return content.parts.map(p => p.type === 'blank' ? `[___: ${(p.acceptedAnswers || []).join(', ')}]` : p.value).join(' ');
				}
				if (content.correctAnswer !== undefined) {
					return `Đáp án: ${content.correctAnswer === true ? 'Đúng' : content.correctAnswer === false ? 'Sai' : content.correctAnswer}`;
				}
				return '';
			},
	
			renderUrlYoutube
		}
	}
</script>