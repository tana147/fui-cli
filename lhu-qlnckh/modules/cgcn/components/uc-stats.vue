<template>
	<v-row dense>
		<v-col v-for="(card, index) in cardList" :key="index" cols="12" sm="6" md="3">
			<v-card outlined class="rounded-xs pa-3 d-flex align-center">
				<v-avatar size="36" :class="card.bgClass" class="mr-3">
					<v-icon size="20" :color="card.iconColor">{{ card.icon }}</v-icon>
				</v-avatar>
				<div>
					<div class="text-caption grey--text text--darken-1">{{ card.title }}</div>
					<div class="text-h5 font-weight-bold">{{ card.value }}</div>
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
				withFilesCount: 0,
				latestYear: "-"
			})
		}
	},
	computed: {
		cardList() {
			const stats = this.statsData || {}
			return [
				{
					title: "Tổng số dự án / HĐ",
					value: stats.totalProjects || 0,
					icon: "mdi-file-document-multiple-outline",
					iconColor: "primary",
					bgClass: "blue-lighten-5"
				},
				{
					title: "Tổng giá trị HĐ (VNĐ)",
					value: this.formatMoney(stats.totalValue || 0),
					icon: "mdi-cash-multiple",
					iconColor: "success",
					bgClass: "green-lighten-5"
				},
				{
					title: "HĐ có minh chứng",
					value: stats.withFilesCount || 0,
					icon: "mdi-file-check-outline",
					iconColor: "warning",
					bgClass: "amber-lighten-5"
				},
				{
					title: "Năm TH gần nhất",
					value: stats.latestYear || "-",
					icon: "mdi-calendar-check-outline",
					iconColor: "deep-purple",
					bgClass: "purple-lighten-5"
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