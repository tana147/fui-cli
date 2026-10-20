<template>
	<span>
		<slot :open="openWindow" />

		<v-dialog v-model="isOpen" :max-width="width" :fullscreen="fullscreen || $vuetify.display.smAndDown" scrollable
			transition="dialog-bottom-transition" persistent>
			<v-card class="ifw__card" :style="!fullscreen && !$vuetify.display.smAndDown ? 'height:'+height : ''">

				<!-- Titlebar -->
				<v-toolbar density="compact" color="primary" class="ifw__toolbar" flat>
					<v-icon size="18" class="ml-2 mr-2">{{ currentIcon || 'mdi-web' }}</v-icon>
					<v-toolbar-title class="ifw__title text-truncate">{{ currentTitle }}</v-toolbar-title>
					<v-spacer />
					<v-btn :icon="fullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen'" size="small" variant="text"
						@click="fullscreen = !fullscreen" />
					<v-btn icon="mdi-refresh" size="small" variant="text" :loading="loading" @click="reloadIframe" />

					<!-- Bấm X → đóng dialog và chạy onclose -->
					<v-btn icon="mdi-close" size="small" variant="text" @click="closeWindow" />
				</v-toolbar>

				<v-progress-linear v-if="loading" indeterminate color="primary" height="2" />

				<v-card-text class="ifw__body pa-0" style="padding:0 !important; margin:0 !important; height: 100%; display: flex; flex-direction: column; overflow: hidden !important;">
					<iframe v-if="isOpen" ref="iframeRef" :src="currentUrl" class="ifw__iframe" frameborder="0"
						allowfullscreen @load="onIframeLoad" @error="onIframeError" style="width:100%; height:100%; flex:1; border:0; display:block; padding:0; margin:0;"></iframe>
					<div v-if="hasError" class="ifw__error">
						<v-icon size="48" color="grey-lighten-2">mdi-alert-circle-outline</v-icon>
						<div class="mt-2 text-grey">Không thể tải trang</div>
						<v-btn class="mt-3" size="small" variant="tonal" @click="reloadIframe">Thử lại</v-btn>
					</div>
				</v-card-text>
			</v-card>
		</v-dialog>
	</span>
</template>

<script>
	export default {
		name: 'UcIframeWindow',

		inject: ['confirmRef'],

		props: {
			title: { type: String, default: '' },
			url: { type: String, default: '' },
			icon: { type: String, default: 'mdi-web' },
			defaultWidth: { type: String, default: '1100px' },
			defaultHeight: { type: String, default: '88vh' },
		},

		emits: ['closed'],

		data() {
			return {
				isOpen: false,
				// Khóa toàn bộ vòng đời cửa sổ để double-click không tạo thêm iframe/request.
				isWindowBusy: false,
				loading: false,
				hasError: false,
				fullscreen: true,
				currentTitle: '',
				currentUrl: '',
				currentIcon: '',
				width: this.defaultWidth,
				height: this.defaultHeight,
				// Dùng tên không có _ prefix vì Vue 3 proxy bỏ qua getter cho _ prefixed keys
				oncloseCb: null,
				iframeDirty: false,
				msgHandler: null,
			};
		},

		mounted() {
			this.msgHandler = (e) => {
				if (!e.data || e.data.type !== 'lms:assignment:dirty') return;
				this.iframeDirty = !!e.data.isDirty;
			};
			window.addEventListener('message', this.msgHandler);
		},

		beforeUnmount() {
			if (this.msgHandler) {
				window.removeEventListener('message', this.msgHandler);
			}
		},

		methods: {
			// Gọi từ bên ngoài: this.$refs.win.openWindow({ title, url, icon, onclose })
			openWindow({ title = '', url = '', icon = '', width, height, onclose = null } = {}) {
				// Cửa sổ đang mở hoặc đang trong bước mở thì bỏ qua click/request tiếp theo.
				if (this.isWindowBusy || this.isOpen) return false;
				this.isWindowBusy = true;

				this.currentTitle = title || this.title;
				this.currentUrl = url || this.url;
				this.currentIcon = icon || this.icon;
				this.width = width || this.defaultWidth;
				this.height = height || this.defaultHeight;
				this.oncloseCb = onclose;
				this.iframeDirty = false; // reset dirty khi mở cửa sổ mới

				this.loading = true;
				this.hasError = false;
				this.isOpen = true;
				return true;
			},

			// Bấm X → kiểm tra dirty trước khi đóng
			async closeWindow() {
				if (this.iframeDirty) {
					const ok = await this.confirmRef.value.show({
						title: 'Bài đang làm chưa được nộp. Bạn có chắc muốn đóng không?',
					});
					if (!ok) return;
				}
				this.doClose();
			},

			doClose() {
				this.isOpen = false;
				this.currentUrl = '';
				this.iframeDirty = false;

				// Hỗ trợ Function lẫn { EXE: '...' } giống openWindow cũ
				const cb = this.oncloseCb;
				this.oncloseCb = null;
				// Chỉ mở khóa sau khi cửa sổ đã đi qua luồng đóng; lần click kế tiếp mới được mở.
				this.isWindowBusy = false;
				if (typeof cb === 'function') {
					cb();
				} else if (cb?.EXE) {
					try { eval(cb.EXE); } catch (e) { console.warn('[IframeWindow] onclose EXE lỗi:', e); }
				}

				this.$emit('closed');
			},

			reloadIframe() {
				if (!this.$refs.iframeRef) return;
				this.loading = true;
				this.hasError = false;
				this.$refs.iframeRef.src = this.currentUrl;
			},

			onIframeLoad() { this.loading = false; },
			onIframeError() { this.loading = false; this.hasError = true; },
		},
	}
</script>