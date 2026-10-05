<template>
	<div>
		<v-tabs v-model="TabModel" color="white" background-color="green">
			<v-tab key="Tab_MenuOnline"> Menu Online </v-tab>
			<v-tab key="Tab_MenuPos"> Menu POS </v-tab>
		</v-tabs>
		<v-tabs-items v-model="TabModel">
			<v-tab-item key="Tab_MenuOnline">
				<uc-category-list :category_list="category_list" :loading="loading" :phanhieu="phanhieu" />
			</v-tab-item>
			<v-tab-item key="Tab_MenuPos">
				<uc-menu-pos />
			</v-tab-item>
		</v-tabs-items>
	</div>
</template>

<script>
	export default {
		props: ["category_list", "loading", "phanhieu"],
		data() {
			return {
				TabModel: [],
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>