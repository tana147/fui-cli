<template>
	<!-- <z-layout> -->
	<div class="px-2">
		<!-- Loading Overlay -->
		<v-overlay v-model="isLoading" class="align-center justify-center">
			<v-progress-circular indeterminate size="64" color="primary"></v-progress-circular>
		</v-overlay>

		<!-- Header -->
		<div class="d-flex flex-column">
			<!-- Row 1: Chọn sản phẩm và Thông tin chi tiết sản phẩm -->
			<div class="d-flex">
				<!-- Bên trái: Chọn sản phẩm -->
				<div style="flex: 1;" class="pa-1">
					<div class="text-subtitle-1 text-primary">
						<b>Chọn sản phẩm</b>
					</div>
					<uc-search-nguyen-lieu v-model:value="ChiTietNguyenLieu.HangHoa_Id" placeholder="Sản phẩm *"
						loaiNguyenLieu="TP,BTP" isHideDetail isUnderlined />
				</div>

				<!-- Bên phải: Thông tin chi tiết sản phẩm -->
				<div style="flex: 5;" class="d-flex flex-column pa-1">
					<div class="text-subtitle-1 text-primary">
						<b>Thông tin chi tiết</b>
					</div>

					<div class="d-flex ga-3">
						<div style="flex: 0.75;">
							<div class="text-caption text-medium-emphasis">Mã sản phẩm</div>
							<div class="text-body-2">{{ ChiTietNguyenLieu.MaNoiBo || '-' }}</div>
						</div>
						<div style="flex: 0.75;">
							<div class="text-caption text-medium-emphasis">Phân loại</div>
							<div class="text-body-2">{{ ChiTietNguyenLieu.TenLoaiNguyenLieu || '-' }}</div>
						</div>
						<div style="flex: 0.75;">
							<div class="text-caption text-medium-emphasis">Đơn vị nhập</div>
							<div class="text-body-2">{{ ChiTietNguyenLieu.TenDonVi || '-' }}</div>
						</div>
						<div style="flex: 0.75;">
							<div class="text-caption text-medium-emphasis">Giá nhập</div>
							<div class="text-body-2">{{ ChiTietNguyenLieu.DonGia_ApDung?.toLocaleString('vi-VN') || '0'
								}}
							</div>
						</div>
						<div style="flex: 0.75;">
							<div class="text-caption text-medium-emphasis">Giá bán</div>
							<div class="text-body-2">{{ ChiTietNguyenLieu.GiaBan?.toLocaleString('vi-VN') || '0' }}
							</div>
						</div>
						<div style="flex: 0.75;">
							<div class="text-caption text-medium-emphasis">Tỉ lệ so với CP</div>
							<div class="text-body-2">{{ tiLeSoVoiChiPhiAuto || 0 }}%</div>
						</div>
						<div style="flex: 0.75;">
							<div class="text-caption text-medium-emphasis">Hạn sử dụng</div>
							<div class="text-body-2">{{ ChiTietNguyenLieu.HanSuDung_Gio || '-' }} giờ</div>
						</div>
						<div style="flex: 1;">
							<div class="text-caption text-medium-emphasis">Cách bảo quản</div>
							<div class="text-body-2">{{ cachThucBaoQuan || '-' }}</div>
						</div>
						<div style="flex: 0.75;">
							<div class="text-caption text-medium-emphasis">Thiết bị bảo quản</div>
							<div class="text-body-2">{{ ChiTietNguyenLieu.BaoQuan_ThietBi || '-' }}</div>
						</div>
						<div style="flex: 1.5;">
							<div class="text-caption text-medium-emphasis">Mô tả</div>
							<div class="text-body-2">{{ ChiTietNguyenLieu.MoTa || '-' }}</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Row 2: Chọn địa điểm sản xuất, sử dụng, khu vực chế biến và ghi chú -->
			<div class="d-flex flex-column pa-1">
				<div class="text-subtitle-1 text-primary">
					<b>Thông tin sử dụng</b>
				</div>

				<div class="d-flex ga-3">
					<div style="flex: 1;">
						<v-autocomplete v-model="diadDiemSanXuatSelect" :items="DsDiaDiemSanXuat"
							item-title="TenDiaDiem" item-value="DiaDiem_Id" label="Chọn địa điểm sản xuất *"
							variant="underlined" density="compact" class="mt-2" />
					</div>

					<div style="flex: 1;">
						<v-autocomplete v-model="khuVucCheBienSelect" item-title="TenKhuVuc" item-value="KhuVuc_Id"
							:items="filteredDsKhuVucCheBien" label="Chọn khu vực chế biến *"
							:disabled="!diadDiemSanXuatSelect" variant="underlined" density="compact" class="mt-2" />
					</div>

					<div style="flex: 1;">
						<v-autocomplete v-model="diadDiemSuDungSelect" :items="DsDiaDiemSuDung" item-title="TenDiaDiem"
							item-value="DiaDiem_Id" label="Chọn địa điểm sử dụng *" variant="underlined"
							density="compact" class="mt-2" />
					</div>

					<div style="flex: 1;">
						<v-text-field v-model="ChiTietNguyenLieu.GhiChu" label="Ghi chú" density="compact"
							variant="underlined" class="mt-2" />
					</div>

					<div style="flex: 0.25;">
						<v-checkbox v-model="ChiTietNguyenLieu.Is_TamKhoa" label="Tạm khóa" color="primary" hide-details
							density="compact" />
					</div>
				</div>
			</div>
		</div>
	</div>

	<v-toolbar density="comfortable" class="ml-3 mr-3">
		<v-sheet>
			<v-toolbar-title class="text-primary text-subtitle-1">
				<b>Công thức chế biến</b>
				<v-chip size="small" variant="tonal" color="primary" class="ml-1">
					SL: {{ filteredRecipes.length }}
				</v-chip>
			</v-toolbar-title>
		</v-sheet>

		<v-spacer />

		<!-- Export -->
		<v-btn color="green" variant="text" @click="exportExcel">
			<v-icon :size="24">mdi-microsoft-excel</v-icon>
		</v-btn>

		<!-- Quy đổi -->
		<!-- <v-btn color="primary" variant="flat" @click="showModalQuyDoi" prepend-icon="mdi-swap-horizontal" text="Quy đổi"
			class="mr-2" /> -->

		<!-- Lưu tất cả -->
		<!-- <v-btn v-if="!isEditPage" color="success" variant="flat" @click="saveAll" prepend-icon="mdi-content-save"
			text="Lưu thông tin" class="mr-2" /> -->

		<!-- Cập nhật -->
		<!-- <v-btn v-if="isEditPage" color="success" variant="flat" @click="editAll" prepend-icon="mdi-content-save"
			text="Lưu thông tin" class="mr-2" /> -->

		<!-- Search -->
		<v-text-field v-model="search" label="Tìm kiếm" prepend-inner-icon="mdi-magnify" density="compact"
			variant="underlined" color="primary" class="mr-4"
			:style="$vuetify.display.smAndDown ? 'width: 100px' : 'max-width: 300px'" />

		<v-btn icon="mdi-plus" size="32" variant="outlined" color="primary" @click="themDongMoi" class="mr-6" />
	</v-toolbar>

	<v-divider />

	<v-table fixed-header height="calc(100vh - 280px)" density="compact" style="min-width: 1200px" class="ml-3 mr-3">
		<thead>
			<tr>
				<th v-for="c in tatCaCot" :key="c.key" :class="c.align ? 'text-' + c.align : ''"
					:style="'width: ' + c.width + 'px; min-width: ' + c.width + 'px'">
					<div v-if="c.key === 'DinhLuongMotPhan'" class="d-flex align-center justify-center">
						{{ c.title }}
						<v-btn icon="mdi-flask-plus" size="22" variant="outlined" color="primary"
							@click="showModalThemCot" class="ml-2">
							<v-icon size="14">mdi-flask-plus</v-icon>
						</v-btn>
					</div>

					<template v-else-if="c.key === 'GhiChu'">
						{{ c.title }}
						<v-tooltip interactive>
							<template v-slot:activator="{ props: activatorProps }">
								<v-icon size="x-small" icon="mdi-information-outline" v-bind="activatorProps"></v-icon>
							</template>
							Nhấn đúp để cập nhật ghi chú!
						</v-tooltip>
					</template>

					<span v-else>{{ c.title }}</span>
				</th>
			</tr>
		</thead>

		<tbody>
			<!-- No data -->
			<tr v-if="!filteredRecipes || filteredRecipes.length === 0">
				<td :colspan="tatCaCot.length" class="text-center py-4 text-grey">
					Không tìm thấy dữ liệu
				</td>
			</tr>

			<!-- Data -->
			<tr v-for="(row, i) in filteredRecipes" :key="rowKey(row, i)">
				<!-- STT -->
				<td class="text-center">{{ i + 1 }}</td>

				<!-- Các cột còn lại -->
				<td v-for="c in colsBody" :key="c.key" :class="c.align ? 'text-' + c.align : ''">
					<div v-if="c.key === 'DinhLuongMotPhan'" class="d-flex justify-end">
						<!-- Chế độ edit hoặc đang edit dòng này -->
						<v-text-field v-if="!isEditPage || editingRow === row.STT" v-model.number="row[c.key]"
							density="compact" hide-details type="number" min="0" variant="underlined"
							style="max-width: 70px" @input="onDinhLuongChange(row)"
							@keyup.enter="onDinhLuongChange(row)" class="number-field" />
						<!-- Chế độ xem (chưa edit) -->
						<div v-else>
							{{ row[c.key] || 0 }}
						</div>
					</div>

					<template v-else-if="c.key === 'NguyenVatLieu'">
						<uc-search-nguyen-lieu v-if="!isEditPage || editingRow === row.STT"
							:key="'nvl-' + row.STT + '-' + (row.HangHoa_Id || 'empty')" v-model:value="row.HangHoa_Id"
							density="compact" isUnderlined @update:value="(val) => onSelectNguyenLieuRow(val, row)"
							isHideDetail loaiNguyenLieu="" placeholder="Nguyên vật liệu" />
						<div v-else>{{ row.TenHangHoa }}</div>
					</template>

					<template v-else-if="c.key === 'GiaNguyenVatLieu'">
						<div class="text-right">
							<!-- Trạng thái 1: Có giá trị số hợp lệ > 0 (đã load từ DB) -->
							<span v-if="typeof row[c.key] === 'number' && row[c.key] > 0">
								{{ Math.ceil(row[c.key]).toLocaleString('vi-VN') }}
							</span>

							<!-- Trạng thái 2: Giá trị = 0 (có đơn vị nhưng không có hệ số quy đổi) -->
							<v-tooltip v-else-if="typeof row[c.key] === 'number' && row[c.key] === 0" interactive>
								<template v-slot:activator="{ props: activatorProps }">
									<v-icon size="x-small" icon="mdi-information-outline"
										v-bind="activatorProps"></v-icon>
								</template>
								Chưa có hệ số quy đổi!
							</v-tooltip>

							<!-- Trạng thái 3: String hoặc chưa tính (mới thêm dòng) -->
							<span v-else class="text-grey text-caption">
								{{ row[c.key] || 'Lưu để tính giá NVL' }}
							</span>
						</div>
					</template>

					<div v-else-if="c.key === 'DonVi'" class="d-flex justify-center">
						<template v-if="!isEditPage || editingRow === row.STT">
							<v-autocomplete v-if="row.DonViCheck" v-model="row[c.key]" :items="row.DonViQuyDoiOptions"
								item-title="QuyDoi_DonViTinh_Ten" item-value="QuyDoi_DonViTinh_Id"
								style="max-width: 90px" variant="underlined" />
							<div v-else class="d-flex align-center justify-center" style="width: 90px">
								<v-autocomplete v-model="row[c.key]" :items="row.DonViGocOptions" item-title="TenDonVi"
									item-value="DonViTinh_Id" style="max-width: 90px" variant="underlined" />
								<v-tooltip interactive>
									<template v-slot:activator="{ props: activatorProps }">
										<v-icon size="x-small" icon="mdi-information-outline"
											v-bind="activatorProps"></v-icon>
									</template>
									Chưa có đơn vị quy đổi, đang dùng đơn vị nhập!
								</v-tooltip>
							</div>
						</template>
						<div v-else>{{ row.TenDonVi }}</div>
					</div>

					<template v-else-if="c.key === 'ChiPhiSuDung'">
						<div class="text-right">
							{{ Math.ceil(row[c.key] || 0).toLocaleString('vi-VN') }}
						</div>
					</template>

					<template v-else-if="c.key === 'GhiChu'">
						<div v-if="editingGhiChuCell?.rowId === row.STT && editingGhiChuCell?.key === c.key"
							class="d-flex">
							<v-text-field v-model="row[c.key]" density="compact" hide-details variant="underlined"
								autofocus @keyup.enter="saveGhiChu(row)" />
							<v-btn icon="mdi-content-save" variant="text" size="small" @click="saveGhiChu(row)"
								color="green" />
							<v-btn icon="mdi-close" variant="text" size="small" @click="cancelGhiChu(row)"
								color="red" />
						</div>
						<div v-else @dblclick="editGhiChu(row, c.key)" style="cursor: pointer; min-height: 20px;">
							<span v-if="row[c.key]">{{ row[c.key] }}</span>
							<span v-else class="text-grey">Nhấn đúp để ghi chú</span>
						</div>
					</template>

					<template v-else-if="c.isCotDinhLuong && c.key !== 'DinhLuongMotPhan'">
						<div class="text-right">
							{{ row[c.key] }}
						</div>
					</template>

					<div v-else-if="c.key === 'Is_TinhDinhLuong'" class="d-flex justify-center">
						<v-checkbox v-model="row[c.key]" color="primary" hide-details
							@change="onDinhLuongChange(row)" />
					</div>

					<template v-else>{{ row.TenDonVi }}</template>
				</td>

				<!-- Action -->
				<td class="text-center">
					<v-btn v-if="isEditPage && editingRow !== row.STT" icon="mdi-square-edit-outline" color="primary"
						variant="text" size="small" @click="editRow(row)" />
					<v-btn v-if="isEditPage && editingRow === row.STT" icon="mdi-content-save" color="green"
						variant="text" size="small" @click="saveRow(row)" />
					<v-btn icon="mdi-trash-can" color="red" variant="text" size="small" @click="xoaThanhPhan(row, i)" />
				</td>
			</tr>
		</tbody>

		<!-- TĐL, sau khi nấu, hao hụt -->
		<tfoot>
			<!-- Tổng định lượng -->
			<tr>
				<td></td>
				<td></td>
				<td></td>
				<td colspan="2" class="text-right font-weight-bold">Tổng định lượng</td>
				<td class="text-center font-weight-bold">{{ donViTDL }}</td>

				<td v-for="c in cotDinhLuong" :key="'tdl-' + c.key" class="text-center font-weight-bold text-primary">
					<!-- <div class="d-flex justify-center align-center"> -->
					<div class="text-right">
						{{ tongTheoCot[c.key].toFixed(2) }}
					</div>
					<!-- </div> -->
				</td>

				<td></td>
				<td></td>
			</tr>

			<!-- Sau khi nấu -->
			<tr>
				<td></td>
				<td></td>
				<td></td>
				<td colspan="2" class="text-right font-weight-bold">Sau khi nấu</td>
				<td class="text-center font-weight-bold">{{ donViSauKhiNau }}</td>

				<td v-for="c in cotDinhLuong" :key="'sau-' + c.key">
					<!-- Chế độ edit: cho phép nhập -->
					<div v-if="!isDisabledSauKhiNau" class="d-flex justify-end">
						<v-text-field v-model.number="sauKhiNauJson[jsonKey(c.dinhLuong)]" density="compact"
							hide-details type="number" min="0" variant="underlined" style="max-width: 70px"
							class="number-field" />
					</div>
					<!-- Chế độ xem: chỉ hiển thị -->
					<div v-else class="text-right">
						{{ sauKhiNauJson[jsonKey(c.dinhLuong)] || 0 }}
					</div>
				</td>

				<td></td>
				<td class="text-center">
					<v-btn v-if="!isDisabledSauKhiNau" icon="mdi-content-save" variant="text" size="small"
						@click="saveSauKhiNau" color="green" />
					<v-btn v-else icon="mdi-square-edit-outline" variant="text" size="small" @click="editSauKhiNau"
						color="primary" />
				</td>
			</tr>

			<!-- Hao hụt -->
			<tr>
				<td></td>
				<td></td>
				<td></td>
				<td colspan="2" class="text-right font-weight-bold">Hao hụt</td>
				<td class="text-center font-weight-bold">{{ donViHaoHut }}</td>

				<td v-for="c in cotDinhLuong" :key="'hao-' + c.key" class="text-center text-red font-weight-bold">
					<div class="text-right">
						{{ haoHutTheoCot[c.key] }}
					</div>
				</td>

				<td></td>
				<td></td>
			</tr>

			<!-- Tổng chi phí -->
			<tr class="bg-blue-lighten-5">
				<td></td>
				<td></td>
				<td></td>
				<td colspan="2" class="text-right font-weight-bold">Tổng chi phí</td>
				<td class="text-center font-weight-bold">VNĐ</td>

				<td v-for="c in cotDinhLuong" :key="'cost-' + c.key" class="text-center font-weight-bold text-green">
					<div class="text-right">
						{{ Math.ceil(tongChiPhiTheoCot[c.key]).toLocaleString('vi-VN') }}
					</div>
				</td>

				<td></td>
				<td></td>
			</tr>
		</tfoot>
	</v-table>

	<v-toolbar density="comfortable" class="ml-3 mr-6 mt-2">
		<v-spacer />

		<!-- Lưu tất cả -->
		<v-btn v-if="!isEditPage" color="success" variant="flat" @click="saveAll" prepend-icon="mdi-content-save"
			text="Lưu thông tin" class="mr-6" />

		<!-- Cập nhật -->
		<v-btn v-if="isEditPage" color="success" variant="flat" @click="editAll" prepend-icon="mdi-content-save"
			text="Lưu thông tin" class="mr-6" />
	</v-toolbar>

	<uc-modal-quy-doi v-model="isShowModalQuyDoi" @onReload="reloadData" :donViOpts="donViOpts"
		@updateDonVi="updateDonVi" />

	<uc-modal-edit v-model="isShowModalEdit" @onReload="reloadData" :detailRecord="detailRecord" />

	<uc-modal-them-dinh-luong v-model="isShowModalThemDinhLuong" :dinhLuongOpts="dinhLuongOpts"
		:cotDinhLuongHienTai="cotDinhLuongHienTai" @onCapNhatCot="capNhatCotDinhLuong" />
	<!-- </z-layout> -->
</template>

<script>
	export default {
		data() {
			return {
				vueData,
				vueAction,
	
				// Loading
				isLoading: false,
	
				// Header
				chiNhanh: null,
				khuVucCheBien: null,
	
				// Đơn vị tổng định lượng, sau khi nấu và hao hụt
				donViTDL: 'Gram',
				donViSauKhiNau: 'Gram',
				donViHaoHut: "%",
	
				// Trạng thái edit/save
				isDisabledSauKhiNau: true,
	
				// Thông tin header
				diadDiemSanXuatSelect: null,
				diadDiemSuDungSelect: null,
				khuVucCheBienSelect: null,
				thietBiBaoQuanSelect: null,
				tiLeSoVoiChiPhi: 0,
	
				// Bảo quản
				cachThucBaoQuan: "",
	
				formData: {
					GiaBan: null,
				},
	
				// TABLE DATA
				DsDiaDiemSanXuat: [],
				DsDiaDiemSuDung: [],
				DsKhuVucCheBien: [],
	
				ChiTietNguyenLieu: {
					HangHoa_Id: null,
					EORDER_SanPham_Id: 0,
					NhomNguyenLieu_Id: null,
					NhomThanhPhan_Id: null,
					DonViTinh_Id: null,
					LoaiNguyenLieu: '',
					TenLoaiNguyenLieu: '',
					MaNoiBo: '',
					TenHangHoa: '',
					DonGia_ApDung: 0,
					DonGia_MoiNhat: 0,
					DonGia_TrungBinh: 0,
					HanSuDung_Gio: 0,
					BaoQuan_NhietDo: '',
					BaoQuan_ThietBi: '',
					MauSac: '',
					ThuongHieu: '',
					NguonGoc: '',
					HinhThai: '',
					DacTinh: '',
					MoTa: '',
					Is_TamKhoa: false,
					GhiChu: '',
				},
	
				// KHÔNG CÓ FAKE DATA - SẼ LOAD TỪ API
				DsChiTieTCongThuc: [],
	
				search: "",
				filters: {
					TenNhomNguyenLieu: null,
					TenHangHoa: null,
				},
	
				// select định lượng
				dinhLuongOpts: [
					{ title: "1/2 phần", val: 0.5 },
					{ title: "1 phần", val: 1 },
					{ title: "2 phần", val: 2 },
					{ title: "3 phần", val: 3 },
					{ title: "4 phần", val: 4 },
					{ title: "5 phần", val: 5 },
					{ title: "6 phần", val: 6 },
					{ title: "7 phần", val: 7 },
					{ title: "8 phần", val: 8 },
					{ title: "9 phần", val: 9 },
					{ title: "10 phần", val: 10 },
				],
	
				// cột định lượng (luôn có 1 phần)
				cotDinhLuong: [
					{ dinhLuong: 1, key: "DinhLuongMotPhan", title: "ĐL 1 phần", width: 80 },
				],
	
				sauKhiNauJson: {},
	
				// Cột cố định
				cotCoDinh: [
					{ title: "#", key: "STT", width: 20, align: "center" },
					{ title: "Nguyên vật liệu", key: "NguyenVatLieu", width: 200 },
					{ title: "Ghi chú chung", key: "GhiChu", width: 130 },
					{ title: "Tính ĐL", key: "Is_TinhDinhLuong", width: 50, align: 'center' },
					{ title: "Giá NVL", key: "GiaNguyenVatLieu", width: 50, align: 'center' },
					{ title: "ĐV sử dụng", key: "DonVi", width: 70, align: "center" },
				],
				colAct: [
					{ title: 'CP sử dụng', key: 'ChiPhiSuDung', width: 50, align: 'center' },
					{ title: ``, key: "act", width: 100, align: "center" },
				],
	
				// MODALS
				isShowModalQuyDoi: false,
				isShowModalEdit: false,
				isShowModalThemDinhLuong: false,
				detailRecord: {},
	
				isEditPage: false,
				editingRow: null,
	
				editingGhiChuCell: null,
			}
		},
	
		mounted() {
			const params = new URLSearchParams(vueData.p_params)
			vueData.CongThuc_Id = params.get("CongThuc_Id")
			vueData.TenHangHoa = params.get("TenHangHoa")
	
			this.onLoadDiaDiemSanXuat()
			this.onLoadKhuVucCheBien()
			if (vueData.CongThuc_Id) {
				this.isEditPage = true
				this.getData(vueData.CongThuc_Id)
			}
		},
	
		watch: {
			// Lấy chi tiết của công thức chính
			'ChiTietNguyenLieu.HangHoa_Id'(val) {
				if (val) {
					this.onLoadChiTietNguyenLieu(val)
				}
			},
			// Reset khu vực select về null
			// diadDiemSanXuatSelect(val) {
			// 	if (val) {
			// 		this.khuVucCheBienSelect = null
			// 	}
			// },
		},
	
		computed: {
			// build toàn bộ cột
			tatCaCot() {
				const cotDinhLuongs = this.cotDinhLuong.map((x) => ({
					title: x.title,
					key: x.key,
					width: x.width,
					align: "center",
					isCotDinhLuong: true,
					dinhLuong: x.dinhLuong,
				}))
				return [...this.cotCoDinh, ...cotDinhLuongs, ...this.colAct]
			},
	
			// Group nhóm thành phần (tạm không sử dụng nữa!)
			hasGroup() {
				return this.tatCaCot.some((c) => c.isGroup)
			},
	
			colsBody() {
				return this.tatCaCot.filter((c) => !["STT", "act"].includes(c.key) && !c.isGroup)
			},
	
			// Bộ lọc danh sách công thức
			filteredRecipes() {
				const keyword = (this.search || "").toLowerCase()
	
				const rows = this.DsChiTieTCongThuc.filter((r) => {
					const a = String(r.TenNhomNguyenLieu || "").toLowerCase()
					const b = String(r.TenHangHoa || "").toLowerCase()
					const c = String(r.DinhLuongMotPhan || "").toLowerCase()
	
					const okSearch = !keyword || a.includes(keyword) || b.includes(keyword) || c.includes(keyword)
					const okGroup = !this.filters.TenNhomNguyenLieu || r.TenNhomNguyenLieu === this.filters.TenNhomNguyenLieu
					const okName = !this.filters.NguyenVatLieu || r.TenHangHoa === this.filters.NguyenVatLieu
					return okSearch && okGroup && okName
				})
	
				return rows
			},
	
			// Lọc khu vực chế biến theo select của địa điểm sản xuất
			filteredDsKhuVucCheBien() {
				if (!this.diadDiemSanXuatSelect) return []
				return this.DsKhuVucCheBien.filter((c) => c.DiaDiem_Id === this.diadDiemSanXuatSelect)
			},
	
			// Gộp row nhóm thành phần (Tạm không sử dụng)
			rowSpanMap() {
				const map = {}
				let cur = null
				let start = 0
	
				this.filteredRecipes.forEach((row, idx) => {
					if (row.NhomThanhPhan !== cur) {
						if (cur !== null) map[start] = idx - start
						cur = row.NhomThanhPhan
						start = idx
					}
				})
	
				if (cur !== null) map[start] = this.filteredRecipes.length - start
				return map
			},
	
			// Lấy ra toàn bộ options đơn vị của các thành phần nguyên liệu để quy đổi
			donViOpts() {
				const all = this.DsChiTieTCongThuc.map((x) => x.DonVi)
				const uniq = [...new Set(all)].filter(Boolean)
				return uniq.sort((a, b) => {
					const aValue = String(a ?? "")
					const bValue = String(b ?? "")
					return aValue.localeCompare(bValue, "vi")
				})
			},
	
			// Tổng theo từng cột định lượng
			tongTheoCot() {
				const tong = {}
				this.cotDinhLuong.forEach((c) => {
					tong[c.key] = this.DsChiTieTCongThuc
						.filter(r => r.Is_TinhDinhLuong)
						.reduce((s, r) => s + (parseFloat(r[c.key]) || 0), 0)
				})
				return tong
			},
	
			// Tổng chi phí theo từng cột định lượng
			tongChiPhiTheoCot() {
				const tong = {}
				this.cotDinhLuong.forEach((c) => {
					tong[c.key] = this.DsChiTieTCongThuc
						.filter(r => r.Is_TinhDinhLuong)
						.reduce((s, r) => {
							const dinhLuong = parseFloat(r[c.key]) || 0
							const gia = parseFloat(r.GiaNguyenVatLieu) || 0
							return s + (dinhLuong * gia)
						}, 0)
				})
				return tong
			},
	
			// Hao hụt % theo từng cột định lượng
			haoHutTheoCot() {
				const haoHut = {}
				this.cotDinhLuong.forEach((c) => {
					const tong = parseFloat(this.tongTheoCot[c.key]) || 0
					const sau = parseFloat(this.sauKhiNauJson[this.jsonKey(c.dinhLuong)]) || 0
					haoHut[c.key] = tong > 0 && sau > 0 ? Math.round(((tong - sau) / tong) * 100) : 0
				})
				return haoHut
			},
	
			// Cột định lượng hiện tại cho modal định lượng
			cotDinhLuongHienTai() {
				return this.cotDinhLuong.map(x => x.dinhLuong)
			},
	
			// Tỉnh tỉ lệ = giá bán / tổng chi phí
			tiLeSoVoiChiPhiAuto() {
				const giaBan = parseFloat(this.ChiTietNguyenLieu.GiaBan) || 0
				const tongChiPhi = this.tongChiPhiTheoCot['DinhLuongMotPhan'] || 0
	
				if (tongChiPhi > 0 && giaBan > 0) {
					return ((giaBan / tongChiPhi) * 100).toFixed(0)
				}
				return 0
			}
		},
	
		methods: {
			// Lấy chi tiết nguyên liệu (công thức)
			onLoadChiTietNguyenLieu(HangHoa_Id) {
				apiCall("/work/MT_NguyenLieu_Select_By_Id", { HangHoa_Id }, (res) => {
					const info = res.data?.[0]?.[0] || {}
	
					const isTamKhoaCongThuc = !!this.ChiTietNguyenLieu?.Is_TamKhoa
					const ghiChuCongThuc = this.ChiTietNguyenLieu?.GhiChu || ''
	
					this.ChiTietNguyenLieu = {
						...this.ChiTietNguyenLieu,
						...info,
						GhiChu: ghiChuCongThuc,
						Is_TamKhoa: isTamKhoaCongThuc,
					}
				})
	
	
			},
	
			// Cập nhật cột định lượng
			onDinhLuongChange(row) {
				const base = parseFloat(row.DinhLuongMotPhan) || 0
				const gia = parseFloat(row.GiaNguyenVatLieu) || 0
	
				// Cập nhật tất cả cột định lượng khác
				this.cotDinhLuong.forEach((c) => {
					if (c.key !== 'DinhLuongMotPhan') {
						row[c.key] = base * c.dinhLuong
					}
				})
	
				// Cập nhật chi phí sử dụng
				if (row.Is_TinhDinhLuong) {
					row.ChiPhiSuDung = base * gia
				} else {
					row.ChiPhiSuDung = 0
				}
			},
	
			// Binding dữ liệu từ nguyên liệu sang chi tiết thành phần NL cấu thành nên món
			onSelectNguyenLieuRow(HangHoa_Id, currentRow) {
				if (!HangHoa_Id) return
	
				apiCall(
					"/work/MT_NguyenLieu_Select_By_Id",
					{ HangHoa_Id: HangHoa_Id },
					(res) => {
						const info = res.data?.[0][0]
						const donViList = res.data?.[1] || []
						console.log('info: ', info)
						console.log('donViList: ', donViList)
						if (!info) return
	
						// CẬP NHẬT THÔNG TIN CƠ BẢN
						currentRow.HangHoa_Id = HangHoa_Id
						currentRow.MaNoiBo = info.MaNoiBo || ''
						currentRow.TenHangHoa = info.TenHangHoa || ''
	
						// Để check xem dùng đơn vị quy đổi hay đơn vị gốc
	
						// Lưu danh sách đơn vị để hiển thị trong autocomplete
						currentRow.DonViQuyDoiOptions = donViList.map((x) => ({
							QuyDoi_DonViTinh_Id: x.QuyDoi_DonViTinh_Id,
							QuyDoi_DonViTinh_Ten: x.QuyDoi_DonViTinh_Ten
						}))
	
						currentRow.DonViGocOptions = [{
							DonViTinh_Id: info.DonViTinhPhieuNhap_Id,
							TenDonVi: info.TenDonVi
						}]
	
						currentRow.DonViCheck = currentRow.DonViQuyDoiOptions.length > 0
	
						// console.log('currentRow.DonViQuyDoiOptions: ', currentRow.DonViQuyDoiOptions)
						// console.log('currentRow.DonViGocOptions: ', currentRow.DonViGocOptions)
	
						// Set giá trị mặc định là đơn vị đầu tiên hoặc đơn vị gốc
						currentRow.DonVi = donViList[0]?.QuyDoi_DonViTinh_Id ?? info.DonViTinh_Id
	
						currentRow.GiaNguyenVatLieu = 'Lưu công thức để tính giá NVL'
	
						// TỰ ĐỘNG TÍNH CHI PHÍ
						this.onDinhLuongChange(currentRow)
					}
				)
			},
	
			// Lấy danh sách địa điểm sản xuất/sử dụng
			onLoadDiaDiemSanXuat() {
				apiCall(
					"/work/HH_DiaDiem_Select",
					null,
					(res) => {
						this.DsDiaDiemSanXuat = res.data
						this.DsDiaDiemSuDung = res.data
					}
				)
			},
	
			// Lấy danh sách khu vực chế biến
			onLoadKhuVucCheBien() {
				apiCall(
					"/work/HH_KhuVuc_Select",
					null,
					(res) => {
						this.DsKhuVucCheBien = res.data
					}
				)
			},
	
			// ROW KEY
			rowKey(row, i) {
				return 'row-' + (row.HangHoa_Id || 'new') + '-' + row.STT + '-' + i
			},
	
			// GROUP ROWSPAN (Tạm không sử dụng)
			isFirstOfGroup(i) {
				return this.rowSpanMap[i] != null
			},
			rowSpanForGroup(i) {
				return this.rowSpanMap[i] || 1
			},
	
			// key cho field định lượng trong row
			makeKey(dinhLuong) {
				if (dinhLuong === 1) return "DinhLuongMotPhan"
				return `DinhLuong${String(dinhLuong).replace(".", "_")}`
			},
	
			// key cho JSON Sau khi nấu
			jsonKey(dinhLuong) {
				return `DinhLuong${String(dinhLuong).replace(".", "_")}`
			},
	
			// Method mới để xử lý cả thêm và xóa cột
			capNhatCotDinhLuong(data) {
				const { added, removed } = data
	
				// Xóa các cột bị removed
				removed.forEach(dinhLuong => {
					this.xoaCotDinhLuong(dinhLuong)
				})
	
				// Thêm các cột mới
				if (added.length > 0) {
					this.themCotDinhLuong(added)
				}
	
				if (removed.length > 0) {
					showToast.success(`Đã xóa ${removed.length} cột!`)
				}
			},
	
			// Thêm cột định lượng
			themCotDinhLuong(dinhLuongList) {
				if (!dinhLuongList || !dinhLuongList.length) return
	
				const list = [...new Set(dinhLuongList)].sort((a, b) => a - b)
	
				list.forEach((dinhLuong) => {
					if (this.cotDinhLuong.some((x) => x.dinhLuong === dinhLuong)) return
	
					const key = this.makeKey(dinhLuong)
	
					this.cotDinhLuong.push({
						dinhLuong,
						key,
						title: `ĐL ${dinhLuong} phần`,
						width: 100,
					})
	
					this.DsChiTieTCongThuc.forEach((r) => {
						const base = parseFloat(r.DinhLuongMotPhan) || 0
						r[key] = base * dinhLuong
					})
	
					const kJson = this.jsonKey(dinhLuong)
					if (this.sauKhiNauJson[kJson] === undefined) this.sauKhiNauJson[kJson] = 0
				})
	
				if (dinhLuongList.length > 0) {
					showToast.success(`Đã thêm ${dinhLuongList.length} cột!`)
				}
			},
	
			// Xóa cột định lượng
			xoaCotDinhLuong(dinhLuong) {
				if (dinhLuong === 1) return
	
				const key = this.makeKey(dinhLuong)
				this.cotDinhLuong = this.cotDinhLuong.filter((x) => x.dinhLuong !== dinhLuong)
	
				this.DsChiTieTCongThuc.forEach((r) => delete r[key])
	
				const kJson = this.jsonKey(dinhLuong)
				delete this.sauKhiNauJson[kJson]
			},
	
			// LOAD DATA TỪ API
			getData(CongThuc_Id) {
				this.isLoading = true
	
				apiCall(
					"/work/MT_CongThuc_Select_By_Id",
					{
						CongThuc_Id: CongThuc_Id || 5,
					},
					(res) => {
						console.log('Data từ API:', res)
						const rows = res.data || []
						const master = rows?.[0]?.[0]
	
						// 0. LOAD THÔNG TIN NGUYÊN LIỆU (MASTER)
						if (master) {
							this.ChiTietNguyenLieu = { ...master }
							this.diadDiemSanXuatSelect = master.DiaDiemSanXuat_Id
							this.diadDiemSuDungSelect = master.DiaDiemSuDung_Id
							this.khuVucCheBienSelect = master.KhuCheBien_Id
						}
	
						// 1. LOAD DANH SÁCH THÀNH PHẦN (DETAIL)
						this.DsChiTieTCongThuc = rows[1].map((r, idx) => ({
							STT: idx + 1,
							CongThuc_ChiTiet_Id: r.CongThuc_ChiTiet_Id,
							HangHoa_Id: r.HangHoa_Id,
							NguyenVatLieu: r.TenHangHoa,
							TenHangHoa: r.TenHangHoa,
							DonGia_TrungBinh: r.DonGia_TrungBinh,
							DonGia_MoiNhat: r.DonGia_MoiNhat,
							GiaNguyenVatLieu:
								r.QuyDoi_HeSo
									? r.DinhLuong * r.DonGia_ApDung / r.QuyDoi_HeSo
									: 0,
							DinhLuongMotPhan: r.DinhLuong ?? 0,
							DonVi: r.DonViTinh_Id ?? 0,
							TenDonVi: r.TenDonVi ?? 0,
							GhiChu: r.GhiChu ?? '',
							Is_TinhDinhLuong: r.Is_TinhDinhLuong !== false,
	
							// Thông tin để save
							KhuCheBien_Id: r.KhuCheBien_Id,
							DiaDiemSuDung_Id: r.DiaDiemSuDung_Id,
							DiaDiemSanXuat_Id: r.DiaDiemSanXuat_Id,
							Is_TamKhoa: r.Is_TamKhoa || false,
							// TenNhomNguyenLieu: r.TenNhomNguyenLieu,
							...r
						}))
	
						// 2. LOAD CÁC CỘT ĐỊNH LƯỢNG TỪ rows[2]
						const dinhLuongData = rows[2] || []
	
						// Lấy danh sách SoPhan (các cột định lượng)
						const soPhanList = dinhLuongData.map(item => item.SoPhan).filter(Boolean)
	
						// Đảm bảo luôn có cột 1 phần
						if (!soPhanList.includes(1)) {
							soPhanList.unshift(1)
						}
	
						// Sort và tạo cột định lượng
						const list = [...new Set(soPhanList)]
							.sort((a, b) => a - b)
							.map((p) => ({
								dinhLuong: p,
								key: this.makeKey(p),
								title: `ĐL ${p} phần`,
								width: 100,
							}))
	
						this.cotDinhLuong = list
	
						console.log('Các cột định lượng đã load:', list)
	
						// 3. TÍNH CÁC CỘT ĐỊNH LƯỢNG CHO TỪNG DÒNG
						this.DsChiTieTCongThuc.forEach((row) => {
							const base = parseFloat(row.DinhLuongMotPhan) || 0
							const gia = parseFloat(row.GiaNguyenVatLieu) || 0
	
							this.cotDinhLuong.forEach((c) => {
								if (c.key !== 'DinhLuongMotPhan') {
									row[c.key] = base * c.dinhLuong
								}
							})
	
							if (row.Is_TinhDinhLuong) {
								row.ChiPhiSuDung = base * gia
							}
						})
	
						// 4. LOAD DỮ LIỆU "SAU KHI NẤU" TỪ rows[2]
						this.sauKhiNauJson = {}
	
						dinhLuongData.forEach((item) => {
							const k = this.jsonKey(item.SoPhan)
							this.sauKhiNauJson[k] = item.DinhLuong_SauCheBien || 0
						})
	
						// Đảm bảo tất cả các cột đều có giá trị
						this.cotDinhLuong.forEach((c) => {
							const k = this.jsonKey(c.dinhLuong)
							if (this.sauKhiNauJson[k] === undefined) {
								this.sauKhiNauJson[k] = 0
							}
						})
	
						console.log('Dữ liệu sau khi nấu:', this.sauKhiNauJson)
	
						// 5. LOAD ĐƠN VỊ
						this.donViTDL = master?.TenDonVi || 'Gram'
						this.donViSauKhiNau = master?.TenDonVi || 'Gram'
	
						console.log('Đã load xong!', {
							rows: this.DsChiTieTCongThuc.length,
							cols: this.cotDinhLuong.length,
							sauKhiNau: Object.keys(this.sauKhiNauJson).length
						})
	
						this.isLoading = false
					},
					(err) => {
						console.error('Lỗi load data:', err)
						showToast.error('Không thể tải dữ liệu!')
						this.isLoading = false
					}
				)
			},
	
			// THÊM DÒNG MỚI
			themDongMoi() {
				const maxSTT = this.DsChiTieTCongThuc.length > 0
					? Math.max(...this.DsChiTieTCongThuc.map(r => r.STT))
					: 0
	
				const newRow = {
					STT: maxSTT + 1,
					HangHoa_Id: null,
					NguyenVatLieu: '',
					MaNoiBo: '',
					TenHangHoa: '',
					DonVi: '',
					GiaNguyenVatLieu: 0,
					DinhLuongMotPhan: 0,
					Is_TinhDinhLuong: true,
					GhiChu: '',
					NhomThanhPhan: '',
					ChiPhiSuDung: 0,
				}
	
				// Thêm các cột định lượng
				this.cotDinhLuong.forEach((c) => {
					if (c.key !== 'DinhLuongMotPhan') {
						newRow[c.key] = 0
					}
				})
	
				this.editingRow = newRow.STT
	
				this.DsChiTieTCongThuc.push(newRow)
				showToast.success('Đã thêm dòng mới!')
			},
	
			// XÓA DÒNG
			xoaThanhPhan(row, index) {
				console.log(this.DsChiTieTCongThuc)
				if (row.TenHangHoa) {
					showConfirm(
						`Bạn chắc chắn muốn xóa ${row.TenHangHoa || 'dòng này'}?`,
						() => {
	
							this.DsChiTieTCongThuc.splice(index, 1)
							this.resetSTT(this.DsChiTieTCongThuc)
							console.log(this.DsChiTieTCongThuc)
							showToast.success('Đã xóa! Nhấn "Lưu thông tin" để cập nhật.')
						}
					)
				} else {
					this.DsChiTieTCongThuc.splice(index, 1)
					this.resetSTT(this.DsChiTieTCongThuc)
					console.log(this.DsChiTieTCongThuc)
					showToast.success('Đã xóa! Nhấn "Lưu thông tin" để cập nhật.')
				}
			},
	
			// LƯU TẤT CẢ
			saveAll() {
				if (!this.ChiTietNguyenLieu.HangHoa_Id) {
					showToast.error('Vui lòng chọn sản phẩm để tạo công thức!', {
						position: 'top',
					})
					return
				}
				if (!this.diadDiemSanXuatSelect) {
					showToast.error('Vui lòng chọn địa điểm sản xuất!', {
						position: 'top',
					})
					return
				}
				if (!this.khuVucCheBienSelect) {
					showToast.error('Vui lòng chọn khu vực chế biến!', {
						position: 'top',
					})
					return
				}
				if (!this.diadDiemSuDungSelect) {
					showToast.error('Vui lòng chọn địa điểm sử dụng!', {
						position: 'top',
					})
					return
				}
	
				// Validate
				const invalid = this.DsChiTieTCongThuc.filter(r => !r.HangHoa_Id)
				if (invalid.length > 0) {
					showToast.error(`Có ${invalid.length} dòng chưa chọn nguyên liệu!`)
					return
				}
	
				// BUILD JSON_DinhLuong
				const result = []
	
				for (const c of this.cotDinhLuong) {
					const tong = parseFloat(this.tongTheoCot[c.key]) || 0
					const sau = parseFloat(this.sauKhiNauJson[this.jsonKey(c.dinhLuong)]) || 0
	
					if (tong > 0 && sau > tong) {
						showToast.error(`Giá trị "Sau khi nấu" không hợp lệ ở cột ${c.dinhLuong} phần!`)
						return
					}
	
					result.push({
						SoPhan: c.dinhLuong,
						DinhLuong_SauCheBien: sau
					})
				}
	
				const JSON_DinhLuong = result
	
				console.log('Lưu sau khi nấu:', JSON.stringify(JSON_DinhLuong))
				this.isDisabledSauKhiNau = true
	
				// BUilD JSON_CongThuc
				const JSON_CongThuc = this.DsChiTieTCongThuc.map(r => ({
					HangHoa_Id: r.HangHoa_Id,
					DinhLuong: r.DinhLuongMotPhan,
					DonViTinh_Id: r.DonVi,
					GhiChu: r.GhiChu,
					Is_TinhDinhLuong: r.Is_TinhDinhLuong,
				}))
	
	
				// Log JSON_CongThuc (object)
				console.log('JSON_CongThuc (object):', JSON_CongThuc)
	
				// Log JSON_CongThuc (string gửi API)
				console.log('JSON_CongThuc (string):', JSON.stringify(JSON_CongThuc))
	
				// BUILD payload
				const payload = {
					HangHoa_Id: this.ChiTietNguyenLieu.HangHoa_Id,
					KhuCheBien_Id: this.khuVucCheBienSelect,
					DiaDiemSuDung_Id: this.diadDiemSuDungSelect,
					DiaDiemSanXuat_Id: this.diadDiemSanXuatSelect,
					GhiChu: this.ChiTietNguyenLieu.GhiChu,
					Is_TamKhoa: !!this.ChiTietNguyenLieu.Is_TamKhoa,
					JSON_CongThuc: JSON.stringify(JSON_CongThuc),
					JSON_DinhLuong: JSON.stringify(JSON_DinhLuong),
	
				}
	
				// Log full payload
				console.log('API Payload:', payload)
	
				apiCall('/work/MT_CongThuc_Insert', payload, (res) => {
					showToast.success('Lưu công thức thành công!')
					// this.getData()
				})
			},
	
			editAll() {
				if (!this.diadDiemSanXuatSelect) {
					showToast.error('Vui lòng chọn địa điểm sản xuất!', {
						position: 'top',
					})
					return
				}
				if (!this.khuVucCheBienSelect) {
					showToast.error('Vui lòng chọn khu vực chế biến!', {
						position: 'top',
					})
					return
				}
				if (!this.diadDiemSuDungSelect) {
					showToast.error('Vui lòng chọn địa điểm sử dụng!', {
						position: 'top',
					})
					return
				}
	
				// Validate
				const invalid = this.DsChiTieTCongThuc.filter(r => !r.HangHoa_Id)
				if (invalid.length > 0) {
					showToast.error(`Có ${invalid.length} dòng chưa chọn nguyên liệu!`)
					return
				}
	
				// BUILD JSON_DinhLuong
				const result = []
	
				for (const c of this.cotDinhLuong) {
					const tong = parseFloat(this.tongTheoCot[c.key]) || 0
					const sau = parseFloat(this.sauKhiNauJson[this.jsonKey(c.dinhLuong)]) || 0
	
					if (tong > 0 && sau > tong) {
						showToast.error(`Giá trị "Sau khi nấu" không hợp lệ ở cột ${c.dinhLuong} phần!`)
						return
					}
	
					result.push({
						SoPhan: c.dinhLuong,
						DinhLuong_SauCheBien: sau
					})
				}
	
				const JSON_DinhLuong = result
	
				console.log('Lưu sau khi nấu:', JSON.stringify(JSON_DinhLuong))
				this.isDisabledSauKhiNau = true
	
				// BUilD JSON_CongThuc
				const JSON_CongThuc = this.DsChiTieTCongThuc.map(r => ({
					CongThuc_ChiTiet_Id: r.CongThuc_ChiTiet_Id ?? 0,
					HangHoa_Id: r.HangHoa_Id,
					DinhLuong: r.DinhLuongMotPhan,
					DonViTinh_Id: r.DonVi,
					GhiChu: r.GhiChu,
					Is_TinhDinhLuong: r.Is_TinhDinhLuong,
				}))
	
	
				// Log JSON_CongThuc (object)
				console.log('JSON_CongThuc (object):', JSON_CongThuc)
	
				// Log JSON_CongThuc (string gửi API)
				console.log('JSON_CongThuc (string):', JSON.stringify(JSON_CongThuc))
	
				// BUILD payload
				const payload = {
					CongThuc_Id: Number(vueData.CongThuc_Id),
					HangHoa_Id: this.ChiTietNguyenLieu.HangHoa_Id,
					KhuCheBien_Id: this.khuVucCheBienSelect,
					DiaDiemSuDung_Id: this.diadDiemSuDungSelect,
					DiaDiemSanXuat_Id: this.diadDiemSanXuatSelect,
					GhiChu: this.ChiTietNguyenLieu.GhiChu,
					Is_TamKhoa: Number(!!this.ChiTietNguyenLieu.Is_TamKhoa),
					JSON_CongThuc: JSON.stringify(JSON_CongThuc),
					JSON_DinhLuong: JSON.stringify(JSON_DinhLuong),
	
				}
	
				// Log full payload
				console.log('API Payload:', payload)
	
				apiCall('/work/MT_CongThuc_Update', payload, (res) => {
					showToast.success('Cập nhật công thức thành công!')
					if (vueData.CongThuc_Id) {
						this.getData(vueData.CongThuc_Id)
						this.editingRow = null
					}
				})
	
	
			},
	
			editRow(row) {
				this.editingRow = row.STT
				// Gọi lại để load đơn vị options
				if (row.HangHoa_Id) {
					this.onSelectNguyenLieuRow(row.HangHoa_Id, row)
				}
			},
	
			saveRow(row) {
				if (!row.HangHoa_Id) {
					showToast.error('Vui lòng chọn nguyên liệu!')
					return
				}
				this.editingRow = null
				showToast.success('Chọn "Lưu thông tin" để cập nhật!')
			},
	
			// SAU KHI NẤU
			editSauKhiNau() {
				this.isDisabledSauKhiNau = false
			},
	
			saveSauKhiNau() {
				for (const c of this.cotDinhLuong) {
					const tong = parseFloat(this.tongTheoCot[c.key]) || 0
					const sau = parseFloat(this.sauKhiNauJson[this.jsonKey(c.dinhLuong)]) || 0
					if (tong > 0 && sau > tong) {
						showToast.error(`Giá trị "Sau khi nấu" không hợp lệ ở cột ${c.dinhLuong} phần!`)
						return
					}
				}
	
				console.log('Lưu sau khi nấu:', JSON.stringify(this.sauKhiNauJson))
				showToast.success('Chọn "Lưu thông tin" để cập nhật!')
				this.isDisabledSauKhiNau = true
			},
	
			// GHI CHÚ
			editGhiChu(row, key) {
				this.editingGhiChuCell = {
					rowId: row.STT,
					key: key
				}
			},
	
			saveGhiChu(row) {
				showToast.success('Chọn "Lưu tất cả" để cập nhật!')
				this.editingGhiChuCell = null
			},
	
			cancelGhiChu(row) {
				this.editingGhiChuCell = null
			},
	
			// MODAL
			openEdit(row) {
				this.isShowModalEdit = true
				this.detailRecord = { ...row }
			},
	
			showModalQuyDoi() {
				this.isShowModalQuyDoi = true
			},
	
			showModalThemCot() {
				this.isShowModalThemDinhLuong = true
			},
	
			reloadData() {
				this.getData()
			},
	
			updateDonVi(donVi) {
				this.donViTDL = donVi
				this.donViSauKhiNau = donVi
			},
	
			// EXPORT
			exportExcel() {
				if (typeof exportCongThucCheBienExcel === 'undefined') {
					showToast.error('Chức năng export chưa được cài đặt!')
					return
				}
	
				const detailRowsSorted = this.filteredRecipes
					.slice()
					.sort((x, y) =>
						String(x.TenNhomNguyenLieu || "").localeCompare(String(y.TenNhomNguyenLieu || ""), "vi")
					)
	
				exportCongThucCheBienExcel({
					company: "CÔNG TY TNHH MTV THƯƠNG MẠI DỊCH VỤ TÔ MINH",
					chiNhanh: this.diadDiemSanXuatSelect ?? this.diadDiemSuDungSelect,
					khuVuc: this.khuVucCheBienSelect,
					tenMon: vueData.TenHangHoa,
					detailRows: detailRowsSorted,
					cotDinhLuong: this.cotDinhLuong,
					donViTDL: this.donViTDL,
					donViSauKhiNau: this.donViSauKhiNau,
					DinhLuongCol_Json: this.sauKhiNauJson,
					hanSuDung: this.ChiTietNguyenLieu.HanSuDung_Gio,
					baoQuan: this.cachThucBaoQuan,
					thietBiBaoQuan: this.ChiTietNguyenLieu.BaoQuan_ThietBi,
					fileName: `DanhSachChiTietCongThuc_${vueData.TenHangHoa}.xlsx`,
				})
			},
	
			// UTILS
			formatPercent(current, total) {
				if (!total) return 0
				return Math.round((current / total) * 100)
			},
	
			resetSTT(rows) {
				rows.forEach((r, i) => {
					r.STT = i + 1
				})
				return rows
			},
	
			parseMoney(val) {
				const n = Number(String(val ?? '').replace(/\D/g, ''))
				return Number.isFinite(n) ? n : 0
			},
	
			formatMoney(val) {
				const n = this.parseMoney(val)
				return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, '.')
			},
		},
	}
</script>