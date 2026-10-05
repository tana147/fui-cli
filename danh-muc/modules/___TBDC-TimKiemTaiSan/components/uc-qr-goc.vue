<template>
	<div>
		<div style="background-color: black; width: 100%; aspect-ratio: 1/1;">
			<div id="qr-reader" style="width: 100%; aspect-ratio: 1/1;"></div>
		</div>

		<slot></slot>

		<input type="file" ref="fileInput" accept="image/*" style="display: none;" @cancel="handleCancel"
			@change="handleFileSelect" />

		<uc-confirm ref="confirm"></uc-confirm>
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
				html5QrCode: null,
				isScanning: false,
				kieu: null,
				thongBao: false,
				message: '',
			};
		},
		mounted() {
			this.initializeQrScanner();
			this.$nextTick(() => {
				this.startScanning();
			});
		},
		beforeUnmount() {
			this.stopScanning();
		},
		methods: {
			async validate(refName, callback, confirmText = "Bạn có muốn lưu dữ liệu?", reset = true) {
				const form = this.$refs[refName];
				if (!form) {
					console.warn(`Form ref "${refName}" not found.`);
					return;
				}
	
				const { valid } = await form.validate();
	
				if (valid && typeof callback === "function") {
					const confirmed = await this.$refs.confirm.open(confirmText);
					if (!confirmed) return;
					await callback();
					if (reset) form.reset();
				}
			},
			alert(kieu, message) {
				this.kieu = kieu;
				this.message = message;
				this.thongBao = true;
			},
			initializeQrScanner() {
				try {
					this.html5QrCode = new Html5Qrcode('qr-reader');
					console.log('Html5Qrcode khởi tạo thành công.');
				} catch (err) {
					console.error('Lỗi khởi tạo Html5Qrcode:', err);
				}
			},
			async startScanning() {
				if (!this.html5QrCode || this.isScanning) return;
	
				const config = {
					fps: 20,
					qrbox: { width: 200, height: 200 },
					disableFlip: true,
					aspectRatio: 1,
				};
	
				try {
					const devices = await Html5Qrcode.getCameras();
					if (!devices || devices.length === 0) {
						showMessage({ type: "red", title: "Không tìm thấy camera trên thiết bị!" });
						return;
					}
	
					await this.html5QrCode.start(
						{ facingMode: 'environment' },
						config,
						async (decodedText) => {
							this.$emit('update:modelValue', decodedText);
							this.$emit('scan-success', decodedText);
							// await this.stopScanning();
							setTimeout(function() {
							// Code cần thực thi sau 2 giây
							}, 2000); // 2000 ms = 2 giây
						},
						(error) => {
							console.log('QR Code scan error:', error);
						}
					);
	
					this.isScanning = true;
					console.log('Camera đã khởi động thành công.');
				} catch (err) {
					console.error('Không thể khởi động máy quét QR:', err.message);
					const errorMsg = err.name === 'NotAllowedError'
						? "Quyền truy cập camera bị từ chối!"
						: err.name === 'NotFoundError'
							? "Không tìm thấy camera. Vui lòng kiểm tra thiết bị!"
							: "Lỗi không xác định khi khởi động camera!";
					showMessage({ type: "red", title: errorMsg });
				}
			},
			async stopScanning() {
				if (this.html5QrCode && this.isScanning) {
					try {
						await this.html5QrCode.stop();
						this.isScanning = false;
						console.log('QR Scanner đã dừng.');
					} catch (err) {
						console.error('Lỗi khi dừng QR scanner:', err);
					}
				} else {
					console.log('QR Scanner không đang chạy, bỏ qua stop.');
				}
			},
			async triggerFileInput() {
				await this.stopScanning();
				if (this.$refs.fileInput) {
					this.$refs.fileInput.click();
				} else {
					console.error('Không tìm thấy input file.');
				}
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
					this.$emit('scan-success');
					console.log('Quét file thành công:', decodedText);
				} catch (err) {
					showMessage({ type: "red", title: "Không phải QR. Vui lòng thử lại!" });
					this.startScanning();
				} finally {
					this.$refs.fileInput.value = '';
				}
			},
		},
	}
</script>