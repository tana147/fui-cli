<template>
	<v-dialog :model-value="visible" @update:model-value="closeDialog" :width="isMobile ? '95%' : 980"
		:max-height="isMobile ? '95dvh' : '88vh'" scrollable>
		<!-- ── LOADING ── -->
		<v-card v-if="loading" class="smd-card smd-card--loading" rounded="xl" elevation="0">
			<div class="smd-loading-body">
				<div class="smd-spinner-ring">
					<svg viewBox="0 0 44 44" class="smd-spinner-svg">
						<circle cx="22" cy="22" r="18" fill="none" stroke-width="3" class="smd-spinner-track" />
						<circle cx="22" cy="22" r="18" fill="none" stroke-width="3" class="smd-spinner-arc"
							stroke-dasharray="56 56" stroke-linecap="round" />
					</svg>
				</div>
				<p class="smd-loading-text">Đang tải kết quả bài làm…</p>
			</div>
		</v-card>
		<!-- ── MAIN CARD ── -->
		<v-card v-else-if="summaryData && summaryData.overview" class="smd-card" rounded="xl" elevation="0">
			<!-- HEADER -->
			<div class="smd-header">
				<div class="smd-header-glow" :style="{ background: scoreGradient }"></div>
				<div class="smd-header-content">
					<div class="smd-header-tag">Kết quả bài làm</div>
					<h2 class="smd-header-title">{{ summaryData.overview.Title }}</h2>

					<!-- Score ring -->
					<div class="smd-score-wrap">
						<div class="smd-score-ring-outer">
							<svg viewBox="0 0 120 120" class="smd-ring-svg">
								<circle cx="60" cy="60" r="50" fill="none" stroke-width="8" class="smd-ring-bg" />
								<circle cx="60" cy="60" r="50" fill="none" stroke-width="8" class="smd-ring-fg"
									:stroke="scoreColor" stroke-linecap="round" :stroke-dasharray="strokeDasharray"
									transform="rotate(-90 60 60)" />
							</svg>
							<div class="smd-ring-inner">
								<span class="smd-score-num" :style="{ color: scoreColor }">
									{{ computedScore }}
								</span>
								<span class="smd-score-max">/ {{ summaryData.overview.MaxScore }}</span>
							</div>
						</div>

						<div class="smd-score-stats">
							<div class="smd-stat-row">
								<div class="smd-stat-pill"
									:style="{ background: scoreColor + '20', color: scoreColor }">
									<v-icon size="13">{{ scoreMoodIcon }}</v-icon>
									{{ scoreMoodLabel }}
								</div>
							</div>
							<div class="smd-stat-grid">
								<div class="smd-stat-box">
									<span class="smd-stat-val text-success">{{ correctCount }}</span>
									<span class="smd-stat-lbl">Đúng</span>
								</div>
								<div class="smd-stat-box">
									<span class="smd-stat-val text-warning">{{ partialCount }}</span>
									<span class="smd-stat-lbl">Một phần</span>
								</div>
								<div class="smd-stat-box">
									<span class="smd-stat-val text-error">{{ wrongCount }}</span>
									<span class="smd-stat-lbl">Sai</span>
								</div>
							</div>
						</div>
					</div>
				</div>

				<button class="smd-close-btn" @click="closeDialog">
					<v-icon size="18">mdi-close</v-icon>
				</button>
			</div>

			<!-- TEACHER COMMENT -->
			<div v-if="summaryData.overview.TeacherComment && summaryData.overview.TeacherComment.trim()"
				class="smd-comment">
				<div class="smd-comment-label">
					<v-icon size="14" color="primary">mdi-comment-text-outline</v-icon>
					Nhận xét của giáo viên
				</div>
				<div class="smd-comment-body" v-html="summaryData.overview.TeacherComment"></div>
			</div>

			<!-- QUESTION TABLE -->
			<div class="smd-table-wrap">
				<div class="smd-table-head">
					<span class="smd-th smd-th--q">Câu hỏi</span>
					<span class="smd-th smd-th--r">{{ isMobile ? 'KQ' : 'Kết quả' }}</span>
					<span class="smd-th smd-th--s">Điểm</span>
				</div>

				<div class="smd-table-body">
					<div v-for="(item, i) in summaryData.details" :key="item.QuestionID" class="smd-table-row"
						:class="'smd-row--'+getStatusInfo(item).status">
						<div class="smd-td smd-td--q">
							<span class="smd-q-num">{{ i + 1 }}</span>
							<div class="smd-q-text" v-html="item.QuestionText"></div>
						</div>
						<div class="smd-td smd-td--r">
							<div class="smd-status-chip" :class="'smd-status-chip--'+getStatusInfo(item).status">
								<v-icon size="14">{{ getStatusInfo(item).icon }}</v-icon>
							</div>
						</div>
						<div class="smd-td smd-td--s">
							<span class="smd-score-cell" :style="{ color: getStatusInfo(item).chipColor }">
								{{ item.Score }}
							</span>
							<span class="smd-score-denom"> / {{ item.MaxScore }}</span>
						</div>
					</div>
				</div>
			</div>

			<!-- FOOTER -->
			<div class="smd-footer">
				<v-btn variant="text" class="smd-btn-close" @click="closeDialog" size="small">
					Đóng
				</v-btn>
				<v-btn variant="flat" class="smd-btn-detail" @click="navigateToDetails" size="small"
					append-icon="mdi-arrow-right">
					Xem bài làm chi tiết
				</v-btn>
			</div>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-summary-modal',
		props: {
			visible: Boolean,
			loading: Boolean,
			summaryData: Object,
			isMobile: Boolean
		},
		emits: ['update:visible', 'navigate-to-details'],
		watch: {
			visible(v) {
				if (v) this.renderMath();
			},
			summaryData: {
				deep: true,
				handler() {
					this.renderMath();
				}
			}
		},
		computed: {
			strokeDasharray() {
				return `${(this.scorePct / 100) * 314} 314`
			},
			computedScore() {
				const ov = this.summaryData?.overview;
				if (!ov) return 0;
				let total = 0;
				for (const d of (this.summaryData?.details || [])) {
					total += Number(d.Score) || 0;
				}
				const ovScore = Number(ov.Score);
				const roundTotal = Math.round(total * 100) / 100;
				if (!isNaN(ovScore) && ovScore > 0) {
					return Math.max(ovScore, roundTotal);
				}
				return roundTotal;
			},
			scorePct() {
				const ov = this.summaryData?.overview;
				if (!ov || !ov.MaxScore) return 0;
				return Math.min(100, Math.round((this.computedScore / ov.MaxScore) * 100));
			},
			scoreColor() {
				const p = this.scorePct;
				if (p === 100) return 'rgb(var(--v-theme-primary))';
				if (p >= 80) return '#22c55e';
				if (p >= 50) return '#f59e0b';
				return '#ef4444';
			},
			scoreGradient() {
				return `radial-gradient(ellipse at 60% 0%, ${this.scoreColor}28 0%, transparent 70%)`;
			},
			scoreMoodIcon() {
				const p = this.scorePct;
				if (p >= 80) return 'mdi-trophy-outline';
				if (p >= 50) return 'mdi-thumb-up-outline';
				return 'mdi-book-open-page-variant-outline';
			},
			scoreMoodLabel() {
				const p = this.scorePct;
				if (p >= 80) return `Xuất sắc — ${this.scorePct}%`;
				if (p >= 50) return `Khá — ${this.scorePct}%`;
				return `Cần cố gắng — ${this.scorePct}%`;
			},
			correctCount() {
				return (this.summaryData?.details || []).filter(i => {
					const score = Number(i.Score) || 0;
					const maxScore = Number(i.MaxScore) || 0;
					if (maxScore > 0 && Math.abs(score - maxScore) < 0.001) return true;
					if (i.IsCorrect === true || i.IsCorrect === 1) return true;
					return false;
				}).length;
			},
			partialCount() {
				return (this.summaryData?.details || []).filter(i => {
					const score = Number(i.Score) || 0;
					const maxScore = Number(i.MaxScore) || 0;
					return score > 0 && maxScore > 0 && (maxScore - score) >= 0.001;
				}).length;
			},
			wrongCount() {
				return (this.summaryData?.details || []).filter(i => {
					const score = Number(i.Score) || 0;
					return score === 0;
				}).length;
			},
		},
		methods: {
			renderMath() {
				this.$nextTick(() => {
					if (window.MathJax?.typesetPromise && this.$el) {
						window.MathJax.typesetPromise([this.$el]).catch(() => {});
					}
				});
			},
			closeDialog() {
				if (this.visible) this.$emit('update:visible', false);
			},
			navigateToDetails() {
				const overview = this.summaryData?.overview;
				if (overview) {
					this.$emit('navigate-to-details', overview);
				} else {
					Vue.$toast?.error('Thiếu thông tin AssignToClassID để điều hướng.');
				}
			},
			getStatusInfo(item) {
				const score = Number(item.Score) || 0;
				const maxScore = Number(item.MaxScore) || 0;
				if (score === 0) return { icon: 'mdi-close-circle', status: 'wrong', color: 'error', chipColor: '#ef4444' };
				if (maxScore > 0 && score >= maxScore - 0.001) return { icon: 'mdi-check-circle', status: 'correct', color: 'success', chipColor: '#22c55e' };
				return { icon: 'mdi-star-half-full', status: 'partial', color: 'warning', chipColor: '#f59e0b' };
			},
		},
	}
</script>

<style scoped>
.smd-table-wrap {
	flex: 1 !important;
	overflow-y: auto !important;
	overflow-x: hidden !important;
}

.smd-table-head {
	display: grid !important;
	grid-template-columns: minmax(0, 1fr) 72px 84px !important;
	gap: 12px !important;
	padding: 10px 20px !important;
	background: color-mix(in srgb, rgb(var(--v-theme-primary)) 5%, white) !important;
	border-bottom: 1px solid rgba(var(--v-theme-primary), 0.08) !important;
	position: sticky !important;
	top: 0 !important;
	z-index: 2 !important;
	align-items: center !important;
}

.smd-th--r,
.smd-th--s {
	text-align: center !important;
}

.smd-table-row {
	display: grid !important;
	grid-template-columns: minmax(0, 1fr) 72px 84px !important;
	gap: 12px !important;
	padding: 14px 20px !important;
	border-bottom: 1px solid #f3f4f8 !important;
	align-items: flex-start !important;
	transition: background 0.12s !important;
}

.smd-td--q {
	display: flex !important;
	align-items: flex-start !important;
	gap: 12px !important;
	min-width: 0 !important;
	max-width: 100% !important;
	overflow: hidden !important;
}

.smd-q-num {
	flex-shrink: 0 !important;
	width: 24px !important;
	height: 24px !important;
	border-radius: 6px !important;
	background: rgba(var(--v-theme-primary), 0.08) !important;
	display: flex !important;
	align-items: center !important;
	justify-content: center !important;
	font-size: 11px !important;
	font-weight: 700 !important;
	color: rgb(var(--v-theme-primary)) !important;
	margin-top: 2px !important;
}

.smd-q-text {
	flex: 1 1 0% !important;
	min-width: 0 !important;
	max-width: 100% !important;
	overflow: hidden !important;
	font-size: 13.5px !important;
	color: #374151 !important;
	line-height: 1.6 !important;
	word-break: break-word !important;
	overflow-wrap: break-word !important;
}

.smd-q-text figure,
.smd-q-text figure.image {
	display: block !important;
	max-width: 100% !important;
	width: 100% !important;
	margin: 0 !important;
	padding: 0 !important;
	float: none !important;
	clear: both !important;
	overflow: hidden !important;
}

.smd-q-text img {
	max-width: 100% !important;
	width: auto !important;
	height: auto !important;
	display: block !important;
	border-radius: 6px !important;
	object-fit: contain !important;
}

.smd-q-text table {
	display: block !important;
	max-width: 100% !important;
	overflow-x: auto !important;
	border-collapse: collapse !important;
	margin: 6px 0 !important;
}

.smd-q-text mjx-container {
	max-width: 100% !important;
	overflow-x: auto !important;
	overflow-y: hidden !important;
}

.smd-q-text p {
	margin-bottom: 6px !important;
}

.smd-q-text p:last-child {
	margin-bottom: 0 !important;
}

.smd-td--r {
	display: flex !important;
	justify-content: center !important;
	align-items: center !important;
	flex-shrink: 0 !important;
	align-self: flex-start !important;
	padding-top: 2px !important;
}

.smd-td--s {
	display: flex !important;
	justify-content: center !important;
	align-items: baseline !important;
	flex-shrink: 0 !important;
	align-self: flex-start !important;
	padding-top: 2px !important;
	white-space: nowrap !important;
}

.smd-score-cell {
	font-size: 14px !important;
	font-weight: 700 !important;
	font-variant-numeric: tabular-nums !important;
}

.smd-score-denom {
	font-size: 11px !important;
	color: #94a3b8 !important;
	font-weight: 500 !important;
	margin-left: 2px !important;
}

/* ── RESPONSIVE MOBILE OPTIMIZATION ── */
@media (max-width: 600px) {
	.smd-header {
		padding: 16px 14px 12px !important;
	}

	.smd-header-tag {
		font-size: 9.5px !important;
		padding: 2px 8px !important;
		margin-bottom: 6px !important;
	}

	.smd-header-title {
		font-size: 14.5px !important;
		margin-bottom: 12px !important;
		line-height: 1.35 !important;
	}

	.smd-score-wrap {
		gap: 12px !important;
	}

	.smd-score-ring-outer {
		width: 80px !important;
		height: 80px !important;
	}

	.smd-ring-svg {
		width: 80px !important;
		height: 80px !important;
	}

	.smd-score-num {
		font-size: 17px !important;
	}

	.smd-score-max {
		font-size: 10px !important;
	}

	.smd-score-stats {
		min-width: 0 !important;
		gap: 6px !important;
	}

	.smd-stat-pill {
		font-size: 11px !important;
		padding: 2px 8px !important;
	}

	.smd-stat-box {
		padding: 6px 4px !important;
	}

	.smd-stat-val {
		font-size: 15px !important;
	}

	.smd-stat-lbl {
		font-size: 9px !important;
	}

	/* Compact Columns on Mobile: maximizes width for question */
	.smd-table-head {
		grid-template-columns: minmax(0, 1fr) 36px 48px !important;
		gap: 6px !important;
		padding: 8px 12px !important;
	}

	.smd-th {
		font-size: 10px !important;
		letter-spacing: 0.2px !important;
	}

	.smd-table-row {
		grid-template-columns: minmax(0, 1fr) 36px 48px !important;
		gap: 6px !important;
		padding: 10px 12px !important;
	}

	.smd-td--q {
		gap: 8px !important;
	}

	.smd-q-num {
		width: 20px !important;
		height: 20px !important;
		font-size: 10px !important;
		border-radius: 5px !important;
		margin-top: 1px !important;
	}

	.smd-q-text {
		font-size: 13px !important;
		line-height: 1.5 !important;
	}

	.smd-status-chip {
		width: 22px !important;
		height: 22px !important;
	}

	.smd-score-cell {
		font-size: 12.5px !important;
	}

	.smd-score-denom {
		font-size: 10px !important;
	}

	.smd-footer {
		padding: 10px 14px !important;
	}

	.smd-btn-detail {
		font-size: 12px !important;
	}
}
</style>