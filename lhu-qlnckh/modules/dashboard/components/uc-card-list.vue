<template>
	<v-card outlined class="rounded-xs">
		<v-card-title class="py-2 px-4 primary--text d-flex align-center">
			<span class="text-subtitle-1 font-weight-bold">
				{{ title ?? "" }}
				<v-chip v-if="detailTitle" small class="ml-1 white--text" color="primary">
					{{ detailTitle ?? 0 }}
				</v-chip>
			</span>
			<v-spacer></v-spacer>
			<slot name="rightTitle"></slot>
		</v-card-title>
		<v-divider></v-divider>
		<v-card-text class="pa-3 black--text">
			<div class="d-flex flex-column justify-center align-center mb-3">
				<v-avatar size="40" class="dashboard-stat-avatar--primary mb-1">
					<v-icon color="primary">{{ iconTopList ?? 'mdi-chart-box-outline' }}</v-icon>
				</v-avatar>
				<p class="mb-0 text-h6 font-weight-bold primary--text">{{ titleTopList ?? "" }}</p>
				<p class="mb-0 text-caption grey--text text--darken-1">{{ desciptionTopList ?? "" }}</p>
			</div>
			<slot name="renderBody"></slot>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		props: ["iconTopList", "titleTopList", "desciptionTopList", "title", "detailTitle"]
	}
</script>