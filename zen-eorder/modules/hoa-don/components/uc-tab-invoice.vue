<template>
    <v-container fluid style="padding: 0; height: calc(100vh - 127px); overflow-y: auto">
        <div style="display: flex; flex-wrap: wrap; gap: 15px; overflow-x: auto">
            <div v-for="(item, i) in DataOrder_Sorted" :key="item.HoaDonID">
                <uc-tab-invoice-item :item="item" />
            </div>
        </div>
    </v-container>
</template>

<script>
export default {
    props: ["data_order"],
    computed: {
        DataOrder_Sorted() {
            return this.data_order.slice().sort((a, b) => a.HoaDonID - b.HoaDonID)
        },
    },
    data() {
        return {}
    },
    mounted() {},
    watch: {},
    methods: {},
}
</script>
