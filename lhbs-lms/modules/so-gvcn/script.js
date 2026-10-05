var soGvcnJspreadsheet = window.soGvcnJspreadsheet = {
    normalizeNestedHeaders(nestedHeaders, freezeCount) {
        if (!Array.isArray(nestedHeaders) || !freezeCount) return nestedHeaders || []
        return nestedHeaders.map((row) => {
            let columnIndex = 0
            const normalizedRow = []
                ; (row || []).forEach((header) => {
                    const colspan = Math.max(1, Number(header && header.colspan) || 1)
                    const nextColumnIndex = columnIndex + colspan
                    if (columnIndex < freezeCount && nextColumnIndex > freezeCount) {
                        const frozenColspan = freezeCount - columnIndex
                        const scrollingColspan = nextColumnIndex - freezeCount
                        normalizedRow.push({
                            ...header,
                            title: '',
                            colspan: frozenColspan
                        })
                        normalizedRow.push({
                            ...header,
                            colspan: scrollingColspan
                        })
                    } else {
                        normalizedRow.push({ ...header, colspan })
                    }
                    columnIndex = nextColumnIndex
                })
            return normalizedRow
        })
    },
    syncNestedHeaders(container, freezeCounts) {
        if (!container) return
        const tables = container.querySelectorAll('table.jss_worksheet')
        tables.forEach((table, tableIndex) => {
            const thead = table.querySelector('thead')
            const planTable = !!table.closest('.so-gvcn-plan-tab')
            if (thead) {
                thead.style.setProperty('position', 'sticky', 'important')
                thead.style.setProperty('top', '0px', 'important')
                thead.style.setProperty('z-index', '50', 'important')
                thead.style.setProperty('background-color', '#f5f5f5', 'important')
            }
            let stickyTop = 0
            Array.from(table.querySelectorAll('thead tr')).forEach((row, rowIndex) => {
                row.style.setProperty('position', planTable ? 'static' : 'sticky', 'important')
                row.style.setProperty('top', planTable ? 'auto' : `${stickyTop}px`, 'important')
                row.style.setProperty('z-index', `${33 - rowIndex}`, 'important')
                Array.from(row.children).forEach((cell) => {
                    cell.style.setProperty('position', planTable ? 'static' : 'sticky', 'important')
                    cell.style.setProperty('top', planTable ? 'auto' : `${stickyTop}px`, 'important')
                    cell.style.setProperty('z-index', `${33 - rowIndex}`, 'important')
                    cell.style.setProperty('background-color', '#f5f5f5', 'important')
                })
                stickyTop += row.getBoundingClientRect().height || row.offsetHeight || 28
            })
            const freezeCount = Number(freezeCounts[tableIndex] || freezeCounts[0]) || 0
            if (!freezeCount) return
            table.classList.add('so-gvcn-manual-freeze')
            const tableColumns = Array.from(table.querySelectorAll('colgroup col'))
            const dataColumnWidths = tableColumns
                .slice(1)
                .map(column => Number(column.getAttribute('width')) || column.getBoundingClientRect().width || 0)
            const frozenLeftByColumn = new Map()
            let frozenWidth = 0
            for (let columnIndex = 0; columnIndex < freezeCount; columnIndex += 1) {
                frozenLeftByColumn.set(columnIndex, frozenWidth)
                frozenWidth += dataColumnWidths[columnIndex] || 0
            }
            table.querySelectorAll('thead [data-x], tbody [data-x]').forEach((cell) => {
                const columnIndex = Number(cell.dataset.x)
                if (!Number.isFinite(columnIndex) || columnIndex >= freezeCount) return
                cell.classList.add('jss_freezed')
                cell.style.setProperty('--so-gvcn-freeze-left', `${frozenLeftByColumn.get(columnIndex) || 0}px`)
                cell.style.setProperty('position', 'sticky', 'important')
                cell.style.setProperty('z-index', cell.closest('thead') ? '42' : '22', 'important')
                cell.style.setProperty('background-color', cell.closest('thead') ? '#f5f5f5' : '#fff', 'important')
            })
            table.querySelectorAll('thead tr.jss_nested td[data-column], thead tr.jss_nested th[data-column]')
                .forEach((cell) => {
                    const columns = String(cell.dataset.column || '')
                        .split(',')
                        .map(Number)
                        .filter(Number.isFinite)
                    if (!columns.length || columns.some(columnIndex => columnIndex >= freezeCount)) return
                    cell.classList.add('jss_freezed')
                    cell.style.setProperty('--so-gvcn-freeze-left', `${frozenLeftByColumn.get(columns[0]) || 0}px`)
                    cell.style.setProperty('position', 'sticky', 'important')
                    cell.style.setProperty('z-index', '43', 'important')
                    cell.style.setProperty('background-color', '#f5f5f5', 'important')
                })
        })
    },
    installSpaceEditorFix() {
        if (window.__soGvcnJspreadsheetSpaceFixInstalled) return
        window.__soGvcnJspreadsheetSpaceFixInstalled = true
        document.addEventListener('keydown', (event) => {
            if (![' ', 'Spacebar'].includes(event.key) && event.code !== 'Space') return
            console.log('[so-gvcn][SpaceFix][1] nhận keydown Space', {
                key: event.key,
                code: event.code,
                target: event.target,
                targetTag: event.target?.tagName,
                targetClass: event.target?.className
            })
            if (event.altKey || event.ctrlKey || event.metaKey) return
            const target = event.target
            if (target?.tagName === 'TEXTAREA' || target?.tagName === 'INPUT' || target?.isContentEditable) {
                console.log('[so-gvcn][SpaceFix][2] bỏ qua vì đang nhập trong editor', target)
                return
            }
            let cell = target?.closest?.('td[data-x][data-y]')
            let sheetRoot = cell?.closest?.('.jss_container, .jexcel_container, .jspreadsheet_container')
            const worksheet = sheetRoot?.jssWorksheet || sheetRoot?.jspreadsheet || window.jspreadsheet?.current
            if (!cell && worksheet?.selectedCell) {
                const selectedX = Number(worksheet.selectedCell[0])
                const selectedY = Number(worksheet.selectedCell[1])
                cell = worksheet.records?.[selectedY]?.[selectedX]?.element
                    || worksheet.getCellFromCoords?.(selectedX, selectedY)
                sheetRoot = cell?.closest?.('.jss_container, .jexcel_container, .jspreadsheet_container')
                console.log('[so-gvcn][SpaceFix][2b] lấy cell từ worksheet.selectedCell', {
                    selectedCell: worksheet.selectedCell,
                    selectedX,
                    selectedY,
                    cell,
                    sheetRoot
                })
            }
            console.log('[so-gvcn][SpaceFix][2] tìm cell/worksheet', {
                cell,
                sheetRoot,
                worksheet,
                worksheetHasOpenEditor: typeof worksheet?.openEditor === 'function'
            })
            if (!cell || !worksheet || typeof worksheet.openEditor !== 'function') {
                console.warn('[so-gvcn][SpaceFix][STOP] không tìm thấy cell hoặc worksheet')
                return
            }
            const x = Number(cell.getAttribute('data-x'))
            const y = Number(cell.getAttribute('data-y'))
            console.log('[so-gvcn][SpaceFix][3] tọa độ cell', { x, y, cell })
            if (!Number.isFinite(x) || !Number.isFinite(y)) {
                console.warn('[so-gvcn][SpaceFix][STOP] tọa độ cell không hợp lệ')
                return
            }
            event.preventDefault()
            event.stopImmediatePropagation()
            console.log('[so-gvcn][SpaceFix][4] đã chặn hành vi mặc định của jspreadsheet')
            const currentValue = typeof worksheet.getValueFromCoords === 'function'
                ? worksheet.getValueFromCoords(x, y)
                : worksheet.options?.data?.[y]?.[x]
            const nextValue = `${currentValue == null ? '' : currentValue} `
            console.log('[so-gvcn][SpaceFix][5] giá trị cell', { currentValue, nextValue })
            if (typeof worksheet.setValueFromCoords === 'function') {
                worksheet.setValueFromCoords(x, y, nextValue, true)
                console.log('[so-gvcn][SpaceFix][6] đã setValueFromCoords', { x, y, nextValue })
            }
            worksheet.openEditor(cell, false, event)
            console.log('[so-gvcn][SpaceFix][7] đã openEditor với giá trị cũ')
            const editor = cell.querySelector('textarea, input')
            if (!editor) {
                console.warn('[so-gvcn][SpaceFix][STOP] không tìm thấy editor sau openEditor')
                return
            }
            editor.focus()
            editor.value = nextValue
            editor.selectionStart = editor.selectionEnd = editor.value.length
            editor.dispatchEvent(new Event('input', { bubbles: true }))
            console.log('[so-gvcn][SpaceFix][8] hoàn tất, editor giữ nội dung + Space', { editor, value: editor.value })
        }, true)
    },
    getTableHeight(container, requestedHeight) {
        if (!requestedHeight) return ''
        const normalizedHeight = String(requestedHeight).trim()
        if (!normalizedHeight || normalizedHeight === 'auto') return ''
        const followsViewport = normalizedHeight === '100%'
            || /^calc\(\s*100vh\b/i.test(normalizedHeight)
        if (!followsViewport) return normalizedHeight
        if (!container || typeof window === 'undefined') return normalizedHeight
        // Wrapper ngoài vẫn giữ 100%; chỉ cấp cho JSpreadsheet phần còn lại từ mép trên bảng đến đáy viewport.
        const rect = typeof container.getBoundingClientRect === 'function'
            ? container.getBoundingClientRect()
            : null
        const viewportHeight = window.innerHeight || document.documentElement?.clientHeight || 0
        const top = Math.max(0, Number(rect?.top) || 0)
        const bottomGap = 8
        const height = Math.floor(viewportHeight - top - bottomGap)
        return height > 0 ? `${height}px` : normalizedHeight
    },
    syncTableHeight(container, requestedHeight) {
        if (!container || !requestedHeight) return
        const tableHeight = this.getTableHeight(container, requestedHeight)
        if (!tableHeight || tableHeight === '100%') return
        // JSpreadsheet mới tạo các node này bên trong container; không ép height cứng để bảng tự ôm theo số dòng thực tế.
        container.querySelectorAll(
            '.jss_container, .jspreadsheet_container, .jexcel_container, .jss_content, .jspreadsheet_content, .jexcel_content'
        ).forEach((element) => {
            element.style.setProperty('max-height', tableHeight, 'important')
            element.style.setProperty('height', 'auto', 'important')
        })
    },
    create(container, options) {
        this.installSpaceEditorFix()
        const requestedTableHeight = (options.worksheets || []).find(worksheet => worksheet.tableHeight)?.tableHeight || ''
        const worksheets = (options.worksheets || []).map((worksheet) => {
            const freezeCount = Number(worksheet.freezeColumns) || 0
            const wsConfig = {
                ...worksheet,
                nestedHeaders: this.normalizeNestedHeaders(worksheet.nestedHeaders, freezeCount)
            }
            if (worksheet.tableHeight) {
                const computedH = this.getTableHeight(container, worksheet.tableHeight)
                if (computedH) {
                    wsConfig.tableHeight = computedH
                } else {
                    delete wsConfig.tableHeight
                }
            }
            return wsConfig
        })
        const originalOnload = options.onload
        const freezeCounts = worksheets.map(worksheet => Number(worksheet.freezeColumns) || 0)
        const syncLayout = () => {
            this.syncNestedHeaders(container, freezeCounts)
            if (requestedTableHeight) {
                this.syncTableHeight(container, requestedTableHeight)
            }
        }
        const instance = jspreadsheet(container, {
            ...options,
            worksheets,
            onload: (...args) => {
                syncLayout()
                window.requestAnimationFrame(syncLayout)
                if (typeof originalOnload === 'function') originalOnload(...args)
            }
        })
        // Khi tab hoặc viewport đổi kích thước, chỉ đồng bộ lại phần nội bộ của JSpreadsheet.
        if (typeof ResizeObserver === 'function' && container) {
            const observer = new ResizeObserver(syncLayout)
            observer.observe(container)
            const instances = Array.isArray(instance) ? instance : [instance]
            instances.forEach((sheet) => {
                if (!sheet || typeof sheet.destroy !== 'function') return
                const originalDestroy = sheet.destroy
                sheet.destroy = (...args) => {
                    observer.disconnect()
                    return originalDestroy.apply(sheet, args)
                }
            })
        }
        window.requestAnimationFrame(syncLayout)
        return instance
    }
}