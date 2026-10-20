<template>
	<div>
		<!-- (2.1) Hướng dẫn -->
		<v-alert v-if="guideText" class="mb-2" variant="tonal" type="info" density="comfortable" border="start"
			border-color="info">
			<strong>Hướng dẫn:</strong> {{ guideText }}
		</v-alert>
		<!-- Đáp án tham khảo là dữ liệu dành riêng cho giáo viên; không render ở chế độ học sinh. -->
		<v-alert v-if="isGrade && referenceAnswer" class="mb-2" variant="tonal" type="success" density="comfortable"
			border="start" border-color="success">
			<strong>Đáp án tham khảo:</strong>
			<uc-latex-view :content="referenceAnswer" :escape-html="literalHtmlTags"
				:literal-html-tags="literalHtmlTags" :preserve-html-structure="literalHtmlTags" />
		</v-alert>
		<v-textarea v-if="submissionstatus < 2" :model-value="answer"
			@update:model-value="$emit('answer-change', $event)"
			:label="!isGrade ? 'Nhập câu trả lời của bạn' : 'Câu trả lời của học sinh'" rows="3" outlined
			:readonly="readonly || isGrade" hide-details class="mt-2" @copy="handleCopyPaste" @cut="handleCopyPaste"
			@paste="handleCopyPaste" @contextmenu="handleContextMenu" />

		<!-- (3) Câu trả lời HS -->
			<div v-if="submissionstatus >= 2" class="d-flex flex-column my-2 pa-3 rounded"
				style="background-color:#FAFAFA; border:1px solid #E0E0E0;">
				<div class="d-flex align-center mb-2" style="color:#424242; font-weight:600;">
					<v-icon size="18" class="mr-1" color="#616161">
						mdi-account
					</v-icon>
					Câu trả lời của {{ isGrade ? 'học sinh' : 'bạn' }}:
				</div>
			
				<!-- Giáo viên có thể chọn vùng text; học sinh chỉ xem highlight đã lưu. -->
				<div v-if="isGrade || annotations.length" ref="shortAnswerReview" class="short-answer-review"
					@mouseup="captureTextSelection" @click="handleAnswerReviewClick">
					<uc-latex-view v-if="answer && answer.length > 0" :content="answer"
						:escape-html="literalHtmlTags" :literal-html-tags="literalHtmlTags"
						:preserve-html-structure="literalHtmlTags" />
					<span v-else class="text-medium-emphasis">
						Không nhập câu trả lời
					</span>
				</div>
				<uc-latex-view v-else-if="answer && answer.length > 0" :content="answer"
					:escape-html="literalHtmlTags" :literal-html-tags="literalHtmlTags"
					:preserve-html-structure="literalHtmlTags" />
				<span v-else class="text-medium-emphasis">
					Không nhập câu trả lời
				</span>

				<!-- Nút này chỉ xuất hiện sau khi giáo viên bôi chọn một đoạn văn bản. -->
				<div v-if="isGrade && pendingSelection.text" class="d-flex align-center flex-wrap ga-2 mt-2">
					<span class="text-caption text-medium-emphasis text-truncate">
						Đã chọn: “{{ pendingSelection.text }}”
					</span>
					<v-btn color="primary" variant="tonal" size="small" @mousedown.prevent @click="openAnnotationDialog">
						<v-icon start>mdi-comment-plus-outline</v-icon>
						Thêm ghi chú
					</v-btn>
				</div>

				<!-- Giáo viên có thể sửa/xoá; học sinh chỉ xem highlight và nội dung nhận xét đã lưu. -->
				<div v-if="annotations.length" class="mt-2">
					<div class="text-subtitle-2 font-weight-medium mb-1">
						{{ isGrade ? 'Ghi chú theo vùng văn bản' : 'Nhận xét theo vùng văn bản' }}
					</div>
					<v-list density="compact" border rounded>
						<v-list-item v-for="annotation in annotations" :key="annotation.id" class="px-2"
							@click="isGrade && editAnnotation(annotation)">
							<template #prepend>
								<v-icon color="amber-darken-2">mdi-marker</v-icon>
							</template>
							<v-list-item-title class="text-body-2 text-wrap">{{ annotation.text }}</v-list-item-title>
							<v-list-item-subtitle class="text-wrap">{{ annotation.note }}</v-list-item-subtitle>
							<template #append v-if="isGrade">
								<v-btn icon variant="text" aria-label="Xoá ghi chú"
									@click.stop="removeAnnotation(annotation)">
									<v-icon>mdi-delete-outline</v-icon>
								</v-btn>
							</template>
						</v-list-item>
					</v-list>
				</div>
			</div>
		<!-- (4) Ý kiến học sinh -->
		<div class="mt-2">
			<div class="text-end" v-if="!isGrade && submissionstatus < 2 && isShowBtnComment">
				<v-menu v-model="menu" :close-on-content-click="false" scroll-strategy="close" location="start">
					<template #activator="{ props: menuProps }">
						<v-tooltip location="top">
							<template #activator="{ props: tooltipProps }">
								<v-btn v-bind="{ ...menuProps, ...tooltipProps }" icon="mdi-notebook-edit-outline" size="small"
									variant="text" color="primary" />
							</template>
							<span>Ý kiến của bạn</span>
						</v-tooltip>
					</template>
					<v-card :min-width="widthScreen < 650 ? null : 600" variant="outlined" class="elevation-0">
						<v-card-title class="px-4 py-3" style="background-color:#E3F2FD; color:#1565C0; font-weight:600;">
							Ý kiến của bạn
						</v-card-title>
						<v-list>
							<v-list-item>
								<v-textarea :model-value="grading?.comment || ''" @update:model-value="onStudentCommentInput" rows="2"
									hide-details variant="outlined" placeholder="Nhập ý kiến của bạn" />
							</v-list-item>
						</v-list>
						<v-card-actions class="border-t py-0">
							<v-spacer />
							<v-btn variant="text" color="primary" @click="menu = false">
								Đóng
							</v-btn>
						</v-card-actions>
					</v-card>
				</v-menu>
			</div>
			<div v-else-if="grading?.comment" class="pa-2 rounded bg-blue-lighten-1">
				<b>
					<v-icon class="mr-1" size="18">mdi-message-text-outline</v-icon>
					<span v-if="$i18n.locale =='en'&& isGrade">
						Student's Feedback
					</span>
					<span v-else-if="$i18n.locale !='en'&& isGrade">Ý kiến {{ isGrade ? 'học sinh' : 'bạn' }}:</span>
				</b>
				<div class="mt-1">{{ grading.comment }}</div>
			</div>
		</div>

		<!-- (5) Điểm -->
		<!-- Điểm câu – hiển thị khi đã trả bài (status == 4) -->
		<div v-if="submissionstatus == 4" class="mt-2">
			<strong>{{$i18n.locale == 'en' ? 'Score':'Điểm' }}:</strong>
			<v-chip size="small" :color="scoreChipColor" variant="tonal">
				<v-icon start size="16">mdi-star</v-icon>
				{{ displayScore }} / {{ effectiveMaxPoints }}
			</v-chip>
		</div>

		<!-- (6) Nhận xét GV -->
		<v-alert v-if="submissionstatus == 4 && grading?.teacherComment && !isGrade" border="start" color="info"
			elevation="2" class="mt-2" icon="mdi-comment-quote-outline">
			<strong>Nhận xét GV:</strong> {{ grading.teacherComment || '-' }}
		</v-alert>

		<!-- ĐANG CHỜ CHẤM -->
		<v-alert v-if="!isGrade && submissionstatus >= 2 && submissionstatus !== 4" class="my-2" variant="tonal"
			type="warning" density="comfortable">
			ĐANG CHỜ CHẤM
		</v-alert>

		<!-- GV -->
		<div class="mt-2 teacher-grading-area" v-if="isGrade">
			<div class="d-flex align-center mb-2" v-if="submissionstatus == 2 || submissionstatus == 3">
				<v-number-input :model-value="grading ? grading.manualScore : 0"
					@update:modelValue="val => { grading.manualScore = val;}" label="Điểm" :max="question.points"
					:min="0" variant="outlined" density="compact" hide-details style="max-width: 100px;"
					@blur="submitPoints" control-variant="hidden" inset />
				<span class="text-h6 ml-2 text-primary"> / {{ question.points }}</span>
				<span class="ml-1 text-caption">điểm</span>
			</div>
			<v-textarea :model-value="grading ? grading.teacherComment : ''" @update:modelValue="updateTeacherComment"
				:label="$t('message.TeacherCommentOptional')" rows="2" outlined dense hide-details />
		</div>

		<v-dialog v-model="annotationDialog" max-width="600">
			<v-card>
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3 subtitle-1 font-weight-bold">
					{{ editingAnnotationId ? 'Sửa ghi chú vùng văn bản' : 'Thêm ghi chú vùng văn bản' }}
					<v-spacer />
					<v-btn icon variant="text" aria-label="Đóng" @click="closeAnnotationDialog">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-1">
					<v-alert variant="tonal" color="warning" class="mb-3">
						<strong>Đoạn đã chọn:</strong> {{ annotationDraftText }}
					</v-alert>
					<v-textarea v-model="annotationDraftNote" label="Ghi chú của giáo viên"
						placeholder="Nhập nhận xét cho đoạn văn này..." rows="3" variant="outlined"
						auto-grow hide-details />
				</v-card-text>
				<v-card-actions class="pa-3">
					<v-spacer />
					<v-btn variant="text" @click="closeAnnotationDialog">Huỷ</v-btn>
					<v-btn color="primary" elevation="0" @click="saveAnnotation">Lưu ghi chú</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-question-short-answer',
		props: {
			question: Object,
			answer: String,
			readonly: { type: Boolean, default: false },
			grading: Object,
			isGrade: { type: Boolean, default: false },
			submissionstatus: { type: Number, default: -1 },
			isShowBtnComment: { type: Boolean, default: true },
				isBlockCopyPaste: {
					type: Boolean,
					default: false
				},
				literalHtmlTags: { type: Boolean, default: false }
		},
		emits: ['answer-change', 'grading-change'],
		data() {
			this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
			return {
				menu: false,
				widthScreen: null,
				annotationDialog: false,
				annotationDraftNote: '',
				annotationDraftText: '',
				editingAnnotationId: null,
				pendingSelection: { text: '', start: 0, end: 0 }
			}
		},
		computed: {
			guideText() { return this.question?.config?.submissionNote || this.question?.config?.instruction || '' },
			referenceAnswer() {
				return this.question?.config?.referenceAnswer
					|| this.question?.content?.referenceAnswer
					|| this.question?.referenceAnswer
					|| '';
			},
			displayScore() {
				// Ưu tiên manualScore, rồi autoScore, nếu trống thì mặc định 0
				const s = this.grading?.manualScore ?? this.grading?.autoScore ?? 0;
				return typeof s === 'number' ? s : 0;
			},
			effectiveMaxPoints() {
				return this.question?.points ?? 0;
			},
				scoreChipColor() {
				const s = this.displayScore;
				const max = this.effectiveMaxPoints;
				if (s <= 0) return 'error';
				if (max && s >= max) return 'success';
				return 'primary'; // điểm trung gian
			},
			annotations() {
				return Array.isArray(this.grading?.textAnnotations) ? this.grading.textAnnotations : [];
			}
		},
		mounted() {
			this.widthScreen = window.innerWidth
			window.addEventListener('resize', () => { this.handleResize() })
			// Theo dõi selection toàn trang để xoá thanh hành động khi giáo viên
			// click bỏ chọn; dialog đang mở thì phải giữ pendingSelection để lưu note.
			this._selectionChangeHandler = this.handleDocumentSelectionChange.bind(this)
			document.addEventListener('selectionchange', this._selectionChangeHandler)
			this.scheduleAnnotationRender()
		},
		beforeUnmount() {
			if (this._selectionChangeHandler) {
				document.removeEventListener('selectionchange', this._selectionChangeHandler)
			}
		},
		methods: {
			clearPendingSelection() {
				if (!this.pendingSelection.text) return;
				this.pendingSelection = { text: '', start: 0, end: 0 };
			},
			handleDocumentSelectionChange() {
				// Không xoá selection khi hộp thoại đang mở vì nút Lưu vẫn cần dùng
				// pendingSelection để tạo ghi chú mới.
				if (this.annotationDialog) return;
				const selection = window.getSelection();
				if (!selection || selection.isCollapsed || !selection.toString().trim()) {
					this.clearPendingSelection();
				}
			},
			captureTextSelection() {
				if (!this.isGrade) return;
				const selection = window.getSelection();
				const root = this.$refs.shortAnswerReview;
				if (!selection || !selection.rangeCount || !root) return;
				const range = selection.getRangeAt(0);
				if (!root.contains(range.commonAncestorContainer)) return;
				const rawText = selection.toString();
				const selectedText = rawText.trim();
				if (!selectedText) return;
				let start = this.getSelectionBoundaryOffset(root, range.startContainer, range.startOffset);
				const leadingWhitespace = rawText.indexOf(selectedText);
				if (leadingWhitespace > 0) start += leadingWhitespace;
				this.pendingSelection = {
					text: selectedText,
					start,
					end: start + selectedText.length
				};
			},
			getSelectionBoundaryOffset(root, node, offset) {
				const boundary = document.createRange();
				boundary.selectNodeContents(root);
				boundary.setEnd(node, offset);
				return boundary.toString().length;
			},
			// uc-latex-view đổi xuống dòng thành <br>; chuỗi này phải tính cả <br>
			// để offset khi chọn text khớp với offset lúc dựng lại highlight.
			getLinearText(root) {
				const walker = document.createTreeWalker(root, window.NodeFilter.SHOW_ALL);
				let text = '';
				let currentNode = walker.nextNode();
				while (currentNode) {
					if (currentNode.nodeType === 3) text += currentNode.nodeValue;
					else if (currentNode.nodeType === 1 && currentNode.tagName === 'BR') text += '\n';
					currentNode = walker.nextNode();
				}
				return text;
			},
			// Khi dữ liệu cũ đã mất/thêm ký tự xuống dòng, chuẩn hoá khoảng trắng để
			// vẫn tìm được đúng đoạn ghi chú thay vì bỏ qua highlight.
			normalizeTextWithMap(value) {
				const normalizedChars = [];
				const startMap = [];
				const endMap = [];
				let inWhitespace = false;
				const text = String(value || '');
				for (let index = 0; index < text.length; index++) {
					if (/\s/.test(text[index])) {
						if (normalizedChars.length && !inWhitespace) {
							normalizedChars.push(' ');
							startMap.push(index);
							endMap.push(index + 1);
						}
						inWhitespace = true;
						continue;
					}
					normalizedChars.push(text[index]);
					startMap.push(index);
					endMap.push(index + 1);
					inWhitespace = false;
				}
				if (normalizedChars[normalizedChars.length - 1] === ' ') {
					normalizedChars.pop();
					startMap.pop();
					endMap.pop();
				}
				return { text: normalizedChars.join(''), startMap, endMap };
			},
			findAnnotationRange(rootText, annotation) {
				const text = String(annotation.text || '');
				let preferredStart = Number(annotation.start);
				if (Number.isFinite(preferredStart) && rootText.slice(preferredStart, preferredStart + text.length) === text) {
					return { start: preferredStart, end: preferredStart + text.length };
				}
				const exactStart = rootText.indexOf(text);
				if (exactStart >= 0) return { start: exactStart, end: exactStart + text.length };

				const normalizedRoot = this.normalizeTextWithMap(rootText);
				const normalizedAnnotation = this.normalizeTextWithMap(text).text;
				if (!normalizedAnnotation) return null;
				let searchFrom = 0;
				let bestMatch = null;
				let matchStart = normalizedRoot.text.indexOf(normalizedAnnotation, searchFrom);
				while (matchStart >= 0) {
					const originalStart = normalizedRoot.startMap[matchStart];
					const lastMatchIndex = matchStart + normalizedAnnotation.length - 1;
					const originalEnd = normalizedRoot.endMap[lastMatchIndex];
					const distance = Number.isFinite(preferredStart) ? Math.abs(originalStart - preferredStart) : 0;
					if (!bestMatch || distance < bestMatch.distance) bestMatch = { start: originalStart, end: originalEnd, distance };
					searchFrom = matchStart + 1;
					matchStart = normalizedRoot.text.indexOf(normalizedAnnotation, searchFrom);
				}
				return bestMatch ? { start: bestMatch.start, end: bestMatch.end } : null;
			},
			openAnnotationDialog() {
				if (!this.pendingSelection.text) return;
				this.annotationDraftText = this.pendingSelection.text;
				this.annotationDraftNote = '';
				this.editingAnnotationId = null;
				this.annotationDialog = true;
			},
			editAnnotation(annotation) {
				this.editingAnnotationId = annotation.id;
				this.annotationDraftText = annotation.text || '';
				this.annotationDraftNote = annotation.note || '';
				this.annotationDialog = true;
			},
			saveAnnotation() {
				const note = String(this.annotationDraftNote || '').trim();
				if (!note) {
					Vue.$toast?.warning('Vui lòng nhập ghi chú cho đoạn văn đã chọn', { position: 'top' });
					return;
				}
				const nextAnnotations = this.annotations.map(annotation => ({ ...annotation }));
				if (this.editingAnnotationId) {
					const index = nextAnnotations.findIndex(annotation => annotation.id === this.editingAnnotationId);
					if (index >= 0) nextAnnotations[index] = { ...nextAnnotations[index], note };
				} else {
					nextAnnotations.push({
						id: 'short-answer-note-' + Date.now() + '-' + Math.random().toString(36).slice(2, 8),
						text: this.pendingSelection.text,
						start: this.pendingSelection.start,
						end: this.pendingSelection.end,
						note
					});
				}
				this.$emit('grading-change', { ...(this.grading || {}), textAnnotations: nextAnnotations });
				this.annotationDialog = false;
				this.annotationDraftNote = '';
				this.editingAnnotationId = null;
				this.clearPendingSelection();
				this.scheduleAnnotationRender();
			},
			closeAnnotationDialog() {
				this.annotationDialog = false;
				this.clearPendingSelection();
			},
			removeAnnotation(annotation) {
				const nextAnnotations = this.annotations.filter(item => item.id !== annotation.id);
				this.$emit('grading-change', { ...(this.grading || {}), textAnnotations: nextAnnotations });
				this.scheduleAnnotationRender();
			},
			handleAnswerReviewClick(event) {
				if (!this.isGrade) return;
				const target = event.target;
				const mark = target && target.closest ? target.closest('[data-short-answer-annotation-id]') : null;
				if (!mark) return;
				const annotation = this.annotations.find(item => item.id === mark.getAttribute('data-short-answer-annotation-id'));
				if (annotation) this.editAnnotation(annotation);
			},
			scheduleAnnotationRender() {
				this.$nextTick(() => this.applyAnnotationHighlights());
			},
			clearAnnotationHighlights(root) {
				const marks = root.querySelectorAll('[data-short-answer-annotation-id]');
				Array.prototype.forEach.call(marks, mark => {
					const parent = mark.parentNode;
					while (mark.firstChild) parent.insertBefore(mark.firstChild, mark);
					parent.removeChild(mark);
				});
				root.normalize();
			},
			// Tách theo từng text node để không tạo <mark> bọc ngoài <p>/<div>.
			// Nếu bọc cả block element, nền highlight có thể không được trình duyệt vẽ.
			getTextNodesWithOffsets(root) {
				const walker = document.createTreeWalker(root, window.NodeFilter.SHOW_ALL);
				const segments = [];
				let totalLength = 0;
				let currentNode = walker.nextNode();
				while (currentNode) {
					if (currentNode.nodeType === 3) {
						const end = totalLength + currentNode.nodeValue.length;
						segments.push({ node: currentNode, start: totalLength, end });
						totalLength = end;
					} else if (currentNode.nodeType === 1 && currentNode.tagName === 'BR') {
						// <br> tương ứng một ký tự xuống dòng trong getLinearText().
						totalLength += 1;
					}
					currentNode = walker.nextNode();
				}
				return segments;
			},
			applyAnnotationHighlights() {
				if (!this.isGrade && !this.annotations.length) return;
				const root = this.$refs.shortAnswerReview;
				if (!root) return;
				this.clearAnnotationHighlights(root);
				const rootText = this.getLinearText(root);
				const sortedAnnotations = this.annotations
					.filter(annotation => annotation && annotation.text)
					.slice()
					.sort((a, b) => Number(a.start || 0) - Number(b.start || 0));
				for (let index = sortedAnnotations.length - 1; index >= 0; index--) {
					const annotation = sortedAnnotations[index];
					const textRange = this.findAnnotationRange(rootText, annotation);
					if (!textRange || textRange.end <= textRange.start) continue;
					const segments = this.getTextNodesWithOffsets(root)
						.filter(segment => segment.end > textRange.start && segment.start < textRange.end);
					// Đi từ cuối về đầu để việc chèn mark không làm mất reference của node
					// chưa xử lý ở phía trước.
					for (let segmentIndex = segments.length - 1; segmentIndex >= 0; segmentIndex--) {
						const segment = segments[segmentIndex];
						const localStart = Math.max(textRange.start, segment.start) - segment.start;
						const localEnd = Math.min(textRange.end, segment.end) - segment.start;
						if (localEnd <= localStart) continue;
						const range = document.createRange();
						range.setStart(segment.node, localStart);
						range.setEnd(segment.node, localEnd);
						const mark = document.createElement('mark');
						mark.className = 'short-answer-annotation-highlight';
						mark.setAttribute('data-short-answer-annotation-id', annotation.id);
						mark.setAttribute('title', annotation.note || 'Ghi chú của giáo viên');
						mark.appendChild(range.extractContents());
						range.insertNode(mark);
					}
				}
			},
			handleResize() {
				this.widthScreen = window.innerWidth;
			},
			onStudentCommentInput(val) {
				this.grading.comment = val
				this.$emit('grading-change', { ...this.grading, comment: val })
			},
			updateTeacherComment(val) { this.$emit('grading-change', { ...this.grading, teacherComment: val }); },
			submitPoints() {
				this.$emit('grading-change', {
					...this.grading,
					manualScore: this.grading.manualScore
				});
			},
			handleCopyPaste(event) {
				if (this.isBlockCopyPaste && !this.readonly) {
					event.preventDefault();
					// Có thể thêm thông báo cho user
					Vue.$toast?.warning('Không được phép sao chép/dán nội dung trong bài này', { position: "top" });
				}
			},
			handleContextMenu(event) {
				if (this.isBlockCopyPaste && !this.readonly) {
					event.preventDefault();
				}
			}
		},
		watch: {
			answer() { this.scheduleAnnotationRender(); },
			grading: { handler() { this.scheduleAnnotationRender(); }, deep: true }
		}
	}
</script>

<style scoped>
.short-answer-annotation-highlight {
	background-color: #fff59d;
	border-bottom: 2px solid #f9a825;
	cursor: pointer;
}
</style>