<template>
	<!-- Giữ khoảng đệm ở ba cạnh, riêng mép phải không đệm để scrollbar của nội dung sát viền tab. -->
	<v-card-text class="pt-2 pb-2 pl-2 pr-0" :style="{ height: sheetHeight, overflow: 'hidden', minWidth: '0', maxWidth: '100%', boxSizing: 'border-box' }">
    <v-alert v-if="selectedLopID === '__ALL__'" type="info" variant="tonal" density="compact">
      Chọn một lớp ở thanh trên để nhập thông tin tổ chức lớp.
    </v-alert>
	<div v-else class="d-flex h-100 ga-3" style="min-height: 0; min-width: 0; max-width: 100%; overflow: hidden;">
      <div class="flex-shrink-0 overflow-y-auto" style="width: 260px; border-right: 1px solid rgba(0, 0, 0, 0.12);">
        <v-list density="compact" nav color="primary" class="pa-0">
          <v-list-item v-for="card in organizationCards" :key="card.key" :value="card.key"
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
        </v-list>
      </div>

      <!-- Chỉ vùng nội dung tab được cuộn; page shell và thanh header giữ nguyên vị trí. -->
	  <div ref="scrollContainer" class="flex-grow-1 h-100 overflow-y-auto" style="min-width: 0; min-height: 0; max-width: 100%; overflow-x: hidden;">
        <v-row dense class="pb-2" style="min-width: 0; max-width: 100%;">
          <v-col v-for="card in organizationCards" :key="card.key" cols="12" class="py-1" style="min-width: 0; max-width: 100%;">
            <v-card :id="card.domId" outlined elevation="0" class="mb-2" style="max-width: 100%;">
              <v-card-title class="px-3 py-2 text-subtitle-2 font-weight-bold text-primary d-flex align-center">
                <v-icon start color="primary" class="mr-2" size="small">{{ card.icon }}</v-icon>
                {{ card.title }}
              </v-card-title>
              <v-divider />
              <v-card-text class="pa-0 so-gvcn-card-sheet-wrap">
                <!-- Tab này dùng toàn bộ chiều cao vùng bảng; người dùng cuộn trong JSpreadsheet khi cần. -->
                <div :ref="card.refName" class="w-100 so-gvcn-sheet so-gvcn-organization-sheet"
                  style="height: 100%; max-height: 100%;"></div>
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
		name: 'so-gvcn-c1-tab-to-chuc-lop',
		props: {
			selectedLopID: { type: [String, Number], default: '__ALL__' },
			students: { type: Array, default: () => [] },
			canBoRows: { type: Array, default: () => [] },
			parentRows: { type: Array, default: () => [] },
			groupRows: { type: Array, default: () => [] },
			sheetHeight: { type: String, default: 'calc(100vh - 230px)' }
		},
		data() {
			return {
				localSheetKey: 0,
				organizationCards: [],
				activeCardKey: 'can-bo-lop',
				sheetInstances: {}
			}
		},
		watch: {
			selectedLopID() {
				this.buildCards()
			},
			students: {
				deep: true,
				handler() {
					this.buildCards()
				}
			},
			canBoRows: {
				deep: true,
				handler() {
					this.buildCards()
				}
			},
			parentRows: {
				deep: true,
				handler() {
					this.buildCards()
				}
			},
			groupRows: {
				deep: true,
				handler() {
					this.buildCards()
				}
			}
		},
		created() {
			this.buildCards()
		},
		mounted() {
			this.initAllSheets()
		},
		beforeUnmount() {
			this.destroyAllSheets()
		},
		methods: {
			getStudentNames() {
				return (this.students || [])
					.map(row => row.HoTen || row.HoTenHocSinh || '')
					.filter(Boolean)
			},
			trimRows(rows, minimumLength) {
				const copied = (rows || []).map(row => Array.isArray(row) ? row.slice() : { ...row })
				while (copied.length > minimumLength) {
					const row = copied[copied.length - 1]
					const values = Array.isArray(row) ? row.slice(1) : Object.values(row)
					if (values.some(value => value !== null && value !== undefined && String(value).trim() !== '')) break
					copied.pop()
				}
				while (copied.length < minimumLength) copied.push({})
				return copied
			},
			buildCards() {
				const studentNames = this.getStudentNames()
				const canBoData = this.trimRows(this.canBoRows, 6).map((row, index) => {
					const studentName = row.HocSinh || row[2] || ''
					const student = this.findStudent(studentName)
					return [
						index + 1,
						row.MaHocSinh || row.HocSinhID || row[1] || student.MaHocSinh || student.HocSinhID || '',
						row.SoDanhBo || student.SoDanhBo || '',
						studentName,
						row.ChucVu || row[3] || '',
						row.GhiChu || row[4] || ''
					]
				})
				const parentData = this.trimRows(this.parentRows, 6).map((row, index) => {
					const studentName = row.HocSinh || row[2] || ''
					const student = this.findStudent(studentName)
					const parent = this.getParentSummary(student)
					return [
						index + 1,
						row.MaHocSinh || row.HocSinhID || row[1] || student.MaHocSinh || student.HocSinhID || '',
						row.SoDanhBo || student.SoDanhBo || '',
						studentName,
						parent.names || row.ChaMe || row[3] || '',
						row.NhiemVu || row[6] || '',
						row.GhiChu || row[7] || ''
					]
				})
				const groupMap = new Map((this.groupRows || []).map(row => [
					String(row.HSLopID || row.HocSinhID || ''),
					row
				]))
				const groupData = (this.students || []).map(student => {
					const saved = groupMap.get(String(student.HSLopID || student.HocSinhID || '')) || {}
					return [
						saved.ToNhom || '',
						student.MaHocSinh || student.HocSinhID || '',
						student.SoDanhBo || '',
						student.HoTen || student.HoTenHocSinh || '',
						saved.NhiemVu || '',
						saved.Ban || ''
					]
				})
				this.sortGroupRows(groupData)

				this.organizationCards = [
					{
						key: 'can-bo-lop',
						refName: 'sheetRef_can_bo_lop',
						domId: 'c1_to_chuc_can_bo_lop',
						navTitle: 'I. Ban cán sự lớp',
						icon: 'mdi-account-star-outline',
						title: 'I. BAN CÁN SỰ LỚP',
						columns: [
							{ title: 'STT', name: 'STT', width: 65, align: 'center', readOnly: true },
							{ title: 'MÃ HỌC SINH', name: 'MaHocSinh', width: 130, readOnly: true },
							{ title: 'SỐ DANH BỘ', name: 'SoDanhBo', width: 130, readOnly: true },
							{
								title: 'HỌ VÀ TÊN HỌC SINH', name: 'HocSinh', width: 320,
								type: 'dropdown', source: studentNames, autocomplete: true
							},
							{ title: 'NHIỆM VỤ', name: 'ChucVu', width: 260, align: 'justify' },
							{ title: 'GHI CHÚ', name: 'GhiChu', width: 420, align: 'justify' }
						],
						rows: canBoData
					},
					{
						key: 'ban-dai-dien-cmhs',
						refName: 'sheetRef_ban_dai_dien_cmhs',
						domId: 'c1_to_chuc_ban_dai_dien_cmhs',
						navTitle: 'II. Ban đại diện CMHS',
						icon: 'mdi-human-male-female-child',
						title: 'II. BAN ĐẠI DIỆN CHA MẸ HỌC SINH LỚP',
						columns: [
							{ title: 'STT', name: 'STT', width: 65, align: 'center', readOnly: true },
							{ title: 'MÃ HỌC SINH', name: 'MaHocSinh', width: 130, readOnly: true },
							{ title: 'SỐ DANH BỘ', name: 'SoDanhBo', width: 130, readOnly: true },
							{
								title: 'HỌ VÀ TÊN HỌC SINH', name: 'HocSinh', width: 300,
								type: 'dropdown', source: studentNames, autocomplete: true
							},
							{ title: 'HỌ VÀ TÊN PHỤ HUYNH', name: 'ChaMe', width: 340, readOnly: true },
							{ title: 'NHIỆM VỤ', name: 'NhiemVu', width: 260, align: 'justify' },
							{ title: 'GHI CHÚ', name: 'GhiChu', width: 420, align: 'justify' }
						],
						rows: parentData
					}
				]
				this.localSheetKey++
				this.initAllSheets()
			},
			scrollToCard(card) {
				this.activeCardKey = card.key
				const container = this.$refs.scrollContainer
				// Tìm target trong đúng vùng content có scrollbar, không phụ thuộc $el của Vuetify.
				const target = container?.querySelector?.(`#${card.domId}`)
				if (!container || !target) return

				const top = target.getBoundingClientRect().top
					- container.getBoundingClientRect().top
					+ container.scrollTop
				container.scrollTo({ top, behavior: 'smooth' })
			},
			destroySheet(cardKey) {
				const instance = this.sheetInstances[cardKey]
				if (!instance) return
				try {
					const sheet = Array.isArray(instance) ? instance[0] : instance
					if (sheet && typeof sheet.destroy === 'function') sheet.destroy()
				} catch (error) {}
				delete this.sheetInstances[cardKey]
			},
			destroyAllSheets() {
				Object.keys(this.sheetInstances).forEach(key => this.destroySheet(key))
			},
			getResponsiveColumns(card, container) {
				const columns = (card.columns || []).map(column => ({ ...column }))
				// Chừa 54px cho cột số dòng và viền JSpreadsheet để không tạo thanh cuộn ngang 1–2px.
				const availableWidth = Math.floor(container?.clientWidth || 0) - 54
				if (availableWidth <= 0) return columns

				const fixedColumns = new Set(['STT', 'MaHocSinh', 'SoDanhBo'])
				const minimumWidths = {
					STT: 50,
					MaHocSinh: 105,
					SoDanhBo: 95,
					HocSinh: 180,
					ChucVu: 130,
					ChaMe: 200,
					NhiemVu: 130,
					GhiChu: 150
				}
				const currentWidth = columns.reduce((total, column) => total + Number(column.width || 0), 0)
				if (currentWidth <= availableWidth) return columns

				const fixedWidth = columns
					.filter(column => fixedColumns.has(column.name))
					.reduce((total, column) => total + Number(column.width || 0), 0)
				const flexibleColumns = columns.filter(column => !fixedColumns.has(column.name))
				const flexibleWidth = flexibleColumns.reduce((total, column) => total + Number(column.width || 0), 0)
				const minimumFlexibleWidth = flexibleColumns.reduce((total, column) => total + (minimumWidths[column.name] || 120), 0)
				const targetFlexibleWidth = Math.max(minimumFlexibleWidth, availableWidth - fixedWidth)
				const extraWidth = flexibleWidth - minimumFlexibleWidth
				const distributableWidth = Math.max(0, targetFlexibleWidth - minimumFlexibleWidth)

				flexibleColumns.forEach((column, index) => {
					const minimumWidth = minimumWidths[column.name] || 120
					if (index === flexibleColumns.length - 1) {
						const usedWidth = flexibleColumns.slice(0, index).reduce((total, item) => total + item.width, 0)
						column.width = Math.max(minimumWidth, targetFlexibleWidth - usedWidth)
						return
					}
					const share = extraWidth > 0 ? (column.width - minimumWidth) / extraWidth : 0
					column.width = minimumWidth + Math.floor(distributableWidth * share)
				})
				return columns
			},
			initSheet(card) {
				if (!card) return
				this.$nextTick(() => {
					let container = this.$refs[card.refName]
					if (Array.isArray(container)) container = container[0]
					if (!container || !card.rows || !card.rows.length) {
						this.destroySheet(card.key)
						return
					}

					this.destroySheet(card.key)
					container.innerHTML = ''
					if (typeof jspreadsheet !== 'function') return
					const columns = this.getResponsiveColumns(card, container)

					try {
						this.sheetInstances[card.key] = soGvcnJspreadsheet.create(container, {
							worksheets: [{
								data: card.rows,
								columns,
								rowResize: true,
								columnDrag: false,
								tableWidth: '100%',
								tableOverflow: true,
								// Dùng toàn bộ chiều cao của vùng bảng để giữ header và vùng nhập liệu ổn định;
								// JSpreadsheet tự cuộn dọc/ngang bên trong khi dữ liệu vượt khung.
								tableHeight: '100%',
								lazyLoading: false,
								wordWrap: true,
								allowInsertColumn: false,
								allowInsertRow: false,
								showHeader: true
							}],
							contextMenu: () => false,
							onchange: (worksheet, cell, x, y, value) => {
								if (card.key === 'can-bo-lop' && Number(x) === 3) {
									const student = this.findStudent(value)
									if (student && typeof worksheet.setValueFromCoords === 'function') {
										worksheet.setValueFromCoords(1, Number(y), student.MaHocSinh || student.HocSinhID || '', true)
										worksheet.setValueFromCoords(2, Number(y), student.SoDanhBo || '', true)
									}
								}
								if (card.key === 'ban-dai-dien-cmhs' && Number(x) === 3) {
									this.fillParentRow(worksheet, Number(y), value)
								}
								card.rows = worksheet.getData()
							}
						})
					} catch (error) {
						console.error('Không thể khởi tạo bảng tổ chức lớp:', card.key, error)
					}
				})
			},
			initAllSheets() {
				;(this.organizationCards || []).forEach(card => this.initSheet(card))
			},
			findStudent(name) {
				const cleanName = String(name || '').trim()
				return (this.students || []).find(student =>
					String(student.HoTen || student.HoTenHocSinh || '').trim() === cleanName) || {}
			},
			getLiveCardRows(card) {
				const instance = this.sheetInstances[card.key]
				const worksheet = Array.isArray(instance) ? instance[0] : instance
				if (worksheet && typeof worksheet.closeEditor === 'function') {
					try {
						worksheet.closeEditor(true)
					} catch (error) {}
				}
				if (worksheet && typeof worksheet.getData === 'function') {
					const rows = worksheet.getData()
					card.rows = rows
					return rows
				}
				return card.rows || []
			},
			getParentSummary(student) {
				const father = student?.Cha || student?.HoTenCha || ''
				const mother = student?.Me || student?.HoTenMe || ''
				const fatherJob = student?.NgheNghiepCha || ''
				const motherJob = student?.NgheNghiepMe || ''
				const fatherPhone = student?.SDTCha || student?.DienThoaiCha || ''
				const motherPhone = student?.SDTMe || student?.DienThoaiMe || ''
				return {
					names: father || mother ? ['Cha: ' + father, 'Mẹ: ' + mother].join('\n') : '',
					jobs: fatherJob || motherJob ? ['Cha: ' + fatherJob, 'Mẹ: ' + motherJob].join('\n') : '',
					phones: fatherPhone || motherPhone ? ['Cha: ' + fatherPhone, 'Mẹ: ' + motherPhone].join('\n') : ''
				}
			},
			fillParentRow(worksheet, rowIndex, studentName) {
				if (!worksheet || typeof worksheet.getData !== 'function'
					|| typeof worksheet.setValueFromCoords !== 'function') return
				const student = this.findStudent(studentName)
				const parent = this.getParentSummary(student)
				worksheet.setValueFromCoords(1, rowIndex, student.MaHocSinh || student.HocSinhID || '', true)
				worksheet.setValueFromCoords(2, rowIndex, student.SoDanhBo || '', true)
				worksheet.setValueFromCoords(4, rowIndex, parent.names, true)
			},
			sortGroupRows(rows) {
				return (rows || []).sort((rowA, rowB) => {
					const groupA = String(rowA?.[0] || '').trim()
					const groupB = String(rowB?.[0] || '').trim()
					if (!groupA && groupB) return 1
					if (groupA && !groupB) return -1
					const groupCompare = groupA.localeCompare(groupB, 'vi', {
						numeric: true,
						sensitivity: 'base'
					})
					if (groupCompare !== 0) return groupCompare

					const bookA = String(rowA?.[2] || '').trim()
					const bookB = String(rowB?.[2] || '').trim()
					const bookCompare = bookA.localeCompare(bookB, 'vi', {
						numeric: true,
						sensitivity: 'base'
					})
					if (bookCompare !== 0) return bookCompare
					return String(rowA?.[3] || '').localeCompare(String(rowB?.[3] || ''), 'vi')
				})
			},
			getOrganizationRows() {
				const canBoCard = this.organizationCards.find(card => card.key === 'can-bo-lop') || {}
				const parentCard = this.organizationCards.find(card => card.key === 'ban-dai-dien-cmhs') || {}
				const groupCard = this.organizationCards.find(card => card.key === 'to-nhom-hoc-sinh') || {}
				const canBoRows = this.getLiveCardRows(canBoCard)
				const parentRows = this.getLiveCardRows(parentCard)
				const groupRows = this.getLiveCardRows(groupCard)

				return {
					canBoRows: canBoRows.map((row, index) => {
						const student = this.findStudent(row[3])
						return {
							STT: index + 1,
							HSLopID: student.HSLopID || null,
							HocSinhID: student.HocSinhID || null,
							MaHocSinh: row[1] || student.MaHocSinh || student.HocSinhID || '',
							SoDanhBo: row[2] || student.SoDanhBo || '',
							HocSinh: row[3] || '',
							ChucVu: row[4] || '',
							GhiChu: row[5] || ''
						}
					}),
					parentRows: parentRows.map((row, index) => {
						const student = this.findStudent(row[3])
						const parent = this.getParentSummary(student)
						return {
							STT: index + 1,
							HSLopID: student.HSLopID || null,
							HocSinhID: student.HocSinhID || null,
							MaHocSinh: row[1] || student.MaHocSinh || student.HocSinhID || '',
							SoDanhBo: row[2] || student.SoDanhBo || '',
							HocSinh: row[3] || '',
							ChaMe: row[4] || '',
							NgheNghiep: parent.jobs,
							DienThoai: parent.phones,
							NhiemVu: row[5] || '',
							GhiChu: row[6] || ''
						}
					}),
					groupRows: this.sortGroupRows(groupRows).map((row, index) => {
						const student = this.findStudent(row[3])
						return {
							HSLopID: student.HSLopID || null,
							HocSinhID: student.HocSinhID || null,
							MaHocSinh: row[1] || student.MaHocSinh || student.HocSinhID || '',
							SoDanhBo: row[2] || student.SoDanhBo || '',
							HocSinh: row[3] || '',
							ToNhom: row[0] || '',
							NhiemVu: row[4] || '',
							Ban: row[5] || '',
							RowIndex: index + 1
						}
					})
				}
			}
		}
	}
</script>