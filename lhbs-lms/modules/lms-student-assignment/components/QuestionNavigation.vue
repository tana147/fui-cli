<template>
	<v-card class="question-nav" flat style="height: 100%; display: flex; flex-direction: column;">
		<v-card-title class="d-flex justify-space-between align-center header-respondsive-fs px-2 py-1">
			<span style="font-size: clamp(12px,2vw,14px);">Cấu trúc bài tập</span>
			<v-btn icon size="x-small" density="compact" variant="text" @click="navCollapsed = !navCollapsed">
				<v-icon size="16">{{ navCollapsed ? 'mdi-chevron-down' : 'mdi-chevron-up' }}</v-icon>
			</v-btn>
		</v-card-title>

		<v-divider></v-divider>

		<!-- Thông tin điểm + hạn nộp -->
		<div v-if="assignment" class="px-2 py-1 d-flex flex-column ga-1 border-b">
			<div v-if="draft?.SubmissionStatus === 4" class="d-flex align-center ga-1">
				<v-chip color="primary" size="x-small" variant="outlined">
					<v-icon start size="12">mdi-trophy</v-icon>
					{{ draft?.Score }} / {{ displayMaxScore }}đ
				</v-chip>
				<v-chip size="x-small" color="success" variant="outlined">
					<v-icon start size="12">mdi-check-decagram</v-icon>
					Đã chấm
				</v-chip>
			</div>
			<span class="text-caption text-medium-emphasis d-flex align-center ga-1">
				<v-icon size="12">mdi-calendar-outline</v-icon>
				Hạn: {{ formatDate(assignment?.DueDate) }}
			</span>
		</div>

		<v-expand-transition>
			<div v-show="!navCollapsed" class="pa-2 pb-0" style="flex: 1; overflow: auto; min-height: 0;">
				<div class="d-flex justify-end mb-2">
					<v-btn-toggle :model-value="viewMode" @update:model-value="$emit('update:viewMode', $event)"
						color="primary" variant="outlined" density="compact" divided mandatory size="x-small">
						<v-btn value="single" size="x-small">
							<v-icon size="16">mdi-numeric-1-box</v-icon>
							<span class="ml-1 d-none d-sm-inline">Từng câu</span>
						</v-btn>
						<v-btn value="all" size="x-small">
							<v-icon size="16">mdi-view-list</v-icon>
							<span class="ml-1 d-none d-sm-inline">Tất cả</span>
						</v-btn>
					</v-btn-toggle>
				</div>

				<div v-for="(group, groupIndex) in groups" :key="group.id" class="mb-2">
					<v-list-item @click="toggleGroup(groupIndex)" class="group-header-item px-0 py-1" density="compact">
						<template #prepend>
							<v-icon size="20" class="group-toggle-icon">
								{{ groupCollapsed[groupIndex] ? 'mdi-chevron-right' : 'mdi-chevron-down' }}
							</v-icon>
						</template>
						<v-list-item-title class="group-title body-respondsive-fs">
							{{ group.title }}
						</v-list-item-title>
						<template #append>
							<v-chip size="x-small" color="primary" variant="outlined">
								{{ group.questions.length }} câu
							</v-chip>
						</template>
					</v-list-item>

					<v-expand-transition>
						<div v-show="!groupCollapsed[groupIndex]" class="mt-2">
							<div class="question-grid">
								<v-badge v-for="(q, questionIndexInGroup) in group.questions" :key="q.id"
									location="top right" :color="userAnswers[q.id]?.flag ? 'red' : 'white'"
									:icon="userAnswers[q.id]?.flag ? 'mdi-flag-variant' : ''"
							:model-value="!!userAnswers[q.id]?.flag">
									<v-btn @click="$emit('navigate', groupIndex, questionIndexInGroup, q.id)"
										:color="isNavQuestionLocked(q, group) ? 'grey' : getIconColor(q.id)"
										:variant="isActive(groupIndex, questionIndexInGroup) ? 'elevated' : 'tonal'"
										class="question-btn w-100" size="small">
										<v-icon size="16">{{ isNavQuestionLocked(q, group) ? 'mdi-lock' : getStatusIcon(q.id) }}</v-icon>
										{{ getQuestionNumber(groupIndex, questionIndexInGroup) }}
									</v-btn>
								</v-badge>
							</div>
						</div>
					</v-expand-transition>
				</div>
			</div>
		</v-expand-transition>
	</v-card>
</template>

<script>
	export default {
		name: 'QuestionNavigation',
		props: {
			groups: {
				type: Array,
				default: () => []
			},
			userAnswers: {
				type: Object,
				default: () => ({})
			},
			currentGroupIndex: {
				type: Number,
				default: 0
			},
			currentQuestionIndex: {
				type: Number,
				default: 0
			},
			viewMode: {
				type: String,
				default: 'all'
			},
			draft: {
				type: Object,
				default: () => ({})
			},
			getIconColor: {
				type: Function,
				required: true
			},
			getStatusIcon: {
				type: Function,
				required: true
			},
			getQuestionNumber: {
				type: Function,
				required: true
			},
			assignment: {
				type: Object,
				default: () => ({})
			},
			unlockedQuestionIds: {
				type: Array,
				default: () => []
			}
		},
		emits: ['navigate', 'update:viewMode'],
		data() {
			return {
				navCollapsed: false,
				groupCollapsed: {}
			};
		},
		computed: {
			displayMaxScore() {
				// Random attempt có thể có mẫu số khác nhau theo bộ câu đã bốc.
				// Bài cũ không có AttemptMaxScore vẫn hiển thị MaxScore như trước.
				const attemptMaxScore = this.assignment?.AttemptMaxScore;
				if (attemptMaxScore === null || attemptMaxScore === undefined || attemptMaxScore === '') {
					return this.assignment?.MaxScore;
				}
				const numericScore = Number(attemptMaxScore);
				return Number.isFinite(numericScore) ? numericScore : this.assignment?.MaxScore;
			},
		},
		watch: {
			groups: {
				immediate: true,
				handler(newGroups) {
					if (newGroups) {
						const initialCollapsed = {};
						newGroups.forEach((group, index) => {
							initialCollapsed[index] = false;
						});
						this.groupCollapsed = initialCollapsed;
					}
				}
			}
		},
		methods: {
			formatDate(dateString) {
				if (!dateString) return 'Chưa có';
				try {
					const date = new Date(dateString);
					return date.toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
				} catch { return '—'; }
			},
			toggleGroup(groupIndex) {
				this.groupCollapsed = {
					...this.groupCollapsed,
					[groupIndex]: !this.groupCollapsed[groupIndex]
				};
			},
	
			isActive(groupIndex, questionIndex) {
				return this.currentGroupIndex === groupIndex &&
					this.currentQuestionIndex === questionIndex;
			},

			/** Kiểm tra câu hỏi có bị khóa do chưa đến mốc thời gian video không */
			hasUsableAnswer(answer) {
				if (answer === null || answer === undefined) return false;
				if (typeof answer === 'string' && answer.trim() === '') return false;
				if (Array.isArray(answer) && answer.length === 0) return false;
				if (typeof answer === 'object' && !Array.isArray(answer) && Object.keys(answer).length === 0) return false;
				return true;
			},

			isNavQuestionLocked(q, group) {
				if (!q) return false;
				const isInteractive = Boolean(group?.isInteractiveVideo || group?.media?.type === 'INTERACTIVE_VIDEO' || group?.media?.interactiveVideo);
				if (!isInteractive) return false;
				if (q.timeMarker === undefined || q.timeMarker === null || q.timeMarker === '') return false;
				const ans = this.userAnswers?.[q.id]?.answerData;
				if (this.hasUsableAnswer(ans)) return false;
				return !this.unlockedQuestionIds.includes(q.id);
			}
		}
	}
</script>