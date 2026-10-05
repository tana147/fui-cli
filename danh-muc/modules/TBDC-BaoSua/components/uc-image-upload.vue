<template>
    <div>
        <v-file-input v-model="files" accept="image/*" multiple prepend-icon="" prepend-inner-icon="mdi-camera"
            label="Ảnh đính kèm" density="compact" variant="outlined" @update:modelValue="handleFiles">
            <template #selection="{ fileNames }">
                <span class="text-truncate" style="max-width:200px;">
                    {{ formatFileNames(fileNames) }}
                </span>
            </template>
        </v-file-input>
        <v-alert v-if="error" type="error" density="compact" class="mt-2">
            {{ error }}
        </v-alert>

        <v-row v-if="previewImages.length" class="mt-2" dense>
            <v-col v-for="(img, index) in previewImages" :key="index" cols="4">
                <v-card class="position-relative">
                    <v-img :src="img" aspect-ratio="1" cover class="rounded" />

                    <v-btn icon size="x-small" style="
                            position:absolute;
                            top:6px;
                            right:6px;
                            z-index:10;
                            background:rgba(0,0,0,0.6);
                        " @click="remove(index)">
                        <v-icon color="white" size="16">mdi-close</v-icon>
                    </v-btn>

                </v-card>
            </v-col>
        </v-row>
    </div>
</template>

<script>
export default {
    props: {
        modelValue: {
            type: Array,
            default: () => []
        }
    },

    data() {
        return {
            files: [],
            previewImages: [],
            error: null
        }
    },

    methods: {
        truncate(name, length = 25) {
            if (!name) return ""

            if (name.length <= length) return name

            const ext = name.split(".").pop()
            const base = name.substring(0, length - ext.length - 3)

            return `${base}...${ext}`
        },

        formatFileNames(names) {
            if (names.length === 1) {
                return this.truncate(names[0])
            }

            return `${names.length} ảnh đã chọn`
        },

        handleFiles(files) {
            this.error = null
            const MAX_FILES = 5
            const MAX_SIZE = 5 * 1024 * 1024
            let validFiles = []
            for (const file of files) {

                if (file.size > MAX_SIZE) {
                    this.error = "Mỗi ảnh tối đa 5MB"
                    continue
                }
                validFiles.push(file)
            }
            if (validFiles.length > MAX_FILES) {
                this.error = "Chỉ được upload tối đa 5 ảnh"
                validFiles = validFiles.slice(0, MAX_FILES)
            }
            this.files = validFiles
            this.previewImages = validFiles.map(file =>
                URL.createObjectURL(file)
            )
            this.$emit("update:modelValue", validFiles)
        },

        remove(index) {
            this.files.splice(index, 1)
            this.previewImages.splice(index, 1)
            this.$emit("update:modelValue", this.files)
        }

    }
}
</script>