<template>
	<v-card>
		<v-card-title class="d-flex align-center ga-2">
			<template v-if="!isMobile">
				<div class="text-primary text-left table-title">
					Danh sách hàng hoá trong kho
				</div>
				<v-spacer></v-spacer>
			</template>
			<v-btn v-if="filter.DiaDiem_Id !== 0" rounded size="small" color="primary"
				prepend-icon="mdi-swap-horizontal" @click="onTransfer" text="Luân chuyển" variant="tonal"></v-btn>
			<v-btn rounded size="small" color="primary" prepend-icon="mdi-qrcode-scan" @click="onQuetQR" text="Quét QR"
				variant="tonal"></v-btn>
			<v-text-field v-model="search" density="compact" variant="underlined" label="Tìm kiếm"
				prepend-inner-icon="mdi-magnify" flat hide-details single-line class="search-field"></v-text-field>
		</v-card-title>
		<v-card-text class="pa-0">
			<v-progress-linear v-if="loading" indeterminate color="primary" />
			<uc-kho-desktop v-if="!isMobile" :items="filteredItems" :filter="filter"
				@on-edit-ca-biet="onClickUpdateCaBiet" @on-qr="onClickQR" @on-view-history="viewHistory" />
			<uc-kho-mobile v-else :items="filteredItems" :filter="filter" @on-edit-ca-biet="onClickUpdateCaBiet"
				@on-qr="onClickQR" @on-view-history="viewHistory" />
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
	props: {
		data: Array,
		filter: Object,
		loading: { type: Boolean, default: false },
	},
	emits: ['on-transfer', 'on-edit-ca-biet', 'on-qr', 'on-quet-qr', 'on-view-history'],
	data() {
		return {
			search: null,
		}
	},
	computed: {
		filteredItems() {
			if (!this.search?.trim()) return this.data
			const keyword = this.search.trim().toLowerCase()
			return this.data.filter(item =>
				item.TenHangHoa?.toLowerCase().includes(keyword) ||
				item.DSCaBiet?.some(cb =>
					cb.SoSeries?.toString().toLowerCase().includes(keyword)
				)
			)
		},
		isMobile() {
			return this.$vuetify.display.smAndDown
		},
	},
	methods: {
		onTransfer() {
			this.$emit('on-transfer')
		},
		onClickUpdateCaBiet(item) {
			this.$emit('on-edit-ca-biet', item)
		},
		onClickQR(CaBiet) {
			this.$emit('on-qr', CaBiet)
		},
		onQuetQR() {
			this.$emit('on-quet-qr')
		},
		viewHistory(Item, Is_CaBiet) {
			this.$emit('on-view-history', Item, Is_CaBiet)
		},
	},
}
</script>