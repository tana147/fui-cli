<template>
	<v-row dense class="mb-2">
		<v-col v-for="(item, index) in statCards" :key="index" cols="12" sm="6" md="3">
			<v-card outlined class="rounded-xs pa-3 fill-height d-flex flex-column justify-space-between dashboard-stat-card"
				:class="{ 'dashboard-stat-card--active': activeSection === index + 1 }"
				@click="$emit('select-section', index + 1)">
				<div class="d-flex align-center justify-space-between mb-2">
					<div>
						<div class="text-caption grey--text text--darken-1 font-weight-medium text-uppercase">
							{{ item.title }}
						</div>
						<div class="text-h5 font-weight-bold mt-1" :class="item.textColor">
							{{ item.total }}
						</div>
					</div>
					<v-avatar size="36" :class="item.avatarClass">
						<v-icon :color="item.iconColor" size="20">{{ item.icon }}</v-icon>
					</v-avatar>
				</div>
				<v-divider class="mb-2"></v-divider>
				<div class="d-flex align-center justify-space-between flex-wrap">
					<div v-for="(sub, sIdx) in item.subMetrics" :key="sIdx" class="text-caption grey--text text--darken-2">
						<span>{{ sub.label }}: </span>
						<span class="font-weight-bold" :class="item.textColor">{{ sub.value }}</span>
					</div>
				</div>
			</v-card>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		props: {
		anPhamSummary: {
			type: Object,
			default: () => ({ SL_Tong: 0, SL_TrongNuoc: 0, SL_QuocTe: 0 })
		},
		cgcnHopDongTotal: {
			type: Number,
			default: 0
		},
		cgcnDonViTotal: {
			type: Number,
			default: 0
		},
		giaiThuongTotal: {
			type: Number,
			default: 0
		},
		giaiThuongSinhVien: {
			type: Number,
			default: 0
		},
		giaiThuongGiangVien: {
			type: Number,
			default: 0
		},
		sumNCKHSV: {
			type: Number,
			default: 0
		},
		sumKHCN: {
			type: Number,
			default: 0
		},
		activeSection: {
			type: Number,
			default: 0
		}
	},
	computed: {
		statCards() {
			const slTong = this.anPhamSummary ? (this.anPhamSummary.SL_Tong || 0) : 0
			const slTrongNuoc = this.anPhamSummary ? (this.anPhamSummary.SL_TrongNuoc || 0) : 0
			const slQuocTe = this.anPhamSummary ? (this.anPhamSummary.SL_QuocTe || 0) : 0

			return [
				{
					title: 'I. Ấn phẩm khoa học',
					total: slTong,
					icon: 'mdi-book-open-page-variant-outline',
					iconColor: 'primary',
					textColor: 'primary--text',
					avatarClass: 'dashboard-stat-avatar--primary',
					subMetrics: [
						{ label: 'Trong nước', value: slTrongNuoc },
						{ label: 'Quốc tế', value: slQuocTe }
					]
				},
				{
					title: 'II. Chuyển giao công nghệ',
					total: this.cgcnHopDongTotal,
					icon: 'mdi-handshake-outline',
					iconColor: 'success',
					textColor: 'success--text',
					avatarClass: 'dashboard-stat-avatar--success',
					subMetrics: [
						{ label: 'Dự án/HĐ', value: this.cgcnHopDongTotal },
						{ label: 'Đơn vị tiếp nhận', value: this.cgcnDonViTotal }
					]
				},
				{
					title: 'III. Giải thưởng NCKH',
					total: this.giaiThuongTotal,
					icon: 'mdi-trophy-outline',
					iconColor: 'warning',
					textColor: 'amber--text text--darken-3',
					avatarClass: 'dashboard-stat-avatar--warning',
					subMetrics: [
						{ label: 'SV NCKH', value: this.giaiThuongSinhVien },
						{ label: 'Sáng tạo KHCN', value: this.giaiThuongGiangVien }
					]
				},
				{
					title: 'IV. Đề tài NCKH',
					total: (this.sumNCKHSV || 0) + (this.sumKHCN || 0),
					icon: 'mdi-flask-outline',
					iconColor: 'info',
					textColor: 'cyan--text text--darken-2',
					avatarClass: 'dashboard-stat-avatar--info',
					subMetrics: [
						{ label: 'NCKH Sinh viên', value: this.sumNCKHSV || 0 },
						{ label: 'Đề tài KH&CN', value: this.sumKHCN || 0 }
					]
				}
			]
		}
	}
	}
</script>