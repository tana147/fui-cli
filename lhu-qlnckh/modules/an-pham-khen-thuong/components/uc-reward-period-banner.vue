<template>
	<div class="mb-3 d-flex flex-column justify-center pa-3 pa-sm-4 period-banner-card">
		<!-- Tiêu đề thông báo -->
		<div class="d-flex flex-wrap align-center justify-center mb-2 text-center">
			<h2 class="primary--text text-subtitle-1 text-sm-h5 font-weight-bold">
				Thông báo: {{ thongBaoText }} {{ tenDotText }}
			</h2>
			<v-chip color="success" outlined v-if="isDangMo" class="ms-2 my-1" small>
				Đang mở
			</v-chip>
			<v-chip color="grey" outlined v-else class="ms-2 my-1" small>
				Đã đóng
			</v-chip>
		</div>

		<!-- File hướng dẫn -->
		<div class="d-flex flex-wrap justify-center align-center mb-3 text-caption text-sm-body-2" style="gap: 6px;">
			<span>File hướng dẫn:</span>
			<v-chip color="orange" small outlined v-if="fileHuongDan"
				:href="fileHuongDanUrl" target="_blank">
				{{ fileHuongDan }}
			</v-chip>
			<v-chip color="orange" small outlined v-else>
				Chưa có file hướng dẫn
			</v-chip>
		</div>

		<!-- Timeline thời gian -->
		<div class="period-timeline-wrapper">
			<div class="period-timeline">
				<!-- Mốc bắt đầu -->
				<div class="timeline-step">
					<div class="timeline-badge timeline-badge--active">1</div>
					<div class="timeline-date">{{ startDateFormatted }}</div>
				</div>

				<!-- Đường nối -->
				<div class="timeline-divider"></div>

				<!-- Mốc kết thúc -->
				<div class="timeline-step">
					<div class="timeline-badge">2</div>
					<div class="timeline-date">{{ endDateFormatted }}</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'uc-reward-period-banner',
		props: {
			dotDeXuat: { type: Object, default: () => ({}) }
		},
		data() {
			return {
				vueData
			}
		},
		computed: {
			isDangMo() {
				return this.dotDeXuat && this.dotDeXuat.TinhTrang == 1;
			},
			thongBaoText() {
				if (!this.dotDeXuat || !this.dotDeXuat.ThongBao) return 'Chưa cập nhật thông báo -';
				return this.dotDeXuat.ThongBao;
			},
			tenDotText() {
				return (this.dotDeXuat && this.dotDeXuat.TenDot) || '';
			},
			fileHuongDan() {
				return (this.dotDeXuat && this.dotDeXuat.FileHuongDan) || '';
			},
			fileHuongDanUrl() {
				const baseUrl = (this.vueData && this.vueData.v_Set && this.vueData.v_Set.urlReturnFile) || '';
				return baseUrl + '/FileData/' + this.fileHuongDan;
			},
			startDateFormatted() {
				return this.formatDate(this.dotDeXuat && this.dotDeXuat.ThoiGianBatDau);
			},
			endDateFormatted() {
				return this.formatDate(this.dotDeXuat && this.dotDeXuat.ThoiGianKetThuc);
			}
		},
		methods: {
			formatDate(value) {
				return value ? moment(value).format("DD/MM/YYYY") : "DD/MM/YYYY"
			}
		}
	}
</script>