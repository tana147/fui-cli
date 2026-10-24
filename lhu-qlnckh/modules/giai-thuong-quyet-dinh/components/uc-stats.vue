<template>
	<v-row dense class="mb-1">
		<v-col cols="12" sm="6" md="3" v-for="(item, idx) in cardList" :key="idx">
			<v-card outlined class="rounded-sm py-2 px-3 d-flex align-center">
				<v-avatar :color="item.avatarColor" size="36" class="mr-3">
					<v-icon :color="item.iconColor" size="20">{{ item.icon }}</v-icon>
				</v-avatar>
				<div class="d-flex flex-column">
					<span class="text-caption grey--text text--darken-1">{{ item.label }}</span>
					<span class="text-h5 font-weight-bold">{{ item.value }}</span>
				</div>
			</v-card>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		name: "uc-stats",
	props: {
		stats: {
			type: Object,
			default: () => ({
				totalDecisions: 0,
				decisionsWithFiles: 0,
				totalRewardsLinked: 0,
				latestYear: "--"
			})
		}
	},
	computed: {
		cardList() {
			return [
				{
					label: "Tổng số quyết định",
					value: this.stats.totalDecisions || 0,
					icon: "mdi-file-document-outline",
					iconColor: "primary darken-1",
					avatarColor: "blue-lighten-5"
				},
				{
					label: "Có file đính kèm",
					value: this.stats.decisionsWithFiles || 0,
					icon: "mdi-file-check-outline",
					iconColor: "teal darken-2",
					avatarColor: "green-lighten-5"
				},
				{
					label: "Số đề tài khen thưởng",
					value: this.stats.totalRewardsLinked || 0,
					icon: "mdi-trophy-outline",
					iconColor: "amber darken-3",
					avatarColor: "amber-lighten-5"
				},
				{
					label: "Năm QĐ mới nhất",
					value: this.stats.latestYear || "--",
					icon: "mdi-calendar-clock-outline",
					iconColor: "indigo darken-2",
					avatarColor: "indigo-lighten-5"
				}
			]
		}
	}
	}
</script>