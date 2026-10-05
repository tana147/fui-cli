<template>
	<div class="d-flex justify-center flex-wrap pt-1">
		<div @click="onComplete(item)" v-for="item in DSHoaDon" :key="item.HoaDonID" class="item-bill cursor-pointer">{{item.SoCho}}</div>
	</div>
</template>

<script>
	export default {
		props: ["ds_hd", "cuahangid"],
		data() {
			return {
				Search: null,
				DSHoaDon: [],
			}
		},
		watch: {
			ds_hd: function (ds) {
				this.DSHoaDon = ds
			},
		},
		methods: {
			onComplete(hoaDon) {
				confirm({
					title: `Hoàn thành mã số chờ <b>${hoaDon.SoCho}</b>?`,
					action: function () {
						const params = {
							HoaDonID: hoaDon.HoaDonID,
						}
						ajaxCALL("/eorder/HoaDon_Update_NhanMon", params, (res) => {
							if (res.data) {
								runAction(vueData.getHoaDonHoanThanh)
								//Bắn socket sang trang chờ
								webSocket_Send({
									group: vueData.webSocket_Hub_Waiting,
									data: new Date(),
								})
							}
						})
					},
				})
			},
		},
	}
</script>