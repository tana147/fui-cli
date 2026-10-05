<template>
	<Global>
		<uc-navigation-drawer v-model:activeKey="activeKey" v-model:activeMonHocID="activeMonHocID"
			:studentInfoDetail="studentInfoDetail" :avatarStudent="avatarStudent" :subjectProgress="subjectProgress"
			v-model:isHocSinhTrungHoc="isHocSinhTrungHoc" :version :isMobile>

			<!-- ── TOPBAR (desktop only) ── -->
			<template #topbar>
				<div class="topbar">
					<div class="topbar-icon">
						<v-icon size="18" color="white">{{ activePageIcon }}</v-icon>
					</div>
					<div class="topbar-text">
						<div class="topbar-title">{{ activePageTitle }}</div>
						<div v-if="topbarCtx.subtitle" class="topbar-subtitle">{{ topbarCtx.subtitle }}</div>
					</div>
					<div class="topbar-date">
						{{ new Date().toLocaleDateString('vi-VN', { weekday: 'long', day: '2-digit', month: '2-digit',
						year: 'numeric' }) }}
					</div>
					<v-btn v-if="topbarCtx.onRefresh" size="small" variant="text" icon="mdi-refresh"
						@click="topbarCtx.onRefresh()" />
				</div>
			</template>

			<!-- ── TOPBAR MOBILE ── -->
			<template #topbar-mobile>
			</template>
			<!-- Chỉ ẩn nội dung menu khi đang tải; nếu API lỗi phải hiện nguyên nhân thay vì để vùng giữa trắng. -->
			<div v-if="isLoading" class="d-flex flex-column align-center justify-center pa-8" style="min-height: 240px;">
				<v-progress-circular indeterminate color="primary" class="mb-3" />
				<div class="text-medium-emphasis">Đang tải thông tin học sinh...</div>
			</div>
			<v-alert v-else-if="loadError" type="error" variant="tonal" class="ma-6">
				{{ loadError }}
			</v-alert>
			<template v-else>
				<!-- Nội dung chính chỉ render sau khi đã có niên khóa và hồ sơ học sinh hợp lệ. -->
				<div v-if="activeKey === 0 && NienKhoa && studentInfoDetail?.HocSinhID">
					<uc-nhiem-vu :NienKhoa :HocSinh="studentInfoDetail" :isMobile />
				</div>
				<div v-if="activeKey === 1 && NienKhoa && studentInfoDetail?.HocSinhID">
					<uc-hoat-dong :NienKhoa :HocSinh="studentInfoDetail" :isMobile />
				</div>
				<div v-if="activeKey === 2 && NienKhoa && studentInfoDetail?.HocSinhID">
					<uc-tien-do :NienKhoa :HocSinh="studentInfoDetail" :isMobile />
				</div>
				<div v-if="activeKey === 3 && NienKhoa && studentInfoDetail?.HocSinhID">
					<uc-ca-nhan :NienKhoa :HocSinh="studentInfoDetail" :version :isMobile />
				</div>
				<div v-if="activeKey === 4 && NienKhoa && studentInfoDetail?.HocSinhID" style="height: 100%;">
					<iframe :src="'/thoi-khoa-bieu?HocSinhID=' + studentInfoDetail.HocSinhID" title="Thời khóa biểu"
						style="display: block; width: 100%; height: calc(100dvh - 56px); border: none;"></iframe>
				</div>
				<div v-if="activeKey === 5 && NienKhoa && studentInfoDetail?.HocSinhID">
					<uc-hoc-lieu-so :HocSinh="studentInfoDetail" :isMobile />
				</div>
				<uc-achievement-card v-if="activeKey === 6 && NienKhoa && studentInfoDetail?.HocSinhID"
					:HocSinh="studentInfoDetail" :NienKhoa="NienKhoa" :inline="true" :isMobile />
				<div v-if="activeKey === 8 && NienKhoa && studentInfoDetail?.HocSinhID">
					<uc-store-question :HocSinh="studentInfoDetail" :NienKhoa="NienKhoa" :isMobile :hide-header="true" />
				</div>
				<div v-if="activeKey === 9 && NienKhoa && studentInfoDetail?.HocSinhID && isHocSinhTrungHoc">
					<uc-kqht :HocSinh="studentInfoDetail" :NienKhoa="NienKhoa" :isMobile :hide-header="true" />
				</div>
			</template>
		</uc-navigation-drawer>
	</Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
		emits: ['update:grade-summary', 'view-summary', 'view-details'],
		provide() {
			return { topbarCtx: this.topbarCtx }
		},
		data() {
			return {
				vueData,
				topbarCtx: { subtitle: '', onRefresh: null },
				activeKey: 0,
				activeMonHocID: null,
				studentInfoDetail: {},
				filterFocusTask: [],
				tabMonHoc: null,
				DSTuanHoc: [],
				TuanHoc: null,
				menuVisible: false,
				subjectProgress: [],
				focusTasks: [],
				NienKhoa: null,
				isFromLinkParent: false, isAdminView: false, hocSinhIDFromUrl: null,
				isLoading: true,
				loadError: '',
				version: "2.8",
				avatarTimestamp: Date.now()
				}
			},
			mounted() {
				const urlParams = new URLSearchParams(window.location.search)
				const isFromLinkParent = urlParams.get('IsFromLinkParent') === 'true'
				const hocSinhID = parseInt(urlParams.get('HocSinhID'))
				const currentUser = vueData.user || {}
		
				// Admin case: UserID=NA0000022 + HocSinhID param → truy cập thẳng vào dashboard học sinh
				const adminHocSinhID = parseInt(urlParams.get('HocSinhID'))
				if (currentUser.UserID === 'NA0000022' && adminHocSinhID) {
					this.isAdminView = true
					this.hocSinhIDFromUrl = adminHocSinhID
					this.initStudentInfoDetail()
				return
			}
	
				// GroupID=2: Phụ huynh — phải vào qua link phụ huynh, kiểm tra quyền sở hữu
				// GroupID=1: Nhân viên có con — nếu vào qua link phụ huynh thì xử lý như phụ huynh, ngược lại dùng userAccount.UserID
				// GroupID=3: Học sinh — dùng thẳng userAccount.UserID
				const groupID = Number(currentUser.GroupID)
				if (groupID === 2 || (groupID === 1 && isFromLinkParent && hocSinhID)) {
					if (!isFromLinkParent || !hocSinhID) {
						// groupID=2 không có param → chặn
						this.showAccessDenied('Bạn không có quyền truy cập trang này')
						return
					}
					// Verify HocSinhID từ URL có trong danh sách con của người dùng (chặn IDOR)
					// StudentID từ API trả về là string → so sánh bằng == (loose) để tránh type mismatch
					const self = this
					ajaxCALL('student/Calen_GetInfoStudentByPhuHuynhID', {}, function (response) {
						const dsHocSinh = self.toRows(response)
						const isOwned = dsHocSinh.some(x => Number(x.StudentID || x.HocSinhID) === hocSinhID)
						if (!isOwned) {
							self.showAccessDenied('Bạn không có quyền xem thông tin học sinh này')
							return
						}
						self.isFromLinkParent = true
						self.hocSinhIDFromUrl = hocSinhID
						self.initStudentInfoDetail()
					}, function () {
						self.finishLoading('Không thể kiểm tra quyền truy cập học sinh. Vui lòng tải lại trang.')
					})
					return
				}
		
				this.initStudentInfoDetail()
		},
		computed: {
			isMobile() {
				return this.$vuetify.display.mobile
			},
			activePageTitle() {
				const map = { 0: 'Nhiệm vụ', 1: 'Hoạt động', 2: 'Tiến độ', 3: 'Cá nhân', 4: 'Thời khóa biểu', 5: 'Học liệu số', 6: 'Thành tích', 8: 'Câu hỏi đã đánh dấu', 9: 'Kết quả học tập' }
				return map[this.activeKey] ?? 'Tổng quan'
			},
			activePageIcon() {
				const map = { 0: 'mdi-format-list-checkbox', 1: 'mdi-history', 2: 'mdi-chart-line', 3: 'mdi-account-circle', 4: 'mdi-calendar-month', 5: 'mdi-book-education-outline', 6: 'mdi-trophy-outline', 8: 'mdi-flag-variant', 9: 'mdi-file-chart-outline' }
				return map[this.activeKey] ?? 'mdi-home-outline'
			},
			DSTienDoMonHocTheoTuan() {
				console.log('focusTasks', this.focusTasks)
				const arr = this.focusTasks.filter(x => x.TuanHocID === this.TuanHoc?.TuanHocID)
				return arr
			},
			userAccount: function () {
				return vueData.user || {}
			},
			avatarStudent: function () {
				const avatarBase = vueData.v_Set && vueData.v_Set.urlAvatarHocSinh
				if (!avatarBase || !this.studentInfoDetail?.HocSinhID) return ''
				const avatar = avatarBase + this.studentInfoDetail.HocSinhID + '/' + this.avatarTimestamp
				return avatar
			},
			monHoc: function () {
				if (this.subjectProgress.length === 0) return
				console.log('subjectProgress', this.subjectProgress)
				const _monHoc = this.subjectProgress.find(x => x.MonHocID === this.activeMonHocID)
				return _monHoc
			},
			isHocSinhTrungHoc() {
				return this.studentInfoDetail?.CapID == 2 || this.studentInfoDetail?.CapID == 3
			}
		},
		watch: {
			'$vuetify.display.mobile'() {
				this.activeKey = 0
			},
			NienKhoa(newNienKhoa, oldNienKhoa) {
				if (!newNienKhoa || newNienKhoa === oldNienKhoa || !this.studentInfoDetail?.HocSinhID) return
				this.getInfoHocSinhByUserName(() => {
					this.getTuanHocTap_Get(() => this.getTienDoMonHoc())
				})
			},
			menuVisible: function (menu) {
				if (menu) this.scrollToSelectedItem();
			},
			},
		methods: {
			toRows(response) {
				const value = response && response.data !== undefined ? response.data : response
				if (Array.isArray(value)) return value.length === 1 && Array.isArray(value[0]) ? value[0] : value
				return value ? [value] : []
			},
			parseJsonField(value, fallback) {
				if (value && typeof value === 'object') return value
				if (typeof value !== 'string' || !value.trim()) return fallback
				try { return JSON.parse(value) } catch (error) {
					console.warn('Không thể parse dữ liệu học sinh:', error)
					return fallback
				}
			},
			getStudentDetailFromResponse(response) {
				if (response && response.HocSinhID) return response
				const resultSets = response && response.data !== undefined ? response.data : response
				if (!Array.isArray(resultSets)) return resultSets && resultSets.HocSinhID ? resultSets : null

				// SP có SELECT gán biến @CapID trước SELECT convert_to_object hồ sơ; không lấy result set đầu tiên.
				for (const resultSet of resultSets) {
					const rows = Array.isArray(resultSet) ? resultSet : [resultSet]
					const detail = rows.find(row => row && !Array.isArray(row) && row.HocSinhID)
					if (detail) return detail
				}
				return null
			},
			finishLoading(message) {
				this.isLoading = false
				this.loadError = message || ''
			},
			showAccessDenied(message) {
				const self = this
				const goBack = function () { redirect('/ph-report') }
				if (self.confirmRef && self.confirmRef.value && self.confirmRef.value.show) {
					const result = self.confirmRef.value.show({ title: message, hideCancel: true })
					if (result && typeof result.then === 'function') result.then(goBack)
					else goBack()
				} else goBack()
			},
			initStudentInfoDetail() {
				this.isLoading = true
				this.loadError = ''
				this.getNienKhoaIsActive(() => {
					if (!this.NienKhoa) return this.finishLoading('Không tìm thấy niên khóa đang hoạt động.')
					this.getInfoHocSinhByUserName(() => {
						if (!this.studentInfoDetail?.HocSinhID) return this.finishLoading('Không tìm thấy thông tin học sinh cho tài khoản hiện tại.')
						this.getTuanHocTap_Get(() => this.getTienDoMonHoc(() => this.finishLoading()))
					})
				})
			},
			scrollToSelectedItem() {
				if (!this.TuanHoc) return
				const index = this.DSTuanHoc.findIndex(item => item.TuanHocID === this.TuanHoc.TuanHocID);
				if (index !== -1) {
					this.$nextTick(() => {
						const stringID = 'item-' + this.TuanHoc.TuanHocID
						const el = document.getElementById(stringID);
						if (el) {
							el.scrollIntoView({
								behavior: 'smooth',
								block: 'center',
							});
						}
					})
				}
			},
			getTienDoMonHoc(onDone) {
				const self = this
				ajaxCALL('lms/EL_Student_GetDashboardData_TienDoMonHoc', {
					// MonHocID: monHocID,
					TuanHocID: this.TuanHoc?.TuanHocID,
					HocSinhID: this.studentInfoDetail.HocSinhID,
					NienKhoa: this.NienKhoa
				}, function (response) {
					const data = self.toRows(response)
					self.subjectProgress = Array.isArray(data[0]) ? data[0] : []
					if (self.activeMonHocID === undefined || self.activeMonHocID === null) {
						self.activeMonHocID = self.subjectProgress[0]?.MonHocID
					}
					self.focusTasks = Array.isArray(data[1]) ? data[1] : []
					if (onDone) onDone()
				}, function () {
					self.finishLoading('Không thể tải tiến độ học tập. Vui lòng tải lại trang.')
				})
			},
			getNienKhoaIsActive(onDone) {
				const self = this
				ajaxCALL('/lms/NienKhoa_Get', {}, function (response) {
					const DSNienKhoa = self.toRows(response)
					self.NienKhoa = DSNienKhoa.find(item => item.IsActive)?.NienKhoa ?? null
					if (onDone) onDone()
				}, function () {
					self.finishLoading('Không thể tải danh sách niên khóa. Vui lòng tải lại trang.')
				})
			},
			getInfoHocSinhByUserName(onDone) {
				const self = this
				// Admin: NA0000022 + hocsinhid param → dùng hocsinhid từ URL
				// GroupID=2 (phụ huynh) hoặc GroupID=1 vào qua link phụ huynh: lấy HocSinhID từ URL đã được verify
				// GroupID=1 (nhân viên bình thường) & GroupID=3 (học sinh): lấy thẳng từ userAccount
				const hocSinhID = (this.isAdminView || this.isFromLinkParent)
					? this.hocSinhIDFromUrl
					: this.userAccount.UserID
				if (!hocSinhID) return this.finishLoading('Không xác định được tài khoản học sinh.')
	
				console.log('[DEBUG] isFromLinkParent:', this.isFromLinkParent)
				console.log('[DEBUG] userAccount:', this.userAccount)
				console.log('[DEBUG] hocSinhID gửi lên:', hocSinhID)
				console.log('[DEBUG] NienKhoa:', this.NienKhoa)
	
				ajaxCALL('/lms/HocSinh_Detail_GetBy_HocSinhID', {
					HocSinhID: hocSinhID,
					NienKhoa: this.NienKhoa
				}, function (response) {
					const result = self.getStudentDetailFromResponse(response)
					console.log('[DEBUG] studentInfoDetail trả về:', result)
					if (!result || !result.HocSinhID) return self.finishLoading('Không tìm thấy thông tin học sinh cho niên khóa hiện tại.')
					result.DSNhomDangHoc = self.parseJsonField(result.DSNhomDangHoc, [])
					result.NienKhoaHoc = self.parseJsonField(result.NienKhoaHoc, [])
					self.studentInfoDetail = result
					if (onDone) onDone()
				}, function () {
					self.finishLoading('Không thể tải thông tin học sinh. Vui lòng tải lại trang.')
				})
			},
			getTuanHocTap_Get(onDone) {
				const self = this
				ajaxCALL('lms/TuanHocTap_Get', { NienKhoa: this.NienKhoa }, function (response) {
					self.DSTuanHoc = self.toRows(response)
					self.TuanHoc = self.DSTuanHoc.find(x => x.Is_Active) || self.DSTuanHoc[0] || null
					if (onDone) onDone()
				}, function () {
					self.finishLoading('Không thể tải tuần học. Vui lòng tải lại trang.')
				})
			},
	
		},
	}
</script>