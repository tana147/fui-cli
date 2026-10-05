<template>
	<div>
		<div style="background-color: black; width: 100%; aspect-ratio: 1/1;">
			<video v-if="useBarcodeDetector" ref="video" autoplay playsinline muted
				style="width: 100%; aspect-ratio: 1/1; object-fit: cover;"></video>
			<div v-else id="qr-reader" style="width: 100%; aspect-ratio: 1/1;"></div>
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
	    modelValue: {
	      type: String,
	      default: '',
	    },
	  },
	  data() {
	    return {
	      useBarcodeDetector: false,
	      isSupported: true,
	      videoStream: null,
	      detector: null,
	      scanning: false,
	      html5QrCode: null,
	      isScanning: false,
	    };
	  },
	  mounted() {
	    this.initialize();
	  },
	  beforeUnmount() {
	    this.stopScanning();
	  },
	  methods: {
	    async initialize() {
	      // Check if BarcodeDetector is supported
	      if ('BarcodeDetector' in window) {
	        console.log('Dùng BarcodeDetector');
	        this.useBarcodeDetector = true;
	        this.startBarcodeDetector();
	      } else {
	        console.log('Fallback sang html5-qrcode');
	        this.useBarcodeDetector = false;
	        this.startHtml5Qrcode();
	      }
	    },
	
	    // ===================== BarcodeDetector Mode =====================
	    async startBarcodeDetector() {
	      try {
	        this.videoStream = await navigator.mediaDevices.getUserMedia({
	          video: { facingMode: 'environment', width: { ideal: 1280 } },
	        });
	        this.$refs.video.srcObject = this.videoStream;
	        this.detector = new BarcodeDetector({ formats: ['qr_code'] });
	        this.scanning = true;
	        this.scanLoop();
	      } catch (err) {
	        console.error('Lỗi bật camera:', err);
	        this.isSupported = false;
	      }
	    },
	
	    async scanLoop() {
	      if (!this.scanning) return;
	      try {
	        const barcodes = await this.detector.detect(this.$refs.video);
	        if (barcodes.length > 0) {
	          const decodedText = barcodes[0].rawValue;
	          this.$emit('update:modelValue', decodedText);
	          this.$emit('scan-success', decodedText);
	          await this.stopScanning();
	          return;
	        }
	      } catch (err) {
	        // console.log("Scan error:", err);
	      }
	      requestAnimationFrame(this.scanLoop);
	    },
	
	    // ===================== html5-qrcode Mode =====================
	    async startHtml5Qrcode() {
	      if (!window.Html5Qrcode) {
	        this.isSupported = false;
	        console.error('html5-qrcode chưa được import.');
	        return;
	      }
	
	      try {
	        this.html5QrCode = new Html5Qrcode('qr-reader');
	        const devices = await Html5Qrcode.getCameras();
	        if (!devices || devices.length === 0) {
	          console.error('Không tìm thấy camera trên thiết bị!');
	          return;
	        }
	
	        await this.html5QrCode.start(
	          { facingMode: 'environment' },
	          { fps: 30, qrbox: { width: 150, height: 150 }, experimentalFeatures: { useBarCodeDetectorIfSupported: true } },
	          async (decodedText) => {
	            this.$emit('update:modelValue', decodedText);
	            this.$emit('scan-success', decodedText);
	            await this.stopScanning();
	          },
	          (error) => console.log('QR Code scan error:', error)
	        );
	
	        this.isScanning = true;
	      } catch (err) {
	        console.error('Không thể khởi động máy quét QR:', err);
	        this.isSupported = false;
	      }
	    },
	
	    // ===================== Stop =====================
	    async stopScanning() {
	      if (this.useBarcodeDetector) {
	        this.scanning = false;
	        if (this.videoStream) {
	          this.videoStream.getTracks().forEach(track => track.stop());
	          this.videoStream = null;
	        }
	      } else if (this.html5QrCode && this.isScanning) {
	        try {
	          await this.html5QrCode.stop();
	          this.isScanning = false;
	        } catch (err) {
	          console.error('Lỗi khi dừng QR scanner:', err);
	        }
	      }
	    },

      triggerFileInput() {
      // KHÔNG await trước click, để đảm bảo browser không chặn
      if (this.$refs.fileInput) {
      this.$refs.fileInput.click();
      } else {
      console.error('Không tìm thấy input file.');
      }
      },
	
	    // ===================== File Select =====================
	    async handleFileSelect(event) {
	      const file = event.target.files[0];
	      if (!file || !file.type.startsWith('image/')) return;
	
	      if (this.useBarcodeDetector) {
	        // BarcodeDetector decode từ ảnh
	        try {
	          const imageBitmap = await createImageBitmap(file);
	          const barcodes = await this.detector.detect(imageBitmap);
	          if (barcodes.length > 0) {
	            const decodedText = barcodes[0].rawValue;
	            this.$emit('update:modelValue', decodedText);
	            this.$emit('scan-success', decodedText);
	          } else {
	            console.warn('Không tìm thấy QR trong ảnh!');
	          }
	        } catch (err) {
	          console.error('Lỗi quét ảnh bằng BarcodeDetector:', err);
	        }
	      } else if (this.html5QrCode) {
	        // html5-qrcode decode file
	        try {
	          const decodedText = await this.html5QrCode.scanFile(file, true);
	          this.$emit('update:modelValue', decodedText);
	          this.$emit('scan-success', decodedText);
	        } catch (err) {
	          console.error('Không phải QR. Vui lòng thử lại!');
	        }
	      }
	
	      event.target.value = ''; // Reset input để chọn lại file
	    }
	  },
	}
</script>