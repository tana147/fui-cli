<template>
	<v-card>
		<v-card-title>
			<div style="display:flex; flex-direction: column; align-items: flex-start;">
				<p class="mb-0 text-subtitle-2">{{title ?? ''}}
				</p>
				<p class="mb-0 primary--text" style="font-weight: 500; font-size: 1.7rem">
					{{description ?? ''}}</p>
			</div>
			<v-spacer></v-spacer>
			<v-btn fab small color="primary">
				<v-icon medium >{{trailingIcon ?? 'mdi-help'}}</v-icon>
			</v-btn>
		</v-card-title>
	</v-card>
</template>

<script>
	export default {
		props: ["title", "description", "trailingIcon"],
		data() {
			return {}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>