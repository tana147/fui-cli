<template>
    <v-file-input class="input-file" v-model="internalFiles" :label="label" :multiple="multiple" :show-size="showSize"
        outlined density="compact" prepend-icon="" append-inner-icon="mdi-folder-upload-outline"
        :rules="[rules.maxFileSize, rules.maxFiles]" :accept="fileAccept" @update:modelValue="emitFiles"
        :hide-details="isValid ? true : false">
        <template v-slot:selection="{ fileNames }">
            <template v-for="(fileName, index) in fileNames" :key="index">
                <v-chip class="me-2" :color="getColor(fileName)" dark size="small" label>
                    <v-icon left small>{{ getIcon(fileName) }}</v-icon>
                    {{ fileName }}
                </v-chip>
            </template>
        </template>
    </v-file-input>
</template>

<script>
export default {
    props: {
        modelValue: { type: [Array, File, null], default: () => [] },
        label: { type: String, default: 'Chọn file' },
        multiple: { type: Boolean, default: true },
        showSize: { type: Boolean, default: true },
        fileAccept: { type: String, default: 'image/*,.pdf' },
    },

    data() {
        return {
            isValid: true,
            internalFiles: this.modelValue || [],
            MAX_SIZE: 2 * 1024 * 1024,
            rules: {
                maxFileSize: (files) => {
                    if (!files || !files.length) return true
                    console.log('files', files)
                    const isValid = [...files].every((file) => file.size <= 2 * 1024 * 1024)
                    this.isValid = isValid
                    return isValid || 'Mỗi file phải nhỏ hơn 2MB'
                },
                maxFiles: (files) => {
                    if (!files || !files.length) return true
                    const isValid = files.length <= 5
                    this.isValid = isValid
                    return isValid || 'Chỉ được chọn tối đa 5 file'
                },
            },
        }
    },

    watch: {
        modelValue(val) {
            if (val && val.length === 0) {
                this.isValid = true
            }
            this.internalFiles = val
        },
    },

    methods: {
        emitFiles() {
            this.$emit('update:model-value', this.internalFiles)
        },

        getIcon(fileName) {
            if (!fileName) return 'mdi-file'
            if (fileName.includes('.png') || fileName.includes('.jpg') || fileName.includes('.jpeg') || fileName.includes('.gif') || fileName.includes('.webp') || fileName.includes('.svg'))
                return 'mdi-image'
            if (fileName.includes('pdf')) return 'mdi-file-pdf-box'
            return 'mdi-file'
        },

        getColor(fileName) {
            if (!fileName) return 'indigo'
            if (fileName.includes('.png') || fileName.includes('.jpg') || fileName.includes('.jpeg') || fileName.includes('.gif') || fileName.includes('.webp') || fileName.includes('.svg'))
                return 'green'
            if (fileName.includes('pdf')) return 'red'
            return 'blue'
        },
    },
}
</script>
