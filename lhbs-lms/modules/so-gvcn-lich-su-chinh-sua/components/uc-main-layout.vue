<template>
	<Global style="height: 100dvh; max-height: 100dvh; width: 100%; display: flex; flex-direction: column; overflow: hidden; box-sizing: border-box;">
		<template #header>
			<v-card class="elevation-1 mb-2">
				<v-card-title class="d-flex align-center flex-wrap ga-2 py-2">
					<v-icon color="primary" class="mr-1">mdi-history</v-icon>
					<span class="font-weight-bold text-subtitle-1 text-md-h6 text-primary">Lịch sử chỉnh sửa Sổ GVCN</span>
					<v-chip color="primary" variant="tonal" size="small" class="font-weight-medium">Niên khóa {{ currentNienKhoa }}</v-chip>
					<v-chip v-if="selectedLopObj" color="success" variant="tonal" size="small" class="font-weight-medium">
						Lớp {{ selectedLopObj.TenLop }} ({{ isCap1 ? 'Tiểu học' : (selectedClassCapID === 2 ? 'THCS' : 'THPT') }})
					</v-chip>
				</v-card-title>
				<v-divider />
				<!-- Bộ lọc dùng chung một khoảng ngày để khớp với các màn hình báo cáo của LMS. -->
				<v-card-text class="py-2">
					<v-row dense align="center">
						<!-- Lớp đã có sẵn Khối/CapID từ API; hiển thị trực tiếp trong option để tránh bắt người dùng chọn hai lần. -->
						<v-col cols="12" sm="6" md="4">
							<v-select v-model="selectedLopID" :items="danhSachLopOptions" item-title="TenLopDisplay" item-value="LopID"
								label="Lớp" density="compact" variant="outlined" hide-details :loading="isFilterLoading"
								placeholder="Chọn lớp" :no-data-text="isFilterLoading ? 'Đang tải danh sách lớp...' : 'Chưa có dữ liệu lớp'"
								@update:model-value="fetchLichSuTongHop" />
						</v-col>
						<!-- Khoảng ngày và nhóm thao tác dùng độ rộng theo nội dung để nút/badge nằm sát bộ lọc. -->
						<v-col cols="12" sm="6" md="auto">
							<uc-date-range-picker v-model="filterDateRange" :NienKhoa="currentNienKhoa" />
						</v-col>
						<!-- Số tổng là số bản ghi log; snapshot nhận xét được lưu theo từng học sinh nên không đồng nhất với số lần bấm Lưu. -->
						<v-col cols="12" sm="12" md="auto" class="history-filter-actions d-flex align-center justify-start ga-2 flex-wrap">
							<v-btn color="primary" variant="flat" class="history-refresh-btn" :loading="isLoading" @click="fetchLichSuTongHop">
								<v-icon start size="18">mdi-refresh</v-icon>LÀM MỚI
							</v-btn>
							<v-chip v-if="tongSoLanSua > 0" color="primary" variant="tonal" size="small" class="history-total-chip font-weight-medium">
								<v-icon start size="15">mdi-counter</v-icon>
								Tổng <b class="history-total-count">{{ tongSoLanSua }}</b> bản ghi
							</v-chip>
						</v-col>
							</v-row>
							<v-alert v-if="errorMessage" type="error" variant="tonal" density="compact" class="mt-2 mb-0">
								{{ errorMessage }}
							</v-alert>
						</v-card-text>
			</v-card>
		</template>

		<!-- Global bọc nội dung trong v-container nên flex-grow không làm vùng này tự cuộn; dùng chiều cao viewport rõ ràng để bảng luôn có scrollbar. -->
		<div class="pa-2" style="height: calc(100dvh - 115px); max-height: calc(100dvh - 115px); overflow-y: auto; overflow-x: hidden; box-sizing: border-box;">
			<template v-if="isLoading || isFilterLoading">
				<v-skeleton-loader type="table-heading, list-item-three-line@3" class="elevation-1 rounded" />
			</template>
			<!-- Không có lớp thì không dựng tab mặc định, tránh khiến người dùng tưởng dữ liệu đang là của tất cả lớp. -->
			<template v-else-if="!selectedLopID">
				<v-card class="elevation-1 rounded pa-8 text-center text-medium-emphasis">
					<v-icon size="42" color="grey">mdi-school-outline</v-icon>
					<div class="mt-3">Chưa tìm thấy lớp có dữ liệu lịch sử chỉnh sửa.</div>
				</v-card>
			</template>
			<template v-else>
				<!-- Các tab luôn hiện đủ để giáo viên biết toàn bộ cấu trúc của Sổ GVCN. -->
				<v-expansion-panels v-model="openedPanels" multiple class="elevation-1 rounded">
					<v-expansion-panel v-for="tab in allDisplayTabs" :key="tab.MaTab" class="mb-2 border rounded">
						<v-expansion-panel-title class="py-3 px-4">
							<div class="d-flex align-center justify-space-between w-100 pr-2">
								<div class="d-flex align-center ga-2">
									<v-avatar size="32" :color="tab.color || 'primary'" variant="tonal" class="rounded"><v-icon size="small">{{ tab.icon || 'mdi-tab' }}</v-icon></v-avatar>
									<span class="font-weight-bold text-subtitle-1">{{ tab.TenTab }}</span>
									<v-chip size="x-small" color="primary" variant="tonal">{{ tab.sections.length }} mục lục</v-chip>
								</div>
								<div class="d-flex align-center ga-3 text-caption">
									<span v-if="tab.ThoiGianSuaMoiNhat" class="text-medium-emphasis">Mới nhất: <b>{{ formatDateTime(tab.ThoiGianSuaMoiNhat) }}</b></span>
									<span v-else class="text-grey">Mới nhất: Chưa có</span>
								<v-chip v-if="tab.TongSoLanSua > 0" size="small" color="info" variant="flat">{{ tab.TongSoLanSua }} bản ghi</v-chip>
								<v-chip v-else size="small" color="grey" variant="tonal">Chưa có bản ghi</v-chip>
								</div>
							</div>
						</v-expansion-panel-title>

						<v-expansion-panel-text class="pa-0">
							<v-table density="compact" hover class="w-100">
								<thead><tr class="bg-grey-lighten-4 text-caption font-weight-bold">
									<th style="width: 50px;" class="text-center">STT</th><th style="width: 250px;">Nhóm mục</th><th>Mục lục / Tiêu đề</th>
									<th style="width: 140px;" class="text-center">Trạng thái / Bản ghi</th><th style="width: 200px;">Người ghi nhận gần nhất</th>
									<th style="width: 170px;">Thời gian ghi nhận/phiên bản</th><th style="width: 130px;" class="text-center">Thao tác</th>
								</tr></thead>
								<tbody>
									<tr v-for="(item, idx) in tab.sections" :key="item.MaMuc + idx">
										<td class="text-center text-caption text-medium-emphasis">{{ idx + 1 }}</td>
										<td class="text-caption font-weight-medium text-grey-darken-2">{{ item.NhomMuc || '—' }}</td>
										<td><div class="font-weight-bold text-body-2" :class="item.SoLanChinhSua > 0 ? 'text-primary' : 'text-grey-darken-2'">{{ item.TenMuc }}</div><div v-if="item.TenDong" class="text-caption text-grey">Dòng: {{ item.TenDong }}</div></td>
										<td class="text-center"><v-chip v-if="item.SoLanChinhSua > 0" size="x-small" color="primary" variant="flat" class="font-weight-bold">{{ item.SoLanChinhSua }} bản ghi</v-chip><v-chip v-else size="x-small" color="grey" variant="tonal">Chưa có</v-chip></td>
										<td><div v-if="item.SoLanChinhSua > 0" class="d-flex align-center ga-1"><v-icon size="14" color="grey">mdi-account-edit</v-icon><span class="text-caption font-weight-medium">{{ item.NguoiSuaMoiNhat || '—' }}</span></div><span v-else class="text-caption text-grey">Chưa có</span></td>
										<td class="text-caption" :class="item.SoLanChinhSua > 0 ? 'text-medium-emphasis' : 'text-grey'">{{ formatDateTime(item.ThoiGianSuaMoiNhat) }}</td>
										<td class="text-center"><v-btn v-if="item.SoLanChinhSua > 0" size="small" color="primary" variant="outlined" prepend-icon="mdi-history" @click="openDetailDialog(tab, item)">Chi tiết</v-btn><v-btn v-else size="small" color="grey" variant="text" disabled>Chưa có</v-btn></td>
									</tr>
								</tbody>
							</v-table>
						</v-expansion-panel-text>
					</v-expansion-panel>
				</v-expansion-panels>
			</template>
		</div>

		<!-- Popup chỉ hiển thị lịch sử của đúng một mục lục, tránh trộn log giữa các tab. -->
		<!-- Popup ưu tiên nội dung nghiệp vụ; mã audit/bảng nguồn chỉ còn ở dòng truy vết phụ. -->
		<v-dialog v-model="showDetailDialog" max-width="1400" scrollable>
			<v-card class="rounded-lg overflow-hidden">
			<!-- Tiêu đề dialog chỉ giữ tên tab/mục đang xem để thanh xanh gọn, không lặp lại chữ "Chi tiết lịch sử". -->
			<v-card-title class="bg-primary text-white d-flex align-center justify-space-between py-2 px-3 audit-dialog-title">
				<div class="audit-dialog-heading d-flex align-center ga-2 min-w-0"><v-icon color="white">mdi-history</v-icon><span class="text-subtitle-2 font-weight-medium text-truncate">{{ activeTab?.TenTab || 'Sổ GVCN' }}{{ activeItem?.TenMuc ? ' • ' + activeItem.TenMuc : '' }}</span></div>
				<v-btn icon="mdi-close" variant="text" color="white" density="compact" @click="showDetailDialog = false" />
			</v-card-title>
				<v-card-subtitle class="bg-grey-lighten-4 py-2 px-4 d-flex align-center justify-space-between flex-wrap ga-2 border-b">
					<div><span>Lớp: <b>{{ selectedLopObj?.TenLop || activeItem?.LopID || 'Chưa chọn lớp' }}</b></span><span class="ml-3">Nhóm mục: <b>{{ activeItem?.NhomMuc || '—' }}</b></span></div>
					<v-chip size="small" color="primary" variant="tonal">Tổng {{ detailLogs.length }} bản ghi lịch sử</v-chip>
				</v-card-subtitle>
			<v-card-text class="pa-0">
				<div v-if="isDetailLoading" class="text-center py-6"><v-progress-circular indeterminate color="primary" size="24" class="mr-2" />Đang tải lịch sử chi tiết...</div>
				<div v-else-if="detailErrorMessage" class="text-center py-6 text-error">{{ detailErrorMessage }}</div>
				<div v-else-if="detailLogs.length === 0" class="text-center py-6 text-grey">Chưa có bản ghi chi tiết nào cho mục này.</div>
				<v-data-table-virtual v-else :headers="detailTableHeaders" :items="detailLogs" item-value="__detailKey" fixed-header hover density="compact" :item-height="220" height="calc(60vh - 8px)" class="audit-detail-virtual-table">
					<template #item.stt="{ index }"><span class="text-caption text-medium-emphasis">{{ index + 1 }}</span></template>
					<template #item.time="{ item }"><div class="text-primary font-weight-bold text-caption">{{ formatDateTime(item.CreateTime) }}</div></template>
					<template #item.user="{ item }"><div class="font-weight-medium text-body-2">{{ formatAuditUser(item) }}</div><div v-if="formatAuditUserCode(item)" class="text-caption text-grey">{{ formatAuditUserCode(item) }}</div></template>
					<template #item.action="{ item }"><v-chip size="small" variant="tonal" :color="auditActionColor(item.AuditAction)" label>{{ formatAuditAction(item.AuditAction) }}</v-chip></template>
					<!-- Hiển thị thẳng toàn bộ dữ liệu nghiệp vụ; nội dung quá dài cuộn trong chính ô để không phá virtual list. -->
					<template #item.content="{ item }"><div class="audit-virtual-content"><div class="audit-virtual-content__full">{{ formatLogContent(item) }}</div><div class="text-caption text-grey">Mã truy vết: {{ item.LogID || '—' }}<span v-if="formatSourceTable(item.NguonBang)"> · {{ formatSourceTable(item.NguonBang) }}</span></div></div></template>
				</v-data-table-virtual>
			</v-card-text>
			<v-divider /><v-card-actions class="pa-3 bg-grey-lighten-4"><v-spacer /><v-btn variant="outlined" color="primary" @click="showDetailDialog = false">Đóng</v-btn></v-card-actions>
		</v-card>
	</v-dialog>

	</Global>
</template>

<script>
	export default {
		data() {
				const nienKhoa = Number(vueData.NienKhoa) || 2026
				const now = new Date()
				const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
				const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0)
				// Mặc định chỉ lọc tháng dương lịch hiện tại; vẫn giữ bộ chọn để giáo viên tra khoảng ngày khác.
				const toLocalISODate = function (date) {
					return String(date.getFullYear()) + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0')
				}
				return {
					currentNienKhoa: nienKhoa,
					// Hai danh sách này lấy từ API thật; không giữ dữ liệu mẫu để tránh hiển thị sai phạm vi quyền của giáo viên.
					danhSachKhoi: [], danhSachLop: [],
					selectedKhoiID: 0, selectedLopID: null,
					filterDateRange: { from: toLocalISODate(monthStart), to: toLocalISODate(monthEnd) },
					isLoading: false, isFilterLoading: false, isDetailLoading: false,
					errorMessage: '', detailErrorMessage: '', historyLogs: [],
					openedPanels: [0, 1], showDetailDialog: false, activeTab: null, activeItem: null, detailLogs: [],
					detailTableHeaders: [
						{ title: '#', key: 'stt', width: '50px', align: 'center', sortable: false },
						{ title: 'Thời gian log/phiên bản', key: 'time', width: '190px', sortable: false },
						{ title: 'Người thực hiện', key: 'user', width: '205px', sortable: false },
						{ title: 'Thao tác', key: 'action', width: '145px', sortable: false },
						{ title: 'Nội dung / dữ liệu ghi nhận', key: 'content', sortable: false }
					]
				}
			},
			computed: {
				danhSachLopFiltered() {
				// Không còn bộ lọc Khối riêng; TenLopDisplay đã mang theo Khối để người dùng nhận diện lớp.
				if (!this.selectedKhoiID) return this.danhSachLop
				return this.danhSachLop.filter(x => x.KhoiID == this.selectedKhoiID)
			},
			danhSachLopOptions() {
				// Màn hình lịch sử chỉ tra cứu một lớp cụ thể vì cấu trúc tab khác nhau giữa cấp 1 và cấp 2/3.
				return this.danhSachLopFiltered
			},
			selectedLopObj() {
				if (!this.selectedLopID) return null
				return this.danhSachLop.find(x => x.LopID == this.selectedLopID)
			},
			// Ưu tiên CapID của lớp; chỉ suy ra từ KhoiID khi API lớp không trả CapID.
			selectedClassCapID() {
				const classCapID = Number(this.selectedLopObj?.CapID || this.selectedLopObj?.KhoiCapID || 0)
				if (classCapID) return classCapID
				const khoiID = Number(this.selectedLopObj?.KhoiID || 0)
				if (khoiID >= 1 && khoiID <= 5) return 1
				if (khoiID >= 6 && khoiID <= 9) return 2
				if (khoiID >= 10 && khoiID <= 12) return 3
				return Number(vueData.CapID) || 0
			},
			isCap1() {
				return this.selectedClassCapID === 1
			},
			tongSoLanSua() {
				return this.historyLogs.reduce((sum, item) => sum + (Number(item.SoLanChinhSua) || 0), 0)
			},
			allDisplayTabs() {
				const baseConfig = this.getBaseTabConfig(this.isCap1)
				const logMap = new Map()
				for (const row of this.historyLogs) logMap.set(row.MaTab + '__' + row.MaMuc, row)
				// Hiển thị tab nghiệp vụ cùng một nhóm tổng quan riêng: bảng cha không có AuditTab
				// nên không thể gán an toàn các bản ghi đó vào tab dữ liệu học sinh chỉ đọc.
				return baseConfig.map(tabDef => {
					let tabTongSoLanSua = 0
					let tabThoiGianMoiNhat = null
					const enrichedSections = tabDef.sections.map(sec => {
						const dbRow = logMap.get(tabDef.MaTab + '__' + sec.MaMuc)
						if (!dbRow) return { ...sec, SoLanChinhSua: 0, NguoiSuaMoiNhat: 'Chưa có', ThoiGianSuaMoiNhat: null, LopID: this.selectedLopID }
						tabTongSoLanSua += Number(dbRow.SoLanChinhSua) || 0
						if (!tabThoiGianMoiNhat || new Date(dbRow.ThoiGianSuaMoiNhat) > new Date(tabThoiGianMoiNhat)) tabThoiGianMoiNhat = dbRow.ThoiGianSuaMoiNhat
						return { ...sec, ...dbRow, SoLanChinhSua: Number(dbRow.SoLanChinhSua) || 0, NguoiSuaMoiNhat: dbRow.NguoiSuaMoiNhat || '—', LopID: dbRow.LopID || this.selectedLopID }
					})
					return { ...tabDef, sections: enrichedSections, TongSoLanSua: tabTongSoLanSua, ThoiGianSuaMoiNhat: tabThoiGianMoiNhat }
				})
			}
		},
			mounted() {
				// Tải danh sách lớp trước, sau đó mở ngay lớp đầu tiên để tránh quét toàn bộ lịch sử khi khởi động.
			this.openedPanels = [0, 1]
			this.loadKhoi().then(() => this.loadLop()).then(() => {
				// Không quét summary của toàn bộ 24 bảng khi mở trang; lớp đầu tiên sẽ được tải theo đúng bộ lọc lớp.
				const firstClass = this.danhSachLop[0] || null
				this.selectedLopID = firstClass?.LopID || null
				return this.fetchLichSuTongHop()
			})
			},
		methods: {
			getBaseTabConfig(isCap1) {
				if (isCap1) return [
					{ MaTab: 'tong-quan-so-gvcn', TenTab: 'TỔNG QUAN SỔ GVCN', icon: 'mdi-book-open-page-variant', color: 'blue-grey', sections: [{ MaMuc: 'tong-quan-so-gvcn', TenMuc: 'Bản ghi tổng quan Sổ GVCN', NhomMuc: 'TỔNG QUAN' }] },
					{ MaTab: 'du-lieu-hs', TenTab: 'THÔNG TIN HS LỚP', icon: 'mdi-account-details', color: 'blue-grey', sections: [{ MaMuc: 'so-yeu-ly-lich', TenMuc: 'Sơ yếu lý lịch & Thông tin học sinh', NhomMuc: 'THÔNG TIN HỌC SINH' }] },
					{ MaTab: 'to-chuc-lop', TenTab: 'TỔ CHỨC LỚP', icon: 'mdi-account-group', color: 'success', sections: [{ MaMuc: 'can-bo-lop', TenMuc: 'Cán bộ lớp', NhomMuc: 'TỔ CHỨC LỚP HỌC' }, { MaMuc: 'ban-dai-dien-cmhs', TenMuc: 'Ban đại diện CMHS', NhomMuc: 'TỔ CHỨC LỚP HỌC' }, { MaMuc: 'to-nhom-hoc-sinh', TenMuc: 'Phân chia tổ/nhóm', NhomMuc: 'TỔ CHỨC LỚP HỌC' }, { MaMuc: 'giao-vien-bo-mon', TenMuc: 'Danh sách giáo viên bộ môn', NhomMuc: 'DANH SÁCH GIÁO VIÊN BỘ MÔN' }] },
					{ MaTab: 'ke-hoach-nam-hoc', TenTab: 'KH CHỦ NHIỆM NĂM HỌC', icon: 'mdi-calendar-star', color: 'primary', sections: [{ MaMuc: 'thong-ke-tinh-hinh', TenMuc: '1. Thống kê tình hình lớp học', NhomMuc: 'I. ĐẶC ĐIỂM TÌNH HÌNH' }, { MaMuc: 'duy-tri-so-luong', TenMuc: '1. Duy trì số lượng', NhomMuc: 'II. NỘI DUNG KẾ HOẠCH' }, { MaMuc: 'chat-luong-giao-duc', TenMuc: '2. Chất lượng giáo dục', NhomMuc: 'II. NỘI DUNG KẾ HOẠCH' }] },
					{ MaTab: 'cong-tac-cn', TenTab: 'CÔNG TÁC CHỦ NHIỆM THÁNG', icon: 'mdi-clipboard-text-clock', color: 'purple', sections: [{ MaMuc: 'ke-hoach-thang', TenMuc: 'Kế hoạch trọng tâm tháng', NhomMuc: 'CÔNG TÁC CHỦ NHIỆM' }, { MaMuc: 'ke-hoach-tuan', TenMuc: 'Kế hoạch từng tuần', NhomMuc: 'CÔNG TÁC CHỦ NHIỆM' }] },
					{ MaTab: 'hs-can-quan-tam', TenTab: 'HS CẦN QUAN TÂM', icon: 'mdi-heart-pulse', color: 'pink', sections: [{ MaMuc: 'hs-can-quan-tam', TenMuc: 'Hồ sơ học sinh cần quan tâm', NhomMuc: 'THEO DÕI HỌC SINH' }] },
					{ MaTab: 'nhan-xet-thang', TenTab: 'NHẬN XÉT THÁNG (LMS)', icon: 'mdi-comment-text-multiple', color: 'teal', sections: [{ MaMuc: 'nhan-xet-thang', TenMuc: 'Đánh giá nhận xét tháng LMS', NhomMuc: 'NHẬN XÉT HỌC SINH' }] },
					{ MaTab: 'so-ket-hk1', TenTab: 'SƠ KẾT HKI', icon: 'mdi-file-certificate', color: 'amber-darken-2', sections: [{ MaMuc: 'cong-tac-duy-tri', TenMuc: '1. Công tác duy trì số lượng', NhomMuc: 'ĐÁNH GIÁ HOẠT ĐỘNG LỚP' }, { MaMuc: 'nang-luc-pham-chat', TenMuc: '2. Về năng lực, phẩm chất', NhomMuc: 'ĐÁNH GIÁ HOẠT ĐỘNG LỚP' }, { MaMuc: 'ket-qua-hk1', TenMuc: 'Kết quả học kì I', NhomMuc: 'KẾT QUẢ HỌC KÌ I' }] },
					{ MaTab: 'tong-ket-nam', TenTab: 'TỔNG KẾT NĂM HỌC', icon: 'mdi-trophy-variant', color: 'deep-orange', sections: [{ MaMuc: 'danh-gia-tong-quan', TenMuc: 'Đánh giá tổng quan', NhomMuc: 'ĐÁNH GIÁ TỔNG QUAN' }, { MaMuc: 'khen-thuong-hoan-thanh', TenMuc: 'Khen thưởng và hoàn thành CT', NhomMuc: 'ĐÁNH GIÁ TỔNG QUAN' }] },
					{ MaTab: 'theo-doi-si-so', TenTab: 'THEO DÕI SĨ SỐ HS THEO THÁNG', icon: 'mdi-chart-line', color: 'indigo', sections: [{ MaMuc: 'theo-doi-si-so', TenMuc: 'Biến động sĩ số học sinh', NhomMuc: 'THEO DÕI SĨ SỐ' }] },
					{ MaTab: 'thong-ke-do-tuoi', TenTab: 'THỐNG KÊ ĐỘ TUỔI HS', icon: 'mdi-human-male-female-child', color: 'cyan', sections: [{ MaMuc: 'thong-ke-do-tuoi', TenMuc: 'Thống kê độ tuổi theo năm sinh', NhomMuc: 'THỐNG KÊ ĐỘ TUỔI' }] },
					{ MaTab: 'theo-doi-thanh-tich', TenTab: 'THEO DÕI THÀNH TÍCH HS', icon: 'mdi-medal-outline', color: 'deep-purple', sections: [{ MaMuc: 'theo-doi-thanh-tich', TenMuc: 'Theo dõi thành tích học sinh', NhomMuc: 'THEO DÕI THÀNH TÍCH' }] },
					{ MaTab: 'so-lien-lac', TenTab: 'THEO DÕI PHỤ HUYNH ĐI HỌP', icon: 'mdi-account-voice', color: 'blue', sections: [{ MaMuc: 'so-lien-lac', TenMuc: 'Theo dõi phụ huynh đi họp', NhomMuc: 'THEO DÕI PHỤ HUYNH' }] },
					{ MaTab: 'noi-dung-hop-ph', TenTab: 'NỘI DUNG HỌP PHHS', icon: 'mdi-account-group-outline', color: 'indigo', sections: [{ MaMuc: 'noi-dung-hop-ph', TenMuc: 'Nội dung họp phụ huynh học sinh', NhomMuc: 'NỘI DUNG HỌP PHHS' }] }
				]
				return [
					{ MaTab: 'tong-quan-so-gvcn', TenTab: 'TỔNG QUAN SỔ GVCN', icon: 'mdi-book-open-page-variant', color: 'blue-grey', sections: [{ MaMuc: 'tong-quan-so-gvcn', TenMuc: 'Bản ghi tổng quan Sổ GVCN', NhomMuc: 'TỔNG QUAN' }] },
					{ MaTab: 'du-lieu-hs', TenTab: 'DỮ LIỆU HS LỚP', icon: 'mdi-account-details', color: 'blue-grey', sections: [{ MaMuc: 'du-lieu-hs', TenMuc: 'Danh sách và hồ sơ học sinh lớp', NhomMuc: 'DỮ LIỆU HỌC SINH' }] },
					// THCS/THPT hiển thị 7 bảng con trong cùng tab; MaMuc khớp từng nhóm log và card nguồn.
					{ MaTab: 'chi-tieu', TenTab: 'XD CHỈ TIÊU & GIẢI PHÁP', icon: 'mdi-target', color: 'primary', sections: [
						{ MaMuc: 'chi-tieu-giao-duc', TenMuc: 'I. Chỉ tiêu 2 mặt giáo dục', NhomMuc: 'CHỈ TIÊU & GIẢI PHÁP' },
						{ MaMuc: 'danh-hieu', TenMuc: 'DANH HIỆU', NhomMuc: 'CHỈ TIÊU & GIẢI PHÁP' },
						{ MaMuc: 'hoat-dong-phong-trao', TenMuc: 'THAM GIA CÁC HOẠT ĐỘNG PHONG TRÀO KHÁC', NhomMuc: 'CHỈ TIÊU & GIẢI PHÁP' },
						{ MaMuc: 'theo-doi-si-so', TenMuc: 'II. THEO DÕI SĨ SỐ', NhomMuc: 'II. THEO DÕI SĨ SỐ' },
						{ MaMuc: 'giao-vien-bo-mon', TenMuc: 'III. DANH SÁCH GIÁO VIÊN BỘ MÔN', NhomMuc: 'III. DANH SÁCH GIÁO VIÊN BỘ MÔN' },
						{ MaMuc: 'ban-dai-dien-cmhs', TenMuc: 'IV. DANH SÁCH BAN ĐẠI DIỆN CHA MẸ HỌC SINH', NhomMuc: 'IV. DANH SÁCH BAN ĐẠI DIỆN CHA MẸ HỌC SINH' },
						{ MaMuc: 'can-bo-lop', TenMuc: 'V. DANH SÁCH CÁN BỘ LỚP', NhomMuc: 'V. DANH SÁCH CÁN BỘ LỚP' }
					] },
					{ MaTab: 'ke-hoach', TenTab: 'KH GD THÁNG - TUẦN', icon: 'mdi-calendar-month', color: 'purple', sections: [{ MaMuc: 'ke-hoach', TenMuc: 'Kế hoạch giáo dục tháng - tuần', NhomMuc: 'KẾ HOẠCH' }] },
					{ MaTab: 'ren-luyen', TenTab: 'HỒ SƠ THEO DÕI QTRL', icon: 'mdi-star-circle', color: 'teal', sections: [{ MaMuc: 'ren-luyen', TenMuc: 'Theo dõi quá trình rèn luyện', NhomMuc: 'RÈN LUYỆN' }] },
					{ MaTab: 'so-lien-lac', TenTab: 'SỔ LIÊN LẠC ĐIỆN TỬ', icon: 'mdi-book-open-page-variant', color: 'blue', sections: [{ MaMuc: 'so-lien-lac', TenMuc: 'Thông tin sổ liên lạc điện tử', NhomMuc: 'SỔ LIÊN LẠC' }] },
					{ MaTab: 'huong-nghiep', TenTab: 'HƯỚNG NGHIỆP', icon: 'mdi-compass', color: 'orange-darken-2', sections: [{ MaMuc: 'huong-nghiep', TenMuc: 'Tư vấn và giáo dục hướng nghiệp', NhomMuc: 'HƯỚNG NGHIỆP' }] }
				]
			},
				// Chuẩn hóa response của tAPI; một số SP trả thẳng rows, một số phiên bản trả data[0].
				normalizeRows(raw) {
					if (raw && Array.isArray(raw.data)) return this.normalizeRows(raw.data)
					if (!Array.isArray(raw)) return []
					if (raw.length && Array.isArray(raw[0])) return this.normalizeRows(raw[0])
					return raw.filter(row => row && typeof row === 'object')
				},
				getCurrentHocKi() {
					return Number(vueData.HocKi || vueData.NienKhoaItem?.HocKi) || 0
				},
				getCurrentCapID() {
					return Number(vueData.CapID) || 0
				},
				// Lớp tổ hợp cấp 3 (ví dụ 11B1, 11B2) được hiển thị thành một lớp nghiệp vụ 11B,
				// nhưng vẫn giữ toàn bộ LopIDs để khi tra cứu lịch sử không bỏ sót dữ liệu của lớp thành viên.
				buildGroupedClassList(rows) {
					const map = new Map()
					;(rows || []).forEach(row => {
						if (!row || row.LopID === undefined || row.LopID === null) return
						const tenLop = String(row.TenLop || row.LopID).trim()
						const capID = Number(row.CapID || this.getCurrentCapID())
						const isCap3 = capID === 3 || Number(row.KhoiID || 0) > 9
						const isLopToHop = isCap3 && (row.IsLopToHop === true || Number(row.IsLopToHop) === 1)
						const tenLopGoc = isLopToHop ? (tenLop.replace(/[0-9]+$/, '') || tenLop) : tenLop
						const key = isLopToHop ? String(row.KhoiID || '') + '|' + tenLopGoc : String(row.LopID)
						const item = map.get(key) || {
							NienKhoa: this.currentNienKhoa,
							LopID: row.LopID,
							LopIDs: [],
							TenLop: tenLopGoc,
							TenLopThanhVien: [],
							TenKhoiHoc: row.TenKhoiHoc || ('Khối ' + row.KhoiID),
							KhoiID: row.KhoiID,
							CapID: capID,
							TrangThai: 'NEW'
						}
						const lopID = String(row.LopID)
						if (!item.LopIDs.some(id => String(id) === lopID)) item.LopIDs.push(row.LopID)
						if (!item.TenLopThanhVien.some(name => name === tenLop)) item.TenLopThanhVien.push(tenLop)
						map.set(key, item)
					})
					return [...map.values()].map(item => {
						const members = [...item.TenLopThanhVien].sort((a, b) => String(a).localeCompare(String(b), 'vi', { numeric: true }))
						const groupName = members.length > 1 ? item.TenLop + ' (' + members.join(', ') + ')' : item.TenLop
						return {
							...item,
							TenLop: groupName,
							// Khi xem tất cả khối, thêm tên khối để phân biệt các lớp trùng tên.
							TenLopDisplay: this.selectedKhoiID ? groupName : groupName + ' (' + item.TenKhoiHoc + ')',
							TenLopThanhVien: members
						}
					}).sort((a, b) => {
						const khoiCompare = Number(a.KhoiID || 0) - Number(b.KhoiID || 0)
						return khoiCompare || String(a.TenLop || '').localeCompare(String(b.TenLop || ''), 'vi', { numeric: true })
					})
				},
				getHistoryParams(extra) {
					const range = this.filterDateRange || {}
					// Khi đã chọn lớp, lấy KhốiID từ chính lớp đó để SP không phải suy luận từ một bộ lọc Khối riêng.
					const selectedKhoiID = Number(this.selectedLopObj?.KhoiID || this.selectedKhoiID) || null
					return Object.assign({
						NienKhoa: this.currentNienKhoa,
						KhoiID: selectedKhoiID,
						LopID: this.selectedLopID || '',
						Ngay: '',
						NgayTu: range.from || '',
						NgayDen: range.to || '',
						Gio: ''
					}, extra || {})
				},
				getSelectedClassIDs() {
					if (!this.selectedLopID) return []
					const item = this.selectedLopObj
					return (item?.LopIDs || [item?.LopID || this.selectedLopID]).filter(Boolean).map(id => String(id))
				},
				loadKhoi(forceRefresh) {
					this.isFilterLoading = true
					return fetchPromise('lms/KhoiHocByCapHoc_Get', {
						CapID: this.getCurrentCapID(),
						HocKi: this.getCurrentHocKi(),
						NienKhoa: this.currentNienKhoa
					}, { forceRefresh: !!forceRefresh, cache: false }).then(res => {
						this.danhSachKhoi = this.normalizeRows(res)
						return this.danhSachKhoi
					}).catch(err => {
						console.error('Lỗi tải danh sách khối:', err)
						this.danhSachKhoi = []
						this.errorMessage = 'Không tải được danh sách khối.'
						return []
					}).then(result => {
						this.isFilterLoading = false
						return result
					})
				},
				loadLop(forceRefresh) {
					this.danhSachLop = []
					// Khi lọc một Khối thì gọi API theo Khối; mặc định màn hình dùng API theo Cấp để lấy lớp trong một lần.
					const khoiIDs = this.selectedKhoiID
						? [Number(this.selectedKhoiID)]
						: this.danhSachKhoi.map(item => Number(item.KhoiID)).filter(Boolean)
					if (!khoiIDs.length) return Promise.resolve([])
					this.isFilterLoading = true
				// API theo Cấp có thể lọc theo quyền GVCN khác với màn hình lịch sử;
				// giữ API theo Khối để danh sách lớp khớp module so-gvcn hiện tại.
				const apiCalls = khoiIDs.map(khoiID => ({
					url: 'lms/Lop_Get_ByKhoiID',
					params: {
						NienKhoa: this.currentNienKhoa,
						HocKi: this.getCurrentHocKi(),
						KhoiID: khoiID
					}
				}))
				// Chạy song song các khối để không chờ tuần tự từng request lớp.
				const batchRequest = typeof fetchBatchPromise === 'function'
					? fetchBatchPromise(apiCalls, { forceRefresh: !!forceRefresh, batchCache: false, silent: true })
					: Promise.all(apiCalls.map(call => fetchPromise(call.url, call.params, { forceRefresh: !!forceRefresh, cache: false })))
					return batchRequest.then(results => {
						const uniqueClasses = new Map()
						results.forEach((res, index) => {
							const khoiID = khoiIDs[index]
							const khoi = this.danhSachKhoi.find(item => Number(item.KhoiID) === khoiID) || {}
							this.normalizeRows(res).forEach(row => {
								if (!row || row.LopID === undefined || row.LopID === null) return
								// Chỉ hiển thị lớp đang hoạt động; các dòng lớp cha/đã đóng không phải lựa chọn truy vết.
								if (row.Enable === false || Number(row.Enable) === 0) return
								// IsNhom là dòng nhóm nghiệp vụ, không phải lớp người dùng có thể chọn để truy vết.
								// Chỉ loại nhóm khỏi dropdown; lớp tổ hợp vẫn giữ lại để buildGroupedClassList gom 11B1/11B2 thành 11B.
								const isNhom = row.IsNhom === true || Number(row.IsNhom) === 1 || String(row.IsNhom).toLowerCase() === 'true'
								if (isNhom) return
								const tenKhoi = row.TenKhoiHoc || khoi.TenKhoiHoc || ('Khối ' + khoiID)
								uniqueClasses.set(String(row.LopID), Object.assign({}, row, {
									KhoiID: row.KhoiID ?? khoiID,
									TenKhoiHoc: row.TenKhoiHoc || khoi.TenKhoiHoc || ('Khối ' + khoiID),
									TenLopDisplay: this.selectedKhoiID ? row.TenLop : (String(row.TenLop || '') + ' (' + tenKhoi + ')')
								}))
							})
						})
						this.danhSachLop = this.buildGroupedClassList(Array.from(uniqueClasses.values()))
						return this.danhSachLop
					}).catch(err => {
						console.error('Lỗi tải danh sách lớp:', err)
						this.danhSachLop = []
						this.errorMessage = 'Không tải được danh sách lớp của khối đã chọn.'
						return []
					}).then(result => {
						this.isFilterLoading = false
						return result
					})
				},
			onKhoiChange() {
				if (!this.selectedKhoiID) this.selectedKhoiID = 0
				this.selectedLopID = null
				this.errorMessage = ''
				this.loadLop().then(() => this.fetchLichSuTongHop())
			},
			async selectFirstClassWithHistory() {
				this.isLoading = true
				this.errorMessage = ''
				try {
					let targetClass = null
					let targetLogs = []

					// Ưu tiên một lần gọi tổng hợp. Nếu API trả LopID trong từng dòng log,
					// có thể xác định ngay lớp đang có dữ liệu mà không phải gọi từng lớp.
					let aggregateRows = []
					try {
						const aggregate = await fetchPromise('lms/SoGVCN_LichSuChinhSua_Get_TongHop', this.getHistoryParams({ LopID: '' }), {
							cache: false, silent: true
						})
						aggregateRows = this.normalizeRows(aggregate)
					} catch (err) {
						console.warn('Không lấy được summary tổng hợp, chuyển sang dò từng lớp:', err)
					}

					const aggregateClassIDs = new Set()
					aggregateRows.forEach(row => {
						;(row.LopIDs || [row.LopID]).filter(id => id !== undefined && id !== null && String(id) !== '').forEach(id => aggregateClassIDs.add(String(id)))
					})
					targetClass = this.danhSachLop.find(item => (item.LopIDs || [item.LopID]).some(id => aggregateClassIDs.has(String(id))))
					if (targetClass) {
						const targetIDs = new Set((targetClass.LopIDs || [targetClass.LopID]).map(id => String(id)))
						targetLogs = this.mergeHistorySummary(aggregateRows.filter(row => (row.LopIDs || [row.LopID]).some(id => targetIDs.has(String(id)))))
					}

					if (!targetClass && this.danhSachLop.length) {
						// Một số phiên bản SP trả summary tổng hợp không kèm LopID. Dò theo từng đợt nhỏ
						// để tránh tạo hàng trăm request đồng thời, đồng thời vẫn chọn đúng lớp có log DB.
						const chunkSize = 10
						for (let offset = 0; offset < this.danhSachLop.length && !targetClass; offset += chunkSize) {
							const chunk = this.danhSachLop.slice(offset, offset + chunkSize)
							const probed = await Promise.all(chunk.map(async item => {
								const classIDs = (item.LopIDs || [item.LopID]).filter(Boolean).map(id => String(id))
								const responses = await Promise.all(classIDs.map(lopID => fetchPromise('lms/SoGVCN_LichSuChinhSua_Get_TongHop', this.getHistoryParams({ LopID: lopID }), {
									cache: false, silent: true
								}).catch(() => [])))
								return { item, logs: this.mergeHistorySummary(responses.flatMap(res => this.normalizeRows(res))) }
							}))
							const match = probed.find(result => result.logs.length > 0)
							if (match) {
								targetClass = match.item
								targetLogs = match.logs
							}
						}
					}

					// Có log thì mở lớp đó; nếu DB chưa có log nào, vẫn chọn lớp đầu tiên để người dùng tiếp tục tra cứu.
					const selectedClass = targetClass || this.danhSachLop[0] || null
					this.selectedLopID = selectedClass?.LopID || null
					this.historyLogs = targetLogs
					return selectedClass
				} catch (err) {
					console.error('Lỗi chọn lớp mặc định có lịch sử:', err)
					this.historyLogs = []
					return null
				} finally {
					this.isLoading = false
				}
			},
			mergeHistorySummary(rows) {
					const summaryMap = new Map()
					for (const row of rows || []) {
						if (!row || !row.MaTab || !row.MaMuc) continue
						const key = row.MaTab + '__' + row.MaMuc
						const current = summaryMap.get(key)
						const rowTime = row.ThoiGianSuaMoiNhat || row.CreateTime
						const currentTime = current?.ThoiGianSuaMoiNhat || ''
						const lopIDs = new Set((current?.LopIDs || []).map(id => String(id)))
						if (row.LopID !== undefined && row.LopID !== null && String(row.LopID) !== '') lopIDs.add(String(row.LopID))
						const isNewer = !currentTime || (rowTime && new Date(rowTime) > new Date(currentTime))
						const merged = current || Object.assign({}, row, { SoLanChinhSua: 0 })
						merged.SoLanChinhSua = (Number(merged.SoLanChinhSua) || 0) + (Number(row.SoLanChinhSua) || 0)
						merged.LopIDs = [...lopIDs]
						if (isNewer) {
							merged.ThoiGianSuaMoiNhat = rowTime || null
							merged.NguoiSuaMoiNhat = row.NguoiSuaMoiNhat || merged.NguoiSuaMoiNhat || '—'
						}
						summaryMap.set(key, merged)
					}
					return [...summaryMap.values()].map(row => ({
						...row,
						LopID: row.LopIDs?.length === 1 ? row.LopIDs[0] : 0
					}))
			},
			fetchLichSuTongHop(forceRefresh) {
				// Không gọi summary toàn hệ thống khi chưa có lớp cụ thể; dữ liệu giữa các cấp học không được trộn chung.
				if (!this.selectedLopID) {
					this.historyLogs = []
					return Promise.resolve([])
				}
				if (this.isLoading) return Promise.resolve(this.historyLogs)
					this.isLoading = true
					this.errorMessage = ''
					const selectedClassIDs = this.getSelectedClassIDs()
					// Lớp gộp phải gọi từng LopID thành viên vì SP lịch sử nhận một LopID đơn; sau đó merge lại theo MaTab/MaMuc.
					const requests = selectedClassIDs.length
						? selectedClassIDs.map(lopID => fetchPromise('lms/SoGVCN_LichSuChinhSua_Get_TongHop', this.getHistoryParams({ LopID: lopID }), {
							forceRefresh: !!forceRefresh, cache: false
						}))
						: [fetchPromise('lms/SoGVCN_LichSuChinhSua_Get_TongHop', this.getHistoryParams(), {
							forceRefresh: !!forceRefresh, cache: false
						})]
					return Promise.all(requests).then(results => {
						this.historyLogs = this.mergeHistorySummary(results.flatMap(res => this.normalizeRows(res)))
						return this.historyLogs
					}).catch(err => {
						console.error('Lỗi tải lịch sử chỉnh sửa:', err)
						this.historyLogs = []
						this.errorMessage = 'Không tải được dữ liệu lịch sử chỉnh sửa.'
						return []
					}).then(result => {
						this.isLoading = false
						return result
					})
				},
				openDetailDialog(tab, item) {
					this.activeTab = tab
					this.activeItem = item
					this.detailLogs = []
					this.detailErrorMessage = ''
					this.showDetailDialog = true
					this.isDetailLoading = true
					const lopIDs = (item.LopIDs || (item.LopID ? [item.LopID] : this.getSelectedClassIDs())).filter(Boolean).map(id => String(id))
					if (!lopIDs.length) {
						this.isDetailLoading = false
						this.detailErrorMessage = 'Cần chọn lớp hoặc dữ liệu log phải có LopID để xem chi tiết.'
						return Promise.resolve([])
					}
					const detailCalls = lopIDs.map(lopID => ({
						url: 'lms/SoGVCN_LichSuChinhSua_Get_ChiTiet',
						params: this.getHistoryParams({ LopID: lopID, MaTab: tab.MaTab, MaMuc: item.MaMuc || '' })
					}))
					const detailRequest = typeof fetchBatchPromise === 'function'
						? fetchBatchPromise(detailCalls, { batchCache: false, silent: true })
						: Promise.all(detailCalls.map(call => fetchPromise(call.url, call.params, { cache: false })))
					return detailRequest.then(results => {
						this.detailLogs = results.flatMap(res => this.normalizeRows(res)).sort((a, b) => new Date(b.CreateTime) - new Date(a.CreateTime) || Number(b.LogID || 0) - Number(a.LogID || 0)).map((log, index) => ({ ...log, __detailKey: this.getDetailLogKey(log, index) }))
						return this.detailLogs
					}).catch(err => {
						console.error('Lỗi tải chi tiết lịch sử:', err)
						this.detailLogs = []
						this.detailErrorMessage = 'Không tải được chi tiết lịch sử của mục này.'
						return []
					}).then(result => {
						this.isDetailLoading = false
						return result
					})
				},
				getDetailLogKey(log, index) {
					return [log?.NguonBang || 'log', log?.LogID || 'row', log?.CreateTime || index].join('__')
				},
				// Audit trực tiếp thường không có AuditUserName và mô tả chứa mã kỹ thuật;
			// các hàm này chuyển thành nhãn nghiệp vụ trước khi đưa lên popup cho giáo viên.
			formatAuditAction(action) {
				return ({ I: 'Thêm mới', U: 'Cập nhật', D: 'Xóa', B: 'Bản lưu' })[String(action || '').trim().toUpperCase()] || 'Ghi nhận'
			},
			auditActionColor(action) {
				return ({ I: 'success', U: 'primary', D: 'error', B: 'info' })[String(action || '').trim().toUpperCase()] || 'secondary'
			},
			formatAuditUser(log) {
				const name = String(log?.HoTenUser || '').trim()
				if (name && !/^unknown\/unavailable$/i.test(name)) return name
				const code = String(log?.CreateUser || '').trim()
				return code && !/^unknown\/unavailable$/i.test(code) ? code : 'Chưa xác định'
			},
			formatAuditUserCode(log) {
				const code = String(log?.CreateUser || '').trim()
				if (!code || /^unknown\/unavailable$/i.test(code)) return ''
				const name = String(log?.HoTenUser || '').trim()
				return name && name !== code && !/^unknown\/unavailable$/i.test(name) ? 'Mã: ' + code : ''
			},
			formatSourceTable(source) {
				const labels = {
					tblSoGVCNKeHoachThang_Log: 'Kế hoạch tháng', tblSoGVCNKeHoachTuan_Log: 'Kế hoạch tuần',
					tblSoGVCNKeHoachNamHoc_Log: 'Kế hoạch năm học', tblSoGVCNChiTieu_Log: 'Chỉ tiêu',
					tblSoGVCNTheoDoiRenLuyen_Log: 'Theo dõi rèn luyện', tblSoGVCNHocSinhCanQuanTam_Log: 'Học sinh cần quan tâm',
					tblSoGVCNCanBoLop_Log: 'Cán bộ lớp', tblSoGVCNBanDaiDienCMHS_Log: 'Ban đại diện CMHS',
					tblSoGVCNToNhomHocSinh_Log: 'Phân chia tổ/nhóm', tblSoGVCNKeHoachNamHocChiTieu_Log: 'Chỉ tiêu năm học',
					tblSoGVCNKeHoachNamHocThongKeLop_Log: 'Thống kê lớp', tblSoGVCNSiSo_Log: 'Sĩ số',
					tblSoGVCNTheoDoiSiSoThang_Log: 'Theo dõi sĩ số tháng', tblSoGVCNGiaoVienBoMon_Log: 'Giáo viên bộ môn',
					tbl_LOG_NhanXetThang: 'Snapshot nội dung nhận xét',
					tbl_LOG_NhanXetThang_Lop: 'Lịch sử trạng thái kỳ nhận xét'
				}
				return labels[String(source || '').trim()] || ''
			},
			// Snapshot nhận xét cũ chứa HTML; chuyển thành văn bản thuần để không render HTML do người dùng nhập.
			formatSnapshotValue(value) {
				const raw = String(value ?? '').replace(/<br\s*\/?>/gi, '\n').replace(/<\/(p|div|li)\s*>/gi, '\n')
				if (!/[<>]/.test(raw)) return raw.trim()
				if (typeof DOMParser !== 'undefined') {
					return new DOMParser().parseFromString(raw, 'text/html').body.textContent.trim()
				}
				return raw.replace(/<[^>]*>/g, ' ').replace(/&nbsp;/gi, ' ').trim()
			},
			formatLogContent(log) {
				const raw = String(log?.NoiDungChinhSua || '').trim()
				const snapshotMarker = '__NXT_JSON__'
				if (raw.startsWith(snapshotMarker)) {
					try {
						const snapshot = JSON.parse(raw.slice(snapshotMarker.length))
						const lines = Object.entries(snapshot || {})
							.map(([label, value]) => [label, this.formatSnapshotValue(value)])
							.filter(([, value]) => value !== '')
							.map(([label, value]) => label + ': ' + value)
						return ['Bản dữ liệu được lưu trước lần cập nhật tiếp theo', ...lines].join('\n')
					} catch (err) {
						return 'Không đọc được nội dung snapshot nhận xét tháng.'
					}
				}
				// Các SP đọc trực tiếp 24 bảng log có thể trả mô tả kỹ thuật mặc định;
				// chỉ hiển thị raw khi đó thực sự là nội dung nghiệp vụ người dùng đọc được.
				const isTechnicalDescription = /^(Bảng nguồn:|Chi tiết được truy xuất trực tiếp)/i.test(raw)
				if (raw && !isTechnicalDescription) {
					// Tách các trường nghiệp vụ thành từng dòng để popup đọc được trên màn hình hẹp;
					// mã truy vết vẫn nằm riêng bên dưới, không trộn vào nội dung chính.
					return raw.replace(/\s*\|\s*/g, '\n')
				}
				const rowLabel = String(log?.TenDong || '').trim()
				if (rowLabel && !/^AuditID:/i.test(rowLabel)) {
					return this.formatAuditAction(log?.AuditAction) + ' nội dung “' + rowLabel + '”.'
				}
				const source = this.formatSourceTable(log?.NguonBang) || this.activeItem?.TenMuc || 'nội dung Sổ GVCN'
				return this.formatAuditAction(log?.AuditAction) + ' dữ liệu ' + source.toLowerCase() + '.'
			},
			hasReadableValue(value) {
				const text = String(value || '').trim()
				return !!text && !/^Chi tiết được truy xuất trực tiếp/i.test(text) && !/^Bảng nguồn:/i.test(text)
			},
			formatDateTime(dt) {
				if (!dt) return 'Chưa có'
				const d = new Date(dt)
				if (isNaN(d.getTime())) return dt
				const dd = String(d.getDate()).padStart(2, '0'), mm = String(d.getMonth() + 1).padStart(2, '0')
				return dd + '/' + mm + '/' + d.getFullYear() + ' ' + String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0') + ':' + String(d.getSeconds()).padStart(2, '0')
			}
		}
	}
</script>

<style scoped>
/* Tạo khoảng cách rõ ràng giữa nút làm mới và chip tổng; số lượng cũng được tách nhẹ khỏi nhãn để dễ đọc ở toolbar hẹp. */
.history-filter-actions {
	gap: 8px !important;
}

.history-total-chip {
	padding-inline: 10px;
}

.history-total-count {
	display: inline-block;
	margin: 0 5px;
}

/* Tiêu đề là nhãn điều hướng của dialog, không phải vùng nội dung cần bôi chọn; giữ chữ trắng ổn định khi người dùng kéo chuột. */
.audit-dialog-title {
	user-select: none;
}

.audit-dialog-title .text-truncate {
	color: #fff !important;
}

/* Nội dung audit được giữ nguyên đầy đủ; chỉ tổ chức lại chữ để các trường dài tự xuống dòng trong ô. */
.audit-detail-table :deep(table) {
	 table-layout: fixed;
}

.audit-detail-table :deep(th) {
	white-space: nowrap;
}

.audit-content-cell {
	vertical-align: top;
	min-width: 0;
}

.audit-content-full {
	white-space: pre-line;
	word-break: break-word;
	line-height: 1.45;
	font-size: 0.875rem;
}

.audit-dialog-heading {
	min-width: 0;
	flex: 1 1 auto;
}

.audit-detail-virtual-table {
	width: 100%;
}

.audit-detail-virtual-table :deep(table) {
	table-layout: fixed;
}

.audit-detail-virtual-table :deep(th),
.audit-detail-virtual-table :deep(td) {
	vertical-align: top;
}

.audit-virtual-content {
	min-width: 0;
	padding: 4px 0;
}

.audit-virtual-content__full {
	max-height: 170px;
	overflow-y: auto;
	white-space: pre-line;
	word-break: break-word;
	line-height: 1.4;
	padding-right: 8px;
}
</style>