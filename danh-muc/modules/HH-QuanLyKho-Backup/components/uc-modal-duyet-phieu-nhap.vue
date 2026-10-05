<template>
	<v-dialog v-model="isShow" width="800">
		<v-card>
			<v-toolbar density="compact" elevation="0">
				<v-toolbar-title>
					Xem chi tiết
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text class="py-1">
				<div class="pa-4 border-bottom bg-grey-lighten-5 pb-0">
					<div class="mt-3">
						<div class="d-flex align-center justify-space-between mb-1">
							<span class="text-grey text-caption">NHÀ CUNG CẤP</span>
							<span class="font-weight-bold">{{ selectedItem.Info.TenNhaCungCap }}</span>
						</div>
						<div class="d-flex align-center justify-space-between mb-1">
							<span class="text-grey text-caption">SỐ HÓA ĐƠN</span>
							<span class="font-weight-bold">{{ selectedItem.Info.SoHoaDon }}</span>
						</div>
						<div class="d-flex align-center justify-space-between mb-1 ">
							<span class="text-grey text-caption">NGÀY NHẬP</span>
							<span class="font-weight-bold">{{ formatDate(selectedItem.Info.NgayNhap) }}</span>
						</div>
						<div class="d-flex align-center justify-space-between mb-1">
							<span class="text-grey text-caption">ĐỊA ĐIỂM</span>
							<span class="font-weight-bold">{{ selectedItem.Info.TenDiaDiem }}</span>
						</div>
						<uc-file-chip :items="selectedItem?.DSFile ?? []"></uc-file-chip>
					</div>
				</div>
				<div class="pa-4 d-flex flex-column pt-0">
					<div class="d-flex justify-space-between align-center mb-3">
						<div class="text-subtitle-2 font-weight-bold">DANH SÁCH HÀNG HOÁ </div>
					</div>

					<v-list v-if="selectedItem?.arrayHangHoa?.length > 0" lines="two"
						class="pa-0 flex-grow-1 overflow-y-auto">
						<v-list-item v-for="(HangHoa, index) in selectedItem.arrayHangHoa" :key="index"
							class="border rounded-lg mb-2 pa-2">
							<template v-slot:prepend>
								<v-avatar color="blue-lighten-5" rounded size="40">
									<v-icon size="20"
										:color="HangHoa.Is_CaBiet ? 'purple' : HangHoa.LoaiHangHoa === 'CCDC' ? 'orange-darken-2' : 'blue'">
										{{ HangHoa.Is_CaBiet ? 'mdi-devices' : HangHoa.LoaiHangHoa === 'CCDC' ?
											'mdi-tools'
											: 'mdi-package-variant' }}
									</v-icon>
								</v-avatar>
							</template>

							<v-list-item-title class="font-weight-bold text-body-2 d-flex align-center ga-2">
								{{ HangHoa.TenHangHoa }}
								<span v-if="HangHoa.Is_CaBiet" class="badge-tai-san">Tài sản</span>
								<span v-else-if="HangHoa.LoaiHangHoa === 'CCDC'" class="badge-ccdc">CCDC</span>
								<span v-else class="badge-nvl">NVL</span>
							</v-list-item-title>

							<v-list-item-subtitle class="text-caption mt-1 d-flex justify-space-between">
								<span>SL: <b>{{ HangHoa.SoLuongNhap ?? HangHoa.SoLuongDat }}</b> {{ HangHoa.TenDonVi
								}}</span>
								<span
									v-if="selectedItem.LoaiPhieu === 'PHIEU_NHAP' || selectedItem.LoaiPhieu === 'LUAN_CHUYEN'"
									class="text-green-darken-2 font-weight-bold">
									{{ calcThanhTien(HangHoa).toLocaleString('vi-VN') }}
								</span>
								<span v-else class="text-green-darken-2 font-weight-bold">
									Chưa rõ
								</span>
							</v-list-item-subtitle>

							<div class="text-caption text-grey mt-1 d-flex flex-wrap ga-3">
								<span v-if="HangHoa.ThueGTGT">VAT: <b>{{ HangHoa.ThueGTGT }}%</b></span>
								<span v-if="HangHoa.ThueKhac">Thuế khác: <b>{{ HangHoa.ThueKhac }}%</b></span>
								<span v-if="HangHoa.ThueNhapKhau">Thuế NK: <b>{{ HangHoa.ThueNhapKhau }}%</b></span>
								<span v-if="HangHoa.PhanTramKhac">% Khác: <b>{{ HangHoa.PhanTramKhac }}%</b></span>
								<span v-if="HangHoa.ChiPhiKhac">CP khác: <b>{{
									Number(HangHoa.ChiPhiKhac).toLocaleString('vi-VN') }}</b></span>
							</div>
						</v-list-item>
						<v-textarea v-model="selectedItem.GhiChu" rows="2" auto-grow label="Ghi chú"
							class="mt-2"></v-textarea>

						<div class="d-flex justify-space-between align-center pa-3 mt-1 rounded"
							style="background: #f5f5f5;">
							<span class="text-caption text-medium-emphasis">Tổng giá trị</span>
							<span class="text-subtitle-2 font-weight-bold text-green-darken-2">
								{{ tongGiaTriPhieu.toLocaleString('vi-VN') }} đ
							</span>
						</div>
					</v-list>

					<div v-else>
						<uc-empty text="Chưa có hàng hoá để hiển thị"></uc-empty>
					</div>
				</div>

			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<!-- <v-btn color="default" variant="tonal" @click="onSubmit('TU_CHOI')">Từ chối</v-btn> -->
				<v-btn color="primary" variant="tonal" @click="onSubmit('HOAN_THANH')">Duyệt</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		selectedItem: Object,
	},

	emits: ['update:isShow', 'onReload'],

	data() {
		return {
		}
	},

	computed: {
		tongGiaTriPhieu() {
			const items = this.selectedItem?.arrayHangHoa
			if (!items || items.length === 0) return '0'
			const total = items.reduce((sum, h) => {
				return sum + this.calcThanhTien(h)
			}, 0)
			return total.toLocaleString('vi-VN')
		}
	},

	methods: {
		formatDate: window.formatDate,

		closeDialog() {
			this.$emit('update:isShow', false)
		},

		calcDonGiaFull(h) {
			const dg = Number(h.DonGia ?? 0)
			const thueKhac = Number(h.ThueKhac ?? 0) * dg / 100
			const thueNK = Number(h.ThueNhapKhau ?? 0) * dg / 100
			const phanTramKhac = Number(h.PhanTramKhac ?? 0) * dg / 100
			const chiPhiKhac = Number(h.ChiPhiKhac ?? 0)
			return dg + thueKhac + thueNK + phanTramKhac + chiPhiKhac
		},
		calcThanhTien(h) {
			const sl = Number(h.SoLuongNhap ?? h.SoLuongDat ?? 0)
			return sl * this.calcDonGiaFull(h)
		},

		async onSubmit(type) {
			const params = {
				PhieuNhap_Id: this.selectedItem.Id,
				TinhTrang: type,
				GhiChu: this.selectedItem.GhiChu
			}
			apiCall("work/HH_PhieuNhap_Update_TinhTrang", params, (res) => {
				if (res) showToast.success("Thành công");
				this.closeDialog()
				this.$emit('onReload', { Id: this.selectedItem.Id })
			})
		}
	},
}
</script>