<template>
	<v-row>
		<v-col cols="4">
			<v-select label="Cửa hàng" outlined dense v-model="vueData.CuaHangID" :items="vueData.DSCuaHang" hide-details
				item-value="CuaHangID" item-text="TenCuaHang" />
		</v-col>
		<v-col cols="2">
			<f-date label="Từ ngày" outlined dense v-model="vueData.TuNgay" :date-add="0" hide-details />
		</v-col>
		<v-col cols="2">
			<f-date label="Đến ngày" outlined dense v-model="vueData.DenNgay" :date-add="0" hide-details />
		</v-col>
		<v-col cols="2">
			<v-btn color="primary" elevation="0" @click="GetBaoCao()"> <v-icon left>mdi-filter</v-icon>Tìm </v-btn>
		</v-col>
	</v-row>
</template>

<script>
	export default {
	    props: [],
	    data() { },
	    mounted() { },
	    computed: {},
	    watch: {},
	    methods: {
	        GetBaoCao() {
	            runAction(vueData.getBaoCao)
	        },
	    },
	}
</script>