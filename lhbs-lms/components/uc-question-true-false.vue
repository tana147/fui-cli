<template>
	<div>
		<!-- (2.1) Hướng dẫn -->
		<v-alert v-if="guideText" class="mb-3" variant="tonal" type="info" density="comfortable" border="start"
			border-color="info">
			<strong>Hướng dẫn:</strong> {{ guideText }}
		</v-alert>

		<v-radio-group :model-value="normalizedAnswer" @update:model-value="$emit('answer-change', $event)" :readonly="readonly"
			hide-details>
			<v-radio v-for="(option, index) in options" :key="index" :value="option.value" class="mb-2">
				<template #label>
					<div class="d-flex align-center justify-space-between w-100 ga-2">
						<uc-latex-view :class="getOptionTextClass(option.value)" :literal-html-tags="literalHtmlTags"
							v-model:content="option.text" />
						<div v-if="isGraded || submissionstatus == 4" class="feedback-icon ">
							<!-- API cũ có thể trả đáp án dưới dạng chuỗi hoặc 0/1; chỉ hiện đáp án đúng sau khi đã chuẩn hóa. -->
							<v-icon v-if="isSelected(option.value) && isCorrect" color="success">mdi-check</v-icon>
							<v-icon v-if="isSelected(option.value) && !isCorrect" color="error">mdi-close</v-icon>
							<v-icon v-if="!isSelected(option.value) && correctAnswer === option.value" color="success"
								style="opacity:.7">mdi-check</v-icon>
							<v-icon v-if="!isSelected(option.value) && correctAnswer !== null && correctAnswer !== option.value" color="error"
								style="opacity:.7">mdi-close</v-icon>
						</div>
					</div>
				</template>
			</v-radio>
		</v-radio-group>

		<!-- (4) Ý kiến học sinh -->
		<div class="mt-3">
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
			<div v-else-if="grading?.comment" class="pa-3 rounded bg-blue-lighten-1">
				<b>
					<v-icon class="mr-1" size="18">mdi-message-text-outline</v-icon> <span v-if="$i18n.locale =='en'&& isGrade">
						Student's Feedback
					</span>
					<span v-else-if="$i18n.locale !='en'&& isGrade">Ý kiến {{ isGrade ? 'học sinh' : 'bạn' }}:</span>
				</b>
				<div class="mt-1">{{ grading.comment }}</div>
			</div>
		</div>

		<div v-if="isGrade && submissionstatus >= 2 && answer === null"
			class="student-answer-panel rounded bg-indigo-lighten-5 pa-3">
			<i class="text-red">{{ isGrade ? 'Học sinh' : 'Bạn' }} không chọn đáp án.</i>
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
		<v-alert v-if="submissionstatus == 4 && !isGrade && grading?.teacherComment" border="start" color="info"
			elevation="2" class="mt-2" icon="mdi-comment-quote-outline">
			<strong>Nhận xét GV:</strong> {{ grading.teacherComment }}
		</v-alert>

		<!-- ĐANG CHỜ CHẤM -->
		<v-alert v-if="!isGrade && submissionstatus >= 2 && submissionstatus !== 4" class="my-3" variant="tonal"
			type="warning" density="comfortable">
			ĐANG CHỜ CHẤM
		</v-alert>

		<!-- GV -->
		<div class="mt-4" v-if="isGrade">
			<v-textarea :model-value="grading?.teacherComment || ''" @update:model-value="updateTeacherComment"
				:label="$t('message.TeacherCommentOptional')" rows="2" outlined dense hide-details />
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-question-true-false',
	props: {
		question: { type: Object, required: true },
		answer: { default: null },
		readonly: { type: Boolean, default: false },
		grading: { type: Object, default: null },
		isGrade: { type: Boolean, default: false },
		submissionstatus: { type: Number, default: -1 },
		isShowBtnComment: { type: Boolean, default: true },
		literalHtmlTags: { type: Boolean, default: false }
	},
	emits: ['answer-change', 'grading-change'],
	data() { 
		this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
		return { menu: false, widthScreen: null }; },
	computed: {
		isGraded() { return this.grading && this.isGrade; },
		// Chuẩn hóa dữ liệu từ API để boolean thật, chuỗi "true/false" và 0/1 cho cùng kết quả hiển thị.
		normalizedAnswer() { return this.normalizeBooleanValue(this.answer); },
		correctAnswer() { return this.normalizeBooleanValue(this.question?.config?.correctAnswer); },
		isCorrect() {
			return this.normalizedAnswer !== null && this.correctAnswer !== null && this.normalizedAnswer === this.correctAnswer;
		},
		options() { return [{ text: 'Đúng', value: true }, { text: 'Sai', value: false }]; },
		guideText() { return this.question?.config?.submissionNote || this.question?.config?.instruction || '' },
		displayScore() {
			const manual = this.grading?.manualScore;
			const auto = typeof this.grading?.autoScore === 'number'
				? this.grading.autoScore
				: (this.submissionstatus === 4 && this.isCorrect ? Number(this.question?.points ?? 0) : 0);
			if (!this.isGrade && this.submissionstatus === 4 && typeof auto === 'number' && auto > 0 &&
				(typeof manual !== 'number' || manual <= 0)) return auto;
			return typeof manual === 'number' ? manual : (typeof auto === 'number' ? auto : 0);
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
		}
	},
	mounted() {
		if (this.isGrade) {
			const score = this.isCorrect ? this.question.points : 0
			this.$emit('grading-change', { ...this.grading, manualScore: score });
		}
		this.widthScreen = window.innerWidth
		window.addEventListener('resize', () => { this.handleResize() })
	},
	methods: {
		// Đáp án True/False đi qua nhiều nguồn dữ liệu nên có thể bị đổi kiểu; giá trị lạ trả null để không đánh dấu nhầm.
		normalizeBooleanValue(value) {
			if (value === true || value === 1) return true;
			if (value === false || value === 0) return false;
			if (value && typeof value === 'object') {
				if (Object.prototype.hasOwnProperty.call(value, 'value')) return this.normalizeBooleanValue(value.value);
				if (Object.prototype.hasOwnProperty.call(value, 'isTrue')) return this.normalizeBooleanValue(value.isTrue);
			}
			if (typeof value !== 'string') return null;
			const normalized = value.trim().toLowerCase();
			if (['true', '1', 'đúng', 'dung', 'yes', 'y'].includes(normalized)) return true;
			if (['false', '0', 'sai', 'no', 'n'].includes(normalized)) return false;
			return null;
		},
		handleResize() {
			this.widthScreen = window.innerWidth;
		},
		isSelected(v) { return this.normalizedAnswer === v },
		getOptionTextClass(v) {
			if (!this.isGraded) return this.isSelected(v) ? 'font-weight-bold' : '';
			const sel = this.isSelected(v), ok = (this.correctAnswer === v);
			if (sel) return 'font-weight-bold'; if (ok) return 'font-italic correct-answer-hint'; return 'text-disabled';
		},
		onStudentCommentInput(val) {
			this.grading.comment = val
			this.$emit('grading-change', { ...this.grading, comment: val })
		},
		updateTeacherComment(val) { this.$emit('grading-change', { ...this.grading, teacherComment: val }); }
	}
	}
</script>

<style scoped>
.correct-answer-hint {
	font-style: italic;
	color: green;
}

.text-disabled {
	color: grey;
}
</style>