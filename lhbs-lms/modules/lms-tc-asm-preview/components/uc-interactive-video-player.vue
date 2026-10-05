<template>
	<div class="interactive-video-player-container">
		<!-- Loading state -->
		<div v-if="isLoading" class="player-loading-overlay">
			<v-progress-circular indeterminate color="primary"></v-progress-circular>
			<span class="mt-2 text-caption text-medium-emphasis">Đang tải video...</span>
		</div>

		<!-- Error state -->
		<div v-else-if="error" class="player-error-overlay">
			<v-icon color="error" size="large">mdi-alert-circle-outline</v-icon>
			<p class="mt-2 text-caption text-error">{{ error }}</p>
		</div>

		<!-- Main player layout -->
		<v-row v-else dense class="align-stretch">
			<!-- Video Player & Timeline -->
			<v-col cols="12" :md="hasQuestions ? 8 : 12" :lg="hasQuestions ? 9 : 12">
				<div class="video-screen-box position-relative w-100">
					<!-- YouTube Player -->
					<div v-if="mediaType === 'youtube'" ref="ytWrapper" class="w-100 h-100 position-absolute" style="top: 0; left: 0;">
						<div :id="playerId" class="w-100 h-100"></div>
						<div class="player-overlay-click" @click="togglePlay"></div>
					</div>

					<!-- HTML5 Video Player -->
					<video v-else-if="mediaType === 'video'" ref="htmlVideoPlayer" controls class="w-100 h-100"
						@play="startTimeCheck" @pause="stopTimeCheck" @timeupdate="onHtmlVideoTimeUpdate"
						@loadedmetadata="onHtmlVideoMetadata">
						<source :src="mediaUrl" type="video/mp4">
						Trình duyệt không hỗ trợ xem video trực tiếp.
					</video>
				</div>

				<!-- Custom Timeline Controller -->
				<div class="w-100 d-flex flex-column mt-2 px-1">
					<div ref="timelineTrack" class="position-relative w-100 px-1 d-flex align-center timeline-track-wrapper">
						<v-slider v-model="sliderTime" :max="videoDuration || 100" min="0" step="1"
							hide-details density="compact" color="primary" track-color="grey-lighten-2"
							:track-size="6" :thumb-size="14"
							@start="onSliderStart"
							@update:model-value="onSliderInput"
							@end="onSliderEnd"
							class="w-100 video-timeline-slider">
						</v-slider>

						<!-- Question Markers on Timeline -->
						<div v-for="item in normalizedInteractions" :key="item.id"
							class="interaction-marker-dot"
							:class="getMarkerDotClasses(item)"
							:style="{ left: `calc(10px + (100% - 20px) * ${getMarkerRatio(item.time)})` }"
							@click.stop="onMarkerClick(item)"
							:title="`Câu ${getQuestionIndexDisplay(item.question.id)} tại ${formatTime(item.time)}`">
							<span class="marker-question-number">{{ getQuestionIndexDisplay(item.question.id) }}</span>
						</div>
					</div>

					<!-- Play Controls & Time -->
					<div class="d-flex align-center justify-space-between w-100 mt-1 flex-wrap ga-2">
						<div class="d-flex align-center ga-2">
							<v-btn icon size="small" variant="tonal" color="primary" @click="togglePlay">
								<v-icon>{{ videoPlaying ? 'mdi-pause' : 'mdi-play' }}</v-icon>
							</v-btn>
							<span class="text-caption font-weight-medium">
								{{ formatTime(videoCurrentTime) }} / {{ formatTime(videoDuration) }}
							</span>
						</div>

						<div class="d-flex align-center ga-2" v-if="hasQuestions">
							<v-chip v-if="isGradedEffective" size="small" color="primary" variant="flat" class="font-weight-medium">
								<v-icon start size="14">mdi-trophy-outline</v-icon>
								{{ totalGroupScore }} / {{ totalGroupMaxScore }} điểm
							</v-chip>
							<v-chip size="small" color="primary" variant="tonal" class="font-weight-medium">
								<v-icon start size="14">mdi-help-circle-outline</v-icon>
								{{ answeredQuestionsCount }} / {{ normalizedInteractions.length }} câu hỏi
							</v-chip>
						</div>
					</div>

					<!-- Quick Question Chips Bar (Luôn thấy mốc câu hỏi ngay dưới video trên mọi màn hình) -->
					<div v-if="hasQuestions" class="quick-question-bar d-flex align-center ga-2 mt-2 pa-2 rounded-lg bg-grey-lighten-4 overflow-x-auto">
						<span class="text-caption font-weight-bold text-medium-emphasis flex-shrink-0 d-flex align-center ga-1">
							<v-icon size="14">mdi-map-marker-multiple-outline</v-icon> Mốc câu:
						</span>
						<v-chip v-for="item in sortedInteractions" :key="item.id"
							size="small"
							class="font-weight-medium cursor-pointer flex-shrink-0"
							:color="getQuestionChipColor(item)"
							:variant="getQuestionChipVariant(item)"
							@click="onMarkerClick(item)">
							<v-icon start size="14">{{ getQuestionStatusIcon(item.question.id) }}</v-icon>
							{{ formatTime(item.time) }} - Câu {{ getQuestionIndexDisplay(item.question.id) }}
							<span v-if="isGradedEffective" class="ml-1 font-weight-bold">
								({{ getQuestionScoreText(item.question) }})
							</span>
						</v-chip>
					</div>
				</div>
			</v-col>

			<!-- Right Sidebar: Question Events / Timeline -->
			<v-col v-if="hasQuestions" cols="12" md="4" lg="3">
				<v-card variant="outlined" class="pa-2 h-100 d-flex flex-column question-timeline-card">
					<div class="text-caption font-weight-bold d-flex align-center justify-space-between pb-2 border-b">
						<div class="d-flex align-center ga-1 text-primary">
							<v-icon size="16">mdi-format-list-checks</v-icon>
							<span>Mốc câu hỏi</span>
						</div>
						<div class="d-flex align-center ga-1">
							<v-chip v-if="isGradedEffective" size="x-small" color="primary" variant="flat">
								{{ totalGroupScore }}đ
							</v-chip>
							<span class="text-caption text-medium-emphasis">
								{{ answeredQuestionsCount }}/{{ normalizedInteractions.length }}
							</span>
						</div>
					</div>

					<!-- Question list -->
					<div class="question-events-list flex-grow-1 mt-2">
						<div v-for="item in sortedInteractions" :key="item.id"
							class="question-timeline-item pa-2 mb-2 rounded cursor-pointer transition-swing"
							:class="getSidebarItemClasses(item)"
							@click="onMarkerClick(item)">
							<div class="d-flex justify-space-between align-center mb-1">
								<div class="d-flex align-center ga-1">
									<v-icon size="14" :color="getQuestionIconColor(item.question.id)">
										{{ getQuestionStatusIcon(item.question.id) }}
									</v-icon>
									<span class="text-caption font-weight-bold">
										{{ formatTime(item.time) }} - Câu {{ getQuestionIndexDisplay(item.question.id) }}
									</span>
								</div>
								<v-chip size="x-small" :color="getQuestionStatusBadge(item).color" :variant="getQuestionStatusBadge(item).variant">
									{{ getQuestionStatusBadge(item).label }}
								</v-chip>
							</div>

							<div class="text-caption text-truncate-2 text-medium-emphasis">
								<span v-if="isQuestionUnlocked(item) || isQuestionAnswered(item.question.id) || isGradedEffective">
									{{ stripHtml(item.question.config?.questionText || '') }}
								</span>
								<span v-else class="text-caption text-disabled font-italic d-flex align-center ga-1">
									<v-icon size="12">mdi-lock-outline</v-icon> Xem video đến mốc {{ formatTime(item.time) }} để mở câu hỏi
								</span>
							</div>
						</div>
					</div>
				</v-card>
			</v-col>
		</v-row>

		<!-- Interactive Question Popup (v-dialog) -->
		<v-dialog v-model="showQuestionOverlay" :persistent="!isGradedEffective" max-width="850">
			<v-card v-if="activeQuestion">
				<!-- Header -->
				<v-card-title class="d-flex align-center justify-space-between pa-4 border-b">
					<div class="d-flex align-center ga-2">
						<v-icon :color="getQuestionIconColor(activeQuestion.id)">{{ getQuestionStatusIcon(activeQuestion.id) }}</v-icon>
						<span class="text-subtitle-1 font-weight-bold">
							Câu hỏi tương tác - Câu {{ getQuestionIndexDisplay(activeQuestion.id) }}
						</span>
					</div>
					<div class="d-flex align-center ga-2">
						<v-chip v-if="isGradedEffective" size="small" :color="getQuestionStatusBadge({ question: activeQuestion }).color" variant="flat" class="font-weight-bold">
							{{ getQuestionScoreText(activeQuestion) }}
						</v-chip>
						<v-chip size="small" color="primary" variant="tonal" class="font-weight-bold">
							{{ activeQuestion.points || 1 }} điểm
						</v-chip>
						<v-btn icon size="small" variant="text" @click="closeDialog" title="Đóng">
							<v-icon>mdi-close</v-icon>
						</v-btn>
					</div>
				</v-card-title>

				<!-- Body Question -->
				<v-card-text class="pa-4 pt-3" style="max-height: 70vh; overflow-y: auto;">
					<!-- Question Content Text -->
					<div class="mb-3">
						<uc-latex-view class="question-text flex-column justify-start" :escape-html="false"
							v-model:content="activeQuestion.config.questionText" style="align-items: start !important; width: 100%;" />
					</div>

					<!-- Question Answer Form -->
					<component :is="getQuestionComponent(activeQuestion)"
						:question="activeQuestion"
						:answer="getAnswerForQuestion(activeQuestion)"
						:readonly="readonly"
						:is-block-copy-paste="isBlockCopyPaste"
						:max-points="activeQuestion.points"
						@answer-change="onAnswerChange(activeQuestion.id, $event)" />
				</v-card-text>

				<!-- Actions -->
				<v-card-actions class="pa-3 border-t d-flex align-center ga-2">
					<template v-if="isGradedEffective">
						<v-spacer></v-spacer>
						<v-btn variant="flat" color="primary" @click="closeDialog" class="px-6">
							Đóng
						</v-btn>
					</template>
					<template v-else>
						<v-btn variant="outlined" color="primary" prepend-icon="mdi-rewind-10" @click="watchAgain" class="flex-grow-1">
							Xem lại (10s)
						</v-btn>
						<v-btn variant="flat" color="primary" append-icon="mdi-play" @click="continueVideo" class="flex-grow-1">
							Tiếp tục video
						</v-btn>
					</template>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-interactive-video-player',
		inject: {
			snackbarRef: {
				default: null
			}
		},
		props: {
			url: {
				type: String,
				required: true
			},
			title: {
				type: String,
				default: ''
			},
			questions: {
				type: Array,
				default: () => []
			},
			userAnswers: {
				type: Object,
				default: () => ({})
			},
			readonly: {
				type: Boolean,
				default: false
			},
			isSubmitted: {
				type: Boolean,
				default: false
			},
			isGraded: {
				type: Boolean,
				default: false
			},
			isBlockCopyPaste: {
				type: Boolean,
				default: false
			},
			getGlobalQuestionNumber: {
				type: Function,
				default: null
			}
		},
		emits: ['update:answer', 'flag'],
		data() {
			return {
				playerId: 'yt-interactive-player-' + Math.random().toString(36).substring(2, 9),
				ytPlayer: null,
				mediaType: null, // 'youtube', 'video', 'unknown'
				mediaUrl: '',
				currentProcessedUrl: '',
				currentVideoId: '',
				isLoading: true,
				error: null,

				// Video state
				videoPlaying: false,
				videoDuration: 0,
				videoCurrentTime: 0,
				sliderTime: 0,
				isDraggingSlider: false,
				isSeeking: false,
				seekTargetTime: null,
				seekTimeout: null,
				dragStartTime: 0,
				lastConfirmedTime: 0,
				lastWarningTime: 0,
				timeCheckInterval: null,
				lastTriggeredQuestionId: null,

				// Overlay question state
				activeQuestion: null,
				showQuestionOverlay: false
			};
		},
		computed: {
			hasQuestions() {
				return this.normalizedInteractions && this.normalizedInteractions.length > 0;
			},
			normalizedInteractions() {
				if (!this.questions || !this.questions.length) return [];
				const total = this.questions.length;
				const duration = this.videoDuration || 100;

				return this.questions.map((q, idx) => {
					let time = null;
					if (q.videoTimestamp != null && !isNaN(Number(q.videoTimestamp))) {
						time = Number(q.videoTimestamp);
					} else if (q.config?.videoTimestamp != null && !isNaN(Number(q.config.videoTimestamp))) {
						time = Number(q.config.videoTimestamp);
					} else if (q.time != null && !isNaN(Number(q.time))) {
						time = Number(q.time);
					} else if (q.config?.time != null && !isNaN(Number(q.config.time))) {
						time = Number(q.config.time);
					} else {
						// Tự động chia đều mốc nếu chưa có timestamp cụ thể
						time = Math.max(5, Math.floor((duration * (idx + 1)) / (total + 1)));
					}

					return {
						id: q.id || `q_${idx}`,
						time: time,
						question: q,
						index: idx
					};
				});
			},
			sortedInteractions() {
				return [...this.normalizedInteractions].sort((a, b) => a.time - b.time);
			},
			answeredQuestionsCount() {
				return this.normalizedInteractions.filter(item => this.isQuestionAnswered(item.question.id)).length;
			},
			totalGroupScore() {
				let total = 0;
				for (const item of this.normalizedInteractions) {
					const s = this.getQuestionScore(item.question.id);
					if (s !== null) {
						total += Number(s);
					}
				}
				return Math.round(total * 100) / 100;
			},
			totalGroupMaxScore() {
				let total = 0;
				for (const item of this.normalizedInteractions) {
					const pts = Number(item.question?.points) || 1;
					total += pts;
				}
				return Math.round(total * 100) / 100;
			},
			isGradedEffective() {
				if (this.isGraded) return true;
				if (typeof vueData !== 'undefined' && (vueData.submissionstatus === 4 || vueData.isGrade || vueData.isGraded)) return true;
				return this.normalizedInteractions.some(item => this._getGrading(item.question.id) !== null || this.getQuestionScore(item.question.id) !== null);
			}
		},
		watch: {
			url: {
				handler(newUrl) {
					this.processUrl(newUrl);
				},
				immediate: true
			}
		},
		mounted() {
			const self = this;
			window.onYouTubeIframeAPIReady = () => {
				if (self.mediaUrl && self.mediaType === 'youtube') {
					self.processUrl(self.mediaUrl);
				}
			};
			if (!window.YT) {
				const tag = document.createElement('script');
				tag.src = "https://www.youtube.com/iframe_api";
				const firstScriptTag = document.getElementsByTagName('script')[0];
				if (firstScriptTag && firstScriptTag.parentNode) {
					firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
				} else {
					document.head.appendChild(tag);
				}
			}
		},
		beforeUnmount() {
			this.stopTimeCheck();
			if (this.seekTimeout) {
				clearTimeout(this.seekTimeout);
				this.seekTimeout = null;
			}
			if (this.ytPlayer) {
				try {
					this.ytPlayer.destroy();
				} catch (e) {}
			}
		},
		methods: {
			processUrl(urlStr) {
				if (!urlStr) {
					this.error = "Không có đường dẫn media.";
					this.isLoading = false;
					return;
				}
				if (this.currentProcessedUrl === urlStr && (this.ytPlayer || this.mediaType)) {
					return;
				}
				this.currentProcessedUrl = urlStr;
				this.isLoading = true;
				this.error = null;
				this.stopTimeCheck();

				// Kiểm tra link Youtube
				try {
					let videoId = '';
					if (urlStr.includes('youtube.com') || urlStr.includes('youtu.be')) {
						const url = new URL(urlStr);
						if (url.pathname.includes('embed/')) {
							const urlSplit = url.pathname.split('embed/');
							videoId = urlSplit[1] ? urlSplit[1].split('?')[0].split('&')[0] : '';
						} else if (url.hostname.includes('youtube.com')) {
							videoId = url.searchParams.get('v');
						} else if (url.hostname.includes('youtu.be')) {
							videoId = url.pathname.slice(1).split('?')[0];
						}
						if (!videoId && url.pathname.includes('shorts/')) {
							const urlSplit = url.pathname.split('shorts/');
							videoId = urlSplit[1] ? urlSplit[1].split('?')[0].split('&')[0] : '';
						}
					}

					if (videoId) {
						this.mediaType = 'youtube';
						this.mediaUrl = `https://www.youtube.com/embed/${videoId}`;
						this.isLoading = false;
						this.$nextTick(() => {
							setTimeout(() => {
								this.initYoutubePlayer(videoId);
							}, 200);
						});
						return;
					}
				} catch (e) {
					console.warn('URL parsing error, falling back', e);
				}

				// Direct video URL
				this.mediaType = 'video';
				this.mediaUrl = urlStr;
				this.isLoading = false;
			},

			ensureYoutubeApiLoaded() {
				if (window.YT && window.YT.Player) {
					return Promise.resolve(window.YT);
				}
				if (window.__ytApiPromise) {
					return window.__ytApiPromise;
				}
				window.__ytApiPromise = new Promise((resolve) => {
					const prev = window.onYouTubeIframeAPIReady;
					window.onYouTubeIframeAPIReady = () => {
						if (typeof prev === 'function') prev();
						resolve(window.YT);
					};
					if (!document.querySelector('script[src*="youtube.com/iframe_api"]')) {
						const tag = document.createElement('script');
						tag.src = "https://www.youtube.com/iframe_api";
						const firstScriptTag = document.getElementsByTagName('script')[0];
						if (firstScriptTag && firstScriptTag.parentNode) {
							firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
						} else {
							document.head.appendChild(tag);
						}
					}
				});
				return window.__ytApiPromise;
			},

			initYoutubePlayer(videoId) {
				if (this.currentVideoId === videoId && this.ytPlayer) return;
				this.currentVideoId = videoId;
				const self = this;

				this.ensureYoutubeApiLoaded().then(() => {
					if (self.ytPlayer) {
						try { self.ytPlayer.destroy(); } catch (e) {}
						self.ytPlayer = null;
					}

					const init = () => {
						let playerEl = document.getElementById(self.playerId);
						const wrapper = self.$refs.ytWrapper || (playerEl ? playerEl.parentElement : document.querySelector('.video-screen-box'));
						if (wrapper && !playerEl) {
							playerEl = document.createElement('div');
							playerEl.id = self.playerId;
							playerEl.className = 'w-100 h-100';
							wrapper.insertBefore(playerEl, wrapper.firstChild);
						}
						if (document.getElementById(self.playerId) && window.YT && window.YT.Player) {
							self.ytPlayer = new window.YT.Player(self.playerId, {
								height: '100%',
								width: '100%',
								videoId: videoId,
								playerVars: {
									enablejsapi: 1,
									origin: window.location.origin,
									controls: 1,
									disablekb: 0,
									modestbranding: 1,
									rel: 0,
									cc_load_policy: 0,
									iv_load_policy: 3
								},
								events: {
									'onReady': self.onPlayerReady,
									'onStateChange': self.onPlayerStateChange
								}
							});
						}
					};

					let checkCount = 0;
					const checkYT = setInterval(() => {
						checkCount++;
						const el = document.getElementById(self.playerId);
						if (window.YT && window.YT.Player && el) {
							clearInterval(checkYT);
							init();
						} else if (checkCount > 100) {
							clearInterval(checkYT);
						}
					}, 100);
				});
			},

			onPlayerReady(event) {
				const player = event.target;
				this.ytPlayer = player;
				this.videoDuration = Math.floor(player.getDuration() || 0);
				this.startTimeCheck();
			},

			onPlayerStateChange(event) {
				if (!window.YT) return;
				if (event.data === window.YT.PlayerState.PLAYING) {
					this.videoPlaying = true;
					this.startTimeCheck();
				} else if (event.data === window.YT.PlayerState.PAUSED) {
					this.videoPlaying = false;
					this.startTimeCheck();
					this.updateCurrentTime();
				} else if (event.data === window.YT.PlayerState.ENDED) {
					this.videoPlaying = false;
					this.updateCurrentTime();
				}
			},

			togglePlay() {
				if (this.mediaType === 'youtube' && this.ytPlayer) {
					if (this.videoPlaying) {
						this.ytPlayer.pauseVideo();
						this.videoPlaying = false;
					} else {
						this.ytPlayer.playVideo();
						this.videoPlaying = true;
					}
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					const vid = this.$refs.htmlVideoPlayer;
					if (vid.paused) {
						vid.play();
						this.videoPlaying = true;
					} else {
						vid.pause();
						this.videoPlaying = false;
					}
				}
			},

			startTimeCheck() {
				if (this.timeCheckInterval) return;
				this.timeCheckInterval = setInterval(() => {
					this.updateCurrentTime();
					this.checkVideoInteraction();
				}, 200);
			},

			stopTimeCheck() {
				if (this.timeCheckInterval) {
					clearInterval(this.timeCheckInterval);
					this.timeCheckInterval = null;
				}
			},

			updateCurrentTime() {
				if (this.isDraggingSlider) return;

				if (this.mediaType === 'youtube' && this.ytPlayer && typeof this.ytPlayer.getCurrentTime === 'function') {
					try {
						const cur = Math.floor(this.ytPlayer.getCurrentTime() || 0);
						const dur = Math.floor(this.ytPlayer.getDuration() || 0);
						if (dur > 0 && (!this.videoDuration || this.videoDuration < 5)) {
							this.videoDuration = dur;
						}

						// Bảo vệ khi đang seek: không cho giá trị 0 hoặc giá trị cũ đè lên seekTargetTime
						if (this.isSeeking) {
							if (this.seekTargetTime != null && Math.abs(cur - this.seekTargetTime) <= 2) {
								this.isSeeking = false;
								this.seekTargetTime = null;
							} else {
								if (this.seekTargetTime != null) {
									this.videoCurrentTime = this.seekTargetTime;
									this.sliderTime = this.seekTargetTime;
								}
								return;
							}
						}

						this.videoCurrentTime = cur;
						if (!this.isDraggingSlider) {
							this.sliderTime = cur;
						}
					} catch (e) {}
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					const cur = Math.floor(this.$refs.htmlVideoPlayer.currentTime || 0);
					const dur = Math.floor(this.$refs.htmlVideoPlayer.duration || 0);
					if (dur > 0 && (!this.videoDuration || this.videoDuration < 5)) {
						this.videoDuration = dur;
					}
					if (this.isSeeking) {
						if (this.seekTargetTime != null && Math.abs(cur - this.seekTargetTime) <= 2) {
							this.isSeeking = false;
							this.seekTargetTime = null;
						} else {
							if (this.seekTargetTime != null) {
								this.videoCurrentTime = this.seekTargetTime;
								this.sliderTime = this.seekTargetTime;
							}
							return;
						}
					}
					this.videoCurrentTime = cur;
					if (!this.isDraggingSlider) {
						this.sliderTime = cur;
					}
				}
			},

			checkVideoInteraction() {
				if (this.isSubmitted || this.isGradedEffective) return;
				if (!this.normalizedInteractions.length) return;
				const curTime = this.videoCurrentTime;

				// Tìm câu hỏi tại mốc hiện tại chưa trả lời
				const target = this.normalizedInteractions.find(
					item => curTime >= item.time &&
					curTime <= item.time + 2 &&
					!this.isQuestionAnswered(item.question.id) &&
					this.lastTriggeredQuestionId !== item.question.id
				);

				if (target) {
					this.lastTriggeredQuestionId = target.question.id;
					this.triggerQuestion(target.question);
				}
			},

			triggerQuestion(question) {
				this.stopTimeCheck();
				this.videoPlaying = false;
				if (this.mediaType === 'youtube' && this.ytPlayer && typeof this.ytPlayer.pauseVideo === 'function') {
					try { this.ytPlayer.pauseVideo(); } catch(e) {}
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.pause();
				}

				this.activeQuestion = question;
				this.showQuestionOverlay = true;
			},

			onMarkerClick(item) {
				if (!this.isGradedEffective && !this.isSubmitted && !this.readonly) {
					// Khi click vào mốc câu hỏi: kiểm tra nếu mốc này vượt qua câu hỏi chưa trả lời phía trước
					const unanswered = this.normalizedInteractions
						.filter(i => !this.isQuestionAnswered(i.question.id))
						.map(i => i.time);

					if (unanswered.length > 0) {
						const earliestUnansweredTime = Math.min(...unanswered);
						if (item.time > earliestUnansweredTime) {
							this.showToast("⚠️ Vui lòng hoàn thành câu hỏi trước đó trước khi làm câu này nhé!", "warning");
							// Chuyển tới câu hỏi chưa trả lời đầu tiên
							const earliestItem = this.normalizedInteractions.find(i => i.time === earliestUnansweredTime);
							if (earliestItem) {
								this.seekVideo(earliestItem.time, true);
								this.triggerQuestion(earliestItem.question);
							}
							return;
						}
					}
				}

				this.seekVideo(item.time, true);
				this.triggerQuestion(item.question);
			},

			seekVideo(seconds, bypassCheck = false) {
				let sec = Math.floor(Number(seconds) || 0);
				if (this.videoDuration > 0) {
					sec = Math.min(this.videoDuration, Math.max(0, sec));
				}

				// Anti-skip check khi kéo thanh tua: không cho tua qua câu hỏi chưa trả lời
				if (!bypassCheck && !this.isGradedEffective && !this.isSubmitted && !this.readonly) {
					const unanswered = this.normalizedInteractions
						.filter(item => !this.isQuestionAnswered(item.question.id))
						.map(item => item.time);

					if (unanswered.length > 0) {
						const nextUnanswered = Math.min(...unanswered);
						if (sec > nextUnanswered) {
							sec = nextUnanswered;
							const now = Date.now();
							if (!this.lastWarningTime || now - this.lastWarningTime > 1500) {
								this.lastWarningTime = now;
								this.showToast("⚠️ Vui lòng hoàn thành câu hỏi trước khi xem tiếp nhé!", "warning");
							}
						}
					}
				}

				this.videoCurrentTime = sec;
				this.sliderTime = sec;
				this.lastConfirmedTime = sec;
				this.seekTargetTime = sec;
				this.isSeeking = true;

				if (this.seekTimeout) clearTimeout(this.seekTimeout);
				this.seekTimeout = setTimeout(() => {
					this.isSeeking = false;
					this.seekTargetTime = null;
				}, 2000);

				if (this.mediaType === 'youtube' && this.ytPlayer && typeof this.ytPlayer.seekTo === 'function') {
					try {
						this.ytPlayer.seekTo(sec, true);
						if (this.videoPlaying && typeof this.ytPlayer.playVideo === 'function') {
							this.ytPlayer.playVideo();
						}
					} catch(e) {}
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.currentTime = sec;
					if (this.videoPlaying) {
						this.$refs.htmlVideoPlayer.play();
					}
				}

				this.startTimeCheck();
			},

			watchAgain() {
				if (!this.activeQuestion) return;
				const item = this.normalizedInteractions.find(i => i.question.id === this.activeQuestion.id);
				const targetTime = Math.max(0, (item?.time || this.videoCurrentTime) - 10);
				this.showQuestionOverlay = false;
				this.activeQuestion = null;
				this.lastTriggeredQuestionId = null;

				this.seekVideo(targetTime);
				if (this.mediaType === 'youtube' && this.ytPlayer && typeof this.ytPlayer.playVideo === 'function') {
					this.ytPlayer.playVideo();
					this.videoPlaying = true;
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.play();
					this.videoPlaying = true;
				}
			},

			closeDialog() {
				this.showQuestionOverlay = false;
				this.activeQuestion = null;
				this.lastTriggeredQuestionId = null;
			},

			continueVideo() {
				this.showQuestionOverlay = false;
				this.activeQuestion = null;
				this.lastTriggeredQuestionId = null;

				if (this.mediaType === 'youtube' && this.ytPlayer && typeof this.ytPlayer.playVideo === 'function') {
					this.ytPlayer.playVideo();
					this.videoPlaying = true;
					this.startTimeCheck();
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.play();
					this.videoPlaying = true;
				}
			},

			onSliderStart() {
				this.isDraggingSlider = true;
				this.dragStartTime = this.videoCurrentTime;
			},

			onSliderInput(val) {
				this.isDraggingSlider = true;
				if (typeof val === 'number') {
					this.sliderTime = val;
					this.videoCurrentTime = val;
				} else if (val != null && !isNaN(Number(val))) {
					const n = Number(val);
					this.sliderTime = n;
					this.videoCurrentTime = n;
				}
			},

			onSliderEnd(val) {
				this.isDraggingSlider = false;
				let sec = this.sliderTime;
				if (typeof val === 'number') {
					sec = val;
				} else if (val != null && !isNaN(Number(val))) {
					sec = Number(val);
				}
				this.seekVideo(sec);
			},

			getMarkerRatio(time) {
				const dur = this.videoDuration || 1;
				return Math.min(1, Math.max(0, time / dur));
			},

			isQuestionUnlocked(item) {
				if (this.readonly || this.isSubmitted || this.isGradedEffective) return true;
				if (!item) return false;
				if (this.isQuestionAnswered(item.question?.id || item.id)) return true;
				return (this.videoCurrentTime || 0) >= item.time;
			},

			_getGrading(questionId) {
				return this.userAnswers?.[questionId]?.grading 
					|| (typeof vueData !== 'undefined' ? vueData.userAnswersSubmitted?.[questionId]?.grading : null)
					|| (typeof vueData !== 'undefined' ? vueData.puseranswers?.[questionId]?.grading : null)
					|| null;
			},

			getQuestionScore(questionId) {
				const g = this._getGrading(questionId);
				if (g) {
					if (typeof g.manualScore === 'number') return g.manualScore;
					if (typeof g.autoScore === 'number') return g.autoScore;
					if (typeof g.score === 'number') return g.score;
					if (g.manualScore !== null && g.manualScore !== undefined && !isNaN(Number(g.manualScore))) return Number(g.manualScore);
					if (g.autoScore !== null && g.autoScore !== undefined && !isNaN(Number(g.autoScore))) return Number(g.autoScore);
					if (g.score !== null && g.score !== undefined && !isNaN(Number(g.score))) return Number(g.score);
					if (g.isCorrect === true) return 1;
					if (g.isCorrect === false) return 0;
				}
				const qObj = this.userAnswers?.[questionId] 
					|| (typeof vueData !== 'undefined' ? vueData.userAnswersSubmitted?.[questionId] : null)
					|| (typeof vueData !== 'undefined' ? vueData.puseranswers?.[questionId] : null);
				if (qObj) {
					if (typeof qObj.manualScore === 'number') return qObj.manualScore;
					if (typeof qObj.autoScore === 'number') return qObj.autoScore;
					if (typeof qObj.score === 'number') return qObj.score;
					if (qObj.manualScore !== null && qObj.manualScore !== undefined && !isNaN(Number(qObj.manualScore))) return Number(qObj.manualScore);
					if (qObj.autoScore !== null && qObj.autoScore !== undefined && !isNaN(Number(qObj.autoScore))) return Number(qObj.autoScore);
					if (qObj.score !== null && qObj.score !== undefined && !isNaN(Number(qObj.score))) return Number(qObj.score);
					if (qObj.isCorrect === true) return 1;
					if (qObj.isCorrect === false) return 0;
				}
				return null;
			},

			getQuestionScoreText(question) {
				if (!question) return '';
				const maxPts = Number(question.points) || 1;
				const score = this.getQuestionScore(question.id);
				if (score === null) return `?/${maxPts}đ`;
				return `${Math.round(score * 100) / 100}/${maxPts}đ`;
			},

			getQuestionStatusBadge(item) {
				if (!item) return { label: 'Chưa làm', color: 'default', variant: 'tonal' };
				const q = item.question || item;
				const qId = q.id;
				const answered = this.isQuestionAnswered(qId);
				const unlocked = this.isQuestionUnlocked(item);

				if (this.isGradedEffective) {
					const score = this.getQuestionScore(qId);
					const grading = this._getGrading(qId);
					const maxPts = Number(q.points) || 1;

					if (!answered && score === null && grading?.isCorrect === undefined) {
						return { label: 'Chưa làm', color: 'grey', variant: 'tonal' };
					}
					if (grading?.isCorrect === true || (score !== null && score >= maxPts)) {
						return { label: 'Đúng', color: 'success', variant: 'flat' };
					}
					if (score !== null && score > 0 && score < maxPts) {
						return { label: 'Một phần', color: 'warning', variant: 'flat' };
					}
					if (score === 0 || grading?.isCorrect === false) {
						return { label: 'Sai', color: 'error', variant: 'flat' };
					}
					if (score === null && grading?.isCorrect === undefined) {
						return { label: 'Chờ chấm', color: 'grey', variant: 'tonal' };
					}
					return { label: 'Đúng', color: 'success', variant: 'flat' };
				}

				if (answered) {
					return { label: 'Đã làm', color: 'success', variant: 'tonal' };
				}
				if (unlocked) {
					return { label: 'Chưa làm', color: 'primary', variant: 'tonal' };
				}
				return { label: 'Chưa mở', color: 'grey', variant: 'tonal' };
			},

			getQuestionStatusIcon(questionId) {
				const item = this.normalizedInteractions.find(i => i.question.id === questionId);
				const question = item?.question;
				const answered = this.isQuestionAnswered(questionId);

				if (this.isGradedEffective) {
					const grading = this._getGrading(questionId);
					const score = this.getQuestionScore(questionId);
					const maxPts = Number(question?.points) || 1;

					if (grading?.isCorrect === true || (score !== null && score >= maxPts)) {
						return 'mdi-check-circle';
					}
					if (score !== null && score > 0 && score < maxPts) {
						return 'mdi-minus-circle-outline';
					}
					if (score === 0 || grading?.isCorrect === false) {
						return 'mdi-close-circle';
					}
					if (!answered && score === null && grading?.isCorrect === undefined) {
						return 'mdi-help-circle-outline';
					}
					return 'mdi-check-circle';
				}

				if (answered) return 'mdi-check-circle';
				if (item && this.isQuestionUnlocked(item)) return 'mdi-clock-outline';
				return 'mdi-lock-outline';
			},

			getQuestionIconColor(questionId) {
				const item = this.normalizedInteractions.find(i => i.question.id === questionId);
				const question = item?.question;
				const answered = this.isQuestionAnswered(questionId);

				if (this.isGradedEffective) {
					const grading = this._getGrading(questionId);
					const score = this.getQuestionScore(questionId);
					const maxPts = Number(question?.points) || 1;

					if (grading?.isCorrect === true || (score !== null && score >= maxPts)) return 'success';
					if (score !== null && score > 0 && score < maxPts) return 'warning';
					if (score === 0 || grading?.isCorrect === false) return 'error';
					if (!answered && score === null && grading?.isCorrect === undefined) return 'grey';
					return 'success';
				}

				if (answered) return 'success';
				if (item && this.isQuestionUnlocked(item)) return 'primary';
				return 'grey';
			},

			getQuestionChipColor(item) {
				const qId = item.question.id;
				const answered = this.isQuestionAnswered(qId);
				const isActive = this.activeQuestion && this.activeQuestion.id === qId;

				if (this.isGradedEffective) {
					const iconColor = this.getQuestionIconColor(qId);
					if (iconColor === 'success') return 'success';
					if (iconColor === 'warning') return 'warning';
					if (iconColor === 'error') return 'error';
					return 'default';
				}

				if (answered) return 'success';
				if (isActive) return 'primary';
				return 'default';
			},

			getQuestionChipVariant(item) {
				const qId = item.question.id;
				const answered = this.isQuestionAnswered(qId);
				const isActive = this.activeQuestion && this.activeQuestion.id === qId;

				if (this.isGradedEffective) {
					return 'flat';
				}

				if (answered) return 'flat';
				if (isActive) return 'elevated';
				return 'tonal';
			},

			getMarkerDotClasses(item) {
				const qId = item.question.id;
				const answered = this.isQuestionAnswered(qId);
				const isActive = this.activeQuestion && this.activeQuestion.id === qId;

				const classes = {
					'is-active': isActive,
					'is-answered': answered
				};

				if (this.isGradedEffective) {
					const iconColor = this.getQuestionIconColor(qId);
					if (iconColor === 'success') classes['is-correct'] = true;
					else if (iconColor === 'error') classes['is-wrong'] = true;
					else if (iconColor === 'warning') classes['is-partial'] = true;
				}

				return classes;
			},

			getSidebarItemClasses(item) {
				const qId = item.question.id;
				const answered = this.isQuestionAnswered(qId);
				const isActive = this.activeQuestion && this.activeQuestion.id === qId;

				if (this.isGradedEffective) {
					const iconColor = this.getQuestionIconColor(qId);
					if (iconColor === 'success') {
						return isActive ? 'bg-green-lighten-4 border-success' : 'bg-green-lighten-5';
					}
					if (iconColor === 'error') {
						return isActive ? 'bg-red-lighten-4 border-error' : 'bg-red-lighten-5';
					}
					if (iconColor === 'warning') {
						return isActive ? 'bg-amber-lighten-4 border-warning' : 'bg-amber-lighten-5';
					}
					return isActive ? 'bg-grey-lighten-3' : 'bg-grey-lighten-4';
				}

				if (isActive) return 'bg-primary-lighten-5 border-primary';
				if (answered) return 'bg-green-lighten-5';
				return 'bg-grey-lighten-4';
			},

			isQuestionAnswered(questionId) {
				const qObj = this.userAnswers?.[questionId];
				const ans = qObj?.answerData !== undefined ? qObj.answerData : (qObj?.answer !== undefined ? qObj.answer : qObj);
				if (ans === undefined || ans === null) return false;
				if (typeof ans === 'string') return ans.trim().length > 0;
				if (Array.isArray(ans)) return ans.length > 0;
				if (typeof ans === 'object') return Object.keys(ans).length > 0;
				return true;
			},

			getAnswerForQuestion(question) {
				if (!question) return null;
				const questionId = typeof question === 'object' ? question.id : question;
				const qType = typeof question === 'object' ? question.type : null;
				const qObj = this.userAnswers?.[questionId];
				const raw = qObj?.answerData !== undefined ? qObj.answerData : (qObj?.answer !== undefined ? qObj.answer : null);

				if (qType === 'FILE_UPLOAD') {
					return (raw === undefined || raw === null) ? [] : (Array.isArray(raw) ? raw : [raw]);
				}
				return raw;
			},

			onAnswerChange(questionId, newAnswer) {
				this.$emit('update:answer', { questionId, answer: newAnswer });
			},

			getQuestionIndexDisplay(questionId) {
				if (typeof this.getGlobalQuestionNumber === 'function') {
					const num = this.getGlobalQuestionNumber(questionId);
					if (num) return num;
				}
				const idx = this.questions.findIndex(q => q.id === questionId);
				return idx >= 0 ? idx + 1 : 1;
			},

			getQuestionComponent(question) {
				if (!question?.type) return 'div';
				const map = {
					'QUIZ_SINGLE_CHOICE': 'uc-question-single-choice',
					'QUIZ_MULTIPLE_CHOICE': 'uc-question-multiple-choice',
					'QUIZ_TRUE_FALSE': 'uc-question-true-false',
					'QUIZ_MULTIPLE_TRUE_FALSE': 'uc-question-multiple-true-false',
					'QUIZ_FILL_IN_BLANK': 'uc-question-fill-in-blank',
					'QUIZ_MATCHING': 'uc-question-matching',
					'SHORT_ANSWER': 'uc-question-short-answer',
					'ESSAY': 'uc-question-essay',
					'FILE_UPLOAD': 'uc-question-file-upload',
					'AUDIO_RESPONSE': 'uc-question-audio-response'
				};
				return map[question.type] || 'div';
			},

			formatTime(seconds) {
				if (!seconds || isNaN(seconds)) return '00:00';
				const h = Math.floor(seconds / 3600);
				const m = Math.floor((seconds % 3600) / 60);
				const s = Math.floor(seconds % 60);
				const mm = m < 10 ? '0' + m : m;
				const ss = s < 10 ? '0' + s : s;
				if (h > 0) {
					const hh = h < 10 ? '0' + h : h;
					return `${hh}:${mm}:${ss}`;
				}
				return `${mm}:${ss}`;
			},

			stripHtml(html) {
				if (!html) return '';
				return html.replace(/<[^>]*>?/gm, '').trim();
			},

			showToast(msg, type = 'warning') {
				if (this.snackbarRef?.value?.showSnackbar) {
					this.snackbarRef.value.showSnackbar({
						message: msg,
						color: type === 'warning' ? 'warning' : (type === 'error' ? 'error' : (type === 'success' ? 'success' : 'info'))
					});
				} else if (typeof toastr !== 'undefined' && typeof toastr[type] === 'function') {
					toastr[type](msg);
				} else {
					console.warn(msg);
				}
			},

			onHtmlVideoTimeUpdate(e) {
				if (!this.isDraggingSlider && this.$refs.htmlVideoPlayer) {
					this.videoCurrentTime = Math.floor(this.$refs.htmlVideoPlayer.currentTime || 0);
					this.checkVideoInteraction();
				}
			},

			onHtmlVideoMetadata(e) {
				if (this.$refs.htmlVideoPlayer) {
					this.videoDuration = Math.floor(this.$refs.htmlVideoPlayer.duration || 0);
				}
			}
		}
	}
</script>