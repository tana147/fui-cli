<template>
	<v-dialog v-model="modelValue" fullscreen persistent>
		<v-sheet>
			<v-toolbar class="bg-primary">
				<v-toolbar-title v-if="!isEditPage" class="ml-2">Công thức mới </v-toolbar-title>
				<v-toolbar-title v-else class="ml-2"> Công thức {{ vueData.MaNoiBo + ' - ' + vueData.TenHangHoa
				}}</v-toolbar-title>

				<v-toolbar-items>
					<v-btn icon="mdi-close" variant="text" @click="onClose()"></v-btn>
				</v-toolbar-items>
			</v-toolbar>

			<div class="px-2 py-1 recipe-detail-shell">
				<div class="recipe-header-compact">
					<div class="recipe-form-grid">
						<div class="recipe-form-item recipe-form-item--base">
							<v-autocomplete v-model="diadDiemSanXuatSelect" :items="DsDiaDiemSanXuat"
								item-title="TenDiaDiem" item-value="DiaDiem_Id" label="* Chọn địa điểm sản xuất"
								variant="outlined" density="compact" />
						</div>

						<div class="recipe-form-item recipe-form-item--base">
							<v-autocomplete v-model="khuVucCheBienSelect" item-title="TenKhuVuc" item-value="KhuVuc_Id"
								:items="filteredDsKhuVucCheBien" label="* Chọn khu vực chế biến"
								:disabled="!diadDiemSanXuatSelect" variant="outlined" density="compact" />
						</div>

						<div class="recipe-form-item recipe-form-item--base">
							<v-autocomplete v-model="diadDiemSuDungSelect" :items="DsDiaDiemSuDung"
								item-title="TenDiaDiem" item-value="DiaDiem_Id" label="* Chọn địa điểm sử dụng"
								variant="outlined" density="compact" />
						</div>

						<div class="recipe-form-item recipe-form-item--unit">
							<v-autocomplete v-model="donViTinhDLSelect" :items="DsDonViTinh" item-title="TenDonVi"
								item-value="DonViTinh_Id" label="* Chọn đơn vị ĐL" variant="outlined"
								density="compact" />
						</div>

						<div class="recipe-form-item recipe-form-item--note">
							<v-text-field v-model="ChiTietCongThuc.GhiChu" label="Ghi chú" density="compact"
								variant="outlined" />
						</div>

						<div class="recipe-form-item recipe-form-item--lock d-flex align-center">
							<v-checkbox v-model="ChiTietCongThuc.Is_TamKhoa" label="Tạm khóa" color="primary"
								hide-details density="compact" class="chk-center" />
						</div>
					</div>

					<div class="recipe-meta-grid">
						<div class="recipe-meta-main">
							<uc-search-nguyen-lieu v-model="ChiTietCongThuc.HangHoa_Id" :initValue="ChiTietCongThuc.HangHoa_Id ? {
								title: ChiTietCongThuc.MaNoiBo + ' - ' + ChiTietCongThuc.TenHangHoa,
								value: ChiTietCongThuc.HangHoa_Id
							} : null" isClearable placeholder="Nhập mã hoặc tên nguyên liệu *" loaiNguyenLieu="TP,BTP" isHideDetail
								density="compact" label="* Tìm kiếm nguyên liệu" />
						</div>

						<div class="recipe-meta-status">
							<v-autocomplete v-model="trangThaiSelect" label="Trạng thái" :items="statusOptions"
								density="compact" hide-details="auto" clearable variant="outlined" item-title="title"
								item-value="value" />
						</div>

						<div class="recipe-meta-stats">
							<div class="recipe-stat-card recipe-stat-card--compact">
								<div class="recipe-stat-label">Phân loại</div>
								<div class="recipe-stat-value">{{ ChiTietCongThuc.TenLoaiNguyenLieu || '-' }}</div>
							</div>

							<div class="recipe-stat-card recipe-stat-card--compact">
								<div class="recipe-stat-label">Đơn vị nhập</div>
								<div class="recipe-stat-value">{{ ChiTietCongThuc.TenDonVi || '-' }}</div>
							</div>

							<div class="recipe-stat-card recipe-stat-card--compact">
								<div class="recipe-stat-label">Giá nhập</div>
								<div class="recipe-stat-value">
									{{ ChiTietCongThuc.DonGia_ApDung?.toLocaleString('vi-VN') || '0' }}
								</div>
							</div>

							<div class="recipe-stat-card recipe-stat-card--compact">
								<div class="recipe-stat-label">Giá bán</div>
								<div class="recipe-stat-value">
									{{ ChiTietCongThuc.GiaBan?.toLocaleString('vi-VN') || '0' }}
								</div>
							</div>

							<div class="recipe-stat-card recipe-stat-card--compact recipe-stat-card--accent">
								<div class="recipe-stat-label">Tỉ lệ so với CP</div>
								<div class="recipe-stat-value">{{ tiLeSoVoiChiPhiAuto || 0 }}%</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<v-toolbar class="pl-2 border-t recipe-section-toolbar">
				<v-sheet>
					<v-toolbar-title class="text-primary text-subtitle-1">
						<b>Công thức chế biến</b>
						<v-chip size="small" variant="tonal" color="primary">
							SL: {{ filteredRecipes.length }}
						</v-chip>
					</v-toolbar-title>
				</v-sheet>

				<v-spacer />

				<v-btn v-if="isEditPage" color="green" variant="text" @click="onExportBangCongThucExcel"
					class="recipe-toolbar-btn">
					<v-icon :size="24">mdi-file-excel-outline</v-icon>
					<span>Xuất excel công thức</span>
				</v-btn>

				<v-btn v-if="isEditPage" color="green" variant="text" @click="onExportBangChiPhiExcel"
					class="recipe-toolbar-btn">
					<v-icon :size="24">mdi-file-excel-outline</v-icon>
					<span>Xuất excel chi phí</span>
				</v-btn>

				<v-btn v-if="!isEditPage" color="green" variant="text" @click="onShowImportModal"
					class="recipe-toolbar-btn">
					<v-icon :size="24">mdi-file-excel-outline</v-icon>
					<span>Nhập Excel</span>
				</v-btn>
			</v-toolbar>

			<v-divider />

			<div class="recipe-table-wrap">
				<v-table fixed-header height="calc(100vh - 303px)" density="compact" :hover="true"
					class="pa-2 fixed-table sticky-footer-table recipe-table">
					<thead>
						<tr>
							<th v-for="c in tatCaCot" :key="c.key" :class="c.align ? 'text-' + c.align : ''"
								:style="'width: ' + c.width + 'px; min-width: ' + c.width + 'px'">
								<div v-if="c.key === 'DinhLuongMotPhan'" class="d-flex align-center justify-end">
									{{ c.title }}
									<v-btn icon="mdi-flask-plus" size="32" variant="outlined" color="primary"
										@click="onShowModalThemCot" class="ml-2">
										<v-icon size="16">mdi-flask-plus</v-icon>
									</v-btn>
								</div>

								<template v-else-if="c.key === 'GhiChu'">
									<div class="d-flex align-center ga-1">
										<span>{{ c.title }}</span>

										<v-tooltip interactive>
											<template #activator="{ props }">
												<v-icon v-bind="props" size="x-small" icon="mdi-information-outline"
													class="align-self-center" />
											</template>
											Nhấn để cập nhật ghi chú!
										</v-tooltip>
									</div>
								</template>

								<span v-else>{{ c.title }}</span>
							</th>
						</tr>
					</thead>

					<tbody>
						<tr v-if="!filteredRecipes || filteredRecipes.length === 0">
							<td :colspan="tatCaCot.length" class="text-center py-4 text-grey">
								Không tìm thấy dữ liệu
							</td>
						</tr>

						<tr v-for="(row, i) in filteredRecipes" :key="toRowKey(row, i)"
							:style="isDuplicateHangHoa(row) ? 'background:#ffe5e5' : ''">
							<td class="text-center">{{ i + 1 }}</td>

							<td v-for="c in colsBody" :key="c.key" :class="c.align ? 'text-' + c.align : ''">
								<div v-if="c.key === 'DinhLuongMotPhan'"
									class="d-flex justify-end recipe-clickable-cell">
									<!-- Chế độ edit hoặc đang edit dòng này -->
									<v-text-field v-if="(!isEditPage && !isImportMode) || editingRow === row.STT"
										:model-value="formatNumber(row[c.key])" density="compact" hide-details
										type="text" variant="underlined" style="max-width: 100px" class="number-field"
										@update:modelValue="(val) => onNumberCommaInput(val, row, c.key)"
										@keyup.enter="onSaveRow(row)" @keydown="onBlockDot" />
									<!-- Chế độ xem (chưa edit) -->
									<div v-else @click="onEditRow(row)" class="recipe-clickable-cell">
										{{ formatNumberDisplay(row[c.key]) }}
									</div>
								</div>

								<template v-else-if="c.isCotDinhLuong && c.key !== 'DinhLuongMotPhan'">
									<div class="text-right">
										{{ formatNumberDisplay(row[c.key]) }}
									</div>
								</template>

								<template v-else-if="c.key === 'NguyenVatLieu'">
									<div>
										<div class="d-flex align-center ga-2">
											<uc-row-nguyen-lieu :row-data="row" :key="row.STT"
												:is-editing="(!isEditPage && !isImportMode) || editingRow === row.STT"
												@update-row="(data) => onUpdateRowNguyenLieu(data, row)"
												@edit-row="onEditRow(row)" />
										</div>

										<!-- Hiển thị ghi chú dưới tên NVL -->
										<div v-if="(!isEditPage && !isImportMode) || editingRow === row.STT"
											class="text-caption text-grey mt-1"
											style="line-height: 1.3; max-width: 250px; word-break: break-word;">
											{{ row.TenThayTheUpdate }}
										</div>

										<div v-else class="text-caption text-grey mt-1"
											style="line-height: 1.3; max-width: 250px; word-break: break-word;">
											{{ row.TenThayThe }}
										</div>
									</div>
								</template>

								<template v-else-if="c.key === 'GiaNguyenVatLieu'">
									<div class="text-right">
										<!-- Trạng thái 1: Có giá trị số hợp lệ > 0 (đã load từ DB) -->
										<span v-if="typeof row[c.key] === 'number' && row[c.key] > 0">
											{{ row[c.key].toLocaleString('vi-VN') }}
										</span>

										<!-- Trạng thái 2: Giá trị = 0 (có đơn vị nhưng không có hệ số quy đổi) -->
										<v-tooltip v-else-if="typeof row[c.key] === 'number' && row[c.key] === 0"
											interactive>
											<template v-slot:activator="{ props: activatorProps }">
												<v-icon size="x-small" icon="mdi-information-outline"
													v-bind="activatorProps">
												</v-icon>
											</template>
											Chưa có đầy đủ thông tin!
										</v-tooltip>

										<!-- Trạng thái 3: String hoặc chưa tính (mới thêm dòng) -->
										<span v-else class="text-grey text-caption">
											{{ row[c.key] || '' }}
										</span>
									</div>
								</template>

								<div v-else-if="c.key === 'DonVi'" class="d-flex justify-center">
									<template v-if="(!isEditPage && !isImportMode) || editingRow === row.STT">
										<v-autocomplete v-if="row.DonViCheck" :model-value="row.DonVi"
											@update:modelValue="(val) => onChangeDonVi(val, row)"
											:items="row.DonViQuyDoiOptions" item-title="QuyDoi_DonViTinh_Ten"
											item-value="QuyDoi_DonViTinh_Id" style="max-width: 90px"
											variant="underlined" />

										<div v-else class="d-flex align-center justify-center" style="width: 90px">
											<v-autocomplete :model-value="row.DonVi"
												@update:modelValue="(val) => onChangeDonViGoc(val, row)"
												:items="row.DonViGocOptions" item-title="TenDonVi"
												item-value="DonViTinh_Id" style="max-width: 90px"
												variant="underlined" />
											<v-tooltip interactive>
												<template v-slot:activator="{ props: activatorProps }">
													<v-icon size="x-small" icon="mdi-information-outline"
														v-bind="activatorProps">
													</v-icon>
												</template>
												Chưa có đơn vị quy đổi, đang dùng đơn vị nhập!
											</v-tooltip>
										</div>
									</template>

									<div v-else @click="onEditRow(row)" class="recipe-clickable-cell">{{ row.TenDonVi }}
									</div>
								</div>

								<template v-else-if="c.key === 'ChiPhiSuDung'">
									<div class="text-right">
										<span v-if="Number.isNaN(row[c.key])" class="text-grey text-caption">
											<!-- Lưu để tính -->
										</span>
										<span v-else>
											{{ row[c.key].toLocaleString('vi-VN') }}
										</span>
									</div>
								</template>

								<template v-else-if="c.key === 'GhiChu'">
									<div v-if="editingGhiChuCell?.rowId === row.STT && editingGhiChuCell?.key === 'GhiChu'"
										class="mt-2">
										<v-textarea v-model="ghiChuDraft" density="compact" hide-details
											variant="underlined" autofocus @keyup.enter.ctrl="onSaveGhiChu(row)"
											placeholder="Nhập ghi chú..." rows="2" auto-grow :clearable="true" />
										<div class="d-flex ga-1 mt-1 mb-1">
											<v-btn size="small" color="primary" variant="flat"
												@click="onSaveGhiChu(row)" prepend-icon="mdi-content-save">
												Lưu ghi chú
											</v-btn>
											<v-btn size="small" color="grey" variant="flat"
												@click="onCancelGhiChu(row)">
												Hủy
											</v-btn>
										</div>
									</div>
									<div v-else @click="onEditGhiChu(row, c.key)" class="recipe-clickable-cell"
										style="min-height: 20px; overflow-wrap: break-word; word-break: break-word; white-space: normal;">
										<span v-if="row[c.key]">{{ row[c.key] }}</span>
										<span v-else class="text-grey">Nhấn để ghi chú</span>
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
								<v-btn v-if="!((!isEditPage && !isImportMode) || editingRow === row.STT)"
									icon="mdi-square-edit-outline" color="primary" variant="text" size="small"
									@click="onEditRow(row)" />
								<v-btn v-if="editingRow === row.STT && isEditPage" icon="mdi-content-save" color="green"
									variant="text" size="small" @click="onSaveRow(row)" />
								<v-btn icon="mdi-trash-can" color="red" variant="text" size="small"
									@click="deleteThanhPhan(row, i)" />
							</td>
						</tr>

						<tr>
							<td></td>
							<td :colspan="tatCaCot.length - 1" class="py-2">
								<v-btn color="primary" variant="outlined" @click="onAddNewRow" prepend-icon="mdi-plus">
									Thêm nguyên liệu
								</v-btn>
							</td>
						</tr>
					</tbody>

					<!-- TĐL, sau khi nấu, hao hụt -->
					<tfoot>
						<!-- Tổng định lượng -->
						<tr>
							<td></td>
							<td></td>
							<td colspan="2" class="text-right font-weight-bold">Tổng định lượng</td>
							<td class="text-center font-weight-bold">{{ donViTDL }}</td>

							<td v-for="c in cotDinhLuong" :key="'tdl-' + c.key"
								class="text-center font-weight-bold text-primary">
								<!-- <div class="d-flex justify-center align-center"> -->
								<div class="text-right">
									<template v-if="ChiTietCongThuc?.LoaiNguyenLieu === 'TP' && donViTinhDLSelect">
										<v-tooltip location="top">
											<template #activator="{ props }">
												<span v-bind="props">
													{{ formatNumberDisplay(tongDLTheoCotDisplay[c.key]) }}
												</span>
											</template>

											<!-- Tổng nguyên liệu: -->
											{{ formatNumberDisplay(tongDLTheoCot[c.key]) }}
											<!-- {{ donViTDL || '' }} -->
										</v-tooltip>
									</template>

									<template v-else>
										{{ formatNumberDisplay(tongDLTheoCotDisplay[c.key]) }}
									</template>
								</div>
								<!-- </div> -->
							</td>

							<td></td>
							<td></td>
							<td></td>
						</tr>

						<!-- Sau khi nấu -->
						<tr>
							<td></td>
							<td></td>
							<td colspan="2" class="text-right font-weight-bold">Sau khi nấu</td>
							<td class="text-center font-weight-bold">{{ donViSauKhiNau }}</td>

							<td v-for="c in cotDinhLuong" :key="'sau-' + c.key">
								<!-- Chế độ edit: cho phép nhập -->
								<div v-if="!isDisabledSauKhiNau" class="d-flex justify-end">
									<v-text-field
										:model-value="formatNumber(sauKhiNauJson[toDinhLuongJsonKey(c.dinhLuong)])"
										density="compact" hide-details type="text" inputmode="numeric"
										variant="underlined" style="max-width: 100px" class="number-field"
										@update:modelValue="(val) => onSauKhiNauInput(val, c.dinhLuong)"
										@keydown="onBlockDot" @keyup.enter="onSaveSauKhiNau()" autofocus="" />
								</div>
								<!-- Chế độ xem: chỉ hiển thị -->
								<div v-else class="text-right">
									{{
										formatNumberDisplay(sauKhiNauJson[toDinhLuongJsonKey(c.dinhLuong)])
									}}
								</div>
							</td>

							<td></td>
							<td></td>
							<td class="text-center">
								<v-btn v-if="!isDisabledSauKhiNau && isEditPage" icon="mdi-content-save" variant="text"
									size="small" @click="onSaveSauKhiNau" color="green" />
								<v-btn v-else icon="mdi-square-edit-outline" variant="text" size="small"
									@click="onEditSauKhiNau" color="primary" />
							</td>
						</tr>

						<!-- Hao hụt -->
						<tr>
							<td></td>
							<td></td>
							<td colspan="2" class="text-right font-weight-bold">Hao hụt</td>
							<td class="text-center font-weight-bold">{{ donViHaoHut }}</td>

							<td v-for="c in cotDinhLuong" :key="'hao-' + c.key"
								class="text-center text-red font-weight-bold">
								<div class="text-right">
									{{ haoHutTheoCot[c.key] }}
								</div>
							</td>

							<td></td>
							<td></td>
							<td></td>
						</tr>

						<!-- Tổng chi phí -->
						<tr>
							<td></td>
							<td></td>
							<td colspan="2" class="text-right font-weight-bold">Tổng chi phí</td>
							<td class="text-center font-weight-bold">VNĐ</td>

							<td v-for="c in cotDinhLuong" :key="'cost-' + c.key"
								class="text-center font-weight-bold text-green">
								<div class="text-right">
									{{ tongChiPhiTheoCot[c.key].toLocaleString('vi-VN') }}
								</div>
							</td>

							<td class="text-center font-weight-bold text-green">
								<div class="text-right">
									{{ tongChiPhi.toLocaleString('vi-VN') }}
								</div>
							</td>
							<td></td>
							<td></td>
						</tr>
					</tfoot>
				</v-table>
			</div>

			<v-toolbar class="recipe-bottom-toolbar">
				<v-spacer />
				<!-- Lưu và tiếp tục -->
				<v-btn v-if="!isEditPage" color="warning" variant="flat" prepend-icon="mdi-content-save"
					class="mr-2 recipe-bottom-btn" @click="saveAndContinue">
					{{ !isSaveNewRecipe ? 'Lưu và nhập mới' : 'Tiếp tục thêm' }}
				</v-btn>

				<!-- Lưu tất cả -->
				<v-btn v-if="!isEditPage" color="primary" variant="flat" @click="saveAll"
					prepend-icon="mdi-content-save" :disabled="isSaveNewRecipe" text="Lưu công thức" />

				<!-- Cập nhật -->
				<v-btn v-if="isEditPage" color="primary" variant="flat" @click="updateAll"
					prepend-icon="mdi-content-save" text="Cập nhật công thức" />
			</v-toolbar>
		</v-sheet>
	</v-dialog>

	<uc-modal-edit-ghi-chu v-model="isShowModalEdit" @onReloadGhiChu="onReloadData" :detailRecord="detailRecord" />

	<uc-modal-them-dinh-luong v-model="isShowModalThemDinhLuong" :cotDinhLuongHienTai="cotDinhLuongHienTai"
		@onCapNhatCot="updateDinhLuongColumns" @updateAll="updateAll" />

	<uc-modal-import-excel v-model="isShowModalImport" :dsDiaDiemSanXuat="DsDiaDiemSanXuat"
		:dsDiaDiemSuDung="DsDiaDiemSuDung" :dsKhuVucCheBien="DsKhuVucCheBien" :dsDonViTinh="DsDonViTinh"
		@onImportSuccess="onImportSuccess" />
</template>

<script>
export default {
	props: ['modelValue', 'DsDiaDiemSanXuat', 'DsDiaDiemSuDung', 'DsKhuVucCheBien', 'DsDonViTinh', 'statusOptions'],
	emits: ['update:modelValue', 'onReload', 'callData'],

	data() {
		return {
			vueData,
			vueAction,

			// Loading
			isLoading: false,

			// Đơn vị tổng định lượng, sau khi nấu và hao hụt
			donViTDL: '',
			donViTDLCheck: '',
			donViSauKhiNau: '',
			donViHaoHut: "%",

			isDisabledSauKhiNau: true,

			// Thông tin header
			diadDiemSanXuatSelect: null,
			diadDiemSuDungSelect: null,
			khuVucCheBienSelect: null,
			donViTinhDLSelect: null,
			trangThaiSelect: null,

			// Bảo quản
			cachThucBaoQuan: "",

			// TABLE DATA
			ChiTietCongThuc: {
				HangHoa_Id: null,
				EORDER_SanPham_Id: 0,
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

			DsChiTieTCongThuc: [],

			search: "",
			filters: {
				TenHangHoa: null,
			},

			// cột định lượng (luôn có 1 phần)
			cotDinhLuong: [
				{ dinhLuong: 1, key: "DinhLuongMotPhan", title: "ĐL 1 phần", width: 60, align: 'right' },
			],

			sauKhiNauJson: {},

			// Cột cố định
			cotCoDinh: [
				{ title: "#", key: "STT", width: 20, align: "center" },
				{ title: "Nguyên vật liệu", key: "NguyenVatLieu", width: 120 },
				{ title: "Tính ĐL", key: "Is_TinhDinhLuong", width: 40, align: 'center' },
				{ title: "CP/1ĐV sử dụng", key: "GiaNguyenVatLieu", width: 70, align: 'right' },
				{ title: "ĐV sử dụng", key: "DonVi", width: 50, align: "center" },
			],
			colAct: [
				{ title: 'CP sử dụng', key: 'ChiPhiSuDung', width: 50, align: 'right' },
				{ title: "Ghi chú", key: "GhiChu", width: 70 },
				{ title: ``, key: "act", width: 50, align: "center" },
			],

			// MODALS
			isShowModalQuyDoi: false,
			isShowModalEdit: false,
			isShowModalThemDinhLuong: false,
			detailRecord: {},

			isEditPage: false,
			editingRow: null,
			suppressMainProductReset: false,

			editingGhiChuCell: null,
			ghiChuDraft: '',
			ghiChuOriginal: '',

			isShowModalImport: false,
			isImportMode: false,

			isSaveNewRecipe: false,
		}
	},

	mounted() { },

	watch: {
		modelValue(val) {
			if (val) {
				this.$emit("callData")
				if (vueData.CongThuc_Id) {
					this.isEditPage = true
					this.loadData(vueData.CongThuc_Id)
				} else {
					this.onAddNewRow()
				}
			}
		},

		// Lấy chi tiết của công thức chính
		'ChiTietCongThuc.HangHoa_Id'(val, oldVal) {
			const isUserChangingMainProduct = this.isEditPage &&
				!this.suppressMainProductReset &&
				!!oldVal &&
				Number(val) !== Number(oldVal)

			if (isUserChangingMainProduct) {
				this.resetCongThucDetailsForMainProductChange()
			}

			if (val) {
				this.loadChiTietNguyenLieu(val)
			}
		},

		donViTinhDLSelect(dvtVal) {
			if (dvtVal) {
				const donVi = this.DsDonViTinh.find(x => x.DonViTinh_Id === dvtVal)
				const tenDonVi = donVi?.TenDonVi || ''

				this.donViTDL = tenDonVi
				this.donViSauKhiNau = tenDonVi
			}
		}
	},

	computed: {
		// build toàn bộ cột
		tatCaCot() {
			const cotDinhLuongs = this.cotDinhLuong.map((x) => ({
				title: x.title,
				key: x.key,
				width: x.width,
				align: "right",
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
				const a = String(r.DinhLuongMotPhan || "").toLowerCase()
				const b = String(r.TenHangHoa || "").toLowerCase()

				const okSearch = !keyword || a.includes(keyword) || b.includes(keyword)
				return okSearch
			})

			return rows
		},

		// Lọc khu vực chế biến theo select của địa điểm sản xuất
		filteredDsKhuVucCheBien() {
			if (!this.diadDiemSanXuatSelect) return []
			return this.DsKhuVucCheBien.filter((c) => c.DiaDiem_Id === this.diadDiemSanXuatSelect)
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
		tongDLTheoCot() {
			const tong = {}
			this.cotDinhLuong.forEach((c) => {
				tong[c.key] = this.DsChiTieTCongThuc
					.filter(r => r.Is_TinhDinhLuong)
					.reduce((s, r) => s + (parseFloat(r[c.key]) || 0), 0)
			})
			return tong
		},

		// Tổng định lượng HIỂN THỊ ở footer
		tongDLTheoCotDisplay() {
			// Nếu là TP và đã chọn đơn vị định lượng => Tổng định lượng = số phần
			if (this.ChiTietCongThuc?.LoaiNguyenLieu === 'TP' && this.donViTinhDLSelect) {
				const out = {}
				this.cotDinhLuong.forEach(c => {
					out[c.key] = c.dinhLuong // 1 phần -> 1, 2 phần -> 2, 0.5 phần -> 0.5
				})
				return out
			}

			// Mặc định: giữ nguyên tổng định lượng theo nguyên liệu như hiện tại
			return this.tongDLTheoCot
		},

		// Tổng chi phí cột CPSD
		tongChiPhi() {
			return this.DsChiTieTCongThuc
				.reduce((s, r) => {
					const chiPhiDongNay = parseFloat(r.ChiPhiSuDung) || 0
					return s + chiPhiDongNay
				}, 0)
		},

		// Tổng chi phí theo từng cột định lượng
		tongChiPhiTheoCot() {
			const tong = {}
			this.cotDinhLuong.forEach((c) => {
				const tiLe = c.dinhLuong

				tong[c.key] = this.DsChiTieTCongThuc
					.reduce((s, r) => {
						const chiPhi1Phan = parseFloat(r.ChiPhiSuDung) || 0
						return s + (chiPhi1Phan * tiLe)
					}, 0)
			})
			return tong
		},

		// Hao hụt % theo từng cột định lượng
		haoHutTheoCot() {
			const haoHut = {}

			this.cotDinhLuong.forEach((c) => {
				const tong = this.toNumberComma(this.tongDLTheoCot[c.key])
				const sau = this.toNumberComma(
					this.sauKhiNauJson[this.toDinhLuongJsonKey(c.dinhLuong)]
				)

				if (tong > 0 && sau > 0) {
					const percent = ((tong - sau) / tong) * 100
					haoHut[c.key] = percent > 0 ? Math.round(percent) : 0
				} else {
					haoHut[c.key] = 0
				}
			})

			return haoHut
		},

		// Cột định lượng hiện tại cho modal định lượng
		cotDinhLuongHienTai() {
			return this.cotDinhLuong.map(x => x.dinhLuong)
		},

		// Tỉnh tỉ lệ = giá bán / tổng chi phí
		tiLeSoVoiChiPhiAuto() {
			const giaBan = parseFloat(this.ChiTietCongThuc.GiaBan) || 0
			const tongChiPhi = this.tongChiPhiTheoCot['DinhLuongMotPhan'] || 0

			if (tongChiPhi > 0 && giaBan > 0) {
				return ((tongChiPhi / giaBan) * 100).toFixed(0)
			}
			return 0
		}
	},

	methods: {
		toNumber(val) {
			const n = Number(val)
			return Number.isFinite(n) ? n : 0
		},

		toNumberComma(val) {
			const n = Number(String(val ?? '').replace(',', '.'))
			return Number.isFinite(n) ? n : 0
		},

		// Cập nhật giá theo đơn vị đang chọn
		// Nếu DonViCheck = true => lấy heSo từ QuyDoiInfo để chia
		// Nếu DonViCheck = false => đơn vị gốc => giá = DonGia_ApDung
		capNhatGiaTheoDonVi(row) {
			const donGia = this.toNumber(row?.DonGia_ApDung || 0)

			// đơn vị gốc
			if (!row?.DonViCheck) {
				row.GiaNguyenVatLieu = donGia
				return
			}

			// đơn vị quy đổi
			const qd = row?.QuyDoiInfo?.find(x =>
				this.toNumber(x?.QuyDoi_DonViTinh_Id) === this.toNumber(row?.DonVi)
			)

			const heSo = this.toNumber(qd?.QuyDoi_HeSo || 0)
			row.GiaNguyenVatLieu = heSo > 0 ? (donGia / heSo) : 0
		},

		capNhatTenDonViTheoDonVi(row) {
			if (!row) return

			if (row.DonViCheck) {
				const opt = (row.DonViQuyDoiOptions || []).find(x =>
					this.toNumber(x?.QuyDoi_DonViTinh_Id) === this.toNumber(row?.DonVi)
				)
				if (opt?.QuyDoi_DonViTinh_Ten) row.TenDonVi = opt.QuyDoi_DonViTinh_Ten
				return
			}

			const optGoc = (row.DonViGocOptions || []).find(x =>
				this.toNumber(x?.DonViTinh_Id) === this.toNumber(row?.DonVi)
			)
			row.TenDonVi = optGoc?.TenDonVi || row.TenDonVi || ''
		},

		capNhatTenThayTheTheoDonVi(row) {
			if (!row) return

			if (!row.DonViCheck) {
				row.TenThayTheUpdate = ''
				row.TenThayThe = ''
				return
			}

			const qd = row?.QuyDoiInfo?.find(x =>
				this.toNumber(x?.QuyDoi_DonViTinh_Id) === this.toNumber(row?.DonVi)
			)

			const tenTT = qd?.TenThayThe ?? ''
			row.TenThayTheUpdate = tenTT
			row.TenThayThe = tenTT
		},

		// gọi chung sau khi đổi đơn vị / nhận dữ liệu mới
		capNhatRowSauKhiDoiDonVi(row) {
			this.capNhatTenDonViTheoDonVi(row)
			this.capNhatTenThayTheTheoDonVi(row)
			this.capNhatGiaTheoDonVi(row)
			this.onDinhLuongChange(row)
		},

		/* ===============================
		LOAD DATA
		=============================== */
		loadData(CongThuc_Id) {
			this.isLoading = true

			apiCall(
				"/work/MT_CongThuc_Select_By_Id",
				{ CongThuc_Id: CongThuc_Id },
				(res) => {
					const rows = res.data || []
					const master = rows?.[0]?.[0]

					// 0. LOAD THÔNG TIN NGUYÊN LIỆU (MASTER)
					if (master) {
						this.suppressMainProductReset = true
						this.ChiTietCongThuc = { ...master }
						this.diadDiemSanXuatSelect = master.DiaDiemSanXuat_Id
						this.diadDiemSuDungSelect = master.DiaDiemSuDung_Id
						this.khuVucCheBienSelect = master.KhuCheBien_Id
						this.trangThaiSelect = master.TrangThai
						this.donViTinhDLSelect = this.donViTDLCheck = master.DinhLuong_DonViTinh_Id
						this.donViTDL = this.donViSauKhiNau = master.DinhLuong_TenDonViTinh
						this.$nextTick(() => {
							this.suppressMainProductReset = false
						})
					}

					// 1. LOAD DANH SÁCH THÀNH PHẦN (DETAIL)
					this.DsChiTieTCongThuc = (rows[1] || []).map((r, idx) => {
						const row = {
							...r,
							STT: idx + 1,

							CongThuc_ChiTiet_Id: r.CongThuc_ChiTiet_Id,
							HangHoa_Id: r.HangHoa_Id,
							NguyenVatLieu: r.TenHangHoa,

							MaNoiBo: r.MaNoiBo ?? '',
							TenHangHoa: r.TenHangHoa,

							DonGia_TrungBinh: r.DonGia_TrungBinh,
							DonGia_MoiNhat: r.DonGia_MoiNhat,
							DonGia_ApDung: r.DonGia_ApDung ?? 0,

							// giữ nguyên biến cũ
							DinhLuongMotPhan: r.DinhLuong ?? 0,
							DonVi: r.DonViTinh_Id ?? 0,
							TenDonVi: r.TenDonVi ?? '',

							GhiChu: r.GhiChu ?? '',
							Is_TinhDinhLuong: r.Is_TinhDinhLuong !== false,

							// Thông tin để save
							KhuCheBien_Id: r.KhuCheBien_Id,
							DiaDiemSuDung_Id: r.DiaDiemSuDung_Id,
							DiaDiemSanXuat_Id: r.DiaDiemSanXuat_Id,
							Is_TamKhoa: r.Is_TamKhoa || false,

							TenThayThe: r.TenThayThe ?? '',
							TenThayTheUpdate: r.TenThayThe ?? '',

							// các field options có thể được bơm khi row vào edit
							DonViCheck: r.DonViCheck, // nếu API có trả
							DonViQuyDoiOptions: r.DonViQuyDoiOptions ?? [],
							DonViGocOptions: r.DonViGocOptions ?? [],
							QuyDoiInfo: r.QuyDoiInfo ?? []
						}

						// nếu API đã trả GiaNguyenVatLieu thì ưu tiên dùng,
						// không thì fallback theo QuyDoi_HeSo như cũ
						row.GiaNguyenVatLieu = this.toNumber(
							r.GiaNguyenVatLieu ?? (
								r.QuyDoi_HeSo
									? (r.DonGia_ApDung / r.QuyDoi_HeSo)
									: r.DonGia_ApDung
							)
						)

						return row
					})

					// 2. LOAD CÁC CỘT ĐỊNH LƯỢNG TỪ rows[2]
					const dinhLuongData = rows[2] || []
					const soPhanList = dinhLuongData.map(item => item.SoPhan).filter(Boolean)

					if (!soPhanList.includes(1)) soPhanList.unshift(1)

					const list = [...new Set(soPhanList)]
						.sort((a, b) => a - b)
						.map((p) => ({
							dinhLuong: p,
							key: this.toDinhLuongKey(p),
							title: `ĐL ${p} phần`,
							width: 60,
						}))

					this.cotDinhLuong = list

					// 3. TÍNH CÁC CỘT ĐỊNH LƯỢNG CHO TỪNG DÒNG
					this.capNhatDinhLuongVaChiPhiChoTatCaDong()

					// 4. LOAD DỮ LIỆU "SAU KHI NẤU"
					this.sauKhiNauJson = {}
					dinhLuongData.forEach((item) => {
						const k = this.toDinhLuongJsonKey(item.SoPhan)
						this.sauKhiNauJson[k] = item.DinhLuong_SauCheBien || null
					})

					this.cotDinhLuong.forEach((c) => {
						const k = this.toDinhLuongJsonKey(c.dinhLuong)
						if (this.sauKhiNauJson[k] === undefined) {
							this.sauKhiNauJson[k] = 0
						}
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

		/* ===============================
		THÊM DÒNG MỚI / LOAD MASTER
		=============================== */
		loadChiTietNguyenLieu(HangHoa_Id) {
			apiCall("/work/MT_NguyenLieu_Select_By_Id", { HangHoa_Id }, (res) => {
				const info = res.data?.[0]?.[0] || {}

				const isTamKhoaCongThuc = !!this.ChiTietCongThuc?.Is_TamKhoa
				const ghiChuCongThuc = this.ChiTietCongThuc?.GhiChu ?? ''
				const hanSuDung = this.ChiTietCongThuc?.HanSuDung_Gio ?? 0

				this.ChiTietCongThuc = {
					...this.ChiTietCongThuc,
					...info,
					HanSuDung_Gio: hanSuDung,
					GhiChu: ghiChuCongThuc,
					Is_TamKhoa: isTamKhoaCongThuc,
				}
			})
		},

		onReloadData() {
			this.loadData()
		},

		/* ===============================
		SAVE / UPDATE
		=============================== */
		async saveAll() {
			if (!this.ChiTietCongThuc.HangHoa_Id) {
				showToast.error('Vui lòng chọn nguyên liệu để tạo công thức!', { position: 'top' })
				throw new Error('Missing HangHoa_Id')
			}
			if (!this.diadDiemSanXuatSelect) {
				showToast.error('Vui lòng chọn địa điểm sản xuất!', { position: 'top' })
				throw new Error('Missing DiaDiemSanXuat')
			}
			if (!this.khuVucCheBienSelect) {
				showToast.error('Vui lòng chọn khu vực chế biến!', { position: 'top' })
				throw new Error('Missing KhuVucCheBien')
			}
			if (!this.diadDiemSuDungSelect) {
				showToast.error('Vui lòng chọn địa điểm sử dụng!', { position: 'top' })
				throw new Error('Missing DiaDiemSuDung')
			}
			if (!this.donViTinhDLSelect) {
				showToast.error('Vui lòng chọn đơn vị định lượng!', { position: 'top' })
				throw new Error('Missing DonViTinh')
			}

			if (!this.toDonViTinhDinhLuongValid()) return

			const invalid = this.DsChiTieTCongThuc.filter(r =>
				!r.HangHoa_Id ||
				!r.DonVi ||
				this.toNumberComma(r.DinhLuongMotPhan) <= 0
			)
			if (invalid.length > 0) {
				showToast.error(`Có ${invalid.length} dòng chưa đủ thông tin (nguyên liệu/đơn vị/định lượng)!`)
				return
			}

			const result = []
			for (const c of this.cotDinhLuong) {
				const sau = this.toNumberComma(this.sauKhiNauJson[this.toDinhLuongJsonKey(c.dinhLuong)])
				result.push({ SoPhan: c.dinhLuong, DinhLuong_SauCheBien: sau })
			}

			const JSON_DinhLuong = result
			this.isDisabledSauKhiNau = true

			const JSON_CongThuc = this.DsChiTieTCongThuc.map(r => ({
				HangHoa_Id: r.HangHoa_Id,
				DinhLuong: this.toNumberComma(r.DinhLuongMotPhan),
				DonViTinh_Id: r.DonVi,
				GhiChu: r.GhiChu,
				Is_TinhDinhLuong: r.Is_TinhDinhLuong,
			}))

			const payload = {
				HangHoa_Id: this.ChiTietCongThuc.HangHoa_Id,
				KhuCheBien_Id: this.khuVucCheBienSelect,
				DiaDiemSuDung_Id: this.diadDiemSuDungSelect,
				DiaDiemSanXuat_Id: this.diadDiemSanXuatSelect,
				DinhLuong_DonViTinh_Id: this.donViTinhDLSelect,
				TrangThai: this.trangThaiSelect,
				GiaNhap: this.tongChiPhi,
				GhiChu: this.ChiTietCongThuc.GhiChu,
				Is_TamKhoa: !!this.ChiTietCongThuc.Is_TamKhoa,
				Is_DungTenThayThe: false,
				JSON_CongThuc: JSON.stringify(JSON_CongThuc),
				JSON_DinhLuong: JSON.stringify(JSON_DinhLuong),
			}

			this.ChiTietCongThuc.DonGia_ApDung = this.tongChiPhi

			return new Promise((resolve, reject) => {
				apiCall('/work/MT_CongThuc_Insert', payload, (res) => {
					if (!res || res.error || res.isOk === false) {
						showToast.error(res?.message || 'Lưu công thức thất bại!')
						reject(new Error(res?.message || 'API error'))
						return
					}

					this.isSaveNewRecipe = true
					showToast.success('Lưu công thức thành công!')
					this.$emit("onReload")
					resolve(true)
				})
			})
		},

		updateAll() {
			if (!this.diadDiemSanXuatSelect) {
				showToast.error('Vui lòng chọn địa điểm sản xuất!', { position: 'top' })
				return
			}
			if (!this.khuVucCheBienSelect) {
				showToast.error('Vui lòng chọn khu vực chế biến!', { position: 'top' })
				return
			}
			if (!this.diadDiemSuDungSelect) {
				showToast.error('Vui lòng chọn địa điểm sử dụng!', { position: 'top' })
				return
			}
			if (!this.donViTinhDLSelect) {
				showToast.error('Vui lòng chọn đơn vị định lượng!', { position: 'top' })
				return
			}

			if (!this.toDonViTinhDinhLuongValid()) return

			const invalid = this.DsChiTieTCongThuc.filter(r =>
				!r.HangHoa_Id ||
				!r.DonVi ||
				this.toNumberComma(r.DinhLuongMotPhan) <= 0
			)

			if (invalid.length > 0) {
				showToast.error(`Có ${invalid.length} dòng chưa đủ thông tin (nguyên liệu/đơn vị/định lượng)!`)
				return
			}

			const result = []
			for (const c of this.cotDinhLuong) {
				const sau = this.toNumberComma(this.sauKhiNauJson[this.toDinhLuongJsonKey(c.dinhLuong)])
				result.push({ SoPhan: c.dinhLuong, DinhLuong_SauCheBien: sau })
			}

			const JSON_DinhLuong = result
			this.isDisabledSauKhiNau = true

			const JSON_CongThuc = this.DsChiTieTCongThuc.map(r => ({
				CongThuc_ChiTiet_Id: r.CongThuc_ChiTiet_Id ?? 0,
				HangHoa_Id: r.HangHoa_Id,
				DinhLuong: this.toNumberComma(r.DinhLuongMotPhan),
				DonViTinh_Id: r.DonVi,
				GhiChu: r.GhiChu,
				Is_TinhDinhLuong: r.Is_TinhDinhLuong,
			}))

			const payload = {
				CongThuc_Id: Number(vueData.CongThuc_Id),
				HangHoa_Id: this.ChiTietCongThuc.HangHoa_Id,
				KhuCheBien_Id: this.khuVucCheBienSelect,
				DiaDiemSuDung_Id: this.diadDiemSuDungSelect,
				DiaDiemSanXuat_Id: this.diadDiemSanXuatSelect,
				DinhLuong_DonViTinh_Id: this.donViTinhDLSelect,
				TrangThai: this.trangThaiSelect,
				GiaNhap: this.tongChiPhi,
				GhiChu: this.ChiTietCongThuc.GhiChu,
				Is_TamKhoa: Number(!!this.ChiTietCongThuc.Is_TamKhoa),
				Is_DungTenThayThe: false,
				JSON_CongThuc: JSON.stringify(JSON_CongThuc),
				JSON_DinhLuong: JSON.stringify(JSON_DinhLuong),
			}

			apiCall('/work/MT_CongThuc_Update', payload, () => {
				showToast.success('Cập nhật công thức thành công!')
				if (vueData.CongThuc_Id) {
					this.loadData(vueData.CongThuc_Id)
					this.editingRow = null
					this.$emit("onReload")
				}
			})
		},

		async saveAndContinue() {
			try {
				let success = true
				if (!this.isSaveNewRecipe) success = await this.saveAll()
				if (success) {
					this.resetData()
					this.onAddNewRow()
				}
			} catch (e) {
				console.warn('Save failed:', e?.message || e)
			}
		},

		// Rule nghiệp vụ:
		// Chỉ cảnh báo khi dòng "Tính ĐL" dùng đơn vị khác đơn vị ĐL của công thức.
		// Không chặn lưu vì công thức TP/BTP có thể chứa nhiều nguyên liệu với đơn vị sử dụng khác nhau.
		// Hàm này luôn trả true theo chủ đích; toast chỉ dùng để nhắc người dùng kiểm tra lại.
		toDonViTinhDinhLuongValid() {
			const donViDL = this.donViTDLCheck
			if (!donViDL) return true

			const invalidRows = this.DsChiTieTCongThuc.filter(r =>
				!!r.HangHoa_Id && !!r.Is_TinhDinhLuong && Number(r.DonVi) !== Number(this.donViTinhDLSelect)
			)

			if (invalidRows.length > 0) {
				const r0 = invalidRows[0]
				showToast.info(
					`Dòng ${r0.STT}: Đang chọn "Tính ĐL" nhưng ĐV sử dụng (${r0.TenDonVi || r0.DonVi}) không khớp với ĐV tính ĐL của công thức!`
				)
				return true
			}

			return true
		},

		/* ===============================
		ROW CRUD
		=============================== */
		onAddNewRow() {
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
				TenDonVi: '',
				DonViCheck: false,
				DonViQuyDoiOptions: [],
				DonViGocOptions: [],
				QuyDoiInfo: [],
				DonGia_ApDung: 0,

				GiaNguyenVatLieu: 0,
				DinhLuongMotPhan: null,
				Is_TinhDinhLuong: true,
				GhiChu: '',
				NhomThanhPhan: '',
				ChiPhiSuDung: 0,
				TenThayThe: '',
				TenThayTheUpdate: '',
			}

			this.cotDinhLuong.forEach((c) => {
				if (c.key !== 'DinhLuongMotPhan') newRow[c.key] = 0
			})

			this.editingRow = newRow.STT
			this.DsChiTieTCongThuc.push(newRow)
		},

		onEditRow(row) {
			this.editingRow = row.STT
		},

		onSaveRow(row) {
			if (!row.HangHoa_Id) {
				showToast.error('Vui lòng chọn nguyên liệu!')
				return
			}

			if (row.Is_TinhDinhLuong) {
				const dl = parseFloat(String(row.DinhLuongMotPhan ?? '').replace(',', '.'))
				if (!Number.isFinite(dl) || dl <= 0) {
					showToast.error('Vui lòng nhập "ĐL 1 phần" > 0!')
					return
				}
			}

			this.editingRow = null

			if (this.isEditPage) {
				this.updateAll()
			} else {
				showToast.success('Chọn "Lưu công thức" để lưu toàn bộ!')
			}
		},

		deleteThanhPhan(row, index) {
			if (row.TenHangHoa) {
				if (this.isEditPage) {
					showConfirm(
						`Bạn chắc chắn muốn xóa ${row.TenHangHoa || 'dòng này'}?`,
						() => {
							this.DsChiTieTCongThuc.splice(index, 1)

							if (this.editingRow === row.STT) this.editingRow = null
							else if (this.editingRow !== null && this.editingRow > row.STT) this.editingRow = this.editingRow - 1

							this.updateRowsStt(this.DsChiTieTCongThuc)
							this.updateAll()
						}
					)
				} else {
					showConfirm(
						`Bạn chắc chắn muốn xóa ${row.TenHangHoa || 'dòng này'}?`,
						() => {
							this.DsChiTieTCongThuc.splice(index, 1)

							if (this.editingRow === row.STT) this.editingRow = null
							else if (this.editingRow !== null && this.editingRow > row.STT) this.editingRow = this.editingRow - 1

							this.updateRowsStt(this.DsChiTieTCongThuc)
							showToast.success('Đã xóa! Nhấn "Lưu công thức" để cập nhật.')
						}
					)
				}
			} else {
				this.DsChiTieTCongThuc.splice(index, 1)
				this.updateRowsStt(this.DsChiTieTCongThuc)
				showToast.success('Đã xóa! Nhấn "Lưu công thức" để cập nhật.')
			}
		},

		updateRowsStt(rows) {
			rows.forEach((r, i) => { r.STT = i + 1 })
			return rows
		},

		toRowKey(row, i) {
			return 'row-' + (row.HangHoa_Id || 'new') + '-' + row.STT + '-' + i
		},

		/* ===============================
		ĐỊNH LƯỢNG
		=============================== */
		onDinhLuongChange(row) {
			const base = parseFloat(String(row.DinhLuongMotPhan || '').replace(',', '.'))
			const gia = parseFloat(String(row.GiaNguyenVatLieu || '').replace(',', '.'))

			this.cotDinhLuong.forEach(c => {
				if (c.key !== 'DinhLuongMotPhan') {
					row[c.key] = (base || 0) * c.dinhLuong
				}
			})

			row.ChiPhiSuDung = (Number(row.GiaNguyenVatLieu) || 0) * this.toNumberComma(row.DinhLuongMotPhan)
		},

		onEditSauKhiNau() {
			this.isDisabledSauKhiNau = false
		},

		onSaveSauKhiNau() {
			if (this.isEditPage) this.updateAll()
			this.isDisabledSauKhiNau = true
		},

		onSauKhiNauInput(val, dinhLuong) {
			if (val === null || val === '') {
				this.sauKhiNauJson[this.toDinhLuongJsonKey(dinhLuong)] = val
				return
			}

			const raw = String(val).replace(/\./g, '').replace(/,/g, '.')
			const number = Number(raw)
			if (isNaN(number)) return

			this.sauKhiNauJson[this.toDinhLuongJsonKey(dinhLuong)] = number
		},

		toDinhLuongKey(dinhLuong) {
			if (dinhLuong === 1) return "DinhLuongMotPhan"
			return `DinhLuong${String(dinhLuong).replace(".", "_")}`
		},

		toDinhLuongJsonKey(dinhLuong) {
			return `DinhLuong${String(dinhLuong).replace(".", "_")}`
		},

		capNhatDinhLuongVaChiPhiChoTatCaDong() {
			this.DsChiTieTCongThuc.forEach((row) => {
				const base = parseFloat(row.DinhLuongMotPhan) || 0
				const gia = parseFloat(row.GiaNguyenVatLieu) || 0

				// update các cột định lượng
				this.cotDinhLuong.forEach((c) => {
					if (c.key !== 'DinhLuongMotPhan') {
						row[c.key] = base * c.dinhLuong
					}
				})

				// update chi phí
				row.ChiPhiSuDung = base * gia
			})
		},

		updateDinhLuongColumns(payload) {
			const added = payload?.added || []
			const removed = payload?.removed || []

			// Xóa các cột bị removed
			removed.forEach((dinhLuong) => {
				this.deleteDinhLuongColumn(dinhLuong)
			})

			// Thêm các cột mới
			if (added.length > 0) {
				this.updateDinhLuongColumnsAdd(added)
			}

			// Sau khi add/remove cột -> tính lại toàn bộ
			this.capNhatDinhLuongVaChiPhiChoTatCaDong()

			if (this.isEditPage) {
				this.updateAll()
			}
		},

		updateDinhLuongColumnsAdd(dinhLuongList) {
			if (!dinhLuongList || !dinhLuongList.length) return

			const list = [...new Set(dinhLuongList)].sort((a, b) => a - b)

			list.forEach((dinhLuong) => {
				if (this.cotDinhLuong.some((x) => x.dinhLuong === dinhLuong)) return

				const key = this.toDinhLuongKey(dinhLuong)

				this.cotDinhLuong.push({
					dinhLuong,
					key,
					title: `ĐL ${dinhLuong} phần`,
					width: 60,
					align: 'right'
				})

				// set giá trị cho từng dòng (để UI có ngay)
				this.DsChiTieTCongThuc.forEach((r) => {
					const base = parseFloat(r.DinhLuongMotPhan) || 0
					r[key] = base * dinhLuong
				})

				// đảm bảo có key trong sauKhiNauJson
				const kJson = this.toDinhLuongJsonKey(dinhLuong)
				if (this.sauKhiNauJson[kJson] === undefined) this.sauKhiNauJson[kJson] = null
			})
		},

		deleteDinhLuongColumn(dinhLuong) {
			if (dinhLuong === 1) return

			const key = this.toDinhLuongKey(dinhLuong)
			this.cotDinhLuong = this.cotDinhLuong.filter((x) => x.dinhLuong !== dinhLuong)

			this.DsChiTieTCongThuc.forEach((r) => delete r[key])

			const kJson = this.toDinhLuongJsonKey(dinhLuong)
			delete this.sauKhiNauJson[kJson]
		},

		/* ===============================
		GHI CHÚ
		=============================== */
		onEditGhiChu(row, key) {
			this.editingGhiChuCell = { rowId: row.STT, key }
			this.ghiChuOriginal = row[key] ?? ''
			this.ghiChuDraft = row[key] ?? ''
		},

		onSaveGhiChu(row) {
			const key = this.editingGhiChuCell?.key
			if (!key) return

			row[key] = this.ghiChuDraft
			this.editingGhiChuCell = null

			if (this.isEditPage) this.updateAll()
		},

		onCancelGhiChu() {
			this.ghiChuDraft = ''
			this.ghiChuOriginal = ''
			this.editingGhiChuCell = null
		},

		/* ===============================
		NGUYÊN LIỆU (NHẬN UPDATED DATA TỪ uc-row-nguyen-lieu)
		=============================== */
		onUpdateRowNguyenLieu(updatedData, currentRow) {
			Object.assign(currentRow, updatedData)

			// Sau khi row bị đổi DonViCheck/DonVi/QuyDoi... => tính lại ngay
			// (đặc biệt case: quy đổi bị khóa hết => chuyển sang gốc)
			this.capNhatRowSauKhiDoiDonVi(currentRow)
		},

		/* ===============================
		ĐỔI ĐƠN VỊ
		=============================== */
		onChangeDonVi(val, row) {
			row.DonVi = Number(val)
			row.DonViCheck = true

			this.capNhatRowSauKhiDoiDonVi(row)
		},

		onChangeDonViGoc(val, row) {
			row.DonVi = Number(val)
			row.DonViCheck = false

			this.capNhatRowSauKhiDoiDonVi(row)
		},

		/* ===============================
		INPUT SỐ
		=============================== */
		onNumberCommaInput(val, row, key) {
			if (val === null || val === '') {
				row[key] = val
				return
			}

			const raw = String(val).replace(/\./g, '').replace(/,/g, '.')
			const number = Number(raw)
			if (isNaN(number)) return

			row[key] = number
			this.onDinhLuongChange(row)
		},

		onBlockDot(e) {
			if (e.ctrlKey) {
				const allowCtrlKeys = ['a', 'c', 'v', 'x']
				if (allowCtrlKeys.includes(e.key.toLowerCase())) return
			}

			const allowKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab']
			if (allowKeys.includes(e.key)) return

			const value = e.target.value

			if (/^\d$/.test(e.key)) return

			if (e.key === ',') {
				if (value.includes(',')) e.preventDefault()
				return
			}

			e.preventDefault()
		},

		/* ===============================
		Modal
		=============================== */
		onShowModalThemCot() {
			this.isShowModalThemDinhLuong = true
		},

		onShowImportModal() {
			this.isShowModalImport = true
		},

		onClose() {
			this.resetData()
			this.$emit('update:modelValue', false)
			vueData.CongThuc_Id = null
			vueData.TenHangHoa = null
		},

		isDuplicateHangHoa(row) {
			if (!row.HangHoa_Id) return false
			return this.filteredRecipes.filter(r => r.HangHoa_Id === row.HangHoa_Id).length > 1
		},

		formatNumber(val) {
			if (val === null || val === '' || val === undefined) return ''

			const num = Number(val)
			if (isNaN(num)) return val

			return num.toLocaleString('vi-VN')
		},

		formatNumberDisplay(val) {
			if (val === null || val === '' || val === undefined) return '0,00'

			const num = Number(val)
			if (isNaN(num)) return '0,00'

			return num.toLocaleString('vi-VN', {
				minimumFractionDigits: 2,
				maximumFractionDigits: 2
			})
		},

		resetCongThucDetailsForMainProductChange() {
			this.DsChiTieTCongThuc = []
			this.cotDinhLuong = [
				{ dinhLuong: 1, key: "DinhLuongMotPhan", title: "ĐL 1 phần", width: 80 },
			]
			this.sauKhiNauJson = {}
			this.editingRow = null
			this.editingGhiChuCell = null
			this.isDisabledSauKhiNau = true
			this.onAddNewRow()
		},

		resetData() {
			this.diadDiemSanXuatSelect = null
			this.diadDiemSuDungSelect = null
			this.khuVucCheBienSelect = null
			this.donViTinhDLSelect = null
			this.donViTDL = null
			this.donViSauKhiNau = null
			this.tiLeSoVoiChiPhi = 0
			this.cachThucBaoQuan = ""

			this.ChiTietCongThuc = {
				HangHoa_Id: null,
				EORDER_SanPham_Id: 0,
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
			}

			this.DsChiTieTCongThuc = []

			this.cotDinhLuong = [
				{ dinhLuong: 1, key: "DinhLuongMotPhan", title: "ĐL 1 phần", width: 80 },
			]

			this.sauKhiNauJson = {}

			this.isEditPage = false
			this.editingRow = null
			this.suppressMainProductReset = false
			this.editingGhiChuCell = null
			this.isImportMode = false
			this.isDisabledSauKhiNau = true
			this.isSaveNewRecipe = false
			this.search = ""
		},

		/* ===============================
		IMPORT / EXPORT
		=============================== */

		onExportBangCongThucExcel() {
			if (typeof exportCongThucCheBienExcel === 'undefined') {
				showToast.error('Chức năng export chưa được cài đặt!')
				return
			}

			const detailRowsSorted = this.filteredRecipes
				.slice()
				.sort((x, y) =>
					String(x.TenNhomVatTu || "").localeCompare(String(y.TenNhomVatTu || ""), "vi")
				)

			const chiNhanhType = this.ChiTietCongThuc.LoaiNguyenLieu === "TP" ? this.ChiTietCongThuc.TenDiaDiemSuDung :
				this.ChiTietCongThuc.TenDiaDiem

			exportCongThucCheBienExcel({
				company: "CÔNG TY TNHH MTV THƯƠNG MẠI DỊCH VỤ TÔ MINH",
				chiNhanh: chiNhanhType ?? '',
				khuVuc: this.ChiTietCongThuc.TenKhuVuc ?? this.khuVucCheBienSelect,
				tenMon: vueData.TenHangHoa,
				detailRows: detailRowsSorted,
				cotDinhLuong: this.cotDinhLuong,
				donViTDL: this.donViTDL,
				donViSauKhiNau: this.donViSauKhiNau,
				DinhLuongCol_Json: this.sauKhiNauJson,

				tongDLTheoCot: this.tongDLTheoCotDisplay,
				haoHutTheoCot: this.haoHutTheoCot,
				tongChiPhiTheoCot: this.tongChiPhiTheoCot,
				tongChiPhi: this.tongChiPhi,

				loaiNguyenLieu: this.ChiTietCongThuc.LoaiNguyenLieu,
				giaBan: this.ChiTietCongThuc.GiaBan,
				tiLeSoVoiChiPhi: this.tiLeSoVoiChiPhiAuto,

				hanSuDung: this.ChiTietCongThuc.HanSuDung_Gio,
				baoQuan: this.cachThucBaoQuan,
				thietBiBaoQuan: this.ChiTietCongThuc.BaoQuan_ThietBi,
				fileName: `BangCongThuc_${vueData.TenHangHoa}.xlsx`,
			})
		},

		onExportBangChiPhiExcel() {
			const chiNhanhType = this.ChiTietCongThuc.LoaiNguyenLieu === "TP" ? this.ChiTietCongThuc.TenDiaDiemSuDung :
				this.ChiTietCongThuc.TenDiaDiem

			exportBangChiPhiExcel({
				company: "CÔNG TY TNHH MTV THƯƠNG MẠI DỊCH VỤ TÔ MINH",
				chiNhanh: chiNhanhType ?? '',
				khuVuc: this.ChiTietCongThuc.TenKhuVuc ?? this.khuVucCheBienSelect,
				tenMon: vueData.TenHangHoa,

				tatCaCot: this.tatCaCot,
				colsBody: this.colsBody,
				detailRows: this.filteredRecipes,

				cotDinhLuong: this.cotDinhLuong,
				donViTDL: this.donViTDL,
				donViSauKhiNau: this.donViSauKhiNau,
				sauKhiNauJson: this.sauKhiNauJson,

				tongDLTheoCot: this.tongDLTheoCotDisplay,
				haoHutTheoCot: this.haoHutTheoCot,
				tongChiPhiTheoCot: this.tongChiPhiTheoCot,
				tongChiPhi: this.tongChiPhi,

				loaiNguyenLieu: this.ChiTietCongThuc.LoaiNguyenLieu,
				giaBan: this.ChiTietCongThuc.GiaBan,
				tiLeSoVoiChiPhi: this.tiLeSoVoiChiPhiAuto,

				loaiNguyenLieu: this.ChiTietCongThuc.LoaiNguyenLieu,
				giaBan: this.ChiTietCongThuc.GiaBan,
				tiLeSoVoiChiPhi: this.tiLeSoVoiChiPhiAuto,

				hanSuDung: this.ChiTietCongThuc.HanSuDung_Gio,
				baoQuan: this.cachThucBaoQuan,
				thietBiBaoQuan: this.ChiTietCongThuc.BaoQuan_ThietBi,

				fileName: `BangChiPhi_${vueData.TenHangHoa}.xlsx`,
			});
		},


		onImportSuccess(data) {
			// console.log('Import data:', data)

			try {
				// 1. Set thông tin sản phẩm chính
				if (data.hangHoa) {
					this.ChiTietCongThuc.HangHoa_Id = data.hangHoa.HangHoa_Id
					// Load chi tiết sản phẩm
					this.loadChiTietNguyenLieu(data.hangHoa.HangHoa_Id)
				}

				// 2. Set địa điểm
				if (data.diaDiemSanXuat) {
					this.diadDiemSanXuatSelect = data.diaDiemSanXuat.DiaDiem_Id
				}

				if (data.diaDiemSuDung) {
					this.diadDiemSuDungSelect = data.diaDiemSuDung.DiaDiem_Id
				}

				if (data.khuVucCheBien) {
					this.khuVucCheBienSelect = data.khuVucCheBien.KhuVuc_Id
				}

				if (data.donViDinhLuong) {
					this.donViTinhDLSelect = data.donViDinhLuong.DonViTinh_Id
				}

				// 3. Set danh sách nguyên liệu
				if (data.DsNguyenLieu && data.DsNguyenLieu.length > 0) {
					this.DsChiTieTCongThuc = data.DsNguyenLieu.map((m, i) => ({
						...m,
						STT: i + 1,
						HangHoa_Id: m.HangHoa_Id ?? m.rowData?.HangHoa_Id,
						NguyenVatLieu: m.TenHangHoa,
						MaNoiBo: m.MaNoiBo ?? '',
						TenHangHoa: m.TenHangHoa,
						DonGia_TrungBinh: m.DonGia_TrungBinh ?? 0,
						DonGia_MoiNhat: m.DonGia_MoiNhat ?? 0,
						DonGia_ApDung: m.DonGia_ApDung ?? 0,
						GiaNguyenVatLieu: m.GiaNguyenVatLieu,
						DinhLuongMotPhan: m.DinhLuongMotPhan,
						DonVi: m.DonVi,
						TenDonVi: m.TenDonVi,
						GhiChu: m.GhiChu ?? '',
						Is_TinhDinhLuong: m.Is_TinhDinhLuong !== false,
						ChiPhiSuDung: m.ChiPhiSuDung ?? 0,
						DonViCheck: m.DonViCheck,
						DonViQuyDoiOptions: m.DonViQuyDoiOptions ?? [],
						DonViGocOptions: m.DonViGocOptions ?? [],
						QuyDoiInfo: m.QuyDoiInfo ?? [],
					}))

					// 4. Tính toán các cột định lượng	
					this.DsChiTieTCongThuc.forEach(row => {
						this.capNhatRowSauKhiDoiDonVi(row)
					})

					this.sauKhiNauJson[this.toDinhLuongJsonKey(1)] = data.sauKhiNau ?? 0


					showToast.success(`Đã import ${data.DsNguyenLieu.length} nguyên liệu!`)
				}

				// 5. Đóng modal import
				this.isShowModalImport = false
				this.isImportMode = true
				this.editingRow = null

				if (!this.isEditPage) {
					this.editingRow = null
				}

			} catch (error) {
				console.error('Handle import error:', error)
				showToast.error('Lỗi khi xử lý dữ liệu import!')
			}
		},
	},
}
</script>
