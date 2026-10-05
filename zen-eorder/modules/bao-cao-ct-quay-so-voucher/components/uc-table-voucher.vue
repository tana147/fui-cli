<template>
    <div>
        <v-card outlined elevation="0">
            <v-card-title align="end" class="py-2 px-3">
                <div class="primary--text text-left mb-2" style="font-weight: 500; font-size: 1.1rem">
                    Báo cáo voucher theo tổng chương trinh
                </div>
                <v-spacer></v-spacer>
                <v-btn icon color="primary" @click="toExcel"><v-icon>mdi-microsoft-excel</v-icon></v-btn>
                <v-text-field dense @input="updateSearch" prepend-inner-icon="mdi-magnify" label="" single-line
                    hide-details class="ml-3 flex-grow-0" style="width: 25%; min-width: 200px;"></v-text-field>
            </v-card-title>
            <v-data-table :key="keyTable" :headers="vueData.headers" :items="vueData.dataTable" :search="search"
                :custom-filter="customSearch" :item-class="getRowClass" :items-per-page="-1" show-expand
                :expanded.sync="vueData.DataExpanded" class="elevation-0 pa-0 tTable" :item-key="'ThuocTinh'" dense
                calculate-widths >
                <template v-slot:expanded-item="{ headers, item }">
                    <td :colspan="headers.length" class="pa-0">
                        <v-data-table label="" :key="subKeyTable"
                            :headers="vueData.subHeaders" :items="item.childRows" elevation="0" :item-class="getRowClass"
                            :items-per-page="-1" hide-default-footer dense>
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
            keyTable: 0,
            subKeyTable: 0,
            search: null,
            vueData
        }
    },
    watch: {
    },
    methods: {
        toExcel() {
            jsonToExcel({ data: vueData.dataTable, filename: 'bao_cao_voucher.xlsx' });
            Vue.$toast.success("Đã xuất Excel", { position: 'top' });
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
        }
    },
}
</script>