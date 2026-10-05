function getNhomSanPham(ds) {
    let uniqueData = []
    if (ds) {
        uniqueData = ds.reduce((acc, item) => {
            const existingItem = acc.find((i) => i.NhomSanPhamID === item.NhomSanPhamID)
            if (!existingItem) {
                acc.push(item)
            }
            return acc
        }, [])
    }
    return uniqueData
}
Vue.component("empty-component", {
    template: /*html*/ `
        <div>
            <div class="text-center title red--text pt-10 border-top"><v-icon color="error" large>mdi-inbox</v-icon> <br/> Mã QR Code không hợp lệ <br/></div>
            <div class="text-center red--text">Vui lòng thử lại hoặc liên hệ với nhân viên phục vụ</div>
        </div>
    `,
})
Vue.component("intro-component", {
    props: ["info"],
    mounted() {
        $(document).ready(function () {
            const queryString = window.location.search
            const urlParams = new URLSearchParams(queryString)
            const CuaHangID = urlParams.get("CuaHangID")
            const PhanHieuID = urlParams.get("PhanHieuID")
            let chid = document.getElementById("cuahang-id")
            let phid = document.getElementById("phanhieu-id")
            if (chid) {
                chid.innerText = `CuaHangID: ${CuaHangID ?? 0}`
            }
            if (phid) {
                phid.innerText = `PhanHieuID: ${PhanHieuID ?? 0}`
            }
        })
    },
    template: /*html*/ `
    `,
    computed: {},
    methods: {},
})
Vue.component("product-pick-component", {
    props: ["dsnhomsanpham", "ctcuahang", "dssanpham"],
    data() {
        return {
            tab: 0,
            searchTab: 0,
            isSearch: false,
            DSSanPhamSelectedFilter: [],
            SearchKeyword: "",
        }
    },
    computed: {
        DSNhomSanPham: function () {
            let arrDSNhomSanPhamWithTabIndex = this.dsnhomsanpham?.map((item, index) => ({ ...item, indexTabNhomSanPham: index }))
            return arrDSNhomSanPhamWithTabIndex
        },
        CTCuaHang: function () {
            return this.ctcuahang
        },
        DSSanPham: function () {
            let arr = []
            this.DSNhomSanPham?.forEach((itemNSP, index) => {
                this.dssanpham?.forEach((itemSanPham) => {
                    if (itemNSP.NhomSanPhamID === itemSanPham.NhomSanPhamID) {
                        arr.push({ ...itemSanPham, indexTabNhomSanPham: index })
                    }
                })
            })
            return arr
        },
        DSSanPhamCurrentTab: function () {
            const keyword = this.SearchKeyword ?? ""
            let filterProduct = []
            let ds = this.DSSanPham?.filter((item) => item.indexTabNhomSanPham === this.tab)
            if (ds && ds.length > 0) {
                filterProduct = ds.filter((item) => {
                    return keyword === "" || toSlug(item.TenNgan).includes(toSlug(keyword)) || toSlug(item.MaSoSanPham).includes(toSlug(keyword))
                })
            }
            return filterProduct
        },
    },
    watch: {},
    methods: {
        onSearch() {
            this.isSearch = !this.isSearch
            if (this.isSearch) {
                setTimeout(() => {
                    this.$refs.searchRef.focus()
                }, 100)
            }
        },
    },
    template: /*html*/ `
        <div style="position:relative;" >
            <v-card style="position:sticky; top:0; z-index:1">
                <v-toolbar elevation="4" dense color="primary">
                    <v-toolbar-title class="white--text">
                        <v-icon class="mr-4 white--text" @click="()=> {
                        const native = window.ReactNativeWebView
                        native.postMessage(JSON.stringify({
                            key: 'back',
                            param: ''
                        }))
                        }">mdi-arrow-left</v-icon>
                        <span v-if="isSearch === false">{{CTCuaHang.TenCuaHang}}</span>
                        <v-text-field v-else
                            ref="searchRef"
                            v-model="SearchKeyword"
                            label="Tìm sản phẩm..."
                            dense
                            hide-details
                            solo
                            outlined
                            clearable
                        ></v-text-field>
                    </v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn color="white" icon @click="onSearch">
                        <v-icon>mdi-magnify</v-icon>
                    </v-btn>
                    <template v-slot:extension>
                        <v-tabs v-model="tab" background-color="success accent-4" dark center-active >
                            <v-tab v-for="item in DSNhomSanPham" :key="item.indexTabNhomSanPham" style="height:100%" >
                                <v-icon left>{{item.IconNhomSanPham}}</v-icon>
                                {{item.TenNhomSanPham}}
                            </v-tab>
                        </v-tabs>
                    </template>
                </v-toolbar>
            </v-card>
            <v-tabs-items v-model="tab" style="height: calc(100vh - 170px); overflow: auto;">
                <v-tab-item :value="tab" :key="tab">
                    <div class="div-item-product" v-for="(product, i) in DSSanPhamCurrentTab" >
                        <product-pick-tem-component :product="product" />
                    </div>
                </v-tab-item>
            </v-tabs-items>
            <v-card>
                <v-footer
                    color="success"
                    style="height:75px; color:white;  border-top-left-radius: 15px; border-top-right-radius: 15px;"
                    padless
                >
                    <v-row style="margin:0">
                        <v-col cols="8">
                            <p class="text-subtilte-1">Giỏ hàng có 0 sản phẩm</p>
                            <p>Tổng tiền giỏ hàng: {{'0'.toLocaleString('vi-vn')}} </p>
                        </v-col>
                        <v-col style="display: flex; justify-content: end;">
                            <v-btn fab dark color="success" small>
                                <v-icon>mdi-shopping</v-icon>
                            </v-btn>
                        </v-col>
                    </v-row>
                </v-footer>
            </v-card>
        </div>
    `,
})
Vue.component("product-pick-tem-component", {
    props: ["product"],
    template: /*html*/ `
        <div @click.stop="onClickProduct()">
            <v-row dense>
                <v-col cols="10" class="d-flex" style="flex-direction:column; justify-content: center;">
                    <span class="text-h6 primary--text" :style="product.TinhTrang === 1 ? 'text-decoration-line: line-through; color: #a9a9a9' : ''">{{product?.TenSanPham.trim()}}</span>
                    <span v-if="product.TinhTrang === 1" class="error--text">(Tạm hết)</span>
                    <p>
                        Giá: <span class="red--text font-weight-bold">{{product?.GiaBan_App.toLocaleString('vi-vn')}}</span>
                    </p>
                </v-col>
                <v-col cols="2">
                    <v-img width="100%" min-height="50" max-height="50" contain
                            :src="vueData.v_Set.defaultImg"
                            lazy-src="vueData.v_Set.defaultImg"
                        >
                            <template v-slot:placeholder>
                                <v-row
                                    dense
                                    class="fill-height ma-0"
                                    align="center"
                                    justify="center"
                                >
                                    <v-progress-circular
                                        indeterminate
                                        color="grey lighten-5"
                                    ></v-progress-circular>
                                </v-row>
                            </template>
                        </v-img>
                </v-col>
            </v-row>
        </div>
    `,
    methods: {
        onClickProduct() {
            const $this = this
            const product = $this.product
            if (product.TinhTrang === 1) {
                Vue.$toast.warning("Món tạm hết, mong Quý khách thông cảm!", { position: "top" })
            } else {
                const productInfo = { ...product, SanPhamGuid: uuidv4(), SoLuong: 1, SoLuongThucTe: 1, GhiChu: "" }
                const cloneTopping = JSON.parse(JSON.stringify(vueData.DSChiTietLienKet))
                const listTopping = cloneTopping.filter((item) => item.NhomLienKetID === product.NhomLienKetID)
                productInfo.ThuocTinh = listTopping
                vueData.DSOrder.push(productInfo)
                vueData.SanPhamGuid_Active = productInfo.SanPhamGuid
                vueData.IsShowDialogDetailProduct = true
            }
        },
    },
})
Vue.component("modal-detail-product-component", {
    data: function () {
        return {
            DisableSend: false,
            IsChecked: false,
        }
    },
    template: /*html*/ `
        <v-dialog v-model="vueData.IsShowDialogDetailProduct" fullscreen scrollable transition="dialog-top-transition">
           <v-card style="padding: 0">
                <v-toolbar elevation="4" dense color="success" style="max-height:48px">
                    <v-toolbar-title class="white--text">{{SanPham?.TenNgan ?? ""}}</v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-icon color="white" @click="vueData.IsShowDialogDetailProduct = false">mdi-close</v-icon>
                </v-toolbar>
                <v-card-text style="padding:0">
                    <v-row style="margin:0">
                        <v-col cols="4">
                            <v-img width="100%" min-height="120" max-height="120" contain
                                    :src="SanPham.AnhSanPham_Url"
                                    lazy-src="SanPham.AnhSanPham_Url"
                                >
                                    <template v-slot:placeholder>
                                        <v-row
                                            dense
                                            class="fill-height ma-0"
                                            align="center"
                                            justify="center"
                                        >
                                            <v-progress-circular
                                                indeterminate
                                                color="grey lighten-5"
                                            ></v-progress-circular>
                                        </v-row>
                                    </template>
                                </v-img>
                        </v-col>
                        <v-col cols="8" class="d-flex" style="flex-direction:column; justify-content: center;">
                            <p class=" text-h6 primary--text font-weight-bold">{{SanPham?.TenNgan ?? ""}} </p>
                            <p class=" text-h6 red--text font-weight-bold">{{SanPham?.GiaBan_App?.toLocaleString('vi-vn') ?? 0}} </p>
                        </v-col>
                    </v-row>
                    <v-row style="margin:0">
                        <v-col>Số lượng</v-col>
                        <v-col>
                            <v-btn @click="onReduce()" :disabled="SanPham?.SoLuong === 0" fab class="bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-minus</v-icon></v-btn>
                            <v-text-field style="width: 50px; display: inline-block;" v-if="SanPham?.SoLuongThapPhan" @blur="onBlurQuantity" ref="refTextFieldQuantity" @keydown="onKeyDownQuantity" :value="roundSoLuong(SanPham.SoLuong)" @click.stop="" type="number" class="centered-input" hide-details dense hide-spin-buttons></v-text-field>
                            <span v-else class="px-2" style="font-size: 16px;font-weight: 500;">{{roundSoLuong(SanPham?.SoLuong)}}</span>
                            <v-btn @click="onIncrease()" fab class="bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-plus</v-icon></v-btn>
                        </v-col>
                    </v-row>
                    <v-row  style="margin:0">
                      <!-- Lấy vị-->
                        <v-col class="d-flex" style="flex-direction: column">
                            <topping-vi-component :detail="detail" :product="SanPham" v-for="(detail, i) in SanPham.ThuocTinh?.filter(item=> isVi(item))" :key="i"/>
                        </v-col>
                    </v-row>
                    <v-row style="margin:0">
                        <!-- Lấy Topping -->
                        <v-col class="d-flex" style="flex-direction: column">
                            <topping-component :detail="detail" :product="SanPham" v-for="(detail, i) in SanPham.ThuocTinh?.filter(item=> isTopping(item))" :key="i"/>
                        </v-col>
                    </v-row>
                    <v-row style="margin:0">
                        <v-col>
                            <p>Ghi chú:</p>
                            <v-textarea @click="scrollToBottom()" solo outlined dense hide-details  v-model="SanPham.GhiChu"></v-text-field>
                        </v-col>
                    </v-row>
                </v-card-text>
           </v-card>
        </v-dialog>
    `,
    computed: {
        SanPham: function () {
            const $this = this
            const index = vueData.DSOrder.findIndex((item) => item.SanPhamGuid === vueData.SanPhamGuid_Active)
            if (index >= 0) {
                $this.IsChecked = vueData.DSOrder[index]?.Is_MangVe ?? false
                return vueData.DSOrder[index]
            } else {
                return []
            }
        },
        ThanhTien: function () {
            return this.SanPham.SoLuong * this.SanPham.GiaBan_CuaHang
        },
        TongTienMon: function () {
            const $this = this
            let tongTienTopping = 0
            $this.SanPham.ThuocTinh?.forEach((item) => {
                tongTienTopping += item.SoLuong * item.GiaBan_CuaHang
            })
            return $this.ThanhTien + tongTienTopping
        },
    },
    methods: {
        isVi(detail) {
            return detail?.SanPhamID === 0 || detail?.SanPhamID === null || detail?.NhomLienKetChiTiet_ParentID !== null || detail?.NhomLienKetChiTiet_ParentID > 0
        },
        isTopping(detail) {
            return detail?.SanPhamID > 0
        },
        onCheck() {
            const $this = this
            $this.SanPham.Is_MangVe = !$this.SanPham.Is_MangVe
            $this.IsChecked = $this.SanPham.Is_MangVe
        },
        scrollToBottom() {
            $(".order-detail-body").scrollTop($(".order-detail-body")[0].scrollHeight)
        },
        onIncrease() {
            const $this = this
            $this.SanPham.SoLuong += 1
            $this.updateToppingQuantity()
        },
        onReduce() {
            const $this = this
            $this.SanPham.SoLuong = $this.SanPham.SoLuong <= 0 ? 0 : $this.SanPham.SoLuong - 1
            if ($this.SanPham.SoLuong <= 0) {
                $this.onDelete() //Remove sản phẩm
            } else {
                $this.updateToppingQuantity()
            }
        },
        onDelete() {
            const $this = this
            const index = vueData.DSOrder.findIndex((item) => item.SanPhamGuid === $this.SanPham.SanPhamGuid)
            if (index >= 0) {
                vueData.DSOrder.splice(index, 1) //Remove sản phẩm
                vueData.IsShowDialogDetailProduct = false //Tắt modal detail
                vueData.IsShowDialogOrder = vueData.DSOrder.length > 0 //Show Modal danh sách món tạm nếu còn món
            }
        },
        onSend() {
            const $this = this
            if ($this.DisableSend === false) {
                $this.DisableSend = true
                const dataJson = []
                //Xử lý danh sách món
                const product = {
                    SanPhamID: $this.SanPham.SanPhamID,
                    SanPhamGUID: $this.SanPham.SanPhamGuid,
                    NhomLienKetID: $this.SanPham.NhomLienKetID ?? 0,
                    NhomLienKetChiTietID: 0,
                    NhomLienKetChiTiet_ParentID: 0,
                    TenHienThi: $this.SanPham.TenSanPham,
                    TenNoiBo: $this.SanPham.TenNgan,
                    SoLuong: $this.SanPham.SoLuong,
                    DonGia: $this.SanPham.GiaBan_CuaHang,
                    ThuTu: 0,
                    GhiChu: $this.SanPham.GhiChu ?? "",
                    Is_MangVe: $this.SanPham.Is_MangVe ? 1 : 0,
                    Is_SanPham: 1,
                    Is_ThuocTinh: 0,
                }
                dataJson.push(product)
                //Xử lý danh sách topping
                $this.SanPham.ThuocTinh.forEach((item) => {
                    if (item.SoLuong > 0) {
                        const topping = {
                            SanPhamID: item.SanPhamID ?? 0,
                            SanPhamGUID: $this.SanPham.SanPhamGuid,
                            NhomLienKetID: item.NhomLienKetID,
                            NhomLienKetChiTietID: item.NhomLienKetChiTietID,
                            NhomLienKetChiTiet_ParentID: item.NhomLienKetChiTiet_ParentID,
                            TenHienThi: item.TenHienThi,
                            TenNoiBo: item.TenNoiBo,
                            SoLuong: item.SoLuong,
                            DonGia: item.GiaBan_CuaHang,
                            ThuTu: item.ThuTu,
                            GhiChu: "",
                            Is_MangVe: $this.SanPham.Is_MangVe ? 1 : 0,
                            Is_SanPham: 0,
                            Is_ThuocTinh: 1,
                        }
                        dataJson.push(topping)
                    }
                })
                const params = {
                    QrCode: vueData.QrCode,
                    ChiTietOrder_JSON: JSON.stringify(dataJson),
                }
                // ajaxCALL("/eorder/auth/HoaDon_Insert", params, (res) => {
                //     if (res.data) {
                //         $this.onDelete() //Remove sản phẩm
                //         vueData.IsShowDialogOrder = vueData.DSOrder.length > 0 //Show Modal danh sách món tạm nếu còn món
                //         Vue.$toast.success("Đã gửi thành công. ZEN cảm ơn quý khách", { position: "top" })
                //         //Push HoaDonID vào local
                //         const hoaDonId = res.data[0].HoaDonID
                //         if (hoaDonId) {
                //             vueData.HoaDonID = hoaDonId
                //         }
                //         $this.DisableSend = false
                //     }
                // })
            }
        },
        onSave() {
            vueData.IsShowDialogDetailProduct = false
            vueData.IsShowDialogOrder = true
        },
        updateToppingQuantity() {
            const $this = this
            $this.SanPham.ThuocTinh.map((item) => {
                if (item.SoLuongThucTe > 0 && item.SanPhamID > 0) {
                    item.SoLuong = item.SoLuongThucTe * $this.SanPham.SoLuong
                }
                return item
            })
        },
        onBlurQuantity(e) {
            let value = e.target.value.trim()
            const regex = /^(\d+(\.\d{0,3})?)?$/
            if (!regex.test(value)) {
                value = value.replace(/[^0-9.]/g, "")
            }
            if (value < 0 || value === "") {
                value = 1
            }
            //Lấy tối đa 3 số thập phân
            if (value.toString().includes(".")) {
                if (value.length - value.indexOf(".") > 2) {
                    value = parseFloat(value).toFixed(2)
                }
            }
            e.target.value = value
            this.SanPham.SoLuong = parseFloat(value)
            this.updateToppingQuantity()
        },
        onKeyDownQuantity(e) {
            if (e.code === "Enter") {
                this.$refs.refTextFieldQuantity.blur()
            }
        },
    },
})
Vue.component("topping-vi-component", {
    props: ["detail", "product"],
    template: /*html*/ `
        <div>
            <p v-if="detail?.NhomLienKetChiTiet_ParentID ===null">{{detail.TenHienThi}}</p>
            <span>{{detail.TenHienThi}}</span>
        </div>
    `,
})
Vue.component("topping-component", {
    props: ["detail", "product"],
    template: /*html*/ `
        <div>{{detail.TenHienThi}}</div>
    `,
})
Vue.component("modal-order-component", {
    data: function () {
        return {
            DisableSend: false,
        }
    },
    template: /*html*/ `
        <v-dialog v-model="vueData.IsShowDialogOrder" fullscreen scrollable transition="dialog-top-transition">
           <v-card class="model-order">
                <div class="pa-2 font-weight-bold border-bottom">
                    <v-row>
                        <v-col cols="6" class="pl-5 pb-0">
                            Giỏ hàng: <span class="text-green">{{HoaDon?.length}} món</span> <br/>
                            Tổng: <span class="error--text">{{TongTienHoaDon?.toLocaleString('vi-vn')}}</span>
                        </v-col>
                        <!--<v-col cols="6"><v-btn block class="float-right" :disabled="HoaDon?.length === 0 || DisableSend" @click="onSendOrder()" color="success"><v-icon left>mdi-chef-hat</v-icon>Gửi chế biến</v-btn></v-col>-->
                    </v-row>
                </div>
                <div class="tr-product bg-green white--text">
                    <div class="td-product-name-send">Tên món</div>
                    <div class="td-product-qty">SL</div>
                    <div class="td-product-price">Giá</div>
                    <div class="td-product-action"></div>
                </div>
                <div class="order-send-body">
                    <template v-for="(item, i) in HoaDon" :key="item.SanPhamGuid">
                       <product-order-component :product="item"/>
                    </template>
                </div>
                <div class="pa-1 border-top">
                    <v-text-field prepend-inner-icon="mdi-magnify" solo clearable label="Tìm theo mã số, tên món..." v-model="vueData.SearchKeyword" class="text-right pt-0" hide-details></v-text-field>
                </div>
                <div class="order-send-product">
                    <product-pick-component />
                </div>
                <div class="pa-3 order-footer">
                    <v-row>
                        <v-col cols="7">
                            <v-btn block @click="onDeleteAll()" color="error"><v-icon left>mdi-trash-can</v-icon>Hủy tất cả món</v-btn>
                        </v-col>
                        <v-col cols="5" class="text-right pl-0 pr-3">
                            <v-btn v-if="vueData.HoaDonID" outlined block @click="onOpenModalHistory()" color="success"><v-icon left>mdi-food-turkey</v-icon>MÓN ĐÃ GỬI</v-btn>
                        </v-col>
                    </v-row>
                </div>
           </v-card>
        </v-dialog>
    `,
    computed: {
        HoaDon: function () {
            return vueData.DSOrder ?? []
        },
        TongTienHoaDon: function () {
            const $this = this
            let tongTienHoaDon = 0
            $this.HoaDon?.forEach((hd) => {
                tongTienHoaDon += hd.SoLuong * hd.GiaBan_CuaHang
                //Tính tiền Topping
                hd.ThuocTinh?.forEach((tt) => {
                    tongTienHoaDon += tt.SoLuong * tt.GiaBan_CuaHang
                })
            })
            return tongTienHoaDon
        },
    },
    methods: {
        clearData() {
            vueData.IsShowDialogDetailProduct = false
            vueData.IsShowDialogOrder = false
            vueData.DSOrder = []
            vueData.SanPhamGuid_Active = null
        },
        onOpenModalHistory() {
            vueData.IsShowDialogHistory = true
        },
        onDeleteAll() {
            vueData.DSOrder = []
            vueData.IsShowDialogDetailProduct = false //Tắt modal detail
            vueData.IsShowDialogOrder = false //Tắt modal lưu tạm
        },
        onSendOrder() {
            const $this = this
            if ($this.DisableSend === false) {
                $this.DisableSend = true
                const dataJson = []
                vueData.DSOrder.forEach((pro) => {
                    //Xử lý danh sách món
                    const product = {
                        SanPhamID: pro.SanPhamID,
                        SanPhamGUID: pro.SanPhamGuid,
                        NhomLienKetID: pro.NhomLienKetID ?? 0,
                        NhomLienKetChiTietID: 0,
                        NhomLienKetChiTiet_ParentID: 0,
                        TenHienThi: pro.TenSanPham,
                        TenNoiBo: pro.TenNgan,
                        SoLuong: pro.SoLuong,
                        DonGia: pro.GiaBan_CuaHang,
                        ThuTu: 0,
                        GhiChu: pro.GhiChu ?? "",
                        Is_MangVe: pro.Is_MangVe ? 1 : 0,
                        Is_SanPham: 1,
                        Is_ThuocTinh: 0,
                    }
                    dataJson.push(product)
                    //Xử lý danh sách topping
                    pro.ThuocTinh.forEach((item) => {
                        if (item.SoLuong > 0) {
                            const topping = {
                                SanPhamID: item.SanPhamID ?? 0,
                                SanPhamGUID: pro.SanPhamGuid,
                                NhomLienKetID: item.NhomLienKetID,
                                NhomLienKetChiTietID: item.NhomLienKetChiTietID,
                                NhomLienKetChiTiet_ParentID: item.NhomLienKetChiTiet_ParentID,
                                TenHienThi: item.TenHienThi,
                                TenNoiBo: item.TenNoiBo,
                                SoLuong: item.SoLuong,
                                DonGia: item.GiaBan_CuaHang,
                                ThuTu: item.ThuTu,
                                GhiChu: "",
                                Is_MangVe: pro.Is_MangVe ? 1 : 0,
                                Is_SanPham: 0,
                                Is_ThuocTinh: 1,
                            }
                            dataJson.push(topping)
                        }
                    })
                })
                // Gọi API
                const params = {
                    QrCode: vueData.QrCode,
                    ChiTietOrder_JSON: JSON.stringify(dataJson),
                }
                // ajaxCALL("/eorder/auth/HoaDon_Insert", params, (res) => {
                //     if (res.data) {
                //         $this.clearData() //Clear data page
                //         Vue.$toast.success("Đã gửi thành công. ZEN cảm ơn quý khách", { position: "top" })
                //         //Push HoaDonID vào local
                //         const hoaDonId = res.data[0].HoaDonID
                //         if (hoaDonId) {
                //             vueData.HoaDonID = hoaDonId
                //         }
                //         $this.DisableSend = false
                //     }
                // })
            }
        },
    },
})
Vue.component("product-order-component", {
    props: ["product"],
    template: /*html*/ `
        <div>
            <div class="tr-product">
                <div class="td-product-name-send text-green">{{product?.TenNgan}}</div>
                <div class="td-product-qty">{{roundSoLuong(product?.SoLuong)}}</div>
                <div class="td-product-price">{{ThanhTien?.toLocaleString('vi-vn')}}</div>
                <div v-on:click.stop="" class="td-product-action text-right pr-2 pl-0">
                    <v-btn @click="onEdit()" fab class="text-green btn-plus pl-0 pr-0" small>Sửa</v-btn>
                </div>
            </div>
            <div class="tr-product bg-green-2" style="border-bottom: 1px dashed rgb(57 119 68);">
                <template v-for="(topping, i) in product?.ThuocTinh?.filter((item) => (item?.SoLuong > 0))" :key="i">
                    <topping-order-component :topping="topping"/>
                </template>
                <div style="width: 100%" v-if="product?.GhiChu && product?.GhiChu !== ''" class="pl-3 py-1">- Ghi chú: {{product?.Is_MangVe ? 'Mang về - ' : ''}}{{product?.GhiChu}}</span>
            </div>
        </div>
    `,
    computed: {
        ThanhTien: function () {
            return this.product.SoLuong * this.product.GiaBan_CuaHang
        },
    },
    methods: {
        onEdit() {
            const $this = this
            vueData.SanPhamGuid_Active = $this.product.SanPhamGuid
            vueData.IsShowDialogOrder = false
            vueData.IsShowDialogDetailProduct = true
        },
    },
})
Vue.component("topping-order-component", {
    props: ["topping"],
    template: /*html*/ `
        <div :class="topping?.NhomLienKetChiTiet_ParentID === null ? 'break-detail' : ''" :style="topping?.SanPhamID > 0 ? 'width: 100%; background-color: #fff;padding: 3px 0;' : ''">
            <div v-if="topping?.SanPhamID > 0">
                <div class="tr-product">
                    <div class="td-product-name-send pa-0 pl-2">+ {{topping?.TenHienThi}}</div>
                    <div class="td-product-qty pa-0">{{roundSoLuong(topping?.SoLuong)}}</div>
                    <div class="td-product-price pa-0">{{(topping?.SoLuong * topping?.GiaBan_CuaHang).toLocaleString('vi-vn')}}</div>
                    <div class="td-product-action"></div>
                </div>
            </div>
            <div v-if="topping?.SanPhamID === 0 || topping?.SanPhamID === null">
                <div v-if="topping?.NhomLienKetChiTiet_ParentID !== null || topping?.NhomLienKetChiTiet_ParentID > 0" class="ml-3 py-1 pt-2">
                     <label>{{topping?.TenHienThi}}</label>
                </div>
            </div>
        </div>
    `,
})
Vue.component("modal_history_component", {
    props: ["is_show_dialog"],
    data: function () {
        return {
            openQRScan: false,
            HoaDon: {},
            KhachHang_QRCode: "",
            ThongTin_KhachHang: {
                KhachHangID: null,
                KhachHang_HoTen: "",
                ZEN: 0,
            },
            TongZENConLai: 0,
        }
    },
    template: /*html*/ `
        <v-dialog v-model="is_show_dialog" fullscreen scrollable transition="dialog-top-transition">
           <v-card class="model-order">
                <div class="title white--text bg-green pa-2 text-center">
                    DANH SÁCH MÓN ĐÃ GỬI
                </div>
                <div class="order-body">
                    <p class="pa-2 border-bottom font-weight-bold">Hóa đơn: <span class="red--text">{{HoaDon?.MaHoaDon}}</span> (Bàn {{HoaDon?.TenBan}})</p>
                    <template v-for="(item, i) in HoaDon?.ChiTietHoaDon" :key="item.HoaDonChiTietID">
                        <product_history_component :product="item" :order="HoaDon" :khachhang="ThongTin_KhachHang" :zen_con_lai="TongZENConLai"/>
                    </template>
                    <v-row>
                        <v-col cols="6">
                            <div  class="pl-3 py-3">
                                <v-text-field v-if="IsShowApprove" class="mb-1" ref="KhachHang_QRCode" :value="KhachHang_QRCode" @blur="blurUpdateValueKhachHang_QRCode" v-on:keyup.enter="handleEnterKhachHang_QRCode" append-outer-icon="mdi-qrcode-scan"  v-on:click:append-outer="openQRScan = true; blurUpdateValueKhachHang_QRCode;" label="Mã thành viên" hide-details dense outlined></v-text-field>
                                <div v-if="ThongTin_KhachHang?.KhachHangID !== null && ThongTin_KhachHang?.KhachHangID !== '0'">
                                    <span class="font-weight-bold">KH: <b class="primary--text">{{ThongTin_KhachHang?.KhachHang_HoTen}}</b><br/></span>
                                    <span class="font-weight-bold">Điểm ZEN: <b class="green--text">{{ThongTin_KhachHang?.ZEN?.toLocaleString('vi-vn')}}</b><br/></span>
                                    <span v-if="IsShowApprove" class="font-weight-bold">Còn lại: <b>{{TongZENConLai?.toLocaleString('vi-vn')}}</b><br/></span>
                                </div>
                                <div v-if="ThongTin_KhachHang?.KhachHangID === null || ThongTin_KhachHang?.KhachHangID === '0'">
                                    <i class="red--text" style="font-size: 12px">Không tìm thấy khách hàng</i>
                                </div>
                            </div>
                        </v-col>
                        <v-col cols="6">
                            <div class="text-right pr-3 py-3" style="padding-bottom: 100px !important">
                                <span class="font-weight-bold">Tạm tính: </span><b class="primary--text">{{HoaDon?.TongTien?.toLocaleString('vi-vn')}}</b> <br/>
                                <span class="font-weight-bold">Tổng VAT: </span><b>{{HoaDon?.TongVAT?.toLocaleString('vi-vn')}}</b> <br/>
                                <span class="font-weight-bold">ZEN: </span><b class="green--text">{{TongZEN.toLocaleString('vi-vn')}}</b> <br/>
                                <span class="font-weight-bold">Thành tiền: </span><b class="red--text">{{KhachPhaiTra.toLocaleString('vi-vn')}}</b> <br/>
                            </div>
                        </v-col>
                    </v-row>
                </div>
                <div class="pa-3 order-footer">
                    <v-row>
                        <v-col cols="4" class="pr-0">
                            <v-btn block @click="onClose()"><v-icon left>mdi-arrow-left</v-icon>Trở về</v-btn>
                        </v-col>
                        <v-col cols="8" class="text-right">
                            <v-btn v-if="IsShowApprove" @click="onApproved()" block color="error"><v-icon left>mdi-cash-check</v-icon>Xác nhận thanh toán</v-btn>
                        </v-col>
                    </v-row>
                </div>
           </v-card>
           <f-qrcode-reader v-model="openQRScan" v-on:update="KhachHang_QRCode = $event"></f-qrcode-reader>
        </v-dialog>
    `,
    computed: {
        IsShowApprove() {
            //1: Chờ xử lý, 2: Chờ thanh toán, 3: Đã thanh toán, 4: Hoàn tất, 5: Đã hủy, 6: Đã thanh toán một phần, 7: Đã trả hàng, 8: Đặt trước, 9: Tiếp nhận đơn hàng
            return this.HoaDon.TrangThai === 1 || this.HoaDon.TrangThai === 9
        },
        TongZEN: function () {
            const $this = this
            let tongTienZEN = 0
            if ($this.HoaDon?.ChiTietHoaDon?.length > 0) {
                tongTienZEN = CT_TongZEN($this.HoaDon?.ChiTietHoaDon)
                $this.TongZENConLai = $this.ThongTin_KhachHang?.ZEN - tongTienZEN
                $this.HoaDon.KhachTra_Zen = tongTienZEN
            }
            return tongTienZEN
        },
        KhachPhaiTra: function () {
            const $this = this
            return CT_KhachPhaiTra($this.HoaDon?.TongTien, $this.HoaDon?.TongVAT, $this.TongZEN, $this.HoaDon?.GiaoHang_Phi)
        },
    },
    watch: {
        is_show_dialog: function (isShow) {
            const $this = this
            if (isShow) {
                const hoaDonID = vueData.HoaDonID
                if (hoaDonID && hoaDonID > 0) {
                    $this.getData() //First load
                }
            }
        },
        KhachHang_QRCode: function (value) {
            const $this = this
            let trimValue = trimWhitespace(value)
            if (trimValue === "") {
                $this.ThongTin_KhachHang = {}
            } else {
                const params = { QrCode: trimValue }
                // ajaxCALL("/eorder/KhachHang_Select_ByCode", params, (res) => {
                //     if (res.data) {
                //         const data = res.data[0]
                //         $this.ThongTin_KhachHang.KhachHangID = data.KhachHangID
                //         $this.ThongTin_KhachHang.ZEN = data.Diem
                //         $this.ThongTin_KhachHang.KhachHang_HoTen = data.HoTen
                //     }
                // })
            }
        },
    },
    methods: {
        onClose() {
            vueData.IsShowDialogHistory = false
        },
        getData() {
            const $this = this
            const hoaDonID = vueData.HoaDonID
            if (hoaDonID && hoaDonID > 0) {
                const params = {
                    QrCode: vueData.QrCode,
                    HoaDonID: hoaDonID,
                }
                // ajaxCALL("/eorder/auth/HoaDon_Select_ById", params, (res) => {
                //     if (res.data) {
                //         const resHoaDon = res.data[0][0] ?? {}
                //         const resChiTietHoaDon = res.data[1] ?? []
                //         //Xử lý khách hàng
                //         $this.ThongTin_KhachHang.KhachHangID = resHoaDon.KhachHangID
                //         $this.ThongTin_KhachHang.ZEN = resHoaDon.KhachHang_Diem
                //         $this.ThongTin_KhachHang.KhachHang_HoTen = resHoaDon.KhachHang_HoTen
                //         $this.KhachHang_QRCode = resHoaDon.KhachHang_DienThoai
                //         $this.TongZENConLai = resHoaDon.KhachHang_Diem - resHoaDon.KhachTra_Zen
                //         //Xử lý món
                //         const productJsonData = []
                //         const productFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 1)
                //         const toppingFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 0)
                //         productFilter.forEach((item, index) => {
                //             const topping = toppingFilter.filter((topping) => topping.SanPhamGUID === item.SanPhamGUID)
                //             const product = { ...item, SoThuTu: index + 1, ThuocTinh: topping }
                //             productJsonData.push(product)
                //         })
                //         const dataJson = { ...resHoaDon, ChiTietHoaDon: productJsonData }
                //         $this.HoaDon = dataJson
                //     }
                // })
            }
        },
        onApproved() {
            const $this = this
            //Kiểm tra số dư ZEN
            if ($this.HoaDon.KhachTra_Zen > $this.ThongTin_KhachHang.ZEN) {
                Vue.$toast.error("Điểm ZEN của khách không đủ để thực hiện thanh toán. Vui lòng kiểm tra lại", { position: "top" })
                return
            }
            const oldStatus = $this.HoaDon.TrangThai
            $this.HoaDon.TrangThai = 2 //Chờ thanh toán
            //Lấy danh sách món đã check ZEN nếu có
            let listZenChecked = []
            if ($this.ThongTin_KhachHang?.KhachHangID !== null) {
                $this.HoaDon?.ChiTietHoaDon.forEach((pro) => {
                    //Xử lý danh sách món check ZEN
                    if (pro.Is_ThanhToanZen === 1) {
                        listZenChecked.push(pro.HoaDonChiTietID)
                    }
                    //Xử lý danh sách topping check ZEN
                    pro.ThuocTinh.forEach((item) => {
                        if (item.SoLuong > 0 && item.Is_ThanhToanZen === 1) {
                            listZenChecked.push(item.HoaDonChiTietID)
                        }
                    })
                })
            }
            const params = {
                QrCode: vueData.QrCode,
                HoaDonID: $this.HoaDon.HoaDonID,
                KhachHangID: $this.ThongTin_KhachHang?.KhachHangID,
                DS_ThanhToanZen: listZenChecked.length > 0 ? listZenChecked.join(",") : "",
            }
            // ajaxCALL("/eorder/HoaDon_MobilePos_XacNhanThanhToan", params, (res) => {
            //     if (res.data) {
            //         Vue.$toast.success(`Xác nhận thanh toán thành công`, { position: "top" })
            //     } else {
            //         $this.HoaDon.TrangThai = oldStatus //Cập nhật lại trạng thái cũ nếu lỗi
            //     }
            // })
        },
        blurUpdateValueKhachHang_QRCode(e) {
            const $this = this
            //Xử lý thêm nếu danh sách món đã có các món check ZEN từ trước thì phải reset lại
            if ($this.HoaDon?.ChiTietHoaDon.length > 0) {
                $this.HoaDon.ChiTietHoaDon = $this.HoaDon?.ChiTietHoaDon.map((item) => {
                    const topping = item.ThuocTinh.map((tt) => ({ ...tt, Is_ThanhToanZen: 0 }))
                    return { ...item, Is_ThanhToanZen: 0, ThuocTinh: topping }
                })
            }
            $this.KhachHang_QRCode = e.target.value
        },
        handleEnterKhachHang_QRCode(e) {
            this.$refs.KhachHang_QRCode.blur()
        },
    },
})
Vue.component("product_history_component", {
    props: ["product", "order", "khachhang", "zen_con_lai"],
    template: /*html*/ `
        <div :class="(product?.SoLuong === 0 || product?.TrangThai === 6 || product?.TrangThai === 7) ? 'cancel-text' : ''">
            <div class="tr-product">
                <div class="td-product-name-his">
                    <b class="text-green">{{product?.SoThuTu}}. {{product?.TenHienThi}}</b>
                    <span style="font-size: 11px" class="gray-text" v-if="product.TienVAT > 0"><br/>VAT ({{product?.PhanTramVAT}}%): {{product?.TienVAT?.toLocaleString('vi-vn')}}</span><br/>
                    <p :class="MauTrangThai + '--text mt-1'">{{product?.TenTrangThai}}</p>
                </div>
                <div class="td-product-qty-his" v-if="product.TenHienThi.toLowerCase() !== 'khăn lạnh'">
                    {{roundSoLuong(product?.SoLuong)}}
                </div>
                <div class="td-product-qty-his" v-if="product.TenHienThi.toLowerCase() === 'khăn lạnh'">
                    <v-text-field v-model="product.SoLuong" style="width: 50px; display: inline-block;" type="number" class="centered-input" hide-details dense hide-spin-buttons></v-text-field>
                    <v-btn @click="onSaveQuantity" fab class="text-green btn-plus pl-0 pr-0 ml-1" x-small><v-icon color="success">mdi-check-bold</v-icon></v-btn>
                </div>
                <div class="td-product-price pr-1">{{product?.TamTinh?.toLocaleString('vi-vn')}}</div>
                <div class="td-product-action" @click.stop="onUpdateZen" :style="{cursor: 'pointer', visibility: HienThiCheckBoxZEN}">
                    <v-icon color="success">{{product.Is_ThanhToanZen === 1 ? 'mdi-checkbox-marked' : 'mdi-checkbox-blank-outline'}}</v-icon>
                </div>
            </div>
            <div class="tr-product bg-green-2" style="border-bottom: 1px dashed rgb(57 119 68);">
                <template v-for="(topping, i) in product?.ThuocTinh?.filter((item) => (item?.SoLuong > 0))" :key="i">
                    <topping_history_component :topping="topping" :khachhang="khachhang" :zen_con_lai="zen_con_lai"/>
                </template>
                <div style="width: 100%" v-if="product?.GhiChu && product?.GhiChu !== ''" class="pl-3 py-1">- Ghi chú: {{product?.GhiChu}}</span>
            </div>
        </div>
    `,
    computed: {
        MauTrangThai: function () {
            const status = this.product.TrangThai
            let color = ""
            if (status === 1) {
                //Đã nhận
                color = ""
            } else if (status === 2) {
                //Đã hoàn thành
                color = "success"
            } else if (status === 5) {
                //Đang chế biến
                color = "warning"
            } else if (status === 6) {
                //Thu ngân hủy
                color = "error"
            } else if (status === 7) {
                //Bếp xác nhận hủy
                color = "error"
            }
            return color
        },
        HienThiCheckBoxZEN: function () {
            return this.khachhang.ZEN > 0 ? "unset" : "hidden"
        },
    },
    methods: {
        onSaveQuantity() {
            const $this = this
            // Gọi API cập nhật số lượng món khăn lạnh
            const params = {
                HoaDonChiTietID: $this.product.HoaDonChiTietID,
                SoLuong: $this.product.SoLuong,
                TrangThai: $this.product.TrangThai,
                GhiChu: $this.product.GhiChu,
            }
            // ajaxCALL("/eorder/HoaDonChiTiet_Update", params, (res) => {
            //     if (res.data) {
            //         Vue.$toast.success(`Cập nhật số lượng ${$this.product.TenHienThi} thành công`, { position: "top" })
            //         $this.DisableSend = false
            //     }
            // })
        },
        onUpdateZen() {
            const $this = this
            if ($this.order.TrangThai === 1 || $this.order.TrangThai === 9) {
                $this.product.Is_ThanhToanZen = $this.product.Is_ThanhToanZen === 0 ? 1 : 0
            }
        },
    },
})
Vue.component("topping_history_component", {
    props: ["topping", "khachhang", "zen_con_lai"],
    template: /*html*/ `
        <div :class="topping?.NhomLienKetChiTiet_ParentID === null ? 'break-detail' : ''" :style="topping?.SanPhamID > 0 ? 'width: 100%; background-color: #fff;padding: 3px 0;' : ''">
            <div v-if="topping?.SanPhamID > 0">
                <div class="tr-product">
                    <div class="td-product-name-send pl-5 py-0">
                        + {{topping?.TenHienThi}}
                        <span style="font-size: 11px" class="gray-text" v-if="topping.TienVAT > 0"><br/>VAT ({{topping?.PhanTramVAT}}%): {{topping?.TienVAT?.toLocaleString('vi-vn')}}</span><br/>
                    </div>
                    <div class="td-product-qty py-0">{{roundSoLuong(topping?.SoLuong)}}</div>
                    <div class="td-product-price pr-1 py-0">{{(topping?.SoLuong * topping?.DonGia).toLocaleString('vi-vn')}}</div>
                    <div class="td-product-action" @click.stop="onUpdateDetailZen" :style="{cursor: 'pointer', visibility: HienThiCheckBoxDetailZEN}">
                        <v-icon color="success">{{topping.Is_ThanhToanZen === 1 ? 'mdi-checkbox-marked' : 'mdi-checkbox-blank-outline'}}</v-icon>
                    </div>
                </div>
            </div>
            <div v-if="topping?.SanPhamID === 0 || topping?.SanPhamID === null">
                <div v-if="topping?.NhomLienKetChiTiet_ParentID !== null || topping?.NhomLienKetChiTiet_ParentID > 0" class="ml-3 py-1 pt-2">
                     <label>{{topping?.TenHienThi}}</label>
                </div>
            </div>
        </div>
    `,
    computed: {
        HienThiCheckBoxDetailZEN: function () {
            return this.khachhang.ZEN > 0 ? "unset" : "hidden"
        },
    },
    methods: {
        onUpdateDetailZen() {
            const $this = this
            if ($this.zen_con_lai < $this.topping.ThanhTien && $this.topping.Is_ThanhToanZen === 0) {
                return Vue.$toast.warning(`Tổng ZEN còn ${this.zen_con_lai.toLocaleString("vi-vn")}, hãy check topping khác`, { position: "top" })
            }
            $this.topping.Is_ThanhToanZen = $this.topping.Is_ThanhToanZen === 0 ? 1 : 0
        },
    },
})