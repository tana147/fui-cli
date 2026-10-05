<template>
    <div @click="onClickProduct()" class="d-flex align-center">
        <v-chip color="success" small class="mx-2">{{ product?.MaSoSanPham }}</v-chip>
        <span class="mx-2" :style="product.TinhTrang === 1 ? 'color: #d7d7d7' : ''">
            {{ product?.TenNgan }}
            <span v-if="product.TinhTrang === 1">
                <v-chip color="error" class="ml-1" small>Tạm hết</v-chip>
            </span>
            <span v-else>
                <v-chip v-if="product.SoLuongTon > 0" color="success" class="ml-1" small>Tồn: {{ product.SoLuongTon }}</v-chip>
                <v-chip v-if="product.Is_BestSeller === 1" color="success" class="ml-1" small>Bán chạy</v-chip>
                <v-chip v-if="product.Is_Signature === 1" color="success" class="ml-1" small>Signature</v-chip>
            </span>
        </span>
    </div>
</template>

<script>
export default {
    props: ["product"],
    methods: {
        onClickProduct() {
            const $this = this
            const product = $this.product
            if (product.TinhTrang === 1) {
                Vue.$toast.warning("Món tạm hết, mong Quý khách thông cảm!", {position: "top"})
            } else {
                //Xử lý topping
                const cloneTopping = JSON.parse(JSON.stringify(vueData.DSChiTietLienKet))
                const listTopping = cloneTopping.filter((item) => item.NhomLienKetID === product.NhomLienKetID)
                //Xử lý nhóm loại ly
                const cloneNhomLoaiLy = JSON.parse(JSON.stringify(vueData.DSNhomLoaiLy))
                console.log('product.NhomLoaiLyID', product.NhomLoaiLyID)
                const listNhomLoaiLy = cloneNhomLoaiLy.filter((item) => item.NhomLoaiLyID === product.NhomLoaiLyID)
                const productInfo = {...product, SanPhamGuid: uuidv4(), SoLuong: 1, ThuocTinh: listTopping, NhomLoaiLy: listNhomLoaiLy, SoLuongThucTe: 1, GhiChu: "", Is_GuiBepBar: 0}
                vueData.ItemProduct = productInfo
                vueData.IsShowDialogDetailProduct = true
            }
        },
    },
}
</script>
