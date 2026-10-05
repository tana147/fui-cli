<template>
    <div>
        <div class="page-navigation pa-2">
            <v-row>
                <v-col cols="4">
                    <v-select v-model="CuaHangID" label="Cửa hàng" :items="DSCuaHang" item-value="CuaHangID"
                        item-text="TenCuaHang" outlined dense hide-details> </v-select>
                </v-col>
                <v-col cols="4" class="d-flex align-center justify-center">
                    <v-checkbox :disabled="!CuaHangID > 0" v-model="IsSignature" label="Signature" color="primary" hide-details class="px-1 ma-0"> </v-checkbox>
                    <v-checkbox :disabled="!CuaHangID > 0" v-model="IsBestSeller" label="Best Seller" color="primary" hide-details class="px-1 ma-0"> </v-checkbox>
                    <v-checkbox :disabled="!CuaHangID > 0" v-model="IsHetMon" label="Hết Món" color="primary" hide-details class="px-1 ma-0"> </v-checkbox>
                </v-col>
                <v-col cols="4" class="d-flex align-center justify-end">
                    <v-tooltip top>
                        <template v-slot:activator="{on, attrs}">
                            <v-btn color="primary" icon v-bind="attrs" v-on="on" @click="openModalBackground" elevation="0" :disabled="!CuaHangID > 0">
                                <v-icon>mdi-image-edit-outline</v-icon>
                            </v-btn>
                        </template>
                        <span>Ảnh menu</span>
                    </v-tooltip>
                    <v-tooltip top>
                        <template v-slot:activator="{on, attrs}">
                            <v-btn color="primary" icon v-bind="attrs" v-on="on" @click="redirectToMenuPos" elevation="0" :disabled="!CuaHangID > 0">
                                <v-icon>mdi-eye-outline</v-icon>
                            </v-btn>
                        </template>
                        <span>Xem trước</span>
                    </v-tooltip>
                    <v-tooltip top>
                        <template v-slot:activator="{on, attrs}">
                            <v-btn color="primary" icon v-bind="attrs" v-on="on" @click="openStoreList" elevation="0" :disabled="!CuaHangID > 0">
                                <v-icon>mdi-store-edit-outline</v-icon>
                            </v-btn>
                        </template>
                        <span>Sao chép đến cửa hàng</span>
                    </v-tooltip>
                    <v-tooltip top>
                        <template v-slot:activator="{on, attrs}">
                            <v-btn color="primary" icon v-bind="attrs" v-on="on" @click="openProductList" elevation="0" :disabled="!CuaHangID > 0">
                                <v-icon>mdi-list-box-outline</v-icon>
                            </v-btn>
                        </template>
                        <span>Sản phẩm ({{ DSSanPham_Menu.length }})</span>
                    </v-tooltip>
                </v-col>
            </v-row>
        </div>
        <uc-menu v-if="CuaHangID > 0" :ct_cuahang="CTCuaHang" :ds_sp_menu="DSSanPham_Menu" :ds_sp="DSSanPham" :is_signature="IsSignature" :is_hetmon="IsHetMon" :is_bestseller="IsBestSeller" @on_load_menu="getCuaHangMenu" />
        <uc-modal-product-list :is_dialog="IsShowDialogProduct" :ds_sp_menu="DSSanPham_Menu" @on_close="IsShowDialogProduct = false" />
        <uc-modal-background v-if="CTMenu.length > 0" :is_dialog="IsShowDialogBackground" :ct_menu="CTMenu" @on_close="IsShowDialogBackground = false" />
        <uc-modal-store v-show="CTCuaHang.length > 0" :is_dialog="IsShowDialogStore" :ct_cuahang="CTCuaHang" @on_close="IsShowDialogStore = false" />
    </div>
</template>

<script>
    export default {
    props: [],
    data() {
        return {
            CuaHangID: null,
            CTCuaHang: [],
            CTMenu: [],
            DSCuaHang: [],
            DSSanPham_Menu: [],
            DSSanPham: [],
            IsSignature: false,
            IsBestSeller: false,
            IsHetMon: false,
            IsShowDialogProduct: false,
            IsShowDialogBackground: false,
            IsShowDialogStore: false,
        }
    },
    mounted() {
        this.getDanhSachCuaHang()
    },
    computed: {},
    watch: {
        CuaHangID: function () {
            this.CTCuaHang = {}
            this.DSSanPham = []
            this.DSSanPham_Menu = []
            this.IsSignature = false
            this.IsBestSeller = false
            this.IsHetMon = false
            this.IsShowDialogProduct = false
            this.IsShowDialogBackground = false
            this.IsShowDialogStore = false
            ajaxCALL("/eorder/CuaHang_Select_ById", {CuaHangID: this.CuaHangID}, (res) => {
                this.CTCuaHang = res.data
                this.CTMenu = res.data
            })
            this.getCuaHangMenu()
            ajaxCALL("/eorder/SanPham_Select_Dropdown_ByCuaHangId", {CuaHangID: this.CuaHangID}, (res) => {
                this.DSSanPham = res.data
            })
        },
    },

    methods: {
        getDanhSachCuaHang() {
            ajaxCALL("/eorder/CuaHang_Select", {}, (res) => {
                this.DSCuaHang = res.data
            })
        },
        redirectToMenuPos() {
            window.open("/menu?chid=" + this.CuaHangID, "_blank")
        },
        getCuaHangMenu() {
            ajaxCALL("/eorder/auth/CuaHangMenu_Select_ByCuaHangId", {CuaHangID: this.CuaHangID}, (res) => {
                const resData = res.data.map((item) => ({
                    ...item,
                    w: 80,
                    h: 80,
                }))
                this.DSSanPham_Menu = resData
            })
        },
        openProductList() {
            this.IsShowDialogProduct = true
        },
        openStoreList() {
            this.IsShowDialogStore = true
        },
        openModalBackground() {
            this.IsShowDialogBackground = true
        },
    },
}
</script>
