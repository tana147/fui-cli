<template>
	<Global>
        <template #header>
            <v-card>
                <v-card-title>Báo cáo đánh giá môn học theo khối</v-card-title>
                <v-card-text>
                    <v-row align="center">
                        <v-col cols="12" sm="2">
                            <v-select v-model="NienKhoaSelected" label="Niên khóa" :items="DSNienKhoa"
                                item-title="label" item-value="NienKhoa" return-object />
                        </v-col>
                        <v-col cols="12" sm="3">
                            <v-select v-model="KhoiItem" label="Chọn khối" :items="DSKhoi" item-title="TenKhoiHoc"
                                item-value="KhoiID" return-object />
                        </v-col>
                        <v-col class="d-flex align-center ga-2 flex-wrap">
                            <span class="text-body-2 text-medium-emphasis">Học kì:</span>
                            <v-btn-toggle v-model="selectedHK" multiple density="compact" variant="outlined" color="primary">
                                <v-btn value="gkhk1" size="small">GK HK1</v-btn>
                                <v-btn value="ckhk1" size="small">CK HK1</v-btn>
                                <v-btn value="gkhk2" size="small">GK HK2</v-btn>
                                <v-btn value="ckhk2" size="small">CK HK2</v-btn>
                            </v-btn-toggle>
                            <v-divider vertical class="mx-1" />
                            <v-btn variant="outlined" color="primary" :loading="loading" :disabled="!KhoiItem" @click="getDS()">
                                <v-icon start>mdi-reload</v-icon>Tải dữ liệu
                            </v-btn>
                            <v-btn variant="outlined" color="success" :disabled="DS.length === 0" @click="exportExcel">
                                <v-icon start>mdi-file-excel</v-icon>Xuất Excel
                            </v-btn>
                            <v-btn variant="outlined" color="warning"
                                :disabled="!BaoCaoID || !activeKiKey || DS.length === 0 || activeBaoCaoItem?.IsChotBaoCao"
                                @click="onChotBaoCao">
                                <v-icon start>mdi-lock-check</v-icon>Chốt báo cáo
                            </v-btn>
                        </v-col>
                    </v-row>
                    <v-row v-if="activeBaoCaoItem?.IsChotBaoCao" dense class="mt-0">
                        <v-col>
                            <p class="text-caption text-medium-emphasis">
                                <v-icon size="14" color="red">mdi-lock</v-icon>
                                <span class="text-red font-weight-bold">Đã chốt</span>
                                — [{{ activeBaoCaoItem.NguoiChot }}] {{ activeBaoCaoItem.HoTenNguoiChot }} •
                                {{ activeBaoCaoItem.NgayChot }}
                            </p>
                        </v-col>
                    </v-row>
                </v-card-text>
            </v-card>
        </template>

        <v-divider />

        <div id="bc-table-wrap" style="max-height: calc(100dvh - 77px); overflow-y: auto;">
            <div v-if="DS.length === 0 && !loading"
                class="d-flex flex-column align-center justify-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3 opacity-40">mdi-table-search</v-icon>
                <p class="text-body-2">Chọn khối hoặc Tất cả khối để xem dữ liệu</p>
            </div>

            <!-- Bảng 1: Các môn học -->
            <table v-if="DS.length > 0" id="bc-table-1" class="bc-table">
                <thead>
                    <tr>
                        <th rowspan="3" class="bc-th text-center" style="min-width:180px">NỘI DUNG<br>ĐÁNH GIÁ</th>
                        <th rowspan="3" class="bc-th text-center" style="min-width:65px">TS&nbsp;HS<br>ĐẦU NĂM</th>
                        <th rowspan="3" class="bc-th text-center" style="min-width:65px">TS&nbsp;HS<br>{{ activeKiLabel }}</th>
                        <th :colspan="kisSelected.length * 3" class="bc-th text-center">ĐÁNH GIÁ</th>
                        <th v-if="hasChiTieu" rowspan="2" colspan="6" class="bc-th text-center" style="background:#fff3e0">SO VỚI CHỈ TIÊU ({{ activeKiLabel }}){{ isAllKhoi ? ' — tổng hợp theo sĩ số từng khối' : '' }}</th>
                    </tr>
                    <tr>
                        <th :colspan="kisSelected.length" class="bc-th text-center">HOÀN THÀNH TỐT (T)</th>
                        <th :colspan="kisSelected.length" class="bc-th text-center">HOÀN THÀNH (H)</th>
                        <th :colspan="kisSelected.length" class="bc-th text-center">CHƯA HOÀN THÀNH (C)</th>
                    </tr>
                    <tr>
                        <th v-for="(ki, idx) in kisRepeat3" :key="'h1-' + idx"
                            :class="['bc-th text-center', { 'bc-col-active-th': activeKiKey === ki.key }]"
                            style="min-width:65px">
                            {{ ki.label }}
                        </th>
                        <template v-if="hasChiTieu">
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">CT HTT</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">± HTT</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">CT HT</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">± HT</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">CT CHT</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">± CHT</th>
                        </template>
                    </tr>
                </thead>
                <tbody>
                    <tr class="bc-section-row">
                        <td :colspan="tableColspan" class="bc-td-section text-center font-weight-bold">CÁC MÔN HỌC VÀ HOẠT ĐỘNG
                            GIÁO DỤC
                        </td>
                    </tr>
                    <tr v-for="(row, i) in DS" :key="i" :class="i % 2 === 0 ? '' : 'bc-row-alt'">
                        <td class="bc-td">{{ row.TenMonHoc_HienThi }}</td>
                        <td class="bc-td text-center">{{ row.TongSoHocSinh_DauNam }}</td>
                        <td class="bc-td text-center">{{ row[activeKiKey]?.TongSoHocSinh_TrongKi ?? '—' }}</td>
                                                <template v-for="field in ['TiLe_HoanThanhTot', 'TiLe_HoanThanh', 'TiLe_ChuaHoanThanh']" :key="field">
                            <td v-for="ki in kisSelected" :key="ki.key + field"
                                :class="['bc-td text-center', { 'bc-col-active': activeKiKey === ki.key }]">
                                {{ formatPct(row[ki.key]?.[field]) }}
                            </td>
                        </template>
                        <template v-if="hasChiTieu">
                            <template v-for="field in ['TiLe_HoanThanhTot', 'TiLe_HoanThanh', 'TiLe_ChuaHoanThanh']" :key="'ct-' + field">
                                <td class="bc-td text-center" style="background:#fffde7">{{ formatPct(getChiTieuVal(row, field)) }}</td>
                                <td :class="['bc-td text-center', getTangGiamClass(row, field)]" style="background:#fffde7">{{ formatTangGiam(row, field) }}</td>
                            </template>
                        </template>
                    </tr>
                </tbody>
            </table>

            <!-- Bảng 2: Năng lực & Phẩm chất -->
            <table v-if="DS2.length > 0" id="bc-table-2" class="bc-table mt-4">
                <thead>
                    <tr>
                        <th rowspan="3" class="bc-th text-center" style="min-width:220px">NỘI DUNG<br>ĐÁNH GIÁ</th>
                        <th rowspan="3" class="bc-th text-center" style="min-width:65px">TS&nbsp;HS<br>ĐẦU NĂM</th>
                        <th rowspan="3" class="bc-th text-center" style="min-width:65px">TS&nbsp;HS<br>{{ activeKiLabel }}</th>
                        <th :colspan="kisSelected.length * 3" class="bc-th text-center">ĐÁNH GIÁ</th>
                        <th v-if="hasChiTieu" rowspan="2" colspan="6" class="bc-th text-center" style="background:#fff3e0">SO VỚI CHỈ TIÊU ({{ activeKiLabel }}){{ isAllKhoi ? ' — tổng hợp theo sĩ số từng khối' : '' }}</th>
                    </tr>
                    <tr>
                        <th :colspan="kisSelected.length" class="bc-th text-center">TỐT (T)</th>
                        <th :colspan="kisSelected.length" class="bc-th text-center">ĐẠT (Đ)</th>
                        <th :colspan="kisSelected.length" class="bc-th text-center">CẦN CỐ GẮNG (C)</th>
                    </tr>
                    <tr>
                        <th v-for="(ki, idx) in kisRepeat3" :key="'h2-' + idx"
                            :class="['bc-th text-center', { 'bc-col-active-th': activeKiKey === ki.key }]"
                            style="min-width:65px">
                            {{ ki.label }}
                        </th>
                        <template v-if="hasChiTieu">
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">CT T</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">± T</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">CT Đ</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">± Đ</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">CT CGG</th>
                            <th class="bc-th text-center" style="min-width:65px;background:#fff3e0">± CGG</th>
                        </template>
                    </tr>
                </thead>
                <tbody>
                    <tr class="bc-section-row">
                        <td :colspan="tableColspan" class="bc-td-section text-center font-weight-bold">NĂNG LỰC CHUNG</td>
                    </tr>
                    <tr v-for="(row, i) in DS2_NangLuc" :key="'nl-' + i" :class="i % 2 === 0 ? '' : 'bc-row-alt'">
                        <td class="bc-td">{{ row.TenMonHoc_HienThi }}</td>
                        <td class="bc-td text-center">{{ row.TongSoHocSinh_DauNam }}</td>
                        <td class="bc-td text-center">{{ row[activeKiKey]?.TongSoHocSinh_TrongKi ?? '—' }}</td>
                                                <template v-for="field in ['TiLe_HoanThanhTot', 'TiLe_HoanThanh', 'TiLe_ChuaHoanThanh']" :key="field">
                            <td v-for="ki in kisSelected" :key="ki.key + field"
                                :class="['bc-td text-center', { 'bc-col-active': activeKiKey === ki.key }]">
                                {{ formatPct(row[ki.key]?.[field]) }}
                            </td>
                        </template>
                        <template v-if="hasChiTieu">
                            <template v-for="field in ['TiLe_HoanThanhTot', 'TiLe_HoanThanh', 'TiLe_ChuaHoanThanh']" :key="'ct-' + field">
                                <td class="bc-td text-center" style="background:#fffde7">{{ formatPct(getChiTieuVal(row, field)) }}</td>
                                <td :class="['bc-td text-center', getTangGiamClass(row, field)]" style="background:#fffde7">{{ formatTangGiam(row, field) }}</td>
                            </template>
                        </template>
                    </tr>
                    <tr class="bc-section-row">
                        <td :colspan="tableColspan" class="bc-td-section text-center font-weight-bold">PHẨM CHẤT</td>
                    </tr>
                    <tr v-for="(row, i) in DS2_PhamChat" :key="'pc-' + i" :class="i % 2 === 0 ? '' : 'bc-row-alt'">
                        <td class="bc-td">{{ row.TenMonHoc_HienThi }}</td>
                        <td class="bc-td text-center">{{ row.TongSoHocSinh_DauNam }}</td>
                        <td class="bc-td text-center">{{ row[activeKiKey]?.TongSoHocSinh_TrongKi ?? '—' }}</td>
                                                <template v-for="field in ['TiLe_HoanThanhTot', 'TiLe_HoanThanh', 'TiLe_ChuaHoanThanh']" :key="field">
                            <td v-for="ki in kisSelected" :key="ki.key + field"
                                :class="['bc-td text-center', { 'bc-col-active': activeKiKey === ki.key }]">
                                {{ formatPct(row[ki.key]?.[field]) }}
                            </td>
                        </template>
                        <template v-if="hasChiTieu">
                            <template v-for="field in ['TiLe_HoanThanhTot', 'TiLe_HoanThanh', 'TiLe_ChuaHoanThanh']" :key="'ct-' + field">
                                <td class="bc-td text-center" style="background:#fffde7">{{ formatPct(getChiTieuVal(row, field)) }}</td>
                                <td :class="['bc-td text-center', getTangGiamClass(row, field)]" style="background:#fffde7">{{ formatTangGiam(row, field) }}</td>
                            </template>
                        </template>
                    </tr>
                </tbody>
            </table>
        </div>
    </Global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
    data() {
        return {
            vueData,
            DSNienKhoa: [],
            NienKhoaSelected: null,
            DSKhoi: [],
            KhoiItem: null,
            DS: [],
            DS2: [],
            loading: false,
            selectedHK: [],
            BAOCAO_CONFIG: { 1: 29, 2: 30, 3: 31, 4: 32, 5: 33 },
            BaoCaoItems: { gkhk1: null, ckhk1: null, gkhk2: null, ckhk2: null },
            RawKiData: { gkhk1: null, ckhk1: null, gkhk2: null, ckhk2: null },
            RawByKhoiKiData: {},
            DSChiTieu: [],
        }
    },
    computed: {
        TitleCap() { return renderText(parseInt(vueData.CapID)) },
        TitlePage() { return getTitlePageByURL(window.location.pathname + window.location.search) },
        DS2_NangLuc() { return this.DS2.filter(r => r.TenMonHoc_HienThi?.includes('Năng lực')) },
        DS2_PhamChat() { return this.DS2.filter(r => r.TenMonHoc_HienThi?.includes('Phẩm chất')) },
        isAllKhoi() { return !!this.KhoiItem?.IsAllKhoi },
        kisSelected() {
            const labels = { gkhk1: 'GK HK1', ckhk1: 'CK HK1', gkhk2: 'GK HK2', ckhk2: 'CK HK2' }
            return ['gkhk1', 'ckhk1', 'gkhk2', 'ckhk2']
                .filter(k => this.selectedHK.includes(k))
                .map(k => ({ key: k, label: labels[k] }))
        },
        kisRepeat3() { return [...this.kisSelected, ...this.kisSelected, ...this.kisSelected] },
        activeKiKey() {
            const hk = new URLSearchParams(window.location.search).get('hk') ?? ''
            const map = { 'GK_HK1': 'gkhk1', 'CK_HK1': 'ckhk1', 'GK_HK2': 'gkhk2', 'CK_HK2': 'ckhk2' }
            return map[hk] ?? null
        },
        activeBaoCaoItem() {
            return this.BaoCaoID && this.activeKiKey ? (this.BaoCaoItems[this.activeKiKey] ?? null) : null
        },
        BaoCaoID() {
            return this.BAOCAO_CONFIG[this.KhoiItem?.KhoiID] ?? null
        },
        activeKiLabel() {
            const labels = { gkhk1: 'GK HK1', ckhk1: 'CK HK1', gkhk2: 'GK HK2', ckhk2: 'CK HK2' }
            return this.activeKiKey ? labels[this.activeKiKey] : 'HK'
        },
        chiTieuMap() {
            const byID = {}, byName = {}
            const filtered = this.DSChiTieu.filter(r => this.isAllKhoi || String(r.KhoiID) === String(this.KhoiItem?.KhoiID))

            if (this.isAllKhoi) {
                // Chỉ tiêu khác nhau theo khối; tổng hợp theo số học sinh đã được đánh giá để so sánh cùng mẫu số với kết quả.
                const grouped = {}
                for (const r of filtered) {
                    const weight = this.getChiTieuWeight(r)
                    if (!(weight > 0)) continue
                    const groupKey = r.MonHocID != null ? 'id:' + r.MonHocID : 'name:' + r.TenMonHoc_HienThi
                    if (!grouped[groupKey]) grouped[groupKey] = { MonHocID: r.MonHocID ?? null, TenMonHoc_HienThi: r.TenMonHoc_HienThi, Is_MonHoc: r.Is_MonHoc, sum: {}, weight: {} }
                    const item = grouped[groupKey]
                    // Bảng chỉ tiêu lưu hai bộ cột riêng: môn học và năng lực/phẩm chất; cộng gộp cả hai để khối tổng hợp không làm mất chỉ tiêu NL-PC.
                    for (const field of ['ChiTieu_HoanThanhTot', 'ChiTieu_HoanThanh', 'ChiTieu_ChuaHoanThanh', 'ChiTieu_Tot', 'ChiTieu_Dat', 'ChiTieu_CanCoGang']) {
                        if (r[field] === null || r[field] === undefined || r[field] === '') continue
                        const value = Number(r[field])
                        if (!Number.isFinite(value)) continue
                        item.sum[field] = (item.sum[field] ?? 0) + value * weight
                        item.weight[field] = (item.weight[field] ?? 0) + weight
                    }
                }
                for (const item of Object.values(grouped)) {
                    const target = { MonHocID: item.MonHocID, TenMonHoc_HienThi: item.TenMonHoc_HienThi, Is_MonHoc: item.Is_MonHoc, _targetWeights: {} }
                    for (const field of ['ChiTieu_HoanThanhTot', 'ChiTieu_HoanThanh', 'ChiTieu_ChuaHoanThanh', 'ChiTieu_Tot', 'ChiTieu_Dat', 'ChiTieu_CanCoGang']) {
                        target[field] = item.weight[field]
                            ? Math.round(item.sum[field] / item.weight[field] * 100) / 100
                            : null
                        target._targetWeights[field] = item.weight[field] ?? 0
                    }
                    if (target.MonHocID != null) byID[target.MonHocID] = target
                    if (target.TenMonHoc_HienThi) byName[target.TenMonHoc_HienThi] = target
                }
            } else {
                for (const r of filtered) { if (r.MonHocID) byID[r.MonHocID] = r; byName[r.TenMonHoc_HienThi] = r }
            }
            return { byID, byName }
        },
        hasChiTieu() {
            return !!(this.activeKiKey && (Object.keys(this.chiTieuMap.byID).length || Object.keys(this.chiTieuMap.byName).length))
        },
        tableColspan() { return 3 + this.kisSelected.length * 3 + (this.hasChiTieu ? 6 : 0) },
    },
    watch: {
        NienKhoaSelected() {
            this.DS = []
            this.DS2 = []
            if (this.KhoiItem) this.getDS()
        },
        KhoiItem(v) {
            this.DS = []
            this.DS2 = []
            if (v) this.getDS()
        },
    },
    mounted() { this.init() },
    methods: {
        async init() {
            const urlParams = new URLSearchParams(window.location.search)
            const HK_MAP = { 'GK_HK1': 'gkhk1', 'CK_HK1': 'ckhk1', 'GK_HK2': 'gkhk2', 'CK_HK2': 'ckhk2' }
            const urlHkKey = HK_MAP[urlParams.get('hk')]
            this.selectedHK = urlHkKey ? [urlHkKey] : ['gkhk1', 'ckhk1', 'gkhk2', 'ckhk2']

            const res = await fetchPromise('lms/NienKhoa_Get', {})
            const unique = [...new Map((res ?? []).map(r => [r.NienKhoa, r])).values()]
                .map(r => ({ ...r, label: `${r.NienKhoa} - ${r.NienKhoa + 1}` }))
            this.DSNienKhoa = unique
            this.NienKhoaSelected = unique.find(r => r.IsActive) ?? unique[0] ?? null
            this.getKhoi()
        },
        async getKhoi() {
            const grades = await fetchPromise('lms/KhoiHocByCapHoc_Get', { CapID: 1 })
            this.DSKhoi = [
                { KhoiID: 0, TenKhoiHoc: 'Tất cả khối', CapID: 1, IsAllKhoi: true },
                ...(grades ?? []).map(k => ({ ...k, IsAllKhoi: false })),
            ]
            const urlKhoiID = parseInt(new URLSearchParams(window.location.search).get('khoiid'))
            if (urlKhoiID) {
                this.KhoiItem = this.DSKhoi.find(k => k.KhoiID === urlKhoiID) ?? null
            }
        },
        async getDS() {
            if (!this.KhoiItem || this.selectedHK.length === 0) return
            this.loading = true
            this.BaoCaoItems = { gkhk1: null, ckhk1: null, gkhk2: null, ckhk2: null }
            this.RawKiData = { gkhk1: null, ckhk1: null, gkhk2: null, ckhk2: null }
            this.RawByKhoiKiData = {}
            try {
                const HK_LIST = ['GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2']
                const KI_KEYS = ['gkhk1', 'ckhk1', 'gkhk2', 'ckhk2']
                const activeKeys = [...KI_KEYS]
                const nienKhoa = this.NienKhoaSelected?.NienKhoa ?? vueData.NienKhoa
                const params = { KhoiID: this.KhoiItem.KhoiID, NienKhoa: nienKhoa }
                this.DSChiTieu = (await fetchPromise('lms/ChiTieu_C1_Get', { NienKhoa: nienKhoa })) ?? []

                if (this.isAllKhoi) {
                    const grades = this.DSKhoi.filter(k => !k.IsAllKhoi)
                    const rawByKhoi = await this.getAllKhoiData(grades, nienKhoa, HK_LIST, KI_KEYS)
                    this.RawByKhoiKiData = rawByKhoi
                    const rowsFor = (key, resultSet) => this.aggregateRowsByGrade(
                        grades.map(k => ({
                            KhoiID: k.KhoiID,
                            rows: this.getResultSetRows(rawByKhoi[String(k.KhoiID)]?.[key], resultSet),
                        }))
                    )
                    this.DS = this.mergeRows(rowsFor('gkhk1', 0), rowsFor('ckhk1', 0), rowsFor('gkhk2', 0), rowsFor('ckhk2', 0))
                    this.DS2 = this.mergeRows(rowsFor('gkhk1', 1), rowsFor('ckhk1', 1), rowsFor('gkhk2', 1), rowsFor('ckhk2', 1))
                } else {
                    // Mỗi khối vẫn lấy JSON đã chốt riêng; dữ liệu một khối tiếp tục giữ đúng trạng thái và quyền chốt hiện có.
                    if (this.BaoCaoID && activeKeys.length > 0) {
                        const bcResults = await fetchBatchPromise(
                            activeKeys.map(key => ({
                                url: 'lms/BaoCao_TongHop_Get_BaoCaoID_HocKi_CapID',
                                params: { BaoCaoID: this.BaoCaoID, HocKi: HK_LIST[KI_KEYS.indexOf(key)], CapID: vueData.CapID, NienKhoa: params.NienKhoa }
                            })),
                            { forceRefresh: true }
                        )
                        activeKeys.forEach((key, i) => {
                            const res = bcResults[i]
                            this.BaoCaoItems[key] = Array.isArray(res?.[1]) ? (res[1][0] ?? null) : null
                        })
                    }

                    const rawData = { gkhk1: null, ckhk1: null, gkhk2: null, ckhk2: null }
                    const needFetch = activeKeys.filter(key => !this.BaoCaoItems[key]?.IsChotBaoCao)
                    if (needFetch.length > 0) {
                        const apiRes = await fetchBatchPromise(
                            needFetch.map(key => ({
                                url: 'lms/BaoCao_DanhGiaMonHoc_HK_TheoKhoi',
                                params: { ...params, HocKi: HK_LIST[KI_KEYS.indexOf(key)] }
                            }))
                        )
                        needFetch.forEach((key, i) => {
                            rawData[key] = apiRes[i]
                            this.RawKiData[key] = apiRes[i]
                        })
                    }
                    // Dùng JSON đã chốt cho học kì đã chốt.
                    activeKeys.forEach(key => {
                        if (this.BaoCaoItems[key]?.IsChotBaoCao) {
                            rawData[key] = JSON.parse(this.BaoCaoItems[key].JSON_BaoCao)
                        }
                    })

                    this.DS = this.mergeRows(
                        this.getResultSetRows(rawData.gkhk1, 0), this.getResultSetRows(rawData.ckhk1, 0),
                        this.getResultSetRows(rawData.gkhk2, 0), this.getResultSetRows(rawData.ckhk2, 0)
                    )
                    this.DS2 = this.mergeRows(
                        this.getResultSetRows(rawData.gkhk1, 1), this.getResultSetRows(rawData.ckhk1, 1),
                        this.getResultSetRows(rawData.gkhk2, 1), this.getResultSetRows(rawData.ckhk2, 1)
                    )
                }
            } finally {
                this.loading = false
            }
        },
        // Dùng promise chain để tuần tự truy vấn trạng thái chốt theo học kì trong component FUI.
        getAllKhoiData(grades, nienKhoa, HK_LIST, KI_KEYS) {
            const rawByKhoi = {}
            const reportByKhoi = {}
            const gradesWithReport = grades.filter(k => this.BAOCAO_CONFIG[k.KhoiID])

            for (const grade of grades) {
                const gradeKey = String(grade.KhoiID)
                rawByKhoi[gradeKey] = { gkhk1: null, ckhk1: null, gkhk2: null, ckhk2: null }
                reportByKhoi[gradeKey] = { gkhk1: null, ckhk1: null, gkhk2: null, ckhk2: null }
            }

            // Mỗi bản chốt có BaoCaoID riêng theo khối và học kì; giữ nguyên JSON chốt của từng khối trong số tổng hợp.
            const statusChain = KI_KEYS.reduce((chain, key) => chain.then(() => {
                if (!gradesWithReport.length) return
                const requests = gradesWithReport.map(grade => ({
                    url: 'lms/BaoCao_TongHop_Get_BaoCaoID_HocKi_CapID',
                    params: {
                        BaoCaoID: this.BAOCAO_CONFIG[grade.KhoiID],
                        HocKi: HK_LIST[KI_KEYS.indexOf(key)],
                        CapID: vueData.CapID,
                        NienKhoa: nienKhoa,
                    },
                }))
                return fetchBatchPromise(requests, { forceRefresh: true }).then(results => {
                    gradesWithReport.forEach((grade, index) => {
                        const result = results[index]
                        reportByKhoi[String(grade.KhoiID)][key] = Array.isArray(result?.[1]) ? (result[1][0] ?? null) : null
                    })
                })
            }), Promise.resolve())

            return statusChain.then(() => {
                const needFetch = grades.flatMap(grade => KI_KEYS
                    .filter(key => !reportByKhoi[String(grade.KhoiID)][key]?.IsChotBaoCao)
                    .map(key => ({ grade, key })))
                if (!needFetch.length) return
                const requests = needFetch.map(({ grade, key }) => ({
                    url: 'lms/BaoCao_DanhGiaMonHoc_HK_TheoKhoi',
                    params: { KhoiID: grade.KhoiID, NienKhoa: nienKhoa, HocKi: HK_LIST[KI_KEYS.indexOf(key)] },
                }))
                return fetchBatchPromise(requests).then(results => {
                    needFetch.forEach(({ grade, key }, index) => {
                        rawByKhoi[String(grade.KhoiID)][key] = results[index]
                    })
                })
            }).then(() => {
                for (const grade of grades) {
                    const gradeKey = String(grade.KhoiID)
                    for (const key of KI_KEYS) {
                        const report = reportByKhoi[gradeKey][key]
                        if (report?.IsChotBaoCao) rawByKhoi[gradeKey][key] = JSON.parse(report.JSON_BaoCao)
                    }
                }
                return rawByKhoi
            })
        },
        getResultSetRows(res, idx) {
            return Array.isArray(res?.[0]) ? (res[idx] ?? []) : (idx === 0 && Array.isArray(res) ? res : [])
        },
        aggregateRowsByGrade(gradeRows) {
            const rowsByName = new Map()
            const countFields = ['TongSoHocSinh_DauNam', 'TongSoHocSinh_TrongKi', 'HoanThanhTot', 'HoanThanh', 'ChuaHoanThanh']
            for (const gradeData of gradeRows) {
                const gradeID = Number(gradeData.KhoiID)
                for (const row of gradeData.rows ?? []) {
                    const name = row?.TenMonHoc_HienThi
                    if (!name) continue
                    // SP báo cáo chỉ trả tên môn, không có MonHocID; nhận diện hai môn theo tên và khối rồi gắn ID cho tra chỉ tiêu.
                    const subjectName = name.trim().toLowerCase()
                    const isTnxh = subjectName === 'tự nhiên và xã hội'
                    const isKhoaHoc = subjectName === 'khoa học'
                    const isTnxhKhoaHoc = (isTnxh && gradeID >= 1 && gradeID <= 3)
                        || (isKhoaHoc && gradeID >= 4 && gradeID <= 5)
                    const targetMonHocID = isTnxh ? 3 : isKhoaHoc ? 4 : row.MonHocID
                    const displayName = isTnxhKhoaHoc ? 'TNXH/Khoa học' : name
                    const groupKey = isTnxhKhoaHoc ? 'combined:tnxh-khoa-hoc' : 'name:' + name
                    if (!rowsByName.has(groupKey)) {
                        const aggregate = {
                            TenMonHoc_HienThi: displayName,
                            MonHocID: isTnxhKhoaHoc ? null : (row.MonHocID ?? null),
                            ChiTieuMonHocIDs: [],
                        }
                        countFields.forEach(field => { aggregate[field] = 0 })
                        rowsByName.set(groupKey, aggregate)
                    }
                    const aggregate = rowsByName.get(groupKey)
                    if (isTnxhKhoaHoc && targetMonHocID != null && !aggregate.ChiTieuMonHocIDs.includes(targetMonHocID)) {
                        aggregate.ChiTieuMonHocIDs.push(targetMonHocID)
                    } else if (!isTnxhKhoaHoc && aggregate.MonHocID == null && row.MonHocID != null) {
                        aggregate.MonHocID = row.MonHocID
                    }
                    countFields.forEach(field => {
                        const value = Number(row[field])
                        if (Number.isFinite(value)) aggregate[field] += value
                    })
                }
            }

            // Tỉ lệ toàn cấp tính từ tổng số học sinh và lượt đánh giá, không cộng hay lấy trung bình các phần trăm theo khối.
            return [...rowsByName.values()].map(row => {
                const total = row.TongSoHocSinh_TrongKi
                row.TiLe_HoanThanhTot = total ? Math.round(row.HoanThanhTot / total * 10000) / 100 : 0
                row.TiLe_HoanThanh = total ? Math.round(row.HoanThanh / total * 10000) / 100 : 0
                row.TiLe_ChuaHoanThanh = total ? Math.round(row.ChuaHoanThanh / total * 10000) / 100 : 0
                return row
            })
        },
        getChiTieuWeight(target) {
            if (!this.activeKiKey) return 0
            const raw = this.RawByKhoiKiData[String(target.KhoiID)]?.[this.activeKiKey]
            const rows = this.getResultSetRows(raw, 0).concat(this.getResultSetRows(raw, 1))
            const matched = rows.find(row => target.MonHocID != null && row.MonHocID != null
                ? String(row.MonHocID) === String(target.MonHocID)
                : row.TenMonHoc_HienThi === target.TenMonHoc_HienThi)
            return Number(matched?.TongSoHocSinh_TrongKi) || 0
        },
        async onChotBaoCao() {
            // Báo cáo tổng hợp nhiều khối không có một BaoCao_ChiTietID duy nhất để chốt.
            if (this.isAllKhoi || !this.BaoCaoID || !this.activeKiKey) return
            const ok = await this.confirmRef.value.show({ title: 'Xác nhận chốt báo cáo?' })
            if (!ok) return
            const key = this.activeKiKey
            const baoCaoItem = this.BaoCaoItems[key]
            if (!baoCaoItem) return
            const res = await fetchPromise('lms/BaoCao_TongHop_Upd_Chot_BaoCao', {
                BaoCao_ChiTietID: baoCaoItem.BaoCao_ChiTietID,
                JSON_BaoCao: this.RawKiData[key]
            }, { cache: false })
            if (res) {
                this.snackbarRef.value.showSnackbar({ message: 'Chốt báo cáo thành công', color: 'success' })
                this.getDS()
            }
        },
        mergeRows(gkhk1Arr, ckhk1Arr, gkhk2Arr, ckhk2Arr) {
            const toMap = arr => { const m = {}; for (const r of arr) m[r.TenMonHoc_HienThi] = r; return m }
            const m1 = toMap(gkhk1Arr), m2 = toMap(ckhk1Arr), m3 = toMap(gkhk2Arr), m4 = toMap(ckhk2Arr)
            const keys = [...new Set([...Object.keys(m1), ...Object.keys(m2), ...Object.keys(m3), ...Object.keys(m4)])]
            return keys.map(ten => {
                const rows = [m1[ten], m2[ten], m3[ten], m4[ten]].filter(Boolean)
                return {
                    TenMonHoc_HienThi: ten,
                    MonHocID: m1[ten]?.MonHocID ?? m2[ten]?.MonHocID ?? m3[ten]?.MonHocID ?? m4[ten]?.MonHocID ?? null,
                    ChiTieuMonHocIDs: [...new Set(rows.flatMap(row => row.ChiTieuMonHocIDs ?? []))],
                    TongSoHocSinh_DauNam: m1[ten]?.TongSoHocSinh_DauNam ?? m2[ten]?.TongSoHocSinh_DauNam ?? '—',
                    gkhk1: m1[ten] ?? null,
                    ckhk1: m2[ten] ?? null,
                    gkhk2: m3[ten] ?? null,
                    ckhk2: m4[ten] ?? null,
                }
            })
        },
        formatPct(val) {
            if (val === null || val === undefined) return '—'
            return val + '%'
        },
        // SP trả Is_MonHoc=0 cho năng lực/phẩm chất; các loại đánh giá này dùng bộ cột chỉ tiêu riêng với môn học.
        getChiTieuFieldMap(ct) {
            if (ct?.Is_MonHoc === false || String(ct?.Is_MonHoc) === '0') {
                return { TiLe_HoanThanhTot: 'ChiTieu_Tot', TiLe_HoanThanh: 'ChiTieu_Dat', TiLe_ChuaHoanThanh: 'ChiTieu_CanCoGang' }
            }
            return { TiLe_HoanThanhTot: 'ChiTieu_HoanThanhTot', TiLe_HoanThanh: 'ChiTieu_HoanThanh', TiLe_ChuaHoanThanh: 'ChiTieu_ChuaHoanThanh' }
        },
        getTangGiam(row, field) {
            if (!this.hasChiTieu) return null
            const actual = row[this.activeKiKey]?.[field]
            const target = this.getChiTieuVal(row, field)
            if (actual == null || target == null) return null
            return Math.round((actual - target) * 100) / 100
        },
        getChiTieuVal(row, field) {
            if (!this.hasChiTieu) return null
            // Dòng TNXH/Khoa học đại diện cho hai MonHocID; gộp chỉ tiêu của cả hai theo cùng sĩ số đã đánh giá.
            if (row.ChiTieuMonHocIDs?.length > 1) {
                let weightedSum = 0
                let totalWeight = 0
                for (const monHocID of row.ChiTieuMonHocIDs) {
                    const ct = this.chiTieuMap.byID[monHocID]
                    if (!ct) continue
                    const targetField = this.getChiTieuFieldMap(ct)[field]
                    const value = ct[targetField]
                    const weight = Number(ct._targetWeights?.[targetField]) || 0
                    if (value == null || weight <= 0) continue
                    weightedSum += Number(value) * weight
                    totalWeight += weight
                }
                return totalWeight ? Math.round(weightedSum / totalWeight * 100) / 100 : null
            }
            const ct = (row.MonHocID && this.chiTieuMap.byID[row.MonHocID]) ?? this.chiTieuMap.byName[row.TenMonHoc_HienThi] ?? null
            if (!ct) return null
            const FM = this.getChiTieuFieldMap(ct)
            return ct[FM[field]] ?? null
        },
        formatTangGiam(row, field) {
            const v = this.getTangGiam(row, field)
            if (v === null) return '—'
            return (v > 0 ? '+' : '') + v + '%'
        },
        getTangGiamClass(row, field) {
            const v = this.getTangGiam(row, field)
            if (v === null) return ''
            return v > 0 ? 'text-success font-weight-bold' : v < 0 ? 'text-red font-weight-bold' : ''
        },
        exportExcel() {
            const wb = XLSX.utils.book_new()
            const t1 = document.getElementById('bc-table-1')
            const t2 = document.getElementById('bc-table-2')
            if (t1) {
                const ws1 = XLSX.utils.table_to_sheet(t1)
                XLSX.utils.book_append_sheet(wb, ws1, 'Môn học')
            }
            if (t2) {
                const ws2 = XLSX.utils.table_to_sheet(t2)
                XLSX.utils.book_append_sheet(wb, ws2, 'Năng lực - Phẩm chất')
            }
            const tenKhoi = this.KhoiItem?.TenKhoiHoc ?? 'Khoi'
            const nk = this.NienKhoaSelected?.NienKhoa ?? vueData.NienKhoa
            XLSX.writeFile(wb, 'BaoCao_DanhGia_' + tenKhoi + '_NK' + nk + '.xlsx')
        },
    },
	}
</script>