<template>
	<div>
		<p>{{chuctrach.value}}</p>
		<v-autocomplete :items="dsgiangviendukien" outlined dense hide-details placeholder="Chọn giảng viên"
			:item-text="getName" item-value="GiangVienID" v-model="chuctrach" />
	</div>
</template>

<script>
	export default {
		props: ["dsgiangviendukien", "chuctrach"],
		data() {
			return {}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {
			getName(obj) {
				let text = obj.HoTenHocHamHocVi
				return text
			},
			getGiangVienInfo(gvid) {
				const $this = this
				const giangvienDuKien = this.dsgiangviendukien.find(item => item.GiangVienID === gvid)
				giangvienDuKien.ChucTrach = $this.chuctrach.text
				giangvienDuKien.ChucTrachID = $this.chuctrach.value
	
	
				const existIndex = $this.detai.HoiDongThanhVienObj_Arr.findIndex((item) => item.ChucTrachID === $this.chuctrach.value)
				console.log("existIndex", existIndex)
				if (existIndex === -1) {
					$this.detai.HoiDongThanhVienObj_Arr.push(giangvienDuKien);
				}
				else {
					$this.detai.HoiDongThanhVienObj_Arr[existIndex] = giangvienDuKien
				}
				console.log("$this.detai xxx", $this.detai)
			}
		},
	}
</script>