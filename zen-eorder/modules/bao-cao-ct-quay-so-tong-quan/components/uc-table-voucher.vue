<template>
    <div>
        <v-card outlined elevation="0">
            <v-card-title align="end" class="py-2 px-3">
                <div class="primary--text text-left mb-2" style="font-weight: 500; font-size: 1.1rem">
                    Báo cáo voucher tổng quan
                </div>
                <v-spacer></v-spacer>
                <v-btn icon color="primary" @click="toExcel"><v-icon>mdi-microsoft-excel</v-icon></v-btn>
                <v-text-field dense @input="updateSearch" prepend-inner-icon="mdi-magnify" label="" single-line
                    hide-details class="ml-3 flex-grow-0" style="width: 25%; min-width: 200px;"></v-text-field>
            </v-card-title>
            <v-data-table height="calc(100vh - 245px)" :key="keyTable" :headers="vueData.headers"
                :items="vueData.dataTable" :search="search" :custom-filter="customSearch" 
                :items-per-page="-1" show-expand :expanded.sync="vueData.DataExpanded" class="elevation-0 pa-0 tTable"
                :item-key="'Muc'" dense calculate-widths>
                <template v-slot:expanded-item="{ headers, item }">
                    <td :colspan="headers.length" class="pa-0">
                        <!-- //table-visibility-collapse -->
                        <v-data-table class=" elevation-0 pa-0 tTable" label=""
                            :key="subKeyTable" :headers="vueData.subHeaders" :items="item.childRows" elevation="0"
                             :items-per-page="-1" hide-default-footer dense>
                            <template v-slot:item="{ item, headers }">
                                <tr>
                                    <!-- Lặp qua headers để render từng cell -->
                                    <td v-for="header in headers" :key="header.value" class="text-right">
                                        <!-- Các cột động -->
                                        <template v-if="header.value != 'sumFormatted' && header.value != 'Muc' ">
                                            <div class="d-flex align-center justify-end">
                                                <v-icon v-if="item[header.value + '_isGrowth'] > 0"
                                                    color="primary" >
                                                    mdi-menu-up
                                                </v-icon>
                                                <v-icon v-else-if="item[header.value + '_isGrowth'] < 0"
                                                    color="red" >
                                                    mdi-menu-down
                                                </v-icon>
                                                <v-icon small v-else-if="item[header.value + '_isGrowth'] == 0"
                                                    color="orange" >
                                                    mdi-minus
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