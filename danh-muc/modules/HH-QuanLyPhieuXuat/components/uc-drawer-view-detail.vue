<template>
	<v-navigation-drawer :model-value="isShow" @update:model-value="closeDrawer" location="right" width="800" temporary
		:scrim='false' class="elevation-5">
		<template v-if="selectedItem">
			<div class="pa-4 border-bottom bg-grey-lighten-5">
				<div class="d-flex justify-space-between align-center">
					<div class="d-flex align-center ga-2">
						<h3 class="text-h6 font-weight-bold text-blue-grey-darken-3">Chi tiết phiếu xuất</h3>
						<v-chip v-if="selectedItem.LoaiPhieuXuat" :color="loaiPhieuColor" size="small" variant="tonal">
							{{ loaiPhieuText }}
						</v-chip>
					</div>
					<div class="d-flex align-center ga-1">
						<v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-printer-outline"
							@click="$emit('print-emit', selectedItem)">In</v-btn>
						<v-btn icon="mdi-close" variant="text" size="small" @click="closeDrawer"></v-btn>
					</div>
				</div>
				<div class="mt-3">
					<div class="d-flex align-center justify-space-between mb-1">
						<span class="text-grey text-caption">SỐ PHIẾU XUẤT</span>
						<span class="font-weight-bold">{{ selectedItem.SoPhieuXuat }}</span>
					</div>
					<div class="d-flex align-center justify-space-between mb-1">
						<span class="text-grey text-caption">NGÀY XUẤT</span>
						<span class="font-weight-bold">{{ formatDate(selectedItem.NgayXuat) }}</span>
					</div>
					<div class="d-flex align-center justify-space-between mb-1">
						<span class="text-grey text-caption">ĐỊA ĐIỂM</span>
						<span class="font-weight-bold">{{ selectedItem.TenDiaDiem }}</span>
					</div>
					<div v-if="selectedItem.DiaDiemNhan" class="d-flex align-center justify-space-between mb-1">
						<span class="text-grey text-caption">ĐỊA ĐIỂM NHẬN</span>
						<span class="font-weight-bold">{{ selectedItem.DiaDiemNhan }}</span>
					</div>
					<div class="d-flex align-center justify-space-between mb-1">
						<span class="text-grey text-caption">NGƯỜI XUẤT</span>
						<span class="font-weight-bold">{{ selectedItem.NguoiXuat }}</span>
					</div>
					<div v-if="selectedItem.GhiChu" class="d-flex align-center justify-space-between mb-1">
						<span class="text-grey text-caption">GHI CHÚ</span>
						<span class="font-weight-bold">{{ selectedItem.GhiChu }}</span>
					</div>
				</div>
			</div>

			<div class="pa-4 d-flex flex-column" style="height: calc(100% - 310px);">
				<div class="d-flex justify-space-between align-center mb-3">
					<div class="text-subtitle-2 font-weight-bold">DANH SÁCH HÀNG HOÁ ĐÃ XUẤT</div>
					<v-chip size="x-small" color="primary" variant="tonal">{{ selectedItem.arrayHangHoa?.length || 0 }} mặt hàng</v-chip>
				</div>

				<v-list v-if="selectedItem?.arrayHangHoa?.length > 0" lines="two"
					class="pa-0 flex-grow-1 overflow-y-auto custom-scroll">
					<v-list-item v-for="(HangHoa, index) in selectedItem.arrayHangHoa" :key="index"
						class="border rounded-lg mb-2 pa-2">
						<template v-slot:prepend>
							<v-avatar :color="HangHoa.Is_CaBiet ? 'purple-lighten-5' : HangHoa.LoaiHangHoa === 'CCDC' ? 'orange-lighten-5' : 'blue-lighten-5'" rounded size="40">
								<v-icon size="20" :color="HangHoa.Is_CaBiet ? 'purple' : HangHoa.LoaiHangHoa === 'CCDC' ? 'orange-darken-2' : 'blue'">
									{{ HangHoa.Is_CaBiet ? 'mdi-devices' : HangHoa.LoaiHangHoa === 'CCDC' ? 'mdi-tools' : 'mdi-cube-outline' }}
								</v-icon>
							</v-avatar>
						</template>

						<v-list-item-title class="font-weight-bold text-body-2 d-flex align-center ga-2">
							{{ HangHoa.TenHangHoa }}
							<span v-if="HangHoa.Is_CaBiet" class="badge-tai-san">Tài sản</span>
							<span v-else-if="HangHoa.LoaiHangHoa === 'CCDC'" class="badge-ccdc">CCDC</span>
							<span v-else class="badge-nvl">NVL</span>
						</v-list-item-title>

						<v-list-item-subtitle class="text-caption mt-1">
							<span>Khu vực: <b>{{ HangHoa.TenKhuVuc }}</b></span>
						</v-list-item-subtitle>

						<v-list-item-subtitle class="text-caption mt-1 d-flex justify-space-between">
							<span>SL: <b>{{ HangHoa.SoLuongXuat }}</b> {{ HangHoa.TenDonVi }}</span>
							<span class="text-green-darken-2 font-weight-bold">
								{{ (Number(HangHoa.SoLuongXuat) * Number(HangHoa.DonGia)).toLocaleString('vi-VN') }}
							</span>
						</v-list-item-subtitle>
					</v-list-item>
				</v-list>

				<div v-else>
					<uc-empty text="Chưa có hàng hoá để hiển thị"></uc-empty>
				</div>
			</div>

			<!-- Summary footer -->
			<div class="drawer-summary d-flex justify-space-between align-center">
				<span class="text-body-2 text-grey">Tổng tiền hàng</span>
				<span class="text-h6 font-weight-bold text-green-darken-2">{{ tongTienHang.toLocaleString('vi-VN') }} đ</span>
			</div>
		</template>
	</v-navigation-drawer>
</template>

<script>
	export default {
		props: {
			isShow: Boolean,
			selectedItem: Object,
		},
		emits: ['update:isShow', 'print-emit'],
		computed: {
			loaiPhieuText() {
				const map = {
					'HUY': 'Huỷ', 'SAN_XUAT': 'Sản xuất',
					'SU_DUNG': 'Sử dụng', 'LUAN_CHUYEN': 'Luân chuyển'
				}
				return map[this.selectedItem?.LoaiPhieuXuat] || ''
			},
			loaiPhieuColor() {
				const map = {
					'HUY': 'primary', 'SAN_XUAT': 'success',
					'SU_DUNG': 'orange', 'LUAN_CHUYEN': 'purple'
				}
				return map[this.selectedItem?.LoaiPhieuXuat] || 'grey'
			},
			tongTienHang() {
				if (!this.selectedItem?.arrayHangHoa) return 0
				return this.selectedItem.arrayHangHoa.reduce((sum, item) => {
					return sum + (Number(item.SoLuongXuat) * Number(item.DonGia) || 0)
				}, 0)
			},
		},
		methods: {
			closeDrawer() {
				this.$emit('update:isShow', false)
			},
			formatDate: window.formatDate,
		},
	}
</script>