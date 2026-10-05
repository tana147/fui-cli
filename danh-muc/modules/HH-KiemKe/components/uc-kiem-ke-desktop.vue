<template>
	<div class="d-flex" style="height: 100%">
		<!-- Bảng chính — không còn expanded row, click row mở drawer -->
		<v-data-table-virtual :items="DSHangHoa" :headers="headers" :height="tableHeight" density="compact"
			:disable-sort="true" fixed-header item-value="HangHoa_Id" @click:row="onClickRow" :row-props="getRowProps">

			<template v-slot:item.LoaiDisplay="{ item }">
				<v-chip size="small" :color="getLoaiColor(item)" variant="tonal">
					{{ getLoaiText(item) }}
				</v-chip>
			</template>

			<template v-slot:item.TrangThaiKK="{ item }">
				<v-chip size="small" :color="getKKStatusColor(item)" variant="tonal">
					{{ getKKStatusText(item) }}
				</v-chip>
			</template>

			<template #no-data>
				<uc-empty text="Chưa có hàng hoá để hiển thị" />
			</template>
		</v-data-table-virtual>

		<!-- Drawer chi tiết bên phải -->
		<v-navigation-drawer v-model="showDrawer" location="right" width="520" temporary :scrim="false"
			class="elevation-5">
			<template v-if="selectedItem">
				<!-- Header -->
				<div class="pa-3 border-b bg-grey-lighten-5">
					<div class="d-flex align-center justify-space-between">
						<div class="d-flex align-center ga-2 overflow-hidden">
							<v-chip size="small" :color="getLoaiColor(selectedItem)" variant="tonal">
								{{ getLoaiText(selectedItem) }}
							</v-chip>
							<span class="text-body-1 font-weight-medium text-truncate">
								{{ selectedItem.TenHangHoa }}
							</span>
						</div>
						<v-btn icon="mdi-close" size="small" variant="text" @click="closeDrawer" />
					</div>
					<div class="text-caption text-medium-emphasis mt-1">
						{{ selectedItem.Is_CaBiet ? 'Cá biệt' : 'Tổng' }}:
						<b>{{ selectedItem.Tong }}</b> {{ selectedItem.TenDonVi }}
						·
						<v-chip size="x-small" :color="getKKStatusColor(selectedItem)" variant="tonal" class="ml-1">
							{{ getKKStatusText(selectedItem) }}
						</v-chip>
					</div>
				</div>

				<!-- Nội dung -->
				<div class="kk-drawer-body">
					<!-- Hàng hoá thường (DSSoLuong) -->
					<template v-if="!selectedItem.Is_CaBiet">
						<div v-for="(HangHoa, idx) in selectedItem.DSSoLuong" :key="idx" class="pa-3" :class="{
								'border-b': idx !== selectedItem.DSSoLuong.length - 1,
								'bg-green-lighten-5': HangHoa.TinhTrangKiemKe && !isKiemKe
							}">
							<div class="d-flex align-center justify-space-between mb-2">
								<div class="text-body-2 font-weight-medium">
									<v-icon size="16" class="mr-1">mdi-map-marker-outline</v-icon>
									{{ HangHoa.TenKhuVuc }}
								</div>
								<template v-if="!isKiemKe">
									<v-chip size="small" :color="HangHoa.TinhTrangKiemKe ? 'green' : 'orange'"
										variant="tonal">
										{{ HangHoa.TinhTrangKiemKe ? 'Đã kiểm kê' : 'Chưa kiểm kê' }}
									</v-chip>
								</template>
								<template v-else>
									<input type="checkbox" class="kk-native-checkbox" :checked="HangHoa.TinhTrangKiemKe"
										@change="onCheckKiemKe(HangHoa, $event)" />
								</template>
							</div>
							<div class="mb-2">
								<div class="text-caption text-medium-emphasis mb-1">Đơn vị kiểm kê</div>
								<div v-if="!isKiemKe" class="text-body-2 font-weight-medium">
									{{ getTenDonViTinh(HangHoa.DonViKiemKe_Id) }}
								</div>
								<select v-else class="kk-native-select" :value="HangHoa.DonViKiemKe_Id"
									@change="onSelectDonVi(HangHoa, $event)">
									<option value="" disabled>Chọn đơn vị</option>
									<option v-for="dv in HangHoa.DSDonViTinh" :key="dv.DonViTinh_Id"
										:value="dv.DonViTinh_Id">{{ dv.TenDonViQuyDoi }}</option>
								</select>
							</div>
							<div class="d-flex ga-3 mb-2">
								<div class="flex-1">
									<div class="text-caption text-medium-emphasis">Thực tế</div>
									<div v-if="!isKiemKe" class="text-body-2 font-weight-medium">
										{{ HangHoa.SoLuongThucTe }}
									</div>
									<input v-else class="kk-native-input" type="number" step="0.01"
										:value="HangHoa.SoLuongThucTe"
										@input="HangHoa.SoLuongThucTe = $event.target.value"
										@blur="HangHoa.SoLuongThucTe = format2(HangHoa.SoLuongThucTe)"
										:disabled="HangHoa.DonViKiemKe_Id === null" />
								</div>
								<div class="flex-1">
									<div class="text-caption text-medium-emphasis">Hệ thống</div>
									<div class="text-body-2 font-weight-medium">{{ HangHoa.TongSauQuyDoi }}</div>
								</div>
							</div>
							<div>
								<div class="text-caption text-medium-emphasis mb-1">Ghi chú</div>
								<div v-if="!isKiemKe" class="text-body-2">{{ HangHoa.GhiChu || '—' }}</div>
								<textarea v-else class="kk-native-textarea" rows="1" placeholder="Ghi chú"
									:value="HangHoa.GhiChu" @input="HangHoa.GhiChu = $event.target.value"></textarea>
							</div>
						</div>
					</template>

					<!-- Hàng hoá cá biệt (DSCaBiet) -->
					<template v-else>
						<div v-for="(CaBiet, idx) in selectedItem.DSCaBiet" :key="idx" class="pa-3" :class="{
								'border-b': idx !== selectedItem.DSCaBiet.length - 1,
								'bg-green-lighten-5': CaBiet.TinhTrangKiemKe && !isKiemKe
							}">
							<div class="d-flex align-center justify-space-between mb-2">
								<div class="text-body-2 font-weight-medium">{{ CaBiet.SoSeries }}</div>
								<template v-if="!isKiemKe">
									<v-chip size="small" :color="CaBiet.TinhTrangKiemKe ? 'green' : 'orange'"
										variant="tonal">
										{{ CaBiet.TinhTrangKiemKe ? 'Đã KK' : 'Chưa KK' }}
									</v-chip>
								</template>
								<template v-else>
									<input type="checkbox" class="kk-native-checkbox" :checked="CaBiet.TinhTrangKiemKe"
										@change="CaBiet.TinhTrangKiemKe = $event.target.checked" />
								</template>
							</div>
							<div class="text-caption text-medium-emphasis mb-1">Mã vạch</div>
							<div class="text-body-2 mb-2">{{ CaBiet.MaVach === '' ? 'Chưa có' : CaBiet.MaVach }}</div>
							<div class="text-caption text-medium-emphasis mb-1">Hiện tại</div>
							<div class="text-body-2 mb-2">
								{{ getTenDiaDiem(CaBiet.DiaDiemHienTai_Id) + ' / ' +
								getTenKhuVuc(CaBiet.KhuVucHienTai_Id) + ' / ' }}
								<v-chip :color="mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangHienTai]?.color ?? ''"
									size="small">
									{{ mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangHienTai]?.text ?? 'Chưa rõ' }}
								</v-chip>
							</div>
							<template v-if="!isKiemKe">
								<div class="text-caption text-medium-emphasis mb-1">Thực tế</div>
								<div class="text-body-2 mb-2">
									{{ getTenDiaDiem(CaBiet.DiaDiemThucTe_Id) + ' / ' +
									getTenKhuVuc(CaBiet.KhuVucThucTe_Id) + ' / ' }}
									<v-chip :color="mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangThucTe]?.color ?? ''"
										size="small">
										{{ mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangThucTe]?.text ?? 'Chưa rõ' }}
									</v-chip>
								</div>
							</template>
							<template v-else>
								<select class="kk-native-select mb-2" :value="CaBiet.DiaDiemThucTe_Id"
									@change="CaBiet.DiaDiemThucTe_Id = Number($event.target.value)">
									<option value="" disabled>Địa điểm thực tế</option>
									<option v-for="dd in DSDiaDiem" :key="dd.DiaDiem_Id" :value="dd.DiaDiem_Id">{{
										dd.TenDiaDiem }}</option>
								</select>
								<select class="kk-native-select mb-2" :value="CaBiet.KhuVucThucTe_Id"
									@change="CaBiet.KhuVucThucTe_Id = $event.target.value ? Number($event.target.value) : null">
									<option value="">Khu vực thực tế</option>
									<option v-for="kv in DSKhuVucKho" :key="kv.KhuVuc_Id" :value="kv.KhuVuc_Id">{{
										kv.TenKhuVuc }}</option>
								</select>
								<select class="kk-native-select mb-2" :value="CaBiet.TinhTrangThucTe"
									@change="CaBiet.TinhTrangThucTe = $event.target.value">
									<option value="" disabled>Tình trạng thực tế</option>
									<option v-for="tt in DSTinhTrangCaBiet" :key="tt.value" :value="tt.value">{{
										tt.title }}</option>
								</select>
							</template>
							<div>
								<div class="text-caption text-medium-emphasis mb-1">Ghi chú</div>
								<div v-if="!isKiemKe" class="text-body-2">{{ CaBiet.GhiChu || '—' }}</div>
								<textarea v-else class="kk-native-textarea" rows="1" placeholder="Ghi chú"
									:value="CaBiet.GhiChu" @input="CaBiet.GhiChu = $event.target.value"></textarea>
							</div>
						</div>
					</template>
				</div>

				<!-- Điều hướng -->
				<div class="kk-drawer-footer d-flex align-center justify-space-between border-t pa-2">
					<v-btn variant="text" size="small" :disabled="selectedIndex <= 0" @click="navigateItem(-1)"
						prepend-icon="mdi-chevron-left">Trước</v-btn>
					<span class="text-caption text-medium-emphasis">
						{{ selectedIndex + 1 }} / {{ DSHangHoa.length }}
					</span>
					<v-btn variant="text" size="small" :disabled="selectedIndex >= DSHangHoa.length - 1"
						@click="navigateItem(1)" append-icon="mdi-chevron-right">Sau</v-btn>
				</div>
			</template>
		</v-navigation-drawer>
	</div>
</template>
<script>
	export default {
		name: 'uc-kiem-ke-desktop',
		props: {
			DSHangHoa: Array,
			isKiemKe: Boolean,
			DSDiaDiem: Array,
			DSKhuVucKho: Array,
			DSDonViTinh: Array,
			mapDiaDiem: Object,
			mapKhuVuc: Object,
			mapDonViTinh: Object,
			tableHeight: { type: String, default: 'calc(100vh - 249px)' },
		},
		emits: ['select-don-vi-tinh', 'check-kiem-ke'],
		data() {
			return {
				mapTinhTrangHangHoaCaBiet,
				DSTinhTrangCaBiet,
				showDrawer: false,
				selectedItem: null,
				selectedIndex: -1,
				headers: [
					{ title: "Tên hàng hoá", key: "TenHangHoa", align: 'start' },
					{ title: "Loại", key: "LoaiDisplay", align: 'center', width: 120 },
					{ title: "ĐVT", key: "TenDonVi", align: 'center', width: 100 },
					{ title: "Tổng SL", key: "Tong", align: 'end', width: 90 },
					{ title: "Kiểm kê", key: "TrangThaiKK", align: 'center', width: 130 },
				],
			}
		},
		methods: {
			onClickRow(event, row) {
				this.selectedItem = row.item
				this.selectedIndex = this.DSHangHoa.indexOf(row.item)
				this.showDrawer = true
			},
			getRowProps(row) {
				return {
					class: this.selectedItem === row.item ? 'bg-blue-lighten-5' : '',
					style: 'cursor: pointer',
				}
			},
			validateCurrentItem() {
				if (!this.isKiemKe || !this.selectedItem) return true
				if (!this.selectedItem.Is_CaBiet) {
					const invalid = (this.selectedItem.DSSoLuong || []).find(
						x => x.TinhTrangKiemKe && Number(x.SoLuongThucTe) < 0
					)
					if (invalid) {
						showToast.error('Số lượng thực tế không được âm (' + invalid.TenKhuVuc + ')')
						return false
					}
				}
				return true
			},
			closeDrawer() {
				if (!this.validateCurrentItem()) return
				this.showDrawer = false
			},
			navigateItem(direction) {
				if (!this.validateCurrentItem()) return
				const newIndex = this.selectedIndex + direction
				if (newIndex < 0 || newIndex >= this.DSHangHoa.length) return
				this.selectedIndex = newIndex
				this.selectedItem = this.DSHangHoa[newIndex]
			},
			onSelectDonVi(HangHoa, event) {
				HangHoa.DonViKiemKe_Id = Number(event.target.value)
				this.$emit('select-don-vi-tinh', HangHoa)
			},
			onCheckKiemKe(HangHoa, event) {
				HangHoa.TinhTrangKiemKe = event.target.checked
				this.$emit('check-kiem-ke', HangHoa)
			},
			format2(v) {
				const n = parseFloat(v)
				if (isNaN(n)) return ''
				return (Math.round(n * 100) / 100).toFixed(2)
			},
			getTenDiaDiem(DiaDiem_Id) {
				return this.mapDiaDiem[DiaDiem_Id] ?? 'Chưa rõ'
			},
			getTenKhuVuc(KhuVuc_Id) {
				return this.mapKhuVuc[KhuVuc_Id] ?? 'Chưa rõ'
			},
			getTenDonViTinh(DonViTinh_Id) {
				return this.mapDonViTinh[DonViTinh_Id] ?? ''
			},
			getLoaiText(item) {
				if (item.Is_CaBiet) return 'Tài sản'
				if (item.LoaiNguyenLieu === 'TP') return 'Thành phẩm'
				if (item.LoaiNguyenLieu === 'BTP') return 'Bán TP'
				if (item.LoaiNguyenLieu === 'NL') return 'Nguyên liệu'
				if (item.LoaiHangHoa === 'CCDC') return 'CCDC'
				return 'Khác'
			},
			getLoaiColor(item) {
				if (item.Is_CaBiet) return 'purple'
				if (item.LoaiNguyenLieu === 'TP') return 'green'
				if (item.LoaiNguyenLieu === 'BTP') return 'teal'
				if (item.LoaiNguyenLieu === 'NVL') return 'blue'
				if (item.LoaiHangHoa === 'CCDC') return 'orange'
				return 'grey'
			},
			getKKCount(item) {
				if (item.Is_CaBiet) {
					const arr = item.DSCaBiet || []
					return { done: arr.filter(x => x.TinhTrangKiemKe).length, total: arr.length }
				}
				const arr = item.DSSoLuong || []
				return { done: arr.filter(x => x.TinhTrangKiemKe).length, total: arr.length }
			},
			getKKStatusText(item) {
				const { done, total } = this.getKKCount(item)
				if (total === 0) return 'Chưa có'
				if (done === total) return 'Hoàn thành'
				return done + '/' + total
			},
			getKKStatusColor(item) {
				const { done, total } = this.getKKCount(item)
				if (total === 0) return 'grey'
				if (done === total) return 'green'
				if (done > 0) return 'orange'
				return 'red'
			},
		}
	}
</script>