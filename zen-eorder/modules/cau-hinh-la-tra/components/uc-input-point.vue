<template>
	<div class="page-section">
		<v-card elevation="0">
			<v-card-title>Thiết lập tỷ lệ quy đổi lá trà</v-card-title>
			<v-card-text>
				<v-text-field v-model="vueData.DSCauHinh[0].TyLeQuyDoiLaTra" outlined hide-details dense label="Tỷ lệ quy đổi"/>
			</v-card-text>
			<v-card-actions>
				<v-btn @click="onUpdateConfig" elevation="0" color="primary">
					<v-icon left>mdi-content-save</v-icon>Lưu điểm
				</v-btn>
			</v-card-actions>
		</v-card>
	</div>
</template>

<script>
	export default {
	    data() {
	        return {
	        }
	    },
	    watch: {},
	    methods: {
	        onUpdateConfig: function () {
	            const $this = this
	            const params = {
	                TyLeQuyDoiLaTra: vueData.DSCauHinh[0].TyLeQuyDoiLaTra ?? 0
	            }
	            ajaxCALL("/eorder/CauHinh_Update_TyLeLaTra", params, (res) => {
	                Vue.$toast.success("Lưu tỷ lệ thành công", { position: "top" })
	            })
	        },
	    },
	}
</script>