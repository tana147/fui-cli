<template>
    <v-text-field ref="refSearchText" v-model="searchText" class="mt-2" placeholder="F5 - Tìm theo tên nguyên liệu, nhân viên..." outlined dense hide-details clearable style="width: 318px" background-color="white" color="primary"></v-text-field>
</template>

<script>
export default {
    props: ["value"],
    data() {
        return {
            searchText: null,
            DataOrderTemp: vueData.DSHoaDonDaTiepNhan_ResFilter,
        }
    },
    mounted() {
        window.addEventListener("keydown", this.handleKeyDown) //Lắng nghe sự kiện keyDown, sử dụng cho phím tắt
    },
    beforeDestroy() {
        window.removeEventListener("keydown", this.handleKeyDown)
    },
    computed: {
        DataOrder_Sorted: function () {
            return this.value ?? []
        },
    },
    watch: {
        searchText: _.debounce(function (val) {
            if (val) {
                let _searchText = val.toString().toLowerCase()
                const dataOrderFilter = this.DataOrder_Sorted.filter((item) => {
                    const searchTerm = _searchText.toLowerCase()
                    const MaHoaDon = item.MaHoaDon ? item.MaHoaDon.toLowerCase() : ""
                    const TenBan = item.TenBan ? item.TenBan.toLowerCase() : ""
                    const TenKhu = item.TenKhu ? item.TenKhu.toLowerCase() : ""
                    return MaHoaDon.includes(searchTerm) || TenBan.includes(searchTerm) || TenKhu.includes(searchTerm)
                })
                this.$emit("input", dataOrderFilter)
            } else {
                this.$emit("input", vueData.DSHoaDonDaTiepNhan_ResFilter)
            }
        }, 100),
    },
    methods: {
        handleKeyDown(event) {
            if (event.keyCode === 116) {
                // Sử dụng mã keyCode của phím "F5"
                event.preventDefault() // Chặn ko cho Refresh page khi bấm F5
                this.focusInputF5()
            }
        },
        focusInputF5() {
            const $this = this
            //Chỉ hoạt động ở Tab Món
            if (vueData.TabProduct === 0) {
                //Khi Nhấn phím F5 thì Input tìm kiếm = null
                $this.searchText = null
                this.$refs.refSearchText.focus()
            }
        },
    },
}
</script>
