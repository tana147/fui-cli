<template>
	<v-select outlined v-if="vueData?.CTHoaDon?.GrabOrderID" v-model="vueData.cancelCodeGRAB" label="Ghi chú hủy"
		:items="vueData.OptionsCancelOrder" tile dense :menu-props="{ offsetY: true }"></v-select>
	<v-text-field v-else v-model="vueData.CTHoaDon.GhiChu_Huy" outlined tile dense label="Ghi chú hủy"></v-text-field>
</template>
<script>
	export default {
	      data() {
	            return {
	                  vueData
	            }
	      },
	}
</script>