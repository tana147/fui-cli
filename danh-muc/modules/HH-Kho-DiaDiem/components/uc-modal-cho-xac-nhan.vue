<template>
	<v-dialog v-model="isShow" :fullscreen="isMobile" :max-width="isMobile ? '100%' : 800"
		:transition="isMobile ? 'dialog-bottom-transition' : 'dialog-transition'">
		<v-card>
			<v-toolbar density="compact" color="primary">
				<v-toolbar-title class="font-weight-bold text-subtitle-1 text-truncate">
					{{ isMobile ? 'Chờ xác nhận' : 'Danh sách chờ xác nhận' }}
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn v-if="isMobile" class="ml-2" variant="tonal" icon="mdi-qrcode-scan" rounded="lg" size="large"
					@click="onOpenDiaglogQr"></v-btn>
				<v-btn icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-card-text v-if="!isMobile" class="pa-0">
				<v-data-table :items="DSChoXacNhan" :headers="headerYeuCau" height="500" density="compact"
					:disable-sort="true" fixed-header hide-default-footer :items-per-page="-1">

					<template v-slot:item.LoaiPhieu="{ item }">
						<span>{{ mapLoaiPhieu[item.LoaiPhieu].text }}</span>
					</template>

					<template v-slot:item.actions="{ item }">
						<v-btn color="primary" variant="tonal" density="compact" prepend-icon="mdi-eye-outline"
							@click="onViewDetailYeuCau(item)">
							Xem chi tiết
						</v-btn>
					</template>
					<template #no-data>
						<uc-empty text="Chưa có yêu cầu xác nhận" />
					</template>
				</v-data-table>
			</v-card-text>

			<div v-else class="bg-grey-lighten-5 min-h-100 pb-4 mt-2 mobile-cho-xac-nhan custom-scroll">
				<v-card v-for="(item, index) in DSChoXacNhan" :key="index"
					class="mobile-card-item rounded-lg elevation-2" @click="onViewDetailYeuCau(item)">
					<div class="pa-3">
						<div class="d-flex justify-space-between align-start mb-2">
							<div class="font-weight-bold text-subtitle-1 text-primary line-clamp-2"
								style="line-height:1.3">
								{{ item.TenPhieu }}
							</div>
						</div>

						<div class="d-flex justify-space-between align-center pt-2 mt-1">
							<span class="text-caption text-grey">
								{{ mapLoaiPhieu[item.LoaiPhieu].text }}
							</span>
							<v-spacer></v-spacer>
							<v-btn size="small" color="primary" variant="text" prepend-icon="mdi-eye-outline"
								@click="onViewDetailYeuCau(item)">
								Xem
							</v-btn>
						</div>
					</div>
				</v-card>
			</div>
		</v-card>
	</v-dialog>

	<v-dialog v-model="isShowQrDialog" :fullscreen="isMobile" width="500" transition="dialog-bottom-transition">
		<v-card class="bg-black">
			<v-toolbar color="transparent" theme="dark">
				<v-toolbar-title>Quét QR</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon="mdi-close" @click="closeQrDialog"></v-btn>
			</v-toolbar>
			<v-card-text class="pa-0 d-flex flex-column align-center justify-center" style="height: 100%">
				<uc-qr v-model="MaVach" @scan-success="afterSuccess" ref="qrScanner" :cooldown-ms="1000"
					:continuous="true" style="width: 100%; aspect-ratio: 1/1;">
				</uc-qr>
				<div class="mt-4 text-white text-center px-4">Di chuyển camera đến mã QR phiếu nhập</div>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
export default {

	props: {
		isShow: Boolean,
		DSChoXacNhan: Array,
	},
	emits: ['load-data', 'update:isShow', 'on-view-detail-yeu-cau'],
	data() {
		return {
			mapTinhTrangPhieu,
			headerYeuCau: [
				{ title: "Loại phiếu", key: "LoaiPhieu", align: 'start', width: '150px' },
				{ title: "Tên phiếu", key: "TenPhieu", align: 'start' },
				{ title: "", key: "actions", align: 'center' },
			],

			mapLoaiPhieu:
			{
				'PHIEU_NHAP': {
					text: 'Phiếu nhập',
					color: 'orange'
				},
			},
			isShowQrDialog: false,
			MaVach: null,
		}
	},

	computed: {
		isMobile() {
			return this.$vuetify.display.smAndDown
		},
	},
	methods: {
		closeDialog() {
			this.$emit('update:isShow', false)
			this.$emit('load-data')
		},
		closeQrDialog() {
			this.isShowQrDialog = false
		},

		onViewDetailYeuCau(item) {
			this.$emit('on-view-detail-yeu-cau', item)
		},
		onOpenDiaglogQr() {
			this.isShowQrDialog = true
		},
		afterSuccess() {
			this.isShowQrDialog = false;
			const data = JSON.parse(this.MaVach)
			this.$emit('on-view-detail-yeu-cau', { Id: data })
		},
	}

}
</script>