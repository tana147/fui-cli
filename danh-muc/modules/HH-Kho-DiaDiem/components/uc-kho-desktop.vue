<template>
    <v-data-table :items="items" :headers="headers" height="calc(100vh - 216px)" density="compact"
        item-value="HangHoa_Id" fixed-header :items-per-page="itemsPerPage" @click:row="onClickRow"
        :row-props="getRowProps" items-per-page-text="Bản ghi" :items-per-page-options="[50, 100, 200]">
        <template v-slot:item.TenHangHoa="{ item }">
            <span>{{ item.TenHangHoa }}</span>
            <span v-if="item.Is_CaBiet" class="badge-tai-san ml-2">Tài sản</span>
            <span v-else-if="item.LoaiHangHoa === 'CCDC'" class="badge-ccdc ml-2">CCDC</span>
            <span v-else class="badge-nvl ml-2">NVL</span>
        </template>
        <template v-slot:item.Is_CaBiet="{ item }">
            <v-icon v-if="item.Is_CaBiet" color="primary">mdi-check</v-icon>
        </template>
        <template #no-data>
            <uc-empty text="Chưa có hàng hoá để hiển thị" />
        </template>
    </v-data-table>

    <!-- Drawer chi tiết -->
    <v-navigation-drawer v-model="drawerOpen" location="right" temporary :width="560" :scrim="false"
        style="z-index: 1010; position: fixed">
        <template v-if="selected">
            <!-- Drawer header -->
            <v-toolbar density="compact" color="primary" :title="selected.TenHangHoa">
                <template v-slot:append>
                    <v-btn icon="mdi-close" variant="text" @click="drawerOpen = false" />
                </template>
            </v-toolbar>

            <!-- Summary -->
            <div class="d-flex ga-3 pa-3 border-b text-body-2">
                <div>
                    Tổng: <b class="text-primary">{{ selected.Tong }}</b>
                </div>
                <div>
                    Trong kho: <b>{{ selected.TrongKho }}</b>
                </div>
                <div>
                    Đang SD: <b>{{ selected.DangSuDung }}</b>
                </div>
                <div>
                    <span v-if="selected.Is_CaBiet" class="badge-tai-san">Tài sản</span>
                    <span v-else-if="selected.LoaiHangHoa === 'CCDC'" class="badge-ccdc">CCDC</span>
                    <span v-else class="badge-nvl">NVL</span>
                </div>
            </div>

            <!-- Body -->
            <div class="kho-drawer-body">
                <!-- CaBiet list -->
                <template v-if="selected.Is_CaBiet && selected.DSCaBiet?.length">
                    <div v-for="cb in selected.DSCaBiet" :key="cb.CaBiet_Id" class="kho-drawer-card">
                        <div class="d-flex align-center justify-space-between mb-1">
                            <div class="text-body-2 font-weight-medium">{{ cb.SoSeries }}</div>
                            <div class="d-flex align-center ga-1">
                                <v-chip :color="mapTinhTrangHangHoaCaBiet[cb.TinhTrang]?.color" size="x-small"
                                    variant="tonal">
                                    {{ mapTinhTrangHangHoaCaBiet[cb.TinhTrang]?.text }}
                                </v-chip>
                                <v-menu>
                                    <template v-slot:activator="{ props }">
                                        <v-btn size="x-small" variant="text" v-bind="props" icon="mdi-dots-vertical" />
                                    </template>
                                    <v-list density="compact">
                                        <v-list-item @click.stop="$emit('on-edit-ca-biet', cb)"
                                            prepend-icon="mdi-square-edit-outline" title="Cập nhật" />
                                    </v-list>
                                </v-menu>
                            </div>
                        </div>
                        <div class="text-caption text-medium-emphasis">
                            Mã vạch: {{ cb.MaVach || 'Chưa có' }}
                        </div>
                        <div class="d-flex ga-4 text-caption mt-1">
                            <span class="text-medium-emphasis">{{ cb.TenKhuVuc || 'Chưa có' }}</span>
                        </div>
                        <div class="kho-cb-info-grid mt-2">
                            <div class="kho-cb-info-item">
                                <div class="text-caption text-medium-emphasis">BĐ bảo hành</div>
                                <div class="text-body-2">{{ formatDate(cb.NgayBatDauBaoHanh) || '—' }}</div>
                            </div>
                            <div class="kho-cb-info-item">
                                <div class="text-caption text-medium-emphasis">KT bảo hành</div>
                                <div class="text-body-2">{{ formatDate(cb.NgayKetThucBaoHanh) || '—' }}</div>
                            </div>
                        </div>
                    </div>
                </template>

                <!-- SoLuong list -->
                <template v-if="!selected.Is_CaBiet && selected.DSSoLuong?.length">
                    <div v-for="(sl, idx) in selected.DSSoLuong" :key="idx" class="kho-drawer-card">
                        <div class="d-flex align-center justify-space-between">
                            <div class="d-flex ga-4 text-body-2">
                                <span>Khu vực: {{ sl.TenKhuVuc }}</span>
                                <span>SL: <b class="text-primary">{{ sl.SoLuong }}</b></span>
                            </div>
                            <v-menu>
                                <template v-slot:activator="{ props }">
                                    <v-btn size="x-small" variant="text" v-bind="props" icon="mdi-dots-vertical" />
                                </template>
                                <v-list density="compact">
                                    <v-list-item @click.stop="$emit('on-luan-chuyen', sl, selected)"
                                        prepend-icon="mdi-swap-horizontal" title="Luân chuyển" />
                                </v-list>
                            </v-menu>
                        </div>
                    </div>
                </template>
            </div>

            <!-- Drawer footer - navigation -->
            <div class="kho-drawer-footer border-t pa-2 d-flex align-center justify-space-between">
                <v-btn size="small" variant="text" prepend-icon="mdi-chevron-left" :disabled="selectedIndex <= 0"
                    @click="navigate(-1)">Trước</v-btn>
                <span class="text-caption text-medium-emphasis">
                    {{ selectedIndex + 1 }} / {{ items.length }}
                </span>
                <v-btn size="small" variant="text" append-icon="mdi-chevron-right"
                    :disabled="selectedIndex >= items.length - 1" @click="navigate(1)">Sau</v-btn>
            </div>
        </template>
    </v-navigation-drawer>
</template>

<script>
export default {
    props: {
        items: { type: Array, default: function () { return [] } },
    },
    emits: ['on-edit-ca-biet', 'on-luan-chuyen'],
    data: function () {
        return {
            mapTinhTrangHangHoaCaBiet,
            drawerOpen: false,
            selected: null,
            selectedIndex: -1,
            itemsPerPage: 50,
            headers: [
                { title: 'Tên hàng hoá', key: 'TenHangHoa', align: 'start' },
                { title: 'Số lượng', key: 'Tong', align: 'end', width: 150 },
                { title: 'Trong kho', key: 'TrongKho', align: 'end', width: 150 },
                { title: 'Đang sử dụng', key: 'DangSuDung', align: 'end', width: 150 },
                { title: 'Tài sản', key: 'Is_CaBiet', align: 'center', width: 150 },
            ],
        }
    },
    methods: {
        formatDate: window.formatDate,

        onClickRow: function (event, row) {
            var item = row.item
            this.selectedIndex = this.items.findIndex(function (x) { return x.HangHoa_Id === item.HangHoa_Id })
            this.selected = item
            this.drawerOpen = true
        },

        getRowProps: function (row) {
            if (this.selected && row.item.HangHoa_Id === this.selected.HangHoa_Id) {
                return { class: 'bg-blue-lighten-5' }
            }
            return {}
        },

        navigate: function (direction) {
            var newIdx = this.selectedIndex + direction
            if (newIdx < 0 || newIdx >= this.items.length) return
            this.selectedIndex = newIdx
            this.selected = this.items[newIdx]
        },
    },
}
</script>
