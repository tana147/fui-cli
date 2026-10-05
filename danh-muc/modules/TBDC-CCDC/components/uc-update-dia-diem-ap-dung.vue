<template>
    <div class="pa-4">
        <div class="d-flex align-center mb-3">
            <div class="font-weight-bold">Địa điểm áp dụng ({{ DSDiaDiemApDung.length }})</div>
        </div>
        <v-list density="compact" class="d-flex flex-row flex-wrap supplier-location-list">
            <v-list-item v-for="(item, index) in DSDiaDiem" :key="item.DiaDiem_Id || index">
                <v-list-item-title>
                    <v-checkbox v-model="modelDSDiaDiemApDung" :value="item.DiaDiem_Id" :label="item.TenDiaDiem"
                        color="primary" hide-details="auto" />
                </v-list-item-title>
            </v-list-item>
        </v-list>
        <div class="d-flex">
            <v-spacer></v-spacer>
            <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="onSubmit">Lưu</v-btn>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        DSDiaDiem: Array,
        DSDiaDiemApDung: Array,
        selectedItem: Object,
    },
    emits: ['update:DSDiaDiemApDung', 'load-dia-diem-ap-dung'],
    data() {
        return {
            isLocationTableReady: false,
        }
    },

    mounted() {
    },
    computed: {
        modelDSDiaDiemApDung: {
            get() {
                return this.DSDiaDiemApDung
            },
            set(val) {
                this.$emit('update:DSDiaDiemApDung', val)
            }
        },
    },

    watch: {
    },

    methods: {
        onSubmit() {
            apiCall('/work/HH_HangHoa_DiaDiem_Update', {
                HangHoa_Id: this.selectedItem.HangHoa_Id,
                DSDiaDiem: this.modelDSDiaDiemApDung.length ? this.modelDSDiaDiemApDung.join(',') : '',
            }, async () => {
                showToast.success('Cập nhật địa điểm áp dụng thành công')
                this.$emit('load-dia-diem-ap-dung')
            })
        },
    }

}
</script>
