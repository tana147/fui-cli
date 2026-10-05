<template>
	<v-expansion-panel :readonly="IsCancel || IsOldOrder || SanPham?.HoaDonChiTietID > 0" :style="CancelBackground" @click="scrollToOpen">
        <v-expansion-panel-header id="header-panel" class="d-flex flex-column pa-0" hide-actions>
            <div class="tr-product mt-1">
                <div class="td-product-name cursor-pointer">
                    <p class="mb-0 font-weight-bold text-green">{{ thu_tu + 1 }}. {{ SanPham?.TenSanPham }}</p>
                    <p class="product-status-name" v-if="SanPham?.TrangThai" :style="CancelColor">{{ SanPham?.TenTrangThai }}</p>
                    <small class="product-status-name font-weight-light">
                        <span>
                            Giá: <span class="red--text font-weight-regular">{{ SanPham?.GiaBan_CuaHang?.toLocaleString("vi-vn") }}</span>
                        </span>
                        <span v-if="SanPham.TienVAT_CuaHang_SanPham > 0" class="mb-0">
                            • VAT ({{ SanPham.PhanTramVAT }}%): <span class="red--text font-weight-regular">{{ SanPham.TienVAT_CuaHang_SanPham.toLocaleString("vi-vn") }}</span>
                        </span>
                    </small>
                </div>
                <div class="td-product-price product-price-main">
                    <span v-if="SanPham.Is_KhuyenMai === 1">
                        <v-icon color="primary">mdi-gift</v-icon>
                    </span>
                    <span v-else>{{ ThanhTien?.toLocaleString("vi-vn") }}</span>
                </div>
                <div class="td-product-qty product-qty-button" v-if="!IsCancel">
                    <v-btn @click.stop="onReduce" :disabled="SanPham.HoaDonID > 0 || SanPham.Is_KhuyenMai === 1" class="fab v-btn--round bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-minus</v-icon></v-btn>
                    <v-text-field v-if="SanPham.SoLuongThapPhan" @blur="blurSoLuong" ref="refTextFieldSoLuong" @keydown="handleEnter" :value="roundSoLuong(SanPham.SoLuong)" @click.stop="" :disabled="(SanPham.TrangThai && SanPham?.SoLuong <= 1) || SanPham.HoaDonID !== 0 || SanPham.Is_KhuyenMai === 1" type="number" class="centered-input" hide-details dense hide-spin-buttons></v-text-field>
                    <span v-else class="px-2 mb-0">{{ SanPham?.SoLuong }}</span>
                    <v-btn @click.stop="onIncrease" :disabled="SanPham.HoaDonID > 0 || SanPham.Is_KhuyenMai === 1" class="fab v-btn--round bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-plus</v-icon></v-btn>
                </div>
                <div class="td-product-qty product-qty-button" v-else>
                    <span class="px-2">{{ SanPham?.SoLuong }}</span>
                </div>
                <div class="td-product-zen cursor-pointer" @click.stop="onUpdateZen" :style="{visibility: value.KhachHang_ZEN > 0 && SanPham.Is_KhuyenMai === 0 ? 'unset' : 'hidden'}">
                    <v-icon :color="IsCancel ? 'error' : 'success'">{{ SanPham.Is_ThanhToanZen === 1 ? "mdi-checkbox-marked" : "mdi-checkbox-blank-outline" }}</v-icon>
                </div>
                <div class="td-product-cancel">
                    <v-btn v-if="!IsCancel && !IsOldOrder" @click.stop="onHuyMon(SanPham.HoaDonID)" class="fab v-btn--round" elevation="0" x-small color="error"><v-icon small>mdi-close</v-icon></v-btn>
                </div>
            </div>
            <div class="w-100">
                <p class="pt-0 ma-2 fs-13px">
                    <span v-if="SanPham?.Is_MangVe">Mang về, </span>
                    <span v-if="SanPham?.TenLoaiLy">{{ SanPham?.TenLoaiLy }}, </span>
                    <template v-if="SanPham.ThuocTinh.filter((item) => item.SoLuong > 0).length > 0">
                        {{ renderViSanPham(SanPham.ThuocTinh.filter((item) => item.SoLuong > 0)) }}
                    </template>
                </p>
            </div>
            <div class="tr-product" v-if="detail.SanPhamID > 0" v-for="(detail, index) in SanPham.ThuocTinh.filter((item) => item.SoLuong > 0)">
                <div class="td-product-name fs-13px pl-2 pt-0 pb-1">
                    + {{ detail?.TenNoiBo }}
                    <p class="font-weight-light fs-11px mt-1 pl-3">
                        <span>
                            Giá: <span class="font-weight-regular">{{ detail?.GiaBan_CuaHang?.toLocaleString("vi-vn") }}</span>
                            <span v-if="detail.TienVAT_CuaHang_SanPham > 0">
                                • VAT({{ detail?.VAT_CuaHang }}%): <span class="font-weight-regular">{{ detail?.TienVAT_CuaHang_SanPham.toLocaleString("vi-vn") }}</span>
                            </span>
                        </span>
                    </p>
                </div>
                <div class="td-product-price pa-0 pb-0" v-if="detail?.SoLuong > 0">{{ thanhTienTopping(detail).toLocaleString("vi-vn") }}</div>
                <div class="td-product-price pa-0 pb-0" style="color: #bdbdbd" v-if="detail?.SoLuong === 0">{{ detail?.GiaBan_CuaHang?.toLocaleString("vi-vn") }}</div>
                <div class="td-product-qty pa-0 pb-0">
                    <span class="px-2" style="font-size: 14px; font-weight: 500">{{ roundSoLuong(detail?.SoLuong) }}</span>
                </div>
                <div class="td-product-zen pa-0 pb-0" :style="{visibility: value.KhachHang_ZEN > 0 && detail.SoLuong > 0 ? 'unset' : 'hidden'}" @click.stop="onUpdateDetailZEN(detail)">
                    <v-icon :color="detail?.TrangThai === 6 || detail?.TrangThai === 7 ? 'error' : 'success'">{{ detail?.Is_ThanhToanZen === 1 ? "mdi-checkbox-marked" : "mdi-checkbox-blank-outline" }}</v-icon>
                </div>
            </div>
            <div class="product-note">
                <div v-if="SanPham?.GhiChu" class="pa-2">
                    Ghi chú: <span>{{ SanPham?.GhiChu }}</span>
                </div>
            </div>
        </v-expansion-panel-header>
        <v-expansion-panel-content>
            <div class="tr-product border-bottom-primary">
                <div class="ml-2 py-1" v-if="vueData.LoaiPhanHieuID !== 1">
                    <label @click="onCheck()" class="cursor-pointer">
                        <span :class="IsChecked ? 'topping-checked' : ''"> Mang về</span>
                    </label>
                </div>
                <template v-for="(detail, i) in SanPham.NhomLoaiLy" :key="i">
                    <label class="ml-2 my-1" @click="onCheckLoaiLy(detail)" style="cursor: pointer">
                        <span class="mr-2" :style="{color: detail.Is_Checked ? 'red' : 'black', 'font-weight': detail.Is_Checked ? 'bold' : 'normal'}">{{ detail?.TenLoaiLy }}</span>
                    </label>
                </template>
                <template v-for="(detail, i) in SanPham.ThuocTinh.filter((item) => item.SoLuong > 0 && item?.SanPhamID > 0)" :key="i" v-if="SanPham.TrangThai">
                    <uc-order-product-topping :detail="detail" :product="SanPham" v-model="value" />
                </template>
                <template v-for="(detail, i) in SanPham.ThuocTinh" :key="i" v-if="!SanPham.TrangThai">
                    <uc-order-product-topping :detail="detail" :product="SanPham" v-model="value" />
                </template>
                <div class="break-detail">
                    <v-text-field class="input-note" v-model="SanPham.GhiChu" solo dense hide-details placeholder="Ghi chú"></v-text-field>
                </div>
            </div>
        </v-expansion-panel-content>
        <uc-modal-huy-mon :isDialog.sync="IsDialogHuyMon" :SanPham="SanPham" v-model="value" />
    </v-expansion-panel>
</template>

<script>
	export default {
		props: ["value", "SanPham", "thu_tu", "order", "Panel"],
    mounted() {
        this.IsChecked = this.SanPham.Is_MangVe
    },
    data() {
        return {
            IsChecked: false,
            IsDialogHuyMon: false,
        }
    },
    computed: {
        IsOldOrder: function () {
            const $this = this
            return $this.value.HoaDonID > 0 && checkTrangThaiButtonFooter($this.value.TrangThai)
        },
        IsCancel: function () {
            const $this = this
            return $this.SanPham.TrangThai === 6 || $this.SanPham.TrangThai === 7
        },
        CancelBackground: function () {
            const $this = this
            return $this.SanPham.TrangThai === 6 || $this.SanPham.TrangThai === 7 ? "background-color: #ff00001c" : "background-color: #ffffff"
        },
        CancelColor: function () {
            const $this = this
            return $this.SanPham.TrangThai === 6 || $this.SanPham.TrangThai === 7 ? "color: red" : "color: #1976d2"
        },
        /** Tạm tính */
        ThanhTien: function () {
            let thanhtien = 0
            thanhtien = this.SanPham.SoLuong * this.SanPham.GiaBan_CuaHang
            this.SanPham.ThanhTien = thanhtien
            return thanhtien
        },
        HienThiBtnKhuyenMai: function () {
            let style = "unset"
            if (this.SanPham?.Is_ThanhToanZen === 1) {
                style = "hidden"
            }
            return style
        },
    },
    methods: {
        CTTongTienMon() {
            const $this = this
            let tongTienTopping = 0
            let tongTienMon = 0
            //Kiểm tra Sản phẩm đó có khuyến mãi ko?
            if ($this.SanPham.Is_KhuyenMai === 0) {
                $this.SanPham?.ThuocTinh?.forEach((item) => {
                    tongTienTopping += item.SoLuong * item.GiaBan_CuaHang
                })
                if ($this.SanPham.HoaDonID <= 0) {
                    //Lấy ThanhTien từ computed khi mới thêm dsorder
                    tongTienMon = $this.ThanhTien + tongTienTopping + ($this.SanPham.TienVAT_CuaHang_SanPham ?? 0)
                } else {
                    //Lấy TamTinh của sản phẩm đã lưu vào database ra để tính tổng tiền món thay vì tự tính
                    tongTienMon = $this.SanPham.TamTinh + tongTienTopping + ($this.SanPham.TienVAT_CuaHang_SanPham ?? 0)
                }
                if (tongTienMon > $this.value.KhachHang_ZEN) {
                    $this.SanPham.Is_ThanhToanZen = 0
                }
            }
            this.SanPham.TongTienMon = tongTienMon
            return tongTienMon
        },
        scrollToOpen() {
            this.$nextTick(() => {
                setTimeout(() => {
                    const itemId = `item-${this.SanPham.SanPhamGUID}`
                    const titleElement = document.getElementById(itemId)
                    if (titleElement) {
                        titleElement.scrollIntoView({
                            behavior: "smooth",
                            block: "nearest",
                        })
                    }
                }, 0)
            })
        },
        onIncrease() {
            const $this = this
            $this.SanPham.SoLuong += 1
            if ($this.SanPham.TienVAT_CuaHang_SanPham > 0) {
                $this.SanPham.TienVAT_CuaHang_SanPham = CT_TienVAT($this.SanPham.TienVAT_CuaHang_SanPham, $this.SanPham.PhanTramVAT, $this.ThanhTien)
            }
            $this.updateToppingQuantity() //Tăng số lượng topping theo số lượng món
        },
        onReduce() {
            const $this = this
            $this.SanPham.SoLuong = $this.SanPham.SoLuong <= 0 ? 0 : $this.SanPham.SoLuong - 1

            if ($this.SanPham.TienVAT_CuaHang_SanPham > 0) {
                $this.SanPham.TienVAT_CuaHang_SanPham = CT_TienVAT($this.SanPham.TienVAT_CuaHang_SanPham, $this.SanPham.PhanTramVAT, $this.ThanhTien)
            }
            if ($this.SanPham.SoLuong <= 0) {
                $this.onDelete() //Remove sản phẩm
            } else {
                $this.updateToppingQuantity() //Giảm số lượng topping theo số lượng món
            }
        },
        updateToppingQuantity() {
            const $this = this
            $this.SanPham.ThuocTinh.map((item) => {
                if (item.SoLuongThucTe > 0 && item.SanPhamID > 0) {
                    item.SoLuong = item.SoLuongThucTe * parseFloat($this.SanPham.SoLuong)
                    //Khi updateTopping thì update luôn cả TienVAT của topping
                    let thanhtien = item.SoLuong * item.GiaBan_CuaHang
                    item.TienVAT_CuaHang_SanPham = CT_TienVAT(item.TienVAT_CuaHang_SanPham, item.VAT_CuaHang ?? 0, thanhtien)
                }
                return item
            })
        },
        onDelete() {
            const $this = this
            $this.value.TongMonChuaTra -= 1
            const index = $this.order.findIndex((item) => item.SanPhamGUID === $this.SanPham.SanPhamGUID)
            if (index >= 0) {
                $this.order.splice(index, 1) //Remove sản phẩm
            }
        },
        onUpdateZen() {
            const $this = this
            $this.SanPham.Is_ThanhToanZen = $this.SanPham.Is_ThanhToanZen === 0 ? 1 : 0
            //Nếu Sản phẩm check ZEN thì các thuộc tính trong có số lượng > 0 thì thuộc tính đó sẽ checkZEN
            if ($this.SanPham.Is_ThanhToanZen === 1) {
                $this.SanPham.ThuocTinh = $this.SanPham.ThuocTinh.map((itemTP) => {
                    if (itemTP.SoLuong > 0) {
                        itemTP.Is_ThanhToanZen = 1
                        return itemTP
                    }
                    return itemTP
                })
            }
            if ($this.SanPham.Is_ThanhToanZen === 1) {
                $this.SanPham.Is_KhuyenMai = 0
            }
        },
        onUpdateDetailZEN(detail) {
            detail.Is_ThanhToanZen = detail.Is_ThanhToanZen === 0 ? 1 : 0
        },
        onHuyMon(HoaDonID) {
            const $this = this
            if (checkTrangThaiButtonFooter(this.value.TrangThai) && $this.SanPham.TrangThai) {
                return Vue.$toast.error(`Hóa đơn trong trạng thái ${this.value.TenTrangThai}`, {position: "top"})
            }
            if (HoaDonID > 0) {
                $this.IsDialogHuyMon = true
            } else {
                $this.onDelete()
            }
        },
        onCheck() {
            const $this = this
            $this.SanPham.Is_MangVe = !$this.SanPham.Is_MangVe
            $this.IsChecked = $this.SanPham.Is_MangVe
        },
        onCheckLoaiLy(loaiLy) {
            const $this = this
            const loaiLyId = loaiLy.LoaiLyID ?? 0
            const isUnchecked = $this.SanPham.LoaiLyID === loaiLyId
            $this.SanPham.NhomLoaiLy = $this.SanPham.NhomLoaiLy.map((item) => ({
                ...item,
                Is_Checked: isUnchecked ? false : item.LoaiLyID === loaiLyId,
            }))
            $this.SanPham.LoaiLyID = isUnchecked ? null : loaiLyId
            $this.SanPham.TenLoaiLy = isUnchecked ? null : loaiLy.TenLoaiLy
        },
        updateSoLuongSanPham(value) {
            const num = parseInt(trimWhitespace(value))
            if (num > 0 || !isNaN(num)) {
                this.SanPham.SoLuong = Number(num)
            } else {
                this.SanPham.SoLuong = 1
            }
        },
        renderViSanPham(arr) {
            let string = ""
            let filterArr = arr.filter((item) => item.GiaBan_CuaHang <= 0 && item?.SanPhamID <= 0)
            let getName = filterArr.map((item) => item.TenNoiBo)
            string = getName.join(", ")
            return string
        },
        blurSoLuong(e) {
            const $this = this
            let value = e.target.value.trim()
            const regex = /^(\d+(\.\d{0,3})?)?$/
            if (!regex.test(value)) {
                value = value.replace(/[^0-9.]/g, "")
            }
            if (value < 0 || value === "") {
                value = 1
            }
            if (vueData.LoaiPhanHieuID === 1) {
                value = parseInt(value)
            } else {
                //Lấy tối đa 3 số thập phân
                if (value.toString().includes(".")) {
                    if (value.length - value.indexOf(".") > 2) {
                        value = parseFloat(value).toFixed(2)
                    }
                }
            }
            e.target.value = value
            $this.SanPham.SoLuong = parseFloat(value)
            $this.SanPham.TienVAT_CuaHang_SanPham = CT_TienVAT($this.SanPham.TienVAT_CuaHang_SanPham, $this.SanPham.PhanTramVAT, $this.ThanhTien)
            $this.updateToppingQuantity()
        },
        handleEnter(e) {
            if (e.code === "Enter") {
                this.$refs.refTextFieldSoLuong.blur()
            }
        },
        thanhTienTopping(detail) {
            return detail.SoLuong * detail.GiaBan_CuaHang
        },
    },
	}
</script>