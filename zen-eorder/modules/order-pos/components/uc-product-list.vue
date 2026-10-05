<template>
    <div>
        <div class="div-item-product" v-for="(product, i) in DSSanPham" :key="product.SanPhamID">
            <uc-product-list-item :product="product" />
        </div>
    </div>
</template>

<script>
export default {
    computed: {
        DSSanPham: function () {
            const keyword = vueData.SearchKeyword ?? ""
            const filterProduct = vueData.DSSanPham.filter((item) => {
                return keyword === "" || toSlug(item.TenNgan).includes(toSlug(keyword)) || toSlug(item.MaSoSanPham).includes(toSlug(keyword))
            })
            return filterProduct ?? []
        },
    },
}
</script>
