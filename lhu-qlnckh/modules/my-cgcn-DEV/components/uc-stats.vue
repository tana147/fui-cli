<template>
	<v-row dense class="cgcn-stats-row">
		<v-col cols="12" sm="6" md="2">
			<v-card outlined class="rounded-xs elevation-1 pa-2 text-center">
				<div class="text-caption grey--text text--darken-1">Tổng hồ sơ</div>
				<div class="text-h6 font-weight-bold primary--text">
					{{ statsData.totalAll || 0 }}
				</div>
			</v-card>
		</v-col>

		<v-col cols="12" sm="6" md="2">
			<v-card outlined class="rounded-xs elevation-1 pa-2 text-center">
				<div class="text-caption grey--text text--darken-1">Dự thảo</div>
				<div class="text-h6 font-weight-bold grey--text text--darken-2">
					{{ statsData.countDraft || 0 }}
				</div>
			</v-card>
		</v-col>

		<v-col cols="12" sm="6" md="2">
			<v-card outlined class="rounded-xs elevation-1 pa-2 text-center">
				<div class="text-caption grey--text text--darken-1">Chờ xét duyệt</div>
				<div class="text-h6 font-weight-bold orange--text text--darken-2">
					{{ statsData.countPending || 0 }}
				</div>
			</v-card>
		</v-col>

		<v-col cols="12" sm="6" md="3">
			<v-card outlined class="rounded-xs elevation-1 pa-2 text-center">
				<div class="text-caption grey--text text--darken-1">Cần bổ sung / Sửa</div>
				<div class="text-h6 font-weight-bold red--text text--darken-2">
					{{ statsData.countRejected || 0 }}
				</div>
			</v-card>
		</v-col>

		<v-col cols="12" sm="6" md="3">
			<v-card outlined class="rounded-xs elevation-1 pa-2 text-center">
				<div class="text-caption grey--text text--darken-1">Đã phê duyệt</div>
				<div class="text-h6 font-weight-bold green--text text--darken-2">
					{{ statsData.countApproved || 0 }}
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
					totalAll: 0,
					countDraft: 0,
					countPending: 0,
					countRejected: 0,
					countApproved: 0
				})
			}
		}
	}
</script>