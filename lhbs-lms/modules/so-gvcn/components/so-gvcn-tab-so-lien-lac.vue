<template>
	<!-- h-100 flex-column: sheet chiếm toàn bộ chiều cao của v-window-item -->
	<div class="h-100 overflow-hidden d-flex flex-column">
		<!-- Chỉ hiển thị lý do khi kỳ sổ liên lạc bị từ chối; component cha truyền giá trị này từ trạng thái workflow. -->
		<v-alert v-if="reasonReject" type="error" variant="tonal" density="compact" class="ma-2"
			style="flex: 0 0 auto; min-height: auto;">
			Lý do từ chối: {{ reasonReject }}
		</v-alert>
		<div class="pt-0 position-relative flex-grow-1 overflow-hidden so-gvcn-sheet so-gvcn-sheet-wrap so-gvcn-so-lien-lac-sheet-wrap" style="min-height: 0;">
			<v-overlay :model-value="loading" contained persistent class="align-center justify-center">
				<v-progress-circular indeterminate color="primary" size="32" />
			</v-overlay>
			<div ref="sheetRef" class="w-100 h-100"></div>
		</div>
	</div>
</template>

<script>
	export default {
		name: 'so-gvcn-tab-so-lien-lac',
		props: {
			selectedLopID: { type: String, default: '__ALL__' },
			rows: { type: Array, default: () => [] },
			columns: { type: Array, default: () => [] },
			nestedHeaders: { type: Array, default: () => [] },
			sheetHeight: { type: String },
			soLienLacSheetHeight: { type: String },
			sheetKey: { type: [Number, String], default: 0 },
			readOnly: { type: Boolean, default: false },
			reasonReject: { type: String, default: '' },
			loading: { type: Boolean, default: false }
		},
		emits: ['update:rows'],
		data() {
			return {
				sheetInstance: null,
				timer: null,
				savedScrollTop: 0,
				savedScrollLeft: 0,
				savedElScrollTop: 0,
				savedElScrollLeft: 0,
				savedSelection: null,
				lastSelection: null,
				lastActiveCell: null,
				_savedParentScrolls: null
			}
		},
		methods: {
			getContentTableHeight(container, rowCount, nestedHeaderCount = 0) {
				const rowHeight = 28
				const naturalHeight = Math.max(96, (Math.max(1, Number(nestedHeaderCount) + 1) * rowHeight)
					+ (Math.max(1, Number(rowCount) || 0) * rowHeight) + 4)
				const viewportHeight = typeof soGvcnJspreadsheet === 'object'
					&& typeof soGvcnJspreadsheet.getTableHeight === 'function'
					? parseInt(soGvcnJspreadsheet.getTableHeight(container, '100%'), 10)
					: naturalHeight
				return `${Number.isFinite(viewportHeight) && viewportHeight > 0
					? Math.min(naturalHeight, viewportHeight)
					: naturalHeight}px`
			},
			getInstance() {
				const inst = this.sheetInstance
				return Array.isArray(inst) ? inst[0] : inst
			},
			scheduleInit() {
				if (this.timer) clearTimeout(this.timer)
				this.timer = setTimeout(() => this.initSheet(), 50)
			},
			getScrollElement() {
				const container = this.$refs.sheetRef
				if (!container) return null
				return container.querySelector('.jss_content, .jspreadsheet_content, .jexcel_content')
					|| container.querySelector('.jss_container, .jspreadsheet_container, .jexcel_container')
					|| container
			},
			// Double-click mở editor bằng focus() của JSpreadsheet; trình duyệt có thể tự cuộn
			// đến input/textarea vừa focus. Snapshot riêng các lớp scroll để trả bảng về đúng
			// vị trí người dùng đang xem mà không làm thay đổi selection hiện tại.
			captureScrollSnapshot() {
				const container = this.$refs.sheetRef
				if (!container) return []
				const snapshot = []
				const remember = (element) => {
					if (!element || snapshot.some(item => item.element === element)) return
					snapshot.push({
						element,
						top: element.scrollTop,
						left: element.scrollLeft
					})
				}
				remember(this.getScrollElement())
				remember(this.$el)
				let parent = container.parentElement
				while (parent && parent !== document.body) {
					remember(parent)
					parent = parent.parentElement
				}
				return snapshot
			},
			restoreScrollSnapshot(snapshot) {
				if (!Array.isArray(snapshot)) return
				snapshot.forEach(({ element, top, left }) => {
					try {
						element.scrollTop = top
						element.scrollLeft = left
					} catch (e) {}
				})
			},
			restoreDoubleClickEditor(container, snapshot) {
				const sheet = this.getInstance()
				if (!sheet || !sheet.edition || !container) return
				const editor = container.querySelector('td.editor input, td.editor textarea, td.editor [contenteditable="true"]')
				if (!editor) return
				// Focus lại với preventScroll để ô editor hiện ngay trong cell, không kéo viewport.
				try {
					editor.focus({ preventScroll: true })
				} catch (e) {
					try { editor.focus() } catch (focusError) {}
				}
				this.restoreScrollSnapshot(snapshot)
			},
			getSingleCellCopyText(worksheet, selection) {
				if (!Array.isArray(selection) || selection.length < 4) return undefined
				const x1 = Number(selection[0])
				const y1 = Number(selection[1])
				const x2 = Number(selection[2])
				const y2 = Number(selection[3])
				if (![x1, y1, x2, y2].every(Number.isFinite) || x1 !== x2 || y1 !== y2) return undefined

				const row = worksheet?.options?.data?.[y1] ?? this.rows?.[y1]
				const value = Array.isArray(row) ? row[x1] : row?.[x1]
				if (value == null) return ''
				if (typeof value === 'object') {
					for (const key of ['value', 'v', 'text', 'textContent', 'innerText', 'innerHTML', 'displayValue']) {
						const nested = value[key]
						if (nested !== null && nested !== undefined && typeof nested !== 'object') {
							const text = String(nested)
							return text === '[object Object]' ? '' : text
						}
					}
					return ''
				}
				const text = String(value)
				return text === '[object Object]' ? '' : text
			},
			handleEditorDoubleClick(event) {
				const container = this.$refs.sheetRef
				const target = event && event.target
				const cell = target && typeof target.closest === 'function'
					? target.closest('td[data-x][data-y]')
					: null
				if (!container || !cell || !container.contains(cell)) return

				const snapshot = this.captureScrollSnapshot()
				const restore = () => this.restoreDoubleClickEditor(container, snapshot)
				// Capture phase chạy trước handler mặc định của JSpreadsheet; các lần restore
				// sau đó chặn cả việc focus/layout muộn tiếp tục kéo scroll sang vị trí khác.
				if (typeof window !== 'undefined' && typeof window.requestAnimationFrame === 'function') {
					window.requestAnimationFrame(restore)
				}
				setTimeout(restore, 0)
				setTimeout(restore, 50)
				setTimeout(restore, 150)
			},
			saveCurrentState() {
				const container = this.$refs.sheetRef
				if (!container) return
				const contentEl = this.getScrollElement()
				if (contentEl) {
					if (contentEl.scrollTop > 0) this.savedScrollTop = contentEl.scrollTop
					if (contentEl.scrollLeft > 0) this.savedScrollLeft = contentEl.scrollLeft
				}
				if (this.$el && (this.$el.scrollTop > 0 || this.$el.scrollLeft > 0)) {
					this.savedElScrollTop = this.$el.scrollTop
					this.savedElScrollLeft = this.$el.scrollLeft
				}
				let p = container.parentElement
				this._savedParentScrolls = new Map()
				while (p && p !== document.body) {
					if (p.scrollTop > 0 || p.scrollLeft > 0) {
						this._savedParentScrolls.set(p, { top: p.scrollTop, left: p.scrollLeft })
					}
					p = p.parentElement
				}
				const sheet = this.getInstance()
				if (sheet) {
					if (typeof sheet.getSelection === 'function') {
						const sel = sheet.getSelection()
						if (sel && sel.length) this.lastSelection = sel
					} else if (sheet.selectedCell) {
						this.lastSelection = sheet.selectedCell
					}
				}
			},
			restoreState() {
				const container = this.$refs.sheetRef
				if (!container) return
				const contentEl = this.getScrollElement()
				if (contentEl && (this.savedScrollTop > 0 || this.savedScrollLeft > 0)) {
					contentEl.scrollTop = this.savedScrollTop
					contentEl.scrollLeft = this.savedScrollLeft
				}
				if (this.$el && (this.savedElScrollTop > 0 || this.savedElScrollLeft > 0)) {
					this.$el.scrollTop = this.savedElScrollTop
					this.$el.scrollLeft = this.savedElScrollLeft
				}
				if (this._savedParentScrolls) {
					this._savedParentScrolls.forEach((pos, el) => {
						try { el.scrollTop = pos.top; el.scrollLeft = pos.left } catch (e) {}
					})
				}
				const sheet = this.getInstance()
				const targetSelection = this.lastSelection || this.savedSelection
				if (sheet && targetSelection) {
					try {
						const x1 = targetSelection[0]
						const y1 = targetSelection[1]
						const x2 = targetSelection[2] !== undefined ? targetSelection[2] : x1
						const y2 = targetSelection[3] !== undefined ? targetSelection[3] : y1
						if (typeof sheet.updateSelectionFromCoords === 'function') {
							sheet.updateSelectionFromCoords(x1, y1, x2, y2)
						}
					} catch (e) {}
				}
			},
			attachRealtimeListeners(container) {
				if (!container) return
				if (!container._hasEditorDoubleClickListener) {
					container._editorDoubleClickHandler = this.handleEditorDoubleClick
					container._hasEditorDoubleClickListener = true
					container.addEventListener('dblclick', container._editorDoubleClickHandler, true)
				}
				const contentEl = this.getScrollElement()
				if (contentEl && !contentEl._hasScrollListener) {
					contentEl._hasScrollListener = true
					contentEl.addEventListener('scroll', () => {
						if (contentEl.scrollTop > 0 || contentEl.scrollLeft > 0) {
							this.savedScrollTop = contentEl.scrollTop
							this.savedScrollLeft = contentEl.scrollLeft
						}
					}, { passive: true })
				}
			},
			destroySheet() {
				if (this.sheetInstance) {
					try {
						const sheet = this.getInstance()
						if (sheet && typeof sheet.destroy === 'function') sheet.destroy()
					} catch (e) {}
					this.sheetInstance = null
				}
			},
			initSheet() {
				const container = this.$refs.sheetRef
				if (!container || this.selectedLopID === '__ALL__') {
					this.destroySheet()
					return
				}
				this.saveCurrentState()
				this.destroySheet()
				container.innerHTML = ''

				if (typeof jspreadsheet === 'function') {
					this.sheetInstance = soGvcnJspreadsheet.create(container, {
						worksheets: [{
							data: this.rows || [],
							columns: (this.columns || []).map(column => {
								const normalizedColumn = this.readOnly ? { ...column, readOnly: true } : column
								// JSpreadsheet chỉ nhận left/center/right ở thuộc tính align; CSS của riêng tab sẽ xử lý justify cho ô dữ liệu.
								return !normalizedColumn.readOnly && normalizedColumn.type !== 'numeric' && normalizedColumn.align !== 'center'
									? { ...normalizedColumn, align: 'left' }
									: normalizedColumn
							}),
							nestedHeaders: this.nestedHeaders || [],
							rowResize: true,
							columnDrag: false,
							tableWidth: '100%',
							tableOverflow: true,
							tableHeight: this.getContentTableHeight(container, (this.rows || []).length, (this.nestedHeaders || []).length),
							lazyLoading: false,
							freezeColumns: 4,
							wordWrap: true,
							allowInsertColumn: false,
							allowInsertRow: false,
							showHeader: true
						}],
						contextMenu: () => false,
						// JSpreadsheet đóng gói ô nhiều dòng theo định dạng TSV/CSV nên có thể
						// thêm dấu ngoặc kép khi copy trực tiếp. Với đúng một ô, trả về text gốc
						// để copy từ cell và copy sau khi double-click cho cùng một kết quả.
						oncopy: (worksheet, selection) => this.getSingleCellCopyText(worksheet, selection),
						onselection: (worksheet, x1, y1, x2, y2) => {
							this.lastSelection = [Number(x1), Number(y1), Number(x2 !== undefined ? x2 : x1), Number(y2 !== undefined ? y2 : y1)]
							this.lastActiveCell = { x: Number(x1), y: Number(y1) }
							const contentEl = container.querySelector('.jexcel_content, .jspreadsheet_content')
							if (contentEl && contentEl.scrollTop > 0) {
								this.savedScrollTop = contentEl.scrollTop
								this.savedScrollLeft = contentEl.scrollLeft
							}
						},
						onchange: (worksheet, cell, x, y, value) => {
							this.lastActiveCell = { x: Number(x), y: Number(y) }
							this.lastSelection = [Number(x), Number(y), Number(x), Number(y)]
							const contentEl = container.querySelector('.jexcel_content, .jspreadsheet_content')
							if (contentEl && contentEl.scrollTop > 0) {
								this.savedScrollTop = contentEl.scrollTop
								this.savedScrollLeft = contentEl.scrollLeft
							}
							if (Array.isArray(this.rows) && this.rows[y]) {
								this.rows[y][x] = value
								this.$emit('update:rows', this.rows)
							}
						}
					})

					this.$nextTick(() => {
						this.attachRealtimeListeners(container)
						this.restoreState()
						setTimeout(() => {
							this.attachRealtimeListeners(container)
							this.restoreState()
						}, 50)
						setTimeout(() => this.restoreState(), 150)
						setTimeout(() => this.restoreState(), 300)
					})
				}
			}
		},
		watch: {
			selectedLopID(newVal, oldVal) {
				if (newVal !== oldVal) {
					this.savedScrollTop = 0
					this.savedScrollLeft = 0
					this.savedElScrollTop = 0
					this.savedElScrollLeft = 0
					this.savedSelection = null
					this.lastSelection = null
					this.lastActiveCell = null
					this._savedParentScrolls = null
				}
				this.scheduleInit()
			},
			sheetKey() {
				this.scheduleInit()
			}
		},
		mounted() {
			this.scheduleInit()
		},
		beforeUnmount() {
			if (this.timer) clearTimeout(this.timer)
			const container = this.$refs.sheetRef
			if (container && container._editorDoubleClickHandler) {
				container.removeEventListener('dblclick', container._editorDoubleClickHandler, true)
				delete container._editorDoubleClickHandler
				delete container._hasEditorDoubleClickListener
			}
			this.destroySheet()
		}
	}
</script>