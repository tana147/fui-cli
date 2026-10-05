<template>
    <div>
     
        <div  dense @click="onClickProduct()" class="d-flex align-center" style="gap: 10px">
            <div>
                <v-img width="70" height="70" contain :src="product?.AnhSanPham_Url" lazy-src="vueData.v_Set.defaultImg" />
            </div>
            <div class="d-flex flex-column justify-center">
                <b class="primary--text" :style="product.TinhTrang === 1 ? 'color: #a9a9a9 !important' : ''">
                    {{ product?.TenSanPham.trim() }}
                    <span v-if="product.TinhTrang === 1">
                        <v-chip color="error" class="ml-1" small>Tạm hết</v-chip>
                    </span>
                    <span v-else>
                        <v-chip v-if="product.SoLuongTon > 0" color="success" class="ml-1" small>Tồn: {{ product.SoLuongTon }}</v-chip>
                        <v-chip v-if="product.Is_BestSeller === 1" color="success" class="ml-1" small>Bán chạy</v-chip>
                        <v-chip v-if="product.Is_Signature === 1" color="success" class="ml-1" small>Signature</v-chip>
                    </span>
                </b>
                <p class="red--text" :style="product.TinhTrang === 1 ? 'color: #a9a9a9 !important' : ''">{{ product?.GiaBan_App.toLocaleString("vi-vn") }}</p>
            </div>
        </div>
        <v-divider></v-divider>
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
                const productInfo = {...product, SanPhamGuid: uuidv4(), SoLuong: 1, SoLuongThucTe: 1, GhiChu: ""}
                const cloneTopping = JSON.parse(JSON.stringify(vueData.DSChiTietLienKet))
                const listTopping = cloneTopping.filter((item) => item.NhomLienKetID === product.NhomLienKetID)
                productInfo.ThuocTinh = listTopping
                vueData.DSOrder.push(productInfo)
                vueData.SanPhamGuid_Active = productInfo.SanPhamGuid
                vueData.IsShowDialogDetailProduct = true
            }
        },
    },
}
</script>
