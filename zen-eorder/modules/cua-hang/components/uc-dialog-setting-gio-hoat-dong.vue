<template>
	<v-dialog v-model="vueData.IsDialogActiveTime" scrollable width="600">
		<v-card>
			<v-toolbar dense flat>
				<v-toolbar-title>Thiết lập giờ hoạt động - {{ vueData.CuaHangActiveTime.TenCuaHang }}</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="vueData.IsDialogActiveTime = false"><v-icon>mdi-close</v-icon></v-btn>
			</v-toolbar>
			<v-card-text>
				<v-row>
					<v-col cols="6">
						<v-text-field v-model="gioTu" label="Giờ hoạt động từ" outlined dense
							hide-details></v-text-field>
					</v-col>
					<v-col cols="6">
						<v-text-field v-model="gioDen" label="Giờ hoạt động đến" outlined dense
							hide-details></v-text-field>
					</v-col>
				</v-row>
			</v-card-text>
			<v-card-actions>
				<v-spacer />
				<v-btn text color="primary" @click="onSubmit">Lưu</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>
<script>
	export default {
	    methods: {
	        onSubmit() {
	            const params = {
	                CuaHangID: vueData.CuaHangActiveTime.CuaHangID,
	                GioHoatDong_Tu: this.gioTu,
	                GioHoatDong_Den: this.gioDen,
	            }
	
	            confirm({
	                title: `<b>Xác nhận</b>`,
	                message: `Cập nhật thông tin giờ hoạt động cho <b>${vueData.CuaHangActiveTime.TenCuaHang} </b>`,
	                action: function () {
	                    ajaxCALL("/eorder/CuaHang_Update_GioHoatDong", params, (res) => {
	                        showToast({ type: "green", title: "Cập nhật thời gian hoạt động của cửa hàng thành công!" })
	                        vueData.IsDialogActiveTime = false
	                        runAction(vueData.getCuaHang)
	                    })
	                },
	            })
	        },
	    },
	    watch: {
	        "vueData.IsDialogActiveTime": {
	            immediate: true,
	            handler(val) {
	                if (!val) {
	                    this.gioTu = ""
	                    this.gioTu = ""
	                    return
	                }
	                const [h1, m1] = vueData.CuaHangActiveTime.GioHoatDong_Tu.split(":")
	                const [h2, m2] = vueData.CuaHangActiveTime.GioHoatDong_Den.split(":")
	
	                this.gioTu = `${parseInt(h1)}:${m1}`
	                this.gioDen = `${parseInt(h2)}:${m2}`
	            },
	        },
	    },
	    computed: {},
	    data() {
	        return {
	            gioTu: "",
	            gioDen: "",
	            vueData,
	        }
	    },
	}
</script>