<template>
	<div class="uc-question-ordering">
		<v-alert v-if="guideText" class="mb-2" variant="tonal" type="info" density="comfortable" border="start" border-color="info">
			<strong>{{ $i18n.locale === 'en' ? 'Instruction:' : 'Hướng dẫn:' }}</strong> {{ guideText }}
		</v-alert>

		<p class="text-caption text-medium-emphasis mb-2">
			{{ isInteractionLocked ? 'Thứ tự câu trả lời.' : 'Sắp xếp các ý theo thứ tự đúng bằng nút mũi tên.' }}
		</p>

		<div v-for="(item, index) in orderedItems" :key="item.id" class="ordering-item d-flex align-center ga-2 mb-2 pa-2 rounded border">
			<v-chip size="small" color="primary" variant="tonal" class="ordering-index flex-shrink-0">{{ index + 1 }}</v-chip>
			<div class="ordering-item-content flex-grow-1 min-w-0">
				<uc-latex-view v-model:content="item.text" :literal-html-tags="literalHtmlTags" />
			</div>
			<v-icon v-if="isResultVisible" :color="isCorrectPosition(index) ? 'success' : 'error'" size="20">
				{{ isCorrectPosition(index) ? 'mdi-check-circle' : 'mdi-close-circle' }}
			</v-icon>
			<div v-if="!isInteractionLocked" class="ordering-actions d-flex align-center flex-shrink-0">
				<v-btn icon="mdi-arrow-up" size="small" variant="text" :disabled="index === 0" :aria-label="'Đưa ý ' + (index + 1) + ' lên'" @click="moveItem(index, -1)" />
				<v-btn icon="mdi-arrow-down" size="small" variant="text" :disabled="index === orderedItems.length - 1" :aria-label="'Đưa ý ' + (index + 1) + ' xuống'" @click="moveItem(index, 1)" />
			</div>
		</div>

		<div v-if="isResultVisible" class="mt-2">
			<div class="text-caption text-medium-emphasis">
				{{ $i18n.locale === 'en' ? 'Correct positions' : 'Đúng' }} {{ correctPositionCount }}/{{ correctOrderIds.length }}
			</div>
			<div class="d-flex align-center ga-2 mt-1">
				<strong>{{ $i18n.locale === 'en' ? 'Score' : 'Điểm' }}:</strong>
				<v-chip size="small" :color="scoreChipColor" variant="tonal">
					<v-icon start size="16">mdi-star</v-icon>
					{{ displayScore }} / {{ effectiveMaxPoints }}
				</v-chip>
			</div>
			<!-- Khi đã chấm, hiển thị thứ tự chuẩn để học sinh/giáo viên đối chiếu từng vị trí. -->
			<v-alert v-if="correctPositionCount < correctOrderIds.length" class="mt-2" variant="tonal" type="info" density="comfortable">
				<strong>{{ $i18n.locale === 'en' ? 'Correct order:' : 'Thứ tự đúng:' }}</strong>
				<ol class="mb-0 mt-1 ps-5">
					<li v-for="item in correctOrderItems" :key="'correct-' + item.id">
						<uc-latex-view v-model:content="item.text" :literal-html-tags="literalHtmlTags" />
					</li>
				</ol>
			</v-alert>
		</div>

		<!-- Khi chấm bài, answer rỗng phải được xem là chưa trả lời, không được lấy thứ tự hiển thị để chấm. -->
		<v-alert v-if="isGrade && Number(submissionstatus) >= 2 && !hasSubmittedOrder" class="my-2" variant="tonal" type="info" density="comfortable">
			{{ $i18n.locale === 'en' ? 'The student did not answer this question.' : 'Học sinh chưa sắp xếp đáp án.' }}
		</v-alert>

		<!-- Quiz tự động chấm vẫn có trạng thái chờ khi bài đã nộp nhưng chưa được trả điểm. -->
		<v-alert v-if="!isGrade && Number(submissionstatus) >= 2 && Number(submissionstatus) !== 4" class="my-2" variant="tonal" type="warning" density="comfortable">
			{{ $i18n.locale === 'en' ? 'WAITING FOR GRADING' : 'ĐANG CHỜ CHẤM' }}
		</v-alert>

		<!-- Đồng bộ với các component question base: học sinh xem nhận xét GV sau khi bài được trả. -->
		<v-alert v-if="Number(submissionstatus) === 4 && !isGrade && (grading?.teacherComment || '').trim().length > 0" border="start" color="info"
			elevation="2" class="mt-2" icon="mdi-comment-quote-outline">
			<strong>{{ $i18n.locale === 'en' ? 'Teacher feedback:' : 'Nhận xét GV:' }}</strong> {{ grading.teacherComment }}
		</v-alert>

		<div class="mt-2">
			<div class="text-end" v-if="!isGrade && submissionstatus < 2 && isShowBtnComment">
				<v-menu v-model="menu" :close-on-content-click="false" scroll-strategy="close" location="start">
					<template #activator="{ props: menuProps }">
						<v-tooltip location="top">
							<template #activator="{ props: tooltipProps }">
								<v-btn v-bind="{ ...menuProps, ...tooltipProps }" icon="mdi-notebook-edit-outline" size="small" variant="text" color="primary" />
							</template>
							<span>Ý kiến của bạn</span>
						</v-tooltip>
					</template>
					<v-card :min-width="widthScreen < 650 ? null : 600" variant="outlined" class="elevation-0">
						<v-card-title class="px-4 py-3">Ý kiến của bạn</v-card-title>
						<v-list>
							<v-list-item>
								<v-textarea :model-value="grading?.comment || ''" @update:model-value="onStudentCommentInput" rows="2" hide-details variant="outlined" placeholder="Nhập ý kiến của bạn" />
							</v-list-item>
						</v-list>
						<v-card-actions class="border-t py-0">
							<v-spacer />
							<v-btn variant="text" color="primary" @click="menu = false">Đóng</v-btn>
						</v-card-actions>
					</v-card>
				</v-menu>
			</div>
			<div v-else-if="grading?.comment" class="pa-2 rounded bg-blue-lighten-1">
				<b><v-icon class="mr-1" size="18">mdi-message-text-outline</v-icon>Ý kiến:</b>
				<div class="mt-1">{{ grading.comment }}</div>
			</div>
		</div>

		<div v-if="isGrade" class="mt-2">
			<v-textarea :model-value="grading?.teacherComment || ''" @update:model-value="updateTeacherComment" :label="$t('message.TeacherCommentOptional')" rows="2" outlined dense hide-details />
		</div>
	</div>
</template>

<script>
	export default {
		props: {
			question: { type: Object, required: true },
			answer: { type: Array, default: function() { return [] } },
			readonly: { type: Boolean, default: false },
			grading: { type: Object, default: function() { return {} } },
			isGrade: { type: Boolean, default: false },
			submissionstatus: { type: [Number, String], default: -1 },
			isShowBtnComment: { type: Boolean, default: true },
			literalHtmlTags: { type: Boolean, default: false },
		},
		emits: ['answer-change', 'grading-change'],
		data() {
			return {
				orderedItems: [],
				menu: false,
				widthScreen: 0,
			}
		},
		computed: {
			guideText() {
				return this.question?.config?.submissionNote || this.question?.config?.instruction || ''
			},
			isInteractionLocked() {
				return this.readonly || this.isGrade || this.submissionstatus >= 2
			},
			isResultVisible() {
				return this.isGrade || Number(this.submissionstatus) === 4
			},
			correctOrderIds() {
				const items = Array.isArray(this.question?.config?.items) ? this.question.config.items : []
				const itemIds = items.map(item => String(item?.id ?? ''))
				const sourceOrder = Array.isArray(this.question?.config?.correctOrder) && this.question.config.correctOrder.length
					? this.question.config.correctOrder
					: itemIds
				const resolved = sourceOrder.map(value => {
					const raw = value && typeof value === 'object' ? (value.id ?? value.value) : value
					if (itemIds.includes(String(raw))) return String(raw)
					const index = Number(raw)
					return Number.isInteger(index) && itemIds[index] ? itemIds[index] : null
				}).filter(Boolean)
				const missing = itemIds.filter(id => !resolved.includes(id))
				return [...resolved, ...missing]
			},
			correctPositionCount() {
				return this.submittedOrderIds.reduce((count, id, index) => count + (this.isCorrectPosition(index) ? 1 : 0), 0)
			},
			submittedOrderIds() {
				const itemIds = new Set((this.question?.config?.items || []).map(item => String(item?.id ?? '')))
				return Array.isArray(this.answer)
					? this.answer.map(value => String(value?.id ?? value)).filter(id => itemIds.has(id))
					: []
			},
			hasSubmittedOrder() {
				return this.submittedOrderIds.length > 0
			},
			correctOrderItems() {
				const itemById = new Map(this.orderedItems.map(item => [String(item.id), item]))
				return this.correctOrderIds.map(id => itemById.get(String(id))).filter(Boolean)
			},
			// Quiz ordering chia đều tổng điểm cho từng vị trí đúng và làm tròn ở bước lưu/hiển thị.
			calculatedScore() {
				if (!this.correctOrderIds.length || !this.effectiveMaxPoints) return 0
				return Math.round((this.correctPositionCount / this.correctOrderIds.length) * this.effectiveMaxPoints * 100) / 100
			},
			displayScore() {
				const manual = this.grading?.manualScore
				const auto = typeof this.grading?.autoScore === 'number'
					? this.grading.autoScore
					: (Number(this.submissionstatus) === 4 ? this.calculatedScore : 0)
				// Giữ cùng quy tắc với các quiz base: khi học sinh đã được trả bài,
				// autoScore dương không bị manualScore rỗng/0 che mất.
				if (!this.isGrade && Number(this.submissionstatus) === 4 && auto > 0 &&
					(typeof manual !== 'number' || manual <= 0)) return auto
				return typeof manual === 'number' ? manual : (typeof auto === 'number' ? auto : 0)
			},
			effectiveMaxPoints() {
				return Number(this.question?.points ?? 0) || 0
			},
			scoreChipColor() {
				const score = this.displayScore
				if (score <= 0) return 'error'
				if (this.effectiveMaxPoints && score >= this.effectiveMaxPoints) return 'success'
				return 'primary'
			},
		},
		mounted() {
			this.syncItems()
			this.widthScreen = window.innerWidth
			window.addEventListener('resize', this.handleResize)
			if (this.isGrade) this.emitAutoGrade()
		},
		beforeUnmount() {
			window.removeEventListener('resize', this.handleResize)
		},
		watch: {
			answer: { deep: true, handler() { this.syncItems(); if (this.isGrade) this.emitAutoGrade() } },
			question: { deep: true, handler() { this.syncItems(); if (this.isGrade) this.emitAutoGrade() } },
			isGrade(value) { if (value) this.emitAutoGrade() },
		},
		methods: {
			handleResize() {
				this.widthScreen = window.innerWidth
			},
			textValue(value) {
				if (value === null || value === undefined) return ''
				if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') return String(value)
				if (Array.isArray(value)) return value.map(item => this.textValue(item)).filter(Boolean).join(' ')
				if (typeof value === 'object') return this.textValue(value.html ?? value.content ?? value.text ?? value.label ?? value.value ?? '')
				return ''
			},
			// Giữ thứ tự học sinh đã chọn khi parent restore answer; các item mới thêm sẽ nối vào cuối.
			syncItems() {
				const source = Array.isArray(this.question?.config?.items) ? this.question.config.items : []
				const items = source.map((item, index) => ({
					id: String(item?.id ?? ('ordering_' + (index + 1))),
					text: this.textValue(item?.text ?? item?.label ?? item?.content ?? item),
				}))
				const byId = new Map(items.map(item => [item.id, item]))
				const answerIds = Array.isArray(this.answer) ? this.answer.map(value => String(value?.id ?? value)).filter(id => byId.has(id)) : []
				const orderedIds = answerIds.length ? answerIds : items.map(item => item.id)
				const missingIds = items.map(item => item.id).filter(id => !orderedIds.includes(id))
				this.orderedItems = [...orderedIds, ...missingIds].map(id => byId.get(id)).filter(Boolean)
			},
			moveItem(index, direction) {
				if (this.isInteractionLocked) return
				const targetIndex = index + direction
				if (index < 0 || targetIndex < 0 || targetIndex >= this.orderedItems.length) return
				const moved = this.orderedItems.splice(index, 1)[0]
				this.orderedItems.splice(targetIndex, 0, moved)
				this.$emit('answer-change', this.orderedItems.map(item => item.id))
			},
			// Trang chấm dùng autoScore; không ghi đè manualScore đã có nguồn teacher_regrade.
			emitAutoGrade() {
				this.$emit('grading-change', { ...(this.grading || {}), autoScore: this.calculatedScore })
			},
			isCorrectPosition(index) {
			return String(this.submittedOrderIds[index] ?? '') === String(this.correctOrderIds[index] ?? '')
			},
			onStudentCommentInput(value) {
				this.$emit('grading-change', { ...(this.grading || {}), comment: value })
			},
			updateTeacherComment(value) {
				this.$emit('grading-change', { ...(this.grading || {}), teacherComment: value })
			},
		},
	}
</script>

<style scoped>
.uc-question-ordering {
	width: 100%;
}

.uc-question-ordering .ordering-item {
	min-height: 48px;
	background-color: rgba(248, 250, 252, 0.8);
}

.uc-question-ordering .ordering-item-content {
	min-width: 0;
}

.uc-question-ordering .ordering-index {
	min-width: 28px;
	justify-content: center;
}
</style>