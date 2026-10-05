<template>
	<div>
        <v-card outlined elevation="0" v-for="(table, idx) in vueData.dataTable">
            <v-card-title align="end" class="py-2 px-3">
                <div class="primary--text text-left mb-2" style="font-weight: 500; font-size: 1.1rem">
                    {{ titleDynamic[idx] }}
                </div>
                <v-spacer></v-spacer>
                <v-btn icon color="primary" @click="toExcel">
                    <v-icon>mdi-microsoft-excel</v-icon>
                </v-btn>
                <v-text-field dense @input="updateSearch" prepend-inner-icon="mdi-magnify" label="" single-line
                    hide-details class="ml-3 flex-grow-0" style="width: 25%; min-width: 200px;"></v-text-field>
            </v-card-title>
            <v-data-table :key="'table-' + idx" :headers="vueData.headers" :items="table" :search="searchStates"
                :custom-filter="customSearch" :items-per-page="-1" show-expand :expanded.sync="expandedStates[idx]"
                class="elevation-0 pa-0 tTable" :item-key="'MaChuongTrinh'" dense calculate-widths>
                <template v-slot:expanded-item="{ headers, item }">
                    <td :colspan="headers.length" class="pa-0">
                        <v-data-table  label=""
                            :key="'table-' + idx + '-' + keyTable" :headers="vueData.subHeaders" :items="item.childRows"
                            elevation="0" :items-per-page="-1" hide-default-footer dense>
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
            searchStates: [],
            expandedStates: [], // mỗi bảng 1 expanded list riêng
            titleDynamic: [
                'Báo cáo voucher nhận của tổng chương trinh theo cửa hàng',
                'Báo cáo voucher quét của tổng chương trinh theo cửa hàng',
                'Báo cáo voucher đổi của tổng chương trinh theo cửa hàng'
            ],
            vueData
        }
    },
    watch: {
    },
    created() {
        this.searchStates = vueData.dataTable.map(() => null);
        this.expandedStates = vueData.dataTable.map(() => []);
    },
    methods: {
        toExcel(idx) {
            const data = this.searchStates[idx]
                ? this.vueData.dataTable[idx].filter(row =>
                    this.customSearch(null, this.searchStates[idx], row))
                : this.vueData.dataTable[idx];
            jsonToExcel({ data, filename: `bao_cao_voucher_${idx + 1}.xlsx` });
            Vue.$toast.success("Đã xuất Excel", { position: 'top' });
        },
        updateSearch: _.debounce(function (text) {
            this.searchStates[idx] = text;
        }, 300),
        customSearch(value, search, item) {
            const normalizedSearch = (search || '').toLowerCase();
            return ['MaChuongTrinh', 'TenChuongTrinh', 'TenCuaHang']
                .some(field => item[field]?.toString().toLowerCase().includes(normalizedSearch));
        },
    },
	}
</script>