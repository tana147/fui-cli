<template>
	<Global class="uc-log-hoc-lieu-so d-flex flex-column">
		<template #header>
			<v-card class="elevation-1 mb-2">
				<v-card-title class="d-flex align-center flex-wrap ga-2 py-2">
					<v-icon color="primary" class="mr-1">mdi-history</v-icon>
					<span class="font-weight-bold text-subtitle-1 text-md-h6 text-primary">Lịch sử thay đổi nội dung học liệu số</span>
				</v-card-title>
				<v-divider />
				<!-- Dùng bộ chọn khoảng ngày chung của LMS; nhóm filter/action có gap 12px và tự xuống hàng trên màn hình hẹp. -->
				<v-card-text class="py-2">
					<v-row dense align="center" class="ga-3">
						<v-col cols="12" md="auto">
							<uc-date-range-picker v-model="filters.dateRange" />
						</v-col>
						<v-col cols="12" md="4">
							<v-text-field
								v-model="filters.keyword"
								label="Từ khóa"
								placeholder="Nội dung, học liệu hoặc người thao tác"
								prepend-inner-icon="mdi-magnify"
								variant="outlined"
								density="compact"
								hide-details
								clearable
								@keyup.enter="loadLogs"
							/>
						</v-col>
						<v-col cols="12" md="auto" class="d-flex align-center flex-wrap ga-3">
							<v-btn color="primary" variant="flat" :loading="loading" @click="loadLogs">
								<v-icon start>mdi-magnify</v-icon>TÌM KIẾM
							</v-btn>
							<v-btn variant="outlined" color="grey-darken-1" :disabled="loading" @click="resetFilters">
								<v-icon start>mdi-filter-remove</v-icon>XÓA BỘ LỌC
							</v-btn>
						</v-col>
					</v-row>
					<v-alert v-if="errorMessage" type="error" variant="tonal" density="compact" class="mt-2 mb-0">
						{{ errorMessage }}
					</v-alert>
				</v-card-text>
			</v-card>
		</template>

		<div class="pa-2">
			<v-card class="elevation-1">
				<v-card-title class="d-flex align-center py-2">
					<span class="font-weight-medium text-primary">Nhật ký thay đổi nội dung</span>
					<v-spacer />
					<span class="text-caption text-medium-emphasis">{{ items.length }} bản ghi</span>
				</v-card-title>
				<v-divider />
				<!-- Giữ tiêu đề bảng cố định và để các dòng cuộn trong vùng cao còn lại của viewport. -->
				<v-data-table
					:headers="headers"
					:items="items"
					:loading="loading"
					fixed-header
					height="calc(100vh - 250px)"
					:items-per-page="50"
					:items-per-page-options="[25, 50, 100]"
					item-value="LogID"
					density="compact"
					hover
					no-data-text="Chưa có dữ liệu"
				>
					<template #item.AuditTime="{ item }">
						{{ formatDateTime((item.raw || item).AuditTime) }}
					</template>
					<template #item.ActionLabel="{ item }">
						<v-chip :color="formatActionColor(item.raw || item)" size="small" variant="tonal">
							{{ formatActionLabel(item.raw || item) }}
						</v-chip>
					</template>
					<template #item.NguoiThucHien="{ item }">
						<div class="d-flex flex-column">
							<span>{{ formatAuditActorName(item.raw || item) }}</span>
							<span v-if="formatAuditActorCode(item.raw || item)" class="text-caption text-medium-emphasis">
								Mã: {{ formatAuditActorCode(item.raw || item) }}
							</span>
						</div>
					</template>
					<template #item.actions="{ item }">
						<v-btn icon variant="text" color="primary" aria-label="Xem chi tiết log" @click="openDetail(item.raw || item)">
							<v-icon>mdi-eye</v-icon>
						</v-btn>
					</template>
				</v-data-table>
			</v-card>
		</div>

		<!-- Chuyển snapshot audit thành thay đổi theo tên trường dễ hiểu; HTML chỉ được rút thành văn bản và luôn render dạng text an toàn. -->
		<v-dialog v-model="detailDialog" max-width="900" scrollable>
			<v-card class="pa-0">
				<v-toolbar density="compact" flat>
					<v-toolbar-title>Chi tiết lịch sử học liệu số</v-toolbar-title>
					<v-spacer />
					<v-btn icon variant="text" aria-label="Đóng" @click="closeDetail">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-toolbar>
				<v-divider />
				<v-card-text class="px-4 py-3">
					<v-progress-linear v-if="detailLoading" indeterminate color="primary" class="mb-3" />
					<v-alert v-if="detailError" type="error" variant="tonal" density="compact" class="mb-3">
						{{ detailError }}
					</v-alert>
					<div v-if="detailItem">
						<v-row dense>
							<v-col cols="12" sm="6"><strong>Thời gian:</strong> {{ formatDateTime(detailItem.AuditTime) }}</v-col>
							<v-col cols="12" sm="6">
								<strong>Thao tác:</strong>
								<v-chip :color="formatActionColor(detailItem)" size="small" variant="tonal" class="ml-1">
									{{ formatActionLabel(detailItem) }}
								</v-chip>
							</v-col>
							<v-col cols="12" sm="6"><strong>Học liệu:</strong> {{ detailItem.TenHocLieu || '—' }}</v-col>
							<v-col cols="12" sm="6"><strong>Nội dung:</strong> {{ detailItem.TenNoiDung || '—' }}</v-col>
							<v-col cols="12" sm="6"><strong>Môn học:</strong> {{ detailItem.TenMonHoc || '—' }}</v-col>
							<v-col cols="12" sm="6">
								<strong>Người thực hiện:</strong> {{ formatAuditActorName(detailItem) }}
								<span v-if="formatAuditActorCode(detailItem)" class="text-medium-emphasis"> ({{ formatAuditActorCode(detailItem) }})</span>
							</v-col>
						</v-row>
						<v-divider class="my-3" />
						<div class="text-subtitle-2 font-weight-bold mb-2">Thông tin đã thay đổi</div>
						<v-alert v-if="!detailChanges.length" type="info" variant="tonal" density="compact">
							Không có thông tin nội dung thay đổi để hiển thị.
						</v-alert>
						<v-table v-else density="compact" class="w-100">
							<thead>
								<tr>
									<th>Thông tin</th>
									<th>Trước</th>
									<th>Sau</th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="change in detailChanges" :key="change.key">
									<td class="font-weight-medium text-no-wrap">{{ change.label }}</td>
									<td><div class="change-value">{{ change.before }}</div></td>
									<td><div class="change-value">{{ change.after }}</div></td>
								</tr>
							</tbody>
						</v-table>
					</div>
				</v-card-text>
			</v-card>
		</v-dialog>
	</Global>
</template>

<script>
	export default {
		data() {
		return {
			filters: { dateRange: { from: null, to: null }, keyword: '' },
			headers: [
				{ title: 'Thời gian', key: 'AuditTime', width: 180 },
				{ title: 'Thao tác', key: 'ActionLabel', width: 120 },
				{ title: 'Học liệu', key: 'TenHocLieu', minWidth: 180 },
				{ title: 'Nội dung', key: 'TenNoiDung', minWidth: 180 },
				{ title: 'Môn học', key: 'TenMonHoc', width: 150 },
				{ title: 'Người thực hiện', key: 'NguoiThucHien', minWidth: 220 },
				{ title: 'Chi tiết', key: 'actions', sortable: false, align: 'center', width: 90 }
			],
			items: [],
			loading: false,
			errorMessage: '',
			detailDialog: false,
			detailLoading: false,
			detailError: '',
			detailItem: null,
			listRequestVersion: 0,
			detailRequestVersion: 0
		}
	},
	computed: {
		// Chỉ đưa các trường nghiệp vụ đã đổi vào dialog; mã log, ID và timestamp nội bộ không cần người dùng diễn giải.
		detailChanges() {
			return this.buildReadableChanges(this.detailItem)
		}
	},
	mounted() {
		// Nạp danh sách mới nhất khi mở trang; bộ lọc ngày chỉ giới hạn khi người dùng chọn khoảng.
		this.loadLogs()
	},
	methods: {
		normalizeRows(raw) {
			// Chuẩn hóa cả array trực tiếp và resultset bọc trong data của fetchPromise trước khi bind vào bảng.
			if (raw && Array.isArray(raw.data)) return this.normalizeRows(raw.data)
			if (!Array.isArray(raw)) return []
			if (raw.length && Array.isArray(raw[0])) return this.normalizeRows(raw[0])
			return raw.filter(row => row && typeof row === 'object')
		},
		loadLogs() {
			const requestVersion = ++this.listRequestVersion
			this.loading = true
			this.errorMessage = ''
			const params = {
				TuNgay: this.filters.dateRange.from || null,
				DenNgay: this.filters.dateRange.to || null,
				Search: String(this.filters.keyword || '').trim()
			}

			// FunctionName của tAPI bỏ prefix spAPI_; cache tắt để các thao tác vừa ghi được đọc ngay.
			return fetchPromise('lms/FP_NoiDungHocLieu_Log_Select', params, { cache: false })
				.then(raw => {
					if (requestVersion !== this.listRequestVersion) return
					this.items = this.normalizeRows(raw)
				})
				.catch(error => {
					if (requestVersion !== this.listRequestVersion) return
					console.error('Lỗi tải lịch sử nội dung học liệu số:', error)
					this.items = []
					this.errorMessage = 'Không tải được lịch sử nội dung học liệu số.'
				})
				.then(() => {
					if (requestVersion === this.listRequestVersion) this.loading = false
				})
		},
		resetFilters() {
			this.filters = { dateRange: { from: null, to: null }, keyword: '' }
			this.loadLogs()
		},
		openDetail(row) {
			if (!row || row.LogID === undefined || row.LogID === null) return
			const requestVersion = ++this.detailRequestVersion
			this.detailItem = row
			this.detailError = ''
			this.detailDialog = true
			this.detailLoading = true

			// Lấy snapshot đầy đủ theo LogID; request version ngăn phản hồi cũ ghi đè khi đổi dòng nhanh.
			return fetchPromise('lms/FP_NoiDungHocLieu_Log_GetDetail', { LogID: row.LogID }, { cache: false })
				.then(raw => {
					if (requestVersion !== this.detailRequestVersion) return
					const rows = this.normalizeRows(raw)
					if (rows.length) this.detailItem = rows[0]
				})
				.catch(error => {
					if (requestVersion !== this.detailRequestVersion) return
					console.error('Lỗi tải chi tiết log học liệu số:', error)
					this.detailError = 'Không tải được dữ liệu chi tiết.'
				})
				.then(() => {
					if (requestVersion === this.detailRequestVersion) this.detailLoading = false
				})
		},
		closeDetail() {
			this.detailRequestVersion += 1
			this.detailDialog = false
			this.detailLoading = false
		},
		formatDateTime(value) {
			if (!value) return '—'
			const date = new Date(value)
			if (Number.isNaN(date.getTime())) return String(value)
			return date.toLocaleString('vi-VN', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' })
		},
		formatActionLabel(row) {
			if (!row) return 'Đã thay đổi'
			const label = String(row.ActionLabel || '').trim()
			const action = String(label || row.AuditAction || row.AuditEvent || '').toUpperCase()
			const labels = { I: 'Thêm mới', INSERT: 'Thêm mới', U: 'Cập nhật', UPDATE: 'Cập nhật', D: 'Xóa', SOFT_DELETE: 'Xóa', DELETE: 'Xóa' }
			return labels[action] || label || 'Đã thay đổi'
		},
		// Tách màu thao tác thành xanh lá, xanh dương và đỏ để thêm mới, cập nhật, xóa không bị nhầm nhau.
		formatActionColor(row) {
			const label = String(row && row.ActionLabel || '').trim().toUpperCase()
			const action = String(row && (row.AuditAction || row.AuditEvent) || '').toUpperCase()
			if (action === 'I' || action === 'INSERT' || label.indexOf('THÊM') >= 0) return 'success'
			if (action === 'D' || action === 'DELETE' || action === 'SOFT_DELETE' || label.indexOf('XÓA') >= 0) return 'error'
			if (action === 'U' || action === 'UPDATE' || label.indexOf('CẬP NHẬT') >= 0) return 'info'
			return 'default'
		},
		// Chỉ dùng họ tên đã được ghi trực tiếp trong audit log; không tra cứu chéo sang danh bạ khác.
		formatAuditActorName(row) {
			if (!row) return '—'
			const name = String(row.NguoiThucHienHoTen || row.AuditUserName || '').trim()
			if (name && !this.isAuditUserCode(name)) return name
			const currentValue = String(row.NguoiThucHien || '').trim()
			if (currentValue && !this.isAuditUserCode(currentValue)) return currentValue
			return name || currentValue || row.AuditUser || row.NguoiThucHienMa ? 'Chưa ghi họ tên trong log' : '—'
		},
		formatAuditActorCode(row) {
			if (!row) return ''
			const code = String(row.NguoiThucHienMa || row.AuditUser || '').trim()
			if (code) return code
			const currentValue = String(row.NguoiThucHien || '').trim()
			return this.isAuditUserCode(currentValue) ? currentValue : ''
		},
		isAuditUserCode(value) {
			return /^[A-Z]{2}\d{4,}$/i.test(String(value || '').trim())
		},
		// Audit payload có thể là object hoặc JSON bị mã hóa lồng nhau; phân tích an toàn trước khi dựng phần so sánh.
		parseAuditValue(value) {
			if (typeof value !== 'string') return value
			const text = value.trim()
			if (!text || (text[0] !== '{' && text[0] !== '[' && text[0] !== '"')) return value
			try {
				const parsed = JSON.parse(text)
				return typeof parsed === 'string' ? this.parseAuditValue(parsed) : parsed
			} catch (error) {
				return value
			}
		},
		normalizeAuditSnapshot(value) {
			const parsed = this.parseAuditValue(value)
			if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return null
			return parsed
		},
		// Bỏ mã định danh và metadata hệ thống để người dùng chỉ tập trung vào nội dung học liệu.
		isTechnicalAuditField(key) {
			const name = String(key || '')
			return /(?:^|_)(?:Log|Audit|Event|Operation|Source|Nguon)/i.test(name) ||
				/(?:ID|Id|Time|Date|User|NguoiThucHien)$/i.test(name) ||
				/^(?:Create|Update|Delete|Insert|Modified)/i.test(name)
		},
		auditFieldLabel(key) {
			const field = String(key || '').split('.').pop()
			const labels = {
				TenNoiDung: 'Tên nội dung',
				TenHocLieu: 'Tên học liệu',
				TenMonHoc: 'Môn học',
				LoaiNoiDung: 'Loại nội dung',
				ThuTu: 'Thứ tự trong học liệu',
				Is_Xoa: 'Trạng thái',
				htmlContent: 'Nội dung bài học',
				content: 'Nội dung bài học',
				title: 'Tiêu đề',
				description: 'Mô tả',
				url: 'Đường dẫn',
				linkUrl: 'Đường dẫn',
				fileName: 'Tên tệp',
				fileUrl: 'Tệp đính kèm'
			}
			if (labels[field]) return labels[field]
			return field.replace(/([a-z0-9])([A-Z])/g, '$1 $2').replace(/[_-]+/g, ' ').replace(/^./, first => first.toLocaleUpperCase('vi-VN')) || 'Thông tin'
		},
		areAuditValuesEqual(first, second) {
			const a = this.parseAuditValue(first)
			const b = this.parseAuditValue(second)
			if (a === b) return true
			if (a === null || b === null || typeof a !== 'object' || typeof b !== 'object') return false
			if (Array.isArray(a) !== Array.isArray(b)) return false
			const aKeys = Object.keys(a).sort()
			const bKeys = Object.keys(b).sort()
			if (aKeys.length !== bKeys.length || aKeys.some((key, index) => key !== bKeys[index])) return false
			return aKeys.every(key => this.areAuditValuesEqual(a[key], b[key]))
		},
		htmlToReadableText(value) {
			const html = String(value || '')
			if (!html) return ''
			if (typeof DOMParser !== 'undefined') {
				const parsedDocument = new DOMParser().parseFromString(html, 'text/html')
				Array.from(parsedDocument.querySelectorAll('script, style, noscript, template')).forEach(node => node.remove())
				return String(parsedDocument.body.textContent || '').replace(/\s+/g, ' ').trim()
			}
			return html.replace(/<script[\s\S]*?<\/script>/gi, ' ').replace(/<style[\s\S]*?<\/style>/gi, ' ').replace(/<[^>]*>/g, ' ').replace(/&nbsp;/gi, ' ').replace(/&amp;/gi, '&').replace(/&lt;/gi, '<').replace(/&gt;/gi, '>').replace(/&quot;/gi, '"').replace(/&#39;/gi, "'").replace(/\s+/g, ' ').trim()
		},
		formatAuditFieldValue(key, value, side, action) {
			if (value === undefined || value === null || value === '') {
				if (side === 'before') return 'Chưa có'
				if (action === 'SOFT_DELETE' || action === 'DELETE') return 'Đã xóa'
				return 'Để trống'
			}
			if (key === 'LoaiNoiDung') {
				const types = { BAI: 'Bài học', HTML: 'Trang nội dung', VIDEO: 'Video', PDF: 'Tài liệu PDF', FILE: 'Tệp đính kèm', LINK: 'Đường dẫn' }
				return types[String(value).toUpperCase()] || String(value)
			}
			if (key === 'Is_Xoa') return value === true || value === 1 || value === '1' || String(value).toLowerCase() === 'true' ? 'Đã xóa' : 'Đang sử dụng'
			if (typeof value === 'boolean') return value ? 'Có' : 'Không'
			if (typeof value === 'object') {
				if (Array.isArray(value)) return value.length ? value.map(item => this.formatAuditFieldValue(key, item, side, action)).join('; ') : 'Không có mục nào'
				return Object.keys(value).filter(field => !this.isTechnicalAuditField(field)).map(field => this.auditFieldLabel(field) + ': ' + this.formatAuditFieldValue(field, value[field], side, action)).join('; ') || 'Không có thông tin'
			}
			const text = String(value)
			if (/<[a-z!/][^>]*>/i.test(text)) return this.htmlToReadableText(text) || 'Nội dung trống'
			return text
		},
		buildReadableChanges(item) {
			if (!item) return []
			const before = this.normalizeAuditSnapshot(item.BeforeData)
			const afterValue = item.AfterData !== undefined && item.AfterData !== null ? item.AfterData : item.DataJson
			const after = this.normalizeAuditSnapshot(afterValue)
			if (!before && !after) return []
			const action = String(item.AuditAction || item.AuditEvent || '').toUpperCase()
			const changes = []
			const addChange = (key, previousValue, nextValue) => {
				if (this.areAuditValuesEqual(previousValue, nextValue)) return
				changes.push({
					key,
					label: this.auditFieldLabel(key),
					before: this.formatAuditFieldValue(key.split('.').pop(), previousValue, 'before', action),
					after: this.formatAuditFieldValue(key.split('.').pop(), nextValue, 'after', action)
				})
			}
			const beforeData = before ? this.parseAuditValue(before.DataJson) : null
			const afterData = after ? this.parseAuditValue(after.DataJson) : null
			const beforeFields = beforeData && typeof beforeData === 'object' ? beforeData : (beforeData ? { htmlContent: beforeData } : {})
			const afterFields = afterData && typeof afterData === 'object' ? afterData : (afterData ? { htmlContent: afterData } : {})
			const dataKeys = Array.from(new Set(Object.keys(beforeFields).concat(Object.keys(afterFields))))
			dataKeys.filter(key => !this.isTechnicalAuditField(key)).forEach(key => addChange('DataJson.' + key, beforeFields[key], afterFields[key]))
			const snapshotKeys = Array.from(new Set(Object.keys(before || {}).concat(Object.keys(after || {}))))
			snapshotKeys.filter(key => key !== 'DataJson' && !this.isTechnicalAuditField(key)).forEach(key => addChange(key, before ? before[key] : undefined, after ? after[key] : undefined))
			return changes
		}
	}
	}
</script>

<style scoped>
.uc-log-hoc-lieu-so .change-value {
		max-height: 220px;
		min-width: 160px;
		overflow-y: auto;
		overflow-wrap: anywhere;
		white-space: pre-wrap;
	}
</style>