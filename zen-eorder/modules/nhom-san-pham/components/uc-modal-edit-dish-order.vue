<template>
    <v-dialog v-model="vueData.dialogDishOrder" scrollable width="500">
        <v-card elevation="0">
            <v-toolbar dense flat>
                <v-toolbar-title>Danh sách nhóm {{ NhomMonOrder.TenNhomSanPhamMon }}</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.dialogDishOrder = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-select class="mb-5" dense v-model="Is_HienThi" label="Hiển thị thống kê số lượng" density="compact" hide-details="auto" outlined :items="optionsHienThi"></v-select>
                <v-row dense>
                    <v-col v-for="item in options" :key="item.id" cols="12" sm="6" md="6">
                        <v-checkbox class="mt-0 pt-0" v-model="NhomSanPhamID" :label="item.text" :value="item.id" density="compact" hide-details="auto" />
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn @click="onSave" color="primary" text> Lưu </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    emits: ["Finish"],
    props: {
        item: {
            type: Object,
        },
    },
    data() {
        return {
            NhomSanPhamID: [],
            Is_HienThi: false,
            optionsHienThi:[ {
                text: 'Không',
                value: 0
            }, {
                text: 'Có',
                value: 1
            }],
            vueData,
        }
    },
    watch: {
        "vueData.dialogDishOrder": {
            handler(val) {
                if (val) return this.resetFields()
            },
        },
        item: function (val) {
            if (!val) return

            this.NhomSanPhamID = val["itemIDs"]
            this.Is_HienThi = val["Is_HienThi"]
        },
    },
    computed: {
        NhomMonOrder: function () {
            return this.item || {}
        },
        options: function () {
            const options = vueData.DSNhomSanPham_Table.map((x) => ({
                id: x.NhomSanPhamID,
                text: x.TenNhomSanPham,
            }))
            return [...options]
        },
    },
    methods: {
        resetFields() {
            this.NhomSanPhamID = []
        },
        onSave() {
            const NhomID = this.NhomMonOrder.NhomSanPhamMonID

            if (!NhomID) return

            const params = {
                NhomSanPhamMonID: NhomID,
                Is_HienThi: this.Is_HienThi,
                NhomSanPhamID_List: this.NhomSanPhamID.join(",") ?? "",
            }

            ajaxCALL("/eorder/NhomSanPhamMon_Update_Nhom", params, (res) => {
                if (res.data) {
                    vueData.dialogDishOrder = false
                    Vue.$toast.success("Lưu danh sách món sản phẩm thành công", {position: "top"})
                    this.$emit("Finish")
                }
            })
        },
    },
}
</script>
