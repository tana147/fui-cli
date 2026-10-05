<template>
	<div class="div-poster-carousel carousel-menu">
		<v-carousel v-if="CTManHinh" v-model="currentIndex" :cycle="!stop" :interval="duration" touchless
			hide-delimiters height="100vh">
			<v-carousel-item v-for="(item, i) in vueData.CTManHinh" :key="i" reverse-transition="fade-transition">
				<template v-if="item.FileContentType === 'video/mp4'">
					<video :ref="el => setVideoRef(el, i)" :src="item.FileURL" autoplay muted playsinline
						style="width: 100%; height: 100%; object-fit: cover;" />
				</template>
				<template v-else>
					<img :src="item.FileURL" style="width: 100%; height: 100%; object-fit: contain;" />
				</template>
			</v-carousel-item>
		</v-carousel>
	</div>
</template>

<script>
	export default {
		data() {
			const urlParams = new URLSearchParams(window.location.search);
			const manhHinhID = urlParams.get("id");
			return {
				currentIndex: 0,
				stop: false,
				CTManHinh: vueData.CTManHinh,
				ManHinhID: manhHinhID,
				vueData,
				ready: false,
				duration: 1000,
				videoRefs: {} // 🆕 chứa danh sách video theo index
			};
		},
		methods: {
			resetIndex() {
				this.currentIndex = 0;
			},
	
			setVideoRef(el, i) {
				if (el) {
					this.$set(this.videoRefs, i, el);
				}
			},
	
			async handleData2() {
				const currentItem = this.vueData.CTManHinh[this.currentIndex];
				if (!currentItem) return;
	
				this.stop = true;
	
				// 🛑 Dừng các video khác
				Object.entries(this.videoRefs).forEach(([idx, vid]) => {
					if (parseInt(idx) !== this.currentIndex && vid && !vid.paused) {
						vid.pause();
						vid.currentTime = 0;
					}
				});
	
				if (currentItem.FileContentType === "video/mp4") {
					await this.$nextTick();
	
					const video = this.videoRefs[this.currentIndex];
					if (video) {
						try {
							video.currentTime = 0;
							await video.play();
	
							// ✅ Đảm bảo sự kiện onended được gán để chuyển slide sau khi video kết thúc
							video.onended = () => {
	
								this.stop = false;
	
								// ⏭️ Slide tiếp theo
								this.currentIndex = (this.currentIndex + 1) % this.vueData.CTManHinh.length;
							};
	
							const duration = video.duration || 5;
							this.duration = duration * 1000;
						} catch (err) {
							this.stop = false;
						}
					} else {
						this.stop = false;
					}
				} else {
					this.duration = (this.vueData.DSManHinh[0]?.TocDoChuyen || 3) * 1000;
	
					// ⏳ Giữ ảnh đủ thời gian rồi chuyển tiếp
					setTimeout(() => {
						this.stop = false;
						this.currentIndex = (this.currentIndex + 1) % this.vueData.CTManHinh.length;
					}, this.duration);
				}
			}
		},
		watch: {
			"vueData.CTManHinh": {
				handler(newVal) {
					if (newVal && newVal.length > 0) {
						this.ready = true;
					}
				},
				deep: true,
				immediate: true
			},
			"vueData.DSManHinh": {
				handler(newVal) {
					if (newVal && newVal.length > 0) {
						this.duration = newVal[0].TocDoChuyen * 1000;
					}
				},
				deep: true,
				immediate: true
			},
			currentIndex(val, oldVal) {
				if (val !== oldVal && this.ready) {
					this.handleData2();
				}
			}
		}
	}
</script>