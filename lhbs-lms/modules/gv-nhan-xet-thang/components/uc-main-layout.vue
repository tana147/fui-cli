<template>
	<Global>
		<template #header>
			<v-card>
				<v-card-title class="d-flex align-center flex-wrap ga-2">
					<span>{{ TitlePage }} • {{ TitleCap }}</span>
					<v-chip v-if="ThangObj" :color="ThangObj?.MauTinhTrang" class="ms-2" size="small">
						{{ ThangObj?.TenTinhTrang }}
					</v-chip>
					<v-chip color="primary" variant="tonal" class="ms-2" size="small">
						{{ isEn ? 'Total students' : 'Tổng số học sinh' }}: {{ items.length }}
					</v-chip>
					<v-spacer />
					<v-btn-toggle v-model="isEn" size="small" class="ms-auto">
						<v-btn :value="false" :disabled="!isEn" :color="!isEn ? 'green' : 'white'" @click="setLanguage(false)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="30" />
						</v-btn>
						<v-btn :value="true" :disabled="isEn" :color="isEn ? 'green' : 'white'" @click="setLanguage(true)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="30" />
						</v-btn>
					</v-btn-toggle>
				</v-card-title>
				<v-card-text class="pb-0 px-0">
					<v-row dense>
						<v-col cols="2">
							<v-select v-model="LopItem" :label="isEn ? 'Select class' : 'Chọn lớp'" :items="DSLop" item-title="TenLop"
								item-value="LopID" return-object :hide-details="true" class="ms-1"
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'" />
						</v-col>
						<v-col cols="2">
							<v-select v-model="ThangObj" :label="isEn ? 'Select month' : 'Chọn tháng'" :items="DSThang" :item-title="formatThangHienThi"
								item-value="Lop_NhanXetThangID" return-object :hide-details="true"
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
								<template v-slot:item="{ props, item }">
									<v-list-item v-bind="props" :title="formatThangHienThi(item.raw)">
										<template #append>
											<v-chip :color="item.raw.MauTinhTrang">{{ formatTinhTrang(item.raw.TenTinhTrang) }}</v-chip>
										</template>
									</v-list-item>
								</template>
							</v-select>
						</v-col>
						<v-col>
							<v-btn color="primary" variant="outlined" prepend-icon="mdi-refresh" @click="onRefresh">
								{{ isEn ? 'Refresh' : 'Làm mới' }}
							</v-btn>
						</v-col>
						<v-col cols="12" class="pb-4">
							<div class="d-flex justify-space-between align-center">
								<div v-if="ThangObj?.ReasonReject && ThangObj.TinhTrang === 3">
									Lý do từ chối: <span class="text-red">{{ ThangObj?.ReasonReject }}</span>
								</div>
								<div class="d-flex ga-2">
									<v-btn v-if="items.length > 0"
										:prepend-icon="isReviewMode ? 'mdi-pencil' : 'mdi-eye'"
										:color="isReviewMode ? 'warning' : 'secondary'" variant="outlined"
										@click="isReviewMode = !isReviewMode">
										{{ isReviewMode ? (isEn ? 'Back to entry' : 'Quay lại nhập liệu') : (isEn ? 'Review' : 'Xem lại') }}
									</v-btn>
									<v-btn v-if="!(ThangObj?.Is_HienThiPhuHuynh === false && ThangObj?.Thang === 5)"
										prepend-icon="mdi-file-excel" color="success" variant="outlined"
										:disabled="items.length === 0 || isReadOnly" @click="onImport">
										{{ isEn ? 'Import Excel' : 'Import dữ liệu từ Excel' }}
									</v-btn>
									<v-menu v-if="items.length > 0">
										<template #activator="{ props }">
											<v-btn v-bind="props" color="success" variant="outlined" prepend-icon="mdi-file-excel">
												{{ isEn ? 'Export Excel' : 'Xuất Excel' }} <v-icon end>mdi-chevron-down</v-icon>
											</v-btn>
										</template>
										<v-list>
											<v-list-item @click="onExportExcel('class')">
												<v-list-item-title>{{ isEn ? 'Export current class' : 'Xuất lớp hiện tại' }}</v-list-item-title>
											</v-list-item>
											<v-list-item @click="onExportExcel('grade')">
												<v-list-item-title>{{ isEn ? 'Export entire grade' : 'Xuất toàn bộ khối' }}</v-list-item-title>
											</v-list-item>
										</v-list>
									</v-menu>
									<v-btn v-if="CapID === 1" prepend-icon="mdi-file-pdf-box" color="error" variant="outlined"
										:loading="isExportingPdf" :disabled="items.length === 0" @click="onExportPDF">
										{{ isEn ? 'Export PDF' : 'Xuất PDF' }}
									</v-btn>
									<v-btn prepend-icon="mdi-content-save" color="info" variant="outlined"
										:disabled="items.length === 0 || isReadOnly" @click="onSave">
										{{ isEn ? 'Save draft all' : 'Lưu tạm tất cả' }}
									</v-btn>
									<v-btn v-if="isAdminUser && ThangObj" prepend-icon="mdi-swap-horizontal"
										color="secondary" variant="outlined" @click="IsShowDialogTinhTrang = true">
										{{ isEn ? 'Change status' : 'Chuyển trạng thái' }}
									</v-btn>
									<v-btn
										v-if="CapID === 1 && !(ThangObj?.Is_HienThiPhuHuynh === false && ThangObj?.Thang === 5)"
										prepend-icon="mdi-send" color="primary" variant="outlined" class="me-1"
										:disabled="items.length === 0 || isReadOnly" @click="onSendToTruong">
										{{ isEn ? 'Submit to lead' : 'Gửi tổ trưởng' }}
									</v-btn>
									<v-btn
										v-if="(CapID === 2 || CapID === 3) && !(ThangObj?.Is_HienThiPhuHuynh === false && ThangObj?.Thang === 5)"
										prepend-icon="mdi-send" color="primary" variant="outlined" class="me-1"
										:disabled="items.length === 0 || isReadOnly" @click="onSendToBGH">
										{{ isEn ? 'Submit to principal' : 'Gửi BGH' }}
									</v-btn>
								</div>
							</div>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</template>

		<v-divider />
		<div v-if="isLoadingViPham" class="d-flex align-center ga-3 px-4 py-2">
			<v-progress-circular indeterminate size="18" width="2" color="primary" />
			<span class="text-body-2 text-medium-emphasis">{{ viPhamLoadingText }}</span>
		</div>
		<v-data-table :key="keyTable" :headers="headers" :items="items" items-per-page="-1" hide-default-footer
			:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'"
			style="height: calc(100dvh - 119px); overflow-y: auto;">

			<!-- ─── Học sinh ─── -->
			<template #item.HocSinh="{ item }">
				<uc-info-student :item="item" />
			</template>

			<!-- ─── GVCN view: Phối hợp + các trường phụ ─── -->
			<template #item.gvcn_extra="{ item }">
				<div class="d-flex ga-2 flex-column pa-2">
					<v-select v-model="item.PhoiHopCMHS" :label="isEn ? 'Coordination with parents' : 'Phối hợp CMHS'"
						:items="isEn ? ['Good', 'Pass', 'Fail'] : ['Tốt', 'Đạt', 'Không đạt']"
						:placeholder="isEn ? 'Select' : 'Chọn'" :disabled="isReadOnly"
						:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'" />
					<template v-if="!isKhoiCanLoai">
						<v-select v-model="item.PhanLoai_TuyenThang"
							:items="isEn ? ['Direct admission', 'Direct admission with commitment'] : ['Tuyển thẳng', 'Tuyển thẳng có cam kết']"
							:label="isEn ? 'Direct admission classification' : 'Phân loại tuyển thẳng'" :disabled="isReadOnly"
							:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'" />
						<v-text-field v-model="item.Flyers" label="Flyers" :disabled="isReadOnly" />
						<v-text-field v-model="item.DiemTA" label="Điểm Tiếng Anh" :disabled="isReadOnly" />
						<v-checkbox v-model="item.DKHocTiep" label="Đăng ký học tiếp" :disabled="isReadOnly" />
						<v-textarea v-model="item.DeXuat_NDCamKet" label="Đề xuất / ND cam kết" :hide-details="false"
							:disabled="isReadOnly" />
					</template>
				</div>
			</template>

			<template #item.NhanXet_ChuanBiNienKhoaSau="{ item }">
				<div style="padding: 10px; min-width: 200px;">
					<uc-quill-editor
						:key="'NhanXet_ChuanBiNienKhoaSau' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NhanXet_ChuanBiNienKhoaSau" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>

			<template #item.NhanXetGVCN_VePhuHuynh_HTML="{ item }">
				<div style="padding: 10px; max-width: 250px;">
					<uc-quill-editor
						:key="'NhanXetGVCN_VePhuHuynh_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NhanXetGVCN_VePhuHuynh_HTML" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>

			<template #item.NhanXetGVCN_VeHocSinh_HTML="{ item }">
				<div style="padding: 10px; max-width: 250px;">
					<uc-quill-editor
						:key="'NhanXetGVCN_VeHocSinh_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NhanXetGVCN_VeHocSinh_HTML" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>

			<!-- ─── Cấp 1: Các cột nhận xét môn ─── -->
			<template #item.NhanXetToan_HTML="{ item }">
				<div style="padding: 10px; max-width: 280px;">
					<uc-quill-editor
						:key="'NhanXetToan_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NhanXetToan_HTML" :spellcheck="false" style="height: 150px;"
						:readOnly="isReadOnly" />
					<v-text-field class="mt-2" v-model="item.DiemToan" placeholder="Nhập điểm..."
						messages="*Lưu ý: Thang điểm 10" variant="filled" :clearable="false" suffix="Điểm"
						:readOnly="isReadOnly" solo reverse />
				</div>
			</template>

			<template #item.NhanXetTiengViet_HTML="{ item }">
				<div style="padding: 10px; max-width: 280px;">
					<uc-quill-editor
						:key="'NhanXetTiengViet_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NhanXetTiengViet_HTML" :spellcheck="false" style="height: 150px;"
						:readOnly="isReadOnly" />
					<v-text-field class="mt-2" v-model="item.DiemTiengViet" placeholder="Nhập điểm..."
						messages="*Lưu ý: Thang điểm 10" variant="filled" :clearable="false" suffix="Điểm"
						:readOnly="isReadOnly" solo reverse />
				</div>
			</template>

			<template #item.NhanXetMonHocKhac_HTML="{ item }">
				<div style="padding: 10px; max-width: 280px;">
					<uc-quill-editor
						:key="'NhanXetMonHocKhac_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NhanXetMonHocKhac_HTML" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>

			<template #item.HoatDongGiaoDucKhac_HTML="{ item }">
				<div style="padding: 10px; max-width: 280px;">
					<uc-quill-editor
						:key="'HoatDongGiaoDucKhac_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.HoatDongGiaoDucKhac_HTML" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>

			<template #item.PhamChatNangLuc_HTML="{ item }">
				<div style="padding: 10px; max-width: 280px;">
					<uc-quill-editor
						:key="'PhamChatNangLuc_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.PhamChatNangLuc_HTML" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>

			<!-- ─── Cấp 2 & 3: NgayNghi ─── -->
			<template #item.NgayNghi="{ item }">
				<div class="d-flex ga-2 flex-column" style="padding: 8px; min-width: 200px;">
					<div v-if="item.NgayNghi?.TongSoTiet > 0" class="d-flex justify-space-between align-center">
						<span class="font-weight-medium text-body-2">
							Tổng số tiết: {{ item.NgayNghi?.TongSoTiet }}
						</span>
						<v-btn icon="mdi-eye" size="small" variant="text" color="primary"
							:title="'Xem báo nghỉ chi tiết - ' + item.HoTen"
							:href="'/gv-xem-vang-tre-nghi-phep?hocsinhid=' + item.HocSinhID + '&lopid=' + item.LopID + '&ngaybatdau=' + item.firstDay + '&ngayketthuc=' + item.lastDay"
							target="_blank" />
					</div>
					<v-chip v-for="mon in item.NgayNghi?.MonVang" :key="mon.TenMonHoc" color="orange" size="small"
						style="width: fit-content;">
						{{ mon.TenMonHoc }}
					</v-chip>

					<template v-if="getViPhamCuaHocSinh(item.HocSinhID).length > 0">
						<v-divider class="mt-1" />
						<div v-for="lvp in getViPhamCuaHocSinh(item.HocSinhID)" :key="lvp.LoaiViPham" class="mt-1">
							<v-chip size="x-small" color="error" variant="tonal"
								style="cursor: pointer; height: auto; white-space: normal;"
								@click="toggleViPhamExpand(item.HocSinhID, lvp.LoaiViPham)">
								<v-progress-circular v-if="viPhamLoadingMap[lvp.LoaiViPham]" indeterminate size="10"
									width="2" class="me-1" />
								{{ tenViPhamVI(lvp.TenViPham) }} ({{ lvp.SoLuong_HS }} {{ lvp.LoaiViPham === 2 ? 'ngày'
								: 'tiết' }})
							</v-chip>
							<div v-if="viPhamExpandedMap[item.HocSinhID + '_' + lvp.LoaiViPham]" class="mt-1 ms-2">
								<!-- LoaiViPham 2: hiển thị theo ngày (unique) -->
								<template v-if="lvp.LoaiViPham === 2">
									<div v-for="ngay in [...new Set(getViPhamChiTiet(item.HocSinhID, lvp.LoaiViPham).map(r => r.Ngay))]"
										:key="ngay" class="text-caption text-medium-emphasis">
										{{ formatNgayViPham(ngay) }}
									</div>
								</template>
								<!-- Các vi phạm khác: hiển thị theo tiết -->
								<template v-else>
									<div v-for="(row, idx) in getViPhamChiTiet(item.HocSinhID, lvp.LoaiViPham)"
										:key="idx" class="text-caption text-medium-emphasis">
										{{ formatNgayViPham(row.Ngay) }} · Tiết {{ row.Tiet }} · {{ row.TenMonHoc }}
									</div>
								</template>
							</div>
						</div>
					</template>

					<!-- ─── Nhóm học ─── -->
					<template
						v-if="item.DSNhom?.some(n => n.LopHocID && getViPhamCuaHocSinhTrongNhom(item.HocSinhID, n.LopHocID).length > 0)">
						<v-divider class="mt-2 mb-1" />
						<!-- <div class="text-caption text-medium-emphasis mb-1">Nhóm học:</div> -->
						<template v-for="nhom in item.DSNhom" :key="nhom.NhomID">
							<div v-if="nhom.LopHocID && getViPhamCuaHocSinhTrongNhom(item.HocSinhID, nhom.LopHocID).length > 0"
								class="mb-1">
								<!-- <v-chip size="x-small" color="indigo" variant="tonal">{{ nhom.TenNhom }}</v-chip> -->
								<div v-for="lvp in getViPhamCuaHocSinhTrongNhom(item.HocSinhID, nhom.LopHocID)"
									:key="nhom.NhomID + '_' + lvp.LoaiViPham" class="ms-2 mt-1">
									<v-chip size="x-small" color="error" variant="tonal"
										style="cursor: pointer; height: auto; white-space: normal;"
										@click="toggleViPhamExpandNhom(item.HocSinhID, nhom.LopHocID, lvp.LoaiViPham)">
										<v-progress-circular
											v-if="viPhamLoadingMap_Nhom[nhom.LopHocID + '_' + lvp.LoaiViPham]"
											indeterminate size="10" width="2" class="me-1" />
										{{ tenViPhamVI(lvp.TenViPham) }} ({{ lvp.SoLuong_HS }} {{ lvp.LoaiViPham === 2 ?
										'ngày' : 'tiết' }})
									</v-chip>
									<div v-if="viPhamExpandedMap_Nhom[item.HocSinhID + '_' + nhom.LopHocID + '_' + lvp.LoaiViPham]"
										class="mt-1 ms-2">
										<template v-if="lvp.LoaiViPham === 2">
											<div v-for="ngay in [...new Set(getViPhamChiTietNhom(item.HocSinhID, nhom.LopHocID, lvp.LoaiViPham).map(r => r.Ngay))]"
												:key="ngay" class="text-caption text-medium-emphasis">
												{{ formatNgayViPham(ngay) }}
											</div>
										</template>
										<template v-else>
											<div v-for="(row, idx) in getViPhamChiTietNhom(item.HocSinhID, nhom.LopHocID, lvp.LoaiViPham)"
												:key="idx" class="text-caption text-medium-emphasis">
												{{ formatNgayViPham(row.Ngay) }} · Tiết {{ row.Tiet }} · {{
												row.TenMonHoc }}
											</div>
										</template>
									</div>
								</div>
							</div>
						</template>
					</template>
				</div>
			</template>

			<!-- ─── Cấp 2 & 3: Cuối kỳ (T12, T5) ─── -->
			<template #item.UuDiem="{ item }">
				<div style="padding: 10px;">
					<uc-quill-editor :key="'UuDiem' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.UuDiem" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>
			<template #item.NhuocDiem="{ item }">
				<div style="padding: 10px;">
					<uc-quill-editor :key="'NhuocDiem' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NhuocDiem" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>
			<template #item.DeXuat="{ item }">
				<div style="padding: 10px;">
					<uc-quill-editor :key="'DeXuat' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.DeXuat" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>
			<template #item.NhanXetGVCN="{ item }">
				<div style="padding: 10px;">
					<uc-quill-editor :key="'NhanXetGVCN' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NhanXetGVCN" :spellcheck="false" :readOnly="isReadOnly" :maxLength="500" />
				</div>
			</template>

			<!-- ─── Cấp 2 & 3: Các tháng thường ─── -->
			<template #item.NoiDungKienThuc_HTML="{ item }">
				<div style="padding: 10px; min-width: 200px;">
					<uc-quill-editor
						:key="'NoiDungKienThuc_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NoiDungKienThuc_HTML" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>
			<template #item.NoiDungNangLuc_HTML="{ item }">
				<div style="padding: 10px; min-width: 200px;">
					<uc-quill-editor
						:key="'NoiDungNangLuc_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NoiDungNangLuc_HTML" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>
			<template #item.NoiDungHoatDongKhac_HTML="{ item }">
				<div style="padding: 10px; min-width: 200px;">
					<uc-quill-editor
						:key="'NoiDungHoatDongKhac_HTML' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.NoiDungHoatDongKhac_HTML" :spellcheck="false" :readOnly="isReadOnly" />
				</div>
			</template>

			<!-- ─── Xem lại: RenderNhanXet (cấp 2&3 tháng thường) ─── -->
			<template #item.RenderNhanXet="{ item }">
				<div style="padding: 10px; min-width: 300px;">
					<uc-quill-editor :key="'RenderNhanXet' + item.HocSinhID + ThangObj?.Lop_NhanXetThangID + quillKey"
						v-model="item.RenderNhanXet" :spellcheck="false" :readOnly="true"
						class="custom-height-uc-quill-editor" />
				</div>
			</template>

		</v-data-table>

		<!-- Copy dialog -->
		<v-dialog v-model="IsShowDialogCopy" width="500">
			<v-card :title="isEn ? 'Copy monthly comments' : 'Sao chép nhận xét tháng'">
				<v-card-text>
					<v-select v-model="ThangObj_Copy" :label="isEn ? 'Select month to copy' : 'Chọn tháng sao chép'"
						:items="DSThang.filter(x => x.Lop_NhanXetThangID !== ThangObj?.Lop_NhanXetThangID)"
						:item-title="formatThangHienThi" return-object
						:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'" />
					<v-select v-model="ThangObj" :label="isEn ? 'Current selected month' : 'Tháng đang chọn'" :items="DSThang" :item-title="formatThangHienThi"
						return-object :readonly="true"
						:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'" />
				</v-card-text>
				<v-card-actions>
					<v-spacer />
					<v-btn @click="IsShowDialogCopy = false">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
					<v-btn color="primary" @click="onConfirmCopy">{{ isEn ? 'Confirm' : 'Xác nhận' }}</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<v-dialog v-model="IsShowDialogTinhTrang" width="520">
			<v-card :title="isEn ? 'Change monthly comment status' : 'Chuyển trạng thái nhận xét tháng'">
				<v-card-text>
					<v-select v-model="TinhTrangNew" :label="isEn ? 'Select status' : 'Chọn trạng thái'" :items="DSTinhTrang" item-title="title"
						item-value="value" :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'" />
					<v-textarea v-model="ReasonRejectNew" :label="isEn ? 'Reason for rejection' : 'Lý do từ chối'" :placeholder="isEn ? 'Enter reason (if any)' : 'Nhập lý do (nếu có)'"
						:disabled="TinhTrangNew !== 3" />
				</v-card-text>
				<v-card-actions>
					<v-spacer />
					<v-btn @click="IsShowDialogTinhTrang = false">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
					<v-btn color="primary" :disabled="TinhTrangNew === null" @click="onUpdateTinhTrang">
						{{ isEn ? 'Confirm' : 'Xác nhận' }}
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</Global>
</template>

<script>
	export default {
		name: 'NhanXetThang',

	// Inject snackbarRef, iframeRef được provide từ app root (qua Global.vue)
	inject: ['snackbarRef', 'iframeRef', 'confirmRef'],

	data() {
		const isLanguage = localStorage.getItem('IsLanguage')
		const isEn = isLanguage ? JSON.parse(isLanguage) : false
		if (window.$i18n) {
			window.$i18n.locale = isEn ? 'en' : 'vi'
		}
		return {
			vueData,
			isEn,
			DSLop: [],
			DSThang: [],
			LopItem: null,
			ThangObj: null,
			items: [],
			isLowScreen: window.innerWidth < 1366,			isReviewMode: false,			IsShowDialogCopy: false,
			isExportingPdf: false,
			IsShowDialogTinhTrang: false,
			TinhTrangNew: null,
			ReasonRejectNew: '',
			ThangObj_Copy: null,
			DSTongHop_ViPham: [],
			viPhamDetailMap: {},
			viPhamLoadingMap: {},
			viPhamExpandedMap: {},
			DSLopHoc: [],
			mainLopHocID: null,
			DSTongHop_ViPham_Nhom: {},
			viPhamDetailMap_Nhom: {},
			viPhamLoadingMap_Nhom: {},
			viPhamExpandedMap_Nhom: {},
			isLoadingViPham: false,
			viPhamLoadingText: '',
			keyTable: 0,
			quillKey: 0,
		}
	},

	mounted() {
		this.getLop()
		this._resizeHandler = () => {
			this.isLowScreen = window.innerWidth < 1366
		}
		window.addEventListener('resize', this._resizeHandler)
		this._storageHandler = (e) => {
			if (e.key === 'IsLanguage') {
				try {
					const isEn = JSON.parse(e.newValue) ?? false
					this.isEn = isEn
					if (window.$i18n) {
						window.$i18n.locale = isEn ? 'en' : 'vi'
					}
				} catch (err) {}
			}
		}
		window.addEventListener('storage', this._storageHandler)
	},

	beforeUnmount() {
		window.removeEventListener('resize', this._resizeHandler)
		if (this._storageHandler) window.removeEventListener('storage', this._storageHandler)
	},

	computed: {
		CapID() {
			return vueData.CapID
		},
		TitleCap() {
			const capId = parseInt(vueData.capid)
			if (this.isEn) {
				if (capId === 1) return 'Primary School'
				if (capId === 2) return 'Secondary School'
				if (capId === 3) return 'High School'
				return `Level ${capId}`
			}
			return renderText(capId)
		},
		TitlePage() {
			if (this.isEn) {
				return 'Monthly Comments'
			}
			return getTitlePageByURL(window.location.pathname + window.location.search)
		},
		isAdminUser() {
			return vueData.user?.UserID === 'NA0000022'
		},
		DSTinhTrang() {
			return [
				{ title: this.isEn ? 'Not saved' : 'Chưa lưu', value: 0 },
				{ title: this.isEn ? 'Draft saved' : 'Lưu tạm', value: 1 },
				{ title: this.isEn ? 'Submitted to lead' : 'Gửi tổ trưởng', value: 2 },
				{ title: this.isEn ? 'Rejected' : 'Từ chối', value: 3 },
				{ title: this.isEn ? 'Approved' : 'Duyệt', value: 4 },
			]
		},
		/** Readonly khi tình trạng là Đã duyệt (2) hoặc Từ chối (4), hoặc đang xem lại */
		isReadOnly() {
			return this.isReviewMode || this.ThangObj?.TinhTrang === 2 || this.ThangObj?.TinhTrang === 4
		},
		/** Các khối KHÔNG cần cột tuyển thẳng / Flyers / DiemTA */
		isKhoiCanLoai() {
			const DSKhoi_CanLoai = [1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12]
			const lop = this.DSLop.find(x => x.LopID === this.LopItem?.LopID)
			return DSKhoi_CanLoai.includes(lop?.KhoiID)
		},
		isCuoiKi() {
			return [12, 5].includes(this.ThangObj?.Thang)
		},
		headers() {
			// Explicit dep: nếu isReviewMode hoặc ThangObj thay đổi, computed tự re-evaluate
			const _r = this.isReviewMode
			const _t = this.ThangObj
			return this.renderHeader()
		},
	},

	watch: {
		'vueData.NienKhoa': function (v) {
			console.log("vueData.NienKhoa",vueData.NienKhoa)
			if (v) {
				this.getLop(true)
				this.LopItem = null
				this.ThangObj = null
				this.DSThang = []
				this.items = []
				this.isReviewMode = false
			}
		},
		LopItem(LopItem) {
			if (!LopItem) return
			this.ThangObj = null
			this.items = []
			this.isReviewMode = false
			this.getThang()
		},
		ThangObj(ThangObj) {
			if (!ThangObj) return
			this.items = []
			this.isReviewMode = false
			this.TinhTrangNew = ThangObj.TinhTrang ?? null
			this.ReasonRejectNew = ThangObj.ReasonReject ?? ''
			this.getNhanXetThang()
		},
		isLowScreen() {
			// headers tự re-compute khi isLowScreen đổi (computed dependency)
		},
		isReviewMode() {
			if (!this.ThangObj) return
			// Chỉ remount quill editors (không remount cả table)
			this.quillKey++
		},
	},

	methods: {
		// ─────────────────────────────────────────
		// Snackbar helpers (thay thế Vue.$toast)
		// ─────────────────────────────────────────
		$toast(type, message) {
			this.snackbarRef?.value?.showSnackbar({ type, message })
		},
		$toastPromise(promise, { loadingText, successText, errorPrefix } = {}) {
			this.snackbarRef?.value?.showPromise(promise, {
				loadingText: loadingText ?? 'Đang xử lý...',
				onSuccess: () => ({
					text: successText ?? 'Thành công!',
					color: 'success',
					prependIcon: 'mdi-check-circle-outline',
					timeout: 2000,
					timer: 'white',
				}),
				onError: (err) => ({
					text: `${errorPrefix ?? 'Lỗi'}: ${err?.message ?? 'Không xác định'}`,
					color: 'error',
					prependIcon: 'mdi-alert-circle-outline',
					timeout: 5000,
					timer: 'white',
					reverseTimer: true,
				}),
			})
		},

		// ─────────────────────────────────────────
		// Fetch data
		// ─────────────────────────────────────────
		async getLop(forceRefresh = false) {
			this.DSLop = await fetchPromise('lms/Lop_Get_By_CapID', {
				CapID: vueData.CapID,
				NienKhoa: vueData.NienKhoa,
			}, { forceRefresh })
		},

		async getThang(forceRefresh = false) {
			this.DSThang = await fetchPromise('lms/NhanXetThang_Lop_Get_GV', {
				NienKhoa: vueData.NienKhoa,
				LopID: this.LopItem.LopID,
			}, { forceRefresh })

			const existThang = this.DSThang.find(
				x => x.Lop_NhanXetThangID === this.ThangObj?.Lop_NhanXetThangID
			)
			if (existThang) this.ThangObj = { ...existThang }
		},

		async getNhanXetThang(forceRefresh = false) {
			this.keyTable +=1
			this.items = await fetchPromise('lms/NhanXetThang_Get', {
				Lop_NhanXetThangID: this.ThangObj.Lop_NhanXetThangID,
				LopID: this.LopItem.LopID,
				NienKhoa: vueData.NienKhoa,
			}, { forceRefresh: true })

			await this.convertItems()
		},

		// ─────────────────────────────────────────
		// convertItems — gắn NgayNghi + gọi API 1 tổng hợp vi phạm
		// ─────────────────────────────────────────
		async convertItems() {
			this.viPhamDetailMap = {}
			this.viPhamLoadingMap = {}
			this.viPhamExpandedMap = {}
			this.mainLopHocID = null
			this.isLoadingViPham = true
			this.viPhamLoadingText = 'Đang tải tổng hợp vi phạm...'
			try {
				const { firstDay, lastDay } = this.getFirstAndLastDay(
					vueData.NienKhoa,
					this.ThangObj?.Thang
				)
				const { firstDay: viPhamFirstDay, lastDay: viPhamLastDay } = this.getViPhamDateRange(this.ThangObj)

				// Gắn NgayNghi từ DSChuyenCan_TreVang (được fetch cùng NhanXetThang_Get hoặc riêng)
				this.items = this.items.map(x => {
					const existDSTreVang = (vueData.DSChuyenCan_TreVang ?? [])
						.find(n => n.HocSinhID === x.HocSinhID)
					const dsNhom = (() => {
						try { return typeof x.DSNhom === 'string' ? JSON.parse(x.DSNhom) : (x.DSNhom ?? []) }
						catch { return [] }
					})()
					return {
						...x,
						firstDay,
						lastDay,
						LopID: this.LopItem.LopID,
						DSNhom: dsNhom,
						NgayNghi: {
							MonVang: existDSTreVang ? JSON.parse(existDSTreVang.MonVang) : [],
							TongSoTiet: existDSTreVang?.TongSoTiet || null,
						},
					}
				})

				const isGVCNThang5 = this.ThangObj?.Is_HienThiPhuHuynh === false && this.ThangObj?.Thang === 5

			if (!isGVCNThang5) {
				// Resolve LopHocID trong hệ quansinh (khác với LopItem.LopID của LMS)
				await this.getLopHocBackground()
				this.mainLopHocID = this.DSLopHoc.find(x => x.TenLop === this.LopItem.TenLop)?.LopHocID ?? null
				// Capture vào local var để tránh race condition khi user đổi tháng nhanh
				const lopHocID = this.mainLopHocID

				// API 1: lấy tổng hợp loại vi phạm theo lớp + tháng
				if (lopHocID) {
					try {
						this.DSTongHop_ViPham = await fetchPromise(
							'quansinh/LMS_SoDauBai_TongHopTheoLoaiViPham',
							{ TuNgay: viPhamFirstDay, DenNgay: viPhamLastDay, LopHocID: lopHocID },
							{ cache: false }
						) ?? []

						// API 2: eager-load chi tiết song song cho các loại có vi phạm
						const dsCoViPham = this.DSTongHop_ViPham.filter(x => x.SoLuong > 0)
						if (dsCoViPham.length > 0) {
							let done = 0
							const total = dsCoViPham.length
							this.viPhamLoadingText = `Đang tải chi tiết vi phạm (0/${total})...`
							await Promise.all(dsCoViPham.map(async lvp => {
								await this.loadViPhamDetail(lvp.LoaiViPham, lopHocID)
							}))
						}
					} catch {
						this.DSTongHop_ViPham = []
					}
				}

				// Nhóm học vi phạm (Cấp 2 & 3) — DSLopHoc đã có từ getLopHocBackground() ở trên
				if (vueData.CapID === 2 || vueData.CapID === 3) {
					this.items = this.items.map(item => ({
						...item,
						DSNhom: item.DSNhom.map(nhom => ({
							...nhom,
							LopHocID: this.DSLopHoc.find(x => x.TenLop === nhom.TenNhom)?.LopHocID ?? null,
						})),
					}))
					const uniqueLopHocIDs = [...new Set(
						this.items.flatMap(x => x.DSNhom.map(n => n.LopHocID)).filter(Boolean)
					)]
					if (uniqueLopHocIDs.length > 0) {
						this.viPhamLoadingText = `Đang tải vi phạm nhóm học (0/${uniqueLopHocIDs.length})...`
						await this.loadNhomViPham(uniqueLopHocIDs, viPhamFirstDay, viPhamLastDay, (done, total) => {
							this.viPhamLoadingText = `Đang tải vi phạm nhóm học (${done}/${total})...`
						})
					}
				}
			}
			} finally {
				this.isLoadingViPham = false
				this.viPhamLoadingText = ''
			}
			// Pre-compute RenderNhanXet (luôn có sẵn cho review mode, tránh race condition)
			this.buildRenderNhanXet()
		},

		// ─────────────────────────────────────────
		// Vi phạm — accordion per student
		// ─────────────────────────────────────────
		toggleViPhamExpand(hocSinhID, loaiViPham) {
			const key = hocSinhID + '_' + loaiViPham
			this.viPhamExpandedMap = { ...this.viPhamExpandedMap, [key]: !this.viPhamExpandedMap[key] }
		},

		// Trả về danh sách loại vi phạm + số lần vi phạm riêng của từng học sinh
		getViPhamCuaHocSinh(hocSinhID) {
			return this.DSTongHop_ViPham
				.filter(x => x.SoLuong > 0)
				.map(lvp => {
					const rows = (this.viPhamDetailMap[lvp.LoaiViPham] ?? [])
						.filter(x => x.HocSinhID === hocSinhID)
					const soLuong = lvp.LoaiViPham === 2
						? new Set(rows.map(r => r.Ngay)).size
						: rows.length
					return { ...lvp, SoLuong_HS: soLuong }
				})
				.filter(x => x.SoLuong_HS > 0)
		},

		async loadViPhamDetail(loaiViPham, lopHocID) {
			this.viPhamLoadingMap = { ...this.viPhamLoadingMap, [loaiViPham]: true }
			try {
				const { firstDay, lastDay } = this.getViPhamDateRange(this.ThangObj)
				const data = await fetchPromise(
					'quansinh/LMS_SoDauBai_TongHopTheoLoaiViPham_ChiTiet',
					{ TuNgay: firstDay, DenNgay: lastDay, LopHocID: lopHocID ?? this.mainLopHocID, LoaiViPham: loaiViPham },
					{ cache: false }
				)
				this.viPhamDetailMap = { ...this.viPhamDetailMap, [loaiViPham]: data ?? [] }
			} catch {
				this.viPhamDetailMap = { ...this.viPhamDetailMap, [loaiViPham]: [] }
			} finally {
				this.viPhamLoadingMap = { ...this.viPhamLoadingMap, [loaiViPham]: false }
			}
		},
		getViPhamChiTiet(hocSinhID, loaiViPham) {
			return (this.viPhamDetailMap[loaiViPham] ?? []).filter(x => x.HocSinhID === hocSinhID)
		},

		// ─────────────────────────────────────────
		// Background LopHocID lookup + nhóm vi phạm
		// ─────────────────────────────────────────
		async getLopHocBackground() {
			if (!this.LopItem) return
			// LopItem.KhoiID là số khối thực (1–12) từ LMS
			// Cần tìm KhoiID tương ứng trong hệ quansinh qua TenKhoi
			const khoiNum = this.DSLop.find(x => x.LopID === this.LopItem.LopID)?.KhoiID
			if (!khoiNum) return
			console.log("khoiNum", khoiNum)
			try {
				const dsKhoi = await fetchPromise('quansinh/Basic_KhoiSelectByNamHocID', {
					NamHocID: vueData.NienKhoa,
					DonViID: 1,
				})
				if (!dsKhoi?.length) return
				const matchedKhoi = dsKhoi.find(k => k.TenKhoi === 'Khối ' + khoiNum)
				if (!matchedKhoi) return
				this.DSLopHoc = await fetchPromise('quansinh/Basic_LopHocSelectByKhoiNamHocID', {
					NamHocID: vueData.NienKhoa,
					KhoiID: matchedKhoi.KhoiID,
				}) ?? []
			} catch {
				// non-critical, fail silently
			}
		},

		async loadNhomViPham(lopHocIDs, firstDay, lastDay, progressCallback = null) {
			this.DSTongHop_ViPham_Nhom = {}
			this.viPhamDetailMap_Nhom = {}
			this.viPhamLoadingMap_Nhom = {}
			this.viPhamExpandedMap_Nhom = {}
			let done = 0
			const total = lopHocIDs.length
			await Promise.all(lopHocIDs.map(async lopHocID => {
				try {
					const ds = await fetchPromise(
						'quansinh/LMS_SoDauBai_TongHopTheoLoaiViPham',
						{ TuNgay: firstDay, DenNgay: lastDay, LopHocID: lopHocID },
						{ cache: false }
					) ?? []
					this.DSTongHop_ViPham_Nhom = { ...this.DSTongHop_ViPham_Nhom, [lopHocID]: ds }
					const dsCoViPham = ds.filter(x => x.SoLuong > 0)
					if (dsCoViPham.length > 0) {
						await Promise.all(dsCoViPham.map(lvp => this.loadViPhamDetailNhom(lopHocID, lvp.LoaiViPham, firstDay, lastDay)))
					}
				} catch {
					this.DSTongHop_ViPham_Nhom = { ...this.DSTongHop_ViPham_Nhom, [lopHocID]: [] }
				} finally {
					done++
					if (progressCallback) progressCallback(done, total)
				}
			}))
		},

		async loadViPhamDetailNhom(lopHocID, loaiViPham, firstDay, lastDay) {
			const loadingKey = lopHocID + '_' + loaiViPham
			this.viPhamLoadingMap_Nhom = { ...this.viPhamLoadingMap_Nhom, [loadingKey]: true }
			try {
				const data = await fetchPromise(
					'quansinh/LMS_SoDauBai_TongHopTheoLoaiViPham_ChiTiet',
					{ TuNgay: firstDay, DenNgay: lastDay, LopHocID: lopHocID, LoaiViPham: loaiViPham },
					{ cache: false }
				)
				const prevNhom = this.viPhamDetailMap_Nhom[lopHocID] ?? {}
				this.viPhamDetailMap_Nhom = {
					...this.viPhamDetailMap_Nhom,
					[lopHocID]: { ...prevNhom, [loaiViPham]: data ?? [] },
				}
			} catch {
				const prevNhom = this.viPhamDetailMap_Nhom[lopHocID] ?? {}
				this.viPhamDetailMap_Nhom = {
					...this.viPhamDetailMap_Nhom,
					[lopHocID]: { ...prevNhom, [loaiViPham]: [] },
				}
			} finally {
				this.viPhamLoadingMap_Nhom = { ...this.viPhamLoadingMap_Nhom, [loadingKey]: false }
			}
		},

		getViPhamCuaHocSinhTrongNhom(hocSinhID, lopHocID) {
			const dsTongHop = this.DSTongHop_ViPham_Nhom[lopHocID] ?? []
			return dsTongHop
				.filter(x => x.SoLuong > 0)
				.map(lvp => {
					const rows = (this.viPhamDetailMap_Nhom[lopHocID]?.[lvp.LoaiViPham] ?? [])
						.filter(x => x.HocSinhID === hocSinhID)
					const soLuong = lvp.LoaiViPham === 2
						? new Set(rows.map(r => r.Ngay)).size
						: rows.length
					return { ...lvp, SoLuong_HS: soLuong }
				})
				.filter(x => x.SoLuong_HS > 0)
		},

		getViPhamChiTietNhom(hocSinhID, lopHocID, loaiViPham) {
			return (this.viPhamDetailMap_Nhom[lopHocID]?.[loaiViPham] ?? []).filter(x => x.HocSinhID === hocSinhID)
		},

		toggleViPhamExpandNhom(hocSinhID, lopHocID, loaiViPham) {
			const key = hocSinhID + '_' + lopHocID + '_' + loaiViPham
			this.viPhamExpandedMap_Nhom = { ...this.viPhamExpandedMap_Nhom, [key]: !this.viPhamExpandedMap_Nhom[key] }
		},

		tenViPhamVI(ten) {
			return (ten ?? '').split('/')[0].trim()
		},

		formatNgayViPham(ngay) {
			return ngay ? String(ngay).slice(0, 5) : ''
		},

		// ─────────────────────────────────────────
		// Helpers
		// ─────────────────────────────────────────
		getFirstAndLastDay(nienKhoa, month) {
			// Months 1–8 fall in the second calendar year of the academic year (e.g. NienKhoa 2024 → 2025)
			// Months 9–12 fall in the first calendar year (e.g. NienKhoa 2024 → 2024)
			const year = month >= 9 ? parseInt(nienKhoa) : parseInt(nienKhoa) + 1
			const firstDay = dayjs(`${year}-${month}-01`).startOf('month').format('YYYY-MM-DD')
			const lastDay = dayjs(`${year}-${month}-01`).endOf('month').format('YYYY-MM-DD')
			return { firstDay, lastDay }
		},

		// Tháng 1: TuNgay = NienKhoa-09-05; Tháng 5: TuNgay = (NienKhoa+1)-01-01
		getViPhamDateRange(thangObj) {
			if (thangObj?.Thang === 1) {
				const firstDay = dayjs(`${parseInt(vueData.NienKhoa)}-09-05`).format('YYYY-MM-DD')
				const lastDay = dayjs(`${thangObj.Nam}-${thangObj.Thang}-01`).endOf('month').format('YYYY-MM-DD')
				return { firstDay, lastDay }
			}
			if (thangObj?.Thang === 5) {
				const firstDay = dayjs(`${parseInt(vueData.NienKhoa) + 1}-01-01`).format('YYYY-MM-DD')
				const lastDay = dayjs(`${thangObj.Nam}-${thangObj.Thang}-01`).endOf('month').format('YYYY-MM-DD')
				return { firstDay, lastDay }
			}
			return this.getFirstAndLastDay(vueData.NienKhoa, thangObj?.Thang)
		},

		validateNhanXetGVCN(itemsToCheck) {
			const MAX = 500
			const overLimit = itemsToCheck.filter(item => item.NhanXetGVCN && item.NhanXetGVCN.length > MAX)
			if (overLimit.length > 0) {
				const names = overLimit.map(item => `<b>${item.HoTen}</b> (${item.NhanXetGVCN.length} ký tự)`).join(', ')
				this.$toast('warning', `Nhận xét ghi học bạ vượt quá 500 ký tự: ${names}. Vui lòng chỉnh lại trước khi lưu.`)
				return false
			}
			return true
		},

		buildSavePayload() {
			return this.items.map(item => ({
				...item,
				LopID: this.LopItem.LopID,
				Lop_NhanXetThangID: this.ThangObj.Lop_NhanXetThangID,
				Is_Reject: false,
				DKHocTiep: item.DKHocTiep ?? false,
			}))
		},

		// ─────────────────────────────────────────
		// Actions
		// ─────────────────────────────────────────
		onRefresh() {
			this.getNhanXetThang(true)
		},

		onImport() {
			if (!this.LopItem) {
				this.$toast('error', 'Vui lòng chọn lớp')
				return
			}
			if (!this.ThangObj) {
				this.$toast('error', 'Vui lòng chọn tháng')
				return
			}
			this.iframeRef.value.openWindow({
				title: 'Import Excel nhận xét tháng',
				icon: 'mdi-file-excel',
				url: `/gv-nhan-xet-thang-import?lopid=${this.LopItem.LopID}&lop_nxtid=${this.ThangObj.Lop_NhanXetThangID}&nienkhoa=${vueData.NienKhoa}`,
				onclose: () => {
					if (JSON.parse(localStorage.getItem('IsImportNXT'))) {
						localStorage.removeItem('IsImportNXT')
						this.getThang(true)
						this.getNhanXetThang(true)
					}
				},
			})
		},

		async onSave() {
			if (!this.validateNhanXetGVCN(this.items)) return
			const ok = await this.confirmRef.value.show({ title: 'Xác nhận lưu tạm tất cả nhận xét tháng?' })
			if (!ok) return

			const JSON_NhanXetThang = this.buildSavePayload()
			console.log("JSON_NhanXetThang", JSON_NhanXetThang)
			const promise = fetchPromise('lms/NhanXetThang_Ins', { JSON_NhanXetThang }, {forceRefresh: true})
				.then(() => fetchPromise('lms/NhanXetThang_Upd_TinhTrang', {
					TinhTrang: 1,
					Lop_NhanXetThangID: this.ThangObj.Lop_NhanXetThangID,
					ReasonReject: '',
				}, {forceRefresh: true}))
				.then(() => {
					this.getThang(true)
				})
			this.$toastPromise(promise, {
				loadingText: 'Đang lưu tạm tất cả...',
				successText: 'Lưu tạm tất cả nhận xét tháng thành công',
				errorPrefix: 'Lưu thất bại',
			})
		},

		renderTextDSHocSinhDaLuu() {
			let count = 0
			for (const item of this.items) {
				if (item.NhanXetThangID > 0) count++
			}
			return count
		},

		// ─────────────────────────────────────────
		// Review mode: gộp các cột nhận xét thành RenderNhanXet
		// ─────────────────────────────────────────
		buildRenderNhanXet() {
			function convertNewLineToP(text) {
				if (!text) return ''
				return text.split(/\n+/).map(line => `<p>${line}</p>`).join('')
			}
			this.items = this.items.map(x => {
				let RenderNhanXet = ''
				if (vueData.CapID === 1) {
					RenderNhanXet = [
						x.NhanXetToan_HTML ? `<b>Môn Toán${x.DiemToan ? ' (' + x.DiemToan + 'đ)' : ''}: </b>` + x.NhanXetToan_HTML + '<br/>' : '',
						x.NhanXetTiengViet_HTML ? `<b>Tiếng Việt${x.DiemTiengViet ? ' (' + x.DiemTiengViet + 'đ)' : ''}: </b>` + x.NhanXetTiengViet_HTML + '<br/>' : '',
						x.NhanXetMonHocKhac_HTML ? '<b>Môn học khác: </b>' + x.NhanXetMonHocKhac_HTML + '<br/>' : '',
						x.HoatDongGiaoDucKhac_HTML ? '<b>Hoạt động GD khác: </b>' + x.HoatDongGiaoDucKhac_HTML + '<br/>' : '',
						x.PhamChatNangLuc_HTML ? '<b>Phẩm chất - Năng lực: </b>' + x.PhamChatNangLuc_HTML + '<br/>' : '',
					].join('')
				} else {
					const isCuoiKi = [12, 5].includes(x.Thang ?? this.ThangObj?.Thang)
					if (isCuoiKi) {
						RenderNhanXet = [
							x.UuDiem ? ('<b>Ưu điểm: </b>' + convertNewLineToP(x.UuDiem) + '<br/>') : '<b>Ưu điểm: - </b><br/>',
							x.NhuocDiem ? ('<b>Nhược điểm: </b>' + convertNewLineToP(x.NhuocDiem) + '<br/>') : '<b>Nhược điểm: - </b><br/>',
							x.DeXuat ? ('<b>Đề xuất: </b>' + convertNewLineToP(x.DeXuat) + '<br/>') : '<b>Đề xuất: - </b><br/>',
							x.NhanXetGVCN ? ('<b>Nhận xét học bạ: </b>' + convertNewLineToP(x.NhanXetGVCN) + '<br/>') : '',
						].join('')
					} else {
						RenderNhanXet = (
							(x.NoiDungKienThuc_HTML ? ('<b>Học tập: </b>' + convertNewLineToP(x.NoiDungKienThuc_HTML) + '<br/>') : '<b>Học tập: - </b><br/>')
							+ (x.NoiDungNangLuc_HTML ? ('<b>Nền nếp: </b>' + convertNewLineToP(x.NoiDungNangLuc_HTML) + '<br/>') : '<b>Nền nếp: - </b><br/>')
							+ (x.NoiDungHoatDongKhac_HTML ? ('<b>Mong muốn phối hợp: </b>' + convertNewLineToP(x.NoiDungHoatDongKhac_HTML) + '<br/>') : '<b>Mong muốn phối hợp: - </b><br/>')
						)
					}
				}
				return { ...x, RenderNhanXet }
			})
		},

		onSendToTruong() {
			if (this.renderTextDSHocSinhDaLuu() !== this.items.length) {
				this.$toast('warning', 'Vui lòng lưu hết tất cả học sinh trước khi gửi tổ trưởng')
				return
			}
			const promise = fetchPromise('lms/NhanXetThang_Upd_TinhTrang', {
				TinhTrang: 2,
				Lop_NhanXetThangID: this.ThangObj.Lop_NhanXetThangID,
				ReasonReject: '',
			}, {forceRefresh: true})
			this.$toastPromise(promise, {
				successText: 'Gửi tổ trưởng thành công',
			})
			promise.then(() => {
				this.getThang(true)
				this.getNhanXetThang(true)
			})
		},

		onSendToBGH() {
			if (this.renderTextDSHocSinhDaLuu() !== this.items.length) {
				this.$toast('warning', 'Vui lòng lưu hết tất cả học sinh trước khi gửi')
				return
			}
			this.confirmRef.value.show({ title: 'Xác nhận gửi nhận xét tháng lên BGH?' }).then(ok => {
				if (!ok) return
			const promise = fetchPromise('lms/NhanXetThang_Upd_TinhTrang', {
				TinhTrang: 2,
				Lop_NhanXetThangID: this.ThangObj.Lop_NhanXetThangID,
				ReasonReject: '',
			}, {forceRefresh: true})
			this.$toastPromise(promise, {
				successText: 'Gửi BGH thành công',
			})
			promise.then(() => {
				this.getThang(true)
				this.getNhanXetThang(true)
			})
			})
		},

		onUpdateTinhTrang() {
			if (!this.ThangObj) return
			const reason = this.TinhTrangNew === 3 ? (this.ReasonRejectNew ?? '') : ''
			const promise = fetchPromise('lms/NhanXetThang_Upd_TinhTrang', {
				TinhTrang: this.TinhTrangNew,
				Lop_NhanXetThangID: this.ThangObj.Lop_NhanXetThangID,
				ReasonReject: reason,
			}, { forceRefresh: true })
			this.$toastPromise(promise, {
				loadingText: 'Đang cập nhật trạng thái...',
				successText: 'Cập nhật trạng thái thành công',
				errorPrefix: 'Cập nhật thất bại',
			})
			promise.then(() => {
				this.IsShowDialogTinhTrang = false
				this.getThang(true)
				this.getNhanXetThang(true)
			})
		},

		onConfirmCopy() {
			if (!this.ThangObj_Copy) {
				this.$toast('warning', 'Vui lòng chọn tháng sao chép')
				return
			}
			const promise = fetchPromise('lms/NhanXetThang_Copy', {
				Lop_NhanXetThangID: this.ThangObj.Lop_NhanXetThangID,
				Lop_NhanXetThangID_Copy: this.ThangObj_Copy.Lop_NhanXetThangID,
			}, {forceRefresh: true})
			this.$toastPromise(promise, {
				successText: 'Sao chép thành công',
			})
			promise.then(() => {
				this.IsShowDialogCopy = false
				this.getNhanXetThang(true)
			})
		},

		// ─────────────────────────────────────────
		// renderHeader — đầy đủ logic GVCN / PhuHuynh view / Review mode
		// ─────────────────────────────────────────
		renderHeader() {
			const H_HocSinh = {
				title: this.isEn ? 'Student' : 'Học sinh', value: 'HocSinh',
				align: 'center', minWidth: 180, width: 180, fixed: true,
			}

			let headers = [H_HocSinh]

			// ── Chế độ xem lại (review mode) ──
			if (this.isReviewMode) {
				if (vueData.CapID === 1) {
					headers.push({
						title: this.isEn ? 'Summary comment' : 'Nhận xét tổng hợp',
						value: 'RenderNhanXet',
						align: 'center',
						minWidth: 500,
					})
				} else if (vueData.CapID === 2 || vueData.CapID === 3) {
					headers.push({
						title: this.isEn ? 'Absences / Violations' : 'Ngày nghỉ / Vi phạm',
						value: 'NgayNghi',
						align: 'center',
						width: 220,
					})
					if (this.isCuoiKi) {
						headers.push({
							title: this.isEn ? 'Summary comment' : 'Nhận xét tổng hợp',
							value: 'RenderNhanXet',
							align: 'center',
							minWidth: 400,
						})
					} else {
						headers.push({
							title: this.isEn ? 'Summary comment' : 'Nhận xét tổng hợp',
							value: 'RenderNhanXet',
							align: 'center',
							minWidth: 350,
						})
					}
				}
				// Không hiện nút Lưu tạm khi xem lại
				return headers
			}

			// ── Chế độ GVCN nhập liệu (Is_HienThiPhuHuynh = false) ──
			if (!this.ThangObj?.Is_HienThiPhuHuynh) {
				headers.push({
					title: this.isEn ? 'Coordination & Info' : 'Phối hợp & Thông tin',
					value: 'gvcn_extra',
					align: 'center',
					width: 250,
				})
				headers.push({
					title: this.isEn ? "Teacher's comment on Parent" : 'Nhận xét về Phụ huynh',
					value: 'NhanXetGVCN_VePhuHuynh_HTML',
					align: 'center',
					width: 280,
				})
				headers.push({
					title: this.isEn ? "Teacher's comment on Student" : 'Nhận xét về Học sinh',
					value: 'NhanXetGVCN_VeHocSinh_HTML',
					align: 'center',
					width: 280,
				})
				if (this.ThangObj?.Thang === 5) {
					headers.push({
						title: this.isEn ? 'Next school year prep notes' : 'Nhận xét chuẩn bị niên khóa sau',
						value: 'NhanXet_ChuanBiNienKhoaSau',
						align: 'center',
						minWidth: 220,
					})
				}

				// ── Chế độ hiển thị cho Phụ huynh ──
			} else {

				// Cấp 1
				if (vueData.CapID === 1) {
					headers = [
						...headers,
						{ title: this.isEn ? 'Math comment' : 'Nhận xét môn Toán', value: 'NhanXetToan_HTML', align: 'center', minWidth: 280, width: 280 },
						{ title: this.isEn ? 'Vietnamese comment' : 'Nhận xét môn Tiếng Việt', value: 'NhanXetTiengViet_HTML', align: 'center', minWidth: 280, width: 280 },
						{ title: this.isEn ? 'Other subjects comment' : 'Nhận xét môn học khác', value: 'NhanXetMonHocKhac_HTML', align: 'center', minWidth: 280, width: 280 },
						{ title: this.isEn ? 'Other educational activities' : 'Hoạt động giáo dục khác', value: 'HoatDongGiaoDucKhac_HTML', align: 'center', minWidth: 280, width: 280 },
						{ title: this.isEn ? 'Qualities & Competencies' : 'Phẩm chất - Năng lực', value: 'PhamChatNangLuc_HTML', align: 'center', minWidth: 280, width: 280 },
					]

					// Cấp 2 & 3
				} else if (vueData.CapID === 2 || vueData.CapID === 3) {
					headers.push({
						title: this.isEn ? 'Absences / Violations' : 'Ngày nghỉ / Vi phạm',
						value: 'NgayNghi',
						align: 'center',
						width: 220,
					})

					if (this.isCuoiKi) {
						headers = [
							...headers,
							{ title: this.isEn ? 'Strengths' : 'Ưu điểm', value: 'UuDiem', align: 'center', minWidth: 200 },
							{ title: this.isEn ? 'Weaknesses' : 'Nhược điểm', value: 'NhuocDiem', align: 'center', minWidth: 200 },
							{ title: this.isEn ? 'Recommendations' : 'Đề xuất', value: 'DeXuat', align: 'center', minWidth: 200 },
							...(this.ThangObj?.Thang === 5
								? [{ title: this.isEn ? 'Report card comment' : 'Nhận xét ghi học bạ', value: 'NhanXetGVCN', align: 'center', minWidth: 200 }]
								: []),
						]
					} else {
						headers = [
							...headers,
							{ title: this.isEn ? 'Academic performance' : 'Về học tập', value: 'NoiDungKienThuc_HTML', align: 'center', minWidth: 220 },
							{ title: this.isEn ? 'Discipline & Conduct' : 'Về nền nếp', value: 'NoiDungNangLuc_HTML', align: 'center', minWidth: 220 },
							{ title: this.isEn ? 'Desired coordination' : 'Mong muốn phối hợp', value: 'NoiDungHoatDongKhac_HTML', align: 'center', minWidth: 220 },
						]
					}
				}
			}

			return headers
		},

		async onExportPDF() {
			if (!this.items.length) return
			if (typeof pdfMake === 'undefined') {
				this.$toast('error', 'Không tải được thư viện xuất PDF. Vui lòng thử lại.')
				return
			}
			this.isExportingPdf = true
			try {
				const logoUrl = window.location.origin + '/_cdn/lhbs-lms/logo_lhbs_2.jpg'
				const logoBase64 = await this.getBase64FromUrl(logoUrl)
				const lopItem = this.LopItem
				const content = []
				for (const item of this.items) {
					const IMG = { image: 'logo', width: 64, height: 64 }
					const PROFILE = {
						text: [
							'Học sinh: ',
							{ text: item.HoTen + '\t\t\t', bold: true, margin: [0, 0, 20, 0] },
							'Lớp: ',
							{ text: lopItem?.TenLop, bold: true }
						],
						alignment: 'center', fontSize: 14, margin: [0, 20, 0, 0]
					}
					const HEADER = { alignment: 'center', columns: [IMG, PROFILE] }
					const TITLE = {
						text: ['THÔNG TIN VỀ HỌC TẬP VÀ RÈN LUYỆN \n', { text: 'THÁNG ' + this.ThangObj?.Thang }],
						bold: true, fontSize: 20, alignment: 'center', margin: [0, 10, 0, 10]
					}
					const pageBreak = { text: '', fontSize: 14, bold: true, pageBreak: 'before', margin: [0, 0, 0, 8] }
					const margins = { text: '', fontSize: 14, bold: true, margin: [0, 0, 0, 12] }
					const SIGNATURE = {
						table: {
							widths: ['*', 150],
							body: [
								['', { text: 'Giáo viên chủ nhiệm', alignment: 'center' }],
								['', { text: lopItem?.Ten_GVCN, bold: true, alignment: 'center' }]
							]
						},
						layout: { defaultBorder: false }
					}
					const TITLE_SUBJECT_TOAN = [{ text: 'Môn Toán', border: [true, true, true, true], bold: true }]
					const TITLE_SUBJECT_TIENG_VIET = [{ text: 'Môn Tiếng Việt', border: [true, true, true, true], bold: true }]
					const TITLE_SUBJECT_KHAC = [{ text: 'Môn học khác', border: [true, true, true, true], bold: true }]
					const TITLE_HD_GD_KHAC = [{ text: 'Hoạt động giáo dục khác', border: [true, true, true, true], bold: true }]
					const TITLE_PC_NL = [{ text: 'Phẩm chất - Năng lực', border: [true, true, true, true], bold: true }]
					const TITLE_EMPTY = { text: '', border: [false, false, false, false] }
					const CONTENT_SUBJECT_TOAN = [{ text: item.NhanXetToan_HTML, alignment: 'justify', border: [true, false, true, true] }]
					const CONTENT_SUBJECT_TIENG_VIET = [{ text: item.NhanXetTiengViet_HTML, alignment: 'justify', border: [true, false, true, true] }]
					const CONTENT_SUBJECT_MON_HOC_KHAC = [{ text: item.NhanXetMonHocKhac_HTML, alignment: 'justify', border: [true, false, true, true] }]
					const CONTENT_SUBJECT_HD_GD_KHAC = [{ text: item.HoatDongGiaoDucKhac_HTML, alignment: 'justify', border: [true, false, true, true] }]
					const CONTENT_SUBJECT_PC_NL = [{ text: item.PhamChatNangLuc_HTML, border: [true, false, true, true] }]
					const STAR_SUBJECT_TOAN = { text: ['Sản phẩm\n học tập \n\n', { text: item.SoSao_Toan }], alignment: 'center', border: [false, true, true, true] }
					const STAR_SUBJECT_TIENG_VIET = { text: ['Sản phẩm\n học tập \n\n', { text: item.SoSao_TiengViet }], alignment: 'center', border: [false, true, true, true] }
					const CONTENT_WIDTH = 515
					const toan_widths = Number(item.DiemToan ?? 0) > 0 ? [CONTENT_WIDTH * 0.8, CONTENT_WIDTH * 0.2] : ['*']
					const tieng_viet_widths = Number(item.DiemTiengViet ?? 0) > 0 ? [CONTENT_WIDTH * 0.8, CONTENT_WIDTH * 0.2] : ['*']
					if (Number(item.DiemToan ?? 0) > 0) {
						TITLE_SUBJECT_TOAN.push(TITLE_EMPTY)
						CONTENT_SUBJECT_TOAN.push(STAR_SUBJECT_TOAN)
					}
					if (Number(item.DiemTiengViet ?? 0) > 0) {
						TITLE_SUBJECT_TIENG_VIET.push(TITLE_EMPTY)
						CONTENT_SUBJECT_TIENG_VIET.push(STAR_SUBJECT_TIENG_VIET)
					}
					const TABLE_CONTENT_TOAN = { table: { widths: toan_widths, body: [TITLE_SUBJECT_TOAN, CONTENT_SUBJECT_TOAN] }, layout: { defaultBorder: false } }
					const TABLE_CONTENT_TIENG_VIET = { table: { widths: tieng_viet_widths, body: [TITLE_SUBJECT_TIENG_VIET, CONTENT_SUBJECT_TIENG_VIET] }, layout: { defaultBorder: false } }
					const TABLE_CONTENT_MON_HOC_KHAC = { table: { widths: ['*'], body: [TITLE_SUBJECT_KHAC, CONTENT_SUBJECT_MON_HOC_KHAC] }, layout: { defaultBorder: false } }
					const TABLE_CONTENT_HD_GD_KHAC = { table: { widths: ['*'], body: [TITLE_HD_GD_KHAC, CONTENT_SUBJECT_HD_GD_KHAC] }, layout: { defaultBorder: false } }
					const TABLE_CONTENT_PC_NL = { table: { widths: ['*'], body: [TITLE_PC_NL, CONTENT_SUBJECT_PC_NL] }, layout: { defaultBorder: false } }
					content.push(HEADER)
					content.push(TITLE)
					content.push(TABLE_CONTENT_TOAN)
					content.push(margins)
					content.push(TABLE_CONTENT_TIENG_VIET)
					content.push(margins)
					content.push(TABLE_CONTENT_MON_HOC_KHAC)
					content.push(margins)
					content.push(TABLE_CONTENT_HD_GD_KHAC)
					content.push(margins)
					content.push(TABLE_CONTENT_PC_NL)
					content.push(margins)
					content.push(SIGNATURE)
					content.push(pageBreak)
				}
				const dd = {
					pageSize: 'A4',
					content: content.slice(0, -1),
					images: { logo: logoBase64 },
					styles: {},
					defaultStyle: { fontSize: 12 }
				}
				const pdf = pdfMake.createPdf(dd)
				pdf.print()
			} finally {
				this.isExportingPdf = false
			}
		},
		async getBase64FromUrl(url) {
			const data = await fetch(url)
			const blob = await data.blob()
			return new Promise((resolve, reject) => {
				const reader = new FileReader()
				reader.readAsDataURL(blob)
				reader.onloadend = () => resolve(reader.result)
				reader.onerror = reject
			})
		},

		async onExportExcel(exportType = 'class') {
			if (!this.items.length) return
			if (!window.XLSX) {
				const promise = new Promise((resolve) => {
					const s = document.createElement('script')
					s.src = 'https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js'
					s.onload = () => resolve(window.XLSX)
					document.head.appendChild(s)
				})
				await promise
			}
			const XLSX = window.XLSX

			const exportHeaders = ['Mã học sinh', 'Số danh bộ', 'Họ tên']
			const exportKeys = ['HocSinhID', 'SoDanhBo', 'HoTen']

			const renderHeader = this.renderHeader()
			for (const h of renderHeader) {
				const key = h.value || h.key
				if (key === 'HocSinh' || key === 'hocSinh') {
					continue
				}
				if (key === 'gvcn_extra') {
					exportHeaders.push('Phối hợp CMHS')
					exportKeys.push('PhoiHopCMHS')
					if (!this.isKhoiCanLoai) {
						exportHeaders.push('Phân loại tuyển thẳng')
						exportKeys.push('PhanLoai_TuyenThang')
						exportHeaders.push('Flyers')
						exportKeys.push('Flyers')
						exportHeaders.push('Điểm Tiếng Anh')
						exportKeys.push('DiemTA')
						exportHeaders.push('Đăng ký học tiếp')
						exportKeys.push('DKHocTiep_Display')
						exportHeaders.push('Đề xuất / ND cam kết')
						exportKeys.push('DeXuat_NDCamKet')
					}
					continue
				}
				if (key === 'NgayNghi') {
					exportHeaders.push('Ngày nghỉ / Vi phạm')
					exportKeys.push('NgayNghi_Display')
					continue
				}
				if (key === 'NhanXetToan_HTML') {
					exportHeaders.push(h.title)
					exportKeys.push('NhanXetToan_HTML_Strip')
					exportHeaders.push('Điểm Toán')
					exportKeys.push('DiemToan')
					continue
				}
				if (key === 'NhanXetTiengViet_HTML') {
					exportHeaders.push(h.title)
					exportKeys.push('NhanXetTiengViet_HTML_Strip')
					exportHeaders.push('Điểm Tiếng Việt')
					exportKeys.push('DiemTiengViet')
					continue
				}

				exportHeaders.push(h.title)
				exportKeys.push(key)
			}

			const mapItemsToRows = (itemsList) => {
				return itemsList.map(item => {
					if (!item.NgayNghi) {
						const existDSTreVang = (vueData.DSChuyenCan_TreVang ?? []).find(n => n.HocSinhID === item.HocSinhID)
						item.NgayNghi = {
							MonVang: existDSTreVang ? JSON.parse(existDSTreVang.MonVang) : [],
							TongSoTiet: existDSTreVang?.TongSoTiet || null,
						}
					}
					return exportKeys.map(key => {
						if (key === 'DKHocTiep_Display') {
							return item.DKHocTiep ? 'Đăng ký học tiếp' : 'Không'
						}
						if (key === 'NgayNghi_Display') {
							let lines = []
							if (item.NgayNghi?.TongSoTiet > 0) {
								lines.push(`Tổng số tiết vắng: ${item.NgayNghi.TongSoTiet}`)
							}
							if (item.NgayNghi?.MonVang?.length > 0) {
								const monVangStr = item.NgayNghi.MonVang.map(m => m.TenMonHoc).join(', ')
								lines.push(`Môn vắng: ${monVangStr}`)
							}
							if (typeof this.getViPhamCuaHocSinh === 'function') {
								const vps = this.getViPhamCuaHocSinh(item.HocSinhID)
								if (vps && vps.length > 0) {
									vps.forEach(vp => {
										const unit = vp.LoaiViPham === 2 ? 'ngày' : 'tiết'
										lines.push(`${this.tenViPhamVI(vp.TenViPham)} (${vp.SoLuong_HS} ${unit})`)
									})
								}
							}
							return lines.join('\n')
						}
						if (key === 'NhanXetToan_HTML_Strip') {
							return this.stripHtml(item.NhanXetToan_HTML)
						}
						if (key === 'NhanXetTiengViet_HTML_Strip') {
							return this.stripHtml(item.NhanXetTiengViet_HTML)
						}
						const val = item[key]
						if (typeof val === 'string' && (val.includes('<') || val.includes('>'))) {
							return this.stripHtml(val)
						}
						return val ?? ''
					})
				})
			}

			const workbook = XLSX.utils.book_new()

			if (exportType === 'grade') {
				const currentLop = this.DSLop.find(x => x.LopID === (this.LopItem?.LopID || this.LopID))
				if (!currentLop) return
				const targetKhoiID = currentLop.KhoiID
				const classesInGrade = this.DSLop.filter(x => x.KhoiID === targetKhoiID)

				// Eager load month list in parallel
				const monthPromises = classesInGrade.map(async (cls) => {
					const thangList = await fetchPromise('lms/NhanXetThang_Lop_Get_GV', {
						NienKhoa: vueData.NienKhoa,
						LopID: cls.LopID,
					})
					const match = thangList?.find(t => t.Thang === this.ThangObj.Thang)
					return {
						class: cls,
						lopNhanXetThangID: match?.Lop_NhanXetThangID
					}
				})
				const resolvedMonths = await Promise.all(monthPromises)

				// Eager load comments in parallel
				const commentPromises = resolvedMonths
					.filter(m => m.lopNhanXetThangID)
					.map(async (m) => {
						const items = await fetchPromise('lms/NhanXetThang_Get', {
							Lop_NhanXetThangID: m.lopNhanXetThangID,
							LopID: m.class.LopID,
							NienKhoa: vueData.NienKhoa,
						})
						return {
							className: m.class.TenLop,
							items: items || []
						}
					})
				const classComments = await Promise.all(commentPromises)

				classComments.forEach(cc => {
					if (cc.items.length) {
						const rows = mapItemsToRows(cc.items)
						const worksheet = XLSX.utils.aoa_to_sheet([exportHeaders, ...rows])
						XLSX.utils.book_append_sheet(workbook, worksheet, cc.className)
					}
				})

				const fileName = `NhanXetThang_Khoi_${currentLop.KhoiID}_Thang_${this.ThangObj?.Thang || ''}.xlsx`
				XLSX.writeFile(workbook, fileName)
			} else {
				const rows = mapItemsToRows(this.items)
				const worksheet = XLSX.utils.aoa_to_sheet([exportHeaders, ...rows])
				XLSX.utils.book_append_sheet(workbook, worksheet, this.LopItem?.TenLop || 'NhanXetThang')
				const fileName = `NhanXetThang_${this.LopItem?.TenLop || 'Lop'}_Thang_${this.ThangObj?.Thang || 'Thang'}.xlsx`
				XLSX.writeFile(workbook, fileName)
			}
		},

		stripHtml(html) {
			if (!html) return ''
			const temp = document.createElement('div')
			temp.innerHTML = html
			return temp.textContent || temp.innerText || ''
		},
		setLanguage(isEn) {
			this.isEn = isEn
			localStorage.setItem('IsLanguage', isEn)
			if (window.$i18n) {
				window.$i18n.locale = isEn ? 'en' : 'vi'
			}
		},
		formatThangHienThi(item) {
			if (!item) return ''
			const str = typeof item === 'object' ? item.Thang_HienThi : item
			if (!str) return ''
			if (!this.isEn) return str
			return str.replace(/Tháng/g, 'Month').replace(/Tuần/g, 'Week')
		},
		formatTinhTrang(statusStr) {
			if (!statusStr) return ''
			if (!this.isEn) return statusStr
			const map = {
				'Chưa lưu': 'Not saved',
				'Lưu tạm': 'Draft saved',
				'Gửi tổ trưởng': 'Submitted to lead',
				'Gửi BGH': 'Submitted to principal',
				'Đã gửi': 'Submitted',
				'Từ chối': 'Rejected',
				'Duyệt': 'Approved',
				'Đã duyệt': 'Approved'
			}
			return map[statusStr] || statusStr
		},
	},
	}
</script>