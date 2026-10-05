<template>
	<v-card :style="{'background-color': vueData.mode ? vueData.colorMode.dark.tertiary : 'white'}" style="">
		<v-card-title :style="styleCardTitle" class="d-flex">
			<div v-if="!isCustom" style="display:flex; flex-direction: column; align-items: flex-start;flex: 1 1 auto">
				<p class="mb-0 text-subtitle-2 " :class="vueData.mode ? 'white--text' : 'black--text'"
					style="word-break: normal" :style="styleTitle">{{title ?? ''}}
				</p>
				<p class="mt-0 mb-0" :class="vueData.mode ? 'white--text' : 'primary--text'" style="font-weight: 500"
					:style="styleDescription">
					{{description ?? ''}}</p>
			</div>
			<div class="justify-space-between" v-if="isCustom" style="display:flex; flex-direction: row; align-items: center;flex: 1 1 auto; gap:8px">
				<p class="mb-0 text-subtitle-2 " :class="vueData.mode ? 'white--text' : 'black--text'"
					style="word-break: normal" :style="styleTitle">{{title ?? ''}}
				</p>
				<p class="mt-0 mb-0" :class="vueData.mode ? 'white--text' : 'primary--text'" style="font-weight: 500"
					:style="styleDescription">
					{{description ?? ''}}</p>
			</div>
			<v-btn v-if="!isCustom" fab small :color="vueData.mode ? 'white' : 'primary'" style="cursor: default;flex: 0 0 auto">
				<v-icon medium :color="vueData.mode ? 'black' : 'white'">{{trailingIcon ?? 'mdi-help'}}</v-icon>
			</v-btn>
		</v-card-title>
	</v-card>
</template>

<script>
	export default {
		props: ["title", "description", "trailingIcon", "styleDescription", "styleTitle", "styleCardTitle", 'isCustom'],
		data() {
			return {
				vueData
			}
		},
		mounted() {
		},
		computed: {},
		watch: {},
		methods: {},
	}
</script>