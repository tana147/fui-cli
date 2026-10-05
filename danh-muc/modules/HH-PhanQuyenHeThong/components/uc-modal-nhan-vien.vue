<template>
    <v-dialog :modelValue="modelValue" max-width="600" @update:modelValue="onDialogChange">
        <v-card>
            <template v-slot:title>
                {{ isEdit ? 'Cập nhật nhân viên' : 'Thêm mới nhân viên' }}
            </template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose" />
            </template>

            <v-card-text>
                <v-form ref="refForm">
                    <v-row class="mt-2">
                        <v-col cols="12">
                            <v-autocomplete v-model="formData.MaNhanVien" label="Nhân viên" :items="nhanVienCatalog"
                                item-title="NhanVienDisplay" item-value="MaNhanVien" required autofocus
                                :rules="[rules.required]" variant="outlined" density="comfortable" />
                        </v-col>

                        <v-col cols="6">
                            <v-select v-model="formData.BoPhan_Id" label="Bộ phận" :items="boPhanList"
                                item-title="TenBoPhan" item-value="BoPhan_Id" required :rules="[rules.required]"
                                variant="outlined" density="comfortable" />
                        </v-col>

                        <v-col cols="6">
                            <v-select v-model="formData.TinhTrang" label="Tình trạng" :items="tinhTrangOptions"
                                item-title="text" item-value="value" required :rules="[rules.required]"
                                variant="outlined" density="comfortable" />
                        </v-col>
                    </v-row>
                </v-form>
            </v-card-text>

            <v-card-actions>
                <v-spacer />
                <v-btn color="default" variant="text" @click="onClose">Hủy</v-btn>
                <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="onSave">
                    Lưu
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
    export default {
  name: 'uc-modal-nhan-vien',
  props: {
    modelValue: {
      type: Boolean,
      required: true,
    },
    nhanVienDetail: {
      type: Object,
      default: null,
    },
    isEdit: {
      type: Boolean,
      default: false,
    },
    boPhanList: {
      type: Array,
      required: true,
    },
    nhanVienCatalog: {
      type: Array,
      default: function () {
        return []
      },
    },
  },
  emits: ['update:modelValue', 'save'],
  data() {
    return {
      formData: this.createEmptyForm(),
      rules: {
        required: function (value) {
          return !(value === null || value === undefined || value === '') || 'Không được để trống'
        },
      },
      tinhTrangOptions: [
        { text: 'Hoạt động', value: 0 },
        { text: 'Tạm khóa', value: 1 },
      ],
    }
  },
  watch: {
    nhanVienDetail: {
      handler(val) {
        if (val) {
          this.formData = this.cloneFormData(val)
        } else {
          this.resetForm()
        }
      },
      deep: true,
      immediate: true,
    },
  },
  methods: {
    createEmptyForm() {
      return {
        NhanVien_Id: null,
        MaNhanVien: '',
        BoPhan_Id: null,
        TinhTrang: 0,
      }
    },
    cloneFormData(source) {
      return {
        NhanVien_Id: source && source.NhanVien_Id ? source.NhanVien_Id : null,
        MaNhanVien: source && source.MaNhanVien ? source.MaNhanVien : '',
        BoPhan_Id: source && source.BoPhan_Id ? source.BoPhan_Id : null,
        TinhTrang: source && source.TinhTrang !== undefined ? Number(source.TinhTrang) : 0,
      }
    },
    resetForm() {
      this.formData = this.createEmptyForm()
      if (this.$refs.refForm && this.$refs.refForm.resetValidation) {
        this.$refs.refForm.resetValidation()
      }
    },
    onDialogChange(value) {
      this.$emit('update:modelValue', value)
    },
    onClose() {
      this.$emit('update:modelValue', false)
      setTimeout(() => {
        this.resetFormAfterClose()
      }, 300)
    },
    resetFormAfterClose() {
      this.resetForm()
    },
    async onSave() {
      const validation = await this.$refs.refForm.validate()
      if (!validation.valid) { return }
      this.$emit('save', this.cloneFormData(this.formData))
    },
  },
}
</script>