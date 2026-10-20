<template>
	<div class="uc-log-diem-table">
		<v-card>
			<v-card-title class="d-flex align-center flex-wrap ga-2">
				<span class="text-primary font-weight-medium">Lịch sử nhập điểm</span>
				<v-text-field
					v-model="nguoiNhapKeyword"
					label="Tìm người nhập điểm"
					placeholder="Gõ tên hoặc mã"
					prepend-inner-icon="mdi-magnify"
					density="compact"
					variant="outlined"
					hide-details
					clearable
					max-width="280"
					class="ml-4"
				/>
				<v-spacer />
				<span class="text-caption text-medium-emphasis">
					{{ filteredLogCount }} lượt ghi nhận · {{ studentItems.length }} học sinh
				</span>
			</v-card-title>
			<v-divider />

			<!-- Tách trạng thái chưa tra cứu, không có dữ liệu và không khớp ô tìm người nhập. -->
			<v-alert v-if="!hasSearched" type="info" variant="tonal" class="ma-4">
				Chọn điều kiện lọc rồi bấm Tra cứu để xem lịch sử nhập điểm.
			</v-alert>
			<v-alert v-else-if="!loading && items.length === 0" type="info" variant="tonal" class="ma-4">
				Không có lịch sử nhập điểm phù hợp với điều kiện đã chọn.
			</v-alert>
			<v-alert v-else-if="!loading && filteredLogCount === 0" type="info" variant="tonal" class="ma-4">
				Không có lượt ghi nhận nào khớp người nhập điểm đang tìm.
			</v-alert>

			<!-- Group theo học sinh; bảng ngoài chỉ có vài trăm dòng nên dùng expand-row ổn định hơn virtual table có dòng con biến chiều cao. -->
			<v-data-table
				v-else
				v-model:expanded="expandedStudentKeys"
				:headers="headers"
				:items="studentItems"
				:row-props="studentRowProps"
				:loading="loading"
				item-value="studentKey"
				fixed-header
				density="compact"
				:items-per-page="-1"
				hide-default-footer
				height="calc(100vh - 250px)"
				show-expand
				expand-on-click
				expand-strategy="single"
				hover
			>
				<template #item.hocSinh="{ item }">
					<div class="d-flex flex-column py-1">
						<span class="font-weight-medium">{{ item.HoTen || '-' }}</span>
						<span class="text-caption text-medium-emphasis">Mã HS: {{ item.HocSinhID || '-' }}</span>
						<span class="text-caption text-medium-emphasis">Số danh bộ: {{ item.SoDanhBo || '-' }}</span>
						<v-chip v-if="isStudentExpanded(item)" size="x-small" color="primary" variant="tonal" class="mt-1 align-self-start">
							Đang mở chi tiết
						</v-chip>
					</div>
				</template>
				<template #item.NhapDiemTime="{ item }">
					<div class="font-weight-medium">{{ formatDateTime(item.latestTime) }}</div>
					<div class="text-caption text-medium-emphasis">{{ item.logs.length }} lượt log</div>
				</template>
				<template #item.logCount="{ item }">
					<span>{{ item.logs.length }}</span>
				</template>
				<template #expanded-row="{ columns, item }">
					<tr>
						<td :colspan="columns.length" class="pa-0">
							<div class="uc-log-diem-table__detail pa-3">
								<div class="text-caption text-medium-emphasis mb-2">
									Lịch sử điểm của <strong>{{ item.HoTen || '-' }}</strong>
									· {{ item.logs.length }} lượt ghi nhận
								</div>
								<!-- Chỉ mở một học sinh; bảng chi tiết không tạo scrollbar lồng. -->
								<v-table density="compact" class="uc-log-diem-table__detail-table">
									<thead>
										<tr>
											<th>Thời gian</th>
											<th>Môn học</th>
											<th class="text-center">STT nhóm</th>
											<th>Nhóm cột điểm</th>
											<th class="text-center">STT cột</th>
											<th>Cột điểm</th>
											<th>Giá trị</th>
											<th>Người nhập / thời gian</th>
										</tr>
									</thead>
									<tbody>
										<tr v-for="log in item.logs" :key="log.__logKey">
											<td class="text-no-wrap">{{ formatDateTime(log.NhapDiemTime) }}</td>
											<td>{{ log.TenMonHoc_HienThi || '-' }}</td>
											<td class="text-center">{{ displayOrder(log.ThuTuNhomCotDiem) }}</td>
											<td>{{ log.TenNhomCotDiem_VI || log.MaNhomCotDiem || '-' }}</td>
											<td class="text-center">{{ displayOrder(log.ThuTuCotDiem) }}</td>
											<td>{{ log.MaCotDiem || log.TenCotDiem_VI || '-' }}</td>
											<td>{{ formatScoreValue(log.KetQuaDanhGia_VI) }}</td>
											<td>
												<div>{{ log.NhapDiemUserName || log.NhapDiemUser || '-' }}</div>
												<div v-if="log.NhapDiemUser" class="text-caption text-medium-emphasis">{{ log.NhapDiemUser }}</div>
												<div class="text-caption text-medium-emphasis">{{ formatDateTime(log.NhapDiemTime) }}</div>
											</td>
										</tr>
									</tbody>
								</v-table>
							</div>
						</td>
					</tr>
				</template>
			</v-data-table>
		</v-card>
	</div>
</template>

<script>
	export default {
		props: {
			items: {
				type: Array,
				default: function () { return [] }
			},
			loading: {
				type: Boolean,
				default: false
			},
			hasSearched: {
				type: Boolean,
				default: false
			}
		},
		data() {
			return {
				headers: [
					{ title: 'Thời gian gần nhất', key: 'NhapDiemTime', value: 'NhapDiemTime', sortable: false, width: 175 },
					{ title: 'Học sinh', key: 'hocSinh', value: 'hocSinh', sortable: false, minWidth: 230 },
					{ title: 'Lớp', key: 'TenLop', value: 'TenLop', sortable: false, width: 75 },
					{ title: 'Số lượt log', key: 'logCount', value: 'logCount', sortable: false, width: 110 }
				],
				nguoiNhapKeyword: '',
				expandedStudentKeys: []
			}
		},
		computed: {
			// Tìm người nhập trên log gốc nhưng chỉ giữ lại học sinh có ít nhất một bản ghi khớp.
			filteredItems() {
				const keyword = String(this.nguoiNhapKeyword || '').trim().toLocaleLowerCase('vi-VN')
				if (!keyword) return [...this.items]
				return this.items.filter(item => {
					const userText = [item.NhapDiemUserName, item.NhapDiemUser]
						.filter(value => value !== undefined && value !== null && String(value).trim() !== '')
						.join(' ')
						.toLocaleLowerCase('vi-VN')
					return userText.includes(keyword)
				})
			},
			// Gom theo học sinh + lớp; không gom các log điểm vào cùng một ô để vẫn giữ lịch sử từng lần nhập.
			studentItems() {
				const groups = new Map()
				for (const row of this.filteredItems) {
					const studentKey = [row.LopID || row.TenLop || '', row.HocSinhID || row.SoDanhBo || row.HoTen || 'unknown'].join('|')
					let group = groups.get(studentKey)
					if (!group) {
						group = {
							studentKey,
							HoTen: row.HoTen,
							HocSinhID: row.HocSinhID,
							SoDanhBo: row.SoDanhBo,
							TenLop: row.TenLop,
							LopID: row.LopID,
							logs: []
						}
						groups.set(studentKey, group)
					}
					group.logs.push(row)
				}

				return [...groups.values()].map(group => {
					const logs = [...group.logs].sort((a, b) => this.compareLogRows(a, b)).map((log, index) => ({
						...log,
						// KQHTID + BackupID phân biệt bản ghi hiện tại/lịch sử; index xử lý trường hợp dữ liệu trùng key.
						__logKey: String(log.KQHTID || log.HocSinhID || 'log') + '-' + String(log.BackupID || 0) + '-' + index
					}))
					const latestLog = [...logs].sort((a, b) => new Date(b.NhapDiemTime || 0) - new Date(a.NhapDiemTime || 0))[0]
					return {
						...group,
						logs,
						latestTime: latestLog?.NhapDiemTime || null
					}
				}).sort((a, b) => {
					const lopCompare = String(a.TenLop || '').localeCompare(String(b.TenLop || ''), 'vi', { numeric: true, sensitivity: 'base' })
					if (lopCompare !== 0) return lopCompare
					const danhBoCompare = String(a.SoDanhBo || '').localeCompare(String(b.SoDanhBo || ''), 'vi', { numeric: true, sensitivity: 'base' })
					if (danhBoCompare !== 0) return danhBoCompare
					return String(a.HoTen || '').localeCompare(String(b.HoTen || ''), 'vi', { sensitivity: 'base' })
				})
			},
			filteredLogCount() {
				return this.filteredItems.length
			}
		},
		watch: {
			// Kết quả tra cứu mới có thể không còn học sinh đang mở; đóng expansion cũ để không giữ dòng chi tiết ngoài tập dữ liệu.
			items() {
				this.expandedStudentKeys = []
			}
		},
		methods: {
			// Row props làm nổi bật đúng dòng học sinh cha đang chứa bảng chi tiết mở bên dưới.
			studentRowProps({ item }) {
				return {
					class: this.isStudentExpanded(item) ? 'uc-log-diem-table__student-row--expanded' : ''
				}
			},
			isStudentExpanded(item) {
				const rawItem = item?.raw || item
				const key = rawItem?.studentKey
				return key !== undefined && this.expandedStudentKeys.some(value => String(value) === String(key))
			},
			compareOrder(leftValue, rightValue) {
				const left = Number(leftValue)
				const right = Number(rightValue)
				if (Number.isFinite(left) && Number.isFinite(right)) return left - right
				if (Number.isFinite(left)) return -1
				if (Number.isFinite(right)) return 1
				return 0
			},
			compareLogRows(a, b) {
				// Thứ tự lấy từ cấu hình: môn → nhóm cột → cột điểm; thời gian chỉ là tie-breaker cuối cùng.
				const subjectOrder = this.compareOrder(a.ThuTuMonHoc, b.ThuTuMonHoc)
				if (subjectOrder !== 0) return subjectOrder
				const subjectName = String(a.TenMonHoc_HienThi || '').localeCompare(String(b.TenMonHoc_HienThi || ''), 'vi', { sensitivity: 'base' })
				if (subjectName !== 0) return subjectName
				const groupOrder = this.compareOrder(a.ThuTuNhomCotDiem, b.ThuTuNhomCotDiem)
				if (groupOrder !== 0) return groupOrder
				const scoreOrder = this.compareOrder(a.ThuTuCotDiem, b.ThuTuCotDiem)
				if (scoreOrder !== 0) return scoreOrder
				const scoreName = String(a.MaCotDiem || '').localeCompare(String(b.MaCotDiem || ''), 'vi', { numeric: true, sensitivity: 'base' })
				if (scoreName !== 0) return scoreName
				return new Date(a.NhapDiemTime || 0) - new Date(b.NhapDiemTime || 0)
			},
			displayOrder(value) {
				return value === undefined || value === null || String(value).trim() === '' ? '-' : value
			},
			// Một số điểm được lưu dạng chuỗi ".3"/".5"; chỉ chuẩn hóa phần hiển thị, không thay đổi dữ liệu log gốc.
			formatScoreValue(value) {
				if (value === undefined || value === null || String(value).trim() === '') return '-'
				const text = String(value).trim()
				return text.replace(/^(-?)\.(\d+)$/, '$10.$2')
			},
			formatDateTime(value) {
				if (!value) return '-'
				const date = new Date(value)
				if (Number.isNaN(date.getTime())) return String(value).replace('T', ' ')
				return date.toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
			}
		}
	}
</script>

<style scoped>
/* Bảng chi tiết có nhiều cột; giữ dữ liệu thẳng hàng và để bảng ngoài chỉ có một scrollbar. */
.uc-log-diem-table td,
.uc-log-diem-table th {
	white-space: nowrap;
}

/* Dòng cha đang mở dùng nền/viền xanh và chip để người dùng nhận biết bảng con thuộc về học sinh nào. */
.uc-log-diem-table__student-row--expanded > td {
	background: rgba(46, 125, 50, 0.09) !important;
	border-top: 2px solid rgba(46, 125, 50, 0.55) !important;
}

.uc-log-diem-table__student-row--expanded > td:first-child {
	border-left: 3px solid #2e7d32 !important;
}

.uc-log-diem-table__detail {
	background: rgba(46, 125, 50, 0.035);
	border-left: 3px solid rgba(46, 125, 50, 0.35);
}

.uc-log-diem-table__detail-table {
	border: 1px solid rgba(0, 0, 0, 0.08);
}
</style>