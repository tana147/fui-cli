<template>
	<v-row v-if="stats" dense>
		<v-col cols="6" sm="4" md="2" v-for="card in cardList" :key="card.title">
			<c-stats :title="card.title" :value="card.value" :suffix="card.suffix" :icon="card.icon" :color="card.color"
				:bg-color="card.bgColor" />
		</v-col>
	</v-row>
</template>

<script>
	export default {
		name: 'uc-stats',
		props: {
			stats: { type: Object, default: () => ({}) }
		},
		computed: {
			cardList() {
				if (!this.stats) return [];
				return [
					{
						title: "Chờ duyệt",
						value: this.stats.HoatDongChoDuyet ?? 0,
						icon: "mdi-file-clock-outline",
						color: "warning",
						bgColor: "orange-lighten-5",
						suffix: ""
					},
					{
						title: "Tổng số GV",
						value: this.stats.TongSoGiangVien ?? 0,
						icon: "mdi-account-group-outline",
						color: "primary",
						bgColor: "blue-lighten-5",
						suffix: ""
					},
					{
						title: "GV đạt",
						value: this.stats.SoGiangVienDat ?? 0,
						icon: "mdi-account-check-outline",
						color: "success",
						bgColor: "green-lighten-5",
						suffix: ""
					},
					{
						title: "GV chưa đạt",
						value: this.stats.SoGiangVienChuaDat ?? 0,
						icon: "mdi-account-alert-outline",
						color: "error",
						bgColor: "red-lighten-5",
						suffix: ""
					},
					{
						title: "Hoàn thành",
						value: this.stats.TyLeHoanThanh == null ? 0 : this.stats.TyLeHoanThanh.toFixed(1),
						icon: "mdi-check-all",
						color: "success",
						bgColor: "green-lighten-5",
						suffix: "%"
					},
					{
						title: "Số giờ TB/GV",
						value: this.stats.SoGioTB == null ? 0 : this.stats.SoGioTB.toFixed(1),
						icon: "mdi-clock-outline",
						color: "purple",
						bgColor: "purple-lighten-5",
						suffix: "giờ"
					}
				];
			}
		}
	}
</script>