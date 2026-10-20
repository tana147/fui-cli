<template>
	<div>
		<add-new-worktree-dialog />

		<!-- <v-autocomplete
			:items="['Skiing', 'Ice hockey', 'Soccer', 'Basketball', 'Hockey', 'Reading', 'Writing', 'Coding', 'Basejump']"
			label="Interests" multiple /> -->
		<div class="d-flex justify-end">
			<v-btn @click="vueData.isAddWorkTreeDialog = true" color="primary">Tạo mới work tree</v-btn>
		</div>
		<workflow-detail />
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {},
	}
</script>