<template>
	<v-row class="pa-4 pb-2">
		<v-col v-for="item in items" :key="item.title" cols="12" sm="6" lg="3">
			<uc-stat-card :title="item.title" :value="item.value" :icon="item.icon" :coloricon="item.coloricon"
				:colortitle="item.colortitle" :bgicon="item.bgicon" :bgclass="item.bgclass" />
		</v-col>
	</v-row>
</template>

<script>
	export default {
	props: {
		items: {
			type: Array,
			default: function () {
				return []
			},
		},
	},
}
</script>