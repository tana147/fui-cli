<template>
    <v-dialog v-model="isShow" width="400">
        <v-card>
            <v-toolbar density="compact" elevation="0">
                <div class="d-flex flex-column pl-6">
                    <v-toolbar-title>
                        Cập nhật
                    </v-toolbar-title>
                    <div class="text-subtitle-2">
                        Địa điểm hiện tại: {{ selectedCaBiet.TenDiaDiem }}
                    </div>
                </div>
                <v-spacer />
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
            </v-toolbar>
            <v-divider></v-divider>
            <v-card-text class="pt-1">
                <v-form ref="form">
                    <v-row dense>
                        <v-col cols="12" class="mt-1">
                            <v-autocomplete color="primary" v-model="selectedCaBiet.KhuVuc_Id" density="compact"
                                :items="DSKhuVucFilter" item-value="KhuVuc_Id" item-title="TenKhuVuc" label="Khu vực">
                            </v-autocomplete>
                        </v-col>
                        <v-col cols="12" class="mt-1">
                            <v-autocomplete color="primary" v-model="selectedCaBiet.TinhTrang" density="compact"
                                :items="DSTinhTrangCaBiet" :rules="[rules.required]" item-value="value"
                                item-title="title" label="Tình trạng">
                            </v-autocomplete>
                        </v-col>
                    </v-row>
                </v-form>
            </v-card-text>

            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" variant="tonal" @click="onSubmit">Cập nhật</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: {
        isShow: Boolean,
        selectedCaBiet: Object,
        DSKhuVuc: Array,
    },
    emits: ['update:isShow', 'onReload'],
    data() {
        return {
            DSTinhTrangCaBiet,
            rules: {
                required: (value) => !!value || 'Trường này không được để trống',
            },
        }
    },
    computed: {
        DSKhuVucFilter() {
            let res = this.DSKhuVuc.filter((KhuVuc) => KhuVuc.DiaDiem_Id === this.selectedCaBiet.DiaDiem_Id)
            return [
                { KhuVuc_Id: 0, TenKhuVuc: 'Kho' },
                ...res
            ]
        }
    },
    methods: {
        closeDialog() {
            this.$refs.form?.reset()
            this.$refs.form?.resetValidation()
            this.$emit('update:isShow', false)
        },

        async onSubmit() {
            const { valid } = await this.$refs.form.validate();
            if (!valid) {
                showToast.info('Vui lòng nhập đầy đủ thông tin cần thiết')
                return
            }
            const params = {
                CaBiet_Id: this.selectedCaBiet.CaBiet_Id,
                KhuVuc_Id: this.selectedCaBiet.KhuVuc_Id,
                SoSeries: this.selectedCaBiet.SoSeries,
                NguyenGia: this.selectedCaBiet.NguyenGia,
                TinhTrang: this.selectedCaBiet.TinhTrang,
                ThoiGianKhauHao: this.selectedCaBiet.ThoiGianKhauHao,
                NgayBatDauSuDung: this.selectedCaBiet.NgayBatDauSuDung,
                NgayBatDauBaoHanh: this.selectedCaBiet.NgayBatDauBaoHanh,
                NgayKetThucBaoHanh: this.selectedCaBiet.NgayKetThucBaoHanh,
            }
            apiCall("work/TS_CaBiet_Update", params, (res) => {
                if (res) showToast.success("Thành công");
                this.$emit('onReload', params)
                this.closeDialog()
            })
        }
    },
}
</script>