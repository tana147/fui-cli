<template>
    <v-dialog v-model="isShow" max-width="1300" scrollable>
        <v-card>
            <template v-slot:title>Cập nhật công cụ dụng cụ</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
            </template>

            <v-card-text class="pa-0" style="padding-top: 0 !important;">
                <v-sheet class="d-flex supplier-tabs-sheet" elevation="0">
                    <v-tabs v-model="activeTab" color="primary" direction="vertical" class="supplier-tabs-nav">
                        <v-tab value="THONG_TIN" prepend-icon="mdi-information-slab-circle-outline">Thông tin</v-tab>
                        <v-tab value="CHUYEN_DOI_DON_VI" prepend-icon="mdi-swap-horizontal">Chuyển đổi đơn vị</v-tab>
                        <v-tab value="TON_TOI_THIEU" prepend-icon="mdi-warehouse">Tồn tối thiểu</v-tab>
                        <v-tab value="DIA_DIEM_AP_DUNG" prepend-icon="mdi-map-marker-outline">Địa điểm áp dụng</v-tab>
                    </v-tabs>
                    <v-divider vertical></v-divider>
                    <v-tabs-window v-model="activeTab" class="flex-fill supplier-tabs-window">
                        <v-tabs-window-item value="THONG_TIN">
                            <uc-update-info :selectedItem="selectedItem" :DSNhomTinhChat="DSNhomTinhChat"
                                :DSNhomVTHH="DSNhomVTHH" :DSNhomTenSanPham="DSNhomTenSanPham"
                                :DSDonViTinh="DSDonViTinh"></uc-update-info>
                        </v-tabs-window-item>

                        <v-tabs-window-item value="CHUYEN_DOI_DON_VI">
                            <uc-update-chuyen-doi-don-vi v-if="isLoading" :selectedItem="selectedItem"
                                :tableData="DSDoiDonVi" :DSDonViTinh="DSDonViTinh"
                                @load-doi-don-vi="onLoadDoiDonVi"></uc-update-chuyen-doi-don-vi>
                        </v-tabs-window-item>

                        <v-tabs-window-item value="TON_TOI_THIEU">
                            <uc-update-ton-toi-thieu v-if="isLoading" :selectedItem="selectedItem"
                                :tableData="DSTonToiThieu" :DSDiaDiem="DSDiaDiem"
                                @load-ton-toi-thieu="onLoadTonToiThieu"></uc-update-ton-toi-thieu>
                        </v-tabs-window-item>

                        <v-tabs-window-item value="DIA_DIEM_AP_DUNG">
                            <uc-update-dia-diem-ap-dung v-model:DSDiaDiemApDung="DSDiaDiemApDung" :DSDiaDiem="DSDiaDiem"
                                :selectedItem="selectedItem"
                                @load-dia-diem-ap-dung="onLoadDiaDiemApDung"></uc-update-dia-diem-ap-dung>
                        </v-tabs-window-item>
                    </v-tabs-window>
                </v-sheet>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: {
        isShow: Boolean,
        selectedItem: Object,
        DSNhomTinhChat: Array,
        DSNhomVTHH: Array,
        DSNhomTenSanPham: Array,
        DSDonViTinh: Array,
        DSDiaDiem: Array,
    },
    emits: ['update:isShow', 'reload'],
    data() {
        return {
            activeTab: 'THONG_TIN',
            isLoading: false,

            DSDiaDiemApDung: [],
            DSDoiDonVi: [],
            DSTonToiThieu: []
        }
    },
    watch: {
        activeTab: function (value) {
            switch (value) {
                case 'CHUYEN_DOI_DON_VI':
                    this.loadDSDoiDonVi()
                    break;
                case 'TON_TOI_THIEU':
                    this.loadDSTonToiThieu()
                    break;
                case 'DIA_DIEM_AP_DUNG':
                    this.loadDSDiaDiemApDung()
                    break
            }
        }
    },
    methods: {
        closeDialog() {
            this.activeTab = 'THONG_TIN'
            this.$emit('update:isShow', false)
            this.$emit('reload')
        },

        async loadDSDoiDonVi() {
            this.isLoading = false
            const params = {
                HangHoa_Id: this.selectedItem.HangHoa_Id,
            }
            const data = await apiCallPromise('work/HH_HangHoaQuyDoi_Select_By_HangHoa_Id', params)
            this.DSDoiDonVi = data
            this.isLoading = true
        },

        async loadDSDiaDiemApDung() {
            const params = {
                HangHoa_Id: this.selectedItem.HangHoa_Id,
            }
            const data = await apiCallPromise('work/HH_HangHoa_DiaDiem_Select', params)
            this.DSDiaDiemApDung = data?.map((item) => item.DiaDiem_Id)
        },

        async loadDSTonToiThieu() {
            this.isLoading = false
            const params = {
                HangHoa_Id: this.selectedItem.HangHoa_Id,
            }
            const data = await apiCallPromise('work/HH_HangHoa_TonToiThieu_Select', params)
            this.DSTonToiThieu = data
            this.isLoading = true
        },
        onLoadDiaDiemApDung() {
            this.loadDSDiaDiemApDung()
        },

        onLoadDoiDonVi() {
            this.loadDSDoiDonVi()
        },

        onLoadTonToiThieu() {
            this.loadDSTonToiThieu()
        },
    },
}
</script>
