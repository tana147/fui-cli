<template>
	<v-row dense class="cgcn-stats-row">
		<v-col v-for="(card, index) in cardList" :key="index" cols="12" sm="6" md="3">
			<v-card outlined class="rounded-xs elevation-1 pa-3 d-flex align-center">
				<v-avatar size="38" :class="card.bgClass" class="mr-3">
					<v-icon size="22" :color="card.iconColor">{{ card.icon }}</v-icon>
				</v-avatar>
				<div>
					<div class="text-caption grey--text text--darken-1">{{ card.title }}</div>
					<div class="text-h6 font-weight-bold" :class="card.textClass">{{ card.value }}</div>
				</div>
			</v-card>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		name: "uc-stats",
		props: {
			statsData: {
				type: Object,
				default: () => ({
					totalProjects: 0,
					totalValue: 0,
					countPending: 0,
					countApproved: 0,
					countRejected: 0
				})
			}
		},
		computed: {
			cardList() {
				const stats = this.statsData || {}
				return [
					{
						title: "Hồ sơ chờ xét duyệt",
						value: stats.countPending || 0,
						icon: "mdi-clock-alert-outline",
						iconColor: "orange darken-3",
						textClass: "orange--text text--darken-3",
						bgClass: "orange lighten-5"
					},
					{
						title: "Hồ sơ đã phê duyệt",
						value: stats.countApproved || 0,
						icon: "mdi-check-circle-outline",
						iconColor: "green darken-2",
						textClass: "green--text text--darken-2",
						bgClass: "green lighten-5"
					},
					{
						title: "Yêu cầu bổ sung",
						value: stats.countRejected || 0,
						icon: "mdi-alert-circle-outline",
						iconColor: "red darken-2",
						textClass: "red--text text--darken-2",
						bgClass: "red lighten-5"
					},
					{
						title: "Tổng giá trị HĐ đã duyệt",
						value: this.formatMoney(stats.totalValue || 0),
						icon: "mdi-cash-multiple",
						iconColor: "primary",
						textClass: "primary--text",
						bgClass: "blue lighten-5"
					}
				]
			}
		},
		methods: {
			formatMoney(val) {
				if (typeof formatAsCurrency === "function") {
					return formatAsCurrency(Number(val) || 0, 0)
				}
				return Number(val || 0).toLocaleString("vi-VN")
			}
		}
	}
</script>