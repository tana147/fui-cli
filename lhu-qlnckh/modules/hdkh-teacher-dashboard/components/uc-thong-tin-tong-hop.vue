<template>
	<v-card variant="tonal" color="primary">
		<div v-if="!data" class="pa-4">
			<v-skeleton-loader type="list-item-three-line"></v-skeleton-loader>
		</div>
		<v-card-text v-else>
			<v-row align="center">
				<v-col cols="12" md="6" class="border-e-md">
					<div class="text-overline mb-2">Thực hiện Nghĩa vụ NCKH</div>
					<div class="d-flex align-baseline">
						<div class="text-h4 font-weight-bold">{{ data.TongGio_DaThucHien || 0 }}</div>
						<div class="text-h6 ml-1">/ {{ data.NghiaVu_PhaiThucHien || 0 }} giờ</div>
					</div>
					<v-progress-linear :model-value="progressPercentage" color="primary" height="12" rounded
						class="my-2"></v-progress-linear>
					<div class="d-flex justify-space-between text-caption">
						<span>Tiến độ: {{ progressPercentage.toFixed(1) }}%</span>
						<v-chip :color="status.color" size="small" variant="flat" label>
							<v-icon start :icon="status.icon"></v-icon>
							{{ status.text }}
						</v-chip>
					</div>
				</v-col>
				<v-col cols="12" md="6">
					<v-list-item density="compact">
						<template v-slot:prepend>
							<v-icon icon="mdi-target-variant" color="grey"></v-icon>
						</template>
						<v-list-item-title>Định mức gốc</v-list-item-title>
						<template v-slot:append><span class="font-weight-medium">{{ data.DinhMuc_Goc || 0 }}
								giờ</span></template>
					</v-list-item>
					<v-list-item density="compact">
						<template v-slot:prepend>
							<v-icon icon="mdi-sale" color="grey"></v-icon>
						</template>
						<v-list-item-title>Miễn giảm</v-list-item-title>
						<template v-slot:append><span class="font-weight-medium">{{ data.TongGio_MienGiam || 0 }}
								giờ</span></template>
					</v-list-item>
					<v-divider class="my-1"></v-divider>
					<v-list-item density="compact">
						<template v-slot:prepend>
							<v-icon icon="mdi-content-save-move-outline" color="green"></v-icon>
						</template>
						<v-list-item-title>Bảo lưu từ năm trước</v-list-item-title>
						<template v-slot:append><span class="font-weight-medium text-green">{{
								data.TongGio_BaoLuu_TuNamTruoc || 0 }} giờ</span></template>
					</v-list-item>
					<v-list-item density="compact">
						<template v-slot:prepend>
							<v-icon icon="mdi-alert-circle-outline" color="red"></v-icon>
						</template>
						<v-list-item-title>Còn thiếu từ năm trước</v-list-item-title>
						<template v-slot:append><span class="font-weight-medium text-red">{{ data.SoGio_Thieu_TuNamTruoc
								|| 0 }} giờ</span></template>
					</v-list-item>
				</v-col>
			</v-row>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		props: { data: { type: Object, default: null } },
		computed: {
			progressPercentage() {
				if (!this.data || !this.data.NghiaVu_PhaiThucHien || this.data.NghiaVu_PhaiThucHien === 0) return 0;
				const percentage = (this.data.TongGio_DaThucHien / this.data.NghiaVu_PhaiThucHien) * 100;
				return Math.min(percentage, 100);
			},
			status() {
				if (!this.data) return { text: 'Đang tải...', color: 'grey', icon: 'mdi-progress-clock' };
				if (this.data.KetLuan === 'Đạt') return { text: 'Đạt', color: 'success', icon: 'mdi-check-circle' };
				return { text: 'Chưa đạt', color: 'warning', icon: 'mdi-alert' };
			}
		}
	}
</script>