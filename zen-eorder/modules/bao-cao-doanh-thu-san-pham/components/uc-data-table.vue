<template>
    <div>
        <v-card outlined elevation="0">
            <v-card-title align="end" class="py-2 px-3">
                <div class="primary--text text-left mb-2 elevation-0" style="font-weight: 500; font-size: 1.1rem">
                    Báo cáo {{ isSoLuong? "số lượng" : "doanh thu" }} theo sản phẩm
                </div>
                <v-spacer></v-spacer>
                <v-btn icon color="primary" @click="toExcel"><v-icon>mdi-microsoft-excel</v-icon></v-btn>
                <v-text-field dense @input="updateSearch" prepend-inner-icon="mdi-magnify" label="" single-line
                    hide-details class="ml-3 flex-grow-0" style="width: 25%; min-width: 200px;"></v-text-field>
            </v-card-title>
            <v-data-table height="calc(100vh - 270px)" :headers="vueData.TableHeader" :items="vueData.DataReport"
                :search="search" :custom-filter="customSearch" :item-class="getRowClass" :items-per-page="50"
                show-expand :expanded.sync="vueData.DataExpanded" class="elevation-0 pa-0 tTable"
                :item-key="'SanPhamID'" dense calculate-widths @item-expanded="onExpandedTable"
                :footer-props="{ 'items-per-page-options': [50, 100, 150, 200, -1] }">
                <template v-slot:expanded-item="{ headers, item }" :key="keyTable">
                    <td :colspan="headers.length" class="pa-0" :key="keyTable">
                        <!-- Loading indicator for expanded row -->
                        <div v-if="expandLoading[item.SanPhamID + '_' + item.PhanHieuID]" class="pa-4 text-center">
                            <v-progress-circular indeterminate color="primary" size="24"></v-progress-circular>
                            <span class="ml-2">Đang tải dữ liệu chi tiết...</span>
                        </div>
                        <!-- class="table-visibility-collapse" -->
                        <v-data-table v-else label="" :headers="item.subHeader" :items="item.dataSubTable" elevation="0"
                            :item-class="getRowClass" :items-per-page="-1" hide-default-footer dense>
                            <template v-slot:item="{ item, headers }">
                               <tr>
                                    <!-- Lặp qua headers để render từng cell -->
                                    <td v-for="header in headers" :key="header.value" :class="['text-right', header.cellClass]">
                                        <!-- Dynamic columns with up/down icons -->
                                        <template v-if="header.value != 'sumRevenueFormatted' && header.value != 'TenCuaHang'">
                                            <div class="d-flex align-center justify-end">
                                                <v-icon v-if="item[header.value + '_isGrowth'] > 0" color="primary" small>
                                                    mdi-menu-up
                                                </v-icon> 
                                                <v-icon v-else-if="item[header.value + '_isGrowth'] < 0" color="red" small>
                                                    mdi-menu-down
                                                </v-icon>
                                                <span :style="{ color: item[header.value + '_isGrowth'] > 0 ? '#4caf50' : item[header.value + '_isGrowth'] < 0 ? '#f44336' : '#666' }">{{ item[header.value] }}</span>
                                            </div>
                                        </template>
                                        <!-- Total column (highlight) -->
                                        <template v-else-if="header.value === 'sumRevenueFormatted'">
                                            <span style="font-weight: bold; color: #d32f2f;">{{ item[header.value] }}</span>
                                        </template>
                                        <!-- Store name column -->
                                        <template v-else>
                                            <span style="color: #333;">{{ item[header.value] }}</span>
                                        </template>
                                    </td>
                                </tr>
                            </template>
                        </v-data-table>
                    </td>
                </template>
            </v-data-table>
        </v-card>

        <!-- Modal tiến trình lấy dữ liệu chi tiết -->
        <v-dialog v-model="showProgressModal" persistent centered width="450">
            <v-card small elevation="0" outlined>
                <v-card-title>
                    <div class="d-flex justify-space-between align-center" style="width: 100%;">
                        <h5 class="primary--text">Tiến trình lấy dữ liệu chi tiết</h5>
                    </div>
                </v-card-title>
                <v-card-text class="mx-auto">
                    <div class="pr-2 pl-2">
                        <v-progress-linear v-if="isExpandLoading" :value="expandProcessNum"></v-progress-linear>

                        <div v-if="expandProgressItems && expandProgressItems.length > 0" style="height: 600px; overflow-y: auto;">
                            <div v-for="item in expandProgressItems" :key="item.CuaHangID">
                                <v-list-item :class="{ 'error-row': item.status === 3 }">
                                    <v-list-item-content>
                                        <div :style="{ color: item.status === 3 ? '#f44336' : 'inherit', fontWeight: item.status === 3 ? 'bold' : 'normal' }">
                                            {{ item.TenCuaHang || ('Cửa hàng #' + item.CuaHangID) }}
                                        </div>
                                        <div style="font-size: 11px; color: #999; margin-top: 4px;">
                                            <span v-if="expandStartTimes[item.CuaHangID]">Start: {{ expandStartTimes[item.CuaHangID] }}</span>
                                            <span v-if="expandEndTimes[item.CuaHangID]" class="ml-3">End: {{ expandEndTimes[item.CuaHangID] }}</span>
                                            <span v-if="expandRequestTimes[item.CuaHangID] !== undefined" class="ml-3">
                                                {{ expandRequestTimes[item.CuaHangID] }} ms
                                            </span>
                                        </div>
                                        <div v-if="item.status === 3 && expandErrors[item.CuaHangID]" style="font-size: 11px; color: #f44336; margin-top: 4px;">
                                            <v-icon x-small color="red" class="mr-1">mdi-alert-circle</v-icon>
                                            {{ expandErrors[item.CuaHangID] }}
                                        </div>
                                    </v-list-item-content>
                                    <v-list-item-action>
                                        <v-btn v-if="item.status === 1" elevation="0" icon :loading="true" small />
                                        <v-icon v-else-if="item.status === 2" color="primary" small>mdi-check</v-icon>
                                        <v-btn v-else-if="item.status === 3" icon small @click.stop="retryExpandStore(item.CuaHangID)">
                                            <v-icon small>mdi-reload</v-icon>
                                        </v-btn>
                                    </v-list-item-action>
                                </v-list-item>
                                <v-divider />
                            </div>
                        </div>
                        <div v-else style="height: 200px; display: flex; align-items: center; justify-content: center;">
                            <span style="color: #999;">Đang chuẩn bị dữ liệu...</span>
                        </div>
                    </div>
                </v-card-text>

                <v-card-actions>
                    <v-spacer />
                    <v-btn color="red" text @click="closeExpandProgressModal" :disabled="isExpandLoading">Đóng</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>
<script>
export default {
    data() {
        return {
            subHeaderDefault: [
                {
                    text: 'Cửa hàng',
                    value: 'TenCuaHang',
                    width: 504,
                    align: 'right'
                },
                {
                    text: 'Tổng',
                    value: 'sumRevenueFormatted',
                    width: '100px',
                    align: 'right',
                    cellClass: "highlight-total"
                }
            ],
            keyTable: 0,
            subKeyTable: 0,
            search: null,
            vueData,
            // Progress modal state for expand
            showProgressModal: false,
            isExpandLoading: false,
            expandLoading: {},
            expandStatuses: Object.create(null),
            expandCompletedCount: 0,
            expandRequestTimes: Object.create(null),
            expandStartTimes: Object.create(null),
            expandEndTimes: Object.create(null),
            expandErrors: Object.create(null),
            expandStoreList: [],
            currentExpandItem: null
        }
    },
    watch: {
        "vueData.DataReport": function (x) {
            console.log(x)
        }
    },
    computed: {
        isSoLuong() {
            return this.vueData.FilterObject.IsSoLuong;
        },
        expandProcessNum() {
            const total = this.expandStoreList.length || 0;
            return total ? (this.expandCompletedCount / total) * 100 : 0;
        },
        expandProgressItems() {
            const nameMap = Object.create(null);
            const ds = Array.isArray(vueData.DSCuaHang) ? vueData.DSCuaHang : [];
            for (let i = 0; i < ds.length; i++) nameMap[ds[i].CuaHangID] = ds[i].TenCuaHang;

            return this.expandStoreList.map((id) => ({
                CuaHangID: id,
                TenCuaHang: nameMap[id],
                status: this.expandStatuses[id] ?? 0
            }));
        }
    },
    methods: {
        toExcel() {
            jsonToExcel({ data: this.vueData.DataReport, filename: 'bao_cao_doanh_thu_san_pham.xlsx' });
            Vue.$toast.success("Đã xuất Excel", { position: 'top' });
        },
        setExpandStatus(id, st) {
            this.$set(this.expandStatuses, id, st);
        },
        closeExpandProgressModal() {
            this.showProgressModal = false;
        },
        async onExpandedTable({ item, value }) {
            if (!value || item.TenSanPham === "Tổng" || item.sumRevenueCol == 0) return

            // Safely read selected store IDs from the global filter
            const selectedStoreIds = (vueData.FilterObject && Array.isArray(vueData.FilterObject.CuaHangIDs))
                ? vueData.FilterObject.CuaHangIDs
                : [];

            // Build params for a single store request
            const makeParams = (storeId) => ({
                ...vueData.FilterObject,
                SanPhamID: item.SanPhamID,
                PhanHieuID: item.PhanHieuID,
                CuaHangID: storeId,
                CuaHangIDs: undefined 
            })

            // Nếu chỉ có 1 cửa hàng, không cần hiển thị modal
            if (!selectedStoreIds || selectedStoreIds.length <= 1) {
                const expandKey = item.SanPhamID + '_' + item.PhanHieuID;
                this.$set(this.expandLoading, expandKey, true);
                
                const params = makeParams(selectedStoreIds[0] ? selectedStoreIds[0] : null)
                ajaxCALL('/eorder/BaoCao_DoanhThu_SanPham_byPhanHieuId_v2', params, (res) => {
                    this.$set(this.expandLoading, expandKey, false);
                    this.buildReportTable(res.data, item)
                })
                return
            }

            // Nhiều cửa hàng - hiển thị modal progress
            this.currentExpandItem = item;
            this.expandStatuses = Object.create(null);
            this.expandCompletedCount = 0;
            this.expandStoreList = selectedStoreIds.slice();
            this.expandRequestTimes = Object.create(null);
            this.expandStartTimes = Object.create(null);
            this.expandEndTimes = Object.create(null);
            this.expandErrors = Object.create(null);

            // Set status loading cho tất cả
            for (let i = 0; i < selectedStoreIds.length; i++) {
                this.setExpandStatus(selectedStoreIds[i], 1);
            }

            this.isExpandLoading = true;
            this.showProgressModal = true;

            await this.$nextTick();

            // Tạo danh sách task để chạy song song
            const CONCURRENCY = 5;
            const tasks = selectedStoreIds.map(id => () => this.fetchExpandStore(id, makeParams(id)));
            const results = await this.runWithConcurrency(tasks, CONCURRENCY);

            // Gom dữ liệu
            const combined = results.filter(r => r && r.ok).flatMap(r => r.data || []);
            
            this.isExpandLoading = false;
            this.buildReportTable(combined, item);
        },

        async fetchExpandStore(CuaHangID, params) {
            const start = performance.now();
            const startTime = new Date().toLocaleTimeString('vi-VN');
            this.$set(this.expandStartTimes, CuaHangID, startTime);

            try {
                const body = JSON.stringify(params);

                const res = await fetch(vueData.v_Set?.apiDomain + "/eorder/BaoCao_DoanhThu_SanPham_byPhanHieuId_v2", {
                    method: "POST",
                    headers: {
                        "content-type": "application/json; charset=utf-8",
                        "authorization": $awt
                    },
                    body
                });

                const end = performance.now();
                const endTime = new Date().toLocaleTimeString('vi-VN');
                this.$set(this.expandRequestTimes, CuaHangID, Math.round(end - start));
                this.$set(this.expandEndTimes, CuaHangID, endTime);

                if (res.ok) {
                    const json = await res.json();
                    if (json && json.data) {
                        this.setExpandStatus(CuaHangID, 2); // done
                        this.expandCompletedCount += 1;
                        return { ok: true, storeId: CuaHangID, data: Array.isArray(json.data) ? json.data : [] };
                    } else {
                        this.setExpandStatus(CuaHangID, 2);
                        this.expandCompletedCount += 1;
                        return { ok: true, storeId: CuaHangID, data: [] };
                    }
                } else {
                    this.setExpandStatus(CuaHangID, 3); // error
                    this.$set(this.expandErrors, CuaHangID, `HTTP Error: ${res.status} ${res.statusText}`);
                    this.expandCompletedCount += 1;
                    return { ok: false, storeId: CuaHangID, data: [] };
                }
            } catch (error) {
                const endTime = new Date().toLocaleTimeString('vi-VN');
                this.$set(this.expandEndTimes, CuaHangID, endTime);
                this.setExpandStatus(CuaHangID, 3); // error
                this.$set(this.expandErrors, CuaHangID, error.message || 'Unknown error');
                this.expandCompletedCount += 1;
                return { ok: false, storeId: CuaHangID, data: [], errMsg: error.message };
            }
        },

        async runWithConcurrency(tasks, limit) {
            const results = new Array(tasks.length);
            let idx = 0, running = 0;
            return new Promise((resolve) => {
                const launchNext = () => {
                    while (running < limit && idx < tasks.length) {
                        const current = idx++;
                        running++;
                        tasks[current]()
                            .then(r => { results[current] = r; })
                            .catch(e => { results[current] = { ok: false, storeId: null, errMsg: e?.message || 'error' }; })
                            .finally(() => {
                                running--;
                                if (idx >= tasks.length && running === 0) resolve(results);
                                else launchNext();
                            });
                    }
                };
                launchNext();
            });
        },

        async retryExpandStore(id) {
            if (this.isExpandLoading && this.expandStatuses[id] === 1) return;

            this.expandCompletedCount = Math.max(0, this.expandCompletedCount - (this.expandStatuses[id] === 2 ? 1 : 0));
            this.setExpandStatus(id, 1);

            const item = this.currentExpandItem;
            if (!item) return;

            const params = {
                ...vueData.FilterObject,
                SanPhamID: item.SanPhamID,
                PhanHieuID: item.PhanHieuID,
                CuaHangID: id,
                CuaHangIDs: undefined
            };

            await this.fetchExpandStore(id, params);
        },
        buildReportTable(subData, rowTarget) {
            console.log("buildReportTable", subData)
            if (!subData?.length || !rowTarget) return

            const [dynamicVariables, dataRaw] = vueData.DataRaw || []
            const [aliasKey] = Object.keys(dynamicVariables[0])

            const subDataMap = new Map()
            const subDataRefactor = subData.map(e => ({
                ...e,
                [aliasKey]: e.HinhThucThoiGian
            }))

            subDataRefactor.forEach(item => {
                const key = `spID${item.SanPhamID}_phID${item.PhanHieuID}_chID${item.CuaHangID}_time${item[aliasKey]}`
                subDataMap.set(key, item)
            })

            const uniqueStores = [...new Map(
                subDataRefactor.map(item => [item.CuaHangID, {
                    TenCuaHang: item.TenCuaHang,
                    CuaHangID: item.CuaHangID,
                    SanPhamID: item.SanPhamID,
                    PhanHieuID: item.PhanHieuID,
                    TenPhanHieu: item.TenPhanHieu,
                    TenSanPham: item.TenSanPham
                }])
            ).values()]

            const dataTable = uniqueStores.map(store => {
                const subRow = { ...store, sumRevenueCol: 0 }

                vueData.dynamicHeaders.forEach(head => {
                    const timeValue = head[aliasKey]
                    const key = `spID${store.SanPhamID}_phID${store.PhanHieuID}_chID${store.CuaHangID}_time${timeValue}`
                    const data = subDataMap.get(key)
                    const GiaTriBaoCao = data ? parseFloat(data.GiaTriBaoCao) || 0 : 0

                    subRow[head.value] = GiaTriBaoCao.toLocaleString("vi-vn")  // formatPrice(GiaTriBaoCao)
                    subRow[head.value + '_value'] = GiaTriBaoCao
                    subRow.sumRevenueCol += GiaTriBaoCao
                })

                subRow.sumRevenueFormatted = subRow.sumRevenueCol.toLocaleString("vi-vn")  //formatPrice(subRow.sumRevenueCol)
                return subRow
            })

            const dataTableWithGrowth = dataTable.map(rowItem => {
                const newRow = { ...rowItem }
                vueData.dynamicHeaders.forEach((head, index, arr) => {
                    if (index === 0) {
                        newRow[head.value + '_isGrowth'] = 0
                    } else {
                        const current = rowItem[head.value + '_value']
                        const prev = rowItem[arr[index - 1].value + '_value']
                        newRow[head.value + '_isGrowth'] = this.getGrowth(current, prev)
                    }
                })
                return newRow
            })

            // Cập nhật đúng 1 dòng (rowTarget)
            const targetIndex = vueData.DataReport.findIndex(r =>
                r.SanPhamID === rowTarget.SanPhamID && r.PhanHieuID === rowTarget.PhanHieuID
            )
            if (targetIndex !== -1) {
                vueData.DataReport[targetIndex] = {
                    ...vueData.DataReport[targetIndex],
                    subHeader: [...this.subHeaderDefault, ...vueData.dynamicHeaders],
                    dataSubTable: dataTableWithGrowth
                }
            }
            vueData.DataReport = [...vueData.DataReport]

            this.keyTable++
        },
        suffixColumn(col) {
            if (col === 'Gio') return 'H'
            return ''
        },
        preflixColumn(col) {
            switch (col) {
                case 'Tuan': return 'Tuần'
                case 'Thang': return 'Tháng'
                case 'Quy': return 'Quý'
                default: return ''
            }
        },
        formatDaily(str) {
            return moment(str).format("D/M")
        },
        formatString(str) {
            if (!str) return

            return str
                .normalize("NFD")                     // Tách dấu khỏi ký tự gốc
                .replace(/[\u0300-\u036f]/g, "")      // Xoá dấu
                .replace(/[^a-zA-Z0-9 ]/g, "")        // Bỏ ký tự đặc biệt, giữ chữ/số/khoảng trắng
                .trim()                               // Bỏ khoảng trắng đầu/cuối
                .replace(/\s+/g, "_");                // Thay khoảng trắng bằng _
        },
        updateSearch: _.debounce(function (text) {
            this.search = text;
        }, 300),
        customSearch(value, search, item) {
            const normalizedSearch = (search || '').toLowerCase()
            return Object.values(item).some(v => {
                try {
                    return v?.toString().toLowerCase().includes(normalizedSearch)
                } catch {
                    return false
                }
            })
        },
        getGrowth(current, prev) {
            if (current > prev) return 1
            if (current < prev) return -1
            return 0
        }


    },
}
</script>