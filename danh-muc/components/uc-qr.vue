<template>
	<div>
		<div style="background-color: black; width: 100%; aspect-ratio: 1/1;">
			<video ref="video" autoplay playsinline muted
				style="width: 100%; aspect-ratio: 1/1; object-fit: cover;"></video>
		</div>

		<slot></slot>

		<input type="file" ref="fileInput" accept="image/*" style="display: none" @change="handleFileSelect" />

		<p v-if="!isSupported" style="color: red; text-align: center;">
			Trình duyệt không hỗ trợ quét QR code. Vui lòng chọn trình duyệt khác.
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
	            default: () => ['qr_code'],
	        },
	    },
	    data() {
	        return {
	            isSupported: true,
	            useBarcodeDetector: false,
	            // BarcodeDetector
	            videoStream: null,
	            detector: null,
	            scanning: false,
	            // ZXing
	            codeReader: null,
	            scanControl: null,
	            // Common
	            paused: false,
	            lastText: '',
	            lastEmitAt: 0,
	        }
	    },
	    mounted() {
	        if (this.autoStart) {
	            setTimeout(() => this.initialize(), 500)
	        }
	    },
	    beforeUnmount() {
	        this.stop()
	    },
	    methods: {
	        async initialize() {
	            if ('BarcodeDetector' in window) {
	                console.log('Dùng BarcodeDetector')
	                this.useBarcodeDetector = true
	                await this.startBarcodeDetector()
	            } else if (window.ZXing) {
	                console.log('Fallback sang ZXing')
	                this.useBarcodeDetector = false
	                await this.startZxing()
	            } else {
	                this.isSupported = false
	                console.error('Không hỗ trợ BarcodeDetector hoặc ZXing chưa được tải.')
	            }
	        },
	
	        async start() {
	            if (this.useBarcodeDetector) {
	                await this.startBarcodeDetector()
	            } else {
	                await this.startZxing()
	            }
	        },
	
	        stop() {
	            if (this.useBarcodeDetector) {
	                this.scanning = false
	                if (this.videoStream) {
	                    this.videoStream.getTracks().forEach((t) => t.stop())
	                    this.videoStream = null
	                }
	            } else {
	                if (this.scanControl) {
	                    this.scanControl.stop()
	                    this.scanControl = null
	                }
	                if (this.codeReader) {
	                    this.codeReader.reset()
	                    this.codeReader = null
	                }
	            }
	        },
	
	        pause() {
	            this.paused = true
	        },
	
	        resume() {
	            this.paused = false
	        },
	
	        // ===== BarcodeDetector =====
	        async startBarcodeDetector() {
	            try {
	                this.videoStream = await navigator.mediaDevices.getUserMedia({
	                    video: { facingMode: 'environment', width: { ideal: 1280 } },
	                })
	                this.$refs.video.srcObject = this.videoStream
	
	                this.detector = new BarcodeDetector({ formats: this.formats })
	                this.scanning = true
	                this.loop()
	            } catch (err) {
	                console.error('Lỗi bật camera (BarcodeDetector):', err)
	                this.isSupported = false
	            }
	        },
	
	        async loop() {
	            if (!this.scanning) return
	
	            if (!this.paused && this.detector && this.$refs.video) {
	                try {
	                    const barcodes = await this.detector.detect(this.$refs.video)
	                    if (barcodes.length > 0) {
	                        const decodedText = barcodes[0].rawValue
	                        this.handleDetection(decodedText)
	                    }
	                } catch (e) {
	                    // ignore
	                }
	            }
	
	            requestAnimationFrame(this.loop)
	        },
	
	        // ===== ZXing fallback =====
	        async startZxing() {
	            try {
	                const { BrowserMultiFormatReader, BarcodeFormat, DecodeHintType } = ZXing
	
	                const hints = new Map()
	                const supportedFormats = this.formats.map((f) => {
	                    switch (f.toLowerCase()) {
	                        case 'qr_code':
	                            return BarcodeFormat.QR_CODE
	                        case 'code_128':
	                            return BarcodeFormat.CODE_128
	                        case 'ean_13':
	                            return BarcodeFormat.EAN_13
	                        default:
	                            return BarcodeFormat.QR_CODE
	                    }
	                })
	                hints.set(DecodeHintType.POSSIBLE_FORMATS, supportedFormats)
	
	                this.codeReader = new BrowserMultiFormatReader(hints)
	
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
	                console.error('Lỗi bật camera (ZXing):', e)
	                this.isSupported = false
	            }
	        },
	
	        // ===== Common =====
	        // handleDetection(text) {
	        //   const now = Date.now()
	        //   if (text === this.lastText && now - this.lastEmitAt < this.cooldownMs) return
	
	        //   this.lastText = text
	        //   this.lastEmitAt = now
	
	        //   this.$emit('update:modelValue', text)
	        //   this.$emit('scan-success', text)
	        //   this.$emit('scan-raw', { text, ts: now })
	        // },
	
	        handleDetection(text) {
	            const now = Date.now();
	            if (text === this.lastText && now - this.lastEmitAt < this.cooldownMs) return;
	
	            this.lastText = text;
	            this.lastEmitAt = now;
	
	            this.playBeep();
	
	            this.$emit('update:modelValue', text);
	            this.$emit('scan-success', text);
	            this.$emit('scan-raw', { text, ts: now });
	        },
	        playBeep() {
	            const audio = new Audio('/_cdn/lhbs-quanlyts/qr.mp3');
	            audio.play().catch((err) => {
	                console.warn('Không thể phát âm thanh:', err);
	            });
	        },
	
	        triggerFileInput() {
	            if (this.$refs.fileInput) this.$refs.fileInput.click()
	        },
	
	        async handleFileSelect(event) {
	            const file = event.target.files[0]
	            if (!file || !file.type.startsWith('image/')) return
	
	            try {
	                const img = await createImageBitmap(file)
	
	                if (this.useBarcodeDetector) {
	                    if (!this.detector) {
	                        this.detector = new BarcodeDetector({ formats: this.formats })
	                    }
	                    const barcodes = await this.detector.detect(img)
	                    if (barcodes.length > 0) {
	                        const decodedText = barcodes[0].rawValue
	                        this.handleDetection(decodedText)
	                    } else {
	                        console.warn('Không tìm thấy QR trong ảnh!')
	                    }
	                } else {
	                    const result = await this.codeReader.decodeFromImageBitmap(img)
	                    this.handleDetection(result.getText())
	                }
	            } catch (err) {
	                console.error('Lỗi khi quét ảnh:', err)
	            }
	
	            event.target.value = ''
	        },
	    },
	}
</script>