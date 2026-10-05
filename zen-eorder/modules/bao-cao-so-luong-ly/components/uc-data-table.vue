<template>
    <div >
        <v-card outlined elevation="0">
            <v-card-title align="end" class="py-2 px-3">
                <div class="primary--text text-left mb-2" style="font-weight: 500; font-size: 1.1rem">
                    Báo cáo số lượng ly
                </div>
                <v-spacer></v-spacer>
                <v-btn icon color="primary" @click="toExcel"><v-icon>mdi-microsoft-excel</v-icon></v-btn>
            </v-card-title>
            <v-data-table height="calc(100vh - 233px)" :key="keyTable" :headers="vueData.TableHeader" :items="vueData.DataReport" :item-class="getRowClass"
                :hide-default-footer="false" show-expand :expanded.sync="vueData.DataExpanded" class="elevation-0 pa-0 tTable"
               :item-key="'TenNhomSanPhamBaoCao'" :items-per-page="-1" dense calculate-widths
                @item-expanded="onExpandedTable">
                <template v-slot:expanded-item="{ headers, item }">
                    <td :colspan="headers.length" class="pa-0">
                        <v-data-table class="table-visibility-collapse" label="Báo cáo số lượng ly"
                            :headers="item.subHeader" :items="item.dataSubTable" elevation="0" :item-class="getRowClass"
                            :items-per-page="-1" hide-default-footer dense />
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
    watch: {
    },
    methods: {
        toExcel() {
            jsonToExcel({ data: vueData.DataReport, filename: 'bao_cao_so_luong_ly.xlsx'});
            Vue.$toast.success("Đã xuất Excel", { position: 'top' });
        },
        onExpandedTable({ item, value }) {
            if (!value || item.TenNhomSanPhamBaoCao === "Tổng" || item.sumRevenueCol == 0) return
            const params = { ...vueData.FilterObject, NhomSanPham_BaoCaoID: item.NhomSanPham_BaoCaoID, PhanHieuID: item.PhanHieuID }
            ajaxCALL('/eorder/BaoCao_SoLuongLy_byPhanHieuID', params, (res) => {
                 if (!res.data || res.data.length === 0) 
                    return

                 this.buildReportTable(res.data, item)
            })
        },
        buildReportTable(subData, row) {
            [groupItemReport, dynamicVariables, dataRaw] = vueData.DataRaw
            const [TenNhomSanPhamBaoCao, TenPhanHieu, NhomSanPham_BaoCaoID, PhanHieuID] = Object.keys(groupItemReport[0])

            const [aliasKey] = Object.keys(dynamicVariables[0])
            const isDaily = aliasKey === 'Ngay'

            // remap
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
                // Ghép các field để tạo khóa duy nhất
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

            const dataTable = uniqueRow.map(brand => {
                const subRow = { ...brand, sumRevenueCol: 0 }

                vueData.dynamicHeaders.forEach(head => {
                    const key = `subTable_chID${brand.CuaHangID}_phID${brand[PhanHieuID]}_time${head[aliasKey]}`
                    const data = subDataMap.get(key)

                    const soLuong = data ? data.SoLuong : 0

                    subRow[head.value] = formatPrice(soLuong)
                    subRow[head.value + '_value'] = soLuong
                    subRow.sumRevenueCol += soLuong
                })
                subRow.sumRevenueFormatted = formatPrice(subRow.sumRevenueCol)
                return subRow
            })
            row.dataSubTable = Object.assign([], dataTable)

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
        }
    },
}
</script>