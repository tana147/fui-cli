<template>
    <div>
        <v-card outlined elevation="0">
            <v-card-title align="end" class="py-2 px-3">
                <div class="primary--text text-left mb-2" style="font-weight: 500; font-size: 1.1rem">
                    Báo cáo {{ vueData.isReportDoanhThu ? 'số lượng' : 'doanh thu' }} phân loại ly
                </div>
                <v-spacer></v-spacer>
                <v-btn icon color="primary" @click="toExcel"><v-icon>mdi-microsoft-excel</v-icon></v-btn>
            </v-card-title>
            <v-data-table height="calc(100vh - 236px)" :key="keyTable" :headers="vueData.TableHeader"
                :items="vueData.DataReport" :item-class="getRowClass" :hide-default-footer="false" show-expand
                :expanded.sync="vueData.DataExpanded" class="elevation-0 pa-0 tTable" :item-key="'LoaiLyID'" :items-per-page="-1"
                dense calculate-widths @item-expanded="onExpandedTable" :keyTable="keyTable">
                <template v-slot:expanded-item="{ headers, item }">
                    <td :colspan="headers.length" class="pa-0">
                        <!-- class="table-visibility-collapse" -->
                        <v-data-table label="Báo cáo số lượng ly" :headers="item.subHeader" :items="item.dataSubTable"
                            elevation="0" :item-class="getRowClass" :items-per-page="-1" hide-default-footer dense>
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
                                               <span :style="{ color: item[header.value + '_isGrowth'] > 0 ? '#4caf50' : item[header.value + '_isGrowth'] < 0 ? '#f44336' : '#666' }">{{ item[header.value].toLocaleString("vi-vn")  }}</span>
                                            </div>
                                        </template>
                                        <!-- Total column (highlight) -->
                                        <template v-else-if="header.value === 'sumRevenueFormatted'">
                                            <span style="font-weight: bold; color: #d32f2f;">{{ item[header.value].toLocaleString("vi-vn")  }}</span>
                                        </template>
                                        <!-- Store name column -->
                                        <template v-else>
                                            <span style="color: #333;">{{ item[header.value].toLocaleString("vi-vn")  }}</span>
                                        </template>
                                    </td>
                                </tr>
                            </template>
                        </v-data-table>
                    </td>
                </template>
            </v-data-table>
        </v-card>
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
            vueData
        }
    },
    methods: {
        toExcel() {
            jsonToExcel({ data: vueData.DataReport, filename: 'bao_cao_so_luong_ly.xlsx' });
            Vue.$toast.success("Đã xuất Excel", { position: 'top' });
        },

        onExpandedTable({ item, value }) {
            if (!value || item.TenNhomSanPhamBaoCao === "Tổng" || item.sumRevenueCol == 0) return
            const params = { ...vueData.FilterObject, LoaiLyID: item.LoaiLyID, PhanHieuID: item.PhanHieuID }
            ajaxCALL('/eorder/BaoCao_DoanhThu_PhanLoaiLy_byPhanHieuId', params, (res) => {
                this.sanitizeReponse(res.data, item)
            })
        },

        sanitizeReponse(subData, row) {
            if (!subData || subData.length === 0) return
            this.buildReportTable(subData, row)
        },

        buildReportTable(subData, row) {
            [groupItemReport, dynamicVariables, dataRaw] = vueData.DataRaw
            const [TenNhomSanPhamBaoCao, TenPhanHieu, NhomSanPham_BaoCaoID, PhanHieuID] = Object.keys(groupItemReport[0])

            const [aliasKey] = Object.keys(dynamicVariables[0])
            const isDaily = aliasKey === 'Ngay'

            // Re-map HinhThucThoiGian
            const subDataRefactor = subData.map(e => ({
                ...e,
                [aliasKey]: e.HinhThucThoiGian
            }))

            row.subHeader = [...this.subHeaderDefault, ...vueData.dynamicHeaders]

            row.subData = subDataRefactor.filter(x => x.PhanHieuID == row.PhanHieuID)

            const subDataMap = new Map()
            row.subData.forEach(item => {
                const key = `subTable_chID${item.CuaHangID}_phID${item[PhanHieuID]}_time${item[aliasKey]}`
                subDataMap.set(key, item)
            })

            const seen = new Set()

            const uniqueRow = row.subData.filter(item => {
                const key = `${item.NhomSanPham_BaoCaoID}_${item.CuaHangID}`
                if (seen.has(key)) return false
                seen.add(key)
                return true
            }).map(item => ({
                TenNhomSanPhamBaoCao: item.TenNhomSanPhamBaoCao,
                NhomSanPham_BaoCaoID: item.NhomSanPham_BaoCaoID,
                TenCuaHang: item.TenCuaHang,
                CuaHangID: item.CuaHangID,
                PhanHieuID: item.PhanHieuID,
                TenPhanHieu: item.TenPhanHieu
            }))

            // build dataTable + sum 
            const dataTable = uniqueRow.map(brand => {
                const subRow = { ...brand, sumRevenueCol: 0 }

                vueData.dynamicHeaders.forEach(head => {
                    const key = `subTable_chID${brand.CuaHangID}_phID${brand[PhanHieuID]}_time${head[aliasKey]}`
                    const data = subDataMap.get(key)
                    const GiaTriBaoCao = data ? (parseFloat(data.GiaTriBaoCao) || 0) : 0

                    subRow[head.value] = GiaTriBaoCao
                    subRow.sumRevenueCol += GiaTriBaoCao
                })

                subRow.sumRevenueFormatted = subRow.sumRevenueCol
                return subRow
            })

            // thêm cờ tăng/giảm giống component “sản phẩm”
            const dataTableWithGrowth = dataTable.map(rowItem => {
                const newRow = { ...rowItem }
                vueData.dynamicHeaders.forEach((head, index, arr) => {
                    if (index === 0) {
                        newRow[head.value + '_isGrowth'] = 0
                    } else {
                        const current = rowItem[head.value]
                        const prev = rowItem[arr[index - 1].value]
                        newRow[head.value + '_isGrowth'] = this.getGrowth(current, prev)
                    }
                })
                return newRow
            })

            row.dataSubTable = dataTableWithGrowth
            this.keyTable++
        },

        getGrowth(current, prev) {
            if (current > prev) return 1
            if (current < prev) return -1
            return 0
        },
        getRowClass(item) {
            return ''
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
                .normalize("NFD")
                .replace(/[\u0300-\u036f]/g, "")
                .replace(/[^a-zA-Z0-9 ]/g, "")
                .trim()
                .replace(/\s+/g, "_")
        }
    }
}

</script>