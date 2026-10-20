<template>
	<v-card class="audio-player" elevation="2">
		<div class="player-content">
			<!--
				Ưu tiên backend MediaElement để trình duyệt tự giải mã file audio.
				Một số file ghi âm WebM/MP3 không thể đi qua decodeAudioData nhưng vẫn
				phát được bằng thẻ audio native; khi waveform lỗi, player sẽ chuyển sang
				fallback bên dưới thay vì để vùng nghe bị treo ở 0:00.
			-->
			<div class="waveform-container">
				<div v-show="!usingNativeAudio" :ref="waveformRef" class="waveform"></div>
				<div v-if="usingNativeAudio" class="native-audio-fallback">
					<audio ref="nativeAudio" class="native-audio" :src="nativeAudioUrl" controls preload="metadata"
						style="width: 100%;"
						@loadedmetadata="handleNativeReady" @timeupdate="handleNativeTimeUpdate"
						@play="isPlaying = true" @pause="isPlaying = false" @ended="isPlaying = false"
						@error="handleNativeError" />
					<div class="text-caption text-medium-emphasis mt-1">
						Waveform không khả dụng, đang dùng trình phát audio của trình duyệt.
					</div>
				</div>

				<!-- Loading overlay -->
				<div v-if="loading" class="loading-overlay d-flex align-center justify-center">
					<v-progress-circular indeterminate size="28" />
					<div class="mt-1 text-caption">{{ loadingText }}</div>
				</div>
			</div>

			<!-- Controls -->
			<div class="player-controls">
				<!-- Play / Pause -->
				<v-btn icon size="small" variant="text" color="primary"
					:disabled="loadingAudio || (!waveSurfer && !nativeAudioReady)"
					@click="togglePlay">
					<v-icon size="24">
						{{ isPlaying ? 'mdi-pause' : 'mdi-play' }}
					</v-icon>
				</v-btn>

				<!-- Time -->
				<span class="time-text">{{ currentTime }}</span>

				<!-- Volume -->
				<div class="volume-control">
					<v-icon size="18" class="volume-icon" @click="toggleMute">
						{{ volumeIcon }}
					</v-icon>

					<v-slider v-model="volume" min="0" max="1" step="0.01" hide-details density="compact"
						class="volume-slider" :disabled="loadingAudio || (!waveSurfer && !nativeAudioReady)"
						@update:modelValue="setVolume" />
				</div>

				<!-- Speed -->
				<v-menu>
					<template #activator="{ props }">
						<v-chip size="x-small" variant="text" v-bind="props"
							:disabled="loadingAudio || (!waveSurfer && !nativeAudioReady)">
							{{ playbackSpeed }}x
						</v-chip>
					</template>

					<v-list density="compact">
						<v-list-item v-for="speed in speedOptions" :key="speed"
							:class="{ 'v-list-item--active': playbackSpeed === speed }" @click="setSpeed(speed)">
							{{ speed }}x
						</v-list-item>
					</v-list>
				</v-menu>

				<!-- Duration -->
				<span class="time-text text-grey">{{ duration }}</span>
			</div>
		</div>
	</v-card>
</template>

<script>
	export default {
		name: 'AudioPlayer',
	
		props: {
			audioUrl: {
				type: String,
				default: '',
			},
		},
	
		data() {
			return {
				// ref duy nhất cho waveform
				waveformRef: `waveform-${generateID()}`,
	
				waveSurfer: null,
				nativeAudioReady: false,
				nativeAudioUrl: '',
				usingNativeAudio: false,
				activeAudioUrl: '',
				objectUrl: '',
				loadRequestId: 0,
				isPlaying: false,
	
				volume: 0.8,
				previousVolume: 0.8, 
	
				loading: false,
				loadingAudio: false,
				loadingText: 'Đang tải...',
	
				currentTime: '0:00',
				duration: '0:00',
	
				playbackSpeed: 1,
				speedOptions: [0.5, 0.75, 1, 1.25, 1.5, 2],
			}
		},
	
		computed: {
			volumeIcon() {
				if (this.volume === 0) return 'mdi-volume-mute'
				if (this.volume < 0.5) return 'mdi-volume-low'
				return 'mdi-volume-high'
			},
		},
	
		mounted() {
			if (this.audioUrl) {
				this.loadAudio(this.audioUrl)
			}
		},
	
		watch: {
			audioUrl(newUrl) {
				this.loadAudio(newUrl)
			},
		},
	
		methods: {
			async loadAudio(url) {
				const requestId = ++this.loadRequestId
				this.resetPlayer()
				if (!url) return

				this.loading = true
				this.loadingAudio = true
				this.loadingText = 'Đang tải âm thanh...'
				let finalUrl = url
				let objectUrl = ''

				try {
					// ===== Google Drive =====
					if (url.includes('drive.google.com')) {
						const fileId =
							url.match(/\/file\/d\/([^/]+)/)?.[1] ||
							new URL(url).searchParams.get('id')

						if (!fileId) throw new Error('Không tìm thấy fileId Google Drive')

						const tokenResult = await this.ajaxCALLPromise('lms/FP_Youtube_Token_Get')
						const accessToken = tokenResult?.access_token
						if (!accessToken) throw new Error('Không lấy được access token Google Drive')

						const response = await fetch(
							`https://www.googleapis.com/drive/v3/files/${fileId}?alt=media`,
							{ headers: { Authorization: `Bearer ${accessToken}` } }
						)
						if (!response.ok) throw new Error(`Google Drive trả về HTTP ${response.status}`)

						const blob = await response.blob()
						objectUrl = URL.createObjectURL(blob)
						finalUrl = objectUrl
					}

					if (requestId !== this.loadRequestId) return
					this.activeAudioUrl = finalUrl
					this.objectUrl = objectUrl

					this.waveSurfer?.destroy()
					this.waveSurfer = null
					await this.$nextTick()

					const container = this.$refs[this.waveformRef]
					if (!container) throw new Error('Waveform container not found')
					if (typeof WaveSurfer === 'undefined') {
						throw new Error('WaveSurfer chưa được nạp')
					}

					this.waveSurfer = WaveSurfer.create({
						container,
						// MediaElement tránh decodeAudioData/ScriptProcessorNode của WebAudio.
						backend: 'MediaElement',
						waveColor: '#B3E5FC',
						progressColor: '#1976D2',
						cursorColor: '#1976D2',
						height: 50,
						barWidth: 2,
						barRadius: 2,
						barGap: 1,
					})

					this.waveSurfer.on('ready', () => {
						this.duration = this.formatTime(this.waveSurfer.getDuration())
						this.waveSurfer.setVolume(this.volume)
						this.loading = false
						this.loadingAudio = false
					})
					this.waveSurfer.on('error', error => this.handleLoadError(error, finalUrl, requestId))
					this.waveSurfer.on('audioprocess', () => {
						this.currentTime = this.formatTime(this.waveSurfer.getCurrentTime())
					})
					this.waveSurfer.on('seek', () => {
						this.currentTime = this.formatTime(this.waveSurfer.getCurrentTime())
					})
					this.waveSurfer.on('finish', () => { this.isPlaying = false })
					this.waveSurfer.load(finalUrl)
				} catch (error) {
					this.handleLoadError(error, finalUrl, requestId)
				}
			},
			handleLoadError(error, fallbackUrl = this.activeAudioUrl, requestId = this.loadRequestId) {
				if (requestId !== this.loadRequestId) return
				// Giải mã waveform có thể lỗi dù browser vẫn phát được file bằng <audio>.
				// Fallback này giữ cho giáo viên vẫn nghe được bài mà không làm lỗi trang chấm.
				this.waveSurfer?.destroy()
				this.waveSurfer = null
				this.activeAudioUrl = fallbackUrl || ''
				this.nativeAudioUrl = fallbackUrl || ''
				this.usingNativeAudio = !!this.nativeAudioUrl
				this.loading = false
				this.loadingAudio = false
				this.loadingText = 'Đang dùng trình phát audio native'
				this.isPlaying = false
			},
			resetPlayer() {
				this.waveSurfer?.destroy()
				this.waveSurfer = null
				const nativeAudio = this.$refs.nativeAudio
				if (nativeAudio) {
					nativeAudio.pause()
					nativeAudio.removeAttribute('src')
					nativeAudio.load()
				}
				if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
				this.objectUrl = ''
				this.nativeAudioReady = false
				this.nativeAudioUrl = ''
				this.usingNativeAudio = false
				this.activeAudioUrl = ''
				this.loading = false
				this.loadingAudio = false
				this.currentTime = '0:00'
				this.duration = '0:00'
				this.isPlaying = false
			},
			handleNativeReady(event) {
				const audio = event?.target || this.$refs.nativeAudio
				this.nativeAudioReady = !!audio
				this.duration = this.formatTime(audio?.duration || 0)
				if (audio) audio.volume = this.volume
				this.loading = false
				this.loadingAudio = false
			},
			handleNativeTimeUpdate(event) {
				const audio = event?.target || this.$refs.nativeAudio
				if (audio) this.currentTime = this.formatTime(audio.currentTime || 0)
			},
			handleNativeError() {
				this.loading = false
				this.loadingAudio = false
				this.isPlaying = false
			},

			togglePlay() {
				if (this.usingNativeAudio) {
					const audio = this.$refs.nativeAudio
					if (!audio) return
					if (audio.paused) audio.play().catch(() => { this.handleNativeError() })
					else audio.pause()
					return
				}
				if (!this.waveSurfer) return
				this.waveSurfer.playPause()
				this.isPlaying = !this.isPlaying
			},
	
			setVolume() {
				this.waveSurfer?.setVolume(this.volume)
				const audio = this.$refs.nativeAudio
				if (audio) audio.volume = this.volume
			},
	
			toggleMute() {
				if (this.volume === 0) {
					this.volume = this.previousVolume
				} else {
					this.previousVolume = this.volume
					this.volume = 0
				}
				this.setVolume()
			},
	
			setSpeed(speed) {
				this.playbackSpeed = speed
				this.waveSurfer?.setPlaybackRate(speed)
				const audio = this.$refs.nativeAudio
				if (audio) audio.playbackRate = speed
			},
	
			formatTime(sec) {
				const m = Math.floor(sec / 60)
				const s = Math.floor(sec % 60)
				return `${m}:${String(s).padStart(2, '0')}`
			},
	
			ajaxCALLPromise(url, params = null) {
				return new Promise(resolve => {
					ajaxCALL(url, params, res => {
						resolve(res?.data ?? res)
					})
				})
			},
		},
	
		beforeUnmount() {
			this.loadRequestId++
			this.resetPlayer()
		},
	}
</script>