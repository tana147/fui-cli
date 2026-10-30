<template>
	<Global>
        <template #header>
            <v-card>
                <v-card-title class="d-flex align-center">
                    {{ TitlePage }} • {{ TitleCap }}
                    <v-spacer />
                    <!-- Chỉ hiện ở cấp 1; người dùng chọn học kỳ trước khi khóa tất cả lớp/môn trong kỳ đó. -->
                    <v-btn v-if="Number(CapID) === 1" class="mr-2" color="warning" variant="outlined"
                        prepend-icon="mdi-lock" :loading="bulkLockLoading"
                        :disabled="bulkLockLoading || !vueData.NienKhoa"
                        @click="onLockWholeLevel">
                        {{ bulkLockLoading ? bulkLockPhase : 'Khóa cấp 1 theo kì' }}
                    </v-btn>
                    <v-btn variant="outlined" color="primary" prepend-icon="mdi-reload" @click="onRefresh">
                        Làm mới
                    </v-btn>
                </v-card-title>
            </v-card>
        </template>

        <v-divider />

        <div class="khoa-cot-diem-layout">
            <aside class="khoa-cot-diem-tree-panel">
                <div class="pa-3">
                    <div class="text-subtitle-1 font-weight-bold">Danh sách khối, lớp, môn</div>
                    <div class="text-caption text-medium-emphasis">Chọn môn để xem các cột điểm</div>
                    <v-text-field v-model="subjectSearchInput" class="mt-3" label="Tìm môn học"
                        prepend-inner-icon="mdi-magnify" density="compact" variant="outlined" hide-details
                        clearable @click:clear="onSearchClear" @update:model-value="onSearchInput" />
                </div>
                <v-divider />

                <!-- Kết quả tìm kiếm dạng danh sách gọn (dùng v-show để giữ DOM, tránh hủy & mount lại treeview gây giật lag) -->
                <v-list v-show="subjectSearchKeyword.trim()" density="compact" nav class="pa-2 overflow-y-auto" style="max-height: calc(100% - 130px);">
                    <template v-if="searchedSubjectList.length">
                        <v-list-item v-for="item in searchedSubjectList" :key="item.id"
                            :title="item.title" :subtitle="item.subtitle"
                            :active="selectedSubjectNodeId === item.id"
                            color="primary" class="mb-1 rounded"
                            @click="onSelectSearchedSubject(item)">
                            <template #prepend>
                                <v-icon size="small" color="primary">mdi-book-education-outline</v-icon>
                            </template>
                        </v-list-item>
                    </template>
                    <div v-else class="pa-4 text-caption text-medium-emphasis text-center">
                        Không tìm thấy môn học phù hợp
                    </div>
                </v-list>

                <!-- Cây Khối - Lớp - Môn: dùng v-show để cây treeview luôn tồn tại trong DOM, khi clear search chuyển đổi tức thì không gián đoạn -->
                <div v-show="!subjectSearchKeyword.trim()" class="overflow-y-auto" style="max-height: calc(100% - 130px);">
                    <v-treeview v-if="treeNodes.length" v-model:opened="openedTreeNodeIDs"
                        v-model:selected="selectedTreeNodeIDs" :items="treeNodes" item-title="title"
                        item-value="id" item-children="children" selectable select-strategy="independent"
                        activatable density="compact" color="primary" class="pa-2"
                        @update:activated="onTreeActivated" />
                    <div v-else class="pa-4 text-caption text-medium-emphasis">
                        Đang tải danh sách khối, lớp, môn...
                    </div>
                </div>
            </aside>

            <main class="khoa-cot-diem-table-panel">
                <div class="pa-3 d-flex align-center flex-wrap ga-3">
                    <div>
                        <div class="text-subtitle-1 font-weight-bold">
                            {{ selectedSubjectTitle || 'Danh sách cột điểm' }}
                        </div>
                        <div class="text-caption text-medium-emphasis">
                            {{ selectedSubjectContext || 'Vui lòng chọn môn học trên cây' }}
                        </div>
                    </div>
                    <v-spacer />
                    <v-select v-model="MaNhomCotDiemItem" label="Nhóm cột điểm" :items="DSMaNhomCotDiem"
                        item-title="TenNhomCotDiemDisplay" item-value="MaNhomCotDiem" :disabled="!MonHocItem"
                        return-object density="compact" hide-details style="max-width: 230px" />
                </div>
                <v-divider />

                <v-card-text class="py-2 d-flex align-center ga-2 flex-wrap">
            <v-chip v-if="selectedStatusFilter !== null" size="small" color="info" variant="tonal">
                Đang lọc: {{ selectedStatusFilter ? 'Đã khóa' : 'Chưa khóa' }}
            </v-chip>

            <v-chip v-if="hasMixedSelectedStatus" size="small" color="warning" variant="tonal">
                Đang chọn lẫn Đã khóa/Chưa khóa
            </v-chip>

            <v-btn v-if="canShowLockButton" size="small" color="success" variant="outlined"
                :disabled="selectedUnlockedCount === 0 || hasMixedSelectedStatus"
                @click="onLockSelected">
                <v-icon start>mdi-lock</v-icon>
                Khóa đã chọn ({{ selectedUnlockedCount }})
            </v-btn>

            <v-btn v-if="canShowUnlockButton" size="small" color="warning" variant="outlined"
                :disabled="selectedLockedCount === 0 || hasMixedSelectedStatus"
                @click="onOpenUnlockSelected">
                <v-icon start>mdi-lock-open</v-icon>
                Mở khóa đã chọn ({{ selectedLockedCount }})
            </v-btn>

            <v-btn v-if="selectedStatusFilter !== null" size="small" color="primary" variant="text"
                @click="clearSelectionFilter">
                Hiện tất cả
            </v-btn>
                </v-card-text>

                <v-divider />

                <v-data-table v-model="DSSelected" :headers="headers" :items="DSView" :row-props="getRowProps"
            :loading="loadingTable" loading-text="Đang tải danh sách cột điểm..."
            item-selectable="IsSelectable" item-value="RowKey" :show-select="true"
            items-per-page="-1" hide-default-footer hover style="max-height: calc(100dvh - 77px); overflow-y: auto;">
            <template #item.actions="{ item }">
                <v-btn size="small" :color="item.IsLocked ? 'warning' : 'success'" variant="outlined"
                    @click="onClickToggle(item)">
                    <v-icon start>{{ item.IsLocked ? 'mdi-lock-open' : 'mdi-lock' }}</v-icon>
                    {{ item.IsLocked ? 'Mở khóa' : 'Khóa' }}
                </v-btn>
            </template>

            <template #item.TenTinhTrang="{ item }">
                <v-chip size="x-small" :color="item.MauTinhTrang || 'default'" variant="tonal">
                    {{ item.TenTinhTrang || 'Chưa cập nhật' }}
                </v-chip>
            </template>

            <template #no-data>

                <div class="d-flex flex-column align-center justify-center py-12 text-medium-emphasis">
                    <v-icon size="48" class="mb-3 opacity-40">mdi-table-search</v-icon>
                    <p class="text-body-2">Chọn môn học để xem danh sách cột điểm</p>
                </div>
            </template>
                </v-data-table>
            </main>
        </div>

        <uc-dialog v-model="dialogKhoa.show" title="Xác nhận mở khóa" done-text="Xác nhận"
            @onSubmit="onConfirmMoKhoa">
            <v-textarea v-model="dialogKhoa.LyDo" label="Lý do mở khóa" rows="3" auto-grow
                placeholder="Nhập lý do mở khóa cột điểm..." />
        </uc-dialog>

        <uc-dialog v-model="dialogMoKhoaSelected.show" title="Mở khóa cột điểm đã chọn" done-text="Xác nhận"
            @onSubmit="onConfirmMoKhoaSelected">
            <v-textarea v-model="dialogMoKhoaSelected.LyDo" label="Lý do mở khóa" rows="3" auto-grow
                placeholder="Nhập lý do mở khóa các cột điểm đã chọn..." />
        </uc-dialog>
        <!-- Mỗi lần chỉ khóa một trong bốn kỳ đánh giá, trên toàn bộ lớp/môn cấp 1. -->
        <v-dialog v-model="bulkLockPeriodDialog" max-width="460">
            <v-card>
                <v-card-title class="text-subtitle-1 font-weight-bold">Khóa cột điểm cấp 1 theo từng kỳ</v-card-title>
                <v-card-text>
                    <div class="text-body-2 mb-3">Chọn một kỳ cần khóa trong niên khóa {{ vueData.NienKhoa }}.</div>
                    <v-radio-group v-model="bulkLockSelectedPeriod" hide-details>
                        <v-radio v-for="item in bulkLockPeriodOptions" :key="item.value"
                            :label="item.title" :value="item.value" />
                    </v-radio-group>
                </v-card-text>
                <v-card-actions>
                    <v-spacer />
                    <v-btn variant="text" @click="bulkLockPeriodDialog = false">Đóng</v-btn>
                    <v-btn color="primary" :disabled="!bulkLockSelectedPeriod" @click="onConfirmBulkLockPeriod">
                        Tiếp tục
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <!-- Giữ tiến trình trên màn hình sau khi xác nhận để người dùng theo dõi từng giai đoạn xử lý. -->
        <v-dialog v-model="bulkLockProgressVisible" max-width="440" persistent>
            <v-card class="pa-5">
                <div class="d-flex align-center">
                    <v-progress-circular indeterminate color="primary" size="28" width="3" class="mr-3" />
                    <div class="text-subtitle-1 font-weight-bold">Đang khóa cột điểm cấp 1</div>
                </div>
                <div class="text-body-2 mt-4">{{ bulkLockPhase }}</div>
                <v-progress-linear :model-value="bulkLockProgressPercent" color="primary" rounded height="8"
                    class="mt-2" />
                <div class="d-flex justify-space-between text-caption text-medium-emphasis mt-2">
                    <span>{{ bulkLockProgressDetail }}</span>
                    <span>{{ bulkLockProgressPercent }}%</span>
                </div>
            </v-card>
        </v-dialog>
    </Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
    data() {
        return {
            vueData,
            CapID: vueData.CapID,
            treeNodes: [],
            openedTreeNodeIDs: [],
            selectedTreeNodeIDs: [],
            subjectSearchInput: '',
            subjectSearchKeyword: '',
            searchDebounceTimer: null,
            selectedSubjectNodeId: null,
            loadingTable: false,
            bulkLockLoading: false,
            bulkLockPhase: '',
            bulkLockPeriodDialog: false,
            bulkLockSelectedPeriod: null,
            bulkLockPeriodOptions: [
                { title: 'GKHK1 · GK_HK1', value: 'GKHK1' },
                { title: 'CKHK1 · CK_HK1', value: 'CKHK1' },
                { title: 'GKHK2 · GK_HK2', value: 'GKHK2' },
                { title: 'CKHK2 · CK_HK2', value: 'CKHK2' },
            ],
            bulkLockProgressVisible: false,
            bulkLockProgressPercent: 0,
            bulkLockProgressDetail: '',
            treeSubjectMap: {},
            DSLop: [],
            LopItem: null,
            DSMonHoc: [],
            MonHocItem: null,
            DSMaNhomCotDiem: [],
            MaNhomCotDiemItem: null,
            DS: [],
            DSSelected: [],
            dialogKhoa: { show: false, item: null, LyDo: '' },
            dialogMoKhoaSelected: { show: false, LyDo: '' },
            headers: [
                { title: 'STT', key: 'STT', width: 60 },
                { title: 'Mã cột điểm', key: 'MaCotDiemDisplay', minWidth: 160 },
                { title: 'Tên cột điểm', key: 'TenCotDiem_VI', minWidth: 220 },
                { title: 'Tình trạng', key: 'TenTinhTrang', minWidth: 120, sortable: false },
                { title: 'Thao tác', key: 'actions', width: 130, sortable: false },
            ],
        }
    },
    computed: {
        TitleCap() { return renderText(parseInt(this.CapID)) },
        TitlePage() { return getTitlePageByURL(window.location.pathname + window.location.search) },
        HocKi() { return vueData.NienKhoaItem?.HocKi },
        HocKiCode() { return this.HocKi === 1 ? 'HK1' : 'HK2' },
        selectedSubjectTitle() {
            return this.MonHocItem?.TenMonHoc || this.MonHocItem?.TenMonHoc_HienThi || ''
        },
        selectedSubjectContext() {
            if (!this.LopItem || !this.MonHocItem) return ''
            return `${this.LopItem.TenLop || ''} • ${this.LopItem.TenKhoiHoc || ''}`
        },
        // Danh sách phẳng tất cả môn học để tìm kiếm tức thì mà không cần duyệt & render lại toàn bộ cây DOM
        allSubjectFlatList() {
            const list = []
            for (const khoi of this.treeNodes) {
                for (const lop of khoi.children || []) {
                    for (const mon of lop.children || []) {
                        list.push({
                            id: mon.id,
                            title: mon.title,
                            subtitle: `${lop.title} • ${khoi.title}`,
                            Lop: mon.Lop,
                            MonHoc: mon.MonHoc,
                            searchStr: this.normalizeSearchText(`${mon.title} ${lop.title} ${khoi.title}`),
                        })
                    }
                }
            }
            return list
        },
        // Danh sách môn tìm kiếm giới hạn tối đa 50 kết quả để giao diện phản hồi tức thì
        searchedSubjectList() {
            const keyword = this.normalizeSearchText(this.subjectSearchKeyword)
            if (!keyword) return []
            const results = []
            for (const item of this.allSubjectFlatList) {
                if (item.searchStr.includes(keyword)) {
                    results.push(item)
                    if (results.length >= 60) break // Cắt ngưỡng tránh render quá nhiều DOM
                }
            }
            return results
        },
        selectedRows() {
            if (!this.DSSelected?.length) return []
            const selectedKeys = new Set(
                this.DSSelected
                    .map(x => (typeof x === 'string' ? x : x?.RowKey))
                    .filter(Boolean)
            )
            return this.DS.filter(x => selectedKeys.has(x.RowKey))
        },
        selectedStatusFilter() {
            if (!this.selectedRows.length) return null
            const firstStatus = !!this.selectedRows[0].IsLocked
            const sameStatus = this.selectedRows.every(x => !!x.IsLocked === firstStatus)
            return sameStatus ? firstStatus : null
        },
        DSView() {
            if (this.selectedStatusFilter === null) {
                return this.DS.map(x => ({ ...x, IsSelectable: true }))
            }
            return this.DS.map(x => ({
                ...x,
                IsSelectable: !!x.IsLocked === this.selectedStatusFilter,
            }))
        },
        selectedLockedCount() {
            return this.selectedRows.filter(x => !!x.IsLocked).length
        },
        selectedUnlockedCount() {
            return this.selectedRows.filter(x => !x.IsLocked).length
        },
        hasMixedSelectedStatus() {
            if (this.selectedRows.length <= 1) return false
            return this.selectedLockedCount > 0 && this.selectedUnlockedCount > 0
        },
        canShowLockButton() {
            if (this.hasMixedSelectedStatus) return false
            return this.selectedStatusFilter !== true
        },
        canShowUnlockButton() {
            if (this.hasMixedSelectedStatus) return false
            return this.selectedStatusFilter !== false
        },
    },
    watch: {
        MaNhomCotDiemItem(v) {
            this.DS = []
            if (v) this.getDS()
        },
        HocKi() {
            this.MaNhomCotDiemItem = null
            this.DSMaNhomCotDiem = []
            this.DS = []
            this.MonHocItem = null
            this.LopItem = null
            this.selectedTreeNodeIDs = []
            this.getAllLop()
        },
        DS() {
            this.DSSelected = []
        },
    },
    mounted() {
        this.getAllLop()
    },
    methods: {
        normalizeMaCotDiem(maCotDiem) {
            if (typeof maCotDiem !== 'string') return maCotDiem
            const splitIndex = maCotDiem.indexOf('_')
            if (splitIndex <= 0) return maCotDiem
            const prefix = maCotDiem.slice(0, splitIndex)
            return /^\d+$/.test(prefix) ? maCotDiem.slice(splitIndex + 1) : maCotDiem
        },
        hasNumericPrefix(maCotDiem) {
            if (typeof maCotDiem !== 'string') return false
            const splitIndex = maCotDiem.indexOf('_')
            if (splitIndex <= 0) return false
            const prefix = maCotDiem.slice(0, splitIndex)
            return /^\d+$/.test(prefix)
        },
        getKhoaKey(monHocLopID, maCotDiem) {
            const monHocLopIDNum = Number(monHocLopID || 0)
            return `${monHocLopIDNum}__${this.normalizeMaCotDiem(maCotDiem || '')}`
        },
        // TAPI có thể trả bit dạng số hoặc chuỗi; xử lý "0" rõ ràng để không coi nó là true.
        isLockedFlag(value) {
            if (typeof value === 'string') {
                return !['', '0', 'false', 'no', 'n', 'null', 'undefined'].includes(value.trim().toLowerCase())
            }
            return !!value
        },
        isEnabledScoreColumn(column) {
            if (!column || column.Enable === undefined || column.Enable === null || column.Enable === '') return true
            return !['0', 'false', 'no', 'n', 'disabled'].includes(String(column.Enable).trim().toLowerCase())
        },
        // Một số API trả danh sách phẳng, một số trả nhiều result set; gom các dòng object để dùng chung an toàn.
        getBulkRows(response) {
            const payload = response?.data ?? response ?? []
            const rows = []
            const visit = value => {
                if (Array.isArray(value)) {
                    value.forEach(visit)
                } else if (value && typeof value === 'object') {
                    rows.push(value)
                }
            }
            visit(payload)
            return rows
        },
        pickKhoaInfo(current, next) {
            if (!current) return next
            const nextID = Number(next.KhoaCotDiemID || 0)
            const currentID = Number(current.KhoaCotDiemID || 0)
            // Dùng bản ghi mới nhất; nếu cùng ID thì giữ trạng thái đã khóa để tránh bỏ sót giữa các nhóm.
            if (nextID > currentID || (nextID === currentID && next.TinhTrang && !current.TinhTrang)) {
                return next
            }
            return current
        },
        async getAllLop() {
            const resKhoi = await fetchPromise('lms/KhoiHocByCapHoc_Get', {
                CapID: this.CapID,
                HocKi: this.HocKi,
                NienKhoa: vueData.NienKhoa,
            })
            const dsKhoi = resKhoi.data ?? resKhoi ?? []
            if (!dsKhoi.length) return
            const batch = dsKhoi.map(khoi => ({
                url: 'lms/Lop_Get_ByKhoiID',
                params: { NienKhoa: vueData.NienKhoa, HocKi: this.HocKi, KhoiID: khoi.KhoiID },
            }))
            const results = await fetchBatchPromise(batch)
            const dsLop = []
            const lopByKhoi = {}
            results.forEach((res, idx) => {
                const lops = res.data ?? res ?? []
                const khoi = dsKhoi[idx]
                lopByKhoi[khoi.KhoiID] = []
                lops.forEach(lop => dsLop.push({
                    ...lop,
                    TenLopDisplay: `${lop.TenLop} (${khoi.TenKhoiHoc})`,
                    TenKhoiHoc: khoi.TenKhoiHoc,
                    KhoiID: khoi.KhoiID,
                }))
                lopByKhoi[khoi.KhoiID] = dsLop.filter(x => x.KhoiID === khoi.KhoiID)
            })
            this.DSLop = dsLop

            const monResults = await fetchBatchPromise(dsLop.map(lop => ({
                url: 'lms/MonHoc_Get_ByLopID_BoMon',
                params: { LopID: lop.LopID, NienKhoa: vueData.NienKhoa, HocKi: this.HocKi },
            })))
            const subjectMap = {}
            monResults.forEach((res, index) => {
                const lop = dsLop[index]
                const dsMon = res.data ?? res ?? []
                subjectMap[lop.LopID] = dsMon.map(mon => ({
                    ...mon,
                    TenMonHoc: mon.TenMonHoc_HienThi || mon.TenMonHoc || '',
                    Lop: lop,
                }))
            })
            this.treeSubjectMap = subjectMap
            this.treeNodes = dsKhoi.map(khoi => ({
                id: `khoi-${khoi.KhoiID}`,
                title: khoi.TenKhoiHoc,
                type: 'khoi',
                children: (lopByKhoi[khoi.KhoiID] || []).map(lop => ({
                    id: `lop-${lop.LopID}`,
                    title: lop.TenLop,
                    type: 'lop',
                    children: (subjectMap[lop.LopID] || []).map(mon => ({
                        id: `mon-${lop.LopID}-${mon.MonHocID}`,
                        title: mon.TenMonHoc,
                        type: 'mon',
                        Lop: lop,
                        MonHoc: mon,
                    })),
                })),
            }))
            // Ban đầu chỉ mở khối để người dùng thấy danh sách lớp mà không bung toàn bộ môn học.
            this.openedTreeNodeIDs = this.getDefaultOpenedTreeIDs(this.treeNodes)
        },
        getDefaultOpenedTreeIDs(nodes) {
            const ids = []
            const walk = (list, level) => (list || []).forEach(node => {
                if (node.children?.length) {
                    if (level === 0) ids.push(node.id)
                    walk(node.children, level + 1)
                }
            })
            walk(nodes, 0)
            return ids
        },
        getSearchOpenedTreeIDs(nodes) {
            const ids = []
            ;(nodes || []).forEach(khoi => {
                ids.push(khoi.id)
                ;(khoi.children || []).forEach(lop => ids.push(lop.id))
            })
            return ids
        },
        normalizeSearchText(value) {
            return String(value || '')
                .normalize('NFD')
                .replace(/[\u0300-\u036f]/g, '')
                .replace(/đ/g, 'd')
                .toLowerCase()
                .trim()
        },
        // Khi xóa tìm kiếm (nút clear), phản hồi tức thì về cây treeview không delay
        onSearchClear() {
            if (this.searchDebounceTimer) {
                clearTimeout(this.searchDebounceTimer)
            }
            this.subjectSearchInput = ''
            this.subjectSearchKeyword = ''
        },
        // Debounce 250ms khi gõ tìm kiếm để không lag giao diện; nếu rỗng thì clear ngay lập tức
        onSearchInput(value) {
            if (this.searchDebounceTimer) {
                clearTimeout(this.searchDebounceTimer)
            }
            if (!value || !value.trim()) {
                this.subjectSearchKeyword = ''
                return
            }
            this.searchDebounceTimer = setTimeout(() => {
                this.subjectSearchKeyword = value || ''
            }, 250)
        },
        // Chọn môn học trực tiếp từ kết quả tìm kiếm mà không cần mở cây DOM nặng
        onSelectSearchedSubject(item) {
            this.selectedSubjectNodeId = item.id
            this.LopItem = item.Lop
            this.MonHocItem = item.MonHoc
            this.DSMonHoc = this.treeSubjectMap[item.Lop?.LopID] || []
            this.MaNhomCotDiemItem = null
            this.DSMaNhomCotDiem = []
            this.DS = []
            this.getMaNhomCotDiem()
        },
        onTreeActivated(ids) {
            const activeID = ids?.[ids.length - 1]
            if (!activeID) return
            const findNode = nodes => {
                for (const node of nodes || []) {
                    if (node.id === activeID) return node
                    const found = findNode(node.children)
                    if (found) return found
                }
                return null
            }
            const node = findNode(this.treeNodes)
            if (node?.type !== 'mon') return
            this.selectedSubjectNodeId = node.id
            this.LopItem = node.Lop
            this.MonHocItem = node.MonHoc
            this.DSMonHoc = this.treeSubjectMap[node.Lop.LopID] || []
            this.MaNhomCotDiemItem = null
            this.DSMaNhomCotDiem = []
            this.DS = []
            this.getMaNhomCotDiem()
        },
        async getMonHoc() {
            if (!this.LopItem) return
            const res = await fetchPromise('lms/MonHoc_Get_ByLopID_BoMon', {
                LopID: this.LopItem.LopID,
                NienKhoa: vueData.NienKhoa,
                HocKi: this.HocKi,
            })
            const dsMonHoc = res.data ?? res ?? []
            this.DSMonHoc = dsMonHoc.map(x => ({
                ...x,
                TenMonHoc: x.TenMonHoc_HienThi || x.TenMonHoc || '',
            }))
            if (this.DSMonHoc.length === 1) this.MonHocItem = this.DSMonHoc[0]
        },
        async getMaNhomCotDiem() {
            if (!this.MonHocItem) return
            const res = await fetchPromise('lms/NhomCauTrucDiem_Get_ByTemplateBangDiemID', {
                TemplateBangDiemID: this.MonHocItem.TemplateBangDiemID,
            })
            const dsNhom = res.data ?? res ?? []
            this.DSMaNhomCotDiem = dsNhom
                .filter(x => x.Semester === this.HocKiCode)
                .map(x => ({
                    ...x,
                    TenNhomCotDiemDisplay: x.TenNhomCotDiem_VI || x.MaNhomCotDiem,
                }))
            if (this.DSMaNhomCotDiem.length === 1) this.MaNhomCotDiemItem = this.DSMaNhomCotDiem[0]
        },
        async getDS() {
            if (!this.LopItem || !this.MonHocItem || !this.MaNhomCotDiemItem) {
                this.DS = []
                return
            }
            this.loadingTable = true
            try {
                const [resBangDiem, resKhoaCotDiem] = await Promise.all([
                    fetchPromise('lms/HocSinhBangDiem_Get_ByMonHocID_MaNhom', {
                        LopID: this.LopItem.LopID,
                        MonHocID: this.MonHocItem.MonHocID,
                        TemplateBangDiemID: this.MonHocItem.TemplateBangDiemID,
                        MaNhomCotDiem: this.MaNhomCotDiemItem.MaNhomCotDiem,
                        ThuTuNhom: this.MaNhomCotDiemItem.ThuTuNhom,
                        Semester: this.MaNhomCotDiemItem.Semester,
                        NienKhoa: vueData.NienKhoa,
                        KhoiID: this.LopItem.KhoiID,
                    }, { cache: false }),
                    fetchPromise('lms/KhoaCotDiem_Get', {
                        LopID: this.LopItem.LopID,
                        MonHocLopID: this.MonHocItem.MonHocLopID,
                        MaNhomCotDiem: this.MaNhomCotDiemItem.MaNhomCotDiem,
                        Semester: this.MaNhomCotDiemItem.Semester,
                        NienKhoa: vueData.NienKhoa,
                    }, { cache: false }),
                ])

                const dsBangDiem = resBangDiem.data ?? resBangDiem ?? []
                const dsKhoaCotDiem = resKhoaCotDiem.data ?? resKhoaCotDiem ?? []

                const firstHocSinhID = dsBangDiem[0]?.HocSinhID
                const dsCotDiemTheoNhom = firstHocSinhID
                    ? dsBangDiem.filter(x => x.HocSinhID === firstHocSinhID)
                    : []

                const khoaMap = dsKhoaCotDiem.reduce((acc, item) => {
                    const key = this.getKhoaKey(item.MonHocLopID, item.MaCotDiem)
                    const nextInfo = {
                        TinhTrang: this.isLockedFlag(item.TinhTrang),
                        KhoaCotDiemID: Number(item.KhoaCotDiemID || 0),
                    }
                    acc[key] = this.pickKhoaInfo(acc[key], nextInfo)
                    return acc
                }, {})

                const monHocLopByDisplayMap = dsKhoaCotDiem.reduce((acc, item) => {
                    const maCotDiemDisplay = item.MaCotDiem || ''
                    if (!maCotDiemDisplay) return acc
                    const next = {
                        MonHocLopID: Number(item.MonHocLopID || 0),
                        KhoaCotDiemID: Number(item.KhoaCotDiemID || 0),
                    }
                    const current = acc[maCotDiemDisplay]
                    if (!current || next.KhoaCotDiemID >= current.KhoaCotDiemID) {
                        acc[maCotDiemDisplay] = next
                    }
                    return acc
                }, {})

                this.DS = dsCotDiemTheoNhom.map((cotDiem, index) => {
                    const maCotDiemDisplay = cotDiem.MaCotDiem || ''
                    const inferredMonHocLopID = monHocLopByDisplayMap[maCotDiemDisplay]?.MonHocLopID || 0
                    const rowMonHocLopID = Number(cotDiem.MonHocLopID || 0)
                    const monHocLopID = this.hasNumericPrefix(maCotDiemDisplay)
                        ? Number(inferredMonHocLopID || rowMonHocLopID || this.MonHocItem.MonHocLopID || 0)
                        : Number(rowMonHocLopID || inferredMonHocLopID || this.MonHocItem.MonHocLopID || 0)
                    const maCotDiemSave = this.normalizeMaCotDiem(maCotDiemDisplay)
                    const khoaInfo = khoaMap[this.getKhoaKey(monHocLopID, maCotDiemDisplay)] || {}
                    const isLocked = this.isLockedFlag(khoaInfo.TinhTrang)
                    return {
                        RowKey: `${monHocLopID}_${maCotDiemDisplay}_${index}`,
                        STT: index + 1,
                        MonHocLopID: monHocLopID,
                        MaCotDiemDisplay: maCotDiemDisplay,
                        MaCotDiemSave: maCotDiemSave,
                        TenCotDiem_VI: cotDiem.TenCotDiem_VI || maCotDiemDisplay,
                        KhoaCotDiemID: khoaInfo.KhoaCotDiemID || null,
                        IsLocked: isLocked,
                        TenTinhTrang: isLocked ? 'Đã khóa' : 'Chưa khóa',
                        MauTinhTrang: isLocked ? 'success' : 'warning',
                    }
                })
            } catch (error) {
                this.DS = []
            } finally {
                this.loadingTable = false
            }
        },
        _confirm() {
            return this.confirmRef?.value
        },
        clearSelectionFilter() {
            this.DSSelected = []
        },
        getRowProps(ctx) {
            const row = ctx?.item?.raw || ctx?.item || {}
            if (this.selectedStatusFilter === null) return {}
            const isDimmed = !!row.IsLocked !== this.selectedStatusFilter
            return isDimmed ? { class: 'row-dimmed' } : {}
        },
        // Mỗi mã nhóm tương ứng một kỳ đánh giá; chỉ tải học kỳ chứa kỳ được chọn.
        getBulkLockPeriodConfig(value) {
            const groupCode = String(value || '')
            const periodByGroupCode = {
                GKHK1: { Value: 1, Code: 'HK1', ColumnSuffix: 'GK_HK1' },
                CKHK1: { Value: 1, Code: 'HK1', ColumnSuffix: 'CK_HK1' },
                GKHK2: { Value: 2, Code: 'HK2', ColumnSuffix: 'GK_HK2' },
                CKHK2: { Value: 2, Code: 'HK2', ColumnSuffix: 'CK_HK2' },
            }
            const period = periodByGroupCode[groupCode]
            return period ? { ...period, GroupCode: groupCode } : null
        },
        // Nhóm cấu hình và mã cột là hai mã riêng; kỳ được chọn khớp theo suffix của MaCotDiem.
        isBulkLockColumnForPeriod(maCotDiem, period) {
            const code = String(maCotDiem || '').trim().toUpperCase()
            const suffix = String(period?.ColumnSuffix || '').trim().toUpperCase()
            return !!suffix && code.endsWith(suffix)
        },
        setBulkLockProgress(phase, completed, total) {
            const safeTotal = Math.max(0, Number(total || 0))
            const safeCompleted = Math.min(safeTotal, Math.max(0, Number(completed || 0)))
            this.bulkLockPhase = phase
            this.bulkLockProgressPercent = safeTotal ? Math.round((safeCompleted / safeTotal) * 100) : 0
            this.bulkLockProgressDetail = safeTotal ? `${safeCompleted}/${safeTotal} yêu cầu` : 'Đang chuẩn bị'
        },
        async fetchBulkRequests(requests, phase) {
            const results = []
            const batchSize = 20
            let completed = 0
            this.setBulkLockProgress(phase, 0, requests.length)
            for (let start = 0; start < requests.length; start += batchSize) {
                const batch = requests.slice(start, start + batchSize)
                const batchResults = await Promise.allSettled(batch.map(async request => {
                    try {
                        return await fetchPromise(request.url, request.params, { cache: false })
                    } finally {
                        completed++
                        this.setBulkLockProgress(phase, completed, requests.length)
                    }
                }))
                const failed = batchResults.find(result => result.status === 'rejected')
                if (failed) throw failed.reason
                results.push(...batchResults.map(result => result.value))
            }
            return results
        },
        // Cây bên trái chỉ tải học kỳ đang mở; thao tác toàn cấp tự tải đủ lớp/môn cho kỳ người dùng chọn.
        async collectCap1LockTargets(groupCode) {
            const period = this.getBulkLockPeriodConfig(groupCode)
            if (!period) throw new Error('Vui lòng chọn kỳ đánh giá')
            const subjectEntries = []
            const seenSubjects = new Set()
            const templateIDs = new Map()
            let skippedSubjects = 0

            this.setBulkLockProgress(`Đang tải khối ${period.Code}`, 0, 1)
            const resKhoi = await fetchPromise('lms/KhoiHocByCapHoc_Get', {
                CapID: 1,
                HocKi: period.Value,
                NienKhoa: vueData.NienKhoa,
            })
            this.setBulkLockProgress(`Đang tải khối ${period.Code}`, 1, 1)
            const dsKhoi = this.getBulkRows(resKhoi)
            const classResponses = await this.fetchBulkRequests(dsKhoi.map(khoi => ({
                url: 'lms/Lop_Get_ByKhoiID',
                params: { NienKhoa: vueData.NienKhoa, HocKi: period.Value, KhoiID: khoi.KhoiID },
            })), `Đang tải lớp ${period.Code}`)
            const classEntries = []
            dsKhoi.forEach((khoi, index) => {
                this.getBulkRows(classResponses[index]).forEach(lop => {
                    classEntries.push({
                        Lop: {
                            ...lop,
                            TenLopDisplay: `${lop.TenLop} (${khoi.TenKhoiHoc})`,
                            TenKhoiHoc: khoi.TenKhoiHoc,
                            KhoiID: khoi.KhoiID,
                        },
                    })
                })
            })

            const subjectResponses = await this.fetchBulkRequests(classEntries.map(({ Lop }) => ({
                url: 'lms/MonHoc_Get_ByLopID_BoMon',
                params: { LopID: Lop.LopID, NienKhoa: vueData.NienKhoa, HocKi: period.Value },
            })), `Đang tải môn ${period.Code}`)
            classEntries.forEach(({ Lop }, index) => {
                this.getBulkRows(subjectResponses[index]).forEach(mon => {
                    const MonHoc = {
                        ...mon,
                        TenMonHoc: mon.TenMonHoc_HienThi || mon.TenMonHoc || '',
                    }
                    const templateID = MonHoc.TemplateBangDiemID
                    if (!Lop.LopID) return
                    if (!MonHoc.MonHocLopID || templateID === undefined || templateID === null || templateID === '') {
                        skippedSubjects++
                        return
                    }

                    const subjectKey = `${Lop.LopID}__${MonHoc.MonHocLopID}`
                    if (seenSubjects.has(subjectKey)) return
                    seenSubjects.add(subjectKey)
                    subjectEntries.push({ Lop, MonHoc })
                    templateIDs.set(String(templateID), templateID)
                })
            })

            const templates = Array.from(templateIDs.values())
            const groupResponses = await this.fetchBulkRequests(templates.map(TemplateBangDiemID => ({
                url: 'lms/NhomCauTrucDiem_Get_ByTemplateBangDiemID',
                params: { TemplateBangDiemID },
            })), 'Đang tải nhóm cột')
            const groupsByTemplate = new Map()
            templates.forEach((TemplateBangDiemID, index) => {
                groupsByTemplate.set(String(TemplateBangDiemID), this.getBulkRows(groupResponses[index])
                    .filter(group => group.Semester === period.Code))
            })

            const templateGroups = new Map()
            subjectEntries.forEach(({ MonHoc }) => {
                const templateKey = String(MonHoc.TemplateBangDiemID)
                ;(groupsByTemplate.get(templateKey) || []).forEach(group => {
                    const groupKey = `${templateKey}__${group.MaNhomCotDiem}`
                    if (!templateGroups.has(groupKey)) {
                        templateGroups.set(groupKey, { TemplateBangDiemID: MonHoc.TemplateBangDiemID, group })
                    }
                })
            })

            const templateGroupEntries = Array.from(templateGroups.entries())
            const columnResponses = await this.fetchBulkRequests(templateGroupEntries.map(([, entry]) => ({
                url: 'lms/CotDiem_Get_ByTemplateBangDiemID_MaNhom',
                params: {
                    TemplateBangDiemID: entry.TemplateBangDiemID,
                    MaNhomCotDiem: entry.group.MaNhomCotDiem,
                },
            })), 'Đang tải danh sách cột')
            const columnsByGroup = new Map()
            templateGroupEntries.forEach(([groupKey], index) => {
                columnsByGroup.set(groupKey, this.getBulkRows(columnResponses[index])
                    .filter(column => this.isEnabledScoreColumn(column) && this.isBulkLockColumnForPeriod(column.MaCotDiem, period)))
            })

            const contexts = []
            subjectEntries.forEach(({ Lop, MonHoc }) => {
                const templateKey = String(MonHoc.TemplateBangDiemID)
                ;(groupsByTemplate.get(templateKey) || []).forEach(group => {
                    const groupKey = `${templateKey}__${group.MaNhomCotDiem}`
                    const columns = columnsByGroup.get(groupKey) || []
                    if (columns.length) contexts.push({ Lop, MonHoc, group, columns })
                })
            })

            const candidateKeys = new Set()
            contexts.forEach(({ Lop, MonHoc, columns }) => columns.forEach(column => {
                const maCotDiem = this.normalizeMaCotDiem(String(column.MaCotDiem || ''))
                if (Lop.LopID && MonHoc.MonHocLopID && maCotDiem) {
                    candidateKeys.add(`${Lop.LopID}__${this.getKhoaKey(MonHoc.MonHocLopID, maCotDiem)}`)
                }
            }))
            return {
                contexts,
                candidateCount: candidateKeys.size,
                classCount: new Set(subjectEntries.map(entry => String(entry.Lop.LopID))).size,
                subjectCount: new Set(subjectEntries.map(entry => `${entry.Lop.LopID}__${entry.MonHoc.MonHocLopID}`)).size,
                skippedSubjects,
                period,
            }
        },
        // Chỉ tra trạng thái sau khi người dùng xác nhận; KhoaCotDiem_Get có thể ghi bản ghi phụ trợ.
        async resolveCap1LockTargets(contexts) {
            const statusRequests = contexts.map(({ Lop, MonHoc, group }) => ({
                url: 'lms/KhoaCotDiem_Get',
                params: {
                    LopID: Lop.LopID,
                    MonHocLopID: MonHoc.MonHocLopID,
                    MaNhomCotDiem: group.MaNhomCotDiem,
                    NienKhoa: vueData.NienKhoa,
                    Semester: group.Semester,
                },
            }))
            const groupCode = contexts[0]?.group?.MaNhomCotDiem || ''
            const statusResponses = await this.fetchBulkRequests(statusRequests, `Đang kiểm tra ${groupCode}`)
            const targetMap = new Map()

            contexts.forEach((context, index) => {
                const khoaMap = {}
                const monHocLopByDisplayMap = {}
                this.getBulkRows(statusResponses[index]).forEach(item => {
                    const maCotDiemDisplay = String(item.MaCotDiem || '')
                    if (!maCotDiemDisplay) return
                    const khoaCotDiemID = Number(item.KhoaCotDiemID || 0)
                    const nextInfo = {
                        TinhTrang: this.isLockedFlag(item.TinhTrang),
                        KhoaCotDiemID: khoaCotDiemID,
                    }
                    const key = this.getKhoaKey(item.MonHocLopID, maCotDiemDisplay)
                    khoaMap[key] = this.pickKhoaInfo(khoaMap[key], nextInfo)

                    const current = monHocLopByDisplayMap[maCotDiemDisplay]
                    const next = {
                        MonHocLopID: Number(item.MonHocLopID || 0),
                        KhoaCotDiemID: khoaCotDiemID,
                    }
                    if (!current || next.KhoaCotDiemID >= current.KhoaCotDiemID) {
                        monHocLopByDisplayMap[maCotDiemDisplay] = next
                    }
                })

                context.columns.forEach(column => {
                    const maCotDiemDisplay = String(column.MaCotDiem || '')
                    const inferredMonHocLopID = monHocLopByDisplayMap[maCotDiemDisplay]?.MonHocLopID || 0
                    const rowMonHocLopID = Number(context.MonHoc.MonHocLopID || 0)
                    const monHocLopID = this.hasNumericPrefix(maCotDiemDisplay)
                        ? Number(inferredMonHocLopID || rowMonHocLopID)
                        : Number(rowMonHocLopID || inferredMonHocLopID)
                    const maCotDiem = this.normalizeMaCotDiem(maCotDiemDisplay)
                    if (!context.Lop.LopID || !monHocLopID || !maCotDiem) return

                    const status = khoaMap[this.getKhoaKey(monHocLopID, maCotDiemDisplay)] || {}
                    const targetKey = `${context.Lop.LopID}__${this.getKhoaKey(monHocLopID, maCotDiem)}`
                    const target = targetMap.get(targetKey) || {
                        LopID: context.Lop.LopID,
                        MonHocLopID: monHocLopID,
                        MaCotDiem: maCotDiem,
                        KhoaCotDiemID: 0,
                        IsLocked: false,
                    }
                    const statusID = Number(status.KhoaCotDiemID || 0)
                    if (statusID > target.KhoaCotDiemID) target.KhoaCotDiemID = statusID
                    target.IsLocked = target.IsLocked || this.isLockedFlag(status.TinhTrang)
                    targetMap.set(targetKey, target)
                })
            })

            return Array.from(targetMap.values())
        },
        onLockWholeLevel() {
            if (Number(this.CapID) !== 1 || this.bulkLockLoading) return
            if (!vueData.NienKhoa) {
                this.snackbarRef.value.showSnackbar({ message: 'Vui lòng chọn niên khóa trước khi khóa toàn cấp 1', color: 'warning' })
                return
            }

            this.bulkLockSelectedPeriod = null
            this.bulkLockPeriodDialog = true
        },
        async onConfirmBulkLockPeriod() {
            if (Number(this.CapID) !== 1 || this.bulkLockLoading) return
            const period = this.getBulkLockPeriodConfig(this.bulkLockSelectedPeriod)
            if (!period) {
                this.snackbarRef.value.showSnackbar({ message: 'Vui lòng chọn kỳ đánh giá cần khóa', color: 'warning' })
                return
            }

            this.bulkLockPeriodDialog = false
            this.bulkLockLoading = true
            this.bulkLockPhase = 'Chờ xác nhận'
            this.bulkLockProgressPercent = 0
            this.bulkLockProgressDetail = ''
            const groupCode = period.GroupCode
            try {
                await this.$nextTick()
                const ok = await this._confirm()?.show({
                    title: `Khóa cấp 1 · ${groupCode} · ${period.ColumnSuffix}`,
                    message: `Áp dụng cho tất cả lớp và môn trong niên khóa ${vueData.NienKhoa}, kỳ ${period.Code}, mã cột có suffix ${period.ColumnSuffix} (${groupCode}). Sẽ giữ nguyên cột đã khóa và khóa các cột còn mở.`,
                    type: 'confirm',
                })
                if (!ok) return

                this.bulkLockProgressVisible = true
                this.setBulkLockProgress(`Đang chuẩn bị khóa ${period.ColumnSuffix}`, 0, 1)
                const summary = await this.collectCap1LockTargets(groupCode)
                if (!summary.candidateCount) {
                    this.snackbarRef.value.showSnackbar({ message: `Không tìm thấy cột điểm có suffix ${period.ColumnSuffix} trong ${period.Code}`, color: 'warning' })
                    return
                }

                const targets = await this.resolveCap1LockTargets(summary.contexts)
                const toLock = targets.filter(target => !target.IsLocked)
                if (!targets.length) {
                    this.snackbarRef.value.showSnackbar({ message: `Không đọc được trạng thái cột điểm của ${groupCode}`, color: 'warning' })
                    return
                }
                if (!toLock.length) {
                    this.snackbarRef.value.showSnackbar({ message: `Toàn bộ ${targets.length} cột điểm thuộc ${groupCode} đã được khóa`, color: 'info' })
                    return
                }

                // Giữ nguyên bản ghi khóa đã có để bảo toàn lịch sử; chỉ tạo mới cho cột chưa có bản ghi.
                const writeRequests = toLock.map(target => target.KhoaCotDiemID
                    ? {
                        url: 'lms/KhoaCotDiem_TinhTrang_Upd_ByKhoaCotDiem',
                        params: { KhoaCotDiemID: target.KhoaCotDiemID, TinhTrang: 1, LyDo: '' },
                    }
                    : {
                        url: 'lms/KhoaCotDiem_Ins_And_Upd',
                        params: {
                            LopID: target.LopID,
                            MonHocLopID: target.MonHocLopID,
                            MaCotDiem: target.MaCotDiem,
                            IsKhoaCotDiem: true,
                        },
                    })

                let successCount = 0
                let failedCount = 0
                let completedCount = 0
                const batchSize = 20
                this.setBulkLockProgress(`Đang khóa ${period.ColumnSuffix}`, 0, writeRequests.length)
                for (let start = 0; start < writeRequests.length; start += batchSize) {
                    const batch = writeRequests.slice(start, start + batchSize)
                    await Promise.all(batch.map(async request => {
                        try {
                            await fetchPromise(request.url, request.params, { cache: false })
                            successCount++
                        } catch (error) {
                            failedCount++
                        } finally {
                            completedCount++
                            this.setBulkLockProgress(`Đang khóa ${period.ColumnSuffix}`, completedCount, writeRequests.length)
                            this.bulkLockProgressDetail = `${completedCount}/${writeRequests.length} · thành công ${successCount} · lỗi ${failedCount}`
                        }
                    }))
                }

                if (failedCount) {
                    this.snackbarRef.value.showSnackbar({
                        message: `Đã khóa ${successCount}/${writeRequests.length} cột thuộc ${groupCode} (${period.ColumnSuffix}); ${failedCount} cột lỗi, vui lòng làm mới và thử lại.`,
                        color: 'warning',
                    })
                } else {
                    this.snackbarRef.value.showSnackbar({
                        message: `Đã khóa ${successCount} cột điểm cấp 1 thuộc ${groupCode} (${period.ColumnSuffix})`,
                        color: 'success',
                    })
                }

                if (this.LopItem && this.MonHocItem && this.MaNhomCotDiemItem) {
                    this.setBulkLockProgress('Đang làm mới danh sách đang xem', 0, 1)
                    await this.getDS()
                    this.setBulkLockProgress('Đang làm mới danh sách đang xem', 1, 1)
                }
            } catch (error) {
                this.snackbarRef.value.showSnackbar({
                    message: `Không thể khóa cột điểm cấp 1 thuộc ${groupCode}${error?.message ? ': ' + error.message : ''}`,
                    color: 'error',
                })
            } finally {
                this.bulkLockLoading = false
                this.bulkLockProgressVisible = false
                this.bulkLockPhase = ''
            }
        },
        
        async lockItem(item) {
            if (item.KhoaCotDiemID) {
                await fetchPromise('lms/KhoaCotDiem_TinhTrang_Upd_ByKhoaCotDiem', {
                    KhoaCotDiemID: item.KhoaCotDiemID,
                    TinhTrang: 1,
                    LyDo: '',
                }, { cache: false })
            } else {
                await fetchPromise('lms/KhoaCotDiem_Ins_And_Upd', {
                    LopID: this.LopItem.LopID,
                    MonHocLopID: item.MonHocLopID || this.MonHocItem.MonHocLopID,
                    MaCotDiem: item.MaCotDiemSave || this.normalizeMaCotDiem(item.MaCotDiemDisplay),
                    IsKhoaCotDiem: true,
                }, { cache: false })
            }
        },
        onClickToggle(item) {
            if (item.IsLocked && item.KhoaCotDiemID) {
                this.dialogKhoa = { show: true, item, LyDo: '' }
            } else {
                this.onLock(item)
            }
        },
        async onLock(item) {
            const ok = await this._confirm()?.show({ title: `Khóa cột điểm "${item.TenCotDiem_VI}"?`, type: 'confirm' })
            if (!ok) return
            await this.lockItem(item)
            this.snackbarRef.value.showSnackbar({ message: 'Khóa cột điểm thành công', color: 'success' })
            this.getDS()
        },
        async onLockSelected() {
            if (this.hasMixedSelectedStatus) {
                this.snackbarRef.value.showSnackbar({ message: 'Không thể thao tác khi đang chọn lẫn cột đã khóa và chưa khóa', color: 'warning' })
                return
            }
            const items = this.selectedRows.filter(x => !x.IsLocked)
            if (!items.length) return
            const ok = await this._confirm()?.show({ title: `Khóa ${items.length} cột điểm đã chọn?`, type: 'confirm' })
            if (!ok) return
            for (const item of items) {
                await this.lockItem(item)
            }
            this.snackbarRef.value.showSnackbar({ message: `Khóa thành công ${items.length} cột điểm`, color: 'success' })
            await this.getDS()
        },
        onOpenUnlockSelected() {
            if (this.hasMixedSelectedStatus) {
                this.snackbarRef.value.showSnackbar({ message: 'Không thể thao tác khi đang chọn lẫn cột đã khóa và chưa khóa', color: 'warning' })
                return
            }
            if (!this.selectedLockedCount) return
            this.dialogMoKhoaSelected = { show: true, LyDo: '' }
        },
        async onConfirmMoKhoaSelected() {
            const lyDo = this.dialogMoKhoaSelected.LyDo?.trim()
            if (!lyDo) {
                this.snackbarRef.value.showSnackbar({ message: 'Vui lòng nhập lý do mở khóa', color: 'error' })
                return
            }
            const items = this.selectedRows.filter(x => !!x.IsLocked && !!x.KhoaCotDiemID)
            if (!items.length) {
                this.snackbarRef.value.showSnackbar({ message: 'Không có cột đã khóa hợp lệ để mở', color: 'warning' })
                return
            }
            for (const item of items) {
                await fetchPromise('lms/KhoaCotDiem_TinhTrang_Upd_ByKhoaCotDiem', {
                    KhoaCotDiemID: item.KhoaCotDiemID,
                    TinhTrang: 0,
                    LyDo: lyDo,
                }, { cache: false })
            }
            this.dialogMoKhoaSelected.show = false
            this.snackbarRef.value.showSnackbar({ message: `Mở khóa thành công ${items.length} cột điểm`, color: 'success' })
            await this.getDS()
        },
        async onConfirmMoKhoa() {
            if (!this.dialogKhoa.LyDo?.trim()) {
                this.snackbarRef.value.showSnackbar({ message: 'Vui lòng nhập lý do mở khóa', color: 'error' })
                return
            }
            if (!this.dialogKhoa.item?.KhoaCotDiemID) {
                this.snackbarRef.value.showSnackbar({ message: 'Không tìm thấy định danh khóa cột điểm', color: 'error' })
                return
            }
            await fetchPromise('lms/KhoaCotDiem_TinhTrang_Upd_ByKhoaCotDiem', {
                KhoaCotDiemID: this.dialogKhoa.item.KhoaCotDiemID,
                TinhTrang: 0,
                LyDo: this.dialogKhoa.LyDo.trim(),
            }, { cache: false })
            this.dialogKhoa.show = false
            this.snackbarRef.value.showSnackbar({ message: 'Mở khóa thành công', color: 'success' })
            this.getDS()
        },
        async onRefresh() {
            if (!this.MaNhomCotDiemItem) {
                this.snackbarRef.value.showSnackbar({
                    message: 'Vui lòng chọn đủ bộ lọc trước khi làm mới',
                    color: 'warning',
                })
                return
            }
            await this.getDS()
        },
    },
	}
</script>