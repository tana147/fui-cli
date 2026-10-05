<template>
    <div>
        <v-autocomplete
            v-model="searchData"
            :placeholder="placeholder"
            :label="label"
            :variant="isUnderlined ? 'underlined' : 'outlined'"
            :items="DsData"
            :clearable="isClearable === 'false' ? false : true"
            return-object
            density="compact"
            no-data-text="Chưa có dữ liệu"
            @update:model-value="onSelectData"
            @update:menu="onStartLoadData"
        />
    </div>
</template>

<script>
export default {
    props: {
        value: {
            type: [String, Number, null],
            default: null,
        },
        isUnderlined: {
            type: Boolean,
            default: false,
        },
        initValue: {
            type: Object,
            default: null,
        },
        placeholder: {
            type: String,
            default: '',
        },
        label: {
            type: String,
            default: '',
        },
        isClearable: {
            type: String,
            default: 'false',
        },
    },
    emits: ['update:value'],
    data() {
        return {
            searchData: null,
            DsData: [],
        }
    },
    mounted() {},
    computed: {},
    watch: {
        // Cha đổi value → cập nhật lại searchData
        value(val) {
            if (val === null) {
                this.searchData = null
            }
        },

        initValue: {
            // :initValue="{
            //   title: item.QuyDoi_DonViTinh_Ten,
            //   value: item.QuyDoi_DonViTinh_Id,
            //}"

            immediate: true,
            deep: true,
            handler(val) {
                if (!val || val.value == null) return

                // 🔑 chỉ gán nếu chưa chọn gì
                if (!this.searchData) {
                    this.searchData = {
                        title: val.title,
                        value: val.value,
                    }
                }
            },
        },
    },
    methods: {
        onStartLoadData(isOpen) {
            if (isOpen && this.DsData.length === 0) {
                this.onLoadData()
            }
        },

        onSelectData(item) {
            this.searchData = item
            this.$emit('update:value', item?.value ?? null)
        },

        onLoadData() {
            apiCall('/work/HH_DonViTinh_Select_Dropdown', null, (res) => {
                this.DsData = res.data.map((item) => ({
                    title: item.TenDonVi,
                    value: item.DonViTinh_Id,
                }))
            })
        },
    },
}
</script>
