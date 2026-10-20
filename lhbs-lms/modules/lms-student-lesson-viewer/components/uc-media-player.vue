<template>
	<div class="media-player-container">
		<!-- Hiển thị tiêu đề nếu có -->
		<h3 v-if="title" class="media-title">{{ title }}</h3>

		<!-- Trạng thái Loading -->
		<div v-if="isLoading" class="loading-overlay">
			<v-progress-circular indeterminate color="primary"></v-progress-circular>
		</div>

		<!-- Trạng thái Lỗi -->
		<div v-else-if="error" class="error-overlay">
			<v-icon color="error" size="x-large">mdi-alert-circle-outline</v-icon>
			<p class="mt-2">{{ error }}</p>
		</div>

		<!-- Giao diện 2 cột khi phát video (YouTube/HTML5 Video) -->
		<v-row v-else-if="mediaType === 'youtube' || mediaType === 'video'">
			<!-- Cột trái: Trình phát và thanh Timeline (chiếm 9/12 cột để phóng to tối đa) -->
			<!-- Video không có câu hỏi thì ẩn sidebar và dùng toàn bộ chiều rộng để tránh vùng trống. -->
			<v-col cols="12" :md="normalizedInteractions.length > 0 ? 9 : 12">
			<div ref="videoPreviewBox" class="video-preview-box position-relative w-100" style="aspect-ratio: 16/9; background: #000; border-radius: 8px; overflow: hidden; width: 100%;">
					<div v-if="mediaType === 'youtube'" key="yt-preview-box" ref="ytWrapper" class="w-100 h-100 position-absolute" style="top: 0; left: 0;">
						<div :id="playerId" class="w-100 h-100"></div>
						<div class="player-overlay" @click="togglePlay"></div>
					</div>
					<video v-else key="html-preview-box" ref="htmlVideoPlayer" controls class="w-100 h-100"
						@play="startTimeCheck" @pause="stopTimeCheck" @timeupdate="onHtmlVideoTimeUpdate"
						@loadedmetadata="onHtmlVideoMetadata">
						<source :src="mediaUrl" type="video/mp4">
						Trình duyệt không hỗ trợ xem video trực tiếp.
					</video>
				</div>

				<!-- Thanh Tua Timeline Tùy chỉnh (Giống mockup) -->
				<div class="w-100 d-flex flex-column mt-3 mb-4">
					<div ref="timelineTrack" class="position-relative w-100 px-1 mb-2 d-flex align-center" style="height: 20px;"
						@mousedown="onTimelineTrackMouseDown"
						@touchstart="onTimelineTrackMouseDown">
						<v-slider v-model="videoCurrentTime" :max="videoDuration || 100" min="0" step="1"
							hide-details density="compact" color="success" track-color="grey-lighten-2"
							:track-size="4" :thumb-size="12"
							@update:model-value="onVideoSliderEnd"
							@change="onVideoSliderEnd"
							class="w-100">
						</v-slider>
						
						<!-- Hiển thị các chấm câu hỏi trắc nghiệm (Căn lề chuẩn xác 100% theo vạch slider) -->
						<div v-for="(item, idx) in normalizedInteractions" :key="idx" 
							class="interaction-marker-dot"
							:style="{ left: `calc(11.5px + (100% - 23px) * ${item.time / (videoDuration || 1)})` }"
							@click.stop="seekVideo(item.time)"
							:title="`Câu hỏi tại giây thứ ${item.time}`">
						</div>
					</div>
					
					<!-- Thanh điều khiển bổ sung cho YouTube vì player đang tắt controls mặc định; HTML5 video cũng dùng chung để giao diện nhất quán. -->
					<div class="d-flex align-center justify-space-between flex-wrap ga-2 w-100">
						<div class="d-flex align-center ga-2">
							<v-btn icon size="small" variant="tonal" color="success" @click="togglePlay">
								<v-icon>{{ videoPlaying ? 'mdi-pause' : 'mdi-play' }}</v-icon>
							</v-btn>
							<span class="text-caption font-weight-medium text-grey-darken-2 text-no-wrap">
								{{ formatTime(videoCurrentTime) }} / {{ formatTime(videoDuration) }}
							</span>
						</div>

						<div class="d-flex align-center ga-1">
							<v-menu location="top">
								<template v-slot:activator="{ props }">
									<v-btn v-bind="props" size="small" variant="text" color="grey-darken-2" class="px-2"
										:title="'Tốc độ phát: ' + playbackRate + 'x'">
										{{ playbackRate }}x
									</v-btn>
								</template>
								<v-list density="compact" min-width="110">
									<v-list-item v-for="rate in playbackRates" :key="rate" :active="playbackRate === rate"
										@click="setPlaybackRate(rate)">
										<v-list-item-title>{{ rate }}x</v-list-item-title>
									</v-list-item>
								</v-list>
							</v-menu>

							<v-btn icon size="small" variant="text" color="grey-darken-2" @click="toggleMute"
								:title="isMuted ? 'Bật âm thanh' : 'Tắt âm thanh'">
								<v-icon>{{ volumeIcon }}</v-icon>
							</v-btn>
							<!-- Dùng range native để đường âm lượng luôn nhìn thấy ổn định giữa các bản Vuetify/trình duyệt. -->
							<input type="range" v-model.number="volume" class="video-volume-range d-none d-sm-flex" min="0" max="1" step="0.05"
								:style="{ '--volume-percent': (volume * 100) + '%' }"
								:aria-label="'Âm lượng ' + Math.round(volume * 100) + '%'" @input="setVolume($event.target.value)">

							<v-btn icon size="small" variant="text" color="grey-darken-2" @click="toggleFullscreen"
								:title="isFullscreen ? 'Thoát toàn màn hình' : 'Toàn màn hình'">
								<v-icon>{{ isFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
							</v-btn>
						</div>
					</div>
				</div>
			</v-col>

			<!-- Chỉ hiển thị danh sách sự kiện khi video thực sự có câu hỏi tương tác. -->
			<v-col v-if="normalizedInteractions.length > 0" cols="12" md="3">
				<v-card variant="outlined" class="pa-4 h-100 d-flex flex-column" style="min-height: 350px; overflow: hidden !important;">
					<v-card-title class="text-subtitle-1 font-weight-bold pa-0 mb-3 d-flex align-center">
						<v-icon color="primary" class="mr-2">mdi-format-list-bulleted</v-icon>
						Sự kiện Video
					</v-card-title>
					<v-divider class="mb-4"></v-divider>
					
					<!-- Timeline dọc (Vertical Timeline) -->
					<div class="video-events-list flex-grow-1 pr-1">
						<div v-for="(item, idx) in sortedInteractions" :key="item.id" class="event-timeline-item d-flex align-start mb-4">
							<!-- Cột mốc trạng thái (Chấm tròn và đường kẻ nối) -->
							<div class="timeline-indicator-col d-flex flex-column align-center mr-3" style="height: 100%;">
								<div class="timeline-dot" 
									:class="{ 'is-completed': completedInteractions.includes(item.id), 'is-active': activeInteraction && activeInteraction.id === item.id }">
									<v-icon v-if="completedInteractions.includes(item.id)" size="x-small" color="white">mdi-check</v-icon>
								</div>
								<div v-if="idx < sortedInteractions.length - 1" class="timeline-line"></div>
							</div>
							
							<!-- Cột thông tin chi tiết (không clickable, text màu đậm dễ nhìn) -->
							<div class="event-details flex-grow-1" style="cursor: default;">
								<div class="text-caption font-weight-bold d-flex justify-space-between align-center">
									<span class="font-weight-bold" style="color: #1a252f !important; font-size: 0.85rem;">
										{{ formatTime(item.time) }}
									</span>
									<v-chip size="x-small" :color="completedInteractions.includes(item.id) ? 'success' : getTypeBadgeColor(getInteractionType(item))" variant="flat" style="color: #ffffff !important; font-weight: 700;">
										{{ getTypeName(getInteractionType(item)) }}
									</v-chip>
								</div>
								<div class="text-body-2 mt-1" style="color: #2c3e50 !important; font-weight: 500;" :title="stripHtml(item.question?.content?.prompt || item.prompt)" v-html="item.question?.content?.prompt || item.prompt">
								</div>
							</div>
						</div>
						<div v-if="normalizedInteractions.length === 0" class="text-center text-grey py-8">
							Video này không có câu hỏi tương tác.
						</div>
					</div>
				</v-card>
			</v-col>
		</v-row>

		<!-- Trình phát Audio (thẻ <audio> của HTML5) -->
		<div v-else-if="mediaType === 'audio'" class="audio-wrapper">
			<audio controls :src="mediaUrl" class="w-100">
				Trình duyệt của bạn không hỗ trợ thẻ audio.
			</audio>
		</div>

		<!-- Trường hợp URL không được hỗ trợ -->
		<div v-else class="unsupported-wrapper">
			<p>Loại media không được hỗ trợ hoặc đường dẫn không hợp lệ.</p>
			<a :href="url" target="_blank" v-if="url">Mở link trực tiếp</a>
		</div>

		<!-- Overlay câu hỏi tương tác dành cho học sinh (Hỗ trợ đầy đủ cả 8 dạng câu hỏi) -->
		<v-dialog v-model="showInteractionOverlay" persistent max-width="850">
			<v-card v-if="activeInteraction" style="border-radius: 16px; overflow: hidden; box-shadow: 0 12px 36px rgba(0,0,0,0.25) !important;">
				<v-card-title class="d-flex align-center pa-4 style-header" style="background: linear-gradient(135deg, #059669 0%, #10b981 100%) !important; color: #ffffff !important;">
					<v-icon class="mr-2" style="color: #ffffff !important;">mdi-help-circle-outline</v-icon>
					<span class="text-subtitle-1 font-weight-bold" style="color: #ffffff !important;">
						Câu hỏi tương tác ({{ getTypeName(getInteractionType(activeInteraction)) }})
					</span>
				</v-card-title>
				<v-card-text class="pa-4 pt-4" style="max-height: 70vh; overflow-y: auto;">
					<!-- Nhúng uc-slide-viewer-v3 để hiển thị trọn vẹn cả 8 dạng câu hỏi với đầy đủ tính năng drag-drop, latex... -->
					<uc-slide-viewer-v3 
						v-if="activeInteractionSlideData" 
						:key="activeInteraction.id"
						:slide-data="activeInteractionSlideData" 
						@quiz-result="onInteractionQuizResult" />
				</v-card-text>
				<v-card-actions class="lh-dialog-actions border-t d-flex align-center ga-2 bg-slate-50">
					<button type="button" class="lh-custom-btn lh-btn-rewind flex-grow-1" @click="watchAgain">
						<v-icon size="small" class="mr-1">mdi-rewind-10</v-icon>
						<span>Xem lại (10s)</span>
					</button>
					<button type="button" class="lh-custom-btn lh-btn-continue flex-grow-1" :disabled="!isAnswerCorrect" @click="continueVideo">
						<span>Tiếp tục video</span>
						<v-icon size="small" class="ml-1">mdi-play</v-icon>
					</button>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-media-player',
		inject: {
			snackbarRef: { default: null }
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
			interactions: {
				type: Array,
				default: () => []
			}
		},
		data() {
			return {
				playerId: 'yt-player-' + Math.random().toString(36).substring(2, 9),
				ytPlayer: null,
				mediaType: null, // 'youtube', 'video', 'audio', 'unknown'
				currentProcessedUrl: '',
				currentVideoId: '',
				isLoading: true,
				error: null,
				
				// Trạng thái tương tác
				completedInteractions: [],
				activeInteraction: null,
				showInteractionOverlay: false,
				
				// Câu trả lời của học sinh
				studentSingleChoiceAnswer: null,
				studentMultipleChoiceAnswers: [],
				studentTrueFalseAnswers: {},
				studentBlankAnswers: {},
				
				videoPlaying: false,
				videoDuration: 0,
				videoCurrentTime: 0,
				playbackRates: [0.5, 1, 1.25, 1.5, 2],
				playbackRate: 1,
				volume: 1,
				lastVolume: 1,
				isMuted: false,
				isFullscreen: false,
				handleFullscreenChange: null,
				
				lastWarningTime: 0,
				lastConfirmedTime: 0,
				dragStartTime: 0,
				isAnswered: false,
				isAnswerCorrect: false,
				timeCheckInterval: null,
				isDraggingSlider: false
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
		computed: {
			normalizedInteractions() {
				let list = this.interactions;
				if (typeof list === 'string') {
					try {
						list = JSON.parse(list);
					} catch(e) {
						list = [];
					}
				}
				if (!Array.isArray(list)) list = [];
				return list;
			},
			sortedInteractions() {
				return [...this.normalizedInteractions].sort((a, b) => a.time - b.time);
			},
			activeInteractionSlideData() {
				if (!this.activeInteraction) return null;
				return this.getInteractionSlideData(this.activeInteraction);
			},
			volumeIcon() {
				if (this.isMuted || this.volume === 0) return 'mdi-volume-off';
				if (this.volume < 0.5) return 'mdi-volume-medium';
				return 'mdi-volume-high';
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
			this.handleFullscreenChange = () => {
				this.isFullscreen = Boolean(document.fullscreenElement);
			};
			document.addEventListener('fullscreenchange', this.handleFullscreenChange);
		},
		beforeUnmount() {
			this.stopTimeCheck();
			if (this.handleFullscreenChange) {
				document.removeEventListener('fullscreenchange', this.handleFullscreenChange);
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
				this.completedInteractions = [];
				this.activeInteraction = null;
				this.showInteractionOverlay = false;
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
					console.warn('URL parsing error, falling back to file extensions', e);
				}

				let domain = '';
				try {
					if (typeof vueData !== 'undefined' && vueData?.v_Set) {
						domain = vueData.v_Set.urlReadFile || vueData.v_Set.urlReturnFile || '';
					}
				} catch(e) {}
				if (!domain && typeof window !== 'undefined' && window.vueData && window.vueData.v_Set) {
					domain = window.vueData.v_Set.urlReadFile || window.vueData.v_Set.urlReturnFile || '';
				}

				// Kiểm tra đuôi file audio
				const audioExtensions = ['.mp3', '.wav', '.ogg', '.m4a'];
				if (audioExtensions.some(ext => urlStr.toLowerCase().endsWith(ext))) {
					this.mediaType = 'audio';
					this.mediaUrl = urlStr.startsWith('http') ? urlStr : (domain + urlStr);
					this.isLoading = false;
					return;
				}

				// Kiểm tra đuôi file video
				const videoExtensions = ['.mp4', '.avi', '.mov', '.webm', '.m3u8'];
				if (videoExtensions.some(ext => urlStr.toLowerCase().endsWith(ext)) || urlStr.startsWith('http') || urlStr.startsWith('/')) {
					this.mediaType = 'video';
					this.mediaUrl = urlStr.startsWith('http') ? urlStr : (domain + urlStr);
					this.isLoading = false;
					return;
				}

				this.mediaType = 'unknown';
				this.error = "Định dạng media không được hỗ trợ.";
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
				if (this.currentVideoId === videoId && this.ytPlayer) {
					return;
				}
				this.currentVideoId = videoId;
				let self = this;
				this.ensureYoutubeApiLoaded().then(() => {
					if (self.ytPlayer) {
						try {
							self.ytPlayer.destroy();
						} catch(e) {}
						self.ytPlayer = null;
					}
					const init = () => {
						let playerEl = document.getElementById(self.playerId);
						const wrapper = self.$refs.ytWrapper || (playerEl ? playerEl.parentElement : document.querySelector('.video-preview-box'));
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
									controls: 0,
									disablekb: 1,
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
						let el = document.getElementById(self.playerId);
						const wrapper = self.$refs.ytWrapper || (el ? el.parentElement : document.querySelector('.video-preview-box'));
						if (wrapper && !el) {
							el = document.createElement('div');
							el.id = self.playerId;
							el.className = 'w-100 h-100';
							wrapper.insertBefore(el, wrapper.firstChild);
						}
						if (window.YT && window.YT.Player && (el || document.getElementById(self.playerId))) {
							clearInterval(checkYT);
							init();
						} else if (checkCount > 150) {
							clearInterval(checkYT);
						}
					}, 100);
				});
			},

			onPlayerReady(event) {
				const player = event.target;
				this.ytPlayer = player;
				this.videoDuration = Math.floor(player.getDuration() || 0);
				this.setPlaybackRate(this.playbackRate);
				this.setVolume(this.volume);
				this.disableYtCC(player);
			},

			onPlayerStateChange(event) {
				if (event.data === window.YT.PlayerState.PLAYING) {
					this.videoPlaying = true;
					this.startTimeCheck();
					this.disableYtCC(event.target);
				} else {
					this.videoPlaying = false;
					this.stopTimeCheck();
				}
			},

			disableYtCC(player) {
				if (!player) return;
				try {
					if (typeof player.unloadModule === 'function') {
						player.unloadModule('captions');
						player.unloadModule('cc');
					}
					if (typeof player.setOption === 'function') {
						player.setOption('captions', 'track', {});
						player.setOption('cc', 'track', {});
					}
				} catch (e) {
					console.warn("Lỗi tắt phụ đề YouTube", e);
				}
			},

			togglePlay() {
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube') {
					if (player && typeof player.getPlayerState === 'function') {
						try {
							const state = player.getPlayerState();
							if (state === 1) { // 1 = PLAYING
								player.pauseVideo();
								this.videoPlaying = false;
							} else {
								player.playVideo();
								this.videoPlaying = true;
							}
						} catch (e) {
							if (typeof player.playVideo === 'function') {
								if (this.videoPlaying) {
									player.pauseVideo();
									this.videoPlaying = false;
								} else {
									player.playVideo();
									this.videoPlaying = true;
								}
							}
						}
					} else if (player && typeof player.playVideo === 'function') {
						if (this.videoPlaying) {
							player.pauseVideo();
							this.videoPlaying = false;
						} else {
							player.playVideo();
							this.videoPlaying = true;
						}
					}
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					const htmlPlayer = this.$refs.htmlVideoPlayer;
					if (htmlPlayer.paused) {
						const promise = htmlPlayer.play();
						if (promise !== undefined) {
							promise.then(() => {
								this.videoPlaying = true;
							}).catch(e => {
								console.warn("Play request was interrupted or prevented", e);
								this.videoPlaying = false;
							});
						} else {
							this.videoPlaying = true;
						}
					} else {
						htmlPlayer.pause();
						this.videoPlaying = false;
					}
				}
			},

			// Giữ tốc độ phát đồng nhất giữa YouTube và video HTML5 để nút điều khiển dùng chung.
			setPlaybackRate(rate) {
				const nextRate = Number(rate);
				if (!Number.isFinite(nextRate) || nextRate <= 0) return;
				this.playbackRate = nextRate;

				if (this.mediaType === 'youtube' && this.ytPlayer && typeof this.ytPlayer.setPlaybackRate === 'function') {
					this.ytPlayer.setPlaybackRate(nextRate);
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.playbackRate = nextRate;
				}
			},

			// YouTube nhận âm lượng theo phần trăm, còn HTML5 nhận số thực từ 0 đến 1.
			setVolume(value) {
				const nextVolume = Math.min(1, Math.max(0, Number(value)));
				if (!Number.isFinite(nextVolume)) return;
				this.volume = nextVolume;
				if (nextVolume > 0) this.lastVolume = nextVolume;
				this.isMuted = nextVolume === 0;

				if (this.mediaType === 'youtube' && this.ytPlayer) {
					if (this.isMuted && typeof this.ytPlayer.mute === 'function') this.ytPlayer.mute();
					if (!this.isMuted && typeof this.ytPlayer.unMute === 'function') this.ytPlayer.unMute();
					if (typeof this.ytPlayer.setVolume === 'function') this.ytPlayer.setVolume(Math.round(nextVolume * 100));
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.volume = nextVolume;
					this.$refs.htmlVideoPlayer.muted = this.isMuted;
				}
			},

			toggleMute() {
				this.setVolume(this.isMuted ? (this.lastVolume || 1) : 0);
			},

			// Toàn màn hình chỉ bao phần video, không kéo sidebar câu hỏi vào cùng khung.
			async toggleFullscreen() {
				const target = this.$refs.videoPreviewBox;
				if (!target) return;
				try {
					if (document.fullscreenElement) {
						await document.exitFullscreen();
						return;
					}
					if (typeof target.requestFullscreen === 'function') {
						await target.requestFullscreen();
					} else if (typeof target.webkitRequestFullscreen === 'function') {
						target.webkitRequestFullscreen();
					}
				} catch (error) {
					console.warn('Không thể bật toàn màn hình video', error);
				}
			},

			showToast(msg, type = 'warning') {
				if (typeof Vue !== 'undefined' && Vue.$toast && typeof Vue.$toast[type] === 'function') {
					Vue.$toast[type](msg);
				} else if (this.$toast && typeof this.$toast[type] === 'function') {
					this.$toast[type](msg);
				} else if (typeof toastr !== 'undefined' && typeof toastr[type] === 'function') {
					toastr[type](msg);
				} else if (this.snackbarRef?.value?.showSnackbar) {
					this.snackbarRef.value.showSnackbar({
						message: msg,
						color: type === 'warning' ? 'warning' : type === 'success' ? 'success' : 'error'
					});
				} else {
					alert(msg);
				}
			},

			onTimelineTrackMouseDown(e) {
				if (e.target && e.target.closest && e.target.closest('.interaction-marker-dot')) {
					return;
				}
				const bar = this.$refs.timelineTrack;
				if (!bar) return;
				
				this.dragStartTime = this.lastConfirmedTime || this.videoCurrentTime;
				this.isDraggingSlider = true;
				const updateTimeFromEvent = (event) => {
					const rect = bar.getBoundingClientRect();
					const clientX = event.clientX || (event.touches && event.touches[0] ? event.touches[0].clientX : 0);
					let ratio = (clientX - rect.left) / rect.width;
					if (ratio < 0) ratio = 0;
					if (ratio > 1) ratio = 1;
					const dur = this.videoDuration || 1;
					this.videoCurrentTime = Math.floor(ratio * dur);
				};

				updateTimeFromEvent(e);

				const onMouseMove = (event) => {
					if (this.isDraggingSlider) {
						updateTimeFromEvent(event);
					}
				};

				const onMouseUp = () => {
					window.removeEventListener('mousemove', onMouseMove);
					window.removeEventListener('touchmove', onMouseMove);
					window.removeEventListener('mouseup', onMouseUp);
					window.removeEventListener('touchend', onMouseUp);
					if (this.isDraggingSlider) {
						this.isDraggingSlider = false;
						this.lastConfirmedTime = this.dragStartTime;
						this.seekVideo(this.videoCurrentTime);
					}
				};

				window.addEventListener('mousemove', onMouseMove);
				window.addEventListener('touchmove', onMouseMove);
				window.addEventListener('mouseup', onMouseUp);
				window.addEventListener('touchend', onMouseUp);
			},
			onVideoSliderEnd(val) {
				this.isDraggingSlider = false;
				let sec = val;
				if (sec === undefined || sec === null || typeof sec === 'object' || isNaN(Number(sec))) {
					sec = this.videoCurrentTime;
				}
				this.seekVideo(sec);
			},
			onSliderChange(val) {
				let sec = val;
				if (sec === undefined || sec === null || typeof sec === 'object' || isNaN(Number(sec))) {
					sec = this.videoCurrentTime;
				}
				this.seekVideo(sec);
			},
			seekVideo(seconds) {
				let sec = seconds;
				if (sec === undefined || sec === null || typeof sec === 'object' || isNaN(Number(sec))) {
					sec = this.videoCurrentTime;
				}
				sec = Math.floor(Number(sec) || 0);

				const unanswered = this.normalizedInteractions
					.filter(item => !this.completedInteractions.includes(item.id))
					.map(item => item.time);

				if (unanswered.length > 0) {
					const nextUnanswered = Math.min(...unanswered);
					if (sec > nextUnanswered) {
						sec = nextUnanswered;
						const now = Date.now();
						if (!this.lastWarningTime || now - this.lastWarningTime > 1500) {
							this.lastWarningTime = now;
							this.showToast("⚠️ Em không được tua vượt qua câu hỏi chưa trả lời nhé!", "warning");
						}
					}
				}

				this.videoCurrentTime = sec;
				this.lastConfirmedTime = sec;
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube' && player && typeof player.seekTo === 'function') {
					player.seekTo(sec, true);
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.currentTime = sec;
				}

				// Kiểm tra nếu mốc tua rơi vào câu hỏi chưa làm -> Kích hoạt câu hỏi ngay!
				const targetInteraction = this.normalizedInteractions.find(item => item.time === sec && !this.completedInteractions.includes(item.id));
				if (targetInteraction) {
					this.lastTriggeredInteractionId = targetInteraction.id;
					this.triggerInteraction(targetInteraction);
				}
			},

			watchAgain() {
				if (!this.activeInteraction) return;
				const currentId = this.activeInteraction.id;
				const targetTime = Math.max(0, this.activeInteraction.time - 10);
				this.showInteractionOverlay = false;
				
				// Reset trạng thái để khi video tự phát lại tới mốc câu hỏi này sẽ tự động bật lại popup
				this.completedInteractions = this.completedInteractions.filter(id => id !== currentId);
				this.lastTriggeredInteractionId = null;

				this.seekVideo(targetTime);
				this.activeInteraction = null;
				
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube' && player && typeof player.playVideo === 'function') {
					player.playVideo();
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.play();
				}
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

			getInteractionType(item) {
				if (!item) return 'QUIZ_SINGLE_CHOICE';
				if (item.question && item.question.type) return item.question.type;
				if (item.type) return item.type;
				return 'QUIZ_SINGLE_CHOICE';
			},

			getInteractionSlideData(item) {
				if (!item) return null;
				let type = this.getInteractionType(item);
				
				// Hợp nhất các nguồn dữ liệu câu hỏi từ nhiều cấu trúc lưu trữ khác nhau
				let rawContent = {
					...(item || {}),
					...(item.config || {}),
					...(item.question?.config || {}),
					...(item.question?.content || {}),
					...(item.content || {})
				};

				// Trích xuất prompt câu hỏi
				let prompt = rawContent.prompt || rawContent.questionText || item.prompt || item.questionText || item.title || '';

				// Trích xuất options/choices
				let options = rawContent.options || rawContent.choices || item.options || item.question?.options || [];
				if (Array.isArray(options)) {
					options = options.map((opt, idx) => {
						if (typeof opt === 'string') {
							return { id: 'opt_' + idx, text: opt };
						}
						return {
							...opt,
							id: opt.id !== undefined && opt.id !== null ? opt.id : ('opt_' + idx),
							text: opt.text !== undefined ? opt.text : (opt.label || opt.value || opt.content || '')
						};
					});
				} else {
					options = [];
				}

				// Xử lý chuẩn hóa correctAnswer / correctAnswers để tương thích với option IDs (opt_0, opt_1...)
				let rawCorrectAnswer = rawContent.correctAnswer !== undefined ? rawContent.correctAnswer : rawContent.correct;
				let normalizedCorrectAnswer = rawCorrectAnswer;
				if (rawCorrectAnswer !== undefined && rawCorrectAnswer !== null) {
					if (typeof rawCorrectAnswer === 'number' || (!isNaN(Number(rawCorrectAnswer)) && !String(rawCorrectAnswer).startsWith('opt_') && options.length > Number(rawCorrectAnswer) && Number(rawCorrectAnswer) >= 0)) {
						normalizedCorrectAnswer = 'opt_' + Number(rawCorrectAnswer);
					}
				}

				let rawCorrectAnswers = rawContent.correctAnswers || (rawContent.correct ? (Array.isArray(rawContent.correct) ? rawContent.correct : [rawContent.correct]) : []);
				let normalizedCorrectAnswers = [];
				if (Array.isArray(rawCorrectAnswers)) {
					normalizedCorrectAnswers = rawCorrectAnswers.map(ca => {
						if (ca !== undefined && ca !== null) {
							if (typeof ca === 'number' || (!isNaN(Number(ca)) && !String(ca).startsWith('opt_') && options.length > Number(ca) && Number(ca) >= 0)) {
								return 'opt_' + Number(ca);
							}
						}
						return ca;
					});
				}

				// Xử lý riêng cho từng dạng câu hỏi để uc-slide-viewer-v3 render mượt mà
				let content = {
					...rawContent,
					prompt: prompt,
					options: options,
					correctAnswer: normalizedCorrectAnswer,
					correctAnswers: normalizedCorrectAnswers.length > 0 ? normalizedCorrectAnswers : rawContent.correctAnswers,
					isInteractiveMode: true
				};

				// Các dạng đặc thù:
				if (type === 'QUIZ_ORDERING') {
					content.items = rawContent.items || options || [];
				} else if (type === 'QUIZ_MATCHING') {
					content.columnA = rawContent.columnA || rawContent.leftItems || rawContent.itemsA || [];
					content.columnB = rawContent.columnB || rawContent.rightItems || rawContent.itemsB || [];
					content.correctPairs = rawContent.correctPairs || rawContent.pairs || [];
				} else if (type === 'QUIZ_CONNECTION') {
					content.groups = rawContent.groups || [];
					content.items = rawContent.items || [];
				} else if (type === 'QUIZ_DRAG_DROP_CATEGORIZE') {
					content.categories = rawContent.categories || [];
					content.items = rawContent.items || [];
				} else if (type === 'QUIZ_FILL_IN_BLANK') {
					content.parts = rawContent.parts || [];
				}

				return {
					type: type,
					content: content
				};
			},

			getTypeName(type) {
				if (type === 'QUIZ_SINGLE_CHOICE') return 'Trắc nghiệm đơn';
				if (type === 'QUIZ_MULTIPLE_CHOICE') return 'Trắc nghiệm nhiều lựa chọn';
				if (type === 'QUIZ_TRUE_FALSE') return 'Đúng sai';
				if (type === 'QUIZ_FILL_IN_BLANK') return 'Điền từ';
				if (type === 'QUIZ_MATCHING') return 'Ghép nối';
				if (type === 'QUIZ_ORDERING') return 'Sắp xếp';
				if (type === 'QUIZ_CONNECTION') return 'Nối cặp';
				if (type === 'QUIZ_DRAG_DROP_CATEGORIZE') return 'Phân loại';
				if (type === 'QUIZ_COMPOSITE') return 'Tổ hợp nhiều câu hỏi';
				return 'Câu hỏi';
			},

			getTypeBadgeColor(type) {
				if (type === 'QUIZ_SINGLE_CHOICE') return '#059669';
				if (type === 'QUIZ_MULTIPLE_CHOICE') return '#0284c7';
				if (type === 'QUIZ_TRUE_FALSE') return '#7c3aed';
				if (type === 'QUIZ_FILL_IN_BLANK') return '#d97706';
				if (type === 'QUIZ_MATCHING') return '#db2777';
				if (type === 'QUIZ_ORDERING') return '#4f46e5';
				if (type === 'QUIZ_CONNECTION') return '#0d9488';
				if (type === 'QUIZ_DRAG_DROP_CATEGORIZE') return '#ea580c';
				if (type === 'QUIZ_COMPOSITE') return '#f43f5e';
				return '#475569';
			},

			onInteractionQuizResult(res) {
				console.log('onInteractionQuizResult:', res);
				const isCorrect = !!(res && (res.result === true || res.isCorrect === true || res.passed === true));
				this.isAnswerCorrect = isCorrect;
				if (isCorrect && this.activeInteraction) {
					if (!this.completedInteractions.includes(this.activeInteraction.id)) {
						this.completedInteractions.push(this.activeInteraction.id);
					}
				}
			},

			startTimeCheck() {
				if (this.timeCheckInterval) return;
				this.timeCheckInterval = setInterval(() => {
					const player = this.ytPlayer;
					if (player && typeof player.getDuration === 'function') {
						const dur = Math.floor(player.getDuration() || 0);
						if (dur > 0 && this.videoDuration !== dur) {
							this.videoDuration = dur;
						}
					}
					if (!this.isDraggingSlider && this.mediaType === 'youtube' && player && typeof player.getCurrentTime === 'function') {
						const currentTime = Math.floor(player.getCurrentTime());
						this.videoCurrentTime = currentTime;
						this.lastConfirmedTime = currentTime;
						const interaction = this.normalizedInteractions.find(item => currentTime >= item.time && currentTime <= item.time + 1 && !this.completedInteractions.includes(item.id));
						if (interaction && this.lastTriggeredInteractionId !== interaction.id) {
							this.lastTriggeredInteractionId = interaction.id;
							this.videoCurrentTime = interaction.time;
							this.triggerInteraction(interaction);
						}
					}
				}, 300);
			},

			stopTimeCheck() {
				if (this.timeCheckInterval) {
					clearInterval(this.timeCheckInterval);
					this.timeCheckInterval = null;
				}
			},

			onHtmlVideoTimeUpdate(event) {
				const video = event.target;
				const currentTime = Math.floor(video.currentTime);
				this.videoCurrentTime = currentTime;
				this.lastConfirmedTime = currentTime;
				const interaction = this.normalizedInteractions.find(item => currentTime >= item.time && currentTime <= item.time + 1 && !this.completedInteractions.includes(item.id));
				if (interaction && this.lastTriggeredInteractionId !== interaction.id) {
					this.lastTriggeredInteractionId = interaction.id;
					this.videoCurrentTime = interaction.time;
					video.pause();
					this.triggerInteraction(interaction);
				}
			},

			onHtmlVideoMetadata(event) {
				this.videoDuration = Math.floor(event.target.duration || 0);
				this.setPlaybackRate(this.playbackRate);
				this.setVolume(this.volume);
			},

			sanitizeSvgHtml(str) {
				if (!str || typeof str !== 'string') return str || '';
				return str
					.replace(/%22(https?:\/\/[^"'\s\\]+)/gi, '$1')
					.replace(/[\\]+["']/g, '"')
					.replace(/=\\?"+([^"\\]+)\\?"+/g, '="$1"')
					.replace(/="""+/g, '="');
			},

			stripHtml(html) {
				if (!html) return '';
				return html.replace(/<[^>]*>?/gm, '').trim();
			},

			triggerInteraction(interaction) {
				this.stopTimeCheck();
				this.videoPlaying = false;
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube' && player && typeof player.pauseVideo === 'function') {
					try {
						player.pauseVideo();
					} catch(e) {}
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.pause();
				}
				this.activeInteraction = interaction;
				
				this.studentSingleChoiceAnswer = null;
				this.studentMultipleChoiceAnswers = [];
				this.studentTrueFalseAnswers = {};
				this.studentBlankAnswers = {};
				
				if (interaction.question?.type === 'QUIZ_TRUE_FALSE' && interaction.question.content?.options) {
					interaction.question.content.options.forEach(opt => {
						this.studentTrueFalseAnswers[opt.id] = null;
					});
				}
				
				this.isAnswered = false;
				this.isAnswerCorrect = false;
				this.showInteractionOverlay = true;
			},

			submitAnswer() {
				if (!this.activeInteraction || !this.activeInteraction.question) return;
				const type = this.activeInteraction.question.type;
				const content = this.activeInteraction.question.content;
				let isCorrect = false;

				if (type === 'QUIZ_SINGLE_CHOICE') {
					isCorrect = this.studentSingleChoiceAnswer === content.correctAnswer;
				} else if (type === 'QUIZ_MULTIPLE_CHOICE') {
					const correctAnswers = content.correctAnswers || [];
					isCorrect = correctAnswers.length === this.studentMultipleChoiceAnswers.length && 
						correctAnswers.every(ans => this.studentMultipleChoiceAnswers.includes(ans));
				} else if (type === 'QUIZ_TRUE_FALSE') {
					isCorrect = content.options.every(opt => this.studentTrueFalseAnswers[opt.id] === opt.correctAnswer);
				} else if (type === 'QUIZ_FILL_IN_BLANK') {
					isCorrect = content.parts.every((part, idx) => {
						if (part.type !== 'blank') return true;
						return (this.studentBlankAnswers[idx] || '').trim().toLowerCase() === part.correctAnswer.trim().toLowerCase();
					});
				}

				this.isAnswered = true;
				this.isAnswerCorrect = isCorrect;

				if (isCorrect) {
					this.showToast("Chính xác!", "success");
				} else {
					this.showToast("Đáp án chưa chính xác. Vui lòng chọn lại!", "error");
				}
			},

			continueVideo() {
				if (!this.isAnswerCorrect) {
					this.showToast("⚠️ Em phải trả lời đúng câu hỏi mới được tiếp tục video nhé!", "warning");
					return;
				}
				let resumeTime = this.videoCurrentTime;
				if (this.activeInteraction) {
					if (!this.completedInteractions.includes(this.activeInteraction.id)) {
						this.completedInteractions.push(this.activeInteraction.id);
					}
					resumeTime = Number(this.activeInteraction.time) || this.videoCurrentTime;
				}
				this.showInteractionOverlay = false;
				this.activeInteraction = null;
				this.isAnswered = false;
				this.isAnswerCorrect = false;
				this.lastTriggeredInteractionId = null;
				
				this.videoCurrentTime = resumeTime;
				this.lastConfirmedTime = resumeTime;

				// Resume phát video từ chính mốc câu hỏi vừa hoàn thành
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube' && player && typeof player.playVideo === 'function') {
					if (typeof player.seekTo === 'function') {
						player.seekTo(resumeTime, true);
					}
					player.playVideo();
					this.videoPlaying = true;
					this.startTimeCheck();
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.currentTime = resumeTime;
					const promise = this.$refs.htmlVideoPlayer.play();
					if (promise !== undefined) {
						promise.catch(e => console.warn(e));
					}
					this.videoPlaying = true;
				}
			},

			getOptionStyle(opt) {
				if (!this.activeInteraction || !this.activeInteraction.question) return {};
				const type = this.activeInteraction.question.type;
				const content = this.activeInteraction.question.content;

				let isCorrect = false;
				let isChosen = false;

				if (type === 'QUIZ_SINGLE_CHOICE') {
					isCorrect = opt.id === content.correctAnswer;
					isChosen = opt.id === this.studentSingleChoiceAnswer;
				} else if (type === 'QUIZ_MULTIPLE_CHOICE') {
					const correctAnswers = content.correctAnswers || [];
					isCorrect = correctAnswers.includes(opt.id);
					isChosen = this.studentMultipleChoiceAnswers.includes(opt.id);
				}

				if (isCorrect) {
					return { borderColor: '#4caf50', backgroundColor: '#e8f5e9', borderWidth: '2px' };
				}
				if (isChosen && !isCorrect) {
					return { borderColor: '#f44336', backgroundColor: '#ffebee', borderWidth: '2px' };
				}
				return { borderColor: '#e0e0e0', backgroundColor: '#ffffff' };
			},

			getOptionIcon(opt) {
				if (!this.activeInteraction || !this.activeInteraction.question) return 'mdi-circle-outline';
				const type = this.activeInteraction.question.type;
				const content = this.activeInteraction.question.content;

				let isCorrect = false;
				let isChosen = false;

				if (type === 'QUIZ_SINGLE_CHOICE') {
					isCorrect = opt.id === content.correctAnswer;
					isChosen = opt.id === this.studentSingleChoiceAnswer;
				} else if (type === 'QUIZ_MULTIPLE_CHOICE') {
					const correctAnswers = content.correctAnswers || [];
					isCorrect = correctAnswers.includes(opt.id);
					isChosen = this.studentMultipleChoiceAnswers.includes(opt.id);
				}

				if (isCorrect) return 'mdi-check-circle';
				if (isChosen) return 'mdi-close-circle';
				return 'mdi-circle-outline';
			},

			getOptionIconColor(opt) {
				if (!this.activeInteraction || !this.activeInteraction.question) return 'grey';
				const type = this.activeInteraction.question.type;
				const content = this.activeInteraction.question.content;

				let isCorrect = false;
				let isChosen = false;

				if (type === 'QUIZ_SINGLE_CHOICE') {
					isCorrect = opt.id === content.correctAnswer;
					isChosen = opt.id === this.studentSingleChoiceAnswer;
				} else if (type === 'QUIZ_MULTIPLE_CHOICE') {
					const correctAnswers = content.correctAnswers || [];
					isCorrect = correctAnswers.includes(opt.id);
					isChosen = this.studentMultipleChoiceAnswers.includes(opt.id);
				}

				if (isCorrect) return 'success';
				if (isChosen) return 'error';
				return 'grey';
			}
		}
	}
</script>

<style scoped>
.media-player-container .video-volume-range {
	appearance: none;
	-webkit-appearance: none;
	background: linear-gradient(to right, #4caf50 0%, #4caf50 var(--volume-percent), #dfe9e2 var(--volume-percent), #dfe9e2 100%);
	border-radius: 999px;
	height: 4px;
	width: 88px;
	flex: 0 0 88px;
	max-width: 88px;
	cursor: pointer;
}

.media-player-container .video-volume-range::-webkit-slider-thumb {
	appearance: none;
	-webkit-appearance: none;
	background: #4caf50;
	border: 0;
	border-radius: 50%;
	height: 12px;
	width: 12px;
}

.media-player-container .video-volume-range::-moz-range-thumb {
	background: #4caf50;
	border: 0;
	border-radius: 50%;
	height: 12px;
	width: 12px;
}

@media (max-width: 599px) {
	.media-player-container .video-volume-range {
		width: 72px;
		flex-basis: 72px;
		max-width: 72px;
	}
}
</style>