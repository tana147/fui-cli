<template>
    <div>
        <div class="page-section pa-0 mt-2">
            <v-card class="page-section" elevation="0">
                <v-card-title> Thiết lập điều kiện số lượng nhóm sản phẩm quà tặng </v-card-title>
                <v-card-text>
                    <v-card style="border: #dbdbdb solid 1px" elevation="0">
                        <v-card-title style="border-bottom: 1px solid #dbdbdb" class="pa-2 px-3">
                            <div class="primary--text text-left" style="font-weight: 500; font-size: 1.1rem">Danh sách nhóm sản phẩm</div>
                        </v-card-title>
                        <v-card-text>
                            <v-list dense>
                                <v-list-item v-for="(category, i) in categoryOrders" :key="i">
                                    <v-list-item-icon style="margin-right: 10px"> <v-icon color="success" v-text="category.IconNhomSanPhamMon"></v-icon> </v-list-item-icon>
                                    <v-list-item-content>
                                        <v-list-item-title>{{ category.TenNhomSanPhamMon }}: </v-list-item-title>
                                        <div v-if="category.items.length > 0" class="mt-1">
                                            <v-chip class="ma-1" small v-for="item in category.items">
                                                <span class="black--text" style="font-weight: normal">
                                                    {{ item.TenNhomSanPham }}
                                                </span>
                                            </v-chip>
                                        </div>
                                        <span v-else class="black--text" style="font-weight: normal">
                                            <i>Chưa có nhóm sản phẩm.</i>
                                        </span>
                                    </v-list-item-content>
                                    <v-list-item-icon class="ml-3">
                                        <v-menu elevation="0" v-model="category.isOpenMenu" :nudge-width="100" offset-y>
                                            <template v-slot:activator="{on, attrs}">
                                                <v-btn color="primary" text v-bind="attrs" v-on="on">
                                                    {{ category.DieuKienSoLuong }}
                                                </v-btn>
                                            </template>

                                            <v-card elevation="0">
                                                <v-card-title> Cập nhật số lượng </v-card-title>
                                                <v-card-text class="mt-1">
                                                    <v-text-field v-model="category.DieuKienSoLuong" regular dense tile />
                                                </v-card-text>
                                                <v-card-actions>
                                                    <v-spacer></v-spacer>
                                                    <v-btn color="primary" @click="category.isOpenMenu = false" text>Đóng</v-btn>
                                                    <v-btn color="primary" @click="onUpdateStock(category)" text>Lưu</v-btn>
                                                </v-card-actions>
                                            </v-card>
                                        </v-menu>
                                    </v-list-item-icon>
                                </v-list-item>
                            </v-list>
                        </v-card-text>
                    </v-card>
                </v-card-text>
            </v-card>
        </div>

        <div class="page-section pa-0 mt-2">
            <v-card class="page-section" elevation="0">
                <v-card-title>
                    Thiết lập quà tặng
                    <v-spacer></v-spacer>
                    <v-btn @click="vueData.IsEdit = true" color="primary" x-small elevation="0" fab><v-icon>mdi-pencil</v-icon></v-btn>
                </v-card-title>
                <v-card-text class="mt-1">
                    <v-card class="page-section" elevation="0">
                        <p><b>Sản phẩm tặng:</b> {{ config.MaSanPham }} - {{ config.TenSanPham ?? "Chưa có sản phẩm tặng" }}</p>
                        <p>
                            <b>Trạng thái:</b>
                            <v-chip v-if="config.IsTangMon == 1" color="success" small>Đang triển khai</v-chip>
                            <v-chip v-else color="error" small>Ngừng hoạt động</v-chip>
                        </p>
                    </v-card>
                </v-card-text>
            </v-card>
        </div>

        <uc-dialog-edit-stock :recordEdit="config" />
    </div>
</template>

<script>
export default {
    data() {
        return {
            itemsTemp: [],
            config: {},
            categoryOrders: [],
            vueData,
        }
    },
    watch: {
        "vueData.DSCauHinh": {
            handler(newVal) {
                const [config] = newVal
                this.config = config
            },
            deep: true,
        },
        "vueData.DSNhomSanPhamMon": {
            handler(newVal) {
                const [categoryOrders = [], groupItems = []] = newVal

                //  xử lí mapping nhóm sản phẩm vào trong Nhóm order
                const handleMapping = categoryOrders.map((category) => {
                    const items = groupItems.filter((item) => item.NhomSanPhamMonID == category.NhomSanPhamMonID)
                    const itemsUnvaliable = groupItems.filter((item) => item.NhomSanPhamMonID == null)
                    const itemIDs = items.map((item) => item.NhomSanPhamID)
                    return {...category, items, itemIDs, itemsUnvaliable, isOpenMenu: false}
                })

                this.categoryOrders = [...handleMapping]
            },
        },
    },
    computed: {},
    methods: {
        onUpdateStock({DieuKienSoLuong, NhomSanPhamMonID}) {
            ajaxCALL("/eorder/NhomSanPhamMon_Update_SoLuong", {DieuKienSoLuong, NhomSanPhamMonID}, () => {
                Vue.$toast.success("Lưu điều kiện số lượng sản phầm thành công", {position: "top"})
                runAction(vueData.getNhomSanPhamMon)
            })
        },
    },
}
</script>
