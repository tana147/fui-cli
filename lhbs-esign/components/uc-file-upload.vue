<template>
	<div class="uc-upload" :class="{ 'uc-upload--dragover': isDragover, 'uc-upload--disabled': disabled }"
        @click="triggerInput" @dragover.prevent="onDragOver" @dragleave.prevent="isDragover = false"
        @drop.prevent="onDrop">

        <input ref="fileInput" type="file" :accept="accept" :multiple="multiple" style="display: none;"
            @change="onFileChange" />

        <!-- Upload Area Content -->
        <slot name="content" :file-name="fileName" :is-uploading="isUploading">
            <div class="uc-upload-inner">
                <v-icon :size="32" :color="disabled ? 'grey-lighten-1' : 'primary'" class="uc-upload-icon">{{ icon }}
                </v-icon>
                <div class="uc-upload-title">{{ title }}</div>
                <div class="uc-upload-hint">{{ hint }}</div>

                <!-- File selected / uploading state -->
                <div v-if="displayUploading" class="uc-upload-status">
                    <v-progress-linear indeterminate color="primary" height="3" class="mt-3" style="max-width: 200px;">
                    </v-progress-linear>
                    <span class="uc-upload-status-text">{{ uploadingText }}</span>
                </div>
                <div v-else-if="displayFileName" class="uc-upload-status">
                    <v-icon size="14" color="success" class="mr-1">mdi-check-circle</v-icon>
                    <span class="uc-upload-status-text">{{ displayFileName }}</span>
                </div>
            </div>
        </slot>
    </div>
</template>

<script>
	export default {
		name: 'uc-upload',
  props: {
    accept:       { type: String, default: '.docx,.pdf,.xlsx,.jpg,.png' },
    multiple:     { type: Boolean, default: false },
    disabled:     { type: Boolean, default: false },
    icon:         { type: String, default: 'mdi-file-upload-outline' },
    title:        { type: String, default: 'Bấm để chọn hoặc kéo file vào đây' },
    hint:         { type: String, default: '' },
    maxSize:      { type: Number, default: 10 }, // MB
    uploadingText:{ type: String, default: 'Đang tải lên...' },
    // Auto upload to server
    autoUpload:   { type: Boolean, default: false },
    uploadSp:     { type: String, default: 'UPLOAD_FileData_Base64' },
    // Manual state control (when autoUpload = false)
    isUploading:  { type: Boolean, default: false },
    fileName:     { type: String, default: '' },
    // auto read as base64 (only when autoUpload = false)
    readBase64:   { type: Boolean, default: false }
  },
  emits: ['file-selected', 'uploaded', 'error', 'update:isUploading', 'update:fileName'],
  data: function () {
    return {
      isDragover: false,
      internalUploading: false,
      internalFileName: ''
    }
  },
  computed: {
    displayUploading: function () {
      return this.autoUpload ? this.internalUploading : this.isUploading
    },
    displayFileName: function () {
      return this.autoUpload ? this.internalFileName : this.fileName
    }
  },
  methods: {
    triggerInput: function () {
      if (this.disabled || this.displayUploading) return
      this.$refs.fileInput.value = ''
      this.$refs.fileInput.click()
    },
    onFileChange: function (e) {
      var files = e.target.files
      if (!files || !files.length) return
      this.processFiles(files)
    },
    onDragOver: function () {
      if (this.disabled) return
      this.isDragover = true
    },
    onDrop: function (e) {
      this.isDragover = false
      if (this.disabled) return
      var files = e.dataTransfer.files
      if (!files || !files.length) return
      this.processFiles(files)
    },
    processFiles: function (files) {
      var self = this
      var fileList = this.multiple ? Array.from(files) : [files[0]]

      // Validate size
      for (var i = 0; i < fileList.length; i++) {
        if (fileList[i].size > this.maxSize * 1024 * 1024) {
          self.$emit('error', { type: 'size', message: 'File "' + fileList[i].name + '" vượt quá ' + self.maxSize + 'MB', file: fileList[i] })
          return
        }
      }

      // Validate accept
      if (this.accept) {
        var exts = this.accept.split(',').map(function (s) { return s.trim().toLowerCase() })
        for (var j = 0; j < fileList.length; j++) {
          var name = fileList[j].name.toLowerCase()
          var valid = exts.some(function (ext) {
            if (ext.startsWith('.')) return name.endsWith(ext)
            return fileList[j].type && fileList[j].type.indexOf(ext) >= 0
          })
          if (!valid) {
            self.$emit('error', { type: 'type', message: 'Định dạng file không được hỗ trợ: ' + fileList[j].name, file: fileList[j] })
            return
          }
        }
      }

      // Auto upload mode: read base64 then call SP
      if (this.autoUpload) {
        self.uploadToServer(fileList[0])
        return
      }

      // Manual mode
      if (this.readBase64) {
        var reader = new FileReader()
        reader.onload = function (evt) {
          var base64 = evt.target.result.split(',')[1] || ''
          self.$emit('file-selected', { file: fileList[0], base64: base64, name: fileList[0].name })
        }
        reader.readAsDataURL(fileList[0])
      } else {
        self.$emit('file-selected', this.multiple ? { files: fileList } : { file: fileList[0], name: fileList[0].name })
      }
    },

    uploadToServer: function (file) {
      if (this.uploadMode === 'formdata') {
        this.uploadViaFormData(file)
      } else {
        this.uploadViaBase64(file)
      }
    },

    uploadViaFormData: function (file) {
      var self = this
      self.internalUploading = true
      self.internalFileName = ''
      self.$emit('update:isUploading', true)

      var formData = new FormData()
      formData.append('file', file)

      var uploadUrl = ''
      try { uploadUrl = vueData.v_Set.apiFileUpload || vueData.v_Set.apiFile || '' } catch (e) {}

      if (!uploadUrl) {
        self.internalUploading = false
        self.$emit('update:isUploading', false)
        self.$emit('error', { type: 'config', message: 'Không tìm thấy URL upload (vueData.v_Set.apiFileUpload)' })
        return
      }

      if (typeof ajaxCALL_File === 'function') {
        ajaxCALL_File(uploadUrl, formData, function (res) {
          var fileRow = self.pickFormDataResponse(res)
          self.handleUploadSuccess(fileRow, file)
        }, function (xhr) {
          self.handleUploadError(xhr)
        })
      } else {
        $.ajax({
          type: 'POST',
          headers: { authorization: (typeof $awt !== 'undefined' ? $awt : '') },
          url: uploadUrl,
          processData: false,
          contentType: false,
          crossDomain: true,
          data: formData,
          success: function (res) { self.handleUploadSuccess(self.pickFormDataResponse(res), file) },
          error: function (xhr) { self.handleUploadError(xhr) }
        })
      }
    },

    handleUploadSuccess: function (fileRow, file) {
      this.internalUploading = false
      this.$emit('update:isUploading', false)
      if (!fileRow || !fileRow.FileID) {
        this.$emit('error', { type: 'server', message: 'Không nhận được FileID sau khi upload.' })
        return
      }
      this.internalFileName = fileRow.FileName || file.name
      this.$emit('update:fileName', this.internalFileName)
      this.$emit('uploaded', {
        FileID: fileRow.FileID,
        FileName: fileRow.FileName || file.name,
        FileUrl: fileRow.FileUrl || '',
        FileSize: file.size,
        file: file
      })
      if (typeof showToast !== 'undefined' && showToast.success) {
        showToast.success('Upload thành công: ' + (fileRow.FileName || file.name))
      }
    },

    handleUploadError: function (xhr) {
      this.internalUploading = false
      this.$emit('update:isUploading', false)
      var msg = xhr && xhr.responseJSON ? xhr.responseJSON.Message : (xhr && xhr.responseText ? xhr.responseText : 'Lỗi upload file.')
      this.$emit('error', { type: 'server', message: msg })
      if (typeof showToast !== 'undefined' && showToast.error) {
        showToast.error(msg)
      }
    },

    uploadViaBase64: function (file) {
      var self = this
      self.internalUploading = true
      self.internalFileName = ''
      self.$emit('update:isUploading', true)

      var reader = new FileReader()
      reader.onload = function (evt) {
        var dataUrl = evt && evt.target ? String(evt.target.result || '') : ''
        var base64 = dataUrl.indexOf(',') >= 0 ? dataUrl.split(',')[1] : ''
        if (!base64) {
          self.internalUploading = false
          self.$emit('update:isUploading', false)
          self.$emit('error', { type: 'read', message: 'Không đọc được nội dung file.' })
          return
        }

        var params = {
          FileBase64: base64,
          FileName: file.name || 'document',
          FileContentType: file.type || 'application/octet-stream'
        }

        if (typeof apiCallAsync === 'function') {
          apiCallAsync(self.uploadSp, params).then(function (res) {
            var fileRow = self.pickUploadedFileRow(res)
            if (!fileRow || !fileRow.FileID) {
              self.internalUploading = false
              self.$emit('update:isUploading', false)
              self.$emit('error', { type: 'server', message: 'Không nhận được FileID sau khi upload.' })
              return
            }
            self.internalUploading = false
            self.internalFileName = fileRow.FileName || file.name
            self.$emit('update:isUploading', false)
            self.$emit('update:fileName', self.internalFileName)
            self.$emit('uploaded', {
              FileID: fileRow.FileID,
              FileName: fileRow.FileName || file.name,
              FileUrl: fileRow.FileUrl || '',
              FileSize: file.size,
              file: file,
              base64: base64
            })
            if (typeof showToast !== 'undefined' && showToast.success) {
              showToast.success('Upload thành công: ' + (fileRow.FileName || file.name))
            }
          }).catch(function (err) {
            self.internalUploading = false
            self.$emit('update:isUploading', false)
            var msg = err && err.responseJSON ? err.responseJSON.Message : (err && err.responseText ? err.responseText : 'Lỗi upload file.')
            self.$emit('error', { type: 'server', message: msg })
            if (typeof showToast !== 'undefined' && showToast.error) {
              showToast.error(msg)
            }
          })
        } else {
          self.internalUploading = false
          self.$emit('update:isUploading', false)
          self.$emit('file-selected', { file: file, base64: base64, name: file.name })
        }
      }
      reader.onerror = function () {
        self.internalUploading = false
        self.$emit('update:isUploading', false)
        self.$emit('error', { type: 'read', message: 'Không đọc được file.' })
      }
      reader.readAsDataURL(file)
    },

    pickUploadedFileRow: function (payload) {
      if (!payload || typeof payload !== 'object') return null
      var row = null
      if (payload.Files && payload.Files[0]) row = payload.Files[0]
      else if (payload.Result) row = payload.Result
      else if (payload.data && payload.data[0] && !Array.isArray(payload.data[0])) row = payload.data[0]
      else if (payload.data && payload.data[0] && payload.data[0][0]) row = payload.data[0][0]
      else if (payload.FileID) row = payload
      if (!row) return null
      return {
        FileID: row.FileID || row.FILE_ID || row.fileId || '',
        FileName: row.FileName || row.FILE_NAME || row.fileName || '',
        FileUrl: row.FileUrl || row.FILE_URL || row.fileUrl || ''
      }
    },

    pickFormDataResponse: function (res) {
      if (!res) return null
      if (res.Files && res.Files[0]) {
        var f = res.Files[0]
        var urlReadFile = ''
        try { urlReadFile = vueData.v_Set.urlReadFile || '' } catch (e) {}
        return {
          FileID: f.FileID || f.fileId || '',
          FileName: f.FileName || f.fileName || '',
          FileUrl: urlReadFile ? (urlReadFile + (f.FileID || '')) : (f.FileUrl || '')
        }
      }
      return this.pickUploadedFileRow(res)
    }
  }
	}
</script>