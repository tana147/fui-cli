<template>
	<v-navigation-drawer :model-value="isShow" @update:model-value="closeDrawer" location="right" width="800" temporary
		:scrim="false" class="elevation-5">
		<template v-if="selectedItem">
			<div class="pa-4 border-b bg-grey-lighten-5">
				<div class="d-flex justify-space-between align-center mb-2">
					<div class="d-flex align-center ga-2">
						<h3 class="text-h6 font-weight-bold text-blue-grey-darken-3">Chi tiết phiếu nhập</h3>
						<v-chip v-if="selectedItem.TinhTrang" size="small" :color="tinhTrangColor" variant="flat"
							class="font-weight-bold">
							{{ tinhTrangText }}
						</v-chip>
					</div>
					<div class="d-flex align-center ga-1">
						<v-btn v-if="selectedItem.TinhTrang === 'CHO_HOA_DON'" size="small" variant="tonal"
							color="primary" prepend-icon="mdi-square-edit-outline"
							@click="$emit('edit-emit', selectedItem)">Sửa</v-btn>
						<v-btn v-if="selectedItem.LoaiPhieu !== 'PHIEU_DAT_HANG'" size="small" variant="tonal"
							color="grey-darken-1" prepend-icon="mdi-printer-outline"
							@click="$emit('print-emit', selectedItem)">In</v-btn>
						<v-btn icon="mdi-close" variant="text" size="small" @click="closeDrawer"></v-btn>
					</div>
				</div>

				<v-table density="compact" class="bg-transparent">
					<tbody>
						<tr>
							<td class="text-grey text-caption" style="width:130px">NHÀ CUNG CẤP</td>
							<td class="font-weight-bold text-right">{{ selectedItem.TenNhaCungCap }}</td>
						</tr>
						<tr>
							<td class="text-grey text-caption">SỐ HÓA ĐƠN</td>
							<td class="font-weight-bold text-right">{{ selectedItem.SoHoaDon }}</td>
						</tr>
						<tr>
							<td class="text-grey text-caption">NGÀY NHẬP</td>
							<td class="font-weight-bold text-right">{{ formatDate(selectedItem.NgayNhap) }}</td>
						</tr>
						<tr>
							<td class="text-grey text-caption">ĐỊA ĐIỂM</td>
							<td class="font-weight-bold text-right">{{ selectedItem.TenDiaDiem }}</td>
						</tr>
					</tbody>
				</v-table>

				<div class="mt-2">
					<uc-file-chip :items="selectedItem?.DSFile ?? []"></uc-file-chip>
				</div>
			</div>

			<div class="pa-4 d-flex flex-column" style="height: calc(100% - 310px);">
				<div class="d-flex justify-space-between align-center mb-3">
					<div class="text-subtitle-2 font-weight-bold">DANH SÁCH HÀNG HOÁ ĐÃ NHẬP</div>
					<v-chip size="small" color="primary" variant="tonal">
						{{ selectedItem?.arrayHangHoa?.length ?? 0 }} mặt hàng
					</v-chip>
				</div>

				<v-list v-if="selectedItem?.arrayHangHoa?.length > 0" lines="two"
					class="pa-0 flex-grow-1 overflow-y-auto custom-scroll">
					<v-list-item v-for="(HangHoa, index) in selectedItem.arrayHangHoa" :key="index"
						class="border rounded-lg mb-2 pa-2">
						<template v-slot:prepend>
							<v-avatar
								:color="HangHoa.Is_CaBiet ? 'purple-lighten-5' : HangHoa.LoaiHangHoa === 'CCDC' ? 'orange-lighten-5' : 'blue-lighten-5'"
								rounded size="40">
								<v-icon size="20"
									:color="HangHoa.Is_CaBiet ? 'purple' : HangHoa.LoaiHangHoa === 'CCDC' ? 'orange-darken-2' : 'blue'">
									{{ HangHoa.Is_CaBiet ? 'mdi-devices' : HangHoa.LoaiHangHoa === 'CCDC' ? 'mdi-tools'
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
				</v-list>

				<div v-else>
					<uc-empty text="Chưa có hàng hoá để hiển thị"></uc-empty>
				</div>
			</div>

			<div class="drawer-summary d-flex justify-space-between align-center">
				<span class="text-body-2 text-grey-darken-1">Tổng tiền hàng</span>
				<span class="text-h6 font-weight-bold text-primary">{{ tongTienHang }}</span>
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
	emits: ['update:isShow', 'edit-emit', 'print-emit'],
	computed: {
		tinhTrangText() {
			const map = {
				'CHO_DUYET': 'Chờ duyệt',
				'CHO_HOA_DON': 'Chờ hoá đơn',
				'HOAN_THANH': 'Hoàn thành',
				'DAT_HANG': 'Đặt hàng',
			}
			return map[this.selectedItem?.TinhTrang] ?? this.selectedItem?.TinhTrang
		},
		tinhTrangColor() {
			const map = {
				'CHO_DUYET': 'warning',
				'CHO_HOA_DON': 'info',
				'HOAN_THANH': 'success',
				'DAT_HANG': 'purple',
			}
			return map[this.selectedItem?.TinhTrang] ?? 'grey'
		},
		tongTienHang() {
			const items = this.selectedItem?.arrayHangHoa
			if (!items || items.length === 0) return '0'
			const total = items.reduce((sum, h) => {
				return sum + this.calcThanhTien(h)
			}, 0)
			return total.toLocaleString('vi-VN')
		},
	},
	methods: {
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
		closeDrawer() {
			this.$emit('update:isShow', false)
		},
		formatDate: window.formatDate,
	},
}
</script>