<template>
    <v-dialog v-model="isShow" :max-width="isMobile ? '100%' : 800">
        <v-card>
            <v-toolbar density="compact" elevation="0">
                <v-toolbar-title>
                    Xem chi tiết
                </v-toolbar-title>
                <v-spacer />
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
            </v-toolbar>
            <v-divider></v-divider>
            <v-card-text class="py-1">
                <div class="pa-4 pt-0 border-bottom bg-grey-lighten-5 pb-0">
                    <div class="mt-3">
                        <div class="d-flex align-center justify-space-between mb-1 ">
                            <span class="text-grey text-caption">NGÀY NHẬP</span>
                            <span class="font-weight-bold">{{ formatDate(selectedItem.Info.NgayNhap) }}</span>
                        </div>
                    </div>
                </div>
                <div class="pa-4 pt-0 d-flex flex-column">
                    <div class="d-flex justify-space-between align-center mb-3">
                        <div class="text-subtitle-2 font-weight-bold">DANH SÁCH HÀNG HOÁ </div>
                    </div>
                    <v-list v-if="selectedItem?.arrayHangHoa?.length > 0" lines="two"
                        class="pa-0 flex-grow-1 overflow-y-auto">
                        <v-list-item v-for="(HangHoa, index) in selectedItem.arrayHangHoa" :key="index"
                            class="border rounded-lg mb-2 pa-2">
                            <template v-slot:prepend>
                                <v-avatar color="blue-lighten-5" rounded size="40">
                                    <v-icon size="20"
                                        :color="HangHoa.Is_CaBiet ? 'purple' : HangHoa.LoaiHangHoa === 'CCDC' ? 'orange-darken-2' : 'blue'">
                                        {{ HangHoa.Is_CaBiet ? 'mdi-devices' : HangHoa.LoaiHangHoa === 'CCDC' ?
                                            'mdi-tools'
                                        : 'mdi-package-variant' }}
                                    </v-icon>
                                </v-avatar>
                            </template>

                            <v-list-item-title class="font-weight-bold text-body-2">
                                {{ HangHoa.TenHangHoa }}
                            </v-list-item-title>

                            <v-list-item-subtitle class="text-caption mt-1 d-flex justify-space-between align-center">

                                <div class="d-flex flex-column">
                                    <span>
                                        SL:
                                        <b class="text-primary">{{ HangHoa.SoLuongNhap }}</b>
                                        {{ HangHoa.TenDonVi }}
                                    </span>

                                    <span
                                        v-if="HangHoa.SoLuongNhap !== HangHoa.SoLuongDaDuyet && selectedItem.Info.PhieuLuanChuyen_Id === 0 && HangHoa.Is_CaBiet === 0"
                                        class="text-grey text-decoration-line-through">
                                        SL cũ: {{ HangHoa.SoLuongDaDuyet }} {{ HangHoa.TenDonVi }}
                                    </span>
                                </div>
                            </v-list-item-subtitle>
                        </v-list-item>
                    </v-list>

                    <div v-else>
                        <uc-empty text="Chưa có hàng hoá để hiển thị"></uc-empty>
                    </div>

                    <v-textarea v-if="selectedItem?.arrayHangHoa?.length > 0" v-model="selectedItem.GhiChu" rows="2"
                        auto-grow label="Ghi chú" class="mt-2"></v-textarea>
                </div>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn variant="text" @click="closeDialog">Đóng</v-btn>
                <v-btn color="primary" variant="tonal" :loading="saving" @click="onSubmit('HOAN_THANH')">Duyệt</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: {
        isShow: Boolean,
        selectedItem: Object,
    },
    emits: ['update:isShow', 'on-load-danh-sach-cho-xac-nhan'],
    data() {
        return {
            saving: false,
        }
    },
    computed: {
        isMobile() {
            return this.$vuetify.display.smAndDown
        },
    },
    methods: {
        formatDate: window.formatDate,
        closeDialog() {
            this.$emit('update:isShow', false)
        },

        async onSubmit(type) {
            this.saving = true
            const params = {
                PhieuNhap_Id: this.selectedItem.Id,
                TinhTrang: type,
                GhiChu: this.selectedItem.GhiChu
            }
            apiCall("work/HH_PhieuNhap_Update_TinhTrang", params, (res) => {
                this.saving = false
                if (res) {
                    showToast.success("Thành công")
                    this.$emit('on-load-danh-sach-cho-xac-nhan')
                    this.closeDialog()
                }
            })
        }
    },
}
</script>