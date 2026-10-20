<template>
	<div class="d-flex flex-column ga-2 overflow-y-auto pa-2">
		<div v-if="searchable && rows.length > 8" class="d-flex align-center ga-2">
			<v-text-field v-model="searchText" label="Tìm trong danh sách" prepend-inner-icon="mdi-magnify"
				clearable density="compact" variant="outlined" hide-details />
			<div class="text-caption text-medium-emphasis text-no-wrap">{{ visibleRows.length }}/{{ rows.length }}</div>
		</div>

		<div v-if="!visibleRows.length" class="text-body-2 text-medium-emphasis pa-2">
			{{ searchText ? 'Không tìm thấy dòng phù hợp.' : emptyText }}
		</div>

		<v-expansion-panels v-else variant="accordion">
			<v-expansion-panel v-for="entry in visibleRows" :key="entry.index" :value="entry.index">
				<v-expansion-panel-title>
					<div class="d-flex flex-column text-left">
						<span class="font-weight-medium">{{ rowTitle(entry.row, entry.index) }}</span>
						<span v-if="rowSubtitle(entry.row)" class="text-caption text-medium-emphasis">
							{{ rowSubtitle(entry.row) }}
						</span>
					</div>
				</v-expansion-panel-title>
				<v-expansion-panel-text>
					<v-row v-if="readOnlyFields(entry.row).length" dense class="mb-1">
						<v-col v-for="field in readOnlyFields(entry.row)" :key="field.index" cols="6" class="py-1">
							<div class="text-caption text-medium-emphasis">{{ field.label }}</div>
							<div class="text-body-2 text-break">{{ displayValue(field.value) }}</div>
						</v-col>
					</v-row>

					<v-row dense>
						<v-col v-for="field in editableFields(entry.row)" :key="field.index"
							:cols="fieldColumns(field.column, field.index)" class="py-1">
							<v-checkbox v-if="field.column.type === 'checkbox'"
							:model-value="!!field.value" :label="field.label"
								:disabled="readOnly" density="compact" hide-details
								@update:model-value="updateCell(entry.index, field.index, $event)" />
						<v-autocomplete v-else-if="field.column.type === 'dropdown' || field.column.type === 'select'"
							:model-value="displayCellValue(field.value, field.index, '')" :label="field.label"
							:items="field.column.source || field.column.items || []"
							:disabled="readOnly" density="compact" variant="outlined" hide-details clearable
							@update:model-value="updateCell(entry.index, field.index, $event)" />
							<v-textarea v-else-if="isLongText(field.column, field.index)"
							:model-value="displayCellValue(field.value, field.index, '')" :label="field.label"
								:disabled="readOnly" auto-grow rows="2" density="compact" variant="outlined" hide-details
								@update:model-value="updateCell(entry.index, field.index, $event)" />
							<v-text-field v-else
							:model-value="displayCellValue(field.value, field.index, '')" :label="field.label"
								:type="isNumeric(field.column, field.index) ? 'number' : 'text'"
								:disabled="readOnly" density="compact" variant="outlined" hide-details
								@update:model-value="updateCell(entry.index, field.index, $event)" />
						</v-col>
					</v-row>
					<div v-if="!editableFields(entry.row).length" class="text-body-2 text-medium-emphasis">
						Không có trường cần chỉnh sửa.
					</div>
				</v-expansion-panel-text>
			</v-expansion-panel>
		</v-expansion-panels>
	</div>
</template>

<script>
	export default {
		props: {
			rows: { type: Array, default: () => [] },
			columns: { type: Array, default: () => [] },
			titleIndex: { type: Number, default: 0 },
			subtitleIndices: { type: Array, default: () => [] },
			nestedHeaders: { type: Array, default: () => [] },
			plainTextIndices: { type: Array, default: () => [] },
			numericIndices: { type: Array, default: () => [] },
			readOnly: { type: Boolean, default: false },
			searchable: { type: Boolean, default: false },
			emptyTitle: { type: String, default: 'Dòng' },
			emptyText: { type: String, default: 'Chưa có dữ liệu.' }
		},
		data() {
			return { localRows: [], searchText: '' }
		},
		watch: {
			rows: {
				deep: false,
				handler() {
					this.localRows = this.cloneRows(this.rows)
				}
			}
		},
		created() {
			this.localRows = this.cloneRows(this.rows)
		},
		computed: {
			visibleRows() {
				const query = String(this.searchText || '').trim().toLocaleLowerCase('vi')
				return this.localRows.map((row, index) => ({ row, index })).filter(entry => {
					if (!query) return true
					return entry.row.map(value => this.displayValue(value, '')).join(' ')
						.toLocaleLowerCase('vi').includes(query)
				})
			}
		},
		methods: {
			// Keep the row-array contract used by the desktop sheet and parent save handlers.
			cloneRows(rows) {
				return (Array.isArray(rows) ? rows : []).map(row => Array.isArray(row)
					? row.map(value => this.cleanSheetValue(value))
					: [])
			},
			cleanSheetValue(value) {
				if (value === null || value === undefined) return ''
				if (Array.isArray(value) || (typeof value === 'object' && !(value instanceof Date))) {
					try { return JSON.stringify(value) } catch (error) { return '' }
				}
				if (value instanceof Date) return value.toISOString()
				return value
			},
			displayValue(value, emptyValue = '—') {
				if (value === null || value === undefined || String(value).trim() === '') return emptyValue
				if (typeof value === 'object') {
					try { return JSON.stringify(value) } catch (error) { return emptyValue }
				}
				return String(value)
			},
			rowTitle(row, index) {
				const value = this.displayValue(row[this.titleIndex], '')
				if (value) return value
				const title = this.emptyTitle || this.columns[this.titleIndex]?.title || 'Dòng'
				return `${title} ${index + 1}`
			},
			rowSubtitle(row) {
				return this.subtitleIndices.map(index => {
					const value = this.displayCellValue(row[index], index, '')
					return value ? `${this.fieldLabel(index)}: ${value}` : ''
				}).filter(Boolean).join(' · ')
			},
			fieldLabel(index) {
				const titles = []
				// Normalize the optional header rows and avoid a line-leading call expression after the array declaration (ASI treated it as calling `titles`).
				const nestedHeaders = Array.isArray(this.nestedHeaders) ? this.nestedHeaders : []
				nestedHeaders.forEach(headerRow => {
					let offset = 0
					const cells = Array.isArray(headerRow) ? headerRow : []
					for (const cell of cells) {
						if (!cell || typeof cell !== 'object') continue
						const span = Math.max(1, Number(cell.colspan) || 1)
						const isMatch = index >= offset && index < offset + span
						if (isMatch && cell.title) titles.push(String(cell.title))
						offset += span
						if (isMatch) break
					}
				})
				const baseTitle = String(this.columns[index]?.title || '')
				return [...new Set([...titles, baseTitle].filter(Boolean))].join(' · ') || ('Thông tin ' + (index + 1))
			},
			readOnlyFields(row) {
				const hidden = [this.titleIndex, ...this.subtitleIndices]
				return this.columns.map((column, index) => ({ column, index, value: row[index] }))
					.filter(field => field.column.readOnly && !hidden.includes(field.index))
					.map(field => ({ ...field, label: this.fieldLabel(field.index) }))
				},
			editableFields(row) {
				return this.columns.map((column, index) => ({ column, index, value: row[index] }))
					.filter(field => !field.column.readOnly)
					.map(field => ({ ...field, label: this.fieldLabel(field.index) }))
				},
			displayCellValue(value, index, emptyValue = '—') {
				const text = this.displayValue(value, emptyValue)
				if (emptyValue === '' && this.plainTextIndices.includes(index)) {
					return text.replace(/<br\s*\/?\s*>/gi, '\n').replace(/<\/p\s*>/gi, '\n')
						.replace(/<[^>]*>/g, '').replace(/&nbsp;/gi, ' ').replace(/&amp;/gi, '&')
						.replace(/&lt;/gi, '<').replace(/&gt;/gi, '>').replace(/&quot;/gi, '"')
						.replace(/&#39;/gi, "'")
				}
				return text
			},
			isNumeric(column, index) {
				if (this.numericIndices.includes(index)) return true
				if (column.type === 'numeric') return true
				const title = String(column.title || '').toLocaleLowerCase('vi')
				return /^(tổng số|nam|nữ|đội viên|nhi đồng|con liệt sĩ|con thương binh|có đánh giá|không đánh giá|hộ nghèo)$/.test(title)
			},
			isLongText(column, index) {
				return column.type !== 'checkbox' && !this.isNumeric(column, index)
					&& (Number(column.width) >= 280 || /ghi chú|lí do|lý do|nhận xét|kết quả|nội dung/i.test(String(column.title || '')))
			},
			fieldColumns(column, index) {
				return this.isLongText(column, index) ? 12 : 6
			},
			updateCell(rowIndex, columnIndex, value) {
				const rows = this.localRows.map(row => row.slice())
				rows[rowIndex][columnIndex] = this.cleanSheetValue(value)
				this.localRows = rows
				this.$emit('cell-changed', { rowIndex, columnIndex, value: this.cleanSheetValue(value), rows: this.cloneRows(rows) })
			},
			setRows(rows) {
				this.localRows = this.cloneRows(rows)
			},
			getRows() {
				return this.cloneRows(this.localRows)
			}
		}
	}
</script>