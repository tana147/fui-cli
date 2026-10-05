<script>
	export default {
  props: {
    modelValue: { type: String, default: '' },
  },
  data() {
    return {
      html5QrCode: null,
      isScanning: false,
      track: null,
      zoomSupported: false,
      zoomLevel: 1,
      maxZoom: 1,
      selectedCameraId: null,
    };
  },
  mounted() {
    this.initializeQrScanner();
    this.$nextTick(this.startScanning);
  },
  beforeUnmount() {
    this.stopScanning();
    if (this.html5QrCode) {
      this.html5QrCode.clear();
      this.html5QrCode = null;
    }
  },
  methods: {
    alert(type, msg) {
      console.log(`[${type}] ${msg}`);
    },

    initializeQrScanner() {
      try {
        this.html5QrCode = new Html5Qrcode('qr-reader');
      } catch (err) {
        console.error('Lỗi khởi tạo Html5Qrcode:', err);
      }
    },

    pickRearCamera(devices) {
      // Ưu tiên label có "back" / "rear" / "environment"
      const rear = devices.find(d => /back|rear|environment/i.test(d.label));
      if (rear) return rear.id;

      // Nếu không có label (iOS/Safari trước khi cấp quyền) hoặc không match, lấy cái cuối
      return devices[devices.length - 1].id;
    },

    async startScanning() {
      if (!this.html5QrCode || this.isScanning) return;

      try {
        const devices = await Html5Qrcode.getCameras();
        if (!devices || devices.length === 0) {
          this.alert("error", "Không tìm thấy camera trên thiết bị!");
          return;
        }

        this.selectedCameraId = this.pickRearCamera(devices);

        await this.html5QrCode.start(
          { deviceId: { exact: this.selectedCameraId } },
          { fps: 20, qrbox: { width: 200, height: 200 }, disableFlip: true, aspectRatio: 1 },
          async (decodedText) => {
          // giữ nguyên hành động cũ
            this.$emit('update:modelValue', decodedText);
            this.$emit('scan-success', decodedText);
            await this.stopScanning();
          },
          (error) => console.log('QR Code scan error:', error)
        );

        // Lấy track từ Html5Qrcode để zoom
        // (Html5Qrcode >= 2.x có getRunningTrack(); nếu không có, fallback sang _localMediaStream)
        setTimeout(() => {
          const track = typeof this.html5QrCode.getRunningTrack === 'function'
            ? this.html5QrCode.getRunningTrack()
            : (this.html5QrCode._localMediaStream?.getVideoTracks?.()[0] ?? null);

          if (track) {
            this.track = track;
            this.checkZoomSupport();
          }
        }, 300);

        this.isScanning = true;
      } catch (err) {
        console.error('Không thể khởi động máy quét QR:', err);
        const errorMsg = err.name === 'NotAllowedError'
          ? "Quyền truy cập camera bị từ chối!"
          : err.name === 'NotFoundError'
            ? "Không tìm thấy camera. Vui lòng kiểm tra thiết bị!"
            : "Lỗi không xác định khi khởi động camera!";
        this.alert("error", errorMsg);
      }
    },

    async stopScanning() {
      if (this.html5QrCode && this.isScanning) {
        try {
          await this.html5QrCode.stop();
        } catch (err) {
          console.error('Lỗi khi dừng QR scanner:', err);
        } finally {
          this.isScanning = false;
          if (this.track) {
            try { this.track.stop(); } catch {}
            this.track = null;
          }
          this.zoomSupported = false;
        }
      }
    },

    checkZoomSupport() {
      if (!this.track) return;
      const caps = this.track.getCapabilities?.() || {};
      if (caps.zoom) {
        this.zoomSupported = true;
        this.maxZoom = caps.zoom.max;
        this.zoomLevel = caps.zoom.min || 1;
      }
    },

    applyZoom() {
      if (!this.track || !this.isScanning || !this.zoomSupported) return;
      this.track.applyConstraints({ advanced: [{ zoom: this.zoomLevel }] })
        .catch(err => console.error('Lỗi khi zoom:', err));
    },

    async triggerFileInput() {
      await this.stopScanning();
      this.$refs.fileInput?.click();
    },

    handleCancel() {
      this.startScanning();
    },

    async handleFileSelect(event) {
      const file = event.target.files[0];
      if (!file || !file.type.startsWith('image/')) {
        this.startScanning();
        return;
      }

      try {
        await this.stopScanning();
        const decodedText = await this.html5QrCode.scanFile(file, true);
        this.$emit('update:modelValue', decodedText);
        this.$emit('scan-success', decodedText);
      } catch (err) {
        this.alert("error", "Không phải QR. Vui lòng thử lại!");
        this.startScanning();
      } finally {
        this.$refs.fileInput.value = '';
      }
    },
  },
}
</script>

<template>
	<div>
		<div style="background-color: black; width: 100%; aspect-ratio: 1/1;">
			<div id="qr-reader" style="width: 100%; aspect-ratio: 1/1;"></div>
		</div>

		<!-- Zoom Slider -->
		<div v-if="zoomSupported" style="margin-top: 10px; text-align: center;">
			<input type="range" min="1" :max="maxZoom" step="0.1" v-model="zoomLevel" @input="applyZoom" />
			<span>Zoom: {{ zoomLevel.toFixed(1) }}x</span>
		</div>

		<slot></slot>

		<input type="file" ref="fileInput" accept="image/*" style="display: none;" @cancel="handleCancel"
			@change="handleFileSelect" />

		<uc-confirm ref="confirm"></uc-confirm>
	</div>
</template>