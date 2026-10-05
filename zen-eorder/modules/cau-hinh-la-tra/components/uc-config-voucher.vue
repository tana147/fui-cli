<template>
	<div class="page-section">
		<v-card elevation="0">
			<v-card-title>Giới thiệu voucher lá trà</v-card-title>
			<v-card-text>
				<f-editor v-model="vueData.DSCauHinh[0].GioiThieuLaTra" :height="400" :toolbar="toolbar" />
			</v-card-text>
			<v-card-actions>
				<v-btn @click="onUpdateConfig" elevation="0" color="primary"><v-icon left>mdi-content-save</v-icon>Lưu
					nội dung giới thiệu</v-btn>
			</v-card-actions>
		</v-card>
	</div>
</template>

<script>
	export default {
	    data() {
	        return {
	            toolbar: ["bold", "italic", "underline", "|", "undo", "redo", "removeFormat", "alignment", "fontSize", "fontFamily", "fontColor", "|", "bulletedList", "numberedList"],
	        }
	    },
	    watch: {},
	    methods: {
	        onUpdateConfig: function () {
	            const $this = this
	            const params = {
	                GioiThieuLaTra: vueData.DSCauHinh[0].GioiThieuLaTra,
	            }
	            ajaxCALL("/eorder/CauHinh_Update_GioiThieuLaTra", params, (res) => {
	                Vue.$toast.success("Lưu nội dung thành công", { position: "top" })
	            })
	        },
	    },
	}
</script>