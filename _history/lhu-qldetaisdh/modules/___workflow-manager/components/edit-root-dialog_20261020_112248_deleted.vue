<template>
	<div>
		<!-- edit root -->

		<v-dialog v-model="vueData.isEditRootDialog" transition="dialog-bottom-transition" max-width="900px" persistent>
			<v-card>
				<c-toolbar @onClose="vueData.isEditRootDialog = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Cập nhật task</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<v-row>
						<v-col cols="12">
							<v-text-field v-model="item.Task_Name" label="Tên task" placeholder="Nhập tên task" outlined
								dense hide-details color="primary" />
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="item.Task_Code" label="Task code" placeholder="Nhập task code"
								outlined dense hide-details color="primary" />
						</v-col>
					</v-row>

					<div class="mt-3 d-flex align-center roleHeight">
						<p>HV có bắt buộc phải làm bước này không:</p>
						<!-- {{taskRequire}} -->
						<v-radio-group class="mb-3 ml-3 wrapRadioGroup" v-model="taskRequire" row>
							<v-radio label="Có" value="1" color="primary" />
							<v-radio label="Không" value="0" color="primary" />
						</v-radio-group>
					</div>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn color="success">Cập nhật</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ["item", "tasklist"],
		data() {
			return {
				taskRequire: null
			}
		},
		mounted() { },
		computed: {
			taskRequire: function () {
				return this.tasklist
			}
		},
		watch: {
			// tasklist: function (val) {
			// 	console.log("val", val, this.item)
			// 	const filterTask = val.filter(task => task.Task_ID === this.item.Task_ID)
			// 	this.taskRequire = filterTask[0]?.Task_Require.toString()
			// 	console.log("this.taskRequire", this.taskRequire, filterTask)
			// }
			item: function (val) {
				console.log("val", val)
				const filterTask = this.tasklist.find(task => task.Task_ID === this.item.Task_ID)
				this.taskRequire = filterTask.Task_Require.toString()
				console.log("this.taskRequire", this.taskRequire)
			}
		},
		methods: {},
	}
</script>