<template>
	<div class="tkb-page">
		<v-progress-linear v-if="loading" indeterminate color="primary" />

		<!-- Khi nhúng vào app phụ huynh không có URL param, phải cho chọn đúng học sinh trước khi tải TKB. -->
		<v-card v-if="showStudentSelector" class="mx-3 mt-2 mb-3" variant="outlined" elevation="0">
			<v-card-text class="pa-3">
				<div class="d-flex align-center mb-2">
					<v-icon color="primary" class="mr-2">mdi-account-school-outline</v-icon>
					<div>
						<div class="text-subtitle-2 font-weight-medium">Học sinh</div>
						<div class="text-caption text-medium-emphasis">Chọn học sinh để xem thời khóa biểu</div>
					</div>
				</div>
				<v-select v-model="selectedHocSinhID" :items="studentOptions" item-title="TenHienThi"
					item-value="HocSinhID" label="Học sinh" variant="outlined" density="comfortable"
					hide-details @update:model-value="onSelectHocSinh" />
			</v-card-text>
		</v-card>

		<!-- Chỉ hiển thị nhận diện ở luồng phụ huynh; luồng có HocSinhID giữ nguyên giao diện cũ. -->
		<v-card v-if="HocSinhSelected && !requestedHocSinhID" class="mx-3 mt-2 mb-3" variant="outlined" elevation="0">
			<v-card-text class="d-flex align-center py-3">
				<v-avatar color="primary" size="42" class="mr-3">
					<v-img v-if="studentAvatar" :src="studentAvatar" :alt="studentDisplayName" cover />
					<v-icon v-else color="white">mdi-account-school-outline</v-icon>
				</v-avatar>
				<div class="min-width-0">
					<div class="text-subtitle-1 font-weight-medium text-truncate">{{ studentDisplayName }}</div>
					<div class="text-body-2 text-medium-emphasis">{{ studentInfoSubtitle }}</div>
				</div>
			</v-card-text>
		</v-card>

		<!-- Cho phép phụ huynh đổi giữa bảng tuần và danh sách lịch theo ngày trên cùng màn hình. -->
		<div v-if="showViewModeToggle" class="tkb-view-switch">
			<v-btn-toggle v-model="viewMode" mandatory color="primary" density="comfortable"
				@update:model-value="onViewModeChange">
				<v-btn value="desktop" size="small">
					<v-icon start size="18">mdi-table</v-icon>
					Bảng tuần
				</v-btn>
				<v-btn value="mobile" size="small">
					<v-icon start size="18">mdi-format-list-bulleted</v-icon>
					Theo ngày
				</v-btn>
			</v-btn-toggle>
		</div>

		<!-- key buộc uc-lich khởi tạo lại khi đổi học sinh, tránh giữ lịch của học sinh trước. -->
		<uc-lich v-if="HocSinhSelected" :key="HocSinhSelected.HocSinhID" :HocSinh="HocSinhSelected"
			:inline="true" :isMobile="renderMobile" />
		<uc-empty v-else-if="!loading && !showStudentSelector" text="Không tìm thấy học sinh được phép xem lịch" />
	</div>
</template>

<script>
	export default {
		data() {
		return {
			HocSinhSelected: null,
			DSHocSinh: [],
			selectedHocSinhID: null,
			requestedHocSinhID: null,
			isMobile: false,
			viewMode: 'desktop',
			manualViewMode: false,
			loading: true,
			resizeHandler: null,
			avatarTimestamp: Date.now()
		}
	},
	created() {
		this.updateScreenMode()
		this.loadHocSinh()
	},
	mounted() {
		this.resizeHandler = () => this.updateScreenMode()
		window.addEventListener('resize', this.resizeHandler)
	},
	beforeUnmount() {
		if (this.resizeHandler) window.removeEventListener('resize', this.resizeHandler)
	},
	computed: {
		studentOptions() {
			// Chỉ cho chọn các học sinh API đánh dấu được phép hiển thị; không nhận ID nhập tùy ý.
			return this.DSHocSinh.filter(item => item.IsShow && Number(item.HocSinhID) > 0)
		},
		showStudentSelector() {
			// Có param thì giữ flow mở trực tiếp; không có param và có nhiều học sinh thì bắt buộc chọn.
			return !this.requestedHocSinhID && this.studentOptions.length > 1
		},
		showViewModeToggle() {
			// Chỉ hiện nút đổi layout ở luồng chọn học sinh; route truyền ID phải mở thẳng màn hình đã định.
			return !this.requestedHocSinhID && !!this.HocSinhSelected
		},
		// Luồng phụ huynh dùng bản ghi đã chọn từ API để luôn giữ tên học sinh trên thẻ nhận diện.
		studentDisplayName() {
			const student = this.HocSinhSelected || {}
			return student.HoTen || student.TenHienThi || 'Học sinh'
		},
		// Dùng cùng nguồn avatar với các page học sinh/phụ huynh khác trong project.
		studentAvatar() {
			const student = this.HocSinhSelected || {}
			const avatarBase = vueData.v_Set && vueData.v_Set.urlAvatarHocSinh
			const hocSinhID = student.HocSinhID || student.StudentID
			return avatarBase && hocSinhID
				? avatarBase + hocSinhID + '/' + this.avatarTimestamp
				: ''
		},
		// Khoi là nguồn phân loại cấp học của API phụ huynh: dưới 1 là mầm non, sau đó là các dải khối phổ thông.
		studentInfoSubtitle() {
			const student = this.HocSinhSelected || {}
			const info = []
			const hasKhoi = student.Khoi !== undefined && student.Khoi !== null && String(student.Khoi).trim() !== ''
			const khoi = Number(student.Khoi)
			let levelLabel = ''
			if (student.TenLop) info.push('Lớp ' + student.TenLop)
			if (hasKhoi && Number.isFinite(khoi)) {
				if (khoi < 1) levelLabel = 'Mầm non'
				else if (khoi <= 5) levelLabel = 'Tiểu học'
				else if (khoi <= 9) levelLabel = 'Trung học cơ sở'
				else if (khoi <= 12) levelLabel = 'Trung học phổ thông'
				else levelLabel = 'Khối ' + khoi
			}
			if (!levelLabel) {
				const studyType = String(student.HinhThucHoc ?? '').trim().toUpperCase()
				if (['SN', 'MẦM NON', 'MAM NON'].includes(studyType)) levelLabel = 'Mầm non'
			}
			if (levelLabel) info.push(levelLabel)
			return info.join(' • ') || 'Thời khóa biểu của học sinh'
		},
		renderMobile() {
			return this.viewMode === 'mobile'
		}
	},
	methods: {
		updateScreenMode() {
			// Dùng kích thước màn hình làm mặc định; sau khi người dùng chọn thì không tự ghi đè lựa chọn đó.
			this.isMobile = window.innerWidth < 960
			if (!this.manualViewMode) this.viewMode = this.isMobile ? 'mobile' : 'desktop'
		},
		onViewModeChange(value) {
			// Đánh dấu lựa chọn thủ công để resize cửa sổ không làm đổi layout ngoài ý muốn.
			if (!value) return
			this.manualViewMode = true
			this.viewMode = value
		},
		getRequestedHocSinhID() {
			// FUI đã map query `?HocSinhID=...` vào state chung vueData.HocSinhID.
			const id = Number(vueData.HocSinhID)
			return Number.isFinite(id) && id > 0 ? id : null
		},
		async loadHocSinh() {
			try {
				// fetchPromise dùng vueData.v_Set.apiDomain và trả về payload data của API.
				const apiUrl = `${vueData.v_Set.apiDomain}/student/Calen_GetInfoStudentByPhuHuynhID`.replace(/([^:]\/)\/+/, '$1')
				const requestedID = this.getRequestedHocSinhID()
				this.requestedHocSinhID = requestedID
				const currentUserID = Number(vueData.user?.UserID)
				const isAdminView = vueData.user?.UserID === 'NA0000022'
				const isStudentView = Number(vueData.user?.GroupID) === 3 && currentUserID > 0

				// Route có ID và người dùng thuộc luồng được phép thì truyền thẳng, không cần tải danh sách học sinh.
				const canUseRequestedIDDirectly = requestedID > 0 && (
					isAdminView || (isStudentView && requestedID === currentUserID)
				)
				if (canUseRequestedIDDirectly) {
					this.HocSinhSelected = { HocSinhID: requestedID, StudentID: requestedID, IsShow: true }
					this.selectedHocSinhID = requestedID
					return
				}

				console.log('[thoi-khoa-bieu] API start', { apiUrl, requestedID, user: vueData.user })
				const students = await fetchPromise('student/Calen_GetInfoStudentByPhuHuynhID', {}, { cache: false })
				console.log('[thoi-khoa-bieu] API response', students)
				const normalizedStudents = (Array.isArray(students) ? students : []).map(item => {
					// API Calen dùng StudentID; uc-lich và v-select dùng HocSinhID nên quy đổi một lần tại đây.
					const hocSinhID = item.StudentID ?? item.HocSinhID ?? item.HocSinhId
					// Mầm non được API đánh dấu HinhThucHoc = SN và thường có Khoi = 0,
					// nên phải được tính là hợp lệ dù không có IsShow tường minh.
					const isMamNon = ['SN', 'MẦM NON', 'MAM NON'].includes(
						String(item.HinhThucHoc ?? '').trim().toUpperCase()
					)
					const isShow = item.IsShow === undefined || item.IsShow === null
						? Number(item.Khoi) > 0 || isMamNon
						: [true, 1, '1', 'true'].includes(item.IsShow)
					return {
						...item,
						HocSinhID: hocSinhID,
						IsShow: isShow,
						TenHienThi: typeof item.TenHienThi === 'string' && item.TenHienThi.trim()
							? item.TenHienThi
							: [item.HoTen, item.TenLop ? `Lớp ${item.TenLop}` : null]
							.filter(Boolean)
							.join(' • ') || String(hocSinhID)
					}
				})
				console.log('[thoi-khoa-bieu] normalized students', normalizedStudents.map(item => ({
					HocSinhID: item.HocSinhID,
					StudentID: item.StudentID,
					Khoi: item.Khoi,
					IsShow: item.IsShow
				})))

				// Dữ liệu học sinh phải lấy từ API/quyền hiện hành; không còn fallback ID tĩnh dùng cho giai đoạn test.
				this.DSHocSinh = normalizedStudents
				const visibleStudents = normalizedStudents.filter(item => item.IsShow && Number(item.HocSinhID) > 0)

				// Có param thì chọn đúng học sinh trong danh sách API; không có param thì chỉ tự chọn khi danh sách có đúng một học sinh.
				this.HocSinhSelected = requestedID
					? visibleStudents.find(item => Number(item.HocSinhID) === requestedID) || null
					: visibleStudents.length === 1 ? visibleStudents[0] : null
				this.selectedHocSinhID = this.HocSinhSelected?.HocSinhID ?? null

				// Admin NA0000022 được phép mở dashboard theo HocSinhID trên URL; học sinh thường chỉ dùng UserID của chính mình.
				const canUseRequestedID = isAdminView
					? requestedID > 0
					: isStudentView && (!requestedID || requestedID === currentUserID)
				if (!this.HocSinhSelected && canUseRequestedID) {
					const hocSinhID = isAdminView ? requestedID : currentUserID
					this.HocSinhSelected = { HocSinhID: hocSinhID, StudentID: hocSinhID, IsShow: true }
					this.selectedHocSinhID = hocSinhID
					console.log('[thoi-khoa-bieu] privileged/student fallback', { isAdminView, HocSinhID: hocSinhID })
				} else if (!this.HocSinhSelected && isStudentView && requestedID !== currentUserID) {
					console.warn('[thoi-khoa-bieu] rejected mismatched HocSinhID', { requestedID, currentUserID })
				}
				console.log('[thoi-khoa-bieu] selected student', this.HocSinhSelected)
			} catch (error) {
				console.error('[thoi-khoa-bieu] API error', error)
				// Khi API lỗi, để màn hình rỗng thay vì hiển thị học sinh mẫu hoặc ID truyền tĩnh.
				this.DSHocSinh = []
				this.HocSinhSelected = null
			} finally {
				this.loading = false
			}
		},
		onSelectHocSinh(value) {
			// Chỉ nhận lựa chọn từ studentOptions, sau đó uc-lich mới được khởi tạo để gọi API TKB.
			const selectedID = Number(value)
			this.HocSinhSelected = this.studentOptions.find(item => Number(item.HocSinhID) === selectedID) || null
		}
	}
	}
</script>

<style scoped>
.tkb-page {
	/* Chiều cao vừa khít nội dung, không ép min-height để không tạo scroll lồng trong iframe */
	width: 100%;
	overflow: visible;
}

.tkb-view-switch {
	display: flex;
	justify-content: flex-end;
	padding: 8px 12px 4px;
}

@media (max-width: 599px) {
	.tkb-view-switch {
		justify-content: center;
	}
}
</style>