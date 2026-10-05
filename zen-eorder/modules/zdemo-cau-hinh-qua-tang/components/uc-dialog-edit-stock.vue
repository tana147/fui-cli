<template>
    <div>
        <v-dialog v-model="vueData.IsEdit" width="500">
            <v-card elevation="0">
                <v-toolbar dense flat>
                    <v-toolbar-title>Thiết lập quà tặng</v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="vueData.IsEdit = false">
                        <v-icon>mdi-close</v-icon>
                    </v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-row>
                        <v-col cols="12">
                            <f-search v-model="itemObject.TangSanPhamID" hide-no-data hide-details dense outlined hide-details
                                return-object item-text="TenSanPham" item-value="SanPhamID" label="Sản phẩm"
                                api="/eorder/SanPham_Select_Search" :api-data="{ TuKhoa: 'TEXT' }" />
                            </v-col>
                        <v-col cols="12">
                            <v-checkbox label="Hoạt động" v-model="isTangMon"></v-checkbox>
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn text color="primary" @click="onSave">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>
<script>
export default {
    props: ["recordEdit"],
    data() {
        return {
            itemObject: {},
            isTangMon: false,
            vueData
        }
    },
    watch: {
        'vueData.IsEdit': {
            handler(value) {
                if (!value) {
                    this.itemObject = {}
                    this.isTangMon = false
                    return
                }

                this.isTangMon = this.recordEdit.isTangMon == 0 ? false : true
            }
        }
    },
    methods: {
        onSave() {
   
            ajaxCALL('/eorder/CauHinh_Update_MonTang', { IsTangMon: this.isTangMon ? 1 : 0, TangSanPhamID: this.itemObject.SanPhamID },
                () => {
                    Vue.$toast.success("Lưu cấu hình thành công", { position: "top" })
                    runAction(vueData.getCauHinh)
                    vueData.IsEdit = false
                }
            )
        }
    },
}
</script>