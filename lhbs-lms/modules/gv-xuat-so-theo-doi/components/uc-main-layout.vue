<template>
	<Global>
		<template #header>
			<v-card>
				<v-card-title class="d-flex align-center flex-wrap ga-2">
					<!-- BGH và Admin đóng vai trò quan sát/theo dõi, giáo viên xuất file -->
					<span>{{ isBghOrAdmin ? 'Theo dõi xuất sổ điểm' : 'Xuất sổ điểm' }}</span>
					<v-spacer />
					<v-chip color="primary" variant="tonal" size="small">{{ schoolYearLabel }}</v-chip>
				</v-card-title>
				<v-card-text>
					<v-row align="center">
						<v-col cols="12" sm="2">
							<v-select v-model="selectedSemester" label="Học kì" :items="semesterOptions"
								item-title="title" item-value="value" hide-details="auto" density="compact" />
						</v-col>
						<v-col v-if="isBghOrAdmin" cols="12" sm="2">
							<v-select v-model="selectedGradeFilter" label="Khối" :items="gradeOptions"
								item-title="title" item-value="value" hide-details="auto" density="compact" />
						</v-col>
						<v-col cols="12" :sm="isBghOrAdmin ? 3 : 5">
							<v-text-field v-model="searchText"
								:label="isBghOrAdmin ? 'Tìm giáo viên' : 'Tìm lớp hoặc môn học'"
								prepend-inner-icon="mdi-magnify" clearable hide-details="auto" density="compact" />
						</v-col>
						<v-col v-if="isBghOrAdmin" cols="12" sm="2">
							<v-select v-model="exportStatusFilter" label="Trạng thái xuất" :items="exportStatusOptions"
								item-title="title" item-value="value" hide-details="auto" density="compact" />
						</v-col>
						<v-col cols="12" :sm="isBghOrAdmin ? 3 : 5" class="d-flex align-center justify-end ga-2 flex-wrap">
							<v-chip size="small" variant="tonal" color="primary">
								{{ filteredAssignments.length }} phân công
							</v-chip>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</template>

		<!-- Bảng phân công giảng dạy & Theo dõi xuất sổ điểm (chung 1 view thống nhất) -->
		<v-data-table-virtual :key="tableRenderKey" :headers="assignmentHeaders"
			:items="filteredAssignments" :show-select="false" fixed-header item-value="_key" :loading="isLoading"
			:item-height="48"
			height="calc(100dvh - 76px)" style="height: calc(100dvh - 76px); min-height: 0;"
			loading-text="Đang tải phân công giảng dạy..." no-data-text="Chưa có lớp/môn phù hợp"
			class="gv-xuat-so-assignment-table">
			<template #top>
				<div class="d-flex align-center justify-space-between flex-wrap ga-2 px-4 py-3">
					<div>
						<div class="text-subtitle-1 font-weight-bold">
							{{ isBghOrAdmin ? 'Các lớp/môn đang được phân công' : 'Các lớp/môn giáo viên đang dạy' }}
						</div>
						<div class="text-caption text-medium-emphasis">
							{{ isBghOrAdmin
								? 'BGH/quản trị theo dõi phân công, tra cứu khối/lớp/môn từng giáo viên đang dạy và tình trạng xuất sổ điểm.'
								: 'Giáo viên xuất file Excel mẫu sổ điểm theo các lớp/môn được phân công.' }}
						</div>
						<div v-if="isBghOrAdmin" class="d-flex align-center ga-2 mt-2 flex-wrap">
							<v-chip size="x-small" variant="tonal" color="info">Tổng: {{ exportStats.total }} phân công</v-chip>
							<v-chip size="x-small" variant="tonal" color="success">Đã xuất: {{ exportStats.exported }}</v-chip>
							<v-chip size="x-small" variant="tonal" color="warning">Chưa xuất: {{ exportStats.notExported }}</v-chip>
						</div>
					</div>
					<!-- Nút xuất Excel: Không hiển thị số đếm trong ngoặc, xuất toàn bộ danh sách lớp/môn đang hiển thị -->
					<v-btn color="success" variant="outlined" prepend-icon="mdi-file-excel-outline"
						:loading="isExporting" :disabled="!filteredAssignments.length" @click="exportExcel">
						Xuất Excel mẫu
					</v-btn>
				</div>

				<!-- Thẻ tóm tắt thông tin giáo viên khi BGH/Admin tìm kiếm theo tên giáo viên -->
				<div v-if="isBghOrAdmin && activeTeacherInfo" class="px-4 pb-3">
					<v-card variant="tonal" color="primary" class="rounded-lg">
						<v-card-text class="py-2 px-3 d-flex align-center justify-space-between flex-wrap ga-3">
							<div>
								<div class="text-subtitle-2 font-weight-bold d-flex align-center ga-2">
									<v-icon icon="mdi-account-school-outline" size="small" />
									{{ activeTeacherInfo.teacherName }}
									<span v-if="activeTeacherInfo.teacherId" class="text-caption font-weight-regular text-medium-emphasis">
										(Mã GV: {{ activeTeacherInfo.teacherId }})
									</span>
								</div>
								<div class="text-caption mt-1 d-flex align-center flex-wrap ga-2">
									<span><b>Khối dạy:</b> {{ activeTeacherInfo.grades.map(g => 'Khối ' + g).join(', ') || 'Chưa rõ' }}</span>
									<span>•</span>
									<span><b>Môn phụ trách:</b> {{ activeTeacherInfo.subjects.join(', ') }}</span>
									<span>•</span>
									<span><b>Tổng số lớp:</b> {{ activeTeacherInfo.totalAssignments }} lớp ({{ activeTeacherInfo.classes.join(', ') }})</span>
								</div>
							</div>
							<div class="d-flex align-center ga-3">
								<div class="text-end">
									<div class="text-caption font-weight-bold">
										Đã xuất: {{ activeTeacherInfo.exportedCount }}/{{ activeTeacherInfo.totalAssignments }} lớp
									</div>
									<div class="text-caption text-medium-emphasis">{{ activeTeacherInfo.exportPercent }}% hoàn thành</div>
								</div>
								<v-progress-circular :model-value="activeTeacherInfo.exportPercent" size="32" width="3"
									:color="activeTeacherInfo.isFullyExported ? 'success' : (activeTeacherInfo.exportedCount > 0 ? 'primary' : 'grey-lighten-1')" />
							</div>
						</v-card-text>
					</v-card>
				</div>
			</template>
			<template #item.STT="{ index }">
				<span class="text-caption text-medium-emphasis font-weight-medium">{{ index + 1 }}</span>
			</template>
			<template #item.TenLop="{ item }">
				<span class="font-weight-medium">{{ item.TenLop }}</span>
			</template>
			<template #item.KhoiID="{ item }">
				<span>{{ item.KhoiID || '—' }}</span>
			</template>
			<template #item.HocKy="{ item }">
				<span>HK{{ item.HocKy || selectedSemester }}</span>
			</template>
			<template #item.GiaoVien="{ item }">
				<span class="text-body-2 font-weight-medium">{{ getAssignmentTeacherName(item) }}</span>
			</template>
			<template #item.LichSuXuat="{ item }">
				<!-- Hiển thị số lần xuất và cho phép click xem danh sách các lần xuất kèm thời gian chi tiết -->
				<div v-if="getExportInfo(item) && getExportInfo(item).count > 0">
					<v-tooltip location="top">
						<template #activator="{ props }">
							<v-chip v-bind="props" size="small" color="primary" variant="tonal" prepend-icon="mdi-history"
								class="cursor-pointer" @click="openHistoryDialog(item)">
								Đã xuất {{ getExportInfo(item).count }} lần
							</v-chip>
						</template>
						<span>Lần cuối: {{ formatDateTime(getExportInfo(item).lastExportedAt) }}<br/>Người xuất: {{ getExportInfo(item).exportedBy || 'Giáo viên' }}<br/><b>(Bấm để xem chi tiết từng lần xuất)</b></span>
					</v-tooltip>
				</div>
				<v-chip v-else size="small" color="grey" variant="tonal">
					Chưa xuất
				</v-chip>
			</template>
			<template #item.TrangThai>
				<v-chip size="x-small" color="success" variant="tonal">Được phân công</v-chip>
			</template>
		</v-data-table-virtual>

		<!-- Modal chi tiết lịch sử từng lần xuất sổ điểm -->
		<v-dialog v-model="showHistoryDialog" max-width="720px">
			<v-card v-if="selectedHistoryAssignment">
				<v-card-title class="d-flex align-center justify-space-between pb-1">
					<div class="d-flex align-center ga-2">
						<v-icon color="primary" icon="mdi-history" />
						<span class="text-subtitle-1 font-weight-bold">Chi tiết lịch sử xuất sổ điểm</span>
					</div>
					<v-btn icon="mdi-close" variant="text" size="small" @click="showHistoryDialog = false" />
				</v-card-title>
				<v-divider />
				<v-card-text class="pt-3">
					<div class="d-flex align-center justify-space-between flex-wrap ga-2 mb-3 bg-grey-lighten-4 pa-3 rounded">
						<div>
							<div class="text-body-2 font-weight-bold text-primary">
								{{ selectedHistoryAssignment.TenLop }} - {{ selectedHistoryAssignment.TenMonHoc }}
							</div>
							<div class="text-caption text-medium-emphasis">
								Giáo viên: {{ getAssignmentTeacherName(selectedHistoryAssignment) }} | Học kì {{ selectedHistoryAssignment.HocKy || selectedSemester }} ({{ schoolYearLabel }})
							</div>
						</div>
						<v-chip color="primary" variant="flat" size="small">
							Tổng: {{ getExportLogs(selectedHistoryAssignment).length }} lượt xuất
						</v-chip>
					</div>

					<v-table density="compact" class="elevation-1 rounded">
						<thead>
							<tr>
								<th class="text-center" style="width: 60px;">Lần</th>
								<th class="text-start" style="min-width: 170px;">Thời gian xuất</th>
								<th class="text-start" style="min-width: 180px;">Người xuất</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="(log, idx) in getExportLogs(selectedHistoryAssignment)" :key="log.id || idx">
								<td class="text-center font-weight-bold">{{ idx + 1 }}</td>
								<td>
									<div class="d-flex align-center ga-1">
										<v-icon size="x-small" color="primary" icon="mdi-clock-outline" />
										<span class="text-body-2">{{ formatDateTime(log.timestamp) }}</span>
									</div>
								</td>
								<td>
									<div class="font-weight-medium text-body-2">{{ log.exportedBy || 'Giáo viên' }}</div>
									<div v-if="log.userId" class="text-caption text-medium-emphasis">ID: {{ log.userId }}</div>
								</td>
							</tr>
							<tr v-if="!getExportLogs(selectedHistoryAssignment).length">
								<td colspan="3" class="text-center py-4 text-medium-emphasis">
									Chưa có bản ghi lịch sử xuất nào cho phân công này.
								</td>
							</tr>
						</tbody>
					</v-table>
				</v-card-text>
				<v-card-actions class="justify-end px-4 pb-3">
					<v-btn variant="text" @click="showHistoryDialog = false">Đóng</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</Global>
</template>

<script>
	export default {
		data() {
		return {
			vueData,
			isLoading: false,
			isExporting: false,
			activeTab: 'details',
			searchText: '',
			searchKeyword: '',
			searchDebounceTimer: null,
			selectedSemester: Number(vueData.NienKhoaItem?.HocKi || 1),
			selectedGradeFilter: 'all',
			exportStatusFilter: 'all',
			exportHistory: {},
			showHistoryDialog: false,
			selectedHistoryAssignment: null,
			assignments: [],
			// BGH/Admin có thể xuất theo phân công của giáo viên khác, nên cần tra tên từ GiaoVienID.
			teacherDirectory: {},
			// Dữ liệu mẫu chỉ phục vụ lúc dựng/preview giao diện khi chưa có user context.
			// Khi tài khoản thật có UserID, dữ liệu này luôn bị thay thế bởi API phân công.
			previewAssignments: [
				{
					GVLopID: 'preview-1', LopID: 601, KhoiID: 6, MonHocID: 901,
					TenLop: '06H', TenMonHoc: 'Hoạt động trải nghiệm, hướng nghiệp', HocKy: 1,
					NienKhoa: 2026, Enable: 1, GiaoVienID: 'GV01', HoTenGV: 'Lê Thị Thanh Thủy'
				},
				{
					GVLopID: 'preview-2', LopID: 602, KhoiID: 6, MonHocID: 902,
					TenLop: '06H', TenMonHoc: 'Ngữ văn', HocKy: 1,
					NienKhoa: 2026, Enable: 1, GiaoVienID: 'GV02', HoTenGV: 'Trần Văn An'
				}
			]
		}
	},
	computed: {
		assignmentHeaders() {
			const headers = [
				{ title: 'STT', value: 'STT', align: 'center', width: 60, sortable: false },
				{ title: 'Học kì', value: 'HocKy', align: 'center', width: 80 }
			]
			// Với BGH / Admin: Đưa cột Giáo viên lên ngay đầu bảng để quan sát trực tiếp
			if (this.isBghOrAdmin) {
				headers.push({ title: 'Giáo viên', value: 'GiaoVien', align: 'start', minWidth: 190 })
			}
			headers.push(
				{ title: 'Khối', value: 'KhoiID', align: 'center', width: 75 },
				{ title: 'Lớp/Nhóm', value: 'TenLop', align: 'start', minWidth: 120 },
				{ title: 'Môn học', value: 'TenMonHoc', align: 'start', minWidth: 180 },
				{ title: 'Lịch sử xuất', value: 'LichSuXuat', align: 'center', minWidth: 150 },
				{ title: 'Trạng thái', value: 'TrangThai', align: 'center', width: 130, sortable: false }
			)
			return headers
		},
		teacherSummaryHeaders() {
			return [
				{ title: 'STT', value: 'STT', align: 'center', width: 64, sortable: false },
				{ title: 'Giáo viên', value: 'teacherName', align: 'start', minWidth: 200 },
				{ title: 'Khối dạy', value: 'grades', align: 'start', minWidth: 130 },
				{ title: 'Môn phụ trách', value: 'subjects', align: 'start', minWidth: 200 },
				{ title: 'Danh sách lớp', value: 'classes', align: 'start', minWidth: 220 },
				{ title: 'Tiến độ xuất sổ điểm', value: 'progress', align: 'center', minWidth: 160 },
				{ title: 'Thao tác', value: 'action', align: 'center', width: 140, sortable: false }
			]
		},
		semesterOptions() {
			return [
					{ title: 'Học kì 1', value: 1 },
					{ title: 'Học kì 2', value: 2 }
			]
		},
		gradeOptions() {
			return [
				{ title: 'Tất cả khối', value: 'all' },
				...Array.from({ length: 12 }, (_, i) => ({ title: `Khối ${i + 1}`, value: i + 1 }))
			]
		},
		exportStatusOptions() {
			return [
				{ title: 'Tất cả trạng thái', value: 'all' },
				{ title: 'Đã xuất Excel', value: 'exported' },
				{ title: 'Chưa xuất Excel', value: 'not_exported' }
			]
		},
		schoolYear() {
			const raw = vueData.NienKhoa || new Date().getFullYear()
			const parsed = Number(String(raw).slice(0, 4))
			return Number.isFinite(parsed) && parsed > 2000 ? parsed : new Date().getFullYear()
		},
		schoolYearLabel() {
			return `Năm học ${this.schoolYear} - ${this.schoolYear + 1}`
		},
		userSystemRight() {
			const raw = vueData?.user?.SystemRight ?? vueData?.SystemRight ?? vueData?.sys_SystemRight ?? 0
			return Number(raw) || 0
		},
		isBghOrAdmin() {
			// Theo convention quyền của LMS: SystemRight 3 = BGH, 9 = System Admin.
			// Hai vai trò này được xem toàn bộ dòng phân công và tra cứu giáo viên; giáo viên thường chỉ xem dòng của mình.
			return [3, 9].includes(this.userSystemRight)
		},
		teacherName() {
			const user = vueData.user || {}
			return this.cleanSheetValue(user.FullName || user.HoTen || user.DisplayName || user.UserName || 'Giáo viên')
		},
		teacherSummaryList() {
			const semesterRows = this.assignments.filter(row => !row.HocKy || Number(row.HocKy) === Number(this.selectedSemester))
			const teacherMap = new Map()

			semesterRows.forEach(row => {
				const tName = this.getAssignmentTeacherName(row) || 'Giáo viên chưa phân'
				const tId = this.cleanSheetValue(row.GiaoVienID) || tName
				if (!teacherMap.has(tId)) {
					teacherMap.set(tId, {
						teacherId: row.GiaoVienID || '',
						teacherName: tName,
						gradesSet: new Set(),
						subjectsSet: new Set(),
						classesSet: new Set(),
						totalAssignments: 0,
						exportedCount: 0
					})
				}
				const item = teacherMap.get(tId)
				const grade = Number(row.KhoiID || row.NhomKhoiID || 0)
				if (grade > 0) item.gradesSet.add(grade)
				if (row.TenMonHoc) item.subjectsSet.add(row.TenMonHoc)
				if (row.TenLop) item.classesSet.add(row.TenLop)
				item.totalAssignments++
				const info = this.getExportInfo(row)
				if (info && info.count > 0) item.exportedCount++
			})

			return [...teacherMap.values()].map(t => {
				const grades = [...t.gradesSet].sort((a, b) => a - b)
				const subjects = [...t.subjectsSet].sort((a, b) => a.localeCompare(b, 'vi'))
				const classes = [...t.classesSet].sort((a, b) => a.localeCompare(b, 'vi'))
				const exportPercent = t.totalAssignments ? Math.round((t.exportedCount / t.totalAssignments) * 100) : 0
				return {
					teacherId: t.teacherId,
					teacherName: t.teacherName,
					grades,
					subjects,
					classes,
					totalAssignments: t.totalAssignments,
					exportedCount: t.exportedCount,
					exportPercent,
					isFullyExported: t.totalAssignments > 0 && t.exportedCount === t.totalAssignments
				}
			}).sort((a, b) => this.compareTeacherName(a.teacherName, b.teacherName))
		},
		filteredTeacherSummaryList() {
			const keyword = this.normalizeLookupText(this.searchKeyword)
			return this.teacherSummaryList.filter(t => {
				// Lọc theo khối
				if (this.selectedGradeFilter !== 'all') {
					if (!t.grades.includes(Number(this.selectedGradeFilter))) return false
				}
				// Lọc theo trạng thái xuất
				if (this.exportStatusFilter === 'exported' && t.exportedCount === 0) return false
				if (this.exportStatusFilter === 'not_exported' && t.isFullyExported) return false

				if (!keyword) return true
				// Chỉ tìm kiếm theo tên giáo viên
				return this.normalizeLookupText(t.teacherName).includes(keyword)
			})
		},
		exportStats() {
			const visibleRows = this.assignments.filter(row => !row.HocKy || Number(row.HocKy) === Number(this.selectedSemester))
			const total = visibleRows.length
			const exported = visibleRows.filter(row => {
				const info = this.getExportInfo(row)
				return Boolean(info && info.count > 0)
			}).length
			const notExported = total - exported
			return { total, exported, notExported }
		},
		activeTeacherInfo() {
			if (!this.searchKeyword) return null
			const keyword = this.normalizeLookupText(this.searchKeyword)
			const matches = this.teacherSummaryList.filter(t => this.normalizeLookupText(t.teacherName).includes(keyword))
			if (matches.length === 1) return matches[0]
			return null
		},
		filteredAssignments() {
			const keyword = this.normalizeLookupText(this.searchKeyword)
			const list = this.assignments.filter(row => {
				const semesterMatches = !row.HocKy || Number(row.HocKy) === Number(this.selectedSemester)
				if (!semesterMatches) return false

				// Lọc theo khối
				if (this.selectedGradeFilter !== 'all') {
					const grade = Number(row.KhoiID || row.NhomKhoiID || 0)
					if (grade !== Number(this.selectedGradeFilter)) return false
				}

				// Lọc theo trạng thái xuất file
				if (this.exportStatusFilter !== 'all') {
					const info = this.getExportInfo(row)
					const isExported = Boolean(info && info.count > 0)
					if (this.exportStatusFilter === 'exported' && !isExported) return false
					if (this.exportStatusFilter === 'not_exported' && isExported) return false
				}

				if (!keyword) return true
				const teacherName = this.getAssignmentTeacherName(row)
				if (this.isBghOrAdmin) {
					// BGH / Admin: Chỉ tìm kiếm theo tên giáo viên
					return this.normalizeLookupText(teacherName).includes(keyword)
				}
				// Giáo viên: Tìm theo tên lớp hoặc tên môn học
				return this.normalizeLookupText(`${row.TenLop} ${row.TenMonHoc}`).includes(keyword)
			})

			// Sắp xếp: Với BGH/Admin thì gom nhóm ưu tiên theo thứ tự Tên giáo viên (TenGV chuẩn tiếng Việt) để quan sát rõ ràng
			if (this.isBghOrAdmin) {
				return list.sort((a, b) => {
					const tA = this.getAssignmentTeacherName(a) || ''
					const tB = this.getAssignmentTeacherName(b) || ''
					const tComp = this.compareTeacherName(tA, tB)
					if (tComp !== 0) return tComp

					const gradeA = Number(a.KhoiID || a.NhomKhoiID || 0)
					const gradeB = Number(b.KhoiID || b.NhomKhoiID || 0)
					if (gradeA !== gradeB) return gradeA - gradeB

					const classComp = String(a.TenLop || '').localeCompare(String(b.TenLop || ''), 'vi')
					if (classComp !== 0) return classComp

					return String(a.TenMonHoc || '').localeCompare(String(b.TenMonHoc || ''), 'vi')
				})
			}

			return list
		},
		tableRenderKey() {
			return `table_${this.selectedSemester}_${this.selectedGradeFilter}_${this.exportStatusFilter}_${this.searchKeyword}_${this.filteredAssignments.length}`
		}
	},
	watch: {
		exportStatusFilter() {
			this.resetTableScroll()
		},
		selectedGradeFilter() {
			this.resetTableScroll()
		},
		searchKeyword() {
			this.resetTableScroll()
		},
		searchText() {
			// Chỉ cập nhật từ khóa sau 250ms để bảng lớn không lọc và render lại theo từng phím gõ.
			clearTimeout(this.searchDebounceTimer)
			this.searchDebounceTimer = setTimeout(() => {
				this.searchKeyword = this.searchText
			}, 250)
		},
		async selectedSemester() {
			this.loadExportHistory()
			this.resetTableScroll()
			// Nhánh BGH/Admin tải lại phân công theo học kì vì API toàn trường nhận HocKi ngay từ đầu.
			if (this.getTeacherId() && this.isBghOrAdmin) {
				await this.loadAssignments()
			}
		}
	},
	async mounted() {
		this.loadExportHistory()
		if (!this.getTeacherId()) {
			this.assignments = this.normalizeAssignments(this.previewAssignments)
			return
		}
		await this.loadAssignments()
	},
	beforeUnmount() {
		clearTimeout(this.searchDebounceTimer)
	},
	methods: {
		getTeacherId() {
			const user = vueData.user || {}
			return String(user.GiaoVienID || user.TeacherID || user.UserID || '').trim()
		},
		getTeacherIdentitySet() {
			const user = vueData.user || {}
			return new Set([
				this.getTeacherId(),
				user.UserID,
				user.GiaoVienID,
				user.TeacherID
			].map(value => this.cleanSheetValue(value)).filter(Boolean))
		},
		isPrimaryClass(unit = {}) {
			const capId = Number(unit.CapID || unit.CapHocID || 0)
			const grade = Number(unit.KhoiID || unit.NhomKhoiID || 0)
			return capId === 1 || (capId === 0 && grade >= 1 && grade <= 5)
		},
		isCurrentTeacherHomeroom(unit = {}) {
			// GVCN được lưu ở tblLop.GVCN; chỉ áp dụng quyền xem toàn bộ môn cho tiểu học.
			if (!this.isPrimaryClass(unit)) return false
			const homeroomTeacherId = this.cleanSheetValue(unit.GVCN)
			return Boolean(homeroomTeacherId && this.getTeacherIdentitySet().has(homeroomTeacherId))
		},
		getAssignmentTeacherName(assignment = {}) {
			const directName = assignment.HoTenGV || assignment.HoTenGiaoVien || assignment.TenGiaoVien
				|| assignment.GiaoVienName || assignment.GiaoVien || `${assignment.HoGV || ''} ${assignment.TenGV || ''}`
			const teacherId = this.cleanSheetValue(assignment.GiaoVienID)
			return this.cleanSheetValue(directName)
				|| this.cleanSheetValue(this.teacherDirectory[teacherId])
				|| this.teacherName
		},
		splitTeacherName(fullName) {
			const clean = this.cleanSheetValue(fullName).trim()
			if (!clean) return { ten: '', hoLot: '' }
			const parts = clean.split(/\s+/)
			if (parts.length === 1) return { ten: parts[0], hoLot: '' }
			const ten = parts[parts.length - 1]
			const hoLot = parts.slice(0, -1).join(' ')
			return { ten, hoLot }
		},
		compareTeacherName(nameA, nameB) {
			const a = this.splitTeacherName(nameA)
			const b = this.splitTeacherName(nameB)
			// Ưu tiên so sánh theo Tên (TenGV) trước theo chuẩn tiếng Việt
			const tenComp = a.ten.localeCompare(b.ten, 'vi')
			if (tenComp !== 0) return tenComp
			// Nếu trùng tên thì so sánh tiếp theo Họ & Tên lót
			return a.hoLot.localeCompare(b.hoLot, 'vi')
		},
		showSnackbar(message, color = 'info') {
			if (this.$root?.$refs?.snackbarRef?.showSnackbar) {
				this.$root.$refs.snackbarRef.showSnackbar({ message, color })
				return
			}
			if (this.vueData.snackbarRef?.value?.showSnackbar) {
				this.vueData.snackbarRef.value.showSnackbar({ message, color })
			}
		},
		resetTableScroll() {
			// Đưa thanh cuộn của virtual table về đầu bảng khi thay đổi bộ lọc để hiển thị ngay dòng đầu tiên
			this.$nextTick(() => {
				const scrollContainer = this.$el?.querySelector?.('.v-table__wrapper') || this.$el?.querySelector?.('.v-virtual-scroll')
				if (scrollContainer) scrollContainer.scrollTop = 0
			})
		},
		normalizeLookupText(value) {
			return this.cleanSheetValue(value).normalize('NFD').replace(/[\u0300-\u036f]/g, '')
				.toLowerCase().replace(/\s+/g, ' ').trim()
		},
		cleanSheetValue(value) {
			// Luôn chuyển object/array thành chuỗi có nghĩa trước khi đưa vào Excel,
			// tránh sinh ra chuỗi "[object Object]" hoặc làm hỏng JSON của file xuất.
			if (value === null || value === undefined) return ''
			if (typeof value === 'object') {
				try { return JSON.stringify(value) } catch (error) { return '' }
			}
			return String(value).trim()
		},
		flattenRows(response) {
			if (Array.isArray(response)) return response.flat(Infinity).filter(row => row && typeof row === 'object')
			if (Array.isArray(response?.data)) return response.data.flat(Infinity).filter(row => row && typeof row === 'object')
			return []
		},
		normalizeAssignmentUnit(row, knownGroupIds = new Set()) {
			const classId = row.LopID
			const groupId = row.NhomID || row.LopNhomID || row.LopHoacNhomID
			const candidateUnitId = groupId || classId
			const hasClassId = classId !== undefined && classId !== null && String(classId).trim() !== ''
			const isKnownGroup = candidateUnitId !== undefined && candidateUnitId !== null
				&& knownGroupIds.has(String(candidateUnitId))
			// tblNhom có thể được trả về dưới NhomID/LopNhomID hoặc chỉ có tên nhóm;
			// khi đó phải bỏ LopID khỏi bản ghi chuẩn hóa để luồng lấy học sinh không rơi về tblLop.
			const isGroup = Boolean(groupId || row.IsNhom || row.IsLopNhom || isKnownGroup
				|| (!hasClassId && (row.TenNhom || row.TenNhom_HienThi)))
			if (isGroup) {
				const normalizedGroupId = groupId || classId
				const groupName = this.cleanSheetValue(row.TenNhom || row.TenNhom_HienThi || row.TenLop || row.TenLop_HienThi)
				return {
					...row,
					LopID: null,
					NhomID: normalizedGroupId,
					TenNhom: groupName,
					TenLop: groupName,
					KhoiID: row.NhomKhoiID || row.KhoiID,
					IsLopNhom: true
				}
			}
			return {
				...row,
				TenLop: this.cleanSheetValue(row.TenLop || row.TenLop_HienThi)
			}
		},
		isHighSchoolClass(unit = {}) {
			// Chỉ cấp 3 mới có quy ước gộp các lớp phân nhánh như 10A1/10A2 thành 10A;
			// lớp nhóm tblNhom luôn giữ nguyên tên nhóm và không đi qua quy tắc này.
			if (unit.NhomID || unit.LopNhomID || unit.IsLopNhom) return false
			const capId = Number(unit.CapID || unit.CapHocID || 0)
			const grade = Number(unit.KhoiID || unit.NhomKhoiID || 0)
			return capId === 3 || (capId === 0 && grade >= 10 && grade <= 12)
		},
		getDisplayAssignmentClassName(unit = {}) {
			const className = this.cleanSheetValue(unit.TenLop || unit.TenLop_HienThi)
			if (!this.isHighSchoolClass(unit)) return className
			// Hỗ trợ cả tên dạng 10A1 và dạng có tiền tố năm học/suffix cơ sở như 26-10A1 - Biên Hòa.
			const branchMatch = className.match(/^((?:\d{2}-)?\d{1,2}[A-Za-zÀ-ỹ]+)[12](\s*[-–].*)?$/i)
			return branchMatch ? `${branchMatch[1]}${branchMatch[2] || ''}` : className
		},
		async filterAssignmentsBySubjectMapping(rows, knownGroupIds = new Set()) {
			const sourceRows = this.flattenRows(rows)
			const subjectIds = [...new Set(sourceRows
				.map(row => Number(row.MonHocID || 0))
				.filter(monHocId => monHocId > 0))]
			if (!subjectIds.length) return sourceRows

			const mappingsBySubjectGrade = new Map()
			// Lấy mapping một lần cho mỗi môn, thay vì gọi lặp lại theo từng dòng phân công.
			const mappingResponses = await Promise.all(subjectIds.map(monHocId => fetchPromise('lms/MonHocLop_Select_By_MonHocID', {
				MonHocID: monHocId,
				LopID: '',
				NienKhoa: this.schoolYear
			}, { cache: false, suppressError: true }).catch(() => [])))
		mappingResponses.forEach((response, index) => {
			const monHocId = subjectIds[index]
			// API này trả cả dòng lớp chưa có cấu hình; chỉ nhận những dòng thực sự map đúng môn.
			this.flattenRows(response).forEach(mapping => {
				if (Number(mapping.MonHocID || 0) !== monHocId) return
				const unitId = mapping.LopNhomID || mapping.NhomID || mapping.LopID
				if (unitId === undefined || unitId === null || String(unitId).trim() === '') return
				const grade = Number(mapping.KhoiID || 0)
				const key = `${monHocId}__${grade}`
				if (!mappingsBySubjectGrade.has(key)) mappingsBySubjectGrade.set(key, new Set())
				mappingsBySubjectGrade.get(key).add(String(unitId))
			})
		})

			return sourceRows.filter(row => {
				const monHocId = Number(row.MonHocID || 0)
				if (!monHocId) return true
				const grade = Number(row.NhomKhoiID || row.KhoiID || 0)
				const allowedUnits = mappingsBySubjectGrade.get(`${monHocId}__${grade}`)
					|| mappingsBySubjectGrade.get(`${monHocId}__0`)
				if (!allowedUnits || !allowedUnits.size) return true
				const unitId = row.NhomID || row.LopNhomID || row.LopHoacNhomID || row.LopID
				// Môn nhóm (ví dụ Ngoại ngữ) chỉ hợp lệ khi đơn vị là NhomID trong tblNhom;
				// bản ghi cùng môn nhưng chỉ trỏ tới LopID như 12D/12E sẽ bị loại tại đây.
				return unitId !== undefined && unitId !== null && allowedUnits.has(String(unitId))
			})
		},
		normalizeAssignments(rows, knownGroupIds = new Set()) {
			const teacherId = this.getTeacherId()
			const mergedAssignments = new Map()
			this.flattenRows(rows)
				.filter(row => row.Enable === undefined || [true, 1, '1'].includes(row.Enable))
				// Dòng môn của lớp chủ nhiệm tiểu học có thể thuộc giáo viên bộ môn khác;
				// vẫn giữ các dòng đó vì GVCN được phép xem toàn bộ môn của lớp mình.
				.filter(row => this.isBghOrAdmin || row.IsGVCNPrimaryScope || !teacherId || !row.GiaoVienID || String(row.GiaoVienID).trim() === teacherId)
				.filter(row => !row.NienKhoa || Number(row.NienKhoa) === this.schoolYear)
				// GiaoVienLop_Get_ByLopID bổ sung một dòng GVCN với MonHocID = 0 khi lớp chưa có phân công GVCN.
				// Đây không phải dòng môn học để xuất sổ nên phải loại trước khi hiển thị, tránh tên môn mặc định "Môn học".
				.filter(row => Number(row.MonHocID || 0) > 0
					&& this.cleanSheetValue(row.TenMonHoc_HienThi || row.TenMonHoc || row.MonHocName))
				.map(row => {
					const unit = this.normalizeAssignmentUnit(row, knownGroupIds)
					const subjectName = this.cleanSheetValue(unit.TenMonHoc_HienThi || unit.TenMonHoc || unit.MonHocName)
					const semester = Number(unit.HocKy || unit.HocKi || this.selectedSemester) || this.selectedSemester
					const displayClassName = this.getDisplayAssignmentClassName(unit)
					// GVLopID là mã bản ghi phân công, không phải mã dòng hiển thị. Khóa theo
					// tên lớp sau khi gộp + môn + học kì để 10A1/10A2 chỉ còn một dòng 10A.
					const key = `${this.normalizeLookupText(displayClassName)}__${this.normalizeLookupText(subjectName)}__${semester}`
					const classIds = !unit.NhomID && unit.LopID ? [unit.LopID] : []
					return {
						...unit,
						_key: key,
						TenLop: displayClassName,
						LopIDs: classIds,
						TenMonHoc: subjectName,
						HocKy: semester
					}
				})
				.filter(row => (row.NhomID || row.LopID) && row.TenLop)
				.forEach(row => {
					const existing = mergedAssignments.get(row._key)
					if (!existing) {
						mergedAssignments.set(row._key, row)
						return
					}
					// Giữ một dòng hiển thị nhưng giữ toàn bộ LopID để luồng xuất lấy học sinh của A1 và A2.
					existing.LopIDs = [...new Set([...(existing.LopIDs || []), ...(row.LopIDs || [])])]
				})
			return [...mergedAssignments.values()]
				.sort((a, b) => `${a.TenLop} ${a.TenMonHoc}`.localeCompare(`${b.TenLop} ${b.TenMonHoc}`, 'vi'))
		},
		async loadPrimaryHomeroomAssignments() {
			if (this.isBghOrAdmin || !this.getTeacherId()) return []
			// Lop_Get_By_CapID tự nhận SysUserID từ token/session và trả quan hệ GVCN của cấp tiểu học.
			// Chỉ các lớp có GVCN trùng tài khoản hiện tại mới được mở rộng sang toàn bộ môn.
			const classResponse = await fetchPromise('lms/Lop_Get_By_CapID', {
				NienKhoa: this.schoolYear,
				CapID: 1
			}, { cache: false, suppressError: true }).catch(() => [])
			const homeroomClasses = this.flattenRows(classResponse)
				.filter(row => row.Enable === undefined || [true, 1, '1'].includes(row.Enable))
				.filter(row => !row.IsNhom && !row.IsLopNhom)
				.filter(row => this.isCurrentTeacherHomeroom(row))
				.filter(row => row.LopID !== undefined && row.LopID !== null)
				.reduce((uniqueRows, row) => {
					const key = String(row.LopID)
					if (!uniqueRows.some(item => String(item.LopID) === key)) uniqueRows.push(row)
					return uniqueRows
				}, [])
			if (!homeroomClasses.length) return []

			const assignmentResponses = await Promise.all(homeroomClasses.map(async classRow => {
				const rows = await fetchPromise('lms/GiaoVienLop_Get_ByLopID', {
					LopID: classRow.LopID,
					NienKhoa: this.schoolYear,
					HocKi: this.selectedSemester,
					ToGiangDayID: null,
					GiaoVienID: null,
					VaiTro: null
				}, { cache: false, suppressError: true }).catch(() => [])
				return this.flattenRows(rows).map(row => ({
					...row,
					LopID: row.LopID || classRow.LopID,
					TenLop: row.TenLop || classRow.TenLopHienThi || classRow.TenLop,
					KhoiID: row.KhoiID || classRow.KhoiID,
					CapID: row.CapID || classRow.CapID || 1,
					NienKhoa: this.schoolYear,
					HocKy: this.selectedSemester,
					IsGVCNPrimaryScope: true
				}))
			}))
			return assignmentResponses.flat()
		},
		async loadAssignments() {
			this.isLoading = true
			try {
				let response
				if (this.isBghOrAdmin) {
					// Khi BGH/Admin xuất file, không dùng tên tài khoản quản trị làm tên giáo viên;
					// tra bảng giáo viên để điền đúng người được phân công trong từng dòng.
					const teacherRows = await fetchPromise('lms/GiaoVien_Get', {}, {
						cache: false,
						suppressError: true
					}).catch(() => [])
					this.teacherDirectory = this.flattenRows(teacherRows).reduce((directory, teacher) => {
						const teacherId = this.cleanSheetValue(teacher.GiaoVienID)
						const teacherName = this.cleanSheetValue(teacher.HoTenGV || teacher.HoTen || `${teacher.HoGV || ''} ${teacher.TenGV || ''}`)
						if (teacherId && teacherName) directory[teacherId] = teacherName
						return directory
					}, {})
					// Lop_Get_ByNienKhoa chỉ đọc tblLop, nên BGH/Admin sẽ bị thiếu các lớp nhóm trong tblNhom.
					// Lop_Get_ByKhoiID là API chuẩn của màn hình phân công: với quyền 3/5/9, API trả cả tblLop và tblNhom.
					const khoiIds = Array.from({ length: 12 }, (_, index) => index + 1)
					const classResponses = await Promise.all(khoiIds.map(khoiID => fetchPromise('lms/Lop_Get_ByKhoiID', {
						NienKhoa: this.schoolYear,
						HocKi: this.selectedSemester,
						KhoiID: khoiID
					}, { cache: false, suppressError: true }).catch(() => [])))
					const classes = classResponses.flatMap(rows => this.flattenRows(rows))
						.filter(row => row.Enable === undefined || [true, 1, '1'].includes(row.Enable))
						.filter(row => row.LopID !== undefined && row.LopID !== null)
						.reduce((uniqueRows, row) => {
							const key = String(row.LopID)
							if (!uniqueRows.some(item => String(item.LopID) === key)) uniqueRows.push(row)
							return uniqueRows
						}, [])
					const assignmentResponses = await Promise.all(classes.map(async classRow => {
						const classAssignments = await fetchPromise('lms/GiaoVienLop_Get_ByLopID', {
							LopID: classRow.LopID,
							NienKhoa: this.schoolYear,
							HocKi: this.selectedSemester,
							// Ba tham số này là tham số hệ thống/tuỳ chọn của SP; truyền null để hợp đồng API đầy đủ.
							ToGiangDayID: null,
							GiaoVienID: null,
							VaiTro: null
						}, { cache: false, suppressError: true }).catch(() => [])
						const isGroup = classRow.IsNhom === true || Number(classRow.IsNhom) === 1
						return this.flattenRows(classAssignments).map(row => ({
							...row,
							// API phân công theo lớp không trả lại tên lớp/học kì ở mọi môi trường.
							// tblNhom dùng NhomID thay vì LopID; không để tên lớp thường ghi đè tên nhóm.
							LopID: isGroup ? null : (row.LopID || classRow.LopID),
							TenLop: isGroup ? '' : (row.TenLop || classRow.TenLopHienThi || classRow.TenLop),
							NhomID: isGroup ? (row.NhomID || row.LopNhomID || classRow.LopID) : row.NhomID,
							TenNhom: isGroup ? (row.TenNhom || classRow.TenNhom || classRow.TenLopHienThi || classRow.TenLop) : row.TenNhom,
								IsLopNhom: isGroup,
								KhoiID: row.KhoiID || classRow.KhoiID,
								NhomKhoiID: isGroup ? (row.NhomKhoiID || classRow.KhoiID) : row.NhomKhoiID,
								CapID: row.CapID || row.CapHocID || classRow.CapID || classRow.CapHocID,
								NienKhoa: this.schoolYear,
							HocKy: this.selectedSemester
						}))
					}))
					response = assignmentResponses.flat()
				} else {
					// Giáo viên bộ môn chỉ lấy các dòng được phân công cho chính mình.
					const assignedResponse = await fetchPromise('lms/GiaoVienLop_Get_By_GiaoVienID', {
						GiaoVienID: this.getTeacherId(),
						NienKhoa: this.schoolYear
					}, { cache: false })
					// Riêng GVCN tiểu học được xem thêm toàn bộ môn của lớp chủ nhiệm;
					// các giáo viên tiểu học không chủ nhiệm không đi qua nhánh mở rộng này.
					const homeroomResponse = await this.loadPrimaryHomeroomAssignments()
					response = [...this.flattenRows(assignedResponse), ...homeroomResponse]
				}
				const knownGroupIds = new Set(this.flattenRows(response)
					.filter(row => row.NhomID || row.IsNhom || row.IsLopNhom)
					.map(row => String(row.NhomID || row.LopNhomID || row.LopID)))
				response = await this.filterAssignmentsBySubjectMapping(response, knownGroupIds)
				this.assignments = this.normalizeAssignments(response, knownGroupIds)
			} catch (error) {
				this.assignments = []
				this.showSnackbar(error?.Message || error?.message || 'Không tải được phân công giảng dạy.', 'error')
			} finally {
				this.isLoading = false
			}
		},
		async getStudentsForAssignment(row) {
			// Chỉ đọc danh sách học sinh của lớp/phân nhóm đang được chọn;
			// tuyệt đối không lấy điểm, đánh giá hoặc nhận xét trong luồng xuất file.
			const isGroup = Boolean(row.NhomID || row.LopNhomID || row.IsLopNhom)
			const api = isGroup ? 'lms/HocSinhNhom_Get_ByNhomID' : 'lms/HocSinhLop_Get_ByLopID'
			// Cấp 3 có thể gom 10A1 + 10A2 thành dòng 10A; khi đó phải lấy học sinh từ tất cả LopID.
			const lopIds = !isGroup && Array.isArray(row.LopIDs) && row.LopIDs.length
				? row.LopIDs
				: [row.LopID]
			const responses = await Promise.all(lopIds.map(unitId => {
				const params = isGroup
					? { NhomID: row.NhomID || unitId, NienKhoa: this.schoolYear }
					: { LopID: unitId, MonHocID: row.MonHocID || 0, HocLieuID: 0, NienKhoa: this.schoolYear }
				return fetchPromise(api, params, { cache: false })
			}))
			const seen = new Set()
			const students = responses.flatMap(response => this.flattenRows(response))
				.map(student => ({
					...student,
					HoTen: this.cleanSheetValue(student.HoTen || `${student.Ho || ''} ${student.Ten || ''}`),
					SoTT: Number(student.SoTT) || 0,
					SoDanhBo: this.cleanSheetValue(student.SoDanhBo),
					HocSinhID: student.HocSinhID || student.HocSinhId || student.StudentID || ''
				}))
				.filter((student, index) => {
					const uniqueKey = student.HocSinhID ? `id_${student.HocSinhID}` : `name_${student.HoTen}_${index}`
					if (!student.HoTen || seen.has(uniqueKey)) return false
					seen.add(uniqueKey)
					return true
				})
			const hasAnySoDanhBo = students.some(student => Boolean(student.SoDanhBo))
			const getStudentTen = student => this.cleanSheetValue(student.Ten)
			// Nếu cả lớp không có Số danh bộ, dùng đúng cột Ten làm thứ tự chính.
			if (!hasAnySoDanhBo) {
				return students.sort((a, b) => getStudentTen(a).localeCompare(getStudentTen(b), 'vi'))
			}

			// Nếu chỉ một vài học sinh thiếu Số danh bộ (ví dụ mới chuyển lớp),
			// không để các em đó làm thay đổi thứ tự Số danh bộ của cả lớp:
			// các dòng có SDB sort tăng dần, dòng thiếu SDB xuống cuối và sort nội bộ theo Ten.
			return students.sort((a, b) => {
				if (!a.SoDanhBo && !b.SoDanhBo) return getStudentTen(a).localeCompare(getStudentTen(b), 'vi')
				if (!a.SoDanhBo) return 1
				if (!b.SoDanhBo) return -1
				const numberA = Number(a.SoDanhBo)
				const numberB = Number(b.SoDanhBo)
				if (Number.isFinite(numberA) && Number.isFinite(numberB) && numberA !== numberB) return numberA - numberB
				const danhBoOrder = a.SoDanhBo.localeCompare(b.SoDanhBo, 'vi', { numeric: true, sensitivity: 'base' })
				if (danhBoOrder) return danhBoOrder
				return getStudentTen(a).localeCompare(getStudentTen(b), 'vi')
			})
		},
		async buildExportPayload() {
			// Xuất toàn bộ danh sách lớp/môn đang hiển thị theo bộ lọc.
			// Mỗi lớp/môn tạo một bảng danh sách học sinh và được xếp vào từng Sheet riêng biệt trong file Excel.
			const rows = this.filteredAssignments
			if (!rows.length) return []
			return Promise.all(rows.map(async (assignment, index) => ({
				assignment,
				students: await this.getStudentsForAssignment(assignment),
				templateIndex: index + 1
			})))
		},
		getStudentRows(students = []) {
			// Chỉ tạo đúng số dòng theo danh sách học sinh thực tế của lớp, không chèn thêm dòng trống dư thừa
			return students.map((student, index) => ({
				stt: index + 1,
				name: student?.HoTen || ''
			}))
		},
		isPrimaryAssignment(assignment = {}) {
			// Khối 1–5 dùng mẫu Tiểu học riêng trong tải xuống.pdf; không dùng bảng đánh giá THCS/THPT.
			const grade = Number(assignment.KhoiID || assignment.NhomKhoiID || 0)
			if (grade >= 1 && grade <= 5) return true
			if (Number(assignment.CapID || 0) === 1) return true
			return /^(0?[1-5])\s*[A-Za-zÀ-ỹ]/i.test(this.cleanSheetValue(assignment.TenLop))
		},
		splitPrimaryStudentName(fullName) {
			const words = this.cleanSheetValue(fullName).split(/\s+/).filter(Boolean)
			if (!words.length) return { hoLot: '', ten: '' }
			if (words.length === 1) return { hoLot: '', ten: words[0] }
			return { hoLot: words.slice(0, -1).join(' '), ten: words[words.length - 1] }
		},
		buildPrimarySheetData(item) {
			const studentRows = this.getStudentRows(item.students)
			const semesterLabel = Number(this.selectedSemester) === 2 ? 'II' : 'I'
			const className = this.cleanSheetValue(item.assignment.TenLop)
			const teacherName = this.getAssignmentTeacherName(item.assignment)
			const subjectName = this.cleanSheetValue(item.assignment.TenMonHoc)
			return [
				['SỞ GIÁO DỤC VÀ ĐÀO TẠO ĐỒNG NAI', '', '', '', '', '', '', ''],
				['TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG', '', '', '', '', '', '', ''],
				['', '', '', '', '', '', '', ''],
				['SỔ THEO DÕI VÀ ĐÁNH GIÁ', '', '', '', '', '', '', ''],
				['HỌC SINH TIỂU HỌC', '', '', '', '', '', '', ''],
				[`NĂM HỌC ${this.schoolYear}-${this.schoolYear + 1}`, '', '', '', '', '', '', ''],
				[`Họ và tên giáo viên: ${teacherName}`, '', '', '', '', '', '', ''],
				[`Môn: ${subjectName}`, '', '', '', '', '', '', ''],
				['TT', 'Họ lót', 'Tên', 'Lớp', `HỌC KÌ ${semesterLabel}`, '', '', ''],
				['', '', '', '', 'ĐĐG', '', '', 'GHI NHẬN CỦA GIÁO VIÊN'],
				...studentRows.map(row => {
					const name = this.splitPrimaryStudentName(row.name)
					return [row.stt, name.hoLot, name.ten, className, '', '', '', '']
				})
			]
		},
		buildSheetData(item) {
			// Mẫu xuất Excel sổ theo dõi và đánh giá cấp Trung học (THCS / THPT) cho môn đánh giá bằng nhận xét theo chuẩn download.pdf
			// Khối đầu trang: Tên trường, Tên sổ, Họ tên giáo viên, Môn - Lớp, Học kỳ & Phân loại môn học
			// Bảng đánh giá 14 cột chuẩn: Số TT | Họ và tên | Mức đánh giá (Thường xuyên: 5 cột con, Giữa kì, Cuối kì, Học kì, Cả năm) | Mức đánh giá lại (Học kì, Cả năm) | Nhận xét sự tiến bộ...
			const studentRows = this.getStudentRows(item.students)
			const semesterLabel = Number(item.assignment.HocKy || this.selectedSemester) === 2 ? 'II' : 'I'
			const className = this.cleanSheetValue(item.assignment.TenLop)
			const teacherName = this.getAssignmentTeacherName(item.assignment)
			const subjectName = this.cleanSheetValue(item.assignment.TenMonHoc)
			return [
				['TRƯỜNG TH-THCS-THPT SONG NGỮ LẠC HỒNG', '', '', '', '', '', '', '', '', '', '', '', '', ''],
				['SỔ THEO DÕI VÀ ĐÁNH GIÁ HỌC SINH', '', '', '', '', '', '', '', '', '', '', '', '', ''],
				[`Họ và tên giáo viên: ${teacherName}`, '', '', '', '', '', '', '', '', '', '', '', '', ''],
				[`Môn: ${subjectName}`, '', '', '', '', '', `Lớp: ${className}`, '', '', '', '', '', '', ''],
				[`HỌC KỲ ${semesterLabel} (Dùng cho môn học đánh giá bằng nhận xét)`, '', '', '', '', '', '', '', '', '', '', '', '', ''],
				['Số TT', 'Họ và tên', 'Mức đánh giá\nĐạt (Đ), chưa đạt (CĐ)', '', '', '', '', '', '', '', '', 'Mức đánh giá lại\nĐạt (Đ), chưa đạt (CĐ)', '', 'Nhận xét sự tiến bộ, ưu điểm nổi bật, hạn chế chủ yếu'],
				['', '', 'Thường xuyên', '', '', '', '', 'Giữa kì', 'Cuối kì', 'Học kì', 'Cả năm', 'Học kì', 'Cả năm', ''],
				...studentRows.map(row => [row.stt, row.name, '', '', '', '', '', '', '', '', '', '', '', '']),
				['Tổng hợp: Đạt: ............  Chưa đạt: ............', '', '', '', '', '', '', '', '', '', '', '', '', '']
			]
		},
		createSheet(item) {
			if (typeof XLSX === 'undefined') throw new Error('Thư viện Excel chưa sẵn sàng.')
			if (this.isPrimaryAssignment(item.assignment)) return this.createPrimarySheet(item)
			const sheetData = this.buildSheetData(item)
			const worksheet = XLSX.utils.aoa_to_sheet(sheetData)
			const lastRowIndex = sheetData.length - 1
			// Gộp ô (merges) đúng theo cấu trúc tiêu đề và bảng 14 cột của Trung học (chuẩn download.pdf với 5 cột Thường xuyên):
			// - Hàng 0: Tên trường (cột 0 -> 13)
			// - Hàng 1: Tên sổ (cột 0 -> 13)
			// - Hàng 2: Họ và tên giáo viên (cột 0 -> 13)
			// - Hàng 3: Môn học (cột 0 -> 5), Lớp (cột 6 -> 13)
			// - Hàng 4: Học kỳ & ghi chú môn (cột 0 -> 13)
			// - Hàng 5-6 Cột 0: Số TT (rowspan 2)
			// - Hàng 5-6 Cột 1: Họ và tên (rowspan 2)
			// - Hàng 5 Cột 2-10: Mức đánh giá (colspan 9)
			// - Hàng 6 Cột 2-6: Thường xuyên (colspan 5)
			// - Hàng 5 Cột 11-12: Mức đánh giá lại (colspan 2)
			// - Hàng 5-6 Cột 13: Nhận xét sự tiến bộ... (rowspan 2)
			// - Hàng cuối: Dòng Tổng hợp (cột 0 -> 13)
			worksheet['!merges'] = [
				{ s: { r: 0, c: 0 }, e: { r: 0, c: 13 } },
				{ s: { r: 1, c: 0 }, e: { r: 1, c: 13 } },
				{ s: { r: 2, c: 0 }, e: { r: 2, c: 13 } },
				{ s: { r: 3, c: 0 }, e: { r: 3, c: 5 } },
				{ s: { r: 3, c: 6 }, e: { r: 3, c: 13 } },
				{ s: { r: 4, c: 0 }, e: { r: 4, c: 13 } },
				{ s: { r: 5, c: 0 }, e: { r: 6, c: 0 } },
				{ s: { r: 5, c: 1 }, e: { r: 6, c: 1 } },
				{ s: { r: 5, c: 2 }, e: { r: 5, c: 10 } },
				{ s: { r: 6, c: 2 }, e: { r: 6, c: 6 } },
				{ s: { r: 5, c: 11 }, e: { r: 5, c: 12 } },
				{ s: { r: 5, c: 13 }, e: { r: 6, c: 13 } },
				{ s: { r: lastRowIndex, c: 0 }, e: { r: lastRowIndex, c: 13 } }
			]
			// Cấu hình độ rộng 14 cột tương ứng
			worksheet['!cols'] = [
				{ wch: 6 },  // Số TT
				{ wch: 28 }, // Họ và tên
				{ wch: 6 },  // Thường xuyên 1
				{ wch: 6 },  // Thường xuyên 2
				{ wch: 6 },  // Thường xuyên 3
				{ wch: 6 },  // Thường xuyên 4
				{ wch: 6 },  // Thường xuyên 5
				{ wch: 9 },  // Giữa kì
				{ wch: 9 },  // Cuối kì
				{ wch: 9 },  // Học kì
				{ wch: 9 },  // Cả năm
				{ wch: 9 },  // ĐG lại Học kì
				{ wch: 9 },  // ĐG lại Cả năm
				{ wch: 38 }  // Nhận xét sự tiến bộ, ưu điểm nổi bật, hạn chế chủ yếu
			]
			// Cấu hình chiều cao các dòng (row height in points) giúp văn bản thông thoáng, không bị che khuất
			const studentRowCount = item.students?.length || 0
			worksheet['!rows'] = [
				{ hpt: 24 }, // Hàng 0: Tên trường
				{ hpt: 24 }, // Hàng 1: Tên sổ
				{ hpt: 22 }, // Hàng 2: Họ và tên giáo viên
				{ hpt: 22 }, // Hàng 3: Môn - Lớp
				{ hpt: 22 }, // Hàng 4: Học kỳ
				{ hpt: 32 }, // Hàng 5: Header 1 (Mức đánh giá, Mức đánh giá lại, Nhận xét...)
				{ hpt: 26 }, // Hàng 6: Header 2 (Thường xuyên, Giữa kì, Cuối kì...)
				...Array.from({ length: studentRowCount }, () => ({ hpt: 22 })),
				{ hpt: 24 }  // Hàng cuối: Dòng Tổng hợp
			]
			// Freeze sau cột Họ và tên (xSplit 2) và sau hàng tiêu đề (ySplit 7)
			worksheet['!freeze'] = { xSplit: 2, ySplit: 7 }
			return worksheet
		},
		createPrimarySheet(item) {
			const worksheet = XLSX.utils.aoa_to_sheet(this.buildPrimarySheetData(item))
			worksheet['!merges'] = [
				...Array.from({ length: 8 }, (_, row) => ({ s: { r: row, c: 0 }, e: { r: row, c: 7 } })),
				{ s: { r: 8, c: 0 }, e: { r: 9, c: 0 } },
				{ s: { r: 8, c: 1 }, e: { r: 9, c: 1 } },
				{ s: { r: 8, c: 2 }, e: { r: 9, c: 2 } },
				{ s: { r: 8, c: 3 }, e: { r: 9, c: 3 } },
				{ s: { r: 8, c: 4 }, e: { r: 8, c: 7 } },
				{ s: { r: 9, c: 4 }, e: { r: 9, c: 6 } }
			]
			worksheet['!cols'] = [
				{ wch: 7 }, { wch: 28 }, { wch: 14 }, { wch: 10 },
				{ wch: 8 }, { wch: 8 }, { wch: 8 }, { wch: 42 }
			]
			const primaryRowCount = item.students?.length || 0
			worksheet['!rows'] = [
				{ hpt: 22 }, { hpt: 22 }, { hpt: 18 }, { hpt: 22 }, { hpt: 22 },
				{ hpt: 22 }, { hpt: 22 }, { hpt: 22 }, { hpt: 26 }, { hpt: 26 },
				...Array.from({ length: primaryRowCount }, () => ({ hpt: 22 }))
			]
			worksheet['!freeze'] = { xSplit: 4, ySplit: 10 }
			return worksheet
		},
		safeFileName(value, fallback = 'So_Diem') {
			// Đ/đ không tách thành dấu Unicode khi normalize NFD nên phải đổi trước,
			// nếu không tên “Đạo đức” sẽ bị mất chữ Đ thành “ao duc”.
			return this.cleanSheetValue(value).replace(/[Đđ]/g, character => character === 'Đ' ? 'D' : 'd')
				.normalize('NFD').replace(/[\u0300-\u036f]/g, '')
				.replace(/[^a-zA-Z0-9._-]+/g, '_').replace(/^_+|_+$/g, '') || fallback
		},
		getSemesterCode(value = this.selectedSemester) {
			return Number(value) === 2 ? 'HKII' : 'HKI'
		},
		safeSheetName(value, fallback = 'Lop') {
			const name = this.cleanSheetValue(value).replace(/[\\/*?:[\]]/g, '_').slice(0, 28).trim()
			return name || fallback
		},
		getExportTrackingKey(row) {
			const teacherId = this.cleanSheetValue(row.GiaoVienID) || 'gv'
			const unitId = row.NhomID || row.LopID || row.TenLop
			const subjectId = row.MonHocID || row.TenMonHoc
			return `exp_${this.schoolYear}_${row.HocKy || this.selectedSemester}_${teacherId}_${unitId}_${subjectId}`
		},
		async loadExportHistory() {
			// 1. Tải trước từ LocalStorage để render tức thì không bị giật UI
			try {
				const raw = localStorage.getItem(`lms_so_diem_export_history_${this.schoolYear}`)
				if (raw) this.exportHistory = JSON.parse(raw)
			} catch (e) {}

			// 2. Gọi API Database tập trung từ LMS để lấy toàn bộ lịch sử các lần xuất sổ điểm
			try {
				const res = await fetchPromise('lms/LichSuXuatSoDiem_Get', {
					NienKhoa: this.schoolYear,
					HocKy: this.selectedSemester,
					GiaoVienID: ''
				}, { cache: false, suppressError: true })

				const rows = this.flattenRows(res)
				if (Array.isArray(rows) && rows.length > 0) {
					const historyMap = {}
					// Nhóm theo từng phân công (Teacher + Unit + Subject + Semester)
					rows.forEach(dbRow => {
						const key = this.getExportTrackingKey({
							GiaoVienID: dbRow.GiaoVienID,
							LopID: dbRow.LopID,
							NhomID: dbRow.NhomID,
							TenLop: dbRow.TenLop,
							MonHocID: dbRow.MonHocID,
							TenMonHoc: dbRow.TenMonHoc,
							HocKy: dbRow.HocKy
						})

						if (!historyMap[key]) {
							historyMap[key] = {
								key,
								teacherId: dbRow.GiaoVienID,
								teacherName: dbRow.TenGiaoVien,
								unitId: dbRow.NhomID || dbRow.LopID || dbRow.TenLop,
								className: dbRow.TenLop,
								subjectId: dbRow.MonHocID || dbRow.TenMonHoc,
								subjectName: dbRow.TenMonHoc,
								semester: dbRow.HocKy,
								schoolYear: dbRow.NienKhoa,
								count: 0,
								lastExportedAt: null,
								exportedBy: null,
								logs: []
							}
						}

						const logEntry = {
							id: dbRow.ID,
							timestamp: dbRow.ThoiGianXuat,
							exportedBy: dbRow.TenNguoiXuat || dbRow.TenGiaoVien || 'Giáo viên',
							userId: dbRow.NguoiXuatID || ''
						}
						historyMap[key].logs.push(logEntry)
					})

					// Tính toán count và lastExportedAt cho từng phân công
					Object.values(historyMap).forEach(item => {
						item.count = item.logs.length
						if (item.logs.length > 0) {
							item.lastExportedAt = item.logs[0].timestamp
							item.exportedBy = item.logs[0].exportedBy
						}
					})

					this.exportHistory = historyMap
					try {
						localStorage.setItem(`lms_so_diem_export_history_${this.schoolYear}`, JSON.stringify(historyMap))
					} catch (e) {}
				}
			} catch (err) {
				console.warn('Không thể tải lịch sử xuất sổ điểm từ Database, sử dụng cache cục bộ:', err)
			}
			return this.exportHistory
		},
		getExportInfo(row) {
			const key = this.getExportTrackingKey(row)
			return this.exportHistory[key] || null
		},
		getExportLogs(assignment) {
			if (!assignment) return []
			const info = this.getExportInfo(assignment)
			if (!info) return []
			if (Array.isArray(info.logs) && info.logs.length) {
				return info.logs
			}
			if (info.lastExportedAt) {
				return [{
					id: 'legacy-1',
					timestamp: info.lastExportedAt,
					exportedBy: info.exportedBy || 'Giáo viên'
				}]
			}
			return []
		},
		openHistoryDialog(assignment) {
			this.selectedHistoryAssignment = assignment
			this.showHistoryDialog = true
		},
		async recordExport(row) {
			const teacherId = this.cleanSheetValue(row.GiaoVienID) || ''
			const teacherName = this.getAssignmentTeacherName(row) || this.teacherName
			const classId = row.IsLopNhom || row.NhomID ? null : (Number(row.LopID) || null)
			const nhomId = row.IsLopNhom || row.NhomID ? (this.cleanSheetValue(row.NhomID || row.LopID) || null) : null
			const className = this.cleanSheetValue(row.TenLop)
			const subjectId = Number(row.MonHocID) || null
			const subjectName = this.cleanSheetValue(row.TenMonHoc)
			const semester = Number(row.HocKy || this.selectedSemester)
			const schoolYear = Number(this.schoolYear)
			const currentUserId = String(vueData.user?.UserID || vueData.user?.UserName || '')
			const currentUserName = this.teacherName || 'Giáo viên'

			// 1. Lưu vào Database LMS qua Stored Procedure spAPI_LichSuXuatSoDiem_Insert
			try {
				fetchPromise('lms/LichSuXuatSoDiem_Insert', {
					GiaoVienID: teacherId,
					TenGiaoVien: teacherName,
					LopID: classId,
					NhomID: nhomId,
					TenLop: className,
					MonHocID: subjectId,
					TenMonHoc: subjectName,
					HocKy: semester,
					NienKhoa: schoolYear,
					NguoiXuatID: currentUserId,
					TenNguoiXuat: currentUserName
				}, { cache: false, suppressError: true })
			} catch (err) {
				console.warn('Không thể ghi nhận lịch sử xuất vào database:', err)
			}

			// 2. Đồng bộ ngay vào state và localStorage để UI cập nhật ngay tức thì
			const key = this.getExportTrackingKey(row)
			const history = { ...(this.exportHistory || {}) }
			const current = history[key] || {
				key,
				teacherId,
				teacherName,
				unitId: row.NhomID || row.LopID || className,
				className,
				subjectId,
				subjectName,
				semester,
				schoolYear,
				logs: []
			}
			if (!Array.isArray(current.logs)) current.logs = []
			const entry = {
				id: `${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
				timestamp: new Date().toISOString(),
				exportedBy: currentUserName,
				userId: currentUserId
			}
			current.logs.unshift(entry)
			current.count = current.logs.length
			current.lastExportedAt = entry.timestamp
			current.exportedBy = entry.exportedBy
			history[key] = current
			this.exportHistory = history
			try {
				localStorage.setItem(`lms_so_diem_export_history_${this.schoolYear}`, JSON.stringify(history))
			} catch (e) {}
		},
		formatDateTime(isoStr) {
			if (!isoStr) return ''
			try {
				const d = new Date(isoStr)
				const pad = n => String(n).padStart(2, '0')
				return `${pad(d.getHours())}:${pad(d.getMinutes())} ${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}`
			} catch (e) {
				return isoStr
			}
		},
		async exportExcel() {
			this.isExporting = true
			try {
				const payload = await this.buildExportPayload()
				if (!payload.length) return

				// Gom nhóm phân công theo từng giáo viên: Mỗi giáo viên xuất ra 1 file Excel duy nhất
				// Trong file Excel đó, mỗi lớp / môn học sẽ nằm trên 1 sheet riêng biệt
				const groupsByTeacher = new Map()
				for (const item of payload) {
					const tId = this.cleanSheetValue(item.assignment.GiaoVienID) || 'default'
					if (!groupsByTeacher.has(tId)) {
						groupsByTeacher.set(tId, {
							teacherId: tId,
							teacherName: this.getAssignmentTeacherName(item.assignment) || this.teacherName,
							items: []
						})
					}
					groupsByTeacher.get(tId).items.push(item)
				}

				let totalSheetsExported = 0
				for (const group of groupsByTeacher.values()) {
					const workbook = XLSX.utils.book_new()
					const usedSheetNames = new Set()

					for (const item of group.items) {
						const className = this.cleanSheetValue(item.assignment.TenLop)
						const subjectName = this.cleanSheetValue(item.assignment.TenMonHoc)

						// Đặt tên sheet dạng: "TênLớp - TênMôn", giới hạn tối đa 30 ký tự chuẩn Excel và đảm bảo không trùng
						let baseSheetName = this.safeSheetName(`${className} - ${subjectName}`)
						let sheetName = baseSheetName
						let counter = 2
						while (usedSheetNames.has(sheetName)) {
							const suffix = ` (${counter++})`
							sheetName = `${baseSheetName.slice(0, 30 - suffix.length)}${suffix}`
						}
						usedSheetNames.add(sheetName)

						// Tạo dữ liệu bảng của lớp/môn tương ứng và đính kèm vào workbook
						const worksheet = this.createSheet(item)
						XLSX.utils.book_append_sheet(workbook, worksheet, sheetName)
						totalSheetsExported++
					}

					// Đặt tên file Excel theo giáo viên và học kì
					let fileName
					if (group.items.length === 1) {
						const single = group.items[0]
						const className = this.cleanSheetValue(single.assignment.TenLop)
						const subjectName = this.cleanSheetValue(single.assignment.TenMonHoc)
						fileName = `${this.safeFileName(`So_Diem_${group.teacherName}_${className}_${subjectName}_${this.getSemesterCode(single.assignment.HocKy)}`)}.xlsx`
					} else {
						fileName = `${this.safeFileName(`So_Diem_${group.teacherName}_${this.getSemesterCode(this.selectedSemester)}_${this.schoolYear}`)}.xlsx`
					}

					XLSX.writeFile(workbook, fileName)

					// Ghi nhận lịch sử xuất file cho tất cả các phân công trong file Excel này
					for (const item of group.items) {
						this.recordExport(item.assignment)
					}

					// Nhường một nhịp cho trình duyệt xử lý lượt tải
					await new Promise(resolve => setTimeout(resolve, 100))
				}

				this.showSnackbar(`Đã xuất thành công ${groupsByTeacher.size} file Excel (${totalSheetsExported} sheet lớp/môn).`, 'success')
			} catch (error) {
				this.showSnackbar(error?.message || 'Không thể xuất Excel.', 'error')
			} finally {
				this.isExporting = false
			}
		}
	}
	}
</script>