<template>
	<Global class="uc-log-diem-main d-flex flex-column">
		<v-card class="flex-shrink-0 elevation-1">
			<v-card-title class="d-flex align-center flex-wrap ga-2 py-2">
				<v-icon color="primary" class="mr-1">mdi-history</v-icon>
				<span class="font-weight-bold text-subtitle-1 text-md-h6 text-primary">Lịch sử nhập điểm</span>
				<v-chip v-if="nienKhoa" color="primary" variant="tonal" size="small">Niên khóa {{ nienKhoa }}</v-chip>
				<v-spacer />
				<span v-if="hasSearched" class="text-caption text-medium-emphasis">{{ items.length }} lượt ghi nhận</span>
			</v-card-title>
			<v-divider />

			<!-- Bộ lọc nằm trong component để layout không bị FUI controls tự chia cột theo module.json. -->
			<v-card-text class="py-2">
				<!-- Gom bộ lọc chính, khoảng ngày và thao tác tra cứu trên một hàng; điều kiện ít dùng vẫn ở bộ lọc nâng cao. -->
				<v-row dense align="center">
					<v-col cols="12" sm="6" md="2">
						<v-select
							v-model="capID"
							:items="DSCap"
							item-title="TenCap"
							item-value="CapID"
							label="Cấp học"
							density="compact"
							variant="outlined"
							hide-details
							:loading="isFilterLoading"
							@update:model-value="onCapChange"
						/>
					</v-col>
					<v-col cols="12" sm="6" md="3">
						<v-autocomplete
							v-model="scopeItem"
							:items="scopeOptions"
							item-title="displayTitle"
							item-value="scopeKey"
							:return-object="true"
							label="Khối / lớp"
							placeholder="Tất cả khối, lớp"
							density="compact"
							variant="outlined"
							hide-details
							clearable
							:disabled="!nienKhoa"
							:loading="isFilterLoading"
							no-data-text="Chưa có dữ liệu khối/lớp"
							@update:model-value="onScopeChange"
						/>
					</v-col>
					<v-col cols="12" md="auto" class="d-flex align-center flex-grow-0">
						<!-- Bộ chọn khoảng ngày trả về from/to để giới hạn truy vấn lịch sử. -->
						<uc-date-range-picker v-model="dateRange" :NienKhoa="nienKhoa" />
					</v-col>
					<v-col cols="12" sm="6" md="2" class="d-flex justify-end">
						<v-btn
							variant="tonal"
							color="primary"
							block
							prepend-icon="mdi-tune-variant"
							@click="showAdvancedFilters = !showAdvancedFilters"
						>
							Bộ lọc nâng cao
							<v-badge v-if="advancedFilterCount" :content="advancedFilterCount" inline color="primary" class="ml-2" />
						</v-btn>
					</v-col>
					<v-col cols="12" md="auto" class="d-flex align-center flex-grow-0">
						<v-btn color="primary" variant="flat" :loading="loading" prepend-icon="mdi-magnify" @click="searchLog">
							Tra cứu
						</v-btn>
					</v-col>
				</v-row>

				<v-expand-transition>
					<div v-if="showAdvancedFilters" class="uc-log-diem-main__advanced-filter mt-2">
						<v-row dense align="center">
							<v-col cols="12" sm="6" md="3">
								<v-select
									v-model="monHocItem"
									:items="DSMonHoc"
									item-title="TenMonHoc_HienThi"
									item-value="MonHocID"
									:return-object="true"
									label="Môn học"
									density="compact"
									variant="outlined"
									hide-details
									clearable
									:disabled="!scopeItem"
									:loading="isFilterLoading"
									@update:model-value="onMonHocChange"
								/>
							</v-col>
							<v-col cols="12" sm="6" md="3">
								<v-select
									v-model="maNhomCotDiemItem"
									:items="DSNhomCotDiem"
									item-title="TenNhomCotDiem_VI"
									item-value="MaNhomCotDiem"
									:return-object="true"
									label="Nhóm cột điểm"
									density="compact"
									variant="outlined"
									hide-details
									clearable
									:disabled="!monHocItem"
									@update:model-value="onNhomCotDiemChange"
								/>
							</v-col>
						</v-row>
					</div>
				</v-expand-transition>
				<v-alert v-if="errorMessage" type="error" variant="tonal" density="compact" class="mt-2 mb-0">{{ errorMessage }}</v-alert>
			</v-card-text>
		</v-card>

		<div class="flex-grow-1 overflow-hidden mt-2">
			<!-- Component bảng chỉ nhận dữ liệu đã lọc; toàn bộ state và API orchestration ở layout này. -->
			<uc-log-diem-table :items="items" :loading="loading" :has-searched="hasSearched" />
		</div>
	</Global>
</template>

<script>
	export default {
		data() {
			const query = typeof window !== 'undefined' ? new URLSearchParams(window.location.search || '') : null
			const queryValue = (...keys) => {
				for (const key of keys) {
					const value = query?.get(key)
					if (value !== null && value !== '') return value
				}
				return null
			}
			const queryNumber = (...keys) => Number(queryValue(...keys)) || null
			const defaultYear = Number(vueData.NienKhoa) || new Date().getFullYear()
			return {
				nienKhoa: queryNumber('nienkhoa', 'NienKhoa', 'namhoc', 'NamHoc') || defaultYear,
				hocKi: Number(vueData.HocKi) || 1,
				capID: queryNumber('capid', 'CapID') || Number(vueData.CapID) || 2,
				khoiItem: null,
				lopItem: null,
				scopeItem: null,
				monHocItem: null,
				maNhomCotDiemItem: null,
				dateRange: { from: queryValue('from', 'FromDate', 'tungay'), to: queryValue('to', 'ToDate', 'denngay') },
				showAdvancedFilters: Boolean(queryValue('monhocid', 'MonHocID', 'nhomcotdiem', 'MaNhomCotDiem')),
				isRestoringFromUrl: false,
				isReadyForUrlSync: false,
				urlSelection: {
					KhoiID: queryNumber('khoiid', 'KhoiID'),
					LopID: queryValue('lopid', 'LopID'),
					MonHocID: queryNumber('monhocid', 'MonHocID'),
					MaNhomCotDiem: queryValue('nhomcotdiem', 'MaNhomCotDiem')
				},
				DSCap: [
					{ CapID: 1, TenCap: 'Cấp 1' },
					{ CapID: 2, TenCap: 'Cấp 2' },
					{ CapID: 3, TenCap: 'Cấp 3' }
				],
				DSKhoi: [],
				DSLop: [],
				DSAllLop: [],
				DSMonHoc: [],
				DSNhomCotDiem: [],
				items: [],
				loading: false,
				isFilterLoading: false,
				hasSearched: false,
				errorMessage: ''
			}
		},
		computed: {
			advancedFilterCount() {
				return [this.monHocItem, this.maNhomCotDiemItem].filter(Boolean).length
			},
			scopeOptions() {
				const gradeOptions = this.DSKhoi.map(item => ({
					...item,
					scopeType: 'khoi',
					scopeKey: 'khoi|' + item.KhoiID,
					displayTitle: String(item.TenKhoiHoc || 'Khối') + ' · Tất cả lớp'
				}))
				const classOptions = this.DSAllLop.map(item => {
					const grade = this.DSKhoi.find(khoi => Number(khoi.KhoiID) === Number(item.KhoiID))
					return {
						...item,
						scopeType: 'lop',
						scopeKey: 'lop|' + (item.LopIDs || [item.LopID]).join(','),
						displayTitle: String(item.TenLop || 'Lớp') + ' · ' + String(grade?.TenKhoiHoc || 'Khối')
					}
				})
				return [...gradeOptions, ...classOptions]
			}
		},
		mounted() {
			// Nạp danh sách điều kiện lọc khi mở trang; truy vấn lịch sử lớn chỉ chạy khi người dùng bấm Tra cứu.
			this.initializeLookups()
		},
		watch: {
			// Date picker phát sinh from/to sau khi người dùng chọn; lưu ngay vào URL để F5 vẫn giữ khoảng ngày.
			dateRange: {
				deep: true,
				handler() {
					this.syncFiltersToUrl()
				}
			}
		},
		methods: {
			normalizeRows(raw) {
			if (raw && Array.isArray(raw.data)) return this.normalizeRows(raw.data)
			if (!Array.isArray(raw)) return []
			if (raw.length && Array.isArray(raw[0])) return this.normalizeRows(raw[0])
			return raw.filter(row => row && typeof row === 'object')
		},
			getUrlQueryValue(...keys) {
				if (typeof window === 'undefined') return null
				const params = new URLSearchParams(window.location.search || '')
				for (const key of keys) {
					const value = params.get(key)
					if (value !== null && value !== '') return value
				}
				return null
			},
			async restoreSelectionFromUrl() {
				const requested = this.urlSelection || {}
				if (requested.KhoiID) {
					const khoi = this.DSKhoi.find(item => Number(item.KhoiID) === Number(requested.KhoiID))
					if (khoi) {
						this.khoiItem = khoi
						this.lopItem = null
						this.DSLop = this.DSAllLop.filter(item => Number(item.KhoiID) === Number(khoi.KhoiID))
						this.scopeItem = this.scopeOptions.find(item => item.scopeType === 'khoi' && Number(item.KhoiID) === Number(khoi.KhoiID)) || null
					}
				}

				if (requested.LopID && this.DSAllLop.length) {
					const requestedIds = String(requested.LopID).split(',').map(id => id.trim()).filter(Boolean)
					const lop = this.DSAllLop.find(item => {
						const itemIds = (item.LopIDs || [item.LopID]).map(id => String(id))
						return requestedIds.every(id => itemIds.includes(id))
					})
					if (lop) {
						this.khoiItem = this.DSKhoi.find(item => Number(item.KhoiID) === Number(lop.KhoiID)) || null
						this.lopItem = lop
						this.DSLop = this.DSAllLop.filter(item => Number(item.KhoiID) === Number(lop.KhoiID))
						this.scopeItem = this.scopeOptions.find(item => item.scopeType === 'lop' && item.scopeKey === 'lop|' + (lop.LopIDs || [lop.LopID]).join(',')) || null
						await this.loadMonHoc()
					}
				}

				// URL chỉ có KhoiID nghĩa là xem toàn bộ lớp trong khối; vẫn phải nạp danh sách môn để bộ lọc nâng cao hoạt động.
				if (requested.KhoiID && !requested.LopID) await this.loadMonHoc()

				if (requested.MonHocID && this.DSMonHoc.length) {
					const monHoc = this.DSMonHoc.find(item => Number(item.MonHocID) === Number(requested.MonHocID))
					if (monHoc) {
						this.monHocItem = monHoc
						await this.loadNhomCotDiem()
					}
				}

				if (requested.MaNhomCotDiem && this.DSNhomCotDiem.length) {
					this.maNhomCotDiemItem = this.DSNhomCotDiem.find(item => String(item.MaNhomCotDiem) === String(requested.MaNhomCotDiem)) || null
				}
			},
			syncFiltersToUrl() {
				if (typeof window === 'undefined' || !window.history?.replaceState || !this.isReadyForUrlSync || this.isRestoringFromUrl) return
				const url = new URL(window.location.href)
				const aliases = ['nienkhoa', 'NienKhoa', 'namhoc', 'NamHoc', 'capid', 'CapID', 'khoiid', 'KhoiID', 'lopid', 'LopID', 'monhocid', 'MonHocID', 'nhomcotdiem', 'MaNhomCotDiem', 'from', 'FromDate', 'tungay', 'to', 'ToDate', 'denngay', 'autoload']
				aliases.forEach(key => url.searchParams.delete(key))

				const setQuery = (key, value) => {
					if (value !== undefined && value !== null && String(value).trim() !== '') url.searchParams.set(key, String(value))
				}
				setQuery('nienkhoa', this.nienKhoa)
				setQuery('capid', this.capID)
				setQuery('khoiid', this.khoiItem?.KhoiID)
				setQuery('lopid', this.getClassIDs())
				setQuery('monhocid', this.monHocItem?.MonHocID)
				setQuery('nhomcotdiem', this.maNhomCotDiemItem?.MaNhomCotDiem)
				setQuery('from', this.dateRange?.from)
				setQuery('to', this.dateRange?.to)
				window.history.replaceState(window.history.state, document.title, `${url.pathname}${url.search}${url.hash}`)
			},
			async initializeLookups() {
				this.isFilterLoading = true
				this.isRestoringFromUrl = true
				try {
					await this.loadNienKhoa()
					await this.loadKhoi()
					// URL khôi phục điều kiện lọc nhưng không kích hoạt truy vấn log tự động khi tải trang.
					await this.restoreSelectionFromUrl()
					this.isRestoringFromUrl = false
					this.isReadyForUrlSync = true
				} catch (error) {
					console.error('Lỗi khởi tạo bộ lọc log điểm:', error)
					this.errorMessage = 'Không tải được danh sách điều kiện lọc.'
				} finally {
					this.isRestoringFromUrl = false
					this.isReadyForUrlSync = true
					this.isFilterLoading = false
				}
			},
			async loadNienKhoa() {
				const rows = this.normalizeRows(await fetchPromise('lms/NienKhoa_Get', {}, { cache: false }))
				const active = rows.find(item => item.IsActive) || rows[0]
				if (active) {
					const matchingYears = rows.filter(item => String(item.NienKhoa) === String(this.nienKhoa))
					const selected = matchingYears.find(item => item.IsActive) || matchingYears[0] || active
					if (!this.nienKhoa) this.nienKhoa = selected.NienKhoa
					this.hocKi = Number(selected.HocKi) || this.hocKi || 1
				}
			},
			async loadKhoi() {
				this.DSKhoi = []
				this.resetAfterKhoi()
				if (!this.nienKhoa) return []
				const rows = this.normalizeRows(await fetchPromise('lms/KhoiHocByCapHoc_Get', {
					CapID: this.capID,
					NienKhoa: this.nienKhoa,
					HocKi: this.hocKi
				}, { cache: false }))
				this.DSKhoi = rows
				// Nạp lớp của toàn bộ khối một lần để autocomplete Khối/Lớp cho phép chọn trực tiếp bất kỳ lớp nào.
				const classResponses = await Promise.all(rows.map(khoi => fetchPromise('lms/Lop_Get_ByKhoiID', {
					NienKhoa: this.nienKhoa,
					KhoiID: khoi.KhoiID,
					HocKi: this.hocKi
				}, { cache: false })))
				this.DSAllLop = this.buildClassOptions(classResponses.flatMap(raw => this.normalizeRows(raw)))
				return rows
			},
			resetAfterKhoi() {
				this.khoiItem = null
				this.lopItem = null
				this.scopeItem = null
				this.monHocItem = null
				this.maNhomCotDiemItem = null
				this.DSLop = []
				this.DSAllLop = []
				this.DSMonHoc = []
				this.DSNhomCotDiem = []
			},
			resetAfterLop() {
				this.lopItem = null
				this.monHocItem = null
				this.maNhomCotDiemItem = null
				this.DSMonHoc = []
				this.DSNhomCotDiem = []
			},
			resetAfterScope() {
				this.monHocItem = null
				this.maNhomCotDiemItem = null
				this.DSMonHoc = []
				this.DSNhomCotDiem = []
			},
			buildClassOptions(rows) {
				const map = new Map()
				const isCap3 = Number(this.capID) === 3
				;(Array.isArray(rows) ? rows : []).forEach(row => {
					if (!row || row.LopID === undefined || row.LopID === null) return
					// tblNhom có thể được trả chung với tblLop; nhóm DI không phải lớp để truy vết log.
					if (row.IsNhom === true || Number(row.IsNhom) === 1) return
					const lopID = String(row.LopID).trim()
					const tenLop = String(row.TenLop || lopID).trim()
					const isLopToHop = isCap3 && (row.IsLopToHop === true || Number(row.IsLopToHop) === 1)
					const tenLopGoc = isLopToHop ? (tenLop.replace(/[0-9]+$/, '') || tenLop) : tenLop
					const key = isLopToHop ? String(row.KhoiID || '') + '|' + tenLopGoc : lopID
					const item = map.get(key) || {
						LopID: row.LopID,
						LopIDs: [],
						TenLop: tenLopGoc,
						TenLopThanhVien: [],
						KhoiID: row.KhoiID,
						GVCN: row.GVCN,
						IsLopToHop: isLopToHop
					}
					if (!item.LopIDs.some(id => String(id) === lopID)) item.LopIDs.push(row.LopID)
					if (!item.TenLopThanhVien.includes(tenLop)) item.TenLopThanhVien.push(tenLop)
					map.set(key, item)
				})
				return [...map.values()].map(item => {
					const members = [...item.TenLopThanhVien].sort((a, b) => String(a).localeCompare(String(b), 'vi', { numeric: true }))
					return {
						...item,
						TenLopThanhVien: members,
						TenLop: members.length > 1 ? item.TenLop + ' (' + members.join(', ') + ')' : item.TenLop
					}
				}).sort((a, b) => String(a.TenLop).localeCompare(String(b.TenLop), 'vi', { numeric: true }))
			},
			async loadLop() {
				this.DSLop = []
				this.resetAfterLop()
				if (!this.khoiItem?.KhoiID) return []
				const raw = await fetchPromise('lms/Lop_Get_ByKhoiID', {
					NienKhoa: this.nienKhoa,
					KhoiID: this.khoiItem.KhoiID,
					HocKi: this.hocKi
				}, { cache: false })
				this.DSLop = this.buildClassOptions(this.normalizeRows(raw))
				return this.DSLop
			},
			async loadMonHoc() {
				this.DSMonHoc = []
				this.DSNhomCotDiem = []
				if (!this.scopeItem || !this.khoiItem?.KhoiID) return []

				// API hiện có nhận LopID, nên khi chọn cả khối phải hỏi từng lớp rồi gộp môn trùng theo MonHocID.
				const classOptions = this.lopItem
					? [this.lopItem]
					: this.DSAllLop.filter(item => Number(item.KhoiID) === Number(this.khoiItem.KhoiID))
				const classIds = [...new Set(classOptions
					.flatMap(item => item.LopIDs || [item.LopID])
					.filter(id => id !== undefined && id !== null && String(id).trim() !== '')
					.map(id => String(id).trim()))]
				if (!classIds.length) return []

				const responses = await Promise.all(classIds.map(lopID => fetchPromise('lms/MonHoc_Get_ByLopID', {
					NienKhoa: this.nienKhoa,
					LopID: lopID,
					HocKi: this.hocKi
				}, { cache: false })))
				const subjectMap = new Map()
				responses.flatMap(raw => this.normalizeRows(raw)).forEach(row => {
					const key = row.MonHocID ?? row.MaMonHoc ?? row.TenMonHoc_HienThi
					if (key === undefined || key === null || String(key).trim() === '') return
					if (!subjectMap.has(String(key))) subjectMap.set(String(key), row)
				})
				this.DSMonHoc = [...subjectMap.values()].sort((a, b) => {
					const orderA = Number(a.ThuTuMonHoc)
					const orderB = Number(b.ThuTuMonHoc)
					if (Number.isFinite(orderA) && Number.isFinite(orderB) && orderA !== orderB) return orderA - orderB
					return String(a.TenMonHoc_HienThi || '').localeCompare(String(b.TenMonHoc_HienThi || ''), 'vi', { sensitivity: 'base' })
				})
				return this.DSMonHoc
			},
			async loadNhomCotDiem() {
				this.DSNhomCotDiem = []
				if (!this.monHocItem?.TemplateBangDiemID) return []
				const raw = await fetchPromise('lms/NhomCauTrucDiem_Get_ByTemplateBangDiemID', {
					TemplateBangDiemID: this.monHocItem.TemplateBangDiemID
				}, { cache: false })
				this.DSNhomCotDiem = this.normalizeRows(raw)
				return this.DSNhomCotDiem
			},
			async onCapChange() {
				try {
					await this.loadKhoi()
					this.syncFiltersToUrl()
				} catch (error) {
					this.handleLookupError(error)
				}
			},
			async onScopeChange(scope) {
				try {
					if (!scope) {
						this.khoiItem = null
						this.lopItem = null
						this.DSLop = []
						this.resetAfterScope()
						this.syncFiltersToUrl()
						return
					}

					this.khoiItem = this.DSKhoi.find(item => Number(item.KhoiID) === Number(scope.KhoiID)) || null
					this.DSLop = this.DSAllLop.filter(item => Number(item.KhoiID) === Number(scope.KhoiID))
					this.resetAfterScope()

					if (scope.scopeType === 'lop') {
						this.lopItem = this.DSLop.find(item => {
							const left = (item.LopIDs || [item.LopID]).map(id => String(id)).join(',')
							const right = (scope.LopIDs || [scope.LopID]).map(id => String(id)).join(',')
							return left === right
						}) || null
					}
					await this.loadMonHoc()
					this.syncFiltersToUrl()
				} catch (error) {
					this.handleLookupError(error)
				}
			},
			async onKhoiChange() {
				try {
					await this.loadLop()
					this.syncFiltersToUrl()
				} catch (error) {
					this.handleLookupError(error)
				}
			},
			async onLopChange() {
				try {
					await this.loadMonHoc()
					this.syncFiltersToUrl()
				} catch (error) {
					this.handleLookupError(error)
				}
			},
			async onMonHocChange() {
				try {
					await this.loadNhomCotDiem()
					this.syncFiltersToUrl()
				} catch (error) {
					this.handleLookupError(error)
				}
			},
			onNhomCotDiemChange() {
				this.syncFiltersToUrl()
			},
			handleLookupError(error) {
				console.error('Lỗi tải bộ lọc log điểm:', error)
				this.errorMessage = 'Không tải được danh sách điều kiện lọc.'
			},
			getClassIDs() {
				if (!this.lopItem) return null
				const ids = (this.lopItem.LopIDs || [this.lopItem.LopID]).filter(id => id !== undefined && id !== null && String(id).trim() !== '')
				return [...new Set(ids.map(id => String(id).trim()))].join(',') || null
			},
			async searchLog() {
				// Ghi lại điều kiện trước khi gọi API để URL luôn là nguồn khôi phục khi người dùng F5.
				this.syncFiltersToUrl()
				this.loading = true
				this.hasSearched = true
				this.errorMessage = ''
				try {
					const raw = await fetchPromise('lms/Log_Diem_TongHop', {
						NienKhoa: this.nienKhoa,
						CapID: this.capID,
						// Giá trị null/chuỗi rỗng là filter mở: SP sẽ không thêm điều kiện tương ứng.
						KhoiID: this.khoiItem?.KhoiID || null,
						LopID: this.getClassIDs() || null,
						MonHocID: this.monHocItem?.MonHocID || null,
						MaNhomCotDiem: this.maNhomCotDiemItem?.MaNhomCotDiem || null,
						HocSinhKeyword: null,
						NhapDiemUser: null,
						FromDate: this.dateRange?.from || null,
						ToDate: this.dateRange?.to || null
					}, { cache: false })
					this.items = this.normalizeRows(raw)
				} catch (error) {
					console.error('Lỗi tải lịch sử nhập điểm:', error)
					this.items = []
					this.errorMessage = 'Không tải được lịch sử nhập điểm.'
				} finally {
					this.loading = false
				}
			}
		}
	}
</script>

<style scoped>
.uc-log-diem-main__advanced-filter {
	padding: 8px 10px 2px;
	border: 1px dashed rgba(46, 125, 50, 0.28);
	border-radius: 6px;
	background: rgba(46, 125, 50, 0.025);
}
</style>