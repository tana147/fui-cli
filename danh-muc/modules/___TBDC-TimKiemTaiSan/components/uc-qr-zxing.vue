<template>
	<div>
		<div style="background-color: black; width: 100%; aspect-ratio: 1/1;">
			<video ref="video" autoplay playsinline muted
				style="width: 100%; aspect-ratio: 1/1; object-fit: cover;"></video>
		</div>

		<slot></slot>

		<input type="file" ref="fileInput" accept="image/*" style="display: none;" @change="handleFileSelect" />

		<p v-if="!isSupported" style="color: red; text-align: center;">
			Trình duyệt không hỗ trợ quét QR code.
		</p>
	</div>
</template>

<script>
	export default {
	
		props: {
			modelValue: String,
			cooldownMs: { type: Number, default: 800 },
			continuous: { type: Boolean, default: true },
			autoStart: { type: Boolean, default: true },
			formats: {
				type: Array,
				default: () => ['qr_code'], // có thể thêm 'code_128', 'ean_13'
			},
		},
		data() {
			return {
				isSupported: true,
				codeReader: null,
				scanControl: null,
				lastText: '',
				lastEmitAt: 0,
				paused: false,
			}
		},
		mounted() {
			if (this.autoStart) {
				// delay 500ms để đảm bảo CDN đã tải xong
				setTimeout(() => this.start(), 500)
			}
		},
		beforeUnmount() {
			this.stop()
		},
		methods: {
			async start() {
				const BrowserMultiFormatReader = ZXing.BrowserMultiFormatReader
				const BarcodeFormat = ZXing.BarcodeFormat
				const DecodeHintType = ZXing.DecodeHintType
	
				const hints = new Map()
				const supportedFormats = this.formats.map(f => {
					switch (f.toLowerCase()) {
						case 'qr_code': return BarcodeFormat.QR_CODE
						case 'code_128': return BarcodeFormat.CODE_128
						case 'ean_13': return BarcodeFormat.EAN_13
						default: return BarcodeFormat.QR_CODE
					}
				})
				hints.set(DecodeHintType.POSSIBLE_FORMATS, supportedFormats)
	
				this.codeReader = new BrowserMultiFormatReader(hints)
	
				try {
					this.scanControl = await this.codeReader.decodeFromVideoDevice(
						null,
						this.$refs.video,
						(result, err, controls) => {
							if (result && !this.paused) {
								this.handleDetection(result.getText())
								if (!this.continuous) controls.stop()
							}
						},
						{ video: { facingMode: 'environment' } }
					)
				} catch (e) {
					console.error('Lỗi bật camera:', e)
					this.isSupported = false
				}
			},
	
			stop() {
				if (this.scanControl) {
					this.scanControl.stop()
					this.scanControl = null
				}
				if (this.codeReader) {
					this.codeReader.reset()
					this.codeReader = null
				}
			},
	
			pause() {
				this.paused = true
			},
	
			resume() {
				this.paused = false
			},
	
			handleDetection(text) {
				const now = Date.now()
				if (text === this.lastText && now - this.lastEmitAt < this.cooldownMs) return
				this.lastText = text
				this.lastEmitAt = now
	
				this.$emit('update:modelValue', text)
				this.$emit('scan-success', text)
				this.$emit('scan-raw', { text, ts: now })
			},
	
			triggerFileInput() {
				if (this.$refs.fileInput) this.$refs.fileInput.click()
			},
	
			async handleFileSelect(event) {
				const file = event.target.files[0]
				if (!file || !file.type.startsWith('image/')) return
	
				try {
					const img = await createImageBitmap(file)
					const result = await this.codeReader.decodeFromImageBitmap(img)
					this.handleDetection(result.getText())
				} catch (err) {
					if (!(err instanceof NotFoundException)) {
						console.error('Lỗi khi quét ảnh:', err)
					} else {
						console.warn('Không tìm thấy mã QR trong ảnh!')
					}
				}
	
				event.target.value = ''
			}
		}
	}
</script>