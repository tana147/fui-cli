<template>
	<v-dialog v-model="dialog" transition="dialog-bottom-transition" max-width="900" persistent>
		<v-card>
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<p class="title mb-0 primary--text">Định nghĩa lớp mới</p>
				</template>
			</c-toolbar>

			<v-card-text>
				<v-row>
					<v-col>
						<v-text-field v-model="selectField.lopID" outlined dense hide-details label="LopID"
							placeholder="Nhập ID lớp" />
					</v-col>
					<v-col>
						<v-select v-model="selectField.loaiThS" label="Loại thạc sĩ" outlined dense hide-details
							:items="LoaiThS" />
					</v-col>
					<v-col>
						<v-select disabled v-model="selectField.loaiThaoTac" label="Loại thao tác" outlined dense
							hide-details :items="LoaiThaoTac" />
					</v-col>
				</v-row>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn :loading="saving" @click="defindClass" color="success">Thêm định nghĩa</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-add",
    props: {
        value: {
            type: Boolean,
            default: false,
        },
    },
    emits: ["input", "on-reload"],
    data() {
        return {
            selectField: {
                lopID: null,
                loaiThS: 1,
                loaiThaoTac: 1,
            },
            saving: false,
            LoaiThS: [
                {
                    text: "Thạc sĩ nghiên cứu",
                    value: 1,
                },
                {
                    text: "Thạc sĩ ứng dụng",
                    value: 4,
                },
                {
                    text: "Đổi đề tài luận văn",
                    value: 2,
                },
                {
                    text: "Gia hạn đề tài luận văn",
                    value: 3,
                },
                {
                    text: "Đổi đề tài đồ án",
                    value: 5,
                },
                {
                    text: "Tiến sĩ",
                    value: 6,
                },
            ],
            LoaiThaoTac: [
                {
                    text: "Làm Luận văn/Đồ án",
                    value: 1,
                },
                {
                    text: "Đổi đề tài Luận văn/Đồ án",
                    value: 2,
                },
                {
                    text: "Gia hạn đề tài luận văn",
                    value: 3,
                },
                {
                    text: "Làm Luận án",
                    value: 4,
                },
            ],
        };
    },
    computed: {
        dialog: {
            get() {
                return this.value;
            },
            set(val) {
                this.$emit("input", val);
            },
        },
    },
    watch: {
        "selectField.loaiThS": function (val) {
            switch (val) {
                case 1:
                case 4:
                    this.selectField.loaiThaoTac = 1;
                    break;
                case 6:
                    this.selectField.loaiThaoTac = 4;
                    break;
                case 2:
                case 5:
                    this.selectField.loaiThaoTac = 2;
                    break;
                case 3:
                    this.selectField.loaiThaoTac = 3;
                    break;
            }
        },
    },
    methods: {
        async defindClass() {
            if (!this.selectField.lopID) {
                Vue.$toast.error("Vui lòng nhập ID lớp", { position: "top" });
                return;
            }

            this.saving = true;
            try {
                let res;
                // Thạc sĩ nghiên cứu
                if (this.selectField.loaiThS === 1) {
                    // Làm luận văn
                    res = await this.insertNewProcess(this.selectField.loaiThS, this.selectField.loaiThaoTac);
                    if (res === null) return;
                    // Đổi/Điều chỉnh đề tài
                    res = await this.insertNewProcess(2, 2);
                    if (res === null) return;
                    // Gia hạn đề tài
                    res = await this.insertNewProcess(3, 3);
                    if (res === null) return;
                // Thạc sĩ ứng dụng
                } else if (this.selectField.loaiThS === 4) {
                    // Làm đồ án
                    res = await this.insertNewProcess(this.selectField.loaiThS, this.selectField.loaiThaoTac);
                    if (res === null) return;
                    // Đổi/Điều chỉnh đề tài
                    res = await this.insertNewProcess(5, 2);
                    if (res === null) return;
                } else {
                    res = await this.insertNewProcess(this.selectField.loaiThS, this.selectField.loaiThaoTac);
                    if (res === null) return;
                }

                Vue.$toast.success("Thêm định dạng lớp thành công", { position: "top" });
                this.$emit("on-reload");
                this.closeDialog();
            } finally {
                this.saving = false;
            }
        },

        async insertNewProcess(processId, processAction) {
            return await ajaxCALLPromise("/Process_Class_Ins", {
                Lop_ID: this.selectField.lopID.trim(),
                Prcoess_ID: processId,
                Process_Action: processAction,
            });
        },

        closeDialog() {
            this.dialog = false;
            this.selectField = {
                lopID: null,
                loaiThS: 1,
                loaiThaoTac: 1,
            };
        },
    },
	}
</script>