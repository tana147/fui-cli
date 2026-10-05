<template>
    <div :class="detail?.NhomLienKetChiTiet_ParentID === null ? 'break-detail' : ''" :style="detail?.NhomLienKetChiTiet_ParentID !== null && detail?.CachSapXep === 1 ? 'width: 50%;' : ''" style="background-color: #fff">
        <div v-if="detail?.NhomLienKetChiTiet_ParentID > 0 && detail?.CachSapXep === 1" style="width: 100%; border-right: 1px solid #d2d2d2b0">
            <div class="tr-product" style="justify-content: space-between">
                <div class="td-product-name pa-0 pl-2">
                    <p class="text-body-2">{{ detail?.TenNoiBo }}</p>
                </div>
                <div class="td-product-qty pa-0 pr-2" style="width: auto">
                    <v-btn @click="onReduce()" :disabled="(detail?.SoLuong === 1 && detail.Is_ThuocTinh === 1) || (product.HoaDonID > 0 && detail.SoLuong <= product.SoLuong)" class="fab v-btn--round bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-minus</v-icon></v-btn>
                    <span class="px-2 text-body-2" style="font-weight: 500">{{ roundSoLuong(detail.SoLuong) }}</span>
                    <v-btn @click="onIncrease()" :disabled="IsMaximum" class="fab v-btn--round bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-plus</v-icon></v-btn>
                </div>
            </div>
        </div>
        <div v-if="detail?.NhomLienKetChiTiet_ParentID > 0 && detail?.CachSapXep === 0">
            <div v-if="detail?.NhomLienKetChiTiet_ParentID !== null || detail?.NhomLienKetChiTiet_ParentID > 0" class="ml-2 pb-1">
                <label @click="onCheck(!IsChecked)" style="cursor: pointer">
                    <span class="mr-2" :style="{ color: IsChecked ? 'red' : 'black', 'font-weight': IsChecked ? 'bold' : 'normal' }">{{ detail?.TenNoiBo }}</span>
                </label>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: ["detail", "product", "value"],
    computed: {
        ThanhTien: function () {
            let thanhtien = 0
            thanhtien = this.detail.SoLuong * this.detail.GiaBan_CuaHang
            this.detail.ThanhTien = thanhtien
            return thanhtien
        },
        IsChecked: function () {
            return this.detail.SoLuong
        },
        IsMaximum: function () {
            const $this = this
            return $this.detail?.SoLuong >= $this.detail?.SoLuongToiDa * Math.ceil($this.product?.SoLuong)
        },
    },
    methods: {
        onIncrease() {
            const $this = this
            $this.detail.SoLuongThucTe += 1
            if ($this.detail.MaintainQuanlityRatio === 1) {
                $this.detail.SoLuong = $this.product.SoLuong
            } else {
                $this.detail.SoLuong = $this.detail.SoLuongThucTe * $this.product.SoLuong
            }
            if ($this.detail.TienVAT_CuaHang_SanPham > 0) {
                $this.detail.TienVAT_CuaHang_SanPham = CT_TienVAT($this.detail.TienVAT_CuaHang_SanPham, $this.detail.VAT_CuaHang, $this.ThanhTien)
            }
        },
        onReduce() {
            const $this = this
            $this.detail.SoLuongThucTe = $this.detail.SoLuongThucTe <= 0 ? 0 : $this.detail.SoLuongThucTe - 1
            if ($this.detail.MaintainQuanlityRatio === 1) {
                $this.detail.SoLuong = $this.detail.SoLuongThucTe * $this.product.SoLuong
            } else {
                $this.detail.SoLuong = $this.detail.SoLuongThucTe * $this.product.SoLuong
            }
            if ($this.detail.SoLuong === 0) {
                $this.detail.Is_ThanhToanZen = 0
            }
            if ($this.detail.TienVAT_CuaHang_SanPham > 0) {
                $this.detail.TienVAT_CuaHang_SanPham = CT_TienVAT($this.detail.TienVAT_CuaHang_SanPham, $this.detail.VAT_CuaHang, $this.ThanhTien)
            }
        },
        onCheck(checked) {
            const $this = this

            //Lấy thông tin thiết lập nhóm cha
            const parentFilter = $this.product.ThuocTinh.filter((item) => item.NhomLienKetChiTietID === $this.detail.NhomLienKetChiTiet_ParentID)
            const parent = parentFilter[0]

            //Lấy tổng số lượng check
            let totalCheck = 1
            $this.product.ThuocTinh.forEach((item) => {
                if (item.NhomLienKetChiTiet_ParentID === parent.NhomLienKetChiTietID && item.SoLuong > 0) {
                    totalCheck += 1
                }
            })

            //Nếu Checked: Ràng buộc số lượng tối đa
            if (checked) {
                if (totalCheck > parent.SoLuongToiDa) {
                    //Chỉ hiển thị thông báo nếu số lượng tối đa > 1. Số lượng tối đa = 1 thì toggle check (Không thông báo)
                    if (parent.SoLuongToiDa > 1) {
                        Vue.$toast.warning(`Chỉ được chọn tối đa ${parent.SoLuongToiDa} ${parent.TenNoiBo}`, { position: "top" })
                        $this.detail.SoLuongThucTe = 0
                    } else {
                        //Set lại số lượng = 0 cho các STPV trong nhóm
                        $this.product.ThuocTinh.map((item) => {
                            if (item.NhomLienKetChiTiet_ParentID === parent.NhomLienKetChiTietID) {
                                item.SoLuongThucTe = 0
                                item.SoLuong = 0
                            }
                            return item
                        })
                        $this.detail.SoLuongThucTe = 1
                    }
                } else {
                    $this.detail.SoLuongThucTe = 1
                }
            } else {
                //Nếu UnChecked: Ràng buộc số lượng tối thiểu
                if (totalCheck < parent.SoLuongToiThieu) {
                    Vue.$toast.warning(`Phải chọn tối thiểu ${parent.SoLuongToiThieu} ${parent.TenNoiBo}`, { position: "top" })
                    $this.detail.SoLuongThucTe = 1
                } else {
                    $this.detail.SoLuongThucTe = 0
                }
            }
            $this.detail.SoLuong = $this.detail.SoLuongThucTe * $this.product.SoLuong
        },
        onUpdateDetailZen() {
            const $this = this
            $this.detail.Is_ThanhToanZen = $this.detail.Is_ThanhToanZen === 0 ? 1 : 0
        },
    },
}
</script>
