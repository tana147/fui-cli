<template>
    <v-row class="mt-4">
        <v-col cols="4" offset="4" v-for="(col, i) in columns" :key="i">
            <div class="page-section mb-4" v-for="(category, i) in col" :key="i">
                <v-card elevation="0">
                    <v-card-title class="d-flex justify-space-between align-center px-0">
                        <span class="primary--text d-flex align-center">
                            <v-icon class="mr-2" color="success">{{ category.IconNhomSanPhamMon }}</v-icon> {{ category.TenNhomSanPhamMon }}
                            <v-chip v-if="category.Is_HienThi" small class="ml-2" color="success">Có hiển thị thống kê</v-chip>
                        </span>
                        <v-btn elevation="0" color="primary" fab icon outlined x-small @click="onEdit(category)"><v-icon>mdi-pencil</v-icon></v-btn>
                    </v-card-title>
                    <v-card-text class="pa-0">
                        <f-table :label="false" :headers="headers" :items="category.items" dense :items-per-page="-1" :hide-default-footer="true" />
                    </v-card-text>
                </v-card>
            </div>
        </v-col>
        <uc-modal-edit-dish-order v-model="isEdit" :item="itemEdit" @Finish="getNhomSanPhamMon" />
    </v-row>
</template>
<script>
export default {
    data() {
        return {
            headers: [
                {
                    text: "Nhóm sản phẩm",
                    value: "TenNhomSanPham",
                },
            ],
            categoryOrders: [], // categoryOrders: danh mục chứa danh sách sản phẩm (chỉ có thể thêm nhóm sản phẩm vào danh mục)
            groupItems: [],
            itemEdit: {},
            isEdit: false,
            vueData,
            columns: [[], [], []],
        }
    },
    watch: {},
    mounted() {
        this.getNhomSanPhamMon()
    },
    methods: {
        ajaxCALLPromise(url, params = null) {
            return new Promise((reslove) => ajaxCALL(url, params, (res) => reslove(res.data)))
        },
        async getNhomSanPhamMon() {
            const res = await this.ajaxCALLPromise("/eorder/NhomSanPhamMon_Select", null)
            const [categories, groupItems] = res

            //  xử lí mapping nhóm sản phẩm vào trong Nhóm order
            const handleMapping = categories.map((category) => {
                const items = groupItems.filter((item) => item.NhomSanPhamMonID == category.NhomSanPhamMonID)
                const itemIDs = items.map((item) => item.NhomSanPhamID)
                return {...category, items, itemIDs}
            })

            this.categoryOrders = await [...handleMapping]
            this.categoryOrders.forEach((item, i) => {
                this.columns[i % 3].push(item)
            })
        },
        onEdit(item) {
            this.itemEdit = Object.assign({}, item)
            vueData.dialogDishOrder = true
        },
    },
}
</script>
