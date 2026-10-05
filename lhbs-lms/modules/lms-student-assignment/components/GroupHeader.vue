<template>
	<v-card class="group-header-card mb-2 w-100" flat border>
		<v-card-text class="py-2">
			<div class="d-flex justify-space-between align-center">
				<div class="d-flex align-center ga-2">
					<div class="">
						<v-icon color="primary" size="20">mdi-folder-text-outline</v-icon>
					</div>
					<div class="group-info">
						<div class="d-flex align-center ga-2 flex-wrap">
							<h3 class="group-title-main">{{ group.title }}</h3>
							<!-- Badge nhận diện nhóm Video tương tác -->
							<v-chip v-if="isInteractiveVideo" size="x-small" color="deep-purple-accent-4" variant="flat" class="text-white font-weight-bold">
								<v-icon start size="12">mdi-video-check-outline</v-icon>Video tương tác
							</v-chip>
						</div>
						<div class="group-meta">
							<span class="text-caption text-medium-emphasis">
								{{ group.questions.length }} câu hỏi
							</span>
							<span class="mx-2">•</span>
							<span class="text-caption text-medium-emphasis">
								Tối đa {{ groupMaxPoint }} điểm
							</span>
						</div>
					</div>
				</div>
				<div class="group-progress-badge">
					<v-chip color="primary" variant="text" size="small" class="progress-chip justify-center font-weight-medium">
						{{ answeredCount }} / {{ group.questions.length }}
					</v-chip>
				</div>
			</div>
			<p v-if="group.description" class="group-description mb-0" style="text-wrap: auto;">
				{{ group.description }}
			</p>
			<!-- Nội dung rich text của Phần hiển thị trực tiếp, không phụ thuộc Media/file; uc-latex-view lọc HTML nguy hiểm. -->
			<uc-latex-view v-if="group.content" class="group-content mb-2" :content="group.content"
				:literal-html-tags="literalHtmlTags" :preserve-html-structure="literalHtmlTags" />

			<!-- Media Section -->
			<div v-if="group.media" class="media-container mt-2">

				<!-- ── GIAO DIỆN VIDEO TƯƠNG TÁC (Toàn màn hình 100%, không cần cột sự kiện phụ) ── -->
				<div v-if="isInteractiveVideo && (interactiveVideoId || group.media?.sourceYT?.source?.length > 0)" class="interactive-video-layout mb-3">
					<!-- Player Video 16:9 mở rộng full chiều ngang -->
					<div class="video-preview-box position-relative w-100" style="aspect-ratio: 16/9; background: #000; border-radius: 8px; overflow: hidden;">
						<!-- YouTube thay thế phần tử player bằng iframe; v-once ngăn Vue patch lại DOM bên thứ ba khi state thời gian đổi. -->
						<div ref="ytWrapper" v-once class="w-100 h-100 position-absolute" style="top: 0; left: 0;">
							<div :id="interactivePlayerId" class="w-100 h-100"></div>
						</div>
						<!-- Overlay nằm ngoài vùng DOM do YouTube quản lý để Vue chỉ cập nhật thuộc tính của chính overlay. -->
						<div class="player-overlay" :style="{ pointerEvents: videoPlaying ? 'auto' : 'none' }" @click="togglePlay"></div>
					</div>

					<!-- Thanh Tua Timeline Tùy chỉnh với marker câu hỏi -->
					<div class="w-100 d-flex flex-column mt-2 px-1">
						<div class="position-relative w-100 d-flex align-center" style="height: 24px;">
							<v-slider v-model="videoCurrentTime" :max="videoDuration || 100" min="0" step="1"
								hide-details density="compact" color="deep-purple-accent-4" track-color="grey-lighten-2"
								:track-size="4" :thumb-size="12"
								@start="onSliderStart"
								@update:model-value="onSliderInput"
								@end="onSliderEnd"
								class="w-100">
							</v-slider>

							<!-- Một chấm đại diện cho một timeMarker; nhiều câu cùng mốc được gộp thành một sự kiện. -->
							<div v-for="marker in interactiveMarkers" :key="marker.key"
								class="interaction-marker-dot"
								:class="{
									'is-completed': isMarkerCompleted(marker),
									'is-active': marker.questions.some(q => activeQuestionId === q.id),
									'is-locked': !isMarkerUnlocked(marker)
								}"
								:style="{ left: 'calc(10px + (100% - 20px) * ' + (marker.time / (videoDuration || 1)) + ')' }"
								@click.stop="seekToQuestion(marker.questions[0])"
								:title="formatTime(marker.time) + ' · ' + marker.questions.length + ' câu hỏi'">
							</div>
						</div>

						<!-- Điều khiển Play/Pause và thời lượng -->
						<div class="d-flex align-center justify-space-between w-100 mt-1">
							<div class="d-flex align-center ga-2">
								<v-btn icon size="x-small" variant="tonal" color="deep-purple-accent-4" @click="togglePlay">
									<v-icon size="18">{{ videoPlaying ? 'mdi-pause' : 'mdi-play' }}</v-icon>
								</v-btn>
								<span class="text-caption font-weight-medium">
									{{ formatTime(videoCurrentTime) }} / {{ formatTime(videoDuration) }}
								</span>
							</div>
							<span class="text-caption text-medium-emphasis">
								{{ interactiveMarkers.length }} mốc / {{ interactiveQuestions.length }} câu hỏi tương tác
							</span>
						</div>
					</div>
				</div>

				<!-- ── VIDEO THƯỜNG (Khi không phải video tương tác) ── -->
				<div v-else-if="group.media?.sourceYT?.source?.length > 0" class="youtube-container">
					<iframe :src="renderUrlYoutube(group.media.sourceYT.source)" frameborder="0"
						allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
						allowfullscreen></iframe>
				</div>

				<uc-wave-audio-player v-if="getAudioSource(group.media)?.length > 0"
					:audio-url="getAudioSource(group.media)" />

				<div v-if="group.media.sourceFiles.image.length > 0" style="min-height: 350px">
					<v-img v-for="file in group.media.sourceFiles.image" :key="file.externalSource || file.source"
						:src="getImageUrl(file)" :lazy-src="getImageUrl(file, 'w200')"
						class="rounded-lg" height="400">
						<template #placeholder>
							<v-row align="center" class="fill-height ma-0" justify="center">
								<v-progress-circular color="grey-lighten-5" indeterminate />
							</v-row>
						</template>
					</v-img>
				</div>

				<div v-if="group.media.sourceFiles.file.length > 0" class="d-flex flex-column ga-2">
					<div v-for="file in group.media.sourceFiles.file" :key="file.externalSource || file.source"
						class="pa-2 rounded-lg" style="border: 1px solid #dbe5ed;">
						<iframe :src="getFileViewerSource(file)" class="assignment-media-file-frame"
							:title="file.name || 'Tệp đính kèm'"></iframe>
					</div>
				</div>
			</div>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		name: 'GroupHeader',
		props: {
			group: {
				type: Object,
				required: true
			},
			answeredCount: {
				type: Number,
				default: 0
			},
			/** Bảng câu trả lời của học sinh { [qid]: { answerData, ... } } */
			userAnswers: {
				type: Object,
				default: () => ({})
			},
			/** ID câu hỏi đang được chọn/active */
			activeQuestionId: {
				type: String,
				default: ''
			},
			/** Vị trí chỉ số nhóm */
			groupIndex: {
				type: Number,
				default: 0
			},
			/** Danh sách câu hỏi đã được mở khóa (truyền từ parent) */
			unlockedIds: {
				type: Array,
				default: () => []
			},
			// Đồng bộ với QuestionCard để phần nội dung nhóm cũng hiển thị mã HTML ở môn Tin học.
			literalHtmlTags: {
				type: Boolean,
				default: false
			}
		},
		emits: ['select-question', 'marker-reached', 'question-unlocked'],
		data() {
			return {
				interactivePlayerId: 'yt-player-' + Math.random().toString(36).substring(2, 9) + '-' + Math.floor(Math.random() * 100000),
				ytPlayer: null,
				videoPlaying: false,
				videoDuration: 0,
				videoCurrentTime: 0,
				// Khi kéo timeline, tạm khóa polling từ YouTube để thumb không bị thời gian cũ ghi đè.
				isDraggingTimeline: false,
				timeCheckTimer: null,
				lastTriggeredMarkerTime: -1,
				unlockedQuestionIds: []
			};
		},
		computed: {
			/** Kiểm tra nhóm có phải là dạng video tương tác hay không */
			isInteractiveVideo() {
				if (!this.group) return false;
				return Boolean(
					this.group.isInteractiveVideo ||
					this.group.media?.type === 'INTERACTIVE_VIDEO' ||
					this.group.media?.interactiveVideo
				);
			},

			/** Lấy YouTube Video ID */
			interactiveVideoId() {
				const source = this.group?.media?.interactiveVideo?.source || this.group?.media?.sourceYT?.source || '';
				if (!source) return '';
				const match = source.match(/[?&]v=([^&]+)|youtu\.be\/([^?]+)|embed\/([^?]+)/);
				return match ? (match[1] || match[2] || match[3]) : '';
			},

			/**
			 * Gom câu hỏi theo timeMarker để đồng bộ với Content Hub.
			 * Dữ liệu cũ dạng mỗi câu một item và dữ liệu mới dạng marker.questions[] đều được hỗ trợ.
			 */
			interactiveMarkers() {
				const byTime = new Map();
				const sourceQuestions = Array.isArray(this.group?.questions) ? this.group.questions : [];
				sourceQuestions.forEach((rawQuestion, rawIndex) => {
					const nestedQuestions = Array.isArray(rawQuestion?.questions)
						? rawQuestion.questions
						: [rawQuestion];
					nestedQuestions.forEach((question, nestedIndex) => {
						if (!question || typeof question !== 'object') return;
						const markerValue = question.timeMarker ?? question.timerMarker ?? question.time
							?? rawQuestion.timeMarker ?? rawQuestion.timerMarker ?? rawQuestion.time;
						if (markerValue === undefined || markerValue === null || markerValue === '') return;
						const time = Math.max(0, Math.floor(Number(markerValue) || 0));
						const key = String(time);
						if (!byTime.has(key)) {
							byTime.set(key, { key: 'marker_' + time, time, questions: [] });
						}
						const marker = byTime.get(key);
						const normalizedQuestion = Number(question.timeMarker) === time
							? question
							: { ...question, timeMarker: time };
						const questionId = normalizedQuestion.id || 'question_' + time + '_' + rawIndex + '_' + nestedIndex;
						if (!marker.questions.some(existing => existing.id === questionId)) {
							marker.questions.push({ ...normalizedQuestion, id: questionId });
						}
					});
				});
				return Array.from(byTime.values()).sort((a, b) => a.time - b.time);
			},

			/** Danh sách câu hỏi có gắn mốc thời gian, dùng cho đếm và trạng thái từng câu. */
			interactiveQuestions() {
				return this.interactiveMarkers.flatMap(marker => marker.questions);
			},

			/** Đếm số câu hỏi tương tác đã hoàn thành */
			completedQuestionsCount() {
				return this.interactiveQuestions.filter(q => this.isQuestionAnswered(q.id)).length;
			},

			groupMaxPoint() {
				if (!this.group?.questions?.length) return 0;
				const total = this.group.questions.reduce(
					(sum, q) => sum + (Number(q.points) || 0),
					0
				);
				return Math.round((total + Number.EPSILON) * 100) / 100;
			}
		},
		watch: {
			'group.media': {
				handler() {
					console.log('[InteractiveVideo] watch group.media changed, isInteractiveVideo:', this.isInteractiveVideo);
					if (this.isInteractiveVideo) {
						this.$nextTick(() => this.initPlayer());
					}
				},
				deep: true
			}
		},
		mounted() {
			console.log('[InteractiveVideo] mounted hook, isInteractiveVideo:', this.isInteractiveVideo, 'videoId:', this.interactiveVideoId, 'group media:', this.group?.media);
			if (this.isInteractiveVideo && this.interactiveVideoId) {
				this.$nextTick(() => this.initPlayer());
			}
		},
		beforeUnmount() {
			this.destroyPlayer();
		},
		methods: {
			// ══════════════════════════════════════════════════════
			// YOUTUBE PLAYER & TIMELINE LOGIC
			// ══════════════════════════════════════════════════════

			ensureYoutubeApiLoaded() {
				console.log('[InteractiveVideo] ensureYoutubeApiLoaded: checking YT API...');
				if (window.YT && window.YT.Player) {
					console.log('[InteractiveVideo] window.YT.Player already available.');
					return Promise.resolve(window.YT);
				}
				if (window.__interactiveYTApiPromise) return window.__interactiveYTApiPromise;
				window.__interactiveYTApiPromise = new Promise(resolve => {
					let checkCount = 0;
					const interval = setInterval(() => {
						checkCount++;
						if (window.YT && window.YT.Player) {
							console.log('[InteractiveVideo] YT API ready via interval polling (' + checkCount * 100 + 'ms)');
							clearInterval(interval);
							resolve(window.YT);
						} else if (checkCount > 100) {
							console.warn('[InteractiveVideo] YT API timeout waiting for script load');
							clearInterval(interval);
							resolve(window.YT || null);
						}
					}, 100);

					const prevReady = window.onYouTubeIframeAPIReady;
					window.onYouTubeIframeAPIReady = () => {
						console.log('[InteractiveVideo] window.onYouTubeIframeAPIReady fired');
						if (typeof prevReady === 'function') prevReady();
						clearInterval(interval);
						resolve(window.YT);
					};
					if (!document.querySelector('script[src*="youtube.com/iframe_api"]')) {
						console.log('[InteractiveVideo] Appending youtube.com/iframe_api script tag to head');
						const script = document.createElement('script');
						script.src = 'https://www.youtube.com/iframe_api';
						document.head.appendChild(script);
					}
				});
				return window.__interactiveYTApiPromise;
			},

			initPlayer() {
				const videoId = this.interactiveVideoId;
				console.log('[InteractiveVideo] initPlayer called, videoId:', videoId, 'playerId:', this.interactivePlayerId);
				if (!videoId) {
					console.warn('[InteractiveVideo] initPlayer aborted: videoId is empty');
					return;
				}

				this.ensureYoutubeApiLoaded().then(() => {
					this.destroyPlayer();
					this.$nextTick(() => {
						const wrapper = this.$refs.ytWrapper;
						console.log('[InteractiveVideo] wrapper ref:', wrapper);
						if (wrapper) {
							wrapper.innerHTML = '';
							const playerDiv = document.createElement('div');
							playerDiv.id = this.interactivePlayerId;
							playerDiv.className = 'w-100 h-100';
							wrapper.appendChild(playerDiv);
							console.log('[InteractiveVideo] Cleaned wrapper and created placeholder div:', playerDiv.id);
						} else {
							let elem = document.getElementById(this.interactivePlayerId);
							if (!elem) {
								const box = this.$el?.querySelector?.('.video-preview-box');
								if (box) {
									elem = document.createElement('div');
									elem.id = this.interactivePlayerId;
									elem.className = 'w-100 h-100';
									box.insertBefore(elem, box.firstChild);
									console.log('[InteractiveVideo] Fallback created div in .video-preview-box:', elem.id);
								}
							}
						}
						if (!window.YT?.Player) {
							console.error('[InteractiveVideo] window.YT.Player is undefined after ensureApiLoaded!');
							return;
						}

						try {
							console.log('[InteractiveVideo] Creating new window.YT.Player for:', this.interactivePlayerId);
							this.ytPlayer = new window.YT.Player(this.interactivePlayerId, {
								height: '100%',
								width: '100%',
								videoId,
								playerVars: {
									controls: 0,
									disablekb: 0,
									modestbranding: 1,
									rel: 0,
									cc_load_policy: 0,
									iv_load_policy: 3,
									enablejsapi: 1,
									origin: window.location.origin
								},
								events: {
										onReady: event => {
											console.log('[InteractiveVideo] onReady fired for:', videoId);
											this.ytPlayer = event.target;
											try {
												const dur = Math.floor(event.target.getDuration?.() || 0);
												console.log('[InteractiveVideo] Duration retrieved onReady:', dur);
												if (dur > 0) this.videoDuration = dur;
											} catch (e) {
												console.warn('[InteractiveVideo] Error getDuration onReady:', e);
											}
											// Khởi động polling ngay khi player sẵn sàng; YouTube có thể không phát
											// lại onStateChange đúng thời điểm thao tác Play đầu tiên.
											this.startTimeCheck();
										},
										onStateChange: event => {
											console.log('[InteractiveVideo] onStateChange:', event.data, '(1=PLAYING, 2=PAUSED, 0=ENDED, 3=BUFFERING)');
											this.ytPlayer = event.target;
										try {
											const dur = Math.floor(event.target.getDuration?.() || 0);
											if (dur > 0) this.videoDuration = dur;
										} catch (e) {}

											const isPlay = event.data === window.YT?.PlayerState?.PLAYING || event.data === 1;
											if (isPlay) {
												this.videoPlaying = true;
												this.startTimeCheck();
											} else if (event.data === 0 || event.data === 2) {
												// Giữ polling sống cả khi PAUSED/ENDED; getCurrentTime() sẽ giữ
												// đúng vị trí cuối và tránh trạng thái callback đến lệch nhịp làm mất timer.
												this.videoPlaying = false;
											}
									},
									onError: event => {
										console.error('[InteractiveVideo] YouTube Player Error code:', event.data, {
											2: 'Tham số không hợp lệ',
											5: 'Lỗi HTML5 Player',
											100: 'Không tìm thấy video / riêng tư',
											101: 'Chủ sở hữu video không cho phép nhúng',
											150: 'Chủ sở hữu video không cho phép nhúng (nhúng bị chặn)'
										}[event.data] || 'Lỗi không xác định');
									}
								}
							});
						} catch (err) {
							console.error('[InteractiveVideo] Exception when calling new YT.Player:', err);
						}
					});
				});
			},

			destroyPlayer() {
				this.stopTimeCheck();
				if (this.ytPlayer) {
					console.log('[InteractiveVideo] destroyPlayer called');
					try { this.ytPlayer.destroy(); } catch (e) {}
					this.ytPlayer = null;
				}
				this.videoPlaying = false;
			},

			startTimeCheck() {
				this.stopTimeCheck();
				this.timeCheckTimer = setInterval(() => {
					// Vuetify cập nhật videoCurrentTime theo thao tác kéo; chỉ đọc lại từ player sau khi thả thanh.
					if (this.isDraggingTimeline) return;
					if (!this.ytPlayer || typeof this.ytPlayer.getCurrentTime !== 'function') return;
					try {
						const current = Math.floor(this.ytPlayer.getCurrentTime() || 0);
						this.videoCurrentTime = current;
						const dur = Math.floor(this.ytPlayer.getDuration() || 0);
						if (dur > 0) this.videoDuration = dur;
						// Callback YouTube đôi khi đến trễ; lấy trạng thái trực tiếp để nút
						// Play/Pause và overlay luôn khớp với iframe thực tế.
						if (typeof this.ytPlayer.getPlayerState === 'function') {
							const playerState = this.ytPlayer.getPlayerState();
							if (playerState === 1) this.videoPlaying = true;
							if (playerState === 0 || playerState === 2) this.videoPlaying = false;
						}
						this.checkTimeMarkers(current);
					} catch (e) {}
				}, 400);
			},

			stopTimeCheck() {
				if (this.timeCheckTimer) {
					clearInterval(this.timeCheckTimer);
					this.timeCheckTimer = null;
				}
			},

			togglePlay() {
				console.log('[InteractiveVideo] togglePlay called, current videoPlaying:', this.videoPlaying, 'player:', this.ytPlayer);
				const player = this.ytPlayer;
				if (!player) {
					console.warn('[InteractiveVideo] Player not found on togglePlay, attempting initPlayer...');
					this.initPlayer();
					return;
				}
				try {
					if (this.videoPlaying) {
						console.log('[InteractiveVideo] Calling pauseVideo()');
											if (typeof player.pauseVideo === 'function') player.pauseVideo();
											this.videoPlaying = false;
										} else {
						console.log('[InteractiveVideo] Calling playVideo()');
						if (typeof player.playVideo === 'function') player.playVideo();
						this.videoPlaying = true;
						this.startTimeCheck();
					}
				} catch (e) {
					console.warn('[InteractiveVideo] Lỗi khi toggle play:', e);
				}
			},

			onSliderStart() {
				this.isDraggingTimeline = true;
			},

			onSliderInput(val) {
				const nextTime = Math.max(0, Number(val) || 0);
				this.videoCurrentTime = nextTime;
			},

			onSliderEnd(val) {
				const nextTime = Math.max(0, Number(val ?? this.videoCurrentTime) || 0);
				this.videoCurrentTime = nextTime;
				this.isDraggingTimeline = false;

				// Chỉ seek một lần khi thả thanh, sau đó để polling lấy lại thời gian thực từ YouTube.
				if (this.ytPlayer && typeof this.ytPlayer.seekTo === 'function') {
					try {
						this.ytPlayer.seekTo(nextTime, true);
						if (this.videoPlaying && typeof this.ytPlayer.playVideo === 'function') this.ytPlayer.playVideo();
					} catch (e) {}
				}
				if (this.videoPlaying) this.startTimeCheck();
			},

			seekToQuestion(q) {
				const time = Number(q.timeMarker || 0);
				console.log('[InteractiveVideo] seekToQuestion:', q.id, 'timeMarker:', time);
				this.videoCurrentTime = time;
				if (this.ytPlayer && typeof this.ytPlayer.seekTo === 'function') {
					try { this.ytPlayer.seekTo(time, true); } catch (e) {}
				}
				this.$emit('select-question', { group: this.group, question: q, groupIndex: this.groupIndex });
			},

			checkTimeMarkers(currentTime) {
				// Mở khóa toàn bộ câu hỏi thuộc marker cùng lúc; học sinh không thể làm
				// trước khi video thực sự đi tới mốc, nhưng vẫn có thể làm lần lượt sau đó.
				this.interactiveMarkers.forEach(marker => {
					if (currentTime < marker.time) return;
					marker.questions.forEach(question => {
						if (!this.unlockedQuestionIds.includes(question.id)) {
							this.unlockedQuestionIds.push(question.id);
							this.$emit('question-unlocked', { questionId: question.id, groupIndex: this.groupIndex });
						}
					});
				});

				if (!this.videoPlaying) return;
				const matchedMarker = this.interactiveMarkers.find(marker => {
					return Math.abs(currentTime - marker.time) <= 1
						&& this.lastTriggeredMarkerTime !== marker.time
						&& marker.questions.some(question => !this.isQuestionAnswered(question.id));
				});

				if (matchedMarker) {
					this.lastTriggeredMarkerTime = matchedMarker.time;
					// Tạm dừng video để học sinh tập trung trả lời nhóm câu hỏi vừa mở khóa.
					if (this.ytPlayer && typeof this.ytPlayer.pauseVideo === 'function') {
						try { this.ytPlayer.pauseVideo(); } catch (e) {}
					}
					const firstUnanswered = matchedMarker.questions.find(question => !this.isQuestionAnswered(question.id));
					this.$emit('marker-reached', {
						group: this.group,
						marker: matchedMarker,
						question: firstUnanswered || matchedMarker.questions[0],
						questions: matchedMarker.questions,
						groupIndex: this.groupIndex
					});
				}
			},

			// ══════════════════════════════════════════════════════
			// HELPER FUNCTIONS
			// ══════════════════════════════════════════════════════

			/** Kiểm tra câu hỏi tương tác đã đến mốc thời gian mở khóa chưa */
			isMarkerCompleted(marker) {
				return Boolean(marker?.questions?.length && marker.questions.every(question => this.isQuestionAnswered(question.id)));
			},

			isMarkerUnlocked(marker) {
				return Boolean(marker?.questions?.some(question => this.isQuestionUnlocked(question)));
			},

			isQuestionUnlocked(q) {
				if (!q) return true;
				if (q.timeMarker === undefined || q.timeMarker === null || q.timeMarker === '') return true;
				if (this.isQuestionAnswered(q.id)) return true;
				if (Array.isArray(this.unlockedIds) && this.unlockedIds.includes(q.id)) return true;
				if (this.unlockedQuestionIds.includes(q.id)) return true;
				return Number(this.videoCurrentTime || 0) >= Number(q.timeMarker);
			},

			isQuestionAnswered(questionId) {
				const ans = this.userAnswers?.[questionId]?.answerData;
				if (ans === null || ans === undefined) return false;
				if (typeof ans === 'string' && ans.trim() === '') return false;
				if (Array.isArray(ans) && ans.length === 0) return false;
				if (typeof ans === 'object' && !Array.isArray(ans) && Object.keys(ans).length === 0) return false;
				return true;
			},

			getQuestionDisplayNumber(question) {
				const idx = (this.group?.questions || []).findIndex(q => q.id === question.id);
				return idx !== -1 ? (idx + 1) : '';
			},

			formatTime(seconds) {
				if (seconds === undefined || seconds === null || isNaN(Number(seconds))) return '00:00';
				const total = Math.max(0, Math.floor(Number(seconds)));
				const mins = Math.floor(total / 60);
				const secs = total % 60;
				return (mins < 10 ? '0' : '') + mins + ':' + (secs < 10 ? '0' : '') + secs;
			},

			stripHtml(html) {
				if (!html) return '';
				return html.replace(/<[^>]*>?/gm, '');
			},

			renderUrlYoutube(url) {
				if (!url) return '';
				let videoId = '';
				const standardMatch = url.match(/[?&]v=([^&]+)/);
				if (standardMatch) videoId = standardMatch[1];
				const shortMatch = url.match(/youtu\.be\/([^?]+)/);
				if (shortMatch) videoId = shortMatch[1];
				const embedMatch = url.match(/embed\/([^?]+)/);
				if (embedMatch) videoId = embedMatch[1];
				if (videoId) return `https://www.youtube.com/embed/${videoId}`;
				return url;
			},

			getDriveFileId(url) {
				if (!url) return null;
				const match = url.match(/\/d\/([^/]+)\//);
				return match ? match[1] : null;
			},

			getMediaSource(file) {
				const source = file?.externalSource || file?.source || '';
				if (/^https?:\/\/lms\.lhbs\.vn\/FileData\//i.test(source)) {
					return source.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/');
				}
				if (/^https?:\/\//i.test(source) || file?.mediaSource !== 'db') return source;
				const base = typeof vueData !== 'undefined' ? (vueData?.v_Set?.urlReadFile || '') : '';
				return base ? `${base.replace(/\/+$/, '')}/${source.replace(/^\/+/, '')}` : source;
			},

			getFileViewerSource(file) {
				const rawSource = file?.dbSource || file?.source || '';
				const isLmsFile = Boolean(file?.dbFileId || file?.resourceFileId || file?.mediaSource === 'db' || /(?:^|\/)FileData\//i.test(rawSource));
				const fileId = file?.dbFileId || file?.resourceFileId || file?.id || String(rawSource).match(/\/FileData\/([^/?#]+)/i)?.[1];
				const rawFileName = file?.name || 'tai-lieu';
				const lastDotIndex = rawFileName.lastIndexOf('.');
				const baseName = lastDotIndex !== -1 ? rawFileName.substring(0, lastDotIndex) : rawFileName;
				const ext = lastDotIndex !== -1 ? rawFileName.substring(lastDotIndex) : '';
				const fileName = `${baseName.replace(/[&+%#?:/\\*"<>|]/g, '_').trim() || 'file'}${ext}`;
				if (!isLmsFile) return file?.externalSource || file?.source || '';
				if (!fileId) return this.getMediaSource(file);
				return `https://file.lhbs.vn/lms/viewer/FileData/${encodeURIComponent(fileId)}/${encodeURIComponent(fileName)}`;
			},

			getAudioSource(media) {
				const record = media?.sourceRecord;
				return record ? this.getMediaSource(record) : '';
			},

			getImageUrl(file, size = 'w1000') {
				const source = this.getMediaSource(file);
				const fileId = this.getDriveFileId(source);
				return fileId ? `https://drive.google.com/thumbnail?id=${file.externalId || fileId}&sz=${size}` : source;
			},

			isPreviewableFile(file) {
				return /\.pdf($|\?)/i.test(file?.name || '') || file?.mimeType === 'application/pdf';
			}
		}
	}
</script>