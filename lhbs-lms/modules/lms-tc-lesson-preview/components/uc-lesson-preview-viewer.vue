<template>
	<div v-if="!initialLesson" class="text-center pa-10 fill-height d-flex flex-column justify-center align-center">
		<v-icon size="64" color="grey-lighten-1">mdi-eye-off-outline</v-icon>
		<h2 class="mt-4 text-h6">Không có dữ liệu xem trước</h2>
		<p class="text-medium-emphasis">Hãy quay lại trình soạn bài và mở xem trước lại.</p>
		<v-btn class="mt-4" variant="outlined" prepend-icon="mdi-close" @click="closePreview">Đóng</v-btn>
	</div>

	<div v-else class="lesson-viewer-container lesson-preview-container">
		<aside class="lesson-sidebar">
			<div class="sidebar-sticky-content">
				<div class="d-flex align-center justify-space-between ga-2 mb-3">
					<div>
						<h3 class="text-subtitle-1 font-weight-bold mb-1">Nội dung bài học</h3>
						<p class="text-caption text-grey-darken-1 mb-0">{{ lessonSubject }}</p>
					</div>
					<v-chip color="primary" variant="tonal" prepend-icon="mdi-eye-outline">Xem trước</v-chip>
				</div>

				<div v-if="initialLesson.EstimatedDuration" class="text-caption text-medium-emphasis mb-3">
					Thời lượng dự kiến: {{ initialLesson.EstimatedDuration }} phút
				</div>

				<ul v-if="tocElements.length" class="lesson-toc">
					<li v-for="element in tocElements" :key="element.id">
						<a href="#" :class="{ 'is-active': activeTocId === element.id }"
							@click.prevent="scrollToElement(element)">
							<span>{{ element.title }}</span>
							<v-icon v-if="isElementCompletionMode && element.required && element.completed"
								size="16" color="success" class="ml-1">mdi-check-circle</v-icon>
							<div v-if="isElementCompletionMode" class="text-caption text-medium-emphasis mt-1">
								{{ element.required ? getElementProgressLabel(element.index) : 'Không bắt buộc' }}
							</div>
						</a>
					</li>
				</ul>
				<p v-else class="text-caption text-medium-emphasis mb-0">Bài học chưa có mục lục.</p>
			</div>
		</aside>

		<main class="lesson-main-content" ref="previewContent">
			<div class="lesson-preview-progress mb-3">
				<div class="d-flex align-center justify-space-between ga-2">
					<v-chip color="primary" variant="tonal" prepend-icon="mdi-eye-outline">Xem thử · mô phỏng</v-chip>
					<span class="text-caption font-weight-bold">{{ Math.round(previewProgressPercent) }}%</span>
				</div>
				<v-progress-linear :model-value="previewProgressPercent" :color="previewIsComplete ? 'success' : 'primary'" height="6" rounded
					aria-label="Tiến độ xem trước" />
				<div class="text-caption text-medium-emphasis mt-1" aria-live="polite">
					{{ previewProgressLabel }}
				</div>
			</div>

			<header class="lesson-header">
				<div class="text-caption text-grey-darken-1 mb-2 sub-title-lesson">
					<span>{{ lessonSubject }}</span>
					<v-icon size="x-small" class="mx-1">mdi-chevron-right</v-icon>
					<span>Bài học</span>
				</div>
				<h1 class="title-lesson font-weight-bold">{{ initialLesson.Title || 'Bài học chưa có tiêu đề' }}</h1>
				<p v-if="initialLesson.Description" class="text-medium-emphasis mt-2 mb-0 sub-title-lesson">
					{{ initialLesson.Description }}
				</p>
			</header>

			<div class="lesson-canvas-container">
				<!-- Chế độ viewer chỉ đọc dùng cùng canvas với trang học sinh; preview không gửi tiến độ học lên server. -->
				<uc-lesson-canvas :elements="initialLesson.elements || []" :is-viewer="true"
					:show-element-progress="isElementCompletionMode"
					:show-expected-duration="true"
					:element-progress-by-index="previewElementProgressByIndex"
					:active-element-index="activeElementIndex"
					:is-sequential="isSequential"
					:first-incomplete-required-index="firstIncompleteRequiredIndex" />
			</div>
		</main>
	</div>
</template>

<script>
	export default {
		props: {
		initialLesson: { type: Object, default: null }
	},
	data() {
		return {
			activeTocId: null,
			previewTimeSpentSeconds: 0,
			previewElementProgressByIndex: {},
			activeElementIndex: -1,
			elementObserver: null,
			progressResizeObserver: null,
			progressInterval: null,
			lastProgressTickAt: 0,
			previewMounted: false
		}
	},
	computed: {
		lessonSubject() {
			return this.initialLesson?.MonHocName || this.initialLesson?.SubjectName || 'Bài học'
		},
		hasLessonContent() {
			return Array.isArray(this.initialLesson?.elements) && this.initialLesson.elements.length > 0
		},
		// Keep the preview on the same policy/version boundary as the student viewer.
		isElementCompletionMode() {
			return this.initialLesson?.CompletionPolicy === 'ALL_REQUIRED'
				&& Number(this.initialLesson?.CompletionVersion) >= 2
		},
		isSequential() {
			return this.isElementCompletionMode && [true, 1, '1'].includes(this.initialLesson?.RequireSequential)
		},
		requiredElements() {
			return (this.initialLesson?.elements || []).filter(element => this.isElementRequired(element))
		},
		totalRequiredCount() {
			return this.requiredElements.length
		},
		completedRequiredCount() {
			return this.requiredElements.filter(element => {
				const index = (this.initialLesson?.elements || []).indexOf(element)
				return this.isElementCompleted(index)
			}).length
		},
		completionDurationSeconds() {
			const durationMinutes = Number(this.initialLesson?.EstimatedDuration)
			return (Number.isFinite(durationMinutes) && durationMinutes >= 1 ? durationMinutes : 3) * 60
		},
		previewProgressPercent() {
			if (!this.hasLessonContent) return 0
			if (this.isElementCompletionMode) {
				return this.totalRequiredCount > 0 ? (this.completedRequiredCount * 100) / this.totalRequiredCount : 0
			}
			return Math.min(100, (this.previewTimeSpentSeconds * 100) / this.completionDurationSeconds)
		},
		previewIsComplete() {
			if (this.isElementCompletionMode) {
				return this.totalRequiredCount > 0 && this.completedRequiredCount === this.totalRequiredCount
			}
			return this.hasLessonContent && this.previewTimeSpentSeconds >= this.completionDurationSeconds
		},
		firstIncompleteRequiredIndex() {
			if (!this.isSequential) return -1
			return (this.initialLesson?.elements || []).findIndex((element, index) =>
				this.isElementRequired(element) && !this.isElementCompleted(index))
		},
		previewProgressLabel() {
			if (!this.hasLessonContent) return 'Bài học chưa có nội dung để xem.'
			if (this.isElementCompletionMode) {
				if (this.totalRequiredCount === 0) return 'Bài học chưa có khối bắt buộc để tính hoàn thành.'
				return this.previewIsComplete
					? 'Đã hoàn thành tất cả khối bắt buộc (mô phỏng).'
					: `${this.completedRequiredCount}/${this.totalRequiredCount} khối bắt buộc đã hoàn thành · thời gian tính khi khối hiện trong vùng xem.`
			}
			return this.previewIsComplete
				? 'Đã đủ thời gian hoàn thành bài (mô phỏng).'
				: `Thời gian xem thử: ${this.formatDuration(this.previewTimeSpentSeconds)} / ${this.formatDuration(this.completionDurationSeconds)}.`
		},
		tocElements() {
			return (this.initialLesson?.elements || [])
				.map((element, index) => ({
					id: `element-${index}`,
					index,
					title: String(element?.ElementData?.title || '').trim() || `Nội dung ${index + 1}`,
					required: this.isElementRequired(element),
					completed: this.isElementCompleted(index)
				}))
		}
	},
	watch: {
		initialLesson: {
			handler() {
				if (this.previewMounted) this.$nextTick(this.initializePreviewTracking)
			},
			deep: true
		}
	},
	mounted() {
		this.previewMounted = true
		this.$nextTick(this.initializePreviewTracking)
	},
	beforeUnmount() {
		this.stopPreviewTracking()
	},
	methods: {
		isElementRequired(element) {
			return element?.IsRequired === undefined || element?.IsRequired === null
				? true
				: [true, 1, '1'].includes(element.IsRequired)
		},
		isElementCompleted(index) {
			return this.previewElementProgressByIndex[index]?.Status === 'COMPLETED'
		},
		getRequiredDuration(element) {
			const seconds = Number(element?.RequiredDurationSeconds)
			return Number.isInteger(seconds) && seconds > 0 ? seconds : 0
		},
		getElementProgressLabel(index) {
			const element = this.initialLesson?.elements?.[index]
			const requiredSeconds = this.getRequiredDuration(element)
			if (!requiredSeconds) return 'Chưa đặt thời gian tối thiểu'
			const progress = this.previewElementProgressByIndex[index] || {}
			const spent = Math.min(Number(progress.TimeSpentSeconds) || 0, requiredSeconds)
			if (progress.Status === 'COMPLETED') return `Hoàn thành · ${spent} / ${requiredSeconds} giây`
			if (this.activeElementIndex === index) return `Đang tính · ${spent} / ${requiredSeconds} giây`
			if (spent > 0) return `Đã tích lũy · ${spent} / ${requiredSeconds} giây`
			return `Chưa bắt đầu · 0 / ${requiredSeconds} giây`
		},
		formatDuration(seconds) {
			const total = Math.max(0, Math.floor(Number(seconds) || 0))
			const minutes = Math.floor(total / 60)
			const remainingSeconds = total % 60
			if (!minutes) return `${remainingSeconds} giây`
			return remainingSeconds ? `${minutes} phút ${remainingSeconds} giây` : `${minutes} phút`
		},
		initializePreviewTracking() {
			this.stopPreviewTracking()
			this.activeTocId = this.tocElements[0]?.id || null
			this.previewTimeSpentSeconds = 0
			this.activeElementIndex = -1
			const progress = {}
			;(this.initialLesson?.elements || []).forEach((element, index) => {
				progress[index] = { Status: 'NOT_STARTED', TimeSpentSeconds: 0 }
			})
			this.previewElementProgressByIndex = progress
			if (!this.initialLesson) return
			this.$nextTick(() => {
				if (this.isElementCompletionMode) this.startElementTracking()
				else this.startLegacyTracking()
				// Resizing media can change which content block is visible and therefore which timer is active.
				if (typeof ResizeObserver !== 'undefined' && this.$refs.previewContent) {
					this.progressResizeObserver = new ResizeObserver(this.refreshActiveElement)
					this.progressResizeObserver.observe(this.$refs.previewContent)
				}
			})
		},
		stopPreviewTracking() {
			if (this.progressInterval) {
				clearInterval(this.progressInterval)
				this.progressInterval = null
			}
			if (this.elementObserver) {
				this.elementObserver.disconnect()
				this.elementObserver = null
			}
			if (this.progressResizeObserver) {
				this.progressResizeObserver.disconnect()
				this.progressResizeObserver = null
			}
			window.removeEventListener('scroll', this.refreshActiveElement)
			window.removeEventListener('resize', this.refreshActiveElement)
			document.removeEventListener('visibilitychange', this.onPreviewVisibilityChange)
		},
		startLegacyTracking() {
			this.lastProgressTickAt = Date.now()
			document.addEventListener('visibilitychange', this.onPreviewVisibilityChange)
			this.progressInterval = setInterval(this.tickLegacyTimer, 1000)
		},
		startElementTracking() {
			this.setupElementObserver()
			this.lastProgressTickAt = Date.now()
			document.addEventListener('visibilitychange', this.onPreviewVisibilityChange)
			this.progressInterval = setInterval(this.tickElementTimer, 1000)
		},
		setupElementObserver() {
			const container = this.$refs.previewContent
			if (!container) return
			const cards = Array.from(container.querySelectorAll('.element-preview'))
			if ('IntersectionObserver' in window) {
				this.elementObserver = new IntersectionObserver(this.refreshActiveElement,
					{ threshold: [0, 0.15, 0.35, 0.6, 0.85], rootMargin: '-10% 0px -10% 0px' })
				cards.forEach(card => this.elementObserver.observe(card))
			}
			window.addEventListener('scroll', this.refreshActiveElement, { passive: true })
			window.addEventListener('resize', this.refreshActiveElement, { passive: true })
			this.refreshActiveElement()
		},
		refreshActiveElement() {
			const container = this.$refs.previewContent
			if (!container) return
			const viewportHeight = window.innerHeight || document.documentElement.clientHeight
			const viewportCenter = viewportHeight / 2
			// Even when several cards fit in the viewport, only the most visible eligible card owns the timer.
			const candidate = Array.from(container.querySelectorAll('.element-preview'))
				.map((card, index) => {
					const rect = card.getBoundingClientRect()
					const visibleHeight = Math.max(0, Math.min(rect.bottom, viewportHeight) - Math.max(rect.top, 0))
					const ratio = rect.height > 0 ? visibleHeight / rect.height : 0
					return { index, ratio, centerDistance: Math.abs((rect.top + rect.bottom) / 2 - viewportCenter) }
				})
				.filter(({ index, ratio }) => ratio > 0 && !this.isElementLocked(index))
				.sort((left, right) => right.ratio - left.ratio || left.centerDistance - right.centerDistance)[0]
			const candidateIndex = candidate?.index ?? -1
			this.activeElementIndex = candidateIndex
			const activeTocElement = this.tocElements.find(element => element.index === candidateIndex)
			if (activeTocElement) this.activeTocId = activeTocElement.id
		},
		isElementLocked(index) {
			return this.isSequential && this.firstIncompleteRequiredIndex >= 0 && index > this.firstIncompleteRequiredIndex
		},
		onPreviewVisibilityChange() {
			this.lastProgressTickAt = Date.now()
		},
		tickLegacyTimer() {
			const now = Date.now()
			const elapsed = Math.floor((now - this.lastProgressTickAt) / 1000)
			if (elapsed < 1) return
			this.lastProgressTickAt += elapsed * 1000
			if (document.hidden || this.previewTimeSpentSeconds >= this.completionDurationSeconds) return
			this.previewTimeSpentSeconds = Math.min(this.completionDurationSeconds, this.previewTimeSpentSeconds + elapsed)
		},
		tickElementTimer() {
			const now = Date.now()
			const elapsed = Math.floor((now - this.lastProgressTickAt) / 1000)
			if (elapsed < 1) return
			this.lastProgressTickAt += elapsed * 1000
			// Refresh the dominant visible block before assigning this interval's seconds.
			this.refreshActiveElement()
			const index = this.activeElementIndex
			if (document.hidden || index < 0 || this.isElementLocked(index)) return
			const element = this.initialLesson?.elements?.[index]
			if (!element || !this.isElementRequired(element)) return
			const requiredSeconds = this.getRequiredDuration(element)
			if (!requiredSeconds) return
			const current = this.previewElementProgressByIndex[index] || { Status: 'NOT_STARTED', TimeSpentSeconds: 0 }
			if (current.Status === 'COMPLETED') return
			const timeSpent = Math.min(requiredSeconds, (Number(current.TimeSpentSeconds) || 0) + elapsed)
			const progress = {
				...this.previewElementProgressByIndex,
				[index]: {
					Status: timeSpent >= requiredSeconds ? 'COMPLETED' : 'IN_PROGRESS',
					TimeSpentSeconds: timeSpent
				}
			}
			this.previewElementProgressByIndex = progress
			if (this.isSequential && timeSpent >= requiredSeconds) this.$nextTick(this.refreshActiveElement)
		},
		// Mỗi mục lục trỏ tới id mà canvas học sinh gán theo thứ tự khối trong bài.
		scrollToElement(element) {
			this.activeTocId = element.id
			document.getElementById(element.id)?.scrollIntoView({ behavior: 'smooth', block: 'start' })
		},
		closePreview() {
			window.parent.postMessage({ type: 'iframeRef_closeWindow' }, '*')
		}
	}
	}
</script>