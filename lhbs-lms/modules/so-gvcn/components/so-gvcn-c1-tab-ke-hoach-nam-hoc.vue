<template>
	<!-- Khóa tab theo viewport để menu và tiêu đề đứng yên; nội dung kế hoạch cuộn trong vùng bên phải. -->
	<v-card-text class="pa-2 so-gvcn-sheet-wrap so-gvcn-plan-tab" :style="{ height: sheetHeight, overflow: 'hidden', minWidth: '0', maxWidth: '100%', boxSizing: 'border-box' }">
		<v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact">
			Chọn một lớp ở thanh trên để lập kế hoạch chủ nhiệm năm học.
		</v-alert>
		<div v-else class="d-flex ga-3" style="flex: 1 1 auto; min-height: 0; min-width: 0; max-width: 100%; overflow: hidden;">
			<div v-if="!sidebarCollapsed" class="flex-shrink-0 overflow-y-auto"
				style="width: 260px; border-right: 1px solid rgba(0, 0, 0, 0.12);">
				<v-list density="compact" nav color="primary" class="pa-0">
					<v-list-subheader class="text-caption font-weight-bold text-primary px-3">
						I. ĐẶC ĐIỂM TÌNH HÌNH
					</v-list-subheader>
					<v-list-item :value="planCards[0].key" :active="activeCardKey === planCards[0].key"
						class="mb-1 rounded" @click="scrollToCard(planCards[0])">
						<template #prepend>
							<v-icon size="small" class="mr-2">{{ planCards[0].icon }}</v-icon>
						</template>
						<v-list-item-title class="text-caption font-weight-bold">
							{{ planCards[0].navTitle }}
						</v-list-item-title>
					</v-list-item>
					<v-list-subheader class="text-caption font-weight-bold text-primary px-3 mt-2">
						II. NỘI DUNG KẾ HOẠCH
					</v-list-subheader>
					<v-list-item :value="planCards[1].key" :active="activeCardKey === planCards[1].key"
						class="mb-1 rounded" @click="scrollToCard(planCards[1])">
						<template #prepend>
							<v-icon size="small" class="mr-2"
								:color="activeCardKey === planCards[1].key ? 'primary' : ''">
								{{ planCards[1].icon }}
							</v-icon>
						</template>
						<v-list-item-title class="text-caption font-weight-bold text-wrap" style="line-height: 1.3;">
							{{ planCards[1].navTitle }}
						</v-list-item-title>
					</v-list-item>
					<v-list-subheader class="text-caption font-weight-bold text-primary px-3 mt-2">
						2. CHẤT LƯỢNG GIÁO DỤC
					</v-list-subheader>
					<v-list-item v-for="card in planCards.slice(2, 5)" :key="card.key" :value="card.key"
						:active="activeCardKey === card.key" class="mb-1 rounded" @click="scrollToCard(card)">
						<template #prepend>
							<v-icon size="small" class="mr-2" :color="activeCardKey === card.key ? 'primary' : ''">
								{{ card.icon }}
							</v-icon>
						</template>
						<v-list-item-title class="text-caption font-weight-bold text-wrap" style="line-height: 1.3;">
							{{ card.navTitle }}
						</v-list-item-title>
					</v-list-item>
					<v-list-item :value="planCards[5].key" :active="activeCardKey === planCards[5].key"
						class="mb-1 rounded" @click="scrollToCard(planCards[5])">
						<template #prepend>
							<v-icon size="small" class="mr-2"
								:color="activeCardKey === planCards[5].key ? 'primary' : ''">
								{{ planCards[5].icon }}
							</v-icon>
						</template>
						<v-list-item-title class="text-caption font-weight-bold text-wrap" style="line-height: 1.3;">
							{{ planCards[5].navTitle }}
						</v-list-item-title>
					</v-list-item>
				</v-list>
			</div>

			<!-- min-height: 0 cho phép vùng này thu nhỏ theo tab; nhờ đó chỉ một scrollbar nội dung được tạo. -->
			<div ref="scrollContainer" class="flex-grow-1 overflow-y-auto" style="min-width: 0; min-height: 0; overflow-x: hidden;" @wheel.capture="onSheetWheel">
				<div class="d-flex align-center text-h6 text-center font-weight-bold py-2">
					<v-btn icon variant="text" size="small" class="mr-2"
						:aria-label="sidebarCollapsed ? 'Hiện menu mục' : 'Ẩn menu mục'"
						@click="sidebarCollapsed = !sidebarCollapsed">
						<v-icon>{{ sidebarCollapsed ? 'mdi-chevron-right' : 'mdi-chevron-left' }}</v-icon>
					</v-btn>
					<div class="flex-grow-1">
					KẾ HOẠCH CHỦ NHIỆM NĂM HỌC
					<div class="text-body-2 mt-1">
						LỚP {{ selectedClass?.TenLop || '.....' }} - NĂM HỌC {{ schoolYearText }}
					</div>
					</div>
				</div>

				<v-row dense class="pb-16">
					<v-col cols="12" class="py-2">
						<v-card :id="planCards[0].domId" variant="outlined" elevation="0">
							<v-card-title
								class="px-3 py-2 text-subtitle-2 font-weight-bold text-primary d-flex align-start"
								style="white-space: pre-line; line-height: 1.6;">
								<v-icon start color="primary" class="mr-2 mt-1" size="small">{{ planCards[0].icon }}
								</v-icon>
								{{ planCards[0].title }}
							</v-card-title>
							<v-divider />
							<v-card-text class="pa-2">
								<div class="wrapper-jexcel">
									<div :ref="planCards[0].refName" class="w-100 so-gvcn-sheet"
										:style="{ height: planCards[0].height }"></div>
								</div>
								<v-textarea v-model="planText.advantages" label="2. Thuận lợi" rows="4" auto-grow
									variant="outlined" density="compact" class="mt-3 mb-2" />
								<v-textarea v-model="planText.difficulties" label="3. Khó khăn" rows="4" auto-grow
									variant="outlined" density="compact" hide-details />
							</v-card-text>
						</v-card>
					</v-col>

					<v-col cols="12" class="py-2">
						<v-card variant="outlined" elevation="0">
							<v-card-title class="px-3 py-2 text-subtitle-2 font-weight-bold text-primary">
								<v-icon start color="primary" class="mr-2" size="small">mdi-clipboard-text-outline
								</v-icon>
								II. NỘI DUNG KẾ HOẠCH CHỦ NHIỆM
							</v-card-title>
							<v-divider />
							<v-card-text class="pa-0">
								<section v-for="(card, index) in planCards.slice(1)" :id="card.domId" :key="card.key"
									class="pa-3" :class="{ 'border-t': index > 0 }">
									<div v-if="card.key === 'pham-chat-nang-luc'"
										class="text-subtitle-1 font-weight-bold text-primary mb-3">
										2. CHẤT LƯỢNG GIÁO DỤC
									</div>
									<div class="text-subtitle-2 font-weight-bold text-primary mb-3"
										style="white-space: pre-line; line-height: 1.6;">
										{{ card.title }}
									</div>

									<div v-if="!card.textOnly" class="wrapper-jexcel">
										<div :ref="card.refName" class="w-100 so-gvcn-sheet"
											:style="{ height: card.height }"></div>
									</div>

									<template v-if="card.key === 'duy-tri-so-luong'">
										<v-textarea v-model="planText.attendanceTarget" label="1.1. Chỉ tiêu phấn đấu"
											rows="4" auto-grow variant="outlined" density="compact" class="mb-2" />
										<v-textarea v-model="planText.attendanceSolution"
											label="1.2. Nhiệm vụ và giải pháp" rows="4" auto-grow variant="outlined"
											density="compact" hide-details />
									</template>
									<v-textarea v-if="card.key === 'pham-chat-nang-luc'"
										v-model="planText.qualitySolution" label="b. Nhiệm vụ và giải pháp" rows="4"
										auto-grow variant="outlined" density="compact" class="mt-3" hide-details />
									<v-textarea v-if="card.key === 'mon-hoc-hoat-dong'"
										v-model="planText.academicSolution" label="b. Nhiệm vụ và giải pháp" rows="4"
										auto-grow variant="outlined" density="compact" class="mt-3" hide-details />
									<template v-if="card.key === 'phong-trao-vo-sach'">
										<v-textarea v-model="planText.handwritingTarget" label="a. Chỉ tiêu phấn đấu"
											rows="4" auto-grow variant="outlined" density="compact" class="mb-2" />
										<v-textarea v-model="planText.handwritingSolution"
											label="b. Nhiệm vụ và giải pháp" rows="4" auto-grow variant="outlined"
											density="compact" hide-details />
									</template>
									<div v-if="card.key === 'hoat-dong-khac'">
										<div class="text-body-2 font-weight-bold mb-2">3.1. Hoạt động ngoài giờ lên lớp
										</div>
										<v-textarea v-model="planText.extracurricularTarget" label="a. Chỉ tiêu"
											rows="4" auto-grow variant="outlined" density="compact" class="mb-2" />
										<v-textarea v-model="planText.extracurricularSolution"
											label="b. Nhiệm vụ và giải pháp" rows="4" auto-grow variant="outlined"
											density="compact" class="mb-3" />

										<div class="text-body-2 font-weight-bold mb-2">
											3.2. Trang trí lớp học, giữ gìn và bảo quản CSVC của lớp
										</div>
										<v-textarea v-model="planText.classroomTarget"
											label="a. Chỉ tiêu (số lượng, tỉ lệ %)" rows="4" auto-grow
											variant="outlined" density="compact" class="mb-2" />
										<v-textarea v-model="planText.classroomSolution"
											label="b. Nhiệm vụ và giải pháp" rows="4" auto-grow variant="outlined"
											density="compact" class="mb-3" />

										<div class="text-body-2 font-weight-bold mb-2">
											3.3. Công tác lao động, xây dựng trường lớp xanh - sạch - đẹp
										</div>
										<v-textarea v-model="planText.laborTarget"
											label="a. Chỉ tiêu (số lượng, tỉ lệ %)" rows="4" auto-grow
											variant="outlined" density="compact" class="mb-2" />
										<v-textarea v-model="planText.laborSolution" label="b. Nhiệm vụ và giải pháp"
											rows="4" auto-grow variant="outlined" density="compact" class="mb-3" />

										<div class="text-body-2 font-weight-bold mb-2">3.4. Công tác xã hội hoá giáo dục
										</div>
										<v-textarea v-model="planText.socializationTarget"
											label="a. Chỉ tiêu (số lượng, tỉ lệ %)" rows="4" auto-grow
											variant="outlined" density="compact" class="mb-2" />
										<v-textarea v-model="planText.socializationSolution"
											label="b. Nhiệm vụ và giải pháp" rows="4" auto-grow variant="outlined"
											density="compact" hide-details />
									</div>
								</section>
							</v-card-text>
						</v-card>
					</v-col>
				</v-row>
			</div>
		</div>
	</v-card-text>
</template>

<script>
	export default {
		name: 'so-gvcn-c1-tab-ke-hoach-nam-hoc',
		props: {
			selectedLopID: { type: [String, Number], default: '__ALL__' },
			selectedClass: { type: Object, default: null },
			schoolYearText: { type: String, default: '' },
			sheetHeight: { type: String, default: 'calc(100vh - 230px)' },
			annualPlan: { type: [String, Object], default: '' }
		},
		data() {
			return {
				activeCardKey: 'dac-diem',
				sidebarCollapsed: false,
				sheetInstances: {},
				qualityCompetencySubjects: this.getDefaultQualityCompetencySubjects(),
				academicSubjectCatalog: [],
				academicSubjects: this.getDefaultAcademicSubjects(),
				planText: this.buildPlanText(this.annualPlan),
				planCards: this.buildPlanCards(this.annualPlan)
			}
		},
		watch: {
			selectedLopID() {
				this.planText = this.buildPlanText(this.annualPlan)
				this.planCards = this.buildPlanCards(this.annualPlan)
				this.initAllSheets()
			},
			annualPlan(value) {
				this.planText = this.buildPlanText(value)
				this.planCards = this.buildPlanCards(value)
				this.initAllSheets()
			}
		},
		async mounted() {
			await this.loadQualityCompetencySubjects()
			this.planCards = this.buildPlanCards(this.annualPlan)
			this.initAllSheets()
		},
		beforeUnmount() {
			this.destroyAllSheets()
		},
		methods: {
			onSheetWheel(event) {
				// JSpreadsheet bắt wheel ngay cả khi bảng không có scrollbar dọc
				// (CSS của tab này cho bảng giãn theo nội dung). Chuyển wheel đó
				// sang vùng nội dung của tab để khi rê chuột trên bảng vẫn cuộn được.
				if (!event.deltaY || !event.target?.closest?.('.jss_content, .jspreadsheet_content, .jexcel_content')) return
				const container = this.$refs.scrollContainer
				if (!container || container.scrollHeight <= container.clientHeight) return
				const nextTop = Math.max(0, Math.min(
					container.scrollTop + event.deltaY,
					container.scrollHeight - container.clientHeight
				))
				if (nextTop === container.scrollTop) return
				event.preventDefault()
				container.scrollTop = nextTop
			},
			// Các bảng kế hoạch có ít dòng nên lấy chiều cao tự nhiên theo dữ liệu;
			// chỉ phần ngang mới cần cuộn, tránh kéo bảng 6 dòng cao bằng cả viewport.
			getPlanTableHeight(rowCount, nestedHeaderCount = 0) {
				const rowHeight = 24
				const headerHeight = Math.max(1, Number(nestedHeaderCount) + 1) * 28
				const dataHeight = Math.max(1, Number(rowCount) || 0) * rowHeight
				// Tên môn ở các header lồng nhau có thể xuống 2-3 dòng; chừa thêm
				// vùng header đó và thanh cuộn ngang để dòng dữ liệu cuối không bị che.
				const wrappedHeaderAllowance = Number(nestedHeaderCount) > 0 ? 48 : 0
				// Bảng có nested header đã chừa phần cuộn trong header; chỉ bảng
				// thống kê không có nested header cần đủ 16px cho scrollbar ngang.
				const horizontalScrollbarHeight = Number(nestedHeaderCount) > 0 ? 4 : 16
				return `${headerHeight + wrappedHeaderAllowance + dataHeight + horizontalScrollbarHeight + 2}px`
			},
			buildPlanCards(value) {
				// The column is shared across primary grades, but its subject identity
				// must follow the curriculum: grades 1-3 use TNXH and grades 4-5 use
				// Science. This also keeps subjectTargets keyed by the real MonHocID.
				this.academicSubjects = this.getAcademicSubjectsForSelectedClass()
				const saved = this.parseAnnualPlan(value)
				const situationRows = this.buildSituationRows(saved)
				const qualityRows = this.buildQualityCompetencyRows(saved)
				const qualityHeaders = this.buildQualityCompetencyNestedHeaders()
				const academicRows = this.buildAcademicRows(saved)
				const academicHeaders = this.buildAcademicNestedHeaders()
				return [
					{
						key: 'dac-diem',
						roman: 'I',
						navTitle: '1. Thống kê tình hình lớp học',
						icon: 'mdi-chart-box-outline',
						domId: 'ke-hoach-nam-hoc-muc-i',
						refName: 'annualSectionIRef',
						title: 'I. ĐẶC ĐIỂM TÌNH HÌNH\n1. THỐNG KÊ TÌNH HÌNH LỚP HỌC',
						columns: [
							{ title: 'Thời điểm / Nội dung', width: 190, readOnly: true },
							{ title: 'Tổng số', width: 85 },
							{ title: 'Nữ', width: 70 },
							{ title: 'Dân tộc', width: 85 },
							{ title: 'Lưu ban', width: 85 },
							{ title: 'Cần quan tâm', width: 120 },
							{ title: 'Con thương binh', width: 130 },
							{ title: 'Con liệt sĩ', width: 110 },
							{ title: 'Hộ nghèo', width: 90 },
							{ title: 'Hộ cận nghèo', width: 110 },
							{ title: 'CB/CCVC', width: 90 },
							{ title: 'Ghi chú', width: 240 }
						],
						rows: situationRows,
						height: this.getPlanTableHeight(situationRows.length)
					},
					{
						key: 'duy-tri-so-luong',
						roman: 'II',
						navTitle: '1. Duy trì số lượng',
						icon: 'mdi-clipboard-text-outline',
						domId: 'ke-hoach-nam-hoc-muc-ii',
						title: '1. DUY TRÌ SỐ LƯỢNG',
						textOnly: true
					},
					{
						key: 'pham-chat-nang-luc',
						roman: 'II',
						navTitle: '2.1. Phẩm chất – Năng lực',
						icon: 'mdi-account-star-outline',
						domId: 'ke-hoach-nam-hoc-muc-ii-pcnl',
						refName: 'annualQualityCompetencyRef',
						title: '2.1. PHẨM CHẤT – NĂNG LỰC\na. CHỈ TIÊU PHẤN ĐẤU',
						freezeColumns: 1,
						columns: this.buildQualityCompetencyColumns(),
						nestedHeaders: qualityHeaders,
						rows: qualityRows,
						height: this.getPlanTableHeight(qualityRows.length, qualityHeaders.length)
					},
					{
						key: 'mon-hoc-hoat-dong',
						roman: 'II',
						navTitle: '2.2. Môn học và HĐGD',
						icon: 'mdi-book-open-page-variant-outline',
						domId: 'ke-hoach-nam-hoc-muc-ii-mon-hoc',
						refName: 'annualAcademicTargetRef',
						title: '2.2. MÔN HỌC VÀ HOẠT ĐỘNG GIÁO DỤC\na. CHỈ TIÊU PHẤN ĐẤU',
						freezeColumns: 1,
						columns: this.buildAcademicColumns(),
						nestedHeaders: academicHeaders,
						rows: academicRows,
						height: this.getPlanTableHeight(academicRows.length, academicHeaders.length)
					},
					{
						key: 'phong-trao-vo-sach',
						roman: 'II',
						navTitle: '2.3. Vở sạch viết chữ đẹp',
						icon: 'mdi-text-box-edit-outline',
						domId: 'ke-hoach-nam-hoc-muc-ii-vo-sach',
						title: '2.3. PHONG TRÀO VỞ SẠCH VIẾT CHỮ ĐẸP',
						textOnly: true
					},
					{
						key: 'hoat-dong-khac',
						roman: 'II',
						navTitle: '3. Các hoạt động khác',
						icon: 'mdi-format-list-checks',
						domId: 'ke-hoach-nam-hoc-muc-iii-hoat-dong',
						title: '3. CÁC HOẠT ĐỘNG KHÁC',
						textOnly: true
					}
				]
			},
			getDefaultAcademicSubjects() {
				return [
					{ MonHocID: 1, TenMonHoc_HienThi: 'Tiếng Việt' },
					{ MonHocID: 2, TenMonHoc_HienThi: 'Toán' },
					{ MonHocID: 5, TenMonHoc_HienThi: 'Ngoại ngữ' },
					{ MonHocID: 19, TenMonHoc_HienThi: 'Lịch sử và Địa lí' },
					{ MonHocID: 4, TenMonHoc_HienThi: 'Khoa học' },
					{ MonHocID: 6, TenMonHoc_HienThi: 'Tin học và Công nghệ (Tin học)' },
					{ MonHocID: 35, TenMonHoc_HienThi: 'Tin học và Công nghệ (Công nghệ)' },
					{ MonHocID: 8, TenMonHoc_HienThi: 'Đạo đức' },
					{ MonHocID: 12, TenMonHoc_HienThi: 'Giáo dục thể chất' },
					{ MonHocID: 9, TenMonHoc_HienThi: 'Nghệ thuật (Âm nhạc)' },
					{ MonHocID: 10, TenMonHoc_HienThi: 'Nghệ thuật (Mĩ thuật)' },
					{ MonHocID: 11, TenMonHoc_HienThi: 'Hoạt động trải nghiệm' }
				]
			},
			getAcademicSubjectsForSelectedClass() {
				const defaultSubjects = this.getDefaultAcademicSubjects()
				const subjects = (this.academicSubjects?.length === defaultSubjects.length
					? this.academicSubjects
					: defaultSubjects).map(subject => ({ ...subject }))
				const grade = Number(this.selectedClass?.KhoiID)
				const scienceIndex = defaultSubjects.findIndex(subject => subject.MonHocID === 4)
				if (scienceIndex < 0) return subjects

				if (grade >= 1 && grade <= 3) {
					const normalize = value => String(value || '')
						.normalize('NFD')
						.replace(/[\u0300-\u036f]/g, '')
						.toLowerCase()
						.replace(/đ/g, 'd')
					const tnxh = (this.academicSubjectCatalog || []).find(subject => {
						const name = normalize(subject.TenMonHoc_HienThi || subject.MonHocName || subject.TenMonHoc)
						const code = normalize(subject.MonHocCode)
						return name.includes('tu nhien va xa hoi') || code === 'tnxh'
					})
					// MonHocID 3 is the legacy LMS ID for Tự nhiên và Xã hội. Prefer
					// the live catalog, while retaining a safe fallback for old data.
					subjects[scienceIndex] = {
						...subjects[scienceIndex],
						MonHocID: Number(tnxh?.MonHocID) || 3,
						TenMonHoc_HienThi: 'TNXH/Khoa học'
					}
				} else {
					subjects[scienceIndex] = {
						...subjects[scienceIndex],
						MonHocID: 4,
						TenMonHoc_HienThi: 'TNXH/Khoa học'
					}
				}
				return subjects
			},
			getDefaultQualityCompetencySubjects() {
				return [
					{ MonHocID: 23, TenMonHoc_HienThi: 'Phẩm chất-Yêu nước', group: 'Phẩm chất' },
					{ MonHocID: 24, TenMonHoc_HienThi: 'Phẩm chất-Nhân ái', group: 'Phẩm chất' },
					{ MonHocID: 25, TenMonHoc_HienThi: 'Phẩm chất-Chăm chỉ', group: 'Phẩm chất' },
					{ MonHocID: 26, TenMonHoc_HienThi: 'Phẩm chất-Trung thực', group: 'Phẩm chất' },
					{ MonHocID: 27, TenMonHoc_HienThi: 'Phẩm chất-Trách nhiệm', group: 'Phẩm chất' },
					{ MonHocID: 20, TenMonHoc_HienThi: 'Năng lực-Tự chủ và tự học', group: 'Năng lực' },
					{ MonHocID: 21, TenMonHoc_HienThi: 'Năng lực-Giao tiếp và hợp tác', group: 'Năng lực' },
					{ MonHocID: 22, TenMonHoc_HienThi: 'Năng lực-Giải quyết vấn đề và sáng tạo', group: 'Năng lực' },
					{ MonHocID: 28, TenMonHoc_HienThi: 'Năng lực-Ngôn ngữ', group: 'Năng lực' },
					{ MonHocID: 29, TenMonHoc_HienThi: 'Năng lực-Tính toán', group: 'Năng lực' },
					{ MonHocID: 30, TenMonHoc_HienThi: 'Năng lực-Khoa học', group: 'Năng lực' },
					{ MonHocID: 31, TenMonHoc_HienThi: 'Năng lực-Công nghệ', group: 'Năng lực' },
					{ MonHocID: 32, TenMonHoc_HienThi: 'Năng lực-Tin học', group: 'Năng lực' },
					{ MonHocID: 33, TenMonHoc_HienThi: 'Năng lực-Thẩm mĩ', group: 'Năng lực' },
					{ MonHocID: 34, TenMonHoc_HienThi: 'Năng lực-Thể chất', group: 'Năng lực' }
				]
			},
			async loadQualityCompetencySubjects() {
				if (typeof ajaxCALLPromise !== 'function') return
				try {
					const subjects = await ajaxCALLPromise('lms/MonHoc_Get_ByCapID', { CapID: 1 })
					this.academicSubjectCatalog = Array.isArray(subjects) ? subjects : []
					const subjectById = new Map((subjects || []).map(subject => [Number(subject.MonHocID), subject]))
					this.qualityCompetencySubjects = this.getDefaultQualityCompetencySubjects().map(fallback => ({
						...fallback,
						...(subjectById.get(fallback.MonHocID) || {})
					}))
					this.academicSubjects = this.getDefaultAcademicSubjects().map(fallback => ({
						...fallback,
						...(subjectById.get(fallback.MonHocID) || {})
					}))
					this.academicSubjects = this.getAcademicSubjectsForSelectedClass()
				} catch (error) {
					console.error('Không thể tải danh sách môn học, phẩm chất và năng lực từ tblMonHoc:', error)
				}
			},
			getQualityCompetencyName(subject) {
				const name = subject.TenMonHoc_HienThi || subject.MonHocName || subject.TenMonHoc || ''
				return name.replace(/^(Phẩm chất|Năng lực)\s*[-–]\s*/i, '').trim()
			},
			buildQualityCompetencyColumns() {
				const subjects = this.qualityCompetencySubjects || this.getDefaultQualityCompetencySubjects()
				return [
					{ title: 'Xếp loại', width: 150, readOnly: true },
					...subjects.map(() => (
						{ title: 'Tỉ lệ (%)', width: 100, type: 'numeric' }
					))
				]
			},
			buildQualityCompetencyNestedHeaders() {
				const subjects = this.qualityCompetencySubjects || this.getDefaultQualityCompetencySubjects()
				const qualityCount = subjects.filter(subject => subject.group === 'Phẩm chất').length
				const competencyCount = subjects.length - qualityCount
				return [
					[
						{ title: '', colspan: 1 },
						{ title: 'Phẩm chất', colspan: qualityCount },
						{ title: 'Năng lực', colspan: competencyCount }
					],
					[
						{ title: '', colspan: 1 },
						...subjects.map(subject => ({
							title: this.getQualityCompetencyName(subject),
							colspan: 1
						}))
					]
				]
			},
			buildQualityCompetencyRows(saved) {
				const subjects = this.qualityCompetencySubjects || this.getDefaultQualityCompetencySubjects()
				const targetColCount = 1 + subjects.length
				const savedRows = saved.qualityCompetencyTargets || saved['pham-chat-nang-luc']
				if (Array.isArray(savedRows) && savedRows.length >= 2) {
					// Mảng cũ 3 dòng: [0: Tốt, 1: Đạt, 2: Cần cố gắng]
					// Lấy đúng dòng 0 (Tốt) và dòng 2 (Cần cố gắng - dòng cuối trong mảng cũ)
					const row0 = (savedRows[0] || []).slice(0, targetColCount)
					const lastIndex = savedRows.length - 1
					const row1 = (savedRows[lastIndex] || []).slice(0, targetColCount)
					while (row0.length < targetColCount) row0.push('')
					while (row1.length < targetColCount) row1.push('')
					row0[0] = 'Tốt (T) ≥'
					row1[0] = 'Cần cố gắng (C)'
					return [row0, row1]
				}
				return [
					['Tốt (T) ≥', ...subjects.map(() => '')],
					['Cần cố gắng (C)', ...subjects.map(() => '')]
				]
			},
			buildAcademicColumns() {
				const subjects = this.academicSubjects || this.getDefaultAcademicSubjects()
				return [
					{ title: 'Xếp loại', width: 170, readOnly: true },
					...subjects.map(() => (
						{ title: 'Tỉ lệ (%)', width: 100, type: 'numeric' }
					))
				]
			},
			buildAcademicNestedHeaders() {
				const subjects = this.academicSubjects || this.getDefaultAcademicSubjects()
				return [[
					{ title: '', colspan: 1 },
					...subjects.map(subject => ({
						title: subject.TenMonHoc_HienThi || subject.MonHocName || subject.TenMonHoc || '',
						colspan: 1
					}))
				]]
			},
			buildAcademicRows(saved) {
				const subjects = this.academicSubjects || this.getDefaultAcademicSubjects()
				const targetColCount = 1 + subjects.length
				const savedRows = saved.academicTargets || saved['mon-hoc-hoat-dong']
				if (Array.isArray(savedRows) && savedRows.length >= 2) {
					// Mảng cũ 3 dòng: [0: Hoàn thành tốt, 1: Hoàn thành, 2: Chưa hoàn thành]
					// Lấy đúng dòng 0 (Hoàn thành tốt) và dòng 2 (Chưa hoàn thành - dòng cuối trong mảng cũ)
					const row0 = (savedRows[0] || []).slice(0, targetColCount)
					const lastIndex = savedRows.length - 1
					const row1 = (savedRows[lastIndex] || []).slice(0, targetColCount)
					while (row0.length < targetColCount) row0.push('')
					while (row1.length < targetColCount) row1.push('')
					row0[0] = 'Hoàn thành tốt (T) ≥'
					row1[0] = 'Chưa hoàn thành (C)'
					return [row0, row1]
				}
				return [
					['Hoàn thành tốt (T) ≥', ...subjects.map(() => '')],
					['Chưa hoàn thành (C)', ...subjects.map(() => '')]
				]
			},
			parseAnnualPlan(value) {
				if (!value) return {}
				try {
					return typeof value === 'string' ? JSON.parse(value) : value
				} catch (error) {
					return {}
				}
			},
			buildPlanText(value) {
				const saved = this.parseAnnualPlan(value)
				const savedRows = Array.isArray(saved.sectionII) ? saved.sectionII : []
				const getLegacyValues = (prefix, key) => {
					const row = savedRows.find(item => String(item?.[0] || '').startsWith(prefix))
					return {
						target: row?.[1] || saved.sections?.[key]?.target || '',
						solution: row?.[2] || saved.sections?.[key]?.solution || ''
					}
				}
				const academic = getLegacyValues('2.2.', 'subjects')
				const attendance = getLegacyValues('1.', 'attendance')
				const quality = getLegacyValues('2.1.', 'qualities')
				const handwriting = getLegacyValues('2.3.', 'handwriting')
				const extracurricular = getLegacyValues('3.1.', 'extracurricular')
				const classroom = getLegacyValues('3.2.', 'classroom')
				const labor = getLegacyValues('3.3.', 'labor')
				const socialization = getLegacyValues('3.4.', 'socialization')
				const classTitleRow = savedRows.find(item => String(item?.[0] || '').startsWith('* Lớp phấn đấu'))
				const attendanceTargetRow = savedRows.find(item => String(item?.[0] || '').startsWith('1.1.'))
				const attendanceSolutionRow = savedRows.find(item => String(item?.[0] || '').startsWith('1.2.'))
				return {
					advantages: saved.advantages || '',
					difficulties: saved.difficulties || '',
					attendanceTarget: saved.attendanceTarget || attendanceTargetRow?.[1] || attendance.target,
					attendanceSolution: saved.attendanceSolution || attendanceSolutionRow?.[2] || attendance.solution,
					qualitySolution: saved.qualitySolution || quality.solution,
					academicSolution: saved.academicSolution || academic.solution,
					handwritingTarget: saved.handwritingTarget || handwriting.target,
					handwritingSolution: saved.handwritingSolution || handwriting.solution,
					extracurricularTarget: saved.extracurricularTarget || extracurricular.target,
					extracurricularSolution: saved.extracurricularSolution || extracurricular.solution,
					classroomTarget: saved.classroomTarget || classroom.target,
					classroomSolution: saved.classroomSolution || classroom.solution,
					laborTarget: saved.laborTarget || labor.target,
					laborSolution: saved.laborSolution || labor.solution,
					socializationTarget: saved.socializationTarget || socialization.target,
					socializationSolution: saved.socializationSolution || socialization.solution,
					classTitle: saved.classTitle || classTitleRow?.[1] || ''
				}
			},
			buildSituationRows(saved) {
				if (Array.isArray(saved.sectionI)) return saved.sectionI.map(row => row.slice())
				const periods = ['Đầu năm', 'Giữa HKI', 'Cuối HKI', 'Đầu HKII', 'Giữa HKII', 'Cuối năm']
				const keys = ['total', 'female', 'ethnic', 'repeater', 'special', 'wounded', 'martyr', 'poor', 'nearPoor', 'official', 'note']
				return periods.map((period, index) => {
					const source = saved.statistics?.[index] || {}
					return [period, ...keys.map(key => source[key] || '')]
				})
			},
			buildContentRows(saved) {
				const sections = [
					['classroom', '3.2. Trang trí lớp học, giữ gìn và bảo quản CSVC của lớp'],
					['labor', '3.3. Công tác lao động, xây dựng trường lớp xanh - sạch - đẹp'],
					['socialization', '3.4. Công tác xã hội hóa giáo dục']
				]
				const savedRows = Array.isArray(saved.sectionII) ? saved.sectionII : []
				const findSavedRow = prefix => savedRows.find(row => String(row?.[0] || '').startsWith(prefix))
				const getSavedValues = (key, title) => {
					const row = findSavedRow(title)
					return [
						row?.[1] || saved.sections?.[key]?.target || '',
						row?.[2] || saved.sections?.[key]?.solution || ''
					]
				}
				const rows = []
				rows.push(...sections.map(([key, title]) => {
					const [target, solution] = getSavedValues(key, title)
					return [title, target, solution]
				}))
				rows.push(['* Lớp phấn đấu đạt danh hiệu', saved.classTitle || '', ''])
				return rows
			},
			scrollToCard(card) {
				this.activeCardKey = card.key
				const container = this.$refs.scrollContainer
				// Chỉ tìm trong vùng content có scrollbar; $el của component Vuetify
				// không đảm bảo là DOM element nên không gọi querySelector trực tiếp trên đó.
				const target = container?.querySelector?.(`#${card.domId}`)
				if (!container || !target) return

				const top = target.getBoundingClientRect().top
					- container.getBoundingClientRect().top
					+ container.scrollTop
				container.scrollTo({ top, behavior: 'smooth' })
			},
			destroySheet(key) {
				const instance = this.sheetInstances[key]
				if (!instance) return
				try {
					const sheet = Array.isArray(instance) ? instance[0] : instance
					if (sheet && typeof sheet.destroy === 'function') sheet.destroy()
				} catch (error) {}
				delete this.sheetInstances[key]
			},
			destroyAllSheets() {
				Object.keys(this.sheetInstances).forEach(key => this.destroySheet(key))
			},
			initSheet(card) {
				this.$nextTick(() => {
					let container = this.$refs[card.refName]
					if (Array.isArray(container)) container = container[0]
					if (!container || typeof jspreadsheet !== 'function') return
					this.destroySheet(card.key)
					container.innerHTML = ''
					// Dùng chiều cao tự nhiên của từng bảng; vùng content bên ngoài vẫn
					// chịu trách nhiệm cuộn khi toàn bộ kế hoạch dài hơn viewport.
					const tableHeight = card.height || 'auto'
					this.sheetInstances[card.key] = soGvcnJspreadsheet.create(container, {
						worksheets: [{
							data: card.rows,
							columns: card.columns,
							nestedHeaders: card.nestedHeaders,
							...(card.freezeColumns ? { freezeColumns: card.freezeColumns } : {}),
							rowResize: true,
							columnDrag: false,
							tableWidth: '100%',
							tableOverflow: true,
							tableHeight,
							lazyLoading: false,
							wordWrap: true,
							allowInsertColumn: false,
							allowInsertRow: false,
							showHeader: true
						}],
						contextMenu: () => false,
						onchange: worksheet => {
							card.rows = worksheet.getData()
						}
					})
				})
			},
			initAllSheets() {
				if (this.selectedLopID === '__ALL__') {
					this.destroyAllSheets()
					return
				}
				this.planCards.filter(card => !card.textOnly).forEach(card => this.initSheet(card))
			},
			toNullableNumber(value) {
				if (value === '' || value === null || value === undefined) return null
				const number = Number(value)
				return Number.isFinite(number) ? number : null
			},
			throwTargetValidationError(message) {
				if (window.Vue && Vue.$toast) {
					Vue.$toast.error(message, { position: 'top' })
				} else if (window.showMessage) {
					showMessage({ title: message })
				} else {
					alert(message)
				}
				throw new Error(message)
			},
			validateSubjectTargetRows(rows, subjects, ratingLabels) {
				subjects.forEach((subject, subjectIndex) => {
					const subjectName = subject.TenMonHoc_HienThi || subject.MonHocName || subject.TenMonHoc || `Môn học ${subject.MonHocID}`
					ratingLabels.forEach((ratingLabel, ratingIndex) => {
						const percentage = this.toNullableNumber(rows?.[ratingIndex]?.[1 + subjectIndex])
						if (percentage !== null && (percentage < 0 || percentage > 100)) {
							this.throwTargetValidationError(`Tỉ lệ của "${subjectName}" - mức "${ratingLabel}" phải nằm trong khoảng từ 0 đến 100.`)
						}
					})
				})
			},
			buildNormalizedSubjectTargets(rows, subjects, ratingFields) {
				const lopID = String(this.selectedClass?.LopID || this.selectedLopID || '').trim()
				return subjects.map((subject, subjectIndex) => {
					const target = {
						LopID: lopID || null,
						MonHocID: subject.MonHocID
					}
					ratingFields.forEach((field, ratingIndex) => {
						target[`${field}_SoLuong`] = null
						target[`${field}_TiLe`] = this.toNullableNumber(rows?.[ratingIndex]?.[1 + subjectIndex])
					})
					return target
				})
			},
			buildNormalizedClassStatistics(rows) {
				const lopID = String(this.selectedClass?.LopID || this.selectedLopID || '').trim()
				const fields = [
					'TongSo', 'Nu', 'DanToc', 'LuuBan', 'CanQuanTam', 'ConThuongBinh',
					'ConLietSi', 'HoNgheo', 'HoCanNgheo', 'CBCCVC'
				]
				const periodCodes = ['DauNam', 'GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2', 'CuoiNam']
				return (rows || []).map((row, index) => {
					const statistic = {
						LopID: lopID || null,
						ThoiDiem: row?.[0] || '',
						ThoiDiemCode: periodCodes[index] || `Moc${index + 1}`,
						GhiChu: row?.[11] || ''
					}
					fields.forEach((field, fieldIndex) => {
						statistic[field] = this.toNullableNumber(row?.[fieldIndex + 1])
					})
					return statistic
				})
			},
			getPlanData() {
				const result = this.planCards.reduce((data, card) => {
					if (card.textOnly) return data
					const instance = this.sheetInstances[card.key]
					const sheet = Array.isArray(instance) ? instance[0] : instance
					data[card.key] = sheet && typeof sheet.getData === 'function'
						? sheet.getData()
						: card.rows
					return data
				}, {})
				result.version = 3
				result.type = 'c1-annual-plan'
				result.sectionI = result['dac-diem']
				result.sectionII = result['noi-dung'] || []
				result.classStatistics = this.buildNormalizedClassStatistics(result.sectionI)
				result.qualityCompetencyTargets = result['pham-chat-nang-luc']
				result.academicTargets = result['mon-hoc-hoat-dong']
				this.validateSubjectTargetRows(
					result.qualityCompetencyTargets,
					this.qualityCompetencySubjects,
					['Tốt', 'Cần cố gắng']
				)
				this.validateSubjectTargetRows(
					result.academicTargets,
					this.academicSubjects,
					['Hoàn thành tốt', 'Chưa hoàn thành']
				)
				result.subjectTargets = [
					...this.buildNormalizedSubjectTargets(
						result.qualityCompetencyTargets,
						this.qualityCompetencySubjects,
						['Tot', 'CanCoGang']
					),
					...this.buildNormalizedSubjectTargets(
						result.academicTargets,
						this.academicSubjects,
						['HoanThanhTot', 'ChuaHoanThanh']
					)
				]
				delete result['dac-diem']
				delete result['noi-dung']
				delete result['pham-chat-nang-luc']
				delete result['mon-hoc-hoat-dong']
				Object.assign(result, this.planText)
				return result
			}
		}
	}
</script>