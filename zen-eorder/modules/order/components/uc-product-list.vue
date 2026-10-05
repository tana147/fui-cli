<template>
    <div>
        <div v-for="(product, i) in DSSanPham" :key="product.SanPhamID">
            <uc-product-list-item :product="product" />
        </div>
    </div>
</template>

<script>
export default {
    computed: {
        DSSanPham: function () {
            let _filterProduct = vueData.DSSanPhamFilter
            let filterProduct = []
                const keyword = vueData.SearchKeyword ?? ""
                filterProduct = _filterProduct.filter((item) => {
                    return keyword === "" || toSlug(item.TenNgan).includes(toSlug(keyword)) || toSlug(item.MaSoSanPham).includes(toSlug(keyword))
                })
          
            return filterProduct ?? []
        },
    },
}
</script>
