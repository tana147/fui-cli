<template>
	<!-- Giao diện khi không có dữ liệu -->
	<div v-if="!initialLesson" class="text-center pa-10 fill-height d-flex flex-column justify-center align-center">
		<v-icon size="64" color="grey-lighten-1">mdi-alert-circle-outline</v-icon>
		<h2 class="mt-4 text-h6">Không tìm thấy nội dung</h2>
		<p class="text-medium-emphasis">Bài giảng này không tồn tại hoặc bạn không có quyền truy cập.</p>
	</div>

	<!-- Giao diện chính khi có dữ liệu -->
	<div v-else class="lesson-viewer-container">

		<!-- ===== CỘT TRÁI: SIDEBAR ===== -->
		<div class="lesson-sidebar">
			<div class="sidebar-sticky-content">
				<h3 class="text-subtitle-1 font-weight-bold mb-1">Nội dung bài học</h3>
				<p class="text-caption text-grey-darken-1 mb-3">{{ initialLesson.MonHocName }}</p>

				<v-progress-linear :model-value="isElementCompletionMode ? requiredCompletionPercent : scrollProgress" color="primary" height="6" rounded class="mb-2">
				</v-progress-linear>
				<div v-if="isElementCompletionMode" class="text-caption text-medium-emphasis mb-4">
					{{ completedRequiredCount }}/{{ totalRequiredCount }} khối bắt buộc đã hoàn thành
				</div>

				<ul class="lesson-toc" v-if="tocElements.length > 0">
					<li v-for="element in tocElements" :key="element.id">
						<a @click="scrollToElement(element.id)" :class="{ 'is-active': activeTocId === element.id }">
							<span>{{ element.title }}</span>
							<v-icon v-if="element.required && element.completed" size="16" color="success" class="ml-1">mdi-check-circle</v-icon>
							<div v-if="isElementCompletionMode && element.required" class="text-caption text-grey mt-1">
								{{ formatElementTime(element.elementID) }}
							</div>
						</a>
					</li>
				</ul>
				<div v-else class="text-caption text-grey">
					Bài học này không có tiêu đề mục.
				</div>
			</div>
		</div>

		<!-- ===== CỘT PHẢI: NỘI DUNG CHÍNH ===== -->
		<!-- Để document/viewport quản lý scroll; tránh scrollbar lồng bên trong bị lùi khỏi mép phải do wrapper có padding. -->
		<div class="lesson-main-content">
			<!-- HEADER ĐÃ NÂNG CẤP -->
			<div class="lesson-header">
				<div class="text-caption text-grey-darken-1 mb-2 sub-title-lesson">
					<span>{{ initialLesson.MonHocName }}</span>
					<v-icon size="x-small" class="mx-1">mdi-chevron-right</v-icon>
					<span>Bài học</span>
				</div>
				<b class=" title-lesson font-weight-bold">{{ initialLesson.Title }}</b>
				<p v-if="initialLesson.Description" class="text-medium-emphasis mt-2 sub-title-lesson">{{
					initialLesson.Description }}
				</p>

			</div>

			<!-- Canvas hiển thị nội dung -->
			<div class="lesson-canvas-container" ref="canvasContainer">
				<uc-lesson-canvas :elements="initialLesson.elements" :is-viewer="true"
					:element-progress="elementProgressByID" :is-sequential="isSequential"
					:first-incomplete-required-index="firstIncompleteRequiredIndex" />
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-lesson-viewer',
	props: {
		initialLesson: Object,
		onUpdateProgress: { type: Function, default: () => { } }
	},
	data() {
		const { mobile } = Vuetify.useDisplay()
		return {
			isCompleted: false,
			timeSpentInterval: null,
			elementTimeSpentInterval: null,
			sessionTimeSpentSeconds: 0,
			progressRequestInFlight: false,
			progressTrackingStopped: false,
			progressTrackingStarted: false,
			elementProgressByID: {},
			pendingElementSecondsByID: {},
			pendingElementEventIDByID: {},
			activeElementID: null,
			activeElementIndex: null,
			elementObserver: null,
			visibleElementRatios: new Map(),
			elementTimerLastAt: 0,
			scrollProgress: 0,
			activeTocId: null,
			tocObserver: null,
			lastUpdateTime: 0,
			mobile
		}
	},
	computed: {
		isElementCompletionMode() {
			return this.initialLesson?.CompletionPolicy === 'ALL_REQUIRED'
				&& Number(this.initialLesson?.CompletionVersion) >= 2;
		},
		isSequential() {
			return this.isElementCompletionMode && [true, 1, '1'].includes(this.initialLesson?.RequireSequential);
		},
		requiredElements() {
			return (this.initialLesson?.elements || []).filter(element => this.isElementRequired(element));
		},
		totalRequiredCount() {
			return this.requiredElements.length;
		},
		completedRequiredCount() {
			return this.requiredElements.filter(element => this.isElementCompleted(element)).length;
		},
		requiredCompletionPercent() {
			return this.totalRequiredCount > 0 ? (this.completedRequiredCount * 100) / this.totalRequiredCount : 0;
		},
		firstIncompleteRequiredIndex() {
			if (!this.isSequential) return -1;
			return (this.initialLesson?.elements || []).findIndex(element =>
				this.isElementRequired(element) && !this.isElementCompleted(element));
		},
		// EstimatedDuration được soạn theo phút; đổi sang giây để cùng đơn vị với TimeSpentSeconds.
		completionDurationSeconds() {
			const durationMinutes = Number(this.initialLesson?.EstimatedDuration);
			const normalizedMinutes = Number.isFinite(durationMinutes) && durationMinutes >= 1
				? durationMinutes
				: 3;
			return normalizedMinutes * 60;
		},
		// TimeSpentSeconds là tổng đã lưu trước đó; sessionTimeSpentSeconds là thời gian gửi thành công của phiên hiện tại.
		totalTimeSpentSeconds() {
			const savedSeconds = Number(this.initialLesson?.TimeSpentSeconds);
			return (Number.isFinite(savedSeconds) && savedSeconds > 0 ? savedSeconds : 0) + this.sessionTimeSpentSeconds;
		},
		tocElements() {
			if (!this.initialLesson || !this.initialLesson.elements) return [];
			return this.initialLesson.elements
				.map((el, index) => ({
					id: `element-${index}`,
					title: el.ElementData.title,
					elementID: el.ElementID,
					required: this.isElementRequired(el),
					completed: this.isElementCompleted(el)
				}))
				.filter(el => el.title && el.title.trim() !== '');
		}
	},
	watch: {
		initialLesson: {
			handler(newVal, oldVal) {
				console.log('[DEBUG] Watcher "initialLesson" được kích hoạt. Giá trị mới (newVal):', newVal);

				if (newVal && !this.progressTrackingStarted) {
					this.hydrateElementProgress();
					this.progressTrackingStarted = true;
					this.isCompleted = [true, 1, '1'].includes(this.initialLesson.IsCompleted);
					this.$nextTick(() => {
						this.setupScrollListener();
						this.setupTocObserver();
						if (!this.isCompleted) {
							if (this.isElementCompletionMode) this.startElementTracking();
							else this.startTracking();
						}
					});
				}
			},
			deep: true,
			immediate: true
		}
	},
	mounted() {
		window.addEventListener('scroll', this.updateScrollProgress, { passive: true });

		if (this.tocElements.length > 0) { this.activeTocId = this.tocElements[0].id }
	},
	beforeUnmount() {
		console.log('[DEBUG] Component "uc-lesson-viewer" SẼ BỊ HỦY (beforeUnmount). Đang xóa interval.');
		this.flushElementProgress(true);
		window.removeEventListener('scroll', this.updateScrollProgress);
		if (this.tocObserver) this.tocObserver.disconnect();
		if (this.elementObserver) this.elementObserver.disconnect();
		document.removeEventListener('visibilitychange', this.onVisibilityChange);
		this.stopProgressTracking();
	},
	methods: {
		isElementRequired(element) {
			return element?.IsRequired === undefined || element?.IsRequired === null
				? true
				: [true, 1, '1'].includes(element.IsRequired);
		},
		getElementProgress(element) {
			return this.elementProgressByID[element?.ElementID] || {
				Status: element?.ElementProgressStatus || 'NOT_STARTED',
				TimeSpentSeconds: Number(element?.ElementTimeSpentSeconds) || 0,
				ProgressPercent: element?.ElementProgressPercent
			};
		},
		isElementCompleted(element) {
			return this.getElementProgress(element).Status === 'COMPLETED'
				|| this.getElementProgress(element).ElementProgressStatus === 'COMPLETED';
		},
		hydrateElementProgress() {
			const progress = {};
			for (const element of (this.initialLesson?.elements || [])) {
				if (!element.ElementID) continue;
				progress[element.ElementID] = {
					Status: element.ElementProgressStatus || 'NOT_STARTED',
					TimeSpentSeconds: Number(element.ElementTimeSpentSeconds) || 0,
					ProgressPercent: element.ElementProgressPercent,
					CompletedTime: element.ElementCompletedTime || null
				};
			}
			this.elementProgressByID = progress;
		},
		formatElementTime(elementID) {
			const element = (this.initialLesson?.elements || []).find(item => Number(item.ElementID) === Number(elementID));
			const required = Number(element?.RequiredDurationSeconds) || 0;
			const saved = Number(this.getElementProgress(element).TimeSpentSeconds) || 0;
			const pending = Number(this.pendingElementSecondsByID[elementID]) || 0;
			return `Đã học ${Math.min(saved + pending, required)} / ${required} giây`;
		},
		createClientEventID() {
			if (window.crypto?.randomUUID) return window.crypto.randomUUID();
			return `evt-${Date.now()}-${Math.random().toString(36).slice(2)}`;
		},
					
		setupElementObserver() {
			const container = this.$refs.canvasContainer;
			if (!container || !this.isElementCompletionMode) return;
			if (this.elementObserver) this.elementObserver.disconnect();
			this.visibleElementRatios = new Map();
			const cards = Array.from(container.querySelectorAll('.element-preview'));
			if (!('IntersectionObserver' in window)) {
				const firstOpen = (this.initialLesson?.elements || []).find((element, index) =>
					!this.isSequential || this.firstIncompleteRequiredIndex < 0 || index <= this.firstIncompleteRequiredIndex);
				this.setActiveElement(firstOpen?.ElementID, firstOpen ? (this.initialLesson.elements || []).indexOf(firstOpen) : null);
				return;
			}
			this.elementObserver = new IntersectionObserver(entries => {
				for (const entry of entries) {
					const index = Number(String(entry.target.id).replace('element-', ''));
					this.visibleElementRatios.set(index, entry.isIntersecting ? entry.intersectionRatio : 0);
				}
				this.refreshActiveElement();
			}, { threshold: [0, 0.15, 0.35, 0.6, 0.85], rootMargin: '-10% 0px -10% 0px' });
			cards.forEach(card => this.elementObserver.observe(card));
		},
	refreshActiveElement() {
			const candidate = Array.from(this.visibleElementRatios.entries())
				.filter(([index, ratio]) => ratio > 0 && !this.isLockedElement(index))
				.sort((left, right) => right[1] - left[1])[0];
			const index = candidate ? candidate[0] : null;
			const element = index === null ? null : this.initialLesson?.elements?.[index];
			this.setActiveElement(element?.ElementID, index);
		},
		isLockedElement(index) {
			return this.isSequential && this.firstIncompleteRequiredIndex >= 0 && index > this.firstIncompleteRequiredIndex;
		},
	setActiveElement(elementID, index) {
			if (Number(elementID) === Number(this.activeElementID)) return;
			this.flushElementProgress(false);
			this.activeElementID = elementID || null;
			this.activeElementIndex = index;
			this.elementTimerLastAt = Date.now();
		},
	startElementTracking() {
			if (this.progressTrackingStopped || this.elementTimeSpentInterval) return;
			this.elementTimerLastAt = Date.now();
			document.addEventListener('visibilitychange', this.onVisibilityChange);
			this.setupElementObserver();
			this.elementTimeSpentInterval = setInterval(() => this.tickElementTimer(), 1000);
		},
	onVisibilityChange() {
			this.elementTimerLastAt = Date.now();
			if (document.hidden) this.flushElementProgress(true);
		},
	tickElementTimer() {
			const now = Date.now();
			const elapsedWholeSeconds = Math.floor((now - this.elementTimerLastAt) / 1000);
			if (elapsedWholeSeconds < 1) return;
			this.elementTimerLastAt += elapsedWholeSeconds * 1000;
			const queuedElementID = Object.keys(this.pendingElementSecondsByID)
				.find(id => Number(this.pendingElementSecondsByID[id]) >= 5);
			if (queuedElementID) this.flushElementProgress(false);
			if (document.hidden || !this.activeElementID || this.isLockedElement(this.activeElementIndex)) return;
			const element = this.initialLesson?.elements?.[this.activeElementIndex];
			if (!element || this.isElementCompleted(element)) return;
			const elementID = element.ElementID;
			this.pendingElementSecondsByID[elementID] = (Number(this.pendingElementSecondsByID[elementID]) || 0) + elapsedWholeSeconds;
			if (this.pendingElementSecondsByID[elementID] >= 5) this.flushElementProgress(false);
		},
	flushElementProgress(force) {
			if (this.progressRequestInFlight || this.progressTrackingStopped) return;
			const elementID = Object.keys(this.pendingElementSecondsByID)
				.find(id => Number(this.pendingElementSecondsByID[id]) >= (force ? 1 : 5));
			if (!elementID) return;
			const timeSpent = Math.min(15, Number(this.pendingElementSecondsByID[elementID]) || 0);
			const clientEventID = this.pendingElementEventIDByID[elementID] || this.createClientEventID();
			this.pendingElementEventIDByID[elementID] = clientEventID;
			this.progressRequestInFlight = true;
			Promise.resolve(this.onUpdateProgress({ elementID, timeSpent, clientEventID }))
				.then(response => {
					const rows = response?.data ?? response;
					const row = Array.isArray(rows) ? (Array.isArray(rows[0]) ? rows[0][0] : rows[0]) : rows;
					const accepted = Math.min(timeSpent, Math.max(1, Number(row?.AcceptedSeconds ?? timeSpent)));
					const remaining = Math.max(0, (Number(this.pendingElementSecondsByID[elementID]) || 0) - accepted);
					// Mỗi lần server nhận một phần heartbeat sẽ có EventID mới cho phần thời gian còn lại.
					delete this.pendingElementEventIDByID[elementID];
					if (remaining > 0) this.pendingElementSecondsByID[elementID] = remaining;
					else {
						delete this.pendingElementSecondsByID[elementID];
					}
					if (row) {
						this.elementProgressByID[elementID] = {
							...this.getElementProgress({ ElementID: elementID }),
							Status: row.Status || 'IN_PROGRESS',
							TimeSpentSeconds: Number(row.TimeSpentSeconds) || 0,
							ProgressPercent: row.ProgressPercent,
							CompletedTime: row.CompletedTime || null
						};
					}
					if ([true, 1, '1'].includes(row?.LessonIsCompleted)) {
						this.isCompleted = true;
						this.stopProgressTracking();
						Vue.$toast.success('Bạn đã hoàn thành bài học!', { position: 'top' });
					} else if (remaining >= 5) {
						this.$nextTick(() => this.flushElementProgress(false));
					}
					this.$nextTick(() => this.refreshActiveElement());
				})
				.catch(error => {
					console.error('[ELEMENT_PROGRESS] Không thể lưu tiến độ:', error);
				})
				.finally(() => { this.progressRequestInFlight = false; });
		},
		stopProgressTracking() {
			// Khi bài đã hoàn thành hoặc component bị hủy, dừng cả timer tổng và timer element.
			this.progressTrackingStopped = true;
			if (this.timeSpentInterval) {
				clearInterval(this.timeSpentInterval);
				this.timeSpentInterval = null;
			}
			if (this.elementTimeSpentInterval) {
				clearInterval(this.elementTimeSpentInterval);
				this.elementTimeSpentInterval = null;
			}
			document.removeEventListener('visibilitychange', this.onVisibilityChange);
		},

		startTracking() {
			console.log('[DEBUG] startTracking() được gọi.');
			if (this.progressTrackingStopped) return;
			// Tạo progress row ngay khi mở bài; thời gian hoàn thành vẫn do ngưỡng động bên dưới quyết định.
			this.progressRequestInFlight = true;
			Promise.resolve(this.onUpdateProgress({ isCompleted: false, timeSpent: 0 }))
				.catch(error => {
					this.stopProgressTracking();
					console.error('[LESSON_PROGRESS] Không thể khởi tạo tiến độ:', error);
				})
				.finally(() => { this.progressRequestInFlight = false; });
			this.lastUpdateTime = Date.now();

			this.timeSpentInterval = setInterval(() => {
				const now = Date.now();
				const elapsedSeconds = (now - this.lastUpdateTime) / 1000;
				if (elapsedSeconds < 5 || this.progressRequestInFlight || this.progressTrackingStopped || this.isCompleted) return;

				const requestStartedAt = now;
				const timeSpent = Math.max(1, Math.round(elapsedSeconds));
				// Chỉ đánh dấu hoàn thành khi tổng thời gian đã tích lũy đạt đúng mốc đã soạn.
				const shouldComplete = this.totalTimeSpentSeconds + timeSpent >= this.completionDurationSeconds;
				this.progressRequestInFlight = true;
				Promise.resolve(this.onUpdateProgress({ isCompleted: shouldComplete, timeSpent }))
					.then(() => {
						// Chỉ cộng thời gian sau khi API xác nhận; request lỗi sẽ được cộng dồn ở lần gửi sau.
						this.sessionTimeSpentSeconds += timeSpent;
						this.lastUpdateTime = requestStartedAt;
						if (shouldComplete) {
							this.isCompleted = true;
							this.stopProgressTracking();
							Vue.$toast.success('Bạn đã hoàn thành bài học!', { position: 'top' });
						}
					})
					.catch(error => {
						this.stopProgressTracking();
						console.error('[LESSON_PROGRESS] Không thể cập nhật tiến độ:', error);
					})
					.finally(() => { this.progressRequestInFlight = false; });

			}, 5000);
		},

		scrollToElement(elementId) {
			const container = this.$refs.canvasContainer;
			if (!container) return;
			const element = container.querySelector(`#${elementId}`);
			if (element) {
				this.activeTocId = elementId
				element.scrollIntoView({
					behavior: "smooth", // cuộn mượt
					block: "start" // vị trí hiển thị: start | center | end | nearest
				});
				return
			}
		},

		setupScrollListener() {
			console.log("[DEBUG] setupScrollListener được gọi.");
		},

		updateScrollProgress() {
			const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
			const scrollHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight;
			this.scrollProgress = scrollHeight > 0 ? (scrollTop / scrollHeight) * 100 : 0;

		},

		setupTocObserver() {
			const container = this.$refs.canvasContainer;
			if (!container || this.tocElements.length === 0 || !('IntersectionObserver' in window)) return;
			if (this.tocObserver) this.tocObserver.disconnect();
			this.tocObserver = new IntersectionObserver(entries => {
				const visible = entries.filter(entry => entry.isIntersecting)
					.sort((left, right) => right.intersectionRatio - left.intersectionRatio)[0];
				if (visible) this.activeTocId = visible.target.id;
			}, { root: null, rootMargin: '0% 0px -20% 0px', threshold: [0, 0.25, 0.6] });
			this.tocElements.forEach(toc => {
				const element = container.querySelector(`#${toc.id}`);
				if (element) this.tocObserver.observe(element);
			});
		}
	}
	}
</script>