<template>
	<div>
		<v-textarea v-model="itemDes.Text_Content"
			:class="[itemDes.Task_Detail_StyleDisplay ? 'mt-2 ' + itemDes.Task_Detail_StyleDisplay : 'mt-2']"
			:style="itemDes.Task_Detail_StyleDisplay ? { 'line-height': '1.4' } : {}" outlined name="input-7-1" rows="3"
			:hide-details="itemDes.Task_Help ? false : true" :hint="itemDes.Task_Help" color="success" flat="false"
			auto-grow dense :rules="textRules" :disabled="!allowEdit && (itemDes.User_Input === 'SDH' || lock === 0)" />

		<div v-if="itemDes.FN_Check === 'fnCheckLimit'" class="mt-2">
			<v-progress-linear :value="Math.min((wordCount / 500) * 100, 100)"
				:color="isValidWordNumber ? 'success' : 'error'" height="6" rounded class="mb-2"></v-progress-linear>

			<div class="d-flex align-center justify-space-between" style="gap: 12px;">
				<span class="text-caption" :class="isValidWordNumber ? 'success--text' : 'error--text'">
					<v-icon x-small :color="isValidWordNumber ? 'success' : 'error'" class="mr-1">
						{{ isValidWordNumber ? 'mdi-check-circle-outline' : 'mdi-alert-circle-outline' }}
					</v-icon>
					{{ isValidWordNumber ? 'Độ dài tóm tắt hợp lệ (120 - 500 từ)' : 'Yêu cầu tóm tắt từ 120 - 500 từ' }}
				</span>
				<span class="text-caption font-weight-bold"
					:class="wordCount === 500 ? 'primary--text' : 'grey--text text--darken-1'">
					{{ wordCount }} / 500 từ
				</span>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		name: "c-textarea-comp",
    props: {
        itemDes: { type: Object, default: () => ({}) },
        textRules: { type: Array, default: () => [] },
        lock: { type: [Number, String], default: 1 },
        allowEdit: { type: Boolean, default: false }
    },
    data() {
        return {
            isValidWordNumber: false,
        }
    },
    computed: {
        wordCount() {
            return this.countWords(this.itemDes.Text_Content || '')
        },
    },
    watch: {
        itemDes: {
            handler(val) {
                if (val.FN_Check === 'fnCheckLimit') {
                    const wordCount = this.countWords(val.Text_Content || '')

                    // Cập nhật trạng thái hợp lệ
                    this.isValidWordNumber = wordCount >= 120 && wordCount <= 500

                    // Giới hạn không cho nhập quá 500 từ
                    if (wordCount > 500) {
                        this.itemDes.Text_Content = this.truncateToWordLimit(val.Text_Content, 500)
                    }
                }
            },
            deep: true,
            immediate: true, // nếu cần kiểm tra ngay khi component mount
        },
    },
    methods: {
        countWords(str) {
            return str.trim().split(/\s+/).filter(Boolean).length
        },
        truncateToWordLimit(str, limit) {
            return str.trim().split(/\s+/).slice(0, limit).join(' ')
        },
    },
	}
</script>