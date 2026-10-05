<template>
    <v-dialog v-model="isShow" max-width="600" scrollable :fullscreen="isMobile">
        <v-card class="bg-white">
            <v-toolbar density="compact" height="40">
                <v-toolbar-title class="text-subtitle-1">
                    Chi tiết báo sửa #{{ selectedBaoSua?.BaoSua_Id }}
                </v-toolbar-title>
                <v-spacer />
                <v-btn icon="mdi-close" variant="text" density="compact" @click="closeDialog" />
            </v-toolbar>

            <v-card-text class="pa-0">
                <div class="pa-3">
                    <div class="d-flex align-center mb-2">
                        <v-avatar size="24" :color="!selectedBaoSua.AnhDaiDien_Url
                            ? stringToColor(selectedBaoSua.HoTenNguoiBaoSua)
                            : undefined">
                            <v-img v-if="selectedBaoSua.AnhDaiDien_Url"
                                :src="'https://file.zentea.vn/work/FileData/' + selectedBaoSua.AnhDaiDien_Url" />
                            <span v-else class="text-caption font-weight-medium text-white">
                                {{ getInitials(selectedBaoSua.HoTenNguoiBaoSua) }}
                            </span>
                        </v-avatar>
                        <div>
                            <div class="d-flex align-center text-body-2">
                                <v-icon size="14" class="mr-1" color="grey">
                                    mdi-clock-outline
                                </v-icon>
                                {{ selectedBaoSua?.HoTenNguoiBaoSua }}
                            </div>

                            <div class="text-caption text-grey">
                                {{ selectedBaoSua?.ThoiGianBaoSua }}
                            </div>
                        </div>
                    </div>
                    <v-divider />
                    <div class="d-flex align-center py-2">
                        <v-icon class="mr-3" color="#1976D2">
                            mdi-devices
                        </v-icon>
                        <span class="text-body-2">
                            {{ selectedBaoSua?.TenHangHoa }}
                        </span>
                    </div>
                    <v-divider />
                    <div class="d-flex align-center py-2">
                        <v-icon class="mr-3" color="#E53935">
                            mdi-map-marker-radius-outline
                        </v-icon>
                        <span class="text-body-2">
                            {{ selectedBaoSua?.TenDiaDiem }}
                        </span>
                    </div>
                    <v-divider />
                    <div class="d-flex align-center py-2">
                        <v-icon class="mr-2" color="#9E9E9E">
                            mdi-message-text-outline
                        </v-icon>
                        <span class="text-body-2 flex-grow-1">
                            {{ selectedBaoSua?.GhiChu }}
                        </span>
                        <v-btn v-if="selectedBaoSua?.HinhAnh" icon="mdi-image-outline" density="compact" variant="text"
                            color="blue-darken-2" />
                    </div>
                    <v-select class="mt-3" density="compact" variant="outlined" v-model="selectedBaoSua.DoUuTien"
                        label="Độ ưu tiên" :items="DSDoUuTien" item-title="key" item-value="value" hide-details />

                    <v-textarea class="mt-3" :clearable="false" rows="4" dense="compact"
                        v-model="selectedBaoSua.GhiChuTiepNhan" label="Ghi chú tiếp nhận">
                    </v-textarea>

                    <v-row v-if="selectedBaoSua.DSFiles?.length > 0" class="mt-2" dense>
                        <v-col v-for="(img, index) in selectedBaoSua.DSFiles" :key="index" cols="4">
                            <v-card class="position-relative">
                                <v-img :src="viewFile(img)" aspect-ratio="1" cover class="rounded"
                                    @click="previewImage(img)" />
                            </v-card>
                        </v-col>
                    </v-row>
                </div>
            </v-card-text>
            <v-card-actions class="px-3 pb-3">
                <v-spacer></v-spacer>
                <v-btn color="primary" variant="elevated" prepend-icon="mdi-check" @click="onSubmit">
                    Tiếp nhận
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>

    <v-dialog v-model="showPreview" max-width="800">
        <v-card>
            <v-img :src="previewUrl" contain max-height="80vh" />
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: {
        isShow: Boolean,
        selectedBaoSua: Object
    },
    emits: ['load-data', 'update:isShow'],
    data() {
        return {
            DSDoUuTien: [
                { key: "#1 - Bình thường", value: 'BINH_THUONG' },
                { key: "#2 - Trung bình", value: 'TRUNG_BINH' },
                { key: "#3 - Cao", value: 'UU_TIEN' },
                { key: "#4 - Khẩn cấp", value: 'KHAN_CAP' },
            ],
            showPreview: false,
            previewUrl: null
        }
    },

    computed: {
        isMobile() {
            return this.$vuetify.display.smAndDown
        }
    },

    methods: {
        formatDateTime: window.formatDateTime,

        getInitials(name) {
            if (!name) return ''
            const parts = name.trim().split(/\s+/)
            return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
        },

        stringToColor(str) {
            if (!str) return 'grey'
            let hash = 0
            for (let i = 0; i < str.length; i++) {
                hash = str.charCodeAt(i) + ((hash << 5) - hash)
            }
            const colors = [
                'red', 'pink', 'purple', 'deep-purple',
                'indigo', 'blue', 'cyan', 'teal',
                'green', 'light-green', 'lime',
                'amber', 'orange', 'deep-orange'
            ]
            return colors[Math.abs(hash) % colors.length]
        },

        closeDialog() {
            this.$emit("update:isShow", false)
        },

        viewFile(FileID) {
            const urlReadFile = 'https://file.zentea.vn/work/HH_FileData/'
            return `${urlReadFile}${FileID}`
        },

        previewImage(img) {
            this.previewUrl = this.viewFile(img)
            this.showPreview = true
        },

        onSubmit() {
            const params = {
                BaoSua_Id: this.selectedBaoSua.BaoSua_Id,
                DoUuTien: this.selectedBaoSua.DoUuTien,
                GhiChu: this.selectedBaoSua.GhiChuTiepNhan,
            }
            const $this = this
            apiCall("work/TS_BaoSua_Update_TiepNhan", params, (res) => {
                if (res) {
                    showToast.success("Thành công");
                    $this.closeDialog()
                    $this.$emit('load-data')
                }
            })
        }
    }
}
</script>