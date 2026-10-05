<template>
    <div class="pa-4">
        <div class="d-flex align-center mb-3">
            <div class="font-weight-bold">Địa điểm áp dụng ({{ selectedLocationIds.length }})</div>
            <v-spacer></v-spacer>
            <v-checkbox :model-value="isSelectAllLocations" label="Chọn tất cả" color="primary" hide-details="auto"
                @update:model-value="toggleSelectAllLocations" />
        </div>
        <v-list v-if="isLocationTableReady && allLocationRows.length" density="compact"
            class="d-flex flex-row flex-wrap supplier-location-list">
            <v-list-item v-for="(item, index) in allLocationRows" :key="item.DiaDiem_Id || index">
                <v-list-item-title>
                    <v-checkbox v-model="selectedLocationIds" :value="item.DiaDiem_Id" :label="item.TenDiaDiem"
                        color="primary" hide-details="auto" />
                </v-list-item-title>
            </v-list-item>
        </v-list>
        <uc-empty v-else-if="isLocationTableReady" text="Chưa có địa điểm áp dụng"></uc-empty>
    </div>
</template>

<script>
    export default {
		props: {
			recordData: { type: Object, default: null },
			active: { type: Boolean, default: false },
		},
		emits: ['reloaded'],
		data() {
			return {
				isLocationTableReady: false,
				allLocationRows: [],
				selectedLocationIds: [],
			}
		},
		watch: {
			active: {
				immediate: true,
				handler(val) {
					if (val && this.recordData?.HangHoa_Id) this.loadLocationRows()
				},
			},
			'recordData.HangHoa_Id'(val) {
				if (this.active && val) this.loadLocationRows()
			},
		},
		computed: {
			isSelectAllLocations() {
				return this.allLocationRows.length > 0 && this.selectedLocationIds.length === this.allLocationRows.length
			},
		},
		methods: {
			async loadLocationRows() {
				if (!this.recordData?.HangHoa_Id) return
				this.isLocationTableReady = false
				const [allLocations, selectedLocations] = await Promise.all([
					apiCallPromise('work/HH_DiaDiem_Select'),
					apiCallPromise('/work/HH_HangHoa_DiaDiem_Select', { HangHoa_Id: this.recordData.HangHoa_Id }),
				])
				this.allLocationRows = Array.isArray(allLocations?.data) ? allLocations.data : Array.isArray(allLocations) ? allLocations : []
				const selectedResponse = Array.isArray(selectedLocations?.data) ? selectedLocations.data : Array.isArray(selectedLocations) ? selectedLocations : []
				this.selectedLocationIds = selectedResponse.map((item) => item.DiaDiem_Id)
				this.isLocationTableReady = true
			},
			toggleSelectAllLocations(val) {
				if (val) {
					this.selectedLocationIds = this.allLocationRows.map((x) => x.DiaDiem_Id)
				} else {
					this.selectedLocationIds = []
				}
			},
			save() {
				if (!this.recordData?.HangHoa_Id) return
				apiCall('/work/HH_HangHoa_DiaDiem_Update', {
					HangHoa_Id: this.recordData.HangHoa_Id,
					DSDiaDiem: this.selectedLocationIds.length ? this.selectedLocationIds.join(',') : '',
				}, async () => {
					showToast.success('Cập nhật địa điểm áp dụng thành công')
					await this.loadLocationRows()
					this.$emit('reloaded')
				})
			},
		},
	}
</script>