<template>
	<v-card :style="{'background-color': vueData.mode ? vueData.colorMode.dark.tertiary : 'white'}">
		<v-card-title :class="vueData.mode ? 'white--text' : 'primary--text'">
			<span> {{title ?? ""}} <v-chip v-if="detailTitle" class="ml-1" :color=" vueData.mode ? 'white' : 'primary'"
					:style="{color: vueData.mode ? 'black' : 'white'}"> {{detailTitle?? 0}}</v-chip></span>
			<v-spacer></v-spacer>
			<slot name="rightTitle"></slot>
		</v-card-title>
		<v-card-text :class="vueData.mode ? 'white--text' : 'black--text'">
			<div style="display:flex; justify-content:center; align-items:center; flex-direction:column">
				<v-btn fab small :color=" vueData.mode ? 'white' : 'primary'">
					<v-icon :color="vueData.mode ? 'black' : 'white'">{{iconTopList ?? 'mdi-help' }}</v-icon>
				</v-btn>
				<p class="mb-0 text-h6">{{titleTopList ?? ""}}</p>
				<p clas="mb-0 text-title">{{desciptionTopList ?? ""}}</p>
			</div>
			<slot name="renderBody"> </slot>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		props: ["iconTopList", "titleTopList", "desciptionTopList", "title", "detailTitle"],
		data() {
			return {}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>