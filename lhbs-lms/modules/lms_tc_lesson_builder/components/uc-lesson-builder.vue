<template>
	<Global upload-manager>
	<div class="builder-layout">
		<!-- Cột trái: Thư viện -->
		<div class="builder-sidebar left-sidebar">
			<!-- Thư viện cuộn trong phần còn lại; nút xem trước luôn nằm sát đáy sidebar. -->
			<div class="flex-grow-1 fpScrollbar" style="min-height: 0;">
				<uc-lesson-component-library @add-element="addElement"></uc-lesson-component-library>
			</div>
			<div v-if="canEdit" class="action-buttons">
				<v-btn variant="outlined" color="primary" block @click="openLessonPreview">
					<v-icon start class="me-1">mdi-eye-outline</v-icon> Xem trước bài học
				</v-btn>
			</div>
		</div>

		<!-- Cột giữa: Canvas -->
		<!-- Canvas và nội dung thuộc tính bên phải cuộn độc lập để mỗi cột giữ đúng chiều cao viewport. -->
		<div class="builder-canvas fpScrollbar">
			<uc-lesson-canvas :elements="lesson.elements" :completion-policy="lesson.CompletionPolicy"
				v-model:selected-index="selectedElementIndex" :read-only="!canEdit"
				@update:elements="updateElements" />
		</div>

		<!-- Cột phải: Thuộc tính và Nút Lưu -->
		<div class="builder-sidebar right-sidebar">
			<uc-lesson-properties v-model:lesson-header="lesson" :element="selectedElement"
				:index="selectedElementIndex" @update:element="updateElement" />
			<!-- Các thao tác lưu và nhập nội dung dành cho giáo viên. -->
			<div v-if="canEdit" class="action-buttons">
				<!-- Content Hub là nguồn nhập duy nhất của trình soạn bài, nên mở dialog trực tiếp. -->
				<v-btn variant="outlined" color="deep-purple" block class="mb-2" @click="isOpenContentHubImport = true">
					<v-icon start class="me-1">mdi-import</v-icon>Import từ Content Hub
				</v-btn>
				<v-btn variant="outlined" block @click="handleSave(false)" class="mb-2"><v-icon start class="me-1">mdi-file-edit-outline</v-icon>
					{{ $t('message.SaveDraft')}}</v-btn>
				<v-btn color="orange" variant="outlined" v-if="classOptions.length > 0" block
					@click="openSheetAssignToClass()" class="mb-2"><v-icon start class="me-1">mdi-clipboard-arrow-right-outline</v-icon>
					{{ $t('message.SaveAndAssign') }}</v-btn>
			</div>
		</div>

		<!-- Dialog Import từ Content Hub: Soạn bài học chỉ nhận tài liệu học tập, ẩn hoàn toàn tab Câu hỏi -->
		<uc-content-hub-import-dialog v-model="isOpenContentHubImport" :resource="lesson" :documents-only="true"
			:allowed-document-types="['DOCUMENT', 'VIDEO', 'AUDIO', 'IMAGE', 'HTML', 'ISPRING']"
			@import-document="handleImportDocumentFromContentHub" />
		<v-bottom-sheet v-model="isOpenSheetAssignToClass" persistent inset>
			<v-card height="fit-content">
				<v-card-title class="bg-warning d-flex">
					<span class="text-white">{{ $t('message.AssignAssignment') }}</span>
					<v-spacer></v-spacer>
					<v-btn variant="text" icon="mdi-close" color="white"
						@click="isOpenSheetAssignToClass = false"></v-btn>
				</v-card-title>
				<v-card-text>
					<v-row dense class="mb-3">
						<v-col cols="12">
							<p class="text-subtitle-2 mb-3">{{ $t('message.Time') }}</p>
							<div class="d-flex ga-3">
								<v-text-field :model-value="formattedDate(deadlines?.date)"
									:label="$t('message.ExpirationDate')" readonly variant="outlined"
									@click="openDate(id)" />
								<v-text-field :model-value="formattedTime(deadlines?.time)"
									:label="$t('message.ExpirationTime')" readonly variant="outlined"
									@click="openTime(id)" />
							</div>
						</v-col>
					</v-row>
					<div class="d-flex">
						<p class="text-subtitle-2">{{ $t('message.ClassList') }}</p>
						<v-spacer></v-spacer>
						<div class="d-flex ga-2" @click='selectedAllClass()'>
							<v-checkbox color="success" :indeterminate="isIndeterminate" v-model="isAllSelected"
								:label="$t('message.SelectAll')">
							</v-checkbox>
						</div>
					</div>
					<div class="d-flex  flex-wrap ga-5">
						<div v-for="item in classOptions" :key="item.LopID" class="d-flex ga-1 justify-center align-center">
							<v-checkbox v-model='selectedClass' :value="item.LopID" color="success">
							</v-checkbox>
							<p>{{ item.TenLopDisplay || item.TenLop }}</p>
						</div>

					</div>

				</v-card-text>
				<v-divider></v-divider>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn variant="text" color="primary" @click="onAssignToClassAndSave">{{ $t('message.Assigned')
					}}</v-btn>
				</v-card-actions>
			</v-card>
		</v-bottom-sheet>
		<!-- Dialog chọn ngày (dùng 1 cái cho tất cả lớp) -->
		<v-dialog v-model="dateDialogVisible" max-width="350">
			<v-card>
				<v-date-picker v-model="deadlines.date" @update:model-value="dateDialogVisible = false" />
				<v-card-actions>
					<v-spacer />
					<v-btn variant="text" @click="dateDialogVisible = false">{{ $t('message.Cancel') }}</v-btn>
					<v-btn color="primary" @click="dateDialogVisible = false">OK</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Dialog chọn giờ (dùng 1 cái cho tất cả lớp) -->
		<v-dialog v-model="timeDialogVisible" max-width="350">
			<v-card>
				<v-time-picker v-model="deadlines.time" format="24hr" @update:model-value="timeDialogVisible = false" />
				<v-card-actions>
					<v-spacer />
					<v-btn variant="text" @click="timeDialogVisible = false">{{ $t('message.Cancel') }}</v-btn>
					<v-btn color="primary" @click="timeDialogVisible = false">OK</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
		</div>
	</Global>
</template>

<script>
	export default {
		name: 'uc-lesson-builder',
	inject: ['snackbarRef', 'iframeRef'],
	props: {
		initialLesson: Object,
		isEditMode: Boolean,
		canEdit: { type: Boolean, default: true },
		onSave: { type: Function, default: () => { } }
	},
	emits: ['update:initialLesson'],
	data() {
		this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
		return {
			vueData,
			lesson: { elements: [] },
			selectedElementIndex: null,
			isOpenSheetAssignToClass: false,
			deadlines: {
				date: null,
				time: null
			},
			selectedClass: [],
			classAssigned: [],
			timeDialogVisible: false,
			dateDialogVisible: false,
			classOptions: [],
			lessonID: null,
			isOpenContentHubImport: false
		}
	},
	computed: {
		selectedElement() {
			if (this.selectedElementIndex === null || !this.lesson.elements) return null;
			return this.lesson.elements[this.selectedElementIndex];
		},
		isIndeterminate: function () {
			return this.selectedClass.length != 0 && this.selectedClass.length !== this.classOptions.length
		},
		isAllSelected: function () {
			return this.selectedClass.length != 0 && this.selectedClass.length == this.classOptions.length
		},
	},
	mounted() {
		// Người xem theo môn không cần gọi API lớp/giao bài; các thao tác này chỉ dành cho chủ bài.
		if (!this.canEdit) return

		// ajaxCALL("/lms/EL_Teacher_GetGroupedDashboard", {

		// }, (res) => {
		// 	const lesson = { ...vueData.Lesson_API[0][0] }
		// 	const id = lesson.LessonID
		// 	this.lessonID = id
		// 	this.classAssignedAssignment = (res?.data[2] || []).filter(x => x.AssignmentID == id);
		// 	this.classAssignedLesson = (res?.data[3] || []).filter(x => x.AssignmentID == id);


		// 	let classAssignedByKhoiMon = (res?.data[1] || []).filter(
		// 		c => c.KhoiID == lesson.KhoiID && c.MonHocID == lesson.MonHocID
		// 	);
		// 	const assignmentAssignedByLopIDs = this.classAssignedAssignment.map(c => c.LopID);
		// 	const lessonAssignedByLopIDs = this.classAssignedLesson.map(c => c.LopID);
		// 	this.classOptions = classAssignedByKhoiMon.filter(
		// 		item => !assignmentAssignedByLopIDs.includes(item.LopID) && !lessonAssignedByLopIDs.includes(item.LopID)
		// 	);

		// });

		fetchPromise('/lms/EL_Teacher_GetLop_GiaoBai', {
		AssignmentID: vueData.lesson.LessonID,
		MonHocID: vueData.lesson.MonHocID,
			ResourceType: 'LESSON'
		}, { cache: false }).then(res => this.loadAssignableClasses(res, vueData.lesson.LessonID))
			.catch(error => this.showSnackbar(error?.Message || error?.message || 'Không thể tải danh sách lớp.', 'error'))
	},
	watch: {
		initialLesson: {
			handler(newVal) {
				if (newVal) {
					const processedElements = (newVal.elements || []).map(el => {
						try {
							el.ElementData = typeof el.ElementData === 'string' ? JSON.parse(el.ElementData) : (el.ElementData || {});
						} catch (e) {
							console.error("Lỗi parse ElementData:", el.ElementData, e);
							el.ElementData = {};
						}
						// Ưu tiên thời lượng lấy từ metadata hoặc ước lượng nội dung chữ; giữ giá trị cũ nếu không đủ dữ liệu để tính lại.
						const expectedDuration = this.getExpectedDurationSeconds(el);
						if (expectedDuration !== null) el.ExpectedDurationSeconds = expectedDuration;
						return el;
					});
					this.lesson = { ...newVal, elements: processedElements };
				}
			},
			immediate: true,
			deep: true
		}
	},
	methods: {
		parseDurationSeconds(value) {
			if (value === null || value === undefined || value === '') return null;
			const numericValue = Number(value);
			if (Number.isFinite(numericValue) && numericValue > 0) return Math.round(numericValue);
			const valueText = String(value).trim();
			const isoMatch = valueText.match(/^PT(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)S)?$/i);
			if (isoMatch) {
				const total = Number(isoMatch[1] || 0) * 3600 + Number(isoMatch[2] || 0) * 60 + Number(isoMatch[3] || 0);
				return total > 0 ? Math.round(total) : null;
			}
			const clockMatch = valueText.match(/^(?:(\d+):)?([0-5]?\d):([0-5]\d)$/);
			if (!clockMatch) return null;
			const total = Number(clockMatch[1] || 0) * 3600 + Number(clockMatch[2]) * 60 + Number(clockMatch[3]);
			return total > 0 ? total : null;
		},
		getExpectedDurationSeconds(element) {
			const elementData = element?.ElementData || {};
			const sourceMetadata = Array.isArray(elementData.sources) ? elementData.sources : [];
			const metadataObjects = [elementData, elementData.metadata, elementData.mediaMetadata, ...sourceMetadata].filter(Boolean);
			const durationKeys = ['durationSeconds', 'DurationSeconds', 'mediaDurationSeconds', 'MediaDurationSeconds', 'duration', 'Duration', 'lengthSeconds', 'LengthSeconds'];
			for (const metadata of metadataObjects) {
				for (const key of durationKeys) {
					const seconds = this.parseDurationSeconds(metadata[key]);
					if (seconds !== null) return seconds;
				}
				const milliseconds = Number(metadata.durationMilliseconds || metadata.DurationMilliseconds || metadata.durationMs || metadata.DurationMs);
				if (Number.isFinite(milliseconds) && milliseconds > 0) return Math.round(milliseconds / 1000);
			}

			let rawText = '';
			let standaloneLinkUrl = '';
			if (element?.ElementType === 'TEXT') rawText = elementData.content || '';
			else if (element?.ElementType === 'HTML') {
				rawText = elementData.textContent || elementData.htmlContent || (elementData.IsHTML ? elementData.source : '');
				// Với HTML ở chế độ URL trang, nội dung ở xa không đọc được an toàn do CORS/đăng nhập.
				if (!elementData.IsHTML) standaloneLinkUrl = this.normalizeExpectedLinkUrl(elementData.source);
			}
			const estimate = this.getTextAndLinkEstimate(rawText);
			const linkUrls = new Set(estimate.linkUrls);
			if (standaloneLinkUrl) linkUrls.add(standaloneLinkUrl);
			const readingSeconds = estimate.wordCount > 0 ? Math.max(1, Math.ceil(estimate.wordCount * 60 / 200)) : 0;
			// Link ngoài được tính một phút đọc/xem sơ bộ; đây là mốc tham khảo vì trang đích có thể dài, ngắn hoặc yêu cầu đăng nhập.
			const linkedPageSeconds = linkUrls.size * 60;
			if (readingSeconds || linkedPageSeconds) return readingSeconds + linkedPageSeconds;
			return this.parseDurationSeconds(element?.ExpectedDurationSeconds);
		},
		normalizeExpectedLinkUrl(value) {
			const candidate = String(value || '').trim();
			if (!candidate) return '';
			try {
				const parsed = new URL(/^www\./i.test(candidate) ? 'https://' + candidate : candidate);
				return ['http:', 'https:'].includes(parsed.protocol) ? parsed.href : '';
			} catch (error) {
				return '';
			}
		},
		getTextAndLinkEstimate(rawHtml) {
			if (!rawHtml || typeof DOMParser === 'undefined') return { wordCount: 0, linkUrls: [] };
			const parsed = new DOMParser().parseFromString('<div>' + rawHtml + '</div>', 'text/html');
			const root = parsed.body.firstElementChild;
			if (!root) return { wordCount: 0, linkUrls: [] };
			root.querySelectorAll('script, style').forEach(node => node.remove());

			const links = new Set();
			Array.from(root.querySelectorAll('a')).forEach(anchor => {
				const href = this.normalizeExpectedLinkUrl(anchor.getAttribute('href') || anchor.href);
				if (href) links.add(href);
				// A URL shown as its own link is counted as a page, not as a single reading word.
				if (href && this.normalizeExpectedLinkUrl(anchor.textContent) === href) anchor.remove();
			});

			const urlPattern = /(?:https?:\/\/|www\.)[^\s<>"']+/gi;
			const collectPlainTextLinks = node => {
				if (node.nodeType === 3) {
					node.nodeValue = (node.nodeValue || '').replace(urlPattern, rawUrl => {
						const trimmedUrl = rawUrl.replace(/[),.;:!?…]+$/u, '');
						const normalizedUrl = this.normalizeExpectedLinkUrl(trimmedUrl);
						if (normalizedUrl) links.add(normalizedUrl);
						return ' ';
					});
					return;
				}
				if (node.nodeType !== 1 || node.tagName === 'A') return;
				Array.from(node.childNodes).forEach(collectPlainTextLinks);
			};
			collectPlainTextLinks(root);

			const text = (root.textContent || '').replace(/\s+/g, ' ').trim();
			const wordCount = text ? text.split(' ').filter(word => /[A-Za-z0-9À-ỹ]/.test(word)).length : 0;
			return { wordCount, linkUrls: Array.from(links) };
		},
		showSnackbar(message, color = 'info') {
			this.snackbarRef?.value?.showSnackbar?.({ message, color })
		},
		getCurrentSchoolYear() {
			return Number(vueData.lesson?.NienKhoa ?? vueData.NienKhoa ?? 0)
		},
		getCurrentGradeId() {
			return Number(vueData.lesson?.KhoiID ?? 0)
		},
		getCurrentTeacherId() {
			return vueData.GiaoVienID_Selected || vueData.lesson?.GiaoVienID || vueData.user?.UserID
		},
		async getAssignedClassNames(assignmentID, resourceType) {
			try {
				const response = await fetchPromise('/lms/EL_Teacher_GetAssignmentStatusByClass', {
					AssignmentID: assignmentID,
					ResourceType: resourceType
				}, { cache: false })
				const rows = (Array.isArray(response) ? response : []).flat(Infinity).filter(row => row?.TenLop)
				return new Set(rows.map(row => String(row.TenLop).trim().replace(/\s+/g, ' ').toLocaleLowerCase('vi-VN')))
			} catch (error) {
				this.showSnackbar(error?.Message || error?.message || error?.response?.data?.Message || 'Không thể kiểm tra trạng thái giao bài. Vui lòng thử lại.', 'error')
				return new Set()
			}
		},
		isClassInCurrentGrade(row, gradeId) {
			if (!gradeId) return true
			if (row?.KhoiID != null) return Number(row.KhoiID) === gradeId
			const gradeFromName = String(row?.TenLop ?? '').trim().match(/^\d+/)?.[0]
			return gradeFromName ? Number(gradeFromName) === gradeId : false
		},
		async getTeacherAssignedClasses(teacherId) {
			try {
				const schoolYear = this.getCurrentSchoolYear()
				const response = await fetchPromise('/lms/GiaoVienLop_Get_By_GiaoVienID', {
					GiaoVienID: teacherId || this.getCurrentTeacherId(),
					NienKhoa: schoolYear
				}, { cache: false })
				const rows = (Array.isArray(response) ? response : []).flat(Infinity)
				const gradeId = this.getCurrentGradeId()
				return rows.filter(row => (row?.Enable == null || [true, 1, '1'].includes(row.Enable))
					&& (!schoolYear || row?.NienKhoa == null || Number(row.NienKhoa) === schoolYear)
					&& this.isClassInCurrentGrade(row, gradeId))
			} catch (error) {
				this.showSnackbar(error?.Message || error?.message || 'Không thể tải lớp giáo viên phụ trách.', 'error')
				return []
			}
		},
		normalizeClassOptions(items) {
			const rows = (Array.isArray(items) ? items : []).filter(item => item?.LopID != null && String(item?.TenLop ?? '').trim())
			const seenIds = new Set()
			const uniqueRows = rows.filter(item => {
				const id = String(item.LopID)
				if (seenIds.has(id)) return false
				seenIds.add(id)
				return true
			})
			return uniqueRows.map(item => {
				const name = String(item.TenLop).trim().replace(/\s+/g, ' ')
				return {
					...item,
					TenLopDisplay: name
				}
			})
		},
		async loadAssignableClasses(items, assignmentID) {
			const sourceItems = Array.isArray(items) ? items.flat() : []
			const assignedClassNames = await this.getAssignedClassNames(assignmentID, 'LESSON')
			const availableSourceItems = sourceItems.filter(item => !assignedClassNames.has(
				String(item?.TenLop ?? '').trim().replace(/\s+/g, ' ').toLocaleLowerCase('vi-VN')
			))
			const teacherId = availableSourceItems.find(item => item?.GiaoVienID || item?.GiaoVienId)?.GiaoVienID
				|| availableSourceItems.find(item => item?.GiaoVienID || item?.GiaoVienId)?.GiaoVienId
			const teacherClasses = await this.getTeacherAssignedClasses(teacherId)
			const availableTeacherClasses = teacherClasses.filter(item => !assignedClassNames.has(
				String(item?.TenLop ?? '').trim().replace(/\s+/g, ' ').toLocaleLowerCase('vi-VN')
			))
			const candidates = this.normalizeClassOptions([...availableSourceItems, ...availableTeacherClasses])
			const checked = await Promise.all(candidates.map(async item => {
				try {
				const response = await fetchPromise('/lms/HocSinhLop_GetByLopIDList', {
					DSLopID: JSON.stringify([item.LopID]),
					AssignmentID: assignmentID || 0,
				}, { cache: false })
				const students = (Array.isArray(response) ? response : []).flat(Infinity)
				return { item, hasActiveStudents: students.some(student => [true, 1, '1'].includes(student?.Enable)) }
				} catch { return { item, hasActiveStudents: false } }
			}))
			this.classOptions = checked.filter(row => row.hasActiveStudents).map(row => row.item)
		},
		selectedAllClass() {
			if (this.isAllSelected) {
				this.selectedClass = []
			} else {
				this.selectedClass = this.classOptions.map(i => i.LopID)
			}
		},
		handleClickClass(item) {
			if (!this.selectedClass.includes(item.LopID)) {
				this.selectedClass.push(item.LopID)
			} else {
				let indexOfLopID = this.selectedClass.indexOf(item.LopID)
				this.selectedClass.splice(indexOfLopID, 1)
			}
			console.log('this.selectedClass', this.selectedClass)
		},
		// Chế độ per-element không được lưu/đưa cho học sinh nếu chưa có ít nhất một required element và đủ ngưỡng.
		validateCompletionSettings() {
			if (this.lesson?.CompletionPolicy !== 'ALL_REQUIRED') return { isValid: true }
			const elements = this.lesson?.elements || []
			const requiredElements = elements.filter(el => [true, 1, '1'].includes(el.IsRequired));
			if (requiredElements.length === 0) {
				return { isValid: false, message: 'Chế độ theo từng khối cần ít nhất một khối bắt buộc.' }
			}
			const missing = requiredElements.find(el => {
				const seconds = Number(el.RequiredDurationSeconds);
				return !Number.isInteger(seconds) || seconds < 1;
			});
			if (missing) {
				const actualIndex = elements.indexOf(missing) + 1;
				return { isValid: false, message: `Mục số ${actualIndex} cần có thời gian bắt buộc (giây) trước khi lưu chế độ này.` }
			}
			return { isValid: true }
		},
		// Kiểm tra nội dung element trước khi giao; completion settings được kiểm tra riêng để tránh lưu cấu hình dở.
		validateLessonElements() {
			const elements = this.lesson?.elements || []
			if (elements.length === 0) {
				return { isValid: false, message: 'Bài học chưa có nội dung nào. Vui lòng thêm nội dung trước khi giao bài.' }
			}
			const completionValidation = this.validateCompletionSettings();
			if (!completionValidation.isValid) return completionValidation;

			for (let i = 0; i < elements.length; i++) {
				const el = elements[i]
				const type = el.ElementType || ''
				const data = el.ElementData || {}
				const elIndexStr = `Mục số ${i + 1}${data.title ? ` ("${data.title}")` : ''}`

				if (type === 'TEXT') {
					const textContent = String(data.content || '').replace(/<[^>]*>/g, '').trim()
					if (!textContent && !String(data.content || '').trim()) {
						return { isValid: false, message: `${elIndexStr} (Văn bản) chưa có nội dung chữ.` }
					}
				} else if (type === 'IMAGE') {
					if (!Array.isArray(data.sources) || data.sources.length === 0 || !data.sources.some(s => s.source || s.url)) {
						return { isValid: false, message: `${elIndexStr} (Hình ảnh) chưa có ảnh nào được tải lên.` }
					}
				} else if (type === 'YOUTUBE') {
					if (!String(data.source || '').trim()) {
						return { isValid: false, message: `${elIndexStr} (Video) chưa có đường dẫn video.` }
					}
				} else if (type === 'FILE') {
					if (!Array.isArray(data.sources) || data.sources.length === 0 || !data.sources.some(s => s.source || s.url)) {
						return { isValid: false, message: `${elIndexStr} (Tài liệu đính kèm) chưa có tệp tin đính kèm.` }
					}
				} else if (type === 'AUDIO') {
					if (!String(data.source || '').trim()) {
						return { isValid: false, message: `${elIndexStr} (Âm thanh) chưa có file âm thanh hoặc đường dẫn audio.` }
					}
				} else if (type === 'HTML') {
					if (!String(data.source || '').trim()) {
						return { isValid: false, message: `${elIndexStr} (HTML) chưa có nội dung mã HTML.` }
					}
				}
			}

			return { isValid: true }
		},
		openSheetAssignToClass() {
			const validation = this.validateLessonElements()
			if (!validation.isValid) {
				this.showSnackbar(validation.message, 'error')
				return
			}
			this.isOpenSheetAssignToClass = true
		},
		async onAssignToClassAndSave() {
			const validation = this.validateLessonElements()
			if (!validation.isValid) {
				this.showSnackbar(validation.message, 'error')
				return
			}
			if (this.deadlines?.date == null || this.deadlines?.time == null) {
				this.showSnackbar(this.$t('message.PleaseEnterDateTime'), 'error')
				return
			}
			if (this.selectedClass.length == 0) {
				this.showSnackbar(this.$t('message.PleaseSelectAtLeastOneClass'), 'error')
				return
			}
			const d = { date: this.deadlines?.date, time: this.deadlines?.time };
			const due = this.getDue(d);
		try {
			// Phải lưu header + toàn bộ element trước để bài mới có LessonID và dữ liệu không bị mất khi đóng iframe.
			const saveResult = await this.handleSave(true)
			if (!saveResult?.LessonID) return
			const lessonID = saveResult.LessonID

			// Chỉ giao sau khi saveLesson đã hoàn tất; nếu giao trước, bài mới chưa có ID hoặc nội dung chưa tồn tại.
			await Promise.all(this.selectedClass.map(async item => {
				const payload = [{
					LopID: item,
					DueDate: due,
					MaxScore: 0, // thêm nếu cần
					Status: 1,
					ResourceType: "LESSON",
					ResourceID: lessonID
				}]

				await fetchPromise('/lms/EL_Teacher_Lesson_CLASS', {
					AssignmentID: lessonID,
					JsonClassItems: payload
				}, { cache: false })
				console.log('payload----', item, ' nnn--- ', payload)
			}))

			this.showSnackbar(this.$t('message.SaveAndAssignSuccess'), 'success');
			this.isOpenSheetAssignToClass = false
			await new Promise(resolve => setTimeout(resolve, 2000))
			// Chỉ đóng iframe sau khi cả lưu bài và giao lớp đã thành công.
			if (window !== window.top) {
				window.parent.postMessage({ type: 'iframeRef_closeWindow' }, '*')
			} else {
				window.open('/lms-teacher-dashboard', '_parent')
			}
		} catch (error) {
			this.showSnackbar(error?.Message || error?.message || error?.response?.data?.Message || 'Không thể lưu và giao bài. Vui lòng thử lại.', 'error')
		}
		},
		async addElement(elementInfo) {
			const lessonID = this.lesson?.LessonID || vueData.LessonID
			// Khối thêm vào lesson ALL_REQUIRED đã có học sinh không chặn progress cho tới khi giáo viên cấu hình ngưỡng.
			const isRequiredByDefault = !(lessonID && this.lesson?.CompletionPolicy === 'ALL_REQUIRED')
			const newElement = {
				LessonID: lessonID || 0,
				ElementType: elementInfo.type,
				ElementData: JSON.parse(JSON.stringify(elementInfo.defaultData)),
				SortOrder: (this.lesson.elements.length + 1) * 10,
				IsRequired: isRequiredByDefault ? 1 : 0,
				CompletionMode: 'TIME_REQUIRED',
				ExpectedDurationSeconds: null,
				RequiredDurationSeconds: null
			};
			newElement.ExpectedDurationSeconds = this.getExpectedDurationSeconds(newElement);
			// Bài mới chưa có LessonID; giữ element ở local để lần lưu đầu tiên tạo bài rồi mới ghi element.
			if (!lessonID) {
				this.lesson.elements.push(newElement)
				this.selectedElementIndex = this.lesson.elements.length - 1
				return
			}
			try {
				const newElementIndex = this.lesson.elements.length
				await fetchPromise('lms/EL_Element_Save_V2', {
					...newElement,
					ElementID: newElement.ElementID || 0,
					ElementData: JSON.stringify(newElement.ElementData)
				}, { cache: false })
				CALL('getLessonData')
				this.selectedElementIndex = newElementIndex
			} catch (error) { this.showSnackbar(error?.Message || error?.message || 'Không thể thêm nội dung.', 'error') }
			// this.lesson.elements.push(newElement);
		},
		async handleImportDocumentFromContentHub(document) {
			if (!document) return
			const sourceKind = String(document.sourceTracking?.sourceKind || '').toUpperCase()
			const mediaType = String(document.mediaType || '').toLowerCase()
			const declaredType = `${document.contentType || ''} ${document.mediaType || ''} ${document.url || ''} ${document.source || ''}`.toLowerCase()
			const isVideo = document.interactive || sourceKind === 'INTERACTIVE_VIDEO' || /video|youtube|\.mp4|\.webm|\.mov/i.test(declaredType)
			const isAudio = mediaType === 'audio' || /audio|\.mp3|\.wav|\.aac|\.m4a|\.ogg/i.test(declaredType)
			// Ảnh Content Hub phải trở thành block IMAGE; nếu rơi vào FILE thì canvas sẽ mở iframe và không thể hiển thị thumbnail ảnh.
			const isImage = mediaType === 'image' || mediaType === 'hình ảnh' || /image|\.png|\.jpe?g|\.gif|\.webp|\.svg|\.bmp|\.ico/i.test(declaredType)
			const isHtml = Boolean(document.htmlContent || /html/i.test(declaredType))
			const isIspring = Boolean(document.iSpringURL || /ispring|application\/x-ispring/i.test(declaredType))

			let elementType = 'FILE'
			if (isVideo) {
				elementType = 'YOUTUBE'
			} else if (isAudio) {
				elementType = 'AUDIO'
			} else if (isImage) {
				elementType = 'IMAGE'
			} else if (isHtml || isIspring) {
				elementType = 'HTML'
			}

			const htmlSource = document.htmlContent || document.source || document.url || document.externalSource || ''
			const audioSource = document.audioUrl || document.url || document.source || document.externalSource || ''
			const imageSource = document.url || document.source || document.externalSource || ''
			const defaultSource = isHtml ? htmlSource : (isAudio ? audioSource : imageSource)

			const elementData = {
				title: document.name || 'Tài liệu Content Hub',
				source: defaultSource,
				durationSeconds: document.durationSeconds ?? null,
				IsHTML: isHtml && Boolean(document.htmlContent),
				interactive: document.interactive === true,
				interactions: Array.isArray(document.interactions) ? document.interactions : [],
				// IMAGE và FILE cùng lưu danh sách nguồn, nhưng IMAGE được canvas/properties render bằng thẻ ảnh trực tiếp.
				sources: ['FILE', 'IMAGE'].includes(elementType) ? [{
					id: document.id || document.driveFileId || '',
					name: document.name || 'Tài liệu Content Hub',
					source: elementType === 'IMAGE' ? imageSource : (document.source || document.url || document.externalSource || ''),
					externalSource: document.externalSource || '',
					mediaSource: document.mediaSource || 'link',
					caption: ''
				}] : undefined,
				sourceTracking: document.sourceTracking || { sourceType: 'CONTENT_HUB', importedAt: new Date().toISOString() }
			}
			
			const newElement = {
				LessonID: vueData.LessonID || vueData.lesson?.LessonID,
				ElementType: elementType,
				ElementData: elementData,
				SortOrder: (this.lesson.elements.length + 1) * 10,
				// Nội dung import vào bài ALL_REQUIRED đang giao được đánh dấu optional trước, chờ giáo viên cấu hình duration.
				IsRequired: !(this.lesson?.LessonID && this.lesson?.CompletionPolicy === 'ALL_REQUIRED') ? 1 : 0,
				CompletionMode: 'TIME_REQUIRED',
				ExpectedDurationSeconds: null,
				RequiredDurationSeconds: null
			}
			newElement.ExpectedDurationSeconds = this.getExpectedDurationSeconds(newElement);
			
			try {
				const newElementIndex = this.lesson.elements.length
				await fetchPromise('lms/EL_Element_Save_V2', {
					...newElement,
					ElementID: newElement.ElementID || 0,
					ElementData: JSON.stringify(newElement.ElementData)
				}, { cache: false })
				CALL('getLessonData')
				this.selectedElementIndex = newElementIndex
				this.showSnackbar(`Đã import ${document.name} từ Content Hub`, 'success')
			} catch (error) {
				this.showSnackbar(error?.Message || error?.message || 'Không thể import tài liệu từ Content Hub.', 'error')
			}
		},
		updateElements(newElements) {
			this.lesson.elements = newElements;
		},
		updateElement(updatedPayload) {
			const newElements = [...this.lesson.elements];
			if (newElements[updatedPayload.index]) {
				const updatedElement = { ...updatedPayload.element };
				const expectedDuration = this.getExpectedDurationSeconds(updatedElement);
				if (expectedDuration !== null) updatedElement.ExpectedDurationSeconds = expectedDuration;
				newElements[updatedPayload.index] = updatedElement;
				this.updateElements(newElements);
			}
		},
		// Không lưu trước khi xem: truyền bản sao thuần để preview phản ánh chính xác nội dung đang soạn.
		openLessonPreview() {
			let previewLesson
			try {
				previewLesson = JSON.parse(JSON.stringify(this.lesson || { elements: [] }))
			} catch (error) {
				this.showSnackbar('Không thể chuẩn bị nội dung xem trước.', 'error')
				return
			}
			const previewToken = `lesson-${Date.now()}-${Math.random().toString(36).slice(2)}`
			try {
				// GlobalIframeWindow chỉ chuyển title/url/kích thước qua postMessage, nên snapshot được gửi một lần qua sessionStorage.
				window.sessionStorage.setItem(`fui-lesson-preview:${previewToken}`, JSON.stringify(previewLesson))
			} catch (error) {
				this.showSnackbar('Không thể lưu dữ liệu tạm để xem trước bài học.', 'error')
				return
			}
			const payload = {
				id: 'WinLessonPreview',
				title: 'Xem trước bài học',
				url: `/lms-tc-lesson-preview?PreviewToken=${encodeURIComponent(previewToken)}`,
				width: '96%',
				height: '92%'
			}
			if (this.iframeRef?.value?.openWindow) {
				this.iframeRef.value.openWindow(payload)
			} else {
				window.parent.postMessage({ type: 'iframeRef_openWindow', ...payload }, '*')
			}
		},
		async handleSave(isPublishing) {
			// Tính lại trước khi gửi để các thay đổi nội dung trực tiếp trong editor cũng cập nhật thời lượng dự kiến được lưu.
			this.lesson.elements = (this.lesson.elements || []).map(element => {
				const expectedDuration = this.getExpectedDurationSeconds(element);
				return expectedDuration === null ? element : { ...element, ExpectedDurationSeconds: expectedDuration };
			});
			const completionValidation = this.validateCompletionSettings()
			if (!completionValidation.isValid) {
				this.showSnackbar(completionValidation.message, 'error')
				return null
			}
			if (isPublishing) {
				const validation = this.validateLessonElements()
				if (!validation.isValid) {
					this.showSnackbar(validation.message, 'error')
					return
				}
			}
			this.$emit('update:initialLesson', this.lesson);
			try {
				return await this.onSave({ lesson: this.lesson, isPublishing });
			} catch (error) {
				this.showSnackbar(error?.Message || error?.message || error?.response?.data?.Message || 'Không thể lưu bài học. Vui lòng thử lại.', 'error')
				return null
			}
		},
		// ==== Helpers hiển thị ====
		formattedDate(dateStr) {
			return dateStr ? dayjs(dateStr).format("DD/MM/YYYY") : "";
		},
		formattedTime(timeStr) {
			return timeStr ? dayjs(timeStr, "HH:mm").format("HH:mm") : "";
		},
		formatDate(dateStr) {
			if (!dateStr) return '—'
			const d = dayjs(dateStr)
			return d.isValid() ? d.format('DD/MM/YYYY HH:mm') : String(dateStr)
		},
		getDue(d) {
			if (!d.date || !d.time) return null;

			const dateObj = dayjs(d.date); // parse ISO date
			const [hour, minute] = d.time.split(':').map(Number);

			return dateObj
				.hour(hour)
				.minute(minute)
				.second(0)
				.format('YYYY-MM-DD HH:mm:ss');
		},

		openDate() {
			if (!this.deadlines) this.deadlines = { date: null, time: null };
			this.dateDialogVisible = true;
		},

		openTime() {
			if (!this.deadlines) this.deadlines = { date: null, time: null };
			this.timeDialogVisible = true;
		},
	}
	}
</script>