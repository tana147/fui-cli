<template>
	<div class="mb-3 d-flex flex-column justify-center pa-3 pa-sm-4 period-banner-card">
		<!-- Tiêu đề đợt & Trạng thái -->
		<div class="d-flex flex-wrap align-center justify-center mb-1 text-center" style="gap: 8px;">
			<h2 class="primary--text text-subtitle-1 text-sm-h5 font-weight-bold">
				{{ tenDotText }}
			</h2>
			<v-chip color="success" outlined v-if="isDangMo" class="ms-1 my-1" small>
				Đang mở
			</v-chip>
			<v-chip color="grey" outlined v-else class="ms-1 my-1" small>
				Đã đóng
			</v-chip>
		</div>

		<!-- Nội dung thông báo -->
		<div v-if="thongBaoText" class="d-flex align-center justify-center text-center text-subtitle-2 text-sm-body-1 grey--text text--darken-3 mb-2 px-2" style="max-width: 900px; margin: 0 auto;">
			<v-icon small color="primary" class="mr-1">mdi-bullhorn-outline</v-icon>
			<span><strong>Thông báo:</strong> {{ thongBaoText }}</span>
		</div>

		<!-- File hướng dẫn -->
		<div class="d-flex flex-wrap justify-center align-center mb-3 text-caption text-sm-body-2 period-guide-wrap">
			<span class="grey--text text--darken-2">File hướng dẫn & quy chế:</span>
			<v-chip color="primary" small outlined v-if="fileHuongDan"
				:href="fileHuongDanUrl" target="_blank" class="font-weight-medium" title="Bấm để tải về file hướng dẫn">
				<v-icon left small>mdi-file-download-outline</v-icon>
				{{ fileNameHuongDan }}
			</v-chip>
			<v-chip color="grey" small outlined v-else class="text-caption">
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
			dotDeXuat: { type: Object, default: () => ({}) },
			fileBaseUrl: { type: String, default: '' },
		},
		computed: {
			isDangMo() {
				return this.dotDeXuat && this.dotDeXuat.TinhTrang == 1
			},
			thongBaoText() {
				if (!this.dotDeXuat || !this.dotDeXuat.ThongBao) return ''
				return this.dotDeXuat.ThongBao
			},
			tenDotText() {
				return (this.dotDeXuat && this.dotDeXuat.TenDot) || ''
			},
			fileHuongDan() {
				return (this.dotDeXuat && this.dotDeXuat.FileHuongDan) || ''
			},
			fileNameHuongDan() {
				return (this.dotDeXuat && (this.dotDeXuat.FileNameHuongDan || this.dotDeXuat.FileHuongDan)) || 'Tải file đính kèm'
			},
			fileHuongDanUrl() {
				const baseUrl = this.fileBaseUrl || (window.vueData && window.vueData.v_Set && window.vueData.v_Set.urlReturnFile) || ''
				return baseUrl ? baseUrl + '/FileData/' + this.fileHuongDan : ''
			},
			startDateFormatted() {
				return this.formatDate(this.dotDeXuat && this.dotDeXuat.ThoiGianBatDau)
			},
			endDateFormatted() {
				return this.formatDate(this.dotDeXuat && this.dotDeXuat.ThoiGianKetThuc)
			},
		},
		methods: {
			formatDate(value) {
				return value ? moment(value).format('DD/MM/YYYY') : 'DD/MM/YYYY'
			},
		},
	}
</script>