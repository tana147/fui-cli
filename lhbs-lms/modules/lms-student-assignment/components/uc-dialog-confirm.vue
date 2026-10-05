<template>
	<v-dialog v-model="modelValue" max-width="460" @update:model-value="$emit('update:modelValue', $event)">
        <v-card class="confirm-dialog-card">

            <!-- Header -->
            <div class="confirm-dialog__header">
                <v-icon size="26" color="white">mdi-send-check-outline</v-icon>
                <span class="confirm-dialog__title">Xác nhận nộp bài</span>
            </div>

            <!-- Body -->
            <v-card-text class="confirm-dialog__body">

                <!-- Cảnh báo chính -->
                <div class="confirm-dialog__warning">
                    <v-icon size="20" color="warning" class="flex-shrink-0 mt-0_5">mdi-alert-outline</v-icon>
                    <span>
                        Bạn có chắc chắn muốn nộp bài không? Sau khi nộp, bạn sẽ
                        <strong>không thể chỉnh sửa</strong> bài làm của mình.
                    </span>
                </div>

                <!-- Danh sách câu chưa làm -->
                <div v-if="unansweredQuestions" class="confirm-dialog__unanswered mt-3">
                    <v-icon size="15" color="error" class="flex-shrink-0">mdi-alert-circle-outline</v-icon>
                    <span>
                        Còn những câu
                        <span class="text-error font-weight-bold">{{ unansweredQuestions }}</span>
                        chưa làm
                    </span>
                </div>

                <!-- Tổng kết nhanh -->
                <div class="confirm-dialog__summary mt-3">
                    <div class="summary-item">
                        <v-icon size="16" color="primary">mdi-pencil-circle-outline</v-icon>
                        <span>Đã làm: <strong>{{ answeredCount }}</strong> / {{ totalQuestions }} câu</span>
                    </div>
                    <div class="summary-item">
                        <v-icon size="16" color="grey">mdi-help-circle-outline</v-icon>
                        <span>Chưa làm: <strong class="text-error">{{ totalQuestions - answeredCount }}</strong>
                            câu</span>
                    </div>
                </div>
            </v-card-text>

            <!-- Actions -->
            <v-card-actions class="confirm-dialog__actions">
                <v-spacer />
                <v-btn variant="text" color="grey-darken-1" @click="$emit('update:modelValue', false)">
                    <v-icon start size="16">mdi-close</v-icon>
                    Hủy
                </v-btn>
                <v-btn color="success" variant="flat" class="confirm-dialog__submit-btn" @click="$emit('confirm')">
                    <v-icon start size="16">mdi-check-all</v-icon>
                    Xác nhận Nộp
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
	export default {
		name: 'ConfirmSubmitDialog',

    props: {
        modelValue: { type: Boolean, default: false },
        unansweredQuestions: { type: String, default: '' }, // vd: "Câu 1, Câu 3"
        answeredCount: { type: Number, default: 0 },
        totalQuestions: { type: Number, default: 0 },
    },

    emits: ['update:modelValue', 'confirm'],
	}
</script>