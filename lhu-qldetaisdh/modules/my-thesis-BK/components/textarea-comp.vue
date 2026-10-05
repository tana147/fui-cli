<template>
    <div>
        <v-alert v-if="ItemDes.FN_Check === 'fnCheckLimit' && !isValidWordNumber" color="error" type="error" border="right" elevation="2" colored-border dense>
            Tóm tắt phải từ 120 đến 500 từ
        </v-alert>

        <v-alert v-if="ItemDes.FN_Check === 'fnCheckLimit' && wordCount === 500" color="primary" border="right" elevation="2" colored-border icon="mdi-information-outline" dense>
            Tóm tắt đã đạt đến 500 từ
        </v-alert>

        <v-textarea
            v-model="ItemDes.Text_Content"
            :class="[ItemDes.Task_Detail_StyleDisplay ? 'mt-2 ' + ItemDes.Task_Detail_StyleDisplay : 'mt-2']"
            :style="ItemDes.Task_Detail_StyleDisplay ? { 'line-height': '10px' } : {}"
            outlined
            name="input-7-1"
            rows="1"
            :hide-details="ItemDes.Task_Help ? false : true"
            :hint="ItemDes.Task_Help"
            color="green"
            flat="false"
            auto-grow
            dense
            :rules="textRules"
            :disabled="ItemDes.User_Input === 'SDH' || lock === 0"
			/>

        <div v-if="ItemDes.FN_Check === 'fnCheckLimit'" class="limitText">{{ wordCount }} / 500 từ</div>
    </div>
</template>

<script>
export default {
    props: ['itemdes', 'textRules', 'lock'],
    data() {
        return {
            isValidWordNumber: false,
        }
    },
    computed: {
        ItemDes: function () {
            return this.itemdes
        },
        wordCount() {
            return this.countWords(this.ItemDes.Text_Content || '')
        },
    },
    watch: {
        itemdes: {
            handler(val) {
                if (val.FN_Check === 'fnCheckLimit') {
                    const wordCount = this.countWords(val.Text_Content || '')
                    console.log('Số từ:', wordCount)

                    // Cập nhật trạng thái hợp lệ
                    this.isValidWordNumber = wordCount >= 120 && wordCount <= 500

                    // Giới hạn không cho nhập quá 500 từ
                    if (wordCount > 500) {
                        this.itemdes.Text_Content = this.truncateToWordLimit(val.Text_Content, 500)
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
