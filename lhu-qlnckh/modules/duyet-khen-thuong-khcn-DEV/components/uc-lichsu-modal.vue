<template>
	<v-dialog v-model="dialog" max-width="600" scrollable>
		<v-card class="rounded-xs">
			<v-card-title class="d-flex align-center px-3 pt-2 pb-3">
				<span class="subtitle-1 font-weight-bold primary--text">Lịch sử xử lý</span>
				<v-spacer></v-spacer>
				<v-btn small icon @click="dialog = false">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>
			<v-card-text class="px-3 py-3 lichsu-modal-body">
				<div v-if="loading" class="text-center py-6">
					<v-progress-circular indeterminate color="primary"></v-progress-circular>
				</div>
				<v-timeline v-else-if="timelineItems.length > 0" dense align-top>
					<v-timeline-item v-for="(item, index) in timelineItems" :key="index" :color="item.color"
						:icon="item.icon" small fill-dot>
						<div class="d-flex flex-column">
							<span class="font-weight-medium">{{ item.title }}</span>
							<span v-if="item.desc" class="text-body-2 grey--text text--darken-1">{{ item.desc }}</span>
							<span class="text-caption grey--text">
								{{ item.dateOnly ? formatDate(item.time) : formatDateTime(item.time) }}<span
									v-if="item.userLabel"> · {{ item.userLabel }}</span>
							</span>
						</div>
					</v-timeline-item>
				</v-timeline>
				<div v-else class="text-center grey--text py-6">Chưa có dữ liệu lịch sử</div>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			value: { type: Boolean, default: false },
			anphamid: { type: Number, default: null },
		},
		emits: ['input'],
		data() {
			return {
				loading: false,
				submitInfo: null,
				lichSuArr: [],
				duyetInfo: null,
			}
		},
		computed: {
			dialog: {
				get() { return this.value },
				set(val) { this.$emit('input', val) },
			},
			timelineItems() {
				const items = []
				if (this.submitInfo && this.submitInfo.ThoiGian) {
					items.push({
						title: 'Gửi bài',
						desc: null,
						time: this.submitInfo.ThoiGian,
						userLabel: this.userLabel(this.submitInfo.NhanVien, this.submitInfo.HoTen),
						color: 'primary',
						icon: 'mdi-send',
						dateOnly: false,
					})
				}
				this.lichSuArr.forEach(item => {
					const meta = this.getMeta(item.HanhDong)
					items.push({
						title: meta.title,
						desc: item.MoTa,
						time: item.ThoiGian,
						userLabel: this.userLabel(item.NhanVien, item.HoTen),
						color: meta.color,
						icon: meta.icon,
						dateOnly: false,
					})
				})
				const hasDuyetLog = this.lichSuArr.some(item => item.HanhDong === 'DUYET')
				if (!hasDuyetLog && this.duyetInfo && this.duyetInfo.TrangThai === 3 && this.duyetInfo.ThoiGianDuyet) {
					const meta = this.getMeta('DUYET')
					items.push({
						title: meta.title,
						desc: 'Dữ liệu cũ trước khi có nhật ký chi tiết',
						time: this.duyetInfo.ThoiGianDuyet,
						userLabel: this.userLabel(this.duyetInfo.NhanVienCapNhat, this.duyetInfo.HoTen),
						color: meta.color,
						icon: meta.icon,
						dateOnly: true,
					})
				}
				return items.sort((a, b) => new Date(a.time) - new Date(b.time))
			},
		},
		watch: {
			dialog(val) {
				if (val && this.anphamid) {
					this.fetchLichSu()
				}
			},
		},
		methods: {
			getMeta(hanhDong) {
				if (hanhDong === 'DUYET') return { title: 'Đã duyệt', color: 'success', icon: 'mdi-check-circle' }
				if (hanhDong === 'TUCHOI') return { title: 'Từ chối', color: 'error', icon: 'mdi-close-circle' }
				if (hanhDong === 'CHINHSUA') return { title: 'Chỉnh sửa dữ liệu', color: 'blue', icon: 'mdi-pencil-circle' }
				if (hanhDong === 'CHUYENDOT') return { title: 'Chuyển đợt duyệt', color: 'purple', icon: 'mdi-swap-horizontal-circle' }
				return { title: hanhDong, color: 'grey', icon: 'mdi-circle-small' }
			},
			formatDateTime(val) {
				if (!val) return ''
				return moment(val).format('DD/MM/YYYY HH:mm')
			},
			formatDate(val) {
				if (!val) return ''
				return moment(val).format('DD/MM/YYYY')
			},
			userLabel(maNV, hoTen) {
				if (!maNV) return ''
				return hoTen ? hoTen + ' (' + maNV + ')' : maNV
			},
			async fetchLichSu() {
				this.loading = true
				try {
					const data = await ajaxCALLPromise('/AnPham_LichSu_Get', { AnPhamID: this.anphamid })
					this.submitInfo = data[0] && data[0][0] ? data[0][0] : null
					this.lichSuArr = data[1] || []
					this.duyetInfo = data[2] && data[2][0] ? data[2][0] : null
				} finally {
					this.loading = false
				}
			},
		},
	}
</script>