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
            searchData: this.value,
            DsData: [],
        }
    },
    mounted() {
        this.onLoadData('')
    },
    computed: {},
    watch: {
        // Cha đổi value → cập nhật lại searchData
        value(val) {
            this.searchData = val

            // nếu clear từ cha
            if (val === null) {
                this.onLoadData('')
            }
        },
    },
    methods: {
        onSelectData(item) {
            this.$emit('update:value', item?.value ?? null)
        },

        onLoadData() {
            apiCall(
                '/work/MT_NguyenLieu_Select',
                {
                    TimKiem: '',
                    LoaiNguyenLieu: '',
                    PageIndex: 1,
                    PageSize: 50,
                },
                (res) => {
                    this.DsData = res.data[1].map((item) => ({
                        title: item.TenHangHoa,
                        value: item.NguyenLieu_Id,
                    }))
                },
            )
        },
    },
}
</script>
