<template>
	<Global>
		<template #header>
			<v-card>
				<v-card-title class="d-flex align-center flex-wrap ga-2">
					<span>{{ TitlePage }} • {{ TitleCap }}</span>
					<v-spacer />
					<v-btn-toggle v-model="isEn" size="small" class="ml-auto">
						<v-btn :value="false" :disabled="!isEn" :color="!isEn ? 'green' : 'white'" @click="setLanguage(false)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="30" />
						</v-btn>
						<v-btn :value="true" :disabled="isEn" :color="isEn ? 'green' : 'white'" @click="setLanguage(true)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="30" />
						</v-btn>
					</v-btn-toggle>
				</v-card-title>
				<v-card-text>
					<v-row align="center">
						<v-col cols="12" sm="3">
							<v-select :key="'khoi_' + isEn" v-model="KhoiItem" :label="isEn ? 'Select grade' : 'Chọn khối'" :items="DSKhoi" :item-title="formatKhoiHienThi"
								item-value="KhoiID" return-object="" :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
								<template #selection="{ item }">
									<span>{{ formatKhoiHienThi(item) }}</span>
								</template>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="formatKhoiHienThi(item)"></v-list-item>
								</template>
							</v-select>
						</v-col>
						<v-col cols="12" sm="3">
							<v-select :key="'lop_' + isEn" v-model="LopItem" :label="isEn ? 'Select class' : 'Chọn lớp'" :items="DSLop" item-title="TenLop"
								item-value="LopID" :disabled="!KhoiItem" return-object="" :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
							</v-select>
						</v-col>
						<v-col class="d-flex align-center ga-2 flex-wrap">
							<v-btn @click="getHocSinh()" variant="outlined" color="primary" :disabled="!LopItem">
								<v-icon start="">mdi-reload</v-icon>{{ isEn ? 'Refresh' : 'Làm mới' }}
							</v-btn>
							<v-btn @click="insHocSinh()" color="teal" :disabled="DSHocSinhSelected.length === 0 || isLoadingTransferReview" :loading="isLoadingTransferReview">
								<v-icon start="">mdi-sync</v-icon>
								{{ isEn ? 'Update student list' : 'Cập nhật DS học sinh' }}
								<v-badge v-if="DSHocSinhSelected.length > 0" :content="DSHocSinhSelected.length"
									color="white" text-color="teal" inline="">
								</v-badge>
							</v-btn>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</template>

		<!-- Thay toàn bộ phần template v-data-table -->
		<v-data-table v-model="DSHocSinhSelected" :headers="headers" :items="items" :show-select="true" :items-per-page="-1"
			:loading="isLoadingHocSinh" :loading-text="isEn ? 'Loading student list...' : 'Đang tải danh sách học sinh...'"
			:items-per-page-text="isEn ? 'Items per page:' : 'Dữ liệu trên mỗi trang'"
			:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'"
			:item-value="(item) => item" hide-default-footer style="max-height: calc(100dvh - 77px); overflow-y: auto;">
			<!-- STT -->
			<template #item.STT="{ item }">
				<span class="text-caption text-medium-emphasis font-weight-medium">{{ item.STT }}</span>
			</template>

			<!-- Thông tin học sinh — gộp avatar + tên + ID + tên tiếng Anh vào 1 hàng ngang -->
			<template #item.ThongTinHocSinh="{ item }">
				<div class="d-flex align-center ga-3 py-2">
					<v-avatar :size="52" class="elevation-2 flex-shrink-0 cursor-pointer"
						v-on:click="openAvatarDialog(item)" v-tooltip="isEn ? 'View full photo' : 'Xem ảnh đầy đủ'">
						<v-img :src="vueData.v_Set.urlAvatarHocSinh + item.HocSinhID + '/' + Date.now()">
						</v-img>
					</v-avatar>
					<div class="d-flex flex-column ga-1">
						<span class="font-weight-bold text-body-2">{{ item.HoTen }}</span>
						<div class="d-flex align-center ga-2 flex-wrap">
							<v-chip size="x-small" variant="tonal" color="primary" label="">
								{{ item.HocSinhID }}
							</v-chip>
							<v-chip size="x-small" variant="tonal" color="secondary" label="">
								SDB: {{ item.SoDanhBo ?? '—' }}
							</v-chip>
						</div>
						<div class="d-flex align-center ga-1">
							<span class="text-caption text-success font-weight-medium">
								{{ item.EnglishName ?? '—' }}
							</span>
							<v-btn icon="mdi-square-edit-outline" color="success" variant="text" size="x-small"
								v-tooltip="isEn ? 'Update English name' : 'Cập nhật tên tiếng Anh'" @click="onOpenModalEditProfile(item)">
							</v-btn>
						</div>
					</div>
				</div>
			</template>

			<!-- Tình trạng KQHT -->
			<template #item.TinhTrangKQHT="{ item }">
				<v-chip v-if="item.isExistInKQHT" :color="renderColorTinhTrang(item.TinhTrangKQHT)" size="small"
					label="">
					<v-icon start="" size="13">mdi-school</v-icon>
					{{ formatTinhTrang(item.TenTinhTrangKQHT, item.TinhTrangKQHT) }}
				</v-chip>
				<v-chip v-else="" color="warning" variant="tonal" size="small" label="">
					<v-icon start="" size="13">mdi-alert-outline</v-icon>
					{{ isEn ? 'Not in Academic Results' : 'Chưa có trong KQHT' }}
				</v-chip>
			</template>

			<!-- Tình trạng QLHS -->
			<template #item.TinhTrangQLHS="{ item }">
				<v-chip :color="renderColorTinhTrang(item.TinhTrangQLHS)" size="small" label="">
					<v-icon start="" size="13">mdi-account-check</v-icon>
					{{ formatTinhTrang(item.TenTinhTrangQLHS, item.TinhTrangQLHS) }}
				</v-chip>
			</template>

			<!-- Nhận xét chuẩn bị niên khóa sau -->
			<template #item.NhanXet_ChuanBiNienKhoaSau="{ item }">
				<div v-if="item.NhanXet_ChuanBiNienKhoaSau" class="py-2 px-1" style="max-width: 360px;">
					<div class="text-body-2"
						style="display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; line-height: 1.4;">
						{{ item.NhanXet_ChuanBiNienKhoaSau }}
					</div>
				</div>
				<v-chip v-else size="x-small" variant="tonal" color="grey">
					{{ isEn ? 'No comments yet' : 'Chưa có nhận xét' }}
				</v-chip>
			</template>

			<!-- Xem chi tiết -->
			<template #item.XemChiTiet="{ item }">
				<v-btn @click="localStorageSetItem(item)" icon="mdi-eye-outline" variant="text" color="primary"
					size="small" v-tooltip="(isEn ? 'View details ' : 'Xem chi tiết ') + item.HoTen">
				</v-btn>
			</template>
		</v-data-table>

		<uc-modal-edit-profile-shared @refresh="getHocSinh(true)" />

		<!-- Rà soát lớp và dữ liệu liên quan trước khi đồng bộ danh sách học sinh. -->
		<v-dialog v-model="isOpenTransferReview" max-width="1000">
			<v-card class="pa-0">
				<v-toolbar dense flat>
					<v-toolbar-title>{{ isEn ? 'Review class update' : 'Rà soát cập nhật lớp' }}</v-toolbar-title>
					<v-spacer />
					<v-btn icon="" @click="closeTransferReview"><v-icon>mdi-close</v-icon></v-btn>
				</v-toolbar>
				<v-card-text class="px-4 py-3">
					<v-alert type="info" variant="tonal" density="compact" class="mb-3">
						<strong>{{ isEn ? 'Destination class:' : 'Lớp nhận:' }}</strong>
						{{ LopItem?.TenLop || LopItem?.LopID }}
						<span class="mx-1">•</span>
						{{ transferReviewItems.length }} {{ isEn ? 'selected students' : 'học sinh được chọn' }}.
						{{ isEn ? 'This action syncs the student roster only. Grades, groups, and subsystem histories are not copied or reassigned automatically.' : 'Thao tác xác nhận chỉ đồng bộ danh sách lớp; điểm, nhóm học và hồ sơ các phân hệ không tự sao chép hoặc đổi sang lớp mới.' }}
					</v-alert>

					<v-alert v-if="hasClassTransfers" type="warning" variant="tonal" density="compact" class="mb-3">
						{{ isEn ? 'The database has no dedicated class transfer history table. If an existing membership row is updated, its previous class may no longer be available in the roster table after this action.' : 'DB chưa có bảng lịch sử chuyển lớp riêng. Nếu bản ghi phân lớp hiện tại bị cập nhật, lớp cũ có thể không còn trong bảng danh sách lớp sau thao tác này.' }}
					</v-alert>

					<div class="overflow-y-auto" style="max-height: 52vh;">
						<v-card v-for="student in transferReviewItems" :key="student.HocSinhID" variant="outlined" class="pa-3 mb-2">
							<div class="d-flex align-center flex-wrap ga-2 mb-2">
								<div class="font-weight-bold">{{ student.HoTen }}</div>
								<v-chip size="small" variant="tonal" label="">{{ student.HocSinhID }}</v-chip>
								<v-chip v-if="student.IsChuyenLop" size="small" color="warning" variant="tonal" label="">
									{{ isEn ? 'Class transfer' : 'Có chuyển lớp' }}
								</v-chip>
								<v-chip v-else size="small" color="success" variant="tonal" label="">
									{{ student.TenLopCu ? (isEn ? 'Same class' : 'Giữ nguyên lớp') : (isEn ? 'No current class' : 'Chưa có lớp hiện tại') }}
								</v-chip>
								<v-chip v-if="Number(student.SoLopDangHoc) > 1" size="small" color="warning" variant="tonal" label="">
									{{ student.SoLopDangHoc }} {{ isEn ? 'active class records' : 'bản ghi lớp đang hiệu lực' }}
								</v-chip>
							</div>
							<div class="text-body-2 mb-2">
								<strong>{{ isEn ? 'Old class:' : 'Lớp cũ:' }}</strong> {{ student.TenLopCu || (isEn ? 'No active class record' : 'Chưa có bản ghi lớp đang học') }}
								<v-icon size="small" class="mx-1">mdi-arrow-right</v-icon>
								<strong>{{ isEn ? 'New class:' : 'Lớp mới:' }}</strong> {{ student.TenLopMoi || LopItem?.TenLop || LopItem?.LopID }}
							</div>
					<!-- Các số đếm chỉ rà nơi dữ liệu đang gắn; dialog không tự sửa hay sao chép hồ sơ sang lớp mới. -->
							<v-row dense>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'Academic results' : 'Điểm KQHT' }}</strong></div>
									<div class="text-caption">{{ isEn ? 'Old class' : 'Lớp cũ' }}: {{ student.SoDiemLopCu || 0 }} • {{ isEn ? 'new class' : 'lớp mới' }}: {{ student.SoDiemLopMoi || 0 }} • {{ isEn ? 'study groups' : 'nhóm học' }}: {{ student.SoDiemNhomDangHoc || 0 }} • {{ isEn ? 'English/other score rows' : 'điểm Tiếng Anh/bảng khác' }}: {{ (student.SoDiemTALopCu || 0) + (student.SoDiemBangKhacLopCu || 0) }}</div>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'Study groups' : 'Nhóm học' }}</strong></div>
									<div class="text-caption">{{ student.SoNhomDangHoc || 0 }} {{ isEn ? 'active groups' : 'nhóm đang học' }} • {{ student.SoNhomLopCu || 0 }} {{ isEn ? 'with old class ID' : 'nhóm còn ghi mã lớp cũ' }}</div>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'LMS assignments' : 'Bài giao LMS' }}</strong></div>
									<div class="text-caption">{{ student.SoBaiTapLopCu || 0 }} {{ isEn ? 'open on old class' : 'bài đang mở ở lớp cũ' }} • {{ student.SoBaiNopLopCu || 0 }} {{ isEn ? 'submissions' : 'bài nộp' }} • {{ student.SoBaiGiaoTrucTiep || 0 }} {{ isEn ? 'direct assignments' : 'bài giao riêng' }} • {{ student.SoKetQuaLMSLopCu || 0 }} {{ isEn ? 'question results' : 'kết quả câu hỏi' }}</div>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'Monthly comments' : 'Nhận xét tháng' }}</strong></div>
									<div class="text-caption">{{ student.SoNhanXetThangLopCu || 0 }} {{ isEn ? 'records on old class' : 'bản ghi ở lớp cũ' }}</div>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'Homeroom book' : 'Sổ GVCN' }}</strong></div>
									<div class="text-caption">{{ student.SoTheoDoiGVCNLopCu || 0 }} {{ isEn ? 'records across homeroom book sections' : 'dòng ở các mục Sổ GVCN' }}</div>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'Other records' : 'Hồ sơ khác' }}</strong></div>
									<div class="text-caption">{{ isEn ? 'Absence' : 'Báo nghỉ' }}: {{ student.SoBaoNghi || 0 }} • {{ isEn ? 'awards/evaluations' : 'khen thưởng/đánh giá' }}: {{ student.SoDanhGiaKhenThuong || 0 }} • {{ isEn ? 'contests/certificates' : 'cuộc thi/chứng nhận' }}: {{ (student.SoCuocThiLopCu || 0) + (student.SoChungNhanLopCu || 0) }}</div>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'Parent feedback and score appeals' : 'Ý kiến phụ huynh / phúc khảo' }}</strong></div>
									<div class="text-caption">{{ isEn ? 'Parent feedback' : 'Ý kiến phụ huynh' }}: {{ student.SoYkienPhuHuynhLopCu || 0 }} • {{ isEn ? 'appeals/rejections' : 'phúc khảo/từ chối điểm' }}: {{ (student.SoPhucKhaoLopCu || 0) + (student.SoTuChoiLopCu || 0) }}</div>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'English assessment records' : 'Hồ sơ đánh giá Tiếng Anh' }}</strong></div>
									<div class="text-caption">IELTS: {{ student.SoIeltsLopCu || 0 }} • Cambridge: {{ student.SoBaoCaoCambridge || 0 }}</div>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'Device bookings' : 'Đăng ký thiết bị' }}</strong></div>
									<div class="text-caption">{{ student.SoDangKyLaptopLopCu || 0 }} {{ isEn ? 'records linked to the old class' : 'bản ghi gắn với lớp cũ' }}</div>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<div class="text-body-2"><strong>{{ isEn ? 'Student LMS history' : 'Lịch sử LMS của học sinh' }}</strong></div>
									<div class="text-caption">{{ student.SoTienDoLMSCaNhan || 0 }} {{ isEn ? 'progress rows' : 'dòng tiến độ cá nhân' }} • {{ student.SoThanhTichLMSNamHoc || 0 }} {{ isEn ? 'achievements this year' : 'thành tích năm học' }}. {{ isEn ? 'These stay with the student account.' : 'Dữ liệu này gắn với hồ sơ học sinh.' }}</div>
								</v-col>
							</v-row>
						</v-card>
					</div>

					<v-checkbox v-model="isTransferReviewAccepted" density="compact" hide-details class="mt-2"
					:label="isEn ? 'I reviewed the old and new classes and understand subsystem data will not be copied automatically.' : 'Tôi đã rà lớp cũ, lớp mới và hiểu dữ liệu các phân hệ không tự chuyển theo.'" />
				</v-card-text>
				<v-card-actions class="mr-1 mb-1">
					<v-spacer />
					<v-btn variant="text" :disabled="isSavingStudentList" @click="closeTransferReview">{{ isEn ? 'Cancel' : 'Hủy' }}</v-btn>
					<v-btn color="primary" variant="text" :loading="isSavingStudentList" :disabled="!isTransferReviewAccepted || isSavingStudentList" @click="confirmInsHocSinh">
						<v-icon start="">mdi-sync</v-icon>{{ isEn ? 'Sync class list' : 'Đồng bộ danh sách lớp' }}
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<v-dialog v-model="isOpenAvatarDialog" max-width="900">
			<div style="position: relative; display: block; line-height: 0; width: fit-content; margin: 0 auto;">
				<img :src="AvatarImageUrl" :alt="isEn ? 'Student photo' : 'Ảnh học sinh'"
					style="display: block; max-height: 90vh; width: auto; height: auto;" />
				<v-btn icon="mdi-close" variant="text" color="white"
					style="position: absolute; top: 8px; right: 8px; z-index: 1;"
					v-on:click="isOpenAvatarDialog = false" />
			</div>
		</v-dialog>
	</Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef'],
	
		data() {
			const isEn = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
			if (this.$i18n) {
				this.$i18n.locale = isEn ? 'en' : 'vi';
			}
			return {
				isEn,
				vueData,
				items: [],
				DSKhoi: [],
				DSLop: [],
				KhoiItem: null,
				LopItem: null,
				DSHocSinhSelected: [],
				isOpenTransferReview: false,
				isLoadingTransferReview: false,
				isSavingStudentList: false,
				isTransferReviewAccepted: false,
				transferReviewItems: [],
				// Giữ table ở trạng thái loading trong suốt thời gian tải dữ liệu theo lớp.
				isLoadingHocSinh: false,
				StudentProfile: null,
				isOpenModalEditProfile: false,
				isOpenAvatarDialog: false,
				AvatarStudent: null,
			}
		},
	
		computed: {
			headers() {
				return [
					{ title: "#", value: "STT", align: "center", width: 56 },
					{ title: this.isEn ? "Student" : "Học sinh", value: "ThongTinHocSinh", align: "start", minWidth: 280 },
					{ title: this.isEn ? "LMS Status" : "Trạng thái LMS", value: "TinhTrangKQHT", align: "center", width: 180 },
					{ title: this.isEn ? "SIS Status" : "Trạng thái QLHS", value: "TinhTrangQLHS", align: "center", width: 180 },
					{ title: this.isEn ? "Next school year prep notes" : "Nhận xét chuẩn bị niên khóa sau", value: "NhanXet_ChuanBiNienKhoaSau", align: "start", minWidth: 280 },
					{ title: "", value: "XemChiTiet", align: "center", width: 120, sortable: false },
				]
			},
			TitleCap() {
				const capId = parseInt(vueData.capid || vueData.CapID);
				if (this.isEn) {
					if (capId === 1) return 'Primary School';
					if (capId === 2) return 'Secondary School';
					if (capId === 3) return 'High School';
					return `Level ${capId}`;
				}
				return renderText(capId);
			},
			TitlePage() {
				if (this.isEn) {
					return 'Student List';
				}
				return getTitlePageByURL(window.location.pathname + window.location.search);
			},
			AvatarImageUrl() {
				return this.AvatarStudent?.HocSinhID ? vueData.v_Set?.urlAvatarHocSinh + this.AvatarStudent.HocSinhID + '/' + Date.now() : ''
			},
			hasClassTransfers() {
				return this.transferReviewItems.some(x => x.IsChuyenLop)
			},
		},
	
		watch: {
			"vueData.NienKhoa": {
				immediate: true,
				handler(newVal) {
					if (!newVal) return
					this.DSKhoi = []
					this.KhoiItem = null
					this.LopItem = null
					this.items = []
					this.getKhoi(true)
				}
			},
			KhoiItem(val) {
				if (!val) return
				this.LopItem = null
				this.items = []
				this.getLop(true)
			},
			LopItem(val) {
				if (!val) return
				this.items = []
				this.getHocSinh(true)
			},
		},
	
		mounted() {
			window.addEventListener('storage', (e) => {
				if (e.key === 'IsLanguage') {
					const isEn = JSON.parse(e.newValue) ?? false;
					this.isEn = isEn;
					if (this.$i18n) this.$i18n.locale = isEn ? 'en' : 'vi';
				}
			});
		},

	
		methods: {
			formatKhoiHienThi(item) {
				if (!item) return '';
				const raw = (item && item.raw) ? item.raw : item;
				const name = typeof raw === 'object' ? (raw.TenKhoiHoc || raw.title) : raw;
				if (!name) return '';
				if (!this.isEn) return name;
				return String(name).replace(/Khối/gi, 'Grade');
			},

			setLanguage(val) {
				this.isEn = val;
				if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi';
				localStorage.setItem('IsLanguage', JSON.stringify(val));
			},

			openAvatarDialog(student) {
				this.AvatarStudent = student
				this.isOpenAvatarDialog = true
			},

			async getKhoi(forceRefresh = false) {
				this.DSKhoi = await fetchPromise("lms/KhoiHocByCapHoc_Get", { 
					CapID: vueData.CapID,
					HocKi: vueData.NienKhoaItem.HocKi,
					NienKhoa: vueData.NienKhoa,
					 }, { forceRefresh })
			},
	
			async getLop(forceRefresh = false) {
				const _dsLop = await fetchPromise("lms/Lop_Get_ByKhoiID", {
					NienKhoa: vueData.NienKhoa,
					HocKi: vueData.NienKhoaItem?.HocKi,
					KhoiID: this.KhoiItem.KhoiID,
				}, { forceRefresh })
				this.DSLop = _dsLop.filter(x => x.IsNhom === false)
			},
	
			async getHocSinh(forceRefresh = false) {
				this.isLoadingHocSinh = true
				this.DSHocSinhSelected = []
				try {
					const isLopToHop = Number(vueData.CapID) === 3
						&& (this.LopItem?.IsLopToHop === true || Number(this.LopItem?.IsLopToHop) === 1)
					const hocSinhLopSource = isLopToHop
						? { url: 'student/LMS_GetHocSinhLop', params: { LopID: this.LopItem?.LopID, NienKhoa: vueData.NienKhoa } }
						: { url: 'student/LMS_GetHocSinhLopChuNhiem', params: { NienKhoa: vueData.NienKhoa } }
					const [DSHocSinhLop, DSHocSinh_LMS, DSHocSinhLop_LMS, DSNhanXetChuanBiNienKhoaSau] = await fetchBatchPromise([
						{ url: 'lms/HocSinhLop_Get', params: { LopID: this.LopItem?.LopID, NienKhoa: vueData.NienKhoa } },
						{ url: 'student/LMS_GetHocSinh', params: { LopID: this.LopItem?.LopID, NienKhoa: vueData.NienKhoa } },
						hocSinhLopSource,
						{
							url: 'lms/NhanXet_HocSinh_NienKhoaSau_Get_ByLopID',
							params: { LopID: this.LopItem?.LopID, NienKhoa: vueData.NienKhoa },
							opts: { suppressError: true },
						},
					], { forceRefresh })
		
					this.items = this.renderDSHocSinh(DSHocSinhLop, DSHocSinh_LMS, DSHocSinhLop_LMS, DSNhanXetChuanBiNienKhoaSau)
				} finally {
					this.isLoadingHocSinh = false
				}
			},
	
			// Đọc trước tình trạng lớp và dữ liệu các phân hệ để người dùng thấy rõ điểm sẽ giữ ở lớp nào.
			insHocSinh() {
				const payload = this.DSHocSinhSelected.map(x => ({
					...x,
					TinhTrang: x.TinhTrangQLHS,
					TenTinhTrang: x.TenTinhTrangQLHS,
				}))
				const HocSinhIDs = [...new Set(payload.map(x => Number(x.HocSinhID)).filter(x => Number.isFinite(x) && x > 0))]
				if (!HocSinhIDs.length || !this.LopItem?.LopID) return
				this.isLoadingTransferReview = true
				this.isTransferReviewAccepted = false
				fetchPromise('lms/HocSinhLop_ChuyenLop_Preview', {
					Json_HocSinhID: JSON.stringify(HocSinhIDs),
					LopMoiID: this.LopItem.LopID,
					NienKhoa: vueData.NienKhoa,
				}, { cache: false, suppressError: true }).then(rows => {
					const previewRows = Array.isArray(rows) ? rows : []
					const previewByID = new Map(previewRows.map(x => [Number(x.HocSinhID), x]))
					const missingIDs = HocSinhIDs.filter(id => !previewByID.has(id))
					if (missingIDs.length) throw new Error((this.isEn ? 'Could not check students: ' : 'Chưa rà được học sinh: ') + missingIDs.join(', '))
					this.transferReviewItems = payload.map(student => {
						const preview = previewByID.get(Number(student.HocSinhID))
						return {
							...preview,
							HoTen: student.HoTen || preview.HoTen,
							TenLopMoi: preview.TenLopMoi || this.LopItem.TenLop || String(this.LopItem.LopID),
							IsChuyenLop: !!preview.LopCuID && String(preview.LopCuID) !== String(this.LopItem.LopID),
						}
					})
					const hasExistingData = row => [
						row.SoDiemLopCu, row.SoDiemLopMoi, row.SoDiemNhomDangHoc,
						row.SoDiemTALopCu, row.SoDiemBangKhacLopCu,
						row.SoNhomDangHoc, row.SoBaiTapLopCu, row.SoBaiNopLopCu,
						row.SoBaiGiaoTrucTiep, row.SoKetQuaLMSLopCu,
						row.SoNhanXetThangLopCu, row.SoTheoDoiGVCNLopCu,
						row.SoBaoNghi, row.SoDanhGiaKhenThuong,
						row.SoYkienPhuHuynhLopCu, row.SoIeltsLopCu, row.SoBaoCaoCambridge,
						row.SoCuocThiLopCu, row.SoChungNhanLopCu, row.SoDangKyLaptopLopCu,
						row.SoPhucKhaoLopCu, row.SoTuChoiLopCu, row.SoTienDoLMSCaNhan,
						row.SoThanhTichLMSNamHoc,
					].some(value => Number(value) > 0)
					const needsReview = this.transferReviewItems.some(row =>
						row.IsChuyenLop || (!row.LopCuID && hasExistingData(row))
					)
					if (needsReview) this.isOpenTransferReview = true
					else this.saveHocSinhList(payload)
				}).catch(err => {
					showMessage({ title: this.isEn ? 'Unable to review class update' : 'Không rà soát được việc cập nhật lớp', message: err?.message || (this.isEn ? 'Please retry before syncing.' : 'Vui lòng thử lại trước khi đồng bộ.') })
				}).then(() => {
					this.isLoadingTransferReview = false
				})
			},

			closeTransferReview() {
				if (this.isSavingStudentList) return
				this.isOpenTransferReview = false
				this.isTransferReviewAccepted = false
			},

			confirmInsHocSinh() {
				if (!this.isTransferReviewAccepted || this.isSavingStudentList) return
				const payload = this.DSHocSinhSelected.map(x => ({
					...x,
					TinhTrang: x.TinhTrangQLHS,
					TenTinhTrang: x.TenTinhTrangQLHS,
				}))
				this.saveHocSinhList(payload)
			},

			// Phân tách bước ghi để học sinh mới đi thẳng, còn chuyển lớp phải qua dialog rà soát trước.
			saveHocSinhList(payload) {
				if (this.isSavingStudentList) return
				// API nhập lớp hiện ghi danh sách thành viên; các phân hệ lịch sử phải theo đúng phạm vi riêng của chúng.
				const promise = Promise.all([
					fetchPromise('lms/IO_IN_HocSinh_Ins', { HocSinhObjArr: payload }, { cache: false, suppressError: true }),
					fetchPromise('lms/IO_IN_HocSinhLop_Ins', { HocSinhLopObjArr: payload, NienKhoa: vueData.NienKhoa }, { cache: false, suppressError: true }),
				])
				this.isSavingStudentList = true
				this.snackbarRef.value.showPromise(promise, {
					loadingText: this.isEn ? `Updating ${payload.length} students...` : `Đang cập nhật ${payload.length} học sinh...`,
					onSuccess: () => ({
						text: this.isEn ? `Updated ${payload.length} students successfully!` : `Cập nhật ${payload.length} học sinh thành công!`,
						color: 'success',
						prependIcon: 'mdi-check-circle-outline',
						timeout: 3000,
						timer: 'white',
					}),
					onError: err => ({
						text: this.isEn ? `Update failed: ${err?.message ?? 'Unknown error'}` : `Cập nhật thất bại: ${err?.message ?? 'Lỗi không xác định'}`,
						color: 'error',
						prependIcon: 'mdi-alert-circle-outline',
						timeout: 5000,
						timer: 'white',
						reverseTimer: true,
					}),
				})
				promise.then(() => {
					this.isOpenTransferReview = false
					this.getHocSinh(true)
				}).then(() => {
					this.isSavingStudentList = false
				}, () => {
					this.isSavingStudentList = false
				})
			},
	
			onOpenModalEditProfile(item) {
				vueData.StudentProfile = { ...item }
				vueData.isOpenModalEditProfile = true
			},
	
			localStorageSetItem(item) {
				if (!localStorage.getItem('tabBottomNavigation')) localStorage.setItem('tabBottomNavigation', 0)
				if (!localStorage.getItem('Semester')) localStorage.setItem('Semester', 1)
				localStorage.setItem('IsPassRoleParent', true)
	
				this.iframeRef.value.openWindow({
					title: (this.isEn ? 'View details: ' : 'Xem chi tiết ') + item.HoTen,
					url: `/ph-report?HocSinhID=${item.HocSinhID}`
				})
			},
	
			formatTinhTrang(text, statusId) {
				if (!text) return this.isEn ? 'None' : 'Không có';
				if (!this.isEn) return text;
				let formatted = String(text);
				if (statusId === 0 || /đang học/i.test(formatted)) return 'Studying';
				if (statusId === 1 || /nghỉ học/i.test(formatted)) return 'Dropped out';
				if (statusId === 2 || /tốt nghiệp/i.test(formatted)) return 'Graduated';
				return formatted
					.replace(/Đang học/gi, 'Studying')
					.replace(/Nghỉ học/gi, 'Dropped out')
					.replace(/Tốt nghiệp/gi, 'Graduated')
					.replace(/Chuyển trường/gi, 'Transferred')
					.replace(/Bảo lưu/gi, 'Deferred')
					.replace(/Không có/gi, 'None');
			},

			renderColorTinhTrang(TinhTrang) {
				if (TinhTrang === 0) return 'green'
				if (TinhTrang === 1) return 'red'
				if (TinhTrang === 2) return 'success'
				return ''
			},
	
			renderDSHocSinh(DSHocSinhLop, DSHocSinh_LMS, DSHocSinhLop_LMS, DSNhanXetChuanBiNienKhoaSau = []) {
				const eduBotHocSinhLop = []
				const currentDSHocSinhLop_LMS = DSHocSinhLop_LMS.filter(x => x.LopID == this.LopItem.LopID)
				const mapNhanXetChuanBi = new Map((DSNhanXetChuanBiNienKhoaSau ?? []).map(x => [x.HocSinhID, x]))
	
				for (const hsl of currentDSHocSinhLop_LMS) {
					const hs = DSHocSinh_LMS.find(x => x.HocSinhID === hsl.HocSinhID)
					if (hs) eduBotHocSinhLop.push({ ...hsl, ...hs })
				}
	
				const uniqueHocSinhID = [...new Set(eduBotHocSinhLop.map(x => x.HocSinhID))]
	
				const items = uniqueHocSinhID.map(id => {
					const hocSinh = DSHocSinhLop.find(x => x.HocSinhID === id)
					const hocSinhLMS = eduBotHocSinhLop.find(x => x.HocSinhID === id)
					const nhanXetChuanBi = mapNhanXetChuanBi.get(id)
					let obj = { isExistInKQHT: !!hocSinh }
	
					if (hocSinh) {
						Object.assign(obj, {
							HSLopID: hocSinh.HSLopID,
							LopID: hocSinh.LopID,
							HocSinhID: hocSinh.HocSinhID,
							HoTen: hocSinh.Ho + ' ' + hocSinh.Ten,
							Ho: hocSinh.Ho,
							Ten: hocSinh.Ten,
							NgaySinh: hocSinh.NgaySinh,
							Nu: hocSinh.Nu,
							TinhTrangKQHT: hocSinh.TinhTrang,
							TenTinhTrangKQHT: hocSinh.TinhTrang === 2 ? (this.isEn ? 'Graduated' : 'Nghỉ học (Tốt nghiệp)') : hocSinh.TenTinhTrang,
							EnglishName: hocSinh.EnglishName,
						})
					}
	
					if (hocSinhLMS) {
						Object.assign(obj, {
							HSLopID: hocSinhLMS.HSLopID,
							LopID: hocSinhLMS.LopID,
							HocSinhID: hocSinhLMS.HocSinhID,
							HoTen: hocSinhLMS.Ho + ' ' + hocSinhLMS.Ten,
							Ho: hocSinhLMS.Ho,
							Ten: hocSinhLMS.Ten,
							NgaySinh: hocSinhLMS.NgaySinh,
							Nu: hocSinhLMS.Nu,
							TinhTrangQLHS: hocSinhLMS.TinhTrang,
							TenTinhTrangQLHS: hocSinhLMS.TinhTrang === 2 ? (this.isEn ? 'Graduated' : 'Nghỉ học (Tốt nghiệp)') : hocSinhLMS.TenTinhTrang,
							SoDanhBo: hocSinhLMS.SoDanhBo,
							CreateUser: hocSinhLMS.CreateUser,
							CreateTime: hocSinhLMS.CreateTime,
							UpdateUser: hocSinhLMS.UpdateUser,
							UpdateTime: hocSinhLMS.UpdateTime,
						})
					}
	
					obj.NhanXet_ChuanBiNienKhoaSau = nhanXetChuanBi?.NhanXet_ChuanBiNienKhoaSau ?? ''
	
					return obj
				})
	
				return items
					.sort((a, b) => {
						const soA = isNaN(a.SoDanhBo) ? a.SoDanhBo : parseInt(a.SoDanhBo)
						const soB = isNaN(b.SoDanhBo) ? b.SoDanhBo : parseInt(b.SoDanhBo)
						if (soA !== soB) return soA < soB ? -1 : 1
						return (a.Ten?.toLowerCase() || '').localeCompare(b.Ten?.toLowerCase() || '')
					})
					.map((x, i) => ({ ...x, STT: i + 1, HoTen: x.Ho + ' ' + x.Ten }))
			},
		},
	}
</script>